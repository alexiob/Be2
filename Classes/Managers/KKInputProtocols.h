//
//  KKInputProtocols.h
//  Be2
//
//  Created by Alessandro Iob on 1/13/10.

@protocol KKTouchesDelegateProtocol <NSObject>

-(void) kkTouchesBegan:(NSMutableSet *)touches withEvent:(UIEvent *)event;
-(void) kkTouchesMoved:(NSMutableSet *)touches withEvent:(UIEvent *)event;
-(void) kkTouchesEnded:(NSMutableSet *)touches withEvent:(UIEvent *)event;
-(void) kkTouchesCancelled:(NSMutableSet *)touches withEvent:(UIEvent *)event;

@end

@protocol KKJoystickDelegateProtocol <NSObject>

-(BOOL) kkTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event withJoystickId:(NSString*)joystickId;
-(BOOL) kkTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event withJoystickId:(NSString*)joystickId;
-(BOOL) kkTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event withJoystickId:(NSString*)joystickId;
-(BOOL) kkTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event withJoystickId:(NSString*)joystickId;

@end

