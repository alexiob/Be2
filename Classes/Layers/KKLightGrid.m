//
//  KKLightGrid.m
//  be2
//
//  Created by Alessandro Iob on 3/8/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKLightGrid.h"
#import "KKMacros.h"
#import "CGPointExtension.h"
#import "KKColorUtilities.h"

#define SIZE_VERTEX 2
#define VERTICES_PER_CELL (3 * 2)
#define SIZE_COLOR 4
#define COLORS_PER_CELL VERTICES_PER_CELL
#define MIN_VISIBLE_OPACITY 10

@implementation KKLightGrid

@synthesize lights;
@synthesize cellWidth, cellHeight, gridWidth, gridHeight;

-(id) initWithCellSize:(CGSize)cs
{
	self = [super initWithColor4B:ccc4 (0, 0, 0, 0)];
	
	if (self) {
		CGSize ws = [[CCDirector sharedDirector] winSize];
		
		cellWidth = cs.width;
		cellHeight = cs.height;
		gridWidth = ceil(ws.width / (float)cellWidth);
		gridHeight = ceil(ws.height / (float)cellHeight);
		
		totalGridCells = gridWidth * gridHeight;
		gridCells = calloc (sizeof (tKKGridCell), totalGridCells);
		
		totalGridVertices = gridWidth * gridHeight * VERTICES_PER_CELL;
		gridVertices = calloc (sizeof (GLfloat), totalGridVertices * SIZE_VERTEX);
		
		totalGridColors = gridWidth * gridHeight * COLORS_PER_CELL;
		gridColors = calloc (sizeof (GLubyte), totalGridColors * SIZE_COLOR);
		
		[self setupGridVertices];
#if !TARGET_IPHONE_SIMULATOR
		[self initGridVBO];
#endif
		[self updateGridColors];
		
		lights = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
		highestLightID = 0;
		
//		baseLightColor = ccc3 (0, 0, 0);
//		baseLightOpacity = 255;
		[self setColor:ccc3 (0, 0, 0)];
		[self setOpacity:255];
		
		[self setAnchorPoint:ccp (0, 0)];
		[self setPosition:ccp (0, 0)];
	}
	return self;
}

-(void) dealloc
{
	[lights release];
	
	[self destroyGridVBO];
	
	free (gridCells);
	free (gridVertices);
	free (gridColors);
	
	[super dealloc];
}

#pragma mark -
#pragma mark Properties

-(void) setOpacity:(GLubyte)o
{
	[super setOpacity:o];
	
	[self updateLights:0 force:YES];
	self.visible = o > MIN_VISIBLE_OPACITY;
}

#pragma mark -
#pragma mark Grid

-(void) updateGridColors
{
	if (self.opacity == 0) return;
	
	for (int i=0; i < totalGridCells; i++) {
		int idx = i * SIZE_COLOR * COLORS_PER_CELL;
		for (int c=0; c < COLORS_PER_CELL; c++) {
			int p = idx + (c * SIZE_COLOR);
			
			gridColors[p++] = gridCells[i].color.r;
			gridColors[p++] = gridCells[i].color.g;
			gridColors[p++] = gridCells[i].color.b;
			gridColors[p] = gridCells[i].opacity;
		}
	}
#if !TARGET_IPHONE_SIMULATOR
	[self updateGridColorsVBO];
#endif
}

-(void) updateGridColorsVBO
{
#if !TARGET_IPHONE_SIMULATOR
	glBindBuffer (GL_ARRAY_BUFFER, gridColorsVBO);
	glBufferData (GL_ARRAY_BUFFER, totalGridColorsSize, gridColors, GL_STATIC_DRAW);
	glBindBuffer (GL_ARRAY_BUFFER, 0);
#endif
}

-(void) setupGridVertices
{
	for (int y=0; y < gridHeight; y++) {
		int yIdx = (y * gridWidth) * SIZE_VERTEX * VERTICES_PER_CELL;
		float yPos = y * cellHeight;
		
		for (int x=0; x < gridWidth; x++) {
			int c = yIdx + (x * SIZE_VERTEX * VERTICES_PER_CELL);
			int v = c;
			
			// triangle 1
			
			// v0 - bl
			gridVertices[v++] = (GLfloat) x * cellWidth; 
			gridVertices[v++] = yPos;
			
			// v1 - tl
			gridVertices[v++] = (GLfloat) gridVertices[c];
			gridVertices[v++] = (GLfloat) gridVertices[c+1] + cellHeight;
			
			// v2 - tr
			gridVertices[v++] = (GLfloat) gridVertices[c] + cellWidth;
			gridVertices[v++] = (GLfloat) gridVertices[c+1] + cellHeight;
			
			// triangle 2
			
			// v0 - bl
			gridVertices[v++] = (GLfloat) gridVertices[c];
			gridVertices[v++] = (GLfloat) gridVertices[c+1];
			
			// v1 - tr
			gridVertices[v++] = (GLfloat) gridVertices[c] + cellWidth;
			gridVertices[v++] = (GLfloat) gridVertices[c+1] + cellHeight;
			
			// v2 - br
			gridVertices[v++] = (GLfloat) gridVertices[c] + cellWidth;
			gridVertices[v++] = (GLfloat) gridVertices[c+1];
		}
	}
}

-(void) initGridVBO
{
#if !TARGET_IPHONE_SIMULATOR
	totalGridVerticesSize = totalGridVertices * SIZE_VERTEX * sizeof (GLfloat);
	totalGridColorsSize = totalGridColors * SIZE_COLOR * sizeof (GLubyte);
	
	glGenBuffers (1, &gridVerticesVBO);
	glBindBuffer (GL_ARRAY_BUFFER, gridVerticesVBO);
	glBufferData (GL_ARRAY_BUFFER, totalGridVerticesSize, gridVertices, GL_STATIC_DRAW);
	glBindBuffer (GL_ARRAY_BUFFER, 0);
	
	glGenBuffers (1, &gridColorsVBO);
	[self updateGridColorsVBO];
#endif
}

-(void) destroyGridVBO
{
#if !TARGET_IPHONE_SIMULATOR
	glDeleteBuffers (1, &gridVerticesVBO);
	glDeleteBuffers (1, &gridColorsVBO);
#endif
}

-(void) draw
{		
	// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
	// Needed states: GL_VERTEX_ARRAY, GL_COLOR_ARRAY
	// Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY
	
	if (self.opacity < MIN_VISIBLE_OPACITY) return;
//	KKLOG (@"visible:%d opacity:%d", self.visible, self.opacity);
	
	glDisableClientState (GL_TEXTURE_COORD_ARRAY);
	glDisable (GL_TEXTURE_2D);

#if TARGET_IPHONE_SIMULATOR
	glVertexPointer (SIZE_VERTEX, GL_FLOAT, 0, gridVertices);
	glColorPointer (SIZE_COLOR, GL_UNSIGNED_BYTE, 0, gridColors);
#else
	glBindBuffer (GL_ARRAY_BUFFER, gridVerticesVBO);
	glVertexPointer (SIZE_VERTEX, GL_FLOAT, 0, NULL);
	glBindBuffer (GL_ARRAY_BUFFER, gridColorsVBO);
	glColorPointer (SIZE_COLOR, GL_UNSIGNED_BYTE, 0, NULL);
#endif
	
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glDrawArrays (GL_TRIANGLES, 0, totalGridVertices);

	glBlendFunc (CC_BLEND_SRC, CC_BLEND_DST);

	glBindBuffer (GL_ARRAY_BUFFER, 0);
	
	glEnableClientState (GL_TEXTURE_COORD_ARRAY);
	glEnable (GL_TEXTURE_2D);	
}

#pragma mark -
#pragma mark Lights

-(KKLight *) addLightWithID:(int)aID kind:(int)aKind
{
	if (aID == -1) aID = highestLightID + 1;
	if (aID > highestLightID) highestLightID = aID;
	
	KKLight *light = [[[KKLight alloc] initWithID:aID kind:aKind] autorelease];
	[lights setObject:light forKey:[NSNumber numberWithInt:aID]];
	lightsNeedUpdate = YES;

	return light;
}

-(void) removeLightWithID:(int)aID
{
	NSNumber *key = [NSNumber numberWithInt:aID];
	
	if ([lights objectForKey:key]) {
		[lights removeObjectForKey:key];
		
		lightsNeedUpdate = YES;
	}
}

-(KKLight *) lightWithID:(int)aID
{
	NSNumber *key = [NSNumber numberWithInt:aID];
	
	return [lights objectForKey:key];
}

-(void) setLightWithID:(int)aID visible:(BOOL)f
{
	KKLight *l = [self lightWithID:aID];
	
	if (l) {
		if (l.visible != f) {
			l.visible = f;
			l.needsUpdate = YES;
		}
	}
}

-(void) resetColor:(ccColor3B)aColor andOpacity:(GLubyte)anOpacity
{
	[self setColor:aColor];
	[self setOpacity:anOpacity];
	
	[self updateLights:0 force:YES];
}

-(void) resetColorAndOpacity:(BOOL)update
{
	[self setCellsColor:self.color opacity:self.opacity update:update];
}

-(void) fadeColorAndOpacity:(ccTime)dt update:(BOOL)update
{
	for (int i=0; i < totalGridCells; i++) {
		if (!ccc3IsEqual(gridCells[i].color, self.color)) 
			gridCells[i].color = ccc3Lerp(gridCells[i].color, self.color, dt);
		if (gridCells[i].opacity != self.opacity)
			gridCells[i].opacity += (self.opacity - gridCells[i].opacity) * dt;
	}
	if (update) [self updateGridColors];	
}

-(void) updateLights:(ccTime)dt force:(BOOL)force
{
	if (self.opacity == 0) return;
	
	if (!force && !lightsNeedUpdate) {
		for (KKLight *light in [lights allValues]) {
			if ([light needsUpdate]) {
				force = YES;
				break;
			}
		}
	}
	
	if (force || lightsNeedUpdate) {
		lightsNeedUpdate = NO;
	
		[self resetColorAndOpacity:NO];
//		[self fadeColorAndOpacity:0.1 update:NO];
		
		for (KKLight *light in [lights allValues]) {
			[light updateCells:gridCells gridWidth:gridWidth gridHeight:gridHeight cellWidth:cellWidth cellHeight:cellHeight dt:dt];
		}
		[self updateGridColors];
	}
}

#pragma mark -
#pragma mark Cells

-(void) setCellsColor:(ccColor3B)c opacity:(GLubyte)o update:(BOOL)f
{
	for (int i=0; i < totalGridCells; i++) {
		gridCells[i].color = c;
		gridCells[i].opacity = o;
	}
	if (f) [self updateGridColors];
}

-(tKKGridCell *) cellAtPosition:(CGPoint)pos
{
	return [self cellAtX:pos.x y:pos.y];
}

-(tKKGridCell *) cellAtX:(int)x y:(int)y
{
	return &gridCells[x + y * gridHeight];
}

-(void) setCellAtX:(int)x y:(int)y color:(ccColor3B)c opacity:(GLubyte)o update:(BOOL)f
{
	int i = x + y * gridWidth;
	
	gridCells[i].color = c;
	gridCells[i].opacity = o;
	
	if (f) {
		int idx = i * SIZE_COLOR * COLORS_PER_CELL;
		for (int c=0; c < COLORS_PER_CELL; c++) {
			int p = idx + (c * SIZE_COLOR);
			
			gridColors[p++] = gridCells[i].color.r;
			gridColors[p++] = gridCells[i].color.g;
			gridColors[p++] = gridCells[i].color.b;
			gridColors[p] = gridCells[i].opacity;
		}
		
#if !TARGET_IPHONE_SIMULATOR
		[self updateGridColorsVBO];
#endif
	}	
}

@end
