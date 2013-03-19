/*
 *  KKEntitiesCommon.m
 *  be2
 *
 *  Created by Alessandro Iob on 3/10/10.
 *  Copyright 2010 Kismik. All rights reserved.
 *
 */

#import "KKEntitiesCommon.h"
#import "KKMath.h"
#import "KKMacros.h"
#import "KKLevel.h"
#import "CGPointExtension.h"

CGPoint limitSpeed (CGPoint speed, KKLevel *level)
{
	KKScreen *screen = [level currentScreen];
	CGPoint minSpeed;
	CGPoint maxSpeed;
	float signX = PSign (speed.x);
	float signY = PSign (speed.y);
	float speedX = ABS (speed.x);
	float speedY = ABS (speed.y);
	
	if (!screen || CGPointEqualToPoint (screen.minSpeed, CGPointZero)) {
		minSpeed = level.minSpeed;
	} else {
		minSpeed = screen.minSpeed;
	}

	if (!screen || CGPointEqualToPoint (screen.maxSpeed, CGPointZero)) {
		maxSpeed = level.maxSpeed;
	} else {
		maxSpeed = screen.maxSpeed;
	}
	
	CGPoint newSpeed = ccpCompMult (ccpClamp (ccp (speedX, speedY), minSpeed, maxSpeed), ccp (signX, signY));
//	KKLOG (@"orig=%@, new=%@", NSStringFromCGPoint(speed), NSStringFromCGPoint(newSpeed));
	return newSpeed;
}

