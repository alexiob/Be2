//
//  KKHero.h
//  be2
//
//  Created by Alessandro Iob on 2/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"

#import "KKEntitiesCommon.h"
#import "KKEntityProtocol.h"
#import "KKLight.h"
#import "KKHUDMessage.h"

@class KKPaddle;
@class KKScreen;
@class KKLevel;
@class KKLight;
@class KKGameEngine;

typedef enum {
	kHeroActionColorTintTo = 400 + 1,
	kHeroActionOpacityFadeTo,
	kHeroActionGlowPulse,
	kHeroActionScaleTo,
} tHeroAction;

typedef enum {
	kHeroKindDefault = 1,
} tHeroKind;

typedef enum {
	kHeroFlagIsMain = 1 << 0,
	kHeroFlagDontUpdateMovement = 1 << 1,
	kHeroFlagScriptUpdate = 1 << 2,
	kHeroFlagScriptUpdateWithPlayerInput = 1 << 3,
} tHeroFlag;

#define HERO_DEFAULT_WIDTH 10
#define HERO_DEFAULT_HEIGHT 10
#define HERO_DEFAULT_SIZE CGSizeMake (HERO_DEFAULT_WIDTH, HERO_DEFAULT_HEIGHT)

@interface KKHero : CCSprite <KKEntityProtocol> {
	KKGameEngine *gameEngine;
	KKLevel *level;
	
	int index;
	int kind;
	int flags;
	CGSize size;
	CGSize sizeOrig;
	CGRect bbox;
	CGPoint acceleration;
	CGPoint speed;
	float elasticity;
	
	NSMutableDictionary *data;
	int lightID;
	
	int msgIdx;
	ccColor3B msgBGColor;
	ccColor3B msgColor;
	ccColor3B msgIcnColor;
	float msgFontSize;
}

@property (readwrite, nonatomic) int index;
@property (readwrite, nonatomic) int kind;
@property (readwrite, nonatomic) int flags;
@property (readwrite, nonatomic) CGSize size;
@property (readwrite, nonatomic) CGPoint acceleration;
@property (readwrite, nonatomic) CGPoint speed;
@property (readwrite, nonatomic) float elasticity;
@property (readonly, nonatomic) NSMutableDictionary *data;
@property (readonly, nonatomic) CGRect bbox;
@property (readonly, nonatomic) CGPoint center;
@property (readonly, nonatomic) BOOL isMainHero;

@property (readonly, nonatomic) KKLight *light;
@property (readwrite, nonatomic) BOOL lightEnabled;
@property (readwrite, nonatomic) BOOL lightVisible;

@property (readonly, nonatomic) CGPoint positionToDisplay;
@property (readonly, nonatomic) CGPoint centerPositionToDisplay;

-(id) initWithLevel:(KKLevel *)aLevel;
-(void) setupLight;

-(void) updateHeroTexture:(NSString *)textureName;
-(void) updateHeroColorMode:(int)colorMode color1:(ccColor3B)color1 color2:(ccColor3B)color2 tintToDuration:(float)tintToDuration;
-(void) updateHeroColorModeSolid:(ccColor3B)color;
-(void) updateHeroOpacityMode:(int)opacityMode opacity1:(GLubyte)opacity1 opacity2:(GLubyte)opacity2 opacityFadeDuration:(GLubyte)opacityFadeDuration;

-(void) pause:(BOOL)f;
-(BOOL) isPaused;

-(void) update:(ccTime)dt;
-(void) updateSpeed:(ccTime)dt;
-(void) updatePosition:(ccTime)dt;

-(void) updateBBox;

-(BOOL) isInScreen:(KKScreen *)screen;

-(KKLight *) light;

-(void) setScaleIncrement:(CGSize)inc duration:(ccTime)d;
-(void) resetScaleIncrement:(ccTime)d;

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn sound:(NSString *)sound;
-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn duration:(float)seconds sound:(NSString *)sound;
-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn bgColor:(ccColor3B)bgc msgColor:(ccColor3B)msgc icnColor:(ccColor3B)icnc fontSize:(CGFloat)pointSize duration:(float)seconds sound:(NSString *)sound;
-(void) removeMessage;

@end
