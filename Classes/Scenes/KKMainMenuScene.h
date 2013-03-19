//
//  MainMenuScene.h
//  Be2
//
//  Created by Alessandro Iob on 4/21/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"
#import "KKScene.h"

#import "KKLevel.h"

@class KKGameEngine;

@interface KKMainMenuScene : KKScene {
	KKGameEngine *gameEngine;
	KKLevel *level;
}

@end
