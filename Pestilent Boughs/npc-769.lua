
-- AI taken from NPC 578

local nokobon = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 40,
	gfxheight = 32,
	width = 40,
	height = 32,
	frames = 4,
	framespeed = 10,
	framestyle = 1,
	nofireball=true,
	cliffturn = true,
	iswalker = true,
	spawnid = npcID + 1
})
npcManager.registerHarmTypes(npcID,
	{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_HELD, HARM_TYPE_TAIL, HARM_TYPE_SPINJUMP, HARM_TYPE_SWORD, HARM_TYPE_LAVA},
	{[HARM_TYPE_JUMP] = 10,
	[HARM_TYPE_FROMBELOW] = 10,
	[HARM_TYPE_NPC] = npcID,
	[HARM_TYPE_HELD] = npcID,
	[HARM_TYPE_TAIL] = 10,
	[HARM_TYPE_PROJECTILE_USED] = npcID,
	[HARM_TYPE_LAVA]={id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

function nokobon.onNPCKill(eventObj, npc, reason)
	if npc.id == npcID and (reason == 1 or reason == 2 or reason == 7) then
		eventObj.cancelled = true
		npc:transform(NPC.config[npc.id].spawnid)
		if reason == 2 or reason == 7 then
			npc.speedY = -5
		end
		npc.speedX = 0
	end
end

function nokobon.onInitAPI()
	registerEvent(nokobon, "onNPCKill", "onNPCKill")
end

return nokobon
