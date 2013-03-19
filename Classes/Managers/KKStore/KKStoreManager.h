//
//  KKStoreManager.h
//  Be2
//
//  Created by Alessandro Iob on 1/25/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "KKStoreObserver.h"

#define STORE_ITEMS_PATH @"ResourcesApp/data/storeItems.plist"
#define STORE_ITEM_PREFIX @"com.kismik.be2free."
#define STORE_ITEM_UNLOCK_ALL_LEVELS @"com.kismik.be2free.unlockAllLevels"

#define KKSTORE [KKStoreManager sharedKKStoreManager]

@protocol KKStoreKitDelegate <NSObject>
@optional
- (void)productPurchased:(NSString *)productId;
@end

@interface KKStoreManager : NSObject<SKProductsRequestDelegate> {
	NSMutableDictionary *storeItems;
	NSMutableDictionary *storeItemsNameToId;
	
	NSMutableArray *purchasableObjects;
	KKStoreObserver *storeObserver;	
}

@property (nonatomic, retain) NSMutableArray *purchasableObjects;
@property (nonatomic, retain) KKStoreObserver *storeObserver;

+(KKStoreManager *) sharedKKStoreManager;
+(void) purgeSharedKKStoreManager;

-(void) requestProductData;

-(BOOL) canCurrentDeviceUseItem:(NSString*)sid;

-(void) buyItem:(NSString*)sid;

-(void) failedTransaction:(SKPaymentTransaction *)transaction;
-(void) provideContent:(NSString*)productIdentifier shouldSerialize:(BOOL)serialize;

-(void) addStoreItemWithId:(NSString *)sid andData:(NSMutableDictionary *)data;

-(BOOL) isItemWithIdPurchased:(NSString *)sid;
-(BOOL) isItemWithNamePurchased:(NSString *)name;
-(NSArray *) listItems;
-(NSDictionary *) getDataForItemId:(NSString *)sid;
-(NSDictionary *) getDataForItemName:(NSString *)name;

+(id)delegate;	
+(void)setDelegate:(id)newDelegate;

@end
