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
	gfxheight = 64,
	gfxwidth = 96,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 6, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

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
	
	cliffturn = false,
	luahandlesspeed = true,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = true,
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
	health = 3, --The amount of NPCs/Fireballs/Tail Swipes/Sword Slashes it takes to make the NPC explode
	shotNPC = 17, --The NPC that gets shot out (Default is 17, SMB3 Bullet Bill)
	shootDelay = 150, --The amount of frames before the NPC shoots (Default is 150)
	reloadDelay = 150,	--The amount of frames before the NPC starts to move again after shooting (Default is 150)
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_WAIT = 0
local STATE_SHOOT = 1
local STATE_RELOAD = 2
local STATE_EXPLODE = 3
local frame = 0

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	
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
		data.state = STATE_WAIT
		--data.spotCollider:Debug(true)
		data.accel = 0
		data.timer = 0
		data.direction = -1
		data.fxtimer = 0
		data.health = cfg.health
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	if data.state == STATE_WAIT then
		if lunatime.tick() % 11 < 3 then
			frame = 0
		elseif lunatime.tick() % 11 < 6 then
			frame = 1
		elseif lunatime.tick() % 11 < 12 then
			frame = 2
		end
		data.accel = data.accel + 0.02
		if data.accel >= 3 then
			data.accel = 3
		end
		if player.x + player.width < v.x + 32 then
			v.direction = -1
		elseif player.x > v.x + v.width - 32 then
			v.direction = 1
		end
		v.speedX = cfg.speed * v.direction
		data.timer = data.timer + 1
		if data.timer >= cfg.shootDelay then
			data.state = STATE_SHOOT
			data.timer = 0
		end
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
	
	if data.state == STATE_SHOOT then
		frame = 3
		if lunatime.tick() % 6 < 3 then
			cfg.gfxoffsetx = -1
		elseif lunatime.tick() % 6 < 7 then
			cfg.gfxoffsetx = 1
		end
		v.speedX = 0
		data.timer = data.timer + 1
		if data.timer < 50 then
			if player.x + player.width < v.x + 32 then
				v.direction = -1
			elseif player.x > v.x + v.width - 32 then
				v.direction = 1
			end
		end
		if data.timer == 50 then
			if v.direction == -1 then
				local lol = NPC.spawn(cfg.shotNPC, v.x, v.y)
				lol.x = v.x - lol.width - 16
				lol.y = v.y - (lol.height / 2) + 16
				lol.direction = v.direction
				if v.friendly then lol.friendly = true end
				Effect.spawn(10, v.x - 48, v.y + 2)
				Effect.spawn(71, v.x - 48, v.y + 2)
			elseif v.direction == 1 then
				local lol = NPC.spawn(cfg.shotNPC, v.x, v.y)
				lol.x = v.x + v.width
				lol.y = v.y - (lol.height / 2) + 16
				lol.direction = v.direction
				if v.friendly then lol.friendly = true end
				Effect.spawn(10, v.x + v.width + 16, v.y + 2)
				Effect.spawn(71, v.x + v.width + 16, v.y + 2)
				end
			data.timer = 0
			SFX.play(22)
			data.state = STATE_RELOAD
			cfg.gfxoffsetx = 0
		end
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
	
	if data.state == STATE_RELOAD then
		if data.timer == 30 then
			SFX.play(82)
		end
		if data.timer >= 30 then
			data.fxtimer = data.fxtimer + 1
			if data.fxtimer >= 6 then
				data.fxtimer = 0
				if v.direction == -1 then
					local xd = Effect.spawn(74, v.x - 24, v.y + 8 + RNG.random(-8, 12))
					xd.speedY = -4
				elseif v.direction == 1 then
					local xd = Effect.spawn(74, v.x + v.width + 16, v.y + 8 + RNG.random(-8, 12))
					xd.speedY = -4
				end
			end
		end
		frame = 0
		v.speedX = 0
		data.timer = data.timer + 1
		if player.x + player.width < v.x + 32 then
			v.direction = -1
		elseif player.x > v.x + v.width - 32 then
			v.direction = 1
		end
		if data.timer >= cfg.reloadDelay then
			data.state = STATE_WAIT
			data.timer = 0
			data.fxtimer = 0
		end
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
	
	if data.state == STATE_EXPLODE then
		frame = 3
		if lunatime.tick() % 6 < 3 then
			cfg.gfxoffsetx = -1
		elseif lunatime.tick() % 6 < 7 then
			cfg.gfxoffsetx = 1
		end
		v.speedX = 0
		data.timer = data.timer + 1
		data.fxtimer = data.fxtimer + 1
		if data.fxtimer >= 10 then
			data.fxtimer = 0
			SFX.play("sound/extended/beat-warn.ogg")
		end
		if data.timer >= 60 then
			Explosion.spawn(v.x + v.width / 2, v.y + v.height / 2, 3)
			v:kill(3)
		end
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
end

function sampleNPC.onNPCHarm(e, v, harmType, culprit)
	if v.id ~= npcID then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	
	if (harmType == HARM_TYPE_NPC or harmType == HARM_TYPE_TAIL or harmType == HARM_TYPE_SWORD) and data.state ~= STATE_EXPLODE then
		data.health = data.health - 1
		SFX.play(39)
		v:mem(0x156, FIELD_WORD, 30) -- set iframes to 30

		if culprit and culprit.__type == "NPC" then
			culprit:kill(3)
		end
		
		if data.health == 0 then
			--Explosion.spawn(v.x + v.width / 2, v.y + v.height / 2, 3)
			data.timer = 0
			data.state = STATE_EXPLODE
			SFX.play(61)
		end

		--if data.health > 0 then
			e.cancelled = true
		--end
	else
		e.cancelled = true
	end
end

--Gotta return the library table!
return sampleNPC