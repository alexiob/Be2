//
//  KKControlServerManager.m
//  be2
//
//  Created by Alessandro Iob on 9/7/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#ifdef KK_DEBUG

#import "KKControlServerManager.h"
#import "SynthesizeSingleton.h"
#import "AsyncSocket.h"
#import "KKMacros.h"
#import "KKStringUtilities.h"
#import "KKLuaManager.h"

@implementation KKControlServerManager

SYNTHESIZE_SINGLETON(KKControlServerManager);

@synthesize isRunning;

-(id) init
{
	self = [super init];
	
	if (self) {
		controlServer = [[AsyncSocket alloc] initWithDelegate:self];

		connectedClients = [[NSMutableArray alloc] initWithCapacity:1];
		
		netService = [[NSNetService alloc] initWithDomain:@"" type:@"_Be2ControlServer._tcp." name:@"" port:CONTROL_SERVER_PORT];
		netService.delegate = self;
		
		isRunning = NO;
		
		lm = KKLM;
	}
	
	return self;
}

-(void) dealloc
{
	[self stop];
	
	if (netService) {
		[netService release];
		netService = nil;
	}
	
	[super dealloc];
}

-(void) start
{
	if (isRunning) return;
	
	NSError *e = nil;
	if (![controlServer acceptOnPort:CONTROL_SERVER_PORT error:&e]) {
		KKLOG (@"Error starting ControlServer: %@", [e description]);
		return;
	}

	[netService publish];
	
	isRunning = YES;
	
	KKLOG (@"ControlServer running on %@:%d", [controlServer localHost], [controlServer localPort]);
}

-(void) stop
{
	if (!isRunning) return;
	
	[netService stop];
	
	[controlServer disconnect];
	
	for (AsyncSocket *s in connectedClients) {
		[s disconnect];
	}
	
	isRunning = NO;
}

#pragma mark -
#pragma mark AsyncSocket Delegates

typedef enum {
	WelcomeMsgTag = 1,
	GenericMsgTag,
} tMsgTag;

-(void) onSocket:(AsyncSocket *)socket didAcceptNewSocket:(AsyncSocket *)newSocket;
{
    [connectedClients addObject:newSocket];
}


-(void) onSocketDidDisconnect:(AsyncSocket *)socket;
{
    [connectedClients removeObject:socket];
}

-(void) onSocket:(AsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port;
{
    KKLOG(@"Accepted client %@:%d", host, port);
    
    NSData *welcomeData = [@"********** Welcome to the Be2 Control Server **********\r\n" 
                           dataUsingEncoding:NSUTF8StringEncoding];
    [socket writeData:(NSData *)welcomeData withTimeout:-1 tag:WelcomeMsgTag];
    
    [socket readDataWithTimeout:-1 tag:GenericMsgTag];
}

#include <unistd.h>

int redirectOutputToClient(void *inFD, const char *buffer, int size)
{
	NSString *t = STR_C2NS (buffer);
	[[KKControlServerManager sharedKKControlServerManager] performSelector:@selector(sendOutputToClient:) withObject:t];
	return 0;
}

-(void) sendOutputToClient:(NSString*)o
{
	NSData *oData = [o dataUsingEncoding:NSUTF8StringEncoding];
	[tmpSocket writeData:oData withTimeout:-1 tag:GenericMsgTag];
//	[tmpSocket writeData:[@"\r\nbe2> " dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:GenericMsgTag];
}

-(void) onSocket:(AsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag;
{
    NSString *tmp = [NSString stringWithUTF8String:(const char *)[data bytes]];
    NSString *input = [tmp stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([input isEqualToString:@"exit"]) {
        NSData *byeData = [@"********** Enjoy and Share **********\r\n" dataUsingEncoding:NSUTF8StringEncoding];
        [socket writeData:byeData withTimeout:-1 tag:GenericMsgTag];
        [socket disconnectAfterWriting];
        return;
    } else {
//		KKLOG (@"1: o: %d e: %d", stdout->_write, stderr->_write);
//		int (*of)(void *, char const *, int) = stdout->_write;
//		int (*ef)(void *, char const *, int) = stderr->_write;
//		stdout->_write = redirectOutputToClient;
//		stderr->_write = redirectOutputToClient;
//		tmpSocket = socket;
		KKLOG (@"Exec command: %@", input);
		[lm execString:input];
//		stdout->_write = of;
//		stderr->_write = ef;
//		KKLOG (@"2: o: %d e: %d", stdout->_write, stderr->_write);
//		tmpSocket = nil;
    }
    
    [socket readDataWithTimeout:-1 tag:GenericMsgTag];
}

#pragma mark -
#pragma mark Bonjour Delegates

-(void) netService:(NSNetService *)netService didNotPublish:(NSDictionary *)errorDict
{
	KKLOG (@"ControlServer Bonjour service not running: %@", [errorDict description]);
}

@end

#endif

