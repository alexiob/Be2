/*
 *  KKMacros.h
 *  Be2
 *
 *  Created by Alessandro Iob on 10/10/09.
 *  Copyright 2009 Kismik. All rights reserved.
 *
 */

#import "KKGlobalConfig.h"
#import "KKStringUtilities.h"

// dictionary access
#define DICT_FLOAT(__D__,__K__,__DEFAULT__) ([__D__ objectForKey:__K__] ? [[__D__ objectForKey:__K__] floatValue] : __DEFAULT__)
#define DICT_INT(__D__,__K__,__DEFAULT__) ([__D__ objectForKey:__K__] ? [[__D__ objectForKey:__K__] intValue] : __DEFAULT__)
#define DICT_BOOL(__D__,__K__,__DEFAULT__) ([__D__ objectForKey:__K__] ? [[__D__ objectForKey:__K__] boolValue] : __DEFAULT__)
#define DICT_STRING(__D__,__K__,__DEFAULT__) ([__D__ objectForKey:__K__] ? [__D__ objectForKey:__K__] : __DEFAULT__)

//#define KKLOG(__S__,...) printf ("<%s:(%d)> %s: %s\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] cStringUsingEncoding:NSASCIIStringEncoding], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(__S__), ##__VA_ARGS__] cStringUsingEncoding:NSASCIIStringEncoding])

#ifdef KK_DEBUG
#define KKLOG(__S__,...) NSLog(@"<%@:(%d)> %@: %@\n", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithUTF8String:__PRETTY_FUNCTION__], [NSString stringWithFormat:(__S__), ##__VA_ARGS__])
#else
#define KKLOG(...) do {} while (0)
#endif

#define ARGS_TO_DICT(__FIRST_OBJ__,__ARGS__) \
	NSMutableDictionary *__ARGS__ = [NSMutableDictionary dictionary]; \
	id eachObject_, key_ = nil, value_ = nil; \
	va_list argumentList_; \
	\
	if (__FIRST_OBJ__) { \
		key_ = __FIRST_OBJ__; \
		va_start (argumentList_, __FIRST_OBJ__); \
		while (eachObject_ = va_arg (argumentList_, id)) { \
			if (key_ == nil) {key_ = eachObject_; continue;} \
			if (value_ == nil) { \
				value_ = eachObject_; \
				[__ARGS__ setObject:value_ forKey:key_]; \
				value_ = nil; \
				key_ = nil; \
			} \
		} \
		va_end(argumentList_); \
	}

#ifdef ANALYTICS_ENABLED

/*
#import "Beacon.h"

#define PMA_INIT [Beacon initAndStartBeaconWithApplicationCode:APP_ID_PINCH_MEDIA_ANALYTICS useCoreLocation:YES useOnlyWiFi:NO]; \
	KKLOG (@"PINCH MEDIA ANALYTICS ENABLED.");
#define PMA_END [[Beacon shared] endBeacon];

#define PMA_START_SUB_BEACON(__NAME__,__TIME_SESSION__) [[Beacon shared] startSubBeaconWithName:__NAME__ timeSession:__TIME_SESSION__];
#define PMA_END_SUB_BEACON(__NAME__) [[Beacon shared] endSubBeaconWithName:__NAME__];
*/
#else

#define PMA_INIT
#define PMA_END

#define PMA_START_SUB_BEACON(__NAME__,__TIME_SESSION__)
#define PMA_END_SUB_BEACON(__NAME__)

#endif

#ifdef ADDS_ENABLED
/*
#import "GreystripeSDK.h"
#import "GreystripeDelegate.h"

#define ADD_GREYSTRIPE_DELEGATE , GreystripeDelegate

#define ADD_GREYSTRIPE_INIT GSInit (APP_ID_GREYSTRIPE); \
	GSSetRelativeRotation (90); \
	GSSetDelegate (self); \
	KKLOG (@"GREYSTRIPE ADDS ENABLED.");
#define ADD_GREYSTRIPE_END GSDealloc ();
#define ADD_GREYSTRIPE_DISPLAY GSDisplayAd ();
*/
#else

#define ADD_GREYSTRIPE_DELEGATE

#define ADD_GREYSTRIPE_INIT
#define ADD_GREYSTRIPE_END
#define ADD_GREYSTRIPE_DISPLAY

#endif
