//
//  KKHUDGameEndLayer.h
//  be2
//
//  Created by Alessandro Iob on 29/7/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"

#import "KKHUDButton.h"

@class KKGameEngine;

#define DIALOG_STEPS 8

#define END_LABELS 4
#define END_STEPS 4

@interface KKHUDGameEndLayer : CCColorLayer {
	KKGameEngine *gameEngine;
	
	CCSprite *pongBackground;
	CCSprite *hero;
	CCSprite *paddle;

	CCLabel *heroLabel;
	CCLabel *paddleLabel;
	NSMutableArray *labelsText;
	int labelsStep;

	CCLabel *endLabels[END_LABELS];
	NSMutableArray *endLabelsText;
	int endLabelsStep;
	
	CCSprite *badge;
}

-(id) initGameEndLayer;
-(void) show;
-(void) hide;

-(void) playAnimation;

@end
