local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")

local ben = {}

ben.npcList = {}
ben.npcMap = {}

ben.bulletList = {}
ben.bulletMap = {}

ben.VERTICAL = 1
ben.HORIZONTAL = 2

local types = {
	[ben.VERTICAL]   = {x = "x", y = "y", w = "width", h = "height", speedX = "speedX", speedY = "speedY"},
	[ben.HORIZONTAL] = {x = "y", y = "x", w = "height", h = "width", speedX = "speedY", speedY = "speedX"},
}

local STATE = {
	IDLE = 0,
	SHOOT = 1,
	ROTATE = 1,
	MOVE = 2,
}


function ben.register(id)
	npcManager.registerEvent(id, ben, "onTickNPC", "onTickBen")
	npcManager.registerEvent(id, ben, "onDrawNPC")
	table.insert(ben.npcList, id)
	ben.npcMap[id] = true
end


function ben.registerBullet(id, typ)
	npcManager.registerEvent(id, ben, "onTickNPC", "onTickBullet")
	npcManager.registerEvent(id, ben, "onDrawNPC")
	table.insert(ben.bulletList, id)
	ben.bulletMap[id] = typ
end


-----------------
-- Bomber Bens --
-----------------

function ben.onTickBen(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		if not v.ai1 or v.ai1 == 0 then
			v.ai1 = config.projectileID
		end
		
		data.initialized = true
		data.state = STATE.IDLE
		data.projectileDir = 1
		data.timer = 0
		data.faceDir = 1

		v.speedX = config.idleSpeed * v.direction
	end

	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
		return
	end

	if data.state == STATE.IDLE and v.ai1 > 0 then
		for _, p in ipairs(Player.get()) do
			if p.section == v.section
			and (v.y + v.height/2) < (p.y + p.height/2)
			and math.abs((p.x + p.width/2) - (v.x + v.width/2)) <= config.overlapDistance
			then
				data.projectileDir = math.sign((p.x + p.width/2) - (v.x + v.width/2))
				data.state = STATE.SHOOT
				break
			end
		end
	elseif data.state == STATE.SHOOT then
		local absSpeed = math.abs(v.speedX)

		if absSpeed > 1 then
			absSpeed = absSpeed * config.deceleration
			v.speedX = absSpeed * v.direction
		end

		if absSpeed <= 2 then
			local x = v.speedX + v.x + v.width/2 + config.spawnOffset.x * v.direction
			local y = v.speedY + v.y + v.height/2 + config.spawnOffset.y
			local n = NPC.spawn(v.ai1, x, y, v.section, false, true)

			n.speedX = config.projectileSpeed.x * n.direction
			n.speedY = config.projectileSpeed.y
			n.friendly = v.friendly

			local e = Effect.spawn(config.shootEffect, x, y)

			e.x = e.x - e.width/2
			e.y = e.y - e.height/2

			if ben.bulletMap[n.id] then
				n.data.stuffAlreadySet = true
				n.data.faceDir = data.projectileDir
				n.direction = 1
			end

			data.state = STATE.MOVE
		end
	elseif data.state == STATE.MOVE then
		local absSpeed = math.abs(v.speedX)

		if absSpeed < config.idleSpeed then
			absSpeed = math.max(absSpeed * config.acceleration, config.idleSpeed)
			v.speedX = absSpeed * v.direction
		else
			data.state = STATE.IDLE
		end
	end

	if data.timer % math.floor(1.5 * config.idleSpeed/v.speedX) == 0 then
		local e = Effect.spawn(config.smokeEffect, v.x + v.width/2 - (v.width/2 + 4) * v.direction, v.y + v.height/2)
		e.x = e.x - e.width/2
		e.y = e.y - e.height/2
	end

	data.timer = data.timer + 1
end


-------------
-- Bullets --
-------------

function ben.onTickBullet(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local fields = types[ben.bulletMap[v.id]]

	local x, y, w, h, speedX, speedY = fields.x, fields.y, fields.w, fields.h, fields.speedX, fields.speedY

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = STATE.IDLE
		data.angleLerp = 0
		data.moveDir = v.direction
		data.targetAngle = 0
		data.rotation = 0

		if not data.stuffAlreadySet then
			if ben.bulletMap[v.id] == ben.VERTICAL then
				local p = npcutils.getNearestPlayer(v)
				data.faceDir = math.sign((p.x + p.width/2) - (v.x + v.width/2))
			else
				data.faceDir = 1
			end

			v[speedX] = 0
			v[speedY] = config.defaultSpeed * v.direction
		end
	end

	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
		if v:mem(0x136, FIELD_BOOL) then
			v:mem(0x136, FIELD_BOOL, false)
		else
			return
		end
	end

	if data.state == STATE.IDLE then
		for _, p in ipairs(Player.get()) do
			if p.section == v.section and math.abs((p[y] + p[h]/2) - (v[y] + v[h]/2)) <= config.overlapDistance then
				local dir = math.sign((p[x] + p[w]/2) - (v[x] + v[w]/2))

				data.state = STATE.ROTATE
				data.moveDir = dir
				v[speedX] = 0
				v[speedY] = 0

				data.targetAngle = -90 * dir

				if ben.bulletMap[v.id] == ben.VERTICAL then
					data.faceDir = -dir * v.direction
					data.targetAngle = data.targetAngle * v.direction
				else
					data.targetAngle = data.targetAngle * -v.direction
				end

				break
			end
		end
	elseif data.state == STATE.ROTATE then
		data.angleLerp = math.min(data.angleLerp + config.rotationSpeed, 1)
		data.rotation = easing.outQuad(data.angleLerp, 0, data.targetAngle, 1)

		if data.angleLerp == 1 then
			data.state = STATE.MOVE
		end
	elseif data.state == STATE.MOVE then
		local absSpeed = math.abs(v[speedX])

		if absSpeed < config.maxSpeed then
			absSpeed = math.max(absSpeed * config.acceleration, config.maxSpeed)
			v[speedX] = absSpeed * data.moveDir
		end
	end
end


function ben.onDrawNPC(v)
	if v.isHidden or v.despawnTimer <= 0 then return end

	local config = NPC.config[v.id]
	local data = v.data

	Graphics.drawBox{
		texture = Graphics.sprites.npc[v.id].img,
		x = v.x + v.width/2 + config.gfxoffsetx * v.direction,
		y = v.y + v.height/2 + config.gfxoffsety,
		sourceX = 0,
		sourceY = v.animationFrame * config.gfxheight,
		sourceWidth = config.gfxwidth,
		sourceHeight = config.gfxheight,
		width = config.gfxwidth * (data.faceDir or 1),
		height = config.gfxheight,
		priority = (config.foreground and -15) or -45,
		sceneCoords = true,
		centered = true,
		rotation = data.rotation or 0,
	}

	npcutils.hideNPC(v)
end

return ben