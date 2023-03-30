--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")
local blockutils = require "blocks/blockutils"

--Create the library table
local sampleBlock = {}
--BLOCK_ID is dynamic based on the name of the library file
local blockID = BLOCK_ID

--Defines Block config for our Block. You can remove superfluous definitions.
local sampleBlockSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8, --# frames between frame change

	--Identity-related flags:
	--semisolid = false, --top-only collision
	sizable = true, --sizable block
	passthrough = true, --no collision
	--bumpable = false, --can be hit from below
	--lava = false, --instakill
	--pswitchable = false, --turn into coins when pswitch is hit
	--smashable = 0, --interaction with smashing NPCs. 1 = destroyed but stops smasher, 2 = hit, not destroyed, 3 = destroyed like butter

	--floorslope = 0, -1 = left, 1 = right
	--ceilingslope = 0,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies blockID settings
blockManager.setBlockSettings(sampleBlockSettings)

--Register the vulnerable harm types for this Block. The first table defines the harm types the Block should be affected by, while the second maps an effect to each, if desired.

--Custom local definitions below
local timerDefaults = {0,9999}
local filterIds = {626,627,628,629,632,640,642,644,646,648,650,652,654,656,660,664}

--Register events
function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onTickBlock")
	--registerEvent(sampleBlock, "onBlockHit")
end

local function seeifblocksaboveplayer(p)

	local b = Block.getIntersecting(p.x, p.y-1, p.x+p.width, p.y)
	local inactiveBlock = filterIds[p.character]

	for i=1,#b do
		local bl = b[i]

		-- awful
		if     not Block.NONSOLID_MAP[bl.id]
		   and not Block.SEMISOLID_MAP[bl.id]
		   and bl.id ~= 658 and bl.id ~= 1282
		   and bl.id ~= inactiveBlock
		   and bl.id ~= blockID
		   and blockutils.hiddenFilter(bl)
		   then
			return true
		end
	end

	return false

end

function sampleBlock.onTickBlock(v)
    -- Don't run code for invisible entities
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local settings = data._settings
	local type = settings.fieldtype or 0

	data.playerTimers = data.playerTimers or {}

	local t = Player.get()
	for i=1,#t do
		local p = t[i]
		if not Colliders.collide(p, v) then
			data.playerTimers[p.idx] = timerDefaults[type+1]
		else

			data.playerTimers[p.idx] = data.playerTimers[p.idx] or timerDefaults[type+1] -- initialize the timer if it hasn't been already

			if type == 0 then -- sap

				if data.playerTimers[p.idx] > 0 then p.speedY = p.speedY * settings.sap.yspeedmult -- fall slower while in the sap and after the timer becomes >0
				end
				p.speedX = p.speedX * settings.sap.xspeedmult -- move slower while in the sap

				if p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED then -- if we jump
					p.speedY = -settings.sap.swimforce -- set our vertical speed

					data.snd = data.snd or Misc.resolveSoundFile(settings.sap.soundname)
					SFX.play(data.snd) -- play the swim sound

					data.playerTimers[p.idx] = 0 -- set the timer to 0.
				end

				if data.playerTimers[p.idx] < settings.sap.timer then -- before two thirds of a second (by default) pass after jumping,
					p.speedY = math.min(p.speedY, -Defines.player_grav+0.00001) -- stop the player from falling (but also move them 0.00001 down every frame to play the falling animation :P )
				end

				data.playerTimers[p.idx] = data.playerTimers[p.idx]+1 -- increase the timer

			elseif type == 1 then -- space

				-- reset jump timer if on ground and not holding anything
				if (p:isOnGround() or settings.space.canmidair) and not p.keys.jump and not p.keys.altJump then
					data.playerTimers[p.idx] = 0
				end

				if not p:isOnGround() and data.playerTimers[p.idx] == 1 and not p.keys.jump and not p.keys.altJump then
					data.playerTimers[p.idx] = -99999
				end

				-- while holding either the jump or spinjump key and the timer is under the max jump time, move the player up
				if (p.keys.jump or p.keys.altJump) and ((settings.space.infinitejumptime or data.playerTimers[p.idx] < settings.space.jumptime) and data.playerTimers[p.idx] > -1) then
					if settings.space.canspin and p.keys.altJump then p:mem(0x50, FIELD_BOOL, true)
					elseif settings.space.canspin and not p.keys.altJump then p:mem(0x50, FIELD_BOOL, false)
					end

					-- if this is the first frame of jumping, play the jump sound
					if data.playerTimers[p.idx] == 1 then
						if settings.space.canspin and p.keys.altJump then
							data.spinsnd = data.spinsnd or Misc.resolveSoundFile(settings.space.spinsound)
							SFX.play(data.spinsnd)
						else
							data.jumpsnd = data.jumpsnd or Misc.resolveSoundFile(settings.space.jumpsound)
							SFX.play(data.jumpsnd)
						end
					end

					-- detect blocks above the player; if there are, forcefully stop the player from going up

					-- if there's no blocks, it's safe to set the player's vertical speed
					if not seeifblocksaboveplayer(p) then p.speedY = -settings.space.maxupspeed
					else data.playerTimers[p.idx] = settings.space.jumptime*4
					end

				elseif (p.keys.jump == nil or p.keys.altJump == nil) then
					data.playerTimers[p.idx] = settings.space.jumptime*4 -- forcefully stop the player from being able to jump if they let go of the jump button

				end

				p.speedY = math.min(p.speedY, settings.space.maxdownspeed-Defines.player_grav+0.00001) -- limit the downwards speed

				data.playerTimers[p.idx] = data.playerTimers[p.idx]+1 -- timer thing

			elseif type == 2 then -- zero g

				if not p:isOnGround() and (p.keys.jump or p.keys.altJump) then
					if not seeifblocksaboveplayer(p) then p.speedY = p.speedY - Defines.player_grav - settings.zerog.yspeed end

					p.speedY = math.min(math.max(p.speedY, -settings.zerog.maxupspeed), settings.zerog.maxdownspeed)

				end

			end

		end
	end
end

--Gotta return the library table!
return sampleBlock