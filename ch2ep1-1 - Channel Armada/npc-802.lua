--[[

	Written by MrDoubleA
	Please give credit!
	
	Credit to Novarender for helping with the logic for the movement of the bullets

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bullet = {}
local npcID = NPC_ID

local deathEffectID = (npcID-3)

local explosionType = Explosion.register(48,69,43,true,false)

local bulletSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 2,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	lifetime = 448,        -- How long the NPC waits before exploding.
	rotationSpeed = 0.015, -- How quickly the NPC rotates.

	explosionType = explosionType, -- The type of explosion the NPC spawns when exploding.
}

npcManager.setNpcSettings(bulletSettings)
npcManager.registerDefines(npcID,{NPC.HITTABLE})
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{ -- Normal death effects have to be spawned manually
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
)




--- Custom Explosion Stuff ---
function bullet.onInitAPI()
	registerEvent(bullet,"onPostExplosion")
	npcManager.registerEvent(npcID, bullet, "onTickEndNPC")
	npcManager.registerEvent(npcID, bullet, "onDrawNPC")
end


function bullet.onTickEndNPC(v)
    if Defines.levelFreeze then return end
    
    local config = NPC.config[v.id]
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.timer = nil
		return
	end

	if not data.timer then
        data.timer = 0
        data.rotation = ((math.pi*1.5)+((math.pi*0.5)*v.direction))%(math.pi*2)

        data.belongsToPlayer = false
    end

    -- Get animation frame
    if data.timer > (config.lifetime*0.65) and ((config.lifetime*0.65)-data.timer)%(config.lifetime*0.08) < (config.lifetime*0.04) then -- Yellow
        v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = (config.frames/2)+(math.floor(data.timer/config.framespeed)%(config.frames/2))})
    else
        v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = (math.floor(data.timer/config.framespeed)%(config.frames/2))})
    end

	if v:mem(0x12C,FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136,FIELD_BOOL)        --Thrown
	or v:mem(0x138,FIELD_WORD) > 0    --Contained within
    then
        if v:mem(0x12C,FIELD_WORD) > 0 then
            data.belongsToPlayer = true
        elseif data.belongsToPlayer then
            v:mem(0x136,FIELD_BOOL,false)
        end

        data.rotation = ((math.pi*1.5)+((math.pi*0.5)*v.direction))%(math.pi*2)
        return
    end

    data.timer = data.timer + 1
    if data.timer > config.lifetime then -- Explosion
        v:mem(0x122,FIELD_WORD,HARM_TYPE_OFFSCREEN) -- Kill the NPC in a slightly unorthodox way, to avoid points being given by the explosion

        if config.explosionType then
            Explosion.spawn(v.x+(v.width/2),v.y+(v.height/2),config.explosionType)
        end
    elseif (data.timer%math.floor(24-(v.speedX+v.speedY))) == 0 then
        local e = Effect.spawn(10,0,0)

        e.x = v.x+(v.width /2)-(math.cos(data.rotation)*(v.width *0.4))-(e.width /2)
        e.y = v.y+(v.height/2)-(math.sin(data.rotation)*(v.height*0.4))-(e.height/2)
    end

    -- Home in on target
    local n -- Player/enemy to home in one

    if data.belongsToPlayer then
        -- Get the nearest enemy
        for _,w in ipairs(NPC.get(NPC.HITTABLE)) do
            if w.idx ~= v.idx and not w.isGenerator and not w.isHidden and w.despawnTimer > 0 and not w.friendly and not NPC.config[w.id].nohurt
            and ((not n) or math.abs((w.x+(w.width/2))-(v.x+(v.width/2)))+math.abs((w.y+(w.height/2))-(v.y+(v.height/2))) < math.abs((n.x+(n.width/2))-(v.x+(v.width/2)))+math.abs((n.y+(n.height/2))-(v.y+(v.height/2))))
            then
                n = w
            end
        end
    else
        n = Player.getNearest(v.x+(v.width/2),v.y+(v.height/2)) -- Get the nearest player
    end

    local rotationSpeed = 0
    
    if n then
        local angle = math.atan2((n.y+(n.height/2))-(v.y+(v.height/2)),(n.x+(n.width/2))-(v.x+(v.width/2)))%(math.pi*2)

        local normalDistance = math.abs(angle-data.rotation) -- How far it'd have to rotate to turn around normallt
        local loopDistance = math.min(math.abs(angle-(data.rotation+(math.pi*2))),math.abs(angle-(data.rotation-(math.pi*2)))) -- How far it'd have to rotate to loop around

        rotationSpeed = math.min(normalDistance,loopDistance)*config.rotationSpeed

		if (data.rotation > angle) ~= (normalDistance > loopDistance) then
			data.rotation = (data.rotation-rotationSpeed)%(math.pi*2) -- CCW
		else
			data.rotation = (data.rotation+rotationSpeed)%(math.pi*2) -- CW
		end
    end

    -- Move in the appropriate direction
    v.speedX = math.cos(data.rotation)*math.max(0,2-(math.abs(rotationSpeed)*20))*2.5
    v.speedY = math.sin(data.rotation)*math.max(0,2-(math.abs(rotationSpeed)*20))*2.5*config.speed
end

function bullet.onDrawNPC(v)
    if v.despawnTimer <= 0 then return end
    
    local config = NPC.config[v.id]
	local data = v.data

	if not data.sprite then
		data.sprite = Sprite{texture = Graphics.sprites.npc[v.id].img,frames = npcutils.getTotalFramesByFramestyle(v)}
	end

	local priority = -45
	if config.priority then
		priority = -15
	end

	data.sprite.x = v.x+(v.width/2)
	data.sprite.y = v.y+v.height-(config.gfxheight/2)

	data.sprite.rotation = math.deg(data.rotation or 0)

	data.sprite.pivot = Sprite.align.CENTRE
	data.sprite.texpivot = Sprite.align.CENTRE

	data.sprite:draw{frame = v.animationFrame+1,priority = priority,sceneCoords = true}

	npcutils.hideNPC(v)
end



function bullet.onPostExplosion(v,p)
	if NPC.config[npcID].explosionType <= 5 or v.id ~= NPC.config[npcID].explosionType then return end

	for x=-1,1,2 do
		for y=-1,1,2 do
			local e = Effect.spawn(10,0,0)

			e.x = v.x-(x*(v.radius/2))-(e.width /2)
			e.y = v.y-(y*(v.radius/2))-(e.height/2)
		end
	end

	if not v.strong then return end

	-- Destroy some extra blocks
	for _,w in ipairs(Colliders.getColliding{a = v.collider,b = Block.MEGA_STURDY,btype = Colliders.BLOCK}) do
		w:remove(true,Player(0))
	end
end



return bullet