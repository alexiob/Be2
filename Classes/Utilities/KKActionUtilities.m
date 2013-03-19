//
//  KKActionUtilities.m
//  be2
//
//  Created by Alessandro Iob on 26/6/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKActionUtilities.h"

CCFiniteTimeAction *getActionSequence (NSArray *actions)
{
	CCFiniteTimeAction *seq = nil;
	for (CCFiniteTimeAction *anAction in actions) {
		if (!seq) {
			seq = anAction;
		} else {
			seq = [CCSequence actionOne:seq two:anAction];
		}
	}
	return seq;
}

CCFiniteTimeAction *getActionSpawn (NSArray *actions)
{
	CCFiniteTimeAction *result = nil;
	for (CCFiniteTimeAction *anAction in actions) {
		if (!result) {
			result = anAction;
		} else {
			result = [CCSpawn actionOne:result two:anAction];
		}
	}
	return result;
}
