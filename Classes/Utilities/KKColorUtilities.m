//
//  KKColorUtilities.m
//  be2
//
//  Created by Alessandro Iob on 2/4/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKColorUtilities.h"

BOOL ccc3IsEqual (ccColor3B c1, ccColor3B c2)
{
	return c1.r == c2.r && c1.g == c2.g && c1.b == c2.b;
}

ccColor3B ccc3Lerp (ccColor3B cFrom, ccColor3B cTo, ccTime dt)
{
	return ccc3(cFrom.r + (cTo.r - cFrom.r) * dt, cFrom.g + (cTo.g - cFrom.g) * dt, cFrom.b + (cTo.b - cFrom.b) * dt);
}
