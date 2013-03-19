//
//  KKEntitiesCommon.h
//  be2
//
//  Created by Alessandro Iob on 2/11/10.
//  Copyright 2010 Kismik. All rights reserved.
//

typedef enum {
	kEntityColorModeSolid = 0,
	kEntityColorModeTintTo,
	kEntityOpacityModeSolid,
	kEntityOpacityModeFadeTo,
} tEntityColorMode;

@class KKLevel;

CGPoint limitSpeed (CGPoint speed, KKLevel *level);
