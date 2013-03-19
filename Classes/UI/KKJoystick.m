//
//  Joystick.m
//  Be2
//
//  Created by Alessandro Iob on 4/7/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKJoystick.h"
#import "KKMacros.h"
#import "KKInputManager.h"

// Joystick view

@implementation KKJoystick

@synthesize model, joystickId;
@synthesize delegate;

-(id) initWithId:(NSString *)jid andWithFile:(NSString *)filename priority:(int)priority
{
	self = [super initWithFile:filename];
	if (self) {
		self.joystickId = jid;
		
		[self setAnchorPoint:ccp (0.5, 0.5)];
		CGSize s = self.texture.contentSize;
		
		model = [[[KKJoystickModel alloc] init:self.position.x y:self.position.y w:s.width h:s.height anchorPoint:[self anchorPoint]] retain];
		touchPriority = priority;
//		[KKIM addTouchesDelegate:self priority:priority];
	}
	
	return self;
}

-(void) setPosition:(CGPoint)pos
{
	[super setPosition:pos];
	[model setPositionX:pos.x y:pos.y];
	CGSize s = self.texture.contentSize;
	[model setCenterX:pos.x + s.width/2 y:pos.y + s.height/2];
}

-(void) dealloc 
{
//	[KKIM removeTouchesDelegate:self];
	
	self.joystickId = nil;
	self.delegate = nil;
	
	[model release];
	[super dealloc];
}

-(void) onEnter
{
	[super onEnter];
	
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:touchPriority swallowsTouches:YES];
}

-(void) onExit
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	
	[super onExit];
}

#pragma mark -
#pragma mark Input

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	BOOL f;
	f = [model touchBegan:touch withEvent:event];
	
	if (f && delegate != nil) {
		[delegate kkTouchBegan:touch withEvent:event withJoystickId:joystickId];
	}
	return f;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	[model touchMoved:touch withEvent:event];
	[delegate kkTouchMoved:touch withEvent:event withJoystickId:joystickId];
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	[model touchEnded:touch withEvent:event];
	[delegate kkTouchEnded:touch withEvent:event withJoystickId:joystickId];
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	[model touchCancelled:touch withEvent:event];
	[delegate kkTouchCancelled:touch withEvent:event withJoystickId:joystickId];
}

/*
-(UITouch *) activationTouch
{
	return [model activationTouch];
}

-(void) kkTouchesBegan:(NSMutableSet *)touches withEvent:(UIEvent *)event
{ 
	UITouch *touch = nil;
	
	touch = [model touchesBegan:touches withEvent:event];
//	KKLOG (@"kkTouchesBegan: %@", touch);
	if (touch) {
		[touches removeObject:touch];
		[KKIM joystick:joystickId touch:touch withEvent:event withTouchType:ccTouchBegan]; 
	}
}

-(void) kkTouchesMoved:(NSMutableSet *)touches withEvent:(UIEvent *)event
{ 
	UITouch *touch = nil;

	touch = [model touchesMoved:touches withEvent:event];
	if (touch) {
		[touches removeObject:touch];
		[KKIM joystick:joystickId touch:touch withEvent:event withTouchType:ccTouchMoved]; 
	}
}

-(void) kkTouchesEnded:(NSMutableSet *)touches withEvent:(UIEvent *)event
{ 
	UITouch *touch = nil;
	
	touch = [model touchesEnded:touches withEvent:event];
	if (touch) {
		[touches removeObject:touch];
		[KKIM joystick:joystickId touch:touch withEvent:event withTouchType:ccTouchEnded]; 
	}
}

-(void) kkTouchesCancelled:(NSMutableSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = nil;
	
	touch = [model touchesCancelled:touches withEvent:event];
	if (touch) {
		[touches removeObject:touch];
		[KKIM joystick:joystickId touch:touch withEvent:event withTouchType:ccTouchCancelled]; 
	}
}
*/
@end



