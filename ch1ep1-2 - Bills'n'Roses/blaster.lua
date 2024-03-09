local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local blaster = {}

local npcID = NPC_ID
local npcIDs = {}

function blaster.register(id)
	npcManager.registerEvent(id, blaster, "onTickNPC")
	npcManager.registerEvent(id, blaster, "onDrawNPC")
	
	npcIDs[id] = true
end

function blaster.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local cfg = NPC.config[v.id]
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		
		data.timer = settings.delay / 2
		data.blastTimer = settings.amountDelay + 1
		data.canFire = true
		data.amount = settings.amount
		data.firing = false
	end
	
	if not cfg.oneway then
		npcutils.faceNearestPlayer(v)
	end
	
	if not settings.alwaysfire then
		if not data.firing then
			if not cfg.oneway then
				if player.x + player.width > v.x - player.width and player.x < (v.x + v.width + player.width) then
					data.canFire = false
					data.timer = settings.delay / 2
				else
					data.canFire = true
				end
			elseif cfg.oneway then
				if v.direction == -1 then
					if player.x + player.width > v.x - player.width and player.x < (v.x + v.width) then
						data.canFire = false
						data.timer = settings.delay / 2
					else
						data.canFire = true
					end
				elseif v.direction == 1 then
					if player.x + player.width > v.x and player.x < (v.x + v.width + player.width) then
						data.canFire = false
						data.timer = settings.delay / 2
					else
						data.canFire = true
					end
				end
			end
		end
	end
	
	data.timer = data.timer + 1
	
	--Text.print(data.timer, 10, 10)
	--Text.print(data.blastTimer, 10, 40)
	
	--The main firing code
	if data.timer >= settings.delay then
		if data.canFire then
			data.firing = true
			
			data.blastTimer = data.blastTimer - 1
			
			if data.blastTimer >= settings.amountDelay then
				if v.ai1 == 0 then
					n = NPC.spawn(17, v.x, v.y) --Spawns a regular Bullet Bill if there is no projectile set
				else
					n = NPC.spawn(v.ai1, v.x, v.y) --If there is a projectile set, spawn it instead
				end
				
				if v.direction == -1 then
					Effect.spawn(10, v.x - 32, v.y + (v.height / 2) - 16)
					n.x = v.x - n.width
					n.y = v.y + (v.height / 2) - (n.height / 2)
				elseif v.direction == 1 then
					Effect.spawn(10, v.x + v.width, v.y + (v.height / 2) - 16)
					n.x = v.x + v.width
					n.y = v.y + (v.height / 2) - (n.height / 2)
				end
				
				n.y = v.y + (v.height / 2) - (n.height / 2)
				n.direction = v.direction
				
				if cfg.fireSFX == nil then
					SFX.play(22)
				else
					SFX.play(cfg.fireSFX)
				end
				
				data.amount = data.amount - 1
			end
			
			if data.blastTimer <= 0 then
				data.blastTimer = settings.amountDelay + 1
			end
		end
		
		--Reset stuff if the amount is 0
		if data.amount <= 0 then
			data.timer = 0
			data.blastTimer = settings.amountDelay + 1
			data.amount = settings.amount
			data.firing = false
		end
	end
end

--Gotta return the library table!
return blaster