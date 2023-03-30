--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi

--Create the library table
local dragonfly = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local dragonflySettings = {
	id = npcID,
	--Sprite size
	gfxheight = 48,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 28,
	height = 44,
	frames = 4,
	framestyle = 1,
	framespeed = 4, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	waitTime = 96,
	moveTime = 48,
	ySpeed = 0.7,
	xSpeed = 2,
	arcMovement = false,
}

--Applies NPC settings
npcManager.setNpcSettings(dragonflySettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function dragonfly.onInitAPI()
	npcManager.registerEvent(npcID, dragonfly, "onTickNPC")
end

function dragonfly.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	local cfg = NPC.config[v.id]
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.move = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
		data.move = false
		npcutils.faceNearestPlayer(v)
		if v.y >= plr.y then
			v.ai2 = 0
		else
			v.ai2 = 1
		end
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		data.move = false
	end
	
	--Start general timer
	data.timer = data.timer + 1
	
	--Stay put for now
	if data.move == false then
		v.speedX = 0
		v.speedY = 0
		if data.timer >= dragonflySettings.waitTime then
			data.timer = 0
			data.move = true
		end
		
	--Go after the player
	
	else
	
		if cfg.arcMovement then
			data.w = 1 * pi/100
			data.timer = data.timer or 0
			data.timer = data.timer + 1
			v.speedX = dragonflySettings.xSpeed * 50 * data.w * sin(data.w*data.timer) * v.direction
		end
	
		--Two types of movements in one! Wow!
		if v.ai2 <= 0 then
			if cfg.arcMovement then
				v.speedY = dragonflySettings.ySpeed * 200 * -data.w * cos(data.w*data.timer)
			else
				v.speedY = -dragonflySettings.ySpeed
			end
		else
			if cfg.arcMovement then
				v.speedY = dragonflySettings.ySpeed * 200 * data.w * cos(data.w*data.timer)
			else
				v.speedY = dragonflySettings.ySpeed
			end
		end
		
		if not cfg.arcMovement then
			if dragonflySettings.moveTime >= 16 then
				if data.timer >= 8 then
					v.speedX = dragonflySettings.xSpeed * v.direction
				end
			else
				v.speedX = dragonflySettings.xSpeed * v.direction
			end
		end
		--Face the player and get ready to chase next time
		if data.timer >= dragonflySettings.moveTime then
			data.timer = 0
			data.move = false
			npcutils.faceNearestPlayer(v)
			if v.y >= plr.y then
				v.ai2 = 0
			else
				v.ai2 = 1
			end
		end
	end
end

--Gotta return the library table!
return dragonfly