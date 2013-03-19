//
//  KKContactsInfoManager.m
//  Be2
//
//  Created by Alessandro Iob on 12/22/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKContactsInfoManager.h"
#import "SynthesizeSingleton.h"
#import "KKMacros.h"
#import "KKUIKit.h"

@implementation KKContactsInfoManager

@synthesize allPeople, gfxPeople;

SYNTHESIZE_SINGLETON(KKContactsInfoManager);

-(id) init
{
	self = [super init];
	
	if (self) {
		ABAddressBookRef addressBook = ABAddressBookCreate ();
		
		allPeople = [[[(NSArray *) ABAddressBookCopyArrayOfAllPeople (addressBook) autorelease] mutableCopy] retain];
		gfxPeople = [[NSMutableArray arrayWithCapacity:10] retain];
		
		for (int i= 0; i < [allPeople count]; i++) {
			ABRecordRef person = [allPeople objectAtIndex:i];
			if (ABPersonHasImageData (person)) {
				[gfxPeople addObject:(id)person];
			}
		}
		
		textures = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
		
		CFRelease (addressBook);
	}
	
	return self;
}

-(void) dealloc
{
	[textures release];
	[allPeople release];
	[gfxPeople release];
	
	[super dealloc];
}

-(NSString *) getPersonName:(ABRecordRef)person
{
	return [NSString stringWithString:[(NSString *) ABRecordCopyCompositeName(person) autorelease]];
}

-(CCTexture2D *) getPersonImage:(ABRecordRef)person
{
	NSString *k = [self getPersonName:person];
	CCTexture2D *image = [textures objectForKey:k];
	
	if (image == nil) {
		image = [[[CCTexture2D alloc] initWithImage:scaledCopyOfUIImage ([UIImage imageWithData:[(NSData *)ABPersonCopyImageData (person) autorelease]], CGSizeMake (64, 64))] autorelease];
		if (image)
			[textures setObject:image forKey:k];
	}
	return image;
}

@end
