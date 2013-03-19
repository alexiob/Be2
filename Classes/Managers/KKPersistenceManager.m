//
//  PersistenceManager.m
//  Be2
//
//  Created by Alessandro Iob on 4/15/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKPersistenceManager.h"
#import "SynthesizeSingleton.h"
#import "KKAppVersion.h"
#import "KKGameEngine.h"
#import "KKInputManager.h"

#define GAME_DATA_FILENAME @"game_v%@.plist"

@implementation KKPersistenceManager

@synthesize info;
@synthesize gameDataPath;
@synthesize deviceOrientation, displayFPS, animationInterval;
@synthesize soundEffectsEnabled, soundEffectsVolume, musicEnabled, musicVolume;
@synthesize savedGameData;
@synthesize inputMode, difficultyLevel;

SYNTHESIZE_SINGLETON(KKPersistenceManager);

-(id) init
{
	self = [super init];
	
	if (self) {
		NSString *filename = [NSString stringWithFormat:GAME_DATA_FILENAME, [KKAppVersion getGameDataVersionNumber]];
		
		self.gameDataPath = [[[NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:filename] retain];
		self.savedGameData = nil;
		
		[self loadUserDefaults];
	}
	
	return self;
}

-(void) dealloc
{
	if (info) [info release], info = nil;
	
	if (savedGameData) [savedGameData release], savedGameData = nil;
	if (gameDataPath) [gameDataPath release], gameDataPath = nil;
	
	[super dealloc];
}

-(NSMutableDictionary *) setupDefaultInfo
{
	info = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
	return info;
}

-(void) loadUserDefaults
{
	if (info) [info release], info = nil;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	if([userDefaults boolForKey:@"optionsSet"]) {
		self.deviceOrientation = [userDefaults integerForKey:@"deviceOrientation"];
		self.displayFPS = [userDefaults boolForKey:@"displayFPS"];
		self.animationInterval = [userDefaults floatForKey:@"animationInterval"];
		
		self.soundEffectsEnabled = [userDefaults boolForKey:@"soundEffectsEnabled"];
		self.soundEffectsVolume = [userDefaults integerForKey:@"soundEffectsVolume"];
		self.musicEnabled = [userDefaults boolForKey:@"musicEnabled"];
		self.musicVolume = [userDefaults integerForKey:@"musicVolume"];
		
		self.inputMode = DICT_INT(userDefaults, @"inputMode", kInputModeJoystick);
		self.difficultyLevel = DICT_INT(userDefaults, @"difficultyLevel", kDifficultyLow);
		
		NSData *data = [userDefaults objectForKey:@"data"];
		if (data) {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			info = [[unarchiver decodeObjectForKey:@"info"] retain];
			[unarchiver finishDecoding];
			[unarchiver release];
		} else {
			info = [self setupDefaultInfo];
		}
	} else {
		self.deviceOrientation = CCDeviceOrientationLandscapeLeft;
		self.displayFPS = YES;
		self.animationInterval = 1.0f/60.0f;
		
		self.soundEffectsEnabled = TRUE;
		self.soundEffectsVolume = 100;
		self.musicEnabled = TRUE;
		self.musicVolume = 100;
		
		self.inputMode = kInputModeJoystick;
		self.difficultyLevel = kDifficultyLow;
		
		info = [self setupDefaultInfo];
	}
}

-(void) saveUserDefaults
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:info forKey:@"info"];
	[archiver finishEncoding];
	[archiver release];
	
	[userDefaults setObject:[data autorelease] forKey:@"data"];
	
	[userDefaults setInteger:self.deviceOrientation forKey:@"deviceOrientation"];
	[userDefaults setBool:self.displayFPS forKey:@"displayFPS"];
	[userDefaults setFloat:self.animationInterval forKey:@"animationInterval"];
	
	[userDefaults setBool:self.soundEffectsEnabled forKey:@"soundEffectsEnabled"];
	[userDefaults setInteger:self.soundEffectsVolume forKey:@"soundEffectsVolume"];
	[userDefaults setBool:self.musicEnabled forKey:@"musicEnabled"];
	[userDefaults setInteger:self.musicVolume forKey:@"musicVolume"];

	[userDefaults setInteger:self.inputMode forKey:@"inputMode"];
	[userDefaults setInteger:self.difficultyLevel forKey:@"difficultyLevel"];

	[userDefaults setBool:YES forKey:@"optionsSet"];
	
	[userDefaults synchronize];
}

-(BOOL) hasSavedGame
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	
	return (BOOL) [fm fileExistsAtPath:self.gameDataPath isDirectory:&isDir] && !isDir;
}

-(NSMutableDictionary *) loadGame
{
	if ([self hasSavedGame]) {
		
		@try {
			self.savedGameData = [NSKeyedUnarchiver unarchiveObjectWithFile:self.gameDataPath];
			KKLOG (@"%@ %@", self.gameDataPath, self.savedGameData);
		}
		
		@catch (NSException *exception) {
			KKLOG (@"%@", exception);
			self.savedGameData = nil;
		}
	}
	return self.savedGameData;
}

-(BOOL) saveGameWithNextLevel:(NSString *)nextLevel
{
	NSMutableDictionary *gameData = [KKGE saveGameData];
	[gameData setObject:nextLevel forKey:@"nextLevel"];
	[gameData setObject:[NSNumber numberWithInt:KKGE.currentLevelScore] forKey:@"previousLevelScore"];
	
	KKLOG (@"%@ %@", self.gameDataPath, gameData);
	if ([NSKeyedArchiver archiveRootObject:gameData toFile:self.gameDataPath]) {
		self.savedGameData = gameData;
		return YES;
	} else {
		return NO;
	}
}

-(BOOL) removeGame
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error;
	
	self.savedGameData = nil;
	return [fm removeItemAtPath:self.gameDataPath error:&error];
}

@end
