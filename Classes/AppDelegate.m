//
//  AppDelegate.m
//  Be2
//
//  Created by Alessandro Iob on 6/8/09.
//  Copyright Kismik 2009. All rights reserved.
//

#import "AppDelegate.h"

#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKDeviceDetection.h"
#import "KKPersistenceManager.h"
#import "KKGraphicsManager.h"
#import "KKSoundManager.h"
#import "KKInputManager.h"
#import "KKObjectsManager.h"
#import "KKGameEngine.h"
#import "KKLuaManager.h"
//#import "KKOpenFeintManager.h"
#import "KKHUDLayer.h"
//#import "KKStoreManager.h"

#ifdef KK_DEBUG
#import "KKControlServerManager.h"
#endif

@implementation AppDelegate

-(void) applicationDidFinishLaunching:(UIApplication *)application
{
	[self setupApp];
}

-(BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	openFeintLaunchOptions = [[NSDictionary dictionaryWithDictionary:launchOptions] retain];
	
	[self setupApp];
	
	return YES;
}

-(void) setupApp
{	
//	PMA_INIT
//	ADD_GREYSTRIPE_INIT
	
	firstDidBecomeActive = YES;
	
	if (isIPad) {
		UIDeviceOrientation o = [UIDevice currentDevice].orientation;
		if (o == UIDeviceOrientationUnknown) o = UIDeviceOrientationPortrait;
		KKPM.deviceOrientation = o;
	} else {
		KKPM.deviceOrientation = UIDeviceOrientationLandscapeLeft;
	}

	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[window setUserInteractionEnabled:YES];
	[window setMultipleTouchEnabled:YES];
	
	if (![CCDirector setDirectorType:kCCDirectorTypeDisplayLink]) {
		[CCDirector setDirectorType:kCCDirectorTypeDefault];
//		[CCDirector setDirectorType:kCCDirectorTypeMainLoop];
	}
	
	director = [CCDirector sharedDirector];
	
	// texture pixel format
//	[director setPixelFormat:kCCRGBA8];
	[director setPixelFormat:kCCPixelFormatRGB565];
//	[director setDepthBufferFormat:kCCDepthBuffer24];
//	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
	
	// setup director
	[director setAnimationInterval:1.0 / UPDATE_INTERVAL_GAME];
	[director setDeviceOrientation:kCCDeviceOrientationLandscapeLeft];
#ifdef KK_DEBUG
	//[director setDisplayFPS:YES];
#endif
	[director attachInWindow:window];

	// init persistence manager
	[KKPersistenceManager sharedKKPersistenceManager];
	
	// saved game
	[KKPM loadGame];
	
	// init store manager
//	[KKStoreManager sharedKKStoreManager];
	
	// init graphics manager
	[KKGraphicsManager sharedKKGraphicsManager];
	
	// init sound engine
	[KKSoundManager sharedKKSoundManager];
	
	// init first scene
	[KKSM loadScene:kSceneIntro transition:kTransitionNone];
/*	
	// init input manager
	[[KKInputManager sharedKKInputManager] setInputActive:NO];
	
	// init lua manager
	[KKLuaManager sharedKKLuaManager];

	// init game engine
	[KKGameEngine sharedKKGameEngine];

#ifdef KK_DEBUG
	// start control server
	[[KKControlServerManager sharedKKControlServerManager] start];
#endif
*/	
	// show UI and avoid first black frame
	[window makeKeyAndVisible];
}

-(void) initOpenFeint
{
//	[KKOFM respondToApplicationLaunchOptions:openFeintLaunchOptions];
	[openFeintLaunchOptions release];
}

-(void) pauseApp
{
	if (!director.isPaused) {
//		bgMusicPlaying = [KKSNDM isBackgroundMusicPlaying];
//		if (bgMusicPlaying)
//			[KKSNDM pauseBackgroundMusic];
		
		[director stopAnimation];
		[director pause];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_APP_PAUSED object:nil];
		
#ifdef KK_DEBUG
		// stop control server
		[[KKControlServerManager sharedKKControlServerManager] stop];
#endif
	}
}

-(void) resumeApp
{
	if (director.isPaused) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_APP_RESUMED object:nil];
		
//		if (bgMusicPlaying)
//			[KKSNDM resumeBackgroundMusic];
		
		[director stopAnimation];
		[director resume];
		[director startAnimation];

#ifdef KK_DEBUG
		// start control server
		[[KKControlServerManager sharedKKControlServerManager] start];
#endif
	}
}

-(void) applicationWillResignActive:(UIApplication *)application
{
//	[KKOFM applicationWillResignActive];

	[KKPM saveUserDefaults];

	[self pauseApp];
}

-(void) applicationDidBecomeActive:(UIApplication *)application
{
//	if (!firstDidBecomeActive)
//		[KKOFM applicationDidBecomeActive];
//	else
		firstDidBecomeActive = NO;
	
	[self resumeApp];
}

-(void) applicationWillEnterForeground:(UIApplication *)application
{
	[self resumeApp];
	
	if (![KKGE isMainMenu] && [KKGE currentGameState] == kGSInGame) {
		[KKGE onPause];
		[(KKHUDLayer *)[KKGE hud] showPauseDialog:YES];
	}
}

-(void) applicationDidEnterBackground:(UIApplication *)application
{
	[self pauseApp];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[[CCTextureCache sharedTextureCache] removeAllTextures];
	[director purgeCachedData];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_APP_MEMORY_WORNING object:nil];
}

-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[director setNextDeltaTimeZero:YES];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_APP_SIGNIFICANT_TIME_CHANGE object:nil];
}

-(void) applicationWillTerminate:(UIApplication*)application {
	[KKPM saveUserDefaults];
	
//	[KKOFM shutdown];
	
//	PMA_END
//	ADD_GREYSTRIPE_END
	
	if ([KKSNDM isBackgroundMusicPlaying])
		[KKSNDM stopBackgroundMusic];

#ifdef KK_DEBUG
	[[KKControlServerManager sharedKKControlServerManager] stop];
	[KKControlServerManager purgeSharedKKControlServerManager];
#endif
	
	[KKScenesManager purgeSharedKKScenesManager];
	[KKLuaManager purgeSharedKKLuaManager];
	[KKGraphicsManager purgeSharedKKGraphicsManager];
	[KKInputManager purgeSharedKKInputManager];
	[KKSoundManager purgeSharedKKSoundManager];
	[KKPersistenceManager purgeSharedKKPersistenceManager];
	[KKObjectsManager purgeSharedKKObjectsManager];
}

- (void)dealloc {
    [super dealloc];
}

-(void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
//	[KKOFM applicationDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

-(void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
//	[KKOFM applicationDidFailToRegisterForRemoteNotifications];
}

-(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
//	[KKOFM applicationDidReceiveRemoteNotification:userInfo];
}

/*
#ifdef ADDS_ENABLED

-(void) greystripeDisplayWillOpen
{
	[self pauseApp];
}

-(void) greystripeDisplayWillClose
{
	[self resumeApp];
}

#endif
*/
@end
