//
//  KKHUDGameOverLayer.m
//  be2
//
//  Created by Alessandro Iob on 21/5/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKHUDGameOverLayer.h"
#import "KKGameEngine.h"
#import "KKGraphicsManager.h"
#import "KKGlobalConfig.h"
#import "KKSoundManager.h"
#import "KKHUDLayer.h"

typedef enum {
	kGameOverActionInfo = 1150 + 1,
} tGameOverAction;

@implementation KKHUDGameOverLayer

-(void) enableRain:(BOOL)f
{
	if (f) {
		[rain resetSystem];
		[rain scheduleUpdateWithPriority:1];
	} else {
		[rain stopSystem];
		[rain unscheduleUpdate];
	}
	[rain setVisible:f];
}

-(void) initRain
{
	rain = [[[CCPointParticleSystem alloc] initWithTotalParticles:1000] autorelease];
	[self addChild:rain z:1000];
	
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	// duration
	rain.duration = kCCParticleDurationInfinity;
	
	rain.emitterMode = kCCParticleModeGravity;
	
	// Gravity Mode: gravity
	rain.gravity = ccp(10,-10);
	
	// Gravity Mode: radial
	rain.radialAccel = 0;
	rain.radialAccelVar = 0;
	
	// Gravity Mode: tagential
	rain.tangentialAccel = 0;
	rain.tangentialAccelVar = 0;
	
	// Gravity Mode: speed of particles
	rain.speed = 330;
	rain.speedVar = 30;
	
	// angle
	rain.angle = -90;
	rain.angleVar = 0;
	
	
	// emitter position
	rain.position = ccp(ws.width / 2, ws.height);
	rain.posVar = ccp(ws.width / 2, 0);
	
	// life of particles
	rain.life = 4.5f;
	rain.lifeVar = 0;
	
	// size, in pixels
	rain.startSize = 1.0f;
	rain.startSizeVar = 2.0f;
	rain.endSize = kCCParticleStartSizeEqualToEndSize;
	
	// emits per second
	rain.emissionRate = 120;
	
	// color of particles
	rain.startColor = (ccColor4F){0.7f,0.7f,0.7f,1.0f};
	rain.startColorVar = (ccColor4F){0.0f,0.0f,0.0f,0.0f};
	rain.endColor = (ccColor4F){0.7f,0.7f,0.7f,0.5f};
	rain.endColorVar = (ccColor4F){0.0f,0.0f,0.0f,0.0f};	
	
	[self enableRain:NO];
}

#define SKY_COLOR ccc3(90, 90, 90)
#define GROUND_COLOR ccc3(9, 76, 11)

#define GROUND_Y SCALE_Y(120)
-(id) initGameOverLayer
{
	self = [super initWithColor4B:ccc4(SKY_COLOR.r, SKY_COLOR.g, SKY_COLOR.b, 255)];
	if (self) {
		CGSize ws = [[CCDirector sharedDirector] winSize];
		
		gameEngine = KKGE;
		
		ground = [CCColorLayer layerWithColor:ccc4(GROUND_COLOR.r, GROUND_COLOR.g, GROUND_COLOR.b, 255) width:ws.width height:GROUND_Y];
		[ground setAnchorPoint:ccp(0,0)];
		[ground setPosition:ccp(0,0)];
		[ground setOpacity:0];
		[self addChild:ground z:100];
		
		actors = [CCSprite spriteWithFile:[gameEngine pathForGraphic:@"/gameOver/actors.png"]];
		[actors setScaleX:SCALE_X(1)];
		[actors setScaleY:SCALE_Y(1)];
		[actors setAnchorPoint:ccp(1,0)];
		[actors setPosition:ccp(ws.width - SCALE_X(10), GROUND_Y - SCALE_Y(10))];
		[actors setOpacity:0];
		[self addChild:actors z:200];
		
		cloudsBack = [CCSprite spriteWithFile:[gameEngine pathForGraphic:@"/gameOver/cloudsBack.png"]];
		[cloudsBack setScaleX:SCALE_X(2)];
		[cloudsBack setScaleY:SCALE_Y(1)];
		[cloudsBack setAnchorPoint:ccp(0,1)];
		[cloudsBack setPosition:ccp(0, ws.height)];
		[cloudsBack setOpacity:0];
		[self addChild:cloudsBack z:10];
		
		cloudsFront = [CCSprite spriteWithFile:[gameEngine pathForGraphic:@"/gameOver/cloudsFront.png"]];
		[cloudsFront setScaleX:SCALE_X(2)];
		[cloudsFront setScaleY:SCALE_Y(1)];
		[cloudsFront setAnchorPoint:ccp(0, 1)];
		[cloudsFront setPosition:ccp(0, ws.height)];
		[cloudsFront setOpacity:0];
		[self addChild:cloudsFront z:20];
		
		thunder = [CCColorLayer layerWithColor:ccc4(255, 255, 255, 255)];// width:ws.width height:ws.height - SCALE_Y(120)];
		[thunder setAnchorPoint:ccp(0, 0)];
		[thunder setPosition:ccp(0, 0)];
		[thunder setOpacity:0];
		[self addChild:thunder z:30];
		
		[self initRain];
		
		gameOver = [CCLabel labelWithString:NSLocalizedString(@"Game Over", @"gameOver") fontName:UI_FONT_DEFAULT fontSize:SCALE_FONT (42)];
		[gameOver setColor:ccc3(202, 202, 202)];
		[gameOver setAnchorPoint:ccp (0.5, 1)];
		[gameOver setPosition:ccp (ws.width/2, ws.height - SCALE_Y (30))];
		[gameOver setOpacity:0];
		[self addChild:gameOver z:15];
		
		CGSize is;
		NSString *msg = NSLocalizedString (@"Exploration+Points", @"scoreMessage");
		scoreMessage = [[[KKHUDButtonLabel alloc] initWithString:msg
														withSize:26
														  target:nil
														selector:nil
						 ] autorelease];
		[scoreMessage setAnchorPoint:ccp(0, 0)];
		is = [scoreMessage contentSize];
		scoreMessagePosIn = ccp(SCALE_X(10), GROUND_Y + is.height*2);
		[scoreMessage setPosition:ccp(scoreMessagePosIn.x, -50)];
		[scoreMessage setColor:ccc3(202, 202, 202)];
		[scoreMessage setLabelColor:ccc3(0, 0, 0)];
		[self addChild:scoreMessage z:16];
		
		score = [[[KKHUDButtonLabel alloc] initWithString:msg
												 withSize:26
												   target:nil
												 selector:nil
				  ] autorelease];
		[score setAnchorPoint:ccp(0, 0)];
		is = [score contentSize];
		scorePosIn = ccp(scoreMessagePosIn.x, scoreMessagePosIn.y - is.height - SCALE_Y(8));
		[score setPosition:ccp(scorePosIn.x, -50)];
		[score setColor:ccc3(202, 202, 202)];
		[score setLabelColor:ccc3(0, 0, 0)];
		[self addChild:score z:16];
		
		[self setVisible:NO];
		[self setOpacity:0];
	}
	return self;
}

/*
 THUNDERS DELAY, DURATION, TYPE
	{0.8, 1.0, 1},
	{3.0, 1.5, 2},
	{10.5, 1.2, 2},
	{11, 2, 2},
	{3.2, 1.6, 1},
	{0.2, 1.7, 1},
	{20.5, 1.6, 2},
	{5.2, 0, 0},
*/
-(void) startThunders
{
	CCAction *action = [CCRepeatForever actionWithAction:
						[CCSequence actions:
						 [CCDelayTime actionWithDuration:0.8],
						 [CCFadeTo actionWithDuration:0.1 opacity:255],
						 [CCDelayTime actionWithDuration:0.1],
						 [CCFadeTo actionWithDuration:0.2 opacity:180],
						 [CCFadeTo actionWithDuration:0.1 opacity:255],
						 [CCFadeTo actionWithDuration:0.2 opacity:120],
						 [CCFadeTo actionWithDuration:0.1 opacity:200],
						 [CCFadeTo actionWithDuration:0.2 opacity:0],
						 
						 [CCDelayTime actionWithDuration:3.0],
						 [CCFadeTo actionWithDuration:0.1 opacity:180],
						 [CCFadeTo actionWithDuration:0.2 opacity:120],
						 [CCFadeTo actionWithDuration:0.1 opacity:170],
						 [CCFadeTo actionWithDuration:0.2 opacity:110],
						 [CCFadeTo actionWithDuration:0.1 opacity:160],
						 [CCFadeTo actionWithDuration:0.2 opacity:100],
						 [CCFadeTo actionWithDuration:0.1 opacity:150],
						 [CCFadeTo actionWithDuration:0.2 opacity:90],
						 [CCFadeTo actionWithDuration:0.1 opacity:110],
						 [CCFadeTo actionWithDuration:0.2 opacity:0],
						 
						 [CCDelayTime actionWithDuration:10.5],
						 [CCFadeTo actionWithDuration:0.1 opacity:180],
						 [CCFadeTo actionWithDuration:0.2 opacity:90],
						 [CCFadeTo actionWithDuration:0.1 opacity:150],
						 [CCFadeTo actionWithDuration:0.2 opacity:110],
						 [CCFadeTo actionWithDuration:0.1 opacity:160],
						 [CCFadeTo actionWithDuration:0.2 opacity:80],
						 [CCFadeTo actionWithDuration:0.1 opacity:150],
						 [CCFadeTo actionWithDuration:0.2 opacity:0],						 
						 
						 [CCDelayTime actionWithDuration:11.0],
						 [CCFadeTo actionWithDuration:0.1 opacity:160],
						 [CCFadeTo actionWithDuration:0.2 opacity:120],
						 [CCFadeTo actionWithDuration:0.1 opacity:170],
						 [CCFadeTo actionWithDuration:0.2 opacity:110],
						 [CCFadeTo actionWithDuration:0.1 opacity:180],
						 [CCFadeTo actionWithDuration:0.2 opacity:100],
						 [CCFadeTo actionWithDuration:0.1 opacity:150],
						 [CCFadeTo actionWithDuration:0.2 opacity:90],
						 [CCFadeTo actionWithDuration:0.1 opacity:150],
						 [CCFadeTo actionWithDuration:0.2 opacity:60],
						 [CCFadeTo actionWithDuration:0.2 opacity:110],
						 [CCFadeTo actionWithDuration:0.3 opacity:0],
						 
						 [CCDelayTime actionWithDuration:3.2],
						 [CCFadeTo actionWithDuration:0.1 opacity:255],
						 [CCDelayTime actionWithDuration:0.1],
						 [CCFadeTo actionWithDuration:0.2 opacity:180],
						 [CCFadeTo actionWithDuration:0.1 opacity:215],
						 [CCFadeTo actionWithDuration:0.1 opacity:100],
						 [CCFadeTo actionWithDuration:0.2 opacity:255],
						 [CCFadeTo actionWithDuration:0.2 opacity:120],
						 [CCFadeTo actionWithDuration:0.1 opacity:215],
						 [CCFadeTo actionWithDuration:0.2 opacity:100],
						 [CCFadeTo actionWithDuration:0.1 opacity:200],
						 [CCFadeTo actionWithDuration:0.2 opacity:0],
						 						 
						 [CCDelayTime actionWithDuration:0.2],
						 [CCFadeTo actionWithDuration:0.2 opacity:255],
						 [CCDelayTime actionWithDuration:0.1],
						 [CCFadeTo actionWithDuration:0.2 opacity:180],
						 [CCFadeTo actionWithDuration:0.1 opacity:215],
						 [CCFadeTo actionWithDuration:0.1 opacity:100],
						 [CCFadeTo actionWithDuration:0.2 opacity:255],
						 [CCFadeTo actionWithDuration:0.2 opacity:120],
						 [CCFadeTo actionWithDuration:0.1 opacity:215],
						 [CCFadeTo actionWithDuration:0.2 opacity:100],
						 [CCFadeTo actionWithDuration:0.1 opacity:200],
						 [CCFadeTo actionWithDuration:0.2 opacity:0],
						 
						 [CCDelayTime actionWithDuration:20.5],
						 [CCFadeTo actionWithDuration:0.1 opacity:160],
						 [CCFadeTo actionWithDuration:0.2 opacity:120],
						 [CCFadeTo actionWithDuration:0.1 opacity:200],
						 [CCFadeTo actionWithDuration:0.2 opacity:80],
						 [CCFadeTo actionWithDuration:0.1 opacity:120],
						 [CCFadeTo actionWithDuration:0.2 opacity:50],
						 [CCFadeTo actionWithDuration:0.1 opacity:150],
						 [CCFadeTo actionWithDuration:0.2 opacity:30],
						 [CCFadeTo actionWithDuration:0.1 opacity:100],
						 [CCFadeTo actionWithDuration:0.2 opacity:0],
						 
						 [CCDelayTime actionWithDuration:5.2],
						 nil
						 ]
						];
	[thunder runAction:action];
}

#define SHOW_DURATION 0.6
#define SCORE_SHOW_DURATION 2.0
#define HIDE_DURATION 0.6

-(void) runScoreInfoActions:(CCAction*)a
{
	[score stopAllActions];
	[scoreMessage stopAllActions];
	
	CCAction *action = [CCSequence actions:
						[CCMoveTo actionWithDuration:SCORE_SHOW_DURATION position:scorePosIn],
						[CCDelayTime actionWithDuration:3],
						[CCMoveTo actionWithDuration:SCORE_SHOW_DURATION position:ccp(scorePosIn.x, -50)],
						a,
						nil
						];
	[score runAction:action];

	action = [CCSequence actions:
			  [CCMoveTo actionWithDuration:SCORE_SHOW_DURATION position:scoreMessagePosIn],
			  [CCDelayTime actionWithDuration:3],
			  [CCMoveTo actionWithDuration:SCORE_SHOW_DURATION position:ccp(scoreMessagePosIn.x, -50)],
			  nil
			  ];
	[scoreMessage runAction:action];
}

-(void) setScoreInfo
{
	[score setLabel:[[(KKHUDLayer *)[gameEngine hud] scoreFormatter] stringFromNumber:[NSNumber numberWithInt:gameEngine.score]]];
	[scoreMessage setLabel:NSLocalizedString (@"Be2+Final+Score", @"scoreMessage")];
	[self runScoreInfoActions:[CCCallFunc actionWithTarget:self selector:@selector(setExplorationInfo)]];
}

-(void) setExplorationInfo
{
	[score setLabel:[NSString stringWithFormat:@"%d / %d", gameEngine.questExplorationPoints, gameEngine.questTotalExplorationPoints]];
	[scoreMessage setLabel:NSLocalizedString (@"Exploration+Points", @"scoreMessage")];
	[self runScoreInfoActions:[CCCallFunc actionWithTarget:self selector:@selector(setQuestTimeInfo)]];
}

-(void) setQuestTimeInfo
{
	[score setLabel:[gameEngine.hud secondsToStringHMS:gameEngine.questTimeElapsed]];
	[scoreMessage setLabel:NSLocalizedString (@"Quest+Time", @"scoreMessage")];
	[self runScoreInfoActions:[CCCallFunc actionWithTarget:self selector:@selector(setScoreInfo)]];
}

-(void) show
{
	[self enableRain:YES];
	
	CGSize ws = [[CCDirector sharedDirector] winSize];
	[cloudsBack setPosition:ccp(0, ws.height)];
	[cloudsFront setPosition:ccp(0, ws.height)];

	[cloudsBack runAction:[CCRepeatForever actionWithAction:[CCSequence actions:
						   [CCMoveBy actionWithDuration:300 position:ccp(-ws.width, 0)], 
						   [CCMoveBy actionWithDuration:300 position:ccp(ws.width, 0)],
						   nil]]];
	
	[cloudsFront runAction:[CCRepeatForever actionWithAction:[CCSequence actions:
						   [CCMoveBy actionWithDuration:200 position:ccp(-ws.width, 0)], 
						   [CCMoveBy actionWithDuration:200 position:ccp(ws.width, 0)],
						   nil]]];
	
	CCAction *action = [CCFadeTo actionWithDuration:SHOW_DURATION opacity:255];
	
	[ground runAction:[[action copy] autorelease]];
	[actors runAction:[[action copy] autorelease]];
	[cloudsBack runAction:[[action copy] autorelease]];
	[cloudsFront runAction:[[action copy] autorelease]];
	[gameOver runAction:[[action copy] autorelease]];
	[self runAction:[CCSequence actions:[CCShow action], [CCFadeTo actionWithDuration:SHOW_DURATION opacity:255], nil]];

	[gameEngine stopBackgroundMusic];
	[gameEngine startBackgroundMusic:@"/gameOver.mp3"];
	
	womanCryID = [gameEngine playSoundLoop:@"/gameOver/womanCry.caf"];
	childCryID = [gameEngine playSoundLoop:@"/gameOver/childCry.caf"];
	rainID = [gameEngine playSoundLoop:@"/gameOver/rainAndThunders.caf"];

	[self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:SHOW_DURATION], [CCCallFunc actionWithTarget:self selector:@selector(setScoreInfo)], nil]];
	 
	[self startThunders];
}

-(void) hide
{
	[self enableRain:NO];
	
	[score stopAllActions];
	[scoreMessage stopAllActions];
	[score runAction:[CCMoveTo actionWithDuration:HIDE_DURATION position:ccp(scorePosIn.x, -50)]];
	[scoreMessage runAction:[CCMoveTo actionWithDuration:HIDE_DURATION position:ccp(scoreMessagePosIn.x, -50)]];
	
	[thunder stopAllActions];
	[thunder setOpacity:0];
	
	[cloudsBack stopAllActions];
	[cloudsFront stopAllActions];
	
	CCAction *action = [CCFadeTo actionWithDuration:HIDE_DURATION opacity:0];
	
	[ground runAction:[[action copy] autorelease]];
	[actors runAction:[[action copy] autorelease]];
	[cloudsBack runAction:[[action copy] autorelease]];
	[cloudsFront runAction:[[action copy] autorelease]];
	[gameOver runAction:[[action copy] autorelease]];
	[self runAction:[CCSequence actions:[CCFadeTo actionWithDuration:HIDE_DURATION opacity:0], [CCHide action], nil]];
	
	[gameEngine stopBackgroundMusic];
	[gameEngine stopSound:womanCryID];
	[gameEngine stopSound:childCryID];
	[gameEngine stopSound:rainID];
}


@end
