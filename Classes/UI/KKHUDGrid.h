//
//  HUDGrid.h
//  Be2
//
//  Created by Alessandro Iob on 9/8/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"

@interface KKHUDGrid : CCColorLayer {
	int gridWidth;
	int gridHeight;
	int totalGridVertices;
	int totalGridColors;
	CGPoint gridOrigin;
	CGSize gridSize;
	float gridCellSize;
	
	GLfloat *gridVertices;
	GLubyte *gridColors;

	GLubyte defaultGridOpacity;
	GLubyte gridOpacity;
}

@property (nonatomic, readwrite) GLubyte defaultGridOpacity;
@property (nonatomic, readwrite) GLubyte gridOpacity;

-(void) updateGrid;
-(void) updateColor;

-(void) setShow:(BOOL)b;
-(void) blinkWithDuration:(float)duration withBlinks:(int)blinks;

-(void) setColor:(ccColor3B)c;
-(void) setOpacity:(GLubyte)o;

@end
