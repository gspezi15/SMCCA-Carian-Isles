local grafZ = {}

local npcManager = require("npcManager")
local rng = require("rng")
local particles = require("particles")

local trails = {}

local STATE_MOVE = 0
local STATE_STILL = 1

local gfx = Graphics.loadImageResolved("sparks.png")

grafZ.sharedSettings = {
	--lua settings
	forcespawn = false,
	setpos = true,
	relativecoords = true,
	blocks = true,
	seconds = true,
	invert = true,
	absolutetime = false,
    parametric = true,
    ribbon = false
}

local proxytbl = {
	rng = rng,
	lunatime = lunatime,
	e = 2.718281828459,
	toBlocks = function(pixels)
		return pixels / 32
	end,
	toPixels = function(blocks)
		return blocks * 32
	end
}

local proxymt = {
	__index = function(t, k)
		return lunatime[k] or rng[k] or math[k] or _G[k]
	end,
	__newindex = function() end
}
setmetatable(proxytbl, proxymt)

function grafZ.register(config)
	npcManager.registerEvent(config.id, grafZ, "onStartNPC")
    npcManager.registerEvent(config.id, grafZ, "onTickNPC")
	 npcManager.registerEvent(config.id, grafZ, "onTickEndNPC")
	 npcManager.registerEvent(config.id, grafZ, "onDrawNPC")
    npcManager.setNpcSettings(table.join(config, grafZ.sharedSettings))
end

function grafZ.onInitAPI()
	registerEvent(grafZ, "onDraw")
end

local funcCache = {}

local parse -- Local outside for recursion
function parse(msg, recurse)
	if funcCache[msg] then
		return funcCache[msg]
	end
	local str = [[
		return function(npc, self, v, x, y, t)
			return {]] .. msg .. [[}
		end
	]]
	local chunk, err = load(str, str, "t", proxytbl)
	if chunk then
		local func = chunk()
		funcCache[msg] = func
		return func
	elseif not recurse then
		-- attempt adding line separators
		-- this might further break a grafZ setup that's already invalid
		-- but that really shouldn't matter
		return parse(msg:gsub("\r?\n", ";\n"), true)
	else
		return nil, err
	end
end

local function call(npc)
	local data = npc.data._basegame
	local settings = NPC.config[npc.id]
	
	local xPos = npc.x
	local yPos = npc.y
	-- If using relative coords, subtract spawn coords
	if settings.relativecoords then
		local spawnX = data.origin.x
		local spawnY = data.origin.y
		xPos = xPos - spawnX
		yPos = yPos - spawnY
	end
	-- If using blocks, divide by 32
	if settings.blocks then
		xPos = xPos / 32
		yPos = yPos / 32
	end
	-- If flipping the y-axis, do so
	if settings.invert then
		yPos = -yPos
	end
	
	local timer 
	if settings.absolutetime then	
		timer = lunatime.tick()
	else
		timer = data.timer
	end
	-- If using seconds, convert to seconds
	if settings.seconds then
		timer = lunatime.toSeconds(timer)
	end
	
	local tbl = data.func(npc, npc, npc, xPos, yPos, timer)

	local x = tbl.x or 0
	local y = tbl.y or tbl[1] or 0
	local speedX = tbl.speedX or 0
	local speedY = tbl.speedY or 0
	
	-- If using blocks, multiply by 32
	if settings.blocks then
		x = x * 32
		y = y * 32
		speedX = speedX * 32
		speedY = speedY * 32
	end
	-- If using seconds, reduce speed accordingly
	if settings.seconds then
		speedX = lunatime.toSeconds(speedX)
		speedY = lunatime.toSeconds(speedY)
	end
	-- If flipping the y-axis, flip the returned value
	if settings.invert then
		y = -y
		speedY = -speedY
	end
	
	-- If the speed variables aren't in the table, erase them here
	if not tbl.speedX then
		speedX = nil
	end
	if not tbl.speedY then
		speedY = nil
	end
	
	return x, y, speedX, speedY
end

function grafZ:onStartNPC()
	local data = self.data._basegame
	local settings = self.data._settings
	local func, err = parse(settings.parserInput or "")
	if not err then
		data.func = func
	end
	data.origin = {
		x = self:mem(0xA8, FIELD_DFLOAT),
		y = self:mem(0xB0, FIELD_DFLOAT)
	}
	
	if NPC.config[self.id].ribbon then
		local trail = particles.Ribbon(0, 0, Misc.resolveFile("particles/r_trail.ini"))
		trail:Attach(self)
		trail:setParam("lifetime", 5)
		trails[self] = trail
	end
end

function grafZ:onTickEndNPC()
	local data = self.data
	
	--If despawned
	if self.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_MOVE
		data.animTimer = 0
		data.hurtTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_MOVE
		data.animTimer = data.animTimer or 0
		data.hurtTimer = data.hurtTimer or 0
	end
	
	if data.state == STATE_MOVE then
		data.animTimer = data.animTimer + 1
		self.animationFrame = math.floor(data.animTimer / 8 % 8)
		
		self.spawnX = self.x
		self.spawnY = self.y
		
		--If touching a player
		if Colliders.collide(player, self) and player.forcedState == 2 and not self.friendly and player:mem(0x140,FIELD_WORD) == 0 --[[changing powerup state]] and player.deathTimer == 0 --[[already dead]] and not Defines.cheat_donthurtme then
			data.state = STATE_STILL
		end
		
	else
		--Stop animating and moving for a second
		self.animationFrame = 3
		data.animTimer = 32
		data.hurtTimer = data.hurtTimer + 1
		if data.hurtTimer > 64 then
			data.hurtTimer = 0
			data.state = STATE_MOVE
		end
		
		self.x = self.spawnX
		self.y = self.spawnY
	end
end

function grafZ:onTickNPC()
	if Defines.levelFreeze then return end
	local data = self.data._basegame
	local data2 = self.data
	local s = self.data._settings
	local settings = NPC.config[self.id]
	data.timer = data.timer or 0
	if settings.forcespawn then
		self:mem(0x12A, FIELD_WORD, 180)
	end
	if self:mem(0x12A, FIELD_WORD) > 0 then
		if type(data.func) == "function" then
			local x, y, speedX, speedY = call(self)
			if speedY then
				self.speedY = speedY
			else
				if settings.setpos then
					self.y = y + data.origin.y
				else
					local relativeY = self.y - data.origin.y
					self.speedY = y - relativeY
				end
			end
			if settings.parametric then
				if speedX then
					self.speedX = speedX
				else
					if settings.setpos then
						local oldX = self.x
						self.x = x + data.origin.x
						if self.x > oldX then
							self.direction = DIR_RIGHT
						elseif self.x < oldX then
							self.direction = DIR_LEFT
						end
					else
						local relativeX = self.x - data.origin.x
						self.speedX = x - relativeX
					end
				end
			end
		elseif s.parserInput ~= nil and s.parserInput ~= "" then
			grafZ.onStartNPC(self)
		end
		if data2.state == STATE_MOVE then
			data.timer = data.timer + 1
		end
	else
		data.timer = 0
	end
end

function grafZ:onDrawNPC()
	--Don't act during time freeze
	if Defines.levelFreeze then return end

	local data = self.data

	if not data.initialized then return end
	
	data.sparkFrames = data.sparkFrames or Sprite{texture = gfx, frames = 3}

	data.sparkFrames.position = vector(self.x - self.width / 2 - 1, self.y - self.height / 2 + 1)
	
	if data.state == STATE_MOVE then
		data.sparkFrames:draw{sceneCoords = true, frame = math.floor(lunatime.tick() / 6) % 3 + 1, priority = -50}
	end
end

function grafZ.onDraw()
	for npc, trail in pairs(trails) do
		if npc.isValid or trail:Count()>0 then
			trail:Draw(-60)
		else
			trails[npc] = nil
		end
	end
end

return grafZ