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
	gfxheight = 32,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 32,
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
	npcblock = true,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = false,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
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

local STATE_IDLE = 0
local STATE_FALLING = 1

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = data._settings

	if data.state == STATE_IDLE then
		v.speedY = -Defines.npc_grav
	end
	
	--If despawned
	if v.despawnTimer <= 0 then
		-- dont do anything lmao
		v:mem(0x124, FIELD_BOOL, false)
		return
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		v:kill(HARM_TYPE_VANISH)
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_IDLE
		data.collider = Colliders.Rect(0,0,v.width,v.height,0)
	end

	data.collider.x = v.x+v.width/2
	data.collider.y = v.y+v.height/2

	if data.state == STATE_IDLE then

		-- The top-left coordinates
		local x,y = v.x-settings.range,v.y

		if #Player.getIntersecting(
			x, y,
			x + v.width + settings.range*2, y + 9999999
		) > 0 then

			data.state = STATE_FALLING
			SFX.play(Misc.resolveSoundFile("StoneFall"))

		end

	end

	data.collider.rotation = data.collider.rotation + v.speedY + Defines.npc_grav

	for _,plr in pairs(Player.get()) do
		if Colliders.speedCollide(data.collider,plr) then
			plr:harm()
		end
	end

end

function sampleNPC.onDrawNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	if v.despawnTimer <= 0 then return end
	if not v.data.initialized then return end

	npcutils.hideNPC(v)

	local data = v.data

	if not data.sprite then
		data.sprite = Sprite{texture = Graphics.sprites.npc[v.id].img, frames = 1}
		data.sprite.pivot = vector(0.5,0.5)
		data.sprite.texpivot = vector(0.5,0.5)
	end

	data.sprite.position = vector(v.x+v.width/2,v.y+v.height/2)
	
	if not Misc.isPaused() then data.sprite:rotate(v.speedY) end

	data.sprite:draw{frame = 1, priority = -45, sceneCoords = true}

end

--Gotta return the library table!
return sampleNPC