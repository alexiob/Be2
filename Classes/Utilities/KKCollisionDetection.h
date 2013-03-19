//
//  KKCollisionDetection.h
//  be2
//
//  Created by Alessandro Iob on 2/18/10.
//  Copyright 2010 Kismik. All rights reserved.
//

typedef enum {
	kSideNone = 0,
	kSideLeft = 1 << 0,
	kSideTop = 1 << 1,
	kSideRight = 1 << 2,
	kSideBottom = 1 << 3,
} tSide;

int whereIsRectForRect (CGRect r1, CGRect r2);
int checkCollisionBetweenRects (CGRect r1, CGPoint s1, CGRect r2, CGPoint s2, float dt, CGPoint *collision);
int checkCollisionRectWithContainerRect (CGRect r1, CGRect r2);

