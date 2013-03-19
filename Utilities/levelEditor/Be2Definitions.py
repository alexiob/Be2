DEFAULT_SCREEN_WIDTH = 480
DEFAULT_SCREEN_HEIGHT = 320

DEFAULT_PADDLE_WIDTH = 10
DEFAULT_PADDLE_HEIGHT = 100

DEFAULT_PADDLE_FONT = 'orangekid'
DEFAULT_PADDLE_FONT_COLOR = '0,0,0'
DEFAULT_PADDLE_FONT_SIZE = 16
DEFAULT_PADDLE_FONT_OPACITY = 255

DEFAULT_SCREEN_BORDER_COLOR = "255,255,255"

DEFAULT_SCREEN_FONT = DEFAULT_PADDLE_FONT

DEFAULT_SCREEN_TITLE_FONT_SIZE = 32
DEFAULT_SCREEN_TITLE_OPACITY = 255
DEFAULT_SCREEN_TITLE_COLOR = '255,255,255'
SCREEN_TITLE_START_Y = 8

DEFAULT_SCREEN_DESCRIPTION_COLOR = '200,200,200'
DEFAULT_SCREEN_DESCRIPTION_FONT_SIZE = 16
DEFAULT_SCREEN_DESCRIPTION_OPACITY = 255
SCREEN_DESCRIPTION_START_Y = 64

DEFAULT_SCREEN_MESSAGE_COLOR = '200,200,200'
DEFAULT_SCREEN_MESSAGE_OPACITY = 255

DEFAULT_ACCELERATION_INPUT_X = 0
DEFAULT_ACCELERATION_INPUT_Y = 1

DEFAULT_ACCELERATION_VISCOSITY_X = 0.75
DEFAULT_ACCELERATION_VISCOSITY_Y = 0.75

DEFAULT_ACCELERATION_FACTOR_X = 1.0
DEFAULT_ACCELERATION_FACTOR_Y = 1.0

DEFAULT_ACCELERATION_MIN_X = -100.0
DEFAULT_ACCELERATION_MIN_Y = -100.0
DEFAULT_ACCELERATION_MAX_X = 100.0 
DEFAULT_ACCELERATION_MAX_Y = 100.0

HERO_DEFAULT_WIDTH = 10
HERO_DEFAULT_HEIGHT = 10

FONT_TO_TTF = {
    DEFAULT_PADDLE_FONT: 'Orange Kid',
}

MAX_BG_IMAGES = 4
BG_IMAGE_SHOW_DURATION = 0.5
BG_IMAGE_OPACITY = 180

#-------------------- FLAGS

# game engine
kGEFlagUpdateDisabled = 1 << 0
kGEFlagScriptUpdateDisabled = 1 << 1
kGEFlagPhysicsUpdateDisabled = 1 << 2

# sides
kSideNone = 0
kSideLeft = 1 << 0
kSideTop = 1 << 1
kSideRight = 1 << 2
kSideBottom = 1 << 3

# level 
kLevelFlagLevelUpdate = 1 << 0
kLevelFlagScriptUpdate = 1 << 1
kLevelFlagShowHUD = 1 << 2
kLevelFlagDoNotStartBackgroundMusic = 1 << 3

# screen

kScreenFlagLeftSideClosed = 1 << 0
kScreenFlagRightSideClosed = 1 << 1
kScreenFlagTopSideClosed = 1 << 2
kScreenFlagBottomSideClosed = 1 << 3
kScreenFlagScriptUpdate = 1 << 4
kScreenFlagScriptOnEnter = 1 << 5
kScreenFlagScriptOnExit = 1 << 6

DEFAULT_BORDER_SIZE = 5

# paddle

kPaddleFlagOffensiveSide = 1 << 0
kPaddleFlagCollisionDisabled = 1 << 1
kPaddleFlagBlockTouches = 1 << 2
kPaddleFlagScriptHandleTouches = 1 << 3
kPaddleFlagIsButton = 1 << 4
kPaddleFlagSelected = 1 << 5
kPaddleFlagEnabled = 1 << 6
kPaddleFlagScriptOnEnter = 1 << 7
kPaddleFlagScriptOnExit = 1 << 8
kPaddleFlagScriptApplyProximityInfluenceToHero = 1 << 9
kPaddleFlagScriptOnSideToggled = 1 << 10
kPaddleFlagScriptUpdate = 1 << 11
#kPaddleFlagScriptUpdateAI = 1 << 12
kPaddleFlagScriptOnHeroInProxymityArea = 1 << 13
kPaddleFlagIsInvisible = 1 << 14
kPaddleFlagNoPositionLimit = 1 << 15
kPaddleFlagIsGlobal = 1 << 16

# hero

kHeroFlagIsMain = 1 << 0
kHeroFlagDontUpdateMovement = 1 << 1
kHeroFlagScriptUpdate = 1 << 2
kHeroFlagScriptUpdateWithPlayerInput = 1 << 3

# ai
kAIFlagCheckInSensorRange = 1 << 0
kAIFlagCheckOutSensorRange = 1 << 1
kAIFlagCheckInProximityArea = 1 << 2
kAIFlagCheckOutProximityArea = 1 << 3

# light
kLightFlagBindToEntity = 1 << 0
kLightFlagBlink = 1 << 1
kLightFlagHardLight = 1 << 2
kLightFlagBlackLight = 1 << 3
kLightFlagAddOpacity = 1 << 4
	
#-------------------- ENUMS

kEntityColorModeSolid = 0
kEntityColorModeTintTo = 1
kEntityOpacityModeSolid = 2
kEntityOpacityModeFadeTo = 3

kLightKindRect = 0

#-------------------- SCORE

SCORE_PER_BORDER_HIT = 100
SCORE_PER_HIT = 150
SCORE_PER_SECOND_LEFT = 1000
