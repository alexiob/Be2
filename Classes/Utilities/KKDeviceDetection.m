//
//  DeviceDetection.m
//  Be2
//
//  Created by Alessandro Iob on 5/20/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKDeviceDetection.h"
#include <sys/types.h>
#include <sys/sysctl.h>

#import "KKMacros.h"

@implementation KKDeviceDetection

+(tDeviceModelType) detectDevice {
	tDeviceModelType detected;
	
//	struct utsname u;
//	uname(&u);
//	NSString *platform = [NSString stringWithCString:u.machine];

	size_t size;
	sysctlbyname ("hw.machine", NULL, &size, NULL, 0);
	char *machine = malloc(size);
	sysctlbyname ("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	free (machine);
	
	if ([platform isEqualToString:@"i386"]) {
		//FIXME: uggly hack for ipad detection in simulator
		CGRect br = [[UIScreen mainScreen] bounds];
		if (br.size.width == 1024 || br.size.height == 1024) detected = kIPadSimulator;
		else detected = kIPhoneSimulator;
	} else if ([platform isEqualToString:@"iPod1,1"]) {
		detected = kIPodTouch1G;
	} else if ([platform isEqualToString:@"iPod2,1"]) {
		detected = kIPodTouch2G;
	} else if ([platform isEqualToString:@"iPod2,2"]) {
		detected = kIPodTouch2G;
	} else if ([platform isEqualToString:@"iPod3,1"]) {
		detected = kIPodTouch2G;
	} else if ([platform isEqualToString:@"iPod"]) {
		detected = kUnknownIPod;
	} else if ([platform isEqualToString:@"iPhone1,1"]) {
		detected = kIPhone1G;
	} else if ([platform isEqualToString:@"iPhone1,2"]) {
		detected = kIPhone3G;
	} else if ([platform isEqualToString:@"iPhone2,1"]) {
		detected = kIPhone3GS;
	} else if ([platform isEqualToString:@"iPhone3,1"]) {
		detected = kIPhone3GS;
	} else if ([platform isEqualToString:@"iPhone3,2"]) {
		detected = kIPhone3GS;
	} else if ([platform isEqualToString:@"iPhone"]) {
		detected = kUnknownIPhone;
	} else if ([platform isEqualToString:@"iPad1,1"]) {
		detected = kIPad1G;
	} else if ([platform isEqualToString:@"iPad"]) {
		detected = kUnknownIPad;
	} else {
		detected = kUnknownDevice;
	}
	return detected;
}

+(NSString *) returnDeviceName:(BOOL)ignoreSimulator {
	NSString *returnValue;
    
	switch ([KKDeviceDetection detectDevice]) {
		case kIPhoneSimulator:
			if (ignoreSimulator) {
				returnValue = @"iPhone 3G";
			} else {
				returnValue = @"iPhone Simulator";
			}
			break;
        case kIPodTouch1G:
			returnValue = @"iPod Touch 1G";
			break;
		case kIPodTouch2G:
			returnValue = @"iPod Touch 2G";
			break;
		case kIPhone1G:
			returnValue = @"iPhone 1G";
			break;
		case kIPhone3G:
			returnValue = @"iPhone 3G";
			break;
		case kIPhone3GS:
			returnValue = @"iPhone 3GS";
			break;
		case kUnknownIPhone:
			returnValue = @"Unknown iPhone";
			break;
		case kUnknownIPod:
			returnValue = @"Unknown iPod";
			break;
		case kUnknownDevice:
		default:
			returnValue = @"Unknown Device";
			break;
    }
    return returnValue;
}

+(tDeviceCapabilityType) deviceCapabilities
{
	tDeviceCapabilityType c;
	
	switch ([KKDeviceDetection detectDevice]) {
		case kIPhoneSimulator:
			c = 0;
			break;
		case kIPodTouch1G:
			c = 0;
			break;
		case kIPodTouch2G:
			c = kBuiltInSpeaker | kBuiltInMicrophone | kSupportsExternalMicrophone;
			break;
		case kIPhone1G:
			c = kBuiltInSpeaker | kBuiltInMicrophone | kBuiltInCamera | kSupportsExternalMicrophone | kSupportsTelephony | kSupportsVibration;
			break;
		case kIPhone3G:
			c = kBuiltInSpeaker | kBuiltInMicrophone | kBuiltInCamera | kSupportsExternalMicrophone | kSupportsTelephony | kSupportsVibration | kSupportsGPS;
			break;
		case kIPhone3GS:
			c = kBuiltInSpeaker | kBuiltInMicrophone | kBuiltInCamera | kSupportsExternalMicrophone | kSupportsTelephony | kSupportsVibration | kSupportsGPS;
			break;
		case kUnknownIPhone:
			c = kBuiltInSpeaker | kBuiltInMicrophone | kBuiltInCamera | kSupportsExternalMicrophone | kSupportsTelephony | kSupportsVibration;
			break;
		case kUnknownIPod:
			c = kBuiltInSpeaker;
			break;
		case kUnknownDevice:
		default:
			c = 0;
			break;
	}
	return c;
}

@end