//
//  KKLuaGameLib.m
//  be2
//
//  Created by Alessandro Iob on 2/22/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKLuaGameLib.h"

#import "KKLuaManager.h"
#import "KKMacros.h"
#import "KKGameEngine.h"
#import "KKMath.h"
#import "KKSoundManager.h"
#import "KKPersistenceManager.h"
#import "KKStringUtilities.h"
#import "KKHUDLayer.h"
//#import "KKOpenFeintManager.h"
#import "KKGraphicsManager.h"

#pragma mark -
#pragma mark Game Utilities

static int luaIsFreeVersion (lua_State *l)
{
	lua_pushboolean(l, [KKGE isFreeVersion]);
	return 1;
}

static int luaAreAllLevelsPurchased (lua_State *l)
{
	lua_pushboolean(l, [KKGE areAllLevelsPurchased]);
	return 1;
}

static int luaBuyAllLevels (lua_State *l)
{
	[KKGE buyAllLevels];
	return 0;
}

static int luaGetGlobal (lua_State *l)
{
	lua_pushinteger(l, [KKGE getGlobal:lua_tointeger(l, 1)]);
	return 1;
}

static int luaSetGlobal (lua_State *l)
{
	[KKGE setGlobal:lua_tointeger(l, 1) toInteger:lua_tointeger(l, 2)];
	return 0;
}

static int luaInputMode (lua_State *l)
{
	lua_pushinteger(l, [KKGE inputMode]);
	return 1;
}

static int luaSetInputMode (lua_State *l)
{
	[KKGE setInputMode:lua_tointeger(l, 1)];
	return 0;
}

static int luaDifficultyLevel (lua_State *l)
{
	lua_pushinteger(l, [KKGE difficultyLevel]);
	return 1;
}

static int luaSetDifficultyLevel (lua_State *l)
{
	[KKGE setDifficultyLevel:lua_tointeger(l, 1)];
	return 0;
}

static int luaStartGameWithLevelName (lua_State *l)
{
	[KKGE startGame:STR_C2NS(lua_tostring(l, 1)) mode:lua_tointeger(l, 2) reset:lua_toboolean(l, 3)];
	return 0;
}

static int luaStartGameWithLevelIndex (lua_State *l)
{
	[KKGE startGame:[KKGE levelNameFromIndex:lua_tointeger(l, 1)] mode:lua_tointeger(l, 2) reset:lua_toboolean(l, 3)];
	return 0;
}

static int luaHasSavedGame (lua_State *l)
{
	lua_pushboolean(l, [KKPM hasSavedGame]);
	return 1;
}

static int luaResumeSavedGame (lua_State *l)
{
	[KKGE resumeSavedGame];
	return 1;
}

static int luaStartLevelName (lua_State *l)
{
	[KKGE startLevel:STR_C2NS(lua_tostring(l, 1)) withTimeout:lua_tonumber(l, 2)];
	return 0;
}

static int luaStartLevelIndex (lua_State *l)
{
	[KKGE startLevel:[KKGE levelNameFromIndex:lua_tointeger(l, 1)] withTimeout:lua_tonumber(l, 2)];
	return 0;
}

static int luaScoreAdd (lua_State *l)
{
	[KKGE scoreAdd:lua_tointeger(l, 1)];
	return 0;
}

static int luaTimeAdd (lua_State *l)
{
	[KKGE timeAdd:lua_tonumber(l, 1)];
	return 0;
}

static int luaExplorationPointsAdd (lua_State *l)
{
	[KKGE explorationPointsAdd:lua_tointeger(l, 1)];
	return 0;
}

static int luaShowLevelScorePanel (lua_State *l)
{
	[KKGE.hud showLevelScorePanelWithDelay:lua_tonumber(l, 1)
								   message:STR_C2NS(lua_tostring(l, 2)) 
									 acNum:lua_tointeger(l, 3)
									 acTot:lua_tointeger(l, 4)
								   acScore:lua_tointeger(l, 5)
								bonusScore:lua_tointeger(l, 6)
								 nextLevel:STR_C2NS(lua_tostring(l, 7))
	 ];
	return 0;
}


static int luaScoreStats (lua_State *l)
{
	lua_pushinteger(l, KKGE.score);
	lua_pushinteger(l, KKGE.scoreMultiplier);
	lua_pushinteger(l, KKGE.previousLevelScore);
	lua_pushinteger(l, KKGE.currentLevelScore);
	return 4;
}

static int luaTimeStats (lua_State *l)
{
	lua_pushnumber(l, KKGE.questTimeElapsed);
	lua_pushnumber(l, KKGE.levelTimeElapsed);
	lua_pushnumber(l, KKGE.levelTimeLeft);
	return 3;
}

static int luaExplorationStats (lua_State *l)
{
	lua_pushinteger(l, KKGE.questExplorationPoints);
	lua_pushinteger(l, KKGE.questTotalExplorationPoints);
	return 2;
}

static int luaAddLife (lua_State *l)
{
	[KKGE addLife];
	return 0;
}

static int luaRemoveLife (lua_State *l)
{
	[KKGE removeLife];
	return 0;
}

static int luaDie (lua_State *l)
{
	[KKGE die:lua_tointeger(l, 1)];
	return 0;
}

static int luaKill (lua_State *l)
{
	[KKGE die:kDieKilled];
	return 0;
}

static int luaKillWithMessage (lua_State *l)
{
	[KKGE die:kDieKilled withMessage:STR_C2NS(lua_tostring(l, 1))];
	return 0;
}

static int luaQuestEnd (lua_State *l)
{
	[KKGE questEnd];
	return 0;
}

static int luaIsFullQuest (lua_State *l)
{
	lua_pushboolean(l, [KKGE isFullQuest]);
	return 1;
}

static int luaIsFullQuestCompleted (lua_State *l)
{
	lua_pushboolean(l, [KKGE isFullQuestCompleted]);
	return 1;
}

static int luaSetFullQuestCompleted (lua_State *l)
{
	[KKGE setFullQuestCompleted:lua_toboolean(l, 1)];
	return 0;
}

static int luaRateNow (lua_State *l)
{
	[KKGE rateNow];
	return 0;
}

static int luaShouldRate (lua_State *l)
{
	lua_pushboolean(l, [KKGE shouldRate]);
	return 1;
}

static int luaOpenKismikURL (lua_State *l)
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.kismik.com"]];
	return 0;
}

static int luaOpenBe2EscapeURL (lua_State *l)
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.be2escape.info"]];
	return 0;
}

static int luaOpenIncompetechURL (lua_State *l)
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://incompetech.com"]];
	return 0;
}

static int luaOpenCocos2DURL (lua_State *l)
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.cocos2d-iphone.org/"]];
	return 0;
}

static int luaPlayBe2Trailer (lua_State *l)
{
	[KKGE playBe2Trailer];
	return 0;
}

static int luaWasBe2TrailerViewed (lua_State *l)
{
	lua_pushboolean(l, [KKGE wasBe2TrailerViewed]);
	return 1;
}

static int luaScaleX(lua_State *l)
{
	lua_pushnumber(l, SCALE_X(lua_tonumber(l, 1)));
	return 1;
}

static int luaScaleY(lua_State *l)
{
	lua_pushnumber(l, SCALE_Y(lua_tonumber(l, 1)));
	return 1;
}

static int luaNormX(lua_State *l)
{
	lua_pushnumber(l, NORM_X(lua_tonumber(l, 1)));
	return 1;
}

static int luaNormY(lua_State *l)
{
	lua_pushnumber(l, NORM_Y(lua_tonumber(l, 1)));
	return 1;
}

#pragma mark -
#pragma mark Game Missions

static int luaSetGlobalMissionFieldToBool (lua_State *l)
{
	[KKGE setGlobalMission:STR_C2NS(lua_tostring(l, 1)) field:STR_C2NS(lua_tostring(l, 2)) toBool:lua_toboolean(l, 3)];
	return 0;
}

static int luaSetGlobalMissionFieldToInt (lua_State *l)
{
	[KKGE setGlobalMission:STR_C2NS(lua_tostring(l, 1)) field:STR_C2NS(lua_tostring(l, 2)) toInt:lua_tointeger(l, 3)];
	return 0;
}

static int luaSetGlobalMissionFieldToFloat (lua_State *l)
{
	[KKGE setGlobalMission:STR_C2NS(lua_tostring(l, 1)) field:STR_C2NS(lua_tostring(l, 2)) toFloat:lua_tonumber(l, 3)];
	return 0;
}

static int luaSetGlobalMissionFieldToString (lua_State *l)
{
	[KKGE setGlobalMission:STR_C2NS(lua_tostring(l, 1)) field:STR_C2NS(lua_tostring(l, 2)) toString:STR_C2NS(lua_tostring(l, 3))];
	return 0;
}

static int luaGlobalMissionBoolField (lua_State *l)
{
	BOOL f = [KKGE globalMission:STR_C2NS(lua_tostring(l, 1)) boolField:STR_C2NS(lua_tostring(l, 2))];
	lua_pushboolean(l, f);
	return 1;
}

static int luaGlobalMissionIntField (lua_State *l)
{
	int f = [KKGE globalMission:STR_C2NS(lua_tostring(l, 1)) intField:STR_C2NS(lua_tostring(l, 2))];
	lua_pushinteger(l, f);
	return 1;
}

static int luaGlobalMissionFloatField (lua_State *l)
{
	float f = [KKGE globalMission:STR_C2NS(lua_tostring(l, 1)) floatField:STR_C2NS(lua_tostring(l, 2))];
	lua_pushnumber(l, f);
	return 1;
}

static int luaGlobalMissionStringField (lua_State *l)
{
	NSString *f = [KKGE globalMission:STR_C2NS(lua_tostring(l, 1)) stringField:STR_C2NS(lua_tostring(l, 2))];
	lua_pushstring(l, STR_NS2C(f));
	return 1;
}

#pragma mark -
#pragma mark Math

static int luaMathRandomIntRange (lua_State *l)
{
	lua_pushinteger(l, RANDOM_INT (lua_tointeger(l, 1), lua_tointeger(l, 2)));
	return 1;
}

static int luaMathRandomInt (lua_State *l)
{
	lua_pushinteger(l, random ());
	return 1;
}
		
#pragma mark -
#pragma mark HUD

static int luaHUDShowTimerLabel (lua_State *l)
{
	[KKGE.hud showTimerLabel:STR_C2NS(lua_tostring(l, 1)) sound:STR_C2NS(lua_tostring(l, 2))];
	return 0;
}

static int luaHUDShowZoomingText (lua_State *l)
{
	[KKGE.hud showZoomingText:STR_C2NS(lua_tostring(l, 1)) sound:STR_C2NS(lua_tostring(l, 2))];
	return 0;
}

#pragma mark -
#pragma mark OpenFeint

static int luaOpenFeintLaunchDashboard (lua_State *l)
{
//	[KKOFM launchDashboard];
	return 0;
}

static int luaOpenFeintLastLoggedInUserName (lua_State *l)
{
	lua_pushstring(l, STR_NS2C (@"be2"));//[KKOFM lastLoggedInUserName]));
	return 1;
}

static int luaOpenFeintUnlockAchievement (lua_State *l)
{
//	[KKOFM unlockAchievement:STR_C2NS(lua_tostring(l, 1))];
	return 0;
}

static int luaOpenFeintIsAchievementUnlocked (lua_State *l)
{
//	BOOL b = [KKOFM isAchievementUnlocked:STR_C2NS(lua_tostring(l, 1))];
	lua_pushboolean(l, YES);
	return 1;
}


static int luaOpenFeintSetHighScoreForLeadeboard (lua_State *l)
{
//	[KKOFM setHighScore:lua_tointeger(l, 1) forLeaderboard:STR_C2NS(lua_tostring(l, 2))];
	return 0;
}

#pragma mark -
#pragma mark Level

#define GET_CURRENT_LEVEL KKLevel *level = [KKGE level];

static int luaLevelName (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushstring(l, STR_NS2C(level.name));
	return 1;
}

static int luaLevelTitle (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushstring(l, STR_NS2C(level.title));
	return 1;
}

static int luaLevelDesc (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushstring(l, STR_NS2C(level.desc));
	return 1;
}

static int luaLevelNextLevelName (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushstring(l, STR_NS2C(level.nextLevelName));
	return 1;
}

static int luaLevelThumbnailImageName (lua_State *l)
{
	lua_pushstring(l, STR_NS2C([KKGE thumbnailImageNameForLevelIndex:lua_tointeger (l, 1)]));
	return 1;
}

static int luaLevelSetBGImageIndexTexturePositionOpacityDuration (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[level setBGImage:lua_tointeger(l, 1)
			  texture:STR_C2NS (lua_tostring (l, 2)) 
			 position:ccp (lua_tonumber(l, 3), lua_tonumber(l, 4))
			  opacity:lua_tointeger(l, 5) 
			 duration:lua_tonumber(l, 6)
	 ];
	return 0;
}

static int luaLevelUnsetBGImageIndex (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[level unsetBGImage:lua_tointeger(l, 1)];
	
	return 0;
}

static int luaLevelKind (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushinteger(l, level.kind);
	return 1;
}

static int luaLevelNumScreens (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushinteger(l, level.numScreens);
	return 1;
}

static int luaLevelFlags (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushinteger(l, level.flags);
	return 1;
}

static int luaLevelSetFlags (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	int flags = lua_tointeger (l, 1);
	level.flags |= flags;

	return 0;
}

static int luaLevelUnsetFlags (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	int flags = lua_tointeger (l, 1);
	level.flags ^= flags;

	return 0;
}

//-----------------------------------

static int luaLevelDifficulty (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushinteger(l, level.difficulty);
	return 1;
}

static int luaLevelMainHeroIndex (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushinteger(l, [level mainHeroIndex]);
	return 1;
}

//-----------------------------------

static int luaLevelMinSpeed (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.minSpeed.x);
	lua_pushnumber(l, level.minSpeed.y);
	return 2;
}

static int luaLevelSetMinSpeed (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.minSpeed = CGPointMake (lua_tonumber(l, 1), lua_tonumber(l, 2));
	return 0;
}

//-----------------------------------

static int luaLevelMaxSpeed (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.maxSpeed.x);
	lua_pushnumber(l, level.maxSpeed.y);
	return 2;
}

static int luaLevelSetMaxSpeed (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.maxSpeed = CGPointMake (lua_tonumber(l, 1), lua_tonumber(l, 2));
	return 0;
}

//-----------------------------------

static int luaLevelJoystickAccelerationFactor (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.joystickAccelerationFactor);
	return 1;
}

static int luaLevelSetJoystickAccelerationFactor (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.joystickAccelerationFactor = lua_tonumber(l, 1);
	return 0;
}

//-----------------------------------

static int luaLevelAccelerationMode (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushinteger(l, level.accelerationMode);
	return 1;
}

static int luaLevelSetAccelerationMode (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.accelerationMode = lua_tointeger(l, 1);
	return 0;
}

//-----------------------------------

static int luaLevelAcceleration (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.acceleration.x);
	lua_pushnumber(l, level.acceleration.y);
	return 2;
}

static int luaLevelSetAcceleration (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.acceleration = CGPointMake (lua_tonumber(l, 1), lua_tonumber(l, 2));
	return 0;
}

//-----------------------------------

static int luaLevelAccelerationViscosity (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.accelerationViscosity.x);
	lua_pushnumber(l, level.accelerationViscosity.y);
	return 2;
}

static int luaLevelSetAccelerationViscosity (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.accelerationViscosity = CGPointMake (lua_tonumber(l, 1), lua_tonumber(l, 2));
	return 0;
}

//-----------------------------------

static int luaLevelAccelerationFactor (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.accelerationFactor.x);
	lua_pushnumber(l, level.accelerationFactor.y);
	return 2;
}

static int luaLevelSetAccelerationFactor (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.accelerationFactor = CGPointMake (lua_tonumber(l, 1), lua_tonumber(l, 2));
	return 0;
}

//-----------------------------------

static int luaLevelAccelerationMin (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.accelerationMin.x);
	lua_pushnumber(l, level.accelerationMin.y);
	return 2;
}

static int luaLevelSetAccelerationMin (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.accelerationMin = CGPointMake (lua_tonumber(l, 1), lua_tonumber(l, 2));
	return 0;
}

//-----------------------------------

static int luaLevelAccelerationMax (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.accelerationMax.x);
	lua_pushnumber(l, level.accelerationMax.y);
	return 2;
}

static int luaLevelSetAccelerationMax (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.accelerationMax = CGPointMake (lua_tonumber(l, 1), lua_tonumber(l, 2));
	return 0;
}

//-----------------------------------

static int luaLevelAccelerationInputX (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushboolean(l, level.accelerationInputX);
	return 1;
}

static int luaLevelSetAccelerationInputX (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.accelerationInputX = lua_toboolean(l, 1);
	return 0;
}

//-----------------------------------

static int luaLevelAccelerationInputY (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushboolean(l, level.accelerationInputY);
	return 1;
}

static int luaLevelSetAccelerationInputY (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.accelerationInputY = lua_toboolean(l, 1);
	return 0;
}

//-----------------------------------

static int luaLevelGravity (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.gravity.x);
	lua_pushnumber(l, level.gravity.y);
	return 2;
}

static int luaLevelSetGravity (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.gravity = CGPointMake (lua_tonumber(l, 1), lua_tonumber(l, 2));
	return 0;
}

//-----------------------------------

static int luaLevelFriction (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.friction);
	return 1;
}

static int luaLevelSetFriction (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.friction = lua_tonumber(l, 1);
	return 0;
}

//-----------------------------------

static int luaLevelColor (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	int r,g,b;
	ccColor3B c = level.color;
	r = c.r;
	g = c.g;
	b = c.b;
	
	lua_pushinteger(l, r);
	lua_pushinteger(l, g);
	lua_pushinteger(l, b);
	return 3;
}

static int luaLevelSetColor (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[level tintToColor:ccc3 (lua_tointeger(l, 1), lua_tointeger(l, 2), lua_tointeger(l, 3))];
	return 0;
}

//-----------------------------------

static int luaLevelSetTitle (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[level setTitle:STR_C2NS(lua_tostring(l, 1))];
	return 0;
}

static int luaLevelSetDescription (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[level setDescription:STR_C2NS(lua_tostring(l, 1))];
	return 0;
}

//-----------------------------------

static int luaLevelMoveMainHeroToScreenIndex (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[level moveMainHeroToScreenIndex:lua_tointeger(l, 1)];
	return 0;
}

static int luaLevelMoveMainHeroToScreenIndexAtPosition (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[level moveMainHeroToScreenIndex:lua_tointeger(l, 1) atPosition:CGPointMake(lua_tonumber(l, 2), lua_tonumber(l, 3))];
	return 0;
}

static int luaLevelMoveMainHeroToScreenName (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	KKScreen *screen = [level screenWithName:STR_C2NS(lua_tostring(l, 1))];
	if (screen)
		[level moveMainHeroToScreenIndex:screen.index];
	return 0;
}

static int luaLevelMoveMainHeroToScreenNameAtPosition (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	KKScreen *screen = [level screenWithName:STR_C2NS(lua_tostring(l, 1))];
	if (screen)
		[level moveMainHeroToScreenIndex:screen.index atPosition:CGPointMake(lua_tonumber(l, 2), lua_tonumber(l, 3))];
	return 0;
}

//-----------------------------------

static int luaLevelPaddleIndexWithName (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	KKPaddle *p = [level paddleWithName:STR_C2NS(lua_tostring(l, 1))];
	int idx = -1;
	if (p) idx = p.index;
	lua_pushinteger(l, idx);
	return 1;
}

//-----------------------------------

static int luaLevelCurrentAvailable (lua_State *l)
{
	NSDictionary *levelInfo = [KKGE currentAvailableLevelInfo];
	lua_pushinteger(l, [[levelInfo objectForKey:@"index"] intValue]);
	lua_pushstring(l, STR_NS2C([levelInfo objectForKey:@"title"]));
	return 2;
}

static int luaLevelPrevAvailable (lua_State *l)
{
	[KKGE prevAvailableLevelInfo];
	return luaLevelCurrentAvailable (l);
}

static int luaLevelNextAvailable (lua_State *l)
{
	[KKGE nextAvailableLevelInfo];
	return luaLevelCurrentAvailable (l);
}

static int luaLevelCurrent (lua_State *l)
{
	NSDictionary *levelInfo = [KKGE currentLevelInfo];
	lua_pushinteger(l, [[levelInfo objectForKey:@"index"] intValue]);
	lua_pushstring(l, STR_NS2C([levelInfo objectForKey:@"title"]));
	return 2;
}

static int luaLevelPrev (lua_State *l)
{
	[KKGE prevLevelInfo];
	return luaLevelCurrent (l);
}

static int luaLevelNext (lua_State *l)
{
	[KKGE nextLevelInfo];
	return luaLevelCurrent (l);
}

static int luaLevelAvailable (lua_State *l)
{
	lua_pushboolean(l, [KKGE levelAvailable:lua_tointeger(l, 1)]);
	return 1;
}

static int luaLevelSetAvailable (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[KKGE setLevel:level.levelIndex available:lua_toboolean(l, 1)];
	return 0;
}

static int luaLevelSetCompleted (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[KKGE setLevel:level.levelIndex completed:lua_toboolean(l, 1)];
	return 0;
}

static int luaLevelSetAvailableWithName (lua_State *l)
{
	[KKGE setLevel:[KKGE levelIndexFromName:STR_C2NS(lua_tostring(l, 1))] available:lua_toboolean(l, 2)];
	return 0;
}

static int luaLevelSetCompletedWithName (lua_State *l)
{
	[KKGE setLevel:[KKGE levelIndexFromName:STR_C2NS(lua_tostring(l, 1))] completed:lua_toboolean(l, 2)];
	return 0;
}

//-----------------------------------

static int luaLevelTimeSuspended (lua_State *l)
{
	lua_pushboolean(l, [KKGE levelTimeSuspended]);
	return 1;
}


static int luaLevelSetTimeSuspended (lua_State *l)
{
	[KKGE setLevelTimeSuspended:lua_toboolean(l, 1)];
	return 0;
}

//-----------------------------------

static int luaLevelShowHUD (lua_State *l)
{
	[KKGE showHUD:lua_toboolean(l, 1)];
	return 0;
}


static int luaLevelSetHUDTimeNotificationEnabled (lua_State *l)
{
	[KKGE.hud setIsTimeNotificationEnabled:lua_toboolean(l, 1)];
	return 0;
}

//-----------------------------------

static int luaLevelTurboAvailableSeconds (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.turboSecondsAvailable);
	return 1;
}

static int luaLevelSetTurboAvailableSeconds (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.turboSecondsAvailable = lua_tonumber(l, 1);
	
	return 0;
}

static int luaLevelAddTurboAvailableSeconds (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.turboSecondsAvailable += lua_tonumber(l, 1);
	if (level.turboSecondsAvailable < 0) level.turboSecondsAvailable = 0;
	[KKGE.hud setTurboLeft:level.turboSecondsAvailable];
	
	return 0;
}

//-----------------------------------

static int luaLevelTurboFactor (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.turboFactor);
	return 1;
}

static int luaLevelSetTurboFactor (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	level.turboFactor = lua_tonumber(l, 1);
	
	return 0;
}

static int luaLevelWasTurboUsed (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushboolean(l, level.wasTurboUsed);
	return 1;
}

#pragma mark -
#pragma mark Screen

#define GET_CURRENT_SCREEN int idx = lua_tointeger (l, 1); \
KKScreen *screen = [[KKGE level] screenAtIndex:idx];

static int luaScreenName (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	NSString *name = @"";
	if (screen) {
		name = screen.name;
	}
	lua_pushstring(l, STR_NS2C(name));
	return 1;
}

static int luaScreenSetTitle (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	if (screen) {
		screen.title = STR_C2NS (lua_tostring (l, 2));
	}
	return 0;
}

static int luaScreenSetDescription (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	if (screen) {
		screen.desc = STR_C2NS (lua_tostring (l, 2));
	}
	return 0;
}

static int luaScreenHeroStartPosition (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	CGPoint p = CGPointZero;
	if (screen) {
		p = [screen heroStartPosition];
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

//-----------------------------------

static int luaScreenFlags (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int flags = 0;
	if (screen) {
		flags = screen.flags;
	}
	lua_pushinteger(l, flags);
	return 1;
}

static int luaScreenSetFlags (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int flags = lua_tointeger (l, 2);
	if (screen) {
		screen.flags |= flags;
	}
	return 0;
}

static int luaScreenUnsetFlags (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int flags = lua_tointeger (l, 2);
	if (screen) {
		screen.flags ^= flags;
	}
	return 0;
}

//-----------------------------------

static int luaScreenPosition (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	CGPoint p;
	if (screen) {
		p = screen.position;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

//-----------------------------------

static int luaScreenAccelerationInputX (lua_State *l)
{
	GET_CURRENT_LEVEL
	GET_CURRENT_SCREEN

	lua_pushboolean(l, DICT_BOOL (screen.data, @"accelerationInputX", level.accelerationInputX));
	return 1;
}

static int luaScreenSetAccelerationInputX (lua_State *l)
{
	GET_CURRENT_LEVEL
	GET_CURRENT_SCREEN
	
	BOOL f = lua_toboolean (l, 2);
	[screen.data setObject:[NSNumber numberWithBool:f] forKey:@"accelerationInputX"];
	if (screen == level.currentScreen) level.accelerationInputX = f;
	[KKGE showHUDMove];
	return 0;
}

static int luaScreenAccelerationInputY (lua_State *l)
{
	GET_CURRENT_LEVEL
	GET_CURRENT_SCREEN
	
	lua_pushboolean(l, DICT_BOOL (screen.data, @"accelerationInputY", level.accelerationInputY));
	return 1;
}

static int luaScreenSetAccelerationInputY (lua_State *l)
{
	GET_CURRENT_LEVEL
	GET_CURRENT_SCREEN
	
	BOOL f = lua_toboolean (l, 2);
	[screen.data setObject:[NSNumber numberWithBool:f] forKey:@"accelerationInputY"];
	if (screen == level.currentScreen) level.accelerationInputY = f;
	[KKGE showHUDMove];
	return 0;
}

//-----------------------------------

static int luaScreenBorderElasticity (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int side = lua_tointeger (l, 2);
	float e = 1.0;
	if (screen) {
		e = [screen borderElasticity:side];
	}
	lua_pushnumber(l, e);
	return 1;
}

//-----------------------------------

static int luaScreenBorderActive (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int side = lua_tointeger (l, 2);
	lua_pushboolean(l, [screen screenBorderActive:side]);
	return 1;
}

static int luaScreenSetBorderActive (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int side = lua_tointeger (l, 2);
	BOOL f = lua_toboolean (l, 3);
	[screen setScreenBorder:side active:f];
	return 0;
}

static int luaCurrentScreenSetBorderActive (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	int side = lua_tointeger (l, 1);
	BOOL f = lua_toboolean (l, 2);
	[level setScreenBorder:side active:f];
	return 0;
}

//-----------------------------------

static int luaScreenSize (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	CGSize p;
	if (screen) {
		p = screen.size;
	}
	lua_pushnumber(l, p.width);
	lua_pushnumber(l, p.height);
	return 2;
}

//-----------------------------------

static int luaScreenColor1 (lua_State *l)
{
	GET_CURRENT_SCREEN

	int r = 0, g = 0, b = 0;
	if (screen) {
		r = screen.color1.r;
		g = screen.color1.g;
		b = screen.color1.b;
	}
	lua_pushinteger(l, r);
	lua_pushinteger(l, g);
	lua_pushinteger(l, b);
	return 3;
}

static int luaScreenColor2 (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int r = 0, g = 0, b = 0;
	if (screen) {
		r = screen.color2.r;
		g = screen.color2.g;
		b = screen.color2.b;
	}
	lua_pushinteger(l, r);
	lua_pushinteger(l, g);
	lua_pushinteger(l, b);
	return 3;
}

static int luaScreenSetColor (lua_State *l)
{
	GET_CURRENT_LEVEL
	GET_CURRENT_SCREEN
	
	ccColor3B c = ccc3 (lua_tointeger(l, 2), lua_tointeger(l, 3), lua_tointeger(l, 4));
	if (screen) {
		screen.colorMode = kEntityColorModeSolid;
		screen.color1 = c;
	}
	[level tintToColor:c];
	return 0;
}

static int luaScreenSetColors (lua_State *l)
{
	GET_CURRENT_LEVEL
	GET_CURRENT_SCREEN
	
	ccColor3B c1 = ccc3 (lua_tointeger(l, 2), lua_tointeger(l, 3), lua_tointeger(l, 4));
	ccColor3B c2 = ccc3 (lua_tointeger(l, 5), lua_tointeger(l, 6), lua_tointeger(l, 7));
	if (screen) {
		screen.colorMode = kEntityColorModeTintTo;
		screen.color1 = c1;
		screen.color2 = c2;
	}
	[level tintToColor:c1 withDuration:level.screenShowDuration mode:kEntityColorModeTintTo];
	return 0;
}

//-----------------------------------
/*
static int luaScreenSetMessage (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	[level setMessage:STR_C2NS(lua_tostring(l, 1))];
	return 0;
}

static int luaScreenSetMessageColor (lua_State *l)
{
	GET_CURRENT_LEVEL
	GET_CURRENT_SCREEN
	
	ccColor3B c = ccc3 (lua_tointeger(l, 2), lua_tointeger(l, 3), lua_tointeger(l, 4));
	if (screen) {
		screen.messageColor = c;
	}
	[level messageTintToColor:c];
	return 0;
}

static int luaScreenSetMessageOpacity (lua_State *l)
{
	GET_CURRENT_LEVEL
	GET_CURRENT_SCREEN
	
	int o = lua_tointeger(l, 2);
	if (screen) {
		screen.messageOpacity = o;
	}
	[level messageFadeToOpacity:o];
	return 0;
}

static int luaScreenMessageEnabled (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	BOOL p = NO;
	if (screen) {
		p = screen.messageEnabled;
	}
	lua_pushboolean(l, p);
	return 1;
}

static int luaScreenSetMessageEnabled (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	if (screen) {
		screen.messageEnabled = lua_toboolean(l, 2);
	}
	return 0;
}
*/

//-----------------------------------

static int luaScreenLightsCount (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int p = 0;
	if (screen) {
		p = screen.numLights;
	}
	lua_pushinteger(l, p);
	return 1;
}

static int luaScreenLightVisible (lua_State *l)
{
	GET_CURRENT_SCREEN

	int i = lua_tointeger(l, 2);
	BOOL p = NO;
	if (screen) {
		if (i < screen.numLights)
			p = [[screen light:i] visible];
	}
	lua_pushboolean(l, p);
	return 1;
}

static int luaScreenSetLightVisible (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int i = lua_tointeger(l, 2);
	BOOL b = lua_toboolean(l, 3);
	if (screen) {
		if (i < screen.numLights) {
			KKLight *l = [screen light:i];
			l.visible = b;
			l.needsUpdate = YES;
		}
	}
	return 0;
}

static int luaScreenLightPosition (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int i = lua_tointeger(l, 2);
	float x = 0;
	float y = 0;
	if (screen) {
		if (i < screen.numLights) {
			KKLight *l = [screen light:i];
			x = l.position.x;
			y = l.position.y;
		}
	}
	lua_pushnumber(l, x);
	lua_pushnumber(l, y);
	return 2;
}

static int luaScreenSetLightPosition (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int i = lua_tointeger(l, 2);
	float x = lua_tonumber(l, 3);
	float y = lua_tonumber(l, 4);
	if (screen) {
		if (i < screen.numLights) {
			KKLight *l = [screen light:i];
			l.position = CGPointMake (x, y);
			l.needsUpdate = YES;
		}
	}
	return 0;
}

static int luaScreenLightSize (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int i = lua_tointeger(l, 2);
	float w = 0;
	float h = 0;
	if (screen) {
		if (i < screen.numLights) {
			KKLight *l = [screen light:i];
			w = l.size.width;
			h = l.size.height;
		}
	}
	lua_pushnumber(l, w);
	lua_pushnumber(l, h);
	return 2;
}

static int luaScreenSetLightSize (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int i = lua_tointeger(l, 2);
	float w = lua_tonumber(l, 3);
	float h = lua_tonumber(l, 4);
	if (screen) {
		if (i < screen.numLights) {
			KKLight *l = [screen light:i];
			l.size = CGSizeMake (w, h);
			l.needsUpdate = YES;
		}
	}
	return 0;
}

static int luaScreenLightPower (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int i = lua_tointeger(l, 2);
	float p = 0;
	if (screen) {
		if (i < screen.numLights)
			p = [[screen light:i] power];
	}
	lua_pushnumber(l, p);
	return 1;
}

static int luaScreenSetLightPower (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	int i = lua_tointeger(l, 2);
	float p = lua_tonumber(l, 3);
	if (screen) {
		if (i < screen.numLights) {
			KKLight *l = [screen light:i];
			l.power = p;
			l.needsUpdate = YES;
		}
	}
	return 0;
}

//-----------------------------------

static int luaScreenSetAvailableTime (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	if (screen) {
		[screen setAvailableTime:lua_tonumber(l, 2)];
	}
	return 0;
}

static int luaScreenRemoveAllMessages (lua_State *l)
{
	[KKGE.hud removeAllMessages];
	return 0;
}

//-----------------------------------

static int luaScreenSetNeedsScriptUpdate (lua_State *l)
{
	GET_CURRENT_SCREEN
	
	if (screen) {
		[screen setNeedsScriptUpdate:lua_toboolean(l, 2)];
	}
	return 0;
}


#pragma mark -
#pragma mark Paddle

#define GET_PADDLE int idx = lua_tointeger (l, 1); \
KKPaddle *paddle = [[KKGE level] paddleAtIndex:idx];

static int luaPaddleKind (lua_State *l)
{
	GET_PADDLE
	
	int p = 0;
	if (paddle) {
		p = paddle.kind;
	}
	lua_pushinteger(l, p);
	return 1;
}

//-----------------------------------

static int luaPaddleFlags (lua_State *l)
{
	GET_PADDLE
	
	int flags = 0;
	if (paddle) {
		flags = paddle.flags;
	}
	lua_pushinteger(l, flags);
	return 1;
}

static int luaPaddleSetFlags (lua_State *l)
{
	GET_PADDLE
	
	int flags = lua_tointeger (l, 2);
	if (paddle) {
		paddle.flags |= flags;
	}
	return 0;
}

static int luaPaddleUnsetFlags (lua_State *l)
{
	GET_PADDLE
	
	int flags = lua_tointeger (l, 2);
	if (paddle) {
		paddle.flags ^= flags;
	}
	return 0;
}

//-----------------------------------

static int luaPaddleBBox (lua_State *l)
{
	GET_PADDLE
	
	CGRect p;
	if (paddle) {
		p = paddle.bbox;
	}
	lua_pushnumber(l, p.origin.x);
	lua_pushnumber(l, p.origin.y);
	lua_pushnumber(l, p.size.width);
	lua_pushnumber(l, p.size.height);
	return 4;
}

//-----------------------------------

static int luaPaddleName (lua_State *l)
{
	GET_PADDLE
	
	NSString *p;
	if (paddle) {
		p = paddle.name;
	} else {
		p = @"";
	}
	lua_pushstring(l, [p UTF8String]);
	return 1;
}

//-----------------------------------

static int luaPaddleSize (lua_State *l)
{
	GET_PADDLE
	
	CGSize p;
	if (paddle) {
		p = paddle.size;
	}
	lua_pushnumber(l, p.width);
	lua_pushnumber(l, p.height);
	return 2;
}

static int luaPaddleSetSize (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.size = CGSizeMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaPaddlePosition (lua_State *l)
{
	GET_PADDLE
	
	CGPoint p;
	if (paddle) {
		p = paddle.position;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaPaddleSetPosition (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.position = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaPaddleMinPosition (lua_State *l)
{
	GET_PADDLE
	
	CGPoint p;
	if (paddle) {
		p = paddle.minPosition;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaPaddleSetMinPosition (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.minPosition = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaPaddleMaxPosition (lua_State *l)
{
	GET_PADDLE
	
	CGPoint p;
	if (paddle) {
		p = paddle.maxPosition;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaPaddleSetMaxPosition (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.maxPosition = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaPaddleSpeed (lua_State *l)
{
	GET_PADDLE
	
	CGPoint p;
	if (paddle) {
		p = paddle.speed;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaPaddleSetSpeed (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.speed = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaPaddleAcceleration (lua_State *l)
{
	GET_PADDLE
	
	CGPoint p;
	if (paddle) {
		p = paddle.acceleration;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaPaddleSetAcceleration (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.acceleration = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaPaddleProximityArea (lua_State *l)
{
	GET_PADDLE
	
	CGSize p;
	if (paddle) {
		p = paddle.proximityArea;
	}
	lua_pushnumber(l, p.width);
	lua_pushnumber(l, p.height);
	return 2;
}

static int luaPaddleSetProximityArea (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.proximityArea = CGSizeMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaPaddleProximityAcceleration (lua_State *l)
{
	GET_PADDLE
	
	CGPoint p;
	if (paddle) {
		p = paddle.proximityAcceleration;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaPaddleSetProximityAcceleration (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.proximityAcceleration = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaPaddleElasticity (lua_State *l)
{
	GET_PADDLE
	
	float p = 1.0;
	if (paddle) {
		p = paddle.elasticity;
	}
	lua_pushnumber(l, p);
	return 1;
}

//-----------------------------------

static int luaPaddleIsButton (lua_State *l)
{
	GET_PADDLE
	
	BOOL p = NO;
	if (paddle) {
		p = paddle.isButton;
	}
	lua_pushinteger(l, p);
	return 1;
}

static int luaPaddleSetIsButton (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.isButton = lua_tointeger(l, 2);
	}
	return 0;
}

//-----------------------------------

static int luaPaddleSelected (lua_State *l)
{
	GET_PADDLE
	
	BOOL p = NO;
	if (paddle) {
		p = paddle.selected;
	}
	lua_pushinteger(l, p);
	return 1;
}

static int luaPaddleSetSelected (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.selected = lua_tointeger(l, 2);
	}
	return 0;
}

//-----------------------------------

static int luaPaddleEnabled (lua_State *l)
{
	GET_PADDLE
	
	BOOL p = NO;
	if (paddle) {
		p = paddle.enabled;
	}
	lua_pushboolean(l, p);
	return 1;
}

static int luaPaddleSetEnabled (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.enabled = lua_toboolean(l, 2);
	}
	return 0;
}

//-----------------------------------

static int luaPaddleIsInvisible (lua_State *l)
{
	GET_PADDLE
	
	BOOL p = NO;
	if (paddle) {
		p = paddle.isInvisible;
	}
	lua_pushboolean(l, p);
	return 1;
}

static int luaPaddleSetIsInvisible (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.isInvisible = lua_toboolean(l, 2);
	}
	return 0;
}

//-----------------------------------

static int luaPaddleColor (lua_State *l)
{
	GET_PADDLE
	
	int r=0, g=0, b=0;
	if (paddle) {
		ccColor3B c = paddle.color;
		r = c.r;
		g = c.g;
		b = c.b;
	}
	lua_pushinteger(l, r);
	lua_pushinteger(l, g);
	lua_pushinteger(l, b);
	return 3;
}

static int luaPaddleSetColor (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle setColor:ccc3 (lua_tointeger(l, 2), lua_tointeger(l, 3), lua_tointeger(l, 4))];
	}
	return 0;
}

//-----------------------------------

static int luaPaddleOpacity (lua_State *l)
{
	GET_PADDLE
	
	int p = 0;
	if (paddle) {
		p = paddle.opacity;
	}
	lua_pushinteger(l, p);
	return 1;
}

static int luaPaddleSetOpacity (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		paddle.opacity = lua_tointeger(l, 2);
	}
	return 0;
}

//-----------------------------------

static int luaPaddleActionStop (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle actionStop:lua_tointeger(l, 2)];
	}
	return 0;
}

static int luaPaddleActionRotateByAngleDurationForeverTag (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle actionRotateBy:lua_tonumber(l, 2)
				  withDuration:lua_tonumber(l, 3) 
					   forever:lua_toboolean(l, 4)
					   withTag:lua_tointeger(l, 5)
		 ];
	}
	return 0;
}

static int luaPaddleActionRotateToAngleDurationForeverTag (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle actionRotateTo:lua_tonumber(l, 2)
				  withDuration:lua_tonumber(l, 3) 
					   forever:lua_toboolean(l, 4)
					   withTag:lua_tointeger(l, 5)
		 ];
	}
	return 0;
}

static int luaPaddleActionScaleByScaleDurationForeverTag (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle actionScaleBy:lua_tonumber(l, 2)
				  withDuration:lua_tonumber(l, 3) 
					   forever:lua_toboolean(l, 4)
					   withTag:lua_tointeger(l, 5)
		 ];
	}
	return 0;
}

static int luaPaddleActionScaleToScaleDurationForeverTag (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle actionScaleTo:lua_tonumber(l, 2)
				 withDuration:lua_tonumber(l, 3) 
					  forever:lua_toboolean(l, 4)
					  withTag:lua_tointeger(l, 5)
		 ];
	}
	return 0;
}

static int luaPaddleActionPulseFromScaleMinMaxDelayDurationTag (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle actionPulseFromScale:lua_tonumber(l, 2)
							 toScale:lua_tonumber(l, 3)
						   withDelay:lua_tonumber(l, 4)
						withDuration:lua_tonumber(l, 5) 
							 withTag:lua_tointeger(l, 6)
		 ];
	}
	return 0;
}

static int luaPaddleTintToColor (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle tintToColor:ccc3 (lua_tointeger(l, 2), lua_tointeger(l, 3), lua_tointeger(l, 4)) withDuration:lua_tonumber(l, 5)];
	}
	return 0;
}

static int luaPaddleFadeToOpacity (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle fadeToOpacity:lua_tointeger(l, 2) withDuration:lua_tonumber(l, 3)];
	}
	return 0;
}

static int luaPaddleFlash (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle flash];
	}
	return 0;
}

//-----------------------------------

static int luaPaddleUpdatePositionWithSpeedAndAcceleration (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle updatePositionWithSpeedAndAcceleration:lua_tonumber(l, 2)];
	}
	return 0;
}


//-----------------------------------

static int luaPaddleIsHeroInsideProximityArea (lua_State *l)
{
	GET_PADDLE
	
	BOOL p = NO;
	if (paddle) {
		p = [paddle isHeroAtIndexInsideProximityArea:lua_tointeger(l, 2)];
	}
	lua_pushboolean(l, p);
	return 1;
}

//-----------------------------------

static int luaPaddleSetLabel (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle setLabel:STR_C2NS (lua_tostring (l, 2))];
	}
	return 0;
}

static int luaPaddleSetLabelColor (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle.label setColor:ccc3 (lua_tointeger(l, 2), lua_tointeger(l, 3), lua_tointeger(l, 4))];
	}
	return 0;
}

static int luaPaddleSetLabelOpacity (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle.label setOpacity:lua_tointeger(l, 2)];
	}
	return 0;
}

static int luaPaddleSetLabelFont (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle setLabelFont:STR_C2NS (lua_tostring (l, 2)) ofSize:lua_tointeger(l, 3)];
	}
	return 1;
}

//-----------------------------------

static int luaPaddleLightsCount (lua_State *l)
{
	GET_PADDLE
	
	int p = 0;
	if (paddle) {
		p = paddle.numLights;
	}
	lua_pushinteger(l, p);
	return 1;
}

static int luaPaddleLightVisible (lua_State *l)
{
	GET_PADDLE
	
	int i = lua_tointeger(l, 2);
	BOOL p = NO;
	if (paddle) {
		if (i < paddle.numLights)
			p = [[paddle light:i] visible];
	}
	lua_pushboolean(l, p);
	return 1;
}

static int luaPaddleSetLightVisible (lua_State *l)
{
	GET_PADDLE
	
	int i = lua_tointeger(l, 2);
	BOOL b = lua_toboolean(l, 3);
	if (paddle) {
		if (i < paddle.numLights) {
			KKLight *l = [paddle light:i];
			l.visible = b;
			l.needsUpdate = YES;
		}
	}
	return 0;
}

static int luaPaddleLightPosition (lua_State *l)
{
	GET_PADDLE
	
	int i = lua_tointeger(l, 2);
	float x = 0;
	float y = 0;
	if (paddle) {
		if (i < paddle.numLights) {
			KKLight *l = [paddle light:i];
			x = l.position.x;
			y = l.position.y;
		}
	}
	lua_pushnumber(l, x);
	lua_pushnumber(l, y);
	return 2;
}

static int luaPaddleSetLightPosition (lua_State *l)
{
	GET_PADDLE
	
	int i = lua_tointeger(l, 2);
	float x = lua_tonumber(l, 3);
	float y = lua_tonumber(l, 4);
	if (paddle) {
		if (i < paddle.numLights) {
			KKLight *l = [paddle light:i];
			l.position = CGPointMake (x, y);
			l.needsUpdate = YES;
		}
	}
	return 0;
}

static int luaPaddleLightSize (lua_State *l)
{
	GET_PADDLE
	
	int i = lua_tointeger(l, 2);
	float w = 0;
	float h = 0;
	if (paddle) {
		if (i < paddle.numLights) {
			KKLight *l = [paddle light:i];
			w = l.size.width;
			h = l.size.height;
		}
	}
	lua_pushnumber(l, w);
	lua_pushnumber(l, h);
	return 2;
}

static int luaPaddleSetLightSize (lua_State *l)
{
	GET_PADDLE
	
	int i = lua_tointeger(l, 2);
	float w = lua_tonumber(l, 3);
	float h = lua_tonumber(l, 4);
	if (paddle) {
		if (i < paddle.numLights) {
			KKLight *l = [paddle light:i];
			l.size = CGSizeMake (w, h);
			l.needsUpdate = YES;
		}
	}
	return 0;
}

static int luaPaddleLightPower (lua_State *l)
{
	GET_PADDLE
	
	int i = lua_tointeger(l, 2);
	float p = 0;
	if (paddle) {
		if (i < paddle.numLights)
			p = [[paddle light:i] power];
	}
	lua_pushnumber(l, p);
	return 1;
}

static int luaPaddleSetLightPower (lua_State *l)
{
	GET_PADDLE
	
	int i = lua_tointeger(l, 2);
	float p = lua_tonumber(l, 3);
	if (paddle) {
		if (i < paddle.numLights) {
			KKLight *l = [paddle light:i];
			l.power = p;
			l.needsUpdate = YES;
		}
	}
	return 0;
}

//-----------------------------------

static int luaPaddleShowMessageEmoticonSound (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle showMessage:STR_C2NS (lua_tostring(l, 2)) 
				 emoticon:lua_tointeger(l, 3) 
					sound:STR_C2NS (lua_tostring(l, 4))
		 ];
	}
	return 0;
}

static int luaPaddleShowMessageEmoticonDurationSound (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle showMessage:STR_C2NS (lua_tostring(l, 2)) 
				 emoticon:lua_tointeger(l, 3) 
				 duration:lua_tonumber(l, 4)
					sound:STR_C2NS (lua_tostring(l, 5))
		 ];
	}
	return 0;
}

static int luaPaddleShowMessageEmoticonBMISizeDurationSound (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle showMessage:STR_C2NS (lua_tostring(l, 2)) 
				 emoticon:lua_tointeger(l, 3)
				  bgColor:ccc3FromNsString(STR_C2NS (lua_tostring(l, 4)))
				 msgColor:ccc3FromNsString(STR_C2NS (lua_tostring(l, 5)))
				 icnColor:ccc3FromNsString(STR_C2NS (lua_tostring(l, 6)))
				 fontSize:lua_tonumber(l, 7)
				 duration:lua_tonumber(l, 8)
					sound:STR_C2NS (lua_tostring(l, 9))
		 ];
	}
	return 0;
}

static int luaPaddleRemoveMessage (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle removeMessage];
	}
	return 0;
}

//-----------------------------------

static int luaPaddleSetTopImage (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		[paddle setTopImage:STR_C2NS (lua_tostring (l, 2))
				  positionX:lua_tonumber(l, 3)
				  positionY:lua_tonumber(l, 4)
					  width:lua_tonumber(l, 5)
					 height:lua_tonumber(l, 6)
					anchorX:lua_tonumber(l, 7)
					anchorY:lua_tonumber(l, 8)
					opacity:lua_tointeger(l, 9)
					rotation:lua_tonumber(l, 10)
		 ];
	}
	return 0;
}

//-----------------------------------

static int luaPaddleSetAI (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		NSMutableDictionary *config = [NSMutableDictionary dictionaryWithCapacity:4];
		[config setObject:STR_C2NS (lua_tostring (l, 2)) forKey:@"defensiveKind"];
		[config setObject:STR_C2NS (lua_tostring (l, 3)) forKey:@"defensiveConfig"];
		[config setObject:STR_C2NS (lua_tostring (l, 2)) forKey:@"offensiveKind"];
		[config setObject:STR_C2NS (lua_tostring (l, 3)) forKey:@"offensiveConfig"];
		
		[paddle setupPaddleAI:config];
	}
	return 0;
}

#pragma mark -
#pragma mark Hero

#define GET_HERO int idx = lua_tointeger (l, 1); \
KKHero *hero = [[KKGE level] heroAtIndex:idx];

static int luaHeroKind (lua_State *l)
{
	GET_HERO
	
	int p = 0;
	if (hero) {
		p = hero.kind;
	}
	lua_pushinteger(l, p);
	return 1;
}

//-----------------------------------

static int luaHeroIsMainHero (lua_State *l)
{
	GET_HERO
	
	BOOL p = NO;
	if (hero) {
		p = hero.isMainHero;
	}
	lua_pushboolean(l, p);
	return 1;
}

//-----------------------------------

static int luaHeroPause (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		[hero pause:lua_toboolean(l, 2)];
	}
	return 0;
}

static int luaHeroIsPaused (lua_State *l)
{
	GET_HERO
	
	BOOL p = NO;
	if (hero) {
		p = [hero isPaused];
	}
	lua_pushboolean(l, p);
	return 1;
}

//-----------------------------------

static int luaHeroFlags (lua_State *l)
{
	GET_HERO
	
	int flags = 0;
	if (hero) {
		flags = hero.flags;
	}
	lua_pushinteger(l, flags);
	return 1;
}

static int luaHeroSetFlags (lua_State *l)
{
	GET_HERO
	
	int flags = lua_tointeger (l, 2);
	if (hero) {
		hero.flags |= flags;
	}
	return 0;
}

static int luaHeroUnsetFlags (lua_State *l)
{
	GET_HERO
	
	int flags = lua_tointeger (l, 2);
	if (hero) {
		hero.flags ^= flags;
	}
	return 0;
}

//-----------------------------------

static int luaHeroBBox (lua_State *l)
{
	GET_HERO
	
	CGRect p;
	if (hero) {
		p = hero.bbox;
	}
	lua_pushnumber(l, p.origin.x);
	lua_pushnumber(l, p.origin.y);
	lua_pushnumber(l, p.size.width);
	lua_pushnumber(l, p.size.height);
	return 4;
}

//-----------------------------------

static int luaHeroSize (lua_State *l)
{
	GET_HERO
	
	CGSize p;
	if (hero) {
		p = hero.size;
	}
	lua_pushnumber(l, p.width);
	lua_pushnumber(l, p.height);
	return 2;
}

static int luaHeroSetSize (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		hero.size = CGSizeMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaHeroPosition (lua_State *l)
{
	GET_HERO
	
	CGPoint p;
	if (hero) {
		p = hero.position;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaHeroSetPosition (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		hero.position = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaHeroSpeed (lua_State *l)
{
	GET_HERO
	
	CGPoint p;
	if (hero) {
		p = hero.speed;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaHeroSetSpeed (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		hero.speed = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaHeroAcceleration (lua_State *l)
{
	GET_HERO
	
	CGPoint p;
	if (hero) {
		p = hero.acceleration;
	}
	lua_pushnumber(l, p.x);
	lua_pushnumber(l, p.y);
	return 2;
}

static int luaHeroSetAcceleration (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		hero.acceleration = CGPointMake (lua_tonumber(l, 2), lua_tonumber(l, 3));
	}
	return 0;
}

//-----------------------------------

static int luaHeroElasticity (lua_State *l)
{
	GET_HERO
	
	float p;
	if (hero) {
		p = hero.elasticity;
	}
	lua_pushnumber(l, p);
	return 1;
}

static int luaHeroSetElasticity (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		hero.elasticity = lua_tonumber(l, 2);
	}
	return 0;
}

//-----------------------------------

static int luaHeroLightEnabled (lua_State *l)
{
	GET_HERO
	
	BOOL p = NO;
	if (hero) {
		p = hero.lightEnabled;
	}
	lua_pushboolean(l, p);
	return 1;
}

static int luaHeroSetLightEnabled (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		hero.lightEnabled = lua_toboolean(l, 2);
	}
	return 0;
}

static int luaHeroLightVisible (lua_State *l)
{
	GET_HERO
	
	BOOL p = NO;
	if (hero) {
		p = hero.lightVisible;
	}
	lua_pushboolean(l, p);
	return 1;
}

static int luaHeroSetLightVisible (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		hero.lightVisible = lua_toboolean(l, 2);
	}
	return 0;
}

static int luaHeroLightPosition (lua_State *l)
{
	GET_HERO
	
	float x = 0;
	float y = 0;
	if (hero) {
		KKLight *l = [hero light];
		if (l) {
			x = l.position.x;
			y = l.position.y;
		}
	}
	lua_pushnumber(l, x);
	lua_pushnumber(l, y);
	return 2;
}

static int luaHeroSetLightPosition (lua_State *l)
{
	GET_HERO
	
	float x = lua_tonumber(l, 2);
	float y = lua_tonumber(l, 3);
	if (hero) {
		KKLight *l = [hero light];
		if (l) {
			l.position = CGPointMake (x, y);
			l.needsUpdate = YES;
		}
	}
	return 0;
}

static int luaHeroLightSize (lua_State *l)
{
	GET_HERO
	
	float w = 0;
	float h = 0;
	if (hero) {
		KKLight *l = [hero light];
		if (l) {
			w = l.size.width;
			h = l.size.height;
		}
	}
	lua_pushnumber(l, w);
	lua_pushnumber(l, h);
	return 2;
}

static int luaHeroSetLightSize (lua_State *l)
{
	GET_HERO
	
	float w = lua_tonumber(l, 2);
	float h = lua_tonumber(l, 3);
	if (hero) {
		KKLight *l = [hero light];
		if (l) {
			l.size = CGSizeMake (w, h);
			l.needsUpdate = YES;
		}
	}
	return 0;
}

static int luaHeroLightPower (lua_State *l)
{
	GET_HERO
	
	float p = 0;
	if (hero) {
		KKLight *l = [hero light];
		if (l) {
			p = [l power];
		}
	}
	lua_pushnumber(l, p);
	return 1;
}

static int luaHeroSetLightPower (lua_State *l)
{
	GET_HERO
	
	float p = lua_tonumber(l, 2);
	if (hero) {
		KKLight *l = [hero light];
		if (l) {
			l.power = p;
			l.needsUpdate = YES;
		}
	}
	return 0;
}

//-----------------------------------

static int luaHeroShowMessageEmoticonSound (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		[hero showMessage:STR_C2NS (lua_tostring(l, 2)) 
				 emoticon:lua_tointeger(l, 3) 
					sound:STR_C2NS (lua_tostring(l, 4))
		 ];
	}
	return 0;
}

static int luaHeroShowMessageEmoticonDurationSound (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		[hero showMessage:STR_C2NS (lua_tostring(l, 2)) 
				 emoticon:lua_tointeger(l, 3) 
				 duration:lua_tonumber(l, 4)
					sound:STR_C2NS (lua_tostring(l, 5))
		 ];
	}
	return 0;
}

static int luaHeroShowMessageEmoticonBMISizeDurationSound (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		[hero showMessage:STR_C2NS (lua_tostring(l, 2)) 
				 emoticon:lua_tointeger(l, 3)
				  bgColor:ccc3FromNsString(STR_C2NS (lua_tostring(l, 4)))
				  msgColor:ccc3FromNsString(STR_C2NS (lua_tostring(l, 5)))
				  icnColor:ccc3FromNsString(STR_C2NS (lua_tostring(l, 6)))
				 fontSize:lua_tonumber(l, 7)
				 duration:lua_tonumber(l, 8)
					sound:STR_C2NS (lua_tostring(l, 9))
		 ];
	}
	return 0;
}

static int luaHeroRemoveMessage (lua_State *l)
{
	GET_HERO
	
	if (hero) {
		[hero removeMessage];
	}
	return 0;
}

#pragma mark -
#pragma mark Sound

#import "CocosDenshion.h"

static int luaAudioMusicVolume (lua_State *l)
{
	lua_pushinteger(l, [KKPM musicVolume]);
	return 1;
}

static int luaAudioSetMusicVolume (lua_State *l)
{
	int v = lua_tointeger(l, 1);
	if (v < 0) v = 0;
	else if (v > 100) v = 100;
	
	[KKPM setMusicVolume:v];
	[KKSNDM setMusicVolume:(float)(v) / 100.0];
	
	return 0;
}

static int luaAudioSoundEffectsVolume (lua_State *l)
{
	lua_pushinteger(l, [KKPM soundEffectsVolume]);
	return 1;
}

static int luaAudioSetSoundEffectsVolume (lua_State *l)
{
	int v = lua_tointeger(l, 1);
	if (v < 0) v = 0;
	else if (v > 100) v = 100;
	
	[KKPM setSoundEffectsVolume:v];
	[KKSNDM setSoundEffectsVolume:(float)(v) / 100.0];
	return 0;
}

static int luaAudioStartBackgroundMusic (lua_State *l)
{
	NSString *filename = STR_C2NS(lua_tostring(l, 1));
	[KKGE startBackgroundMusic:filename];
	return 0;
}

static int luaAudioStopBackgroundMusic (lua_State *l)
{
	[KKGE stopBackgroundMusic];
	return 0;
}

static int luaAudioPauseBackgroundMusic (lua_State *l)
{
	[KKSNDM pauseBackgroundMusic];
	return 0;
}

static int luaAudioResumeBackgroundMusic (lua_State *l)
{
	[KKSNDM resumeBackgroundMusic];
	return 0;
}

static int luaAudioRewindBackgroundMusic (lua_State *l)
{
	[KKSNDM rewindBackgroundMusic];
	return 0;
}

static int luaAudioPlaySound (lua_State *l)
{
	NSString *filename = STR_C2NS(lua_tostring(l, 1));
	[KKGE playSound:filename];
	return 0;
}

static int luaAudioPlaySoundLoop (lua_State *l)
{
	NSString *filename = STR_C2NS(lua_tostring(l, 1));
	int sid = [KKGE playSoundLoop:filename];
	lua_pushinteger(l, sid);
	return 1;
}

static int luaAudioPlaySoundWithPan (lua_State *l)
{
	NSString *filename = STR_C2NS(lua_tostring(l, 1));
	float pan = lua_tonumber(l, 2);
	[KKGE playSound:filename withPan:pan];
	return 0;
}

static int luaAudioPlaySoundForPaddle (lua_State *l)
{
	GET_PADDLE
	
	if (paddle) {
		NSString *filename = STR_C2NS(lua_tostring(l, 2));
		[KKGE playSound:filename forPaddle:paddle];
	}
	return 0;
}

static int luaAudioPlaySoundLoopForPaddle (lua_State *l)
{
	GET_PADDLE
	
	int sid = CD_NO_SOURCE;
	
	if (paddle) {
		NSString *filename = STR_C2NS(lua_tostring(l, 2));
		sid = [KKGE playSoundLoop:filename forPaddle:paddle];
	}
	lua_pushinteger(l, sid);
	return 1;
}

static int luaAudioStopSound (lua_State *l)
{
	int sid = lua_tointeger(l, 1);
	[KKGE stopSound:sid];
	return 0;
}

static int luaAudioStopAllSounds (lua_State *l)
{
	[KKGE stopAllSounds];
	return 0;
}

#pragma mark -
#pragma mark Input

static int luaInputAccelerationMode (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushinteger(l, level.accelerationMode);
	return 1;
}

static int luaInputAccelerationStart (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.accelerationStart.x);
	lua_pushnumber(l, level.accelerationStart.y);
	return 2;
}

static int luaInputAcceleration (lua_State *l)
{
	GET_CURRENT_LEVEL
	
	lua_pushnumber(l, level.acceleration.x);
	lua_pushnumber(l, level.acceleration.y);
	return 2;
}

#pragma mark -
#pragma mark FX

static int luaFxInvertAccelerationX (lua_State *l)
{
	float timeout = lua_tonumber(l, 1);
	[KKGE fxInvertAccelerationX:timeout];
	return 0;
}

static int luaFxInvertAccelerationY (lua_State *l)
{
	float timeout = lua_tonumber(l, 1);
	[KKGE fxInvertAccelerationY:timeout];
	return 0;
}

static int luaFxAccelerationIncrementX (lua_State *l)
{
	float inc = lua_tonumber(l, 1);
	float timeout = lua_tonumber(l, 2);
	[KKGE fxAccelerationIncrementX:inc timeout:timeout];
	return 0;
}

static int luaFxAccelerationIncrementY (lua_State *l)
{
	float inc = lua_tonumber(l, 1);
	float timeout = lua_tonumber(l, 2);
	[KKGE fxAccelerationIncrementY:inc timeout:timeout];
	return 0;
}

static int luaFxBlockedSideMovements (lua_State *l)
{
	int sides = lua_tointeger(l, 1);
	float timeout = lua_tonumber(l, 2);
	[KKGE fxBlockedSideMovements:sides timeout:timeout];
	return 0;
}

static int luaFxHeroScaleIncrement (lua_State *l)
{
	CGSize inc = CGSizeMake(lua_tonumber(l, 1), lua_tonumber(l, 2));
	float timeout = lua_tonumber(l, 3);
	[KKGE fxHeroScaleIncrement:inc timeout:timeout];
	return 0;
}

#pragma mark -
#pragma mark Test

static int luaIsDebug (lua_State *l)
{
#if KK_DEBUG
	lua_pushboolean(l, YES);
#else
	lua_pushboolean(l, NO);
#endif	
	return 1;
}

#ifdef KK_DEBUG

static int luaDownloadLevel (lua_State *l)
{
	[KKGE downloadLevel:STR_C2NS(lua_tostring(l, 1)) fromHost:STR_C2NS(lua_tostring(l, 2)) atPort:lua_tonumber(l, 3)];
	
	return 0;
}

static int luaRemoveDownloadedLevels (lua_State *l)
{
	[KKGE removeDownloadedLevels];
	
	return 0;
}

static int luaTestGameOver (lua_State *l)
{
	KKGE.currentGameState = kGSGameOver;
	[KKGE.hud showGameOverPanel];

	return 0;
}

#endif

#pragma mark -
#pragma mark Library Definition

static const luaL_reg gameLib[] = {
	{"isFreeVersion", luaIsFreeVersion},
	{"areAllLevelsPurchased", luaAreAllLevelsPurchased},
	{"buyAllLevels", luaBuyAllLevels},
	
	{"getGlobal", luaGetGlobal},
	{"setGlobal", luaSetGlobal},

	{"inputMode", luaInputMode},
	{"setInputMode", luaSetInputMode},
	{"difficultyLevel", luaDifficultyLevel},
	{"setDifficultyLevel", luaSetDifficultyLevel},
	
	{"startGameWithLevelName", luaStartGameWithLevelName},
	{"startGameWithLevelIndex", luaStartGameWithLevelIndex},
	{"hasSavedGame", luaHasSavedGame},
	{"resumeSavedGame", luaResumeSavedGame},
	{"startLevelName", luaStartLevelName},
	{"startLevelIndex", luaStartLevelIndex},
	{"scoreAdd", luaScoreAdd},
	{"timeAdd", luaTimeAdd},
	{"explorationPointsAdd", luaExplorationPointsAdd},
	{"showLevelScorePanel", luaShowLevelScorePanel},
	{"scoreStats", luaScoreStats},
	{"timeStats", luaTimeStats},
	{"explorationStats", luaExplorationStats},
	{"addLife", luaAddLife},
	{"removeLife", luaRemoveLife},
	{"die", luaDie},
	{"kill", luaKill},
	{"killWithMessage", luaKillWithMessage},
	{"rateNow", luaRateNow},
	{"shouldRate", luaShouldRate},
	{"openKismikURL", luaOpenKismikURL},
	{"openBe2EscapeURL", luaOpenBe2EscapeURL},
	{"openIncompetechURL", luaOpenIncompetechURL},
	{"openCocos2DURL", luaOpenCocos2DURL},
	{"playBe2Trailer", luaPlayBe2Trailer},
	{"wasBe2TrailerViewed", luaWasBe2TrailerViewed},
	
	{"isFullQuest", luaIsFullQuest},
	{"isFullQuestCompleted", luaIsFullQuestCompleted},
	{"setFullQuestCompleted", luaSetFullQuestCompleted},
	{"questEnd", luaQuestEnd},

	{"scaleX", luaScaleX},
	{"scaleY", luaScaleY},
	{"normX", luaNormX},
	{"normY", luaNormY},
	
	{"setGlobalMissionFieldToBool", luaSetGlobalMissionFieldToBool},
	{"setGlobalMissionFieldToInt", luaSetGlobalMissionFieldToInt},
	{"setGlobalMissionFieldToFloat", luaSetGlobalMissionFieldToFloat},
	{"setGlobalMissionFieldToString", luaSetGlobalMissionFieldToString},
	{"globalMissionBoolField", luaGlobalMissionBoolField},
	{"globalMissionIntField", luaGlobalMissionIntField},
	{"globalMissionFloatField", luaGlobalMissionFloatField},
	{"globalMissionStringField", luaGlobalMissionStringField},
	
	{"fxInvertAccelerationX", luaFxInvertAccelerationX},
	{"fxInvertAccelerationY", luaFxInvertAccelerationY},
	{"fxAccelerationIncrementX", luaFxAccelerationIncrementX},
	{"fxAccelerationIncrementY", luaFxAccelerationIncrementY},
	{"fxBlockedSideMovements", luaFxBlockedSideMovements},
	{"fxHeroScaleIncrement", luaFxHeroScaleIncrement},
	
	{"mathRandomIntRange", luaMathRandomIntRange},
	{"mathRandomInt", luaMathRandomInt},

	{"hudShowTimerLabel", luaHUDShowTimerLabel},
	{"hudShowZoomingText", luaHUDShowZoomingText},
	
	{"openFeintLaunchDashboard", luaOpenFeintLaunchDashboard},
	{"openFeintLastLoggedInUserName", luaOpenFeintLastLoggedInUserName},
	{"openFeintUnlockAchievement", luaOpenFeintUnlockAchievement},
	{"openFeintIsAchievementUnlocked", luaOpenFeintIsAchievementUnlocked},
	{"openFeintSetHighScoreForLeadeboard", luaOpenFeintSetHighScoreForLeadeboard},
	
	{"audioMusicVolume", luaAudioMusicVolume},
	{"audioSetMusicVolume", luaAudioSetMusicVolume},
	{"audioSoundEffectsVolume", luaAudioSoundEffectsVolume},
	{"audioSetSoundEffectsVolume", luaAudioSetSoundEffectsVolume},
	
	{"audioStartBackgroundMusic", luaAudioStartBackgroundMusic},
	{"audioStopBackgroundMusic", luaAudioStopBackgroundMusic},
	{"audioPauseBackgroundMusic", luaAudioPauseBackgroundMusic},
	{"audioResumeBackgroundMusic", luaAudioResumeBackgroundMusic},
	{"audioRewindBackgroundMusic", luaAudioRewindBackgroundMusic},
	
	{"audioPlaySound", luaAudioPlaySound},
	{"audioPlaySoundLoop", luaAudioPlaySoundLoop},
	{"audioPlaySoundWithPan", luaAudioPlaySoundWithPan},
	{"audioPlaySoundForPaddle", luaAudioPlaySoundForPaddle},
	{"audioPlaySoundLoopForPaddle", luaAudioPlaySoundLoopForPaddle},
	{"audioStopSound", luaAudioStopSound},
	{"audioStopAllSounds", luaAudioStopAllSounds},
	
	{"inputAccelerationMode", luaInputAccelerationMode},
	{"inputAccelerationStart", luaInputAccelerationStart},
	{"inputAcceleration", luaInputAcceleration},

	{"levelName", luaLevelName},
	{"levelTitle", luaLevelTitle},
	{"levelDesc", luaLevelDesc},
	{"levelNextLevelName", luaLevelNextLevelName},
	{"levelKind", luaLevelKind},
	{"levelNumScreens", luaLevelNumScreens},
	{"levelFlags", luaLevelFlags},
	{"levelSetFlags", luaLevelSetFlags},
	{"levelUnsetFlags", luaLevelUnsetFlags},
	{"levelDifficulty", luaLevelDifficulty},
	{"levelMainHeroIndex", luaLevelMainHeroIndex},
	{"levelMoveMainHeroToScreenIndex", luaLevelMoveMainHeroToScreenIndex},
	{"levelMoveMainHeroToScreenIndexAtPosition", luaLevelMoveMainHeroToScreenIndexAtPosition},
	{"levelMoveMainHeroToScreenName", luaLevelMoveMainHeroToScreenName},
	{"levelMoveMainHeroToScreenNameAtPosition", luaLevelMoveMainHeroToScreenNameAtPosition},
	{"levelThumbnailImageName", luaLevelThumbnailImageName},

	{"levelSetBGImageIndexTexturePositionOpacityDuration", luaLevelSetBGImageIndexTexturePositionOpacityDuration},
	{"levelUnsetBGImageIndex", luaLevelUnsetBGImageIndex},
	
	{"levelMinSpeed", luaLevelMinSpeed},
	{"levelSetMinSpeed", luaLevelSetMinSpeed},
	{"levelMaxSpeed", luaLevelMaxSpeed},
	{"levelSetMaxSpeed", luaLevelSetMaxSpeed},

	{"levelJoystickAccelerationFactor", luaLevelJoystickAccelerationFactor},
	{"levelSetJoystickAccelerationFactor", luaLevelSetJoystickAccelerationFactor},
	
	{"levelAccelerationMode", luaLevelAccelerationMode},
	{"levelSetAccelerationMode", luaLevelSetAccelerationMode},
	{"levelAcceleration", luaLevelAcceleration},
	{"levelSetAcceleration", luaLevelSetAcceleration},
	{"levelAccelerationViscosity", luaLevelAccelerationViscosity},
	{"levelSetAccelerationViscosity", luaLevelSetAccelerationViscosity},
	{"levelAccelerationFactor", luaLevelAccelerationFactor},
	{"levelSetAccelerationFactor", luaLevelSetAccelerationFactor},
	{"levelAccelerationMin", luaLevelAccelerationMin},
	{"levelSetAccelerationMin", luaLevelSetAccelerationMin},
	{"levelAccelerationMax", luaLevelAccelerationMax},
	{"levelSetAccelerationMax", luaLevelSetAccelerationMax},
	{"levelAccelerationInputX", luaLevelAccelerationInputX},
	{"levelSetAccelerationInputX", luaLevelSetAccelerationInputX},
	{"levelAccelerationInputY", luaLevelAccelerationInputY},
	{"levelSetAccelerationInputY", luaLevelSetAccelerationInputY},

	{"levelGravity", luaLevelGravity},
	{"levelSetGravity", luaLevelSetGravity},
	{"levelFriction", luaLevelFriction},
	{"levelSetFriction", luaLevelSetFriction},

	{"levelColor", luaLevelColor},
	{"levelSetColor", luaLevelSetColor},
	{"levelSetTitle", luaLevelSetTitle},
	{"levelSetDescription", luaLevelSetDescription},

	{"levelPaddleIndexWithName", luaLevelPaddleIndexWithName},

	{"levelCurrentAvailable", luaLevelCurrentAvailable},
	{"levelPrevAvailable", luaLevelPrevAvailable},
	{"levelNextAvailable", luaLevelNextAvailable},
	{"levelCurrent", luaLevelCurrent},
	{"levelPrev", luaLevelPrev},
	{"levelNext", luaLevelNext},
	{"levelAvailable" ,luaLevelAvailable},
	{"levelSetAvailable", luaLevelSetAvailable},
	{"levelSetCompleted", luaLevelSetCompleted},
	{"levelSetAvailableWithName", luaLevelSetAvailableWithName},
	{"levelSetCompletedWithName", luaLevelSetCompletedWithName},

	{"levelTimeSuspended", luaLevelTimeSuspended},
	{"levelSetTimeSuspended", luaLevelSetTimeSuspended},

	{"levelShowHUD", luaLevelShowHUD},
	{"levelSetHUDTimeNotificationEnabled", luaLevelSetHUDTimeNotificationEnabled},

	{"levelTurboAvailableSeconds", luaLevelTurboAvailableSeconds},
	{"levelSetTurboAvailableSeconds", luaLevelSetTurboAvailableSeconds},
	{"levelAddTurboAvailableSeconds", luaLevelAddTurboAvailableSeconds},
	{"levelTurboFactor", luaLevelTurboFactor},
	{"levelSetTurboFactor", luaLevelSetTurboFactor},
	{"levelWasTurboUsed", luaLevelWasTurboUsed},

	{"screenName", luaScreenName},
	{"screenSetTitle", luaScreenSetTitle},
	{"screenSetDescription", luaScreenSetDescription},
	{"screenFlags", luaScreenFlags},
	{"screenSetFlags", luaScreenSetFlags},
	{"screenUnsetFlags", luaScreenUnsetFlags},
	{"screenSize", luaScreenSize},
	{"screenPosition", luaScreenPosition},
	{"screenBorderElasticity", luaScreenBorderElasticity},
	{"screenBorderActive", luaScreenBorderActive},
	{"screenSetBorderActive", luaScreenSetBorderActive},
	{"currentScreenSetBorderActive", luaCurrentScreenSetBorderActive},

	{"screenHeroStartPosition", luaScreenHeroStartPosition},

	{"screenAccelerationInputX", luaScreenAccelerationInputX},
	{"screenSetAccelerationInputX", luaScreenSetAccelerationInputX},
	{"screenAccelerationInputY", luaScreenAccelerationInputY},
	{"screenSetAccelerationInputY", luaScreenSetAccelerationInputY},
	
	{"screenColor1", luaScreenColor1},
	{"screenColor2", luaScreenColor2},
	{"screenSetColor", luaScreenSetColor},
	{"screenSetColors", luaScreenSetColors},
//	{"screenSetMessage", luaScreenSetMessage},
//	{"screenSetMessageColor", luaScreenSetMessageColor},
//	{"screenSetMessageOpacity", luaScreenSetMessageOpacity},
//	{"screenMessageEnabled", luaScreenMessageEnabled},
//	{"screenSetMessageEnabled", luaScreenSetMessageEnabled},
	{"screenLightsCount", luaScreenLightsCount},
	{"screenLightVisible", luaScreenLightVisible},
	{"screenSetLightVisible", luaScreenSetLightVisible},
	{"screenLightSize", luaScreenLightSize},
	{"screenSetLightSize", luaScreenSetLightSize},
	{"screenLightPower", luaScreenLightPower},
	{"screenSetLightPower", luaScreenSetLightPower},
	{"screenLightPosition", luaScreenLightPosition},
	{"screenSetLightPosition", luaScreenSetLightPosition},

	{"screenSetAvailableTime", luaScreenSetAvailableTime},

	{"screenRemoveAllMessages", luaScreenRemoveAllMessages},

	{"screenSetNeedsScriptUpdate", luaScreenSetNeedsScriptUpdate},
	
	{"paddleKind", luaPaddleKind},
	{"paddleFlags", luaPaddleFlags},
	{"paddleSetFlags", luaPaddleSetFlags},
	{"paddleUnsetFlags", luaPaddleUnsetFlags},
	{"paddleName", luaPaddleName},
	{"paddleBBox", luaPaddleBBox},
	{"paddleSize", luaPaddleSize},
	{"paddleSetSize", luaPaddleSetSize},
	{"paddlePosition", luaPaddlePosition},
	{"paddleSetPosition", luaPaddleSetPosition},
	{"paddleMinPosition", luaPaddleMinPosition},
	{"paddleSetMinPosition", luaPaddleSetMinPosition},
	{"paddleMaxPosition", luaPaddleMaxPosition},
	{"paddleSetMaxPosition", luaPaddleSetMaxPosition},
	{"paddleSpeed", luaPaddleSpeed},
	{"paddleSetSpeed", luaPaddleSetSpeed},
	{"paddleAcceleration", luaPaddleAcceleration},
	{"paddleSetAcceleration", luaPaddleSetAcceleration},
	{"paddleProximityArea", luaPaddleProximityArea},
	{"paddleSetProximityArea", luaPaddleSetProximityArea},
	{"paddleProximityAcceleration", luaPaddleProximityAcceleration},
	{"paddleSetProximityAcceleration", luaPaddleSetProximityAcceleration},
	{"paddleElasticity", luaPaddleElasticity},
	{"paddleIsButton", luaPaddleIsButton},
	{"paddleSetIsButton", luaPaddleSetIsButton},
	{"paddleSelected", luaPaddleSelected},
	{"paddleSetSelected", luaPaddleSetSelected},
	{"paddleEnabled", luaPaddleEnabled},
	{"paddleSetEnabled", luaPaddleSetEnabled},
	{"paddleIsInvisible", luaPaddleIsInvisible},
	{"paddleSetIsInvisible", luaPaddleSetIsInvisible},
	{"paddleColor", luaPaddleColor},
	{"paddleSetColor", luaPaddleSetColor},
	{"paddleOpacity", luaPaddleOpacity},
	{"paddleSetOpacity", luaPaddleSetOpacity},
	{"paddleTintToColor", luaPaddleTintToColor},
	{"paddleFadeToOpacity", luaPaddleFadeToOpacity},
	{"paddleFlash", luaPaddleFlash},
	{"paddleUpdatePositionWithSpeedAndAcceleration", luaPaddleUpdatePositionWithSpeedAndAcceleration},
	{"paddleIsHeroInsideProximityArea", luaPaddleIsHeroInsideProximityArea},
	{"paddleSetLabel", luaPaddleSetLabel},
	{"paddleSetLabelColor", luaPaddleSetLabelColor},
	{"paddleSetLabelOpacity", luaPaddleSetLabelOpacity},
	{"paddleSetLabelFont", luaPaddleSetLabelFont},
	{"paddleLightsCount", luaPaddleLightsCount},
	{"paddleLightVisible", luaPaddleLightVisible},
	{"paddleSetLightVisible", luaPaddleSetLightVisible},
	{"paddleLightSize", luaPaddleLightSize},
	{"paddleSetLightSize", luaPaddleSetLightSize},
	{"paddleLightPower", luaPaddleLightPower},
	{"paddleSetLightPower", luaPaddleSetLightPower},
	{"paddleLightPosition", luaPaddleLightPosition},
	{"paddleSetLightPosition", luaPaddleSetLightPosition},
	{"paddleShowMessageEmoticonSound", luaPaddleShowMessageEmoticonSound},
	{"paddleShowMessageEmoticonDurationSound", luaPaddleShowMessageEmoticonDurationSound},
	{"paddleShowMessageEmoticonBMISizeDurationSound", luaPaddleShowMessageEmoticonBMISizeDurationSound},
	{"paddleRemoveMessage", luaPaddleRemoveMessage},
	{"paddleSetTopImage", luaPaddleSetTopImage},
	{"paddleSetAI", luaPaddleSetAI},

	{"paddleActionStop", luaPaddleActionStop},
	{"paddleActionRotateByAngleDurationForeverTag", luaPaddleActionRotateByAngleDurationForeverTag},
	{"paddleActionRotateToAngleDurationForeverTag", luaPaddleActionRotateToAngleDurationForeverTag},
	{"paddleActionScaleByScaleDurationForeverTag", luaPaddleActionScaleByScaleDurationForeverTag},
	{"paddleActionScaleToScaleDurationForeverTag", luaPaddleActionScaleToScaleDurationForeverTag},
	{"paddleActionPulseFromScaleMinMaxDelayDurationTag", luaPaddleActionPulseFromScaleMinMaxDelayDurationTag},
	
	{"heroKind", luaHeroKind},
	{"heroIsMainHero", luaHeroIsMainHero},
	{"heroPause", luaHeroPause},
	{"heroIsPaused", luaHeroIsPaused},
	{"heroFlags", luaHeroFlags},
	{"heroSetFlags", luaHeroSetFlags},
	{"heroUnsetFlags", luaHeroUnsetFlags},
	{"heroBBox", luaHeroBBox},
	{"heroPosition", luaHeroPosition},
	{"heroSetPosition", luaHeroSetPosition},
	{"heroSize", luaHeroSize},
	{"heroSetSize", luaHeroSetSize},
	{"heroAcceleration", luaHeroAcceleration},
	{"heroSetAcceleration", luaHeroSetAcceleration},
	{"heroElasticity", luaHeroElasticity},
	{"heroSetElasticity", luaHeroSetElasticity},
	{"heroSpeed", luaHeroSpeed},
	{"heroSetSpeed", luaHeroSetSpeed},
	{"heroLightEnabled", luaHeroLightEnabled},
	{"heroSetLightEnabled", luaHeroSetLightEnabled},
	{"heroLightVisible", luaHeroLightVisible},
	{"heroSetLightVisible", luaHeroSetLightVisible},
	{"heroLightSize", luaHeroLightSize},
	{"heroSetLightSize", luaHeroSetLightSize},
	{"heroLightPower", luaHeroLightPower},
	{"heroSetLightPower", luaHeroSetLightPower},
	{"heroLightPosition", luaHeroLightPosition},
	{"heroSetLightPosition", luaHeroSetLightPosition},
	{"heroShowMessageEmoticonSound", luaHeroShowMessageEmoticonSound},
	{"heroShowMessageEmoticonDurationSound", luaHeroShowMessageEmoticonDurationSound},
	{"heroShowMessageEmoticonBMISizeDurationSound", luaHeroShowMessageEmoticonBMISizeDurationSound},
	{"heroRemoveMessage", luaHeroRemoveMessage},
	
	{"isDebug", luaIsDebug},
#ifdef KK_DEBUG	
	{"removeDownloadedLevels", luaRemoveDownloadedLevels},
	{"downloadLevel", luaDownloadLevel},
	{"testGameOver", luaTestGameOver},
#endif
	
	{NULL, NULL}
};

void registerLuaGameLib ()
{
	[KKLM addLibrary:@"game" lib:gameLib];
}
