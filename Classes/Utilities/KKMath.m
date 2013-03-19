//
//  KKMath.m
//  Be2
//
//  Created by Alessandro Iob on 10/13/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKMath.h"

void initRandomNumberGenerator (float seed)
{
	if (seed == 0) seed = time (NULL);
	srandom (seed);
}

float baseBinomial ()
{
	float base = 0.0f;
	float r = rand () % 100000;
	
	if (r < 13) base = -4.0f;
	else if (r < 575) base = -3.0f;
	else if (r < 6823) base = -2.0f;
	else if (r < 31126) base = -1.0f;
	else if (r < 68874) base = 0.0f;
	else if (r < 93177) base = 1.0f;
	else if (r < 99425) base = 2.0f;
	else if (r < 99987) base = 3.0f;
	else base = 4.0f;

	return base;
}

float randomBinomial ()
{
	return baseBinomial () + ((float) rand() / RAND_MAX) - 0.5f;
}

int randomNormal (int mean, int amplitude)
{
	float factor;
	
	if (amplitude < 1) factor = 0.0f;
	else if (amplitude == 1) factor = 0.5f;
	else factor = (float) amplitude - 1.0f;
	
	return mean + round (factor * randomBinomial ());
}
