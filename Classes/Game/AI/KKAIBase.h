//
//  KKAIBase.h
//  be2
//
//  Created by Alessandro Iob on 29/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "cocos2d.h"
#import "KKPaddle.h"
#import "KKHero.h"
#import "KKCollisionDetection.h"
#import "KKMath.h"

#define AI_UPDATE_DEFAULT 0.6
#define MAX_SPEED_FACTOR 0.4

typedef enum {
	kAIFlagCheckInSensorRange = 1 << 0,
	kAIFlagCheckOutSensorRange = 1 << 1,
	kAIFlagCheckInProximityArea = 1 << 2,
	kAIFlagCheckOutProximityArea = 1 << 3,
} tAIFlag;

@interface KKAIBase : NSObject {
	KKLevel *level;
	KKPaddle *paddle;
	NSDictionary *config;
	NSMutableDictionary *data;
	
	int flags;
	
	float updateTime;
	float updateTimeout;
	
	int validSides;
	float aiLevel;
	CGPoint maxSpeed;
	float maxSpeedBL;
	float maxSpeedTR;
	CGSize sensorRange;
}

@property (readonly, nonatomic) NSDictionary *config;

-(id) initWithPaddle:(KKPaddle *)aPaddle andConfig:(NSDictionary *)aConfig;
-(void) setup;
-(void) update:(ccTime)dt;

-(BOOL) needsUpdate:(ccTime)dt;
-(int) whereIsHero:(KKHero *)hero;
-(int) isHeroIncomming:(KKHero *)hero;
-(BOOL) isHeroInsideProximityArea:(KKHero *)hero;
-(BOOL) isHeroInSensorRange:(KKHero *)hero;
-(BOOL) isMainHeroMovedByPlayer;
-(float) timeToHitOfSide:(int)side byHero:(KKHero *)hero;
-(CGPoint) limitSpeed:(CGPoint)speed;

@end
