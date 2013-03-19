//
//  GraphicsManager.m
//  Be2
//
//  Created by Alessandro Iob on 6/30/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKGraphicsManager.h"
#import "SynthesizeSingleton.h"
#import "KKDeviceDetection.h"
#import "KKGameEngine.h"

#import <MediaPlayer/MediaPlayer.h>

#define ATLAS_PNG_FORMAT @"atlas_%d.png"
#define ATLAS_PLIST_FORMAT @"atlas_%d.plist"

@implementation KKGraphicsManager

//@synthesize deviceScale;

SYNTHESIZE_SINGLETON(KKGraphicsManager);

-(id) init
{
	self = [super init];
	
	if (self) {
#ifdef KK_IPAD_SUPPORT			
		CGSize ws = [[CCDirector sharedDirector] winSize];
		
		deviceScale = CGPointMake(ws.width/VIRTUAL_WIDTH, ws.height/VIRTUAL_HEIGHT);
#else
		deviceScale = CGPointMake(1.0, 1.0);
#endif
		
//		NSString *path = [[NSBundle mainBundle] bundlePath];
//		for (int i = 0; i < kNumberOfGraphicGroups; i++) {
//			NSString *finalPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:ATLAS_PLIST_FORMAT, i]];
//			atlasSpritePLists[i] = [[[NSDictionary dictionaryWithContentsOfFile:finalPath] objectForKey:@"frames"] retain];
//			atlasSpriteManagers[i] = nil;
//			KKLOG (@"GRAPHICSMANAGER: %@ count is %d.", finalPath, [atlasSpritePLists[i] count]);
//		}
	}
	
	return self;
}

-(void) dealloc
{
	for (int i = 0; i < kNumberOfGraphicGroups; i++) {
		if (atlasSpritePLists[i]) {
			[atlasSpritePLists[i] release];
			atlasSpritePLists[i] = nil;
		}
		if (atlasSpriteManagers[i]) {
			[atlasSpriteManagers[i] release];
			atlasSpriteManagers[i] = nil;
		}
	}
	[super dealloc];
}

-(int) scaleFont:(int)fontSize
{
	int newFontSize;
#ifdef KK_IPAD_SUPPORT			
	switch ([KKDeviceDetection detectDevice]) {
		case kIPadSimulator:
		case kIPad1G:
		case kUnknownIPad:
			newFontSize = fontSize * 2;
			break;
		case kIPhoneSimulator:
		case kIPhone1G:
		case kIPhone3G:
		case kIPhone3GS:
		case kUnknownIPhone:
		case kIPodTouch1G:
		case kIPodTouch2G:
		case kUnknownIPod:
		default:
			newFontSize = fontSize;
			break;
	}
#else
	newFontSize = fontSize;
#endif
	if (newFontSize > FONT_MAX_SIZE) newFontSize = FONT_MAX_SIZE;
	return newFontSize;
}

-(CCSpriteSheet *) getAtlasSpriteManager:(int)group
{
	CCSpriteSheet *m = nil;
	
	if ([self isValidGroup:group]) {
		if ([self loadGroup:group]) {
			m = atlasSpriteManagers[group];
		}
	}
	return m;
}

-(BOOL) isValidGroup:(int)group
{
	return group >= 0 && group < kNumberOfGraphicGroups;
}

-(BOOL) isGroupLoaded:(int)group
{
	return [self isValidGroup:group] && atlasSpriteManagers[group] != nil;
}
	
-(BOOL) loadGroup:(int)group
{
	NSString *path = [[NSBundle mainBundle] bundlePath];
	
	if ([self isValidGroup:group]) {
		if (![self isGroupLoaded:group]) {
			atlasSpriteManagers[group] = [CCSpriteSheet 
										  spriteSheetWithFile:[path stringByAppendingPathComponent:[NSString stringWithFormat:ATLAS_PNG_FORMAT, group]]
										  capacity:[atlasSpritePLists[group] count]
			];
		}
	}
	return atlasSpriteManagers[group] != nil;
}
			
-(void) releaseGroup:(int)group
{
	if ([self isGroupLoaded:group]) {
		[atlasSpriteManagers[group] release];
		atlasSpriteManagers[group] = nil;
	}
}
			
-(CGRect) getSpriteRectFromGroup:(int)group filename:(NSString *)filename
{
	NSDictionary *d = [atlasSpritePLists[group] objectForKey:filename];
	return CGRectMake (
					   [(NSNumber *)[d objectForKey:@"x"] floatValue],
					   [(NSNumber *)[d objectForKey:@"y"] floatValue],
					   [(NSNumber *)[d objectForKey:@"width"] floatValue],
					   [(NSNumber *)[d objectForKey:@"height"] floatValue]
	);
}

-(CCSprite *) spriteFromGroup:(int)group filename:(NSString *)filename;
{
	CCSprite *sprite = nil;
	
	if ([self isValidGroup:group]) {
		CGRect box = [self getSpriteRectFromGroup:group filename:filename];
		
		if (![self isGroupLoaded:group]) [self loadGroup:group];
		
//		NSLog(@"FIX KKGRAPHICS MANAGER SPRITESFROMGROUP");
//		sprite = [CCSprite spriteWithFile:filename rect:(CGRect)box offset:(CGPoint)CGPointZero];

		sprite = [CCSprite spriteWithTexture:atlasSpriteManagers[group].texture rect:box];
	}
	return sprite;
}

#pragma mark -
#pragma mark Video

-(void) playVideo:(NSString *)path
{
	NSURL *url = [NSURL fileURLWithPath:path];
	MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
	
	// Register to receive a notification when the movie has finished playing.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(moviePlayBackDidFinish:)
												 name:MPMoviePlayerPlaybackDidFinishNotification
											   object:moviePlayer];
	
	[KKGE onPausePlaySound:NO];
	
	if ([moviePlayer respondsToSelector:@selector(setFullscreen:animated:)]) {
		// Use the new 3.2 style API
		moviePlayer.controlStyle = MPMovieControlStyleNone;
		moviePlayer.shouldAutoplay = YES;
		// This does blows up in cocos2d, so we'll resize manually
		// [moviePlayer setFullscreen:YES animated:YES];
		[moviePlayer.view setTransform:CGAffineTransformMakeRotation((float)M_PI_2)];
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		moviePlayer.view.frame = CGRectMake(0, 0, winSize.height, winSize.width);	// width and height are swapped after rotation
		[[[CCDirector sharedDirector] openGLView] addSubview:moviePlayer.view];
	} else {
		// Use the old 2.0 style API
		moviePlayer.movieControlMode = MPMovieControlModeHidden;
		[moviePlayer play];
	}
}

-(void) moviePlayBackDidFinish:(NSNotification*)notification {
	MPMoviePlayerController *moviePlayer = [notification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:moviePlayer];
	
	// If the moviePlayer.view was added to the openGL view, it needs to be removed
	if ([moviePlayer respondsToSelector:@selector(setFullscreen:animated:)]) {
		[moviePlayer.view removeFromSuperview];
	}
	
	[moviePlayer release];
	
	[KKGE onResume];
}

@end
