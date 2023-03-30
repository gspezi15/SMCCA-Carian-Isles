local blockManager = require("blockManager")

local sampleBlock = {}
local blockID = BLOCK_ID


function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onCollideBlock")
end

function sampleBlock.onCollideBlock(block,hitter)
	if type(hitter) == "Player" then
		hitter:harm()
	end
end


return sampleBlock