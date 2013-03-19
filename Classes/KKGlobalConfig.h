//
//  KKGlobalConfig.h
//  Be2
//
//  Created by Alessandro Iob on 6/24/09.
//  Copyright 2009 Kismik. All rights reserved.
//

// PREPROCESSOR FLAGS: KK_DEBUG COCOS2D_DEBUG DEBUG ANALYTICS_ENABLED ADDS_ENABLED ADDS_TEST

#import "KKAudioConfig.h"
#import "KKGraphicsConfig.h"

#ifdef KK_BE2_FREE
#define APPLE_ID @"123456789"
#else
#define APPLE_ID @"987654321"
#endif

/*
// ADDS
#ifdef ADDS_TEST
	#define APP_ID_GREYSTRIPE 123456789
#else
	#define APP_ID_GREYSTRIPE 123456789
#endif
*/

#define UPDATE_INTERVAL_GAME 60.0
#define UPDATE_INTERVAL_PHYSICS UPDATE_INTERVAL_GAME
#define UPDATE_INTERVAL_ACCELEROMETER 30.0

#define LEVEL_MAIN_MENU @"mainMenu"
#define LEVEL_QUEST_START @"pongland"

#define SCORE_PER_BORDER_HIT 100
#define SCORE_PER_HIT 150
#define SCORE_PER_SECOND_LEFT 1000

#define APP_FIRST_RUN @"appFirstRun"
#define APP_NUM_LAUNCHES @"appNumLaunches"
#define APP_RATED_VERSION @"appRatedVersion"

#define APP_BE2_TRAILER_VIEWED @"appBe2TrailerViewed"
