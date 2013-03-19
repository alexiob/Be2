//
//  Joystick.h
//  Be2
//
//  Created by Alessandro Iob on 4/7/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKJoystickModel.h"
#import "KKInputProtocols.h"

@interface KKJoystick : CCSprite <CCTargetedTouchDelegate> //<KKTouchesDelegateProtocol>
{
	NSString *joystickId;
	int touchPriority;
	KKJoystickModel *model;
	id<KKJoystickDelegateProtocol> delegate;
}

@property (readwrite, nonatomic, copy) NSString *joystickId;
@property (readonly, nonatomic) KKJoystickModel *model;
@property (readwrite, nonatomic, retain) id<KKJoystickDelegateProtocol> delegate;
//@property (readonly, nonatomic) UITouch *activationTouch;

-(id) initWithId:(NSString *)jid andWithFile:(NSString *)filename priority:(int)priority;

@end
