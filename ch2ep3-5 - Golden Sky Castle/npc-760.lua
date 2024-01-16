--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local Froggaus = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
local id = NPC_ID
--Defines NPC config for our NPC. You can remove superfluous definitions.
local FroggausSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 96,
	gfxwidth = 96,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 86,
	height = 84,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 8,
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
	hp = 60,
	idletime = 75,
	bubbleID = id + 1,
	idletime = 180,
	jumpheight1 = -12,
	jumpheight2 = -14,
	effect = id,
}

--Applies NPC settings
npcManager.setNpcSettings(FroggausSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_IDLE = 1
local STATE_JUMP1 = 2
local STATE_JUMP2 = 3
local STATE_BUBBLE = 4
local STATE_HURT = 5
local speed = 0
local setHP = NPC.config[id].hp
--Register events
function Froggaus.onInitAPI()
	npcManager.registerEvent(npcID, Froggaus, "onTickNPC")
	npcManager.registerEvent(npcID, Froggaus, "onTickEndNPC")
	--npcManager.registerEvent(npcID, Froggaus, "onDrawNPC")
	registerEvent(Froggaus, "onNPCHarm")
end
local config = NPC.config[id]


function Froggaus.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local data = v.data
	local settings = data._settings
	local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
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
		v.stateTimer = 0
		v.HITTABLE = true
		v.phase2 = false
		v.phase3 = false
		v.harmframe = 0
		v.harmtimer = 120
		v.invisibleharm = false
		v.harmed = false
		v.hp = NPC.config[id].hp
		v.consecutive = 0
		v.STATE = STATE_IDLE
	end

	if v.STATE == STATE_IDLE then
		v.stateTimer = v.stateTimer + 1
		v.HITTABLE = true
		if (v.x + v.width / 2) > (p.x + p.width / 2) then
			v.direction = -1
		else
			v.direction = 1
		end
		if v.direction == -1 then
			v.animationFrame = math.floor(lunatime.tick() / 6) % 3
		elseif v.direction == 1 then
			v.animationFrame = math.floor(lunatime.tick() / 6) % 3
		end
		if v.stateTimer == config.idletime then
			v.stateTimer = 0
			if v.phase2 == false then
				v.STATE = STATE_JUMP1
			elseif v.phase2 == true then
				v.STATE = STATE_JUMP2
			end
		end
	end

	if v.STATE == STATE_HURT then
		v.stateTimer = v.stateTimer - 1
		if v.stateTimer >= 0 then
			v.stateTimer = 0
		end
		v.animationFrame = math.floor(lunatime.tick() / 6) % 2 + 10
		if v.stateTimer <= -45 then
			v.stateTimer = 0
			if v.phase2 == false then
				v.STATE = STATE_JUMP1
			elseif v.phase2 == true then
				v.STATE = STATE_JUMP2
			end
		end
		v.HITTABLE = false
	end


	if v.STATE == STATE_JUMP1 then
		v.stateTimer = v.stateTimer + 1
		v.HITTABLE = false
		if v.stateTimer == 10 and v.collidesBlockBottom then
			v.speedY = config.jumpheight1
			speed = 2.5
			SFX.play(1)
		end
		if v.stateTimer <= 10 then
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 3
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 3
			end
		end
		if (v.x + v.width / 2) > (p.x + p.width / 2) then
			v.direction = -1
		else
			v.direction = 1
		end
		if v.stateTimer >= 10 then
			v.speedX = speed * v.direction
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 5
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 5
			end
		end
		if v.stateTimer >= 15 and v.collidesBlockBottom then
			v.stateTimer = 0
			v.speedX = 0
			v.consecutive = v.consecutive + 1
		end
		if v.consecutive == 3 then
			v.consecutive = 0
			v.stateTimer = 0
			v.STATE = STATE_IDLE
		end
	end

	if v.STATE == STATE_JUMP2 then
		v.stateTimer = v.stateTimer + 1
		v.HITTABLE = false
		if v.stateTimer == 10 and v.collidesBlockBottom then
			v.speedY = config.jumpheight2
			speed = 7
			SFX.play(1)
		end
		if v.stateTimer <= 10 then
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 3
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 3
			end
		end
		if (v.x + v.width / 2) > (p.x + p.width / 2) then
			v.direction = -1
		else
			v.direction = 1
		end
		if v.stateTimer >= 10 and v.stateTimer <= 75 then
			v.speedX = speed * v.direction
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 5
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 5
			end
		end
		if v.stateTimer == 90 then
			v.speedY = 11
			v.speedX = 0
		end
		if v.stateTimer >= 75 then
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 6
			elseif v.direction == 1 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 6
			end
		end
		if v.stateTimer >= 15 and v.collidesBlockBottom then
			v.stateTimer = 0
			v.speedX = 0
			defines.earthquake = 10
			v.consecutive = v.consecutive + 1
			SFX.play(37)
			local shockwave1 = NPC.spawn(202, v.x, v.y + 32, v.section)
			local shockwave2 = NPC.spawn(202, v.x, v.y + 32, v.section)
			shockwave1.friendly = v.friendly
			shockwave1.layerName = "Spawned NPCs"
			shockwave2.friendly = v.friendly
			shockwave2.layerName = "Spawned NPCs"
			shockwave1.speedX = 6
			shockwave1.speedY = -4
			shockwave2.speedX = -6
			shockwave2.speedY = -4
		end
		if v.consecutive == 3 then
			v.consecutive = 0
			v.stateTimer = 0
			if v.phase3 == true then
				v.STATE = STATE_BUBBLE
			elseif v.phase3 == false then
				v.STATE = STATE_IDLE
			end
		end
	end

	if v.harmed == true then
		v.harmtimer = v.harmtimer - 1
		v.harmframe = v.harmframe + 1
		if v.harmframe == 4 then
			v.harmframe = 0
		end
		if v.harmframe > 2 then
			v.invisibleharm = true
		else
			v.invisibleharm = false
		end
		if v.harmtimer == 0 then
			v.harmtimer = 120
			v.harmframe = 0
			v.harmed = false
		end
	end

	if v.invisibleharm == true then
		v.animationFrame = -999
	end

	if v.STATE == STATE_BUBBLE then
		v.stateTimer = v.stateTimer + 1
		if v.stateTimer <= 20 then
			v.animationFrame = math.floor(lunatime.tick() / 6) % 1 + 7
		end
		if v.stateTimer >= 20 then
			v.animationFrame = math.floor(lunatime.tick() / 6) % 2 + 8
		end
		if v.stateTimer >= 65 then
			local bubble = NPC.spawn(config.bubbleID, v.x, v.y + 32, v.section)
			local p = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
								
			local startX = p.x + p.width / 2
			local startY = p.y + p.height / 2
			local X = v.x + v.width / 2
			local Y = v.y + v.height / 2
						
			local angle = math.atan2((Y - startY), (X - startX))

			bubble.speedX = -3 * math.cos(angle)
			bubble.speedY = -3 * math.sin(angle)
			bubble.friendly = v.friendly
			bubble.layerName = "Spawned NPCs"
			v.consecutive = v.consecutive + 1
			v.stateTimer = 20
			SFX.play(38)
		end
		if v.stateTimer == 20 and v.consecutive == 4 then
			v.stateTimer = 0
			v.consecutive = 0
			v.STATE = STATE_IDLE
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


	function Froggaus.onNPCHarm(eventObj, v, killReason, culprit)
		local data = v.data
		if v.id ~= npcID then return end
	
		if killReason == HARM_TYPE_JUMP or HARM_TYPE_NPC or HARM_TYPE_PROJECTILE_USED or HARM_TYPE_SWORD or HARM_TYPE_HELD then
			if v:mem(0x156,FIELD_WORD) == 0 and v.HITTABLE == true and v.harmed == false then
				v.hp = v.hp - 10
				v.harmed = true
				SFX.play{
					sound = "FroggausSounds/COI_Bosshit.wav"
				}
				v.STATE = STATE_HURT
			end
		else
			return
		end
		if v.hp < setHP * 2 / 3 + 1 then
			v.phase2 = true
		end
		if v.hp < setHP / 3 + 1 then
			v.phase3 = true
		end
		if v.hp == 0 then
			local effect = Effect.spawn(760, v.x + 32, v.y + 32) 
			effect.speedY = -6
			SFX.play{
				sound = "FroggausSounds/kirby_bossdead.wav"
			}
		end	
		if v.hp > 0 then
			eventObj.cancelled = true
	
			v:mem(0x156,FIELD_WORD,60)
			
			if (reason == HARM_TYPE_JUMP) and type(culrpit) == "Player" then
				culrpit.speedX = math.sign((v.x + v.width*0.5) - (culprit.x + culprit.width*0.5)) * 8

			end
		end
	end

--Gotta return the library table!
return Froggaus