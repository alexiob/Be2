//
//  KKLuaManager.mm
//  Be2
//
//  Created by Alessandro Iob on 12/14/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "KKLuaManager.h"
#import "SynthesizeSingleton.h"
#import "KKMacros.h"
#import "CCFileUtils.h"

#import "stdarg.h"

#define BEGIN_STACK_MODIFY(L) int __startStackIndex = lua_gettop((L));
#define END_STACK_MODIFY(L, i) while(lua_gettop((L)) > (__startStackIndex + (i))) lua_remove((L), __startStackIndex + 1);

@implementation KKLuaManager

SYNTHESIZE_SINGLETON(KKLuaManager);

-(id) init
{
	self = [super init];
	
	if (self) {
		mainState = lua_open ();
		
		luaopen_base (mainState);
		luaopen_math (mainState);
		luaopen_string (mainState);
		luaopen_table (mainState);

		lua_settop (mainState, 0);
		
		[self setupGlobals];
	}
	
	return self;
}

-(void) dealloc
{
	lua_close (mainState);
	
	[super dealloc];
}

-(void) setupGlobals
{
}

-(void) addLibrary:(NSString *)name lib:(const luaL_reg *)lib
{
	luaL_openlib (mainState, STR_NS2C(name), lib, 0);
}

-(BOOL) isFunctionDefined:(NSString *)name
{
	BOOL r = NO;
	
	lua_getglobal (mainState, STR_NS2C(name));
	if (lua_type (mainState, -1) == LUA_TFUNCTION) r = YES;
	lua_pop (mainState, 1);
	
	return r;
}

-(BOOL) getGlobalBool:(NSString *)name
{
	BOOL r = NO;
	
	lua_getglobal (mainState, STR_NS2C(name));
	if (lua_isboolean (mainState, -1))
		r = lua_toboolean (mainState, -1);
	lua_pop (mainState, 1);
	
	return r;
}

-(float) getGlobalFloat:(NSString *)name
{
	float r = 0.0;
	
	lua_getglobal (mainState, STR_NS2C(name));
	if (lua_isnumber (mainState, -1))
		r = lua_tonumber (mainState, -1);
	lua_pop (mainState, 1);
	
	return r;
}

-(int) getGlobalInteger:(NSString *)name
{
	float r = [self getGlobalFloat:name];
	
	return (int) r;
}

-(NSString *) getGlobalString:(NSString *)name
{
	NSString *r = nil;
	
	lua_getglobal (mainState, STR_NS2C(name));
	if (lua_isstring (mainState, -1))
		r = STR_C2NS (lua_tostring (mainState, -1));
	lua_pop (mainState, 1);
	
	return r;
}

-(id) getGlobal:(NSString *)name
{
	id r = nil;
	
	lua_getglobal (mainState, STR_NS2C(name));
	r = [self luaToObj:-1];
	lua_pop (mainState, 1);
	
	return r;
}

-(void) setGlobal:(NSString *)name toBool:(BOOL)val
{
	lua_pushboolean (mainState, val);
	lua_setglobal (mainState, STR_NS2C(name));
}

-(void) setGlobal:(NSString *)name toFloat:(float)val
{
	lua_pushnumber (mainState, val);
	lua_setglobal (mainState, STR_NS2C(name));
}

-(void) setGlobal:(NSString *)name toInteger:(int)val
{
	lua_pushinteger (mainState, val);
	lua_setglobal (mainState, STR_NS2C(name));
}

-(void) setGlobal:(NSString *)name toString:(NSString *)val
{
	lua_pushstring (mainState, STR_NS2C(val));
	lua_setglobal (mainState, STR_NS2C(name));
}

-(void) setGlobal:(NSString *)name toObject:(id)val
{
	[self objToLua:val];
	lua_setglobal (mainState, STR_NS2C(name));
}

-(id) luaToObj:(int)stackIdx
{
	id obj;
	int objType = lua_type (mainState, stackIdx);
	BOOL isDict = NO;
	
	switch (objType) {
		case LUA_TNIL:
		case LUA_TNONE:
			obj = nil;
			break;
		case LUA_TBOOLEAN:
		case LUA_TNUMBER:
			obj = [NSNumber numberWithDouble:lua_tonumber (mainState, stackIdx)];
			break;
		case LUA_TSTRING:
			obj = [NSString stringWithUTF8String:lua_tostring (mainState, stackIdx)];
			break;
		case LUA_TTABLE:
			lua_pushvalue(mainState, stackIdx);
			lua_pushnil(mainState);
			while (!isDict && lua_next(mainState, -2)) {
				if (lua_type (mainState, -2) != LUA_TNUMBER) {
					isDict = YES;
					lua_pop (mainState, 2);
				} else {
					lua_pop (mainState, 1);
				}
			}
			
			if (isDict) {
				obj = [NSMutableDictionary dictionary];
				lua_pushnil (mainState);
				while (lua_next (mainState, -2)) {
					id key = [self luaToObj:-2];
					id val = [self luaToObj:-1];
					[obj setObject:val forKey:key];
					lua_pop (mainState, 1);
				}
			} else {
				obj = [NSMutableArray array];
				lua_pushnil (mainState);
				while (lua_next (mainState, -2)) {
					int idx = lua_tonumber(mainState, -2) - 1;
					id val = [self luaToObj:-1];
					[obj insertObject:val atIndex:idx];
					lua_pop (mainState, 1);
				}
			}
			lua_pop (mainState, 1);
			break;
		default:
			KKLOG(@"unsupported type %d", objType);
			obj = nil;
			break;
	}
	return obj;
}

-(void) objToLua:(id)obj
{
	BEGIN_STACK_MODIFY (mainState);
	
	if ([obj isKindOfClass:[NSNumber class]]) {
		if (strcmp ([obj objCType], @encode (_Bool)) == 0)
			lua_pushboolean (mainState, [obj boolValue]);
		else
			lua_pushnumber (mainState, [obj doubleValue]);
	} else if ([obj isKindOfClass:[NSString class]]) {
		lua_pushstring (mainState, [obj UTF8String]);
	} else if ([obj isKindOfClass:[NSData class]]) {
		lua_pushlstring (mainState, [obj bytes], [obj length]);
	} else if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]]) {
		lua_newtable (mainState);
		for (id o in obj) {
			int i = lua_objlen (mainState, -1);
			[self objToLua:o];
			lua_rawseti (mainState, -2, i + 1);
		}
	} else if ([obj isKindOfClass:[NSDictionary class]]) {
		lua_newtable (mainState);
		for (id key in obj) {
			[self objToLua:key];
			[self objToLua:[obj objectForKey:key]];
			lua_rawset (mainState, -3);
		}
	} else {
		KKLOG(@"invalid obj %@", obj);
	}
	
	END_STACK_MODIFY (mainState, 1);
}

-(void) callFunction:(NSString *)name withObjects:(id)arg, ...
{
	int n_args = 0;
	va_list args;

	lua_getglobal (mainState, STR_NS2C(name));
	if (arg != nil) {
		va_start (args, arg);
		
		while (arg != nil) {
			n_args++;
			[self objToLua:arg];
			arg = va_arg (args, id);
		}
		va_end (args);
	}
	lua_call (mainState, n_args, 0);
}

-(void) loadFile:(NSString *)filename
{
	NSString *path = [CCFileUtils fullPathFromRelativePath:filename];
	if (![[NSFileManager defaultManager] isReadableFileAtPath:path]) {
		KKLOG (@"could not read '%@' file", path);
		return;
	}
		
	KKLOG (@"%@", path);
	int err = luaL_dofile (mainState, STR_NS2C(path));
	
	if (err) {
		KKLOG (@"%s", lua_tostring (mainState, -1));
		lua_pop (mainState, 1);
	}
}

-(void) loadString:(NSString *)str
{
	int err = luaL_dostring (mainState, STR_NS2C(str));
	
	if (err) {
		KKLOG (@"%s", lua_tostring (mainState, -1));
		lua_pop (mainState, 1);
	}
}

-(void) execString:(NSString *)str
{
	int err = luaL_dostring (mainState, STR_NS2C(str));
	
	if (err) {
		KKLOG (@"%s", lua_tostring (mainState, -1));
		lua_pop (mainState, 1);
	}
}

@end
