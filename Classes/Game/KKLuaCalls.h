//
//  KKLuaCalls.h
//  be2
//
//  Created by Alessandro Iob on 27/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "cocos2d.h"

void levelUpdate (ccTime dt);
void levelSetCurrentScreen (int screenIndex);

void screenUpdate (int screenIndex, ccTime dt);
void screenUpdateMainHeroWithPlayerInput (ccTime dt);
void screenOnEnter (int screenIndex);
void screenOnExit (int screenIndex);
void screenOnHeroHitBorders (int heroIndex, int collisionSide);

void paddleUpdate (int paddleIndex, ccTime dt);
void paddleUpdateAI (int paddleIndex, ccTime dt);
void paddleOnHit (int paddleIndex, int heroIndex, int collisionSide, CGPoint collisionPoint);
void paddleOnHeroInProxymityArea (int paddleIndex, int heroIndex);
void paddleOnEnter (int paddleIndex);
void paddleOnExit (int paddleIndex);
void paddleOnSideToggled (int paddleIndex, BOOL isDefensiveSide);
void paddleApplyProximityInfluenceToHero (int paddleIndex, int heroIndex, CGPoint speed, float dist);
void paddleTouchHandler (int paddleIndex, char *handler, CGPoint pos, int tapCount);
void paddleOnClick (int paddleIndex);

void mainHeroUpdate (ccTime dt);
