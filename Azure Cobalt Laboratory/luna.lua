--------------------------------------------------
-- Level code
-- Created 19:51 2020-9-15
--------------------------------------------------

local clearpipe =  require("blocks/ai/clearpipe")
clearpipe.registerNPC(540) 
local spawnzones = API.load("spawnzones") 

local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Azure Cobalt Laboratory",
        [1] = "Laboratory Descent",
		[2] = "Submerged Lab",
        [3] = "Frozen Bonus House",
        [4] = "Bounce Room",
        [5] = "Former Training Room",
        [6] = "Hall of Spirals",
        [7] = "Castle Sewers",
        [8] = "???",
        [9] = "Peppermint Foothills",
        [10] = "Hall of Skewers",
        [11] = "Castle Passage 1",
        [12] = "Castle Passage 2",
        [13] = "Hall of Snowballs",
        [14] = "Preparation Room",
        [15] = "Spirali's Throne",
        [16] = "Snowball Heights",
        [17] = "Peppermint Foothills' Edge",
        [18] = "",
        [19] = "",
        [20] = ""
}

function onEvent(n)
	if n == "Boss Intro" then
		Audio.MusicChange(15, ("Music/Mid-Boss - Spirali.ogg"))
	end
end