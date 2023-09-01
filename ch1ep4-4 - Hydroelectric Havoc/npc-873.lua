--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local playerStun = require("playerstun")
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 72,
	gfxwidth = 56,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 48,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 12,
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
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false
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
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE_FLOAT = 0
local STATE_STOMP = 1
local STATE_RISE = 2
local STATE_KILLED = 3


local function setDir(dir, v)
	if (dir and v.data._basegame.direction == 1) or (v.data._basegame.direction == -1 and not dir) then return end
	if dir then
		v.data._basegame.direction = 1
	else
		v.data._basegame.direction = -1
	end
end

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end



	
	local data = v.data
	local settings = v.data._settings
	
	if settings.hp == nil then
	    settings.hp = 20
	    settings.spawnDelay = 85
	    settings.delay = 300
	    settings.thunderID = 874
	    settings.shockwaveID = 875
	    settings.stompedDelay = 90
	    settings.amplitudeDelay = 12
	    settings.amplitude = 6
	    settings.amplitudeRate = 3.5
	    settings.speed = 2.5
	    settings.harmDelay = 90
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_FLOAT
		data.timer = 0
		data.stomped = false
		v.harmed = false
		data.health = settings.hp or 20
		v.harmframe = 0
		v.harmtimer = settings.harmDelay
	end

	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		return
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
	    
	end
	
	data.timer = data.timer + 1


	if data.state == STATE_FLOAT then
	    v.speedY = math.sin(-data.timer/settings.amplitudeDelay)*settings.amplitude / settings.amplitudeRate
	    v.speedX = settings.speed * v.direction

		if data.timer % settings.spawnDelay < 24 then
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 3 + 6
			else
				v.animationFrame = math.floor(lunatime.tick() / 8) % 3 + 9
			end
		else
			if v.direction == -1 then
				v.animationFrame = math.floor(lunatime.tick() / 8) % 3
			else
				v.animationFrame = math.floor(lunatime.tick() / 8) % 3 + 3
			end
		end
        if data.timer % settings.spawnDelay == 0 then
            local n = NPC.spawn(settings.thunderID, v.x + v.width/3, v.y + v.height/3)
            n.direction = v.direction
            n.speedY = 4
            SFX.play("lightningshot.wav")
            if player.x < v.x + (v.width / 4) then
			    v.direction = -1
		    else
	    		v.direction = 1
    		end
        end
        if data.timer >= settings.delay then
            data.timer = 0
            data.state = STATE_STOMP
            v.speedX = 0
        end
	elseif data.state == STATE_STOMP then
		if v.direction == -1 then
			v.animationFrame = math.floor(lunatime.tick() / 8) % 3 + 6
		else
			v.animationFrame = math.floor(lunatime.tick() / 8) % 3 + 9
		end
        if not data.stomped then
            v.speedY = 6
            if v.collidesBlockBottom then
                Defines.earthquake = 6
                SFX.play(37)
                local nl = NPC.spawn(settings.shockwaveID, v.x + v.width/3, v.y + v.height/3)
                local nr = NPC.spawn(settings.shockwaveID, v.x + v.width/3, v.y + v.height/3)
                nl.speedX = -5
                nr.speedX = 5
                data.stomped = true
                data.timer = 0
				for k, p in ipairs(Player.get()) do
					if p:isGroundTouching() and not playerStun.isStunned(k) and v:mem(0x146, FIELD_WORD) == player.section then
						playerStun.stunPlayer(k, 120)
					end
				end
            end
        else
            v.speedY = -3
            if data.timer >= settings.stompedDelay then
                data.timer = 0
                data.stomped = false
                data.state = STATE_FLOAT
				if player.x < v.x + (v.width / 4) then
					v.direction = -1
				else
					v.direction = 1
				end
                v.speedY = 0
            end
        end
	else
		v:kill(HARM_TYPE_OFFSCREEN)
		SFX.play(36)
		Animation.spawn(10, v.x + (v.width / 4), v.y)
		Animation.spawn(76, v.x + (v.width/4), v.y)
	end
	
	if v.harmed then
		v.harmtimer = v.harmtimer - 1
		v.harmframe = v.harmframe + 1
		if v.harmframe == 6 then
			v.harmframe = 0
		end
		if v.harmframe >= 3 then
			v.animationFrame = -50
		end
		if v.harmtimer == 0 then
			v.harmtimer = settings.harmDelay
			v.harmframe = 0
			v.harmed = false
		end
	end
	
	if v.animationFrame >= 0 then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end

end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if not v.harmed then
        if (reason == HARM_TYPE_NPC and culprit and culprit.id == 13) then
            SFX.play(9)
            data.health = data.health - 1
        else
            data.health = data.health - 4
            SFX.play(39)
            v.harmed = true
        end
		if culprit then
			if type(culprit) == "NPC" and (culprit.id ~= 195 and culprit.id ~= 50) and NPC.HITTABLE_MAP[culprit.id] then
				culprit:kill(HARM_TYPE_NPC)
			elseif culprit.__type == "Player" then
				--Bit of code taken from the basegame chucks
				if (culprit.x + 0.5 * culprit.width) < (v.x + v.width*0.5) then
					culprit.speedX = -4
				else
					culprit.speedX = 4
				end
			end
		end
		if data.health <= 0 then
			data.state = 3
			data.timer = 0
		elseif data.health > 0 then
			eventObj.cancelled = true
			v:mem(0x156,FIELD_WORD,90)
		end
	end
	
	eventObj.cancelled = true
end

--Gotta return the library table!
return sampleNPC