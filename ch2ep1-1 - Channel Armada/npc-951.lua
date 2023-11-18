--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	-- Default npc config
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 1,
	framestyle = 1,
	framespeed = 8,
	npcblock = true,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.
	nohurt = true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	grabside=false,
	grabtop=false,

	-- Custom npc config
	-- These get used if you register the npc with the flamethrower ai file.

	-- The offsets are from the center of the npc
	-- They change where the fires are spawned when shooting
	fireOffsetX = 16,
	fireOffsetY = 16,

	-- If true, fireOffsetX will be normal for left and reversed for right.
	-- Example, if you put 8 for fireOffsetX and set this to true, when the npc is looking right the offset will be -8.
	useDirection = false
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

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	registerEvent(sampleNPC, "onTickEnd")
	registerEvent(sampleNPC, "onExitLevel")
	registerEvent(sampleNPC, "onDraw")
end

-- What npc should it shoot?
local npcToSpawn = npcID + 1 -- Default id for the flamethrower bodies is 751, default id for the flames is 752
-- As long as you change the ids by the same amount this will still work fine without any changes needed

-- How many ticks should the game wait before making the fired npc harmable?
-- This is done as to not hurt players that are standing on top of a flame thrower end.
-- If that shoots and the npc is not friendly the player takes damage. Somehow.
-- Used as a last resort if both players are standing on the npc at once.
local npcFriendlyTimer = 8

local sound = SFX.play{
	sound = "FlameThrowerSound.ogg",
	loops = 0,
	volume = 0
}
local soundVol = 0
local npcThatsFiringExists = false

local multVol = 1/2

local STATE_IDLE = 1
local STATE_SHOOT = 2

function sampleNPC.onTickNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data
	local settings = data._settings
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.init = false
		return
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		settings.idleTimer = settings.idleTimer or 120
		settings.shootTimer = settings.shootTimer or 120
		settings.fireInterval = settings.fireInterval or 4

		v.speedY = v.speedY+Defines.npc_grav
	end

	if not data.throwEnd and v:mem(0x12E, FIELD_WORD) < 20 and v:mem(0x136, FIELD_BOOL) then
		local dir = -v.direction
		v.speedX = v.speedX+0.1*dir
		if math.abs(v.speedX) < 0.2 then v.speedX = 0 data.throwEnd = true end
	end

	if not data.init then
		data.init = true
		data.state = STATE_IDLE
		data.timer = settings.timerInit or 0
		data.stateTimers = {
			settings.idleTimer,
			settings.shootTimer
		}
		data.collider = Colliders.Box(v.x-4,v.y-4,v.width+8,4)
	end
	data.collider.x = v.x-4
	data.collider.y = v.y-4

	if data.timer >= data.stateTimers[data.state] then
		data.state = (data.state==STATE_IDLE and STATE_SHOOT) or STATE_IDLE
		data.timer = 0
	end

	if data.state == STATE_SHOOT or v:mem(0x12C, FIELD_WORD) > 0 then

		if v.despawnTimer == 180 then
			npcThatsFiringExists = true
		end

		if data.timer % settings.fireInterval == 0 then

			local cfg = NPC.config[v.id]

			local xPos,yPos = v.x,v.y
			local xOffset,yOffset = cfg.fireOffsetX or 0, cfg.fireOffsetY or 0

			if cfg.useDirection then xOffset = -xOffset*v.direction end

			xPos = xPos + xOffset
			yPos = yPos + yOffset

			local fire = NPC.spawn(npcToSpawn, xPos, yPos, v.section, false, true)
			local fset = settings.flameSettings

			fire.direction = v.direction
			fire.speedX = fire.direction * 7.5

			if fset then

				fire.data._settings = table.join(fset, fire.data._settings)
				fire.data.rotate = fset.rotate
				fire.data.animatePaused = fset.animatePaused
				fire.data.rotatePaused = fset.rotatePaused
				fire.data.rotateSpeed = fset.rotateSpeed

			end

			if v:mem(0x12C, FIELD_WORD) > 0 then

				fire:mem(0x12E, FIELD_WORD, v:mem(0x12E, FIELD_WORD))
				fire:mem(0x130, FIELD_WORD, v:mem(0x130, FIELD_WORD))
				fire:mem(0x132, FIELD_WORD, v:mem(0x132, FIELD_WORD))
				fire:mem(0x136, FIELD_BOOL, true)
				fire:mem(0x08, FIELD_BOOL, false)

			else

				for _,plr in pairs(Player.get()) do
					if (Colliders.collide(data.collider,plr) or Colliders.speedCollide(data.collider,plr)) and plr.y + plr.height <= data.collider.y + 4 then
						if fire:mem(0x130, FIELD_WORD) == 0 then
							fire:mem(0x130, FIELD_WORD, plr.idx)
							fire:mem(0x12E, FIELD_WORD, 10)
						else
							fire:mem(0x130, FIELD_WORD, 0)
							fire:mem(0x12E, FIELD_WORD, 0)
							fire.friendly = true
							fire.data.friendlyTimer = npcFriendlyTimer
						end
					end
				end
			end
		end

	end

	data.timer = data.timer + 1

end

function sampleNPC.onTickEnd()
	if npcThatsFiringExists then
		soundVol = math.min(soundVol + 1/65/multVol,1)
	else
		soundVol = math.max(soundVol - 1/65/multVol,0)
	end
end

-- oh man using onDraw to play a sound effect really genius 9thcore
-- its the only function that runs while paused okay
function sampleNPC.onDraw()
	if not Misc.isPaused() then sound.volume = soundVol*multVol else sound.volume = 0 end
	npcThatsFiringExists = false
end

function sampleNPC.onExitLevel()
	sound:stop()
end

--Gotta return the library table!
return sampleNPC