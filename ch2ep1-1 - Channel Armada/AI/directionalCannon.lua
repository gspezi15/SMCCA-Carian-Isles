local dirCannon = {}

--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
--NPCutils for rendering --
local npcutils = require("npcs/npcutils")

-- NPC IDs in case I need them --
local npcIDs = {}

--Register events
function dirCannon.register(id, cannons)
	npcManager.registerEvent(id, dirCannon, "onTickNPC")
    npcManager.registerEvent(id, dirCannon, "onDrawNPC")
    
    npcIDs[id] = cannons
end

local function booltoNumber(bool)
	if bool then return 1 else return 0 end
end

function animationHandling(v)
	local data = v.data

	local cfg = data._settings

	-- Custom Animations: Variables --
	data.currentFrame = data.currentFrame or 1
	data.frameTimer = data.frameTimer or NPC.config[v.id].framespeed

	if not data.animTable and cfg.fOptions.frameTable ~= "" then
		-- Custom Animations: Getting the anim table --
		local myFunc,errorString = loadstring("return {".. tostring(cfg.fOptions.frameTable).. "}")

		if myFunc ~= nil then
			data.animTable = myFunc()
		else
			error("Could not parse data: ".. errorString)
		end
	end
	
	-- Custom Animations: Handling --
	data.frameTimer = data.frameTimer - 1

	if #data.animTable <= 1 then return end

	if data.frameTimer <= 0 then
		if data.currentFrame < #data.animTable then
			data.currentFrame = data.currentFrame + 1
		else
			data.currentFrame = 1
		end
		data.frameTimer = NPC.config[v.id].framespeed
	end
end

function dirCannon.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		return
	end
	
	-- Custom settings --
	local cfg = data._settings

	-- Defining some data variables --
	data.shootTimer = data.shootTimer or lunatime.toTicks(cfg.aOptions.roundDelay)
	data.shotsFired = data.shotsFired or 0

	data.sprSizex = math.max(data.sprSizex or 1, 1) or 1
	data.sprSizex = data.sprSizex - 0.05
	data.sprSizey = math.max(data.sprSizey or 1, 1) or 1
	data.sprSizey = data.sprSizey - 0.05

	data.angle = data.angle or cfg.bOptions.shootAngle
	if data.angle > 360 then
		data.angle = data.angle - 360
	end

	-- The 360 Cannon --
	local ballsPShot = cfg.bOptions.shootAmount or npcIDs[v.id]

	-- Calculating angles in vectors and center of NPC --
	data.vAngle = vector(0, -1):rotate(data.angle)
	data.NPCenter = vector(v.x + v.width/2, v.y + v.height/2)

	-- Performance code by MDA, this thing makes sure that the cannon won't shoot if there's more than a set amount of projectiles onscreen --
	local count = 0
	local dontSpawn = false

	if cfg.aOptions.maxProjectiles > 0 then
		for _,npc in NPC.iterate(v.ai1) do
			if npc.despawnTimer > 0 and not npc.isGenerator and not npc.friendly then
				count = count + 1

				if count >= cfg.aOptions.maxProjectiles then
					dontSpawn = true
					break
				end
			end
		end
	end

	-- Handling shooting --
	if v.ai1 <= 0 then v.ai1 = 1 end
	data.shootTimer = data.shootTimer - 1
	if not v.friendly and data.shootTimer <= 0 and not dontSpawn then
		for i = 1, ballsPShot, 1 do
			-- Performance --
			if cfg.aOptions.maxProjectiles > 0 and count + i >  cfg.aOptions.maxProjectiles then break end

			-- Spawning the NPC --
			local otherAng = data.vAngle:rotate(i*360/ballsPShot)

			v1 = NPC.spawn(v.ai1, data.NPCenter.x + (otherAng.x * v.width/3), data.NPCenter.y + (otherAng.y * v.height/3), v.section, false, true)

			v1.speedX, v1.speedY = otherAng.x * cfg.bOptions.shootSpeed, otherAng.y * cfg.bOptions.shootSpeed

			-- Passing special data values --
			v1.data.directionalCannonNPCValues = {}
			v1.data.directionalCannonNPCValues.speed = cfg.bOptions.shootSpeed
			v1.data.directionalCannonNPCValues.angle = data.angle+(i*360/ballsPShot)
			v1.data.directionalCannonNPCValues.index = i

			-- Spawning smoke --
			a1 = Animation.spawn(131, v1.x + (data.vAngle.x * 16), v1.y + ((data.vAngle.y * 16)))
			a1.speedX, a1.speedY = v1.speedX, v1.speedY
		end

		if data.shotsFired >= cfg.aOptions.shotsPerRound - 1 then
			data.shootTimer = lunatime.toTicks(cfg.aOptions.roundDelay)
			data.shotsFired = 0
		else
			data.shootTimer = lunatime.toTicks(cfg.aOptions.shootDelay)
			data.shotsFired = data.shotsFired + 1
		end

		SFX.play(22)

		if cfg.fOptions.exPANDx then
			data.sprSizex = 1.5
		end

		if cfg.fOptions.exPANDy then
			data.sprSizey = 1.5
		end
	end

	-- Aiming and Constant Rotation --
	if cfg.aOptions.pAim then
		local cPlayer = Player.getNearest(data.NPCenter.x, data.NPCenter.y)
		data.chVector = vector((cPlayer.x+cPlayer.width/2) - (data.NPCenter.x), (cPlayer.y+cPlayer.height/2) - (data.NPCenter.y)) -- Thanks 8luestorm for this chunk lol
		data.angle = math.deg(math.atan2(data.chVector.y, data.chVector.x)) + 90
	else
		data.angle = data.angle + cfg.aOptions.constantRotation
	end

	-- Custom Animation Stuff --
	animationHandling(v)

	-- Layer Movement --
	npcutils.applyLayerMovement(v)
end

function dirCannon.onDrawNPC(v)
	local data = v.data

	if not data.NPCenter or not data._settings.aOptions or v:mem(0x40, FIELD_BOOL) then return end

	-- Accessing custom settings --
	local cfg = data._settings

	-- Creating the sprite --
	data.img = data.img or Sprite{x = 0, y = 0, pivot = vector(0.5, 0.5), frames = NPC.config[v.id].frames, texture = Graphics.sprites.npc[v.id].img}

	-- Setting some properties --
	data.img.x, data.img.y = data.NPCenter.x, data.NPCenter.y
	data.img.transform.scale = vector(data.sprSizex, data.sprSizey)
	data.img.rotation = data.angle

	-- Drawing --
	data.img:draw{frame = data.animTable[data.currentFrame] or 1, sceneCoords = true, priority = -45}

	npcutils.hideNPC(v)
end

return dirCannon