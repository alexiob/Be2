from Be2Definitions import *

tColor = 1

D = 0
def DI ():
	global D
	D += 1
	return D

#------------------------------------------------------------------------------

def newLevelConfig (**kargs):
	config = {
		'kind': 0,
	    
		'kLevelFlagLevelUpdate': True,
		'kLevelFlagScriptUpdate': False,
		'kLevelFlagShowHUD': True,
	    'kLevelFlagDoNotStartBackgroundMusic': False,
	    
	    'index': 0,
		'name': '',
		'title': '',
		'description': '',
		'leaderboard': '',
		'leaderboardFree': '',
	    'nextLevelName': '',
		
		'difficulty': 0,
		'availableTime': 0,
		'minimumScore': 0,
		'firstScreen': 'firstScreen',
	    
		'joystickAccelerationFactor': 0.8,
		
		'minSpeedX': 2,
		'minSpeedY': 2,
		'maxSpeedX': 200,
		'maxSpeedY': 200,
	    
		'accelerationInputX': DEFAULT_ACCELERATION_INPUT_X,
		'accelerationInputY': DEFAULT_ACCELERATION_INPUT_Y,
		'accelerationViscosityX': DEFAULT_ACCELERATION_VISCOSITY_X,
		'accelerationViscosityY': DEFAULT_ACCELERATION_VISCOSITY_Y,
		'accelerationFactorX': DEFAULT_ACCELERATION_FACTOR_X,
		'accelerationFactorY': DEFAULT_ACCELERATION_FACTOR_Y,
		'accelerationMinX': DEFAULT_ACCELERATION_MIN_X,
		'accelerationMinY': DEFAULT_ACCELERATION_MIN_Y,
		'accelerationMaxX': DEFAULT_ACCELERATION_MAX_X,
		'accelerationMaxY': DEFAULT_ACCELERATION_MAX_Y,
	    
		'gravityX': 0,
		'gravityY': 0,
		'friction': 0,
		
	    'screenShowDuration': 0.2,
	
	    'borderSideTopColor': DEFAULT_SCREEN_BORDER_COLOR,
	    'borderSideBottomColor': DEFAULT_SCREEN_BORDER_COLOR,
	    'borderSideLeftColor': DEFAULT_SCREEN_BORDER_COLOR,
	    'borderSideRightColor': DEFAULT_SCREEN_BORDER_COLOR,
	
	    'lightGridOpacity': 0,
	    'lightGridOpacityDuration': 0.3,
	    
	    'heroWidth': HERO_DEFAULT_WIDTH,
	    'heroHeight': HERO_DEFAULT_HEIGHT,
	    'heroStartColor': "255,255,255",
	    'heroStartPositionX': 50,
	    'heroStartPositionY': DEFAULT_SCREEN_HEIGHT/2 - HERO_DEFAULT_HEIGHT/2,
	    'heroStartAccelerationX': 0,
	    'heroStartAccelerationY': 0,
	    'heroStartSpeedX': 100,
	    'heroStartSpeedY': 0,
	    'heroStartLightEnabled': 0,

	    'turboSecondsAvailable': 0,
	    'turboFactor': 0,
	    
		'audioBackgroundMusic': '',
	    'audioInSound': '',
	    'audioOutSound': '',
	    'audioSideTopSound': '',
	    'audioSideBottomSound': '',
	    'audioSideLeftSound': '',
	    'audioSideRightSound': '',
	    
	    'scorePerSecondLeft': SCORE_PER_SECOND_LEFT,
	    'explorationPoints': 0,
	
		'paddles': [],
		'screens': [
		    newScreenConfig (0, 0, DEFAULT_SCREEN_WIDTH, DEFAULT_SCREEN_HEIGHT, name='firstScreen'),
	        ],
		'scripts': '',
		'extensions': '',
	}
	config.update (kargs)

	return config

D = 0
LEVEL_PROPERTIES_TYPES = {
    'name': (str, DI()),
    'index': (str, DI()),
    'title': (str, DI()),
    'description': (str, DI()),
    'leaderboard': (str, DI()),
    'leaderboardFree': (str, DI()),
    'kind' : (int, DI()),
    'nextLevelName': (str, DI()),
    
    'kLevelFlagLevelUpdate': (bool, DI()),
    'kLevelFlagScriptUpdate': (bool, DI()),
    'kLevelFlagShowHUD': (bool, DI()),
    'kLevelFlagDoNotStartBackgroundMusic': (bool, DI()),
  
    'difficulty': (int, DI()),
    'availableTime': (float, DI()),
    'minimumScore': (int, DI()),
    'firstScreen': (str, DI()),
  
    'scorePerSecondLeft': (int, DI()),
	'explorationPoints': (int, DI()),

	'joystickAccelerationFactor': (float, DI()),
	
    'minSpeedX': (float, DI()),
    'minSpeedY': (float, DI()),
    'maxSpeedX': (float, DI()),
    'maxSpeedY': (float, DI()),
    
    'accelerationInputX': (bool, DI()),
    'accelerationInputY': (bool, DI()),
    'accelerationViscosityX': (float, DI()),
    'accelerationViscosityY': (float, DI()),
    'accelerationFactorX': (float, DI()),
    'accelerationFactorY': (float, DI()),
    'accelerationMinX': (float, DI()),
    'accelerationMinY': (float, DI()),
    'accelerationMaxX': (float, DI()),
    'accelerationMaxY': (float, DI()),
    
	'gravityX': (float, DI()),
	'gravityY': (float, DI()),
	'friction': (float, DI()),
	
    'screenShowDuration': (float, DI()),
    'borderSideTopColor': (tColor, DI()),
    'borderSideBottomColor': (tColor, DI()),
    'borderSideLeftColor': (tColor, DI()),
    'borderSideRightColor': (tColor, DI()),
    
    'lightGridOpacity': (int, DI()),
    'lightGridOpacityDuration': (float, DI()),

    'heroWidth': (float, DI()),
    'heroHeight': (float, DI()),
    'heroStartColor': (tColor, DI()),
    'heroStartPositionX': (float, DI()),
    'heroStartPositionY': (float, DI()),
    'heroStartAccelerationX': (float, DI()),
    'heroStartAccelerationY': (float, DI()),
    'heroStartSpeedX': (float, DI()),
    'heroStartSpeedY': (float, DI()),
    'heroStartLightEnabled': (bool, DI()),

    'turboSecondsAvailable': (float, DI()),
    'turboFactor': (float, DI()),

    'audioBackgroundMusic': (str, DI()),
    'audioInSound': (str, DI()),
    'audioOutSound': (str, DI()),
    'audioSideTopSound': (str, DI()),
    'audioSideBottomSound': (str, DI()),
    'audioSideLeftSound': (str, DI()),
    'audioSideRightSound': (str, DI()),

    'paddles': None,
    'screens': None,
    'scripts': None,
    'extensions': None,
}

#------------------------------------------------------------------------------

SCREEN_UPDATE_FIELDS = (
    'kScreenFlagLeftSideClosed',
    'kScreenFlagRightSideClosed',
    'kScreenFlagTopSideClosed',
    'kScreenFlagBottomSideClosed',
    'name',
    'title',
    'description',
    'positionX',
    'positionY',
    'width',
    'height',
    'borderSizeTop',
    'borderSizeBottom',
    'borderSizeLeft',
    'borderSizeRight',
    'borderSideTopColor',
    'borderSideBottomColor',
    'borderSideLeftColor',
    'borderSideRightColor',
    'colorMode',
    'colorOpacity',
    'colorColor1',
)

def newScreenConfig (x, y, width, height, **kargs):
	config = {
		'kind': 0,

	    'kScreenFlagLeftSideClosed': False,
		'kScreenFlagRightSideClosed': False,
		'kScreenFlagTopSideClosed': False,
		'kScreenFlagBottomSideClosed': False,
	    'kScreenFlagScriptUpdate': False,
	    'kScreenFlagScriptOnEnter': False,
	    'kScreenFlagScriptOnExit': False,
	    
		'name': '',
		'title': 'New Screen',
		'titleColor': DEFAULT_SCREEN_TITLE_COLOR,
		'description': 'This is a new screen',
	    'descriptionColor': DEFAULT_SCREEN_DESCRIPTION_COLOR,
		'messageColor': DEFAULT_SCREEN_MESSAGE_COLOR,
		'messageOpacity': DEFAULT_SCREEN_MESSAGE_OPACITY,
	    'messageEnabled': 0,
	    
		'difficulty': 0,
	    
		'positionX': x,
		'positionY': y,
		'width': width,
		'height': height,
	    
	    'scorePerBorderHit': SCORE_PER_BORDER_HIT,
	    
		'minSpeedX': 0,
		'minSpeedY': 0,
		'maxSpeedX': 0,
		'maxSpeedY': 0,
	    
		'accelerationInputX': 0,
		'accelerationInputY': 0,
		'accelerationViscosityX': 0,
		'accelerationViscosityY': 0,
		'accelerationFactorX': 0,
		'accelerationFactorY': 0,
		'accelerationMinX': 0,
		'accelerationMinY': 0,
		'accelerationMaxX': 0,
		'accelerationMaxY': 0,
	    
		'gravityX': 0,
		'gravityY': 0,
		'friction': 0,
		
		'availableTime': 0,
	    
		'borderSizeTop': DEFAULT_BORDER_SIZE,
		'borderSizeBottom': DEFAULT_BORDER_SIZE,
		'borderSizeLeft': DEFAULT_BORDER_SIZE,
		'borderSizeRight': DEFAULT_BORDER_SIZE,

	    'borderSideTopColor': "",
	    'borderSideBottomColor': "",
	    'borderSideLeftColor': "",
	    'borderSideRightColor': "",
	    
		'colorMode': 0,
		'colorOpacity': 255,
		'colorColor1': '0,100,0',
		'colorColor2': '0,0,0',
		'colorTintToDuration': 0,
	    
	    'lightGridOpacity': -1,
	    'lightGridOpacityDuration': 0.3,
	    
		'audioBackgroundMusic': '',
	    'audioInSound': '',
	    'audioOutSound': '',
	    'audioSoundLoop': '',
	    'audioSideTopSound': '',
	    'audioSideBottomSound': '',
	    'audioSideLeftSound': '',
	    'audioSideRightSound': '',

		'isCheckpoint': False,
	    'heroStartPositionX': 0,
	    'heroStartPositionY': 0,
	    'heroStartSpeedX': 0,
	    'heroStartSpeedY': 0,
	
	    'lights': [],
		'scripts': '',
		'extensions': '',
		'paddles': [],
	}
	for i in range (MAX_BG_IMAGES):
		config['bgImage%d' % i] = ''
		config['bgImage%dPositionX' % i] = 0
		config['bgImage%dPositionY' % i] = 0
		config['bgImage%dOpacity' % i] = BG_IMAGE_OPACITY
		config['bgImage%dShowDuration' % i] = BG_IMAGE_SHOW_DURATION
	config.update (kargs)
	return config

D = 0
SCREEN_PROPERTIES_TYPES = {
    'name': (str, DI()),
    'title': (str, DI()),
    'titleColor': (tColor, DI()),
    'description': (str, DI()),
    'descriptionColor': (tColor, DI()),
    
    'kind' : (int, DI()),
    
    'kScreenFlagTopSideClosed': (bool, DI()),
    'kScreenFlagBottomSideClosed': (bool, DI()),
    'kScreenFlagLeftSideClosed': (bool, DI()),
    'kScreenFlagRightSideClosed': (bool, DI()),
    'kScreenFlagScriptUpdate': (bool, DI()),
    'kScreenFlagScriptOnEnter': (bool, DI()),
    'kScreenFlagScriptOnExit': (bool, DI()),

    'difficulty': (int, DI()),
    'positionX': (float, DI()),
    'positionY': (float, DI()),
    'width': (float, DI()),
    'height': (float, DI()),
    
    'availableTime': (float, DI()),
    'scorePerBorderHit': (int, DI()),

    'colorMode': (int, DI()),
    'colorOpacity': (int, DI()),
    'colorColor1': (tColor, DI()),
    'colorColor2': (tColor, DI()),
    'colorTintToDuration': (float, DI()),

    'minSpeedX': (float, DI()),
    'minSpeedY': (float, DI()),
    'maxSpeedX': (float, DI()),
    'maxSpeedY': (float, DI()),

    'accelerationInputX': (bool, DI()),
    'accelerationInputY': (bool, DI()),
    'accelerationViscosityX': (float, DI()),
    'accelerationViscosityY': (float, DI()),
    'accelerationFactorX': (float, DI()),
    'accelerationFactorY': (float, DI()),
    'accelerationMinX': (float, DI()),
    'accelerationMinY': (float, DI()),
    'accelerationMaxX': (float, DI()),
    'accelerationMaxY': (float, DI()),
    
	'gravityX': (float, DI()),
	'gravityY': (float, DI()),
	'friction': (float, DI()),
	
    'borderSizeTop': (int, DI()),
    'borderSizeBottom': (int, DI()),
    'borderSizeLeft': (int, DI()),
    'borderSizeRight': (int, DI()),

    'borderSideTopColor': (tColor, DI()),
    'borderSideBottomColor': (tColor, DI()),
    'borderSideLeftColor': (tColor, DI()),
    'borderSideRightColor': (tColor, DI()),

    'lightGridOpacity': (int, DI()),
    'lightGridOpacityDuration': (float, DI()),
 
    'messageColor': (tColor, DI()),
    'messageOpacity': (int, DI()),
    'messageEnabled': (bool, DI()),
   
    'audioBackgroundMusic': (str, DI()),
    'audioInSound': (str, DI()),
    'audioOutSound': (str, DI()),
    'audioSoundLoop': (str, DI()),
    'audioSideTopSound': (str, DI()),
    'audioSideBottomSound': (str, DI()),
    'audioSideLeftSound': (str, DI()),
    'audioSideRightSound': (str, DI()),

	'isCheckpoint': (bool, DI()),
    'heroStartPositionX': (float, DI()),
    'heroStartPositionY': (float, DI()),
    'heroStartSpeedX': (float, DI()),
    'heroStartSpeedY': (float, DI()),

	'lights': None,
    'paddles': None,
    'scripts': None,
    'extensions': None,
}
for i in range (MAX_BG_IMAGES):
	SCREEN_PROPERTIES_TYPES['bgImage%d' % i] = (str, DI())
	SCREEN_PROPERTIES_TYPES['bgImage%dPositionX' % i] = (float, DI())
	SCREEN_PROPERTIES_TYPES['bgImage%dPositionY' % i] = (float, DI())
	SCREEN_PROPERTIES_TYPES['bgImage%dOpacity' % i] = (int, DI())
	SCREEN_PROPERTIES_TYPES['bgImage%dShowDuration' % i] = (float, DI())

#------------------------------------------------------------------------------

def newPaddleConfig (x, y, width, height, **kargs):
	config = {
		'kind': 1,
	    
		'kPaddleFlagOffensiveSide': False,
		'kPaddleFlagCollisionDisabled': False,
		'kPaddleFlagBlockTouches': False,
		'kPaddleFlagScriptHandleTouches': False,
		'kPaddleFlagIsButton': False,
		'kPaddleFlagSelected': False,
		'kPaddleFlagEnabled': True,
	    'kPaddleFlagIsInvisible': False,
	    'kPaddleFlagScriptOnEnter': False,
	    'kPaddleFlagScriptOnExit': False,
	    'kPaddleFlagScriptApplyProximityInfluenceToHero': False,
	    'kPaddleFlagScriptOnSideToggled': False,
	    'kPaddleFlagScriptUpdate': False,
	    #'kPaddleFlagScriptUpdateAI': False,
	    'kPaddleFlagScriptOnHeroInProxymityArea': False,
	    'kPaddleFlagNoPositionLimit': False,
	    'kPaddleFlagIsGlobal': False,
	
		'name': '',
		'positionX': x,
		'positionY': y,
		'z': 0,
		'width': width,
		'height': height,
	    
		'speedX': 0,
		'speedY': 0,
		'minX': 0,
		'minY': 0,
		'maxX': 0,
		'maxY': 0,
	    
		'energy': 0,
		'elasticity':0,
	    
	    'scorePerHit': SCORE_PER_HIT,
	    
		'colorMode': 0,
		'colorOpacity': 255,
		'colorColor1': '255,255,255',
		'colorColor2': '0,0,0',
		'colorTintToDuration': 0,
	    
	    'textureName': '',
	    
		'proximityMode': 0,
		'proximityWidth': 0,
		'proximityHeight': 0,
		'proximityAccelerationX': 0,
		'proximityAccelerationY': 0,
	    
		'aiDefensiveKind': 'pong',
		'aiDefensiveConfig': '',
		'aiOffensiveKind': '',
		'aiOffensiveConfig': '',
	    
		'labelFont': DEFAULT_PADDLE_FONT,
	    'labelFontSize': DEFAULT_PADDLE_FONT_SIZE,
	    'labelColor': DEFAULT_PADDLE_FONT_COLOR,
	    'labelOpacity': DEFAULT_PADDLE_FONT_OPACITY,
	    'labelText': '',

	    'topImageName': "",
	    'topImagePositionX': 0.5,
	    'topImagePositionY': 0.5,
	    'topImageWidth': 0,
	    'topImageHeight': 0,
	    'topImageAnchorX': 0.5,
	    'topImageAnchorY': 0.5,
	    'topImageOpacity': 255,
	    'topImageRotation': 0,

		'audioInSound': '',
		'audioOutSound': '',
	    'audioSoundLoop': '',
	    'audioHitSound': '',
		'audioMoveSound': '',
		'audioMoveSoundTimeout': 1.0,
		'audioClickSound': '',
	    
		'scripts': '',
		'extensions': '',
		'lights': [],
	}
	config.update (kargs)

	return config

D = 0
PADDLE_PROPERTIES_TYPES = {
    'name': (str, DI()),
    'kind': (int, DI()),
    
    'kPaddleFlagOffensiveSide': (bool, DI()),
    'kPaddleFlagCollisionDisabled': (bool, DI()),
    'kPaddleFlagBlockTouches': (bool, DI()),
    'kPaddleFlagScriptHandleTouches': (bool, DI()),
    'kPaddleFlagIsButton': (bool, DI()),
    'kPaddleFlagSelected': (bool, DI()),
    'kPaddleFlagEnabled': (bool, DI()),
    'kPaddleFlagIsInvisible': (bool, DI()),
    'kPaddleFlagScriptOnEnter': (bool, DI()),
    'kPaddleFlagScriptOnExit': (bool, DI()),
    'kPaddleFlagScriptApplyProximityInfluenceToHero': (bool, DI()),
    'kPaddleFlagScriptOnSideToggled': (bool, DI()),
    'kPaddleFlagScriptUpdate': (bool, DI()),
    #'kPaddleFlagScriptUpdateAI': (bool, DI()),
    'kPaddleFlagScriptOnHeroInProxymityArea': (bool, DI()),
    'kPaddleFlagNoPositionLimit': (bool, DI()),
    'kPaddleFlagIsGlobal': (bool, DI()),

    'positionX': (float, DI()),
    'positionY': (float, DI()),
    'width': (float, DI()),
    'height': (float, DI()),
    'z': (float, DI()),

    'energy': (float, DI()),
    'elasticity': (float, DI()),

    'scorePerHit': (int, DI()),
    
    'colorMode': (int, DI()),
    'colorOpacity': (int, DI()),
    'colorColor1': (tColor, DI()),
    'colorColor2': (tColor, DI()),
    'colorTintToDuration': (float, DI()),
  
    'textureName': (str, DI()),
 
    'speedX': (float, DI()),
    'speedY': (float, DI()),
    'minX': (float, DI()),
    'minY': (float, DI()),
    'maxX': (float, DI()),
    'maxY': (float, DI()),
    
    'proximityMode': (int, DI()),
    'proximityWidth': (float, DI()),
    'proximityHeight': (float, DI()),
    'proximityAccelerationX': (float, DI()),
    'proximityAccelerationY': (float, DI()),
    
    'aiDefensiveKind': (str, DI()),
    'aiDefensiveConfig': (str, DI()),
    'aiOffensiveKind': (str, DI()),
    'aiOffensiveConfig': (str, DI()),
    
    'labelText': (str, DI()),
    'labelFont': (str, DI()),
    'labelFontSize': (int, DI()),
    'labelColor': (tColor, DI()),
    'labelOpacity': (int, DI()),

    'topImageName': (str, DI()),
    'topImagePositionX': (float, DI()),
    'topImagePositionY': (float, DI()),
    'topImageWidth': (int, DI()),
    'topImageHeight': (int, DI()),
    'topImageAnchorX': (float, DI()),
    'topImageAnchorY': (float, DI()),
    'topImageOpacity': (int, DI()),
    'topImageRotation': (float, DI()),

    'audioInSound': (str, DI()),
    'audioOutSound': (str, DI()),
    'audioSoundLoop': (str, DI()),
    'audioHitSound': (str, DI()),
    'audioMoveSound': (str, DI()),
    'audioMoveSoundTimeout': (float, DI()),
    'audioClickSound': (str, DI()),
        
    'lights': None,
    'scripts': None,
    'extensions': None,
}

