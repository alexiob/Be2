//
//  KKScissorLayer.m
//  Be2
//
//  Created by Alessandro Iob on 2/5/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKScissorLayer.h"

#pragma mark -
#pragma mark KKScissorLayerStart

@implementation KKScissorLayerStart

-(id) initWithViewportDelegate:(id)delegate
{
	self = [super init];
	if (self) {
		viewportDelegate = delegate;
	}
	return self;
}

-(void) dealloc
{
	viewportDelegate = nil;
	
	[super dealloc];
}

-(void) draw
{
	CGRect viewport = [viewportDelegate viewport];
	
	glScissor (
			   viewport.origin.x,
			   viewport.origin.y,
			   viewport.size.width, 
			   viewport.size.height
			   );
	glEnable (GL_SCISSOR_TEST);
}

@end

#pragma mark -
#pragma mark KKScissorLayerEnd

@implementation KKScissorLayerEnd

-(void) draw
{
	CGRect frame = [[[CCDirector sharedDirector] openGLView] frame];
	glScissor (0, 0, frame.size.width, frame.size.height);
	glDisable (GL_SCISSOR_TEST);
}

@end


