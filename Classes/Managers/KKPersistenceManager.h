//
//  PersistenceManager.h
//  Be2
//
//  Created by Alessandro Iob on 4/15/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"

#define KKPM [KKPersistenceManager sharedKKPersistenceManager]

#define GAME_INFO KKPM.info


@interface KKPersistenceManager : NSObject {
	NSString *gameDataPath;
	NSMutableDictionary *savedGameData;
	
	int deviceOrientation;
	BOOL displayFPS;
	float animationInterval;
	
	BOOL soundEffectsEnabled;
	int soundEffectsVolume;
	BOOL musicEnabled;
	int musicVolume;
	
	int inputMode;
	int difficultyLevel;
	
	NSMutableDictionary *info;
}

@property (readwrite, copy, nonatomic) NSString *gameDataPath;
@property (readwrite, retain, nonatomic) NSMutableDictionary *savedGameData;

@property (readwrite, nonatomic) int deviceOrientation;
@property (readwrite, nonatomic) BOOL displayFPS;
@property (readwrite, nonatomic) float animationInterval;

@property (readwrite, nonatomic) BOOL soundEffectsEnabled;
@property (readwrite, nonatomic) int soundEffectsVolume;
@property (readwrite, nonatomic) BOOL musicEnabled;
@property (readwrite, nonatomic) int musicVolume;

@property (readwrite, nonatomic) int inputMode;
@property (readwrite, nonatomic) int difficultyLevel;

@property (readonly, nonatomic) NSMutableDictionary *info;

+(KKPersistenceManager *) sharedKKPersistenceManager;
+(void) purgeSharedKKPersistenceManager;

-(void) loadUserDefaults;
-(void) saveUserDefaults;

-(NSString *) gameDataPath;

-(BOOL) hasSavedGame;
-(NSMutableDictionary *) loadGame;
-(BOOL) saveGameWithNextLevel:(NSString *)nextLevel;
-(BOOL) removeGame;

@end
