--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local roketon = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local roketonSettings = {
	id = npcID,
	gfxheight = 64,
	gfxwidth = 56,
	width = 56,
	height = 50,
	frames = 1,
	framestyle = 1,
	framespeed = 8, 
	speed = 1.8,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	score = 4,

	grabside=false,
	grabtop=false,
	radius = 64,
}

--Applies NPC settings
npcManager.setNpcSettings(roketonSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]={id=108, xoffset=0.5, xoffsetBack = 0, yoffset= 2.5, yoffsetBack = 1.5},
		[HARM_TYPE_PROJECTILE_USED]={id=108, xoffset=0.5, xoffsetBack = 2.5, yoffset= 0, yoffsetBack = 1.5},
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]={id=108, xoffset=0.5, xoffsetBack = 0, yoffset= 2.5, yoffsetBack = 1.5},
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]={id=108, xoffset=0.5, xoffsetBack = 0, yoffset= 2.5, yoffsetBack = 1.5},
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]={id=108, xoffset=0.5, xoffsetBack = 0, yoffset= 2.5, yoffsetBack = 1.5},
	}
);


--Register events
function roketon.onInitAPI()
	npcManager.registerEvent(npcID, roketon, "onTickNPC")
	registerEvent(roketon, "onNPCKill")
end

function roketon.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	local targetedplayer = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.attackTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.radius = cfg.radius or 64
		data.attackTimer = data.attackTimer or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	then
		data.attackTimer = -1
	end

	v.speedX = cfg.speed * v.direction
	
	if data.attackTimer <= 1 then
		v.speedY = 0
	end
	
	if data.attackTimer > 0 then 
		data.attackTimer = data.attackTimer - 1
		if v.y ~= v.spawnY and data.attackTimer <= 0 then
			SFX.play(37)
			local originX = v.x + 0.5 * v.width
			local originY = v.y + 0.5 * v.height + 8
			local projectile = NPC.spawn(npcID - 1, originX, originY + 16, targetedplayer.section, false, true)

			projectile.speedX = 2 * -v.direction
			local traveltime = math.max((targetedplayer.x - originX) / projectile.speedX, 1)
			projectile.speedY = (targetedplayer.y - originY) / traveltime
			projectile.speedY = math.min(math.max(projectile.speedY, -2), 2)
			data.attackTimer = -1
		else
			if data.up then
				v.speedY = 2.8
			else
				v.speedY = -2.8
			end
		end
	end
	
	if math.abs(targetedplayer.x-v.x)<=data.radius then
		if data.attackTimer == 0 and v:mem(0x138, FIELD_WORD) == 0 then
			data.attackTimer = 32
			if player.y >= v.y then
				data.up = true
			else
				data.up = false
			end
		end
	end	

end

function roketon.onNPCKill(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if reason ~= HARM_TYPE_JUMP then
		SFX.play(65)
	end
end

--Gotta return the library table!
return roketon