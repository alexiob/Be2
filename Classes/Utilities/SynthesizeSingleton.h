//
//  SynthesizeSingleton.h
//  Be2
//
//  Created by Alessandro Iob on 4/21/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#define SYNTHESIZE_SINGLETON(__CLASSNAME__) \
 \
static __CLASSNAME__ *shared ## __CLASSNAME__ = nil; \
 \
+ (__CLASSNAME__ *)shared ## __CLASSNAME__ \
{ \
	@synchronized(self) \
	{ \
		if (shared ## __CLASSNAME__ == nil) \
		{ \
			[[self alloc] init]; \
		} \
	} \
	 \
	return shared ## __CLASSNAME__; \
} \
 \
+(void) purgeShared ## __CLASSNAME__ \
{ \
	@synchronized( self ) { \
		if (shared ## __CLASSNAME__ != nil) \
			[shared ## __CLASSNAME__ release]; \
	} \
} \
 \
+ (id)allocWithZone:(NSZone *)zone \
{ \
	@synchronized(self) \
	{ \
		if (shared ## __CLASSNAME__ == nil) \
		{ \
			shared ## __CLASSNAME__ = [super allocWithZone:zone]; \
			return shared ## __CLASSNAME__; \
		} \
	} \
	 \
	return nil; \
} \
 \
- (id)copyWithZone:(NSZone *)zone \
{ \
	return self; \
} \
 \
- (id)retain \
{ \
	return self; \
} \
 \
- (NSUInteger)retainCount \
{ \
	return NSUIntegerMax; \
} \
 \
- (void)release \
{ \
} \
 \
- (id)autorelease \
{ \
	return self; \
}
