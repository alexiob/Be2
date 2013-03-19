//
//  TimeBar.m
//  Be2
//
//  Created by Alessandro Iob on 4/5/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKTimeBar.h"
#import "KKUIUtilities.h"
#import "KKSoundManager.h"
#import "KKStringUtilities.h"
//#import "CCSprite+Key.h"

#define RADIUS 5.0f
#define GRAY 0.8f
#define GRAY_INT 255 * GRAY
#define ALPHA 0.6f
#define NORMAL_R 170
#define NORMAL_G 0
#define NORMAL_B 0
#define NORMAL_OPACITY 120
#define ALERT_R 255
#define ALERT_G 0
#define ALERT_B 0

#define INDICATOR_RADIUS 3.0f
#define INDICATOR_X 4.0f
#define INDICATOR_Y 4.0f
#define INDICATOR_WIDTH cs.width - (INDICATOR_X * 2.0f)
#define INDICATOR_HEIGHT cs.height - (INDICATOR_Y * 2.0f)
#define INDICATOR_RED 0
#define INDICATOR_GREEN 255
#define INDICATOR_BLUE 0
#define INDICATOR_ALPHA 0.6f
#define DELAY 0.1f
#define ALERT_ZONE 30
#define SHOW_DURATION 0.3f
#define DEFAULT_WARNING_SECONDS 3.0

@implementation KKTimeBar

enum {
	kShownAction = 4001,
	kTimeStepAction,
	kAlertAction,
};

@synthesize positionIn, positionOut, duration;
@synthesize totalSeconds, warningSeconds, shown;
@synthesize backgroundNormalColor, backgroundAlertColor;
@synthesize barNormalColor, barAlertColor;

-(id) init 
{
	return [self initWithPositionIn:CGPointZero positionOut:CGPointZero duration:SHOW_DURATION];
}

-(id) initWithPositionIn:(CGPoint)pIn positionOut:(CGPoint)pOut duration:(float)sec
{
	return [self initWithPositionIn:pIn positionOut:pOut duration:sec width:TIMEBAR_WIDTH height:TIMEBAR_HEIGHT];
}

-(id) initWithPositionIn:(CGPoint)pIn positionOut:(CGPoint)pOut duration:(float)sec width:(float)width height:(float)height
	{
	self = [super init];
	
	if (self != nil) {
		warningSeconds = DEFAULT_WARNING_SECONDS;
		nextTick = 0.0;
		duration = sec;
		backgroundNormalColor = ccc3(NORMAL_R, NORMAL_G, NORMAL_B);
		backgroundAlertColor = ccc3(ALERT_R, ALERT_G, ALERT_B);
		barNormalColor = ccc3(INDICATOR_RED, INDICATOR_GREEN, INDICATOR_BLUE);
		barAlertColor = ccc3(INDICATOR_RED, INDICATOR_GREEN, INDICATOR_BLUE);
		
		CGContextRef context;
		CGImageRef cimage;
		CGSize ws = [[CCDirector sharedDirector] winSize];
		CGSize cs = CGSizeMake (width, height);
		
//		KKLOG (@"TIMEBAR INIT: (x=%f,y=%f) (w=%f, h=%f)", TIMEBAR_MENU_POSITION_IN.x, TIMEBAR_MENU_POSITION_IN.y, width, height);
		
		if (CGPointEqualToPoint (pIn, CGPointZero)) pIn = TIMEBAR_MENU_POSITION_IN;
		if (CGPointEqualToPoint (pOut, CGPointZero)) pOut = TIMEBAR_MENU_POSITION_OUT;
		
		positionIn = pIn;
		positionOut = pOut;

//		KKLOG (@"TIMEBAR INIT IN: (x=%f,y=%f)", pIn.x, pIn.y);
//		KKLOG (@"TIMEBAR INIT OUT: (x=%f,y=%f)", pOut.x, pOut.y);
	
		// generate background image
		context = get_bitmap_context ((NSUInteger) width, (NSUInteger) height);
		
		draw_grey_rounded_background (context, (NSUInteger) width, (NSUInteger) height, RADIUS, GRAY, ALPHA);
		cimage = context_to_image (context);
		
		barBackground = [[CCSprite spriteWithCGImage:cimage key:uuidString()] retain];
		[barBackground setAnchorPoint: ccp (0.0, 0.0)];
		[barBackground setOpacityModifyRGB:NO];
		[barBackground setOpacity:NORMAL_OPACITY];
		[barBackground setColor:backgroundNormalColor];
		[self addChild:barBackground z:1];
		
		CGContextRelease (context);
		//		free_bitmap_context_and_image (context, cimage);
		
//		KKLOG (@"TIMEBAR INIT SIZE: (w=%f, h=%f) (ow=%f, oh=%f)", [self contentSize].width, [self contentSize].height, cs.width, cs.height);
//		KKLOG (@"TIMEBAR INIT INDICATOR: (x=%f,y=%f) (w=%f,w=%f)", INDICATOR_X, INDICATOR_Y, INDICATOR_WIDTH, INDICATOR_HEIGHT);

		// generate indicator image
		context = get_bitmap_context ((NSUInteger) INDICATOR_WIDTH, (NSUInteger) INDICATOR_HEIGHT);
		
		draw_grey_rounded_background (context, (NSUInteger) INDICATOR_WIDTH, (NSUInteger) INDICATOR_HEIGHT, INDICATOR_RADIUS, 1.0, ALPHA);
		cimage = context_to_image (context);
		
		bar = [[CCSprite spriteWithCGImage:cimage key:uuidString()] retain];
		[bar setAnchorPoint:ccp (0.0, 0.0)];
		[bar setPosition: ccp (INDICATOR_X, INDICATOR_Y)];
		[bar setScaleX:1.0];
		[bar setColor:barNormalColor];
		[self setBackgroundToNormal];
		[self addChild:bar z:200000];

		free_bitmap_context_and_image (context, cimage);
		
		// hide the timebar
//		[self setTotalSeconds:0.0];
		[self setPosition:positionOut];
	} 
	return self; 
} 

-(void) dealloc 
{
//	KKLOG(@"TIMEBAR DEALLOC");
	[self stopAllActions];
//	[self onShowEnd];
	
	if (bar) {
//		[[CCTextureCache sharedTextureCache] removeTexture:bar.texture];
		[bar release];
		bar = nil;
	}
	if (barBackground) {
//		[[CCTextureCache sharedTextureCache] removeTexture:barBackground.texture];
		[barBackground release];
		barBackground = nil;
	}
	[super dealloc];
}

-(void) setPosition:(CGPoint)newPosition
{
	BOOL f = CGPointEqualToPoint (newPosition, positionOut);
	
	if (self.visible && f) self.visible = NO;
	else if (!self.visible && !f) self.visible = YES;
	
	[super setPosition:newPosition];
}

-(void) onShowEnd
{
	if (bar) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TIMEBAR_SHOW_END object:nil];
	}
}

-(void) setShown:(BOOL)b
{
	if (!bar) return;
	
	CGPoint p;
	
	if (b) {
		p = positionIn;
	} else {
		p = positionOut;
	}
	
	KKLOG (@"%d", b);
	
	[self stopActionByTag:kShownAction];
	if (!b) {
		[self stopActionByTag:kTimeStepAction];
		[barBackground stopActionByTag:kAlertAction];
	}

	CCSequence *action = [CCSequence actions:
				 [CCEaseElasticOut actionWithAction:[CCMoveTo actionWithDuration:duration position:p] period:UI_EASYACTION_PERIOD],
				 [CCCallFunc actionWithTarget:self selector:@selector(onShowEnd)],
				 nil
	];
	[action setTag:kShownAction];
	[self runAction:action];
	
	shown = b;
}

-(void) setTotalSeconds:(float)total_seconds 
{
	
	[self stopActionByTag:kTimeStepAction];
	[barBackground stopActionByTag:kAlertAction];
	
	totalSeconds = total_seconds;
	availableSeconds = total_seconds;
	nextTick = 0.0;
	
	[bar setPosition: ccp (INDICATOR_X, INDICATOR_Y)];
	[bar setScaleX:1.0];
	[bar setColor:barNormalColor];
	[self setBackgroundToNormal];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:NOTIFICATION_TIMEBAR_COUNTER_STARTED object:self];
	
	id action = [CCRepeat actionWithAction:
		[CCSequence actions:
			[CCDelayTime actionWithDuration:DELAY],
			[CCCallFunc actionWithTarget:self selector:@selector(doTimeStep)],
			nil
		]
		times: (int) (totalSeconds / DELAY) + 1
	];
	[action setTag:kTimeStepAction];
	[self runAction:action];
}

-(void) setBackgroundToNormal
{
	[barBackground runAction:[CCTintTo actionWithDuration:0.2 red:backgroundNormalColor.r green:backgroundNormalColor.g blue:backgroundNormalColor.b]];
}

-(void) setBackgroundToAlert
{
	[barBackground runAction:[CCTintTo actionWithDuration:0.2 red:backgroundAlertColor.r green:backgroundAlertColor.g blue:backgroundAlertColor.b]];
}

-(void) doTimeStep 
{
	availableSeconds -= DELAY;
	
	if (availableSeconds > 0.0) {
//		int width = (int) (((float) (INDICATOR_WIDTH) / totalSeconds) * availableSeconds);
//		int x = INDICATOR_X + INDICATOR_WIDTH - width;
		CGSize cs = [self contentSize];
		float width = (INDICATOR_WIDTH) / totalSeconds * availableSeconds;
		float x = INDICATOR_X + INDICATOR_WIDTH - width;

//		KKLOG (@"TIMEBAR TIMESTEP: (x=%f, y=%f, w=%f) (w=%f, h=%f)", x, INDICATOR_Y, width, cs.width, cs.height);

		[bar setPosition:ccp (x, INDICATOR_Y)];
		[bar setScaleX:width / (INDICATOR_WIDTH)];
		
		if (nextTick == 0.0) {
			if (availableSeconds > warningSeconds) {
				nextTick = availableSeconds - 1.0;
			} else {
				float i = log10f (availableSeconds);
				nextTick = availableSeconds - (i > 0 ? i : 0.08);
				
				if (! [barBackground getActionByTag:kAlertAction]) {
					id action = [CCRepeatForever actionWithAction:
						[CCSequence actions:
							[CCTintTo actionWithDuration:0.3 red:backgroundAlertColor.r green:backgroundAlertColor.g blue:backgroundAlertColor.b],
							[CCTintTo actionWithDuration:0.3 red:backgroundNormalColor.r green:backgroundNormalColor.g blue:backgroundNormalColor.b],
							nil
						]
					];
					[action setTag:kAlertAction];
					[barBackground runAction:action];
				}
			}
		} else if (nextTick >= availableSeconds) {
			nextTick = 0.0;
			[[KKSoundManager sharedKKSoundManager] playSoundEffect:SOUND_TIMETICK channelGroupId:kChannelGroupFX];
		}
	}
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	if (availableSeconds > 0.0f) {
		[center postNotificationName:NOTIFICATION_TIMEBAR_COUNTER_TICK object:self];
	} else {
		[bar setScaleX:0.0f];
		availableSeconds = 0.0f;
		nextTick = 0.0f;
		[barBackground stopActionByTag:kAlertAction];
		[self setBackgroundToNormal];
		
		[center postNotificationName:NOTIFICATION_TIMEBAR_COUNTER_STOPPED object:self];
	}
}

-(CGRect) rect
{
	CGSize s = [self contentSize];
	
	return CGRectMake (self.position.x, self.position.y, s.width, s.height);
}

#pragma mark Protocols

// ContentSize protocol
-(CGSize) contentSize
{
	return [barBackground contentSize];
}

// Opacity protocol
-(void) setOpacity:(GLubyte)o
{
	barBackground.opacity = o;
	bar.opacity = o;
}

@end 
