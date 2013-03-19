//
//  KKStoreObserver.m
//  Be2
//
//  Created by Alessandro Iob on 1/25/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKStoreObserver.h"
#import "KKStoreManager.h"
#import "KKMacros.h"

@implementation KKStoreObserver

-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
		}			
	}
}

-(void) failedTransaction:(SKPaymentTransaction *)transaction
{	
    if (transaction.error.code != SKErrorPaymentCancelled) {		
        // Optionally, display an error here.		
		KKLOG (@"Payment cancelled"); 
    }	
    [[KKStoreManager sharedKKStoreManager] failedTransaction:transaction];	
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];	
}

-(void) completeTransaction:(SKPaymentTransaction *)transaction
{		
    [[KKStoreManager sharedKKStoreManager] provideContent:transaction.payment.productIdentifier shouldSerialize:YES];	
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];	
}

-(void) restoreTransaction:(SKPaymentTransaction *)transaction
{	
    [[KKStoreManager sharedKKStoreManager] provideContent:transaction.originalTransaction.payment.productIdentifier shouldSerialize:YES];	
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];	
}

@end
