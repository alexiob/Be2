//
//  InputManager.m
//  Be2
//
//  Created by Alessandro Iob on 6/8/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKInputManager.h"
#import "SynthesizeSingleton.h"
#import "KKScenesManager.h"
#import "KKMacros.h"

#import "CCTouchHandler.h"
#import "CCTouchDispatcher.h"

#define kInputLayerTag 0xdaded1
#define kInputLayerZ 10000

#define DEFAULT_FITLERING_FACTOR 0.1

@implementation KKInputManager

@synthesize inputLayer;
@synthesize filteringFactor, accelerometerDeltaTime;

SYNTHESIZE_SINGLETON(KKInputManager);

-(id) init
{
	self = [super init];
	
	if (self) {
		touchesDelegatesCount = 0;
//		joysticksDelegatesCount = 0;
		touchesDelegates = [[NSMutableArray alloc] initWithCapacity:10];
//		joysticksDelegates = [[NSMutableDictionary alloc] initWithCapacity:10];
		
		isCalibrating = NO;
		filteringFactor = DEFAULT_FITLERING_FACTOR;
		accelerometerDeltaTime = 0.0;
		
		rolling[X_IDX] = 0.0;
		rolling[Y_IDX] = 0.0;
		rolling[Z_IDX] = 0.0;
		
		acceleration[X_IDX] = 0.0;
		acceleration[Y_IDX] = 0.0;
		acceleration[Z_IDX] = 0.0;
	}
	return self;
}

-(void) dealloc
{
	[self setInputActive:FALSE];

	if (touchesDelegates) [touchesDelegates release];
//	if (joysticksDelegates) [joysticksDelegates release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Activation

-(void) setInputActive:(BOOL)b
{
	CCScene *s = CURRENT_SCENE;
	
	if (b) {
		if (!inputLayer)
			inputLayer = [[KKInputLayer alloc] init];
		
		if (s && ![s getChildByTag:kInputLayerTag]) {
			[s addChild:inputLayer z:kInputLayerZ tag:kInputLayerTag];
//			[inputLayer onEnter];
		}
	} else {
		if (s && [s getChildByTag:kInputLayerTag]) {
//			[inputLayer onExit];
			[s removeChild:inputLayer cleanup:YES];
			[inputLayer release];
			inputLayer = nil;
		}
	}
}

-(BOOL) inputActive
{
	CCScene *s = CURRENT_SCENE;

	return inputLayer && s && [s getChildByTag:kInputLayerTag];
}

-(void) setAccelerometerActive:(BOOL)b
{
	accelerometerDeltaTime = 0.0;
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	if (b) {
		[UIAccelerometer sharedAccelerometer].updateInterval = 1.0 / UPDATE_INTERVAL_ACCELEROMETER;
		[UIAccelerometer sharedAccelerometer].delegate = self;
		
		[self calibrateAccelerometer];
	} else {
		[UIAccelerometer sharedAccelerometer].delegate = nil;
	}
	
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

-(BOOL) accelerometerActive
{
	return [UIAccelerometer sharedAccelerometer].delegate == self;
}

#pragma mark -
#pragma mark Accelerometer

-(float *) rawData
{
	return rawData;
}

-(float *) calibration
{
	return calibration;
}

-(float *) rawAcceleration
{
	return rawAcceleration;
}

-(float *) rolling
{
	return rolling;
}

-(float *) acceleration
{
	return acceleration;
}

-(float *) orientationAngle
{
	return orientationAngle;
}

-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acc
{
	accelerometerDeltaTime = acc.timestamp - accelerometerDeltaTime;

	rawData[0] = acc.x;
	rawData[1] = acc.y;
	rawData[2] = acc.z;
	
	if (isCalibrating) {
		[self findDeviceOrientationFromRawData];
		[self setupAccelerationIndex];
		
		calibration[X_IDX] = accelerationSign[X_IDX] * rawData[accelerationIndex[X_IDX]];
		calibration[Y_IDX] = accelerationSign[Y_IDX] * rawData[accelerationIndex[Y_IDX]];
		calibration[Z_IDX] = accelerationSign[Z_IDX] * rawData[accelerationIndex[Z_IDX]];
		
		calibration[X_IDX] = (calibration[X_IDX] * filteringFactor) + calibration[X_IDX] * (1.0 - filteringFactor);
		calibration[Y_IDX] = (calibration[Y_IDX] * filteringFactor) + calibration[Y_IDX] * (1.0 - filteringFactor);
		calibration[Z_IDX] = (calibration[Z_IDX] * filteringFactor) + calibration[Z_IDX] * (1.0 - filteringFactor);
		
		calibration[X_IDX] = 0.0;
		calibration[Y_IDX] = 0.0;
		calibration[Z_IDX] = 0.0;
		
		isCalibrating = NO;
	} else {
		rawAcceleration[X_IDX] = accelerationSign[X_IDX] * (rawData[accelerationIndex[X_IDX]] - calibration[X_IDX]);
		rawAcceleration[Y_IDX] = accelerationSign[Y_IDX] * (rawData[accelerationIndex[Y_IDX]] - calibration[Y_IDX]);
		rawAcceleration[Z_IDX] = accelerationSign[Z_IDX] * (rawData[accelerationIndex[Z_IDX]] - calibration[Z_IDX]);
		
		// low-pass filter
		rolling[X_IDX] = (rawAcceleration[X_IDX] * filteringFactor) + rolling[X_IDX] * (1.0 - filteringFactor);
		rolling[Y_IDX] = (rawAcceleration[Y_IDX] * filteringFactor) + rolling[Y_IDX] * (1.0 - filteringFactor);
		rolling[Z_IDX] = (rawAcceleration[Z_IDX] * filteringFactor) + rolling[Z_IDX] * (1.0 - filteringFactor);
		
		// hi-pass filter
		acceleration[X_IDX] = rawAcceleration[X_IDX] - rolling[X_IDX];
		acceleration[Y_IDX] = rawAcceleration[Y_IDX] - rolling[Y_IDX];
		acceleration[Z_IDX] = rawAcceleration[Z_IDX] - rolling[Z_IDX];
	}
	
//	KKLOG (@"RAW:(%f,%f,%f) ACC:(%f,%f,%f) ROL:(%f,%f,%f) CAL:(%f,%f,%f)",
//		   rawAcceleration[X_IDX], rawAcceleration[Y_IDX], rawAcceleration[Z_IDX],
//		   acceleration[X_IDX], acceleration[Y_IDX], acceleration[Z_IDX],
//		   rolling[X_IDX], rolling[Y_IDX], rolling[Z_IDX],
//		   calibration[X_IDX], calibration[X_IDX], calibration[X_IDX]
//		   );
}

-(void) calibrateAccelerometer 
{
	isCalibrating = YES;
}

-(void) findDeviceOrientationFromRawData
{
	orientation = UIDeviceOrientationUnknown;

	orientationAngle[YX_IDX] = atan2 (rolling[Y_IDX], rolling[X_IDX]) * 180/M_PI;
	orientationAngle[YZ_IDX] = atan2 (rolling[Y_IDX], rolling[Z_IDX]) * 180/M_PI;
	orientationAngle[XZ_IDX] = atan2 (rolling[X_IDX], rolling[Z_IDX]) * 180/M_PI;
	
	if (rawData[Z_IDX] < -0.75) {
		orientation = UIDeviceOrientationFaceUp;
	} else if (rawData[Z_IDX] > 0.75) {
		orientation = UIDeviceOrientationFaceDown;
	} else if (rawData[X_IDX] < -0.75) {
		orientation = UIDeviceOrientationLandscapeLeft;
	} else if (rawData[X_IDX] > 0.75) {
		orientation = UIDeviceOrientationLandscapeRight;
	} else if (rawData[Y_IDX] < -0.75) {
		orientation = UIDeviceOrientationPortrait;
	} else if (rawData[Y_IDX] > 0.75) {
		orientation = UIDeviceOrientationPortraitUpsideDown;
	}
}

-(void) setupAccelerationIndex
{
	int xIdx = 0, yIdx = 1, zIdx = 2;
	int xSign = 1, ySign = 1, zSign = 1;
	
	switch (orientation) {
		case UIDeviceOrientationPortrait:
			KKLOG (@"CAL UIDeviceOrientationPortrait");
			yIdx = 2;
			zIdx = 1;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			KKLOG (@"CAL UIDeviceOrientationPortraitUpsideDown");
			yIdx = 2;
			zIdx = 1;
			
			xSign = -1;
			ySign = -1;
			break;
		case UIDeviceOrientationLandscapeLeft:
			KKLOG (@"CAL UIDeviceOrientationLandscapeLeft");
			xIdx = 1;
			yIdx = 2;
			zIdx = 0;
			
			xSign = -1;
			ySign = -1;
			break;
		case UIDeviceOrientationLandscapeRight:
			KKLOG (@"CAL UIDeviceOrientationLandscapeRight");
			xIdx = 1;
			yIdx = 2;
			zIdx = 0;
			break;
		case UIDeviceOrientationFaceUp:
			KKLOG (@"CAL UIDeviceOrientationFaceUp");
			xIdx = 1;
			yIdx = 0;
			zIdx = 2;

			xSign = -1;
			break;
		case UIDeviceOrientationFaceDown:
			KKLOG (@"CAL UIDeviceOrientationFaceDown");
			xIdx = 1;
			yIdx = 0;
			zIdx = 2;
			
			xSign = -1;
			ySign = -1;
			break;
		case UIDeviceOrientationUnknown:
		default:
			KKLOG (@"CAL UIDeviceOrientationUnknown");
			break;
	}
	
	accelerationIndex[X_IDX] = xIdx;
	accelerationIndex[Y_IDX] = yIdx;
	accelerationIndex[Z_IDX] = zIdx;
	
	accelerationSign[X_IDX] = xSign;
	accelerationSign[Y_IDX] = ySign;
	accelerationSign[Z_IDX] = zSign;
	
//	KKLOG (@"Calibrating: o=%d, i=(%d, %d, %d), s=(%d, %d, %d)", 
//		   orientation, 
//		   
//		   accelerationIndex[0],
//		   accelerationIndex[1],
//		   accelerationIndex[2],
//		   
//		   accelerationSign[0],
//		   accelerationSign[1],
//		   accelerationSign[2]
//		   );
}

#pragma mark -
#pragma mark Touches

-(BOOL) addHandler:(CCTouchHandler *)handler toArray:(NSMutableArray *)array
{
	int i = 0;
	
	for (CCTouchHandler *h in array) {
		if (h.priority < handler.priority)
			i++;
		
		if (h.delegate == handler.delegate) {
			KKLOG (@"delegate %@ already added to dispatcher list.", handler);
			return NO;
		}
	}
	[array insertObject:handler atIndex:i];
	return YES;
}

-(BOOL) removeDelegate:(id)delegate fromArray:(NSMutableArray *)array
{
	if (delegate != nil) {
		for (CCTouchHandler *handler in array) {
			if (handler.delegate == delegate) {
				[array removeObject:handler];
				return YES;
			}
		}
	}
	return NO;
}

-(void) addTouchesDelegate:(id<KKTouchesDelegateProtocol>)delegate priority:(int)priority
{
	CCTouchHandler *handler = [CCTouchHandler handlerWithDelegate:delegate priority:priority];
	if ([self addHandler:handler toArray:touchesDelegates]) touchesDelegatesCount++;
}

-(void) removeTouchesDelegate:(id<KKTouchesDelegateProtocol>)delegate
{
	if ([self removeDelegate:delegate fromArray:touchesDelegates]) touchesDelegatesCount--;
}

/*
-(void) addJoystickId:(NSString*)joystickId delegate:(id<KKJoystickDelegateProtocol>)delegate priority:(int)priority
{
	if (![joysticksDelegates objectForKey:joystickId]) {
		[joysticksDelegates setObject:[NSMutableArray arrayWithCapacity:1] forKey:joystickId];
	}
	CCTouchHandler *handler = [CCTouchHandler handlerWithDelegate:delegate priority:priority];
	[self addHandler:handler toArray:[joysticksDelegates objectForKey:joystickId]];
}

-(void) removeJoystickId:(NSString*)joystickId delegate:(id<KKJoystickDelegateProtocol>)delegate
{
	if ([joysticksDelegates objectForKey:joystickId]) {
		[self removeDelegate:delegate fromArray:[joysticksDelegates objectForKey:joystickId]];
	}
}
*/

-(void) touches:(NSSet*)touches withEvent:(UIEvent*)event withTouchType:(int)touchType
{
//	KKLOG (@"touches: %d (%d)", [touches count], touchesDelegatesCount);
//	if (touchesDelegatesCount || joysticksDelegatesCount) {
	if (touchesDelegatesCount) {
		NSMutableSet *mtouches = [[touches mutableCopy] autorelease];
		
		for (CCTouchHandler *handler in touchesDelegates) {
			if ([mtouches count]) {
				switch (touchType) {
					case ccTouchBegan:
						[handler.delegate kkTouchesBegan:mtouches withEvent:event];
						break;
					case ccTouchMoved:
						[handler.delegate kkTouchesMoved:mtouches withEvent:event];
						break;
					case ccTouchEnded:
						[handler.delegate kkTouchesEnded:mtouches withEvent:event];
						break;
					case ccTouchCancelled:
						[handler.delegate kkTouchesCancelled:mtouches withEvent:event];
						break;
					default:
						KKLOG(@"unknown touch type %d", touchType);
						return;
				}
			} else {
				return;
			}
		}
	}
}

/*
-(void) joystick:(NSString*)joystickId touch:(UITouch *)touch withEvent:(UIEvent*)event withTouchType:(int)touchType
{
	NSMutableArray *array = [joysticksDelegates objectForKey:joystickId];
	BOOL drop = NO;
	
	if (array && [array count]) {
		for (CCTouchHandler *handler in array) {
			switch (touchType) {
				case ccTouchBegan:
					drop = [handler.delegate kkTouchBegan:touch withEvent:event withJoystickId:joystickId];
					break;
				case ccTouchMoved:
					drop = [handler.delegate kkTouchMoved:touch withEvent:event withJoystickId:joystickId];
					break;
				case ccTouchEnded:
					drop = [handler.delegate kkTouchEnded:touch withEvent:event withJoystickId:joystickId];
					break;
				case ccTouchCancelled:
					drop = [handler.delegate kkTouchCancelled:touch withEvent:event withJoystickId:joystickId];
					break;
				default:
					KKLOG(@"Unknown joystick touch type %d", touchType);
					return;
			}
			if (drop) break;
		}
	}
}
*/
@end
