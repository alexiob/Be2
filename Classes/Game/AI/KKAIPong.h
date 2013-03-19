//
//  KKAIPong.h
//  be2
//
//  Created by Alessandro Iob on 29/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "KKAIBase.h"

#define AI_PONG @"pong"

@interface KKAIPong : KKAIBase {
	float speedLimit;
	BOOL centerWhenNotIncomming;
	BOOL wasUserInputInRange;
	
	int randomStopImprobability;
	float randomStopTimeout;
	float randomStopCurrentTimeout;
	BOOL randomStopActive;
}

@end
