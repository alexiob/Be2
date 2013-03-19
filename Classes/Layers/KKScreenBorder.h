//
//  KKScreenBorder.h
//  be2
//
//  Created by Alessandro Iob on 18/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "cocos2d.h"

typedef enum {
	kScreenBorderActionFadeTo = 500 + 1,
	kScreenBorderActionTintTo,
} tScreenBorderAction;

typedef enum {
	kScreenBorderSideTop = 0,
	kScreenBorderSideBottom,
	kScreenBorderSideLeft,
	kScreenBorderSideRight
} tScreenBorderSide;

@interface KKScreenBorder : CCColorLayer {
	tScreenBorderSide side;
	CGPoint homePosition;
	BOOL active;
}

@property (readwrite, nonatomic) BOOL active;

-(id) initWithSide:(tScreenBorderSide)aSide size:(float)aSize color:(ccColor3B)c opacity:(int)o;

-(void) setActive:(BOOL)f withDuration:(float)duration;
-(void) setColor:(ccColor3B)c withDuration:(float)duration;
-(void) setSize:(float)aSize;

@end
