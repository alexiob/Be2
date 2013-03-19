//
//  InputManager.h
//  Be2
//
//  Created by Alessandro Iob on 6/8/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"

#import "KKInputProtocols.h"
#import "KKInputLayer.h"

#define KKIM [KKInputManager sharedKKInputManager]
#define KKIL [[KKInputManager sharedKKInputManager] inputLayer]

#define X_IDX 0
#define Y_IDX 1
#define Z_IDX 2

#define YX_IDX 0
#define YZ_IDX 1
#define XZ_IDX 2

#define INPUT_MANAGER_PRIORITY -10000

typedef enum {
	kInputModeSlide = 1,
//	kInputModeInertial,
	kInputModeJoystick,
} tInputMode;

@interface KKInputManager : NSObject <UIAccelerometerDelegate> {
	KKInputLayer *inputLayer;
	
	int touchesDelegatesCount;
//	int joysticksDelegatesCount;
	NSMutableArray *touchesDelegates;
//	NSMutableDictionary *joysticksDelegates;
	
	// accelerometer
	
	UIDeviceOrientation orientation;
	BOOL isCalibrating;
	float accelerometerDeltaTime;
	float filteringFactor;
	int accelerationIndex[3];
	int accelerationSign[3];
	float rawData[3];
	float rawAcceleration[3];
	float calibration[3];
	float rolling[3];
	float acceleration[3];
	float orientationAngle[3];
}

@property (readonly, nonatomic) KKInputLayer *inputLayer;
@property (readwrite, nonatomic) BOOL inputActive;
@property (readwrite, nonatomic) BOOL accelerometerActive;

@property (readwrite, nonatomic) float filteringFactor;
@property (readonly, nonatomic) float accelerometerDeltaTime;

+(KKInputManager *) sharedKKInputManager;
+(void) purgeSharedKKInputManager;

-(void) setInputActive:(BOOL)b;
-(BOOL) inputActive;

-(void) setAccelerometerActive:(BOOL)b;
-(BOOL) accelerometerActive;

-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
-(void) calibrateAccelerometer;
-(void) findDeviceOrientationFromRawData;
-(void) setupAccelerationIndex;

-(float *) rawData;
-(float *) calibration;
-(float *) rawAcceleration;
-(float *) rolling;
-(float *) acceleration;
-(float *) orientationAngle;

-(void) addTouchesDelegate:(id<KKTouchesDelegateProtocol>)delegate priority:(int)priority;
-(void) removeTouchesDelegate:(id<KKTouchesDelegateProtocol>)delegate;
//-(void) addJoystickId:(NSString*)joystickId delegate:(id<KKJoystickDelegateProtocol>)delegate priority:(int)priority;
//-(void) removeJoystickId:(NSString*)joystickId delegate:(id<KKJoystickDelegateProtocol>)delegate;

-(void) touches:(NSSet*)touches withEvent:(UIEvent*)event withTouchType:(int)touchType;
//-(void) joystick:(NSString*)joystickId touch:(UITouch *)touch withEvent:(UIEvent*)event withTouchType:(int)touchType;

@end
