-- screen.lua

Screen = {}
local Screen_mt = {__index = Screen}

-- event handlers

function Screen:update (dt)
	self:updateTimers (dt)
	self:updateMessagesScripts (dt)
	
--	local b = (not self.timers or not #self.timers) and (not self.messagesScripts or not #self.messagesScripts)
--	game.screenSetNeedsScriptUpdate (self.index, b)
end

function Screen:onHeroHitBorders (heroIndex, borders)
	self:updateHeroOnBorderHit (heroIndex, borders)
end

function Screen:onEnter ()
	-- called when screen becomes visible
end

function Screen:onExit ()
	-- called when screen becomes NOT visible
end

-- utilities

function Screen:updateMainHeroWithPlayerInput (dt)
	local ax = 0
	local ay = 0
	local lax, lay = game.levelAcceleration ()
	local laxMin, layMin = game.levelAccelerationMin ()
	local laxMax, layMax = game.levelAccelerationMax ()
	local laxFactor, layFactor = game.levelAccelerationFactor ()
	local laxViscosity, layViscosity = game.levelAccelerationViscosity ()
	local hsx, hsy = mainHero:speed ()
	
	if game.levelAccelerationInputX () == true then
		ax = clamp (lax, laxMin, laxMax) * dt * laxFactor
		if ax ~= 0 then
			local accDirX = sign (hsx) * -1
			local newDirX = sign (ax)
			if accDirX == newDirX then
				ax = (math.abs (ax) + laxViscosity) * sign (ax)
			end
		end
	end
	
	if game.levelAccelerationInputY () == true then
		ay = clamp (lay, layMin, layMax) * dt * layFactor
		if ay ~= 0 then
			local accDirY = sign(hsy) * -1
			local newDirY = sign (ay)
			if accDirY == newDirY then
				ay = (math.abs (ay) + layViscosity) * sign (ay)
			end
		end
	end
	
	mainHero:setAcceleration (ax, ay)
end

function Screen:updateHeroOnBorderHit (heroIndex, borders)
	exitSide = kSideNone
	local hsx, hsy = game.heroSpeed (heroIndex)
	local flags = self:flags ()
	 
	if bit.band (borders, kSideLeft) == kSideLeft then
		if bit.band (flags, kScreenFlagLeftSideClosed) == kScreenFlagLeftSideClosed then
			hsx = math.abs (hsx) * self:borderElasticity (kScreenBorderSideLeft)
		else
			exitSide = bit.bor (exitSide, kSideLeft)
		end
	elseif bit.band (borders, kSideRight) == kSideRight then
		if bit.band (flags, kScreenFlagRightSideClosed) == kScreenFlagRightSideClosed then
			hsx = -math.abs (hsx) * self:borderElasticity (kScreenBorderSideRight)
		else
			exitSide = bit.bor (exitSide, kSideRight)
		end
	end

	if bit.band (borders, kSideTop) == kSideTop then
		if bit.band (flags, kScreenFlagTopSideClosed) == kScreenFlagTopSideClosed then
			hsy = -math.abs (hsy) * self:borderElasticity (kScreenBorderSideTop)
		else
			exitSide = bit.bor (exitSide, kSideTop)
		end
	elseif bit.band (borders, kSideBottom) == kSideBottom then
		if bit.band (flags, kScreenFlagBottomSideClosed) == kScreenFlagBottomSideClosed then
			hsy = math.abs (hsy) * self:borderElasticity (kScreenBorderSideBottom)
		else
			exitSide = bit.bor (exitSide, kSideBottom)
		end
	end
	
	game.heroSetSpeed (heroIndex, hsx, hsy)
end

-- attributes:name, title, description

function Screen:name ()
	return game.screenName (self.index)
end

function Screen:setTitle (s)
	return game.screenSetTitle (self.index, s)
end

function Screen:setDescription (s)
	return game.screenSetDescription (self.index, s)
end

-- attributes:flags

function Screen:flags ()
	return game.screenFlags (self.index)
end
	
function Screen:setFlags (flags)
	game.screenSetFlags (self.index, flags)
end
	
function Screen:unsetFlags (flags)
	game.screenUnsetFlags (self.index, flags)
end

-- input

function Screen:accelerationInputX ()
	return game.screenAccelerationInputX (self.index)
end
	
function Screen:setAccelerationInputX (b)
	game.screenSetAccelerationInputX (self.index, b)
end
	
function Screen:accelerationInputY ()
	return game.screenAccelerationInputY (self.index)
end
	
function Screen:setAccelerationInputY (b)
	game.screenSetAccelerationInputY (self.index, b)
end
	
-- attributes:colors

function Screen:color1 ()
	return game.screenColor1 (self.index)
end

function Screen:color2 ()
	return game.screenColor2 (self.index)
end

function Screen:setColor (r, g, b)
	game.screenSetColor (self.index, r, g, b)
end
	
function Screen:setColors (r1, g1, b1, r2, g2, b2)
	game.screenSetColors (self.index, r1, g1, b1, r2, g2, b2)
end
	
-- attributes:position, size

function Screen:position ()
	return game.screenPosition (self.index)
end

function Screen:size ()
	return game.screenSize (self.index)
end

-- attributes:borders

function Screen:borderElasticity (side)
	return game.screenBorderElasticity (self.index, side)
end

function Screen:setBorderActive (side, f)
	game.screenSetBorderActive (self.index, side, f)
end

function Screen:borderActive (side)
	return game.screenBorderActive (self.index, side)
end

-- attributes:message
--[[
function Screen:setMessage (txt)
	game.screenSetMessage (self.index, txt)
end
	
function Screen:setMessageColor (r, g, b)
	game.screenSetMessageColor (self.index, r, g, b)
end
	
function Screen:setMessageOpacity (o)
	game.screenSetMessageOpacity (self.index, o)
end
	
function Screen:messageEnabled ()
	return game.screenMessageEnabled (self.index)
end
		
function Screen:setMessageEnabled (b)
	game.screenSetMessageEnabled (self.index, b)
end
]]--

-- attributes:lights

function Screen:lightsCount ()
	return game.screenLightsCount (self.index)
end
	
function Screen:lightVisible (lightIndex)
	return game.screenLightVisible (self.index, lightIndex)
end
	
function Screen:setLightVisible (lightIndex, b)
	game.screenSetLightVisible (self.index, lightIndex, b)
end

function Screen:lightPosition (lightIndex)
	return game.screenLightPosition (self.index, lightIndex)
end
	
function Screen:setLightPosition (lightIndex, x, y)
	game.screenSetLightPosition (self.index, lightIndex, x, y)
end

function Screen:lightSize (lightIndex)
	return game.screenLightSize (self.index, lightIndex)
end
	
function Screen:setLightSize (lightIndex, w, h)
	game.screenSetLightSize (self.index, lightIndex, w, h)
end

function Screen:lightPower (lightIndex)
	return game.screenLightPower (self.index, lightIndex)
end
	
function Screen:setLightPower (lightIndex, p)
	game.screenSetLightPower (self.index, lightIndex, p)
end

-- attributes:time

function Screen:setAvailableTime (t)
	game.screenSetAvailableTime (self.index, t)
end
	
-- attributes:hero

function Screen:heroStartPosition ()
	return game.screenHeroStartPosition (self.index)
end
	
-- messages

--[[
Format:

{
	{entity(mainHero | 'paddleName'), msg, emoticon, duration, sound, timeoutForNext},
	{kMessageTimeout, seconds},
	{kMessageCallback, callback, arg, timeoutForNext},
}

]]--

function Screen:startMessagesScript (name, messages)
	self.messagesScripts[name] = {
		timeout = 0,
		next = 1,
		messages = messages,
		entity = nil,
	}
--	game.screenSetNeedsScriptUpdate (self.index, true)
end

function Screen:stopMessagesScript (name)
	local data = self.messagesScripts[name]
	
	if data then
		if data.entity then
			data.entity:removeMessage ()
		end
		
		self.messagesScripts[name] = nil
	end
end


function Screen:stopAllMessagesScripts ()
	self.messagesScripts = {}
	game.screenRemoveAllMessages ()
end

function Screen:updateMessagesScripts (dt)
	if not self.messagesScripts or not #self.messagesScripts then return end
	
	for name, data in pairs (self.messagesScripts) do
		data.timeout = data.timeout - dt
		if data.timeout <= 0 then
			if data.next == -1 then
				self.messagesScripts[name] = nil
			else
				local msg = data.messages[data.next]
				local entity = msg[1]
				local duration
				local timeout
				
				if entity == kMessageTimeout then
					data.entity = nil
					timeout = msg[2]
					duration = timeout
				elseif entity == kMessageCallback then
					data.entity = nil
					timeout = msg[4]
					duration = timeout
					msg[2] (self, msg[3])
				else
					if entity ~= mainHero then
						entity = level:paddleWithName (entity)
					end

					timeout = msg[6]
					duration = msg[4]
					entity:showMessageEmoticonDurationSound (msg[2], msg[3], duration, msg[5])
					data.entity = entity
				end
				 
				next = data.next + 1
				if next > #data.messages then
					data.next = -1
					data.timeout = duration
				else
					data.next = next
					data.timeout = timeout 
				end
			end
		end
	end
end

-- timers

function Screen:addTimer (name, timeout, callback, repeating)
	self.timers[name] = {
		origTimeout = timeout,
		timeout = timeout,
		callback = callback,
		repeating = repeating
	}
--	game.screenSetNeedsScriptUpdate (self.index, true)
end

function Screen:removeTimer (name)
	self.timers[name] = nil
end

function Screen:updateTimers (dt)
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

function Screen:init ()
	self.timers = {}
	self.messagesScripts = {}
end

function Screen:destroy ()
	self.timers = nil
	self.messagesScripts = nil
end

function Screen:setup ()
end

function Screen:new (idx)
	local newScreen = {
		index = idx,
	}
	setmetatable (newScreen, Screen_mt)
	
	return newScreen
end

-- global with current screen
screen = nil
exitSide = 0

-- global functions

function screenUpdate (index, dt)
	level.screens[index]:update (dt)
end

function screenUpdateMainHeroWithPlayerInput (dt)
	screen:updateMainHeroWithPlayerInput (dt)
end

function screenOnHeroHitBorders (heroIndex, collisionSide)
	screen:onHeroHitBorders (heroIndex, collisionSide)
end

function screenOnEnter (index)
	level.screens[index]:onEnter ()
end

function screenOnExit (index)
	level.screens[index]:onExit ()
end



