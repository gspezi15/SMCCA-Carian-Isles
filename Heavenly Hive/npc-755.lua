--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

-------------------------------------------
--                                       --
-- Block hit detection help by MrDoubleA --
--                                       --
-------------------------------------------


--Create the library table
local bird = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local birdSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 48,
	width = 48,
	height = 32,
	frames = 4,
	framestyle = 1,
	framespeed = 6,
	speed = 2,
	
	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 
	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,
	

}

--Applies NPC settings
npcManager.setNpcSettings(birdSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
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
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function bird.onInitAPI()
	npcManager.registerEvent(npcID, bird, "onTickNPC")
	--npcManager.registerEvent(npcID, bird, "onTickEndNPC")
	--npcManager.registerEvent(npcID, bird, "onDrawNPC")
	--registerEvent(bird, "onNPCKill")
end

function bird.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
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

v.speedX = 1 * v.direction
       -- Get hit by bumped blocks below
    for _,block in ipairs(Block.getIntersecting(v.x,v.y+v.height,v.x+v.width,v.y+v.height+1)) do
        if block:mem(0x56,FIELD_WORD) < 0 or block:mem(0x54,FIELD_WORD) > 0 then -- If the block is being bumped upwards
            v:harm(HARM_TYPE_FROMBELOW)
            break -- We've already been hit, so we can exit the loop
        end
    end
end

--Gotta return the library table!
return bird