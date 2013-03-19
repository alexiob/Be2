//
//  KKHUDMessage.m
//  be2
//
//  Created by Alessandro Iob on 22/4/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKHUDMessage.h"
#import "KKGameEngine.h"
#import "KKGlobalConfig.h"
#import "KKMacros.h"
#import "KKGraphicsManager.h"

#import "CCDrawingPrimitives.h"

#import "FontManager.h"
#import "FontLabelStringDrawing.h"

#define MESSAGE_MAX_WIDTH 300
#define MESSAGE_MAX_HEIGHT 200
#define EMOTICON_SIZE 10
#define BUBBLE_BORDER 4

static NSString *emoticons[] = {
	@"/emoticons/plain.png",
	@"/emoticons/happy.png",
	@"/emoticons/sad.png",
	@"/emoticons/angel.png",
	@"/emoticons/devil.png",
	@"/emoticons/bored.png",
	@"/emoticons/angry.png",
	@"/emoticons/crying.png",
	@"/emoticons/drunk.png",
	@"/emoticons/kiss.png",
	@"/emoticons/surprised.png",
	@"/emoticons/tongue.png",
	@"/emoticons/winking.png",
	
	@"/emoticons/openfeint.png",
};

typedef enum {
	kHUDMessageActionShow = 9200 + 1,
	kHUDMessageActionTintTo,
} tHUDMessageAction;

@implementation KKHUDMessage

@synthesize duration, index, sourceEntity;

-(id) initWithMessage:(NSString *)message emoticon:(int)eid fontSize:(CGFloat)pointSize kind:(tHUDMessageKind)aKind duration:(float)seconds
{
	self = [super init];
	if (self) {
		kind = aKind;
		duration = seconds;
		
		ZFont *font = [[FontManager sharedManager] zFontWithName:UI_FONT_DEFAULT pointSize:SCALE_FONT(pointSize)];
		CGSize s = [message sizeWithZFont:font constrainedToSize:SCALE_SIZE(CGSizeMake(MESSAGE_MAX_WIDTH, MESSAGE_MAX_HEIGHT))];
		CGRect spriteFrame = CGRectMake (0, 0, 
										 s.width + SCALE_X(BUBBLE_BORDER * 3) + SCALE_X(EMOTICON_SIZE), 
										 s.height + SCALE_Y(BUBBLE_BORDER * 2));
		
		label = [CCLabel labelWithString:NSLocalizedString(message, @"message") 
							  dimensions:s 
							   alignment:UITextAlignmentLeft 
								fontName:UI_FONT_DEFAULT 
								fontSize:SCALE_FONT(pointSize)
				 ];
		[label.texture setAliasTexParameters];
		[label setAnchorPoint:ccp(0,0)];
		[label setPosition:SCALE_POINT(ccp((BUBBLE_BORDER * 2) + EMOTICON_SIZE, BUBBLE_BORDER))];
		[label setColor:ccc3(0,0,0)];
		[label setOpacity:0];
		[self addChild:label z:10];
		
		emoticon = [[CCSprite spriteWithFile:[KKGE pathForGraphic:emoticons[eid]]] retain];
		[emoticon.texture setAliasTexParameters];
//		[emoticon setOpacityModifyRGB:NO];
		[emoticon setOpacity:0];
		[emoticon setAnchorPoint:ccp(0,0.5)];
		[emoticon setPosition:ccp(SCALE_X(BUBBLE_BORDER), spriteFrame.size.height/2)];
		[emoticon setScaleX:SCALE_X(1)];
		[emoticon setScaleY:SCALE_Y(1)];
		[self addChild:emoticon z:20];
		
		[self setTexture:nil];
		[self setTextureRect:spriteFrame];
		[self setColor:ccc3(255,255,255)];
		[self setOpacity:0];
		
		sourceEntity = nil;
		origin = CGPointZero;
	}
	return self;
}

-(void) dealloc
{
//	KKLOG (@"");
	label = nil;
	emoticon = nil;
	sourceEntity = nil;
	
	[super dealloc];
}

#define LW 5
#define B (2 + LW/2)

-(void) drawMessageConnector
{
	if (sourceEntity) {
		origin = [sourceEntity centerPositionToDisplay];
	}
	
	switch (kind) {
		case kHUDMessageKindSay:
			break;
		case kHUDMessageKindThink:
			break;
	}
	
	CGSize s = [self contentSize];
	CGPoint a = [self anchorPoint];
	CGPoint d;
	CGPoint p = ccp(self.position.x - (s.width * a.x), self.position.y - (s.height * a.y));
	float x, y;
	
	if (origin.x < p.x) {
		x = p.x + B;
	} else if (origin.x > p.x + s.width) {
		x = p.x + s.width - B;
	} else {
		x = origin.x;
	}
	
	if (origin.y < p.y) {
		y = p.y + B;
	} else if (origin.y > p.y + s.height) {
		y = p.y + s.height - B;
	} else {
		y = origin.y;
	}
	
	d = ccp(x,y);

	if (self.opacity != 255)
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	ccColor3B c = self.color;
	int o = self.opacity;
	
	glColor4ub(c.r, c.g, c.b, o);
	glLineWidth (LW);
	ccDrawLine ([self convertToNodeSpace:origin], [self convertToNodeSpace:d]);
	
	if (self.opacity != 255)
		glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
}

-(void) draw
{
	if ((sourceEntity && [sourceEntity visible]) || !CGPointEqualToPoint(origin, CGPointZero)) {
		[self drawMessageConnector];
	}
	
	[super draw];
}

#define COLOR_DURATION 0.9

#define BACKGROUND_OPACITY 200
#define LABEL_OPACITY 255
#define EMOTICON_OPACITY 255

-(void) setLabelColor:(ccColor3B)c
{
	CCAction *a = [CCTintTo actionWithDuration:COLOR_DURATION red:c.r green:c.g blue:c.b];
	a.tag = kHUDMessageActionTintTo;
	[label stopActionByTag:kHUDMessageActionTintTo];
	[label runAction:a];
}

-(void) setEmoticonColor:(ccColor3B)c
{
	CCAction *a = [CCTintTo actionWithDuration:COLOR_DURATION red:c.r green:c.g blue:c.b];
	a.tag = kHUDMessageActionTintTo;
	[emoticon stopActionByTag:kHUDMessageActionTintTo];
	[emoticon runAction:a];
	[emoticon setColor:c];
}

-(void) setBackgroundColor:(ccColor3B)c
{
	CCAction *a = [CCTintTo actionWithDuration:COLOR_DURATION red:c.r green:c.g blue:c.b];
	a.tag = kHUDMessageActionTintTo;
	[self stopActionByTag:kHUDMessageActionTintTo];
	[self runAction:a];
	[self setColor:c];
}

-(void) setSourceEntity:(id)entity
{
	origin = CGPointZero;
	sourceEntity = entity;
}

-(void) setSourceOrigin:(CGPoint)pos
{
	sourceEntity = nil;
	origin = pos;
}

-(void) setShown:(BOOL)f
{
	int bgo, lo, eo;
	
	if (f) {
		bgo = BACKGROUND_OPACITY;
		lo = LABEL_OPACITY;
		eo = EMOTICON_OPACITY;
	} else {
		bgo = 0;
		lo = 0;
		eo = 0;
	}
	
	CCAction *bga = [CCFadeTo actionWithDuration:HUD_MESSAGE_SHOW_DURATION opacity:bgo];
	CCAction *la = [CCFadeTo actionWithDuration:HUD_MESSAGE_SHOW_DURATION opacity:lo];
	CCAction *ea = [CCFadeTo actionWithDuration:HUD_MESSAGE_SHOW_DURATION opacity:eo];
	bga.tag = kHUDMessageActionShow;
	la.tag = kHUDMessageActionShow;
	ea.tag = kHUDMessageActionShow;
	
	[self stopActionByTag:kHUDMessageActionShow];
	[label stopActionByTag:kHUDMessageActionShow];
	[emoticon stopActionByTag:kHUDMessageActionShow];
	
	[self runAction:bga];					
	[label runAction:la];					
	[emoticon runAction:ea];					
}

@end
