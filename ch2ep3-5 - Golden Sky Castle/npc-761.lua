local npcManager = require("npcManager")
local particles = require("particles")

local star = {}

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

local config = {
	id = npcID,
	gfxheight = 32,
    gfxwidth = 32,
	width = 28,
	height = 32,
    frames = 6,
    framestyle = 0,
	framespeed = 4, 
    nofireball=0,
	nogravity=1,
	noblockcollision = 1,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true
}

npcManager.setNpcSettings(config)


function star.onInitAPI()
	npcManager.registerEvent(npcID, star, "onTickEndNPC")
end

function star.onTickEndNPC(t)
		--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = t.data
end

return star;
