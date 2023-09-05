--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local cowfish = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local cowfishSettings = {
	id = npcID,
	gfxheight = 48,
	gfxwidth = 48,
	width = 48,
	height = 48,
	frames = 4,
	framestyle = 1,
	framespeed = 10, 
	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 
	nohurt=false,
	nogravity = true,
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

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(cowfishSettings)

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
		[HARM_TYPE_JUMP]=767,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function cowfish.onInitAPI()
	npcManager.registerEvent(npcID, cowfish, "onTickNPC")
	--npcManager.registerEvent(npcID, cowfish, "onTickEndNPC")
	--npcManager.registerEvent(npcID, cowfish, "onDrawNPC")
	--registerEvent(cowfish, "onNPCKill")
end

function cowfish.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	data.fishtimer = data.fishtimer or 0
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.fishtimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--AI
	data.fishtimer = data.fishtimer + 1
	if data.fishtimer <= 102 then
		v.speedX = 1 * v.direction
	else
		v.speedX = 0
	end
	
	if data.fishtimer >= 132 then
		data.fishtimer = 0
	end
end

--Gotta return the library table!
return cowfish