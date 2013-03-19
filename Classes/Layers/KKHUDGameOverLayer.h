//
//  KKHUDGameOverLayer.h
//  be2
//
//  Created by Alessandro Iob on 21/5/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"

#import "KKHUDButton.h"

@class KKGameEngine;

@interface KKHUDGameOverLayer : CCColorLayer {
	KKGameEngine *gameEngine;
	
	CCColorLayer *ground;
	CCSprite *actors;
	CCSprite *cloudsBack;
	CCSprite *cloudsFront;
	CCColorLayer *thunder;
	
	CCPointParticleSystem *rain;
	CCLabel *gameOver;
	
	KKHUDButtonLabel *scoreMessage;
	KKHUDButtonLabel *score;
	CGPoint scoreMessagePosIn;
	CGPoint scorePosIn;
	
	GLuint womanCryID;
	GLuint childCryID;
	GLuint rainID;
}

-(id) initGameOverLayer;
-(void) show;
-(void) hide;

@end
