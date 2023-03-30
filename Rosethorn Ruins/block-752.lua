--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")

--Create the library table
local sampleBlock = {}
--BLOCK_ID is dynamic based on the name of the library file
local blockID = BLOCK_ID

--Defines Block config for our Block. You can remove superfluous definitions.
local sampleBlockSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8, --# frames between frame change
	bumpable = true,
}

--Applies blockID settings
blockManager.setBlockSettings(sampleBlockSettings)

--Register events
function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onTickEndBlock")
end

function sampleBlock.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data
end

--Gotta return the library table!
return sampleBlock