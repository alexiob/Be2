//
//  InputLayer.m
//  Be2
//
//  Created by Alessandro Iob on 4/7/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKInputLayer.h"
#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKMath.h"
#import "KKObjectsManager.h"
#import "KKInputManager.h"

#import "SneakyJoystick.h"
#import "SneakyButton.h"
#import "SneakyJoystickSkinnedBase.h"
#import "SneakyButtonSkinnedBase.h"
#import "ColoredCircleSprite.h"
#import "ColoredSquareSprite.h"

#pragma mark -

@implementation KKInputLayer

@synthesize joystick, joystickBase;

-(id) init
{
	self = [super init];
	if (self) {
		inputManager = KKIM;
		
		[self setIsTouchEnabled:YES];
		
		[self setAnchorPoint:ccp (0.0, 0.0)];
		
		[self initJoystick];
	}
	
	return self;
}

-(void) dealloc
{
	[joystick release], joystick = nil;
	[joystickBase release], joystickBase = nil;
	
	[super dealloc];
}

-(void) onEnter
{
	[super onEnter];
}

-(void) onExit
{
	[super onExit];
}

#pragma mark -
#pragma mark Joystick

#define JOYSTICK_BG_COLOR ccc4(255, 255, 255, 80)
#define JOYSTICK_FG_COLOR ccc4(0, 0, 0, 80)

-(void) initJoystick
{
	joystickBase = [[SneakyJoystickSkinnedBase alloc] init];
	joystickBase.position = ccp(64,64);
	joystickBase.backgroundSprite = [ColoredSquareSprite squareWithColor:JOYSTICK_BG_COLOR size:CGSizeMake(64,64)];
	joystickBase.thumbSprite = [ColoredSquareSprite squareWithColor:JOYSTICK_FG_COLOR size:CGSizeMake(32,32)];
	joystickBase.joystick = [[SneakyJoystick alloc] initWithRect:CGRectMake(0,0,128,128)];
	joystick = [joystickBase.joystick retain];
	[joystickBase setVisible:NO];
	[self addChild:joystickBase];
}

-(void) setJoystickPosition:(CGPoint)pos
{
	joystickBase.position = pos;
}

-(void) showJoystick:(BOOL)f
{
	if (f == joystickBase.visible) return;
	
	[joystickBase setVisible:f];
	
	if (f) {
		[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:joystick priority:INPUT_MANAGER_PRIORITY - 1 swallowsTouches:NO];
	} else {
		[[CCTouchDispatcher sharedDispatcher] removeDelegate:joystick];
	}
}

#pragma mark -
#pragma mark Touches

-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addStandardDelegate:self priority:INPUT_MANAGER_PRIORITY];
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{ 
	[inputManager touches:touches withEvent:event withTouchType:ccTouchBegan];
} 

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{ 
	[inputManager touches:touches withEvent:event withTouchType:ccTouchMoved];
} 

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{ 
	[inputManager touches:touches withEvent:event withTouchType:ccTouchEnded];
} 

-(void) ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[inputManager touches:touches withEvent:event withTouchType:ccTouchCancelled];
}

@end
