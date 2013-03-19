//
//  KKHUDGameEndLayer.m
//  be2
//
//  Created by Alessandro Iob on 29/7/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKHUDGameEndLayer.h"
#import "KKGameEngine.h"
#import "KKGraphicsManager.h"
#import "KKGlobalConfig.h"
#import "KKSoundManager.h"
#import "KKHUDLayer.h"
#import "KKMacros.h"
#import "KKGamePath.h"
#import "KKHero.h"

typedef enum {
	kGameEndActionScore = 1250 + 1,
} tGameEndAction;


@implementation KKHUDGameEndLayer

#define BG_COLOR ccc3(0, 0, 0)
#define FG_COLOR ccc3(255, 255, 255)
#define HERO_LABEL_COLOR ccc3(200, 200, 200)
#define PADDLE_LABEL_COLOR ccc3(200, 100, 100)

-(id) initGameEndLayer
{
	self = [super initWithColor4B:ccc4(BG_COLOR.r, BG_COLOR.g, BG_COLOR.b, 255)];
	if (self) {
		CGSize ws = [[CCDirector sharedDirector] winSize];
		
		gameEngine = KKGE;
		
		pongBackground = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:@"/pongBackground.png"]] retain];
		pongBackground.position = ccp (ws.width/2, ws.height/2);
		pongBackground.scaleX = SCALE_X (1);
		pongBackground.scaleY = SCALE_X (1);
		[self addChild:pongBackground z:10];
		
		// hero
		hero = [[CCSprite alloc] init];
		[hero setTexture:nil];
		[hero setTextureRect:CGRectMake (0, 0, SCALE_X (HERO_DEFAULT_WIDTH), SCALE_Y (HERO_DEFAULT_HEIGHT))];
		[hero setColor:FG_COLOR];
		hero.position = SCALE_POINT (ccp (10, ws.height + HERO_DEFAULT_HEIGHT + 10));
		[self addChild:hero z:20];

		heroLabel = [CCLabel labelWithString:NSLocalizedString(@" ", @"heroLabel")
								   dimensions:CGSizeZero
									alignment:UITextAlignmentCenter 
									 fontName:UI_FONT_DEFAULT 
									 fontSize:SCALE_Y(28)
					  ];
		[heroLabel.texture setAliasTexParameters];
		[heroLabel setColor:HERO_LABEL_COLOR];
		[heroLabel setOpacity:0];
		[heroLabel setAnchorPoint:ccp (0, 0.5)];
		heroLabel.position = ccp (
								  hero.position.x + SCALE_X (HERO_DEFAULT_WIDTH),
								   ws.height/2 + SCALE_Y (HERO_DEFAULT_HEIGHT + 10)
								  );
		[self addChild:heroLabel z:25];
		
		// paddle
		paddle = [[CCSprite alloc] init];
		[paddle setTexture:nil];
		[paddle setTextureRect:CGRectMake (0, 0, SCALE_X (HERO_DEFAULT_WIDTH), SCALE_Y (100))];
		[paddle setColor:FG_COLOR];
		paddle.position = SCALE_POINT (ccp (ws.width + HERO_DEFAULT_WIDTH + 10, ws.height/2));
		[self addChild:paddle z:20];

		paddleLabel = [CCLabel labelWithString:NSLocalizedString(@" ", @"paddleLabel")
								  dimensions:CGSizeZero
								   alignment:UITextAlignmentCenter 
									fontName:UI_FONT_DEFAULT 
									fontSize:SCALE_Y(28)
					 ];
		[paddleLabel.texture setAliasTexParameters];
		[paddleLabel setColor:PADDLE_LABEL_COLOR];
		[paddleLabel setOpacity:0];
		[paddleLabel setAnchorPoint:ccp (1.0, 0.5)];
		paddleLabel.position = ccp (
								  ws.width - SCALE_X (30),
								  heroLabel.position.y - SCALE_Y (30)
								  );
		[self addChild:paddleLabel z:25];

		labelsStep = 0;
		labelsText = [[NSMutableArray arrayWithObjects:
					   @"Where am I?", @"In the Table",
					   @"What do you want?", @"Fun.",
					   @"Whose side are you on?", @"This would be telling...",
					   @" ", @"We want fun...Fun...FUN!",
					   @"You won't get it!", @"By hook or by crook, we will.",
					   @"Who are you?", @"The new Paddle Two.",
					   @"Who is Paddle One?", @"You are Paddle 3042.",
					   @"I am not a paddle; I am a free square!", @" ",
					   nil
					   ] retain];
		
		// end text
		endLabelsStep = 0;
		endLabelsText = [[NSMutableArray arrayWithObjects:
						 @"THE END", @"YOU MADE IT IN", @"AND YOU EXPLORED", @"BE",
						  @"OF", [NSString stringWithFormat:@"%.0f SECONDS",gameEngine.questTimeElapsed], [NSString stringWithFormat:@"%.1f%% OF PONGLAND", (100.0/(float)gameEngine.questTotalExplorationPoints)*(float)gameEngine.questExplorationPoints], @"SEEING",
						 @"THE", @"WITH A SCORE OF", @"NOW, PLEASE, DON'T", @"YOU",
						 @"BEGINNING", [[(KKHUDLayer *)[gameEngine hud] scoreFormatter] stringFromNumber:[NSNumber numberWithInt:gameEngine.score]], @"KNOCK YOURSELF OUT", @"!",
						 nil
						 ] retain];
		
		for (int i = 0; i < END_LABELS; i++) {
			CCLabel *l = [CCLabel labelWithString:NSLocalizedString([endLabelsText objectAtIndex:(i * END_STEPS) + endLabelsStep], @"theEnd")
									   dimensions:CGSizeZero
										alignment:UITextAlignmentCenter 
										 fontName:UI_FONT_DEFAULT 
										 fontSize:SCALE_Y(48)
						  ];
			[l.texture setAliasTexParameters];
			[l setColor:FG_COLOR];
			[l setOpacity:0];
			[l setAnchorPoint:ccp (0.5, 1.0)];
			l.position = SCALE_POINT (ccp (ws.width/2, ws.height - 10 - (i * 48)));
			[self addChild:l z:30];
			endLabels[i] = l;
		}
		
		// badge
		badge = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:@"/badge3042.png"]] retain];
		[badge setScaleX:SCALE_X(1)];
		[badge setScaleY:SCALE_Y(1)];
		badge.position = SCALE_POINT (ccp (ws.width/2, -[badge contentSize].height/2 - SCALE_Y (20)));
		[self addChild:badge z:20];
	}
	return self;
}

-(void) dealloc
{
	[pongBackground release], pongBackground = nil;
	[hero release], hero = nil;
	[paddle release], paddle = nil;
	heroLabel = nil;
	paddleLabel = nil;
	
	for (int i = 0; i < END_LABELS; i++) {
		endLabels[i] = nil;
	}
	
	[labelsText release], labelsText = nil;
	[endLabelsText release], endLabelsText = nil;

	[badge release], badge = nil;
	
	[super dealloc];
}

-(void) show
{
	[gameEngine stopBackgroundMusic];
	[self playAnimation];
}

-(void) hide
{
	for (int i = 0; i < END_LABELS; i++) {
		[endLabels[i] stopAllActions];
	}
	
	[self stopAllActions];
	[hero stopAllActions];
	[paddle stopAllActions];
	[heroLabel stopAllActions];
	[paddleLabel stopAllActions];
	[badge stopAllActions];
	
	[gameEngine stopBackgroundMusic];
}

-(void) playAnimation
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	CCMoveTo *heroMove1 = [CCMoveTo actionWithDuration:1 position:SCALE_POINT (ccp (10, ws.height/2))];
	CCAction *heroAction = [CCSequence actions:
							[CCCallFunc actionWithTarget:self selector:@selector(heroScream)],
							[CCSpawn actions:
							 [CCEaseBounceOut actionWithAction:[[heroMove1 copy] autorelease]],
							 [CCSequence actions:
							  [CCDelayTime actionWithDuration:0.4],
							  [CCCallFunc actionWithTarget:self selector:@selector(heroHit)],
							  [CCDelayTime actionWithDuration:0.3],
							  [CCCallFunc actionWithTarget:self selector:@selector(heroHit)],
							  [CCDelayTime actionWithDuration:0.2],
							  [CCCallFunc actionWithTarget:self selector:@selector(heroHit)],
							  nil
							  ],
							 nil
							 ],
							[CCDelayTime actionWithDuration:0.5],
							[CCCallFunc actionWithTarget:self selector:@selector(heroStop)],
							nil
							];
	
	CCAction *paddleAction = [CCSequence actions:
							  [CCDelayTime actionWithDuration:1.5],
							  [CCCallFunc actionWithTarget:self selector:@selector(heroApplause)],
							  [CCDelayTime actionWithDuration:2.5],
							  [CCCallFunc actionWithTarget:self selector:@selector(playMusic)],
							  [CCDelayTime actionWithDuration:1.0],
							  [CCCallFunc actionWithTarget:self selector:@selector(playDialog)],
							  nil
							  ];
	
	[hero runAction:heroAction];
	[paddle runAction:paddleAction];
}

-(void) heroScream
{
	[gameEngine playSound:@"/elements/scream.caf"];
}

-(void) heroHit
{
	[gameEngine playSound:@"/pongPaddleHit.caf"];
}

-(void) heroStop
{
	[gameEngine playSound:@"/elements/oouh.caf"];
}

-(void) heroScale
{
	[gameEngine playSound:@"/powerupTurbo.caf"];
}

-(void) heroApplause
{
	[gameEngine playSound:@"/gameEnd/applause.caf"];
}

-(void) heroMad
{
	[gameEngine playSound:@"/gameEnd/mad.caf"];
	
	CGSize ws = [[CCDirector sharedDirector] winSize];
	[badge runAction:[CCMoveTo actionWithDuration:3 position:ccp (ws.width/2, [badge contentSize].height/2 - SCALE_Y(30))]];
	[badge runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:10 angle:360]]];
	[badge runAction:[CCRepeatForever actionWithAction:[CCSequence actions:
														[CCScaleTo actionWithDuration:2 scaleX:SCALE_X(1.1) scaleY:SCALE_Y(1.1)],
														[CCScaleTo actionWithDuration:2 scaleX:SCALE_X(0.9) scaleY:SCALE_Y(0.9)],
														nil
														]
					  ]
	 ];
}

-(void) paddlePunked
{
	[gameEngine playSound:@"/gameEnd/punked.caf"];
	[gameEngine startBackgroundMusic:@"/gameEnd2.mp3"];
}

-(void) paddlePlay
{
	[gameEngine playSound:@"/gameEnd/shallWePlayAGame.caf"];
}

-(void) paddleEnter
{
	[gameEngine playSound:@"/powerupTurbo.caf"];
}

-(void) playDialog
{
	[heroLabel setString:[labelsText objectAtIndex:labelsStep*2]];
	[paddleLabel setString:[labelsText objectAtIndex:(labelsStep*2)+1]];

	CCAction *heroAction;
	CCAction *paddleAction = [CCSequence actions:
							  [CCDelayTime actionWithDuration:(labelsStep == 3 ? 0.0 : 4.0)],
							  [CCFadeTo actionWithDuration:1.0 opacity:255],
							  [CCDelayTime actionWithDuration:3.0],
							  [CCFadeTo actionWithDuration:1.0 opacity:0],
							  nil
							  ];
	
	if (labelsStep == 5) {
		CGSize ws = [[CCDirector sharedDirector] winSize];
		[paddle runAction:[CCSequence actions:
						   [CCDelayTime actionWithDuration:3.0],
						   [CCCallFunc actionWithTarget:self selector:@selector(paddleEnter)],
						   [CCDelayTime actionWithDuration:1.0],
						   [CCMoveTo actionWithDuration:1 position:SCALE_POINT (ccp (ws.width - HERO_DEFAULT_WIDTH, ws.height/2))],
						   nil
						   ]
		 ];
	}
	
	labelsStep++;
	if (labelsStep < DIALOG_STEPS) {
		heroAction = [CCSequence actions:
					  [CCFadeTo actionWithDuration:1.0 opacity:255],
					  [CCDelayTime actionWithDuration:(labelsStep == 4 ? 1.0 : 6.0)],
					  [CCFadeTo actionWithDuration:1.0 opacity:0],
					  [CCDelayTime actionWithDuration:2.2],
					  [CCCallFunc actionWithTarget:self selector:@selector(playDialog)],
					  nil
					  ];
	} else {
		heroAction = [CCSequence actions:
					  [CCFadeTo actionWithDuration:1.0 opacity:255],
					  [CCDelayTime actionWithDuration:4.0],
					  [CCCallFunc actionWithTarget:self selector:@selector(paddlePunked)],
					  [CCDelayTime actionWithDuration:1.5],
					  [CCFadeTo actionWithDuration:1.0 opacity:0],
					  [CCDelayTime actionWithDuration:1.0],
					  [CCCallFunc actionWithTarget:self selector:@selector(endDialog)],
					  nil
					  ];
	}
	
	[heroLabel runAction:heroAction];
	[paddleLabel runAction:paddleAction];
}

-(void) endDialog
{

	CCAction *action = [CCSequence actions:
						[CCCallFunc actionWithTarget:self selector:@selector(heroScale)],
						[CCScaleTo actionWithDuration:2.0 scaleX:1.0 scaleY:10.0],
						[CCCallFunc actionWithTarget:self selector:@selector(heroMad)],
						[CCDelayTime actionWithDuration:2.0],
						[CCCallFunc actionWithTarget:self selector:@selector(showScore)],
						nil
						];
	[hero runAction:action];
}

-(void) showScore
{
	CCAction *action = [CCSequence actions:
						[CCDelayTime actionWithDuration:1.0],
						[CCCallFuncND actionWithTarget:self selector:@selector(showEndLabel:number:) data:[NSNumber numberWithInt:0]],
						[CCDelayTime actionWithDuration:1.0],
						[CCCallFuncND actionWithTarget:self selector:@selector(showEndLabel:number:) data:[NSNumber numberWithInt:1]],
						[CCDelayTime actionWithDuration:1.0],
						[CCCallFuncND actionWithTarget:self selector:@selector(showEndLabel:number:) data:[NSNumber numberWithInt:2]],
						[CCDelayTime actionWithDuration:1.0],
						[CCCallFuncND actionWithTarget:self selector:@selector(showEndLabel:number:) data:[NSNumber numberWithInt:3]],
						nil
						];
	
	CCAction *buttons = [CCSequence actions:
						 [CCDelayTime actionWithDuration:14.0],
						 [CCCallFunc actionWithTarget:self selector:@selector(showButtons)],
						 nil
						 ];
	
	[self runAction:action];
	[self runAction:buttons];
}

-(void) showEndLabel:(id)node number:(NSNumber *)i
{
	[endLabels[[i intValue]] runAction:
	 [CCRepeatForever actionWithAction:
	  [CCSequence actions:
	   [CCFadeTo actionWithDuration:1.0 opacity:255],
	   [CCDelayTime actionWithDuration:1.0],
	   [CCFadeTo actionWithDuration:1.0 opacity:0],
	   [CCDelayTime actionWithDuration:1.0],
	   [CCCallFuncND actionWithTarget:self selector:@selector(switchEndLabelText:number:) data:i],
	   nil
	   ]
	  ] 
	 ];
}

-(void) switchEndLabelText:(id)node number:(NSNumber *)n
{
	int i = [n intValue];
	
	if (i == 0) {
		endLabelsStep++;
		if (endLabelsStep >= END_STEPS) endLabelsStep = 0;
	}
	[endLabels[i] setString:NSLocalizedString([endLabelsText objectAtIndex:(i * END_STEPS) + endLabelsStep], @"theEnd")];
}

-(void) playMusic
{
	[pongBackground runAction:[CCFadeTo actionWithDuration:1.0 opacity:60]];
	
	[gameEngine startBackgroundMusicNoLoop:@"/gameEnd1.mp3"];
}

-(void) showButtons
{
	[(KKHUDLayer *)[gameEngine hud] showGameEndButtons];
}

@end
