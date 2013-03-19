//
//  InfoLabel.h
//  Be2
//
//  Created by Alessandro Iob on 6/24/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"
#import "KKUIUtilities.h"

#define NOTIFICATION_INFO_LABEL_REACHED_POSITION @"notif_infoLabelReachedPosition"

typedef enum {
	kInfoLabelEffectNone = 0,
	kInfoLabelEffectPulse,
	kNumberOfInfoLabelEffects,
} tInfoLabelEffects;

@interface KKInfoLabel : CCLabel {
	BOOL shown;
	CGPoint shownPosition;
	CGPoint hiddenPosition;
	tHiddenPositions hiddenPositionFlag;
	
	CCSprite *background;
}

@property (readwrite, nonatomic) BOOL shown;
@property (readonly, nonatomic) CGPoint shownPosition, hiddenPosition;

-(id) initWithString:(NSString*)string fontName:(NSString*)name fontSize:(CGFloat)size backgroundColor:(ccColor3B)color opacity:(GLubyte)opacity width:(int)width height:(int)height;
-(id) initWithString:(NSString*)string fontName:(NSString*)name fontSize:(CGFloat)size backgroundColor:(ccColor3B)color opacity:(GLubyte)opacity width:(int)width height:(int)height alignment:(UITextAlignment)alignment;

-(void) updatePositions:(CGPoint)origin;
-(void) setPositionsShown:(CGPoint)shown hidden:(tHiddenPositions)hidden;
-(void) setShown:(BOOL)v;
-(void) setHidden;
-(void) moveAtPosition:(CGPoint)p duration:(float)d;
-(void) setString:(NSString *)string withEffect:(tInfoLabelEffects)effect;
-(void) setString:(NSString *)string withEffect:(tInfoLabelEffects)effect updatePosition:(BOOL)f;

-(void) doShow;
-(void) doHide;

@end
