-- hero.lua

Hero = {}
local Hero_mt = {__index = Hero}

-- event handlers

function Hero:update (dt)
	self:updateTimers (dt)
end

function Hero:onHeroHitBorders (heroIndex, borders)
end

function Hero:onEnter ()
end

function Hero:onExit ()
end

-- utilities

function Hero:intputIsAccelerating ()
	return game.inputAccelerationMode () ~= kAccelerationUnknown
end

function Hero:intputAccelerationMode ()
	return game.inputAccelerationMode ()
end

function Hero:inputAaccelerationStart ()
	return game.inputAccelerationStart ()
end

function Hero:inputAacceleration ()
	return game.inputAcceleration ()
end

-- attributes: paused

function Hero:isPaused ()
	return game.heroIsPaused (self.index)
end

function Hero:setPaused (b)
	return game.heroPause (self.index, b)
end

-- attributes:position, size, acceleration, speed, elasticity, bbox

function Hero:centerPosition ()
	x, y = game.heroPosition (self.index)
	w, h = game.heroSize (self.index)
	return x + w/2, y + h/2
end

function Hero:position ()
	return game.heroPosition (self.index)
end

function Hero:setPosition (x, y)
	return game.heroSetPosition (self.index, x, y)
end

function Hero:size ()
	return game.heroSize (self.index)
end

function Hero:setSize (w, h)
	return game.heroSetSize (self.index, w, h)
end

function Hero:acceleration ()
	return game.heroAcceleration (self.index)
end

function Hero:setAcceleration (x, y)
	return game.heroSetAcceleration (self.index, x, y)
end

function Hero:elasticity ()
	return game.heroElasticity (self.index)
end

function Hero:setElasticity (x, y)
	return game.heroSetElasticity (self.index, x, y)
end

function Hero:speed ()
	return game.heroSpeed (self.index)
end

function Hero:setSpeed (x, y)
	return game.heroSetSpeed (self.index, x, y)
end

function Hero:bbox ()
	return game.heroBBox (self.index)
end

-- attributes:flags

function Hero:flags ()
	return game.heroFlags (self.index)
end
	
function Hero:setFlags (flags)
	game.heroSetFlags (self.index, flags)
end
	
function Hero:unsetFlags (flags)
	game.heroUnsetFlags (self.index, flags)
end

--[[
-- attributes:colors

function Hero:setColor (r, g, b)
	game.heroSetColor (self.index, r, g, b)
end
	
function Hero:setColors (r1, g1, b1, r2, g2, b2)
	game.heroSetColors (self.index, r1, g1, b1, r2, g2, b2)
end
]]---	

-- attributes:lights

function Hero:lightEnabled ()
	return game.heroLightEnabled (self.index)
end
	
function Hero:setLightEnabled (b)
	game.heroSetLightEnabled (self.index, b)
end

function Hero:lightVisible ()
	return game.heroLightVisible (self.index)
end
	
function Hero:setLightVisible (b)
	game.heroSetLightVisible (self.index, b)
end

function Hero:lightPosition ()
	return game.heroLightPosition (self.index)
end
	
function Hero:setLightPosition (x, y)
	game.heroSetLightPosition (self.index, x, y)
end

function Hero:lightSize ()
	return game.heroLightSize (self.index)
end
	
function Hero:setLightSize (w, h)
	game.heroSetLightSize (self.index, w, h)
end

function Hero:lightPower ()
	return game.heroLightPower (self.index)
end
	
function Hero:setLightPower (p)
	game.heroSetLightPower (self.index, p)
end

-- messages

function Hero:showMessageEmoticonSound (msg, emoticon, sound)
	game.heroShowMessageEmoticonSound (self.index, msg, emoticon, sound)
end

function Hero:showMessageEmoticonDurationSound (msg, emoticon, duration, sound)
	game.heroShowMessageEmoticonDurationSound (self.index, msg, emoticon, duration, sound)
end

function Hero:showMessageEmoticonBMISizeDurationSound (msg, emoticon, bgColor, msgColor, icnColor, duration, sound)
	game.heroShowMessageEmoticonBMISizeDurationSound (self.index, msg, emoticon, bgColor, msgColor, icnColor, duration, sound)
end

function Hero:removeMessage ()
	game.heroRemoveMessage (self.index)
end

-- timers

function Hero:addTimer (name, timeout, callback, repeating)
	self.timers[name] = {
		origTimeout = timeout,
		timeout = timeout,
		callback = callback,
		repeating = repeating
	}
end

function Hero:removeTimer (name)
	self.timers[name] = nil
end

function Hero:updateTimers (dt)
	if not self.timers or not #self.timers then return end
	
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

-- setup

function Hero:init ()
	self.timers = {}
end

function Hero:destroy ()
	hero = nil
end

function Hero:setup ()
end

function Hero:new (idx)
	local newHero = {
		index = idx,
	}
	setmetatable (newHero, Hero_mt)
	
	newHero:init ()
	
	return newHero
end

-- global with main hero
mainHero = nil

-- global functions

function mainHeroUpdate (dt)
	mainHero:update (dt)
end

