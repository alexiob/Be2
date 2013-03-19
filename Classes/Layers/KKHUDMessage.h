//
//  KKHUDMessage.h
//  be2
//
//  Created by Alessandro Iob on 22/4/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"
#import "KKEntityProtocol.h"

#define HUD_MESSAGE_SHOW_DURATION 0.9
#define HUD_MESSAGE_INFINITE_DURATION -1
#define HUD_MESSAGE_FONT_SIZE 18
#define HUD_MESSAGE_COLOR ccc3(0,0,0)
#define HUD_MESSAGE_EMOTICON_COLOR ccc3(255,255,255)
#define HUD_MESSAGE_BG_COLOR ccc3(255,255,255)

typedef enum {
	kEmoticonPlain = 0,
	kEmoticonHappy,
	kEmoticonSad,
	kEmoticonAngel,
	kEmoticonDevil,
	kEmoticonBored,
	kEmoticonAngry,
	kEmoticonCrying,
	kEmoticonDrunk,
	kEmoticonKiss,
	kEmoticonSurprised,
	kEmoticonTongue,
	kEmoticonWinking,
	
	kEmoticonOpenFeint,
} tEmoticon;

typedef enum {
	kHUDMessageKindSay = 1,
	kHUDMessageKindThink,
} tHUDMessageKind;

@interface KKHUDMessage : CCSprite {
	tHUDMessageKind kind;
	CCSprite *emoticon;
	CCLabel *label;
	id<KKEntityProtocol> sourceEntity;
	CGPoint origin;
	
	float duration;
	int index;
}

@property (readwrite, nonatomic) float duration;
@property (readwrite, nonatomic) int index;
@property (readonly, nonatomic) id<KKEntityProtocol> sourceEntity;

-(id) initWithMessage:(NSString *)message emoticon:(int)eid fontSize:(CGFloat)pointSize kind:(tHUDMessageKind)aKind duration:(float)seconds;
-(void) setSourceEntity:(id<KKEntityProtocol>)entity;
-(void) setSourceOrigin:(CGPoint)pos;
-(void) setShown:(BOOL)f;
-(void) setLabelColor:(ccColor3B)c;
-(void) setEmoticonColor:(ccColor3B)c;
-(void) setBackgroundColor:(ccColor3B)c;

@end
