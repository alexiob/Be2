//
//  stringUtilities.h
//  Be2
//
//  Created by Alessandro Iob on 10/17/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "ccTypes.h"

#define STR_C2NS(__S__) [NSString stringWithCString:__S__ encoding:NSUTF8StringEncoding]
#define STR_NS2C(__S__) [__S__ cStringUsingEncoding:NSASCIIStringEncoding]

NSString *uuidString ();
ccColor3B ccc3FromNsString (NSString *s);
