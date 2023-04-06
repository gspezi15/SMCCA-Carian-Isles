--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local colliders = require("Colliders")

--Create the library table
local walker = {}

--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local walkerSettings = {
	id = npcID,
	gfxheight = 26,
	gfxwidth = 44,
	width = 44,
	height = 26,
	frames = 2,
	framestyle = 1,
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
	cliffturn = true,
	nowaterphysics = false,

	jumphurt = false,
	spinjumpsafe = false, 
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,


	--Identity-related flags. Apply various vanilla AI based on the flag:
	iswalker = true,
	
}

--Applies NPC settings
npcManager.setNpcSettings(walkerSettings)

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
		[HARM_TYPE_JUMP]=npcID,
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

--Gotta return the library table!
return walker