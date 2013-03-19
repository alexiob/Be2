//
//  KKAccelerometerSmoother.h
//  Moonteers
//
//  Created by Alessandro Iob on 10/26/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"

@interface KKAccelerometerSmoother : NSObject <UIAccelerometerDelegate> {
@private
	ccVertex3F	_position, _accelerometer;
	CGFloat	_calibration[3], _sensitivity, _smoothing;
	BOOL _calibrate, _forceCalibration, _invert;
	CGFloat _acc[3], _rot[3], _mean[3], _var[3], _cal[3];
}

/* Updates the accelerometer smoothed values. Must be called from game loop, not event loop, for better smoothing */
- (void) update;

@property (readonly, nonatomic) ccVertex3F position;
@property (readwrite, nonatomic) BOOL calibrate, forceCalibration, invert;
@property (readwrite, nonatomic) CGFloat sensitivity, smoothing;

@end
