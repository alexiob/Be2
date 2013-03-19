//
//  KKLight.h
//  be2
//
//  Created by Alessandro Iob on 3/8/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"
#import "KKGridCell.h"
#import "KKEntityProtocol.h"

typedef enum {
	kLightKindRect,
} tLightKind;

typedef enum {
	kLightFlagBindToEntity = 1 << 0,
	kLightFlagBlink = 1 << 1,
	kLightFlagHardLight = 1 << 2,
	kLightFlagBlackLight = 1 << 3,
	kLightFlagAddOpacity = 1 << 4,
} tLightFlag;

@interface KKLight : NSObject {
	int lightID;
	BOOL enabled;
	BOOL visible;
	int kind;
	int flags;
	ccColor3B color;
	GLubyte opacity;
	CGSize size;
	float power;
	CGPoint position;
	
	id <KKEntityProtocol> entity;
	BOOL needsUpdate;
}

@property (readonly, nonatomic) int lightID;
@property (readwrite, nonatomic) BOOL needsUpdate;

@property (readwrite, nonatomic) BOOL enabled;
@property (readwrite, nonatomic) BOOL visible;
@property (readwrite, nonatomic) int kind;
@property (readwrite, nonatomic) int flags;
@property (readwrite, nonatomic) ccColor3B color;
@property (readwrite, nonatomic) GLubyte opacity;
@property (readwrite, nonatomic) CGSize size;
@property (readwrite, nonatomic) float power;
@property (readwrite, nonatomic) CGPoint position;
@property (readwrite, nonatomic, assign) id entity;

-(id) initWithID:(int)aID kind:(int)aKind;

-(BOOL) updateCells:(tKKGridCell *)gridCells gridWidth:(int)gridWidth gridHeight:(int)gridHeight cellWidth:(int)cellWidth cellHeight:(int)cellHeight dt:(ccTime)dt;

@end

