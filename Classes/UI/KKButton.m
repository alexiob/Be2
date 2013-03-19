//
//  Button.m
//  Be2
//
//  Created by Alessandro Iob on 4/10/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKButton.h"
#import "KKSoundManager.h"
#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKStringUtilities.h"
//#import "CCSprite+Key.h"

enum {
	kZoomActionTag = 0xc0c05002,
	kMoveAtPositionAction,
	kHeaderAction,
	kFlaggedAction,
	kPulseAction,
};

#define BORDER_X 4
#define BORDER_Y 1
#define BORDER_TOP 7
#define RADIUS 5.0f
#define GRAY 0.8f
#define GRAY_INT 165
#define ALPHA 0.6f
#define ALPHA_INT (int) (256 * ALPHA)
#define LABEL_R 0
#define LABEL_G 0
#define LABEL_B 0
#define DEFAULT_R 255
#define DEFAULT_G 0
#define DEFAULT_B 0
#define DISABLED_R 126
#define DISABLED_G 126
#define DISABLED_B 126
#define DEFAULT_SCALE 1.0f
#define DISABLED_SCALE 0.7f
#define SELECTED_SCALE 1.7f
#define MOVE_DURATION 0.3f
#define HEADER_SPEED 0.2f

#define HEADER_R 255
#define HEADER_G 0
#define HEADER_B 0

#define FLAGGED_R 0
#define FLAGGED_G 200
#define FLAGGED_B 0

#define OPACITY_MODIFY_RGB NO

@implementation KKButton

@synthesize defaultScale, disabledScale, selectedScale;
@synthesize color, opacity;
@synthesize defaultColor, disabledColor, selectedColor;
@synthesize headerColor, flaggedColor;
@synthesize shownPosition, hiddenPosition;
@synthesize image;
@synthesize label;
@synthesize shown, header, flagged;
@synthesize activateSound, selectedSound, unselectedSound;

#pragma mark Static constructors

+(id) itemWithFile:(NSString*)filename target:(id)rec selector:(SEL)s
{
	return [[[self alloc] initWithFile:filename target:rec selector:s] autorelease];
}

+(id) itemWithFile:(NSString*)filename width:(NSUInteger)width height:(NSUInteger)height scale:(float)imageScale radius:(float)radius gray:(float)gray alpha:(float)alpha target:(id)rec selector:(SEL)s
{
	return [[[self alloc] initWithFile:filename width:(NSUInteger)width height:(NSUInteger)height scale:(float)imageScale radius:radius gray:gray alpha:alpha target:rec selector:s] autorelease];
}

//+(id) itemWithAtlasGroup:(tGraphicGroupEnum)group filename:(NSString*)filename target:(id)rec selector:(SEL)s
//{
//	return [[[self alloc] initWithAtlasGroup:(tGraphicGroupEnum)group filename:filename target:rec selector:s] autorelease];
//}
//
//+(id) itemWithAtlasGroup:(tGraphicGroupEnum)group filename:(NSString*)filename width:(NSUInteger)width height:(NSUInteger)height scale:(float)imageScale radius:(float)radius gray:(float)gray alpha:(float)alpha target:(id)rec selector:(SEL)s
//{
//	return [[[self alloc] initWithAtlasGroup:(tGraphicGroupEnum)group filename:filename width:(NSUInteger)width height:(NSUInteger)height scale:(float)imageScale radius:radius gray:gray alpha:alpha target:rec selector:s] autorelease];
//}

+(id) itemWithLabel:(NSString*)str fontSize:(CGFloat)size target:(id)rec selector:(SEL)s
{
	return [[[self alloc] initWithLabel:str fontSize:size target:rec selector:s] autorelease];
}

#pragma mark Init

#define PULSE_DURATION 1.0f
#define PULSE_OPACITY_MAX 255
#define PULSE_OPACITY_MIN ALPHA_INT

-(void) initDefaultsWithPulse:(BOOL)pulse
{
	self.contentSize = self.contentSize;
	
	self.defaultColor = ccc3(DEFAULT_R, DEFAULT_G, DEFAULT_B);
	disabledColor = ccc3(DISABLED_R, DISABLED_G, DISABLED_B);
	selectedColor = ccc3(defaultColor.r, defaultColor.g, defaultColor.b);
	headerColor = ccc3(HEADER_R, HEADER_G, HEADER_B);
	flaggedColor = ccc3(FLAGGED_R, FLAGGED_G, FLAGGED_B);
	
	defaultScale = DEFAULT_SCALE;
	disabledScale = DISABLED_SCALE, 
	selectedScale = SELECTED_SCALE;
	shownPosition = ccp (0, 0);
	hiddenPosition = ccp (0, 0);
	shown = TRUE;
	
	header = FALSE;
	flagged = FALSE;
	headerPosition = ccp (shownPosition.x, shownPosition.y);
	
	activateSound = nil;
	selectedSound = nil;
	unselectedSound = nil;
	
//	if (pulse) {
//		CCAction *action = [CCRepeatForever actionWithAction:[CCSequence actions:[CCFadeTo actionWithDuration:PULSE_DURATION opacity:PULSE_OPACITY_MAX], 
//														  [CCFadeTo actionWithDuration:PULSE_DURATION opacity:PULSE_OPACITY_MIN],
//														  nil]];
//		action.tag = kPulseAction;
//		[image runAction:action];
//	}
}

-(id) initWithFile:(NSString*)filename target:(id)rec selector:(SEL)s
{
	self = [super initWithTarget:rec selector:s];
	
	if (self) {
		image = [[CCSprite spriteWithFile:filename] retain];
		[image setOpacityModifyRGB:OPACITY_MODIFY_RGB];
		[image setOpacity:opacity];
		[self initDefaultsWithPulse:YES];
	}
	return self;
}

-(id) initWithFile:(NSString*)filename width:(NSUInteger)width height:(NSUInteger)height scale:(float)imageScale radius:(float)radius gray:(float)gray alpha:(float)alpha target:(id)rec selector:(SEL)s
{
	self = [super initWithTarget:rec selector:s];
	
	if (self) {
		topImage = [[CCSprite spriteWithFile:filename] retain];
		[topImage setOpacityModifyRGB:OPACITY_MODIFY_RGB];
		[topImage setOpacity:opacity];
		
		if (imageScale >= 0) topImage.scale = imageScale;
		
		// generate background image
		CGSize s = [topImage contentSize];
		
		if (!width) width = s.width;
		width += BORDER_X * 2;
		if (!height) height = s.height;
		height += BORDER_Y * 2;
		
		CGContextRef context = get_bitmap_context (width, height);
		
		if (radius < 0.0) radius = RADIUS;
		if (gray < 0.0) gray = GRAY;
		if (alpha < 0.0) alpha = ALPHA;
		
		draw_grey_rounded_background (context, width, height, radius, gray, alpha);
		CGImageRef cimage = context_to_image (context);
		
		image = [[CCSprite spriteWithCGImage:cimage key:uuidString()] retain];
		[image setOpacityModifyRGB:OPACITY_MODIFY_RGB];
		[image setOpacity:opacity];
		free_bitmap_context_and_image (context, cimage);
		
		[image addChild:topImage z:100 tag:1];

		s = [image contentSize];
		[topImage setPosition:ccp (s.width/2, s.height/2)];

		 [self initDefaultsWithPulse:YES];
	}
	return self;
}

-(id) initWithLabel:(NSString*)str fontSize:(CGFloat)size target:(id)rec selector:(SEL)s
{
	self = [super initWithTarget:rec selector:s];
	
	if (self) {
		label = [[CCLabel labelWithString:str fontName:UI_FONT_DEFAULT fontSize:size] retain];
		CGSize ls = [label contentSize];
		
		// generate background image
		NSUInteger width = ls.width + BORDER_X * 2;
		NSUInteger height = ls.height + BORDER_Y * 2;
		float radius = RADIUS;
		float gray = GRAY;
		float alpha = ALPHA;
		
		CGContextRef context = get_bitmap_context (width, height);
		
		draw_grey_rounded_background (context, width, height, radius, gray, alpha);
		CGImageRef cimage = context_to_image (context);
		
		image = [[CCSprite spriteWithCGImage:cimage key:uuidString()] retain];
		free_bitmap_context_and_image (context, cimage);
		
		CGSize is = [image contentSize];
	
		[image setOpacityModifyRGB:OPACITY_MODIFY_RGB];
		[image setOpacity:opacity];
		
		[self initDefaultsWithPulse:YES];
		
		[self setLabelColor:ccc3(LABEL_R, LABEL_G, LABEL_B)];
		[label setPosition:ccp (is.width/2, is.height/2 - BORDER_Y)];
	}
	return self;
}

-(void) dealloc
{
	if (label) [label release];
	if (image) {
		[image release];
		image = nil;
	}
	if (topImage) [topImage release];
	if (activateSound) [activateSound release];
	if (selectedSound) [selectedSound release];
	if (unselectedSound) [unselectedSound release];
	
	[super dealloc];
}

#pragma mark Utilities

#define HIDDEN_BORDER 2

-(void) setPositionsShown:(CGPoint)s hidden:(tHiddenPositions)hidden
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	CGSize cs = [image contentSize];
	CGPoint ta = ccp(cs.width * [self anchorPoint].x, cs.height * [self anchorPoint].y);
	
	shownPosition = s;
	headerPosition = ccp (shownPosition.x, shownPosition.y);
	hidden_ = hidden;
	
	switch (hidden) {
		case kHideTop:
			hiddenPosition = ccp (s.x, ws.height + ta.y + HIDDEN_BORDER);
			break;
		case kHideBottom:
			hiddenPosition = ccp (s.x, -(cs.height - ta.y) - HIDDEN_BORDER);
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

-(CGRect) rect
{
	CGSize s = [image contentSize];
	
	CGRect rec = CGRectMake (self.position.x - s.width/2, self.position.y-s.height/2, s.width, s.height);
	return rec;
}

-(void) stopAllButtonActions
{
	[self stopActionByTag:kZoomActionTag];
	[self stopActionByTag:kMoveAtPositionAction];
	[self stopActionByTag:kHeaderAction];
	[self stopActionByTag:kFlaggedAction];
}

-(void) activate {
	if ([self isEnabled] && !header) {
		[self stopAllButtonActions];
        
		self.scale = defaultScale;
        
		if (activateSound != nil)
			[[KKSoundManager sharedKKSoundManager] playSoundEffect:activateSound channelGroupId:kChannelGroupFX];
		
		[super activate];
	}
}

-(void) selected
{
	if ([self isEnabled] && !header) {		
		[self stopActionByTag:kZoomActionTag];
		CCAction *zoomAction = [CCScaleTo actionWithDuration:0.1f scale:selectedScale];
		zoomAction.tag = kZoomActionTag;
		[self runAction:zoomAction];
//		if (!header && !flagged) 
//			[self setColor:selectedColor];
		if (selectedSound != nil)
			[[KKSoundManager sharedKKSoundManager] playSoundEffect:selectedSound channelGroupId:kChannelGroupFX];
	}
}

-(void) unselected
{
	if ([self isEnabled] && !header) {
		[self stopActionByTag:kZoomActionTag];
		CCAction *zoomAction = [CCScaleTo actionWithDuration:0.1f scale:defaultScale];
		zoomAction.tag = kZoomActionTag;
		[self runAction:zoomAction];
//		if (!header && !flagged) 
//			[self setColor:defaultColor];
		if (unselectedSound != nil)
			[[KKSoundManager sharedKKSoundManager] playSoundEffect:unselectedSound channelGroupId:kChannelGroupFX];
	}
}

-(void) setIsEnabled:(BOOL)enabled
{
	[self setIsEnabled:enabled change:YES];
}

-(void) setIsEnabled:(BOOL)enabled change:(BOOL)change
{
	[super setIsEnabled:enabled];
	
	if (change) {
		if (enabled == NO) {
			self.scale = disabledScale;
//			[self setColor:[image color]];
			[self setColor:disabledColor];
//			[image setOpacity:self.opacity];
		} else {
			self.scale = defaultScale;
			[self setColor:defaultColor];
//			[image setOpacity:self.opacity];
		}
	}
}

-(void) setDefaultScale:(float) s
{
	defaultScale = s;
	disabledScale = s * DISABLED_SCALE;
	selectedScale = s* SELECTED_SCALE;
}

-(void) setScale:(float) s
{
	[super setScale:s];
	[self setPositionsShown:shownPosition hidden:hidden_];
}

-(CGSize) contentSize
{
	CGSize s = [image contentSize];
	return CGSizeMake (s.width * [self scale], s.height * [self scale]);
}

-(void) draw
{
	[image draw];
	
	if (topImage) {
		[topImage transform];
		[topImage draw];
	}
	
	if (label) {
		[label transform];
		[label draw];
	}
}

-(void) setOpacity:(GLubyte)newOpacity
{
	opacity = newOpacity;
//	[image setOpacityModifyRGB:OPACITY_MODIFY_RGB];
	[image setOpacity:newOpacity];
	[self setTopImageOpacity:newOpacity];
}

-(void) setColor:(ccColor3B)c
{
	[image setColor:c];
}

-(void) setRGB:(GLubyte)r:(GLubyte)g:(GLubyte)b
{
	[self setColor:ccc3(r,g,b)];
}

-(ccColor3B) color
{
	return [image color];
}

-(void) setDefaultColor:(ccColor3B)c
{
	defaultColor = c;
	[self setColor:c];
}

-(void) setDisabledColor:(ccColor3B)c
{
	disabledColor = c;
}

-(void) setSelectedColor:(ccColor3B)c
{
	selectedColor = c;
}

-(void) setLabelColor:(ccColor3B)c
{
	if (label) [label setColor:c];
}

-(void) setTopImageColor:(ccColor3B)c
{
	if (topImage) [topImage setColor:c];
}

-(void) setTopImageScale:(float)s
{
	if (topImage) [topImage setScale:s];
}

-(void) setTopImageOpacity:(GLubyte)newOpacity
{
	if (topImage) {
//		[topImage setOpacityModifyRGB:OPACITY_MODIFY_RGB];
		[topImage setOpacity:newOpacity];
	}
}

-(void) setTopImage:(NSString *)filename
{
	float imageScale = 0;
	
	if (topImage) {
		imageScale = topImage.scale;
		[topImage release];
	}
	
	topImage = [[CCSprite spriteWithFile:filename] retain];
	[topImage setOpacityModifyRGB:OPACITY_MODIFY_RGB];
	[topImage setOpacity:opacity];

	if (imageScale >= 0) topImage.scale = imageScale;
	
	[image addChild:topImage z:100 tag:1];
	
	CGSize s = [image contentSize];
	[topImage setPosition:ccp (s.width/2, s.height/2)];
	
}

-(void) setShown:(BOOL)v
{
	if (v != shown) {
		CGPoint p;
		if (v) p = shownPosition;
		else p = hiddenPosition;
		
		[self moveAtPosition:p duration:MOVE_DURATION];
		
		shown = v;
		
		[super setIsEnabled:v];
	}
}

-(void) setHidden
{
	self.position = self.hiddenPosition;
	shown = FALSE;
}

-(void) setPosition:(CGPoint)newPosition
{
	BOOL f = CGPointEqualToPoint(newPosition, self.hiddenPosition);
	
	if (self.visible && f) self.visible = NO;
	else if (!self.visible && !f) self.visible = YES;
	
	[super setPosition:newPosition];
}

-(void) moveAtPosition:(CGPoint)p duration:(float)d
{
	if (CGPointEqualToPoint(self.position, p)) return;

	[self stopActionByTag:kMoveAtPositionAction];
	
	CCAction *action = [CCSequence actions:
					  [CCEaseElasticOut actionWithAction:[CCMoveTo actionWithDuration:d position:p] period:UI_EASYACTION_PERIOD],
					  [CCCallFunc actionWithTarget:self selector:@selector(buttonReachedPosition:)],
					  nil
	];
	[action setTag:kMoveAtPositionAction];
	[self runAction:action];
}

-(void) buttonReachedPosition:(id)sender
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:@"buttonReachedPosition" object:self];
}

-(void) setHeader:(BOOL)isHeader
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	CGSize cs = [self contentSize];
	CCAction *action;
	
//	[self stopActionByTag:kHeaderAction];
	
	if (isHeader && !header) {
		CGPoint p = ccp (self.shownPosition.x, ws.height - cs.height/2.0 - BORDER_TOP);
		[self moveAtPosition:p duration:HEADER_SPEED];
		action = [CCTintTo actionWithDuration:HEADER_SPEED red:headerColor.r green:headerColor.g blue:headerColor.b];
		[action setTag:kHeaderAction];
		[self runAction:action];
	} else if (!isHeader && header) {
		[self moveAtPosition:self.shownPosition duration:HEADER_SPEED];
		action = [CCTintTo actionWithDuration:HEADER_SPEED red:defaultColor.r green:defaultColor.g blue:defaultColor.b];
		[action setTag:kHeaderAction];
		[self runAction:action];
	}
	header = isHeader;
}

-(void) setFlagged:(BOOL)f
{
//	CCAction *action;
	
//	[self stopActionByTag:kFlaggedAction];
	
	if (f && !flagged) {
//		action = [CCTintTo actionWithDuration:HEADER_SPEED red:flaggedColor.r green:flaggedColor.g blue:flaggedColor.b];
//		[action setTag:kFlaggedAction];
//		[self runAction:action];
		[self setColor:flaggedColor];
	} else if (!f && flagged) {
//		action = [CCTintTo actionWithDuration:HEADER_SPEED red:defaultColor.r green:defaultColor.g blue:defaultColor.b];
//		[action setTag:kFlaggedAction];
//		[self runAction:action];
		[self setColor:defaultColor];
	}
	flagged = f;
}

@end
