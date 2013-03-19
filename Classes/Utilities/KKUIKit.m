//
//  KKUIKit.m
//  Be2
//
//  Created by Alessandro Iob on 12/29/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKUIKit.h"

UIImage *scaledCopyOfUIImage (UIImage *image, CGSize newSize)
{
	CGImageRef imgRef = image.CGImage;  
	
	CGFloat width = CGImageGetWidth (imgRef);
	CGFloat height = CGImageGetHeight (imgRef);  
	
//	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake (0, 0, width, height);
	if (width > newSize.width || height > newSize.height) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = newSize.width;
			bounds.size.height = bounds.size.width / ratio;
		} else {
			bounds.size.height = newSize.height;
			bounds.size.width = bounds.size.height * ratio;
		}
	}	
	
	CGFloat scaleRatio = bounds.size.width / width;
//	CGSize imageSize = CGSizeMake (CGImageGetWidth (imgRef), CGImageGetHeight (imgRef));
	
	UIGraphicsBeginImageContext (bounds.size);  
	
	CGContextRef context = UIGraphicsGetCurrentContext ();  
	
	CGContextScaleCTM (context, scaleRatio, -scaleRatio);
	CGContextTranslateCTM (context, 0, -height);
	
//	CGContextConcatCTM (context, transform);  
	
	CGContextDrawImage (UIGraphicsGetCurrentContext (), CGRectMake (0, 0, width, height), imgRef);
	
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext ();
	UIGraphicsEndImageContext ();  
	
    return imageCopy;
}
