//
//  JoystickModel.m
//  Be2
//
//  Created by Alessandro Iob on 4/8/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKJoystickModel.h"
#import "KKMacros.h"

@interface Vector : NSObject 
+(CGPoint) makeWithX:(float)x Y:(float)y; 
+(CGPoint) makeIdentity; 
+(CGPoint) add:(CGPoint)vec1 to:(CGPoint)vec2; 
+(CGPoint) truncate:(CGPoint)vec to:(float)max; 
+(CGPoint) multiply:(CGPoint)vec by:(float)factor; 
+(float) lengthSquared:(CGPoint)vec; 
+(float) length:(CGPoint)vec; 
+(CGPoint) subtract:(CGPoint)vec from:(CGPoint)vec; 
+(CGPoint) invert:(CGPoint)vec; 
+(CGPoint) normalize:(CGPoint)pt; 
+(float) distanceBetween:(CGPoint)vec vec2:(CGPoint)vec2; 
+(CGPoint) asAngleVelocity:(CGPoint)vec; 
+(CGPoint) fromAngleVelocity:(CGPoint)vec; 
@end 

@implementation Vector 
+(CGPoint) makeWithX:(float)x Y:(float)y 
{ 
	CGPoint vec; 
	vec.x = x; 
	vec.y = y; 
	return vec; 
} 

+(float) distanceBetween:(CGPoint)vec1 vec2:(CGPoint)vec2 
{ 
	return sqrt(pow(vec1.x - vec2.x, 2) + pow(vec1.y - vec2.y, 2)); 
} 

+(CGPoint) makeIdentity {
	return [self makeWithX: 0.0f Y: 0.0f]; 
} 

+(CGPoint) add:(CGPoint)vec1 to:(CGPoint)vec2 
{ 
	vec2.x += vec1.x; 
	vec2.y += vec1.y; 
	return vec2; 
} 

// converts x y vector into angle velocity 
+(CGPoint) asAngleVelocity:(CGPoint)vec 
{ 
	float a = atan2(vec.y, vec.x); 
	float l = [Vector length:vec]; 
	vec.x = a; 
	vec.y = l; 
	return vec; 
} 

// converts angle velocity vector into x y vector 
+(CGPoint) fromAngleVelocity:(CGPoint)vec 
{ 
	float vel = vec.y; 
	vec.y = cos(vec.x) * vel; 
	vec.x = sin(vec.x) * vel; 
	return vec; 
} 

+(CGPoint) truncate:(CGPoint)vec to:(float)max 
{ 
	// this is not true truncation, but is much faster 
	if (vec.x > max) vec.x = max; 
	if (vec.y > max) vec.y = max; 
	if (vec.y < -max) vec.y = -max; 
	if (vec.x < -max) vec.x = -max; 
	return vec; 
} 

+ (CGPoint) normalize:(CGPoint)pt 
{ 
	float len = [Vector length:pt]; 
	if (len == 0) return pt; 
	pt.x /= len; 
	pt.y /= len; 
	return pt; 
} 

+(CGPoint) multiply: (CGPoint) vec by: (float) factor 
{ 
	vec.x *= factor; 
	vec.y *= factor; 
	return vec; 
} 

+(float) lengthSquared:(CGPoint)vec 
{ 
	return (vec.x*vec.x + vec.y*vec.y); 
} 

+ (float) length:(CGPoint)vec 
{ 
	return sqrt([Vector lengthSquared:vec]); 
} 

+ (CGPoint) invert:(CGPoint)vec 
{ 
	vec.x *= -1; 
	vec.y *= -1; 
	return vec; 
} 

+(CGPoint) subtract:(CGPoint)vec1 from:(CGPoint)vec2 
{ 
	vec2.x -= vec1.x; 
	vec2.y -= vec1.y; 
	return vec2; 
} 

@end 

// Joystick model

@implementation KKJoystickModel

@synthesize activationTouch;

-(id) init:(float)x y:(float)y w:(float)w h:(float)h anchorPoint:(CGPoint)ap
{ 
	self = [super init]; 
	if (self) { 
		anchorPoint = ap;
		mBounds = CGRectMake (x - w*anchorPoint.x, y - h*anchorPoint.y, w, h); 
		mCenter = ccp (0, 0); 
		mCurPosition = ccp (0, 0); 
		mDeadZone = CGRectMake (0, 0, 0, 0); 
		mActive = NO; 
		mStaticCenter = NO; 
	} 
	return self; 
} 

-(void) dealloc
{
	[super dealloc];
}

-(void) setDeadZoneXRadius:(float)x yRadius:(float)y
{
	mDeadZone = CGRectMake (-x, -y, x*2, y*2);
}

-(void) setPositionX:(float)x y:(float)y 
{
	mBounds = CGRectMake (x - mBounds.size.width*anchorPoint.x, y - mBounds.size.height*anchorPoint.y, mBounds.size.width, mBounds.size.height); 
}

-(void) setCenterX:(float)x y:(float)y 
{ 
	mCenter = ccp (x, y);
	mCurPosition = ccp (mCenter.x, mCenter.y);
	mStaticCenter = YES; 
} 

-(BOOL) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]]; 
	if (CGRectContainsPoint (mBounds, location)) {
		mActive = YES; 
		if (!mStaticCenter) 
			mCenter = ccp (location.x, location.y); 
		mCurPosition = ccp (location.x, location.y);
		activationTouch = touch;
		//			KKLOG (@"jmodel began: %d / %d / %d",t, activationTouch, *touch);
		return YES;
	} else {
		return NO;
	}
}

-(void) touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint location = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]]; 
	if (CGRectContainsPoint (mBounds, location)) { 
		mCurPosition = ccp (location.x, location.y); 
	} 
}

-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	mActive = NO; 
	if (!mStaticCenter) 
		mCenter = ccp (0, 0); 
	mCurPosition = ccp (mCenter.x, mCenter.y); 
	activationTouch = nil;
}

-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	activationTouch = nil;
}

/*
-(UITouch *) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{ 
	UITouch *touch = nil;
	NSArray *allTouches = [touches allObjects]; 
	
	for (UITouch *t in allTouches) { 
		CGPoint location = [[CCDirector sharedDirector] convertToGL:[t locationInView:[t view]]]; 
		if (CGRectContainsPoint (mBounds, location)) {
			mActive = YES; 
			if (!mStaticCenter) 
				mCenter = ccp (location.x, location.y); 
			mCurPosition = ccp (location.x, location.y);
			touch = t;
			activationTouch = t;
//			KKLOG (@"jmodel began: %d / %d / %d",t, activationTouch, *touch);
			break;
		} 
	} 
	return touch;
} 

-(UITouch *) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{ 
	UITouch *touch = nil;
	
	if (!mActive) return touch; 
	
	NSArray *allTouches = [touches allObjects]; 
	for (UITouch *t in allTouches) {
		if (t != activationTouch) continue;
		//		KKLOG (@"jmodel moved: %d / %d",t, activationTouch);
		CGPoint location = [[CCDirector sharedDirector] convertToGL:[t locationInView:[t view]]]; 
		touch = t;
		if (CGRectContainsPoint (mBounds, location)) { 
			mCurPosition = ccp (location.x, location.y); 
		} 
		break;
	} 
	return touch;
} 

-(UITouch *) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{ 
	UITouch *touch = nil;
	
	if (!mActive) return touch; 
	
	NSArray *allTouches = [touches allObjects]; 
	for (UITouch* t in allTouches) { 
		if (t != activationTouch) continue;
//		KKLOG (@"jmodel end: %d / %d",t, activationTouch);
		
		// CGPoint location = [[CCDirector sharedDirector] convertCoordinate:[t locationInView:[t view]]]; 
		// if (CGRectContainsPoint (mBounds, location)) { 
		mActive = NO; 
		if (!mStaticCenter) 
			mCenter = ccp (0, 0); 
		mCurPosition = ccp (mCenter.x, mCenter.y); 
		touch = t;
		activationTouch = nil;
		break;
	} 
	return touch;
} 

-(UITouch *) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{ 
	UITouch *touch = nil;
	NSArray *allTouches = [touches allObjects]; 
	
	for (UITouch* t in allTouches) { 
		if (t != activationTouch) continue;
		
		touch = t;
		activationTouch = nil;
		break;
	}
	return touch;
} 
*/

-(CGPoint) getCurrentVelocity 
{ 
	CGPoint p = [Vector subtract:mCenter from:mCurPosition];
	if (CGRectContainsPoint (mDeadZone, p))
		p = ccp (0, 0);
	return p;
} 

-(CGPoint) getCurrentDegreeVelocity 
{ 
	float dx = mCenter.x - mCurPosition.x; 
	float dy = mCenter.y - mCurPosition.y; 
	CGPoint vel = [self getCurrentVelocity]; 
	vel.y = [Vector length:vel]; 
	vel.x = atan2f (-dy, dx) * (180/3.14); 
	return vel; 
} 

@end 

