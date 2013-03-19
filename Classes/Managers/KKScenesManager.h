//
//  ScenesManager.h
//  Be2
//
//  Created by Alessandro Iob on 4/21/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"
#import "KKGameScenes.h"
#import "KKScene.h"

#define KKSM [KKScenesManager sharedKKScenesManager]
#define CURRENT_SCENE KKSM.currentScene
//#define HUD [(KKScene *)CURRENT_SCENE hud]

@interface KKScenesManager : NSObject {
	int currentSceneId;
	KKScene *currentScene;
}

@property (readonly, nonatomic) int currentSceneId;
@property (readonly, nonatomic) KKScene *currentScene;

+(KKScenesManager *) sharedKKScenesManager;
+(void) purgeSharedKKScenesManager;

-(KKScene *) loadScene:(int)sceneId transition:(int)transitionId;
-(void) unloadCurrentScene;

@end
