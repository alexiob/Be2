//
//  HUDLayer.h
//  Be2
//
//  Created by Alessandro Iob on 4/10/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"
#import "KKInputManager.h"
#import "KKHUDButton.h"
#import "KKHUDMessage.h"
#import "KKEntityProtocol.h"
#import "KKHUDGameOverLayer.h"
#import "KKHUDGameEndLayer.h"

@class KKGameEngine;
@class KKSoundManager;

#define MAX_MESSAGES 5
#define MAX_ZOOMING_TEXT 5

typedef enum {
	kMenuStateNone = 0,
	kMenuStateScore = 1,
	kMenuStatePause,
} tMenuState;

@interface KKHUDLayer : CCColorLayer {
	KKGameEngine *gameEngine;
	KKSoundManager *soundManager;
	
	BOOL shown;
	
	CCMenu *menu;
	
	KKHUDButtonImage *pauseButton;
	KKHUDButtonImage *resumeButton;
	KKHUDButtonImage *quitButton;
	KKHUDButtonImage *openFeintButton;
	KKHUDButtonImage *nextLevelButton;
	KKHUDButtonImage *mainMenuButton;
	
	CCSprite *scoreIcon;
	CCBitmapFontAtlas *scoreLabel;
	CCSprite *timeTotalIcon;
	CCBitmapFontAtlas *timeTotalLabel;
	CCSprite *timeLeftIcon;
	CCBitmapFontAtlas *timeLeftLabel;
	
	CCSprite *heroesLeftIcon;
	CCBitmapFontAtlas *heroesLeftLabel;
	
	CCSprite *turboLeftIcon;
	CCBitmapFontAtlas *turboLeftLabel;
	
	CCSprite *moveLeftRightIcon;
	CCSprite *moveUpDownIcon;
	
	CCSprite *challengeScoreIcon;
	CCBitmapFontAtlas *challengeScoreLabel;
	CCSprite *challengeTimeTotalIcon;
	CCBitmapFontAtlas *challengeTimeTotalLabel;
	
	CGPoint buttonPositionPauseIn;
	CGPoint buttonPositionPauseOut;
	
	CGPoint buttonPositionResumeIn;
	CGPoint buttonPositionResumeOut;
	
	CGPoint buttonPositionQuitIn;
	CGPoint buttonPositionQuitOut;
	
	CGPoint buttonPositionOpenFeintIn;
	CGPoint buttonPositionOpenFeintInLevelScorePanel;
	CGPoint buttonPositionOpenFeintOut;
	
	CGPoint buttonPositionNextLevelIn;
	CGPoint buttonPositionNextLevelOut;
	
	CGPoint buttonPositionMainMenuIn;
	CGPoint buttonPositionMainMenuOut;
	CGPoint buttonPositionMainMenuInLevelScorePanel;
	
	CGPoint iconPositionScoreIn;
	CGPoint iconPositionScoreOut;
	CGPoint labelPositionScoreIn;
	CGPoint labelPositionScoreOut;
	
	CGPoint iconPositionTimeTotalIn;
	CGPoint iconPositionTimeTotalOut;
	CGPoint labelPositionTimeTotalIn;
	CGPoint labelPositionTimeTotalOut;
	
	CGPoint iconPositionTimeLeftIn;
	CGPoint iconPositionTimeLeftOut;
	CGPoint labelPositionTimeLeftIn;
	CGPoint labelPositionTimeLeftOut;
	
	CGPoint iconPositionMoveLeftRightIn;
	CGPoint iconPositionMoveLeftRightOut;
	CGPoint iconPositionMoveUpDownIn;
	CGPoint iconPositionMoveUpDownOut;
	
	CGPoint iconPositionTurboLeftIn;
	CGPoint iconPositionTurboLeftOut;
	CGPoint labelPositionTurboLeftIn;
	CGPoint labelPositionTurboLeftOut;
	
	CGPoint iconPositionHeroesLeftIn;
	CGPoint iconPositionHeroesLeftOut;
	CGPoint labelPositionHeroesLeftIn;
	CGPoint labelPositionHeroesLeftOut;
	
	CGPoint iconPositionChallengeScoreIn;
	CGPoint iconPositionChallengeScoreOut;
	CGPoint labelPositionChallengeScoreIn;
	CGPoint labelPositionChallengeScoreOut;
	
	CGPoint iconPositionChallengeTimeTotalIn;
	CGPoint iconPositionChallengeTimeTotalOut;
	CGPoint labelPositionChallengeTimeTotalIn;
	CGPoint labelPositionChallengeTimeTotalOut;
	
	NSNumberFormatter *scoreFormatter;
	NSDateFormatter *timeFormatter;
	
	int startTimerTimout;
	id startTimerTarget;
	SEL startTimerSelector;
	
	BOOL isTimeLeftPulsing;
	BOOL isTimeNotificationEnabled;
	
	CCBitmapFontAtlas *timerLabel;
	
	CCBitmapFontAtlas *zoomingText[MAX_ZOOMING_TEXT];
	int currentZoomingText;
	
	KKHUDMessage *messages[MAX_MESSAGES];
	
	CCSprite *loadProgress;
	CCLabel *loadProgressLabel;
	CCLabel *loadProgressProverbs;
	CCColorLayer *loadProgressBackground;
	float loadProgressWidth;
	GLuint loadProgressSoundLoopID;
	
	CCQuadParticleSystem *pauseEmitter;
	
	CCLabel *levelScorePanelMessage;
	KKHUDButtonLabel *levelScorePanel[10];
	NSString *lspMessage;
	int lspACNum;
	int lspACTot;
	int lspACScore;
	int lspBonusScore;
	NSString *lspNextLevel;
	
	KKHUDGameOverLayer *gameOver;
	KKHUDGameEndLayer *gameEnd;
	
	int menuState;
	
	CCColorLayer *storeBackground;
}

@property (readwrite, nonatomic) BOOL shown;
@property (readwrite, nonatomic) BOOL isTimeNotificationEnabled;

-(NSNumberFormatter *) scoreFormatter;
-(NSDateFormatter *) timeFormatter;

-(NSString *) secondsToStringHMS:(int)t;
-(NSString *) secondsToStringMS:(int)t;

-(void) showStoreBackground:(BOOL)f;

-(void) initPauseEmitter;

-(void) showPauseDialog:(BOOL)f;
-(void) showDialogBackground:(BOOL)f withOpacity:(int)o;

-(void) showPauseButton:(BOOL)f;
-(void) showScore:(BOOL)f;
-(void) showTimeTotal:(BOOL)f;
-(void) showMoveLeftRight:(BOOL)f;
-(void) showMoveUpDown:(BOOL)f;
-(void) showTimeLeft:(BOOL)f;
-(void) showHeroesLeft:(BOOL)f;
-(void) showTurboLeft:(BOOL)f;
-(void) showChallengeScore:(BOOL)f;
-(void) showChallengeTimeTotal:(BOOL)f;

-(void) setScore:(int)score;
-(void) setTimeTotal:(float)t;
-(void) setTimeLeft:(float)t;
-(void) setHeroesLeft:(int)c;
-(void) setTurboLeft:(int)c;

-(void) startSuspendedTimeout:(float)t;

-(void) setChallengeScore:(int)score;
-(void) setChallengeTimeTotal:(float)t;

-(void) showStartTimer:(int)seconds target:(id)target selector:(SEL)selector;
-(void) stopStartTimer;

-(void) showTimerLabel:(NSString*)s sound:(NSString*)sound;

-(void) showZoomingText:(NSString*)s sound:(NSString*)sound;

-(void) startTimers:(BOOL)f;
-(void) updateTimers:(ccTime)dt;

-(void) update:(ccTime)dt;

#pragma mark -
#pragma mark Messages
-(void) preloadMessageFonts;

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn entity:(id<KKEntityProtocol>)entity;
-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn entity:(id<KKEntityProtocol>)entity duration:(float)seconds;
-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn entity:(id<KKEntityProtocol>)entity bgColor:(ccColor3B)bgc msgColor:(ccColor3B)msgc icnColor:(ccColor3B)icnc fontSize:(CGFloat)pointSize duration:(float)seconds;

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn origin:(CGPoint)origin;
-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn origin:(CGPoint)origin duration:(float)seconds;
-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn origin:(CGPoint)origin bgColor:(ccColor3B)bgc msgColor:(ccColor3B)msgc icnColor:(ccColor3B)icnc fontSize:(CGFloat)pointSize duration:(float)seconds;

-(void) removeMessage:(KKHUDMessage *)msg;
-(void) removeMessageWithIndex:(int)idx;
-(void) removeAllMessages;
-(void) destroyAllMessages;

-(int) addMessage:(KKHUDMessage *)msg;

#pragma mark -
#pragma mark Load Progress

-(void) showLoadProgress:(BOOL)f withMessage:(NSString *)msg;
-(void) loadProgressAdd:(float)v withMessage:(NSString *)msg;
-(void) loadProgressEndWithMessage:(NSString *)msg;

#pragma mark -
#pragma mark Level Score Panel

-(void) showLevelScorePanelWithDelay:(float)seconds message:(NSString*)msg acNum:(int)acNum acTot:(int)acTot acScore:(int)acScore bonusScore:(int)bonusScore nextLevel:(NSString*)nextLevel;
-(void) hideLevelScorePanel;
-(void) hideLevelScorePanelUI;

#pragma mark -
#pragma mark Died Panels

-(void) showGameOverPanel;
-(void) showGameEndPanel;
-(void) showGameEndButtons;
-(void) showDiedByTimeoutPanel;
-(void) showDiedByKillPanel;

@end
