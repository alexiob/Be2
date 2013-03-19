//
//  SoundManager.h
//  Be2
//
//  Created by Alessandro Iob on 4/15/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"

#if TARGET_IPHONE_SIMULATOR
#define SOUND_IS_SUPPORTED TRUE
#else
#define SOUND_IS_SUPPORTED TRUE
#endif

#define KKSNDM [KKSoundManager sharedKKSoundManager]
#define KKSNDM_SOUND_PLAY(__SOUND__,__CHANNEL__) [KKSNDM playSoundEffect:__SOUND__ channelGroupId:__CHANNEL__]

#import "CocosDenshion.h"
#import "CDAudioManager.h"
#import <OpenAL/al.h>
#import <OpenAL/alc.h>

typedef enum {
	kSoundManagerInitializing,
	kSoundManagerBuffersLoading,
	kSoundManagerReady
} tSoundManagerState;

typedef enum {
	kChannelToneLoop=0,
	kChannelGroupNonInterruptible,
	kChannelGroupFX,
	kChannelGroupSpeach,
	kNumberOfChannelGroups,
} tChannelGroups;

@interface KKSoundManager : NSObject {
	int soundManagerState;
	CDAudioManager *audioManager;
	CDSoundEngine  *soundEngine;
	
	NSMutableDictionary* loadedSoundEffects;
	bool usedBuffers[CD_MAX_BUFFERS];
	int channelGroups[kNumberOfChannelGroups];
	
	float musicVolume;
	float soundEffectsVolume;
}

@property (readwrite, nonatomic) float musicVolume;
@property (readwrite, nonatomic) float soundEffectsVolume;

+(KKSoundManager *) sharedKKSoundManager;
+(void) purgeSharedKKSoundManager;

-(void) vibrate;

-(float) defaultMusicVolume;
-(float) defaultSoundEffectsVolume;

-(void) resetMusicVolume;
-(void) resetSoundEffectsVolume;

-(BOOL) mute;
-(void) setMute:(BOOL)muteValue; 

-(void) loadBackgroundMusic:(NSString *)path;
-(void) startBackgroundMusic:(NSString *)path loop:(BOOL)b;
-(void) stopBackgroundMusic;
-(void) pauseBackgroundMusic;
-(void) resumeBackgroundMusic;
-(void) rewindBackgroundMusic;
-(BOOL) isBackgroundMusicPlaying;

-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId;
-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId loop:(BOOL)loop;;
-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId gain:(float)gain loop:(BOOL)loop;
-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId pan:(float)pan loop:(BOOL)loop;
-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId pitch:(float)pitch pan:(float)pan gain:(float)gain loop:(BOOL)loop;
-(void) stopSoundEffect:(ALuint)sid;
-(void) stopAllSoundEffects;

-(void) cleanupSounds:(NSArray *)sounds;
-(void) preloadSoundEffectsAsync:(NSArray *)sounds cleanup:(BOOL)cleanup;
-(float) asyncLoadProgress;
-(NSNumber *) preloadSoundEffect:(NSString*)filename;
-(void) unloadSoundEffect:(NSString *)filename;

-(NSNumber*) getNextAvailableBuffer;
-(void) freeBuffer:(NSNumber *)buffer;

-(void) initSoundEngine;
-(void) destroySoundEngine;
-(void) loadSoundBuffers:(NSObject*)data;

@end

@interface KKFadeMusicTo : CCIntervalAction <NSCopying> {
	float startVolume;
	float endVolume;
	float deltaVolume;
}

+(id) actionWithDuration:(ccTime)duration volume:(float)v;
-(id) initWithDuration:(ccTime)duration volume:(float)v;

@end