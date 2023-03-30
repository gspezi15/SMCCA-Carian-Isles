--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local grafAI = require("AI/grafMovementAmp")

--Create the library table
local amp = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local ampSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	width = 28,
	height = 28,
	frames = 8,
	framestyle = 0,
	framespeed = 8, 
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	
	lightradius = 65,
	lightbrightness = 1,
	lightcolor = Color.yellow,
	lightflicker = true
}

local settings = {
	id = npcID
}

--Applies NPC settings
npcManager.setNpcSettings(ampSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
	}, 
	{
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_HELD]=npcID,
	}
);


grafAI.register(settings)

--Gotta return the library table!
return amp