//
//  KKGamePath.h
//  be2
//
//  Created by Alessandro Iob on 28/7/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RESOURCES_FOLDER @"ResourcesApp"
#define RESOURCES_PATH_GRAPHICS @"ResourcesApp/graphics"
#define RESOURCES_PATH_FONTS @"ResourcesApp/graphics/fonts"
#define RESOURCES_PATH_AUDIO @"ResourcesApp/audio"
#define RESOURCES_PATH_MUSICS @"ResourcesApp/audio/musics"
#define RESOURCES_PATH_SOUNDS @"ResourcesApp/audio/sounds"
#define RESOURCES_PATH_SCRIPTS @"ResourcesApp/scripts"
#define RESOURCES_PATH_DATA @"ResourcesApp/data"

#define RESOURCES_PATH_SCRIPTS_BIN @"ResourcesApp/data/objects.bin"

#define LEVELS_FOLDER @"ResourcesApp/data/levels"
#define LEVELS_INFO @"levelsInfo.plist"

#define LEVEL_PATH_GRAPHICS @"graphics"
#define LEVEL_PATH_FONTS @"graphics/fonts"
#define LEVEL_PATH_AUDIO @"audio"
#define LEVEL_PATH_MUSICS @"audio/musics"
#define LEVEL_PATH_SOUNDS @"audio/sounds"
#define LEVEL_PATH_SCRIPTS @"scripts"

#define LEVEL_PLIST @"level.plist"
#define DEFAULT_SCREEN_MESSAGES_PLIST @"defaultScreenMessages.plist"
#define LEVEL_SCREEN_MESSAGES_PLIST @"screenMessages.plist"

@interface KKGamePath : NSObject {

}

#pragma mark -
#pragma mark Paths

+(NSString *) getDocumentsResourcesFolder:(NSString *)rFolder forLevel:(NSString*)lName;
+(NSString *) getResourcesFolder:(NSString *)rFolder forLevel:(NSString *)lName;

+(NSString *) pathForGraphic:(NSString *)str;
+(NSString *) pathForTTFFont:(NSString *)str;
+(NSString *) pathForFont:(NSString *)str size:(int)s;
+(NSString *) pathForSound:(NSString *)str;
+(NSString *) pathForMusic:(NSString *)str;
+(NSString *) pathForScript:(NSString *)str;
+(NSString *) pathForData:(NSString *)str;

+(NSString *) pathForLevelDefinition:(NSString *)str;

+(NSString *) pathForLevel:(NSString *)str inLevel:(NSString *)levelName;
+(NSString *) pathForLevelFont:(NSString *)str size:(int)s inLevel:(NSString *)levelName;
+(NSString *) pathForLevelGraphic:(NSString *)str inLevel:(NSString *)levelName;
+(NSString *) pathForLevelSound:(NSString *)str inLevel:(NSString *)levelName;
+(NSString *) pathForLevelMusic:(NSString *)str inLevel:(NSString *)levelName;
+(NSString *) pathForLevelScript:(NSString *)str inLevel:(NSString *)levelName;

@end
