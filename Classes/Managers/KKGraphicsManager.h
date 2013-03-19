//
//  GraphicsManager.h
//  Be2
//
//  Created by Alessandro Iob on 6/30/09.
//  Copyright 2009 Kismik. All rights reserved.
//

#import "cocos2d.h"
#import "CGPointExtension.h"

typedef enum {
//	kGraphicGroupInGame,
//	kGraphicGroupLogos,
//	kGraphicGroupWeather,
	kNumberOfGraphicGroups
} tGraphicGroupEnum;

#define KKGM [KKGraphicsManager sharedKKGraphicsManager]

#ifdef KK_IPAD_SUPPORT

#define SCALE_POINT(__P__) ccpCompMult(__P__, deviceScale)
#define SCALE_SIZE(__S__) CGSizeMake(__S__.width * deviceScale.x, __S__.height * deviceScale.y)
#define SCALE_X(__F__) (__F__ * deviceScale.x)
#define SCALE_Y(__F__) (__F__ * deviceScale.y)

#define SCALE_FONT(__F__) [KKGM scaleFont:__F__]

#define NORM_POINT(__P__) ccp(NORM_X(__P__.x), NORM_Y(__P__.y))
#define NORM_SIZE(__P__) CGSizeMake(NORM_X(__P__.width), NORM_Y(__P__.height))
#define NORM_X(__F__) (__F__ / deviceScale.x)
#define NORM_Y(__F__) (__F__ / deviceScale.y)

#else

#define SCALE_POINT(__P__) __P__
#define SCALE_SIZE(__S__) __S__
#define SCALE_X(__F__) __F__
#define SCALE_Y(__F__) __F__

#define SCALE_FONT(__F__) [KKGM scaleFont:__F__]

#define NORM_POINT(__P__) __P__
#define NORM_SIZE(__P__) __P__
#define NORM_X(__F__) __F__
#define NORM_Y(__F__) __F__

#endif

#define FONT_MAX_SIZE 128

#define VIRTUAL_WIDTH 480
#define VIRTUAL_HEIGHT 320

CGPoint deviceScale;

@interface KKGraphicsManager : NSObject {
	CCSpriteSheet *atlasSpriteManagers[kNumberOfGraphicGroups];
	NSDictionary *atlasSpritePLists[kNumberOfGraphicGroups];
}

+(KKGraphicsManager *) sharedKKGraphicsManager;
+(void) purgeSharedKKGraphicsManager;

-(CCSpriteSheet *) getAtlasSpriteManager:(int)group;

-(BOOL) isValidGroup:(int)group;
-(BOOL) isGroupLoaded:(int)group;
-(BOOL) loadGroup:(int)group;
-(void) releaseGroup:(int)group;

-(CGRect) getSpriteRectFromGroup:(int)group filename:(NSString *)filename;
-(CCSprite *) spriteFromGroup:(int)group filename:(NSString *)filename;

-(int) scaleFont:(int)fontSize;

-(void) playVideo:(NSString *)path;

@end
