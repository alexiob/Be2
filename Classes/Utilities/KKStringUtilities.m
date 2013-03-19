//
//  KKStringUtilities.m
//  Be2
//
//  Created by Alessandro Iob on 10/17/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKStringUtilities.h"
#import "cocos2d.h"

NSString* uuidString ()
{
    NSString *  result;
    CFUUIDRef   uuid;
    CFStringRef uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSString stringWithFormat:@"%@", uuidStr];
    assert(result != nil);
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

ccColor3B ccc3FromNsString (NSString *s)
{
	NSArray *cs = [s componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
	ccColor3B c;
	
	switch ([cs count]) {
		case 3:
			c = ccc3 (
					  [[cs objectAtIndex:0] intValue],
					  [[cs objectAtIndex:1] intValue],
					  [[cs objectAtIndex:2] intValue]
					  );
			break;
		default:
			c = ccc3 (0, 0, 0);
			break;
	} 
	return c;
}

