//
//  HUDLayer.m
//  Be2
//
//  Created by Alessandro Iob on 4/10/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKHUDLayer.h"
#import "KKMacros.h"
#import "KKObjectsManager.h"
#import "KKPersistenceManager.h"
#import "KKGameEngine.h"
#import "KKMath.h"
#import "KKLuaManager.h"
#import "KKInputManager.h"
#import "KKGraphicsManager.h"
#import "KKSoundManager.h"
#import "KKHUDMessage.h"
//#import "KKOpenFeintManager.h"

#import "FontManager.h"
#import "FontLabelStringDrawing.h"

#import "llimits.h"

#define INPUT_PRIORITY INPUT_MANAGER_PRIORITY - 10

#define SHOW_DURATION 0.3f

#define MESSAGE_MOVE_DURATION 0.5

#define MESSAGE_TOP_BORDER 40
#define MESSAGE_MID_BORDER 10

typedef enum {
	kHLActionMoveTo = 1100 + 1,
	kHLActionFadeTo,
	kHLStartTimer,
	kHLTimerLabel,
	kHLZoomingText,
	kHLPulse,
	kHLActionChangeProverb,
} tHLAction;

@interface KKHUDLayer ()

-(void) onPause:(id)sender;
-(void) onResume:(id)sender;
-(void) onQuit:(id)sender;
-(void) onOpenFeint:(id)sender;
-(void) onNextLevel:(id)sender;
-(void) onMainMenu:(id)sender;

-(KKHUDButtonLabel *) newScorePanelLabelLeft:(BOOL)left label:(NSString*)label y:(float)y;
-(void) cleanupLevelScorePanel;
-(void) showLevelScorePanel;

-(id) action:(id)action visible:(BOOL)f;

@end

@implementation KKHUDLayer

@synthesize shown;
@synthesize isTimeNotificationEnabled;

#define MENU_Z 100
#define TIME_SUSPENDED_Z 200
#define MESSAGE_Z -50
#define STORE_BACKGROUND_Z -55
#define LOAD_PROGRESS_Z 1000

#define BUTTON_IMG_PAUSE @"hud/pause.png"
#define BUTTON_Z_PAUSE 10

#define BUTTON_RESUME @"Resume"
#define BUTTON_QUIT @"Main Menu"
#define BUTTON_OPENFEINT @"OpenFeint"
#define BUTTON_NEXT_LEVEL @"Next Level"
#define BUTTON_MAIN_MENU @"Main Menu"

#define BUTTONS_PADDING 10

#define ICON_IMG_SCORE @"hud/score.png"
#define ICON_IMG_TIME_TOTAL @"hud/timeTotal.png"
#define ICON_IMG_TIME_LEFT @"hud/timeLeft.png"
#define ICON_IMG_TURBO_LEFT @"hud/turboLeft.png"
#define ICON_IMG_MOVE_UP_DOWN @"hud/moveUpDown.png"
#define ICON_IMG_MOVE_LEFT_RIGHT @"hud/moveLeftRight.png"
#define ICON_IMG_HEROES_LEFT @"hud/heroesLeft.png"

#define FONT_SIZE_INFO_LABEL 16
#define FONT_SIZE_SUSPENDED_LABEL 32
#define FONT_SIZE_MENU 32
#define FONT_SIZE_PROGRESS 24
#define FONT_SIZE_PROVERBS 32

#define MENU_PRIORITY 1000
#define BORDER_X SCALE_X(8)
#define BORDER_Y SCALE_Y(8)
#define OPACITY 120
#define SPACE SCALE_X(4)

#define PAUSE_DIALOG_OPACITY 240
#define BUTTON_DIALOG_OPACITY 200

#define LOAD_PROGRESS_WIDTH SCALE_X(300) 
#define LOAD_PROGRESS_HEIGHT SCALE_Y(50)
#define LOAD_PROGRESS_DURATION 0.1

-(id) initWithColor4B:(ccColor4B)c
{
	self = [super initWithColor4B:c];
	if (self) {
		gameEngine = KKGE;
		soundManager = KKSNDM;
		
		CGSize ws = [[CCDirector sharedDirector] winSize];
		CGSize is;
		CGPoint lp;
		
		[self setAnchorPoint:ccp(0, 0)];
		
		ADD_SHARED_OBJECT (@"hudLayer", self);
		
		shown = YES;
		isTimeNotificationEnabled = YES;
		
		// pause
		pauseButton =[[KKHUDButtonImage alloc] initWithFile:[gameEngine pathForGraphic:BUTTON_IMG_PAUSE] 
												   target:self 
												 selector:@selector(onPause:)
					  ];
		is = [pauseButton contentSize];
		buttonPositionPauseIn = ccp (ws.width - BORDER_X, ws.height - BORDER_Y);
		buttonPositionPauseOut = ccp (buttonPositionPauseIn.x, ws.height + SCALE_Y (is.height));
		[pauseButton setPosition:buttonPositionPauseIn];
		[pauseButton setAnchorPoint:ccp (1.0, 1.0)];
		[pauseButton setOpacity:OPACITY];
		pauseButton.visible = NO;
		
		// resume
		resumeButton =[[KKHUDButtonLabel alloc] initWithString:NSLocalizedString (BUTTON_RESUME, @"resume")
													  withSize:FONT_SIZE_MENU
													 target:self 
												   selector:@selector(onResume:)
					  ];
		is = [resumeButton contentSize];
		buttonPositionResumeIn = ccp (ws.width/2 + BUTTONS_PADDING + is.width/2, ws.height/2);
		buttonPositionResumeOut = ccp (ws.width + BUTTONS_PADDING + is.width/2, ws.height/2);
		[resumeButton setPosition:buttonPositionResumeOut];
		[resumeButton setOpacity:BUTTON_DIALOG_OPACITY];
		resumeButton.visible = NO;
		
		// quit
		quitButton =[[KKHUDButtonLabel alloc] initWithString:NSLocalizedString (BUTTON_QUIT, @"quit")
													  withSize:FONT_SIZE_MENU
														target:self 
													  selector:@selector(onQuit:)
					   ];
		is = [quitButton contentSize];
		buttonPositionQuitIn = ccp (ws.width/2 - BUTTONS_PADDING - is.width/2, ws.height/2);
		buttonPositionQuitOut = ccp (-is.width/2, ws.height/2);
		[quitButton setPosition:buttonPositionQuitOut];
		[quitButton setOpacity:BUTTON_DIALOG_OPACITY];
		quitButton.visible = NO;
		
		// openfeint
		openFeintButton =[[KKHUDButtonLabel alloc] initWithString:NSLocalizedString (BUTTON_OPENFEINT, @"openfeint")
													withSize:FONT_SIZE_MENU
													  target:self 
													selector:@selector(onOpenFeint:)
					 ];
		buttonPositionOpenFeintIn = ccp (ws.width/2, ws.height/2 - is.height - BUTTONS_PADDING * 2);
		is = [openFeintButton contentSize];
		buttonPositionOpenFeintInLevelScorePanel = ccp (is.width/2 + BUTTONS_PADDING, is.height/2 + BUTTONS_PADDING);
		buttonPositionOpenFeintOut = ccp (buttonPositionOpenFeintIn.x, -is.height - BUTTONS_PADDING);
		[openFeintButton setPosition:buttonPositionOpenFeintOut];
		[openFeintButton setOpacity:BUTTON_DIALOG_OPACITY];
		openFeintButton.visible = NO;
		
		// main menu
		mainMenuButton =[[KKHUDButtonLabel alloc] initWithString:NSLocalizedString (BUTTON_MAIN_MENU, @"mainMenu")
														 withSize:FONT_SIZE_MENU
														   target:self 
														 selector:@selector(onMainMenu:)
						  ];
		is = [mainMenuButton contentSize];
		buttonPositionMainMenuIn = ccp (ws.width - (is.width/2 + BUTTONS_PADDING), is.height/2 + BUTTONS_PADDING);
		buttonPositionMainMenuOut = ccp (buttonPositionMainMenuIn.x, -is.height - BUTTONS_PADDING);
		buttonPositionMainMenuInLevelScorePanel = ccp (ws.width/2, is.height/2 + BUTTONS_PADDING);
		[mainMenuButton setPosition:buttonPositionMainMenuOut];
		[mainMenuButton setOpacity:BUTTON_DIALOG_OPACITY];
		mainMenuButton.visible = NO;
		
		// next level
		nextLevelButton =[[KKHUDButtonLabel alloc] initWithString:NSLocalizedString (BUTTON_NEXT_LEVEL, @"nextLevel")
														 withSize:FONT_SIZE_MENU
														   target:self 
														 selector:@selector(onNextLevel:)
						  ];
		is = [nextLevelButton contentSize];
		buttonPositionNextLevelIn = ccp (ws.width - BUTTONS_PADDING - is.width/2, is.height/2 + BUTTONS_PADDING);
		buttonPositionNextLevelOut = ccp (buttonPositionNextLevelIn.x, -is.height - BUTTONS_PADDING);
		[nextLevelButton setPosition:buttonPositionOpenFeintOut];
		[nextLevelButton setOpacity:BUTTON_DIALOG_OPACITY];
		nextLevelButton.visible = NO;
		
		// menu
		menu = [CCMenu menuWithItems:
				pauseButton, 
				resumeButton, 
				quitButton, 
				openFeintButton,
				nextLevelButton,
				mainMenuButton,
				nil
				];
		[menu setAnchorPoint:ccp(0, 0)];
		[menu setPosition:ccp(0, 0)];
		[self addChild:menu z:MENU_PRIORITY];
		
		// info
		NSString *fontPathInfo = [gameEngine pathForFont:UI_FONT_DEFAULT size:SCALE_FONT(FONT_SIZE_INFO_LABEL)];
		NSString *fontPathSuspended = [gameEngine pathForFont:UI_FONT_DEFAULT size:SCALE_FONT(FONT_SIZE_SUSPENDED_LABEL)];
		
		// score icon
		scoreIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_SCORE]] retain];
		is = [scoreIcon contentSize];
		lp = ccp (BORDER_X, ws.height - BORDER_Y);
		iconPositionScoreIn = ccp (BORDER_X, lp.y);
		iconPositionScoreOut = ccp (iconPositionScoreIn.x, ws.height + SCALE_Y(is.height));
		[scoreIcon setAnchorPoint:ccp (0.0, 1.0)];
		[scoreIcon setPosition:iconPositionScoreOut];
		[scoreIcon setOpacity:OPACITY];
		[scoreIcon setScaleX:SCALE_X(1)];
		[scoreIcon setScaleY:SCALE_Y(1)];
		[self addChild:scoreIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE, lp.y);
		
		// score label
		scoreLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"000.000.000" fntFile:fontPathInfo] retain];
		is = [scoreLabel contentSize];
		labelPositionScoreIn = ccp (lp.x, lp.y-2);
		labelPositionScoreOut = ccp (labelPositionScoreIn.x, ws.height + is.height);
		[scoreLabel setAnchorPoint:ccp (0.0, 1.0)];
		[scoreLabel setPosition:labelPositionScoreOut];
		[scoreLabel setOpacity:OPACITY];
		[self addChild:scoreLabel];
		lp = ccp (lp.x + is.width + SPACE, lp.y);
		
		// timeTotal icon
		timeTotalIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_TIME_TOTAL]] retain];
		is = [timeTotalIcon contentSize];
		iconPositionTimeTotalIn = ccp (lp.x + SPACE*2, lp.y);
		iconPositionTimeTotalOut = ccp (iconPositionTimeTotalIn.x, ws.height + SCALE_Y(is.height));
		[timeTotalIcon setAnchorPoint:ccp (0.0, 1.0)];
		[timeTotalIcon setPosition:iconPositionTimeTotalOut];
		[timeTotalIcon setOpacity:OPACITY];
		[timeTotalIcon setScaleX:SCALE_X(1)];
		[timeTotalIcon setScaleY:SCALE_Y(1)];
		[self addChild:timeTotalIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE*3, lp.y);
		
		// timeTotal label
		timeTotalLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"00:00:00" fntFile:fontPathInfo] retain];
		is = [timeTotalLabel contentSize];
		labelPositionTimeTotalIn = ccp (lp.x, lp.y-2);
		labelPositionTimeTotalOut = ccp (labelPositionTimeTotalIn.x, ws.height + is.height);
		[timeTotalLabel setAnchorPoint:ccp (0.0, 1.0)];
		[timeTotalLabel setPosition:labelPositionTimeTotalOut];
		[timeTotalLabel setOpacity:OPACITY];
		[self addChild:timeTotalLabel];
		lp = ccp (lp.x + is.width + SPACE, lp.y);
		
		// timeLeft icon
		timeLeftIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_TIME_LEFT]] retain];
		is = [timeLeftIcon contentSize];
		iconPositionTimeLeftIn = ccp (lp.x + SPACE*2, lp.y);
		iconPositionTimeLeftOut = ccp (iconPositionTimeLeftIn.x, ws.height + SCALE_Y(is.height));
		[timeLeftIcon setAnchorPoint:ccp (0.0, 1.0)];
		[timeLeftIcon setPosition:iconPositionTimeLeftOut];
		[timeLeftIcon setOpacity:OPACITY];
		[timeLeftIcon setScaleX:SCALE_X(1)];
		[timeLeftIcon setScaleY:SCALE_Y(1)];
		[self addChild:timeLeftIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE*3, lp.y);
		
		// timeLeft label
		timeLeftLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"00:00" fntFile:fontPathInfo] retain];
		is = [timeLeftLabel contentSize];
		labelPositionTimeLeftIn = ccp (lp.x, lp.y-2);
		labelPositionTimeLeftOut = ccp (labelPositionTimeLeftIn.x, ws.height + is.height);
		[timeLeftLabel setAnchorPoint:ccp (0.0, 1.0)];
		[timeLeftLabel setPosition:labelPositionTimeLeftOut];
		[timeLeftLabel setOpacity:OPACITY];
		[self addChild:timeLeftLabel];
		lp = ccp (lp.x + is.width + SPACE, lp.y);
		
		// moveUpDown icon
		moveUpDownIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_MOVE_UP_DOWN]] retain];
		is = [moveUpDownIcon contentSize];
		iconPositionMoveUpDownIn = ccp (lp.x + SPACE*2, lp.y);
		iconPositionMoveUpDownOut = ccp (iconPositionMoveUpDownIn.x, ws.height + SCALE_Y(is.height));
		[moveUpDownIcon setAnchorPoint:ccp (0.0, 1.0)];
		[moveUpDownIcon setPosition:iconPositionMoveUpDownOut];
		[moveUpDownIcon setOpacity:OPACITY];
		[moveUpDownIcon setScaleX:SCALE_X(1)];
		[moveUpDownIcon setScaleY:SCALE_Y(1)];
		[moveUpDownIcon runAction:[CCRepeatForever actionWithAction:
								   [CCSequence actions:
									[CCTintTo actionWithDuration:0.5 red:0 green:255 blue:0], 
									[CCTintTo actionWithDuration:0.5 red:255 green:255 blue:255], 
									nil]
								   ]
		 ];
		[self addChild:moveUpDownIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE*3, lp.y);
		
		// moveLeftRight icon
		moveLeftRightIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_MOVE_LEFT_RIGHT]] retain];
		is = [moveLeftRightIcon contentSize];
		iconPositionMoveLeftRightIn = ccp (lp.x + SPACE*2, lp.y);
		iconPositionMoveLeftRightOut = ccp (iconPositionMoveLeftRightIn.x, ws.height + SCALE_Y(is.height));
		[moveLeftRightIcon setAnchorPoint:ccp (0.0, 1.0)];
		[moveLeftRightIcon setPosition:iconPositionMoveLeftRightOut];
		[moveLeftRightIcon setOpacity:OPACITY];
		[moveLeftRightIcon setScaleX:SCALE_X(1)];
		[moveLeftRightIcon setScaleY:SCALE_Y(1)];
		[moveLeftRightIcon runAction:[CCRepeatForever actionWithAction:
								   [CCSequence actions:
									[CCTintTo actionWithDuration:0.5 red:0 green:255 blue:0], 
									[CCTintTo actionWithDuration:0.5 red:255 green:255 blue:255], 
									nil]
								   ]
		 ];
		[self addChild:moveLeftRightIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE*3, lp.y);
		
		// turboLeft icon
		turboLeftIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_TURBO_LEFT]] retain];
		is = [turboLeftIcon contentSize];
		iconPositionTurboLeftIn = ccp (lp.x + SPACE*2, lp.y);
		iconPositionTurboLeftOut = ccp (iconPositionTurboLeftIn.x, ws.height + SCALE_Y(is.height));
		[turboLeftIcon setAnchorPoint:ccp (0.0, 1.0)];
		[turboLeftIcon setPosition:iconPositionTurboLeftOut];
		[turboLeftIcon setOpacity:OPACITY];
		[turboLeftIcon setScaleX:SCALE_X(1)];
		[turboLeftIcon setScaleY:SCALE_Y(1)];
		[self addChild:turboLeftIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE*3, lp.y);
		
		// turboLeft label
		turboLeftLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"000" fntFile:fontPathInfo] retain];
		is = [turboLeftLabel contentSize];
		labelPositionTurboLeftIn = ccp (lp.x, lp.y-2);
		labelPositionTurboLeftOut = ccp (labelPositionTurboLeftIn.x, ws.height + is.height);
		[turboLeftLabel setAnchorPoint:ccp (0.0, 1.0)];
		[turboLeftLabel setPosition:labelPositionTurboLeftOut];
		[turboLeftLabel setOpacity:OPACITY];
		[self addChild:turboLeftLabel];
		lp = ccp (lp.x + is.width + SPACE, lp.y);
		
		// heroesLeft icon
		heroesLeftIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_HEROES_LEFT]] retain];
		is = [heroesLeftIcon contentSize];
		iconPositionHeroesLeftIn = ccp (lp.x + SPACE*2, lp.y);
		iconPositionHeroesLeftOut = ccp (iconPositionHeroesLeftIn.x, ws.height + SCALE_Y(is.height));
		[heroesLeftIcon setAnchorPoint:ccp (0.0, 1.0)];
		[heroesLeftIcon setPosition:iconPositionHeroesLeftOut];
		[heroesLeftIcon setOpacity:OPACITY];
		[heroesLeftIcon setScaleX:SCALE_X(1)];
		[heroesLeftIcon setScaleY:SCALE_Y(1)];
		[self addChild:heroesLeftIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE*3, lp.y);
		
		// heroesLeft label
		heroesLeftLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"00" fntFile:fontPathInfo] retain];
		is = [heroesLeftLabel contentSize];
		labelPositionHeroesLeftIn = ccp (lp.x, lp.y-2);
		labelPositionHeroesLeftOut = ccp (labelPositionHeroesLeftIn.x, ws.height + is.height);
		[heroesLeftLabel setAnchorPoint:ccp (0.0, 1.0)];
		[heroesLeftLabel setPosition:labelPositionHeroesLeftOut];
		[heroesLeftLabel setOpacity:OPACITY];
		[self addChild:heroesLeftLabel];
//		lp = ccp (lp.x + is.width + SPACE, lp.y);
		
		// challenge score icon
		challengeScoreIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_SCORE]] retain];
		is = [challengeScoreIcon contentSize];
		lp = ccp (BORDER_X, BORDER_Y);
		iconPositionChallengeScoreIn = ccp (BORDER_X, lp.y);
		iconPositionChallengeScoreOut = ccp (iconPositionChallengeScoreIn.x, -SCALE_Y(is.height));
		[challengeScoreIcon setAnchorPoint:ccp (0.0, 0.0)];
		[challengeScoreIcon setPosition:iconPositionChallengeScoreOut];
		[challengeScoreIcon setOpacity:OPACITY];
		[challengeScoreIcon setScaleX:SCALE_X(1)];
		[challengeScoreIcon setScaleY:SCALE_Y(1)];
		[self addChild:challengeScoreIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE, lp.y);
	
		// challenge score label
		challengeScoreLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"000.000.000" fntFile:fontPathInfo] retain];
		is = [challengeScoreLabel contentSize];
		labelPositionChallengeScoreIn = ccp (lp.x, lp.y-2);
		labelPositionChallengeScoreOut = ccp (labelPositionChallengeScoreIn.x, -is.height);
		[challengeScoreLabel setAnchorPoint:ccp (0.0, 0.0)];
		[challengeScoreLabel setPosition:labelPositionChallengeScoreOut];
		[challengeScoreLabel setOpacity:OPACITY];
		[self addChild:challengeScoreLabel];
		lp = ccp (lp.x + is.width + SPACE, lp.y);

		// challenge time total icon
		challengeTimeTotalIcon = [[CCSprite spriteWithFile:[gameEngine pathForGraphic:ICON_IMG_TIME_TOTAL]] retain];
		is = [challengeTimeTotalIcon contentSize];
		iconPositionChallengeTimeTotalIn = ccp (lp.x + SPACE*2, lp.y);
		iconPositionChallengeTimeTotalOut = ccp (iconPositionChallengeTimeTotalIn.x, -SCALE_Y(is.height));
		[challengeTimeTotalIcon setAnchorPoint:ccp (0.0, 0.0)];
		[challengeTimeTotalIcon setPosition:iconPositionChallengeTimeTotalOut];
		[challengeTimeTotalIcon setOpacity:OPACITY];
		[challengeTimeTotalIcon setScaleX:SCALE_X(1)];
		[challengeTimeTotalIcon setScaleY:SCALE_Y(1)];
		[self addChild:challengeTimeTotalIcon];
		lp = ccp (lp.x + SCALE_X(is.width) + SPACE*3, lp.y);
		
		// challenge time total label
		challengeTimeTotalLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"00:00:00" fntFile:fontPathInfo] retain];		
		is = [challengeTimeTotalLabel contentSize];
		labelPositionChallengeTimeTotalIn = ccp (lp.x, lp.y-2);
		labelPositionChallengeTimeTotalOut = ccp (labelPositionChallengeTimeTotalIn.x, -is.height);
		[challengeTimeTotalLabel setAnchorPoint:ccp (0.0, 0.0)];
		[challengeTimeTotalLabel setPosition:labelPositionChallengeTimeTotalOut];
		[challengeTimeTotalLabel setOpacity:OPACITY];
		[self addChild:challengeTimeTotalLabel];
//		lp = ccp (lp.x + is.width + SPACE, lp.y);

		// timeSuspeded label
		timerLabel = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"00" fntFile:fontPathSuspended] retain];
		[timerLabel setAnchorPoint:ccp (0.5, 0.5)];
		[timerLabel setPosition:ccp(ws.width/2, ws.height/2)];
		[timerLabel setOpacity:OPACITY];
		[timerLabel setVisible:NO];
		[self addChild:timerLabel z:TIME_SUSPENDED_Z];
		
		// zoomingText
		float zty = SCALE_FONT(FONT_SIZE_SUSPENDED_LABEL) * 5;
		
		for (int i=0; i < MAX_ZOOMING_TEXT; i++) {
			zoomingText[i] = [CCBitmapFontAtlas bitmapFontAtlasWithString:@"" fntFile:fontPathSuspended];
			[zoomingText[i] setAnchorPoint:ccp (0.5, 0.5)];
			[zoomingText[i] setPosition:ccp(ws.width/2, ws.height/2 - zty + (i * SCALE_FONT(FONT_SIZE_SUSPENDED_LABEL) * 2))];
			[zoomingText[i] setOpacity:OPACITY];
			[zoomingText[i] setVisible:NO];
			[self addChild:zoomingText[i] z:TIME_SUSPENDED_Z];
		}
		currentZoomingText = 0;
		
		// score formatter
		scoreFormatter = [[NSNumberFormatter alloc] init];
		[scoreFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[scoreFormatter setGroupingSize:3];
		[scoreFormatter setGroupingSeparator:@","];
		[scoreFormatter setPaddingCharacter:@"0"];
		[scoreFormatter setPaddingPosition:NSNumberFormatterPadBeforePrefix];

		// time formatter
		timeFormatter = [[NSDateFormatter alloc] init];
		[timeFormatter setDateFormat:@"HH:MM:SS.FF"];
		
		// defaults
		isTimeLeftPulsing = NO;
		
		[self showPauseButton:NO];
		
		// load progress
		loadProgress = [[CCSprite alloc] init];
		[loadProgress setTexture:nil];
		[loadProgress setTextureRect:CGRectMake (0, 0, 1, LOAD_PROGRESS_HEIGHT)];
		[loadProgress setColor:ccc3(255,255,255)];
		[loadProgress setAnchorPoint:ccp (0.0, 0.5)];
		[loadProgress setPosition:ccp((ws.width - LOAD_PROGRESS_WIDTH)/2, ws.height/2)];
		[loadProgress setOpacity:0];
		[self addChild:loadProgress z:LOAD_PROGRESS_Z];
		
		// load progress label
		loadProgressLabel = [CCLabel labelWithString:@"" 
											   dimensions:CGSizeMake(ws.width - 60, SCALE_FONT(FONT_SIZE_PROGRESS)*3) 
												alignment:UITextAlignmentCenter 
												 fontName:UI_FONT_DEFAULT 
												 fontSize:SCALE_FONT(FONT_SIZE_PROGRESS)
								  ];
		[loadProgressLabel.texture setAliasTexParameters];
		[loadProgressLabel setColor:ccc3(255,255,255)];
		[loadProgressLabel setAnchorPoint:ccp (0.5, 0.5)];
		[loadProgressLabel setPosition:ccp(ws.width/2, loadProgress.position.y + LOAD_PROGRESS_HEIGHT/2 + SCALE_Y(20) + SCALE_FONT(FONT_SIZE_PROGRESS)*2)];
		[loadProgressLabel setOpacity:0];
		[loadProgressLabel setVisible:NO];
		[self addChild:loadProgressLabel z:LOAD_PROGRESS_Z];
		
		// load progress proverbs 
		loadProgressProverbs = [CCLabel labelWithString:@"" 
										  dimensions:CGSizeMake(ws.width - 60, SCALE_FONT(FONT_SIZE_PROVERBS)*3) 
										   alignment:UITextAlignmentCenter 
											fontName:UI_FONT_DEFAULT 
											fontSize:SCALE_FONT(FONT_SIZE_PROVERBS)
							 ];
		[loadProgressProverbs.texture setAliasTexParameters];
		[loadProgressProverbs setColor:ccc3(255,0,0)];
		[loadProgressProverbs setAnchorPoint:ccp (0.5, 0.5)];
		[loadProgressProverbs setPosition:ccp(ws.width/2, loadProgress.position.y - LOAD_PROGRESS_HEIGHT/2 - SCALE_Y(20) - SCALE_FONT(FONT_SIZE_PROVERBS)*2)];
		[loadProgressProverbs setOpacity:0];
		[loadProgressProverbs setVisible:NO];
		[self addChild:loadProgressProverbs z:LOAD_PROGRESS_Z];
		
		// load progress background
		loadProgressBackground = [CCColorLayer layerWithColor:ccc4(0, 0, 0, 0)];
		[loadProgressBackground setAnchorPoint:ccp (0, 0)];
		[loadProgressBackground setPosition:ccp (0, 0)];
		[self addChild:loadProgressBackground z:LOAD_PROGRESS_Z-1];
	
		[self initPauseEmitter];
		
		// game over panel 
		
		gameOver = [[KKHUDGameOverLayer alloc] initGameOverLayer];
		[self addChild:gameOver z:LOAD_PROGRESS_Z-10];
		
		// preload data
		[self preloadMessageFonts];		
	}
	return self;
}

-(void) dealloc
{
	REMOVE_SHARED_OBJECT (@"hudLayer");

	[pauseButton release];

	[scoreIcon release];
	[scoreLabel release];
	[timeTotalIcon release];
	[timeTotalLabel release];
	[timeLeftIcon release];
	[timeLeftLabel release];
	
	[moveUpDownIcon release];
	[moveLeftRightIcon release];
	
	[turboLeftIcon release];
	[turboLeftLabel release];
	
	[heroesLeftIcon release];
	[heroesLeftLabel release];
	
	[challengeScoreIcon release];
	[challengeScoreLabel release];
	[challengeTimeTotalIcon release];
	[challengeTimeTotalLabel release];
	
	[timerLabel release];
	
	[scoreFormatter release];
	[timeFormatter release];
	
	[pauseEmitter release];

	[super dealloc];
}

-(NSNumberFormatter *) scoreFormatter
{
	return scoreFormatter;
}

-(NSDateFormatter *) timeFormatter
{
	return timeFormatter;
}

-(void) onEnter
{
	[super onEnter];
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:INPUT_PRIORITY swallowsTouches:YES];
}

-(void) onExit
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super onExit];
}

#pragma mark -
#pragma mark Store

-(void) showStoreBackground:(BOOL)f
{
	if (f && storeBackground == nil) {
		[KKIM setInputActive:NO];
		storeBackground = [CCColorLayer layerWithColor:ccc4 (0,0,0,200)];
		[self addChild:storeBackground z:STORE_BACKGROUND_Z];
		CCLabel *l = [CCLabel labelWithString:@"PURCHASE IN PROGRESS...WAIT" fontName:UI_FONT_DEFAULT fontSize:32];
		[l setColor:ccc3(255,255,255)];
		[l setAnchorPoint:ccp(0,0)];
		[l setPosition:ccp(50,50)];
		[l runAction:[CCRepeatForever actionWithAction:[CCSequence actions:
														[CCMoveBy actionWithDuration:5.0 position:ccp(0,200)],
														[CCMoveBy actionWithDuration:5.0 position:ccp(0,-200)],
														nil
														]
					  ]
		 ];
		[storeBackground addChild:l];
	} else if (!f && storeBackground != nil) {
		[KKIM setInputActive:YES];
		[self removeChild:storeBackground cleanup:YES];
		storeBackground = nil;
	}
}

#pragma mark -
#pragma mark Event handlers

-(void) onPause:(id)sender
{
	if ([gameEngine paused]) {
		[self onResume:sender];
	} else {
		[gameEngine onPause];	
		[self showPauseDialog:YES];
	}
}

-(void) onResume:(id)sender
{
	[gameEngine onResume];
	[self showPauseDialog:NO];
}

-(void) onQuit:(id)sender
{
	[gameEngine onQuit];
	[self showPauseDialog:NO];
}

-(void) onOpenFeint:(id)sender
{
//	[KKOFM launchDashboard];
}

-(void) onNextLevel:(id)sender
{
	[self hideLevelScorePanel];
}

-(void) onMainMenu:(id)sender
{
	if (menuState == kMenuStateScore) {
		[self hideLevelScorePanelUI];
	} else {
		[mainMenuButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionMainMenuOut] visible:NO]];
		[openFeintButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionOpenFeintOut] visible:NO]];
	}
	
	[gameEngine onQuit];

	if (gameEnd) {
		[gameEnd hide];
		[self removeChild:gameEnd cleanup:YES];
		[gameEnd release];
		gameEnd = nil;
	} else {
		[gameOver hide];
	}
}


#pragma mark -
#pragma mark Timers

-(void) startTimers:(BOOL)f
{
	
}

-(void) updateTimers:(ccTime)dt
{
	
}

#pragma mark -
#pragma mark Update

-(void) update:(ccTime)dt
{
	for (int i = 0; i < MAX_MESSAGES; i++) {
		if (messages[i] != nil) {
			KKHUDMessage *msg = messages[i];
			if (msg.duration == HUD_MESSAGE_INFINITE_DURATION) continue;
			msg.duration -= dt;
			if (msg.duration <= 0) {
				[self removeMessage:msg];
			}
		}
	}
}

#pragma mark -
#pragma mark Visibility

-(void) setShown:(BOOL)f
{
	if (shown == f) return;
	
	shown = f;
}

-(void) enableEmitter:(BOOL)f
{
	KKLOG (@"enable: %d", f);
	if (f) {
		[pauseEmitter resetSystem];
		[pauseEmitter scheduleUpdateWithPriority:1];
	} else {
		[pauseEmitter stopSystem];
		[pauseEmitter unscheduleUpdate];
	}
	[pauseEmitter setVisible:f];
}

-(void) initPauseEmitter
{
	pauseEmitter = [[CCQuadParticleSystem alloc] initWithTotalParticles:200];
	[loadProgressBackground addChild:pauseEmitter z:1];
	[pauseEmitter setVisible:NO];
	
	CGSize ws = [[CCDirector sharedDirector] winSize];

	// duration
	pauseEmitter.duration = -1;
	
	// gravity
	pauseEmitter.gravity = ccp (0, 10);
	
	// angle
	pauseEmitter.angle = 90;
	pauseEmitter.angleVar = 5;
	
	// speed of particles
	pauseEmitter.speed = 10;
	pauseEmitter.speedVar = 20;
	
	// radial
	pauseEmitter.radialAccel = 0;
	pauseEmitter.radialAccelVar = 1;
	
	// tagential
	pauseEmitter.tangentialAccel = 0;
	pauseEmitter.tangentialAccelVar = 1;
	
	// emitter position
	pauseEmitter.position = ccp (0, -10);
	pauseEmitter.posVar = ccp(ws.width, 0);
	
	// life of particles
	pauseEmitter.life = 5;
	pauseEmitter.lifeVar = 1;
	
	// size, in pixels
	pauseEmitter.startSize = SCALE_X(10.0f);
	pauseEmitter.startSizeVar = SCALE_X(10.0f);
	pauseEmitter.endSize = SCALE_X(56.0f);
	pauseEmitter.endSizeVar = SCALE_X(8.0f);
	
	// emits per second
	pauseEmitter.emissionRate = pauseEmitter.totalParticles/pauseEmitter.life;
	
	// color of particles
	pauseEmitter.startColor = (ccColor4F){0.6f,0.6f,0.6f,0.3f};
	pauseEmitter.startColorVar = (ccColor4F){0.0f,0.0f,0.0f,0.1f};
	pauseEmitter.endColor = (ccColor4F){0.0f,0.0f,0.0f,0.0f};
	pauseEmitter.endColorVar = (ccColor4F){0.0f,0.0f,0.0f,0.0f};
	
	// additive
	pauseEmitter.blendAdditive = NO;
	
	[self enableEmitter:NO];
}

-(CCAction *) actionShowAndAction:(CCAction *)action
{
	return [CCSequence actions:[CCShow action], action, nil];
}

-(id) actionActionAndHide:(id)action
{
	return [CCSequence actions:action, [CCHide action], nil];
}

-(id) action:(id)action visible:(BOOL)f
{
	if (f) {
		return [self actionShowAndAction:action];
	} else {
		return [self actionActionAndHide:action];
	}
}

-(void) showDialogBackground:(BOOL)f withOpacity:(int)o
{
	if (o == -1) {
		if (f) {
			o = PAUSE_DIALOG_OPACITY;
		} else {
			o = 0;
		}
	}
	
	[self stopActionByTag:kHLActionFadeTo];
	CCAction *fa = [CCFadeTo actionWithDuration:SHOW_DURATION opacity:o];
	fa.tag = kHLActionFadeTo;
	[self runAction:fa];
}

-(void) showPauseDialog:(BOOL)f
{
	CGPoint pResume;
	CGPoint pQuit;
	CGPoint pOpenFeint;
	
	if (f) {
		menuState = kMenuStatePause;
		pResume = buttonPositionResumeIn;
		pQuit = buttonPositionQuitIn;
		pOpenFeint = buttonPositionOpenFeintIn;
	} else {
		menuState = kMenuStateNone;
		pResume = buttonPositionResumeOut;
		pQuit = buttonPositionQuitOut;
		pOpenFeint = buttonPositionOpenFeintOut;
	}
	
	[self showDialogBackground:f withOpacity:-1];
	
	[resumeButton stopActionByTag:kHLActionMoveTo];
	CCAction *ra = [self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:pResume] visible:f];
	ra.tag = kHLActionMoveTo;
	[resumeButton runAction:ra];

	[quitButton stopActionByTag:kHLActionMoveTo];
	CCAction *qa = [self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:pQuit] visible:f];
	qa.tag = kHLActionMoveTo;
	[quitButton runAction:qa];
	
	[openFeintButton stopActionByTag:kHLActionMoveTo];
	CCAction *oa = [self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:pOpenFeint] visible:f];
	oa.tag = kHLActionMoveTo;
	[openFeintButton runAction:oa];
}

#define SHOW_UI(__F__,__EI__,__EL__,__II__,__IO__,__LI__,__LO__) \
CGPoint ip; \
CGPoint lp; \
\
if (__F__) {ip = __II__; lp = __LI__;} \
else {ip = __IO__; lp = __IO__;} \
\
[__EI__ stopActionByTag:kHLActionMoveTo]; \
[__EL__ stopActionByTag:kHLActionMoveTo]; \
CCAction *ia = [self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:ip] visible:__F__]; \
ia.tag = kHLActionMoveTo; \
CCAction *la = [self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:lp] visible:__F__]; \
la.tag = kHLActionMoveTo; \
[__EI__ runAction:ia]; \
[__EL__ runAction:la];	

-(void) showPauseButton:(BOOL)f
{
	CGPoint p;
	
	if (f) {
		p = buttonPositionPauseIn;
	} else {
		p = buttonPositionPauseOut;
	}
	[pauseButton stopActionByTag:kHLActionMoveTo];
	CCAction *a = [self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:p] visible:f];
	a.tag = kHLActionMoveTo;
	[pauseButton runAction:a];
}

-(void) showScore:(BOOL)f
{
	SHOW_UI(f,scoreIcon,scoreLabel,iconPositionScoreIn,iconPositionScoreOut,labelPositionScoreIn,labelPositionScoreOut)
}

-(void) showTimeTotal:(BOOL)f
{
	SHOW_UI(f,timeTotalIcon,timeTotalLabel,iconPositionTimeTotalIn,iconPositionTimeTotalOut,labelPositionTimeTotalIn,labelPositionTimeTotalOut)
}

-(void) showTimeLeft:(BOOL)f
{
	SHOW_UI(f,timeLeftIcon,timeLeftLabel,iconPositionTimeLeftIn,iconPositionTimeLeftOut,labelPositionTimeLeftIn,labelPositionTimeLeftOut)
}

-(void) showMoveUpDown:(BOOL)f
{
	CGPoint p;

	if (f) p = iconPositionMoveUpDownIn;
	else p = iconPositionMoveUpDownOut;

	[moveUpDownIcon stopActionByTag:kHLActionMoveTo];
	CCAction *a = [CCMoveTo actionWithDuration:SHOW_DURATION position:p];
	a.tag = kHLActionMoveTo;
	[moveUpDownIcon runAction:a];
}

-(void) showMoveLeftRight:(BOOL)f
{
	CGPoint p;
	
	if (f) p = iconPositionMoveLeftRightIn;
	else p = iconPositionMoveLeftRightOut;
	
	[moveLeftRightIcon stopActionByTag:kHLActionMoveTo];
	CCAction *a = [CCMoveTo actionWithDuration:SHOW_DURATION position:p];
	a.tag = kHLActionMoveTo;
	[moveLeftRightIcon runAction:a];
}

-(void) showTurboLeft:(BOOL)f
{
	SHOW_UI(f,turboLeftIcon,turboLeftLabel,iconPositionTurboLeftIn,iconPositionTurboLeftOut,labelPositionTurboLeftIn,labelPositionTurboLeftOut)
}

-(void) showHeroesLeft:(BOOL)f
{
	SHOW_UI(f,heroesLeftIcon,heroesLeftLabel,iconPositionHeroesLeftIn,iconPositionHeroesLeftOut,labelPositionHeroesLeftIn,labelPositionHeroesLeftOut)
}

-(void) showChallengeScore:(BOOL)f
{
	SHOW_UI(f,challengeScoreIcon,challengeScoreLabel,iconPositionChallengeScoreIn,iconPositionChallengeScoreOut,labelPositionChallengeScoreIn,labelPositionChallengeScoreOut)
}

-(void) showChallengeTimeTotal:(BOOL)f
{
	SHOW_UI(f,challengeTimeTotalIcon,challengeTimeTotalLabel,iconPositionChallengeTimeTotalIn,iconPositionChallengeTimeTotalOut,labelPositionChallengeTimeTotalIn,labelPositionChallengeTimeTotalOut)
}

#pragma mark -
#pragma mark Setters

-(NSString *) secondsToStringHMS:(int)t
{
	int h = t / 3600;
	t = t % 3600;
	int m = t / 60;
	t = t % 60;
	int s = t;
	return [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
}

-(NSString *) secondsToStringMS:(int)t
{
	t = t % 3600;
	int m = t / 60;
	t = t % 60;
	int s = t;
	return [NSString stringWithFormat:@"%02d:%02d", m, s];
}

-(void) setScore:(int)score
{
	[scoreLabel setString:[scoreFormatter stringFromNumber:[NSNumber numberWithInt:score]]];
}

-(void) setTimeTotal:(float)t
{
	[timeTotalLabel setString:[self secondsToStringHMS:t]];
}

-(CCAction *) pulseActionWithDuration:(float)duration fromColor:(ccColor3B)c1 toColor:(ccColor3B)c2
{
	CCAction *action = [CCRepeatForever actionWithAction:
						[CCSequence actions:
						 [CCTintTo actionWithDuration:duration red:c1.r green:c1.g blue:c1.b],
						 [CCTintTo actionWithDuration:duration red:c2.r green:c2.g blue:c2.b],
						 nil]];
	return action;
}

#define ALERT_TIME_LEFT 11
-(void) setTimeLeft:(float)t
{
	if (t < 0) t = 0;
	
	if (t <= ALERT_TIME_LEFT && t >= 0) {
		if (!isTimeLeftPulsing) {
			CCAction *action = [self pulseActionWithDuration:0.3 fromColor:ccc3(255,255,255) toColor:ccc3(255,0,0)];
			action.tag = kHLPulse;
			[timeLeftLabel runAction:action];
			isTimeLeftPulsing = YES;
		}
		if (isTimeNotificationEnabled)
			[self showTimerLabel:[NSString stringWithFormat:@"%d", (int)t] sound:SOUND_TIMER_TICK_3];
	} else {
		if (isTimeLeftPulsing) {
			[timeLeftLabel stopActionByTag:kHLPulse];
			[timeLeftLabel setColor:ccc3(255, 255, 255)];
			isTimeLeftPulsing = NO;
		}
	}
	[timeLeftLabel setString:[self secondsToStringMS:t]];
}

-(void) setTurboLeft:(int)c
{
	[turboLeftLabel setString:[NSString stringWithFormat:@"%d", c]];
}

-(void) setHeroesLeft:(int)c
{
	[heroesLeftLabel setString:[NSString stringWithFormat:@"%d", c]];
}

-(void) setChallengeScore:(int)score
{
	[challengeScoreLabel setString:[scoreFormatter stringFromNumber:[NSNumber numberWithInt:score]]];
}

-(void) setChallengeTimeTotal:(float)t
{
	[challengeTimeTotalLabel setString:[self secondsToStringHMS:t]];	
}

-(void) startSuspendedTimeout:(float)t
{
	
}

#pragma mark -
#pragma mark Start Timer

#define TIMER_LABEL_SCALE_DURATION1 0.4
#define TIMER_LABEL_SCALE1 (1.0 * 5)
#define TIMER_LABEL_SCALE_DURATION2 0.4
#define TIMER_LABEL_SCALE2 (1.7 * 5)
#define TIMER_LABEL_SCALE_DURATION3 0.2
#define TIMER_LABEL_SCALE3 (2.0 * 5)

#define TIMER_LABEL_OPACITY 200

-(void) showTimerLabel:(int)n
{
	[self showTimerLabel:[NSString stringWithFormat:@"%d", n] sound:SOUND_TIMER_TICK_1];
}

-(void) showTimerLabel:(NSString*)s sound:(NSString*)sound
{
	[timerLabel setString:s];
	[timerLabel setScale:0];
	
	CCAction *action = [CCSequence actions:
						[CCShow action],
						[CCSpawn actions:
						 [CCScaleTo actionWithDuration:TIMER_LABEL_SCALE_DURATION1 scale:TIMER_LABEL_SCALE1],
						 [CCFadeTo actionWithDuration:TIMER_LABEL_SCALE_DURATION1 opacity:TIMER_LABEL_OPACITY],
						 nil
						 ],
						[CCScaleTo actionWithDuration:TIMER_LABEL_SCALE_DURATION2 scale:TIMER_LABEL_SCALE2],
						[CCSpawn actions:
						 [CCScaleTo actionWithDuration:TIMER_LABEL_SCALE_DURATION3 scale:TIMER_LABEL_SCALE3],
						 [CCFadeTo actionWithDuration:TIMER_LABEL_SCALE_DURATION3 opacity:0],
						 nil
						 ],
						[CCHide action],
						nil];
	
	action.tag = kHLTimerLabel;
	[timerLabel stopActionByTag:kHLTimerLabel];
	[timerLabel runAction:action];
	
	[gameEngine playSound:sound];
}

-(void) updateStartTimer
{
	[self showTimerLabel:startTimerTimout];
	startTimerTimout--;
}

-(void) performStartTimerCallback
{
	if (startTimerTarget && startTimerSelector) {
		[startTimerTarget performSelector:startTimerSelector];
	}
}

-(void) showStartTimer:(int)seconds target:(id)target selector:(SEL)selector
{	
	[self stopStartTimer];
	
	[timerLabel setVisible:YES];
	[timerLabel setOpacity:0];
	
	startTimerTimout = seconds;
	startTimerTarget = target;
	startTimerSelector = selector;
	
	CCAction *action = [CCSequence actions:
						[CCRepeat actionWithAction:[CCSequence actions:
													[CCCallFunc actionWithTarget:self selector:@selector(updateStartTimer)],
													[CCDelayTime actionWithDuration:1.0],
													nil
													]
											 times: seconds
						 ], 
						[CCCallFunc actionWithTarget:self selector:@selector(performStartTimerCallback)],
						nil];
	
	action.tag = kHLStartTimer;

	[self runAction:action];
	
	[self stopActionByTag:kHLActionFadeTo];
	[self setOpacity:255];
	CCAction *fa = [CCFadeTo actionWithDuration:seconds opacity:0];
	fa.tag = kHLActionFadeTo;
	[self runAction:fa];
}

-(void) stopStartTimer
{
	[self stopActionByTag:kHLStartTimer];
}

#pragma mark -
#pragma mark Input

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	BOOL f = NO;
	
	if ([gameEngine paused]) {
		f = YES;
	}
	return f;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
}

#pragma mark -
#pragma mark Zooming Text

#define ZOOMING_TEXT_SCALE_DURATION1 0.4
#define ZOOMING_TEXT_SCALE1 (1.0 * 8)
#define ZOOMING_TEXT_SCALE_DURATION2 0.4
#define ZOOMING_TEXT_SCALE2 (1.7 * 8)
#define ZOOMING_TEXT_SCALE_DURATION3 0.2
#define ZOOMING_TEXT_SCALE3 (2.0 * 8)

#define ZOOMING_TEXT_OPACITY 200

-(void) showZoomingText:(NSString*)s sound:(NSString*)sound;
{
	CCBitmapFontAtlas *l = zoomingText[currentZoomingText];

	currentZoomingText++;
	if (currentZoomingText >= MAX_ZOOMING_TEXT) {
		currentZoomingText = 0;
	}
	
	[l setString:s];
	[l setScale:0];
	
	CCAction *action = [CCSequence actions:
						[CCShow action],
						[CCSpawn actions:
						 [CCScaleTo actionWithDuration:ZOOMING_TEXT_SCALE_DURATION1 scale:ZOOMING_TEXT_SCALE1],
						 [CCFadeTo actionWithDuration:ZOOMING_TEXT_SCALE_DURATION1 opacity:ZOOMING_TEXT_OPACITY],
						 nil
						 ],
						[CCScaleTo actionWithDuration:ZOOMING_TEXT_SCALE_DURATION2 scale:ZOOMING_TEXT_SCALE2],
						[CCSpawn actions:
						 [CCScaleTo actionWithDuration:ZOOMING_TEXT_SCALE_DURATION3 scale:ZOOMING_TEXT_SCALE3],
						 [CCFadeTo actionWithDuration:ZOOMING_TEXT_SCALE_DURATION3 opacity:0],
						 nil
						 ],
						[CCHide action],
						nil];
	
	action.tag = kHLZoomingText;
	[l stopActionByTag:action.tag];
	[l runAction:action];
	
	[gameEngine playSound:sound];
}


#pragma mark -
#pragma mark Messages

-(void) preloadMessageFonts
{
	[[FontManager sharedManager] zFontWithName:UI_FONT_DEFAULT pointSize:HUD_MESSAGE_FONT_SIZE];
}

-(CGPoint) messageAnchorPoint:(CGPoint)p
{
	return ccp (0.5, 0.5);
}

-(CGPoint) resetMessagePositions
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	CGPoint sp = ccp (ws.width/2, SCALE_Y(MESSAGE_TOP_BORDER));
	for (int i = MAX_MESSAGES-1; i >= 0; i--) {
		KKHUDMessage *msg = messages[i];
		if (msg != nil) {
			[msg stopActionByTag:kHLActionMoveTo];
			CCAction *a = [CCMoveTo actionWithDuration:MESSAGE_MOVE_DURATION position:sp];
			a.tag = kHLActionMoveTo;
			[msg runAction:a];
			sp = ccp (sp.x, sp.y + MESSAGE_MID_BORDER + [messages[i] contentSize].height);
		}
	}
	return sp;
}

-(void) hideMessage:(id)target index:(int *)idx
{
	[messages[*idx] setShown:NO];
}

-(void) removeMessage:(id)target msg:(KKHUDMessage *)msg
{
	[self removeChild:msg cleanup:YES];
	[self resetMessagePositions];
}

-(void) addMessage:(id)target msg:(KKHUDMessage *)msg
{
	CGPoint p = [self resetMessagePositions];
	msg.position = p;
	messages[msg.index] = msg;
	[self addChild:msg z:MESSAGE_Z];
	[msg setShown:YES];
}

-(void) removeMessage:(KKHUDMessage *)remove andAdd:(KKHUDMessage *)msg
{
	messages[remove.index] = nil;
	[remove setShown:NO];
	CCAction *a = [CCSequence actions:
				   [CCDelayTime actionWithDuration:HUD_MESSAGE_SHOW_DURATION + 0.2],
				   [CCCallFuncND actionWithTarget:self selector:@selector(removeMessage:msg:) data:remove],
				   [CCCallFuncND actionWithTarget:self selector:@selector(addMessage:msg:) data:msg],
				   nil];
	[self runAction:a];
}

-(void) removeMessage:(KKHUDMessage *)msg
{
	messages[msg.index] = nil;
	[msg setShown:NO];
	CCAction *a = [CCSequence actions:
				   [CCDelayTime actionWithDuration:HUD_MESSAGE_SHOW_DURATION + 0.2],
				   [CCCallFuncND actionWithTarget:self selector:@selector(removeMessage:msg:) data:msg],
				   nil];
	[self runAction:a];
}

-(void) removeMessageWithIndex:(int)idx
{
	[self removeMessage:messages[idx]];
}

-(void) removeAllMessages
{
	for (int i = 0; i < MAX_MESSAGES; i++) {
		if (messages[i] != nil) {
			[messages[i] setShown:NO];
			[self removeMessage:messages[i]];
		}
	}
}

-(void) destroyAllMessages
{
	for (int i = 0; i < MAX_MESSAGES; i++) {
		KKHUDMessage *msg = messages[i];
		messages[i] = nil;
		if (msg != nil) {
			[msg stopAllActions];
			[self removeChild:msg cleanup:YES];
		}
	}
	
	for (id child in [NSArray arrayWithArray:self.children]) {
		if ([child isKindOfClass:[KKHUDMessage class]]) {
			[child stopAllActions];
			[self removeChild:child cleanup:YES];
		}
	}
}

-(int) addMessage:(KKHUDMessage *)msg
{
	int idx = -1;
	KKHUDMessage *remove = nil;
	
	for (int i = 0; i < MAX_MESSAGES; i++) {
		if (messages[i] == nil) {
			idx = i;
			break;
		}
	}
	
	if (idx == -1) {
		int d = MAX_INT;
		for (int i = 0; i < MAX_MESSAGES; i++) {
			if (messages[i].duration >= 0 && messages[i].duration < d) {
				d = messages[i].duration;
				idx = i;
			}
		}
		remove = messages[idx];
		messages[idx] = nil;
	}
	
	CGPoint sp = [self resetMessagePositions];
	msg.index = idx;
	[msg setPosition:sp];
	
	if (remove)
		[self removeMessage:remove andAdd:msg];
	else
		[self addMessage:self msg:msg];
	return idx;
}

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn entity:(id<KKEntityProtocol>)entity
{
	return [self showMessage:msg emoticon:icn entity:entity bgColor:HUD_MESSAGE_BG_COLOR msgColor:HUD_MESSAGE_COLOR icnColor:HUD_MESSAGE_EMOTICON_COLOR fontSize:HUD_MESSAGE_FONT_SIZE duration:HUD_MESSAGE_INFINITE_DURATION]; 
}

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn entity:(id<KKEntityProtocol>)entity duration:(float)seconds
{
	return [self showMessage:msg emoticon:icn entity:entity bgColor:HUD_MESSAGE_BG_COLOR msgColor:HUD_MESSAGE_COLOR icnColor:HUD_MESSAGE_EMOTICON_COLOR fontSize:HUD_MESSAGE_FONT_SIZE duration:seconds]; 
}

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn entity:(id<KKEntityProtocol>)entity bgColor:(ccColor3B)bgc msgColor:(ccColor3B)msgc icnColor:(ccColor3B)icnc fontSize:(CGFloat)pointSize duration:(float)seconds
{
	KKHUDMessage *m = [[[KKHUDMessage alloc] initWithMessage:msg emoticon:icn fontSize:pointSize kind:kHUDMessageKindSay duration:seconds] autorelease];

	[m setBackgroundColor:bgc];
	[m setLabelColor:msgc];
	[m setEmoticonColor:icnc];
	
	[m setSourceEntity:entity];
	[m setAnchorPoint:[self messageAnchorPoint:[entity centerPositionToDisplay]]];

	return [self addMessage:m];
}

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn origin:(CGPoint)origin
{
	return [self showMessage:msg emoticon:icn origin:origin bgColor:HUD_MESSAGE_BG_COLOR msgColor:HUD_MESSAGE_COLOR icnColor:HUD_MESSAGE_EMOTICON_COLOR fontSize:HUD_MESSAGE_FONT_SIZE duration:HUD_MESSAGE_INFINITE_DURATION]; 
}

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn origin:(CGPoint)origin duration:(float)seconds
{
	return [self showMessage:msg emoticon:icn origin:origin bgColor:HUD_MESSAGE_BG_COLOR msgColor:HUD_MESSAGE_COLOR icnColor:HUD_MESSAGE_EMOTICON_COLOR fontSize:HUD_MESSAGE_FONT_SIZE duration:seconds]; 
}

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn origin:(CGPoint)origin bgColor:(ccColor3B)bgc msgColor:(ccColor3B)msgc icnColor:(ccColor3B)icnc fontSize:(CGFloat)pointSize duration:(float)seconds
{
	KKHUDMessage *m = [[[KKHUDMessage alloc] initWithMessage:msg emoticon:icn fontSize:pointSize kind:kHUDMessageKindSay duration:seconds] autorelease];
	
	[m setBackgroundColor:bgc];
	[m setLabelColor:msgc];
	[m setEmoticonColor:icnc];
	
	[m setSourceOrigin:origin];
	[m setAnchorPoint:[self messageAnchorPoint:origin]];

	return [self addMessage:m];
}

#pragma mark -
#pragma mark Load Progress
					
#define LOAD_PROGRESS_OPACITY 255

-(void) showLoadProgressBackground:(BOOL)f
{
	int o;
	if (f) {
		o = LOAD_PROGRESS_OPACITY;
	} else {
		o = 0;
	}
	
	CCAction *fa = [self action:[CCFadeTo actionWithDuration:LOAD_PROGRESS_DURATION opacity:o] visible:f];
	fa.tag = kHLActionFadeTo;
	[loadProgressBackground stopActionByTag:kHLActionFadeTo];
	[loadProgressBackground runAction:fa];
}

-(void) showLoadProgress:(BOOL)f withMessage:(NSString *)msg
{
	int o;
	
	loadProgressWidth = 0;

	[self showLoadProgressBackground:f];
	
	[loadProgressProverbs stopActionByTag:kHLActionChangeProverb];
	[loadProgressProverbs stopActionByTag:kHLActionFadeTo];
	
	if (f) {
		o = LOAD_PROGRESS_OPACITY;
		[loadProgress setScaleX:0];
		loadProgressSoundLoopID = [gameEngine playSoundLoop:SOUND_LOAD_PROGRESS_LOOP];
		loadProgressProverbs.opacity = 0;
		loadProgressProverbs.visible = YES;
	} else {
		o = 0;
		[gameEngine stopSound:loadProgressSoundLoopID];
	}

	CCAction *lpa = [self action:[CCFadeTo actionWithDuration:LOAD_PROGRESS_DURATION opacity:o] visible:f];
	lpa.tag = kHLActionFadeTo;
	
	CCAction *lla = [self action:[CCFadeTo actionWithDuration:LOAD_PROGRESS_DURATION opacity:o] visible:f];
	lla.tag = kHLActionFadeTo;
	
	if (f) {
		CCAction *cpa = [CCRepeatForever actionWithAction:[CCSequence actions:
														   [CCFadeTo actionWithDuration:0.5 opacity:0],
														   [CCCallFunc actionWithTarget:self selector:@selector(changeProverb)],
														   [CCFadeTo actionWithDuration:0.5 opacity:LOAD_PROGRESS_OPACITY],
														   [CCDelayTime actionWithDuration:5],
														   nil
														   ]
						 ];
		CCAction *cca = [CCRepeatForever actionWithAction:[CCSequence actions:
														   [CCTintTo actionWithDuration:1.0 red:255 green:0 blue:255],
														   [CCTintTo actionWithDuration:1.0 red:255 green:0 blue:0],
														   nil
														   ]
						 ];
		cpa.tag = kHLActionChangeProverb;
		cca.tag = kHLActionChangeProverb;
		[loadProgressProverbs runAction:cpa];
		[loadProgressProverbs runAction:cca];
	} else {
		[loadProgressProverbs runAction:[[lla copy] autorelease]];
	}
	
	[loadProgress stopActionByTag:kHLActionFadeTo];
	[loadProgressLabel stopActionByTag:kHLActionFadeTo];
	
	[loadProgress runAction:lpa];
	[loadProgressLabel runAction:lla];
	
	[loadProgressLabel setString:NSLocalizedString (msg, @"loadProgress")];
	
	[self enableEmitter:f];
}

-(void) changeProverb
{
	[loadProgressProverbs setString:[gameEngine randomMessage]];
}

-(void) loadProgressAdd:(float)v withMessage:(NSString *)msg
{
	loadProgressWidth += (LOAD_PROGRESS_WIDTH * v);
	
//	KKLOG (@"w=%f v=%f %@", loadProgressWidth,  v,msg);
	if (loadProgressWidth < 0) loadProgressWidth = 0;
	else if (loadProgressWidth > LOAD_PROGRESS_WIDTH) loadProgressWidth = LOAD_PROGRESS_WIDTH;
	
	[loadProgress setScaleX:loadProgressWidth];
	[loadProgressLabel setString:NSLocalizedString (msg, @"loadProgress")];
}

-(void) loadProgressEndWithMessage:(NSString *)msg
{
	[loadProgress setScaleX:LOAD_PROGRESS_WIDTH];
	[loadProgressLabel setString:NSLocalizedString (msg, @"loadProgress")];
}
										   
#pragma mark -
#pragma mark Level Score Panel

#define FONT_SIZE_SCORE_PANEL_MESSAGE 32
#define FONT_SIZE_SCORE_PANEL_LABEL 22
#define SCORE_PANEL_TOP_MARGIN 64

-(KKHUDButtonLabel *) newScorePanelLabelLeft:(BOOL)left label:(NSString*)label y:(float)y
{
	KKHUDButtonLabel *sb = [[KKHUDButtonLabel alloc] initWithString:NSLocalizedString (label, @"scorePanelLabel")
														   withSize:FONT_SIZE_SCORE_PANEL_LABEL
															 target:nil
														   selector:nil
							];
	CGPoint p;
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	if (left) {
		p = ccp (-BUTTONS_PADDING, y);
		[sb setAnchorPoint:ccp (1, 1)];
	} else {
		p = ccp (ws.width + BUTTONS_PADDING, y);
		[sb setAnchorPoint:ccp (0, 1)];
	}
	[sb setPosition:p];
	[sb setOpacity:BUTTON_DIALOG_OPACITY];
	
	return sb;
}

-(void) showLevelScorePanelWithDelay:(float)seconds message:(NSString*)msg acNum:(int)acNum acTot:(int)acTot acScore:(int)acScore bonusScore:(int)bonusScore nextLevel:(NSString*)nextLevel
{
	gameEngine.currentGameState = kGSInGamePause;

	lspMessage = [msg retain];
	lspACNum = acNum;
	lspACTot = acTot;
	lspACScore = acScore;
	lspBonusScore = bonusScore;
	lspNextLevel = [nextLevel retain];
	
	[self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:seconds], [CCCallFunc actionWithTarget:self selector:@selector(showLevelScorePanel)], nil]];
}

-(void) showLevelScorePanel
{
	menuState = kMenuStateScore;

	[gameEngine startBackgroundMusic:MUSIC_SCORE_PANEL];
	[gameEngine showHUD:NO];
	gameEngine.updateLevelTimeLeft = NO;
	
	[self showDialogBackground:YES withOpacity:-1];
	
	CGSize ws = [[CCDirector sharedDirector] winSize];
	float y = ws.height - SCALE_Y(SCORE_PANEL_TOP_MARGIN);
	int c = 0;

	levelScorePanelMessage = [CCLabel labelWithString:NSLocalizedString(lspMessage, @"levelScoreMessage") 
										   dimensions:CGSizeZero 
											alignment:UITextAlignmentCenter 
											 fontName:UI_FONT_DEFAULT 
											 fontSize:SCALE_FONT(FONT_SIZE_SCORE_PANEL_MESSAGE)
							  ];
	[levelScorePanelMessage.texture setAliasTexParameters];
	[levelScorePanelMessage setPosition:ccp (ws.width/2, ws.height + [levelScorePanelMessage contentSize].height/2 + BUTTONS_PADDING)];
	[levelScorePanelMessage setColor:ccc3(255, 255, 255)];
	[levelScorePanelMessage setOpacity:255];
	[self addChild:levelScorePanelMessage z:MENU_PRIORITY - 10];
	[levelScorePanelMessage runAction:[CCMoveTo actionWithDuration:SHOW_DURATION position:ccp (ws.width/2, ws.height - [levelScorePanelMessage contentSize].height/2 - BUTTONS_PADDING)]];
	
	levelScorePanel[c] = [self newScorePanelLabelLeft:YES label:NSLocalizedString (@"Level Score", @"levelScore") y:y];
	levelScorePanel[c+1] = [self newScorePanelLabelLeft:NO label:[NSString stringWithFormat:@"%d", gameEngine.currentLevelScore] y:y];
	y -= [levelScorePanel[c] contentSize].height + BUTTONS_PADDING;
	c += 2;
	
	int timeScore = 0;
	if (gameEngine.level.availableTime && gameEngine.levelTimeElapsed < gameEngine.level.availableTime) {
		timeScore = (int) (gameEngine.levelTimeLeft * (float) gameEngine.level.scorePerSecondLeft);
		if (gameEngine.difficultyLevel == kDifficultyLow) timeScore = timeScore/10;
		
		levelScorePanel[c] = [self newScorePanelLabelLeft:YES label:[NSString stringWithFormat:NSLocalizedString (@"Time Left [%d]", @"timeLeft"), (int)gameEngine.levelTimeLeft] y:y];
		levelScorePanel[c+1] = [self newScorePanelLabelLeft:NO label:[NSString stringWithFormat:@"%d", timeScore] y:y];
		y -= [levelScorePanel[c] contentSize].height + BUTTONS_PADDING;
		c += 2;
	}
	
	if (lspACTot) {
		levelScorePanel[c] = [self newScorePanelLabelLeft:YES label:[NSString stringWithFormat:NSLocalizedString (@"Achievements [%d/%d]", @"achievements"), lspACNum, lspACTot] y:y];
		levelScorePanel[c+1] = [self newScorePanelLabelLeft:NO label:[NSString stringWithFormat:@"%d", lspACScore] y:y];
		y -= [levelScorePanel[c] contentSize].height + BUTTONS_PADDING;
		c += 2;
	}
	
	if (lspBonusScore) {
		levelScorePanel[c] = [self newScorePanelLabelLeft:YES label:NSLocalizedString (@"Bonus", @"bonusScore") y:y];
		levelScorePanel[c+1] = [self newScorePanelLabelLeft:NO label:[NSString stringWithFormat:@"%d", lspBonusScore] y:y];
		y -= [levelScorePanel[c] contentSize].height + BUTTONS_PADDING;
		c += 2;
	}
	
	[gameEngine scoreAdd:lspACScore + lspBonusScore + timeScore];
	
	levelScorePanel[c] = [self newScorePanelLabelLeft:YES label:NSLocalizedString (@"Total Score", @"totalScore") y:y];
	levelScorePanel[c+1] = [self newScorePanelLabelLeft:NO label:[NSString stringWithFormat:@"%d", gameEngine.score] y:y];
	
	[levelScorePanel[c] setColor:(ccc3 (200, 0, 0))];
	[levelScorePanel[c+1] setColor:(ccc3 (200, 0, 0))];
	[levelScorePanel[c] setLabelColor:(ccc3 (255, 255, 255))];
	[levelScorePanel[c+1] setLabelColor:(ccc3 (255, 255, 255))];
	
	CCAction *a = [self pulseActionWithDuration:0.5 fromColor:ccc3(150, 0, 0) toColor:ccc3(200, 0, 0)];
	[levelScorePanel[c] runAction:[[a copy] autorelease]];
	[levelScorePanel[c+1] runAction:[[a copy] autorelease]];
	
	for (int i = 0; i < 10; i+=2) {
		if (levelScorePanel[i] == nil) break;
		
		[self addChild:levelScorePanel[i] z:MENU_PRIORITY - 10];
		[self addChild:levelScorePanel[i+1] z:MENU_PRIORITY - 10];
		
		[levelScorePanel[i] runAction:[CCMoveTo actionWithDuration:SHOW_DURATION position:ccp (ws.width/2 - BUTTONS_PADDING, levelScorePanel[i].position.y)]];
		[levelScorePanel[i + 1] runAction:[CCMoveTo actionWithDuration:SHOW_DURATION position:ccp (ws.width/2 + BUTTONS_PADDING, levelScorePanel[i+1].position.y)]];
	}
	
	[nextLevelButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionNextLevelIn] visible:YES]];
	[openFeintButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionOpenFeintInLevelScorePanel] visible:YES]];
	[mainMenuButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionMainMenuInLevelScorePanel] visible:YES]];
	
	// set score for level in OpenFeint's leaderboard
//	[KKOFM setHighScore:gameEngine.currentLevelScore forLeaderboard:gameEngine.level.leaderboard];

	[KKPM saveGameWithNextLevel:lspNextLevel];
}

-(void) hideLevelScorePanelUI
{
	menuState = kMenuStateNone;

	[gameEngine stopBackgroundMusic];
	[self showDialogBackground:NO withOpacity:-1];
	
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	[levelScorePanelMessage runAction:[CCMoveTo actionWithDuration:SHOW_DURATION position:ccp (ws.width/2, ws.height + [levelScorePanelMessage contentSize].height/2 + BUTTONS_PADDING)]];

	for (int i = 0; i < 10; i+=2) {
		if (levelScorePanel[i] == nil) break;
		
		[levelScorePanel[i] runAction:[CCMoveTo actionWithDuration:SHOW_DURATION position:ccp (-BUTTONS_PADDING, levelScorePanel[i].position.y)]];
		[levelScorePanel[i + 1] runAction:[CCMoveTo actionWithDuration:SHOW_DURATION position:ccp (ws.width + BUTTONS_PADDING, levelScorePanel[i+1].position.y)]];
	}
	
	[nextLevelButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionNextLevelOut] visible:NO]];
	[openFeintButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionOpenFeintOut] visible:NO]];
	[mainMenuButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionMainMenuOut] visible:NO]];
}

-(void) hideLevelScorePanel
{
	[self hideLevelScorePanelUI];
	[self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:SHOW_DURATION + 0.01], [CCCallFunc actionWithTarget:self selector:@selector(cleanupLevelScorePanel)], nil]];

	[self showLoadProgressBackground:YES];
}

-(void) cleanupLevelScorePanel
{
	[self removeChild:levelScorePanelMessage cleanup:YES];
	levelScorePanelMessage = nil;
	
	for (int i = 0; i < 10; i++) {
		if (levelScorePanel[i] == nil) break;
		[self removeChild:levelScorePanel[i] cleanup:YES];
		[levelScorePanel[i] release];
		levelScorePanel[i] = nil;
	}

	if (lspMessage) [lspMessage release], lspMessage = nil;
	lspACNum = 0;
	lspACTot = 0;
	lspACScore = 0;
	lspBonusScore = 0;
	
	if (lspNextLevel) {
		[gameEngine startLevel:[lspNextLevel autorelease]]; 
		lspNextLevel = nil;
	}
}

#pragma mark -
#pragma mark Died Panels

#define DIE_RESTART_TIMEOUT 3

-(void) restartAfterDied
{
	[self showStartTimer:DIE_RESTART_TIMEOUT target:gameEngine selector:@selector(levelStartTimerTimout)];
}

-(void) showGameOverPanel
{
	[KKPM removeGame];
	
	[gameOver show];
	
	[mainMenuButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionMainMenuIn] visible:YES]];
	[openFeintButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionOpenFeintInLevelScorePanel] visible:YES]];
}

-(void) showGameEndPanel
{
	gameEnd = [[KKHUDGameEndLayer alloc] initGameEndLayer];
	[self addChild:gameEnd z:LOAD_PROGRESS_Z-10];
	
	[KKPM removeGame];
	
	[gameEnd show];
}

-(void) showGameEndButtons
{
	[mainMenuButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionMainMenuIn] visible:YES]];
	[openFeintButton runAction:[self action:[CCMoveTo actionWithDuration:SHOW_DURATION position:buttonPositionOpenFeintInLevelScorePanel] visible:YES]];
}

-(void) showDiedByTimeoutPanel
{
	[self restartAfterDied];
}

-(void) showDiedByKillPanel
{
	[self restartAfterDied];
}

@end
