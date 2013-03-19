//
//  CCSprite+Key.h
//  Be2
//
//  Created by Alessandro Iob on 10/17/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"

@interface CCSprite (CGImageKey)

+(id) spriteWithCGImage:(CGImageRef)image key:(NSString *)key;
-(id) initWithCGImage:(CGImageRef)image key:(NSString *)key;

@end
