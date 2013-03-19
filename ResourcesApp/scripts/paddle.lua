-- paddle.lua

Paddle = {}
local Paddle_mt = {__index = Paddle}

-- event handlers

function Paddle:updateAI (dt)
	if self:isOffensiveSide () and self.offensiveAI then
		self.offensiveAI:update (dt)
	elseif self.defensiveAI then
		self.defensiveAI:update (dt)
	end
end

function Paddle:updateCallbacks (dt)
	if self.callbacks.onUpdate then
		for name, callback in pairs (self.callbacks.onUpdate) do
			callback (self, dt)
		end
	end
end

function Paddle:update (dt)
	-- called after updateAI
	self:updateTimers (dt)
	self:updateCallbacks (dt)
	self:updatePositionWithSpeedAndAcceleration (dt)
end

function Paddle:onEnter ()
	-- called when paddle becomes visible
end

function Paddle:onExit ()
	-- called when paddle becomes NOT visible
end

function Paddle:onTouchBegan (x, y, count)
	-- print ('Paddle:onTouchBegan ', x, y, count, self)
end

function Paddle:onTouchMoved (x, y, count)
	-- print ('Paddle:onTouchMoved ', x, y, count, self)
end

function Paddle:onTouchEnded (x, y, count)
	-- print ('Paddle:onTouchEnded ', x, y, count, self)
end

function Paddle:onClick ()
	-- print ('Paddle:onClick')
end

function Paddle:onHitCallbacks (heroIndex, side, x, y)
	if self.callbacks.onHit then
		for name, callback in pairs (self.callbacks.onHit) do
			callback (self, heroIndex, side, x, y)
		end
	end
end

function Paddle:onHit (heroIndex, side, x, y)
	self:onHitCallbacks (heroIndex, side, x, y)
end

function Paddle:onHeroInProxymityArea (heroIndex)
	-- print ('Paddle:onHeroInProxymityArea ', heroIndex)
end

function Paddle:onSideToggled (isDefensive)
	-- print ('Paddle:onSideToggled ', isDefensive)
end

-- utilities

function Paddle:updateHeroSpeedWithSpeed (heroIndex, side, x, y)
	-- FIXME: paddle energy/collisionPoint
	
	local sx, sy = self:speed ()
	local hsx, hsy = game.heroSpeed (heroIndex)
	local e = self:elasticity ()
	
	if bit.band (side, kSideLeft) == kSideLeft then
		hsx = (-math.abs (hsx) + sx * e)
	elseif bit.band (side, kSideRight) == kSideRight then
		hsx = (math.abs (hsx) + sx * e)
	end
	
	if bit.band (side, kSideTop) == kSideTop then
		hsy = (math.abs (hsy) + sy * e)
	elseif bit.band (side, kSideBottom) == kSideBottom then
		hsy = (-math.abs (hsy) + sy * e)
	end
	
	game.heroSetSpeed (heroIndex, hsx, hsy)
end

function Paddle:updatePositionWithSpeedAndAcceleration (dt)
	game.paddleUpdatePositionWithSpeedAndAcceleration (self.index, dt)
end

function Paddle:limitPosition (x, y)
	w, h = self:size ()
	sx, sy = screen:position ()
	sw, sh = screen:size ()
	
	if (x < sx) then 
		x = sx
	elseif (x + w > sx + sw) then
		x = sx + sw - w
	end
	
	if (y < sy) then 
		y = sy
	elseif (y + h > sy + sh) then
		y = sy + sh - h
	end
	
	return x, y
end

function Paddle:applyProximityInfluenceToHero (heroIndex, sx, sy, dist)
	local ax , ay = game.heroAcceleration (heroIndex)
	local px , py = self:proximityAcceleration ()
	ax = ax + ((px * sx) / dist)
	ay = ay + ((py * sy) / dist)
	game.heroSetAcceleration (heroIndex, ax, ay)
end

-- attributes

function Paddle:kind ()
	return game.paddleKind (self.index)
end

function Paddle:bbox ()
	return game.paddleBBox (self.index)
end

function Paddle:name ()
	return game.paddleName (self.index)
end

-- attributes:flags

function Paddle:flags ()
	return game.paddleFlags (self.index)
end

function Paddle:setFlags (flags)
	game.paddleSetFlags (self.index, flags)
end

function Paddle:unsetFlags (flags)
	game.paddleUnsetFlags (self.index, flags)
end

-- attributes:size, position, speed, acceleration

function Paddle:size ()
	return game.paddleSize (self.index)
end

function Paddle:setSize (width, height)
	game.paddleSetSize (self.index, width, height)
end

function Paddle:centerPosition ()
	x, y = game.paddlePosition (self.index)
	w, h = game.paddleSize (self.index)
	return x + w/2, y + h/2
end

function Paddle:position ()
	return game.paddlePosition (self.index)
end

function Paddle:setPosition (x, y)
	game.paddleSetPosition (self.index, x, y)
end

function Paddle:minPosition ()
	return game.paddleMinPosition (self.index)
end

function Paddle:setMinPosition (x, y)
	game.paddleSetMinPosition (self.index, x, y)
end

function Paddle:maxPosition ()
	return game.paddleMaxPosition (self.index)
end

function Paddle:setMaxPosition (x, y)
	game.paddleSetMaxPosition (self.index, x, y)
end

function Paddle:speed ()
	return game.paddleSpeed (self.index)
end

function Paddle:setSpeed (x ,y)
	game.paddleSetSpeed (self.index, x, y)
end

function Paddle:acceleration ()
	return game.paddleAcceleration (self.index)
end

function Paddle:setAcceleration (x ,y)
	game.paddleSetAcceleration (self.index, x, y)
end

function Paddle:elasticity ()
	return game.paddleElasticity (self.index)
end

-- attributes:proximity

function Paddle:isHeroInsideProximityArea (heroIndex)
	return game.isHeroInsideProximityArea (self.index, heroIndex)
end

function Paddle:proximityArea ()
	return game.paddleProximityArea (self.index)
end

function Paddle:setProximityArea (x ,y)
	game.paddleSetProximityArea (self.index, x, y)
end

function Paddle:proximityAcceleration ()
	return game.paddleProximityAcceleration (self.index)
end

function Paddle:setProximityAcceleration (x ,y)
	game.paddleSetProximityAcceleration (self.index, x, y)
end

-- attributes:buttons

function Paddle:isButton ()
	return game.paddleIsButton (self.index)
end

function Paddle:setIsButton (b)
	game.paddleSetIsButton (self.index, b)
end

function Paddle:selected ()
	return game.paddleSelected (self.index)
end

function Paddle:setIsButton (b)
	game.paddleSetSelected (self.index, b)
end

-- attributes:enabled, color, opacity, visibility

function Paddle:enabled ()
	return game.paddleEnabled (self.index)
end

function Paddle:setEnabled (b)
	game.paddleSetEnabled (self.index, b)
end

function Paddle:isInvisible ()
	return game.paddleIsInvisible (self.index)
end

function Paddle:setIsInvisible (b)
	game.paddleSetIsInvisible (self.index, b)
end

function Paddle:color ()
	return game.paddleColor (self.index)
end

function Paddle:setColor (r, g, b)
	game.paddleSetColor (self.index, r, g, b)
end

function Paddle:opacity ()
	return game.paddleOpacity (self.index)
end

function Paddle:setOpacity (o)
	game.paddleSetOpacity (self.index, o)
end

-- actions fx

function Paddle:actionStop (tag)
	game.paddleActionStop (self.index, tag)
end

function Paddle:actionRotateByAngleDurationForeverTag (angle, duration, forever, tag)
	game.paddleActionRotateByAngleDurationForeverTag (self.index, angle, duration, forever, tag)
end

function Paddle:actionRotateToAngleDurationForeverTag (angle, duration, forever, tag)
	game.paddleActionRotateToAngleDurationForeverTag (self.index, angle, duration, forever, tag)
end

function Paddle:actionScaleByScaleDurationForeverTag (scale, duration, forever, tag)
	game.paddleActionScaleByScaleDurationForeverTag (self.index, scale, duration, forever, tag)
end

function Paddle:actionScaleToScaleDurationForeverTag (scale, duration, forever, tag)
	game.paddleActionScaleToScaleDurationForeverTag (self.index, scale, duration, forever, tag)
end

function Paddle:actionPulseFromScaleMinMaxDelayDurationTag (scaleMin, scaleMax, delay, duration, forever, tag)
	game.paddleActionPulseFromScaleMinMaxDelayDurationTag (self.index, scaleMin, scaleMax, delay, duration, forever, tag)
end

function Paddle:tintToColor (r, g, b, duration)
	game.paddleTintToColor (self.index, r, g, b, duration)
end

function Paddle:fadeToOpacity (o, duration)
	game.paddleFadeToOpacity (self.index, o, duration)
end

function Paddle:flash ()
	return game.paddleFlash (self.index)
end

-- attributes:label

function Paddle:setLabel (s)
	game.paddleSetLabel (self.index, s)
end

function Paddle:setLabelColor (r, g, b)
	game.paddleSetLabelColor (self.index, r, g, b)
end

function Paddle:setLabelOpacity (o)
	game.paddleSetLabelOpacity (self.index, o)
end

function Paddle:setLabelFont (name, size)
	game.paddleSetLabelFont (self.index, name, size)
end

-- attributes: topImage

function Paddle:setTopImage (path, x, y, w, h, anchorX, anchorY, opacity, rotation)
	game.paddleSetTopImage (self.index, path, x, y, w, h, anchorX, anchorY, opacity, rotation)
end

-- attributes:lights

function Paddle:lightsCount ()
	return game.paddleLightsCount (self.index)
end
	
function Paddle:lightVisible (lightIndex)
	return game.paddleLightVisible (self.index, lightIndex)
end
	
function Paddle:setLightVisible (lightIndex, b)
	game.paddleSetLightVisible (self.index, lightIndex, b)
end

function Paddle:lightPosition (lightIndex)
	return game.paddleLightPosition (self.index, lightIndex)
end
	
function Paddle:setLightPosition (lightIndex, x, y)
	game.paddleSetLightPosition (self.index, lightIndex, x, y)
end

function Paddle:lightSize (lightIndex)
	return game.paddleLightSize (self.index, lightIndex)
end
	
function Paddle:setLightSize (lightIndex, w, h)
	game.paddleSetLightSize (self.index, lightIndex, w, h)
end

function Paddle:lightPower (lightIndex)
	return game.paddleLightPower (self.index, lightIndex)
end
	
function Paddle:setLightPower (lightIndex, p)
	game.paddleSetLightPower (self.index, lightIndex, p)
end

-- attributes:ai

function Paddle:setAI (defensiveKind, defensiveConfig, offensiveKind, offensiveConfig)
	game.paddleSetAI (self.index, defensiveKind, defensiveConfig, offensiveKind, offensiveConfig)
end


function Paddle:isOffensiveSide ()
	return bit.band (self:flags (), kPaddleFlagOffensiveSide) == kPaddleFlagOffensiveSide
end

function Paddle:isDefensiveSide ()
	return bit.band (self:flags (), kPaddleFlagOffensiveSide) == 0
end

function Paddle:setDefensiveAI (config)
	if self.defensiveAI then
		self.defensiveAI:destroy ()
		self.defensiveAI = nil
	end
	self.defensiveAI = aiClasses[config.kind]:new (self, KAIDefensive, config)
	self.defensiveAI:init ()
end

function Paddle:setOffensiveAI (config)
	if self.offensiveAI then
		self.offensiveAI:destroy ()
		self.offensiveAI = nil
	end
	self.offensiveAI = aiClasses[config.kind]:new (self, KAIOffensive, config)
	self.offensiveAI:init ()
end

-- sounds

function Paddle:playSound (filename)
	game.audioPlaySoundForPaddle (self.index, filename)
end

function Paddle:playSoundLoop (filename)
	return game.audioPlaySoundLoopForPaddle (self.index, filename)
end

-- messages

function Paddle:showMessageEmoticonSound (msg, emoticon, sound)
	game.paddleShowMessageEmoticonSound (self.index, msg, emoticon, sound)
end

function Paddle:showMessageEmoticonDurationSound (msg, emoticon, duration, sound)
	game.paddleShowMessageEmoticonDurationSound (self.index, msg, emoticon, duration, sound)
end

function Paddle:showMessageEmoticonBMISizeDurationSound (msg, emoticon, bgColor, msgColor, icnColor, duration, sound)
	game.paddleShowMessageEmoticonBMISizeDurationSound (self.index, msg, emoticon, bgColor, msgColor, icnColor, duration, sound)
end

function Paddle:removeMessage ()
	game.paddleRemoveMessage (self.index)
end

-- timers

function Paddle:addTimer (name, timeout, callback, repeating)
	self.timers[name] = {
		origTimeout = timeout,
		timeout = timeout,
		callback = callback,
		repeating = repeating
	}
end

function Paddle:removeTimer (name)
	self.timers[name] = nil
end

function Paddle:updateTimers (dt)
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

-- SPECIAL FX

-- exit mode

function Paddle:fxExitInit (exitCallback)
	self.fxExit = {
		callback = exitCallback,
	}
	
	self.callbacks.onHit.fxExit = self.fxExitOnHit
	self.callbacks.onHit.updateHeroSpeed = nil
end

function Paddle:fxExitCleanup ()
	self.fxExit = nil
	self.callbacks.onHit.fxExit = nil
	self.callbacks.onHit.updateHeroSpeed = self.updateHeroSpeedWithSpeed
end

function Paddle:fxExitOnHit (heroIndex, side, x, y)
	game.levelSetTimeSuspended (true)
	self.fxExit.callback (self)
end

-- brick mode

function Paddle:fxBrickInit (maxHits, breakCallback)
	self.fxBrick = {
		maxHits = maxHits,
		hits = 0,
		callback = breakCallback,
	}
	
	self.callbacks.onHit.fxBrick = self.fxBrickOnHit
end

function Paddle:fxBrickCleanup ()
	self.fxBrick = nil
	self.callbacks.onHit.fxBrick = nil
end

function Paddle:fxBrickOnHit (heroIndex, side, x, y)
	self.fxBrick.hits = self.fxBrick.hits + 1
	self:flash ()
	if self.fxBrick.callback and self.fxBrick.hits >= self.fxBrick.maxHits then
		self.fxBrick.callback (self)
	end
end

-- bonus mode

function Paddle:fxBonusInit (score, sound, hide, bonusCallback)
	self.fxBonus = {
		score = score,
		sound = sound,
		hide = hide,
		callback = bonusCallback,
	}
	
	self.callbacks.onHit.fxBonus = self.fxBonusOnHit
end

function Paddle:fxBonusCleanup ()
	self.fxBonus = nil
	self.callbacks.onHit.fxBonus = nil
end

function Paddle:fxBonusOnHit (heroIndex, side, x, y)
	if self.fxBonus.score ~= 0 then
		scoreAdd (self.fxBonus.score, self.fxBonus.sound)
	end
		
	if self.fxBonus.hide then
		self:setEnabled (false)
	end
	
	if self.fxBonus.callback then
		self.fxBonus.callback (self, side, x, y)
	end
end

-- resize mode

function Paddle:fxResizeInit (minWidth, minHeight, maxWidth, maxHeight, speed)
	self.fxResize = {
		minWidth = game.scaleX (minWidth),
		minHeight = game.scaleY (minHeight),
		maxWidth = game.scaleX (maxWidth),
		maxHeight = game.scaleY (maxHeight),
		speed = speed,
		direction = 1
	}
	
	self.callbacks.onUpdate.fxResize = self.fxResizeOnUpdate
end

function Paddle:fxResizeCleanup ()
	self.fxResize = nil
	self.callbacks.onUpdate.fxResize = nil
end

function Paddle:fxResizeOnUpdate (dt)
	local i = 0
	local w, h = self:size ()
	local s = (self.fxResize.direction * self.fxResize.speed * dt)
	
	if not s then return end
	
	w = w + s
	h = h + s

	local sx = s/2
	local sy = s/2
	
	if self.fxResize.direction > 0 then
		if w >= self.fxResize.maxWidth then
			i = i + 1
			w = self.fxResize.maxWidth
			sx = 0
		end

		if h >= self.fxResize.maxHeight then
			i = i + 1
			h = self.fxResize.maxHeight
			sy = 0
		end
	elseif self.fxResize.direction < 0 then
		if w <= self.fxResize.minWidth then
			i = i + 1
			w = self.fxResize.minWidth
			sx = 0
		end

		if h <= self.fxResize.minHeight then
			i = i + 1
			h = self.fxResize.minHeight
			sy = 0
		end
	end
	
	self:setSize (w, h)
	
	local x, y = self:position ()
	self:setPosition (x - sx, y - sy)
	
	if i >= 2 then
		self.fxResize.direction = -1 * self.fxResize.direction
	end
end

-- END SPECIAL FX

-- setup

function Paddle:init ()
	-- no UI or other entities access here
	self.timers = {}
	self.callbacks = {
		onUpdate = {},
		onHit = {
			updateHeroSpeed = self.updateHeroSpeedWithSpeed,
		},
	}
end

function Paddle:destroy ()
	self.timers = {}
	self.callbacks = {}
	
	if self.offensiveAI then
		self.offensiveAI:destroy ()
		self.offensiveAI = nil
	end
	if self.defensiveAI then
		self.defensiveAI:destroy ()
		self.defensiveAI = nil
	end
end

function Paddle:setup ()
	-- this method is called after every entity has been initialized
	-- here we can access level UI entities
	if self.defensiveAI then
		self.defensiveAI:setup ()
	end
	if self.offensiveAI then
		self.offensiveAI:setup ()
	end
	
end

function Paddle:new (idx)
	local newPaddle = {
		index = idx,
		offensiveAI = nil,
		defensiveAI = nil,
	}
	setmetatable (newPaddle, Paddle_mt)

	return newPaddle
end


-- global functions

function paddleUpdate (index, dt)
	level.paddles[index]:update (dt)
end

function paddleUpdateAI (index, dt)
	level.paddles[index]:updateAI (dt)
end

function paddleOnHit (index, heroIndex, collisionSide, x, y)
	level.paddles[index]:onHit (heroIndex, collisionSide, x, y)
end

function paddleOnHeroInProxymityArea (index, heroIndex)
	level.paddles[index]:onHeroInProxymityArea (heroIndex)
end

function paddleOnEnter (index)
	level.paddles[index]:onEnter ()
end

function paddleOnExit (index)
	level.paddles[index]:onExit ()
end

function paddleApplyProximityInfluenceToHero (index, heroIndex, sx, sy, dist)
	level.paddles[index]:applyProximityInfluenceToHero (heroIndex, sx, sy, dist)
end

function paddleOnSideToggled (index, isDefensiveSide)
	level.paddles[index]:onSideToggled (isDefensiveSide)
end

function paddleTouchHandler (index, handler, x, y, tapCount)
	level.paddles[index][handler] (level.paddles[index], x, y, tapCount)
end

function paddleOnClick (index)
	level.paddles[index]:onClick ()
end


