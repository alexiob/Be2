//
//  KKHUDButton.m
//  be2
//
//  Created by Alessandro Iob on 23/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "KKHUDButton.h"
#import "KKMacros.h"
#import "KKGameEngine.h"
#import "KKGraphicsManager.h"
#import "KKSoundManager.h"

typedef enum {
	kHBActionZoom = 1000 + 1,
} tHBAction;

@implementation KKHUDButtonLabel

#define BUTTON_LABEL_BORDER_X SCALE_X(4)
#define BUTTON_LABEL_BORDER_Y SCALE_Y(4)

#define DEFAULT_SCALE_DEFAULT SCALE_X(1.0)
#define DEFAULT_SCALE_SELECTED SCALE_X (3.0)

-(id) initWithString:(NSString*)text withSize:(int)p target:(id)t selector:(SEL)s
{
	CCSprite *background = [[CCSprite alloc] init];
	self = [super initFromNormalSprite:background
						selectedSprite:background
						disabledSprite:background
							   target:t 
							 selector:s
			];
	[background release];
	
	if (self) {
		runtimeFlags = 0;

		label = [CCLabel labelWithString:NSLocalizedString(text, @"hudButton")
							  dimensions:CGSizeZero 
							   alignment:UITextAlignmentCenter 
								fontName:UI_FONT_DEFAULT 
								fontSize:SCALE_FONT(p)
				 ];
		[label.texture setAliasTexParameters];
		[self addChild:label];
		
		CGSize ls = [label contentSize];
		CGRect r = CGRectMake (
							   0, 0, 
							   ls.width + BUTTON_LABEL_BORDER_X*2, 
							   ls.height + BUTTON_LABEL_BORDER_Y*2
							   );
		[background setContentSize:r.size];
		[background setTexture:nil];
		[background setTextureRect:r];
		[label setAnchorPoint:ccp (0.5, 0.5)];
		[label setPosition:ccp (r.size.width/2, r.size.height/2)];
		[self setLabelColor:ccc3(0,0,0)];
		[self setContentSize:r.size];
	}
	return self;
} 

-(void) dealloc
{
	[super dealloc];
}

-(void) setScale:(float)s
{
	[normalImage_ setScale:s];
}

- (void) setOpacity: (GLubyte)opacity
{
	[self.normalImage setOpacity:opacity];
}

-(void) setColor:(ccColor3B)color
{
	[self.normalImage setColor:color];
}

-(CCLabel *) label
{
	return label;
}

-(void) setLabel:(NSString *)text
{
	[label setString:NSLocalizedString(text, @"hudButton")];
}

-(void) setLabelColor:(ccColor3B)c
{
	[label setColor:c];
}

-(void) setLabelOpacity:(int)o
{
	[label setOpacity:o];
}

-(void) setLabelAnchorPoint:(CGPoint)p
{
	[label setAnchorPoint:p];
}

-(void) draw
{
	[self.normalImage draw];
}

#define SHAKE_SPEED 0.02
#define X1 10
#define Y1 0
#define X2 10
#define Y2 0
#define NUM_SHAKES 5

-(void) resetButtonRuntimeFlagClickFX
{
	runtimeFlags ^= kButtonRuntimeFlagClickFX;
	[super activate];
}

-(void) applyClickedEffects
{
	if (runtimeFlags & kButtonRuntimeFlagClickFX) return;
	runtimeFlags |= kButtonRuntimeFlagClickFX;
	
	CCMoveBy *ar0 = [CCMoveBy actionWithDuration:SHAKE_SPEED position:ccp (X1, Y1)];
	CCMoveBy *ar = [CCMoveBy actionWithDuration:SHAKE_SPEED position:ccp (X2, Y2)];
	CCMoveBy *al = [CCMoveBy actionWithDuration:SHAKE_SPEED position:ccp (-X2, -Y2)];
	CCMoveBy *al0 = [CCMoveBy actionWithDuration:SHAKE_SPEED position:ccp (-X1, -Y1)];
	CCSequence *as = [CCSequence actions:al, ar, nil];
	CCCallFunc *r = [CCCallFunc actionWithTarget:self selector:@selector(resetButtonRuntimeFlagClickFX)];
	CCSequence *a = [CCSequence actions:ar0, [CCRepeat actionWithAction:as times:NUM_SHAKES], al0, r, nil];
	
	[self runAction:a];
}

-(void) activate {
	if ([self isEnabled]) {
		[KKGE playSound:SOUND_BUTTON_ACTIVATE];
		[self applyClickedEffects];
	}
}

@end

@implementation KKHUDButtonImage

@synthesize scaleDefault, scaleSelected;

-(id) initWithFile:(NSString*)filename target:(id)t selector:(SEL)s
{
	self = [super initFromNormalImage:filename 
						selectedImage:filename 
						disabledImage:filename 
							   target:t 
							 selector:s
			];
	if (self) {
		scaleDefault = DEFAULT_SCALE_DEFAULT;
		scaleSelected = DEFAULT_SCALE_SELECTED;
		
		[self setScaleX:SCALE_X(1)];
		[self setScaleY:SCALE_Y(1)];
	}
	return self;
} 

-(void) selected
{
	if ([self isEnabled]) {		
		[super selected];
		[self stopActionByTag:kHBActionZoom];
		CCAction *zoomAction = [CCScaleTo actionWithDuration:0.1f scale:scaleSelected];
		zoomAction.tag = kHBActionZoom;
		[self runAction:zoomAction];
	}
}

-(void) unselected
{
	if ([self isEnabled]) {
		[super unselected];
		[self stopActionByTag:kHBActionZoom];
		CCAction *zoomAction = [CCScaleTo actionWithDuration:0.1f scale:scaleDefault];
		zoomAction.tag = kHBActionZoom;
		[self runAction:zoomAction];
	}
}

-(void) activate {
	if ([self isEnabled]) {
		[KKGE playSound:SOUND_BUTTON_ACTIVATE];
		[super activate];
	}
}

-(void) setScale:(float)s
{
	s = SCALE_X(s);
	[self.normalImage setScale:s];
	[self.selectedImage setScale:s];
	[self.disabledImage setScale:s];	
}

@end
