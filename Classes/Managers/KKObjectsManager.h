//
//  ObjectsManager.h
//  Be2
//
//  Created by Alessandro Iob on 9/7/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"

#define GET_SHARED_OBJECT(__NAME__) [[KKObjectsManager sharedKKObjectsManager].sharedObjects objectForKey:__NAME__]
#define ADD_SHARED_OBJECT(__NAME__,__VALUE__) [[KKObjectsManager sharedKKObjectsManager].sharedObjects setObject:__VALUE__ forKey:__NAME__]
#define REMOVE_SHARED_OBJECT(__NAME__) [[KKObjectsManager sharedKKObjectsManager].sharedObjects removeObjectForKey:__NAME__]

@interface KKObjectsManager : NSObject {
	NSMutableDictionary *sharedObjects;
}

@property (readonly, nonatomic) NSMutableDictionary *sharedObjects;

+(KKObjectsManager *) sharedKKObjectsManager;
+(void) purgeSharedKKObjectsManager;

-(void) setupDefaults;

@end
