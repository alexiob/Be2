//
//  KKControlServerManager.h
//  be2
//
//  Created by Alessandro Iob on 9/7/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#ifdef KK_DEBUG

#define CONTROL_SERVER_PORT 4242
#define CONTROL_SERVER_HEADER_BINARY_COMMAND 0x060642

@class AsyncSocket;
@class KKLuaManager;

@interface KKControlServerManager : NSObject <NSNetServiceDelegate> {
	NSNetService *netService;
	AsyncSocket *controlServer;
	NSMutableArray *connectedClients;
	
	KKLuaManager *lm;
	
	BOOL isRunning;
	
	AsyncSocket *tmpSocket;
}

@property (readonly) BOOL isRunning;

+(KKControlServerManager *) sharedKKControlServerManager;
+(void) purgeSharedKKControlServerManager;

-(void) start;
-(void) stop;

@end

#endif