//
//  IntroScene.h
//  Be2
//
//  Created by Alessandro Iob on 4/28/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"
#import "KKIntroLayer.h"
#import "KKScene.h"

@interface KKIntroScene : KKScene {
	KKIntroLayer *introLayer;
	UIActivityIndicatorView *activity;
}

@end
