//
//  CCSprite+Key.m
//  Be2
//
//  Created by Alessandro Iob on 10/17/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "CCSprite+Key.h"
#import "KKMacros.h"

@implementation CCSprite (CGImageKey)

+(id) spriteWithCGImage:(CGImageRef)image key:(NSString *)key
{
	return [[[(CCSprite *) self alloc] initWithCGImage:image key:key] autorelease];
}

-(id) initWithCGImage:(CGImageRef)image key:(NSString *)key
{
	self = [super init];
	if (self) 
	{
		CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addCGImage:image forKey:key];
		
		CGSize size = texture.contentSize;
		CGRect rect = CGRectMake(0, 0, size.width, size.height );
		
		[self initWithTexture:texture rect:rect];
	}
	
	return self;
}

@end
