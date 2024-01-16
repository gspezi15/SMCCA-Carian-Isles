local smwfuzzy = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local config = {
	id = npcID, 
	width = 10, 
    height = 10,
    gfxwidth = 16,
    gfxheight = 16,
    frames = 1,
    nogravity = true,
    spinjumpsafe = false,
    noblockcollision = true,
	jumphurt = true,
    score = 0
}
npcManager.setNpcSettings(config)

return smwfuzzy