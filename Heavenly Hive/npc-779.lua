--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 38,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 3,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=778,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below

local genID = 0

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = data._settings
	
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

		v.noblockcollision = true

		data.moveTimer = 0

		data.beeGeneratorID = genID
		genID = genID + 1

		if not settings.isSpawner and data.beeGeneratorID == nil then
			v.y = v.y - 16
		end

		data.dead = false
		data.deadTimer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end

	npcutils.applyLayerMovement(v)

	if not settings.isSpawner then

		if not data.dead then

			local plr = npcutils.getNearestPlayer(v)
			local angle = math.atan2(v.y - plr.y, v.x - plr.x)

			npcutils.faceNearestPlayer(v)

			data.moveTimer = data.moveTimer + 1

			if v:mem(0x138, FIELD_WORD) ~= 0 then
				data.moveTimer = 149
			end

			if (settings.moveInstant or data.moveTimer >= 150) and v:mem(0x138, FIELD_WORD) == 0 then
				v.y = v.y + math.cos(angle+math.rad(90))
			end

			if data.beeYPos and v.y >= data.beeYPos.position.y - 32 and v.y + v.height <= data.beeYPos.position.y + 12 + 32 then
				if (settings.moveInstant or data.moveTimer >= 150) and data.moveTimer % 4 == 0 then
					v.speedY = math.sin(data.moveTimer/20)
					if math.floor(math.abs(v.speedY)-0.8) <= 0 then
						v.speedX = v.direction*0.75*4
					end
				end
			else
				if (settings.moveInstant or data.moveTimer >= 150) and data.moveTimer % 4 == 0 then
					if v.y + v.height <= data.beeYPos.position.y and v.y + v.height - 1*0.75*2 < data.beeYPos.position.y then
						v.speedY = 1*0.75*1
					elseif v.y >= data.beeYPos.position.y + 12 and v.y + 1*0.75*2 > data.beeYPos.position.y + 12 then
						v.speedY = -1*0.75*1
					end
					v.speedX = v.direction*0.75*4
				end
			end
		else

			v.friendly = true
			v.dontMove = true

			v.noblockcollision = false

			data.deadTimer = data.deadTimer + 1
			if data.deadTimer >= settings.recoverTime then
				data.deadTimer = 0
				v.noblockcollision = true
				v.friendly = false
				v.dontMove = false
				data.dead = false
			else
				v.speedY = 4
			end
		end
	else
		v.friendly = true
		v.dontMove = true

		local alreadySpawned = false

		for _,npc in ipairs(NPC.get(npcID)) do
			if not npc.data._settings.isSpawner then
				if npc.data.beeGeneratorID ~= nil and npc.data.spawnedByGen and npc.data.theBeeGeneratorThatGeneratedThisBee == data.beeGeneratorID then
					alreadySpawned = true
					break
				end
			end
		end

		data.spawnTimer = (data.spawnTimer or 0) + 1

		if alreadySpawned then
			data.spawnTimer = 0
		end

		if not alreadySpawned and data.spawnTimer >= settings.spawnTime then

			data.spawnTimer = 0

			local bee = NPC.spawn(npcID, v.x, v.y, v.section)
			bee.data.spawnedByGen = true
			bee.data.theBeeGeneratorThatGeneratedThisBee = data.beeGeneratorID
			bee.data._settings.moveInstant = settings.moveInstant
		end
	end
	
end

function sampleNPC.onDrawNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end

	local data = v.data
	local settings = data._settings

	if not data.initialized then return end

	local txture = Graphics.loadImageResolved("BeeEyes.png")
	data.eyes = data.eyes or Sprite{texture = txture, frames = 2}

	data.eyes.position = vector(v.x, v.y)

	if settings.isSpawner then

		local alreadySpawned = false

		for _,npc in ipairs(NPC.get(npcID)) do
			if not npc.data._settings.isSpawner then
				if npc.data.beeGeneratorID ~= nil and npc.data.spawnedByGen and npc.data.theBeeGeneratorThatGeneratedThisBee == data.beeGeneratorID then
					alreadySpawned = true
					break
				end
			end
		end

		if not alreadySpawned then
			data.eyes:draw{sceneCoords = true, frame = math.floor(math.sin((lunatime.tick()-10)/8)+0.5)+1, priority = -46}
		end
		npcutils.hideNPC(v)
	else
		if not data.dead then
			if v.animationFrame == (2 + (v.direction+1)*1.5) then
				v.animationFrame = (v.direction+1)*1.5
			end
		else
			v.direction = data.lastDir

			settings.recoverTime = settings.recoverTime or 240

			if data.deadTimer < settings.recoverTime - 120 then
				v.animationFrame = 2+1.5*(v.direction+1)
			else
				v.animationFrame = math.floor(math.abs(math.floor(math.sin(lunatime.tick()/4))*2)+0.5) + 1.5*(v.direction+1)
			end
		end
	end

	data.beeYPos = Sprite{texture = txture}

	local plr = npcutils.getNearestPlayer(v)
	data.beeYPos.position = vector(v.x, plr.y - 4)

end

function sampleNPC.onNPCHarm(eventToken, v, harmType, culpritOrNil)
	if v.id ~= npcID then return end

	local data = v.data

	if harmType == HARM_TYPE_JUMP then
		eventToken.cancelled = true

		SFX.Play(57)
		data.dead = true
		data.lastDir = v.direction
	end
end

--Gotta return the library table!
return sampleNPC