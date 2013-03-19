//
//  KKLuaCalls.m
//  be2
//
//  Created by Alessandro Iob on 27/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "KKLuaCalls.h"

#import "KKGameEngine.h"
#import "KKLuaManager.h"
#import "KKMacros.h"
#import "KKMath.h"

#pragma mark -
#pragma mark Level

void levelUpdate (ccTime dt)
{
	//	[luaManager execString:[NSString stringWithFormat:@"level:update (%f)", dt]];
	lua_getglobal (mainState, "levelUpdate");
	lua_pushnumber(mainState, dt);
	lua_call (mainState, 1, 0);
}

void levelSetCurrentScreen (int screenIndex)
{
	//	[luaManager execString:[NSString stringWithFormat:@"level:setCurrentScreen (%d)", index]];
	lua_getglobal (mainState, "levelSetCurrentScreen");
	lua_pushinteger(mainState, screenIndex);
	lua_call (mainState, 1, 0);
}

#pragma mark -
#pragma mark Screen

void screenUpdate (int screenIndex, ccTime dt)
{
	//	[luaManager execString:[NSString stringWithFormat:@"level.screens[%d]:update (%f)", s.index, dt]];
	lua_getglobal (mainState, "screenUpdate");
	lua_pushinteger(mainState, screenIndex);
	lua_pushnumber(mainState, dt);
	lua_call (mainState, 2, 0);
}

void screenUpdateMainHeroWithPlayerInput (ccTime dt)
{
//	[luaManager execString:[NSString stringWithFormat:@"screen:updateMainHeroWithPlayerInput (%d, %f)", hero.index, dt]];
	lua_getglobal (mainState, "screenUpdateMainHeroWithPlayerInput");
	lua_pushnumber(mainState, dt);
	lua_call (mainState, 1, 0);
}

void screenOnHeroHitBorders (int heroIndex, int collisionSide)
{
//	[luaManager execString:[NSString stringWithFormat:@"screen:onHeroHitBorders (%d, %d)", hero.index, collisionSide]];
	lua_getglobal (mainState, "screenOnHeroHitBorders");
	lua_pushinteger(mainState, heroIndex);
	lua_pushinteger(mainState, collisionSide);
	lua_call (mainState, 2, 0);
}

void screenOnEnter (int screenIndex)
{
	//	[luaManager execString:[NSString stringWithFormat:@"level.screens[%d]:onEnter ()", index]];
	lua_getglobal (mainState, "screenOnEnter");
	lua_pushinteger(mainState, screenIndex);
	lua_call (mainState, 1, 0);
}

void screenOnExit (int screenIndex)
{
	//	[luaManager execString:[NSString stringWithFormat:@"level.screens[%d]:onExit ()", index]];
	lua_getglobal (mainState, "screenOnExit");
	lua_pushinteger(mainState, screenIndex);
	lua_call (mainState, 1, 0);
}


#pragma mark -
#pragma mark Paddle

void paddleUpdate (int paddleIndex, ccTime dt)
{
	//	[luaManager execString:[NSString stringWithFormat:@"level.paddles[%d]:update (%f)", paddle.index, dt]];
	lua_getglobal (mainState, "paddleUpdate");
	lua_pushinteger(mainState, paddleIndex);
	lua_pushnumber(mainState, dt);
	lua_call (mainState, 2, 0);
}

void paddleUpdateAI (int paddleIndex, ccTime dt)
{
	//	[luaManager execString:[NSString stringWithFormat:@"level.paddles[%d]:updateAI (%f)", [i intValue], dt]];
	lua_getglobal (mainState, "paddleUpdateAI");
	lua_pushinteger(mainState, paddleIndex);
	lua_pushnumber(mainState, dt);
	lua_call (mainState, 2, 0);
}

void paddleOnHit (int paddleIndex, int heroIndex, int collisionSide, CGPoint collisionPoint)
{
//	NSString *s = [NSString stringWithFormat:@"level.paddles[%d]:onHit (%d, %d, %f, %f)", 
//			   paddle.index, 
//			   hero.index,
//			   collisionSide,
//			   collisionPoint.x, collisionPoint.y];
//	[luaManager execString:s];
	lua_getglobal (mainState, "paddleOnHit");
	lua_pushinteger(mainState, paddleIndex);
	lua_pushinteger(mainState, heroIndex);
	lua_pushinteger(mainState, collisionSide);
	lua_pushnumber(mainState, collisionPoint.x);
	lua_pushnumber(mainState, collisionPoint.y);
	lua_call (mainState, 5, 0);
}

void paddleOnHeroInProxymityArea (int paddleIndex, int heroIndex)
{
//	NSString *s = [NSString stringWithFormat:@"level.paddles[%d]:onHeroInProxymityArea (%d)", 
//			   paddle.index, 
//			   hero.index
//			   ];			
//	[luaManager execString:s];
	lua_getglobal (mainState, "paddleOnHeroInProxymityArea");
	lua_pushinteger(mainState, paddleIndex);
	lua_pushinteger(mainState, heroIndex);
	lua_call (mainState, 2, 0);
}

void paddleOnEnter (int paddleIndex)
{
//	[luaManager execString:[NSString stringWithFormat:@"level.paddles[%d]:onEnter ()", index]];
	lua_getglobal (mainState, "paddleOnEnter");
	lua_pushinteger(mainState, paddleIndex);
	lua_call (mainState, 1, 0);
}

void paddleOnExit (int paddleIndex)
{
//	[luaManager execString:[NSString stringWithFormat:@"level.paddles[%d]:onExit ()", index]];
	lua_getglobal (mainState, "paddleOnExit");
	lua_pushinteger(mainState, paddleIndex);
	lua_call (mainState, 1, 0);
}

void paddleApplyProximityInfluenceToHero (int paddleIndex, int heroIndex, CGPoint speed, float dist)
{
//	NSString *str = [NSString stringWithFormat:@"level.paddles[%d]:applyProximityInfluenceToHero (%d, %f, %f, %f)", 
//					 index, 
//					 hero.index,
//					 s.x, s.y,
//					 dist
//					 ];
//	[luaManager execString:str];
	lua_getglobal (mainState, "paddleApplyProximityInfluenceToHero");
	lua_pushinteger(mainState, paddleIndex);
	lua_pushinteger(mainState, heroIndex);
	lua_pushnumber(mainState, speed.x);
	lua_pushnumber(mainState, speed.y);
	lua_pushnumber(mainState, dist);
	lua_call (mainState, 5, 0);
}

void paddleOnSideToggled (int paddleIndex, BOOL isDefensiveSide)
{
//	[luaManager execString:[NSString stringWithFormat:@"level.paddles[%d]:onSideToggled (%d)", index, [self isDefensiveSide]]];
	lua_getglobal (mainState, "paddleOnSideToggled");
	lua_pushinteger(mainState, paddleIndex);
	lua_pushboolean(mainState, isDefensiveSide);
	lua_call (mainState, 2, 0);
}

void paddleTouchHandler (int paddleIndex, char *handler, CGPoint pos, int tapCount)
{
//	NSString *s = [NSString stringWithFormat:@"level.paddles[%d]:%@ (%f, %f, %d)", 
//				   index, 
//				   handler, 
//				   pos.x, pos.y, 
//				   tapCount];
//	[luaManager execString:s];
	lua_getglobal (mainState, "paddleTouchHandler");
	lua_pushinteger(mainState, paddleIndex);
	lua_pushstring(mainState, handler);
	lua_pushnumber(mainState, pos.x);
	lua_pushnumber(mainState, pos.y);
	lua_pushinteger(mainState, tapCount);
	lua_call (mainState, 5, 0);
}

void paddleOnClick (int paddleIndex)
{
//	NSString *s = [NSString stringWithFormat:@"level.paddles[%d]:onClick ()", index];
//	[luaManager execString:s];
	lua_getglobal (mainState, "paddleOnClick");
	lua_pushinteger(mainState, paddleIndex);
	lua_call (mainState, 1, 0);
}

#pragma mark -
#pragma mark Hero

void mainHeroUpdate (ccTime dt)
{
	//	[luaManager execString:[NSString stringWithFormat:@"mainHero:update (%f)", dt]];
	lua_getglobal (mainState, "mainHeroUpdate");
	lua_pushnumber(mainState, dt);
	lua_call (mainState, 1, 0);
}


