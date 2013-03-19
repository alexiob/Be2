//
//  IntroLayer.h
//  Be2
//
//  Created by Alessandro Iob on 4/13/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"

#define NOTIF_INTRO_CLOSED @"KKNotifIntroClosed"

@interface KKIntroLayer : CCColorLayer {
	CCSprite *hero;
	CCSprite *paddle;
	CCLabel *message;
	NSArray *introMessages;
}

-(void) playIntro;

-(void) loadIntroMessages;

@end

