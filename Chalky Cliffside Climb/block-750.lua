local blockManager = require("blockManager")

local hangblocks = require("hangblocks")

local grabRope = {}
local blockID = BLOCK_ID

--Defines Block config for our Block. You can remove superfluous definitions.
local grabRopeSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, --# frames between frame change

	passthrough = true,
}

--Applies blockID settings
blockManager.setBlockSettings(grabRopeSettings)

hangblocks.register(blockID)

--Gotta return the library table!
return grabRope