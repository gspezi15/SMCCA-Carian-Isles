local areaNames = require("areanames")

--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Rosethorn Mountains",
        [1] = "Rosethorn Mountain Ascent",
		[2] = "High Rosethorn Mountain",
        [3] = "Preparation Room",
        [4] = "Arena",
        [5] = "",
        [6] = "",
        [7] = "",
        [8] = "",
        [9] = "",
        [10] = "",
        [11] = "",
        [12] = "",
        [13] = "",
        [14] = "",
        [15] = "",
        [16] = "",
        [17] = "",
        [18] = "",
        [19] = "",
        [20] = ""
        }
        function onEvent(eventname)
	if eventname == "screenlock" then
		Audio.MusicChange (4, "Rosaria Appears.ogg")
	end
end