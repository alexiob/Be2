//
//  GameEngine.m
//  Be2
//
//  Created by Alessandro Iob on 9/9/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "SynthesizeSingleton.h"

#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKMath.h"
#import "KKGameEngine.h"
#import "KKPersistenceManager.h"
#import "KKGraphicsManager.h"
#import "KKScenesManager.h"
#import "KKObjectsManager.h"
#import "KKSoundManager.h"
#import "KKInputManager.h"
#import "KKLuaManager.h"
#import "KKCollisionDetection.h"
#import "KKLuaGameLib.h"
#import "KKEntitiesCommon.h"
#import "KKHUDLayer.h"
#import "CGPointExtension.h"
#import "KKLuaCalls.h"
#import "KKAIClasses.h"
//#import "KKOpenFeintManager.h"
#import "KKOpenFeintConfig.h"
#import "KKGamePath.h"

#import "CocosDenshion.h"

#import "ASIHTTPRequest.h"

#import "SneakyJoystick.h"

#ifdef KK_BE2_FREE
#import "KKStoreManager.h"
#endif

@interface KKGameEngine ()

-(void) initGameScriptLibs;
-(void) loadGameScripts;
-(void) initGameScriptGlobals;
-(void) loadGameScriptTemplates;

@end

#define MUSIC_IN_DURATION 0.2
#define MUSIC_OUT_DURATION 0.2

#define LEVEL_LOAD_SLEEP 2.5
#define LEVEL_LOAD_MINIMUM_SLEEP 0.1

#define LEVEL_START_TIMEOUT 3

#define FIRST_LEVEL_INDEX 0

@implementation KKLevelLoadOperation

-(id) initWithLevelDir:(NSString *)name startAudio:(BOOL)a startTimer:(float)s
{
	self = [super init];
	if (self) {
		levelDir = [name copy];
		audio = a;
		seconds = s;
	}
	return self;
}

-(void) dealloc
{
	if (levelDir) [levelDir release], levelDir = nil;
	
	[super dealloc];
}

-(void) main
{
	NSDate *date = [NSDate date];
	
	BOOL loaded = NO;
	KKGameEngine *gameEngine = KKGE;
	NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
	EAGLContext* oldContext = [EAGLContext currentContext];
	EAGLContext* context = [[EAGLContext alloc]
							initWithAPI:kEAGLRenderingAPIOpenGLES1
							sharegroup:[[[[CCDirector sharedDirector] openGLView] context] sharegroup]];
	
	if (nil == context) {
		KKLOG (@"could not create EAGL context");
	} else if(![EAGLContext setCurrentContext:context]) {
		KKLOG (@"could not set EAGL context");
	} else {
		loaded = [(NSNumber *) [gameEngine performSelector:@selector(loadLevelOperation:) 
						 withObject:[NSArray arrayWithObjects:self, levelDir, nil]
		 ] boolValue];
	}
	
	[EAGLContext setCurrentContext:oldContext];
	[context release];
	
	if (![self isCancelled]) {
		NSArray *data = [NSArray arrayWithObjects:
						 [NSNumber numberWithBool:loaded], 
						 [NSNumber numberWithBool:audio],
						 [NSNumber numberWithFloat:seconds],
						 nil
						 ];
		
		NSTimeInterval ti = [[NSDate date] timeIntervalSinceDate:date];
		if (ti > LEVEL_LOAD_MINIMUM_SLEEP)
			[NSThread sleepForTimeInterval:LEVEL_LOAD_SLEEP];
		[gameEngine performSelectorOnMainThread:@selector(levelLoaded:) withObject:data waitUntilDone:YES];
	}
	[autoreleasepool release];
}

@end

@implementation KKGameEngine

@synthesize unlimitedLifes;
@synthesize currentGameState, currentGamePhase;
@synthesize level, levelName, levelData;
@synthesize flags;
@synthesize isFullQuest;
@synthesize paused;
@synthesize hud;
@synthesize score, scoreMultiplier, previousLevelScore, currentLevelScore;
@synthesize questTimeElapsed, levelTimeElapsed, levelTimeLeft;
@synthesize questExplorationPoints, questTotalExplorationPoints;
@synthesize updateLevelTimeLeft;
@synthesize levelTimeSuspended;
@synthesize inputMode, difficultyLevel;

SYNTHESIZE_SINGLETON(KKGameEngine);

-(id) init
{
	self = [super init];
	
	if (self) {
		luaManager = KKLM;
		soundManager = KKSNDM;
		gameInfo = GAME_INFO;
		
#ifdef KK_BE2_FREE
		[KKStoreManager setDelegate:self];
		KKSTORE;
#endif

		allLevels = 0;
		unlimitedLifes = 0;
		forceFullQuestMode = 0;
		forceFullQuestCompleted = 0;
		
		backgroundQueue = [[NSOperationQueue alloc] init];

		initRandomNumberGenerator (42);

		// application counters
		NSDate *firstRun = [KKPM.info objectForKey:APP_FIRST_RUN];
		if (firstRun == nil) {
			[KKPM.info setObject:[NSDate date] forKey:APP_FIRST_RUN];
		}
		
		NSNumber *numLaunches = [KKPM.info objectForKey:APP_NUM_LAUNCHES];
		if (numLaunches == nil) {
			numLaunches = [NSNumber numberWithInt:0];
		}
		numLaunches = [NSNumber numberWithInt:[numLaunches intValue] + 1];
		[KKPM.info setObject:numLaunches forKey:APP_NUM_LAUNCHES];
		
		self.paused = NO;
		
		self.currentGameState = kGSGameStart;
		self.currentGamePhase = nil;

		[self setupDefaultInfo:![self levelAvailable:FIRST_LEVEL_INDEX]];
		[self loadAvailableLevelsInfo];
		
		[self loadDefaultScreenMessages];

		inputMode = [KKPM inputMode];
		difficultyLevel = [KKPM difficultyLevel];
		
		[self loadGameScriptTemplates];
		[self initGameScriptLibs];
		[self initGameScriptGlobals];
		[self loadGameScripts];
		
		[self resetStartDate];
	}
	return self;
}

-(void) dealloc
{
	if (backgroundQueue) {
		[backgroundQueue cancelAllOperations];
		[backgroundQueue release];
		backgroundQueue = nil;
	}
	if (level) [level release], level = nil;

	if (defaultScreenMessages) [defaultScreenMessages release], defaultScreenMessages = nil;
	if (levelScreenMessages) [levelScreenMessages release], levelScreenMessages = nil;
	
	if (levelName) [levelName release], levelName = nil;
	if (levelData) [levelData release], levelData = nil;
	
	if (availableLevelsInfo) [availableLevelsInfo release], availableLevelsInfo = nil;
	if (sortedAvailableLevelsInfo) [sortedAvailableLevelsInfo release], sortedAvailableLevelsInfo = nil;
	
	if (startDate) [startDate release], startDate = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Store

-(BOOL) isFreeVersion
{
#ifdef KK_BE2_FREE
	return YES;
#else
	return NO;
#endif
}

-(BOOL) areAllLevelsPurchased
{
#ifdef KK_BE2_FREE
	BOOL f = NO;
	f = [KKSTORE isItemWithIdPurchased:STORE_ITEM_UNLOCK_ALL_LEVELS];
	return f;
#else
	return YES;
#endif
}

-(void) buyAllLevels
{
#ifdef KK_BE2_FREE
	[hud showStoreBackground:YES];
	[KKSTORE buyItem:STORE_ITEM_UNLOCK_ALL_LEVELS];
#endif
}

-(void) productPurchased:(NSString*)productIdentifier
{
#ifdef KK_BE2_FREE
	[hud showStoreBackground:NO];
	if ([productIdentifier isEqualToString:STORE_ITEM_UNLOCK_ALL_LEVELS]) {
		if ([level.name isEqualToString:LEVEL_MAIN_MENU]) {
			[KKLM execString:@"level:paddleWithName('buyLevels1'):setEnabled(false)"];
			[KKLM execString:@"level:paddleWithName('buyLevels2'):setEnabled(false)"];
		} else if ([level.name isEqualToString:@"dungeonOfSquares"]){
			[KKLM execString:@"level:gotoNextLevel()"];
		}
	}
#endif
}

-(void) productPurchasedFailed
{
#ifdef KK_BE2_FREE
	[hud showStoreBackground:NO];
#endif
}

#pragma mark -
#pragma mark Game Globals

-(int) getGlobal:(int)n
{
	int r = 0;
	
	switch (n) {
		case 9: // full quest mode
			r = forceFullQuestMode;
			break;
		case 10: // full quest completed
			r = forceFullQuestCompleted;
			break;
		case 12: // all levels
			r = allLevels;
			break;
		case 42: // unlimited lifes
			r = unlimitedLifes;
			break;
		default:
			break;
	}
	return r;
}

-(void) setGlobal:(int)n toInteger:(int)i;
{
	switch (n) {
		case 6: // end scene
			[self questEnd];
			break;
		case 9: // full quest mode
			forceFullQuestMode = i;
			break;
		case 10: // full quest mode
			forceFullQuestCompleted = i;
			break;
		case 12:
			allLevels = i;
			break;
		case 42:
			unlimitedLifes = i;
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark Input Mode

-(void) setInputMode:(int)m
{
	inputMode = m;
	KKPM.inputMode = m;
}

-(void) setDifficultyLevel:(int)m
{
	difficultyLevel = m;
	KKPM.difficultyLevel = m;
}

#pragma mark -
#pragma mark Game Data

-(NSMutableDictionary *) saveGameData
{
	NSMutableDictionary *gameData = [NSMutableDictionary dictionaryWithCapacity:10];
	
	[gameData setObject:[NSNumber numberWithInt:gameMode] forKey:@"gameMode"];
	[gameData setObject:[NSNumber numberWithBool:isFullQuest] forKey:@"isFullQuest"];
	[gameData setObject:[NSNumber numberWithInt:flags] forKey:@"flags"];
	[gameData setObject:[NSNumber numberWithFloat:questTimeElapsed] forKey:@"questTimeElapsed"];
	[gameData setObject:[NSNumber numberWithInt:numPlayerHerosLeft] forKey:@"numPlayerHerosLeft"];
	[gameData setObject:[NSNumber numberWithInt:questExplorationPoints] forKey:@"questExplorationPoints"];
	[gameData setObject:[NSNumber numberWithInt:score] forKey:@"score"];
	[gameData setObject:[NSNumber numberWithInt:scoreMultiplier] forKey:@"scoreMultiplier"];
	[gameData setObject:[NSNumber numberWithInt:scoreForNewLife] forKey:@"scoreForNewLife"];
	
	return gameData;
}

-(void) loadGameData:(NSDictionary *)gameData
{
	gameMode = [[gameData objectForKey:@"gameMode"] intValue];
	isFullQuest = [[gameData objectForKey:@"isFullQuest"] boolValue];
	flags = [[gameData objectForKey:@"flags"] intValue];
	questTimeElapsed = [[gameData objectForKey:@"questTimeElapsed"] floatValue];
	numPlayerHerosLeft = [[gameData objectForKey:@"numPlayerHerosLeft"] intValue];
	questExplorationPoints = [[gameData objectForKey:@"questExplorationPoints"] intValue];
	score = [[gameData objectForKey:@"score"] intValue];
	scoreMultiplier = [[gameData objectForKey:@"scoreMultiplier"] intValue];
	scoreForNewLife = [[gameData objectForKey:@"scoreForNewLife"] intValue];
}

#pragma mark -
#pragma mark Game Info

-(void) setupDefaultInfo:(BOOL)force
{
	if (!force && [gameInfo count]) return;
	
	[gameInfo setObject:[NSMutableDictionary dictionaryWithCapacity:1] forKey:@"levels"];

	[self setLevel:FIRST_LEVEL_INDEX available:YES];
	[self setNextLevel:FIRST_LEVEL_INDEX];
}

// next level
-(int) nextLevel
{
	return [[gameInfo objectForKey:@"nextLevel"] intValue];
}

-(void) setNextLevel:(int)idx
{
	[gameInfo setObject:[NSNumber numberWithInt:idx] forKey:@"nextLevel"];	
}

// level stuff

-(NSMutableDictionary *) gameInfoLevel:(int)levelIndex
{
	NSMutableDictionary *i = [gameInfo objectForKey:@"levels"];
	NSMutableDictionary *li = [i objectForKey:[NSNumber numberWithInt:levelIndex]];
	if (!li) {
		li = [NSMutableDictionary dictionaryWithCapacity:10];
		[i setObject:li forKey:[NSNumber numberWithInt:levelIndex]];
	}
	return li;
}

// info

-(NSMutableDictionary *) levelInfo:(int)idx
{
	return [availableLevelsInfo objectForKey:[NSNumber numberWithInt:idx]];
}

// available
-(BOOL) levelAvailable:(int)levelIndex
{
	// menu levels (with index < 0) should be skipped in menu
	if (levelIndex < 0) return NO;
	
//#ifdef KK_DEBUG
	return YES;
//#endif
	
//	BOOL f = NO;
//	if (allLevels) f = YES;
//	else {
//		NSMutableDictionary *li = [self gameInfoLevel:levelIndex];
//		
//		if ([li objectForKey:@"available"]) {
//			f = [[li objectForKey:@"available"] boolValue];
//		}
//	}
//	return f;
}

-(void) setLevel:(int)levelIndex available:(BOOL)f
{
	NSMutableDictionary *li = [self gameInfoLevel:levelIndex];
	[li setObject:[NSNumber numberWithBool:f] forKey:@"available"];
}


// completed
-(BOOL) levelCompleted:(int)levelIndex
{
	NSMutableDictionary *li = [self gameInfoLevel:levelIndex];
	BOOL f = NO;
	
	if ([li objectForKey:@"completed"]) {
		f = [[li objectForKey:@"completed"] boolValue];
	}
	return f;
}

-(void) setLevel:(int)levelIndex completed:(BOOL)f
{
	NSMutableDictionary *li = [self gameInfoLevel:levelIndex];
	[li setObject:[NSNumber numberWithBool:f] forKey:@"completed"];
}

// bestScore
-(int) levelBestScore:(int)levelIndex
{
	NSMutableDictionary *li = [self gameInfoLevel:levelIndex];
	int f = 0;
	
	if ([li objectForKey:@"bestScore"]) {
		f = [[li objectForKey:@"bestScore"] intValue];
	}
	return f;
}

-(void) setLevel:(int)levelIndex bestScore:(int)f
{
	NSMutableDictionary *li = [self gameInfoLevel:levelIndex];
	[li setObject:[NSNumber numberWithInt:f] forKey:@"bestScore"];
}

// bestTime
-(float) levelBestTime:(int)levelIndex
{
	NSMutableDictionary *li = [self gameInfoLevel:levelIndex];
	float f = 0;
	
	if ([li objectForKey:@"bestTime"]) {
		f = [[li objectForKey:@"bestTime"] floatValue];
	}
	return f;
}

-(void) setLevel:(int)levelIndex bestTime:(float)f
{
	NSMutableDictionary *li = [self gameInfoLevel:levelIndex];
	[li setObject:[NSNumber numberWithFloat:f] forKey:@"bestTime"];
}

//---------------------------------------------------------------
// missions data

-(NSMutableDictionary *) getGlobalMissionData:(NSString *)name
{
	NSMutableDictionary *info = KKPM.info;
	NSMutableDictionary *missions = [info objectForKey:@"missions"];
	NSMutableDictionary *mission;
	
	if (!missions) {
		missions = [NSMutableDictionary dictionaryWithCapacity:10];
		[info setObject:missions forKey:@"missions"];
	}
	mission = [missions objectForKey:name];
	if (!mission) {
		mission = [NSMutableDictionary dictionaryWithCapacity:10];
		[missions setObject:mission forKey:name];
	}
	return mission;
}

-(void) setGlobalMission:(NSString *)name field:(NSString *)field toBool:(BOOL)f
{
//#ifdef KK_DEBUG
//	if ([field isEqualToString:@"completed"]) return;
//#endif
	
	NSMutableDictionary *mission = [self getGlobalMissionData:name];
	[mission setObject:[NSNumber numberWithBool:f] forKey:field];
}

-(void) setGlobalMission:(NSString *)name field:(NSString *)field toInt:(int)f
{
	NSMutableDictionary *mission = [self getGlobalMissionData:name];
	[mission setObject:[NSNumber numberWithInt:f] forKey:field];
}

-(void) setGlobalMission:(NSString *)name field:(NSString *)field toFloat:(float)f
{
	NSMutableDictionary *mission = [self getGlobalMissionData:name];
	[mission setObject:[NSNumber numberWithFloat:f] forKey:field];
}

-(void) setGlobalMission:(NSString *)name field:(NSString *)field toString:(NSString *)f
{
	NSMutableDictionary *mission = [self getGlobalMissionData:name];
	[mission setObject:f forKey:field];
}

-(BOOL) globalMission:(NSString *)name boolField:(NSString *)field
{
//#ifdef KK_DEBUG
//	if ([field isEqualToString:@"completed"]) return NO;
//#endif
		 
	NSMutableDictionary *mission = [self getGlobalMissionData:name];
	return [[mission objectForKey:field] boolValue];
}

-(int) globalMission:(NSString *)name intField:(NSString *)field
{
	NSMutableDictionary *mission = [self getGlobalMissionData:name];
	return [[mission objectForKey:field] intValue];
}

-(float) globalMission:(NSString *)name floatField:(NSString *)field
{
	NSMutableDictionary *mission = [self getGlobalMissionData:name];
	return [[mission objectForKey:field] floatValue];
}

-(NSString *) globalMission:(NSString *)name stringField:(NSString *)field
{
	NSMutableDictionary *mission = [self getGlobalMissionData:name];
	return [mission objectForKey:field];
}

//---------------------------------------------------------------

//-(NSMutableDictionary *) getMissionData:(NSString *)name
//{
//	return nil;
//}

//---------------------------------------------------------------

#pragma mark -
#pragma mark Scripts

-(void) loadScripts:(NSString *)scriptsDir
{
	NSString *file;
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:scriptsDir];
	
	while (file = [dirEnum nextObject]) {
		if ([[file pathExtension] isEqualToString:SCRIPT_EXT]) {
			[luaManager loadFile:[NSString stringWithFormat:@"%@/%@", scriptsDir, file]];
		}
	}
}

-(void) loadLevelScripts
{
	NSString *path = [self getResourcesFolder:LEVELS_FOLDER forLevel:levelName];
	[self loadScripts:[NSString stringWithFormat:@"%@/%@", path, LEVEL_PATH_SCRIPTS]];
}

-(void) loadGameScripts
{
	[self loadScripts:[CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:RESOURCES_PATH_SCRIPTS]]];

	//FIXME: lua bytecode msube compiled for iPhone architecture!!
//	[luaManager loadFile:[CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:RESOURCES_PATH_SCRIPTS_BIN]]];
	if ([luaManager isFunctionDefined:@"main"])
		[luaManager callFunction:@"main" withObjects:levelName, nil];
}

-(void) initGameScriptLibs
{
	registerLuaGameLib ();
}

-(void) initGameScriptGlobals
{
	registerLuaGameLib();
	[luaManager setGlobal:@"resourcesPath" toObject:[CCFileUtils fullPathFromRelativePath:RESOURCES_FOLDER]];
}

#define SCRIPT_TEMPLATE_PATH(__NAME__) [NSString stringWithContentsOfFile:[self pathForScript:[NSString stringWithFormat:@"/templates/%@.%@", __NAME__, SCRIPT_TEMPLATE_EXT]] encoding:NSUTF8StringEncoding error:nil]

-(void) loadGameScriptTemplates
{
	NSString *t;
	
	t = SCRIPT_TEMPLATE_PATH (TEMPLATE_LEVEL);
	ADD_SHARED_OBJECT (TEMPLATE_LEVEL, t);
	
	t = SCRIPT_TEMPLATE_PATH (TEMPLATE_SCREEN);
	ADD_SHARED_OBJECT (TEMPLATE_SCREEN, t);
	
	t = SCRIPT_TEMPLATE_PATH (TEMPLATE_PADDLE);
	ADD_SHARED_OBJECT (TEMPLATE_PADDLE, t);
}

#pragma mark -
#pragma mark Screen Messages

-(void) loadDefaultScreenMessages
{
	NSString *errorDesc = nil;
	NSPropertyListFormat plistFormat;
	NSString *plistPath = [self pathForData:DEFAULT_SCREEN_MESSAGES_PLIST];
	NSData *plistData = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	defaultScreenMessages = [(NSDictionary *) [NSPropertyListSerialization
								 propertyListFromData:plistData 
								 mutabilityOption:NSPropertyListMutableContainersAndLeaves 
								 format:&plistFormat
								 errorDescription:&errorDesc
								 ] retain];
	KKLOG (@"loaded %@", plistPath);
}

-(void) loadLevelScreenMessages
{
	if (levelScreenMessages) [levelScreenMessages release], levelScreenMessages = nil;
	
	NSString *errorDesc = nil;
	NSPropertyListFormat plistFormat;
	NSString *plistPath = [self pathForLevel:LEVEL_SCREEN_MESSAGES_PLIST];
	if (![[NSFileManager defaultManager] isReadableFileAtPath:plistPath]) return;
	
	NSData *plistData = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	levelScreenMessages = [(NSDictionary *) [NSPropertyListSerialization
											   propertyListFromData:plistData 
											   mutabilityOption:NSPropertyListMutableContainersAndLeaves 
											   format:&plistFormat
											   errorDescription:&errorDesc
											   ] retain];
	
	KKLOG (@"loaded %@", plistPath);
}

#define SCREEN_MESSAGES_KEY @"messages"
#define SCREEN_MESSAGES_DEFAULT_KEY @"default"

-(NSString *) randomMessage
{
	NSArray *messages = nil;
	NSString *msg = nil;
	
	if ([levelScreenMessages objectForKey:SCREEN_MESSAGES_DEFAULT_KEY]) {
		messages = (NSArray *)[(NSDictionary *)[levelScreenMessages objectForKey:SCREEN_MESSAGES_DEFAULT_KEY] objectForKey:SCREEN_MESSAGES_KEY];
	} else {
		messages = (NSArray *)[(NSDictionary *)[defaultScreenMessages objectForKey:SCREEN_MESSAGES_DEFAULT_KEY] objectForKey:SCREEN_MESSAGES_KEY];			
	}
	
	if (messages) {
		int i = RANDOM_INT (0, [messages count] - 1);
		msg = (NSString *)[messages objectAtIndex:i];
	}
	return msg;	
}

-(NSString *) screenMessageWithIndex:(int)idx
{
	if (idx == -1) return @"";
	
	NSNumber *k = [NSNumber numberWithInt:idx];
	NSArray *messages = nil;
	NSString *msg = nil;
	
	if ([levelScreenMessages objectForKey:k]) {
		messages = (NSArray *)[(NSDictionary *)[levelScreenMessages objectForKey:k] objectForKey:SCREEN_MESSAGES_KEY];
	} else if ([levelScreenMessages objectForKey:SCREEN_MESSAGES_DEFAULT_KEY]) {
		messages = (NSArray *)[(NSDictionary *)[levelScreenMessages objectForKey:SCREEN_MESSAGES_DEFAULT_KEY] objectForKey:SCREEN_MESSAGES_KEY];
	} else {
		if ([defaultScreenMessages objectForKey:k]) {
			messages = (NSArray *)[(NSDictionary *)[defaultScreenMessages objectForKey:k] objectForKey:SCREEN_MESSAGES_KEY];			
		} else {
			messages = (NSArray *)[(NSDictionary *)[defaultScreenMessages objectForKey:SCREEN_MESSAGES_DEFAULT_KEY] objectForKey:SCREEN_MESSAGES_KEY];			
		}
	}

	if (messages) {
		int i = RANDOM_INT (0, [messages count] - 1);
		msg = (NSString *)[messages objectAtIndex:i];
	}
	return msg;
}

-(NSString *) screenMessage:(KKScreen *)screen
{
	return [self screenMessageWithIndex:screen.index];
}

#pragma mark -
#pragma mark FX

-(void) fxReset
{
	fxInvertAccelerationX = NO;
	fxInvertAccelerationY = NO;
	fxAccelerationIncrementX = 0;
	fxAccelerationIncrementXTimeout = 0;
	fxAccelerationIncrementY = 0;
	fxAccelerationIncrementYTimeout = 0;
	fxHeroScaleIncrement = CGSizeMake(1, 1);
	fxHeroScaleIncrementTimeout = 0;
	[level.mainHero resetScaleIncrement:0];
}

-(void) fxInvertAccelerationX:(float)timeout
{
	if (timeout) {
		fxInvertAccelerationX = YES;
		fxInvertAccelerationXTimeout = timeout;
	} else {
		fxInvertAccelerationX = NO;
	}
}

-(void) fxInvertAccelerationY:(float)timeout
{
	if (timeout) {
		fxInvertAccelerationY = YES;
		fxInvertAccelerationYTimeout = timeout;
	} else {
		fxInvertAccelerationY = NO;
	}
}

-(void) fxAccelerationIncrementX:(float)inc timeout:(float)timeout
{
	fxAccelerationIncrementX = inc;
	fxAccelerationIncrementXTimeout = timeout;
}

-(void) fxAccelerationIncrementY:(float)inc timeout:(float)timeout;
{
	fxAccelerationIncrementY = inc;
	fxAccelerationIncrementYTimeout = timeout;
}

-(void) fxBlockedSideMovements:(int)sides timeout:(float)timeout
{
	fxBlockedSideMovements = sides;
	fxBlockedSideMovementsTimeout = timeout;
}

#define FX_SIZE_INCREMENT_DURATION 0.4

-(void) fxHeroScaleIncrement:(CGSize)inc timeout:(float)timeout
{
	fxHeroScaleIncrement = inc;
	fxHeroScaleIncrementTimeout = timeout;
	
	if (fxHeroScaleIncrementTimeout) {
		[level.mainHero setScaleIncrement:inc duration:FX_SIZE_INCREMENT_DURATION]; 
	} else {
		[level.mainHero resetScaleIncrement:FX_SIZE_INCREMENT_DURATION];
	}
}

-(void) updateFX:(ccTime)dt
{
	if (fxInvertAccelerationXTimeout) {
		if (fxInvertAccelerationXTimeout != -1) {
			fxInvertAccelerationXTimeout -= dt;
			if (fxInvertAccelerationXTimeout <= 0) {
				fxInvertAccelerationXTimeout = 0;
				fxInvertAccelerationX = NO;
			}
		}
	}
	
	if (fxInvertAccelerationYTimeout) {
		if (fxInvertAccelerationYTimeout != -1) {
			fxInvertAccelerationYTimeout -= dt;
			if (fxInvertAccelerationYTimeout <= 0) {
				fxInvertAccelerationYTimeout = 0;
				fxInvertAccelerationY = NO;
			}
		}
	}
	
	if (fxAccelerationIncrementXTimeout) {
		if (fxAccelerationIncrementXTimeout != -1) {
			fxAccelerationIncrementXTimeout -= dt;
			if (fxAccelerationIncrementXTimeout <= 0) {
				fxAccelerationIncrementXTimeout = 0;
				fxAccelerationIncrementX = 0;
			}
		}
	}
	
	if (fxAccelerationIncrementYTimeout) {
		if (fxAccelerationIncrementYTimeout != -1) {
			fxAccelerationIncrementYTimeout -= dt;
			if (fxAccelerationIncrementYTimeout <= 0) {
				fxAccelerationIncrementYTimeout = 0;
				fxAccelerationIncrementY = 0;
			}
		}
	}
	
	if (fxBlockedSideMovementsTimeout) {
		if (fxBlockedSideMovementsTimeout != -1) {
			fxBlockedSideMovementsTimeout -= dt;
			if (fxBlockedSideMovementsTimeout <= 0) {
				fxBlockedSideMovementsTimeout = 0;
				fxBlockedSideMovements = kSideNone;
			}
		}
	}
	
	if (fxHeroScaleIncrementTimeout) {
		if (fxHeroScaleIncrementTimeout != -1) {
			fxHeroScaleIncrementTimeout -= dt;
			if (fxHeroScaleIncrementTimeout <= 0) {
				fxHeroScaleIncrementTimeout = 0;
				fxHeroScaleIncrement = CGSizeMake(1, 1);
				[level.mainHero resetScaleIncrement:FX_SIZE_INCREMENT_DURATION]; 
			}
		}
	}
}

#pragma mark -
#pragma mark Level Info

-(BOOL) isMainMenu
{
	return [level.name isEqualToString:LEVEL_MAIN_MENU];
}

-(void) loadAvailableLevelsInfo
{
	if (availableLevelsInfo) {
		[availableLevelsInfo release];
		availableLevelsInfo = nil;
	}
	availableLevelsInfo = [[NSMutableDictionary dictionaryWithCapacity:20] retain];
	
	questTotalExplorationPoints = 0;

#ifdef xKK_DEBUG
	NSString *levelsDir = [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@", LEVELS_FOLDER]];
	NSError *error = nil;
	NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:levelsDir error:&error];	

	for (NSString *levelDir in dirContents) {
		NSString *errorDesc = nil;
		NSPropertyListFormat plistFormat;
		NSString *plistPath = [self pathForLevelDefinition:levelDir];
		NSData *plistData = [[NSFileManager defaultManager] contentsAtPath:plistPath];
		NSDictionary *data = (NSDictionary *)[NSPropertyListSerialization
											  propertyListFromData:plistData 
											  mutabilityOption:NSPropertyListMutableContainersAndLeaves 
											  format:&plistFormat
											  errorDescription:&errorDesc
											  ];
		
		int idx = [[data objectForKey:@"index"] intValue];
		NSNumber *nIdx = [NSNumber numberWithInt:idx];
		NSMutableDictionary *li = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   [data objectForKey:@"kind"], @"kind",
								   nIdx, @"index",
								   [data objectForKey:@"name"], @"name",
								   [data objectForKey:@"title"], @"title",
								   [data objectForKey:@"description"], @"description",
								   [data objectForKey:@"difficulty"], @"difficulty",
								   [data objectForKey:@"availableTime"], @"availableTime",
								   [data objectForKey:@"minimumScore"], @"minimumScore",
								   [data objectForKey:@"explorationPoints"], @"explorationPoints",
								   nil
								   ];
		if ([data objectForKey:@"explorationPoints"]) {
			questTotalExplorationPoints += [[data objectForKey:@"explorationPoints"] intValue];
		}
		
		[availableLevelsInfo setObject:li forKey:nIdx];
	}
#else
	NSString *plistPath = [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", LEVELS_FOLDER, LEVELS_INFO]];
	NSString *errorDesc = nil;
	NSPropertyListFormat plistFormat;
	NSData *plistData = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	NSMutableDictionary *infoData = (NSMutableDictionary *)[[NSPropertyListSerialization
												   propertyListFromData:plistData 
												   mutabilityOption:NSPropertyListMutableContainersAndLeaves 
												   format:&plistFormat
												   errorDescription:&errorDesc
												   ] retain];
	
	for (NSMutableDictionary *data in [infoData allValues]) {
		if ([data objectForKey:@"explorationPoints"]) {
			questTotalExplorationPoints += [[data objectForKey:@"explorationPoints"] intValue];
		}
		[availableLevelsInfo setObject:data forKey:[NSNumber numberWithInt:[[data objectForKey:@"index"] intValue]]];
	}
#endif
	
	NSArray *keys = [availableLevelsInfo allKeys];
	NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(compare:)];
	if (sortedAvailableLevelsInfo) {
		[sortedAvailableLevelsInfo release];
		sortedAvailableLevelsInfo = nil;
	}
	sortedAvailableLevelsInfo = [[NSMutableArray arrayWithCapacity:[sortedKeys count]] retain];
	
	for (NSString *k in sortedKeys) {
		[sortedAvailableLevelsInfo addObject:[availableLevelsInfo objectForKey:k]];
	}
	currentAvailableLevelInfoIndex = 1;//[sortedAvailableLevelsInfo count] - 1;
	KKLOG (@"++++++ currentAvailableLevelInfo: %d %d", currentAvailableLevelInfoIndex, [sortedAvailableLevelsInfo count] - 1);

	[self currentAvailableLevelInfo];
}

-(NSMutableDictionary *) currentAvailableLevelInfo
{
	NSMutableDictionary *li = [sortedAvailableLevelsInfo objectAtIndex:currentAvailableLevelInfoIndex];
	BOOL lb = [self levelAvailable:[[li objectForKey:@"index"] intValue]];
	KKLOG (@"++++++ currentAvailableLevelInfo: %d %d %d", currentAvailableLevelInfoIndex, [sortedAvailableLevelsInfo count] - 1, lb);
	if (!lb) {
		[self prevAvailableLevelInfo];
		li = [sortedAvailableLevelsInfo objectAtIndex:currentAvailableLevelInfoIndex];
	}
	return li;
}

-(void) prevAvailableLevelInfo
{
	currentAvailableLevelInfoIndex--;
	if (currentAvailableLevelInfoIndex < 0) currentAvailableLevelInfoIndex = [sortedAvailableLevelsInfo count] - 1;
	KKLOG (@"++++++ currentAvailableLevelInfo: %d %d", currentAvailableLevelInfoIndex, [sortedAvailableLevelsInfo count] - 1);
	
	NSDictionary *li = [self currentAvailableLevelInfo];
	if (![self levelAvailable:[[li objectForKey:@"index"] intValue]]) [self prevAvailableLevelInfo];
}

-(void) nextAvailableLevelInfo
{
	currentAvailableLevelInfoIndex++;
	if (currentAvailableLevelInfoIndex >= [sortedAvailableLevelsInfo count]) currentAvailableLevelInfoIndex = 0;
	KKLOG (@"++++++ currentAvailableLevelInfo: %d %d", currentAvailableLevelInfoIndex, [sortedAvailableLevelsInfo count] - 1);
	NSDictionary *li = [self currentAvailableLevelInfo];
	if (![self levelAvailable:[[li objectForKey:@"index"] intValue]]) [self nextAvailableLevelInfo];
}

-(NSMutableDictionary *) currentLevelInfo
{
	NSMutableDictionary *li = [sortedAvailableLevelsInfo objectAtIndex:currentAvailableLevelInfoIndex];
	return li;
}

-(void) prevLevelInfo
{
	currentAvailableLevelInfoIndex--;
	if (currentAvailableLevelInfoIndex < 0) currentAvailableLevelInfoIndex = [sortedAvailableLevelsInfo count] - 1;
	KKLOG (@"++++++ currentAvailableLevelInfo: %d %d", currentAvailableLevelInfoIndex, [sortedAvailableLevelsInfo count] - 1);
	NSDictionary *li = [self currentLevelInfo];
	if ([[li objectForKey:@"index"] intValue] < 0) [self prevLevelInfo];
}

-(void) nextLevelInfo
{
	currentAvailableLevelInfoIndex++;
	if (currentAvailableLevelInfoIndex >= [sortedAvailableLevelsInfo count]) currentAvailableLevelInfoIndex = 0;
	KKLOG (@"++++++ currentAvailableLevelInfo: %d %d", currentAvailableLevelInfoIndex, [sortedAvailableLevelsInfo count] - 1);
	NSDictionary *li = [self currentLevelInfo];
	if ([[li objectForKey:@"index"] intValue] < 0) [self nextLevelInfo];
}

-(NSString *) levelNameFromIndex:(int)idx
{
	for (NSMutableDictionary *li in sortedAvailableLevelsInfo) {
		if ([[li objectForKey:@"index"] intValue] == idx)
			return [li objectForKey:@"name"];
	}
	return nil;
}

-(int) levelIndexFromName:(NSString *)name
{
	for (NSMutableDictionary *li in sortedAvailableLevelsInfo) {
		if ([[li objectForKey:@"name"] isEqualToString:name])
			return [[li objectForKey:@"index"] intValue];
	}
	return -1000;
}

#pragma mark -
#pragma mark Level Data Preload

#define PRELOAD_LEVEL_COUNT 0.2 
#define PRELOAD_SCRIPTS_COUNT 0.2 
#define PRELOAD_GFX_COUNT 0.2
#define PRELOAD_SOUND_COUNT 0.2
#define PRELOAD_MUSIC_COUNT 0.2

#define performLoadProgressAddWithMessage(__V__,__M__) [self performSelectorOnMainThread:@selector(loadProgressAddWithMessage:) withObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:__V__],__M__, nil] waitUntilDone:YES];
#define performLoadProgressEndWithMessage(__M__) [self performSelectorOnMainThread:@selector(loadProgressEndWithMessage:) withObject:__M__ waitUntilDone:YES];

-(void) loadProgressAddWithMessage:(NSArray *)d
{
	[hud loadProgressAdd:[[d objectAtIndex:0] floatValue] withMessage:[d objectAtIndex:1]];
}

-(void) loadProgressEndWithMessage:(NSString *)d
{
	[hud loadProgressEndWithMessage:d];
}

-(void) preloadLevelGraphics:(KKLevelLoadOperation *)operation
{
	NSArray *spritesheets = [levelData objectForKey:@"graphicsSpritesheets"];
	
	if (spritesheets && [spritesheets count]) {
		if ([operation isCancelled]) return;
	}
	performLoadProgressAddWithMessage (PRELOAD_GFX_COUNT, @"Finished loading art");
}

#define isAudioKey(__K__) (__K__ && ![__K__ isEqualToString:@""] && [__K__ hasPrefix:@"audio"] && [__K__ hasSuffix:@"Sound"])

-(void) preloadLevelSounds:(KKLevelLoadOperation *)operation
{
	NSMutableArray *sounds = [NSMutableArray arrayWithCapacity:10];
	
	// level
	for (NSString *k in levelData) {
		if (isAudioKey(k)) {
			NSString *f = [levelData objectForKey:k];
			if (![sounds containsObject:f]) [sounds addObject:f];
		}
	}
	
	// screens
	for (NSDictionary *d in [levelData objectForKey:@"screens"]) {
		for (NSString *k in d) {
			if (isAudioKey(k)) {
				NSString *f = [d objectForKey:k];
				if (![sounds containsObject:f]) [sounds addObject:f];
			}
		}
	}
	
	// paddles
	for (NSDictionary *d in [levelData objectForKey:@"paddles"]) {
		for (NSString *k in d) {
			if (isAudioKey(k)) {
				NSString *f = [d objectForKey:k];
				if (![sounds containsObject:f]) [sounds addObject:f];
			}
		}
	}
	
	NSArray *ps = [levelData objectForKey:@"audioSoundsToPreload"];
	if (ps) {
		for (NSString *i in ps) [sounds addObject:i];
	}
	
	[self extendSoundsArrayWithStandardSounds:sounds];
	
	NSMutableArray *soundsWithPath = [NSMutableArray arrayWithCapacity:[sounds count]];
	
	for (NSString *filename in sounds) {
		if (!filename || [filename isEqualToString:@""]) continue;
		[soundsWithPath addObject:[self pathForLevelSound:filename]];
	}
	
	int c = [soundsWithPath count];
	float s = PRELOAD_SOUND_COUNT / (c + 1);
	
	[soundManager cleanupSounds:soundsWithPath];
	
	int i = 1;
	for (NSString *filename in soundsWithPath) {
		if ([operation isCancelled]) break;
		
		NSString *m = [NSString stringWithFormat:@"Loading sound %d/%d", i, c];
		performLoadProgressAddWithMessage (s, m);
		[soundManager preloadSoundEffect:filename];
		i++;
	}
	performLoadProgressAddWithMessage (s, @"Finished loading sounds");
}

-(void) preloadLevelBackgroundMusic:(KKLevelLoadOperation *)operation
{
	NSString *filename = nil;
	NSString *firstScreen = [levelData objectForKey:@"firstScreen"];
	
	for (NSDictionary *d in [levelData objectForKey:@"screens"]) {
		if ([firstScreen isEqualToString:[d objectForKey:@"name"]]) {
			filename = [d objectForKey:@"audioBackgroundMusic"];
			break;
		}
	}	
	
	if (!filename || [filename isEqualToString:@""])
		filename = [levelData objectForKey:@"audioBackgroundMusic"];
	
	performLoadProgressAddWithMessage (PRELOAD_MUSIC_COUNT/2, @"Loading music");
	[self loadBackgroundMusic:filename];
	performLoadProgressAddWithMessage (PRELOAD_MUSIC_COUNT/2 , @"Finished loading music");
}

#pragma mark -
#pragma mark Level Start

-(void) startLevelAudio
{
	if (!(level.flags & kLevelFlagDoNotStartBackgroundMusic))
		[self startBackgroundMusic:[level audioBackgroundMusic]];
	[self playSound:[level audioInSound]];
}

-(void) stopLevelAudio
{
	[self stopBackgroundMusic];
	[self playSound:[level audioOutSound]];
}

-(void) levelStartTimerTimout
{
	currentGameState = kGSInGame;
	[self startLevelAudio];
	[hud showPauseButton:YES];
}

-(void) cleanupCurrentLevel
{
	if (level) {
		[self fxReset];
		level.visible = NO;
		[level destroyLevel];
		[CURRENT_SCENE removeChild:level cleanup:YES];
		[level release];
		level = nil;
	}
}

-(void) setupCurrentLevel
{
	if (levelData) {
		level = [(KKLevel *)[KKLevel alloc] initWithData:levelData];
		level.visible = NO;
		previousScreen = nil;
		[level setupLevel];
		[level setScreen:[level firstScreen] shown:YES];
		[level setScreen:[level firstScreen] active:YES];
		[[level firstScreen] applyShown];
		[self resetScreenCheckpoint];
	}
}

-(void) startLevelLoadOperation:(id)target operation:(KKLevelLoadOperation *)operation
{
	[backgroundQueue addOperation:[operation autorelease]];
}

#pragma mark -
#pragma mark Life Management

-(void) checkLifeAchievements
{
	if (numPlayerHerosLeft >= 10) {
//		[KKOFM unlockAchievement:OFA_TEN_LIFES];
	}
}

-(void) addLife
{
	[self addLifeWithMessage:@"New Life"];
}

-(void) addLifeWithMessage:(NSString *)msg
{
	numPlayerHerosLeft += 1;
	[hud setHeroesLeft:numPlayerHerosLeft];
	[hud showTimerLabel:NSLocalizedString(msg, @"newLife") sound:SOUND_ADD_LIFE];
	
	[self checkLifeAchievements];
}

-(void) removeLife
{
	[self removeLifeWithMessage:@"Failed"];
}

-(void) removeLifeWithMessage:(NSString *)msg
{
#ifndef KK_DEBUG
	if (!unlimitedLifes)
		numPlayerHerosLeft -= 1;
#endif	
	[hud setHeroesLeft:numPlayerHerosLeft];
	
	[hud showTimerLabel:NSLocalizedString(msg, @"removeLife") sound:SOUND_REMOVE_LIFE];
}

-(void) die:(tDie)mode
{
	[self die:mode withMessage:@"Failed"];
}

-(void) die:(tDie)mode withMessage:(NSString *)msg
{
	[hud showPauseButton:NO];
	[self stopBackgroundMusic];
	
	[self removeLifeWithMessage:msg];
	
	if (numPlayerHerosLeft <= 0) {
		KKLOG (@"setIdleTimerDisabled: %d", NO);
		[[UIApplication sharedApplication] setIdleTimerDisabled:NO];

		currentGameState = kGSGameOver;
		level.visible = NO;
		
		KKScreen *screen = [level currentScreen];
		[level setScreen:screen shown:NO];
		[level setScreen:screen active:NO];
		[screen applyShown];
		[screen onExit];
		
		[self computeFinalScore];
		
		// set TOP QUESTS score if in quest mode
		if (self.isFullQuest) {
//			[KKOFM setHighScore:score forLeaderboard:OFL_TOP_QUESTS];
		}
		
		[hud showGameOverPanel];
	} else {
		currentGameState = kGSGameStart;
		
		switch (mode) {
			case kDieTimeout:
				[hud showDiedByTimeoutPanel];
				
				levelTimeLeft = [self getAvailableTime];
				[hud setTimeLeft:levelTimeLeft];
				updateLevelTimeLeft = YES;
				
				break;
			case kDieKilled:
				[hud showDiedByKillPanel];
				break;
		}
		
		// move player to last checkpoint
		level.mainHero.speed = checkpointScreenSpeed;
		[self moveMainHeroToScreen:checkpointScreen atPosition:checkpointScreenPosition];
		
		previousScreen = nil;
		
		[KKLM execString:@"level:onDie ()"];
	}
}

-(void) questEnd
{
	[hud showPauseButton:NO];
	[self stopBackgroundMusic];
	
	currentGameState = kGSGameOver;
	level.visible = NO;
	
	KKScreen *screen = [level currentScreen];
	[level setScreen:screen shown:NO];
	[level setScreen:screen active:NO];
	[screen applyShown];
	[screen onExit];
	
	[self computeFinalScore];
	
	// set TOP QUESTS score if in quest mode
	if (self.isFullQuest) {
//		[KKOFM setHighScore:score forLeaderboard:OFL_TOP_QUESTS];
	}
	
	[hud showGameEndPanel];
}

#define MISSION_FULL_QUEST @"fullQuest"

-(BOOL) isFullQuest
{
	return isFullQuest || forceFullQuestMode;
}

-(BOOL) isFullQuestCompleted
{
	return [self globalMission:MISSION_FULL_QUEST boolField:@"completed"] || forceFullQuestCompleted;
}

-(void) setFullQuestCompleted:(BOOL)v
{
	[self setGlobalMission:MISSION_FULL_QUEST field:@"completed" toBool:v];
}

#pragma mark -
#pragma mark Level Checkpoints

-(void) resetScreenCheckpoint
{
	[self setScreenCheckpoint:[level firstScreen] data:level.data];
}

-(void) setScreenCheckpoint:(KKScreen *)screen data:(NSDictionary *)data
{
	checkpointScreen = screen;
	checkpointScreenPosition = SCALE_POINT (ccp (
												 DICT_FLOAT (data, @"heroStartPositionX", 50),
												 DICT_FLOAT (data, @"heroStartPositionY", 180)
												 )
											);
	
	checkpointScreenSpeed = SCALE_POINT (ccp (
											 DICT_FLOAT (data, @"heroStartSpeedX", 10),
											 DICT_FLOAT (data, @"heroStartSpeedY", 10)
											 )
										);
}

#pragma mark -
#pragma mark Level Load

-(id) loadLevelOperation:(NSArray *)args
{
	KKLevelLoadOperation *operation = [args objectAtIndex:0];
	NSString *levelDir = [args objectAtIndex:1];

	BOOL loaded = NO;
	NSString *errorDesc = nil;
	NSPropertyListFormat plistFormat;
	NSString *plistPath = [self pathForLevelDefinition:levelDir];
	NSData *plistData = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	
	if (levelName) [levelName release], levelName = nil;
	if (levelData) [levelData release], levelData = nil;
	
	previousScreen = nil;
	
	hud.isTimeNotificationEnabled = YES;
	
	performLoadProgressAddWithMessage (PRELOAD_LEVEL_COUNT/2, @"Loading table definition");
	levelData = (NSMutableDictionary *)[NSPropertyListSerialization
								 propertyListFromData:plistData 
								 mutabilityOption:NSPropertyListMutableContainersAndLeaves 
								 format:&plistFormat
								 errorDescription:&errorDesc
								 ];
	performLoadProgressAddWithMessage (PRELOAD_LEVEL_COUNT/2, @"Finished loading definition");
	
	if (!levelData) {
		KKLOG (@"'%@' error:%@", levelDir, errorDesc);
		[errorDesc release];
		levelData = nil;
	} else {
		if (![operation isCancelled]) {
			levelName = [levelDir copy];
			[levelData retain];
			
			performLoadProgressAddWithMessage (PRELOAD_LEVEL_COUNT/2, @"Loading some intelligence");
			[self loadLevelScripts];
			performLoadProgressAddWithMessage (PRELOAD_LEVEL_COUNT/2, @"Little intelligence loaded");
			
			[self preloadLevelBackgroundMusic:operation];
			[self preloadLevelSounds:operation];
			[self preloadLevelGraphics:operation];
			
			//FIXME: on cancel should release all resouces
			if (![operation isCancelled]) {
				loaded = YES;
				KKLOG (@"'%@'", levelName);
			}
		} else {
			levelData = nil;
		}
	}
	
	if (loaded) {
		[self setupCurrentLevel];
		performLoadProgressEndWithMessage ([self randomMessage]);
	} else {
		performLoadProgressEndWithMessage (@"Table load cancelled");
	}
	
	return (id) [NSNumber numberWithBool:loaded];
}

-(void) startLevel:(NSString *)name withAudio:(BOOL)audio withStartTimer:(float)seconds
{
	currentGameState = kGSLoading;
	
	hud = GET_SHARED_OBJECT(@"hudLayer");
	[hud destroyAllMessages];
	[hud showPauseButton:NO];
	[hud showLoadProgress:YES withMessage:@"Loading world"];
	
	[self stopLevelAudio];
	[self cleanupCurrentLevel];
	
	KKLevelLoadOperation *levelLoadOperation = [[KKLevelLoadOperation  alloc] initWithLevelDir:name 
																					 startAudio:audio 
																					 startTimer:seconds
												 ];
	CCAction *a = [CCSequence actions:
				   [CCDelayTime actionWithDuration:MUSIC_OUT_DURATION + 0.2],
				   [CCCallFuncND actionWithTarget:self selector:@selector(startLevelLoadOperation:operation:) data:levelLoadOperation],
				   nil
				   ];
	[CURRENT_SCENE runAction:a];
	
	KKLOG (@"setIdleTimerDisabled: %d", YES);
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

-(void) startLevel:(NSString *)name withStartTimer:(float)seconds
{
	[self startLevel:name withAudio:NO withStartTimer:seconds];
}

-(void) startLevel:(NSString *)name andAudio:(BOOL)audio
{
	[self startLevel:name withAudio:YES withStartTimer:0];
}

-(void) startLevel:(NSString *)name
{
	[self startLevel:name withAudio:NO withStartTimer:LEVEL_START_TIMEOUT];
}

-(void) startLevelCallback:(id)target name:(NSString *)name
{
	KKLOG (@"%@", name);
	[self startLevel:[name autorelease] withAudio:NO withStartTimer:LEVEL_START_TIMEOUT];
}

-(void) startLevel:(NSString *)name withTimeout:(float)timeout
{
	KKLOG (@"%@ %f", name, timeout);
	CCAction *a = [CCSequence actions:
				   [CCDelayTime actionWithDuration:timeout],
				   [CCCallFuncND actionWithTarget:self selector:@selector(startLevelCallback:name:) data:[name copy]],
				   nil
				   ];
	[CURRENT_SCENE runAction:a];
}

-(void) levelLoaded:(NSArray *)result
{
	BOOL ib = ![level.name isEqualToString:LEVEL_MAIN_MENU];
	KKLOG (@"setIdleTimerDisabled: %d", ib);
	[[UIApplication sharedApplication] setIdleTimerDisabled:ib];
	
	BOOL loaded = [[result objectAtIndex:0] boolValue];
	BOOL audio = [[result objectAtIndex:1] boolValue];
	float seconds = [[result objectAtIndex:2] floatValue];

	if (loaded) {
		level.visible = YES;
		[CURRENT_SCENE addChild:level z:0];		
		
		// level game config
		levelTimeSuspended = NO;
		levelTimeElapsed = 0;
		levelTimeLeft = [self getAvailableTime];
		updateLevelTimeLeft = levelTimeLeft > 0;
		
		previousLevelScore = score;
		currentLevelScore = 0;
		
		if (audio) [self startLevelAudio];
		
		BOOL sh = level.flags & kLevelFlagShowHUD;
		[self showHUD:sh];
		
		[level.mainHero pause:NO];
		
		if (seconds) {
			currentGameState = kGSGameStart;
			[hud showPauseButton:NO];
			[hud showStartTimer:seconds target:self selector:@selector(levelStartTimerTimout)];
		} else {
			currentGameState = kGSInGame;
		}
	}
	
	[hud showLoadProgress:NO withMessage:@""];
}

-(void) setCurrentScreen:(KKScreen *)screen prevScreen:(KKScreen *)prev
{
	if (prev) {
		if (prev.audioSoundLoopID != CD_NO_SOURCE) {
			[self stopSound:prev.audioSoundLoopID];
			prev.audioSoundLoopID = CD_NO_SOURCE;
		}
		[self playSound:[prev audioOutSound]];
	}
	if (screen) {
		[self playSound:[screen audioInSound]];
		screen.audioSoundLoopID = [self playSoundLoop:[screen audioSoundLoop]];
		[self startBackgroundMusic:[screen audioBackgroundMusic]];
		
		if (hudShown) {
			[self showHUDMove];
		}
		
		if (screen.isCheckpoint && screen != checkpointScreen) {
			[hud showTimerLabel:NSLocalizedString (@"Checkpoint!", @"checkpoint") sound:SOUND_CHECKPOINT];
			[self setScreenCheckpoint:screen data:screen.data];
			level.mainHero.acceleration = ccp (0, 0);
		}
	}
}

#pragma mark -
#pragma mark Sound

-(void) startBackgroundMusicCallback:(id)target filename:(NSString *)filename
{
	[soundManager startBackgroundMusic:[self pathForLevelMusic:filename] loop:YES];
	[filename release];
}

-(void) startBackgroundMusicNoLoopCallback:(id)target filename:(NSString *)filename
{
	[soundManager startBackgroundMusic:[self pathForLevelMusic:filename] loop:NO];
	[filename release];
}

-(void) stopBackgroundMusicCallback
{
	[soundManager stopBackgroundMusic];
}

-(void) loadBackgroundMusic:(NSString *)filename
{
	if (filename && ![filename isEqualToString:@""]) {
		[soundManager loadBackgroundMusic:[self pathForLevelMusic:filename]];
	}
}

-(void) startBackgroundMusic:(NSString *)filename selector:(SEL)sel
{
	if (filename && ![filename isEqualToString:@""]) {
		CCAction *a = [CCSequence actions:
					   [KKFadeMusicTo actionWithDuration:MUSIC_OUT_DURATION volume:0],
					   [CCCallFunc actionWithTarget:self selector:@selector(stopBackgroundMusicCallback)],
					   [CCCallFuncND actionWithTarget:self selector:sel data:[filename copy]],
					   [KKFadeMusicTo actionWithDuration:MUSIC_IN_DURATION volume:[soundManager defaultMusicVolume]],
					   nil
					   ];
		a.tag = kGEActionBackgroundMusic;
		[CURRENT_SCENE stopActionByTag:kGEActionBackgroundMusic];
		[CURRENT_SCENE runAction:a];
	}
}

-(void) startBackgroundMusic:(NSString *)filename
{
	[self startBackgroundMusic:filename selector:@selector(startBackgroundMusicCallback:filename:)];
}
	 
-(void) startBackgroundMusicNoLoop:(NSString *)filename
{
	[self startBackgroundMusic:filename selector:@selector(startBackgroundMusicNoLoopCallback:filename:)];
}
		 
-(void) stopBackgroundMusic
{
	if ([soundManager isBackgroundMusicPlaying]) {
		CCAction *a = [CCSequence actions:
					   [KKFadeMusicTo actionWithDuration:MUSIC_OUT_DURATION volume:0],
					   [CCCallFunc actionWithTarget:self selector:@selector(stopBackgroundMusicCallback)],
					   nil
					   ];
		a.tag = kGEActionBackgroundMusic;
		[CURRENT_SCENE stopActionByTag:kGEActionBackgroundMusic];
		[CURRENT_SCENE runAction:a];
	}
}

-(void) extendSoundsArrayWithStandardSounds:(NSMutableArray *)sounds
{
	NSArray *standardSounds = [NSArray arrayWithObjects:
							   SOUND_LOAD_PROGRESS_LOOP,
							   SOUND_TIMER_TICK_1,
							   SOUND_TIMER_TICK_2,
							   SOUND_TIMER_TICK_3,
							   SOUND_BUTTON_ACTIVATE,
							   SOUND_PADDLE_HIT_1,
							   SOUND_PADDLE_HIT_2,
							   SOUND_LEVEL_TIMEOUT,
							   SOUND_PAUSE,
							   SOUND_ADD_LIFE,
							   SOUND_REMOVE_LIFE,
							   SOUND_CHECKPOINT,
							   SOUND_OF_ACHIEVEMENT_UNLOCKED,
							   SOUND_ADD_TIME,
							   SOUND_REMOVE_TIME,
							   nil
							   ];
	for (NSString *s in standardSounds) {
		if (![sounds containsObject:s]) {
			[sounds addObject:s];
		}
	}
}
	 
-(void) preloadSounds:(NSMutableArray *)sounds cleanup:(BOOL)cleanup target:(id)target selector:(SEL)selector
{
	if (cleanup)
		[self extendSoundsArrayWithStandardSounds:sounds];
	
	NSMutableArray *soundsWithPath = [NSMutableArray arrayWithCapacity:[sounds count]];
	
	for (NSString *filename in sounds) {
		if (!filename || [filename isEqualToString:@""]) continue;
		[soundsWithPath addObject:[self pathForLevelSound:filename]];
	}
	
	if (cleanup) [soundManager cleanupSounds:soundsWithPath];
	
	int i = 1;
	for (NSString *filename in soundsWithPath) {
		[soundManager preloadSoundEffect:filename];
		if (target) {
			[target performSelector:selector withObject:[NSNumber numberWithInt:i]];
		}
		i++;
	}
}

-(void) playSound:(NSString *)filename
{
	if (filename && ![filename isEqualToString:@""]) {
		[soundManager playSoundEffect:[self pathForLevelSound:filename] channelGroupId:kChannelGroupFX];
	}
}

-(void) playSound:(NSString *)filename withPan:(float)pan
{
	if (filename && ![filename isEqualToString:@""]) {
		[soundManager playSoundEffect:[self pathForLevelSound:filename] channelGroupId:kChannelGroupFX pan:pan loop:NO];
	}
}

-(GLuint) playSoundLoop:(NSString *)filename
{
	if (filename && ![filename isEqualToString:@""]) {
		return [soundManager playSoundEffect:[self pathForLevelSound:filename] channelGroupId:kChannelGroupNonInterruptible loop:YES];
	}
	return CD_NO_SOURCE;
}

-(void) playSound:(NSString *)filename forPaddle:(KKPaddle *)paddle
{
	if (filename && ![filename isEqualToString:@""]) {
		float pan = ((2.0/level.currentScreen.size.width) * (paddle.center.x - level.currentScreen.position.x)) - 1;
		[soundManager playSoundEffect:[self pathForLevelSound:filename] channelGroupId:kChannelGroupFX pan:pan loop:NO];
	}	
}

-(GLuint) playSoundLoop:(NSString *)filename forPaddle:(KKPaddle *)paddle
{
	if (filename && ![filename isEqualToString:@""]) {
		float pan = ((2.0/level.currentScreen.size.width) * (paddle.center.x - level.currentScreen.position.x)) - 1;
		return [soundManager playSoundEffect:[self pathForLevelSound:filename] channelGroupId:kChannelGroupNonInterruptible pan:pan loop:YES];
	}	
	return CD_NO_SOURCE;
}

-(void) stopSound:(ALuint)sid
{
	[soundManager stopSoundEffect:sid];
}

-(void) stopAllSounds
{
	[soundManager stopAllSoundEffects];
}

#pragma mark -
#pragma mark HUD Management

-(void) showHUDMove
{
	BOOL smlr = [level getBoolForKey:@"accelerationInputX" withDefault:NO];
	BOOL smud = [level getBoolForKey:@"accelerationInputY" withDefault:NO];
	
	[hud showMoveLeftRight:hudShown && smlr];
	[hud showMoveUpDown:hudShown && smud];
}

-(void) showHUD:(BOOL)f
{
	hudShown = f;
	
	BOOL stl = [self getAvailableTime] > 0;
	BOOL shl = numPlayerHerosLeft > 0;
	BOOL stul = level.turboFactor != 0;
	
	[hud setTimeTotal:questTimeElapsed];
	if (levelTimeLeft) [hud setTimeLeft:levelTimeLeft];
	[hud setTurboLeft:(int) level.turboSecondsAvailable];
	[hud setHeroesLeft:numPlayerHerosLeft];
	[hud setScore:score];
	
	[hud showTimeTotal:f];
	[hud showTimeLeft:f && stl];
	[hud showHeroesLeft:f && shl];
	[hud showScore:f];
	[hud showTurboLeft:f && stul];
	[hud showPauseButton:f];

	[self showHUDMove];
}

#pragma mark -
#pragma mark Score

-(void) checkScoreAchievements
{
	if (score >= 1000000) {
//		[KKOFM unlockAchievement:OFA_MILLION_POINTS_SQUARE];
	}
}

-(void) scoreAdd:(int)p
{
	if (level && [self isMainMenu]) return;
	
	int i = p * scoreMultiplier;

	score += i;
	currentLevelScore += i;

	scoreForNewLife -= i;
	if (score && scoreForNewLife < 0) {
		while (scoreForNewLife < 0) {
			[self addLife];
			scoreForNewLife += NEW_LIFE_SCORE;
		}
		scoreForNewLife = NEW_LIFE_SCORE;
	}
	
	[hud setScore:score];
	
	[self checkScoreAchievements];
}

-(void) computeFinalScore
{
	int aScore = questExplorationPoints * EXPLORATION_POINT_TO_SCORE;
	if (questExplorationPoints == questTotalExplorationPoints)
		aScore += FULL_EXPLORATION_SCORE;
	
	aScore += LIFES_LEFT_SCORE * numPlayerHerosLeft;
	
	[self scoreAdd:aScore];
}

#pragma mark -
#pragma mark Time

-(void) timeAdd:(float)p
{
	levelTimeLeft += p;
	[hud setTimeLeft:levelTimeLeft];
	
	if (p > 0) {
		[hud showZoomingText:NSLocalizedString(@"More Time!", @"timeAdd") sound:SOUND_ADD_TIME];
	} else if (p < 0) {
		[hud showZoomingText:NSLocalizedString(@"Less Time!", @"timeRemove") sound:SOUND_REMOVE_TIME];
	}

}

#pragma mark -
#pragma mark Exploration Points

-(void) checkExplorationAchievements
{
	if (questExplorationPoints == questTotalExplorationPoints) {
//		[KKOFM unlockAchievement:OFA_THE_GREAT_EXPLORER];
	}
}

-(void) explorationPointsAdd:(int)p
{
	questExplorationPoints += p;
	
	[self checkExplorationAchievements];
}

#pragma mark -
#pragma mark Time deltas

-(void) resetStartDate
{
	if (startDate) [startDate release];
	startDate = [[NSDate date] retain];
}

-(float) timeDeltaFromStartDate
{
	return [startDate timeIntervalSinceNow];
}

#pragma mark -
#pragma mark Pause management

-(void) setPaused:(BOOL)f
{
	if (paused == f) return;
	
	paused = f;
	
	KKLOG (@"setIdleTimerDisabled: %d", !f);
	[[UIApplication sharedApplication] setIdleTimerDisabled:!f];
}

#pragma mark -
#pragma mark Commands

-(void) onPause {
	[self onPausePlaySound:YES];
}

-(void) onPausePlaySound:(BOOL)ps
{
	if (paused) return;
	
	self.paused = YES;
	
	previousGameState = currentGameState;
	
	if (currentGameState == kGSInGame) currentGameState = kGSInGamePause;
	else currentGameState = kGSPause;
	
	wasBackgroundMusicPlaying = [soundManager isBackgroundMusicPlaying];
	if (wasBackgroundMusicPlaying)
		[soundManager pauseBackgroundMusic];

	if (ps) pauseSoundLoopId = [self playSoundLoop:SOUND_PAUSE]; 
	else pauseSoundLoopId = CD_NO_SOURCE;
}

-(void) onResume
{
	if (!paused) return;
	
	currentGameState = previousGameState;
	previousGameState = kGSNone;
	
	self.paused = NO;
	
	[self stopSound:pauseSoundLoopId];
	
	if (wasBackgroundMusicPlaying)
		[soundManager resumeBackgroundMusic];
}

-(void) onQuit
{
	[hud destroyAllMessages];
	
	currentGameState = previousGameState;
	previousGameState = kGSNone;
	
	self.paused = NO;
	
	if (pauseSoundLoopId != CD_NO_SOURCE)
		[self stopSound:pauseSoundLoopId];

//	if (![self isMainMenu])
//		[KKPM removeGame];
	[self resetGame];
	
	KKLOG (@"setIdleTimerDisabled: %d", NO);
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	[self startLevel:LEVEL_MAIN_MENU andAudio:YES];
}

#pragma mark -
#pragma mark Update

#define UI_UPDATE_TIMEOUT 1

-(void) levelTimeLeftTimeout
{
	[self playSound:SOUND_LEVEL_TIMEOUT];
	updateLevelTimeLeft = NO;
	
	[KKLM execString:@"level:onTimeLeftTimeout ()"];
//	[self die:kDieTimeout];
}

-(void) updateTimers:(ccTime)dt
{
	static float uit = UI_UPDATE_TIMEOUT;
	BOOL uif = NO;
	
	if (!levelTimeSuspended) {
		uit += dt;
		if (uit >= UI_UPDATE_TIMEOUT) {
			uit = 0;
			uif = YES;
		}
		
		levelTimeElapsed += dt; // how much time the player is playing into the current level
		questTimeElapsed += dt;
		
		if (uif) {
			[hud setTimeTotal:questTimeElapsed];
		}
		
		if (updateLevelTimeLeft) {
			if (!levelTimeLeftSuspended) {
				levelTimeLeft -= dt; // how much time is left to complete the level (can be +/- by bonuses)
				if (uif) {
					[hud setTimeLeft:levelTimeLeft];
					
					if (levelTimeLeft <= 0.1) [self levelTimeLeftTimeout];
				}
			} else {
				if (levelTimeLeftSuspendedTimout) {
					// time left till the suspension is enabled. -1 is forever
					levelTimeLeftSuspendedTimout -= dt;
					if (levelTimeLeftSuspendedTimout <= 0) {
						levelTimeLeftSuspendedTimout = 0;
						levelTimeLeftSuspended = NO;
					}
				}
			}
		}
	}
}

-(void) enableUpdate
{
	flags ^= kGEFlagUpdateDisabled;
}

-(void) disableUpdate
{
	flags |= kGEFlagUpdateDisabled;
}

#pragma mark Paddles

-(void) updatePaddles:(ccTime)dt
{
	// update paddles
	for (NSNumber *i in level.paddlesArray) {
		KKPaddle *paddle = [level paddleAtIndex:[i intValue]];
		
		if (![paddle enabled]) continue;
		
		if (paddle.flags & kPaddleFlagScriptUpdate) {
			paddleUpdate(paddle.index, dt);
		} else {
			[paddle updatePositionWithSpeedAndAcceleration:dt];
		} 
	}
}

-(void) updatePaddlesAI:(ccTime)dt
{
	// update paddles AI
	for (NSNumber *i in level.paddlesArray) {
		KKPaddle *paddle = [level paddleAtIndex:[i intValue]];
		if (![paddle enabled]) continue;
		
		if ([paddle isOffensiveSide] && paddle.offensiveAIKind) {
			switch (paddle.offensiveAIKind) {
				case kAIKindScript:
					paddleUpdateAI(paddle.index, dt);
					break;
				case kAIKindClass:
					[paddle.offensiveAI update:dt];
					break;
			}
		} else {
			switch (paddle.defensiveAIKind) {
				case kAIKindScript:
					paddleUpdateAI(paddle.index, dt);
					break;
				case kAIKindClass:
					[paddle.defensiveAI update:dt];
					break;
			}
		}
	}
}

#pragma mark Hero

#define GRAVITY_FACTOR 20

-(CGPoint) applyAccelerationTurbo:(CGPoint)acc dt:(ccTime)dt
{
	if (level.turboSecondsAvailable > 0 && level.turboFactor) {
		level.wasTurboUsed = YES;
		level.turboSecondsAvailable -= dt;
		if (level.turboSecondsAvailable < 0) level.turboSecondsAvailable = 0;
		[hud setTurboLeft:(int)ceil (level.turboSecondsAvailable)];
		
		return ccpMult (acc, level.turboFactor);
	} else {
		return acc;
	}
}

/*
#define SLOWDOWN 20
-(CGPoint) nullAcceleration:(CGPoint)acc dt:(ccTime)dt
{
	float sx = PSign (acc.x);
	float sy = PSign (acc.y);
	float ax = ABS (acc.x);
	float ay = ABS (acc.y);
	
	if (ax > 0) {
		ax = ax - (SLOWDOWN * dt);
		if (ax < 0) ax = 0;
	}
	if (ay > 0) {
		ay = ay - (SLOWDOWN * dt);
		if (ay < 0) ay = 0;
	}
	return ccp (sx * ax,  sy * ay);
}
*/

-(CGPoint) inputAcceleration:(ccTime)dt
{
	KKHero *hero = [level mainHero];
	
	float ax = 0;
	float ay = 0;
	
	int lam = level.accelerationMode;
	CGPoint la = level.acceleration;
	CGPoint laMin = level.accelerationMin;
	CGPoint laMax = level.accelerationMax;
	CGPoint laFactor = level.accelerationFactor;
	CGPoint laViscosity = level.accelerationViscosity;
	CGPoint hs = hero.speed;
	CGPoint acc;
	
	if (level.accelerationInputX) {
		ax = Clamp (la.x, laMin.x, laMax.x) * dt * laFactor.x;
		if (ax) {
			float accDirX = PSign (hs.x) * -1;
			float newDirX = PSign (ax);
			if (accDirX == newDirX) {
				ax = (ABS (ax) + laViscosity.x) * PSign (ax);
			}
		}
		//				KKLOG (@"X:o=%f m=%f M=%f a:%f (dt=%f, f:%f) s:%f", la.x, laMin.x, laMax.x, ax, dt, laFactor.x, hs.x);
		if (fxAccelerationIncrementX) {
			ax = fxAccelerationIncrementX * ax;
		}
		if (fxInvertAccelerationX) {
			ax = -1 * ax;
		}
		if (fxBlockedSideMovements & kSideLeft && ax < 0) ax = 0;
		if (fxBlockedSideMovements & kSideRight && ax > 0) ax = 0;
	}
	
	if (level.accelerationInputY) {
		ay = Clamp (la.y, laMin.y, laMax.y) * dt * laFactor.y;
		if (ay) {
			float accDirY = PSign (hs.y) * -1;
			float newDirY = PSign (ay);
			if (accDirY == newDirY) {
				ay = (ABS (ay) + laViscosity.y) * PSign (ay);
			}
		}
		if (fxAccelerationIncrementY) {
			ay = fxAccelerationIncrementY * ay;
		}
		if (fxInvertAccelerationY) {
			ay = -1 * ay;
		}
		if (fxBlockedSideMovements & kSideBottom && ay < 0) ay = 0;
		if (fxBlockedSideMovements & kSideTop && ay > 0) ay = 0;
	}
	
	acc = ccp (ax, ay);
	
	if (lam == kAccelerationTurbo) {
		acc = [self applyAccelerationTurbo:acc dt:dt];
	}
	
	return acc;
}

-(void) difficultyLevelUpdateMainHero:(ccTime)dt
{
	KKHero *hero = [level mainHero];
	CGPoint acc = [self inputAcceleration:dt];
	
	hero.acceleration = acc;
	if (difficultyLevel == kDifficultyLow) {
//		switch (inputMode) {
//			case kInputModeSlide:
				hero.speed = limitSpeed (ccpAdd (hero.speed, ccpMult(acc, level.joystickAccelerationFactor)), level);
//				break;
//			case kInputModeJoystick:
//				hero.speed = limitSpeed (ccpAdd (hero.speed, ccpMult(acc, level.joystickAccelerationFactor)), level);
//				break;
//		}
	}
}

-(void) inputModeSlideUpdateMainHero:(ccTime)dt
{
	KKHero *hero = [level mainHero];
	
	hero.acceleration = CGPointZero;
	int lam = level.accelerationMode;
	if (lam != kAccelerationUnknown)
		[self difficultyLevelUpdateMainHero:dt];
}

#define JOYSTICK_FACTOR_NORMAL 0.6
#define JOYSTICK_FACTOR_GRAVITY 0.9
#define JOYSTICK_ACC_X 260
#define JOYSTICK_ACC_Y 260

#define SMOOTH_MIN 0.9
#define SMOOTH_VAL 0.1

#define JOY_SMOOTH(__P__) ccp(PSign(__P__.x) * (ABS(__P__.x) < SMOOTH_MIN? SMOOTH_VAL : ABS(__P__.x)), PSign(__P__.y) * (ABS(__P__.y) < SMOOTH_MIN? SMOOTH_VAL : ABS(__P__.y)))

-(void) inputModeJoystickUpdateMainHero:(ccTime)dt
{
	KKHero *hero = [level mainHero];
	
	hero.acceleration = CGPointZero;
	int lam = level.accelerationMode;
	if (lam != kAccelerationUnknown) {
//		CGPoint joyVelocity = JOY_SMOOTH([[[KKIM inputLayer] joystick] velocity]);
		CGPoint joyVelocity = [[[KKIM inputLayer] joystick] velocity];
		CGPoint accFactor = ccp (
								 (level.gravity.x == 0 ? JOYSTICK_FACTOR_NORMAL : JOYSTICK_FACTOR_GRAVITY),
								 (level.gravity.y == 0 ? JOYSTICK_FACTOR_NORMAL : JOYSTICK_FACTOR_GRAVITY)
		);
		level.acceleration = ccpCompMult(joyVelocity, ccpCompMult(ccp(JOYSTICK_ACC_X, JOYSTICK_ACC_Y), accFactor));

		[self difficultyLevelUpdateMainHero:dt];
	}
}

-(void) updateMainHeroWithPlayerInput:(ccTime)dt
{
	KKHero *hero = [level mainHero];
	
	if (hero) {
		if (hero.flags & kHeroFlagScriptUpdateWithPlayerInput) {
			screenUpdateMainHeroWithPlayerInput(dt);
		} else {
			switch (inputMode) {
				case kInputModeSlide:
					[self inputModeSlideUpdateMainHero:dt];
					break;
				case kInputModeJoystick:
					[self inputModeJoystickUpdateMainHero:dt];
					break;
			}
		}
	}
}

-(int) updateHero:(KKHero *)hero screenBorderCollision:(KKScreen *)screen dt:(ccTime)dt
{
	int exitSide = kSideNone;
	int collisionSide = checkCollisionRectWithContainerRect (hero.bbox, screen.bbox);
	
	if (collisionSide != kSideNone) {
		screenOnHeroHitBorders(hero.index, collisionSide);
		exitSide = [luaManager getGlobalInteger:@"exitSide"];
		
		if (exitSide == kSideNone) {
			float pan = 0;
			NSString *side = nil;
			switch (collisionSide) {
				case kSideLeft:
					side = @"audioSideLeftSound";
					pan = -1;
					break;
				case kSideRight:
					side = @"audioSideRightSound";
					pan = 1;
					break;
				case kSideTop:
					side = @"audioSideTopSound";
					break;
				case kSideBottom:
					side = @"audioSideBottomSound";
					break;
			}
			NSString *snd = [level getStringForKey:[side retain] withDefault:@""];
			[side release];
			[self playSound:snd withPan:pan];
			
			[self scoreAdd:screen.scorePerBorderHit];
		}
	}
	return exitSide;
}

-(void) updateHero:(KKHero *)hero paddleCollision:(KKPaddle *)paddle dt:(ccTime)dt
{
	int collisionSide = kSideNone;
	
	if (!(paddle.flags & kPaddleFlagCollisionDisabled)) {
		CGPoint collisionPoint;
		collisionSide = [paddle checkCollisionWithRect:hero.bbox speed:hero.speed collisionPoint:&collisionPoint dt:dt];
	
		if (collisionSide != kSideNone) {
			paddleOnHit(paddle.index, hero.index, collisionSide, collisionPoint);
			[self playSound:[paddle audioHitSound] forPaddle:paddle];
			[self scoreAdd:paddle.scorePerHit];
		}
	}
}

-(void) updateHeroCollisionWithPaddles:(KKHero *)hero screen:(KKScreen *)screen dt:(ccTime)dt
{
	for (NSNumber *i in [level.paddlesArray allObjects]) {
		KKPaddle *paddle = [level paddleAtIndex:[i intValue]];
		[self updateHero:hero paddleCollision:paddle dt:dt];
	}
}

-(void) updateHeroProximityWithPaddles:(KKHero *)hero screen:(KKScreen *)screen dt:(ccTime)dt
{
	for (NSNumber *i in level.paddlesArray) {
		KKPaddle *paddle = [level paddleAtIndex:[i intValue]];
		
		if (!paddle.enabled || paddle.proximityMode == kPaddleProximityNone) continue;
		
		if ([paddle isHeroInsideProximityArea:hero]) {
			if (paddle.flags & kPaddleFlagScriptOnHeroInProxymityArea)
				paddleOnHeroInProxymityArea(paddle.index, hero.index);
			[paddle applyProximityInfluenceToHero:hero dt:dt];
		}
	}
}

-(void) flipScreenPaddlesSide
{
	if (!previousScreen) return;
	
	for (int ppi = 0; ppi < previousScreen.numPaddles; ppi++) {
		KKPaddle *p = previousScreen.paddles[ppi];
		if ([p isGlobal]) continue;
		
		for (int cpi = 0; cpi < level.currentScreen.numPaddles; cpi++) {
			if (p == level.currentScreen.paddles[cpi]) {
				[p toggleSide];
				break;
			}
		}
	}
}

-(float) getAvailableTime
{
	float t;
	
	if (level.availableTime == 0) {
		t = level.currentScreen.availableTime;
	} else {
		t = level.availableTime;
	}
	return t;
}

-(void) setupScreenHUD
{
	if (level.availableTime == 0) {
		if (level.currentScreen.availableTime) {
			levelTimeLeft = level.currentScreen.availableTime;
			updateLevelTimeLeft = levelTimeLeft > 0;
			[hud setTimeLeft:levelTimeLeft];
			[hud showTimeLeft:updateLevelTimeLeft];
		} else {
			[hud showTimeLeft:NO];
			updateLevelTimeLeft = NO;
		}
	}
}

-(void) sendHero:(KKHero *)hero toScreen:(KKScreen *)screen exitSide:(int)exitSide
{
	if (exitSide != kSideNone) {
		KKScreen *nextScreen = [level findNextScreen:screen atSide:exitSide forHero:hero];
		
		if (!nextScreen) {
			KKLOG (@"%d toScreen:%d exitSide:%d", hero.index, screen.index, exitSide);
			return;
		}
		
		if (hero.isMainHero) {
			previousScreen = screen;
			[level setScreen:previousScreen shown:NO];
			[level setScreen:previousScreen active:NO];
			
			[level setScreen:nextScreen shown:YES];
			[level setScreen:nextScreen active:YES];
			
			[previousScreen applyShown];
			[nextScreen applyShown];
			
			[self flipScreenPaddlesSide];
			
			// move hero inside next screen
			
			float px = hero.position.x;
			float py = hero.position.y;
			
			if (exitSide & kSideLeft) {
				px = screen.position.x - hero.size.width - 1;
			} else if (exitSide & kSideRight) {
				px = screen.position.x + screen.size.width + hero.size.width + 1;
			}
			if (exitSide & kSideTop) {
				py = screen.position.y + screen.size.height + hero.size.height + 1;
			} else if (exitSide & kSideBottom) {
				py = screen.position.y - hero.size.height - 1;
			}
			
			hero.position = CGPointMake (px, py);
			
			[self setupScreenHUD];
		}
	}
}

-(void) moveMainHeroToScreen:(KKScreen *)screen atPosition:(CGPoint)pos
{
	if (screen != [level currentScreen]) {
		previousScreen = [level currentScreen];
		
		if (previousScreen) {
			[level setScreen:previousScreen shown:NO];
			[level setScreen:previousScreen active:NO];
		}
		
		[level setScreen:screen shown:YES];
		[level setScreen:screen active:YES];
		
		if (previousScreen) [previousScreen applyShown];
		[screen applyShown];
		
		[self flipScreenPaddlesSide];			
	}
	level.mainHero.position = ccpAdd(screen.position, pos);
	
	[self setupScreenHUD];
}

#pragma mark Main

-(void) updateGame:(ccTime)dt
{
	if (!level || flags & kGEFlagUpdateDisabled) return;

	// timers
	[self updateTimers:dt];
	[self updateFX:dt];
	[hud update:dt];
	
	KKScreen *screen = [level currentScreen];
	KKHero *hero;
	int exitSide = kSideNone;
	
	// scripts
	if (!(flags & kGEFlagScriptUpdateDisabled)) {
		if (level.flags & kLevelFlagScriptUpdate) {
			levelUpdate(dt);
		}

		for (KKScreen *s in level.activeScreens) {
//			if ((s.flags & kScreenFlagScriptUpdate) && s.needsScriptUpdate) {
			if ((s.flags & kScreenFlagScriptUpdate)) {
				screenUpdate(s.index, dt);
			}
		}
		
		if (level.mainHero.flags & kHeroFlagScriptUpdate) {
			mainHeroUpdate(dt);
		}
	}
	
	// update main hero
	[self updateMainHeroWithPlayerInput:dt];
	
	// paddles AI update
	[self updatePaddlesAI:dt];
	[self updatePaddles:dt];
	
	// hero update
	for (NSNumber *i in level.heroesArray) {
		hero = [level heroAtIndex:[i intValue]];
		
		if (hero.flags & kHeroFlagDontUpdateMovement) continue;
		
		// friction
		if (level.friction)
			hero.acceleration = ccpMult(hero.acceleration, level.friction);
		// gravity
		hero.acceleration = ccpAdd(hero.acceleration, ccpMult(ccpCompMult(level.gravity, level.accelerationFactor), dt * GRAVITY_FACTOR));
		
		// paddle proxymity effects
		[self updateHeroProximityWithPaddles:hero screen:screen dt:dt];
		
		// update hero speed
		[hero updateSpeed:dt];
		
		// collision detection
		if (!(flags & kGEFlagPhysicsUpdateDisabled)) {
			// border collisions
			exitSide |= [self updateHero:hero screenBorderCollision:screen dt:dt];

			// paddles collision
			[self updateHeroCollisionWithPaddles:hero screen:screen dt:dt];
		}
		
		// update hero position
		[hero updatePosition:dt];
		
		// exit from screen
		if (exitSide != kSideNone)
			[self sendHero:hero toScreen:screen exitSide:exitSide];
	}

	[level update:dt];
}
	

-(void) update:(ccTime)dt
{
	switch (currentGameState) {
		case kGSLoading:
			break;
		case kGSGameStart:
			break;
		case kGSInGame:
			[self updateGame:dt];
			break;
		case kGSInGamePause:
			break;
		case kGSGameOver:
			break;
		case kGSPause:
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark Start Game

-(void) resetGame
{
	score = 0;
	scoreMultiplier = 1;
	currentLevelScore = 0;
	previousLevelScore = 0;
	scoreForNewLife = NEW_LIFE_SCORE;
	questTimeElapsed = 0;
	levelTimeElapsed = 0;
	numPlayerHerosLeft = NUM_LIFES_AT_START;
}

-(void) setGameMode:(tGameMode)aGameMode
{
	gameMode = aGameMode;
}

-(void) startGame:(NSString *)aLevelName mode:(tGameMode)aGameMode reset:(BOOL)reset
{
	KKLOG (@"level=%@ mode=%d reset=%d", aLevelName, aGameMode, reset);
	
	KKLOG (@"setIdleTimerDisabled: %d", YES);
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	currentGameState = kGSInGame;
	
	[self setGameMode:aGameMode];
	
	scoreMultiplier = 1;
	levelTimeElapsed = 0;
	questTimeElapsed = 0;
	
	if (reset) [self resetGame];
	
	isFullQuest = gameMode == kGMQuest && [aLevelName isEqualToString:LEVEL_QUEST_START];
	
	[self startLevel:aLevelName withStartTimer:LEVEL_START_TIMEOUT];
}

-(void) resumeSavedGame
{
	NSMutableDictionary *gameData = KKPM.savedGameData;

	[self resetGame];
	[self loadGameData:gameData];
	[self setGameMode:gameMode];
	previousLevelScore = [[gameData objectForKey:@"previousLevelScore"] intValue];
	
	currentGameState = kGSInGame;
	[self startLevel:[gameData objectForKey:@"nextLevel"] withStartTimer:LEVEL_START_TIMEOUT];
}

#pragma mark -
#pragma mark Rating

#define APP_NUM_LAUNCHES_BEFORE_RATE 6
#define APP_TIME_DELTA_BEFORE_RATE (60*60*24*7) /*one week */
#define APP_REVIEW_URL @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@"
//#define APP_REVIEW_URL @"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=0&sortOrdering=1&type=Purple+Software"
//#define APP_REVIEW_URL @"https://userpub.itunes.apple.com/WebObjects/MZUserPublishing.woa/wa/addUserReview?id=%@&type=Purple+Software"


-(void) rateNow
{
	NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	[KKPM.info setObject:appVersion forKey:APP_RATED_VERSION];
	
	NSString* iTunesLink = [NSString stringWithFormat:APP_REVIEW_URL, APPLE_ID];
	KKLOG (@"iTunesLink: %@", iTunesLink);
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
}

-(BOOL) shouldRate
{
	BOOL f = NO;
	
	NSString *ratedVersion = [KKPM.info objectForKey:APP_RATED_VERSION];
	
	NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

	// reset checks if rated version is different from app version
	if (ratedVersion != nil && ![ratedVersion isEqualToString:appVersion]) {
		[KKPM.info setObject:[NSDate date] forKey:APP_FIRST_RUN];
		[KKPM.info setObject:[NSNumber numberWithInt:1] forKey:APP_NUM_LAUNCHES];
		[KKPM.info setObject:nil forKey:APP_RATED_VERSION];
		ratedVersion = nil;
	}
	
	NSDate *firstRun = [KKPM.info objectForKey:APP_FIRST_RUN];
	NSNumber *numLaunches = [KKPM.info objectForKey:APP_NUM_LAUNCHES];
	NSDate *timeSinceFirstRun;
	
	if ([firstRun respondsToSelector:@selector(dateByAddingTimeInterval:)]) {
		timeSinceFirstRun = [firstRun dateByAddingTimeInterval:APP_TIME_DELTA_BEFORE_RATE];
	} else {
		timeSinceFirstRun = [firstRun addTimeInterval:APP_TIME_DELTA_BEFORE_RATE];
	}
	
	if (ratedVersion == nil &&
		(
		 [numLaunches intValue] >= APP_NUM_LAUNCHES_BEFORE_RATE || 
		 [(NSDate*)[NSDate date] compare:timeSinceFirstRun] == NSOrderedDescending || 
		 [self isFullQuestCompleted]
		)) {
		f = YES;
	}
	
	return f;
}

#pragma mark -
#pragma mark Paths

-(NSString *) getDocumentsResourcesFolder:(NSString *)rFolder forLevel:(NSString*)lName
{
	return [KKGamePath getDocumentsResourcesFolder:rFolder forLevel:lName];
}

-(NSString *) getResourcesFolder:(NSString *)rFolder forLevel:(NSString *)lName
{
	return [KKGamePath getResourcesFolder:rFolder forLevel:lName];
}

#define LEVEL_THUMBNAIL_IMAGE @"levelThumbnail.png"

-(NSString *) thumbnailImageNameForLevelIndex:(int)levelIndex
{
	NSString *folder = [self getResourcesFolder:LEVELS_FOLDER forLevel:[self levelNameFromIndex:levelIndex]];
	
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@/%@", folder, LEVEL_PATH_GRAPHICS, LEVEL_THUMBNAIL_IMAGE]];
}

// global paths

-(NSString *) pathForGraphic:(NSString *)str
{
	return [KKGamePath pathForGraphic:str];
}

-(NSString *) pathForTTFFont:(NSString *)str
{
	return [KKGamePath pathForTTFFont:str];
}

-(NSString *) pathForFont:(NSString *)str size:(int)s
{
	return [KKGamePath pathForFont:str size:s];
}

-(NSString *) pathForSound:(NSString *)str
{
	return [KKGamePath pathForSound:str];
//	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", RESOURCES_PATH_SOUNDS, str]];
}

-(NSString *) pathForMusic:(NSString *)str
{
	return [KKGamePath pathForMusic:str];
}

-(NSString *) pathForScript:(NSString *)str
{
	return [KKGamePath pathForScript:str];
}

-(NSString *) pathForLevelDefinition:(NSString *)str
{
	return [KKGamePath pathForLevelDefinition:str];
}

-(NSString *) pathForData:(NSString *)str
{
	return [KKGamePath pathForData:str];
}

// level paths

-(NSString *) pathForLevel:(NSString *)str
{
	return [KKGamePath pathForLevel:str inLevel:levelName];
}

-(NSString *) pathForLevelGraphic:(NSString *)str
{
	return [KKGamePath pathForLevelGraphic:str inLevel:levelName];
}

-(NSString *) pathForLevelFont:(NSString *)str size:(int)s
{
	return [KKGamePath pathForLevelFont:str size:s inLevel:levelName];
}

-(NSString *) pathForLevelSound:(NSString *)str
{
	return [KKGamePath pathForLevelSound:str inLevel:levelName];
}

-(NSString *) pathForLevelMusic:(NSString *)str
{
	return [KKGamePath pathForLevelMusic:str inLevel:levelName];
}

-(NSString *) pathForLevelScript:(NSString *)str
{
	return [KKGamePath pathForLevelScript:str inLevel:levelName];
}

#pragma mark -
#pragma mark Stuff
	
-(void) playBe2Trailer
{
	return;
//	[KKPM.info setObject:[NSNumber numberWithBool:YES] forKey:APP_BE2_TRAILER_VIEWED];
//	[KKGM playVideo:[KKGamePath pathForGraphic:@"video/be2Trailer.m4v"]];
}
	
-(BOOL) wasBe2TrailerViewed
{
	return TRUE;
//	return (BOOL) [[KKPM.info objectForKey:APP_BE2_TRAILER_VIEWED] boolValue];
}	

#pragma mark -
#pragma mark Utilities

-(void) removeDownloadedLevels
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *docs = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *path = [NSString stringWithFormat:@"%@/%@", docs, LEVELS_FOLDER];
	NSError *error;

	if ([fileManager fileExistsAtPath:path]) {
		BOOL success = [fileManager removeItemAtPath:path error:&error];
		KKLOG (@"Deleted path '%@': %@", path, (!success ? [error localizedDescription] : @"OK"));
	}

	// reload level info
	[self loadAvailableLevelsInfo];
	// notify user of success or failure
	KKLOG (@"Levels deleted");
	[hud showTimerLabel:@"Deleted" sound:@"gong.caf"];
}

-(void) downloadLevel:(NSString*)name fromHost:(NSString*)host atPort:(int)port
{
	KKLOG (@"level:%@ host:%@ port:%d", name, host, port);
	NSString *basePath = [NSString stringWithFormat:@"http://%@:%d/levels/%@", host, port, name];
	NSString *path;
	NSURL *url;
	ASIHTTPRequest *request;
	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// get files index
	url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/index", basePath]];
	KKLOG (@"Requesting level 'index': %@", [url absoluteString]);
	request = [ASIHTTPRequest requestWithURL:url];
	[request startSynchronous];
	error = [request error];
	if (error) {
		KKLOG (@"Error requesting level 'index': %@", [error localizedDescription]);
		return;
	}
	
	// cleanup current level data, if any
	path = [self getDocumentsResourcesFolder:LEVELS_FOLDER forLevel:name];
	
	for (NSString *filename in [fileManager contentsOfDirectoryAtPath:path error:&error]) {
		NSString *i = [NSString stringWithFormat:@"%@/%@", path, filename];
		if (![fileManager isDeletableFileAtPath:i]) {
			[fileManager setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],NSFileImmutable, nil] 
						  ofItemAtPath:i 
								 error:&error];
			KKLOG (@"Changing deletable attribute for file '%@': %d", i, [fileManager isDeletableFileAtPath:i]);
		}
		[fileManager removeItemAtPath:i error:&error];
		KKLOG (@"Deleted path [%d] '%@': %@", (error ? [fileManager isDeletableFileAtPath:i] : YES), i, (error ? [error localizedDescription] : @"OK"));
	}
	
	// download level files
	NSArray *filesIndex = [[request responseString] componentsSeparatedByString:@","];
	for (NSString *filename in filesIndex) {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", basePath, filename]];
		path = [NSString stringWithFormat:@"%@/%@", [self getDocumentsResourcesFolder:LEVELS_FOLDER forLevel:name], filename];

		// check for existing files
		if ([fileManager fileExistsAtPath:path]) {
			if (![fileManager isDeletableFileAtPath:path]) {
				[fileManager setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],NSFileImmutable, nil] 
							  ofItemAtPath:path 
									 error:&error];
				KKLOG (@"Changing deletable attribute for file '%@': %@", path, (error ? [error localizedDescription] : @"OK"));
			}
		} else {
			// create directory path
			[[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
													 withIntermediateDirectories:YES 
																	  attributes:nil 
																		   error:&error];
			if (error) {
				KKLOG (@"Error creating directory path '%@': %@", [path stringByDeletingLastPathComponent], [error localizedDescription]);
			}
		}
		KKLOG (@"Requesting level file: %@", [url absoluteString]);
		request = [ASIHTTPRequest requestWithURL:url];
		[request setDownloadDestinationPath:path];
		[request startSynchronous];
		error = [request error];
		if (error) {
			KKLOG (@"Error requesting level file '%@': %@", filename, [error localizedDescription]);
			return;
		} else {
			KKLOG (@"Downloaded: '%@' to '%@'", [url absoluteString], path);
		}
	}
	// reload level info
	[self loadAvailableLevelsInfo];
	// notify user of success or failure
	KKLOG (@"Level downloaded: %@", name);
	[hud showTimerLabel:@"Downloaded" sound:@"gong.caf"];
}

@end
