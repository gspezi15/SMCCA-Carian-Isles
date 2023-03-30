--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local dorrie = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID


--Some code was taken from Elf's Moving Cloud NPC.


--Defines NPC config for our NPC. You can remove superfluous definitions.
local dorrieSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 114,
	gfxwidth = 122,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 58,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = -8,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	playerblocktop=-1,
	

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(dorrieSettings)

--Custom local definitions below


--Register events
function dorrie.onInitAPI()
	npcManager.registerEvent(npcID, dorrie, "onTickEndNPC")
end

function dorrie.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	data.timer = data.timer or false
	
	if settings.startStill and data.timer == false or v.dontMove then
		if v.direction == DIR_LEFT then
			v.animationFrame = 0
		elseif v.direction == DIR_RIGHT then
			v.animationFrame = 2
		end
		for _,p in ipairs(Player.get()) do
			if (p.standingNPC ~= nil and p.standingNPC.idx == v.idx) and settings.startStill then
				v.speedX = 2 * v.direction
				data.timer = true
				break
			end
		end
	else
		v.speedX = 2 * v.direction
	end
	
end

--Gotta return the library table!
return dorrie