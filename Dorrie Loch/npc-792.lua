local npc = {}

local id = NPC_ID

local npcManager = require("npcManager")
local lineguide = require("lineguide")
lineguide.registerNpcs(id)

local table = table
local insert = table.insert
local remove = table.remove

local math = math
local floor = math.floor
local max = math.max

local ipairs = ipairs

local drawBox = Graphics.drawBox

npcManager.setNpcSettings({
	id = id,
	
	gfxheight = 24,
	height = 24,
	width = 18,
	gfxwidth = 18,
	
	frames = 1,
	
	nogravity = true,
	noblockcollision = true,
	
	jumphurt = true,
	nohurt = true,
	
	noiceball = true,
	noyoshi = true,
	
	maxWidth = 96,
	
	platformId = id + 1,
	
	acceleration = 0.075,
})

local npcutils = require 'npcs/npcutils'

local drawNPC = npcutils.drawNPC

local function isColliding(a,b)
   if ((b.x >= a.x + a.width) or
	   (b.x + b.width <= a.x) or
	   (b.y >= a.y + a.height) or
	   (b.y + b.height <= a.y)) then
		  return false 
   else return true
	   end
end
	
local texture

function npc.onDrawNPC(v, idx)
	if v.despawnTimer <= 0 then return end
	
	local cfg = NPC.config[id]
	local data = v.data._basegame
	local settings = v.data._settings
	
	if not data.init then return end
	
	texture = texture or Graphics.sprites.npc[id].img

	drawNPC(v, {
		texture = texture,
		
		xOffset = settings.width,

		priority = -46,
		frame = 2,
	})

	drawBox{
		texture = texture,
		
		x = v.x + cfg.width,
		y = v.y,
		sourceY = cfg.height,
		sourceHeight = cfg.height,
		
		width = settings.width - cfg.width,
		
		priority = -46,
		sceneCoords = true,
	}
		
	local platforms = data.platforms or data.lines
	
	for index, platform in ipairs(platforms) do
		if platform and platform.isValid then
			local frame = cfg.height * 3
			local x = v.x

			if index == 2 then
				x = v.x + settings.width + cfg.width - 4
			end
			
			local distance = (v.y + cfg.height) - platform.y
			
			drawBox{
				texture = texture,
				
				x = x,
				y = floor(v.y + cfg.height),
				sourceY = frame,
				sourceHeight = cfg.height,
				
				height = -distance,
				
				priority = -46,
				sceneCoords = true,
			}
		end
	end
end

local function spawnPlatform(v, ...)
	local n = NPC.spawn(...)
	n.ai1 = 1
	n.layerName = v.layerName
	n.friendly = v.friendly
	
	local forcedState = v:mem(0x138, FIELD_WORD)
	local forcedTimer1 = v:mem(0x13C, FIELD_DFLOAT)
	local forcedTimer2 = v:mem(0x144, FIELD_WORD)
	
	n:mem(0x138, FIELD_WORD, forcedState)
	n:mem(0x13C, FIELD_WORD, forcedTimer1)
	n:mem(0x144, FIELD_WORD, forcedTimer2)
	
	return n
end

local function init(v, data, settings, cfg)
	settings.activeLineguide = settings.activeLineguide or 0
	settings.len = settings.len or 96
	settings.width = settings.width or 96
	settings.noSaving = settings.noSaving or false
	settings.noBreak = settings.noBreak or false
	
	if data.lineguide and settings.activeLineguide ~= 0 then
		data.lineguide.lineSpeed = 0
	end
	
	data.platforms = {}

	local platformId = cfg.platformId
	local platformCfg = NPC.config[platformId]
	local platformW = platformCfg.width

	local x = v.x
	local y = v.y
	local h = settings.len
	
	local saved = data.saved
	
	if saved and #saved > 0 then
		for ind, saved in ipairs(data.saved) do
			insert(data.platforms, spawnPlatform(v, platformId, saved.x, saved.y))
		end
	else
		insert(data.platforms, spawnPlatform(v, platformId, x - platformW * 0.5, y + h))
		insert(data.platforms, spawnPlatform(v, platformId, x + settings.width - 16, y + h))
	end
	
	data.width = settings.width
	data.height = settings.len
	data.touched = false
end

local function platformsBreak(v, platforms, data)
	data.lines = {}
	
	for index = 1, #platforms do
		local platform = platforms[index]
		platform.ai1 = 2
		platform.speedX = 0
		platform.speedY = 0
		
		insert(data.lines, {
			y = platform.y,
			width = platform.width,
			isValid = true,
		})
	end
	
	triggerEvent(v.deathEventName)
	
	data.platforms = nil
	data.dead = true
end

local function platformDistance(platform, v)
	return -((v.y + v.height) - platform.y)
end

local function platformsAi(v, data, settings, cfg, layer)
	local platforms = data.platforms
	if platforms == nil or #platforms == 0 then return end
	
	local acceleration = cfg.acceleration
	
	local firstPlatform = platforms[1]
	local secondPlatform = platforms[2]
	
	if not firstPlatform.isValid then return end
	if not secondPlatform.isValid  then return end
	
	local firstDistance = platformDistance(firstPlatform, v)
	local secondDistance = platformDistance(firstPlatform, v)
	
	data.height = max(firstDistance, secondDistance)
	
	for _, p in ipairs(Player.get()) do
		local standingNPC = p.standingNPC
		
		if standingNPC and not Defines.levelFreeze then
			if not data.touched and (standingNPC == firstPlatform or standingNPC == secondPlatform) then
				if data.lineguide and data.lineguide.lineSpeed == 0 then
					data.lineguide.lineSpeed = 2
				end
				
				data.touched = true
			end
			
			if standingNPC == firstPlatform then
				firstPlatform.speedY = firstPlatform.speedY + acceleration
				secondPlatform.speedY = secondPlatform.speedY - acceleration
			elseif standingNPC == secondPlatform then
				firstPlatform.speedY = firstPlatform.speedY - acceleration
				secondPlatform.speedY = secondPlatform.speedY + acceleration
			else
				firstPlatform.speedY = 0
				secondPlatform.speedY = 0
			end
		else
			firstPlatform.speedY = 0
			secondPlatform.speedY = 0
		end
	end

	for index, platform in ipairs(platforms) do
		platform.despawnTimer = v.despawnTimer

		local x = v.x - platform.width * 0.5
		if index == 2 then
			x = v.x + data.width - 16
		end
		
		platform.x = x 
		platform.y = platform.y + layer.speedY + v.speedY

		if v:mem(0x138, FIELD_WORD) == 4 then
			if v:mem(0x144, FIELD_WORD) == 1 then
				platform.y = platform.y - 1
			end
		end
		
		if platform.y < v.y + v.height then
			platform.y = v.y + v.height
			
			if not settings.noBreak then
				return platformsBreak(v, platforms, data)
			else
				if index == 2 then
					firstPlatform.speedY = 0
				else
					secondPlatform.speedY = 0
				end
			end
		end
	end
end

local function inCamera(v, data, settings, cfg)
	local platformId = cfg.platformId
	local platformCfg = NPC.config[platformId]
	local platformW = platformCfg.width
	
	local zone = {
		x = v.x - platformW,
		y = v.y,
		width = settings.width + platformW + 64,
		height = (data.height or settings.len) + platformCfg.height + 32,
	}
	
	for _,cam in ipairs(Camera.get()) do
		if isColliding(cam, zone) then
			return true
		end
	end
end

local function beforeDespawning(v, data, settings, cfg)
	data.saved = {}
	
	for _, platform in ipairs(data.platforms) do
		if platform and platform.isValid then
			insert(data.saved, {y = platform.y, x = platform.x})
			platform:kill(9)
		end
	end

	data.platforms = nil -- clear existing
	data.init = nil
end

function npc.onTickEndNPC(v)
	local cfg = NPC.config[id]
	local data = v.data._basegame
	local settings = v.data._settings
	
	local layer = v.layerObj
	v.x = v.x + layer.speedX
	v.y = v.y + layer.speedY
	
	if v.despawnTimer <= 0 and data.platforms then
		if not settings.noSaving then
			beforeDespawning(v, data, settings, cfg)
		end
	elseif v.despawnTimer <= 0 and data.dead then
		if settings.despawn then
			return v:kill(9)
		elseif settings.respawn then
			data.width = nil
			data.height = nil
			data.init = nil
			data.lines = nil
			data.dead = nil
			data.touched = nil
		end
	end
	
	if not inCamera(v, data, settings, cfg) then -- a bit customized spawning
		if data.platforms and settings.noSaving then
			for _, platform in ipairs(data.platforms) do
				if platform and platform.isValid then
					platform:kill(9)
				end
			end
			
			return v:kill(9)
		end
		
		return 
	else
		v.despawnTimer = 180
	end
	
	if not data.init then
		init(v, data, settings, cfg)
		data.init = true
	end

	platformsAi(v, data, settings, cfg, layer)
	
	local lines = data.lines
	if lines then
		for index, line in ipairs(lines) do
			local x = v.x - line.width * 0.5
			
			if index == 2 then
				x = v.x + data.width - 16
			end	
			
			line.x = x
			line.y = (line.y + layer.speedY + v.speedY)
		end
	end
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onDrawNPC')
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc