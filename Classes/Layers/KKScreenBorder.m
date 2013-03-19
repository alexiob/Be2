//
//  KKScreenBorder.m
//  be2
//
//  Created by Alessandro Iob on 18/3/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "KKScreenBorder.h"
#import "KKMacros.h"
#import "KKGraphicsManager.h"
#import "KKColorUtilities.h"

@implementation KKScreenBorder

@synthesize active;

-(id) initWithSide:(tScreenBorderSide)aSide size:(float)aSize color:(ccColor3B)c opacity:(int)o
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	float w = ws.width;
	float h = ws.height;
	
	if (aSide == kScreenBorderSideTop || aSide == kScreenBorderSideBottom) {
		h = SCALE_Y(aSize);
	} else if (aSide == kScreenBorderSideLeft || aSide == kScreenBorderSideRight) {
		w = SCALE_X(aSize);
	}
	
	self = [super initWithColor:ccc4(c.r, c.g, c.b, o)
						  width:w	
						 height:h
			];
	if (self) {
		active = YES;
		side = aSide;
		
		switch (side) {
			case kScreenBorderSideTop:
				homePosition = ccp (0, ws.height - h);
				break;
			case kScreenBorderSideBottom:
				homePosition = ccp (0, 0);
				break;
			case kScreenBorderSideLeft:
				homePosition = ccp (0, 0);
				break;
			case kScreenBorderSideRight:
				homePosition = ccp (ws.width - w, 0);
				break;
			default:
				break;
		}
		[self setAnchorPoint:ccp(0,0)];
		self.position = homePosition;
	}
	return self;
}

-(void) dealloc
{
	[super dealloc];
}

-(void) setActive:(BOOL)f withDuration:(float)duration
{
	BOOL a = f != 0;
	if (active == a) return;
	active = a;
	[self stopActionByTag:kScreenBorderActionFadeTo];
	CCAction *action = [CCFadeTo actionWithDuration:duration opacity:(f ? 255 : 0)];
	action.tag = kScreenBorderActionFadeTo;
	[self runAction:action];
}

-(void) setColor:(ccColor3B)c withDuration:(float)duration
{
	if (c.g == 1 && c.b == 1) {
		[self setOpacity:c.r];
		return;
	}
	
	if (ccc3IsEqual (self.color, c)) return;
	
	[self stopActionByTag:kScreenBorderActionTintTo];
	CCAction *action = [CCTintTo actionWithDuration:duration red:c.r green:c.g blue:c.b];
	action.tag = kScreenBorderActionTintTo;
	[self runAction:action];
}

-(void) setSize:(float)aSize
{
	CGSize ws = [[CCDirector sharedDirector] winSize];
	
	if (side == kScreenBorderSideTop || side == kScreenBorderSideBottom) {
		[self setContentSize:CGSizeMake ([self contentSize].width, aSize)];
		if (side == kScreenBorderSideTop) {
			homePosition = ccp (0, ws.height - aSize);
			self.position = homePosition;
		}
	} else if (side == kScreenBorderSideLeft || side == kScreenBorderSideRight) {
		[self setContentSize:CGSizeMake (aSize, [self contentSize].height)];
		if (side == kScreenBorderSideRight) {
			homePosition = ccp (ws.width - aSize, 0);
			self.position = homePosition;
		}
	}
}

@end
