//
//  InputLayer.h
//  Be2
//
//  Created by Alessandro Iob on 4/7/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"

@class KKInputManager;

@class SneakyJoystickSkinnedBase;
@class SneakyJoystick;
@class SneakyButton;
	
@interface KKInputLayer : CCLayer {
	KKInputManager *inputManager;

	SneakyJoystickSkinnedBase *joystickBase;
	SneakyJoystick *joystick;
}

@property (readonly, nonatomic) SneakyJoystickSkinnedBase *joystickBase;
@property (readonly, nonatomic) SneakyJoystick *joystick;

-(void) initJoystick;
-(void) setJoystickPosition:(CGPoint)pos;
-(void) showJoystick:(BOOL)f;

@end
