-- Rollingball by Novarender, I modified it to make it just ba ll --

--Clean up a couple of things in this file
--Make sure to do the throwing code + all the "validity" checks for NPCs, Blocks and Player's throwing
--Fix broken boss hit mechanics
--Configs
--Rename rollingball assets

--Throwing mechanics:
--Minimum cooldown: .5 sec
--Maximum cooldown: 6 sec
--Limit: 2 rollingballs at once
-- Limit can be broken with maxiumum cooldown

local rollingball = {}
local npcMan = require("npcManager")
local npcUt = require("npcs/npcutils")

-- This library comes with the following hooks:
--[[

onTick - After ball tick
onDraw - After ball draw
onBump - When the ball bumps

]]

local bouncy = table.map{458, 582, 583, 584, 585, 594, 595, 596, 597, 598, 599}
--Move to configs

do
    function rollingball.onInitAPI()
        rollingball.hittable = table.map(NPC.HITTABLE)
        registerEvent(rollingball, "onTick")
        registerEvent(rollingball, "onDraw")
        registerEvent(rollingball, "onStart")
    end

    function rollingball.registerID(id)
        npcMan.registerEvent(id,rollingball,"onDrawNPC")
        npcMan.registerEvent(id,rollingball,"onTickNPC")
        rollingball.activeID = id --You can get rid of this and/or edit the script to suit your needs
        rollingball.effectID = rollingball.activeID
    end

    function rollingball.initNPC(v)
        local d = v.data
        local s = d._settings
        local config = NPC.config[v.id]

        if v.despawnTimer <= 0 then
            d.init = false
            return
        end
        if not d.init then
            d.init = true
            d.rV = 0
            d.rotation = 0
            d.prevSpeedY = 0
            rollingball.addEmitter(v)
        end

        return d
    end

    function rollingball.killNPC(v)
        v:kill()
        SFX.play(9)
        Effect.spawn(rollingball.effectID, v.x, v.y)
    end

    function rollingball.addEmitter(v)
        local emt = {}
        emt.emitter = Particles.Emitter(v.x + v.width/2, v.y + v.height, Misc.resolveFile("smoketrail.ini"));
        emt.timer = 0
        emt.npc = v
        table.insert(rollingball.emitters, emt)
    end

    rollingball.emitters = {}
end

function rollingball.onTickNPC(v)
    local d = rollingball.initNPC(v)
    if not d then return end
    local c = NPC.config[v.id]
    --[[ ================ ]]--

    local cancelNPCTurnaround = true

    --Ball physics
    if v.direction == -1 then
        if c.minimumSpeed >= 0 and v.speedX > -1.5 then
            v.speedX = v.speedX + math.max(-0.1, -3.2 - v.speedX)
        end
        if c.maximumSpeed >= 0 and v.speedX < -c.maximumSpeed then
            v.speedX = -c.maximumSpeed
        end
    else
        if c.minimumSpeed >= 0 and v.speedX < 1.5 then
            v.speedX = v.speedX + math.min(0.1, 3.2 - v.speedX)
        end
        if c.maximumSpeed >= 0 and v.speedX > c.maximumSpeed then
            v.speedX = c.maximumSpeed
        end
    end    
    d.rotation = d.rotation + d.rV
    d.prevSpeedY = v.speedY

    
    --Searching for interacting blocks and NPCs
    for _,b in Block.iterateIntersecting(v.x + v.speedX, v.y + v.speedY - 2, v.x + v.width + v.speedX, v.y + v.height + v.speedY + 2) do
        if not b.isHidden then
            --Check for slope
            local isHard = c.strongBreak[b.id] 
            local canBreak = c.breakable[b.id] or isHard
            if ((b.x > v.x + v.width - 4 and v.speedX > 0) or (b.x + v.width < v.x + 4 and v.speedX < 0)) and b.y < v.y + v.height and b.y + b.height > v.y + 1 then
                -- Misc.dialog(b.y + b.height - (v.y + 1), b.y + b.height > v.y, b.y + b.height, v.y)
                if b.contentID > 0 then
                    b:hit()
                elseif canBreak then
                    b:remove(true)
                    if isHard then
                        rollingball.killNPC(v)
                    end
                end
            end
            -- if b.y < v.y + v.height and b.y + b.height > v.y then --Impromptu wall collision
            --     v:kill()
            -- end
        end
    end
    for _,n in NPC.iterateIntersecting(v.x + v.speedX - 12, v.y + v.speedY, v.x + v.width + v.speedX + 12, v.y + v.height + v.speedY + 2) do --I couldn't figure out how to make colliders work with a constantly changing hitbox size
        if bouncy[n.id] then
            cancelNPCTurnaround = false
        end
        if n.x + n.width > v.x + v.speedX or n.x < v.x + v.width + v.speedX then
            if rollingball.hittable[n.id] then
                n:harm()
            end
        end
    end
    
    --Setting some NPC properties
    if cancelNPCTurnaround then
        v:mem(0x120,FIELD_BOOL,false) --Disable block turnaround
        v:mem(0x12E,FIELD_WORD,100)  --Disabling NPC turnaround (throw timer)
        v:mem(0x136,FIELD_BOOL,true)  --Is a projectile
    else
        v:mem(0x12E,FIELD_WORD,0)
    end

    if v.collidesBlockRight or v.collidesBlockLeft then
        --Note: due to :cloudigit:, there's a bug in the collision of NPCs where they think they've hit a wall when brushing against a wall while moving away from it. This can happen from moving upwards/downwards and horizontally while brushing against a corner.
        --This can be observed by shooting right at x = -199743.63 in my test level. Shoot at the corner and the ball will make a "bump" noise. Before I fixed it using actuallyCollides, it would just kill the ball instead!

        local x, x2
        local y, y2 = v.y, v.y+v.height
        if v.speedX < 0 then
            x, x2 = v.x-2, v.x
        else
            x, x2 = v.x+v.width, v.x+v.width+2
        end

        local actuallyCollides
        for _,b in Block.iterateIntersecting(x, y, x2, y2) do
            if not b.isHidden then
                actuallyCollides = true
                break
            end
        end
        for _,n in NPC.iterateIntersecting(x, y, x2, y2) do
            if NPC.config[n.id].npcblock then
                actuallyCollides = true
            end

            --Random NPC interactions on bump
            if n.id == 241 then
                n.speedY = 2.01
            end
        end

        if actuallyCollides then
            for _,n in NPC.iterateIntersecting(x, y, x2, y2) do
                if n.id == 241 then
                    n.speedY = 2.01
                end
            end

            rollingball.killNPC(v)
            return
        end
    end
end

-- --Might store emitters separately and manually move them to the npcs, stop their flow when the NPC dies, update them even during clear pipe travel, etc.

-- function rollingball.onStart()
--     mem(0x00B2C5AC, FIELD_FLOAT, 5)
-- end
function rollingball.onDrawNPC(v)
    local d = rollingball.initNPC(v)
    if not d then return end

    if v.collidesBlockBottom then
        local c = v.width*math.pi --Circumference
        d.rV = v.speedX/c * 360 --angle to rotate (rotational velocity)
        if d.prevSpeedY > 6.75 then --The reason this is in onDraw is to negate the bounce inherited from being a projectile.
            v.speedY = -d.prevSpeedY*0.45
        end
    end

    -- Graphics.drawBox { --Check out the good ol' sprited frames method -- 4 frames of rotation, animation speed dependent on rotational velocity      
    --     x = v.x + v.width/2,
    --     y = v.y + v.height/2,
    --     width = v.width,
    --     height = v.height,

    --     sourceY = v.height*v.animationFrame,
    --     sourceHeight = v.height,

    --     sceneCoords = true,
    --     priority = -44,
    --     rotation = math.floor(d.rotation/45)*45,
    --     centered = true,
    --     texture = Graphics.sprites.npc[v.id].img
    -- }
    -- npcUt.hideNPC(v)
end


function rollingball.onDraw()
    local numEmitters = #rollingball.emitters
    for k = numEmitters, 1, -1 do
        local v = rollingball.emitters[k]
        local n = v.npc
        local e = v.emitter

        if not n then
            v.timer = v.timer - 1/65 --1 frame is 1/65 of a second
        elseif not n.isValid then
            v.npc = nil
            v.timer = 1 --Wait for all particles to die (1 sec)
        elseif not Misc.isPaused() then
            e.x = n.x + n.width/2 - math.sign(n.speedX)*2
            e.y = n.y + n.height
            if n.collidesBlockBottom then
                v.timer = v.timer - (math.random()*0.3846154 + 0.1076923) * math.abs(n.speedX)/3.2 --7 to 32 per second, modified by speed
                if v.timer <= 0 then
                    v.timer = v.timer + 1 --Resets to ~ 1
                    e:Emit()
                end
            end
        end
        if v.timer < 0 and not n then
            v.emitter:Destroy()
            table.remove(rollingball.emitters, k)
        else
            e:Draw()
        end
    end
end

return rollingball