//
//  KKScreen.m
//  be2
//
//  Created by Alessandro Iob on 2/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKScreen.h"
#import "KKMacros.h"
#import "KKStringUtilities.h"
#import "KKLevel.h"
#import "KKLuaManager.h"
#import "KKObjectsManager.h"
#import "KKGameEngine.h"
#import "KKGraphicsManager.h"
#import "KKLuaCalls.h"

#import "CocosDenshion.h"

#define GET_BORDER_SIZE(__K__,__F__) (flags & __F__ ? DICT_FLOAT (data, __K__, DEFAULT_SCREEN_BORDER_SIZE) : 0)

@implementation KKScreen

@synthesize index, kind, flags, difficulty, data;
@synthesize title, desc;
@synthesize position, size;
@synthesize minSpeed, maxSpeed;
@synthesize availableTime;
@synthesize active;
@synthesize numLights;
@synthesize numPaddles, paddles;
@synthesize colorMode, opacity, color1, color2, colorTintToDuration;
@synthesize titleColor, descriptionColor; //, messageColor, messageOpacity, messageEnabled;
@synthesize bbox;
@synthesize audioSoundLoopID;
@synthesize scorePerBorderHit;
@synthesize needsScriptUpdate;

#define BLOCK_SIZE 20
#define performLoadProgressMessage [gameEngine performSelectorOnMainThread:@selector(loadProgressEndWithMessage:) withObject:[NSString stringWithFormat:@"Initializing screen block %d", (index/BLOCK_SIZE) + 1] waitUntilDone:NO];

-(id) initWithData:(NSMutableDictionary *)paddleData fromLevel:(KKLevel *)aLevel withIndex:(int)idx
{
	self = [super init];
	if (self) {
		gameEngine = KKGE;
		luaManager = KKLM;
		
		index = idx;
		audioSoundLoopID = CD_NO_SOURCE;
		needsScriptUpdate = YES;
		
		if (!(index % BLOCK_SIZE)) performLoadProgressMessage;
		
		[self initScreen:paddleData fromLevel:aLevel];
	}
	return self;
}

-(void) dealloc
{
//	KKLOG (@"idx=%d", index);
	[self destroyScreen];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Properties

-(CGPoint) origin
{
	return position;
}

-(NSString *) name
{
	return [data objectForKey:@"name"];
}

-(void) setTitle:(NSString *)s
{
	if (title) {
		[title release];
		title = nil;
	}
	title = [s copy];
	if (level)
		[level setTitle:title];
}

-(void) setDesc:(NSString *)s
{
	if (desc) {
		[desc release];
		desc = nil;
	}
	desc = [s copy];
	if (level)
		[level setDescription:desc];
}

-(BOOL) isCheckpoint
{
	return DICT_BOOL (data, @"isCheckpoint", NO);
}

-(BOOL) shown
{
	return visibilityCounter != 0;
}

-(BOOL) visible
{
	return [self shown];
}

-(void) setShown:(BOOL)f
{
	if (f) {
		visibilityCounter++;
	} else {
		visibilityCounter--;
		if (visibilityCounter < 0) visibilityCounter = 0;
	}

	BOOL b = visibilityCounter != 0;
	
	for (int i = 0; i < numPaddles; i++) {
		if ([paddles[i] isGlobal]) continue;
		[paddles[i] setShown:b];
	}
}

-(void) applyShown
{
	BOOL b = visibilityCounter != 0;

//	KKLOG (@"idx:%d b:%d visibilityCounter:%d enabled:%d", index, b, visibilityCounter);

	for (int i=0; i < numLights; i++) {
		[level.lightGrid setLightWithID:lights[i] visible:b];
	}
	
	for (int i = 0; i < numPaddles; i++) {
		if ([paddles[i] isGlobal]) continue;
		
		if (paddles[i].enabled)
			[paddles[i] applyShown];
	}
}

-(CGPoint) positionToDisplay
{
	return ccp (position.x - level.currentScreen.position.x, position.y - level.currentScreen.position.y);
}

-(CGPoint) centerPositionToDisplay
{
	return ccp (position.x - level.currentScreen.position.x + size.width/2, position.y - level.currentScreen.position.y + size.height/2);
}

//-(void) setMessageEnabled:(BOOL)f
//{
//	[level setMessageEnabled:f];
//	
//	messageEnabled = f;
//}

-(CGSize) sizeWithoutBorders
{
	borderSize[kScreenBorderSideTop] = SCALE_Y(GET_BORDER_SIZE (@"borderSizeTop", kScreenFlagTopSideClosed));
	borderSize[kScreenBorderSideBottom] = SCALE_Y(GET_BORDER_SIZE (@"borderSizeBottom", kScreenFlagBottomSideClosed));
	borderSize[kScreenBorderSideLeft] = SCALE_X(GET_BORDER_SIZE (@"borderSizeLeft", kScreenFlagLeftSideClosed));
	borderSize[kScreenBorderSideRight] = SCALE_X(GET_BORDER_SIZE (@"borderSizeRight", kScreenFlagRightSideClosed));
	
	return CGSizeMake (
				size.width - (borderSize[kScreenBorderSideLeft] + borderSize[kScreenBorderSideRight]), 
				size.height - (borderSize[kScreenBorderSideTop] + borderSize[kScreenBorderSideBottom])
				);
}

-(NSString *) audioBackgroundMusic
{
	return [data objectForKey:@"audioBackgroundMusic"];
}

-(NSString *) audioInSound
{
	return [data objectForKey:@"audioInSound"];
}

-(NSString *) audioOutSound
{
	return [data objectForKey:@"audioOutSound"];
}

-(NSString *) audioSoundLoop
{
	return [data objectForKey:@"audioSoundLoop"];
}

-(CGPoint) heroStartPosition
{
	CGPoint p = SCALE_POINT (ccp (
								  DICT_FLOAT (data, @"heroStartPositionX", 0),
								  DICT_FLOAT (data, @"heroStartPositionY", 0)
								  ));
	return p;
}

#pragma mark -
#pragma mark Screen setup

-(void) initScreen:(NSMutableDictionary *)screenData fromLevel:(KKLevel *)aLevel
{
	data = screenData;
	level = aLevel;
	
	active = NO;
	visibilityCounter = 0;
	kind = [[data objectForKey:@"kind"] intValue];
	flags = [[data objectForKey:@"flags"] intValue];
	difficulty = [[data objectForKey:@"difficulty"] intValue];

	self.title = [data objectForKey:@"title"];
	self.desc = [data objectForKey:@"description"];
	
//	KKLOG (@"'%@' [%d]", self.name, self.flags & kScreenFlagScriptUpdate);

	titleColor = ccc3FromNsString (DICT_STRING (data, @"titleColor", @"255,255,255"));
	descriptionColor = ccc3FromNsString (DICT_STRING (data, @"descriptionColor", @"200,200,200"));
//	messageColor = ccc3FromNsString (DICT_STRING (data, @"messageColor", @"200,200,200"));
//	messageOpacity = DICT_INT (data, @"messageOpacity", 180);
//	self.messageEnabled = DICT_BOOL (data, @"messageEnabled", NO);
	
	position = SCALE_POINT(CGPointMake (
							[[data objectForKey:@"positionX"] floatValue],
							[[data objectForKey:@"positionY"] floatValue]
							));
	size = SCALE_SIZE(CGSizeMake (
					   [[data objectForKey:@"width"] floatValue],
					   [[data objectForKey:@"height"] floatValue]
					   ));

	minSpeed = SCALE_POINT(CGPointMake (
							[[data objectForKey:@"minSpeedX"] floatValue],
							[[data objectForKey:@"minSpeedY"] floatValue]
							));
	
	maxSpeed = SCALE_POINT(CGPointMake (
							[[data objectForKey:@"maxSpeedX"] floatValue],
							[[data objectForKey:@"maxSpeedY"] floatValue]
							));
	
	availableTime = DICT_FLOAT (data, @"availableTime", 0.0);
	
	scorePerBorderHit = DICT_INT (data, @"scorePerBorderHit", SCORE_PER_BORDER_HIT);

	borderSize[kScreenBorderSideTop] = SCALE_Y(GET_BORDER_SIZE (@"borderSizeTop", kScreenFlagTopSideClosed));
	borderSize[kScreenBorderSideBottom] = SCALE_Y(GET_BORDER_SIZE (@"borderSizeBottom", kScreenFlagBottomSideClosed));
	borderSize[kScreenBorderSideLeft] = SCALE_X(GET_BORDER_SIZE (@"borderSizeLeft", kScreenFlagLeftSideClosed));
	borderSize[kScreenBorderSideRight] = SCALE_X(GET_BORDER_SIZE (@"borderSizeRight", kScreenFlagRightSideClosed));

	borderElasticity[kScreenBorderSideTop] = DICT_FLOAT (data, @"borderElasticityTop", 1.0);
	borderElasticity[kScreenBorderSideBottom] = DICT_FLOAT (data, @"borderElasticityBottom", 1.0);
	borderElasticity[kScreenBorderSideLeft] = DICT_FLOAT (data, @"borderElasticityLeft", 1.0);
	borderElasticity[kScreenBorderSideRight] = DICT_FLOAT (data, @"borderElasticityRight", 1.0);
	
	[self setupScreenColor:[data objectForKey:@"color"]];
	[self setupScreenLights:[data objectForKey:@"lights"]];

	NSArray *paddlesData = [data objectForKey:@"paddles"];

	numPaddles = [paddlesData count];
	paddles = calloc (numPaddles, sizeof (KKPaddle*));
	
	for (int i = 0; i < numPaddles; i++) {
		paddles[i] = [level paddleAtIndex:[[paddlesData objectAtIndex:i] intValue]];
	}
	
	[self updateBBox];
	
	[self setupScripts:[data objectForKey:@"scripts"]];
}

-(void) destroyScreen
{
	if (audioSoundLoopID != CD_NO_SOURCE) {
		[gameEngine stopSound:audioSoundLoopID];
		audioSoundLoopID = CD_NO_SOURCE;
	}
	
	[luaManager execString:[NSString stringWithFormat:@"level.screens[%d]:destroy ()", index]];
	
	level = nil;
	data = nil;
	
	if (paddles) free (paddles), paddles = nil;
}

#pragma mark -
#pragma mark Scripts

-(void) setupScripts:(NSString *)scriptsData
{
	if (!scriptsData) scriptsData = @"";
	
	@try {
		NSString *s = [NSString stringWithFormat:GET_SHARED_OBJECT (TEMPLATE_SCREEN),
					   scriptsData,
					   index
					   ];
		[luaManager loadString:s];
	}
	@catch (NSException *e) {
		KKLOG (@"%@", [e reason]);
	}
}

#pragma mark -
#pragma mark Utilities

-(NSArray *) paddlesIndexArray
{
	return [data objectForKey:@"paddles"];
}

-(CGPoint) globalToScreenPoint:(CGPoint)p
{
	return ccp (p.x + position.x, p.y + position.y);
}

-(CGPoint) screenToGlobalPoint:(CGPoint)p
{
	return ccp (p.x - position.x, p.y - position.y);
}

-(CGRect) calcBBox
{
	return CGRectMake (
					   position.x + borderSize[kScreenBorderSideLeft], 
					   position.y + borderSize[kScreenBorderSideBottom], 
					   size.width - (borderSize[kScreenBorderSideLeft] + borderSize[kScreenBorderSideRight]),
					   size.height - (borderSize[kScreenBorderSideBottom] + borderSize[kScreenBorderSideTop])
					   );
}

-(void) updateBBox
{
	bbox = [self calcBBox];
}

-(float) borderSize:(tScreenBorderSide)side
{
	return borderSize[side];
}

-(float) borderElasticity:(tScreenBorderSide)side
{
	return borderElasticity[side];
}

-(KKLight *) light:(int)idx
{
	return [level.lightGrid lightWithID:lights[idx]];
}

-(BOOL) screenBorderActive:(tScreenBorderSide)border
{
	BOOL f = NO;
	
	switch (border) {
		case kScreenBorderSideTop:
			f = flags & kScreenFlagTopSideClosed;
			break;
		case kScreenBorderSideBottom:
			f = flags & kScreenFlagBottomSideClosed;
			break;
		case kScreenBorderSideLeft:
			f = flags & kScreenFlagLeftSideClosed;
			break;
		case kScreenBorderSideRight:
			f = flags & kScreenFlagRightSideClosed;
			break;
	}
	return f;
}

-(void) setScreenBorder:(tScreenBorderSide)border active:(BOOL)f
{
	int borderFlags = 0;
	
	switch (border) {
		case kScreenBorderSideTop:
			borderFlags = kScreenFlagTopSideClosed;
			break;
		case kScreenBorderSideBottom:
			borderFlags = kScreenFlagBottomSideClosed;
			break;
		case kScreenBorderSideLeft:
			borderFlags = kScreenFlagLeftSideClosed;
			break;
		case kScreenBorderSideRight:
			borderFlags = kScreenFlagRightSideClosed;
			break;
	}
	
	if (borderFlags) {
		if (f)
			flags |= borderFlags;
		else
			flags ^= borderFlags;
	}
	
	[self updateBBox];
	
	if (self == level.currentScreen)
		[level setScreenBorder:border active:f];
}

#pragma mark -
#pragma mark Setup

-(void) setupScreenLights:(NSArray *)lightsData
{
	for (int i = 0; i < numLights; i++) {
		if (lights[i] != 0) {
			[level.lightGrid removeLightWithID:lights[i]];
			lights[i] = 0;
		}
	}
	numLights = 0;
	
	if (!lightsData) return;
	
	numLights = 0;
	
	for (NSDictionary *lData in lightsData) {
		int lID = [[lData objectForKey:@"lightID"] intValue];
		KKLight *light = [level.lightGrid addLightWithID:lID kind:DICT_INT (lData, @"kind", kLightKindRect)];
		
		light.visible = NO;
		light.enabled = DICT_BOOL (lData, @"enabled", YES);
		light.flags = DICT_INT (lData, @"flags", 0) | kLightFlagBindToEntity;
		light.entity = self;
		light.opacity = DICT_INT (lData, @"opacity", 0);
		if ([lData objectForKey:@"color"]) light.color = ccc3FromNsString ([lData objectForKey:@"color"]);
		light.position = CGPointMake (
								 level.lightGrid.gridWidth * DICT_FLOAT (lData, @"positionX", 0.5), 
								 level.lightGrid.gridHeight * DICT_FLOAT (lData, @"positionY", 0.5)
								 );
		light.size = CGSizeMake (
								 DICT_INT (lData, @"width", 4), 
								 DICT_INT (lData, @"height", 4)
								 );
		light.power = DICT_FLOAT (lData, @"power", 0.0);
		
		lights[numLights] = light.lightID;
		
		numLights++;
		if (numLights >= SCREEN_MAX_LIGHTS) {
			KKLOG (@"too many lights %d (max is %d).", [lightsData count], SCREEN_MAX_LIGHTS);
			break;
		}
	}
}	

-(void) setupScreenColor:(NSDictionary *)colorData
{
	colorMode = [[colorData objectForKey:@"mode"] intValue];
	
	switch (colorMode) {
		case kEntityColorModeTintTo:
			color1 = ccc3FromNsString ([colorData objectForKey:@"color1"]);
			color2 = ccc3FromNsString ([colorData objectForKey:@"color2"]);
			colorTintToDuration = [[colorData objectForKey:@"tintToDuration"] floatValue];
			break;
		case kEntityColorModeSolid:
		default:
			color1 = ccc3FromNsString ([colorData objectForKey:@"color1"]);
			break;
	}
	if ([colorData objectForKey:@"opacity"]) {
		opacity = [[colorData objectForKey:@"opacity"] intValue];
	} else {
		opacity = 255;
	}
}

#pragma mark -
#pragma mark Update

-(void) update:(ccTime)dt
{
}

-(void) paddlesOnEnterAndOnExit
{
	for (int i = 0; i < numPaddles; i++) {
		KKPaddle *p = paddles[i];
	
		if (!p.enabled) continue;
		if ([p isGlobal]) continue;

		if (p.visibilityCounter == 1) {
			if (p.flags & kPaddleFlagScriptOnEnter) paddleOnEnter(p.index);
			[p onEnterSounds];
		} else if (p.enabled && !p.shown) {
			if (p.flags & kPaddleFlagScriptOnExit) paddleOnExit(index);
			[p onExitSounds];
		}
	}
}

-(void) onEnter
{
	needsScriptUpdate = YES;
	
	if (flags & kScreenFlagScriptOnEnter)
		screenOnEnter(index);
	
	[self paddlesOnEnterAndOnExit];
}

-(void) onExit
{
	if (flags & kScreenFlagScriptOnExit)
		screenOnExit(index);
	
	[self paddlesOnEnterAndOnExit];
}

@end
