//
//  DeviceDetection.h
//  Be2
//
//  Created by Alessandro Iob on 5/20/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import <sys/utsname.h>

#define isIPhone ([KKDeviceDetection detectDevice] >= kIPhoneSimulator && [KKDeviceDetection detectDevice] <= kUnknownIPhone)
#define isIPodTouch ([KKDeviceDetection detectDevice] >= kIPodTouch1G && [KKDeviceDetection detectDevice] <= kUnknownIPod)
#define isIPad ([KKDeviceDetection detectDevice] >= kIPadSimulator && [KKDeviceDetection detectDevice] <= kUnknownIPad)

typedef enum {
    kUnknownDevice = 0,
    kIPhoneSimulator = 1,

    kIPhone1G,
    kIPhone3G,
    kIPhone3GS,
	kIPhone4,
	kUnknownIPhone,
	
    kIPodTouch1G,
    kIPodTouch2G,
	kUnknownIPod,

    kIPadSimulator,
    kIPad1G,
	kUnknownIPad,
} tDeviceModelType;

typedef enum {
	kBuiltInSpeaker = 1 << 1,
	kBuiltInCamera = 1 << 2,
	kBuiltInMicrophone = 1 << 3,
	kSupportsExternalMicrophone = 1 << 4,
	kSupportsTelephony = 1 << 5,
	kSupportsVibration = 1 << 6,
	kSupportsGPS = 1 << 7,
	kSupportsGyroscope = 1 << 8,
} tDeviceCapabilityType;

@interface KKDeviceDetection : NSObject

+(tDeviceModelType) detectDevice;
+(NSString *) returnDeviceName:(BOOL)ignoreSimulator;
+(tDeviceCapabilityType) deviceCapabilities;

@end
