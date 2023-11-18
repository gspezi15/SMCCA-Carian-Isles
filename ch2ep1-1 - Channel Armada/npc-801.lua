--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
--Create the library table
local Roy = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
local id = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = id,
	--Sprite size
	gfxheight = 68,
	gfxwidth = 80,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 75,
	height = 62,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 0,
	framestyle = 0,
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
	noiceball = true,
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
	hp = 8,
	effect = 753
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=753,
		[HARM_TYPE_FROMBELOW]=753,
		[HARM_TYPE_NPC]=753,
		[HARM_TYPE_PROJECTILE_USED]=753,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=753,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=753,
	}
);

--Custom local definitions below
local STATE_IDLE = 0
local STATE_SHOOT = 1
local STATE_JUMP = 2
local STATE_GROUNDPOUND = 3
local STATE_MISSILE = 4
local STATE_WHILEJUMP = 5
local STATE_FALL = 6

--Register events
function Roy.onInitAPI()
	npcManager.registerEvent(npcID, Roy, "onTickEndNPC")
	--npcManager.registerEvent(npcID, Roy, "onDrawNPC")
	registerEvent(Roy, "onNPCHarm")
end

function Roy.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	--local definitions for this function
	local config = NPC.config[id]
	local data = v.data
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_IDLE
		data.hp = config.hp - 2
		data.shootconsecutive = 3
		data.jumpconsecutive = 2
		data.randommovement = 0
		data.stateTimer = 0
		data.harmframe = 0
		data.harmtimer = 65
		data.invisibleharm = false
		data.harmed = false
	end
	local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)


	if data.harmed == true then
		data.harmtimer = data.harmtimer - 1
		data.harmframe = data.harmframe + 1
		if data.harmframe == 4 then
			data.harmframe = 0
		end
		if data.harmframe > 2 then
			data.invisibleharm = true
		else
			data.invisibleharm = false
		end
		if data.harmtimer == 0 then
			data.harmtimer = 65
			data.harmframe = 0
			data.harmed = false
		end
	end

	--State tells what to do
	if data.state == STATE_IDLE then
		data.stateTimer = data.stateTimer + 1
		v.speedX = 0
		if (v.x + v.width / 2) > (p.x + p.width / 2) then
			v.direction = -1
		else
			v.direction = 1
		end
		if data.invisibleharm == false then
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 5
			end
		else
			v.animationFrame = -50
		end
		if data.stateTimer >= 45 then
			data.stateTimer = 0
			data.state = RNG.randomInt(STATE_SHOOT, STATE_MISSILE)
		end
	end
	--State Jump
	if data.state == STATE_JUMP then
		data.stateTimer = data.stateTimer + 1
		if (v.x + v.width / 2) > (p.x + p.width / 2) then
			v.direction = -1
		else
			v.direction = 1
		end
		
		if data.invisibleharm == false then
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 1
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 6
			end
		else
			v.animationFrame = -50
		end
		if data.stateTimer == 1 then
			v.speedX = 0
			data.randommovement = RNG.randomInt(6, -6)
		end
		if data.stateTimer == 15 then
			v.speedY = -9
			data.stateTimer = 0
			data.state = STATE_WHILEJUMP
		end
		if data.stateTimer == 10 and data.jumpconsecutive == 0 then
			data.state = STATE_IDLE
			data.jumpconsecutive = 2
			data.stateTimer = 0
			data.randommovement = 0
		end
	end
	if data.state == STATE_WHILEJUMP then
		if (v.x + v.width / 2) > (p.x + p.width / 2) then
			v.direction = -1
		else
			v.direction = 1
		end
		if not v.collidesBlockLeft or not v.collidesBlockRight then
			v.speedX = data.randommovement
		elseif v.collidesBlockLeft or v.collidesBlockRight then
			v.speedX = 0
		end
		
		if data.invisibleharm == false then
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 1
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 6
			end
		else
			v.animationFrame = -50
		end
		if v.collidesBlockBottom then
			data.jumpconsecutive = data.jumpconsecutive - 1
			data.state = STATE_JUMP
		end
	end
	--data.stateShoot
	if data.state == STATE_SHOOT then
		if (v.x + v.width / 2) > (p.x + p.width / 2) then
			v.direction = -1
		else
			v.direction = 1
		end
	end

	if data.state == STATE_SHOOT then
		data.stateTimer = data.stateTimer + 1
		
		if data.invisibleharm == false then
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 1
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 6
			end
		else
			v.animationFrame = -50
		end
		if data.stateTimer == 45 then
			v.speedY = -1
			local bullet = NPC.spawn(17,v.x + 32, v.y,player.section)
			SFX.play(22)
			if v.direction == -1 then
				Effect.spawn(10, v.x, v.y)
			elseif v.direction == 1 then
				Effect.spawn(10, v.x + 64, v.y)
			end
			npcutils.faceNearestPlayer(bullet)
		end
		if data.stateTimer >= 45 then
			v.speedX = -2 * v.direction
		end
		if v.collidesBlockBottom and data.stateTimer >= 60 then
			v.speedX = 0
			v.speedY = 0
			data.shootconsecutive = data.shootconsecutive - 1
			data.stateTimer = 0
		end
		if data.shootconsecutive == 0 then
			data.state = STATE_IDLE
			data.stateTimer = 0
			data.shootconsecutive = 3
		end
	end
	--data.stateGround Pound
	if data.state == STATE_GROUNDPOUND then
		data.stateTimer = data.stateTimer + 1
		
		if data.invisibleharm == false then
			v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 10
		else
			v.animationFrame = -50
		end
	
		if data.stateTimer == 1 then
			v.speedY = -12
		end
		if data.stateTimer > 1 then
			v.speedX = 3.75 * v.direction
		end
		if data.stateTimer == 60 then
			data.stateTimer = 0
			data.state = STATE_FALL
		end
	end
	if data.state == STATE_FALL then
		v.speedX = 0
		
		if data.invisibleharm == false then
			if not v.collidesBlockBottom then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 10
			elseif v.collidesBlockBottom then
				data.stateTimer = data.stateTimer + 1
				v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 11
			end
		else
			v.animationFrame = -50
		end
	
		if data.stateTimer == 1 then
			Defines.earthquake = 15
			triggerEvent("royevent")
			SFX.play(22)
			SFX.play(37)
			Animation.spawn(10, v.x - 16, v.y + 32)
			Animation.spawn(10, v.x + 64, v.y + 32)
			Effect.spawn(10, v.x - 16, v.y)
			Effect.spawn(10, v.x + 64, v.y)
			local bullet1 = NPC.spawn(17,v.x + 64, v.y,player.section)
			bullet1.direction = 1
			local bullet2 = NPC.spawn(17,v.x,v.y,player.section)
			bullet2.direction = -1
		elseif data.stateTimer == 30 then
			data.state = STATE_IDLE
			data.stateTimer = 0
		end
	end
	--data.stateMissile
	if data.state == STATE_MISSILE then
	data.stateTimer = data.stateTimer + 1
	if (v.x + v.width / 2) > (p.x + p.width / 2) then
		v.direction = -1
	else
		v.direction = 1
	end
	
	if data.invisibleharm == false then
		if v.direction == -1 then
			v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 1
		elseif v.direction == 1 then
			v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 6
		end
	else
		v.animationFrame = -50
	end
	if data.stateTimer == 1 then
		v.speedX = 0
		data.jumpconsecutive = 1
		data.randommovement = RNG.randomInt(6, -6)
	end
	if data.stateTimer == 15 then
		v.speedY = RNG.randomInt(-7, -10)
	end
	if data.stateTimer >= 15 then
		v.speedX = data.randommovement
	end
	if data.stateTimer == 60 then
		data.state = STATE_WHILEJUMP
		data.stateTimer = 0
		data.randommovement = -1.5 * v.direction
		v.speedY = -3.5
		SFX.play(22)
		if v.direction == -1 then
			Effect.spawn(10, v.x, v.y)
			local bullet = NPC.spawn(757,v.x,v.y,player.section)
			bullet.speedX = 5 * v.direction
		elseif v.direction == 1 then
			Effect.spawn(10, v.x + 64, v.y)
			local bullet = NPC.spawn(757,v.x + 64,v.y,player.section)
			bullet.speedX = 5 * v.direction
		end
	end
	if data.stateTimer >= 30 then
		v.speedX = data.randommovement
	end

	
end



	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
end

function Roy.onNPCHarm(e, v, r, o)
	if v.id ~= id then return end
	if r == 9 or r == HARM_TYPE_LAVA then return end
	local data = v.data
	local config = NPC.config[v.id]
	
	if data.hp >= 0 then
		if ((r == HARM_TYPE_NPC and o and o.id ~= 13) or r == HARM_TYPE_HELD or r == HARM_TYPE_PROJECTILE_USED or r == HARM_TYPE_SWORD or r == HARM_TYPE_JUMP or r == HARM_TYPE_SPINJUMP) and data.harmed == false then
			data.hp = data.hp - 1
			SFX.play(39)
			data.harmed = true
			if o and o.id ~= 13 then
				o.speedX = 4 * -v.direction
				o.speedY = -3
			end

		elseif (r == HARM_TYPE_NPC and o and o.id == 13) then
			data.hp = data.hp - 0.25
			SFX.play(9)	
		end
		e.cancelled = true
	else
		local e = Effect.spawn(config.effect, v.x, v.y)
		e.speedX = 0
		e.speedY = -10
		SFX.play(41)
	end
end

--Gotta return the library table!
return Roy