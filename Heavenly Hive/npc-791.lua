--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local beetle = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local beetleSettings = {
	id = npcID,
	gfxheight = 48,
	gfxwidth = 64,
	width = 32,
	height = 48,
	frames = 6,
	framestyle = 0,
	framespeed = 10, 
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	jumphurt = false, 
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(beetleSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=npcID,
		--[HARM_TYPE_NPC]=npcID,
		---[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below

local STATE_WALK = 0
local STATE_FLY = 1

function beetle.onNPCKill(obj, v, harm)
	if v.id == npcID then
		local data = v.data
		if harm ~= HARM_TYPE_SPINJUMP and harm ~= HARM_TYPE_LAVA and harm ~= HARM_TYPE_SWORD then
			Animation.spawn(npcID, v.x - 16, v.y, v.animationFrame + 1)
		end
	end
end

--Register events
function beetle.onInitAPI()
	npcManager.registerEvent(npcID, beetle, "onTickEndNPC")
	registerEvent(beetle, "onNPCKill")
end

local function getAnimationFrame(v)
	local data = v.data
	local frame = v.animationFrame
	if data.state == STATE_WALK then
		if lunatime.tick() % 16 < 4 then
			frame = 0
			elseif lunatime.tick() % 16 < 8 then
			frame = 1
			elseif lunatime.tick() % 16 < 12 then
			frame = 2
			else
			frame = 3
		end
	end
						
	if data.state == STATE_FLY then
		if lunatime.tick() % 10 < 5 then
			frame = 4
			else
			frame = 5
		end
	end
	v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
end

function beetle.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	data.timer = data.timer or 0
	getAnimationFrame(v)
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_WALK
		data.timer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	if data.state == nil then
		data.state = STATE_WALK
	end
	
	if data.state == STATE_WALK and v.dontMove ~= true then
			v.speedX = 1.21 * v.direction
	elseif data.state == STATE_FLY then
		data.timer = data.timer + 1
		if v.collidesBlockLeft == true or v.collidesBlockRight == true then
			data.timer = 0
		end
		if data.timer <= 47 then
			v.speedX = 0
			v.speedY = -2
			npcutils.faceNearestPlayer(v)
		elseif data.timer > 47 and data.timer <= 111 then
			v.speedY = -Defines.npc_grav
		else
			v.speedX = 1.5 * v.direction
			v.speedY = 0.5
		end
		if v.collidesBlockBottom == true then
			data.state = STATE_WALK
			npcutils.faceNearestPlayer(v)
			data.timer = 0
		end
	end
	
	if data.state == STATE_WALK and v.collidesBlockLeft == true or v.collidesBlockRight == true or v.collidesBlockBottom == false then
		data.state = STATE_FLY
	end
end	

--Gotta return the library table!
return beetle