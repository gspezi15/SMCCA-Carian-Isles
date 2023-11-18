--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

-- Treat it like a percentage.
-- If the game's TPS (ticks per second, SMBX's frames per second), in %, is lower than this% of the max TPS it'll stop creating new afterimages.
-- Acts as sort of a lag prevention machine; you have to have a lot of these on screen at once to be able to reach this limit but its still nice to have
-- Example: if the current TPS is 29, the max TPS is 60 and the threshold is 50%,
-- It'll stop creating new afterimages until the TPS is higher than 29.
-- Not the best solution out there, though. Could be improved upon.
local afterImageThreshold = 90

-- The maximum amount of after images per spikeball.
-- If you put, say, 10 after images in here, no npc will have more than 10 after images stored.
local maxAfterImages = 999

-- The time it takes for a new after image to be created.
-- Lower number means more after images, at the cost of performance.
local afterImageInterval = 4

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 41,
	gfxwidth = 41,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 19,
	height = 20,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = false,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
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
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onStart")
end

function sampleNPC.onTickNPC(v)
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
		--Handling
	end

end

function sampleNPC.onStart()
	afterImageInterval = math.max(afterImageInterval, 1)
end

function sampleNPC.onDrawNPC(v)
	if Defines.levelFreeze
	or v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	or v.despawnTimer <= 0 then return end

	local data = v.data
	local settings = v.data._settings

	if data.sprite == nil then
		data.sprite = Sprite{texture = Graphics.sprites.npc[npcID].img, frames = 1}
		data.sprite.pivot = vector(0.5,0.5)
		data.sprite.texpivot = vector(0.5,0.5)
		data.tail = {}
		data.tailTimer = 0
		data.totalAfterImages = 0
	end

	data.sprite.position = vector(v.x + v.width/2, v.y + v.height/2)

	if not Misc.isPaused() then
		data.sprite:rotate(10)
		data.tailTimer = data.tailTimer + 1

		if data.totalAfterImages < maxAfterImages and 1/Routine.deltaTime > Misc.GetEngineTPS()*afterImageThreshold/100 and data.tailTimer % afterImageInterval == 0 then
			data.totalAfterImages = data.totalAfterImages + 1
			local spr = Sprite{texture = Graphics.sprites.npc[npcID].img, frames = 1}
			spr.position = data.sprite.position
			spr.rotation = data.sprite.rotation
			spr.pivot = vector(0.5,0.5)
			spr.texpivot = vector(0.5,0.5)
			data.tail[spr] = 1
		end

	end

	data.sprite:draw{frame = 1, priority = -44, sceneCoords = true}

	npcutils.hideNPC(v)

	for s,a in pairs(data.tail) do
		if not Misc.isPaused() then a = a - 1/32 end
		data.tail[s] = a
		if a <= 0 then data.tail[s] = nil data.totalAfterImages = data.totalAfterImages - 1
		else
			s:draw{frame = 1, priority = -45, sceneCoords = true, color = Color.white..a}
		end
	end

end

--Gotta return the library table!
return sampleNPC