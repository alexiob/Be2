//
//  KKHero.m
//  be2
//
//  Created by Alessandro Iob on 2/10/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKHero.h"
#import "KKMacros.h"
#import "KKLevel.h"
#import "CGPointExtension.h"
#import "KKGraphicsManager.h"
#import "KKGameEngine.h"
#import "KKHUDLayer.h"

@implementation KKHero

@synthesize index, kind, flags;
@synthesize size, acceleration, speed, bbox;
@synthesize elasticity;
@synthesize data;

-(id) initWithLevel:(KKLevel *)aLevel
{
	self = [super init];
	if (self) {
		gameEngine = KKGE;
		level = aLevel;
		index = 0;
		kind = kHeroKindDefault;
		flags = 0;
		
		acceleration = ccp (0, 0);
		speed = ccp (0, 0);
		size = SCALE_SIZE(HERO_DEFAULT_SIZE);
		sizeOrig = size;
		
		elasticity = 1.0;
		
		msgIdx = -1;
		msgBGColor = self.color;
		msgColor = HUD_MESSAGE_COLOR;
		msgIcnColor = HUD_MESSAGE_EMOTICON_COLOR;
		msgFontSize = HUD_MESSAGE_FONT_SIZE;
		
		data = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
		
		[self setupLight];
		
		[self setOpacityModifyRGB:NO];
		[self setAnchorPoint:ccp (0, 0)];
		
		[self updateHeroTexture:nil];
		
		[self updateBBox];
	}
	return self;
}

-(void) dealloc
{
	[data release];
	
	[super dealloc];
}

-(void) setupLight
{
	if (lightID != 0) {
		[level.lightGrid removeLightWithID:lightID];
		lightID = 0;
	}
	
	KKLight *light = [level.lightGrid addLightWithID:(int)self kind:kLightKindRect];
	light.enabled = NO;
	light.visible = YES;
	light.flags |= kLightFlagBindToEntity;
	light.opacity = 0;
	light.entity = self;
	light.size = CGSizeMake (7, 7);
	light.power = 0.0;
	lightID = light.lightID;
}

#pragma mark -
#pragma mark Properties

-(void) setLightEnabled:(BOOL)f
{
	if (lightID) self.light.enabled = f;
}

-(BOOL) lightEnabled
{
	if (lightID) return self.light.enabled;
	else return NO;
}

-(void) setLightVisible:(BOOL)f
{
	if (lightID) self.light.visible = f;
}

-(BOOL) lightVisible
{
	if (lightID) return self.light.visible;
	else return NO;
}

-(KKLight *) light
{
	if (lightID) return [level.lightGrid lightWithID:lightID];
	else return nil;
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
	sizeOrig = s;
	[self updateBBox];
}

-(void) setScale:(float)s
{
	size = CGSizeMake(sizeOrig.width * s, sizeOrig.height * s);
	[self updateBBox];
	[super setScale:s];
}

-(void) setScaleX:(float)s
{
	size = CGSizeMake(sizeOrig.width * s, size.height);
	[self updateBBox];
	[super setScaleX:s];
}

-(void) setScaleY:(float)s
{
	size = CGSizeMake(size.width, sizeOrig.height * s);
	[self updateBBox];
	[super setScaleY:s];
}

-(CGPoint) center
{
	return ccp(self.position.x + size.width/2, self.position.y + size.height/2);
}

-(BOOL) isMainHero
{
	return flags & kHeroFlagIsMain;
}

-(CGPoint) positionToDisplay
{
	return ccp (self.position.x - level.currentScreen.position.x, self.position.x - level.currentScreen.position.x);
}

-(CGPoint) centerPositionToDisplay
{
	return ccp (self.position.x - level.currentScreen.position.x + size.width/2, self.position.y - level.currentScreen.position.y + size.height/2);
}

-(void) setSpeed:(CGPoint)s
{
	speed = limitSpeed (s, level);
}

#pragma mark -
#pragma mark FX

-(void) setScaleIncrement:(CGSize)inc duration:(ccTime)d
{
	CCAction *action = [CCScaleTo actionWithDuration:d scaleX:inc.width scaleY:inc.height];
	action.tag = kHeroActionScaleTo;
	[self stopActionByTag:kHeroActionScaleTo];
	[self runAction:action];
}

-(void) resetScaleIncrement:(ccTime)d
{
	if (d) {
		CCAction *action = [CCScaleTo actionWithDuration:d scaleX:1.0 scaleY:1.0];
		action.tag = kHeroActionScaleTo;
		[self stopActionByTag:kHeroActionScaleTo];
		[self runAction:action];
	} else {
		self.scaleX = 1.0;
		self.scaleY = 1.0;
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

#pragma mark -
#pragma mark Update

-(void) updateHeroTexture:(NSString *)textureName
{
	if (!textureName || [textureName isEqualToString:@""]) {
		[self setTexture:nil];
		[self setTextureRect:CGRectMake(0, 0, size.width, size.height)];
	} else {
		CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:textureName];
		if (texture) {
			CGRect rect = CGRectZero;
			rect.size = texture.contentSize;
	//		[texture setAntiAliasTexParameters];
			[self setTexture:texture];
			[self setTextureRect:rect];
	//		CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:textureName];
	//		[self setTexture:frame.texture];
	//		[self setTextureRect:frame.rect];
	//		[self setDisplayFrame:frame];
		
	//		[self setScaleX:(1.0 / rect.size.width) * size.width];
	//		[self setScaleY:(1.0 / rect.size.height) * size.height];
		}
	}
}

-(void) updateHeroColorMode:(int)colorMode color1:(ccColor3B)color1 color2:(ccColor3B)color2 tintToDuration:(float)tintToDuration
{
	[self stopActionByTag:kHeroActionColorTintTo];
	
	switch (colorMode) {
		case kEntityColorModeTintTo:
			[self setColor:color1];
			CCAction *action = [CCRepeatForever actionWithAction:[CCSequence actions:
																  [CCTintTo actionWithDuration:tintToDuration red:color2.r green:color2.g blue:color2.b],
																  [CCTintTo actionWithDuration:tintToDuration red:color1.r green:color1.g blue:color1.b],
																  nil
																  ]
								];
			action.tag = kHeroActionColorTintTo;
			[self runAction:action];
			break;
		case kEntityColorModeSolid:
		default:
			[self setColor:color1];
			break;
	}
	
	msgBGColor = color1;
}

-(void) updateHeroColorModeSolid:(ccColor3B)color
{
	[self updateHeroColorMode:kEntityColorModeSolid color1:color color2:ccc3(0,0,0) tintToDuration:0];
}

-(void) updateHeroOpacityMode:(int)opacityMode opacity1:(GLubyte)opacity1 opacity2:(GLubyte)opacity2 opacityFadeDuration:(GLubyte)opacityFadeDuration
{
	[self stopActionByTag:kHeroActionOpacityFadeTo];
	
	switch (opacityMode) {
		case kEntityOpacityModeFadeTo:
			[self setOpacity:opacity1];
			CCAction *action = [CCRepeatForever actionWithAction:[CCSequence actions:
																  [CCFadeTo actionWithDuration:opacityFadeDuration opacity:opacity2],
																  [CCFadeTo actionWithDuration:opacityFadeDuration opacity:opacity2],
																  nil
																  ]
								];
			action.tag = kHeroActionOpacityFadeTo;
			[self runAction:action];
			break;
		case kEntityOpacityModeSolid:
		default:
			[self setOpacity:opacity1];
			break;
	}
}

-(void) updateSpeed:(ccTime)dt
{
	if (!(flags & kHeroFlagDontUpdateMovement)) {
		speed = limitSpeed (ccpAdd (speed, acceleration), level);
	}
}

-(void) updatePosition:(ccTime)dt
{
	if (!(flags & kHeroFlagDontUpdateMovement)) {
		self.position = ccp ((self.position.x + speed.x * dt), (self.position.y + speed.y * dt));
	}
}

-(void) update:(ccTime)dt
{
}

-(void) pause:(BOOL)f
{
	if (f && ![self isPaused]) {
		[gameEngine.hud showPauseButton:NO];
		flags |= kHeroFlagDontUpdateMovement;
	} else if (!f && [self isPaused]) {
		[gameEngine.hud showPauseButton:YES];
		flags ^= kHeroFlagDontUpdateMovement;
	}
}

-(BOOL) isPaused
{
	return flags & kHeroFlagDontUpdateMovement;
}

#pragma mark -
#pragma mark Messages

-(int) showMessage:(NSString *)msg emoticon:(tEmoticon)icn sound:(NSString *)sound
{
	msgIdx = [self showMessage:msg emoticon:icn bgColor:msgBGColor msgColor:msgColor icnColor:msgIcnColor fontSize:msgFontSize duration:HUD_MESSAGE_INFINITE_DURATION sound:sound];
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
