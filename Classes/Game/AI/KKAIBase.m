//
//  KKAIBase.m
//  be2
//
//  Created by Alessandro Iob on 29/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "KKAIBase.h"
#import "KKMacros.h"
#import "KKLevel.h"
#import "KKGraphicsManager.h"

@implementation KKAIBase

@synthesize config;

-(id) initWithPaddle:(KKPaddle *)aPaddle andConfig:(NSDictionary *)aConfig
{
	self = [super init];
	if (self) {
		paddle = aPaddle;
		level = paddle.level;
		config = [aConfig retain];
		data = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
		
		updateTime = DICT_INT (config, @"updateTimeout", AI_UPDATE_DEFAULT);
		updateTimeout = 0;
		
		flags = DICT_INT (config, @"flags", 0);
		validSides = DICT_INT (config, @"validSides", kSideLeft|kSideRight);
		aiLevel = DICT_FLOAT (config, @"aiLevel", 2.0);
		float mx = DICT_FLOAT (config, @"maxSpeedX", level.maxSpeed.x);
		if (mx == -1) mx = level.maxSpeed.x;
		float my = DICT_FLOAT (config, @"maxSpeedY", level.maxSpeed.y);
		if (my == -1) my = level.maxSpeed.y;
		maxSpeed = ccp (
						mx * MAX_SPEED_FACTOR,
						my * MAX_SPEED_FACTOR
						);
		maxSpeedBL = DICT_FLOAT (config, @"maxSpeedBL", 0) * MAX_SPEED_FACTOR;
		maxSpeedTR = DICT_FLOAT (config, @"maxSpeedTR", 0) * MAX_SPEED_FACTOR;
		sensorRange = CGSizeMake (
						SCALE_X (DICT_FLOAT (config, @"sensorRangeWidth", 0)),
						SCALE_Y (DICT_FLOAT (config, @"sensorRangeHeight", 0))
						);
		[self setup];
	}
	return self;
}

-(void) dealloc
{
	[super dealloc];
	
	if (data) [data release], data = nil;
	if (config) [config release], config = nil;
}

-(void) setup
{
	
}

#pragma mark -
#pragma mark Update

-(void) update:(ccTime)dt
{
}

#pragma mark -
#pragma mark Utilities

-(BOOL) needsUpdate:(ccTime)dt
{
	BOOL f = NO;
	
	updateTimeout -= dt;
	if (updateTimeout <= 0) {
		f = YES;
		updateTimeout = updateTime;
	}
	return f;
}

-(int) whereIsHero:(KKHero *)hero
{
	return whereIsRectForRect (paddle.bbox, hero.bbox);
}

-(int) isHeroIncomming:(KKHero *)hero
{
	CGPoint heroSpeed = hero.speed;
	int sides = whereIsRectForRect (hero.bbox, paddle.bbox);
	int incomming = kSideNone;
	
	if (sides & kSideTop && heroSpeed.y < 0) {
		incomming |= kSideTop;
	}else if (sides & kSideBottom && heroSpeed.y > 0) {
		incomming |= kSideBottom;
	}
	if (sides & kSideRight && heroSpeed.x < 0) {
		incomming |= kSideRight;
	}else if (sides & kSideLeft && heroSpeed.x > 0) {
		incomming |= kSideLeft;
	}
	return incomming;
}

-(BOOL) isHeroInsideProximityArea:(KKHero *)hero
{
	return [paddle isHeroInsideProximityArea:hero];
}

-(BOOL) isHeroInSensorRange:(KKHero *)hero
{
	CGRect bbox = CGRectMake(
							 paddle.position.x - sensorRange.width, 
							 paddle.position.y - sensorRange.height, 
							 paddle.size.width + sensorRange.width * 2,
							 paddle.size.height + sensorRange.height * 2
							 );
	return CGRectIntersectsRect(bbox, hero.bbox);
}

-(BOOL) isMainHeroMovedByPlayer
{
	return level.accelerationMode != kAccelerationUnknown;
}

-(float) timeToHitOfSide:(int)side byHero:(KKHero *)hero
{
	float dist;
	float time = -1;
	
	if (side & kSideTop) {
		dist = hero.position.y - (paddle.position.y + paddle.size.height);
		time = ABS(dist / hero.speed.y);
	} else if (side & kSideBottom) {
		dist = paddle.position.y - (hero.position.y + hero.size.height);
		time = ABS(dist / hero.speed.y);
	} else if (side & kSideRight) {
		dist = hero.position.x - (paddle.position.x + paddle.size.width);
		time = ABS(dist / hero.speed.x);
	} else if (side & kSideLeft) {
		dist = paddle.position.x - (hero.position.x + hero.size.width);
		time = ABS(dist / hero.speed.x);
	}
	
	return time;
}

-(CGPoint) limitSpeed:(CGPoint)speed
{
	float sx = PSign (speed.x);
	float sy = PSign (speed.y);
	
	if (maxSpeedTR && (sx > 0 || sy > 0)) {
		if (sx > 0 && ABS(speed.x) > maxSpeedTR) speed.x = maxSpeedTR;
		if (sy > 0 && ABS(speed.y) > maxSpeedTR) speed.y = maxSpeedTR;
	} else if (maxSpeedBL && (sx < 0 || sy < 0)) {
		if (sx < 0 && ABS(speed.x) > maxSpeedBL) speed.x = sx * maxSpeedBL;
		if (sy < 0 && ABS(speed.y) > maxSpeedBL) speed.y = sy * maxSpeedBL;
	} else {
		if (maxSpeed.x && ABS(speed.x) > maxSpeed.x) speed.x = sx * maxSpeed.x;
		if (maxSpeed.y && ABS(speed.y) > maxSpeed.y) speed.y = sy * maxSpeed.y;
	}
	return speed;
}

@end
