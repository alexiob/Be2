//
//  GameEngine.h
//  Be2
//
//  Created by Alessandro Iob on 9/9/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"
#import "KKLevel.h"
#import <OpenAL/al.h>
#import <OpenAL/alc.h>

#define NUM_LIFES_AT_START 3
#define NEW_LIFE_SCORE 100000
#define EXPLORATION_POINT_TO_SCORE 1000
#define FULL_EXPLORATION_SCORE 100000
#define LIFES_LEFT_SCORE 100000

@class KKHUDLayer;
@class KKLuaManager;
@class KKSoundManager;

#define TEMPLATE_LEVEL @"level"
#define TEMPLATE_SCREEN @"screen"
#define TEMPLATE_PADDLE @"paddle"

typedef enum {
	kGMUnknown = -1,
	kGMNone = 0,
	kGMQuest,
	kGMTimeTrial,
	kGMChallenge
} tGameMode;

typedef enum {
	kDifficultyLow = 1,
	kDifficultyMedium,
	kDifficultyHigh
} tDifficulty;

typedef enum {
	kGSUnknown = -1,
	kGSNone = 0,
	kGSInit,
	
	kGSPause,
	
	kGSLoading,
	
	kGSMainIntro,
	kGSMainMenu,
	
	kGSGameStart,
	kGSInGame,
	kGSInGamePause,
	kGSGameOver,
} tGameState;

typedef enum {
	kGEFlagUpdateDisabled = 1 << 0,
	kGEFlagScriptUpdateDisabled = 1 << 1,
	kGEFlagPhysicsUpdateDisabled = 1 << 2,
} tGEFlag;

typedef enum {
	kGEActionBackgroundMusic = 10000 + 1,
} tGEAction;

typedef enum {
	kDieTimeout = 1,
	kDieKilled
} tDie;

#define KKGE [KKGameEngine sharedKKGameEngine]

@interface KKLevelLoadOperation : NSOperation
{
	NSString *levelDir;
	BOOL audio;
	float seconds;
}

-(id) initWithLevelDir:(NSString *)name startAudio:(BOOL)a startTimer:(float)s;

@end

@interface KKGameEngine : NSObject {
	KKLuaManager *luaManager;
	KKHUDLayer *hud;
	KKSoundManager *soundManager;
	
	NSMutableDictionary *gameInfo;
	
	tGameState currentGameState;
	tGameState previousGameState;
	NSString *currentGamePhase;
	
	tGameMode gameMode;
	BOOL isFullQuest;
	
	NSDate *startDate;
	
	NSMutableDictionary *availableLevelsInfo;
	NSMutableArray *sortedAvailableLevelsInfo;
	int currentAvailableLevelInfoIndex;
	
	NSString *levelName;
	NSMutableDictionary *levelData;
	KKLevel *level;
	
	KKScreen *previousScreen;
	
	int flags;
	
	NSDictionary *defaultScreenMessages;
	NSDictionary *levelScreenMessages;
	
	BOOL paused;
	BOOL hudShown;
	
	float questTimeElapsed; // how much time the player is playing into the game
	float levelTimeElapsed; // how much time the player is playing into the current level
	float levelTimeLeft; // how much time is left to complete the level (can be +/- by bonuses)
	BOOL updateLevelTimeLeft; // TRUE when there is a timeLeft timer in action
	BOOL levelTimeSuspended; // the levelTimeElapsed and levelTimeLeft are suspended 
	BOOL levelTimeLeftSuspended; // the levelTimeLeft decrementing is suspended 
	float levelTimeLeftSuspendedTimout; // time left till the suspension is enabled. -1 is forever
	
	int numPlayerHerosLeft; // number of heroes available for the player plus the current hero
	
	KKScreen *checkpointScreen; // screen where to restart if a player dies
	CGPoint checkpointScreenPosition;
	CGPoint checkpointScreenSpeed;
	
	int questTotalExplorationPoints;
	int questExplorationPoints;
	
	int previousLevelScore;
	int currentLevelScore;
	int score; // current score
	int scoreMultiplier; // active score multiplier
	int scoreForNewLife;
	
	// hero effects
	BOOL fxInvertAccelerationX;
	float fxInvertAccelerationXTimeout;
	BOOL fxInvertAccelerationY;
	float fxInvertAccelerationYTimeout;
	
	float fxAccelerationIncrementX;
	float fxAccelerationIncrementXTimeout;
	float fxAccelerationIncrementY;
	float fxAccelerationIncrementYTimeout;
	
	int fxBlockedSideMovements;
	float fxBlockedSideMovementsTimeout;
	
	CGSize fxHeroScaleIncrement;
	float fxHeroScaleIncrementTimeout;
	
//	float fxHeroElasticity;
//	float fxHeroElasticityTimeout;
	
	// misc
	ALuint pauseSoundLoopId;
	BOOL wasBackgroundMusicPlaying;
	
	NSOperationQueue *backgroundQueue;
	
	int allLevels;
	int unlimitedLifes;
	int forceFullQuestMode;
	int forceFullQuestCompleted;
	
	int inputMode;
	int difficultyLevel;
}

@property (readonly, nonatomic) int unlimitedLifes;
@property (readwrite, nonatomic) int inputMode;
@property (readwrite, nonatomic) int difficultyLevel;

@property (readwrite, nonatomic) int flags;
@property (readonly, nonatomic) BOOL isFullQuest;

@property (readonly, nonatomic, retain) KKLevel *level;
@property (readonly, nonatomic) NSString *levelName;
@property (readonly, nonatomic) NSMutableDictionary *levelData;

@property (readwrite, nonatomic) tGameState currentGameState;
@property (readwrite, nonatomic, copy) NSString *currentGamePhase;

@property (readwrite, nonatomic) BOOL paused;

@property (readonly, nonatomic) KKHUDLayer *hud;

@property (readwrite, nonatomic) int questExplorationPoints;
@property (readwrite, nonatomic) int questTotalExplorationPoints;
@property (readwrite, nonatomic) int previousLevelScore;
@property (readwrite, nonatomic) int currentLevelScore;
@property (readwrite, nonatomic) int score;
@property (readwrite, nonatomic) int scoreMultiplier;
@property (readwrite, nonatomic) float questTimeElapsed;
@property (readwrite, nonatomic) float levelTimeElapsed;
@property (readwrite, nonatomic) float levelTimeLeft;

@property (readwrite, nonatomic) BOOL updateLevelTimeLeft;
@property (readwrite, nonatomic) BOOL levelTimeSuspended;

+(KKGameEngine *) sharedKKGameEngine;
+(void) purgeSharedKKGameEngine;

#pragma mark -
#pragma mark Store

-(BOOL) isFreeVersion;
-(BOOL) areAllLevelsPurchased;
-(void) buyAllLevels;
-(void) productPurchased:(NSString*)productIdentifier;
-(void) productPurchasedFailed;

#pragma mark -
#pragma mark Game Globals

-(int) getGlobal:(int)n;
-(void) setGlobal:(int)n toInteger:(int)i;

#pragma mark -
#pragma mark Game Info
-(void) setupDefaultInfo:(BOOL)force;
-(int) nextLevel;
-(void) setNextLevel:(int)idx;
-(NSMutableDictionary *) levelInfo:(int)idx;
-(NSMutableDictionary *) gameInfoLevel:(int)levelIndex;
-(BOOL) levelAvailable:(int)levelIndex;
-(void) setLevel:(int)levelIndex available:(BOOL)f;
-(BOOL) levelCompleted:(int)levelIndex;
-(void) setLevel:(int)levelIndex completed:(BOOL)f;
-(int) levelBestScore:(int)levelIndex;
-(void) setLevel:(int)levelIndex bestScore:(int)f;
-(float) levelBestTime:(int)levelIndex;
-(void) setLevel:(int)levelIndex bestTime:(float)f;

-(void) loadAvailableLevelsInfo;
-(BOOL) levelAvailable:(int)levelIndex;

-(NSMutableDictionary *) currentAvailableLevelInfo;
-(void) prevAvailableLevelInfo;
-(void) nextAvailableLevelInfo;

-(NSMutableDictionary *) currentLevelInfo;
-(void) prevLevelInfo;
-(void) nextLevelInfo;

-(NSString *) levelNameFromIndex:(int)idx;
-(int) levelIndexFromName:(NSString *)name;

-(NSMutableDictionary *) getGlobalMissionData:(NSString *)name;
-(void) setGlobalMission:(NSString *)name field:(NSString *)field toBool:(BOOL)f;
-(void) setGlobalMission:(NSString *)name field:(NSString *)field toInt:(int)f;
-(void) setGlobalMission:(NSString *)name field:(NSString *)field toFloat:(float)f;
-(void) setGlobalMission:(NSString *)name field:(NSString *)field toString:(NSString *)f;
-(BOOL) globalMission:(NSString *)name boolField:(NSString *)field;
-(int) globalMission:(NSString *)name intField:(NSString *)field;
-(float) globalMission:(NSString *)name floatField:(NSString *)field;
-(NSString *) globalMission:(NSString *)name stringField:(NSString *)field;

//-(NSMutableDictionary *) getMissionData:(NSString *)name;

#pragma mark -
#pragma mark Game
-(void) loadProgressAddWithMessage:(NSArray *)d;
-(void) loadProgressEndWithMessage:(NSString *)d;

-(void) loadScripts:(NSString *)scriptsDir;

-(void) loadDefaultScreenMessages;
-(void) loadLevelScreenMessages;
-(NSString *) screenMessageWithIndex:(int)idx;
-(NSString *) screenMessage:(KKScreen *)screen;
-(NSString *) randomMessage;

-(void) resetStartDate;
-(float) timeDeltaFromStartDate;

-(void) cleanupCurrentLevel;

-(void) levelStartTimerTimout;

-(BOOL) isMainMenu;

-(void) startLevel:(NSString *)name withStartTimer:(float)seconds;
-(void) startLevel:(NSString *)name andAudio:(BOOL)audio;
-(void) startLevel:(NSString *)name;
-(void) startLevel:(NSString *)name withTimeout:(float)timeout;

-(void) startGame:(NSString *)aLevelName mode:(tGameMode)aGameMode reset:(BOOL)reset;

-(void) resumeSavedGame;

-(void) resetGame;

-(void) updateTimers:(ccTime)dt;
-(void) update:(ccTime)dt;
-(void) enableUpdate;
-(void) disableUpdate;

-(void) scoreAdd:(int)p;
-(void) timeAdd:(float)p;
-(void) explorationPointsAdd:(int)p;
-(void) computeFinalScore;

-(float) getAvailableTime;

-(void) showHUD:(BOOL)f;
-(void) showHUDMove;

-(void) setCurrentScreen:(KKScreen *)screen prevScreen:(KKScreen *)prev;

-(void) moveMainHeroToScreen:(KKScreen *)screen atPosition:(CGPoint)pos;
-(void) sendHero:(KKHero *)hero toScreen:(KKScreen *)screen exitSide:(int)exitSide;

-(void) addLife;
-(void) addLifeWithMessage:(NSString *)msg;
-(void) removeLife;
-(void) removeLifeWithMessage:(NSString *)msg;
-(void) die:(tDie)mode;
-(void) die:(tDie)mode withMessage:(NSString *)msg;

-(void) questEnd;
-(BOOL) isFullQuestCompleted;
-(void) setFullQuestCompleted:(BOOL)v;

-(void) resetScreenCheckpoint;
-(void) setScreenCheckpoint:(KKScreen *)screen data:(NSDictionary *)data;

-(void) rateNow;
-(BOOL) shouldRate;

#pragma mark -
#pragma mark FX

-(void) fxReset;

-(void) fxInvertAccelerationX:(float)timeout;
-(void) fxInvertAccelerationY:(float)timeout;

-(void) fxAccelerationIncrementX:(float)inc timeout:(float)timeout;
-(void) fxAccelerationIncrementY:(float)inc timeout:(float)timeout;

-(void) fxBlockedSideMovements:(int)sides timeout:(float)timeout;

-(void) fxHeroScaleIncrement:(CGSize)inc timeout:(float)timeout;

#pragma mark -
#pragma mark Sound

-(void) extendSoundsArrayWithStandardSounds:(NSMutableArray *)sounds;
-(void) preloadSounds:(NSMutableArray *)sounds cleanup:(BOOL)cleanup target:(id)target selector:(SEL)selector;

-(void) loadBackgroundMusic:(NSString *)filename;
-(void) startBackgroundMusic:(NSString *)filename;
-(void) startBackgroundMusicNoLoop:(NSString *)filename;
-(void) stopBackgroundMusic;

-(void) playSound:(NSString *)filename;
-(GLuint) playSoundLoop:(NSString *)filename;
-(void) playSound:(NSString *)filename withPan:(float)pan;
-(void) playSound:(NSString *)filename forPaddle:(KKPaddle *)paddle;
-(GLuint) playSoundLoop:(NSString *)filename forPaddle:(KKPaddle *)paddle;
-(void) stopSound:(ALuint)sid;
-(void) stopAllSounds;

#pragma mark -
#pragma mark Commands
-(void) onPause;
-(void) onPausePlaySound:(BOOL)ps;
-(void) onResume;
-(void) onQuit;

#pragma mark -
#pragma mark Game Data
-(NSMutableDictionary *) saveGameData;
-(void) loadGameData:(NSDictionary *)gameData;

#pragma mark -
#pragma mark Paths
-(NSString *) getResourcesFolder:(NSString *)rFolder forLevel:(NSString *)lName;

-(NSString *) pathForGraphic:(NSString *)str;
-(NSString *) pathForTTFFont:(NSString *)str;
-(NSString *) pathForFont:(NSString *)str size:(int)s;
-(NSString *) pathForSound:(NSString *)str;
-(NSString *) pathForMusic:(NSString *)str;
-(NSString *) pathForScript:(NSString *)str;
-(NSString *) pathForData:(NSString *)str;

-(NSString *) pathForLevelDefinition:(NSString *)str;
-(NSString *) pathForLevel:(NSString *)str;
-(NSString *) pathForLevelFont:(NSString *)str size:(int)s;
-(NSString *) pathForLevelGraphic:(NSString *)str;
-(NSString *) pathForLevelSound:(NSString *)str;
-(NSString *) pathForLevelMusic:(NSString *)str;
-(NSString *) pathForLevelScript:(NSString *)str;

-(NSString *) thumbnailImageNameForLevelIndex:(int)levelIndex;

#pragma mark -
#pragma mark Utilities
-(void) removeDownloadedLevels;
-(void) downloadLevel:(NSString*)name fromHost:(NSString*)host atPort:(int)port;

#pragma mark -
#pragma mark Stuff
-(void) playBe2Trailer;
-(BOOL) wasBe2TrailerViewed;

@end
