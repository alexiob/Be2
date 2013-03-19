-- ai.lua

aiClasses = {}

kAIDefensive = 1
kAIOffensive = 2

AI = {}
local AI_mt = {__index = AI}

-- event handlers

function AI:update (dt)
	self:updateTimers (dt)
end

function AI:onEnter ()
	-- called when paddle becomes visible
end

function AI:onExit ()
	-- called when paddle becomes NOT visible
end

function AI:onHit (heroIndex, side, x, y)
end

-- timers

function AI:addTimer (name, timeout, callback, repeating)
	self.timers[name] = {
		origTimeout = timeout,
		timeout = timeout,
		callback = callback,
		repeating = repeating
	}
end

function AI:removeTimer (name)
	self.timers[name] = nil
end

function AI:updateTimers (dt)
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

function AI:init ()
	-- no UI or other entities access here
	self.timers = {}
	self.config = {}
	self.data = {}
end

function AI:destroy ()
	self.paddle = nil
	self.timers = {}
	self.config = {}
	self.data = {}
end

function AI:setup ()
	-- this method is called after every entity has been initialized
	-- here we can access level UI entities
end

function AI:new (paddle, mode, config)
	local newAI = {
		paddle = paddle,
		mode = mode,
		config = config
	}
	setmetatable (newAI, AI_mt)
	
	return newAI
end

aiClasses.generic = AI

----------------------------------------------------------------------------------

AIPerfectVertical = {}
local AIPerfectVertical_mt = {__index = AIPerfectVertical}

UPDATE_TIMEOUT = 0.1
MAX_ACCELERATION = 40
DECELERATION = 0.1
MOMENTUM = 0.6

function AIPerfectVertical:update (dt)
	AI.update (self, dt)
	
	self.nextUpdate = self.nextUpdate - dt
	if self.nextUpdate <= 0 then
		self.nextUpdate = self.config.updateTimeout
		
		sx, sy = self.paddle:speed ()
		ax, ay = self.paddle:acceleration ()
		px, py = self.paddle:position ()
		pw, ph = self.paddle:size ()
		dy = ph * (1 / randomIntRange (5, 7))
		
		hpx, hpy = mainHero:position ()
		hpw, hph = mainHero:size ()

		if py + ph - dy < hpy then
			if ay < 0 then ay = ay * (self.config.deceleration * dt) end
			ay = ay + (self.config.maxAcceleration * dt)
			if sy < 0 then sy = sy * (self.config.momentum * dt) end
		elseif py + dy > hpy + hph then
			if ay > 0 then ay = ay * (self.config.deceleration * dt) end
			ay = ay - (self.config.maxAcceleration * dt)
			if sy > 0 then sy = sy * (self.config.momentum * dt) end
		else
			ay = ay * (self.config.deceleration * dt)
			sy = sy * (self.config.momentum * dt)
		end

		if (ay > self.config.maxAcceleration) then ay = self.config.maxAcceleration end
		if (ay < -self.config.maxAcceleration) then ay = -self.config.maxAcceleration end
		
		self.paddle:setAcceleration (ax, ay)
		self.paddle:setSpeed (sx, sy)
	end
end

function AIPerfectVertical:init ()
	AI.init (self)

	self.nextUpdate = 0

	defaultConfig = {
		updateTimeout = UPDATE_TIMEOUT,
		maxAcceleration = MAX_ACCELERATION,
		deceleration = DECELERATION,
		momentum = MOMENTUM
	}
	
	for k, v in pairs (defaultConfig) do
		if self.config[k] == nil then
			self.config[k] = v
		end
	end
end

function AIPerfectVertical:new (paddle, mode, config)
	local newAI = {
		paddle = paddle,
		mode = mode,
		config = config
	}
	setmetatable (newAI, AIPerfectVertical_mt)
	return newAI
end

setmetatable (AIPerfectVertical, {__index = AI})

aiClasses.perfectVertical = AIPerfectVertical
