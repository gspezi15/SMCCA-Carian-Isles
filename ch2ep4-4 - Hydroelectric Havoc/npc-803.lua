local rng = require ("rng")
local npcManager = require ("npcManager")

local baronsparky = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
		id=npcID,
		gfxheight=64,
		gfxwidth=64,
		width=48,
		height=48,
		frames=2,
		framestyle=0,
		jumphurt=1,
		nogravity=1,
		noblockcollision=1,
		nofireball=1,
		noiceball=1,
		xspeed=1,
		yspeed=1.5,
		xspread=250,
		yspread=64,
		score=0,
		noyoshi=1,
		spinjumpsafe=true,
		splits=4,
		lightradius=128,
		lightbrightness=2,
		lightcolor=Color.orange,
		spawnid = 804,
		splitid = 352,
		ishot = true,
		durability = -1,
		health = 3
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_NPC]=0,
		[HARM_TYPE_HELD]=0,
		[HARM_TYPE_PROJECTILE_USED]=0,
		[HARM_TYPE_SWORD]=0
	}
);

function baronsparky.onInitAPI()
	npcManager.registerEvent(npcID, baronsparky, "onTickEndNPC")
	registerEvent(baronsparky, "onNPCKill", "onNPCKill", true)
end


function baronsparky.onNPCKill (eventObj, killedNPC, killReason)
	-- Manage big guy's HP
	if  killedNPC.id == npcID  and  killReason ~= 1 and killReason ~= 9 then
		eventObj.cancelled = true
		SFX.play(39)
		local data = killedNPC.data._basegame
		if data.hurtTimer == nil then
			data.hurtTimer = 0
			data.hp = data.hp or NPC.config[v.id].health or 3
		end
		if data.hurtTimer <= 0 then
			data.hp = data.hp - 1
			data.hurtTimer = rng.randomInt(60,70)
		end
	end
end

function baronsparky.onTickEndNPC(v)
	-- Only update the behavior when the level is not frozen
	if  Defines.levelFreeze  then  return;  end;
	
	local data = v.data._basegame;
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.startTimer = nil
		data.homeX = nil
		return
	end
	
	local cfg = NPC.config[v.id]
	-- Initialize the data if it doesn't exist yet
	if data.startTimer == nil then
		data.startTimer = 65
		data.fireTimer = 15
		data.hurtTimer = data.hurtTimer or 0
		data.xTimer = 0
		data.yTimer = 0
		data.hp = data.hp or cfg.health or 3
		data.xSpeed = cfg.xspeed
		data.ySpeed = cfg.yspeed
		data.xSpread = cfg.xspread
		data.ySpread = cfg.yspread
		data.initFriendly = data.initFriendly or v.friendly
	end
	if data.hp > 0 or data.hurtTimer > 0 then
		
		-- Determine the target --section cause the target variable wasn't used for anything else
		local section = v:mem(0x146, FIELD_WORD)


		-- Wrap around section boundaries
		--[[
		if  (v.x > sectionBounds.right)  then
			local homeXDiff = data.homeX - sectionBounds.right
			data.homeX = sectionBounds.left + homeXDiff

		elseif  (v.x < sectionBounds.left)  then
			local homeXDiff = data.homeX - sectionBounds.left
			data.homeX = sectionBounds.right + homeXDiff
		end
		--]]

		data.hurtTimer  = data.hurtTimer - 1
		local isHeld = v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x130, FIELD_WORD) > 0
		if not isHeld then
			if data.homeX == nil then
				data.startX = v.x
				data.startY = v.y
				data.homeX = data.startX
				data.homeY = data.startY
			end
			data.startTimer = data.startTimer - 1

			if  data.startTimer <= 0  and  data.hurtTimer <= 0  then
				data.xTimer     = (data.xTimer + data.xSpeed) % 360
				data.yTimer     = (data.yTimer + data.ySpeed) % 360
				data.fireTimer  = data.fireTimer  - 1
			end


			-- Move in separate sine waves
			if not v.dontMove then
				v.x = data.homeX + data.xSpread*math.sin(math.rad(data.xTimer))
			end
			v.y = data.homeY - data.ySpread*(math.sin(math.rad(data.yTimer - 90)) + 1)


			-- Attacking
			if  data.fireTimer <= 0  then
				local fireball = NPC.spawn(cfg.spawnid, v.x+v.width*0.5, v.y+v.height-4, section, false, true)
				SFX.play(62)
				fireball.friendly = v.friendly
				fireball.layerName = "Spawned NPCs"

				fireball.speedY = 1
				--fireball.speedX = -1
				--if  targetIsLeft  then  fireball.speedX = fireball.speedX * -1;  end;

				-- Determine the next delay based on how many were fired in a row
				data.fireTimer = 100
			end
		end

		-- Invincibility
		v.friendly = data.initFriendly
		if  data.hurtTimer > 0  then
			v:mem(0x156, FIELD_WORD, 30)
			v:mem(0x26, FIELD_WORD, 30)
			v.friendly = true
		end

		-- Update the animation
		v.animationFrame = v.animationFrame % 4
	else
		local section = v:mem(0x146, FIELD_WORD)
		Animation.spawn(69, v.x + 32, v.y + 32) 
		SFX.play(43)
		v:kill()
	end
end

return baronsparky