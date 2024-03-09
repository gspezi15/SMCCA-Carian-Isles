local npcManager = require("npcManager")
local AI = require("AI/bomberBen")

local sampleNPC = {}
local npcID = NPC_ID
local deathEffectID = npcID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 32,
	gfxwidth = 32,

	width = 32,
	height = 28,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framestyle = 1,
	framespeed = 8,

	speed = 1,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,

	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside = false,
	grabtop = false,
	staticdirection = true,

	defaultSpeed = 6,
	overlapDistance = 16,
	rotationSpeed = 0.05,
	maxSpeed = 8,
	acceleration = 1.01,
}

npcManager.setNpcSettings(sampleNPCSettings)
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
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP] = deathEffectID,
		[HARM_TYPE_FROMBELOW] = deathEffectID,
		[HARM_TYPE_NPC] = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD] = deathEffectID,
		[HARM_TYPE_TAIL] = deathEffectID,
		[HARM_TYPE_SPINJUMP] = 10,
		[HARM_TYPE_OFFSCREEN] = nil,
		[HARM_TYPE_SWORD] = deathEffectID,
	}
);

AI.registerBullet(npcID, AI.HORIZONTAL)

return sampleNPC