//
//  IntroScene.m
//  Be2
//
//  Created by Alessandro Iob on 4/28/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKIntroScene.h"
#import "KKScenesManager.h"
#import "KKGameScenes.h"
#import "KKMacros.h"

#import "KKInputManager.h"
#import "KKGameEngine.h"
#import "KKLuaManager.h"
#ifdef KK_DEBUG
#import "KKControlServerManager.h"
#endif

@implementation KKIntroScene

-(id) init
{
	self = [super init];
	
	if (self) {
		introLayer = [[KKIntroLayer layerWithColor:ccc4(0,0,0,255)] retain];
		[self addChild:introLayer z:2000];
			
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(introClosed:) name:NOTIF_INTRO_CLOSED object:nil];

		[introLayer playIntro];
	}
	
	return self;
}

-(void) dealloc
{
	if (introLayer) [introLayer release], introLayer = nil;
	
	[super dealloc];
}

-(void) introClosed:(id)sender
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activity.center = ccp (activity.frame.size.height + 6, ws.width/2);
	[activity startAnimating];
	[[[CCDirector sharedDirector] openGLView] addSubview:activity];
	
	[self schedule:@selector(loadingInit) interval:0.25];
}

-(void) loadingInit
{
	[self unschedule:@selector(loadingInit)];
	
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
	
	[KKSM loadScene:kSceneMainMenu transition:kTransitionFadeToBlack];
	
	[activity removeFromSuperview];
	[activity release], activity = nil;
}

@end
