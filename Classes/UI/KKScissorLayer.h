//
//  KKScissorLayer.h
//  Be2
//
//  Created by Alessandro Iob on 2/5/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"

@protocol KKScissorViewportDelegateProtocol

-(CGRect) viewport;
@end;

@interface KKScissorLayerStart : CCNode
{
	id viewportDelegate;
}

-(id) initWithViewportDelegate:(id)delegate;

@end

@interface KKScissorLayerEnd : CCNode
{
}

@end

