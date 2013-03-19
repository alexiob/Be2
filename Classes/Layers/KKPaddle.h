//
//  KKPaddle.h
//  be2
//
//  Created by Alessandro Iob on 2/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"

#import "KKEntitiesCommon.h"
#import "KKEntityProtocol.h"

#import "KKHUDMessage.h"

@class KKHero;
@class KKScreen;
@class KKLevel;
@class KKLight;
@class KKLuaManager;
@class KKAIBase;
@class KKGameEngine;

typedef enum {
	kPaddleActionColorTintTo = 300 + 1,
	kPaddleActionFadeTo,
	kPaddleActionClickedFX,
	kPaddleActionInvisible,
} tPaddleAction;

typedef enum {
	kPaddleKindNone = 0,
	kPaddleKindVSlider,
	kPaddleKindHSlider
} tPaddleKind;

typedef enum {
	kPaddleProximityNone = 0,
	kPaddleProximityRect,
	kPaddleProximityDisc
} tPaddleProximity;

typedef enum {
	kPaddleFlagOffensiveSide = 1 << 0,
	kPaddleFlagCollisionDisabled = 1 << 1,
	kPaddleFlagBlockTouches = 1 << 2,
	kPaddleFlagScriptHandleTouches = 1 << 3,
	kPaddleFlagIsButton = 1 << 4,
	kPaddleFlagSelected = 1 << 5,
	kPaddleFlagEnabled = 1 << 6,
	kPaddleFlagScriptOnEnter = 1 << 7,
	kPaddleFlagScriptOnExit = 1 << 8,
	kPaddleFlagScriptApplyProximityInfluenceToHero = 1 << 9,
	kPaddleFlagScriptOnSideToggled = 1 << 10,
	kPaddleFlagScriptUpdate = 1 << 11,
//	kPaddleFlagScriptUpdateAI = 1 << 12,
	kPaddleFlagScriptOnHeroInProxymityArea = 1 << 13,
	kPaddleFlagIsInvisible = 1 << 14,
	kPaddleFlagNoPositionLimit = 1 << 15,
	kPaddleFlagIsGlobal = 1 << 16,
} tPaddleFlag;

typedef enum {
	kPaddleRuntimeFlagClickFX = 1 << 0,
} tPaddleRuntimeFlags;

#define PADDLE_MAX_LIGHTS 10

@interface KKPaddle : CCSprite <KKEntityProtocol> {
	KKGameEngine *gameEngine;
	KKLuaManager *luaManager;
	
	NSMutableDictionary *data;
	KKLevel *level;
	
	int index;
	int kind;
	int flags;
	int runtimeFlags;
	
	int z;
	CGSize size;
	CGPoint acceleration;
	CGPoint speed;
	CGRect bbox;
	CGPoint minPosition;
	CGPoint maxPosition;
	
	tEntityColorMode colorMode;
	ccColor3B color1;
	ccColor3B color2;
	float colorTintToDuration;
	
	float energy;
	float elasticity;
	
	int proximityMode;
	CGSize proximityArea;
	CGPoint proximityAcceleration; 

	int numLights;
	int lights[PADDLE_MAX_LIGHTS];
	
	int visibilityCounter;
	
	NSString *labelFontFile;
	CCBitmapFontAtlas *label;
	
	CCSprite *topImage;
	
	int defensiveAIKind;
	KKAIBase *defensiveAI;
	int offensiveAIKind;
	KKAIBase *offensiveAI;
	
	GLuint audioSoundLoopID;

	int msgIdx;
	ccColor3B msgBGColor;
	ccColor3B msgColor;
	ccColor3B msgIcnColor;
	float msgFontSize;
	
	CGPoint lastMovement;
	float lastMovementTime;
	float audioMoveSoundTimeout;
	NSString *audioMoveSound;
	
	int scorePerHit;
}

@property (readwrite, nonatomic) int index;
@property (readonly, nonatomic) int kind;
@property (readwrite, nonatomic) int flags;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) KKLevel *level;
@property (readonly, nonatomic) NSMutableDictionary *data;
@property (readonly, nonatomic) int visibilityCounter;

@property (readonly, nonatomic) CGPoint positionToDisplay;
@property (readonly, nonatomic) CGPoint centerPositionToDisplay;

@property (readonly, nonatomic) int z;
@property (readwrite, nonatomic) CGSize size;
@property (readwrite, nonatomic) CGPoint acceleration;
@property (readwrite, nonatomic) CGPoint speed;
@property (readwrite, nonatomic) CGPoint minPosition;
@property (readwrite, nonatomic) CGPoint maxPosition;
@property (readonly, nonatomic) CGRect bbox;
@property (readonly, nonatomic) CGPoint center;

@property (readwrite, nonatomic) int proximityMode;
@property (readwrite, nonatomic) CGSize proximityArea;
@property (readwrite, nonatomic) CGPoint proximityAcceleration;

@property (readwrite, nonatomic) float elasticity;

@property (readonly, nonatomic) BOOL isOffensiveSide;
@property (readonly, nonatomic) BOOL isDefensiveSide;

@property (readwrite, nonatomic) BOOL shown;
@property (readwrite, nonatomic) BOOL isButton;
@property (readwrite, nonatomic) BOOL selected;
@property (readwrite, nonatomic) BOOL enabled;
@property (readwrite, nonatomic) BOOL isInvisible;
@property (readonly, nonatomic) BOOL isGlobal;

@property (readonly, nonatomic) int numLights;

//@property (readonly, nonatomic) CCBitmapFontAtlas *label;

@property (readwrite, retain, nonatomic) KKAIBase *defensiveAI;
@property (readwrite, nonatomic) int defensiveAIKind;
@property (readwrite, retain, nonatomic) KKAIBase *offensiveAI;
@property (readwrite, nonatomic) int offensiveAIKind;

@property (readonly, nonatomic) NSString *audioInSound;
@property (readonly, nonatomic) NSString *audioOutSound;
@property (readonly, nonatomic) NSString *audioSoundLoop;
@property (readonly, nonatomic) NSString *audioHitSound;
@property (readonly, nonatomic) NSString *audioMoveSound;
@property (readonly, nonatomic) NSString *audioClickSound;
@property (readwrite, nonatomic) GLuint audioSoundLoopID;

@property (readwrite, nonatomic) int scorePerHit;

-(id) initWithData:(NSMutableDictionary *)paddleData fromLevel:(KKLevel *)aLevel withIndex:(int)idx;

-(void) initPaddle:(NSMutableDictionary *)paddleData;
-(void) destroyPaddle;

-(void) setupScripts:(NSString *)scriptsData;

-(void) setupPaddleAI:(NSDictionary *)aiData;
-(void) destroyAI;

-(void) setupPaddleProximity:(NSDictionary *)proximityData;
-(void) setupPaddleTexture:(NSString *)textureName;
-(void) setupPaddleColor:(NSDictionary *)colorData;
-(void) setupPaddleLights:(NSArray *)lightsData;
-(void) setupPaddleLabel:(NSDictionary *)labelData;
-(void) setupPaddleTopImage:(NSDictionary *)imageData;

-(void) setTopImage:(NSString *)path positionX:(float)x positionY:(float)y width:(float)w height:(float)h anchorX:(float)ax anchorY:(float)ay opacity:(int)o rotation:(float)r;

-(void) update:(ccTime)dt;
-(BOOL) updatePositionWithSpeedAndAcceleration:(ccTime)dt;

-(int) checkCollisionWithRect:(CGRect)r speed:(CGPoint)s collisionPoint:(CGPoint *)collisionPoint dt:(ccTime)dt;
-(BOOL) isHeroInsideProximityArea:(KKHero *)hero;
-(BOOL) isHeroAtIndexInsideProximityArea:(int)idx;
-(void) applyProximityInfluenceToHero:(KKHero *)hero dt:(ccTime)dt;

-(BOOL) isInScreen:(KKScreen *)screen;
-(void) toggleSide;

-(BOOL) containsPoint:(CGPoint)p;
-(BOOL) handleTouchType:(int)touchType position:(CGPoint)pos tapCunt:(int)tapCount;

-(void) clicked;

-(CCBitmapFontAtlas *) label;
-(void) setLabelFont:(NSString *)fontName ofSize:(int)fontSize;
-(void) setLabel:(NSString *)str;
-(void) destroyLabel;
-(void) updateLabelPosition;

-(KKLight *) light:(int)idx;

-(void) applyShown;

-(void) onEnterSounds;
-(void) onExitSounds;

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn sound:(NSString *)sound;
-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn duration:(float)seconds sound:(NSString *)sound;
-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn bgColor:(ccColor3B)bgc msgColor:(ccColor3B)msgc icnColor:(ccColor3B)icnc fontSize:(CGFloat)pointSize duration:(float)seconds sound:(NSString *)sound;
-(void) removeMessage;

#pragma mark -
#pragma mark FX Actions

-(void) actionStop:(int)aTag;
-(void) actionRotateBy:(float)angle withDuration:(float)seconds forever:(BOOL)forever withTag:(int)aTag;
-(void) actionRotateTo:(float)angle withDuration:(float)seconds forever:(BOOL)forever withTag:(int)aTag;
-(void) actionScaleBy:(float)aScale withDuration:(float)seconds forever:(BOOL)forever withTag:(int)aTag;
-(void) actionScaleTo:(float)aScale withDuration:(float)seconds forever:(BOOL)forever withTag:(int)aTag;
-(void) actionPulseFromScale:(float)minScale toScale:(float)maxScale withDelay:(float)delay withDuration:(float)seconds withTag:(int)aTag;

-(void) tintToColor:(ccColor3B)c withDuration:(float)duration;
-(void) fadeToOpacity:(int)o withDuration:(float)duration;
-(void) fadeToOpacity:(int)o withDuration:(float)duration tag:(int)tag;
-(void) flash;


@end
