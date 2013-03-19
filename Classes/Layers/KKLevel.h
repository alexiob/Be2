//
//  KKLevel.h
//  be2
//
//  Created by Alessandro Iob on 2/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"

#import "KKScreen.h"
#import "KKPaddle.h"
#import "KKHero.h"
#import "KKInputProtocols.h"
#import "KKLightGrid.h"
#import "KKScreenBorder.h"
#import "FontLabel.h"

@class KKGameEngine;
@class KKLuaManager;

#define DEFAULT_ACCELERATION_INPUT_X NO
#define DEFAULT_ACCELERATION_INPUT_Y YES

#define DEFAULT_ACCELERATION_VISCOSITY_X 0.75
#define DEFAULT_ACCELERATION_VISCOSITY_Y 0.75

#define DEFAULT_ACCELERATION_FACTOR_X 1.0
#define DEFAULT_ACCELERATION_FACTOR_Y 1.0

#define DEFAULT_ACCELERATION_MIN_X -100.0
#define DEFAULT_ACCELERATION_MIN_Y -100.0
#define DEFAULT_ACCELERATION_MAX_X 100.0 
#define DEFAULT_ACCELERATION_MAX_Y 100.0

#define MAX_BG_IMAGES 4

typedef enum {
	kLevelActionShowScreen = 100 + 1,
	kLevelActionScaleHero,
	kLevelActionTitle,
	kLevelActionDescription,
	kLevelActionMessage,
	kLevelActionMessageMove,
	kLevelActionMessageTintTo,
	kLevelActionMessageFadeTo,
	kLevelActionScreenColor,
	kLevelActionScreenColorTintTo,
	kLevelActionLightGridFadeTo,
	kLevelActionBGImageFadeTo,
	kLevelActionBGImageMoveTo,
	kLevelActionStartTimer,
} tLevelAction;

typedef enum {
	kLevelFlagLevelUpdate = 1 << 0, // 1
	kLevelFlagScriptUpdate = 1 << 1, // 2
	kLevelFlagShowHUD = 1 << 2, // 4
	kLevelFlagDoNotStartBackgroundMusic = 1 << 3,
} tLevelFlags;

typedef enum {
	kAccelerationUnknown = 0,
	kAccelerationNormal,
	kAccelerationTurbo,
} tAccelerationMode;

#define MAX_HEROES 10

@interface KKLevel : CCColorLayer <KKTouchesDelegateProtocol> {
	KKGameEngine *gameEngine;
	KKLuaManager *luaManager;
	
	NSMutableDictionary *data;
	
	int levelIndex;
	int flags;
	
	int numHeroes;
	KKHero *heroes[MAX_HEROES];
	int mainHeroIndex;
	KKHero *mainHero;
	
	int numPaddles;
	KKPaddle **paddles;
	int numScreens;
	KKScreen **screens;
	KKScreen *currentScreen;
//	KKScreen *nearByScreens[4];
	NSMutableSet *activeScreens;
	float screenScaleX;
	float screenScaleY;
	
	CGPoint minSpeed;
	CGPoint maxSpeed;
	
	int minimumScore;
	float availableTime;
	int availableHeroes;
	
	float screenShowDuration;
	
	CCLayer *entitiesLayer;
	
	NSMutableArray *heroesArray;
	NSMutableArray *screensArray;
	NSMutableSet *paddlesArray;
	NSMutableArray *sortedPaddlesArray;
	NSMutableSet *globalPaddlesArray;
	
	tAccelerationMode accelerationMode;
	CGPoint accelerationStart;
	CGPoint acceleration;
	CGPoint accelerationViscosity;
	CGPoint accelerationFactor;
	CGPoint accelerationMin;
	CGPoint accelerationMax;
	BOOL accelerationInputX;
	BOOL accelerationInputY;

	CGPoint gravity;
	float friction;
	
	float turboSecondsAvailable;
	float turboFactor;
	BOOL wasTurboUsed;
	
	CCBitmapFontAtlas *titleLabel;
	CCBitmapFontAtlas *descriptionLabel;
//	CCBitmapFontAtlas *messageLabel;
//	BOOL messageEnded;
	
	CCSprite *bgImages[MAX_BG_IMAGES];
	
//	KKLightGrid *backgroundGrid;
	KKLightGrid *lightGrid;
	
	NSMutableDictionary *touchToPaddle;
	
	KKScreenBorder *borders[4];
	
	int scorePerSecondLeft;
	
	BOOL handledByJoystick;
	UITouch *joystickTouch;
	float joystickAccelerationFactor;
}

@property (readwrite, nonatomic) float joystickAccelerationFactor;

@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *desc;
@property (readonly, nonatomic) NSString *leaderboard;
@property (readonly, nonatomic) NSMutableDictionary *data;
@property (readonly, nonatomic) NSString *nextLevelName;

@property (readonly, nonatomic) int kind;
@property (readonly, nonatomic) int levelIndex;
@property (readwrite, nonatomic) int flags;
@property (readonly, nonatomic) int difficulty;

@property (readonly, nonatomic) int numHeroes;

@property (readonly, nonatomic) int numPaddles;

@property (readonly, nonatomic) int numScreens;
@property (readonly, nonatomic) int firstScreenIndex;
@property (readonly, nonatomic) KKScreen *firstScreen;
@property (readonly, nonatomic) int currentScreenIndex;
@property (readwrite, nonatomic, assign) KKScreen *currentScreen;
@property (readonly, nonatomic) NSSet *activeScreens;
@property (readwrite, nonatomic) float screenScaleX;
@property (readwrite, nonatomic) float screenScaleY;

@property (readonly, nonatomic) NSArray *heroesArray;
@property (readonly, nonatomic) NSArray *screensArray;
@property (readonly, nonatomic) NSMutableSet *paddlesArray;
@property (readonly, nonatomic) NSArray *sortedPaddlesArray;
@property (readonly, nonatomic) NSMutableSet *globalPaddlesArray;

@property (readonly, nonatomic) KKHero *mainHero;
@property (readonly, nonatomic) int mainHeroIndex;

@property (readwrite, nonatomic) CGPoint minSpeed;
@property (readwrite, nonatomic) CGPoint maxSpeed;

@property (readonly, nonatomic) int minimumScore;
@property (readonly, nonatomic) float availableTime;
@property (readonly, nonatomic) int availableHeroes;

@property (readwrite, nonatomic) float screenShowDuration;

@property (readwrite, nonatomic) tAccelerationMode accelerationMode;
@property (readwrite, nonatomic) CGPoint accelerationStart;
@property (readwrite, nonatomic) CGPoint acceleration;
@property (readwrite, nonatomic) CGPoint accelerationViscosity;
@property (readwrite, nonatomic) CGPoint accelerationFactor;
@property (readwrite, nonatomic) CGPoint accelerationMin;
@property (readwrite, nonatomic) CGPoint accelerationMax;
@property (readwrite, nonatomic) BOOL accelerationInputX;
@property (readwrite, nonatomic) BOOL accelerationInputY;

@property (readwrite, nonatomic) CGPoint gravity;
@property (readwrite, nonatomic) float friction;

@property (readwrite, nonatomic) float turboSecondsAvailable;
@property (readwrite, nonatomic) float turboFactor;
@property (readwrite, nonatomic) BOOL wasTurboUsed;

@property (readonly, nonatomic) KKLightGrid *lightGrid;

@property (readonly, nonatomic) CCBitmapFontAtlas *titleLabel;
@property (readonly, nonatomic) CCBitmapFontAtlas *descriptionLabel;
//@property (readonly, nonatomic) CCBitmapFontAtlas *messageLabel;

@property (readonly, nonatomic) NSString *audioBackgroundMusic;
@property (readonly, nonatomic) NSString *audioInSound;
@property (readonly, nonatomic) NSString *audioOutSound;

@property (readwrite, nonatomic) int scorePerSecondLeft;


-(id) initWithData:(NSMutableDictionary *)levelData;

-(void) initLevel:(NSMutableDictionary *)levelData;
-(void) destroyLevel;
-(void) setupLevel;

-(void) setupScripts:(NSString *)scriptsData;

-(void) setupMainHero;
-(void) resetMainHeroPosition;

-(void) update:(ccTime)dt;

-(void) setTitle:(CCBitmapFontAtlas *)label toString:(NSString *)str;
-(void) setTitle:(NSString *)str;
-(void) setTitle:(NSString *)str color:(ccColor3B)color;
-(void) setTitle:(NSString *)str color:(ccColor3B)color fadeOutDuration:(float)fod hiddenDuration:(float)hd fadeInDuration:(float)fid;

-(void) setDescription:(CCBitmapFontAtlas *)label toString:(NSString *)str;
-(void) setDescription:(NSString *)str;
-(void) setDescription:(NSString *)str color:(ccColor3B)color;
-(void) setDescription:(NSString *)str color:(ccColor3B)color fadeOutDuration:(float)fod hiddenDuration:(float)hd fadeInDuration:(float)fid;

//-(void) setMessageEnabled:(BOOL)f;
//-(void) setMessage:(CCBitmapFontAtlas *)label toString:(NSString *)str;
//-(void) setMessageForCurrentScreen;
//-(void) setMessage:(NSString *)str;
//-(void) setMessage:(NSString *)str color:(ccColor3B)c;
//-(void) setMessage:(NSString *)str color:(ccColor3B)c opacity:(int)o;
//-(void) setMessage:(NSString *)str color:(ccColor3B)c opacity:(int)o fadeOutDuration:(float)fod hiddenDuration:(float)hd fadeInDuration:(float)fid;
//-(void) messageTintToColor:(ccColor3B)c;
//-(void) messageFadeToOpacity:(int)o;

-(void) resetLightGridOpacity;

-(NSMutableDictionary *) screenData:(KKScreen *)screen;

-(void) startScreenColorModeTintTo;
-(void) tintToColor:(ccColor3B)c;
-(void) tintToColor:(ccColor3B)c withDuration:(float)duration mode:(int)mode;

-(void) showScreen:(KKScreen *)screen;
-(void) showScreen:(KKScreen *)screen withDuration:(float)duration;

-(KKScreen *) screenAtIndex:(int)idx;
-(KKScreen *) screenWithName:(NSString *)name;

-(void) setScreenWithIndex:(int)idx shown:(BOOL)f;
-(void) setScreenWithName:(NSString *)name shown:(BOOL)f;
-(void) setScreen:(KKScreen *)s shown:(BOOL)f;

-(void) setScreenWithIndex:(int)idx active:(BOOL)f;
-(void) setScreenWithName:(NSString *)name active:(BOOL)f;
-(void) setScreen:(KKScreen *)s active:(BOOL)f;

-(void) setScreenBorder:(tScreenBorderSide)border active:(BOOL)f;

-(KKScreen *) findNextScreen:(KKScreen *)screen atSide:(int)side forHero:(KKHero *)hero;

-(void) setBGImage:(int)i texture:(NSString *)imageName position:(CGPoint)pos opacity:(int)o duration:(float)d;
-(void) unsetBGImage:(int)idx;

-(KKPaddle *) paddleAtIndex:(int)idx;
-(KKPaddle *) paddleWithName:(NSString *)name;

-(void) initHeroes;
-(void) destroyHeroes;
-(KKHero *) addHeroOfKind:(tHeroKind)hKind flags:(tHeroFlag)hFlags size:(CGSize)hSize;
-(void) removeHeroAtIndex:(int)index;
-(void) removeHero:(KKHero *)hero;
-(KKHero *) heroAtIndex:(int)index;
-(KKHero *) heroWithFlags:(int)hFlags;
-(KKHero *) mainHero;
-(int) mainHeroIndex;
-(void) moveMainHeroToScreenIndex:(int)screenIdx;
-(void) moveMainHeroToScreen:(KKScreen *)screen;
-(void) moveMainHeroToScreenIndex:(int)screenIdx atPosition:(CGPoint)pos;
-(void) moveMainHeroToScreen:(KKScreen *)screen atPosition:(CGPoint)pos;

-(void) initInput;
-(void) destroyInput;
-(void) cleanAccelerationSlide;

-(BOOL) getBoolForKey:(NSString *)key withDefault:(BOOL)d;
-(int) getIntForKey:(NSString *)key withDefault:(int)d;
-(float) getFloatForKey:(NSString *)key withDefault:(float)d;
-(NSString *) getStringForKey:(NSString *)key withDefault:(NSString *)d;

-(int) getNZIntForKey:(NSString *)key withDefault:(int)d;
-(float) getNZFloatForKey:(NSString *)key withDefault:(float)d;

@end
