//
//  KKHUDButton.h
//  be2
//
//  Created by Alessandro Iob on 23/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "cocos2d.h"

typedef enum {
	kButtonRuntimeFlagClickFX = 1 << 0,
} tButtonRuntimeFlag;

@interface KKHUDButtonLabel : CCMenuItemImage {
	int runtimeFlags;
	CCLabel *label;
}

-(id) initWithString:(NSString *)text withSize:(int)p target:(id)t selector:(SEL)s;

-(CCLabel *) label;
-(void) setLabel:(NSString *)text;
-(void) setLabelColor:(ccColor3B)c;
-(void) setLabelOpacity:(int)o;
-(void) setLabelAnchorPoint:(CGPoint)p;

@end

@interface KKHUDButtonImage : CCMenuItemImage {
	float scaleDefault;
	float scaleSelected;
}

@property (readwrite, nonatomic) float scaleDefault;
@property (readwrite, nonatomic) float scaleSelected;

-(id) initWithFile:(NSString*)filename target:(id)t selector:(SEL)s;

@end
