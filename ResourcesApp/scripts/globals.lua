do
	function globalsInit ()
		-- game modes
		kGMQuest = 1
		kGMTimeTrial = 2
		kGMChallenge = 3

		-- input modes
		kInputModeSlide = 1
		kInputModeJoystick = 2

		-- difficulty levels
		kDifficultyLow = 1
		kDifficultyMedium = 2
		kDifficultyHigh = 3
	
		-- die modes
		kDieTimeout = 1
		kDieKilled = 2

		-- side flags
		kSideNone = 0
		kSideLeft = bit.blshift (1, 0)
		kSideTop = bit.blshift (1, 1)
		kSideRight = bit.blshift (1, 2)
		kSideBottom = bit.blshift (1, 3)
		
		-- level flags
		kLevelFlagLevelUpdate = bit.blshift (1, 0)
		kLevelFlagScriptUpdate = bit.blshift (1, 1)
		kLevelFlagShowHUD = bit.blshift (1, 2)
		kLevelFlagDoNotStartBackgroundMusic = bit.blshift (1, 3)
		
		-- screen flags
		kScreenFlagLeftSideClosed = bit.blshift (1, 0)
		kScreenFlagRightSideClosed = bit.blshift (1, 1)
		kScreenFlagTopSideClosed = bit.blshift (1, 2)
		kScreenFlagBottomSideClosed = bit.blshift (1, 3)
		kScreenFlagScriptUpdate = bit.blshift (1, 4)
		kScreenFlagScriptOnEnter = bit.blshift (1, 5)
		kScreenFlagScriptOnExit = bit.blshift (1, 6)

		-- paddle flags
		kPaddleFlagOffensiveSide = bit.blshift (1, 0)
		kPaddleFlagCollisionDisabled = bit.blshift (1, 1)
		kPaddleFlagBlockTouches = bit.blshift (1, 2)
		kPaddleFlagHandleTouches = bit.blshift (1, 3)
		kPaddleFlagIsButton = bit.blshift (1, 4)
		kPaddleFlagSelected = bit.blshift (1, 5)
		kPaddleFlagEnabled = bit.blshift (1, 6)
		kPaddleFlagScriptOnEnter = bit.blshift (1, 7)
		kPaddleFlagScriptOnExit = bit.blshift (1, 8)
		kPaddleFlagScriptApplyProximityInfluenceToHero = bit.blshift (1, 9)
		kPaddleFlagScriptOnSideToggled = bit.blshift (1, 10)
		kPaddleFlagScriptUpdate = bit.blshift (1, 11)
		kPaddleFlagScriptOnHeroInProxymityArea = bit.blshift (1, 13)
		kPaddleFlagIsInvisible = bit.blshift (1, 14)
		kPaddleFlagNoPositionLimit = bit.blshift (1, 15)
	
		-- lights flags
		kLightFlagBindToEntity = bit.blshift (1, 0)
		kLightFlagBlink = bit.blshift (1, 1)
		kLightFlagHardLight = bit.blshift (1, 2)
		kLightFlagBlackLight = bit.blshift (1, 3)
		kLightFlagAddOpacity = bit.blshift (1, 4)

		-- hero acceleration modes
		kAccelerationUnknown = 0
		kAccelerationNormal = 1
		kAccelerationTurbo = 2
		
		-- screen borders
		kScreenBorderSideTop = 0
		kScreenBorderSideBottom = 1
		kScreenBorderSideLeft = 2
		kScreenBorderSideRight = 3

		-- message emoticons
		kEmoticonPlain = 0
		kEmoticonHappy = 1
		kEmoticonSad = 2
		kEmoticonAngel = 3
		kEmoticonDevil = 4
		kEmoticonBored = 5
		kEmoticonAngry = 6
		kEmoticonCrying = 7
		kEmoticonDrunk = 8
		kEmoticonKiss = 9
		kEmoticonSurprised = 10
		kEmoticonTongue = 11
		kEmoticonWinking = 12

		-- message special entities
		kMessageTimeout = -1
		kMessageCallback = -2
		
		-- OpenFeint achievements

		if game.isFreeVersion () then
			OFA_TRAINING_MOVE_COMPLETED = "636102"
			OFA_TRAINING_JUMP_COMPLETED = "640702"
			
			OFA_PONGLAND_LEVEL_COMPLETED = "640712"
			
			OFA_ROLLER_SQUARESTER_LEVEL_COMPLETED = "640722"
			OFA_ROLLER_SQUARESTER_FULL_BONUS = "640732"
			
			OFA_DUNGEON_OF_SQUARES_LEVEL_COMPLETED = "640742"
			OFA_DUNGEON_OF_SQUARES_FULL_BONUS = "640752"
			OFA_DUNGEON_OF_SQUARES_WITHOUT_TURBO = "640762"
			
			OFA_DOODLE_PADDLE_LEVEL_COMPLETED = "640772"
			OFA_DOODLE_PADDLE_FULL_BONUS = "640782"

			OFA_FREE_FALLING_LEVEL_COMPLETED = "640792"
			OFA_FREE_FALLING_FULL_BONUS = "640802"
			OFA_FREE_FALLING_FANTASTIC_FALL = "640812"

			OFA_PONGANOID_LEVEL_COMPLETED = "640822"
			OFA_PONGANOID_FULL_BONUS = "640832"
			OFA_PONGANOID_BRICKNATOR = "640842"

			OFA_PINGFALL_LEVEL_COMPLETED = "640852"

			OFA_SQUARE_MACHINE_LEVEL_COMPLETED = "640862"
			OFA_SQUARE_MACHINE_MASTER = "640872"

			OFA_OBEY_OR_NOT_LEVEL_COMPLETED = "640882"
			OFA_OBEY_OR_NOT_ANARCHIST = "640892"
			OFA_OBEY_OR_NOT_NEVER_FAILED = "640902"

			OFA_LAST_PADDLE_STANDING_LEVEL_COMPLETED = "640912"

			OFA_THE_GREAT_ESCAPIST = "640922"
		
		else		
			OFA_TRAINING_MOVE_COMPLETED = "348434"
			OFA_TRAINING_JUMP_COMPLETED = "588272"
			
			OFA_PONGLAND_LEVEL_COMPLETED = "367914"
			
			OFA_ROLLER_SQUARESTER_LEVEL_COMPLETED = "367924"
			OFA_ROLLER_SQUARESTER_FULL_BONUS = "367854"
			
			OFA_DUNGEON_OF_SQUARES_LEVEL_COMPLETED = "367964"
			OFA_DUNGEON_OF_SQUARES_WITHOUT_TURBO = "367974"
			OFA_DUNGEON_OF_SQUARES_FULL_BONUS = "383284"
			
			OFA_DOODLE_PADDLE_LEVEL_COMPLETED = "383264"
			OFA_DOODLE_PADDLE_FULL_BONUS = "383274"

			OFA_FREE_FALLING_LEVEL_COMPLETED = "385014"
			OFA_FREE_FALLING_FULL_BONUS = "385024"
			OFA_FREE_FALLING_FANTASTIC_FALL = "385034"

			OFA_PONGANOID_LEVEL_COMPLETED = "407444"
			OFA_PONGANOID_FULL_BONUS = "407454"
			OFA_PONGANOID_BRICKNATOR = "407464"

			OFA_PINGFALL_LEVEL_COMPLETED = "433814"

			OFA_SQUARE_MACHINE_LEVEL_COMPLETED = "458064"
			OFA_SQUARE_MACHINE_MASTER = "458094"

			OFA_OBEY_OR_NOT_LEVEL_COMPLETED = "481234"
			OFA_OBEY_OR_NOT_ANARCHIST = "481244"
			OFA_OBEY_OR_NOT_NEVER_FAILED = "538432"

			OFA_LAST_PADDLE_STANDING_LEVEL_COMPLETED = "481264"

			OFA_THE_GREAT_ESCAPIST = "407484"

		end
	end
end


