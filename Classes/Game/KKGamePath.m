//
//  KKGamePath.m
//  be2
//
//  Created by Alessandro Iob on 28/7/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKGamePath.h"

#import "CCFileUtils.h"

@implementation KKGamePath

#pragma mark -
#pragma mark Paths

+(NSString *) getDocumentsResourcesFolder:(NSString *)rFolder forLevel:(NSString*)lName
{
	NSString *docs = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	return [NSString stringWithFormat:@"%@/%@/%@", docs, rFolder, lName];
}

+(NSString *) getResourcesFolder:(NSString *)rFolder forLevel:(NSString *)lName
{
	NSString *path;
	
#ifdef KK_DEBUG	
	// if exists level folder in Documents use it else
	NSFileManager *fileManager = [NSFileManager defaultManager];
	path = [self getDocumentsResourcesFolder:rFolder forLevel:lName];
	if (![fileManager fileExistsAtPath:path])
#endif
		path = [NSString stringWithFormat:@"%@/%@", rFolder, lName];
	return path;
}

// global paths

+(NSString *) pathForGraphic:(NSString *)str
{
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", RESOURCES_PATH_GRAPHICS, str]];
}

+(NSString *) pathForTTFFont:(NSString *)str
{
	return str;
}

+(NSString *) pathForFont:(NSString *)str size:(int)s
{
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@-%d.fnt", RESOURCES_PATH_FONTS, str, s]];
}

+(NSString *) pathForSound:(NSString *)str
{
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", RESOURCES_PATH_SOUNDS, str]];
}

+(NSString *) pathForMusic:(NSString *)str
{
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", RESOURCES_PATH_MUSICS, str]];
}

+(NSString *) pathForScript:(NSString *)str
{
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", RESOURCES_PATH_SCRIPTS, str]];
}

+(NSString *) pathForLevelDefinition:(NSString *)str
{
	NSString *folder = [self getResourcesFolder:LEVELS_FOLDER forLevel:str];
	
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", folder, LEVEL_PLIST]];
}

+(NSString *) pathForData:(NSString *)str
{
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", RESOURCES_PATH_DATA, str]];
}

// level paths

+(NSString *) pathForLevel:(NSString *)str inLevel:(NSString *)levelName
{
	NSString *folder = [self getResourcesFolder:LEVELS_FOLDER forLevel:levelName];
	return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@", folder, str]];
}

+(NSString *) pathForLevelGraphic:(NSString *)str inLevel:(NSString *)levelName
{
	if ([str isAbsolutePath]) {
		return [self pathForGraphic:str];
	} else {
		NSString *folder = [self getResourcesFolder:LEVELS_FOLDER forLevel:levelName];
		return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@/%@", folder, LEVEL_PATH_GRAPHICS, str]];
	}
}

+(NSString *) pathForLevelFont:(NSString *)str size:(int)s inLevel:(NSString *)levelName
{
	if ([str isAbsolutePath]) {
		return [self pathForFont:str size:s];
	} else {
		NSString *folder = [self getResourcesFolder:LEVELS_FOLDER forLevel:levelName];
		return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@/%@-%d.fnt", folder, LEVEL_PATH_FONTS, str, s]];
	}
}

+(NSString *) pathForLevelSound:(NSString *)str inLevel:(NSString *)levelName
{
	if ([str isAbsolutePath]) {
		return [self pathForSound:str];
	} else {
		NSString *folder = [self getResourcesFolder:LEVELS_FOLDER forLevel:levelName];
		return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@/%@", folder, LEVEL_PATH_SOUNDS, str]];
	}
}

+(NSString *) pathForLevelMusic:(NSString *)str inLevel:(NSString *)levelName
{
	if ([str isAbsolutePath]) {
		return [self pathForMusic:str];
	} else {
		NSString *folder = [self getResourcesFolder:LEVELS_FOLDER forLevel:levelName];
		return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@/%@", folder, LEVEL_PATH_MUSICS, str]];
	}
}

+(NSString *) pathForLevelScript:(NSString *)str inLevel:(NSString *)levelName
{
	if ([str isAbsolutePath]) {
		return [self pathForScript:str];
	} else {
		NSString *folder = [self getResourcesFolder:LEVELS_FOLDER forLevel:levelName];
		return [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"%@/%@/%@", folder, LEVEL_PATH_SCRIPTS, str]];
	}
}


@end
