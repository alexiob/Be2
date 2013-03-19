//
//  IntroLayer.m
//  Be2
//
//  Created by Alessandro Iob on 4/13/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKIntroLayer.h"
#import "KKGlobalConfig.h"
#import "KKSoundManager.h"
#import "KKScenesManager.h"
#import "KKGraphicsManager.h"
#import "KKMacros.h"
#import "KKMath.h"
#import "KKGamePath.h"

typedef enum {
	kIntroSceneReflected = 0,
	kIntroSceneEscaped,
	kIntroSceneBanzai,
} tIntroScene;

#define INTRO_MESSAGES_PLIST @"introMessages.plist"

#ifdef KK_BE2_FREE
#define BE2_LOGO @"logoSquareFree.png"
#else
#define BE2_LOGO @"logoSquare.png"
#endif

@implementation KKIntroLayer

-(id) initWithColor4B:(ccColor4B)aColor
{
	self = [super initWithColor4B:aColor];
	
	if (self) {
		RANDOM_SEED();
		
		CGSize ws = [[CCDirector sharedDirector] winSize];
		
		[self loadIntroMessages];
		
		[self setAnchorPoint:ccp (0, 0)];
		[self setPosition:ccp (0, 0)];
		
		hero = [CCSprite spriteWithFile:[KKGamePath pathForGraphic:BE2_LOGO]];
		[hero setAnchorPoint:ccp (0, 0)];
		[hero setPosition:SCALE_POINT (ccp (60, 60))];
		[hero setScaleX:SCALE_X(1)];
		[hero setScaleY:SCALE_Y(1)];
		[self addChild:hero z:10];
		
		paddle = [CCSprite spriteWithFile:[KKGamePath pathForGraphic:@"logoPaddle.png"]];
		[paddle setAnchorPoint:ccp (0, 0)];
		[paddle setPosition:ccp (ws.width - SCALE_X(100), SCALE_Y(60))];
		[paddle setScaleX:SCALE_X(1)];
		[paddle setScaleY:SCALE_Y(1)];
		[self addChild:paddle z:10];		
		
		message = [[CCLabel labelWithString:@" " fontName:UI_FONT_DEFAULT fontSize:SCALE_Y(32)] retain];
		[message setPosition:SCALE_POINT (ccp (60, 60))];
		[message setOpacity:0];
		[message setAnchorPoint:ccp(0, 0)];
		[self addChild:message z:5];
		
		[KKSNDM preloadSoundEffect:@"/intro/heroReflected.caf"];
		[KKSNDM preloadSoundEffect:@"/intro/heroEscaped.caf"];
		[KKSNDM preloadSoundEffect:@"/intro/heroBanzai.caf"];
	}
	return self;
}

-(void) releaseIntroSprites
{
	if (hero) [self removeChild:hero cleanup:TRUE];
	if (paddle) [self removeChild:paddle cleanup:TRUE];
}

-(void) dealloc
{
	if (introMessages) [introMessages release], introMessages = nil;
	[self releaseIntroSprites];
	
	[super dealloc];
}

-(void) loadIntroMessages
{
	NSString *errorDesc = nil;
	NSPropertyListFormat plistFormat;
	NSString *plistPath = [KKGamePath pathForData:INTRO_MESSAGES_PLIST];
	NSData *plistData = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	introMessages = [(NSArray *) [NSPropertyListSerialization
											   propertyListFromData:plistData 
											   mutabilityOption:NSPropertyListMutableContainersAndLeaves 
											   format:&plistFormat
											   errorDescription:&errorDesc
											   ] retain];
	KKLOG (@"loaded %@: %@", plistPath, introMessages);
}

-(void) introClosed
{
	[self stopAllActions];
	[hero stopAllActions];
	[paddle stopAllActions];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:NOTIF_INTRO_CLOSED object:nil];
}

-(void) fadeInMessage
{
	CCAction *action = [CCFadeTo actionWithDuration:0.5 opacity:255];
	[message runAction:action];
}

-(void) playSound:(NSString *)filename
{
	if (filename && ![filename isEqualToString:@""]) {
		[KKSNDM playSoundEffect:[KKGamePath pathForSound:filename] channelGroupId:kChannelGroupFX];
	}
}

-(void) playHitAndReflectedSounds
{
	[self playSound:SOUND_PADDLE_HIT_2];
	[self playSound:@"/intro/heroReflected.caf"];
}

-(void) playEscapedSounds
{
	[self playSound:@"/intro/heroEscaped.caf"];
}

-(void) playBanzaiSounds
{
	[self playSound:@"/intro/heroBanzai.caf"];
}

-(void) setMessage
{
	RANDOM_SEED ();
	int i = RANDOM_INT (0, [introMessages count] - 1);
	NSString *msg = (NSString *)[introMessages objectAtIndex:i];
	[message setString:NSLocalizedString (msg, @"introMessage")];
}

-(void) playIntroSceneReflected
{
	CGSize hs = [hero contentSize];

	[self setMessage];
	
	CCAction *ha = [CCSequence actions:
					[CCMoveTo actionWithDuration:0.3 position:ccp(paddle.position.x - SCALE_X(hs.width), hero.position.x - SCALE_Y(40))],
					[CCCallFunc actionWithTarget:self selector:@selector(playHitAndReflectedSounds)],
					[CCMoveTo actionWithDuration:0.9 position:SCALE_POINT(ccp(-hs.width, -hs.height - 10))],
					[CCCallFunc actionWithTarget:self selector:@selector(fadeInMessage)],
					[CCDelayTime actionWithDuration:1.2],
					[CCCallFunc actionWithTarget:self selector:@selector(introClosed)],
					nil];
	[hero runAction:ha];
	
	CCAction *pa = [CCMoveBy actionWithDuration:0.3 position:SCALE_POINT (ccp(0, -40))];
	[paddle runAction:pa];
}

-(void) playIntroSceneEscaped
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	[self setMessage];
	
	ccBezierConfig bezier;
	bezier.controlPoint_1 = ccp (0, -ws.height/2);
	bezier.controlPoint_2 = ccp (SCALE_X(60), -ws.height/2);
	bezier.endPosition = ccp (SCALE_X(130), ws.height + SCALE_Y(10));
	
	CCAction *ha = [CCSequence actions:
					[CCBezierBy actionWithDuration:1.0 bezier:bezier],
					[CCCallFunc actionWithTarget:self selector:@selector(playEscapedSounds)],
					[CCCallFunc actionWithTarget:self selector:@selector(fadeInMessage)],
					[CCDelayTime actionWithDuration:1.2],
					[CCCallFunc actionWithTarget:self selector:@selector(introClosed)],
					nil];
	[hero runAction:ha];
	
	CCAction *pa = [CCMoveBy actionWithDuration:0.5 position:SCALE_POINT (ccp(0, -60))];
	[paddle runAction:pa];
}

-(void) playIntroSceneBanzai
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	[self setMessage];
	
	CCAction *ha = [CCSequence actions:
					[CCSpawn actions:
					 [CCCallFunc actionWithTarget:self selector:@selector(playBanzaiSounds)],
					 [CCEaseElasticIn actionWithAction:[CCMoveBy actionWithDuration:1.1 position:SCALE_POINT (ccp(150, 50))]],
					 nil
					 ],
					[CCCallFunc actionWithTarget:self selector:@selector(fadeInMessage)],
					[CCDelayTime actionWithDuration:1.8],
					[CCCallFunc actionWithTarget:self selector:@selector(introClosed)],
					nil];
	[hero runAction:ha];
	
	CCAction *pa = [CCSequence actions:
					[CCDelayTime actionWithDuration:0.7],
					[CCMoveBy actionWithDuration:0.3 position:ccp(0, ws.height + SCALE_Y(10))],
					nil];
	[paddle runAction:pa];
}

-(void) playIntro
{
	RANDOM_SEED ();

	switch (RANDOM_INT (kIntroSceneReflected, kIntroSceneBanzai)) {
		case kIntroSceneReflected:
			[self playIntroSceneReflected];
			break;
		case kIntroSceneEscaped:
			[self playIntroSceneEscaped];
			break;
		case kIntroSceneBanzai:
			[self playIntroSceneBanzai];
			break;
		default:
			break;
	}
}

@end
