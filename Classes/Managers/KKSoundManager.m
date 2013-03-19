//
//  SoundManager.m
//  Be2
//
//  Created by Alessandro Iob on 4/15/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKSoundManager.h"
#import "KKPersistenceManager.h"
#import "SynthesizeSingleton.h"

@implementation KKSoundManager

SYNTHESIZE_SINGLETON(KKSoundManager);

@synthesize musicVolume, soundEffectsVolume;

-(id) init
{
	self = [super init];
	
	if (self) {
		soundManagerState = kSoundManagerInitializing;
		
		loadedSoundEffects = [[NSMutableDictionary alloc] initWithCapacity:CD_MAX_BUFFERS];
		
		[self initSoundEngine];
	}
	
	return self;
}

-(void) dealloc
{
	[loadedSoundEffects autorelease];
	[self destroySoundEngine];
	
	[super dealloc];
}

-(void) initSoundEngine
{
#if SOUND_IS_SUPPORTED
	
	channelGroups[kChannelToneLoop] = 1; // This means only 1 loop will play at a time
	channelGroups[kChannelGroupNonInterruptible] = 4;//2 voices that can't be interrupted
	channelGroups[kChannelGroupFX] = 16; // 16 voices to be shared by the fx
	channelGroups[kChannelGroupSpeach] = 1; // 1 voices to be shared by the speaches

	//set the session to MediaPlayback to take the audio hardware
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty (
							 kAudioSessionProperty_AudioCategory,
							 sizeof (sessionCategory),
							 &sessionCategory
							 );
	AudioSessionSetActive (TRUE);	
	
	//Initialise audio manager asynchronously as it can take a few seconds
	[CDAudioManager initAsynchronously:kAMM_FxPlusMusicIfNoOtherAudio channelGroupDefinitions:channelGroups channelGroupTotal:kNumberOfChannelGroups];

	if ([CDAudioManager sharedManagerState] != kAMStateInitialised) {
		//The audio manager is not initialised yet so kick off the sound loading as an NSOperation that will wait for the audio manager
		NSInvocationOperation* bufferLoadOp = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadSoundBuffers:) object:nil] autorelease];
		NSOperationQueue *opQ = [[[NSOperationQueue alloc] init] autorelease]; 
		[opQ addOperation:bufferLoadOp];
		soundManagerState = kSoundManagerInitializing;
	} else {
		[self loadSoundBuffers:nil];
		soundManagerState = kSoundManagerBuffersLoading;
	}	
	
	audioManager = [CDAudioManager sharedManager];
	soundEngine = audioManager.soundEngine;

#endif
	
	self.musicVolume = (float)KKPM.musicVolume/100.0f;
	self.soundEffectsVolume = (float)KKPM.soundEffectsVolume/100.0f;
}

-(void) destroySoundEngine
{
#if SOUND_IS_SUPPORTED
	if (audioManager) [audioManager release];
#endif
}

-(void) vibrate
{
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

-(void) loadSoundBuffers:(NSObject*) data {
	
	// Wait for the audio manager if it is not initialised yet
	while ([CDAudioManager sharedManagerState] != kAMStateInitialised) {
		[NSThread sleepForTimeInterval:0.1];
	}	
	
	
	//Use: afconvert -f caff -d ima4 yourfile.wav to create an ima4 compressed version of a wave file
//	CDSoundEngine *sse = [CDAudioManager sharedManager].soundEngine;
//	NSMutableArray *loadRequests = [[[NSMutableArray alloc] init] autorelease];
//	NSBundle *bundle = [NSBundle mainBundle];
	
//	for (int i=0; i < kNumberOfSoundEffects; i++) {
//		NSString *p = [NSString stringWithFormat:@"sfx_%d", i, nil];
//		[loadRequests addObject:[[[CDBufferLoadRequest alloc] init:kChannelGroupFX fileName:[bundle pathForResource:p ofType:@"aiff"]] autorelease]];
//	}
//	
//	[sse loadBuffersAsynchronously:loadRequests];
	soundManagerState = kSoundManagerBuffersLoading;
}

-(float) defaultMusicVolume
{
	return (float)KKPM.musicVolume/100.0f;
}

-(float) defaultSoundEffectsVolume
{
	return (float)KKPM.soundEffectsVolume/100.0f;
}

-(void) resetMusicVolume
{
	self.musicVolume = [self defaultMusicVolume];
}

-(void) resetSoundEffectsVolume
{
	self.soundEffectsVolume = [self defaultSoundEffectsVolume];
}

-(void) setSoundEffectsVolume:(float)v
{
	if (v < 0.0) v = 0.0;
	else if (v > 1.0) v = 1.0;
	soundEffectsVolume = v;
#if SOUND_IS_SUPPORTED
	audioManager.soundEngine.masterGain = v;
#endif
}

-(void) setMusicVolume:(float)v
{
	if (v < 0.0) v = 0.0;
	else if (v > 1.0) v = 1.0;
	musicVolume = v;
#if SOUND_IS_SUPPORTED
	audioManager.backgroundMusic.volume = v;
#endif
}

-(BOOL) mute
{
#if SOUND_IS_SUPPORTED
	return audioManager.mute;
#else
	return TRUE;
#endif
}	

-(void) setMute:(BOOL)muteValue 
{
#if SOUND_IS_SUPPORTED
	audioManager.mute = muteValue;
#endif
}

-(void) loadBackgroundMusic:(NSString *)path
{
	if (!((KKPersistenceManager *) KKPM).musicEnabled) return;
	
#if SOUND_IS_SUPPORTED
	[audioManager preloadBackgroundMusic:path];
#endif
}

-(void) startBackgroundMusic:(NSString *)path loop:(BOOL)b
{
	if (!((KKPersistenceManager *) KKPM).musicEnabled) return;
	
#if SOUND_IS_SUPPORTED
	[audioManager playBackgroundMusic:path loop:b];
#endif
}

-(void) stopBackgroundMusic
{
#if SOUND_IS_SUPPORTED
	[audioManager stopBackgroundMusic];
#endif
}

-(void) pauseBackgroundMusic
{
#if SOUND_IS_SUPPORTED
	[audioManager pauseBackgroundMusic];
#endif
}

-(void) resumeBackgroundMusic
{
#if SOUND_IS_SUPPORTED
	[audioManager resumeBackgroundMusic];
#endif
}

-(void) rewindBackgroundMusic
{
#if SOUND_IS_SUPPORTED
	[audioManager rewindBackgroundMusic];
#endif
}

-(BOOL) isBackgroundMusicPlaying
{
#if SOUND_IS_SUPPORTED	
	return [audioManager isBackgroundMusicPlaying];
#else
	return NO;
#endif	
}	

-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId
{
	return [self playSoundEffect:filename channelGroupId:channelGroupId gain:1.0f loop:NO];
}

-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId loop:(BOOL)loop
{
	return [self playSoundEffect:filename channelGroupId:channelGroupId gain:1.0f loop:loop];
}

-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId pan:(float)pan loop:(BOOL)loop
{
	return [self playSoundEffect:filename channelGroupId:channelGroupId pitch:1.0f pan:pan gain:1.0f loop:loop];
}

-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId gain:(float)gain loop:(BOOL)loop
{
	return [self playSoundEffect:filename channelGroupId:channelGroupId pitch:1.0f pan:0.0f gain:gain loop:loop];
}

/*
 * @param channelGroupId the channel group that will be used to play the sound.
 * @param pitch pitch multiplier. e.g 1.0 is unaltered, 0.5 is 1 octave lower. 
 * @param pan stereo position. -1 is fully left, 0 is centre and 1 is fully right.
 * @param gain gain multiplier. e.g. 1.0 is unaltered, 0.5 is half the gain
 * @param loop should the sound be looped or one shot.
 */ 
-(ALuint) playSoundEffect:(NSString *)filename channelGroupId:(int)channelGroupId pitch:(float)pitch pan:(float)pan gain:(float)gain loop:(BOOL)loop
{
//	KKLOG (@"soundManager.playSoundEffect: %d %@", ((KKPersistenceManager *) KKPM).soundEffectsEnabled, filename);
	
	if (!((KKPersistenceManager *) KKPM).soundEffectsEnabled) return 0;

#if SOUND_IS_SUPPORTED
	NSNumber *soundId = (NSNumber*)[loadedSoundEffects objectForKey:filename];
	
	if (soundId == nil)
		[self preloadSoundEffect:filename];
		soundId = (NSNumber*)[loadedSoundEffects objectForKey:filename];
	
	if (soundId != nil) {
		return [soundEngine playSound:[soundId intValue] channelGroupId:channelGroupId pitch:pitch pan:pan gain:gain loop:loop];
	}
#endif
	return CD_NO_SOURCE;
}

-(void) stopSoundEffect:(ALuint)sid
{
	[soundEngine stopSound:sid];
}

-(void) stopAllSoundEffects
{
	[soundEngine stopAllSounds];
}

-(void) cleanupSounds:(NSArray *)sounds
{
//	[self stopAllSoundEffects];
	
	for (NSString *filename in [loadedSoundEffects allValues]) {
		if (![sounds containsObject:filename]) {
			[self unloadSoundEffect:filename];
		}
	}
}

-(void) preloadSoundEffectsAsync:(NSArray *)sounds cleanup:(BOOL)cleanup
{
	NSMutableArray *loadRequests = [[[NSMutableArray alloc] init] autorelease];

	if (cleanup) {
		[self cleanupSounds:sounds];
	}
	
	for (NSString *filename in sounds) {
		if (![loadedSoundEffects objectForKey:filename]) {
			NSNumber *soundId = [self getNextAvailableBuffer];
			[loadRequests addObject:[[[CDBufferLoadRequest alloc] init:[soundId intValue] filePath:filename] autorelease]];
		}
	}
	
	[soundEngine loadBuffersAsynchronously:loadRequests];
}

-(float) asyncLoadProgress
{
	return [soundEngine asynchLoadProgress];
}

-(NSNumber *) preloadSoundEffect:(NSString*)filename
{
	NSNumber *soundId = (NSNumber *)[loadedSoundEffects objectForKey:filename];
	
//	KKLOG (@"preloadSoundEffect: %d - %@",[soundId intValue], filename);
#if SOUND_IS_SUPPORTED
	if(soundId == nil) {
		soundId = [self getNextAvailableBuffer];
		if ([soundEngine loadBuffer:[soundId intValue] filePath:filename])
			[loadedSoundEffects setObject:soundId forKey:filename];
		else {
			[self freeBuffer:soundId];
			soundId = nil;
		}
	}
#endif
	return soundId;
}

-(void) unloadSoundEffect:(NSString *)filename
{
	NSNumber* soundId = [loadedSoundEffects objectForKey:filename];
	
	if(soundId != nil) 	{
#if SOUND_IS_SUPPORTED
		[soundEngine unloadBuffer:[soundId intValue]];
#endif
		[self freeBuffer:soundId];
		[loadedSoundEffects removeObjectForKey:filename];
	}
}

-(NSNumber*) getNextAvailableBuffer
{
	for(int i = 0; i < CD_MAX_BUFFERS ; i++) {
		if(!usedBuffers[i]) {
			usedBuffers[i] = true;
			return [[[NSNumber alloc] initWithInt:i] autorelease];
		}
	}
	return nil;
}

-(void) freeBuffer:(NSNumber *)buffer
{
	usedBuffers[[buffer intValue]] = false;
}


@end

@implementation KKFadeMusicTo

+(id) actionWithDuration:(ccTime)t volume:(float)v
{	
	if (v == -1) v = [KKSNDM defaultMusicVolume];
	return [[[self alloc] initWithDuration:t volume:v ] autorelease];
}

-(id) initWithDuration:(ccTime)t volume:(float)v
{
	if (!(self=[super initWithDuration: t]))
		return nil;
	
	endVolume = v;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	CCAction *copy = [[[self class] allocWithZone:zone] initWithDuration:[self duration] volume:endVolume];
	return copy;
}

-(void) startWithTarget:(id)aTarget
{
	[super startWithTarget:aTarget];
	
	startVolume = [KKSoundManager sharedKKSoundManager].musicVolume;
	deltaVolume = endVolume - startVolume;
}

-(void) update:(ccTime)t
{
	[KKSoundManager sharedKKSoundManager].musicVolume = startVolume + deltaVolume * t;
	if ([KKSoundManager sharedKKSoundManager].musicVolume == 0.0)
		[[KKSoundManager sharedKKSoundManager] stopBackgroundMusic];
}

@end
