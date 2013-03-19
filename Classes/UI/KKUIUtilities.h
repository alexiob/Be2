//
//  KKUIUtilities.h
//  Be2
//
//  Created by Alessandro Iob on 4/5/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"

typedef enum {
	kHideTop,
	kHideBottom,
	kHideLeft,
	kHideRight,
	kNumberOfHiddenPositions,
} tHiddenPositions;

CGColorRef create_device_gray_color(CGFloat w, CGFloat a);
CGColorRef create_device_rgb_color(CGFloat r, CGFloat g, CGFloat b, CGFloat a);

CGContextRef get_bitmap_context (NSUInteger width, NSUInteger height);
void free_bitmap_context_and_image (CGContextRef context, CGImageRef image);

CGImageRef context_to_image (CGContextRef context);//, NSUInteger width, NSUInteger height);
void draw_grey_rounded_background (CGContextRef context, NSUInteger width, NSUInteger height, float radius, float gray, float alpha);

@interface KKUIViewAlphaTo : CCIntervalAction <NSCopying> {
	GLubyte toOpacity;
	GLubyte fromOpacity;
	UIView *view;
}

+(id) actionWithDuration:(ccTime)t opacity:(GLubyte)o uiview:(UIView *)uiview;
-(id) initWithDuration:(ccTime)t opacity:(GLubyte)o uiview:(UIView *)uiview;

@end
