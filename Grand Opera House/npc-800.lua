--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local klonoa = require("characters/klonoa")
klonoa.UngrabableNPCs[NPC_ID] = true
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
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
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

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
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})
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
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
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

		settings.speedXMin = settings.speedXMin or -3
		settings.speedXMax = settings.speedXMax or 3
		settings.speedYMin = settings.speedYMin or -4
		settings.speedYMax = settings.speedYMax or -4
		settings.emitting = settings.emitting or false
		settings.emitTimer = settings.emitTimer or 160
		settings.waitTimer = settings.waitTimer or 130
		settings.emittingInterval = settings.emittingInterval or 4
		settings.emitSFX = settings.emitSFX or 16
		settings.emitid = settings.emitid or 951
		settings.emitFX = settings.emitFX or 10
		settings.throw = settings.throw or false
		settings.SFXSet = settings.SFXSet or 0
		settings.FXSet = settings.FXSet or 0

		data.timer = data.timer or 0
		data.emitting = settings.emitting
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		data.emitting = false
	end
	v.friendly = true
	--Execute main AI.
	data.timer = data.timer + 1
	if data.emitting == false then
		if data.timer >= settings.waitTimer then
			data.timer = 0
			data.emitting = true
		end
	else
		if data.timer == settings.emittingInterval and settings.SFXSet == 1 and settings.emitSFX ~= 0 then
			SFX.play(settings.emitSFX)
		end
		if data.timer == settings.emittingInterval and settings.FXSet == 1 and settings.emitFX ~= 0 then
			local ptl = Animation.spawn(settings.emitFX, v.x+v.width/2,v.y+v.height/2)
			ptl.x = ptl.x - ptl.width/2
			ptl.y = ptl.y - ptl.height/2
		end
		if data.timer % settings.emittingInterval == 0 then
			if settings.emitSFX ~= 0 and settings.SFXSet ~= 1 then
				SFX.play(settings.emitSFX)
			end
			if settings.emitFX ~= 0 and settings.FXSet ~= 1 then
				local ptl = Animation.spawn(settings.emitFX, v.x+v.width/2,v.y+v.height/2)
				ptl.x = ptl.x - ptl.width/2
				ptl.y = ptl.y - ptl.height/2
			end
			local projectile = NPC.spawn(settings.emitid, v.x+v.width/2,v.y+v.height/2)
			projectile.x = projectile.x - projectile.width/2
			projectile.y = projectile.y - projectile.height/2
			projectile.speedX = RNG.random(settings.speedXMin,settings.speedXMax)
			projectile.speedY = RNG.random(settings.speedYMin,settings.speedYMax)
			if settings.throw == true then
				projectile:mem(0x12E, FIELD_WORD, 30)
				projectile:mem(0x132, FIELD_WORD, -1)
				projectile:mem(0x136, FIELD_BOOL, true)
			end
		end
		if data.timer >= settings.emitTimer then
			data.timer = 0
			data.emitting = false
		end
	end
	-- Layer Movement --
	npcutils.applyLayerMovement(v)
end

--Gotta return the library table!
return sampleNPC