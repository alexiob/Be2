//
//  KKLight.m
//  be2
//
//  Created by Alessandro Iob on 3/8/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKLight.h"
#import "KKMacros.h"
#import "KKMath.h"
#import "KKScreen.h"
#import "KKPaddle.h"
#import "KKHero.h"

@implementation KKLight

@synthesize lightID, enabled, visible, kind, flags;
@synthesize color, opacity;
@synthesize size, power, position;
@synthesize entity;
@synthesize needsUpdate;

-(id) initWithID:(int)aID kind:(int)aKind
{
	self = [super init];
	if (self) {
		enabled = YES;
		visible = YES;
		
		lightID = aID;
		kind = aKind;
		needsUpdate = YES;
	}
	return self;
}

#pragma mark -
#pragma mark Properties

-(void) setEnabled:(BOOL)f
{
	needsUpdate = enabled != f;
	enabled = f;
}

-(void) setVisible:(BOOL)f
{
	needsUpdate = visible != f;
	visible = f;
}

-(void) setFlags:(int)f
{
	needsUpdate = flags != f;
	flags = f;
}

-(void) setColor:(ccColor3B)c
{
	needsUpdate = YES;
	color = c;
}

-(void) setOpacity:(GLubyte)o
{
	needsUpdate = opacity != o;
	opacity = o;
}

-(void) setSize:(CGSize)s
{
	needsUpdate = YES;
	size = s;
}

-(void) setPosition:(CGPoint)p
{
	needsUpdate = YES;
	position = p;
}

-(void) setPower:(float)p
{
	needsUpdate = power != p;
	power = p;
}

-(void) setEntity:(id)e
{
	needsUpdate = entity != e;
	entity = e;
}

#pragma mark -
#pragma mark Render

#define SET_CELL(__I__, __C__, __O__) \
gridCells[__I__].color.r = (gridCells[__I__].color.r + __C__.r) & 255; \
gridCells[__I__].color.g = (gridCells[__I__].color.g + __C__.g) & 255; \
gridCells[__I__].color.b = (gridCells[__I__].color.b + __C__.b) & 255; \
int oo = (int)gridCells[__I__].opacity; \
int to; \
if (flags & kLightFlagAddOpacity) to = (oo + (int)__O__);  \
else to = (oo - (int)__O__); \
if (to < 0) to = 0; \
else if (to > 255) to = 255; \
gridCells[__I__].opacity = to;

#define SET_HLINE(__Y__) \
if (__Y__ >= 0 && __Y__ < gridHeight) { \
	int yi = gridWidth * __Y__; \
	for (int x = sx; x < sx + width; x++) { \
		if (x >= 0 && x < gridWidth) { \
			int i = yi + x; \
			SET_CELL (i, color, o) \
		} \
	} \
}

#define SET_VLINE(__X__) \
if (__X__ >= 0 && __X__ < gridWidth) { \
	for (int y = sy + 1; y < sy + height - 1; y++) { \
		if (y >= 0 && y < gridHeight) { \
			int i = y * gridWidth + __X__; \
			SET_CELL (i, color, o) \
		} \
	} \
}

#define SET_VLINE_FULL(__X__) \
if (__X__ >= 0 && __X__ < gridWidth) { \
	for (int y = sy; y < sy + height; y++) { \
		if (y >= 0 && y < gridHeight) { \
			int i = y * gridWidth + __X__; \
			SET_CELL (i, color, o) \
		} \
	} \
}

-(void) drawRect:(tKKGridCell *)gridCells gridWidth:(int)gridWidth gridHeight:(int)gridHeight opacity:(GLubyte)o width:(int)width height:(int)height position:(CGPoint)pos
{
	int sx = pos.x;
	int sy = pos.y;
	if (width == 1) {
		sy -= height/2;
		SET_VLINE_FULL (sx);
	} else if (height == 1)	{
		sx -= width/2;
		SET_HLINE (sy);
	} else {
		sx -= width/2;
		sy -= height/2;
		SET_HLINE (sy);
		SET_HLINE ((sy + height - 1));
		SET_VLINE (sx);
		SET_VLINE ((sx + width - 1));
	}
}

-(BOOL) updateCells:(tKKGridCell *)gridCells gridWidth:(int)gridWidth gridHeight:(int)gridHeight cellWidth:(int)cellWidth cellHeight:(int)cellHeight dt:(ccTime)dt
{
	needsUpdate = NO;
	
	if (!enabled) return needsUpdate;
	
	CGPoint pos;
	
	if (flags & kLightFlagBindToEntity && entity != nil) {
		if ([entity isKindOfClass:[KKScreen class]] || [entity isKindOfClass:[KKPaddle class]]) {
			pos = [entity positionToDisplay];
			pos = ccp ((int) (pos.x / cellWidth) + position.x, (int) (pos.y / cellHeight) + position.y);
		} else if ([entity isKindOfClass:[KKHero class]]) {
			pos = [entity centerPositionToDisplay];
			pos = ccp ((int) (pos.x / cellWidth), (int) (pos.y / cellHeight));
		}
		needsUpdate = YES;
	} else {
		pos = position;
	}
	
	if (flags & kLightFlagBlink) {
		needsUpdate = YES;
		
		if (RANDOM_INT (0, 10) < 1) return needsUpdate;
	}
	
	if (!visible) return needsUpdate;
	
	switch (kind) {
		case kLightKindRect:
		default:
		{
			int m = MIN (size.width, size.height);
			float minOpacity = 255;
			float oStep;
			float o = 0;
			
			if (flags & kLightFlagBlackLight) {
				o = 255;
				minOpacity = 0;
			}
			
			if (flags & kLightFlagHardLight) {
				oStep = (255 - opacity);
				minOpacity = oStep;
			} else {
				oStep = (255 - opacity) / (float) (m/2);
			}
			
			for (int d=0; d < m; d+=2) {
				int w = (int)size.width - d;
				int h = (int)size.height - d;
				
				float p = m - d;
				if (p > 1.0) {
					p = (float)pow ((m-d)/2, 2);
				}
				p = 255.0 * (power / p);
				
				if (flags & kLightFlagBlackLight) {
					o -= oStep + p;
					if (o < minOpacity) o = minOpacity;
				} else {
					o += oStep + p;
					if (o > minOpacity) o = minOpacity;
				}

				[self drawRect:gridCells gridWidth:gridWidth gridHeight:gridHeight opacity:(GLubyte)o width:w height:h position:pos];
			}
			break;
		}
	}
	
	return needsUpdate;
}

@end

