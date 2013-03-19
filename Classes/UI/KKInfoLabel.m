//
//  InfoLabel.m
//  Be2
//
//  Created by Alessandro Iob on 6/24/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKInfoLabel.h"
#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKStringUtilities.h"
//#import "CCSprite+Key.h"

#define MOVE_DURATION 0.3f

enum {
	kMoveAtPositionAction = 3001,
};

#define RADIUS 5.0f
#define GRAY 0.8f
#define GRAY_INT 165
#define ALPHA 0.6f
#define BG_BORDER 12
#define BORDER_X 2

@implementation KKInfoLabel

@synthesize shown, shownPosition, hiddenPosition;

-(id) initWithString:(NSString*)string fontName:(NSString*)name fontSize:(CGFloat)size backgroundColor:(ccColor3B)color opacity:(GLubyte)opacity width:(int)width height:(int)height
{
	return [self initWithString:string fontName:name fontSize:size backgroundColor:color opacity:opacity width:width height:height alignment:UITextAlignmentLeft];
}

-(id) initWithString:(NSString*)string fontName:(NSString*)name fontSize:(CGFloat)size backgroundColor:(ccColor3B)color opacity:(GLubyte)opacity width:(int)width height:(int)height alignment:(UITextAlignment)alignment
{
	self = [super initWithString:string dimensions:CGSizeMake (width - BORDER_X*2, height) alignment:alignment fontName:name fontSize:size];
	
	if (self) {
		shownPosition = ccp (0, 0);
		hiddenPosition = ccp (0, 0);
		
		if (&color) {
			CGContextRef context = get_bitmap_context (width, height);
			
			draw_grey_rounded_background (context, width, height, RADIUS, GRAY, ALPHA);
			CGImageRef cimage = context_to_image (context);
			
			background = [[CCSprite spriteWithCGImage:cimage key:uuidString()] retain];
			free_bitmap_context_and_image (context, cimage);
			
			switch (alignment) {
				case UITextAlignmentCenter:
					[background setAnchorPoint:ccp(0.5, 0.5)];
					break;
				default:
					[background setAnchorPoint:ccp(0.0, 0.5)];
					break;
			}
			[background setOpacityModifyRGB:NO];
			[background setOpacity:opacity];
			[background setColor:color];
			[self addChild:background z:-1];
			
			[self setContentSize:CGSizeMake (width, height)];
		}
	}
	
	return self;
}

-(void) dealloc
{
	if (background) {
//		[[CCTextureCache sharedTextureCache] removeTexture:background.texture];
		[background release];
		background = nil;
	}
	
	[super dealloc];
}

#define PULSE_SPEED 0.07f
#define PULSE_SCALE 1.1f
#define PULSE_DELAY 0.1f

-(void) setString:(NSString *)string withEffect:(tInfoLabelEffects)effect
{
	[self setString:string withEffect:effect updatePosition:YES];
}

-(void) setString:(NSString *)string withEffect:(tInfoLabelEffects)effect updatePosition:(BOOL)f
{
	CGSize s = [self contentSize];
	CGPoint p = ccp (shownPosition.x - s.width/2, shownPosition.y);
	
	switch (effect) {
		case kInfoLabelEffectNone:
			[self setString:string];
			if (f)
				[self updatePositions:p];
			break;
		case kInfoLabelEffectPulse:
			[self setString:string];
			if (f)
				[self updatePositions:p];
			[self runAction:[
							 CCSequence actions:[CCScaleTo actionWithDuration:PULSE_SPEED scale:PULSE_SCALE], 
							 [CCDelayTime actionWithDuration:PULSE_DELAY],
							 [CCScaleTo actionWithDuration:PULSE_SPEED scale:1.0f], 
							 nil]
			];
			break;
		default:
			break;
	}
}

#define HIDDEN_BORDER 2

-(void) setPosition:(CGPoint)newPosition
{
	BOOL f = CGPointEqualToPoint(newPosition, self.hiddenPosition);
	
	if (self.visible && f) self.visible = NO;
	else if (!self.visible && !f) self.visible = YES;
	
	[super setPosition:newPosition];
}

-(void) updatePositions:(CGPoint)origin
{
	CGSize s = [self contentSize];
	CGPoint p = ccp (origin.x + s.width/2, origin.y);
	BOOL b = self.shown;
	
	[self setPositionsShown:p hidden:hiddenPositionFlag];
	if (b)
		p = self.shownPosition;
	else
		p = self.hiddenPosition;
//	KKLOG (@"updatePosition: %d, p:(%f, %f), s:(%f, %f), h:(%f, %f)", self.shown, p.x, p.y, self.shownPosition.x, self.shownPosition.y, self.hiddenPosition.x, self.hiddenPosition.y);
	self.position = p;
}

-(void) setPositionsShown:(CGPoint)s hidden:(tHiddenPositions)hidden
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	CGSize cs = [self contentSize];
	CGPoint ta = ccp(cs.width * [self anchorPoint].x, cs.height * [self anchorPoint].y);
	
	shownPosition = s;
	hiddenPositionFlag = hidden;

	if (background) {
//		[background setPosition:ccp (s.x - cs.width/2 - BG_BORDER, cs.height/2)];
		switch (alignment_) {
			case UITextAlignmentCenter:
				[background setPosition:ccp (cs.width/2, cs.height/2)];
				break;
			default:
				[background setPosition:ccp (- BG_BORDER/2, cs.height/2)];
				break;
		}
	}
	
	switch (hidden) {
		case kHideTop:
			hiddenPosition = ccp (s.x, ws.height + ta.y + HIDDEN_BORDER);
			break;
		case kHideBottom:
			hiddenPosition = ccp (s.x, -(cs.height + ta.y) - HIDDEN_BORDER);
			break;
		case kHideLeft:
			hiddenPosition = ccp (-(cs.width - ta.x) - HIDDEN_BORDER, s.y);
			break;
		case kHideRight:
			hiddenPosition = ccp (ws.width + ta.x + HIDDEN_BORDER, s.y);
			break;
		default:
			break;
	}
}

-(void) doShow
{
	[self setShown:YES];
}

-(void) doHide
{
	[self setShown:NO];
}

-(void) setShown:(BOOL)v
{
	if (v != self.shown) {
		CGPoint p;
		if (v) p = self.shownPosition;
		else p = self.hiddenPosition;
		
		[self moveAtPosition:p duration:MOVE_DURATION];
		
		shown = v;
	}
}

-(void) setHidden
{
	self.position = self.hiddenPosition;
	shown = FALSE;
}

-(void) moveAtPosition:(CGPoint)p duration:(float)d
{
	if (CGPointEqualToPoint(self.position, p)) return;
	
	if ([self getActionByTag:kMoveAtPositionAction])
		[self stopActionByTag:kMoveAtPositionAction];
	
	CCAction *action = [CCSequence actions:
					  [CCEaseElasticOut actionWithAction:[CCMoveTo actionWithDuration:d position:p] period:UI_EASYACTION_PERIOD],
					  [CCCallFunc actionWithTarget:self selector:@selector(buttonReachedPosition:)],
					  nil
					  ];
	[action setTag:kMoveAtPositionAction];
	[self runAction:action];
	
//	[self runAction:[CCSequence actions:
//					 [CCMoveTo actionWithDuration:d position:p],
//					 [CCCallFunc actionWithTarget:self selector:@selector(buttonReachedPosition:)],
//					 nil]
//	];
}

-(void) buttonReachedPosition:(id)sender
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:NOTIFICATION_INFO_LABEL_REACHED_POSITION object:self userInfo:[NSDictionary dictionaryWithObject:self forKey:@"object"]];
}


@end
