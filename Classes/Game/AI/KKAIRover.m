//
//  KKAIRover.m
//  be2
//
//  Created by Alessandro Iob on 24/8/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKAIRover.h"
#import "KKLevel.h"
#import "KKScreen.h"
#import "KKPaddle.h"
#import "KKHero.h"
#import "KKMacros.h"

@implementation KKAIRover

-(void) setup
{
	speedLimit = DICT_FLOAT (config, @"speedFactor", 1.0) * 
	DICT_FLOAT (config, @"speedFactorMult", 1.5) + 
	DICT_FLOAT (config, @"speedFactorMin", 7.5);
	
	float ax = DICT_FLOAT (config, @"accelerationX", 40.0);
	float ay = DICT_FLOAT (config, @"accelerationY", 40.0);
	if (ax == -1) ax = RANDOM_INT (20, 60);
	if (ay == -1) ay = RANDOM_INT (20, 60);
	
	acceleration = ccp (
						ax, 
						ay
						);
	
	if (DICT_INT (config, @"maxSpeedRandom", 0)) {
		maxSpeed = ccp (
						(float) (RANDOM_INT ((int)maxSpeed.x/2, (int)maxSpeed.x)),
						(float) (RANDOM_INT ((int)maxSpeed.y/2, (int)maxSpeed.y))
						);
	}
	
	wasUserInputInRange = NO;
}

-(void) update:(ccTime)dt
{
	if (![self needsUpdate:dt]) return;
	
	KKHero *hero = [level mainHero];
	
	BOOL doUpdate = YES;
	
	if (flags & kAIFlagCheckInSensorRange) {
		doUpdate = [self isHeroInSensorRange:hero];
	} else if (flags & kAIFlagCheckOutSensorRange) {
		doUpdate = ![self isHeroInSensorRange:hero];
	} else if (flags & kAIFlagCheckInProximityArea) {
		doUpdate = [self isHeroInsideProximityArea:hero];
	} else if (flags & kAIFlagCheckOutProximityArea) {
		doUpdate = ![self isHeroInsideProximityArea:hero];
	}
	
	if (!doUpdate) return;
	
	float sx, sy;
	CGPoint pc = paddle.center;
	CGPoint hc = hero.center;
	
	if (!CGPointEqualToPoint(pc, hc)) {
		sx = acceleration.x;
		sy = acceleration.y;
		
		if (pc.x > hc.x) {
			sx = -sx;
		} else if (pc.x == hc.x) {
			sx = 0;
		}
		if (pc.y > hc.y) {
			sy = -sy;
		} else if (pc.y == hc.y) {
			sy = 0;
		}
	}
	paddle.speed = [self limitSpeed:ccp(paddle.speed.x + sx, paddle.speed.y + sy)];
}

@end
