//
//  KKGameScenes.h
//  Be2
//
//  Created by Alessandro Iob on 4/21/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

typedef enum {
	kSceneNone = 0,
	kSceneIntro = 1,
	kSceneMainMenu,
} tGameScenes;

typedef enum {
	kTransitionNone = 0,
	kTransitionFadeToWhite = 1,
	kTransitionFadeToBlack,
} tGameSceneTransitions;