
-- AI taken from NPC 579

local nokobon = {}

local npcManager = require("npcManager")

local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 30,
	gfxheight = 42,
	width = 30,
	height = 42,
	frames = 2,
	framespeed = 10,
	framestyle = 0,
	score = 0,
	jumphurt = true,
	spinjumpsafe = false,
	nohurt = true,
	noyoshi=true,
	noiceball=false,
	nofireball=true,
	explosiondelay = 120,
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_FROMBELOW, HARM_TYPE_TAIL, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_NPC, HARM_TYPE_LAVA},
	{[HARM_TYPE_TAIL] = 10,
	[HARM_TYPE_PROJECTILE_USED] = 10,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function nokobon.onTickNPC(npc)
	if Defines.levelFreeze then return end
	if npc:mem(0x12A, FIELD_WORD) <= 0 or npc:mem(0x138, FIELD_WORD) > 0 then
		npc.ai1 = 0
		return
	end


	if not npc.friendly then
		npc.ai1 = npc.ai1 + 1
	end
	-- Copied from the springs NPC
	if npc.collidesBlockBottom then
		npc.speedX = npc.speedX * 0.5
	end
	if npc.ai1 >= NPC.config[npc.id].explosiondelay then
		npc:kill()
	end
end

function nokobon.onDrawNPC(npc)
	if npc:mem(0x12A, FIELD_WORD) <= 0 then return end
	npc.ai5 = 1
	end

function nokobon.onNPCKill(eventObj, npc, reason)
	if npc.id == npcID and npc.ai5 == 1 then
		if reason == 2 or reason == 7 then
			eventObj.cancelled = true
			npc.speedX = 0
			npc.speedY = -5
		elseif reason ~= 9 then
			Explosion.spawn(npc.x + 0.5 * npc.width, npc.y + 0.5 * npc.height, 3)
		end
	end
end

function nokobon.onInitAPI()
	npcManager.registerEvent(npcID, nokobon, "onTickNPC")
	npcManager.registerEvent(npcID, nokobon, "onDrawNPC")
	registerEvent(nokobon, "onNPCKill", "onNPCKill")
end

return nokobon