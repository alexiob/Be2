//
//  KKOpenFeintManager.h
//  Be2
//
//  Created by Alessandro Iob on 1/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#define KKOFM [KKOpenFeintManager sharedKKOpenFeintManager]

@interface KKOpenFeintManager : NSObject {}

+(KKOpenFeintManager *) sharedKKOpenFeintManager;
+(void) purgeSharedKKOpenFeintManager;

-(void) launchDashboard;

-(NSString *) lastLoggedInUserName;

-(void) respondToApplicationLaunchOptions:(NSDictionary *)launchOptions;
-(void) applicationDidBecomeActive;
-(void) applicationWillResignActive;
-(void) shutdown;
-(void) applicationDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
-(void) applicationDidFailToRegisterForRemoteNotifications;
-(void) applicationDidReceiveRemoteNotification:(NSDictionary *)userInfo;

-(void) unlockAchievement:(NSString*)achievementId;
-(BOOL) isAchievementUnlocked:(NSString*)achievementId;

-(void) setHighScore:(int)score forLeaderboard:(NSString*)lbid;

@end
