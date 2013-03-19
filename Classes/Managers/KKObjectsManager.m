//
//  ObjectsManager.m
//  Be2
//
//  Created by Alessandro Iob on 9/7/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKObjectsManager.h"
#import "SynthesizeSingleton.h"

@implementation KKObjectsManager

@synthesize sharedObjects;

SYNTHESIZE_SINGLETON(KKObjectsManager);

-(id) init
{
	self = [super init];
	
	if (self) {
		sharedObjects = [[NSMutableDictionary alloc] initWithCapacity:50];
		
		[self setupDefaults];
	}
	
	return self;
}

-(void) dealloc
{
	if (sharedObjects) {
		[sharedObjects release];
		sharedObjects = nil;
	}
	
	[super dealloc];
}

-(void) setupDefaults
{
}

@end
