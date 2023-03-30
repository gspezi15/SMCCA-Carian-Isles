--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 30,
	gfxwidth = 36,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
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
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=799,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=799,
		[HARM_TYPE_PROJECTILE_USED]=799,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=799,
		[HARM_TYPE_TAIL]=799,
		[HARM_TYPE_SPINJUMP]=799,
		--[HARM_TYPE_OFFSCREEN]=799,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local mmenemyshot = Misc.resolveFile("mmenemyshot.wav")
local mmenemyreflect = Misc.resolveFile("mmenemyreflect.wav")
local mmenemydamage = Misc.resolveFile("mmenemydamage.wav")
local killprojectiles = {171, 266, 291, 292, 346}

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
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
		active = false
		v.timer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	v.animationTimer = 0
	if v.timer == 0 then
		if v.direction == -1 and player.x + 224 >= v.x then
			active = true
			v.timer = 1
		elseif v.direction == 1 and player.x - 224 <= v.x then
			active = true
			v.timer = 1
		end
	end
	
	if active then
		if v.direction == -1 then
			v.animationFrame = 1
		else
			v.animationFrame = 3
		end
	else
		if v.direction == -1 then
			v.animationFrame = 0
		else
			v.animationFrame = 2
		end
	end
	
	if v.timer ~= 0 then
		v.timer = v.timer + 1
	end
	
	if v.timer == 50 then
		for j = 2, -2, -2 do
			if i ~= 0 or j ~= 0 then
				local a = v.spawn(856, v.x, v.y + (v.height/4))
				SFX.play(mmenemyshot)
				a.speedX = 2 * v.direction
				a.speedY = j
			end
		end
	elseif v.timer == 100 then
		active = false
	elseif v.timer == 200 then
		v.timer = 0
	end
end

function sampleNPC.onNPCHarm(eventObj, v, killReason, culprit)
	if npcID ~= v.id or v.isGenerator then return end
	
	if not active then
		if killReason ~= HARM_TYPE_PROJECTILE_USED or killReason ~= HARM_TYPE_SPINJUMP or killReason ~= HARM_TYPE_SWORD then
			eventObj.cancelled = true
			SFX.play(mmenemyreflect)
		end
	elseif killReason ~= HARM_TYPE_LAVA then
		eventObj.cancelled = true
		SFX.play(mmenemydamage)
		v:kill(HARM_TYPE_OFFSCREEN)
	end
	if killReason == HARM_TYPE_JUMP then
		eventObj.cancelled = true
		SFX.play(mmenemyreflect)
	end
end
--Gotta return the library table!
return sampleNPC