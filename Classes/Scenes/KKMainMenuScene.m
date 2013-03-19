//
//  MainMenuScene.m
//  Be2
//
//  Created by Alessandro Iob on 4/21/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKMainMenuScene.h"
#import "KKInputManager.h"
#import "KKHUDLayer.h"
#import "KKGameEngine.h"

//#import "KKOpenFeintManager.h"
#import "AppDelegate.h"

@implementation KKMainMenuScene

-(id) init
{
	self = [super init];
	
	if (self) {
		gameEngine = KKGE;
		KKHUDLayer *hud = [KKHUDLayer layerWithColor:ccc4(0,0,0,0)];		
		[self addChild:hud z:1000];

		[self schedule:@selector(update:)];

	}
	return self;
}

-(void) update:(ccTime)dt
{	
	[gameEngine update:dt];
}

-(void) dealloc
{
	[level release], level = nil;
	gameEngine = nil;
	
	[super dealloc];
}

-(void) onEnter
{
	[super onEnter];
	
	[gameEngine startLevel:LEVEL_MAIN_MENU andAudio:YES];
	[KKIM setInputActive:YES];
	
//	[KKOFM applicationDidBecomeActive];
	[(AppDelegate *)[[UIApplication sharedApplication] delegate] initOpenFeint];
}

-(void) onExit
{
	[KKIM setInputActive:NO];
	
	[super onExit];
}

@end
