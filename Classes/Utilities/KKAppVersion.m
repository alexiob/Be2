//
//  KKAppVersion.m
//  Be2
//
//  Created by Alessandro Iob on 10/14/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKAppVersion.h"


@implementation KKAppVersion

+(NSString *) getAppVersionNumber;
{
	NSString *myVersion, *buildNum, *versText=nil;
	
	myVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	buildNum = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	if (myVersion) {
		if (buildNum)
			versText = [NSString stringWithFormat:@"%@ (%@)", myVersion, buildNum];
		else
			versText = myVersion;
	} else if (buildNum)
		versText = buildNum;
	
	return versText;
}

+(NSString *) getGameDataVersionNumber;
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"KKGameDataVersion"];
}

@end
