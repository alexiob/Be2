//
//  KKAIRover.h
//  be2
//
//  Created by Alessandro Iob on 24/8/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKAIBase.h"

#define AI_ROVER @"rover"

@interface KKAIRover : KKAIBase {
	CGPoint acceleration;
	float speedLimit;

	BOOL wasUserInputInRange;
}

@end
