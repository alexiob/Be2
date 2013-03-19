//
//  KKMath.h
//  Be2
//
//  Created by Alessandro Iob on 10/13/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#include <stdlib.h>
#import "ccTypes.h"
#import "CGPointExtension.h"

#define EPSILON 0.000001
#define FLOAT_EQ(x,v) (((v - EPSILON) < x) && (x < ( v + EPSILON)))
#define FLOAT_EQ_ZERO(x) (((0.0 - EPSILON) < x) && (x < ( 0.0 + EPSILON)))

#define	DegreesToRadians(x) ((x) * M_PI / 180.0)
#define	RadiansToDegrees(x) ((x) * 180.0 / M_PI)
#define	Norm(X, Y, Z) (sqrt((X)*(X) + (Y)*(Y) + (Z)*(Z)))
#define Sign(X) ((X < 0.0f) ? -1 : ((X == 0.0f) ? 0 : 1))
#define PSign(X) ((X <= 0.0f) ? -1 : 1)
#define Clamp(X, A, B) ((X < A) ? A : ((X > B) ? B : X))

#define VERTEX3F_COORD_AT_INDEX(P, X) ((float*)&P)[X]

#define rectLeft(__R__) __R__.origin.x
#define rectRight(__R__) (__R__.origin.x + __R__.size.width)
#define rectBottom(__R__) __R__.origin.y
#define rectTop(__R__) (__R__.origin.y + __R__.size.height)
#define rectNext(__R__,__S__,__DT__) CGRectMake (__R__.origin.x + (__S__.x * __DT__), __R__.origin.y + (__S__.y * __DT__), __R__.size.width, __R__.size.height)
#define rectPrev(__R__,__S__,__DT__) CGRectMake (__R__.origin.x - (__S__.x * __DT__), __R__.origin.y - (__S__.y * __DT__), __R__.size.width, __R__.size.height)

#define RANDOM_SEED() srandom (time (NULL))
#define RANDOM_INT(__MIN__, __MAX__) ((__MIN__) + random() % ((__MAX__+1) - (__MIN__)))

void initRandomNumberGenerator (float seed);
float baseBinomial ();
float randomBinomial ();
int randomNormal (int mean, int amplitude);

static inline ccVertex3F ccVertex3FMult (ccVertex3F p1, float l)
{
	return (ccVertex3F) {p1.x * l, p1.y * l, p1.z * l};
}
