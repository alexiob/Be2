//
//  TimeBar.h
//  Be2
//
//  Created by Alessandro Iob on 4/5/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"

#define NOTIFICATION_TIMEBAR_COUNTER_TICK @"notif_timebar_counter_tick"
#define NOTIFICATION_TIMEBAR_COUNTER_STARTED @"notif_timebar_counter_started"
#define NOTIFICATION_TIMEBAR_COUNTER_STOPPED @"notif_timebar_counter_stopped"
#define NOTIFICATION_TIMEBAR_SHOW_END @"notif_show_end"

#define TIMEBAR_WIDTH 200.0f
#define TIMEBAR_HEIGHT 20.0f

#define TIMEBAR_MENU_POSITION_IN ccp (ws.width/2 - cs.width/2, 23)
#define TIMEBAR_MENU_POSITION_OUT ccp (-cs.width - 2, TIMEBAR_MENU_POSITION_IN.y)
#define TIMEBAR_MAP_POSITION_IN ccp (4, ws.height - cs.height - 5)
#define TIMEBAR_MAP_POSITION_OUT ccp (4, ws.height + cs.height + 7)
#define TIMEBAR_SHOP_POSITION_IN ccp (4, ws.height - cs.height)
#define TIMEBAR_SHOP_POSITION_OUT ccp (4, ws.height + cs.height + 7)

@interface KKTimeBar : CCLayer {
	CGPoint positionIn;
	CGPoint positionOut;
	float duration;
	ccColor3B backgroundNormalColor, backgroundAlertColor;
	ccColor3B barNormalColor, barAlertColor;
	
	GLubyte opacity;
	CCSprite *barBackground;
	CCSprite *bar;
	
	float totalSeconds;
	float availableSeconds;
	float nextTick;
	float warningSeconds;
	
	BOOL shown;
}

-(id) initWithPositionIn:(CGPoint)pIn positionOut:(CGPoint)pOut duration:(float)sec;
-(id) initWithPositionIn:(CGPoint)pIn positionOut:(CGPoint)pOut duration:(float)sec width:(float)width height:(float)height;

-(void) setTotalSeconds:(float)total_seconds;
-(void) setBackgroundToNormal;
-(void) setBackgroundToAlert;
-(void) setShown:(BOOL)b;

@property (readwrite, nonatomic) ccColor3B backgroundNormalColor, backgroundAlertColor;
@property (readwrite, nonatomic) ccColor3B barNormalColor, barAlertColor;
@property (readwrite, nonatomic) CGPoint positionIn, positionOut;
@property (readwrite, nonatomic) float duration;
@property (readonly, nonatomic) float totalSeconds;
@property (readwrite, nonatomic) float warningSeconds;
@property (readwrite, nonatomic) BOOL shown;

@end 
