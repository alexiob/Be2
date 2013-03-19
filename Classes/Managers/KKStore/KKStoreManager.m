//
//  KKStoreManager.m
//  Be2
//
//  Created by Alessandro Iob on 1/25/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKStoreManager.h"
#import "KKMacros.h"
#import "SynthesizeSingleton.h"
#import "CCFileUtils.h"
#import "KKGameEngine.h"
#import "KKHUDLayer.h"
#import "KKHUDMessage.h"

@implementation KKStoreManager

SYNTHESIZE_SINGLETON(KKStoreManager);

@synthesize purchasableObjects;
@synthesize storeObserver;

static NSString *ownServer = nil;

#pragma mark -
#pragma mark Setup

-(id) init
{
	self = [super init];
	
	if (self) {
		// load available store items
		storeItems = [[NSMutableDictionary alloc] init];
		storeItemsNameToId = [[NSMutableDictionary alloc] init];
		
		NSString *path = [CCFileUtils fullPathFromRelativePath:STORE_ITEMS_PATH];
		NSMutableDictionary *items = [NSMutableDictionary dictionaryWithContentsOfFile:path];
		for (NSString *sid in [items allKeys]) {
			NSMutableDictionary *data = [items objectForKey:sid];
			
			[self addStoreItemWithId:sid andData:data];
		}

		// check store
		purchasableObjects = [[NSMutableArray alloc] init];
		[self requestProductData];
		
		// load saved purchases from userDefaults
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		for (NSString *sid in [storeItems allKeys]) {
			NSMutableDictionary *data = [storeItems objectForKey:sid];
			[data setObject:[NSNumber numberWithBool:[userDefaults boolForKey:sid]] forKey:@"isPurchased"];
		}
		
		storeObserver = [[KKStoreObserver alloc] init];
		[[SKPaymentQueue defaultQueue] addTransactionObserver:storeObserver];
 	}
	
	return self;
}
			 
-(void) dealloc {
	[storeObserver release];
	[purchasableObjects release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Notifications

#define NOTIFICATION_STORE_BG_COLOR ccc3 (219, 159, 218)

-(void) notifyMessage:(NSString *)msg withEmoticon:(tEmoticon)emoticon withSound:(NSString *)snd
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	[KKGE.hud showMessage:msg
				 emoticon:emoticon
				   origin:ccp (0, ws.height - 30) 
				  bgColor:NOTIFICATION_STORE_BG_COLOR 
				 msgColor:HUD_MESSAGE_COLOR
				 icnColor:HUD_MESSAGE_EMOTICON_COLOR 
				 fontSize:HUD_MESSAGE_FONT_SIZE 
				 duration:8
	 ];
	[KKGE playSound:snd];
}

#pragma mark -
#pragma mark Store items

-(void) addStoreItemWithId:(NSString *)sid andData:(NSMutableDictionary *)data
{
	[data setObject:[NSNumber numberWithBool:NO] forKey:@"isPurchased"];
	
	[storeItems setObject:data forKey:sid];
	[storeItemsNameToId setObject:sid forKey:[data objectForKey:@"name"]];
	KKLOG (@"%@ (%@)", sid, [data objectForKey:@"name"]);
}

-(BOOL) isItemWithIdPurchased:(NSString *)sid
{
	BOOL r = NO;
	NSMutableDictionary *data = [storeItems objectForKey:sid];
	
	if (data) {
		if ([data objectForKey:@"isEmbedded"])
			r = [(NSNumber *)[data objectForKey:@"isEmbedded"] boolValue];
		if (r == NO)
			r = [(NSNumber *)[data objectForKey:@"isPurchased"] boolValue];
	}
	KKLOG (@"r:%d embedded:%d purchased:%d", 
		   r, 
		   [(NSNumber *)[data objectForKey:@"isEmbedded"] boolValue], 
		   [(NSNumber *)[data objectForKey:@"isPurchased"] boolValue]
		   );
	return r;
}

-(BOOL) isItemWithNamePurchased:(NSString *)name
{
	NSString *sid = [storeItemsNameToId objectForKey:name];
	
	if (sid) return [self isItemWithIdPurchased:sid];
	else return NO;
}

-(NSArray *) listItems
{
	return [storeItems allKeys];
}

-(NSDictionary *) getDataForItemId:(NSString *)sid
{
	return [storeItems objectForKey:sid];
}

-(NSDictionary *) getDataForItemName:(NSString *)name
{
	NSString *sid = [storeItemsNameToId objectForKey:name];
	
	if (sid) return [storeItems objectForKey:sid];
	else return nil;
}

#pragma mark -
#pragma mark Delegate

static __weak id<KKStoreKitDelegate> delegate_;

+(id) delegate {
    return delegate_;
}

+(void) setDelegate:(id)newDelegate {
    delegate_ = newDelegate;	
}

#pragma mark -
#pragma mark Requests

-(void) requestProductData
{
//	SKProductsRequest *request= [[[SKProductsRequest alloc] 
//								 initWithProductIdentifiers:[NSSet setWithArray:[storeItems allKeys]]
//								  ] autorelease]; //FIXME: autorelease is right or wrong!?!?!
	
	SKProductsRequest *request= [[SKProductsRequest alloc] 
								  initWithProductIdentifiers:[NSSet setWithArray:[storeItems allKeys]]
								  ]; //FIXME: autorelease is right or wrong!?!?!
	
	request.delegate = self;
	[request start];
}

-(void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	[purchasableObjects addObjectsFromArray:response.products];
	KKLOG (@"products: %d [%d]",[purchasableObjects count], [response.products count]);

	for(int i=0; i < [purchasableObjects count];i++) {
		SKProduct *product = [purchasableObjects objectAtIndex:i];
		NSMutableDictionary *data = [storeItems objectForKey:[product productIdentifier]];
		
		if (!data) {
			KKLOG (@"item %@ not in local store info.", [product productIdentifier]);
			data = [NSMutableDictionary dictionary];
			[storeItems setObject:data forKey:[product productIdentifier]];
		}
		
		[data setObject:[product localizedTitle] forKey:@"name"];
		[data setObject:[product localizedDescription] forKey:@"description"];
		KKLOG (@"item:%@ Cost:%f ID:%@", 
			   [product localizedTitle],
			   [[product price] doubleValue],
			   [product productIdentifier]
		);
	}
//	[request autorelease];
	[request release];
}

-(void) buyItem:(NSString*)sid
{
	if([self canCurrentDeviceUseItem:sid]) {
		[self notifyMessage:NSLocalizedString(@"Pingland Store: you can use this item for this session.", @"")
			   withEmoticon:kEmoticonHappy 
				  withSound:@""
		 ];

		[self provideContent:sid shouldSerialize:NO];
		return;
	}
	
	if ([SKPaymentQueue canMakePayments]) {
		SKPayment *payment = [SKPayment paymentWithProductIdentifier:sid];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
		
		[self notifyMessage:NSLocalizedString(@"Pingland Store: purchased started, you will be charged once! It may take some time. Please wait.", @"")
			   withEmoticon:kEmoticonHappy
				  withSound:@""
		 ];
	} else {
		[self notifyMessage:NSLocalizedString(@"Pingland Store: you are not authorized to purchase from App Store.", @"")
			   withEmoticon:kEmoticonSad 
				  withSound:@""
		 ];
	}
}

-(BOOL) canCurrentDeviceUseItem:(NSString*)sid
{
	NSString *uniqueID = [[UIDevice currentDevice] uniqueIdentifier];
	// check udid and featureid with developer's server
	
	if(ownServer == nil) return NO; // sanity check
	
	NSURL *url = [NSURL URLWithString:ownServer];
	
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:60];
	
	[theRequest setHTTPMethod:@"POST"];		
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	NSString *postData = [NSString stringWithFormat:@"itemid=%@&udid=%@", sid, uniqueID];
	
	NSString *length = [NSString stringWithFormat:@"%d", [postData length]];	
	[theRequest setValue:length forHTTPHeaderField:@"Content-Length"];	
	
	[theRequest setHTTPBody:[postData dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSHTTPURLResponse* urlResponse = nil;
	NSError *error = [[[NSError alloc] init] autorelease];  
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:theRequest
												 returningResponse:&urlResponse 
															 error:&error];  
	
	NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
	
	BOOL retVal = NO;
	if ([responseString isEqualToString:@"YES"]) {
		retVal = YES;
	}
	
	[responseString release];
	return retVal;
}

-(void) failedTransaction:(SKPaymentTransaction *)transaction
{
	NSString *messageToBeShown;
	
//	if (transaction && transaction.error) {
//		messageToBeShown = [NSString stringWithFormat:NSLocalizedString(@"Pingland Store: unable to complete your purchase. Reason: %@. You can try: %@", @""), 
//								  [transaction.error localizedFailureReason], 
//								  [transaction.error localizedRecoverySuggestion]
//								  ];
//	} else {
		messageToBeShown = NSLocalizedString(@"Pingland Store: unable to complete your purchase. Try again, please.", @"");
//	}

	[self notifyMessage:messageToBeShown
		   withEmoticon:kEmoticonSad
			  withSound:@""
	 ];
	
	if ([delegate_ respondsToSelector:@selector(productPurchasedFailed)])
		[delegate_ productPurchasedFailed];
}

-(void) provideContent:(NSString*)productIdentifier shouldSerialize:(BOOL)serialize
{
	NSMutableDictionary *data = [storeItems objectForKey:productIdentifier];
	
	[data setObject:[NSNumber numberWithBool:YES] forKey:@"isPurchased"];
	
	NSString *messageToBeShown = [NSString stringWithFormat:NSLocalizedString(@"Pingland Store: purchased '%@'!", @""), 
								  [data objectForKey:@"label"]
								  ];
	
	[self notifyMessage:messageToBeShown
		   withEmoticon:kEmoticonHappy
			  withSound:@""
	 ];
	
	if ([delegate_ respondsToSelector:@selector(productPurchased:)])
		[delegate_ productPurchased:productIdentifier];
	
	if (serialize) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setBool:YES forKey:productIdentifier];
	}
}

@end
