//
//  KKPaddle.m
//  be2
//
//  Created by Alessandro Iob on 2/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKPaddle.h"
#import "KKMacros.h"
#import "KKStringUtilities.h"
#import "KKMath.h"
#import "KKCollisionDetection.h"
#import "KKLevel.h"
#import "KKLuaManager.h"
#import "KKGameEngine.h"
#import "KKObjectsManager.h"
#import "KKGraphicsManager.h"
#import "KKLuaCalls.h"
#import "KKAIClasses.h"
#import "KKHUDLayer.h"

#import "CocosDenshion.h"

@implementation KKPaddle

@synthesize level, index, kind, flags, data;
@synthesize visibilityCounter;
@synthesize z, size, acceleration, speed;
@synthesize minPosition, maxPosition;
@synthesize proximityMode, proximityArea, proximityAcceleration;
@synthesize elasticity;
@synthesize bbox;
//@synthesize label;
@synthesize numLights;
@synthesize offensiveAI, offensiveAIKind, defensiveAI, defensiveAIKind;
@synthesize audioSoundLoopID;
@synthesize scorePerHit;

#define PADDLE_DEFAULT_LABEL_FONT @"orangekid"
#define PADDLE_DEFAULT_LABEL_FONT_SIZE 16
#define PADDLE_DEFAULT_LABEL_COLOR @"0,0,0"
#define PADDLE_DEFAULT_LABEL_OPACITY 255

#define PADDLE_LABEL_Z 10
#define PADDLE_TOP_IMAGE_Z 8

#define MOVE_TIME_DELTA 1.0
#define MOVE_DELTA 5

#define BLOCK_SIZE 30
#define performLoadProgressMessage [gameEngine performSelectorOnMainThread:@selector(loadProgressEndWithMessage:) withObject:[NSString stringWithFormat:@"Initializing paddle block %d", (index/BLOCK_SIZE) + 1] waitUntilDone:NO];

-(id) initWithData:(NSMutableDictionary *)paddleData fromLevel:(KKLevel *)aLevel withIndex:(int)idx
{
	self = [super init];
	if (self) {
		gameEngine = KKGE;
		luaManager = KKLM;
		
		index = idx;
		level = aLevel;
		label = nil;
		audioSoundLoopID = CD_NO_SOURCE;
		runtimeFlags = 0;
		
		msgIdx = -1;
		msgBGColor = self.color;
		msgColor = HUD_MESSAGE_COLOR;
		msgIcnColor = HUD_MESSAGE_EMOTICON_COLOR;
		msgFontSize = HUD_MESSAGE_FONT_SIZE;
		
		lastMovement = CGPointZero;
		lastMovementTime = MOVE_TIME_DELTA;
		
		[self setLabelFont:PADDLE_DEFAULT_LABEL_FONT ofSize:PADDLE_DEFAULT_LABEL_FONT_SIZE];
		
		[self setVisible:NO];
		[self setOpacityModifyRGB:NO];
		
		if (!(index % BLOCK_SIZE)) performLoadProgressMessage;
		
		[self initPaddle:paddleData];
	}
	return self;
}

-(void) dealloc
{
	[self destroyLabel];
	[self destroyPaddle];
	
	[super dealloc];
}

#define MIN_OPACITY 250

-(void) draw
{	
	if (!texture_) {
		// Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
		// Needed states: GL_VERTEX_ARRAY, GL_COLOR_ARRAY
		// Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY
		
		BOOL newBlend = NO;
		if (self.opacity < MIN_OPACITY) {
			if (blendFunc_.src != CC_BLEND_SRC || blendFunc_.dst != CC_BLEND_DST) {
				newBlend = YES;
				glBlendFunc (blendFunc_.src, blendFunc_.dst);
			}
		}
		
#define kQuadSize sizeof(quad_.bl)

		glDisableClientState (GL_TEXTURE_COORD_ARRAY);
		glDisable (GL_TEXTURE_2D);
		
		int offset = (int)&quad_;
		
		// vertex
		int diff = offsetof ( ccV3F_C4B_T2F, vertices);
		glVertexPointer (3, GL_FLOAT, kQuadSize, (void*) (offset + diff) );
		
		// color
		diff = offsetof ( ccV3F_C4B_T2F, colors);
		glColorPointer (4, GL_UNSIGNED_BYTE, kQuadSize, (void*)(offset + diff));
		
		glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);
		
		if (newBlend)
			glBlendFunc (CC_BLEND_SRC, CC_BLEND_DST);
		
		glEnableClientState (GL_TEXTURE_COORD_ARRAY);
		glEnable (GL_TEXTURE_2D);
	} else {
		[super draw];
	}
}

#pragma mark -
#pragma mark Properties

-(NSString *) name
{
	NSString *s = [data objectForKey:@"name"];
	return (s ? s : @"");
}

-(void) runColorModeTintToAction
{
	if (colorMode == kEntityColorModeTintTo) {
		[self stopActionByTag:kEntityColorModeTintTo];
		CCAction *action = [CCRepeatForever actionWithAction:[CCSequence actions:
															  [CCTintTo actionWithDuration:colorTintToDuration red:color2.r green:color2.g blue:color2.b],
															  [CCTintTo actionWithDuration:colorTintToDuration red:color1.r green:color1.g blue:color1.b],
															  nil
															  ]
							];
		action.tag = kPaddleActionColorTintTo;
		[self runAction:action];
	}
}

-(void) applyShown
{
	BOOL v = self.enabled && self.shown;

//	KKLOG (@"idx:%d v:%d visibilityCounter:%d enabled:%d apply:%d", index, v, visibilityCounter, self.enabled, self.visible != v);

	if (self.visible != v) {
		CCAction *action = nil;
		
		[self stopActionByTag:kPaddleActionFadeTo];
		[label stopActionByTag:kPaddleActionFadeTo];
		
		if (self.isInvisible == NO) {
			if (v) {
				[self setOpacity:0];
				action = [CCSequence actions:
						  [CCShow action],
						  [CCFadeTo actionWithDuration:0.1 opacity:DICT_INT ([data objectForKey:@"color"], @"opacity", 255)],
						  [CCCallFunc actionWithTarget:self selector:@selector(runColorModeTintToAction)],
						  nil];
			} else {
				action = [CCSequence actions:
						  [CCFadeTo actionWithDuration:0.1 opacity:0],
						  [CCHide action],
						  nil];
			}
			action.tag = kPaddleActionFadeTo;
		} else {
			self.visible = v;
		}
		
		if (action) {
			[self runAction:action];
			[label runAction:[[action copy] autorelease]];
		}
			
		for (int i=0; i < numLights; i++) {
			[level.lightGrid setLightWithID:lights[i] visible:v];
		}
	}
}

-(BOOL) shown
{
	return visibilityCounter != 0;
}

-(void) setShown:(BOOL)f
{
	if (f) {
		visibilityCounter++;
	} else {
		visibilityCounter--;
		if (visibilityCounter < 0) visibilityCounter = 0;
	}
}
	
-(void) updateBBox
{
	bbox = CGRectMake (self.position.x, self.position.y, size.width, size.height);
}

-(void) setPosition:(CGPoint)pos
{
	[super setPosition:pos];
	[self updateBBox];
}

-(void) setSize:(CGSize)s
{
	size = s;
	[self setTextureRect:CGRectMake (0, 0, size.width, size.height)];
	[self updateBBox];
	[self updateLabelPosition];
}

-(void) setSpeed:(CGPoint)s
{
//	if (index == 0) KKLOG (@"%@ %@", NSStringFromCGPoint (speed), NSStringFromCGPoint (s));
	speed = s;
}

-(CGPoint) center
{
	return ccp(self.position.x + size.width/2, self.position.y + size.height/2);
}

-(BOOL) isOffensiveSide
{
	return (flags & kPaddleFlagOffensiveSide) > 0;
}

-(BOOL) isDefensiveSide
{
	return !(flags & kPaddleFlagOffensiveSide);
}

-(CGPoint) positionToDisplay
{
	return ccp (self.position.x - level.currentScreen.position.x, self.position.y - level.currentScreen.position.y);
}

-(CGPoint) centerPositionToDisplay
{
	return ccp (self.position.x - level.currentScreen.position.x + size.width/2, self.position.y - level.currentScreen.position.y + size.height/2);
}

-(BOOL) isButton
{
	return (flags & kPaddleFlagIsButton) > 0;
}

-(void) setIsButton:(BOOL)f
{
	if (f) {
		flags |= kPaddleFlagIsButton;
	} else {
		flags ^= kPaddleFlagIsButton;
	}
}

-(BOOL) selected
{
	return (flags & kPaddleFlagSelected) > 0;
}

-(void) setSelected:(BOOL)f
{
	if (f) {
		flags |= kPaddleFlagSelected;
	} else {
		flags ^= kPaddleFlagSelected;
	}
}

-(BOOL) enabled
{
	return (flags & kPaddleFlagEnabled) > 0;
}

-(void) setEnabled:(BOOL)f
{
	if (f && !self.enabled) {
		flags |= kPaddleFlagEnabled;
	} else if (!f && self.enabled) {
		flags ^= kPaddleFlagEnabled;
	}
	[self applyShown];
}

-(BOOL) isInvisible
{
	return (flags & kPaddleFlagIsInvisible) == kPaddleFlagIsInvisible;
}

-(void) setIsInvisible:(BOOL)f
{
	if (f) {
		flags |= kPaddleFlagIsInvisible;
		[self fadeToOpacity:0 withDuration:0.3 tag:kPaddleActionInvisible];
	} else {
		flags ^= kPaddleFlagIsInvisible;
		[self fadeToOpacity:255 withDuration:0.3 tag:kPaddleActionInvisible];
	}
}

-(BOOL) isGlobal
{
	return (flags & kPaddleFlagIsGlobal) == kPaddleFlagIsGlobal;
}

#pragma mark -
#pragma mark FX Actions

-(void) actionStop:(int)aTag
{
	[self stopActionByTag:aTag];
}

-(void) actionRotateBy:(float)angle withDuration:(float)seconds forever:(BOOL)forever withTag:(int)aTag
{
	if (aTag) [self stopActionByTag:aTag];
	
	CCAction *action = [CCRotateBy actionWithDuration:seconds angle:angle];
	if (forever) action = [CCRepeatForever actionWithAction:(CCIntervalAction *)action];
	action.tag = aTag;
	[self runAction:action];
}

-(void) actionRotateTo:(float)angle withDuration:(float)seconds forever:(BOOL)forever withTag:(int)aTag
{
	if (aTag) [self stopActionByTag:aTag];
	
	CCAction *action = [CCRotateTo actionWithDuration:seconds angle:angle];
	if (forever) action = [CCRepeatForever actionWithAction:(CCIntervalAction *)action];
	action.tag = aTag;
	[self runAction:action];
}

-(void) actionScaleBy:(float)aScale withDuration:(float)seconds forever:(BOOL)forever withTag:(int)aTag
{
	if (aTag) [self stopActionByTag:aTag];
	
	CCAction *action = [CCScaleBy actionWithDuration:seconds scale:aScale];
	if (forever) action = [CCRepeatForever actionWithAction:(CCIntervalAction *)action];
	action.tag = aTag;
	[self runAction:action];
}

-(void) actionScaleTo:(float)aScale withDuration:(float)seconds forever:(BOOL)forever withTag:(int)aTag
{
	if (aTag) [self stopActionByTag:aTag];
	
	CCAction *action = [CCScaleTo actionWithDuration:seconds scale:aScale];
	if (forever) action = [CCRepeatForever actionWithAction:(CCIntervalAction *)action];
	action.tag = aTag;
	[self runAction:action];
}

-(void) actionPulseFromScale:(float)minScale toScale:(float)maxScale withDelay:(float)delay withDuration:(float)seconds withTag:(int)aTag
{
	if (aTag) [self stopActionByTag:aTag];
	
	CCAction *action = [CCRepeatForever actionWithAction:
						[CCSequence actions:
						 [CCScaleTo actionWithDuration:seconds scale:minScale],
						 [CCDelayTime actionWithDuration:delay],
						 [CCScaleTo actionWithDuration:seconds scale:maxScale],
						 nil
						 ]
						];
	
	action.tag = aTag;
	[self runAction:action];
}

-(void) tintToColor:(ccColor3B)c withDuration:(float)duration
{
	[self stopActionByTag:kPaddleActionColorTintTo];
	
	CCAction *action = [CCTintTo actionWithDuration:duration red:c.r green:c.g blue:c.b];
	action.tag = kPaddleActionColorTintTo;
	[self runAction:action];
}

-(void) fadeToOpacity:(int)o withDuration:(float)duration
{
	[self fadeToOpacity:o withDuration:duration tag:kPaddleActionFadeTo];
}

-(void) fadeToOpacity:(int)o withDuration:(float)duration tag:(int)tag
{
	[self stopActionByTag:tag];
	[label stopActionByTag:tag];
	
	CCAction *action = [CCFadeTo actionWithDuration:duration opacity:o];
	action.tag = tag;
	[self runAction:action];
	[label runAction:[[action copy] autorelease]];
}

-(void) flash
{
	[self stopActionByTag:kPaddleActionColorTintTo];
	
	CCAction *action = [CCSequence actions:
						[CCTintTo actionWithDuration:0.1 red:255 green:255 blue:255],
						[CCTintTo actionWithDuration:0.3 red:color1.r green:color1.g blue:color1.b],
						nil
						];
	action.tag = kPaddleActionColorTintTo;
	[self runAction:action];	
}

-(void) invisibleHit
{
	[self stopActionByTag:kPaddleActionInvisible];
	[label stopActionByTag:kPaddleActionInvisible];
	
	CCAction *action = [CCSequence actions:
						[CCFadeTo actionWithDuration:0.1 opacity:255],
						[CCFadeTo actionWithDuration:0.1 opacity:0],
						nil
						];
	action.tag = kPaddleActionInvisible;
	[self runAction:action];
	[label runAction:[[action copy] autorelease]];
}

#pragma mark -
#pragma mark Audio properties

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

-(NSString *) audioHitSound
{
	return [data objectForKey:@"audioHitSound"];
}

-(NSString *) audioMoveSound
{
	return [data objectForKey:@"audioMoveSound"];
}

-(NSString *) audioClickSound
{
	return [data objectForKey:@"audioClickSound"];
}

#pragma mark -
#pragma mark Sounds

-(void) onEnterSounds
{
	[gameEngine playSound:[self audioInSound] forPaddle:self];
	
	audioSoundLoopID = [gameEngine playSoundLoop:[self audioSoundLoop] forPaddle:self];
}

-(void) onExitSounds
{
	if (audioSoundLoopID != CD_NO_SOURCE) {
		[gameEngine stopSound:audioSoundLoopID];
		audioSoundLoopID = CD_NO_SOURCE;
	}

	[gameEngine playSound:[self audioOutSound] forPaddle:self];
}

#pragma mark -
#pragma mark Paddle setup

-(void) initPaddle:(NSMutableDictionary *)paddleData
{
	data = paddleData;

//	KKLOG (@"'%@' [%d]", self.name, paddleData);
	
	visibilityCounter = 0;
	
	[self setAnchorPoint:ccp(0, 0)];
	
	kind = DICT_INT (data, @"kind", 0);
	flags = DICT_INT (data, @"flags", 0);
	self.enabled = self.enabled;
	
	size = SCALE_SIZE(CGSizeMake (
					   [[data objectForKey:@"width"] floatValue],
					   [[data objectForKey:@"height"] floatValue]
					   ));
	speed = SCALE_POINT(CGPointMake (
					   DICT_FLOAT (data, @"speedX", 0),
					   DICT_FLOAT (data, @"speedY", 0)
					   ));
	
	minPosition = SCALE_POINT(CGPointMake (
						 DICT_FLOAT (data, @"minX", 0),
						 DICT_FLOAT (data, @"minY", 0)
						 ));
	maxPosition = SCALE_POINT(CGPointMake (
							   DICT_FLOAT (data, @"maxX", 0),
							   DICT_FLOAT (data, @"maxY", 0)
							   ));

	self.position = SCALE_POINT(ccp (
						 [[data objectForKey:@"positionX"] floatValue],
						 [[data objectForKey:@"positionY"] floatValue]
						 ));

	z = DICT_INT (data, @"z", 0);
	
	energy = DICT_FLOAT (data, @"energy", 1.0);
	elasticity = DICT_FLOAT (data, @"elasticity", 1.0);

	scorePerHit = DICT_INT (data, @"scorePerHit", SCORE_PER_HIT);
	
	audioMoveSoundTimeout = DICT_FLOAT (data, @"audioMoveSoundTimeout", MOVE_TIME_DELTA);
	audioMoveSound = DICT_STRING (data, @"audioMoveSound", @"");
	if ([audioMoveSound isEqualToString:@""]) audioMoveSound = nil;
	
	[self setupPaddleProximity:[data objectForKey:@"proximity"]];
	[self setupPaddleColor:[data objectForKey:@"color"]];
	[self setupPaddleTexture:DICT_STRING (data, @"textureName", @"")];
	[self setupPaddleLights:[data objectForKey:@"lights"]];
	[self setupPaddleLabel:[data objectForKey:@"label"]];
	[self setupPaddleTopImage:[data objectForKey:@"topImage"]];

	[self setupScripts:[data objectForKey:@"scripts"]];
	[self setupPaddleAI:[data objectForKey:@"ai"]];
	
	if (self.isInvisible) {
		[self setIsInvisible:YES];
	}
}

-(void) destroyPaddle
{
//	KKLOG (@"%d", index);
	if (audioSoundLoopID != CD_NO_SOURCE) {
		[gameEngine stopSound:audioSoundLoopID];
		audioSoundLoopID = CD_NO_SOURCE;
	}

	if (topImage) [topImage release], topImage = nil;
	
	[self destroyAI];
	data = nil;
}

#pragma mark -
#pragma mark Scripts

-(void) setupScripts:(NSString *)scriptsData
{
	if (!scriptsData) scriptsData = @"";
	
	@try {
		NSString *s = [NSString stringWithFormat:GET_SHARED_OBJECT (TEMPLATE_PADDLE),
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
#pragma mark Setup

-(void) destroyAI
{
	if (defensiveAI) [defensiveAI release], defensiveAI = nil;
	if (offensiveAI) [offensiveAI release], offensiveAI = nil;
	
	defensiveAIKind = 0;
	offensiveAIKind = 0;
}

-(NSDictionary *) dictFromAIConfig:(NSString *)aiConfig
{
	NSDictionary *config;

	if (aiConfig && ![aiConfig isEqualToString:@""]) {
		NSString *errorDesc = nil;
		NSPropertyListFormat plistFormat;
		NSData *plistData = [aiConfig dataUsingEncoding:NSUTF8StringEncoding];
		config = (NSDictionary *)[NSPropertyListSerialization
								  propertyListFromData:plistData 
								  mutabilityOption:NSPropertyListMutableContainersAndLeaves 
								  format:&plistFormat
								  errorDescription:&errorDesc
								  ];
	} else {
		config = [NSDictionary dictionary];
	}

	return config;
}

-(void) setupPaddleAI:(NSDictionary *)aiData
{
	if (!aiData) return;

	NSString *aiKind;
	NSString *aiConfig;
	
	[self destroyAI];
	
	aiKind = [aiData objectForKey:@"defensiveKind"];
	if (aiKind && ![aiKind isEqualToString:@""]) {
		aiConfig = [aiData objectForKey:@"defensiveConfig"];
		if ([aiKind isEqualToString:AI_SCRIPT]) {
			if (!aiConfig || [aiConfig isEqualToString:@""]) aiConfig = @"{}";
			[luaManager execString:[NSString stringWithFormat:@"level.paddles[%d]:setDefensiveAI (%@)", index, aiConfig]];
			defensiveAIKind = kAIKindScript;
		} else {
			NSDictionary *config = [self dictFromAIConfig:aiConfig];
			NSString *className = [NSString stringWithFormat:@"KKAI%@", [aiKind capitalizedString]];
			defensiveAI = [[NSClassFromString(className) alloc] initWithPaddle:self andConfig:config];
			defensiveAIKind = kAIKindClass;
		}
	}
	
	aiKind = [aiData objectForKey:@"offensiveKind"];
	if (aiKind && ![aiKind isEqualToString:@""]) {
		aiConfig = [aiData objectForKey:@"offensiveConfig"];
		if ([aiKind isEqualToString:AI_SCRIPT]) {
			if (!aiConfig || [aiConfig isEqualToString:@""]) aiConfig = @"{}";
			[luaManager execString:[NSString stringWithFormat:@"level.paddles[%d]:setOffensiveAI (%@)", index, aiConfig]];
			offensiveAIKind = kAIKindScript;
		} else {
			NSDictionary *config = [self dictFromAIConfig:aiConfig];
			NSString *className = [NSString stringWithFormat:@"KKAI%@", [aiKind capitalizedString]];
			offensiveAI = [[NSClassFromString(className) alloc] initWithPaddle:self andConfig:config];
			offensiveAIKind = kAIKindClass;
		}
	}
}

-(void) setupPaddleProximity:(NSDictionary *)proximityData
{
	if (!proximityData) {
		proximityMode = kPaddleProximityNone;
		proximityArea = CGSizeMake (0, 0);
		proximityAcceleration = ccp (0, 0);
		return;
	}
	
	proximityMode = [[proximityData objectForKey:@"mode"] intValue];
	switch (proximityMode) {
		case kPaddleProximityRect:
			proximityArea = SCALE_SIZE(CGSizeMake (
									   [[proximityData objectForKey:@"width"] floatValue],
									   [[proximityData objectForKey:@"height"] floatValue]
			));
			proximityAcceleration = SCALE_POINT(ccp (
										[[proximityData objectForKey:@"accelerationX"] floatValue],
										[[proximityData objectForKey:@"accelerationY"] floatValue]
										));
			
//			KKLOG (@"mode=%d area=%@ acc=%@", proximityMode, NSStringFromCGSize(proximityArea), NSStringFromCGPoint(proximityAcceleration));
			break;
//		case kPaddleProximityDisc:
//			proximityArea = CGSizeMake (
//									   [[proximityData objectForKey:@"width"] floatValue],
//									   0
//									   );
//			break;
		case kPaddleProximityNone:
		default:
			break;
	}
}

-(void) setupPaddleColor:(NSDictionary *)colorData
{
	for (int i = 0; i < numLights; i++) {
		if (lights[i] != 0) [level.lightGrid removeLightWithID:lights[i]];
	}
	numLights = 0;
	
	if (!colorData) return;
	
	[self stopActionByTag:kPaddleActionColorTintTo];
	
	colorMode = [[colorData objectForKey:@"mode"] intValue];
	switch (colorMode) {
		case kEntityColorModeTintTo:
			color1 = ccc3FromNsString ([colorData objectForKey:@"color1"]);
			color2 = ccc3FromNsString ([colorData objectForKey:@"color2"]);
			colorTintToDuration = [[colorData objectForKey:@"tintToDuration"] floatValue];
			
			[self setColor:color1];
			CCAction *action = [CCRepeatForever actionWithAction:[CCSequence actions:
																  [CCTintTo actionWithDuration:colorTintToDuration red:color2.r green:color2.g blue:color2.b],
																  [CCTintTo actionWithDuration:colorTintToDuration red:color1.r green:color1.g blue:color1.b],
																  nil
																  ]
								];
			action.tag = kPaddleActionColorTintTo;
			[self runAction:action];
			break;
		case kEntityColorModeSolid:
		default:
			color1 = ccc3FromNsString ([colorData objectForKey:@"color1"]);
//			KKLOG (@"(%d, %d, %d) %@", color1.r, color1.g, color1.b, [colorData objectForKey:@"color1"]);
			[self setColor:color1];
			break;
	}
	[self setOpacity:DICT_INT (colorData, @"opacity", 255)];
}

-(void) setupPaddleTexture:(NSString *)textureName
{
	if (!textureName || [textureName isEqualToString:@""]) {
		[self setTexture:nil];
		[self setTextureRect:CGRectMake (0, 0, size.width, size.height)];
	} else {
//		CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:textureName];
//		[self setTexture:frame.texture];
//		[self setTextureRect:frame.rect];
//		[self setDisplayFrame:frame];
	
		CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:[gameEngine pathForLevelGraphic:textureName]];
		if (texture) {
			CGRect rect = CGRectZero;
			rect.size = texture.contentSize;
			[texture setAntiAliasTexParameters];
			[self setTexture:texture];
			[self setTextureRect:rect];
			
			[self setScaleX:(1.0 / rect.size.width) * size.width];
			[self setScaleY:(1.0 / rect.size.height) * size.height];
		}
	}
}

-(void) setTopImage:(NSString *)path positionX:(float)x positionY:(float)y width:(float)w height:(float)h anchorX:(float)ax anchorY:(float)ay opacity:(int)o rotation:(float)r
{
	if (!path || [path isEqualToString:@""]) {
		if (topImage) topImage.visible = NO;
		return;	
	}
	
	if (!topImage) {
		topImage = [[CCSprite alloc] init];
		[self addChild:topImage z:PADDLE_TOP_IMAGE_Z];
	}

	CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:path];
	BOOL v = NO;
	
	if (texture) {
		CGSize s = [self contentSize];
		CGRect rect = CGRectZero;
		rect.size = texture.contentSize;
		[texture setAntiAliasTexParameters];
		[topImage setTexture:texture];
		[topImage setTextureRect:rect];
		
		if (w == 0) w = rect.size.width;
		else w = SCALE_X (w);
		if (h == 0) h = rect.size.height;
		else h = SCALE_Y (h);
		
		[topImage setScaleX:(1.0 / rect.size.width) * w];
		[topImage setScaleY:(1.0 / rect.size.height) * h];
		
		[topImage setRotation:r];
		
		[topImage setAnchorPoint:ccp (ax, ay)];
		
		if (x > 0 && x < 1) x = s.width * x;
		else x = SCALE_X(x);
		if (y > 0 && y < 1) y = s.height * y;
		else y = SCALE_Y(y);
		[topImage setPosition:ccp (x, y)];
		
		[topImage setOpacity:o];
		
		v = YES;
	} else {
		KKLOG (@"unknown image '%@'", path);
	}
	topImage.visible = v;
}

-(void) setupPaddleTopImage:(NSDictionary *)imageData
{
	if (!imageData) {
		if (topImage) topImage.visible = NO;
		return;	
	}
	
	if (!topImage) {
		topImage = [[CCSprite alloc] init];
		[self addChild:topImage z:PADDLE_TOP_IMAGE_Z];
	}
	
	NSString *textureName = DICT_STRING (imageData, @"textureName", @"");
	BOOL v = NO;
	
	if (textureName && ![textureName isEqualToString:@""]) {
		CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:[gameEngine pathForLevelGraphic:textureName]];
		if (texture) {
			CGSize s = [self contentSize];
			CGRect rect = CGRectZero;
			rect.size = texture.contentSize;
			[texture setAntiAliasTexParameters];
			[topImage setTexture:texture];
			[topImage setTextureRect:rect];
			
			float w = SCALE_X (DICT_FLOAT (imageData, @"width", 0));
			float h = SCALE_Y (DICT_FLOAT (imageData, @"height", 0));
			if (w == 0) w = rect.size.width;
			if (h == 0) h = rect.size.height;
			[topImage setScaleX:(1.0 / rect.size.width) * w];
			[topImage setScaleY:(1.0 / rect.size.height) * h];
			
			[topImage setRotation:DICT_FLOAT (imageData, @"rotation", 0)];
			
			[topImage setAnchorPoint:ccp (
									   DICT_FLOAT (imageData, @"anchorX", 0.5),
									   DICT_FLOAT (imageData, @"anchorY", 0.5)
									   )
			 ];
			
			float x = DICT_FLOAT (imageData, @"positionX", s.width/2);
			float y = DICT_FLOAT (imageData, @"positionY", s.height/2);
			if (x > 0 && x < 1) x = s.width * x;
			else x = SCALE_X(x);
			if (y > 0 && y < 1) y = s.height * y;
			else y = SCALE_Y(y);
			[topImage setPosition:ccp (x, y)];
			
			[topImage setOpacity:DICT_INT (imageData, @"opacity", 255)];
			
			v = YES;
		} else {
			KKLOG (@"unknown texture '%@'", textureName);
		}

	}
	topImage.visible = v;
}

-(void) setupPaddleLights:(NSArray *)lightsData
{
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
		
		int cw = (int) (size.width/level.lightGrid.cellWidth);
		int ch = (int) (size.height/level.lightGrid.cellHeight);
		light.position = CGPointMake (
									  cw * DICT_FLOAT (lData, @"positionX", 0.5), 
									  ch * DICT_FLOAT (lData, @"positionY", 0.5)
									  );
		
		int w = DICT_INT (lData, @"width", 0);
		int h = DICT_INT (lData, @"height", 0);
		if (w == 0) w = cw + 4;
		if (h == 0) h = ch + 4;
		light.size = SCALE_SIZE(CGSizeMake (w, h));
		light.power = DICT_FLOAT (lData, @"power", 0.0);

		lights[numLights] = light.lightID;
		
		numLights++;
		if (numLights >= PADDLE_MAX_LIGHTS) {
			KKLOG (@"too many lights %d (max is %d).", [lightsData count], PADDLE_MAX_LIGHTS);
			break;
		}
	}
}	

-(void) setupPaddleLabel:(NSDictionary *)labelData
{
	if (!labelData) return;

	NSString *s = DICT_STRING (labelData, @"text", @"");
	
	if (![s isEqualToString:@""]) {
		[self setLabelFont:DICT_STRING (labelData, @"font", PADDLE_DEFAULT_LABEL_FONT) 
					ofSize:DICT_INT (labelData, @"fontSize", PADDLE_DEFAULT_LABEL_FONT_SIZE)];
		
		[label setColor:ccc3FromNsString (DICT_STRING (labelData, @"color", PADDLE_DEFAULT_LABEL_COLOR))];
		[label setOpacity:DICT_INT (labelData, @"opacity", PADDLE_DEFAULT_LABEL_OPACITY)];
		[self setLabel:s];
		[label setVisible:YES];
	} else {
		[label setVisible:NO];
	}
}

#pragma mark -
#pragma mark Update

-(void) update:(ccTime)dt
{
}

-(BOOL) updatePositionWithSpeedAndAcceleration:(ccTime)dt
{
	if (speed.x == 0 && speed.y == 0 && acceleration.x == 0 && acceleration.y == 0)
		return NO;

	speed = ccpAdd (speed, acceleration);
	self.position = ccpAdd (self.position, ccpMult(speed, dt));

	float x = self.position.x;
	float y = self.position.y;
	
	BOOL autoMove = !((defensiveAIKind && [self isDefensiveSide]) || 
				(offensiveAIKind && [self isOffensiveSide]));
	
	// boundaries check
	// NOTE: min AND max position MUST NOT have 0 values to become active
	if (autoMove) {
		if (speed.x && (minPosition.x && maxPosition.x)) {
			float minx = minPosition.x;
			float maxx = maxPosition.x;
			if (x < minx) {
				x = minx;
				speed.x = ABS(speed.x);
			} else if (x > maxx) {
				x = maxx;
				speed.x = -ABS(speed.x);
			}
		}
		if (speed.y && (minPosition.y && maxPosition.y)) {
			float miny = minPosition.y;
			float maxy = maxPosition.y;

			if (y < miny) {
				y = miny;
				speed.y = ABS(speed.y);
			} else if (y > maxy) {
				y = maxy;
				speed.y = -ABS(speed.y);
			}
		}
	} else {
		BOOL f = NO;
		if (minPosition.x && maxPosition.x) {
			float minx = minPosition.x;
			float maxx = maxPosition.x;
			if (x < minx) {
				x = minx;
			} else if (x > maxx) {
				x = maxx;
			}
			f = YES;
		}
		if (minPosition.y && maxPosition.y) {
			float miny = minPosition.y;
			float maxy = maxPosition.y;
			
			if (y < miny) {
				y = miny;
			} else if (y > maxy) {
				y = maxy;
			}
			f = YES;
		}
		
		if (!f) {
			if (!(flags & kPaddleFlagNoPositionLimit)) {
				KKScreen *s = level.currentScreen;
				float minx = s.position.x;
				float miny = s.position.y;
				float maxx = minx + s.size.width - size.width;
				float maxy = miny + s.size.height - size.height;
				
				if (x < minx) x = minx;
				else if (x > maxx) x = maxx;
				
				if (y < miny) y = miny;
				else if (y > maxy) y = maxy;
			}
		}
	}
	
	self.position = ccp (x, y);
	
	BOOL moved = NO;
	CGPoint p = ccpSub(lastMovement, self.position);
	lastMovementTime += dt;
	if (lastMovementTime > audioMoveSoundTimeout && (ABS(p.x) > MOVE_DELTA || ABS(p.y) > MOVE_DELTA)) {
		lastMovement = self.position;
		lastMovementTime = 0;
		moved = YES;
		
		if (audioMoveSound)
			[gameEngine playSound:audioMoveSound forPaddle:self];
	}
	return moved;
}

#pragma mark -
#pragma mark Label

-(CCBitmapFontAtlas *) label
{
	return label;
}

-(void) setLabelFont:(NSString *)fontName ofSize:(int)fontSize
{
	NSString *f = [gameEngine pathForFont:fontName size:SCALE_FONT(fontSize)];
	if (labelFontFile == nil || ![labelFontFile isEqualToString:f]) {
		labelFontFile = [f retain];
		label = [[CCBitmapFontAtlas bitmapFontAtlasWithString:@"" fntFile:labelFontFile] retain];
		[label.texture setAliasTexParameters];
		[self addChild:label z:PADDLE_LABEL_Z];
		[self updateLabelPosition];
	}
}

-(void) destroyLabel
{
	if (labelFontFile) [labelFontFile release], labelFontFile = nil;
	if (label) [label release], label = nil;
}

-(void) updateLabelPosition
{
	[label setPosition:ccp (size.width/2, size.height/2)];
}

-(void) setLabel:(NSString *)str
{
	[label setString:NSLocalizedString(str, @"paddleLabel")];
	[self updateLabelPosition];
}

#pragma mark -
#pragma mark Collisions

-(int) checkCollisionWithRect:(CGRect)r speed:(CGPoint)s collisionPoint:(CGPoint *)collisionPoint dt:(ccTime)dt
{
	int collisionSides = kSideNone;
	
	if (self.enabled) {
		collisionSides = checkCollisionBetweenRects (r, s, bbox, speed, dt, collisionPoint);
		
		if (collisionSides != kSideNone) {
			if (self.isInvisible) {
				[self invisibleHit];
			}
		}
	}
	return collisionSides;
}

#pragma mark -
#pragma mark Proximity

-(BOOL) isHeroInsideProximityArea:(KKHero *)hero
{
//	if (proximityMode == kPaddleProximityNone) return NO;
//	if (CGSizeEqualToSize(proximityArea, CGSizeZero)) return NO;
	
	CGRect pBBox = CGRectMake (
							   self.position.x - proximityArea.width, 
							   self.position.y - proximityArea.height, 
							   size.width + proximityArea.width * 2, 
							   size.height + proximityArea.height * 2
							   );
	
	return CGRectIntersectsRect (hero.bbox, pBBox);
}

-(BOOL) isHeroAtIndexInsideProximityArea:(int)idx
{
	return [self isHeroInsideProximityArea:[level heroAtIndex:idx]];
}

#define PROXIMITY_FACTOR 80.0
-(void) applyProximityInfluenceToHero:(KKHero *)hero dt:(ccTime)dt
{
	if (proximityMode == kPaddleProximityRect) {
		int side = whereIsRectForRect (hero.bbox, bbox);
		float dist = ccpDistance (hero.position, self.position) / 10.0;
		CGPoint s = ccp (0, 0);
		
		if (side & kSideTop) s.y = 1;
		else if (side & kSideBottom) s.y = -1;

		if (side & kSideLeft) s.x = -1;
		else if (side & kSideRight) s.x = 1;

		if (dist < 1) dist = 1;
		
		if (flags & kPaddleFlagScriptApplyProximityInfluenceToHero) {
			paddleApplyProximityInfluenceToHero(index, hero.index, s, dist);
		} else {
			// standard proximity handler
			hero.acceleration = ccp (
									 hero.acceleration.x + ((proximityAcceleration.x * s.x * dt * PROXIMITY_FACTOR) / dist), 
									 hero.acceleration.y + ((proximityAcceleration.y * s.y * dt * PROXIMITY_FACTOR) / dist)
			);
		}
	}
}

#pragma mark -
#pragma mark Utilities

-(BOOL) isInScreen:(KKScreen *)screen
{
	BOOL r = NO;
	
	if (screen) {
		r = CGRectContainsRect ([screen bbox], bbox);
	}
	return r;
}

-(void) toggleSide
{
	if (flags & kPaddleFlagOffensiveSide) flags ^= kPaddleFlagOffensiveSide;
	else flags |= kPaddleFlagOffensiveSide;
	
	if (flags & kPaddleFlagScriptOnSideToggled)
		paddleOnSideToggled(index, [self isDefensiveSide]);
}

-(KKLight *) light:(int)idx
{
	return [level.lightGrid  lightWithID:lights[idx]];
}

#pragma mark -
#pragma mark Touches

-(BOOL) containsPoint:(CGPoint)p
{
	return CGRectContainsPoint (bbox, p);
}

-(BOOL) handleTouchType:(int)touchType position:(CGPoint)pos tapCunt:(int)tapCount
{
	BOOL touchHandled = (flags & kPaddleFlagBlockTouches || flags & kPaddleFlagIsButton ? YES : NO);
	
	if (flags & kPaddleFlagScriptHandleTouches) {
		//		KKLOG (@"[%d] %@ (%d) %d", touchHandled, NSStringFromCGPoint(pos), touchType, tapCount);
		char *handler = "";
		switch (touchType) {
			case ccTouchBegan:
				handler = "onTouchBegan";
				break;
			case ccTouchMoved:
				handler = "onTouchMoved";
				break;
			case ccTouchEnded:
			case ccTouchCancelled:
				handler = "onTouchEnded";
				break;
		}
		paddleTouchHandler(index, handler, pos, tapCount);
	}
	return touchHandled;
}

#define SHAKE_SPEED 0.02
#define X1 10
#define Y1 0
#define X2 10
#define Y2 0
#define NUM_SHAKES 5

-(void) resetPaddleRuntimeFlagClickFX
{
	runtimeFlags ^= kPaddleRuntimeFlagClickFX;
}

-(void) onClickCallback
{
	paddleOnClick(index);
}

-(void) applyClickedEffects
{
	if (flags & kPaddleFlagIsButton) {
		if (runtimeFlags & kPaddleRuntimeFlagClickFX) return;
		runtimeFlags |= kPaddleRuntimeFlagClickFX;
		
		CCMoveBy *ar0 = [CCMoveBy actionWithDuration:SHAKE_SPEED position:ccp (X1, Y1)];
		CCMoveBy *ar = [CCMoveBy actionWithDuration:SHAKE_SPEED position:ccp (X2, Y2)];
		CCMoveBy *al = [CCMoveBy actionWithDuration:SHAKE_SPEED position:ccp (-X2, -Y2)];
		CCMoveBy *al0 = [CCMoveBy actionWithDuration:SHAKE_SPEED position:ccp (-X1, -Y1)];
		CCSequence *as = [CCSequence actions:al, ar, nil];
		CCCallFunc *r = [CCCallFunc actionWithTarget:self selector:@selector(resetPaddleRuntimeFlagClickFX)];
		CCCallFunc *c = [CCCallFunc actionWithTarget:self selector:@selector(onClickCallback)];
		CCSequence *a = [CCSequence actions:ar0, [CCRepeat actionWithAction:as times:NUM_SHAKES], al0, r, c, nil];
		a.tag = kPaddleActionClickedFX;
		
		[self runAction:a];
	}
}

-(void) clicked
{
	[gameEngine playSound:[self audioClickSound] forPaddle:self];
	
	[self applyClickedEffects];
}

#pragma mark -
#pragma mark Messages

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn sound:(NSString *)sound
{
	msgIdx = [self showMessage:msg emoticon:icn bgColor:msgBGColor msgColor:msgColor icnColor:msgIcnColor fontSize:msgFontSize duration:HUD_MESSAGE_SHOW_DURATION sound:sound];
	return msgIdx;
}

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn duration:(float)seconds sound:(NSString *)sound
{
	msgIdx = [self showMessage:msg emoticon:icn bgColor:msgBGColor msgColor:msgColor icnColor:msgIcnColor fontSize:msgFontSize duration:seconds sound:sound];
	return msgIdx;
}

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn bgColor:(ccColor3B)bgc msgColor:(ccColor3B)msgc icnColor:(ccColor3B)icnc fontSize:(CGFloat)pointSize duration:(float)seconds sound:(NSString *)sound
{
	msgIdx = [gameEngine.hud showMessage:msg emoticon:icn entity:self bgColor:bgc msgColor:msgc icnColor:icnc fontSize:pointSize duration:seconds];
	[gameEngine playSound:sound];
	
	return msgIdx;
}

-(void) removeMessage
{
	if (msgIdx != -1)
		[gameEngine.hud removeMessageWithIndex:msgIdx];
}

@end
