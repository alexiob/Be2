//
//  AppDelegate.h
//  Be2
//
//  Created by Alessandro Iob on 6/8/09.
//  Copyright Kismik 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

#import "KKScenesManager.h"
#import "KKMacros.h"

#define NOTIF_APP_MEMORY_WORNING @"notificationAppMemoryWarning"
#define NOTIF_APP_SIGNIFICANT_TIME_CHANGE @"notificationAppSignificantTimeChange"
#define NOTIF_APP_PAUSED @"notificationAppPaused"
#define NOTIF_APP_RESUMED @"notificationAppResumed"

@interface AppDelegate : NSObject <UIAlertViewDelegate, UITextFieldDelegate, UIApplicationDelegate ADD_GREYSTRIPE_DELEGATE>
{
	UIWindow *window;
	CCDirector *director;
	
	KKScenesManager *scenesManager;
	
	BOOL bgMusicPlaying;
	BOOL firstDidBecomeActive;
	NSDictionary *openFeintLaunchOptions;
}

-(void) setupApp;
-(void) pauseApp;
-(void) resumeApp;

-(void) initOpenFeint;

@end
