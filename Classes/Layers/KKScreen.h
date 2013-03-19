//
//  KKScreen.h
//  be2
//
//  Created by Alessandro Iob on 2/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"
#import "KKEntityProtocol.h"
#import "KKScreenBorder.h"

@class KKHero;
@class KKPaddle;
@class KKLevel;
@class KKLight;
@class KKLuaManager;
@class KKGameEngine;

typedef enum {
	kScreenActionColorTintTo = 200 + 1,
} tScreenAction;

typedef enum {
	kScreenFlagLeftSideClosed = 1 << 0, // 1
	kScreenFlagRightSideClosed = 1 << 1, // 2
	kScreenFlagTopSideClosed = 1 << 2, // 4
	kScreenFlagBottomSideClosed = 1 << 3, // 8
	kScreenFlagScriptUpdate = 1 << 4,
	kScreenFlagScriptOnEnter = 1 << 5,
	kScreenFlagScriptOnExit = 1 << 6,
} tScreenFlags;

@class KKLevel;

#define SCREEN_MAX_LIGHTS 30
#define DEFAULT_SCREEN_BORDER_SIZE 5

@interface KKScreen : NSObject <KKEntityProtocol> {
	KKGameEngine *gameEngine;
	KKLuaManager *luaManager;

	NSMutableDictionary *data;
	KKLevel *level;
	
	NSString *title;
	NSString *desc;
	
	int index;
	int kind;
	int flags;
	int difficulty;
	CGPoint maxSpeed;
	CGPoint minSpeed;
	
	CGPoint position;
	CGSize size;
	CGRect bbox;
	
	int colorMode;
	int opacity;
	ccColor3B color1;
	ccColor3B color2;
	float colorTintToDuration;
	
	ccColor3B titleColor;
	ccColor3B descriptionColor;
//	ccColor3B messageColor;
//	int messageOpacity;
//	BOOL messageEnabled;
	
	float availableTime;
	
	int visibilityCounter;
	BOOL active;
	
	int numLights;
	int lights[SCREEN_MAX_LIGHTS];
	
	int numPaddles;
	KKPaddle **paddles;
	
	float borderSize[4];
	float borderElasticity[4];
	
	GLuint audioSoundLoopID;
	
	int scorePerBorderHit;
	
	BOOL needsScriptUpdate;
}

@property (readonly, nonatomic) NSString *name;
@property (readwrite, nonatomic, copy) NSString *title;
@property (readwrite, nonatomic, copy) NSString *desc;
@property (readonly, nonatomic) NSMutableDictionary *data;

@property (readwrite, nonatomic) int index;
@property (readonly, nonatomic) int kind;
@property (readwrite, nonatomic) int flags;
@property (readonly, nonatomic) int difficulty;
@property (readonly, nonatomic) BOOL isCheckpoint;

@property (readonly, nonatomic) CGPoint position;
@property (readonly, nonatomic) CGPoint origin;
@property (readonly, nonatomic) CGSize size;
@property (readonly, nonatomic) CGRect bbox;
@property (readonly, nonatomic) CGSize sizeWithoutBorders;

@property (readonly, nonatomic) CGPoint positionToDisplay;
@property (readonly, nonatomic) CGPoint centerPositionToDisplay;

@property (readonly, nonatomic) CGPoint minSpeed;
@property (readonly, nonatomic) CGPoint maxSpeed;

@property (readwrite, nonatomic) int colorMode;
@property (readwrite, nonatomic) int opacity;
@property (readwrite, nonatomic) ccColor3B color1;
@property (readwrite, nonatomic) ccColor3B color2;
@property (readwrite, nonatomic) float colorTintToDuration;

@property (readwrite, nonatomic) ccColor3B titleColor;
@property (readwrite, nonatomic) ccColor3B descriptionColor;
//@property (readwrite, nonatomic) ccColor3B messageColor;
//@property (readwrite, nonatomic) int messageOpacity;
//@property (readwrite, nonatomic) BOOL messageEnabled;

@property (readwrite, nonatomic) float availableTime;

@property (readwrite, nonatomic) BOOL shown;
@property (readwrite, nonatomic) BOOL active;

@property (readonly, nonatomic) int numLights;

@property (readonly, nonatomic) int numPaddles;
@property (readonly, nonatomic) KKPaddle **paddles;

@property (readonly, nonatomic) NSString *audioBackgroundMusic;
@property (readonly, nonatomic) NSString *audioInSound;
@property (readonly, nonatomic) NSString *audioOutSound;
@property (readonly, nonatomic) NSString *audioSoundLoop;
@property (readwrite, nonatomic) GLuint audioSoundLoopID;

@property (readwrite, nonatomic) int scorePerBorderHit;

@property (readwrite, nonatomic) BOOL needsScriptUpdate;

-(id) initWithData:(NSMutableDictionary *)screenData fromLevel:(KKLevel *)level withIndex:(int)idx;

-(void) initScreen:(NSMutableDictionary *)screenData fromLevel:(KKLevel *)level;
-(void) destroyScreen;

-(void) setupScripts:(NSString *)scriptsData;

-(NSArray *) paddlesIndexArray;

-(CGPoint) globalToScreenPoint:(CGPoint)p;
-(CGPoint) screenToGlobalPoint:(CGPoint)p;

-(void) setupScreenColor:(NSDictionary *)colorData;
-(void) setupScreenLights:(NSArray *)lightsData;
-(void) updateBBox;

-(float) borderSize:(tScreenBorderSide)side;
-(float) borderElasticity:(tScreenBorderSide)side;
-(BOOL) screenBorderActive:(tScreenBorderSide)border;
-(void) setScreenBorder:(tScreenBorderSide)border active:(BOOL)f;

-(void) update:(ccTime)dt;

-(void) onEnter;
-(void) onExit;

-(KKLight *) light:(int)idx;

-(void) applyShown;

-(CGPoint) heroStartPosition;

@end
