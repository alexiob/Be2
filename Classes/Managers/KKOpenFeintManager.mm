//
//  KKOpenFeintManager.mm
//  Be2
//
//  Created by Alessandro Iob on 1/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKOpenFeintManager.h"
#import "SynthesizeSingleton.h"
#import "KKMacros.h"
#import "KKGlobalConfig.h"
#import "KKOpenFeintConfig.h"
#import "KKPersistenceManager.h"
#import "KKObjectsManager.h"
#import "KKSoundManager.h"
#import "KKHUDLayer.h"
#import "KKGameEngine.h"

#import "cocos2d.h"

#import "AppDelegate.h"

#import "OpenFeint+UserOptions.h"

#import "OpenFeintDelegate.h"

#import "OFChallengeDelegate.h"
#import "OFChallengeToUser.h"
#import "OFChallenge.h"
#import "OFChallengeDefinition.h"
#import "OFControllerLoader.h"

#import "OFNotificationDelegate.h"

#import "OFAchievementService.h"
#import "OFAchievementService+Private.h"
#import "OFUnlockedAchievementNotificationData.h"
#import "OFAchievement.h"

#import "OFSocialNotificationService.h"

#import "OFHighScoreService.h"

@interface KKOpenFeintManager () <OpenFeintDelegate, OFChallengeDelegate, OFNotificationDelegate>

-(void) dashboardWillAppear;
-(void) dashboardDidAppear;
-(void) dashboardWillDisappear;
-(void) dashboardDidDisappear;
-(void) userLoggedIn:(NSString*)userId;
-(BOOL) showCustomOpenFeintApprovalScreen;

-(void) userLaunchedChallenge:(OFChallengeToUser*)challengeToLaunch withChallengeData:(NSData*)challengeData;
-(void) userRestartedChallenge;

-(BOOL) isOpenFeintNotificationAllowed:(OFNotificationData*)notificationData;
-(void) handleDisallowedNotification:(OFNotificationData*)notificationData;
-(void) notificationWillShow:(OFNotificationData*)notificationData;

@end

@implementation KKOpenFeintManager

SYNTHESIZE_SINGLETON(KKOpenFeintManager);

-(id) init
{
	self = [super init];
	
#if OPENFEINT_ENABLED
	if (self) {
		NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:KKPM.deviceOrientation], OpenFeintSettingDashboardOrientation,
								  OPENFEINT_DISPLAY_NAME, OpenFeintSettingShortDisplayName,
								  [NSNumber numberWithBool:YES], OpenFeintSettingEnablePushNotifications,
								  [NSNumber numberWithBool:NO], OpenFeintSettingDisableUserGeneratedContent,
								  [NSNumber numberWithBool:NO], OpenFeintSettingAlwaysAskForApprovalInDebug,
								  [NSNumber numberWithBool:OPENFEINT_GAME_CENTER_ENABLED], OpenFeintSettingGameCenterEnabled,
								  [[[CCDirector sharedDirector] openGLView] window], OpenFeintSettingPresentationWindow,
								  nil
								  ];
		
		OFDelegatesContainer *delegates = [OFDelegatesContainer
										   containerWithOpenFeintDelegate:self
										   andChallengeDelegate:self
										   andNotificationDelegate:self
										   ];
		[OpenFeint 
		 initializeWithProductKey:OPENFEINT_PRODUCT_KEY 
		 andSecret:OPENFEINT_PRODUCT_SECRET 
		 andDisplayName:OPENFEINT_DISPLAY_NAME
		 andSettings:settings 
		 andDelegates:delegates
		];
		
		KKLOG(@"initialized");
	}
#endif
	
	return self;
}

-(void) dealloc
{
	[super dealloc];
}

#pragma mark -
#pragma mark Wrappers

-(void) launchDashboard
{
	[OpenFeint launchDashboard];
}

-(NSString *) lastLoggedInUserName
{
	return [OpenFeint lastLoggedInUserName];
}

#pragma mark -
#pragma mark Application logic

-(void) respondToApplicationLaunchOptions:(NSDictionary *)launchOptions
{
#if OPENFEINT_ENABLED
	[OpenFeint respondToApplicationLaunchOptions:launchOptions];
#endif	
}

-(void) applicationDidBecomeActive
{
#if OPENFEINT_ENABLED
	[OpenFeint applicationDidBecomeActive];
#endif	
}

-(void) applicationWillResignActive
{
#if OPENFEINT_ENABLED
	[OpenFeint applicationWillResignActive];
#endif	
}

-(void) shutdown
{
#if OPENFEINT_ENABLED
	[OpenFeint shutdown];
#endif	
}

-(void) applicationDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
#if OPENFEINT_ENABLED
	[OpenFeint applicationDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
#endif	
}

-(void) applicationDidFailToRegisterForRemoteNotifications
{
#if OPENFEINT_ENABLED
	[OpenFeint applicationDidFailToRegisterForRemoteNotifications];
#endif	
}

-(void) applicationDidReceiveRemoteNotification:(NSDictionary *)userInfo
{
#if OPENFEINT_ENABLED
	[OpenFeint applicationDidReceiveRemoteNotification:userInfo];
#endif	
}

#pragma mark -
#pragma mark Delegates

-(void) dashboardWillAppear
{
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] pauseApp];
//	[KKSNDM setMute:YES];
}

-(void) dashboardDidAppear
{
}

-(void) dashboardWillDisappear
{
//	[KKSNDM setMute:NO];
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] resumeApp];
}

-(void) dashboardDidDisappear
{
}

-(void) userLoggedIn:(NSString*)userId
{
	OFLog(@"New user logged in! Hello %@", [OpenFeint lastLoggedInUserName]);
}

-(BOOL) showCustomOpenFeintApprovalScreen
{
	return NO;
}

#pragma mark -
#pragma mark Delegates Challenge

-(void) userLaunchedChallenge:(OFChallengeToUser*)challengeToLaunch withChallengeData:(NSData*)challengeData
{
	OFLog(@"Launched Challenge: %@", challengeToLaunch.challenge.challengeDefinition.title);
//	PlayAChallengeController* controller = (PlayAChallengeController*)OFControllerLoader::load(@"PlayAChallenge");
//	[controller setChallenge:challengeToLaunch];
//	[controller setData:challengeData];
//	MyOpenFeintSampleAppDelegate* appDelegate = (MyOpenFeintSampleAppDelegate*)[[UIApplication sharedApplication] delegate];	
//	[appDelegate.rootController pushViewController:controller animated:YES];
}

-(void) userRestartedChallenge
{
	OFLog(@"Ignoring challenge restart.");
}

#pragma mark -
#pragma mark Delegates Notification

/*
kNotificationCategoryLogin,
kNotificationCategoryChallenge,
kNotificationCategoryHighScore,
kNotificationCategoryLeaderboard,
kNotificationCategoryAchievement,
kNotificationCategorySocialNotification,
kNotificationCategoryPresence
*/

/*
kNotificationTypeNone = 0,
kNotificationTypeSubmitting,
kNotificationTypeDownloading,
kNotificationTypeError,
kNotificationTypeSuccess,
kNotificationTypeNewResources,
kNotificationTypeUserPresenceOnline,
kNotificationTypeUserPresenceOffline,
kNotificationTypeNewMessage,
*/

-(BOOL) isOpenFeintNotificationAllowed:(OFNotificationData*)notificationData
{
	switch (notificationData.notificationType) {
		case kNotificationTypeError:
			return YES;
			break;
		default:
			break;
	}
	
	switch (notificationData.notificationCategory) {
		case kNotificationCategoryLogin:
		case kNotificationCategoryHighScore:
		case kNotificationCategoryLeaderboard:
		case kNotificationCategoryAchievement:
			return NO;
			break;
		default:
			return YES;
			break;
	}
}

#define NOTIFICATION_ACHIEVEMENT_BG_COLOR ccc3 (219, 159, 218)
#define NOTIFICATION_DEFAULT_BG_COLOR ccc3 (136, 176, 120)
#define NOTIFICATION_DEFAULT_COLOR ccc3 (255, 255, 255)

-(void) handleDisallowedNotification:(OFNotificationData*)notificationData
{
//	KKLOG (@"%@ c:(%d, %d) t:(%d, %d)", notificationData.notificationText, 
//		   notificationData.notificationCategory, kNotificationCategoryAchievement, 
//		   notificationData.notificationType, kNotificationTypeSuccess);
	
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	switch (notificationData.notificationCategory) {
		case kNotificationCategoryAchievement:
			if (notificationData.notificationType == kNotificationTypeSuccess) {
				OFUnlockedAchievementNotificationData *uaData = (OFUnlockedAchievementNotificationData *)notificationData;
//				NSString *uaIcon = [NSString stringWithFormat:@"/achievements/%@", [[uaData.unlockedAchievement.iconUrl pathComponents] lastObject]];	
				
				[KKGE.hud showMessage:[NSString stringWithFormat:NSLocalizedString (@"Congratulations, '%@' achievement unlocked!", @"achevement unlocked"), 
								  uaData.unlockedAchievement.title]
						emoticon:kEmoticonOpenFeint
						  origin:ccp (0, ws.height - 30) 
						 bgColor:NOTIFICATION_ACHIEVEMENT_BG_COLOR 
						msgColor:HUD_MESSAGE_COLOR
						icnColor:HUD_MESSAGE_EMOTICON_COLOR 
						fontSize:HUD_MESSAGE_FONT_SIZE 
						duration:8
				 ];
				[KKGE playSound:SOUND_OF_ACHIEVEMENT_UNLOCKED];
			}
			break;
		default:
			[KKGE.hud showMessage:[notificationData notificationText]
						 emoticon:kEmoticonOpenFeint
						   origin:ccp (ws.width, -30) 
						  bgColor:NOTIFICATION_DEFAULT_BG_COLOR
						 msgColor:NOTIFICATION_DEFAULT_COLOR
						 icnColor:HUD_MESSAGE_EMOTICON_COLOR 
						 fontSize:HUD_MESSAGE_FONT_SIZE 
						 duration:5
			 ];
			break;
	}
}

-(void) notificationWillShow:(OFNotificationData*)notificationData
{
//	KKLOG(@"An OpenFeint notification is about to pop-up: %@", notificationData.notificationText);
}

#pragma mark -
#pragma mark Achievements

-(void) unlockAchievement:(NSString*)achievementId
{
#ifndef KK_DEBUG
	if ([KKGE unlimitedLifes]) return;
#endif
	
//	[OFAchievementService unlockAchievement:achievementId];
	
	[[OFAchievement achievement:achievementId] updateProgressionComplete:100.0f andShowNotification:YES];	
}

-(BOOL) isAchievementUnlocked:(NSString*)achievementId
{
	BOOL unlocked = NO;
	
	NSString* lastLoggedInUser = [OpenFeint lastLoggedInUserId];
	if ([lastLoggedInUser longLongValue] > 0) {
		unlocked = [[OFAchievement achievement:achievementId] isUnlocked];
//		unlocked = [OFAchievementService alreadyUnlockedAchievement:achievementId forUser:lastLoggedInUser];
	}	
	return unlocked;
}

#pragma mark -
#pragma mark Leaderboards

-(void) setHighScore:(int)score forLeaderboard:(NSString*)lbid
{
#ifndef KK_DEBUG
	if ([KKGE unlimitedLifes]) return;
#endif	
	if (!lbid || [lbid isEqualToString:@""]) return;
	[OFHighScoreService setHighScore:score forLeaderboard:lbid onSuccess:OFDelegate() onFailure:OFDelegate()];
}


@end
