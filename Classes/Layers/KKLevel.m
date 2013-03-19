//
//  KKLevel.m
//  be2
//
//  Created by Alessandro Iob on 2/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKLevel.h"
#import "KKMacros.h"
#import "KKMath.h"
#import "KKGameEngine.h"
#import "KKLuaManager.h"
#import "KKCollisionDetection.h"
#import "KKInputManager.h"
#import "KKObjectsManager.h"
#import "CGPointExtension.h"
#import "KKGraphicsManager.h"
#import "KKLuaCalls.h"
#import "KKStringUtilities.h"

// z is relative to layer
#define LAYER_BACKGROUND_GRID_Z 10
#define BG_IMAGES_Z 20
#define TITLE_LABEL_Z 30
#define MESSAGE_LABEL_Z 40
#define LAYER_ENTITIES_Z 50
#define LAYER_SCREEN_BORDER_Z 100
#define LAYER_LIGHT_GRID_Z 1000

// z is relative to LAYER_ENTITIES
#define PADDLE_Z 10
#define HERO_Z 20

#define TITLE_LABEL_Y 50
#define DESCRIPTION_LABEL_Y 82

#define SCREEN_SHOW_DURATION 0.2
#define INPUT_PRIORITY 1

#define BGIMAGE_SHOW_DURATION 0.5
#define BGIMAGE_HIDE_DURATION 0.2
#define BGIMAGE_MOVE_DURATION 0.1
#define BG_IMAGE_OPACITY 180

@interface KKLevel ()

-(void) initScreenBorders;

@end

@implementation KKLevel

@synthesize data;
@synthesize flags, levelIndex;
@synthesize availableTime, minimumScore, availableHeroes;
@synthesize numHeroes, numPaddles, numScreens, activeScreens;
@synthesize screenScaleX, screenScaleY;
@synthesize heroesArray, screensArray, paddlesArray, sortedPaddlesArray, globalPaddlesArray;
@synthesize minSpeed, maxSpeed;
@synthesize screenShowDuration;
@synthesize accelerationStart, acceleration, accelerationMode, accelerationViscosity, accelerationFactor;
@synthesize accelerationMin, accelerationMax, accelerationInputX, accelerationInputY;
@synthesize friction, gravity;
@synthesize turboSecondsAvailable, turboFactor, wasTurboUsed;
@synthesize lightGrid;
@synthesize titleLabel, descriptionLabel; //, messageLabel;
@synthesize scorePerSecondLeft;
@synthesize joystickAccelerationFactor;

-(id) initWithData:(NSMutableDictionary *)levelData
{
	self = [super initWithColor4B:ccc4(0, 0, 0, 255)];
	if (self) {
		gameEngine = KKGE;
		luaManager = KKLM;
		
		CGSize ws = [[CCDirector sharedDirector] winSize];
		
		activeScreens = [[NSMutableSet setWithCapacity:10] retain];
		screenScaleX = 1.0;
		screenScaleY = 1.0;
		
		[self setAnchorPoint:ccp (0.0, 0.0)];
		[self setPosition:ccp (0.0, 0.0)];

		// labels
		titleLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"" fntFile:[gameEngine pathForFont:UI_FONT_DEFAULT size:SCALE_FONT(32)]] retain];
		[titleLabel.texture setAliasTexParameters];
		titleLabel.position = ccp (ws.width/2, ws.height - SCALE_Y(TITLE_LABEL_Y));
		[self addChild:titleLabel z:TITLE_LABEL_Z];
		
		descriptionLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"" fntFile:[gameEngine pathForFont:UI_FONT_DEFAULT size:SCALE_FONT(16)]] retain];
		[descriptionLabel.texture setAliasTexParameters];
		descriptionLabel.position = ccp (ws.width/2, ws.height - SCALE_Y(DESCRIPTION_LABEL_Y));
		[self addChild:descriptionLabel z:TITLE_LABEL_Z];
		
//		messageLabel =  [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"" fntFile:[gameEngine pathForFont:UI_FONT_DEFAULT size:SCALE_FONT(128)]] retain];
//		[messageLabel.texture setAliasTexParameters];
//		[messageLabel setAnchorPoint:ccp (0.0, 1.0)];
//		[self addChild:messageLabel z:MESSAGE_LABEL_Z];
		
		// paddles and heroes
		entitiesLayer = [[CCLayer alloc] init];
		[self addChild:entitiesLayer z:LAYER_ENTITIES_Z];
		[entitiesLayer setAnchorPoint:ccp (0.0, 0.0)];
		[entitiesLayer setPosition:ccp (0.0, 0.0)];

		// background images
		for (int i = 0; i < MAX_BG_IMAGES; i++) {
			bgImages[i] = [[[CCSprite alloc] init] autorelease];
			[bgImages[i] setOpacityModifyRGB:NO];
			bgImages[i].opacity = 0;
			bgImages[i].visible = NO;
			[self addChild:bgImages[i] z:BG_IMAGES_Z];
		}
		// background grid
//		backgroundGrid = [[KKLightGrid alloc] initWithCellSize:SCALE_SIZE(CGSizeMake (40, 40))];
//		[self addChild:backgroundGrid z:LAYER_BACKGROUND_GRID_Z];
//		backgroundGrid.visible = NO;
		
		// lights grid
		lightGrid = [[KKLightGrid alloc] initWithCellSize:SCALE_SIZE(CGSizeMake (10, 10))];
		[lightGrid setOpacity:0.0];
		[self addChild:lightGrid z:LAYER_LIGHT_GRID_Z];

		heroesArray = [[NSMutableArray arrayWithCapacity:MAX_HEROES] retain];
		screensArray = [[NSMutableArray arrayWithCapacity:10] retain];
		paddlesArray = [[NSMutableSet setWithCapacity:50] retain];
		globalPaddlesArray = [[NSMutableSet setWithCapacity:50] retain];
		sortedPaddlesArray = nil;
		
		touchToPaddle = [[NSMutableDictionary dictionaryWithCapacity:5] retain];
		
		[self initScreenBorders];
		[self initHeroes];
		
		[self initLevel:levelData];
	}
	return self;
}

-(void) dealloc
{
	KKLOG (@"idx=%d", levelIndex);
	[self destroyHeroes];
	
	[activeScreens release];
	
	[entitiesLayer release];
	
	[titleLabel release];
	[descriptionLabel release];
//	[messageLabel release];
	
	[heroesArray release];
	[paddlesArray release];
	[screensArray release];
	[globalPaddlesArray release];
	if (sortedPaddlesArray) [sortedPaddlesArray release], sortedPaddlesArray = nil;
	
	[touchToPaddle release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Properties

-(NSString *) name
{
	return [data objectForKey:@"name"];
}

-(NSString *) title
{
	return [data objectForKey:@"title"];
}

-(NSString *) desc
{
	return [data objectForKey:@"description"];
}

-(NSString *) leaderboard
{
#ifdef KK_BE2_FREE
	return [data objectForKey:@"leaderboardFree"];
#else
	return [data objectForKey:@"leaderboard"];
#endif
}

-(int) kind
{
	return [[data objectForKey:@"kind"] intValue];
}

-(int) difficulty
{
	return [[data objectForKey:@"difficulty"] intValue];
}

-(NSString *) nextLevelName
{
	return [data objectForKey:@"nextLevelName"];
}


-(NSString *) audioBackgroundMusic
{
	return [data objectForKey:@"audioBackgroundMusic"];
}

-(NSString *) audioInSound
{
	return [data objectForKey:@"audioInSound"];
}

-(NSString *) audioOutSound
{
	return [data objectForKey:@"audioOutSound"];
}

-(void) setMinSpeed:(CGPoint)p
{
	[data setObject:[NSNumber numberWithFloat:p.x] forKey:@"minSpeedX"];
	[data setObject:[NSNumber numberWithFloat:p.y] forKey:@"minSpeedY"];
	p = SCALE_POINT (p);
	minSpeed = p;
}

-(void) setMaxSpeed:(CGPoint)p
{
	[data setObject:[NSNumber numberWithFloat:p.x] forKey:@"maxSpeedX"];
	[data setObject:[NSNumber numberWithFloat:p.y] forKey:@"maxSpeedY"];
	p = SCALE_POINT (p);
	maxSpeed = p;
}

-(void) setAccelerationInputX:(BOOL)p
{
	[data setObject:[NSNumber numberWithBool:p] forKey:@"accelerationInputX"];
	accelerationInputX = p;
}

-(void) setAccelerationInputY:(BOOL)p
{
	[data setObject:[NSNumber numberWithBool:p] forKey:@"accelerationInputY"];
	accelerationInputY = p;
}

-(void) setAccelerationViscosity:(CGPoint)p
{
	[data setObject:[NSNumber numberWithFloat:p.x] forKey:@"accelerationViscosityX"];
	[data setObject:[NSNumber numberWithFloat:p.y] forKey:@"accelerationViscosityY"];
	accelerationViscosity = p;
}

-(void) setAccelerationFactor:(CGPoint)p
{
	[data setObject:[NSNumber numberWithFloat:p.x] forKey:@"accelerationFactorX"];
	[data setObject:[NSNumber numberWithFloat:p.y] forKey:@"accelerationFactorY"];
	accelerationFactor = p;
}

-(void) setAccelerationMin:(CGPoint)p
{
	[data setObject:[NSNumber numberWithFloat:p.x] forKey:@"accelerationMinX"];
	[data setObject:[NSNumber numberWithFloat:p.y] forKey:@"accelerationMinY"];
	p = SCALE_POINT (p);
	accelerationMin = p;
}

-(void) setAccelerationMax:(CGPoint)p
{
	[data setObject:[NSNumber numberWithFloat:p.x] forKey:@"accelerationMaxX"];
	[data setObject:[NSNumber numberWithFloat:p.y] forKey:@"accelerationMaxY"];
	p = SCALE_POINT (p);
	accelerationMax = p;
}

-(void) setGravity:(CGPoint)p
{
	[data setObject:[NSNumber numberWithFloat:p.x] forKey:@"gravityX"];
	[data setObject:[NSNumber numberWithFloat:p.y] forKey:@"gravityY"];
	p = SCALE_POINT (p);
	gravity = p;
}

-(void) setFriction:(float)p
{
	[data setObject:[NSNumber numberWithFloat:p] forKey:@"friction"];
	friction = p;
}

#pragma mark -
#pragma mark Level setup

#define JOYSTICK_ACC_FACTOR 0.8

-(void) initLevel:(NSMutableDictionary *)levelData
{
	[self destroyLevel];
	
	data = levelData;
	[data retain];
	KKLOG (@"'%@'", self.name);
	
	if (data) {
		NSArray *paddlesData = [data objectForKey:@"paddles"];
		NSArray *screensData = [data objectForKey:@"screens"];
		
		flags = [[data objectForKey:@"flags"] intValue];
		levelIndex = DICT_INT (data, @"index", 0);
		availableTime = DICT_FLOAT (data, @"availableTime", 0);
		
		minimumScore = DICT_INT (data, @"minimumScore", 0);
		availableHeroes = DICT_INT (data, @"availableHeroes", -1);
		
		screenShowDuration = DICT_FLOAT (data, @"screenShowDuration", SCREEN_SHOW_DURATION);
		
		numPaddles = [paddlesData count];
		numScreens = [screensData count];
		
		minSpeed = SCALE_POINT(CGPointMake (
								[[data objectForKey:@"minSpeedX"] floatValue],
								[[data objectForKey:@"minSpeedY"] floatValue]
								));
		
		maxSpeed = SCALE_POINT(CGPointMake (
								[[data objectForKey:@"maxSpeedX"] floatValue],
								[[data objectForKey:@"maxSpeedY"] floatValue]
								));
		
		paddles = calloc (numPaddles, sizeof (KKPaddle*));
		screens = calloc (numScreens, sizeof (KKScreen*));
		
		turboSecondsAvailable = DICT_FLOAT (data, @"turboSecondsAvailable", 0);
		turboFactor = DICT_FLOAT (data, @"turboFactor", 0);
		wasTurboUsed = NO;
		
		scorePerSecondLeft = DICT_INT (data, @"scorePerSecondLeft", SCORE_PER_SECOND_LEFT);
		
		[self setupScripts:[data objectForKey:@"scripts"]];

		joystickAccelerationFactor = DICT_FLOAT (data, @"joystickAccelerationFactor", JOYSTICK_ACC_FACTOR);
		if (joystickAccelerationFactor == 0.0) joystickAccelerationFactor = JOYSTICK_ACC_FACTOR;

		for (int i = 0; i < numPaddles; i++) {
			paddles[i] = [[KKPaddle alloc] initWithData:[paddlesData objectAtIndex:i] fromLevel:self withIndex:i];
			[entitiesLayer addChild:paddles[i] z:PADDLE_Z + paddles[i].z];
			if ([paddles[i] isGlobal]) {
				[globalPaddlesArray addObject:[NSNumber numberWithInt:i]];
				[paddles[i] setShown:YES];
				[paddles[i] applyShown];
			}
		}
		
		for (int i = 0; i < numScreens; i++) {
			screens[i] = [[KKScreen alloc] initWithData:[screensData objectAtIndex:i] fromLevel:self withIndex:i];
			screens[i].index = i;
		}
		
		currentScreen = nil;
		
		[self setupMainHero];
	}
	
	[self resetLightGridOpacity];
	[self initInput];
	[self setTitle:self.title];
}

-(void) destroyLevel
{
	[self destroyInput];

	[activeScreens removeAllObjects];

	[globalPaddlesArray removeAllObjects];
	
	if (data) {
		for (int i = 0; i < numScreens; i++) {
			[screens[i] release];
		}
		free (screens);

		for (int i = 0; i < numPaddles; i++) {
			[paddles[i] release];
		}
		free (paddles);
		
		[data release], data = nil;
		
		[entitiesLayer removeAllChildrenWithCleanup:YES];
	}
	
	[luaManager execString:@"if level then level:destroy () end"];
	
	currentScreen = nil;
}

-(void) setupLevel
{
	KKLOG (@"'%@'", self.name);
	
	// run setup scripts
	[luaManager execString:@"level:setup ()"];
	
	for (int i = 0; i < numPaddles; i++) {
		[luaManager execString:[NSString stringWithFormat:@"level.paddles[%d]:setup ()", i]];
	}
	
	for (int i = 0; i < numScreens; i++) {
		[luaManager execString:[NSString stringWithFormat:@"level.screens[%d]:setup ()", i]];
	}	
}

#pragma mark -
#pragma mark Screen Borders

-(void) initScreenBorders
{
	for (int i = kScreenBorderSideTop; i <= kScreenBorderSideRight; i++) {
		borders[i] = [[KKScreenBorder alloc] initWithSide:i 
													  size:DEFAULT_SCREEN_BORDER_SIZE
													 color:ccc3(255,255,255) 
												   opacity:255
					   ];
		[self addChild:borders[i] z:LAYER_SCREEN_BORDER_Z];
	}
}

-(void) setScreenBorders:(KKScreen *)screen withDuration:(float)duration
{
	int f;
	
	if (screen == nil) {
		f = kScreenFlagTopSideClosed | kScreenFlagBottomSideClosed | kScreenFlagLeftSideClosed | kScreenFlagRightSideClosed;
	} else {
		f = screen.flags;
	}

	[borders[kScreenBorderSideTop] setActive:f & kScreenFlagTopSideClosed withDuration:duration];
	[borders[kScreenBorderSideBottom] setActive:f & kScreenFlagBottomSideClosed withDuration:duration];
	[borders[kScreenBorderSideLeft] setActive:f & kScreenFlagLeftSideClosed withDuration:duration];
	[borders[kScreenBorderSideRight] setActive:f & kScreenFlagRightSideClosed withDuration:duration];

	[borders[kScreenBorderSideTop] setSize:[screen borderSize:kScreenBorderSideTop]];
	[borders[kScreenBorderSideBottom] setSize:[screen borderSize:kScreenBorderSideBottom]];
	[borders[kScreenBorderSideLeft] setSize:[screen borderSize:kScreenBorderSideLeft]];
	[borders[kScreenBorderSideRight] setSize:[screen borderSize:kScreenBorderSideRight]];
	
	NSString *s;
	
	s = [self getStringForKey:@"borderSideTopColor" withDefault:@""];
	if (![s isEqualToString:@""])
		[borders[kScreenBorderSideTop] setColor:ccc3FromNsString(s) withDuration:duration];
	s = [self getStringForKey:@"borderSideBottomColor" withDefault:@""];
	if (![s isEqualToString:@""])
		[borders[kScreenBorderSideBottom] setColor:ccc3FromNsString(s) withDuration:duration];
	s = [self getStringForKey:@"borderSideLeftColor" withDefault:@""];
	if (![s isEqualToString:@""])
		[borders[kScreenBorderSideLeft] setColor:ccc3FromNsString(s) withDuration:duration];
	s = [self getStringForKey:@"borderSideRightColor" withDefault:@""];
	if (![s isEqualToString:@""])
		[borders[kScreenBorderSideRight] setColor:ccc3FromNsString(s) withDuration:duration];
	
	[borders[kScreenBorderSideBottom] setActive:f & kScreenFlagBottomSideClosed withDuration:duration];
	[borders[kScreenBorderSideLeft] setActive:f & kScreenFlagLeftSideClosed withDuration:duration];
	[borders[kScreenBorderSideRight] setActive:f & kScreenFlagRightSideClosed withDuration:duration];
}

-(void) setScreenBorder:(tScreenBorderSide)border active:(BOOL)f
{
	[borders[border] setActive:f withDuration:screenShowDuration];	
}

-(void) setScreenBorder:(tScreenBorderSide)border color:(ccColor3B)c
{
	[borders[border] setColor:c withDuration:screenShowDuration];	
}

#pragma mark -
#pragma mark Scripts

-(void) setupScripts:(NSString *)scriptsData
{
	if (!scriptsData) scriptsData = @"";
	
	@try {
		NSString *s = [NSString stringWithFormat:GET_SHARED_OBJECT (TEMPLATE_LEVEL),
					   scriptsData
					   ];
		
		[luaManager loadString:s];
	}
	@catch (NSException *e) {
		KKLOG (@"%@", [e reason]);
	}
}

#pragma mark -
#pragma mark Update

-(void) update:(ccTime)dt
{
	// gfx/sound update ONLY!
	
	if (flags & kLevelFlagLevelUpdate) {
		for (KKScreen *s in activeScreens) {
			[s update:dt];
		}
		
		[lightGrid updateLights:dt force:NO];
	}
	
//	if (messageEnded)
//		[self setMessageForCurrentScreen];
}

#pragma mark -
#pragma mark Input - Hero Acceleration

-(void) initInput
{
	[self cleanAccelerationSlide];

	[KKIM addTouchesDelegate:self priority:INPUT_PRIORITY];
}

-(void) destroyInput
{
	[KKIM removeTouchesDelegate:self];
}

-(void) resetAccelerationSlide:(CGPoint)start mode:(tAccelerationMode)mode
{
	accelerationMode = mode;
	accelerationStart = start;
}

-(void) updateAccelerationSlide:(CGPoint)pos mode:(tAccelerationMode)mode
{
	accelerationMode = mode;
	acceleration = NORM_POINT (ccp (pos.x - accelerationStart.x, pos.y - accelerationStart.y));
}

-(void) cleanAccelerationSlide
{
	accelerationMode = kAccelerationUnknown;
	accelerationStart = CGPointZero;
	acceleration = CGPointZero;
}

-(tAccelerationMode) accelerationModeFromTouches:(int)touches withEvent:(int)event
{
	tAccelerationMode mode = kAccelerationUnknown;
	int c;
	
	switch (gameEngine.inputMode) {
		case kInputModeSlide:
			c = touches;
			break;
		case kInputModeJoystick:
			c = event;
			break;
	}
	
	switch (c) {
		case 1:
			mode = kAccelerationNormal;
			break;
		case 2:
		case 3:
		case 4:
		case 5:
			mode = kAccelerationTurbo;
			break;
		default:
			break;
	} 
	return mode;
}

#pragma mark -
#pragma mark Input - Paddles Touch

// this methods returns YES if touches should be blocked
-(BOOL) handlePaddlesTouches:(NSSet *)touches ofType:(int)touchType
{
	static CGPoint localTouchesPosition[10];
	static int localTouchesTapCount[10];
	
	int c = 0;
	for (UITouch *touch in touches) {
		localTouchesPosition[c] = ccpAdd([[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]], currentScreen.position);
		localTouchesTapCount[c] = touch.tapCount;
		c++;
	}

	if (touchType != ccTouchBegan) {
		c = 0;
		for (UITouch *touch in touches) {
			NSNumber *h = [NSNumber numberWithInt:[touch hash]];
			KKPaddle *paddle = [touchToPaddle objectForKey:h];
			
			if (paddle) {
				BOOL inPaddle = [paddle containsPoint:localTouchesPosition[c]];

				// button like paddle support
				if (touchType == ccTouchEnded || touchType == ccTouchCancelled) {
					if (paddle.isButton && paddle.enabled) {
						if (touchType == ccTouchEnded && paddle.selected) 
							[paddle clicked];
						paddle.selected = NO;
					}
					[touchToPaddle removeObjectForKey:h];
				}
				if (touchType == ccTouchMoved) {
					if (paddle.isButton && paddle.enabled) {
						if (inPaddle && !paddle.selected) {
							paddle.selected = YES;
						} else if (!inPaddle && paddle.selected) {
							paddle.selected = NO;
						}
					}
				}
				
				if ([paddle handleTouchType:touchType position:localTouchesPosition[c] tapCunt:localTouchesTapCount[c]]) {
					if (paddle.flags & kPaddleFlagBlockTouches) [self cleanAccelerationSlide];
					return YES;
				}
			}
			c++;
		}
	} else {
		for (int i=0; i < currentScreen.numPaddles; i++) {
			KKPaddle *paddle = currentScreen.paddles[i];

			c = 0;
			for (UITouch *touch in touches) {
				if ([paddle containsPoint:localTouchesPosition[c]]) {
					if (paddle.isButton && paddle.enabled) {
						paddle.selected = YES;
					}
					if ([paddle handleTouchType:touchType position:localTouchesPosition[c] tapCunt:localTouchesTapCount[c]]) {
						[touchToPaddle setObject:paddle forKey:[NSNumber numberWithInt:[touch hash]]];
						return YES;
					}
				}
				c++;
			}
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Input handlers

-(void) kkTouchesBegan:(NSMutableSet *)touches withEvent:(UIEvent *)event
{
	BOOL drop = [self handlePaddlesTouches:touches ofType:ccTouchBegan];
	
	if (drop) {
		accelerationMode = kAccelerationUnknown;
		return;
	}
	
	accelerationMode = [self accelerationModeFromTouches:[touches count] withEvent:[[event allTouches] count]];
	
	switch (gameEngine.inputMode) {
		case kInputModeSlide:
			if (accelerationMode != kAccelerationUnknown) {
				UITouch *t = [touches anyObject];
				CGPoint p = [[CCDirector sharedDirector] convertToGL:[t locationInView:[t view]]];
				
				[self resetAccelerationSlide:p mode:accelerationMode];
				[touches removeAllObjects];
			} else {
				[self cleanAccelerationSlide];
			}
			break;
		case kInputModeJoystick:
			if (!joystickTouch) {
				for (UITouch *t in touches) {
					CGPoint p = [[CCDirector sharedDirector] convertToGL:[t locationInView:[t view]]];
					[KKIM.inputLayer setJoystickPosition:p];
					handledByJoystick = [KKIM.inputLayer.joystick ccTouchBegan:t withEvent:event];
					if (handledByJoystick) {
						joystickTouch = t;
						[KKIM.inputLayer showJoystick:YES];
						break;
					}
				}
			}
			break;
	}
}

-(void) kkTouchesMoved:(NSMutableSet *)touches withEvent:(UIEvent *)event
{
	if (!handledByJoystick) 
		[self handlePaddlesTouches:touches ofType:ccTouchMoved];
	
	if (accelerationMode == kAccelerationUnknown) return;

	switch (gameEngine.inputMode) {
		case kInputModeSlide:
			accelerationMode = [self accelerationModeFromTouches:[touches count] withEvent:[[event allTouches] count]];
			
			if (accelerationMode != kAccelerationUnknown) {
				UITouch *t = [touches anyObject];
				CGPoint p = [[CCDirector sharedDirector] convertToGL:[t locationInView:[t view]]];
				[self updateAccelerationSlide:p mode:accelerationMode];
				[touches removeAllObjects];
			} else {
				[self cleanAccelerationSlide];
			}
			break;
		case kInputModeJoystick:
			if (handledByJoystick) 
				[KKIM.inputLayer.joystick ccTouchMoved:joystickTouch withEvent:event];
			break;
	}
}

-(void) kkTouchesEnded:(NSMutableSet *)touches withEvent:(UIEvent *)event
{
	if (!handledByJoystick) 
		[self handlePaddlesTouches:touches ofType:ccTouchEnded];
	
	if (accelerationMode == kAccelerationUnknown) return;
	
	int n = [[event allTouches] count] - [touches count];
	accelerationMode = [self accelerationModeFromTouches:n withEvent:n];
	
	switch (gameEngine.inputMode) {
		case kInputModeSlide:
			if (accelerationMode != kAccelerationUnknown) {
				[touches removeAllObjects];
			}
			[self cleanAccelerationSlide];
			break;
		case kInputModeJoystick:
			if (handledByJoystick && [touches containsObject:joystickTouch]) {
				[KKIM.inputLayer.joystick ccTouchEnded:joystickTouch withEvent:event];
				[KKIM.inputLayer showJoystick:NO];
				joystickTouch = nil;
				handledByJoystick = NO;
			}
			break;
	}
}

-(void) kkTouchesCancelled:(NSMutableSet *)touches withEvent:(UIEvent *)event
{
	[self kkTouchesEnded:touches withEvent:event];
}

#pragma mark -
#pragma mark Title

#define DEFAULT_TITLE_FOD 0.1
#define DEFAULT_TITLE_HD 0.0
#define DEFAULT_TITLE_FID 0.1

-(void) setTitle:(CCBitmapFontAtlas *)label toString:(NSString *)str
{
	[titleLabel setString:NSLocalizedString(str, @"levelTitle")];
}

-(void) setTitle:(NSString *)str
{
	if (currentScreen)
		[self setTitle:str color:currentScreen.titleColor];
}

-(void) setTitle:(NSString *)str color:(ccColor3B)color
{
	[self setTitle:str color:color fadeOutDuration:-1 hiddenDuration:-1 fadeInDuration:-1];
}

-(void) setTitle:(NSString *)str color:(ccColor3B)color fadeOutDuration:(float)fod hiddenDuration:(float)hd fadeInDuration:(float)fid
{
	fod = (fod == -1 ? DEFAULT_TITLE_FOD : fod);
	hd = (hd == -1 ? DEFAULT_TITLE_HD : hd);
	fid = (fid == -1 ? DEFAULT_TITLE_FID : fid);
	
	[titleLabel stopActionByTag:kLevelActionTitle];
	CCAction *action = [CCSequence actions:
						[CCFadeTo actionWithDuration:fod opacity:0], 
						[CCCallFuncND actionWithTarget:self selector:@selector(setTitle:toString:) data:str],
						[CCDelayTime actionWithDuration:hd],
						[CCSpawn actions:[CCTintTo actionWithDuration:fid red:color.r green:color.g blue:color.b], [CCFadeTo actionWithDuration:fid opacity:255], nil],
						nil
	];
	action.tag = kLevelActionTitle;
	[titleLabel runAction:action];
}

#pragma mark -
#pragma mark Description

#define DEFAULT_DESCRIPTION_FOD 0.1
#define DEFAULT_DESCRIPTION_HD 0.0
#define DEFAULT_DESCRIPTION_FID 0.1
#define DEFAULT_DESCRIPTION_DURATION 10

-(void) setDescription:(CCBitmapFontAtlas *)label toString:(NSString *)str
{
	[descriptionLabel setString:NSLocalizedString(str, @"levelDescription")];
}

-(void) setDescription:(NSString *)str
{
	if (self.currentScreen)
		[self setDescription:str color:currentScreen.descriptionColor];
}

-(void) setDescription:(NSString *)str color:(ccColor3B)color
{
	[self setDescription:str color:color fadeOutDuration:-1 hiddenDuration:-1 fadeInDuration:-1];
}

-(void) setDescription:(NSString *)str color:(ccColor3B)color fadeOutDuration:(float)fod hiddenDuration:(float)hd fadeInDuration:(float)fid
{
	fod = (fod == -1 ? DEFAULT_DESCRIPTION_FOD : fod);
	hd = (hd == -1 ? DEFAULT_DESCRIPTION_HD : hd);
	fid = (fid == -1 ? DEFAULT_DESCRIPTION_FID : fid);
	
	[descriptionLabel stopActionByTag:kLevelActionDescription];
	CCAction *action = [CCSequence actions:
						[CCFadeTo actionWithDuration:fod opacity:0], 
						[CCCallFuncND actionWithTarget:self selector:@selector(setDescription:toString:) data:str],
						[CCDelayTime actionWithDuration:hd],
						[CCSpawn actions:[CCTintTo actionWithDuration:fid red:color.r green:color.g blue:color.b], [CCFadeTo actionWithDuration:fid opacity:255], nil],
//						[CCDelayTime actionWithDuration:DEFAULT_DESCRIPTION_DURATION],
//						[CCFadeTo actionWithDuration:fod*10 opacity:0], 
						nil
						];
	action.tag = kLevelActionDescription;
	[descriptionLabel runAction:action];
}

#pragma mark -
#pragma mark Messages

/*
#define DEFAULT_MESSAGE_FOD 0.1
#define DEFAULT_MESSAGE_HD 0.0
#define DEFAULT_MESSAGE_FID 0.1
#define DEFAULT_MESSAGE_DURATION 0.1
#define DEFAULT_MESSAGE_SPEED 4

-(void) setMessageEnabled:(BOOL)f
{
	if (!currentScreen || f == currentScreen.messageEnabled) return;
	
	int o = (f ? 255 : 0);
	CCAction *a;
	
	CCFadeTo *fadeToAction = [CCFadeTo actionWithDuration:DEFAULT_MESSAGE_FID opacity:o];
	fadeToAction.tag = kLevelActionMessageFadeTo;
	
	[messageLabel stopActionByTag:kLevelActionMessage];
	[messageLabel stopActionByTag:kLevelActionMessageMove];
	[messageLabel stopActionByTag:kLevelActionMessageTintTo];
	[messageLabel stopActionByTag:kLevelActionMessageFadeTo];

	if (f) {
		a = [CCSequence actions:[CCShow action], fadeToAction, nil];
		[self setMessage:nil];
	} else {
		a = [CCSequence actions:fadeToAction, [CCHide action], nil];
	}
	[messageLabel runAction:a];
}

-(void) messageEnded
{
	messageEnded = YES;
}

-(void) setMessage:(CCBitmapFontAtlas *)label toString:(NSString *)str
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	[messageLabel stopActionByTag:kLevelActionMessageMove];
	if (str != nil)
		[messageLabel setString:NSLocalizedString(str, @"levelMessage")];
	CGSize ms = [messageLabel contentSize];
	if (str != nil)
		[messageLabel setPosition:ccp (ws.width, ms.height + SCALE_Y(RANDOM_INT (-20, 30)))];
	
	CCAction *moveAction = [CCSequence actions:
							[CCMoveBy actionWithDuration:DEFAULT_MESSAGE_DURATION * ((messageLabel.position.x + ms.width) / DEFAULT_MESSAGE_SPEED)
												position:ccp (-(messageLabel.position.x + ms.width), 0)],
							[CCCallFunc actionWithTarget:self selector:@selector(messageEnded)],
							nil
							];
	moveAction.tag = kLevelActionMessageMove;
	[messageLabel runAction:moveAction];
}

-(void) setMessageForCurrentScreen
{
	if (currentScreen && currentScreen.messageEnabled)
		[self setMessage:[gameEngine screenMessageWithIndex:currentScreen.index]];
}

-(void) setMessage:(NSString *)str
{
	if (self.currentScreen)
		[self setMessage:str color:currentScreen.messageColor];
}

-(void) setMessage:(NSString *)str color:(ccColor3B)c
{
	[self setMessage:str color:c opacity:-1];
}

-(void) setMessage:(NSString *)str color:(ccColor3B)c opacity:(int)o
{
	[self setMessage:str color:c opacity:o fadeOutDuration:-1 hiddenDuration:-1 fadeInDuration:-1];
}

-(void) setMessage:(NSString *)str color:(ccColor3B)c opacity:(int)o fadeOutDuration:(float)fod hiddenDuration:(float)hd fadeInDuration:(float)fid
{
	if (!currentScreen) return;
	
	fod = (fod == -1 ? DEFAULT_MESSAGE_FOD : fod);
	hd = (hd == -1 ? DEFAULT_MESSAGE_HD : hd);
	fid = (fid == -1 ? DEFAULT_MESSAGE_FID : fid);
	o = (o == -1 ? currentScreen.messageOpacity : o);
	
	[messageLabel stopActionByTag:kLevelActionMessage];
	[messageLabel stopActionByTag:kLevelActionMessageMove];
	[messageLabel stopActionByTag:kLevelActionMessageTintTo];
	[messageLabel stopActionByTag:kLevelActionMessageFadeTo];
	
	CCTintTo *tintToAction = [CCTintTo actionWithDuration:fid red:c.r green:c.g blue:c.b];
	tintToAction.tag = kLevelActionMessageTintTo;

	CCFadeTo *fadeToAction = [CCFadeTo actionWithDuration:fid opacity:o];
	fadeToAction.tag = kLevelActionMessageFadeTo;
	
	CCAction *action = [CCSequence actions:
						[CCFadeTo actionWithDuration:fod opacity:0], 
						[CCCallFuncND actionWithTarget:self selector:@selector(setMessage:toString:) data:str],
						[CCDelayTime actionWithDuration:hd],
						[CCSpawn actions:tintToAction, fadeToAction,nil],
						nil
						];
	action.tag = kLevelActionMessage;
	[messageLabel runAction:action];
	messageEnded = NO;
}

-(void) messageTintToColor:(ccColor3B)c
{
	if (!currentScreen || !currentScreen.messageEnabled) return;

	[messageLabel stopActionByTag:kLevelActionMessageTintTo];
	CCAction *tintToAction = [CCTintTo actionWithDuration:DEFAULT_MESSAGE_FID red:c.r green:c.g blue:c.b];
	tintToAction.tag = kLevelActionMessageTintTo;
	
	[messageLabel runAction:tintToAction];
}

-(void) messageFadeToOpacity:(int)o
{
	if (!currentScreen || !currentScreen.messageEnabled) return;
	
	[messageLabel stopActionByTag:kLevelActionMessageFadeTo];
	CCAction *fadeToAction = [CCFadeTo actionWithDuration:DEFAULT_MESSAGE_FID opacity:o];
	fadeToAction.tag = kLevelActionMessageFadeTo;
	[messageLabel runAction:fadeToAction];
}
*/

#pragma mark -
#pragma mark Lights

-(void) resetLightGridOpacity
{
	int o = 1;
	
	if (currentScreen) {
		o = [[currentScreen.data objectForKey:@"lightGridOpacity"] intValue];
	}	
	if (o == -1)
		o = [[data objectForKey:@"lightGridOpacity"] intValue];
	
	if (o == lightGrid.opacity) return;
	
	[lightGrid stopActionByTag:kLevelActionLightGridFadeTo];
	CCAction *action = [CCFadeTo actionWithDuration:[self getFloatForKey:@"lightGridOpacityDuration" withDefault:0.3] 
											opacity:o];
	action.tag = kLevelActionLightGridFadeTo;
	[lightGrid runAction:action];
}

#pragma mark -
#pragma mark Background Image

-(void) hideBGImage:(int)i
{
	if (!bgImages[i].visible) return;
	
	CCAction *action = [CCSequence actions:
						[CCFadeTo actionWithDuration:BGIMAGE_HIDE_DURATION opacity:0],
						[CCHide action],
						nil
						];
	action.tag = kLevelActionBGImageFadeTo;
	[bgImages[i] stopActionByTag:kLevelActionBGImageFadeTo];
	[bgImages[i] runAction:action];
}

-(void) setBGImage:(int)i texture:(NSString *)imageName position:(CGPoint)pos opacity:(int)o duration:(float)d 
{
	CCSprite *img = bgImages[i];
	CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:[gameEngine pathForLevelGraphic:imageName]];

	BOOL v = img.visible;
	
	if (texture) {
		CGRect rect = CGRectZero;
		rect.size = texture.contentSize;
		[img setTexture:texture];
		[img setTextureRect:rect];
		[img setOpacityModifyRGB:NO];
		[img setScaleX:SCALE_X(1)];
		[img setScaleY:SCALE_Y(1)];
		
		id a;
		if (v) {
			a = [CCFadeTo actionWithDuration:d opacity:0];
		} else {
			a = [CCShow action];
		}

		CCAction *sa = [CCSequence actions:
						a,
						[CCSpawn actions:
						 [CCFadeTo actionWithDuration:d opacity:o],
						 [CCMoveTo actionWithDuration:BGIMAGE_MOVE_DURATION position:pos],
						 nil],
						nil
						];
		sa.tag = kLevelActionBGImageFadeTo;
		[img stopActionByTag:kLevelActionBGImageFadeTo];
		[img runAction:sa];
	} else if (v) {
		[self hideBGImage:i];
	}
}

-(void) unsetBGImage:(int)idx
{
	CCSprite *img = bgImages[idx];
	CCTexture2D *texture = [img texture];
	
	if (texture) {
		CGRect rect = CGRectZero;
		[img setTexture:nil];
		[img setTextureRect:rect];
		
		[[CCTextureCache sharedTextureCache] removeTexture:texture];
	}
}

-(void) setupBackgroundImages
{
	for (int i = 0; i < MAX_BG_IMAGES; i++) {
		NSString *imageName = [self getStringForKey:[NSString stringWithFormat:@"bgImage%d", i] withDefault:@""];
		
		if (imageName != nil && ![imageName isEqualToString:@""]) {
			CGPoint p = bgImages[i].position;
			
			CGPoint pos = SCALE_POINT(CGPointMake(
							  [self getFloatForKey:[NSString stringWithFormat:@"bgImage%dPositionX", i] withDefault:p.x], 
							  [self getFloatForKey:[NSString stringWithFormat:@"bgImage%dPositionY", i] withDefault:p.y] 
							  ));
			[self setBGImage:i 
					 texture:imageName 
					position:pos
					  opacity:[self getIntForKey:[NSString stringWithFormat:@"bgImage%dOpacity", i] withDefault:BG_IMAGE_OPACITY]
					 duration:[self getFloatForKey:[NSString stringWithFormat:@"bgImage%dShowDuration", i] withDefault:BGIMAGE_SHOW_DURATION]
			 ];
		} else {
			[self hideBGImage:i];
		}
	}
	
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
}

#pragma mark -
#pragma mark Screens

-(NSMutableDictionary *) screenData:(KKScreen *)screen
{
	return [[data objectForKey:@"screens"] objectAtIndex:screen.index];
}

-(void) tintToColor:(ccColor3B)c
{
	[self tintToColor:c withDuration:screenShowDuration mode:kEntityColorModeSolid];
}

-(void) tintToColor:(ccColor3B)c withDuration:(float)duration mode:(int)mode
{
	CCAction *action;
	
	[self stopActionByTag:kLevelActionScreenColor];
	[self stopActionByTag:kLevelActionScreenColorTintTo];
	
	switch (mode) {
		case kEntityColorModeTintTo:
			action = [CCSequence actions:
					  [CCTintTo actionWithDuration:duration*3 red:c.r green:c.g blue:c.b],
					  [CCCallFunc actionWithTarget:self selector:@selector(startScreenColorModeTintTo)],
					  nil
					  ];
			break;
		case kEntityColorModeSolid:
		default:
			action = [CCTintTo actionWithDuration:duration*3 red:c.r green:c.g blue:c.b];
			break;
	}
	action.tag = kLevelActionScreenColor;
	
	[self runAction:action];	
}

-(void) startScreenColorModeTintTo
{
	[self stopActionByTag:kLevelActionScreenColorTintTo];
	
	CCAction *action = [CCRepeatForever actionWithAction:[CCSequence actions:
														 [CCTintTo actionWithDuration:currentScreen.colorTintToDuration red:currentScreen.color2.r green:currentScreen.color2.g blue:currentScreen.color2.b],
														 [CCTintTo actionWithDuration:currentScreen.colorTintToDuration red:currentScreen.color1.r green:currentScreen.color1.g blue:currentScreen.color1.b],
														 nil
														 ]
					   ];
	action.tag = kLevelActionScreenColorTintTo;
	
	[self runAction:action];
}

-(void) setScreenColor:(KKScreen *)screen withDuration:(float)duration
{
	[self tintToColor:screen.color1 withDuration:duration mode:screen.colorMode];
}

-(void) showScreen:(KKScreen *)screen
{
	[self showScreen:screen withDuration:screenShowDuration];
}

-(void) showScreen:(KKScreen *)screen withDuration:(float)duration
{
	CGSize ws = [[CCDirector sharedDirector] winSize];

	[entitiesLayer stopActionByTag:kLevelActionShowScreen];
	
	screenScaleX = 1.0 / ((1.0 / ws.width) * screen.size.width);
	screenScaleY = 1.0 / ((1.0 / ws.height) * screen.size.height);
	
	CGPoint pos = ccp(-screen.position.x, -screen.position.y);
	
	[self setCurrentScreen:screen];
	[self setScreenBorders:screen withDuration:duration];
	[self setTitle:screen.title];
	[self setDescription:screen.desc];
	[self setScreenColor:screen withDuration:duration];
	
	if (CGPointEqualToPoint (entitiesLayer.position, pos) && 
		entitiesLayer.scaleX == screenScaleX &&
		entitiesLayer.scaleY == screenScaleY) return;
	
	CCAction *action = [CCSequence actions:[CCCallFunc actionWithTarget:gameEngine selector:@selector(disableUpdate)],
						[CCSpawn actions:
						 [CCMoveTo actionWithDuration:duration position:pos],
						 [CCScaleTo actionWithDuration:duration scaleX:screenScaleX scaleY:screenScaleY],
						 nil
						],
						[CCCallFunc actionWithTarget:gameEngine selector:@selector(enableUpdate)],
						nil
						];
	action.tag = kLevelActionShowScreen;
	[entitiesLayer runAction:action];
}

-(KKScreen *) screenAtIndex:(int)idx
{
	if (idx >= 0 && idx < numScreens)
		return screens[idx];
	else {
		KKLOG (@"invalid index %d [0, %d]", idx, numScreens - 1);
		return nil;
	}
}

-(KKScreen *) screenWithName:(NSString *)name
{
	KKScreen *s = nil;
	
	for (int i = 0; i < numScreens; i++) {
		if ([screens[i].name isEqualToString:name]) {
			s = screens[i];
			break;
		}
	}
	return s;
}

-(int) screenWithNameIndex:(NSString *)name
{
	int r = -1;
	
	for (int i = 0; i < numScreens; i++) {
		if ([screens[i].name isEqualToString:name]) {
			r = i;
			break;
		}
	}
	return r;
}

-(int) firstScreenIndex
{
	return [self screenWithNameIndex:[data objectForKey:@"firstScreen"]];
}

-(KKScreen *) firstScreen
{
	return [self screenAtIndex:self.firstScreenIndex];
}

-(int) currentScreenIndex
{
	return currentScreen != nil ? currentScreen.index : -1;
}

-(void) setCurrentScreen:(KKScreen *)screen
{
	KKScreen *prevScreen = currentScreen;
	
	if (currentScreen) [currentScreen onExit];
	
	currentScreen = screen;

	int index = -1;
	
	if (screen != nil) {
		index = currentScreen.index;

		minSpeed = SCALE_POINT(ccp (
									[self getNZFloatForKey:@"minSpeedX" withDefault:DEFAULT_ACCELERATION_MIN_X], 
									[self getNZFloatForKey:@"minSpeedY" withDefault:DEFAULT_ACCELERATION_MIN_Y]
									));
		maxSpeed = SCALE_POINT(ccp (
									[self getNZFloatForKey:@"maxSpeedX" withDefault:DEFAULT_ACCELERATION_MIN_X], 
									[self getNZFloatForKey:@"maxSpeedY" withDefault:DEFAULT_ACCELERATION_MIN_Y]
									));
		
		
		accelerationInputX = [self getBoolForKey:@"accelerationInputX" withDefault:DEFAULT_ACCELERATION_INPUT_X];
		accelerationInputY = [self getBoolForKey:@"accelerationInputY" withDefault:DEFAULT_ACCELERATION_INPUT_Y];
		accelerationViscosity = ccp (
									 [self getNZFloatForKey:@"accelerationViscosityX" withDefault:DEFAULT_ACCELERATION_VISCOSITY_X], 
									 [self getNZFloatForKey:@"accelerationViscosityY" withDefault:DEFAULT_ACCELERATION_VISCOSITY_Y]
									 );
		accelerationFactor = ccp (
								  [self getNZFloatForKey:@"accelerationFactorX" withDefault:DEFAULT_ACCELERATION_FACTOR_X], 
								  [self getNZFloatForKey:@"accelerationFactorY" withDefault:DEFAULT_ACCELERATION_FACTOR_Y]
								  );
		accelerationMin = SCALE_POINT(ccp (
								  [self getNZFloatForKey:@"accelerationMinX" withDefault:DEFAULT_ACCELERATION_MIN_X], 
								  [self getNZFloatForKey:@"accelerationMinY" withDefault:DEFAULT_ACCELERATION_MIN_Y]
								  ));
		accelerationMax = SCALE_POINT(ccp (
							   [self getNZFloatForKey:@"accelerationMaxX" withDefault:DEFAULT_ACCELERATION_MAX_X], 
							   [self getNZFloatForKey:@"accelerationMaxY" withDefault:DEFAULT_ACCELERATION_MAX_Y]
							   ));
		
		gravity = SCALE_POINT(ccp (
								   [self getNZFloatForKey:@"gravityX" withDefault:0], 
								   [self getNZFloatForKey:@"gravityY" withDefault:0]
					   ));
		
		friction = [self getNZFloatForKey:@"friction" withDefault:1];
	}
	
	[self resetLightGridOpacity];
	
	//messageEnded = YES;
	
	levelSetCurrentScreen(index);
	
	[gameEngine setCurrentScreen:currentScreen prevScreen:prevScreen];
	
	[self setupBackgroundImages];
	 
	if (currentScreen) [currentScreen onEnter];
}

-(KKScreen *) currentScreen
{
	return currentScreen;
}

// orders array in descending order
NSInteger sortedPaddlesArraySort (id idx1, id idx2, void *contect)
{
	KKLevel *level = [KKGE level];
	KKPaddle *p1 = [level paddleAtIndex:[idx1 intValue]];
	KKPaddle *p2 = [level paddleAtIndex:[idx2 intValue]];
	
	if (p1.z > p2.z) return NSOrderedAscending;
	else if (p1.z < p2.z) return NSOrderedDescending;
	else return NSOrderedSame;
}

-(void) updatePaddlesAndScreensArrays
{
	[paddlesArray removeAllObjects];
	[screensArray removeAllObjects];
	
	[paddlesArray unionSet:globalPaddlesArray];
	
	for (KKScreen *s in activeScreens) {
		[screensArray addObject:[NSNumber numberWithInt:s.index]];
		
		[paddlesArray addObjectsFromArray:[s paddlesIndexArray]];
	}
	
	// sort paddles by z
	if (sortedPaddlesArray) [sortedPaddlesArray release];
	sortedPaddlesArray = [[NSMutableArray arrayWithArray:[paddlesArray allObjects]] retain];
	[sortedPaddlesArray sortUsingFunction:sortedPaddlesArraySort context:nil];
//	KKLOG (@"count: %d", [paddlesArray count]);
}

-(void) setScreenWithIndex:(int)idx shown:(BOOL)f
{
	[self setScreen:[self screenAtIndex:idx] shown:f];
}

-(void) setScreen:(KKScreen *)s shown:(BOOL)f
{
	if (s) {
		[s setShown:f];
		
		[self updatePaddlesAndScreensArrays];
	}
}

-(void) setScreenWithName:(NSString *)name shown:(BOOL)f
{
	[self setScreenWithIndex:[self screenWithNameIndex:name] shown:f];
}

-(void) setScreenWithIndex:(int)idx active:(BOOL)f
{
	[self setScreen:[self screenAtIndex:idx] active:f];
}

-(void) setScreen:(KKScreen *)s active:(BOOL)f
{
	if (s) {
		[s setActive:f];
		
		if (f) {
			[activeScreens addObject:s];
			[self showScreen:s];
		} else {
			[activeScreens removeObject:s];
		}
		
		[self updatePaddlesAndScreensArrays];
	}
}

-(void) setScreenWithName:(NSString *)name active:(BOOL)f
{
	[self setScreenWithIndex:[self screenWithNameIndex:name] active:f];	
}

-(KKScreen *) findNextScreen:(KKScreen *)screen atSide:(int)side forHero:(KKHero *)hero
{
	KKScreen *nextScreen = nil;
	KKScreen *s;
	
	float px = screen.position.x;
	float py = screen.position.y;
	float w = screen.size.width;
	float h = screen.size.height;
	
	CGRect screenRect = CGRectMake(px, py, w, h);

	if (side & kSideTop) {
		for (int i=0; i < numScreens; i++) {
			s = screens[i];			
			
			if (s == screen) continue;
			
			CGRect sRect = CGRectMake(s.position.x, s.position.y, s.size.width, s.size.height);
			if (CGRectIntersectsRect(screenRect, sRect)) {
				if ((s.position.y <= py + h) &&
					(s.position.y > py) &&
					(s.position.y + s.size.height > py + h) &&
					CGRectIntersectsRect(sRect, hero.bbox)) {
					nextScreen = s;
					break;
				}
			}
		}
	} else if (side & kSideBottom) {
		for (int i=0; i < numScreens; i++) {
			s = screens[i];			
			
			if (s == screen) continue;
			
			CGRect sRect = CGRectMake(s.position.x, s.position.y, s.size.width, s.size.height);
			if (CGRectIntersectsRect(screenRect, sRect)) {
				if ((s.position.y + s.size.height > py) &&
					(s.position.y + s.size.height <= py + h) &&
					(s.position.y < py) &&
					CGRectIntersectsRect(sRect, hero.bbox)) {
					nextScreen = s;
					break;
				}
			}
		}
	} else if (side & kSideLeft) {
		for (int i=0; i < numScreens; i++) {
			s = screens[i];			
			
			if (s == screen) continue;
			
			CGRect sRect = CGRectMake(s.position.x, s.position.y, s.size.width, s.size.height);
			if (CGRectIntersectsRect(screenRect, sRect)) {
				if ((s.position.x < px) &&
					(s.position.x + s.size.width >= px) &&
					(s.position.x + s.size.width <= px + w) &&
					CGRectIntersectsRect(sRect, hero.bbox)) {
					nextScreen = s;
					break;
				}
			}
		}
	} else if (side & kSideRight) {
		for (int i=0; i < numScreens; i++) {
			s = screens[i];			

			CGRect sRect = CGRectMake(s.position.x, s.position.y, s.size.width, s.size.height);
			if (CGRectIntersectsRect(screenRect, sRect)) {
				if ((s.position.x >= px) &&
					(s.position.x <= px + w) && 
					(s.position.x + s.size.width > px + w) &&
					CGRectIntersectsRect(sRect, hero.bbox)) {
					nextScreen = s;
					break;
				}
			}
		}
	}
	
	return nextScreen;
}

#pragma mark -
#pragma mark Paddles

-(KKPaddle *) paddleAtIndex:(int)idx
{
	if (idx >= 0 && idx < numPaddles)
		return paddles[idx];
	else {
		KKLOG (@"invalid index %d [0, %d]", idx, numPaddles - 1);
		return nil;
	}
}

-(KKPaddle *) paddleWithName:(NSString *)name
{
	KKPaddle *s = nil;
	
	for (int i = 0; i < numPaddles; i++) {
		if ([paddles[i].name isEqualToString:name]) {
			s = paddles[i];
			break;
		}
	}
	return s;
}

#pragma mark -
#pragma mark Heroes

-(void) initHeroes
{
	numHeroes = 0;
	mainHero = nil;
	mainHeroIndex = -1;
}

-(void) destroyHeroes
{
	for (int i = 0; i< MAX_HEROES; i++) {
		if (heroes[i]) {
			[heroes[i] release];
			heroes[i] = nil;
		}
	}
}

-(int) findFreeHeroIndex
{
	int index = -1;
	
	for (int i = 0; i < MAX_HEROES; i++) {
		if (!heroes[i]) {
			index = i;
			break;
		}
	}
	return index;
}

-(void) updateHeroesArray
{
	[heroesArray removeAllObjects];
	
	for (int i = 0; i < MAX_HEROES; i++) {
		if (heroes[i]) {
			[heroesArray addObject:[NSNumber numberWithInt:i]];
		}
	}
}

-(KKHero *) addHeroOfKind:(tHeroKind)hKind flags:(tHeroFlag)hFlags size:(CGSize)hSize
{
	int index = [self findFreeHeroIndex];
	
	if (index == -1) return nil;
	
	KKHero *hero = [[KKHero alloc] initWithLevel:self];
	
	hero.kind = hKind;
	hero.flags = hFlags;
	hero.size = hSize;
	hero.index = index;

	heroes[index] = hero;
	numHeroes++;
	
	if ([hero isMainHero]) {
		mainHero = hero;
		mainHeroIndex = index;
		[luaManager execString:[NSString stringWithFormat:@"mainHero.index = %d", index]];
	}
	[self updateHeroesArray];
	
	[entitiesLayer addChild:hero z:HERO_Z];
	
	return hero;
}

-(void) removeHeroAtIndex:(int)index
{
	if (index >= 0 && index < numHeroes) {
		KKHero *hero = heroes[index];
		if (hero) {
			[entitiesLayer removeChild:hero cleanup:YES];
			if ([hero isMainHero]) {
				mainHero = nil;
				mainHeroIndex = -1;
			}
			[hero release];
			heroes[index] = nil;
			numHeroes--;
			
			[self updateHeroesArray];
		}
	}
}

-(void) removeHero:(KKHero *)hero
{
	[self removeHeroAtIndex:hero.index];
}

-(KKHero *) heroAtIndex:(int)index
{
	if (index >= 0 && index < numHeroes) {
		return heroes[index];
	} else {
		KKLOG (@"invalid index %d [%d, %d]", index, 0, numHeroes);
	}
	return nil;
}

-(KKHero *) heroWithFlags:(int)hFlags
{
	KKHero *hero = nil;
	
	for (int i = 0; i < MAX_HEROES; i++) {
		if (heroes[i] && (heroes[i].flags & hFlags)) {
			hero = heroes[i];
			break;
		}
	}
	return hero;
}

-(KKHero *) mainHero
{
	return mainHero;
}

-(int) mainHeroIndex
{
	return mainHeroIndex;
}

-(void) setupMainHero
{
	CGSize s = SCALE_SIZE (CGSizeMake(
									  DICT_FLOAT (data, @"heroWidth", HERO_DEFAULT_WIDTH),
									  DICT_FLOAT (data, @"heroHeight", HERO_DEFAULT_HEIGHT)
									  )
						   );
	KKHero *hero = [self addHeroOfKind:kHeroKindDefault flags:kHeroFlagIsMain size:s];
	[hero updateHeroColorModeSolid:ccc3FromNsString (DICT_STRING (data, @"heroStartColor", @"255,255,255"))];
	
	[self resetMainHeroPosition];
}

-(void) resetMainHeroPosition
{
	CGPoint sp = [self firstScreen].position;
	CGPoint p = SCALE_POINT (ccp (
								  DICT_FLOAT (data, @"heroStartPositionX", 50),
								  DICT_FLOAT (data, @"heroStartPositionY", 180)
								  ));
							 
	[mainHero setPosition:ccpAdd (p, sp)];
	mainHero.acceleration = SCALE_POINT (ccp (
							 DICT_FLOAT (data, @"heroStartAccelerationX", 0),
							 DICT_FLOAT (data, @"heroStartAccelerationY", 0)
							 ));
	mainHero.speed = SCALE_POINT(ccp (
					  DICT_FLOAT (data, @"heroStartSpeedX", 0),
					  DICT_FLOAT (data, @"heroStartSpeedY", 0)
					  ));
	mainHero.lightEnabled = DICT_BOOL (data, @"heroStartLightEnabled", NO);
}

-(void) moveMainHeroToScreenIndex:(int)screenIdx
{
	[self moveMainHeroToScreenIndex:screenIdx atPosition:[mainHero positionToDisplay]];
}

-(void) moveMainHeroToScreen:(KKScreen *)screen
{
	[self moveMainHeroToScreen:screen atPosition:[mainHero positionToDisplay]];
}

-(void) moveMainHeroToScreenIndex:(int)screenIdx atPosition:(CGPoint)pos
{
	KKScreen *screen = [self screenAtIndex:screenIdx];
	[self moveMainHeroToScreen:screen atPosition:pos];
}

-(void) moveMainHeroToScreen:(KKScreen *)screen atPosition:(CGPoint)pos
{
	[gameEngine moveMainHeroToScreen:screen atPosition:pos];
}

#pragma mark -
#pragma mark Data Utilities

-(BOOL) getBoolForKey:(NSString *)key withDefault:(BOOL)d
{
	BOOL r = d;
	BOOL found = NO;
	
	if (currentScreen != nil) {
		NSDictionary *sd = [self screenData:currentScreen];
		if ([sd objectForKey:key]) {
			r = [[sd objectForKey:key] boolValue];
			found = YES;
		}
	}
	
	if (!found) {
		if ([data objectForKey:key]) {
			r = [[data objectForKey:key] boolValue];
			found = YES;
		}
	}
	
	return r;
}

-(int) getIntForKey:(NSString *)key withDefault:(int)d
{
	int r = d;
	BOOL found = NO;
	
	if (currentScreen != nil) {
		NSDictionary *sd = [self screenData:currentScreen];
		if ([sd objectForKey:key]) {
			r = [[sd objectForKey:key] intValue];
			found = YES;
		}
	}
	
	if (!found) {
		if ([data objectForKey:key]) {
			r = [[data objectForKey:key] intValue];
			found = YES;
		}
	}
	
	return r;
}

-(float) getFloatForKey:(NSString *)key withDefault:(float)d
{
	float r = d;
	BOOL found = NO;
	
	if (currentScreen != nil) {
		NSDictionary *sd = [self screenData:currentScreen];
		if ([sd objectForKey:key]) {
			r = [[sd objectForKey:key] floatValue];
			found = YES;
		}
	}
	
	if (!found) {
		if ([data objectForKey:key]) {
			r = [[data objectForKey:key] floatValue];
			found = YES;
		}
	}
	
	return r;
}

-(NSString *) getStringForKey:(NSString *)key withDefault:(NSString *)d
{
	NSString *r = d;
	BOOL found = NO;
	
	if (currentScreen != nil) {
		NSMutableDictionary *sd = [self screenData:currentScreen];
		if (sd) {
			r = [sd objectForKey:key];
			if (r && ![r isEqualToString:@""])
				found = YES;
		} else {
			KKLOG (@"unknown screen %d <%@>", currentScreen.index, currentScreen);
		}

	}
	
	if (!found) {
		r = [data objectForKey:key];
		if (!r) r = @"";
	}
	
	return r;
}

#pragma mark -
#pragma mark Non Zero Data Utilities

-(int) getNZIntForKey:(NSString *)key withDefault:(int)d
{
	int r = d;
	BOOL found = NO;
	
	if (currentScreen != nil) {
		NSDictionary *sd = [self screenData:currentScreen];
		if ([sd objectForKey:key]) {
			r = [[sd objectForKey:key] intValue];
			if (r != 0)
				found = YES;
		}
	}
	
	if (!found) {
		if ([data objectForKey:key]) {
			r = [[data objectForKey:key] intValue];
			found = YES;
		}
	}
	
	return r;
}

-(float) getNZFloatForKey:(NSString *)key withDefault:(float)d
{
	float r = d;
	BOOL found = NO;
	
	if (currentScreen != nil) {
		NSDictionary *sd = [self screenData:currentScreen];
		if ([sd objectForKey:key]) {
			r = [[sd objectForKey:key] floatValue];
			if (r != 0)
				found = YES;
		}
	}
	
	if (!found) {
		if ([data objectForKey:key]) {
			r = [[data objectForKey:key] floatValue];
			found = YES;
		}
	}
	
	return r;
}


@end
