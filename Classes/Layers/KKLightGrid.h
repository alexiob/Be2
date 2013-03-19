//
//  KKLightGrid.h
//  be2
//
//  Created by Alessandro Iob on 3/8/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"
#import "KKLight.h"
#import "KKGridCell.h"

@interface KKLightGrid : CCColorLayer {
	int cellWidth;
	int cellHeight;
	int gridWidth;
	int gridHeight;

	int totalGridCells;
	tKKGridCell *gridCells;
	
	int totalGridVertices;
	GLfloat *gridVertices;
	int totalGridVerticesIndex;
	GLshort *gridVerticesIndex;
	int totalGridColors;
	GLubyte *gridColors;
	
	GLuint gridVerticesVBO;
	GLuint gridColorsVBO;
	int totalGridVerticesSize;
	int totalGridColorsSize;
	
	NSMutableDictionary *lights;
	BOOL lightsNeedUpdate;
	int highestLightID;
}

@property (readonly, nonatomic) NSMutableDictionary *lights;
@property (readonly, nonatomic) int cellWidth;
@property (readonly, nonatomic) int cellHeight;
@property (readonly, nonatomic) int gridWidth;
@property (readonly, nonatomic) int gridHeight;

-(id) initWithCellSize:(CGSize)cs;
-(void) updateGridColors;
-(void) setupGridVertices;
-(void) initGridVBO;
-(void) destroyGridVBO;
-(void) updateGridColorsVBO;

-(void) setCellsColor:(ccColor3B)c opacity:(GLubyte)o update:(BOOL)f;
-(tKKGridCell *) cellAtPosition:(CGPoint)pos;
-(tKKGridCell *) cellAtX:(int)x y:(int)y;
-(void) setCellAtX:(int)x y:(int)y color:(ccColor3B)c opacity:(GLubyte)o update:(BOOL)f;

-(KKLight *) addLightWithID:(int)aID kind:(int)aKind;
-(void) removeLightWithID:(int)aID;
-(KKLight *) lightWithID:(int)aID;
-(void) setLightWithID:(int)aID visible:(BOOL)f;

-(void) resetColor:(ccColor3B)aColor andOpacity:(GLubyte)anOpacity;
-(void) resetColorAndOpacity:(BOOL)update;
-(void) updateLights:(ccTime)dt force:(BOOL)force;

@end
