-- level.lua

Level = {}
local Level_mt = {__index = Level}

-- event handlers

function Level:update (dt)
	self:updateTimers (dt)
end

function Level:onTimeLeftTimeout ()
	game.die (kDieTimeout)
end

function Level:onDie ()
end

-- attributes:info

function Level:name ()
	return game.levelName ()
end

function Level:title ()
	return game.levelTitle ()
end

function Level:desc ()
	return game.levelDesc ()
end

function Level:nextLevelName ()
	return game.levelNextLevelName ()
end

function Level:numScreens ()
	return game.levelNumScreens ()
end

-- attributes:screen

function Level:currentScreen ()
	return self.screens[self.currentScreenIndex]
end

function Level:setCurrentScreen (idx)
	self.currentScreenIndex = idx
	screen = self.screens[self.currentScreenIndex]
end

-- attributes:color

function Level:color ()
	return game.levelColor ()
end

function Level:setColor (r, g, b)
	game.levelSetColor (r, g, b)
end

-- attributes:flags

function Level:flags ()
	return game.levelFlags ()
end
	
function Level:setFlags (flags)
	game.levelSetFlags (flags)
end
	
function Level:unsetFlags (flags)
	game.levelUnsetFlags (flags)
end

-- attributes:turbo

function Level:wasTurboUsed ()
	return game.levelWasTurboUsed ()
end

-- utilities

function Level:showHUD (b)
	game.levelShowHUD (b)
end

function Level:paddleWithName (name)
	for idx, paddle in pairs (self.paddles) do
		if paddle:name () == name then
			return paddle
		end
	end
	return nil
end

function Level:screenWithName (name)
	for idx, screen in pairs (self.screens) do
		if screen:name () == name then
			return screen
		end
	end
	return nil
end

-- timers

function Level:addTimer (name, timeout, callback, repeating)
	self.timers[name] = {
		origTimeout = timeout,
		timeout = timeout,
		callback = callback,
		repeating = repeating
	}
end

function Level:removeTimer (name)
	self.timers[name] = nil
end

function Level:updateTimers (dt)
	for name, data in pairs (self.timers) do
		data.timeout = data.timeout - dt
		if data.timeout <= 0 then
			data.callback (self, name)
			if data.repeating then
				data.timeout = data.origTimeout
			else
				self.timers[name] = nil
			end
		end
	end
end

-- exploration points

function Level:explorationPointsAdd (name, points)
	if self.explorationPoints[name] == nil then
		game.explorationPointsAdd (points)
		self.explorationPoints[name] = points
	end
end

-- setup

function Level:init ()
	self.paddles = {}
	self.screens = {}
	self.timers = {}
	self.explorationPoints = {}
	
	self.currentScreenIndex = -1
	
	mainHero = Hero:new (0)
end

function Level:destroy ()
	screen = nil
	level = nil
	mainHero = nil
end

-- setup is called when all level data (paddles, screens, etc)
-- is initialized.
function Level:setup ()
end

function Level:new ()
	local newLevel = {}
	setmetatable (newLevel, Level_mt)
	return newLevel
end

-- global with current level
level = nil

-- global with current screen
screen = nil

-- global functions

function levelUpdate (dt)
	level:update (dt)
end

function levelSetCurrentScreen (index)
	level:setCurrentScreen (index)
end


