//
//  KKEntityProtocol.h
//  be2
//
//  Created by Alessandro Iob on 3/8/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "cocos2d.h"


@protocol KKEntityProtocol <NSObject>

//@property (readonly, nonatomic) BOOL visible;

@property (readonly, nonatomic) CGRect bbox;

@property (readonly, nonatomic) CGPoint positionToDisplay;
@property (readonly, nonatomic) CGPoint centerPositionToDisplay;

-(BOOL) visible;

@end
