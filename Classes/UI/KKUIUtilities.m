//
//  UIUtilities.m
//  Be2
//
//  Created by Alessandro Iob on 4/5/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "KKUIUtilities.h"
#import "KKMacros.h"

CGColorRef create_device_gray_color(CGFloat w, CGFloat a)
{
    CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
    CGFloat comps[] = {w, a};
    CGColorRef color = CGColorCreate(gray, comps);
    CGColorSpaceRelease(gray);
    return color;
}

CGColorRef create_device_rgb_color(CGFloat r, CGFloat g, CGFloat b, CGFloat a)
{
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGFloat comps[] = {r, g, b, a};
    CGColorRef color = CGColorCreate(rgb, comps);
    CGColorSpaceRelease(rgb);
    return color;
}

CGContextRef get_bitmap_context (NSUInteger width, NSUInteger height) 
{
//	KKLOG (@"get_bitmap_context (w=%d, h=%d)", width, height);
	int bytes_per_row = (width * 4);
//	void *data = malloc (bytes_per_row * height);

	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB ();
	
	CGContextRef context = CGBitmapContextCreate (
		nil, width, height, 
		8, bytes_per_row, 
		color_space, kCGImageAlphaPremultipliedLast
	);
	CGContextTranslateCTM (context, 0.0f, height);
	CGContextScaleCTM (context, 1.0f, -1.0f); // Flip the CTM to get (0,0) in the right place
	CGColorSpaceRelease (color_space);

	return context;
}

void free_bitmap_context_and_image (CGContextRef context, CGImageRef image)
{
//	char *data = CGBitmapContextGetData (context);
	
	CGContextRelease (context);
//	if (data) free (data);
	CGImageRelease (image);	
}

CGImageRef context_to_image (CGContextRef context)//NSUInteger width, NSUInteger height)
{
//	CGRect bounding_box = CGRectMake (0.0, 0.0, width, height); 
	CGImageRef image = CGBitmapContextCreateImage (context);
//	CGContextDrawImage (context, bounding_box, image);
	
	return image;
}

void draw_grey_rounded_background (CGContextRef context, NSUInteger width, NSUInteger height, float radius, float gray, float alpha) 
{
	CGRect bounding_box = CGRectMake (0.0, 0.0, (float) width, (float) height); 
//	KKLOG (@"draw_grey_rounded_background (w=%f, h=%f)", bounding_box.size.width, bounding_box.size.height);
	
	CGContextBeginPath (context);
	CGContextSetGrayFillColor (context, gray, alpha);
	CGContextMoveToPoint (context, CGRectGetMinX (bounding_box) + radius, CGRectGetMinY (bounding_box));
	CGContextAddArc (context, CGRectGetMaxX (bounding_box) - radius, CGRectGetMinY (bounding_box) + radius, radius, 3 * M_PI / 2, 0, 0);
	CGContextAddArc (context, CGRectGetMaxX(bounding_box) - radius, CGRectGetMaxY(bounding_box) - radius, radius, 0, M_PI / 2, 0);
	CGContextAddArc (context, CGRectGetMinX(bounding_box) + radius, CGRectGetMaxY(bounding_box) - radius, radius, M_PI / 2, M_PI, 0);
	CGContextAddArc (context, CGRectGetMinX(bounding_box) + radius, CGRectGetMinY(bounding_box) + radius, radius, M_PI, 3 * M_PI / 2, 0);
	CGContextClosePath (context);
	CGContextFillPath (context);
}

@implementation KKUIViewAlphaTo

+(id) actionWithDuration:(ccTime)t opacity:(GLubyte)o uiview:(UIView *)uiview
{
	return [[[self alloc] initWithDuration:t opacity:o uiview:uiview] autorelease];
}

-(id) initWithDuration:(ccTime)t opacity:(GLubyte)o uiview:(UIView *)uiview
{
	if((self=[super initWithDuration:t])) {
		toOpacity = o;
		view = uiview;
	}
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	CCAction *copy = [[[self class] allocWithZone:zone] initWithDuration:[self duration] opacity:toOpacity uiview:view];
	return copy;
}

-(void) startWithTarget:(CCNode *)aTarget
{
	[super startWithTarget:aTarget];
	
	fromOpacity = (int) (view.alpha * 255.0f);
}

-(void) update:(ccTime)t
{
	view.alpha = (float)(fromOpacity + ( toOpacity - fromOpacity ) * t) / 255.0f;
}

@end
