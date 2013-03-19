//
//  ScenesManager.m
//  Be2
//
//  Created by Alessandro Iob on 4/21/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKScenesManager.h"
#import "KKMacros.h"
#import "KKIntroScene.h"
#import "KKMainMenuScene.h"

#import "SynthesizeSingleton.h"

@implementation KKScenesManager

@synthesize currentScene, currentSceneId;

SYNTHESIZE_SINGLETON(KKScenesManager);

-(id) init
{
	self = [super init];
	
	if (self) {
		currentSceneId = kSceneNone;
		currentScene = nil;
	}
	return self;
}

-(void) dealloc
{
	[self unloadCurrentScene];
	
	[super dealloc];
}

#define FADE_TRANSITION_DURATION 0.6f

-(KKScene *) loadScene:(int)sceneId transition:(int)transitionId
{
	if (sceneId != currentSceneId) {
		currentSceneId = sceneId;
		currentScene = nil;
		
		switch (sceneId) {
			case kSceneIntro:
				currentScene = [KKIntroScene node];
				break;
			case kSceneMainMenu:
				currentScene = [KKMainMenuScene node];
				break;
		}

		CCScene *t = nil;
		
		switch (transitionId) {
			case kTransitionNone:
				t = currentScene;
				break;
			case kTransitionFadeToBlack:
				t = [CCFadeTransition transitionWithDuration:FADE_TRANSITION_DURATION scene:currentScene withColor:ccc3(0 , 0, 0)];
				break;
			case kTransitionFadeToWhite:
				t = [CCFadeTransition transitionWithDuration:FADE_TRANSITION_DURATION scene:currentScene withColor:ccc3(255, 255, 255)];
				break;
		}
		
		if (![CCDirector sharedDirector].runningScene)
			[[CCDirector sharedDirector] runWithScene:t];
		else
			[[CCDirector sharedDirector] replaceScene:t];
		
		[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	}
	return currentScene;
}

-(void) unloadCurrentScene
{
	if (currentScene != nil) {
		[currentScene release];
		currentScene = nil;
		currentSceneId = kSceneNone;
	}
}

@end
