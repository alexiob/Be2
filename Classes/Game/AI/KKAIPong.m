//
//  KKAIPong.m
//  be2
//
//  Created by Alessandro Iob on 29/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "KKAIPong.h"
#import "KKLevel.h"
#import "KKScreen.h"
#import "KKPaddle.h"
#import "KKMacros.h"

#define REPOSITION_MIN 1
#define REPOSITION_MAX 3

@implementation KKAIPong

-(void) setup
{
	speedLimit = DICT_FLOAT (config, @"speedFactor", 1.0) * 
	DICT_FLOAT (config, @"speedFactorMult", 1.5) + 
	DICT_FLOAT (config, @"speedFactorMin", 7.5);
	
	centerWhenNotIncomming = DICT_BOOL (config, @"centerWhenNotIncomming", YES);
	wasUserInputInRange = NO;
	
	randomStopImprobability = DICT_INT (config, @"randomStopImprobability", 0);
	randomStopTimeout = DICT_FLOAT (config, @"randoStopTimeout", 1.5);
	randomStopCurrentTimeout = 0;
	randomStopActive = NO;
}

-(BOOL) randomStop:(ccTime)dt
{
	if (randomStopImprobability) {
		if (randomStopCurrentTimeout) {
			randomStopCurrentTimeout -= dt;
			if (randomStopCurrentTimeout <= 0) {
				randomStopCurrentTimeout = 0;
				if (randomStopActive) [paddle setLabel:@""];
				randomStopActive = NO;
			}
		} else {
			randomStopCurrentTimeout = randomStopTimeout;
			
			if (RANDOM_INT (0, randomStopImprobability) == randomStopImprobability) {
				paddle.acceleration = ccp (0, 0);
				paddle.speed = ccp (0, 0);
				randomStopActive = YES;
				[paddle setLabel:@"0"];
			} else {
				randomStopActive = NO;
			}
			KKLOG (@"randoStop: %d", randomStopActive);
		}
	}
	return randomStopActive;
}

-(void) update:(ccTime)dt
{
	BOOL rs = [self randomStop:dt];
	
	if (![self needsUpdate:dt] || rs) return;
	
	KKScreen *screen = level.currentScreen;
	KKHero *hero = [level mainHero];
	BOOL incomming = [self isHeroIncomming:hero];
	
	BOOL doUpdate = YES;
	
	if (incomming) {
		if (flags & kAIFlagCheckInSensorRange) {
			doUpdate = [self isHeroInSensorRange:hero];
		} else if (flags & kAIFlagCheckOutSensorRange) {
			doUpdate = ![self isHeroInSensorRange:hero];
		} else if (flags & kAIFlagCheckInProximityArea) {
			doUpdate = [self isHeroInsideProximityArea:hero];
		} else if (flags & kAIFlagCheckOutProximityArea) {
			doUpdate = ![self isHeroInsideProximityArea:hero];
		}
	}

	
	if (!doUpdate) return;

	int sides = validSides;
	if (centerWhenNotIncomming)
		sides = incomming & validSides;
	float time = [self timeToHitOfSide:sides byHero:hero];
	float dist = 0;
		
	if (sides) {
		float hc, hs, ha, l, pc, end;
		BOOL isH = sides & (kSideTop|kSideBottom);
		BOOL isV = sides & (kSideLeft|kSideRight);
		
		if (isV) {
			hc = hero.center.y;
			hs = hero.speed.y;
			ha = hero.acceleration.y;
			l = screen.sizeWithoutBorders.height + screen.position.y;
			pc = paddle.center.y;
		} else if (isH) {
			hc = hero.center.x;
			hs = hero.speed.x;
			ha = hero.acceleration.x;
			l = screen.sizeWithoutBorders.width + screen.position.x;
			pc = paddle.center.x;
		}
		
		// Find the final position of the ball
		end = hc + (hs + ha) * time;
			
		// Add in wall collisions for better accuracy
		// (according to the aiLevel level)
		for (int k=1; k < aiLevel; k++) {
			if (end > l) end = 2 * l - end;
			else if (end < 0) end = -end;
		}
		dist = end - pc;
		
		float vel = dist / time;
		
		// Add a little acceleration
		float accel = vel / (speedLimit / 0.2);
		
		// Calculate the velocity according to our acceleration
		vel = (dist + accel * sqrt (time) / 2) / time;
		
		if (isV) {
//			paddle.acceleration = ccp(0, accel);
			paddle.speed = [self limitSpeed:ccp(0, vel)];
		} else if (isH) {
//			paddle.acceleration = ccp(accel, 0);
			paddle.speed = [self limitSpeed:ccp(vel, 0)];
		}
	} else {
		sides = [self whereIsHero:hero] & validSides;
		BOOL isH = sides & (kSideTop|kSideBottom);
		BOOL isV = sides & (kSideLeft|kSideRight);
				
		paddle.acceleration = ccp (0, 0);
		
		if (isV) {
			if (paddle.minPosition.y && paddle.maxPosition.y)
				dist = paddle.minPosition.y + ((paddle.maxPosition.y - paddle.minPosition.y) / 2);
			else
				dist = (screen.size.height/2) + screen.position.y;
			
			if (dist == paddle.center.y)
				paddle.speed = ccp (0, 0);
			else
				paddle.speed = ccp(0, ((dist - paddle.center.y) / RANDOM_INT (REPOSITION_MIN, REPOSITION_MAX)));
		} else if (isH) {
			if (paddle.minPosition.x && paddle.maxPosition.x)
				dist = paddle.minPosition.x + ((paddle.maxPosition.x - paddle.minPosition.x) / 2);
			else
				dist = (screen.size.width/2) + screen.position.x;
			
			if (dist == paddle.center.x)
				paddle.speed = ccp (0, 0);
			else
				paddle.speed = ccp(((dist - paddle.center.x) / RANDOM_INT (REPOSITION_MIN, REPOSITION_MAX)), 0);
		}
	}
}

@end
