//
//  KKLuaManager.h
//  Be2
//
//  Created by Alessandro Iob on 12/14/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"	

#import "KKStringUtilities.h"

#define SCRIPT_EXT @"lua"
#define SCRIPT_TEMPLATE_EXT @"luat"

#define KKLM [KKLuaManager sharedKKLuaManager]

lua_State *mainState;

@interface KKLuaManager : NSObject {
}

+(KKLuaManager *) sharedKKLuaManager;
+(void) purgeSharedKKLuaManager;

-(void) setupGlobals;

-(void) addLibrary:(NSString *)name lib:(const luaL_reg *)lib;

-(BOOL) isFunctionDefined:(NSString *)name;

-(BOOL) getGlobalBool:(NSString *)name;
-(float) getGlobalFloat:(NSString *)name;
-(int) getGlobalInteger:(NSString *)name;
-(NSString *) getGlobalString:(NSString *)name;
-(id) getGlobal:(NSString *)name;

-(void) setGlobal:(NSString *)name toBool:(BOOL)val;
-(void) setGlobal:(NSString *)name toFloat:(float)val;
-(void) setGlobal:(NSString *)name toInteger:(int)val;
-(void) setGlobal:(NSString *)name toString:(NSString *)val;
-(void) setGlobal:(NSString *)name toObject:(id)val;

-(id) luaToObj:(int)stackIdx;
-(void) objToLua:(id)obj;

-(void) loadFile:(NSString *)filename;
-(void) loadString:(NSString *)str;

-(void) callFunction:(NSString *)name withObjects:(id)arg, ...;

-(void) execString:(NSString *)str;

@end
