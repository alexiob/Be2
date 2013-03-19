//
//  HUDGrid.m
//  Be2
//
//  Created by Alessandro Iob on 9/8/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKHUDGrid.h"
#import "KKMacros.h"

#define GRID_SCALE_SPEED 0.7
#define GRID_SCALE_SHOW 1.0
#define GRID_SCALE_HIDE 13.0
#define GRID_FADE_SPEED GRID_SCALE_SPEED

#define GRID_OPACITY 60

enum {
	kActionShow = 50001,
	kActionFade,
	kActionBlink,
};

@implementation KKHUDGrid

@synthesize gridOpacity, defaultGridOpacity;

-(id) initWithColor4B:(ccColor4B)color
{
	self = [super initWithColor4B:color];
	
	if (self) {
		CGSize ws = [[CCDirector sharedDirector] winSize];

		gridCellSize = 32;
		gridWidth = (ws.width/gridCellSize) + 2;
		gridHeight = (ws.height/gridCellSize) + 2;
		totalGridVertices = (gridWidth * gridHeight);
		totalGridColors = (gridWidth * gridHeight);
		gridOrigin = ccp (-gridCellSize/2, -gridCellSize/2);
		gridSize = CGSizeMake (gridCellSize * gridWidth, gridCellSize * gridHeight);
		
		defaultGridOpacity = GRID_OPACITY;
		gridOpacity = defaultGridOpacity;

		gridVertices = calloc (sizeof (GLfloat), totalGridVertices * 2);
		gridColors = calloc (sizeof (GLubyte), totalGridColors * 4);
		
		[self updateGrid];
		[self updateColor];
		
		[self setAnchorPoint:ccp (0, 0)];
		[self setPosition:ccp (0, 0)];
	}
	return self;
}

-(void) dealloc
{
	free (gridVertices);
	free (gridColors);
	
	[super dealloc];
}
-(void) updateColor
{
	for (NSUInteger i=0; i < totalGridColors; i++)
	{
		NSUInteger idx = i * 4;
		
		gridColors[idx] = [self color].r;
		gridColors[idx + 1] = [self color].g;
		gridColors[idx + 2] = [self color].b;
		gridColors[idx + 3] = [self opacity];
	}
}

-(void) updateGrid
{
	int c = 0;
	for (int y=0; y < gridHeight; y++, c+=4) {
		gridVertices[c] = (GLfloat) gridOrigin.x;
		gridVertices[c+1] = (GLfloat) y * gridCellSize + gridOrigin.y;
		gridVertices[c+2] = (GLfloat) gridSize.width;
		gridVertices[c+3] = gridVertices[c+1];
	}	
	for (int x=0; x < gridWidth; x++, c+=4) {
		gridVertices[c] = (GLfloat) x * gridCellSize + gridOrigin.x;
		gridVertices[c+1] = (GLfloat) gridOrigin.y;
		gridVertices[c+2] = gridVertices[c];
		gridVertices[c+3] = (GLfloat) gridSize.height;
	}
}

-(void) draw
{		
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glVertexPointer (2, GL_FLOAT, 0, gridVertices);
	glColorPointer (4, GL_UNSIGNED_BYTE, 0, gridColors);
	
	if (gridOpacity != 255)
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glDrawArrays (GL_LINES, 0, totalGridVertices);
	
	if (gridOpacity != 255)
		glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);	
}

-(void) setShow:(BOOL)b
{
	[self stopActionByTag:kActionShow];
	[self stopActionByTag:kActionFade];
	
	CCAction *action;
	
	if (b) {
		action = [CCSpawn actions:
				  [CCFadeTo actionWithDuration:GRID_FADE_SPEED opacity:defaultGridOpacity],
				  [CCScaleTo actionWithDuration:GRID_SCALE_SPEED scale:GRID_SCALE_SHOW],
				  [CCMoveTo actionWithDuration:GRID_SCALE_SPEED position:ccp(0, 0)],
				  nil
		];
	} else {
		CGSize ws = [[CCDirector sharedDirector] winSize];
		action = [CCSpawn actions:
				  [CCFadeTo actionWithDuration:GRID_FADE_SPEED opacity:0],
				  [CCScaleTo actionWithDuration:GRID_SCALE_SPEED scale:GRID_SCALE_HIDE],
				  [CCMoveTo actionWithDuration:GRID_SCALE_SPEED position:ccp(ws.width/2 * -GRID_SCALE_HIDE, ws.height/2 * -GRID_SCALE_HIDE)],
				  nil
		];
	}
	action.tag = kActionShow;
	[self runAction:action];
}

-(void) blinkWithDuration:(float)duration withBlinks:(int)blinks
{
	[self stopActionByTag:kActionBlink];
	CCAction *action = [CCSequence actions:[CCBlink actionWithDuration:duration blinks:blinks],
					  (self.visible ? [CCShow action] : [CCHide action]),
					  nil
	];
	action.tag = kActionBlink;
	[self runAction:action];
}

-(void) setColor:(ccColor3B)c
{
	[super setColor:c];
	[self updateColor];
}

-(void) setOpacity:(GLubyte)o
{
	if (o > defaultGridOpacity) o = GRID_OPACITY;
	
	gridOpacity = o;
	[super setOpacity:gridOpacity];
}

@end
