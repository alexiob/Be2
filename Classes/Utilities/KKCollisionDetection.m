//
//  KKCollisionDetection.m
//  be2
//
//  Created by Alessandro Iob on 2/18/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKCollisionDetection.h"
#import "KKMacros.h"
#import "KKMath.h"

#define collisionX(__R1__,__R2__,__I__) (1.0 / (__R1__.size.width + __R2__.size.width)) * ABS (__I__.origin.x - __R2__.origin.x)
#define collisionY(__R1__,__R2__,__I__) (1.0 / (__R1__.size.height + __R2__.size.height)) * ABS (__I__.origin.y - __R2__.origin.y)
#define logCollisionX(__R1__,__R2__,__I__) KKLOG (@"collisionX (%f + %f (%f), ABS(%f - %f) (%f)",__R1__.size.width, __R2__.size.width, (__R1__.size.width + __R2__.size.width), __I__.origin.x, __R2__.origin.x,ABS (__I__.origin.x - __R2__.origin.x))
#define logCollisionY(__R1__,__R2__,__I__) KKLOG (@"collisionY (%f + %f (%f), ABS(%f - %f) (%f)",__R1__.size.height, __R2__.size.height, (__R1__.size.height + __R2__.size.height), __I__.origin.y, __R2__.origin.y,ABS (__I__.origin.y - __R2__.origin.y))

int whereIsRectForRect (CGRect r1, CGRect r2)
{
	int side = kSideNone;

	float r1MidX = CGRectGetMidX (r1);
	float r1MidY = CGRectGetMidY (r1);
	
	if (r1MidX <= rectLeft (r2)) side |= kSideLeft;
	if (r1MidX >= rectRight (r2)) side |= kSideRight;
	if (r1MidY <= rectBottom (r2)) side |= kSideBottom;
	if (r1MidY >= rectTop (r2)) side |= kSideTop;
	
	return side;
}

int checkCollisionBetweenRects (CGRect r1, CGPoint s1, CGRect r2, CGPoint s2, float dt, CGPoint *collision)
{
	int hitSide = kSideNone;

	CGRect r1Next = rectNext (r1, s1, dt);
	CGRect r2Next = rectNext (r2, s2, dt);
	CGRect intersection = CGRectIntersection (r1Next, r2Next);
	BOOL ib = CGRectIsEmpty (intersection);
	
	if (ib && !CGRectIsEmpty (CGRectIntersection (r1, r2))) {
		r1Next = r1;
		r2Next = r2;
	} else if (ib) {
		return hitSide;
	}

	float r1MidX = CGRectGetMidX (r1);
	float r1MidY = CGRectGetMidY (r1);

	BOOL r1IsRight = r1MidX >= rectRight (r2);
	BOOL r1IsTop = r1MidY >= rectTop (r2);
	BOOL r1IsLeft = r1MidX <= rectLeft (r2);
	BOOL r1IsBottom = r1MidY <= rectBottom (r2);
	
	if (r1IsTop && (rectBottom (r1Next) <= rectTop (r2Next))) {
		hitSide |= kSideTop;
		collision->x = collisionX (r1Next, r2Next, intersection);
	} else if (r1IsBottom && (rectTop (r1Next) >= rectBottom (r2Next))) {
		hitSide |= kSideBottom;	
		collision->x = collisionX (r1Next, r2Next, intersection);
	}
	
	if (r1IsRight && (rectLeft (r1Next) <= rectRight (r2Next))) {
		hitSide |= kSideRight;	
		collision->y = collisionY (r1Next, r2Next, intersection);
	} else if (r1IsLeft && (rectRight (r1Next) >= rectLeft (r2Next)))  {
		hitSide |= kSideLeft;	
		collision->y = collisionY (r1Next, r2Next, intersection);
	}

#ifdef KK_DEBUG_COLLISION
	if (hitSide == kSideNone) {
		KKLOG (@"unhandled r2r collision:\n\tr1=%@, s1=%@f, r2=%@, s1=%@, dt=%f\n\tmid=(%f, %f) %r=%d t=%d l=%d b=%d", 
			   NSStringFromCGRect(r1),
			   NSStringFromCGPoint(s1),
			   NSStringFromCGRect(r2),
			   NSStringFromCGPoint(s2),
			   dt,
			   
			   r1MidX, r1MidY,
			   r1IsRight, r1IsTop, r1IsLeft, r1IsBottom
			   );
	}
#endif
	return hitSide;
}


int checkCollisionRectWithContainerRect (CGRect r1, CGRect r2)
{
	int hitSide = kSideNone;

	if (rectLeft (r1) < rectLeft (r2)) hitSide |= kSideLeft;
	else if (rectRight (r1) >= rectRight (r2)) hitSide |= kSideRight;

	if (rectBottom (r1) < rectBottom (r2)) hitSide |= kSideBottom;
	else if (rectTop (r1) >= rectTop (r2)) hitSide |= kSideTop;
	
	return hitSide;
}
