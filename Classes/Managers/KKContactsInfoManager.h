//
//  KKContactsInfoManager.h
//  Be2
//
//  Created by Alessandro Iob on 12/22/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"
#import "AddressBook/AddressBook.h"

#define KKCIM [KKContactsInfoManager sharedKKContactsInfoManager]

@interface KKContactsInfoManager : NSObject {
	NSMutableArray *allPeople;
	NSMutableArray *gfxPeople;
	
	NSMutableDictionary *textures;
}

@property (readonly, nonatomic) NSMutableArray *allPeople;
@property (readonly, nonatomic) NSMutableArray *gfxPeople;

+(KKContactsInfoManager *) sharedKKContactsInfoManager;
+(void) purgeSharedKKContactsInfoManager;

-(NSString *) getPersonName:(ABRecordRef)person;
-(CCTexture2D *) getPersonImage:(ABRecordRef)person;

@end
