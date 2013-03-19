//
//  Button.h
//  Be2
//
//  Created by Alessandro Iob on 4/10/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"
#import "KKUIUtilities.h"
#import "KKGraphicsManager.h"

@interface KKButton : CCMenuItem <CCRGBAProtocol> {
	CCSprite *image;
	CCSprite *topImage;
	CCLabel *label;
	BOOL shown;
	
	ccColor3B color;
	GLubyte opacity;
	ccColor3B defaultColor, disabledColor, selectedColor;
	ccColor3B headerColor, flaggedColor;
	
	float defaultScale, disabledScale, selectedScale;
	CGPoint shownPosition;
	CGPoint hiddenPosition;
	tHiddenPositions hidden_;
	
	BOOL header;
	BOOL flagged;
	CGPoint headerPosition;
	
	NSString *activateSound;
	NSString *selectedSound;
	NSString *unselectedSound;
}

@property (readwrite, nonatomic) BOOL shown;
@property (readwrite, nonatomic) float defaultScale, disabledScale, selectedScale;
@property (readwrite, assign, nonatomic) ccColor3B color;
@property (readwrite, assign, nonatomic) ccColor3B defaultColor, disabledColor, selectedColor;
@property (readwrite, assign, nonatomic) ccColor3B headerColor, flaggedColor;
@property (readwrite, assign, nonatomic) GLubyte opacity;
@property (readonly, nonatomic) CGPoint shownPosition, hiddenPosition;
@property (readonly, nonatomic) CCSprite *image;
//@property (readonly, nonatomic) CCSprite *topImage;
@property (readonly, nonatomic) CCLabel *label;
@property (readwrite, nonatomic) BOOL header, flagged;
@property (readwrite, copy, nonatomic) NSString *activateSound, *selectedSound, *unselectedSound;

+(id) itemWithFile:(NSString*)filename target:(id)rec selector:(SEL)s;
+(id) itemWithFile:(NSString*)filename width:(NSUInteger)width height:(NSUInteger)height scale:(float)imageScale radius:(float)radius gray:(float)gray alpha:(float)alpha target:(id)rec selector:(SEL)s;
+(id) itemWithLabel:(NSString*)str fontSize:(CGFloat)size target:(id)rec selector:(SEL)s;

-(id) initWithFile:(NSString*)filename target:(id)rec selector:(SEL)s;
-(id) initWithFile:(NSString*)filename width:(NSUInteger)width height:(NSUInteger)height scale:(float)imageScale radius:(float)radius gray:(float)gray alpha:(float)alpha target:(id)rec selector:(SEL)s;
-(id) initWithLabel:(NSString*)str fontSize:(CGFloat)size target:(id)rec selector:(SEL)s;

-(void) setIsEnabled:(BOOL)enabled;
-(void) setIsEnabled:(BOOL)enabled change:(BOOL)change;
-(void) setColor:(ccColor3B)c;
-(void) setDefaultColor:(ccColor3B)c;
-(void) setDisabledColor:(ccColor3B)c;
-(void) setSelectedColor:(ccColor3B)c;
-(void) setLabelColor:(ccColor3B)c;
-(void) setTopImage:(NSString *)filename;
-(void) setTopImageColor:(ccColor3B)c;
-(void) setTopImageOpacity:(GLubyte)newOpacity;
-(void) setTopImageScale:(float)s;
-(void) setPositionsShown:(CGPoint)shown hidden:(tHiddenPositions)hidden;
-(void) setShown:(BOOL)v;
-(void) setHidden;
-(void) moveAtPosition:(CGPoint)p duration:(float)d;

@end
