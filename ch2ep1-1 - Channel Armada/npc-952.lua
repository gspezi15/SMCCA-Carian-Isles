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
	frames = 1,
	framespeed = 8,
	gfxheight = 26,
	gfxwidth = 25,
	width = 25,
	height = 26,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	nogravity = false,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	jumphurt = true, --If true, spiny-like
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	isvegetable = true
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
		HARM_TYPE_OFFSCREEN,
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
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickNPC(v)
	if Defines.levelFreeze then return end
	if not v.friendly then return end
	local data = v.data
	if not data.init then
		data.init = true
		data.timer = 0
	end
	data.timer = data.timer + 1
	if data.friendlyTimer and data.timer >= data.friendlyTimer then v.friendly = false end
end

function sampleNPC.onDrawNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then return end

	local data = v.data
	local settings = data._settings

	if data.sprite == nil then
		data.sprite = Sprite{texture = Graphics.sprites.npc[npcID].img, frames = NPC.config[v.id].frames}
		data.sprite.pivot = vector(0.5,0.5)
		data.sprite.texpivot = vector(0.5,0.5)
		data.sprite.rotation = 0

		data.frameTimer = 0
		data.frame = 1

		if settings.randomFrame then data.frame = RNG.randomInt(NPC.config[v.id].frames) end
		if settings.randomRot then data.sprite.rotation = RNG.randomInt(0,15)*6 end

		settings.rotateSpeed = settings.rotateSpeed or 1

	end

	if not Misc.isPaused() or settings.animatePaused then data.frameTimer = data.frameTimer + 1 end

	if data.frameTimer >= NPC.config[v.id].framespeed then
		data.frame = (data.frame + 1) % (NPC.config[v.id].frames+1)
		data.frameTimer = 0
	end

	data.sprite.position = vector(v.x + v.width/2, v.y + v.height/2)

	if (not Misc.isPaused() or settings.rotatePaused) and settings.rotate then data.sprite:rotate(v.speedY*v.direction*settings.rotateSpeed) end

	data.sprite:draw{frame = data.frame, priority = -46, sceneCoords = true}

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return sampleNPC