//
//  JoystickModel.h
//  Be2
//
//  Created by Alessandro Iob on 4/8/09.
//  Copyright 2009 D-Level srl. All rights reserved.
//

#import "cocos2d.h"

@interface KKJoystickModel : NSObject 
{ 
	CGPoint anchorPoint;
	bool mStaticCenter; 
	CGPoint mCenter; 
	CGPoint mCurPosition; 
	CGPoint mVelocity; 
	CGRect mDeadZone; 
	CGRect mBounds;
	bool mActive; 
	
	UITouch *activationTouch;
} 

@property (readonly, nonatomic) UITouch *activationTouch;

-(id) init:(float)x y:(float)y w:(float)w h:(float)h anchorPoint:(CGPoint)ap; 
-(void) setPositionX:(float)x y:(float)y;
-(void) setCenterX:(float)x y:(float)y; 
-(void) setDeadZoneXRadius:(float)x yRadius:(float)y;

-(BOOL) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event;
-(void) touchMoved:(UITouch *)touch withEvent:(UIEvent *)event;
-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event;
-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event;

/*
-(UITouch *) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event; 
-(UITouch *) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event; 
-(UITouch *) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event; 
-(UITouch *) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event; 
*/

-(CGPoint) getCurrentVelocity; 
-(CGPoint) getCurrentDegreeVelocity; 

@end

