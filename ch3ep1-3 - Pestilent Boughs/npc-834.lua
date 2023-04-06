--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local redirector = require("redirector")
local npcutils = require("npcs/npcutils")

--Create the library table
local heavy_zed = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local heavy_zedSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 48,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 44,
	height = 48,
	frames = 5,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
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
	ignorethrownnpcs=true,
}

--Applies NPC settings
npcManager.setNpcSettings(heavy_zedSettings)

--Register events
function heavy_zed.onInitAPI()
	npcManager.registerEvent(npcID, heavy_zed, "onTickEndNPC")
end

local movementTableX = {}
local movementTableY = {}

function heavy_zed.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.keepSpeedX = 0
		data.keepSpeedY = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		if settings.behaviour == 1 then
			v.ai2 = 1
		end
		data.keepSpeedX = data.keepSpeedX or 0
		data.keepSpeedY = data.keepSpeedY or 0
	end
	
	v.speedX = data.keepSpeedX
	v.speedY = data.keepSpeedY
	
	if v.ai2 > 0 then
		v.animationFrame = math.floor(lunatime.tick() / 48) % 2
	else
		v.animationFrame = math.floor(lunatime.tick() / 4) % 3 + 2
	end
	
	--If these extra settings are nil
	if settings.speed == nil then
		settings.speed = 1
		settings.behaviour = 0
	end
	
	if v.ai2 <= 0 then
		for _,bgo in ipairs(BGO.getIntersecting(v.x+(v.width/2)-0.5,v.y+(v.height/2),v.x+(v.width/2)+0.5,v.y+(v.height/2)+0.5)) do
			if redirector.VECTORS[bgo.id] then -- If this is a redirector and has a speed associated with it
				local redirectorSpeed = redirector.VECTORS[bgo.id] * settings.speed -- Get the redirector's speed and make it match the speed in the NPC's settings		
				-- Now, just put that speed from earlier onto the NPC
					if v.ai1 <= 0 then
						data.keepSpeedX = redirectorSpeed.x
						data.keepSpeedY = redirectorSpeed.y
						v.ai3 = redirectorSpeed.x
						v.ai4 = redirectorSpeed.y
					else
						data.keepSpeedX = 0
						data.keepSpeedY = 0
					end
			elseif bgo.id == redirector.TERMINUS then -- If this BGO is one of the crosses
				-- Simply make the NPC stop moving
				if v.ai1 <= 0 then
					data.keepSpeedX = 0
					data.keepSpeedY = 0
				else
					data.keepSpeedX = v.ai3
					data.keepSpeedY = v.ai4
				end
			end
		end
	end
	
	--Move via redirector
	if settings.behaviour == 1 then
		
		for _,p in ipairs(Player.get()) do
			if (p.standingNPC ~= nil and p.standingNPC.idx == v.idx) then
				if v.ai2 > 0 then
					SFX.play("Heavy Zed - SML2.wav")
				end
				v.ai2 = v.ai2 - 1
				v.speedX = data.keepSpeedX
				v.speedY = data.keepSpeedY
				v.ai1 = 0
			else
				v.ai1 = 1
				if v.ai2 <= 0 then
					v.speedX = -v.speedX
					v.speedY = -v.speedY
				end
			end
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = heavy_zedSettings.frames
	});
end

--Gotta return the library table!
return heavy_zed