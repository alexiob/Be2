//
//  KKStoreObserver.h
//  Be2
//
//  Created by Alessandro Iob on 1/25/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface KKStoreObserver : NSObject<SKPaymentTransactionObserver> {
}

-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;
-(void) failedTransaction:(SKPaymentTransaction *)transaction;
-(void) completeTransaction:(SKPaymentTransaction *)transaction;
-(void) restoreTransaction:(SKPaymentTransaction *)transaction;

@end
