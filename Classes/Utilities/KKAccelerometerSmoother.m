//
//  KKAccelerometerSmoother.m
//  Moonteers
//
//  Created by Alessandro Iob on 10/26/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKAccelerometerSmoother.h"
#import "KKMacros.h"
#import "KKMath.h"

#define kAccelerometerNaN -100.0f
#define kAccelerometerFrequency 30.0f
#define kAccelerometerMinStep 0.02f
#define kAccelerometerNoiseAttenuation 3.0f

@implementation KKAccelerometerSmoother

@synthesize sensitivity=_sensitivity, smoothing=_smoothing;
@synthesize calibrate=_calibrate, forceCalibration=_forceCalibration, position=_position, invert=_invert;

-(id) init
{
	self = [super init];
	if (self) {
		//Setting-up accelerometer
		[UIAccelerometer sharedAccelerometer].updateInterval = (1.0 / kAccelerometerFrequency);
		[UIAccelerometer sharedAccelerometer].delegate = self;
		
		//Set-up ivars.
		_invert = YES;
		_sensitivity = 1.0f;
		_smoothing = 0.1;
		_position.x = _position.y = _position.z = 0.0f;
		_calibration[0] = _calibration[1] = _calibration[2] = kAccelerometerNaN;
		_position = (ccVertex3F) {kAccelerometerNaN, kAccelerometerNaN, kAccelerometerNaN};
		
		_acc[0] = _acc[1] = _acc[2] = _rot[0] = _rot[1]= _rot[2] = _mean[0] = _mean[1] = _mean[2] = 0.0f;
		_var[0] = _var[1] = _var[2] = 1.0f;
		_cal[0] = _cal[1] = _cal[2] = kAccelerometerNaN;		
	}
	
	return self;
}

-(void) dealloc
{
	[UIAccelerometer sharedAccelerometer].delegate = nil;
	
	[super dealloc];
}

-(void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration 
{
	CGFloat		x, y, z;
	
	KKLOG (@"Accelerometer: %f | %f, %f, %f\n", [NSDate timeIntervalSinceReferenceDate]*kAccelerometerFrequency, acceleration.x, acceleration.y, acceleration.z);
	
	x = acceleration.x * _sensitivity * (_invert ? 1.0f : -1.0f);
	y = acceleration.y * _sensitivity * (_invert ? 1.0f : -1.0f);
	z = acceleration.z * _sensitivity * (_invert ? 1.0f : -1.0f);
	
	if (_calibrate) {
		if (_calibration[0] == kAccelerometerNaN) {
			_calibration[0] = -x;
		}
		if (_calibration[1] == kAccelerometerNaN) {
			_calibration[1] = -y;
		}
		
		//We smooth the accelerometer raw input (we're in the "accelerometer loop" now).
		_calibration[0] = -x * _smoothing + _calibration[0] * (1. - _smoothing);
		_calibration[1] = -y * _smoothing + _calibration[1] * (1. - _smoothing);
	}
	
	_accelerometer = (ccVertex3F) {x, y, z};
}

/* 
 The accelerometer automatically recalibrates when outside (-0.2, -0.2, 0.4, 0.4)
 Filter noise when movement is small to avoid jitter.
 */

#define kClampMinX -0.35f
#define kClampMaxX -0.35f
#define kClampMinY -0.4f
#define kClampMaxY -0.4f

-(void) update
{
	CGFloat x, y, z, d, alpha = _smoothing;
	NSUInteger i;
	BOOL skipUpdate = NO;
	
	// Take into account calibrated center.
	x = _accelerometer.x + _calibration[0];
	y = _accelerometer.y + _calibration[1];
	z = _accelerometer.z;
	
	// Smooth more for small movement to filter out noise/jitter.
	d = Clamp(ABS(Norm(_acc[0], _acc[1], _acc[2]) - Norm(x, y, z)) / kAccelerometerMinStep / _sensitivity - 1.0f, 0.0f, 1.0f);
	alpha = (1.0f - d) * _smoothing / kAccelerometerNoiseAttenuation + d * _smoothing;
	
	// Smooth again (we're in gameLoop now)
	_acc[0] = -y * alpha + _acc[0] * (1.0f - alpha);
	_acc[1] = -x * alpha + _acc[1] * (1.0f - alpha);
	_acc[2] =  z * alpha + _acc[2] * (1.0f - alpha);
	
	// Clamp values.
	_acc[0] = Clamp(_acc[0], kClampMinX, kClampMaxX);
	_acc[1] = Clamp(_acc[1], kClampMinY, kClampMaxY);
	
	// Compute smoothed mean and variance.
	for (i=0; i<3; ++i) {
		_mean[i] = _acc[i] * _smoothing + _mean[i] * (1.0f - _smoothing);
		_var[i] = (_acc[i] - _mean[i]) * (_acc[i] - _mean[i]) * _smoothing + _var[i] * (1.0f - _smoothing);
	}
	
	// Autocalibration when at screen borders, and ship motion variance is low
	if (((_cal[0] == kAccelerometerNaN) ? 
		 ((Norm(_var[0], _var[1], _var[2]) < 0.002) && ((ABS(_acc[0]) > 0.2) || (ABS(_acc[1]) > 0.2))) : 
		 ((Norm(_var[0], _var[1], _var[2]) < 0.002) && (Norm(_position.x, _position.y, 0.0) > 0.01))) 
		|| _forceCalibration) {
		//Smoothly position to center.
		_position = ccVertex3FMult (_position, 0.9f);
		
		//Recalibrate, i.e. compute new center.
		for (i=0; i<3; ++i) {
			if (_cal[i] == kAccelerometerNaN) {
				_cal[i] = _calibration[i];
			}
		}		
		_cal[0] = -_accelerometer.x * _smoothing + _cal[0] * (1. - _smoothing);
		_cal[1] = -_accelerometer.y * _smoothing + _cal[1] * (1. - _smoothing);
	} else {
		for (i=0; i<3; ++i) {
			// If were automatically recalibrating, update actual calibration with the one computed while recalibrating.
			if (_cal[i] != kAccelerometerNaN) {
				_acc[i] = VERTEX3F_COORD_AT_INDEX (_position, i);
				_calibration[i] = _cal[i];
				_cal[i] = kAccelerometerNaN;
				skipUpdate = YES;
			}
		}
		if (!skipUpdate) {
			for (i=0; i<3; ++i) {
				//Update positon with new value.
				VERTEX3F_COORD_AT_INDEX (_position, i) = _acc[i];
			}
		}
	}
}

-(void) setSmoothing:(CGFloat)x
{
	_smoothing = 1.0/x;
}

-(CGFloat) smoothing
{
	return 1.0/_smoothing;
}


@end
