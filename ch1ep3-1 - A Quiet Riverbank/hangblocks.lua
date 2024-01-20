--[[
	hangblocks.lua v1.0.2

	A library that adds blocks that function as Donkey Kong Country 2-esque horizontal ropes.
	This script handles player behavior when hanging from a block, as well as collision detection
	for hangblocks.

	by cold soup
]]

local blockManager = require("blockManager")

local hangblocks = {}

local blockIDs = {}

hangblocks.playerData = {}

---------------------- CUSTOMIZABLE PROPERTIES ----------------------
--[[
	This script by default is only configured properly for Mario, as he's the only one I made 
	graphics for. However, you can set the graphics and properties of other characters by adding 
	their constants to the tables of individual properties.
	
	Example: 
	hangblocks.grabframes = {
	 	[CHARACTER_MARIO] = Graphics.loadImageResolved("grabframes-mario.png"),
		[CHARACTER_LUIGI] = Graphics.loadImageResolved("grabframes-luigi.png")
	}

	List of character constants: https://docs.codehaus.moe/#/constants/characters
]]

-- grab graphics
hangblocks.grabframes = {
	[CHARACTER_MARIO] = Graphics.loadImageResolved("grabframes-mario.png")
}

-- width and height of an individual frame
hangblocks.framewidth = {
	[CHARACTER_MARIO] = 36
}
hangblocks.frameheight = {
	[CHARACTER_MARIO] = 60
}

-- x and y offsets of a single frame
hangblocks.frameXoffset = {
	[CHARACTER_MARIO] = -4
}
hangblocks.frameYoffset = {
	[CHARACTER_MARIO] = -6
}

-- number of frames for moving while on a hangblock
hangblocks.numframes = {
	[CHARACTER_MARIO] = 2
}

-- render priority of the climbing animation
-- mainly here if you want a character to be behind the blocks
hangblocks.framepriority = {
	[CHARACTER_MARIO] = -25
}

-- speed of the animation
hangblocks.animSpeed = 12

---------------------------------------------------------------------

function hangblocks.register(id)
	blockManager.registerEvent(id, hangblocks, "onTickEndBlock")
	blockIDs[id] = true
end

function hangblocks.onInitAPI()
	registerEvent(hangblocks, "onTick")
	registerEvent(hangblocks, "onDraw")
end

local function initializePlayerData(index)
	if hangblocks.playerData[index] then return end
	hangblocks.playerData[index] = {
		grabbing = false,
		currentBlock = nil,
		grabDelay = 0, -- player can't grab blocks if this value is above 0, used so small players can drop 
		currentFrame = 0,
		animationTimer = hangblocks.animSpeed;
	}
end

function hangblocks.onTick()
	for _,p in ipairs(Player.get()) do
		initializePlayerData(p.idx)

		if (hangblocks.playerData[p.idx].grabDelay > 0) then
			hangblocks.playerData[p.idx].grabDelay = hangblocks.playerData[p.idx].grabDelay - 1
			p:mem(0x172,FIELD_BOOL,false) -- added so the player doesn't shoot a projectile/tail swipe when they jump off
		end

		if (player:mem(0x12E, FIELD_BOOL)) then -- prevents players from grabbing ropes while crouching
			hangblocks.playerData[p.idx].grabDelay = 10 -- set to 10 because link gets stuck otherwise
		end

		-- behavior for grabbing a rope
		if (hangblocks.playerData[p.idx].grabbing) then
			p.y = hangblocks.playerData[p.idx].currentBlock.y
			p.isOnGround = true -- janky dumb way of making the player's momentum work like it does on the ground
			p.speedY = 0

			-- prevents the player from running or using projectiles while grabbing a rope
			p.keys.run = false
			p.keys.altRun = false

			-- animation-related code
			if (p.speedX == 0) then
				hangblocks.playerData[p.idx].currentFrame = 0
				hangblocks.playerData[p.idx].animationTimer = hangblocks.animSpeed + 1
			else
				hangblocks.playerData[p.idx].animationTimer = hangblocks.playerData[p.idx].animationTimer + 1

				if (hangblocks.playerData[p.idx].animationTimer > hangblocks.animSpeed) then
					hangblocks.playerData[p.idx].currentFrame = (1 + (hangblocks.playerData[p.idx].currentFrame % hangblocks.numframes[p.character]))
					if (p.direction == -1) then hangblocks.playerData[p.idx].currentFrame = hangblocks.playerData[p.idx].currentFrame + hangblocks.numframes[p.character] end
					
					hangblocks.playerData[p.idx].animationTimer = 0
				end
			end

			-- lets go of the rope if the player jumped or pressed down
			if(p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED or p.keys.down == KEYS_DOWN) then
				hangblocks.playerData[p.idx].grabbing = false
				hangblocks.playerData[p.idx].grabDelay = 10
			end
		end

		hangblocks.playerData[p.idx].grabbing = false
	end
end

function hangblocks.onDraw()
  	for _,p in ipairs(Player.get()) do
  		if (hangblocks.playerData[p.idx].grabbing and p.deathTimer <= 0) then
  			p:setFrame(-50)

			if (not p:mem(0x142, FIELD_BOOL)) then -- don't draw the player if they're blinking
  				Graphics.draw{
  					type = RTYPE_IMAGE,
  					image = hangblocks.grabframes[p.character],
  					sceneCoords = true,
  					x = p.x + hangblocks.frameXoffset[p.character],
  					y = p.y + hangblocks.frameYoffset[p.character],
  					priority = hangblocks.framepriority[p.character],
  					sourceX = hangblocks.playerData[p.idx].currentFrame * hangblocks.framewidth[p.character],
  					sourceY = (hangblocks.frameheight[p.character] * (p.powerup)) - hangblocks.frameheight[p.character],
  					sourceWidth = hangblocks.framewidth[p.character],
  					sourceHeight = hangblocks.frameheight[p.character]
  				}
  			end
		end
  	end
end

function hangblocks.onTickEndBlock(v)
    -- Don't run code for invisible entities
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	
	-- checks for players touching the block
	for _,p in ipairs(Player.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
		if (p.speedY >= 0 and -- player is falling
			p.y > v.y-6 and -- top of player is touching the block
			hangblocks.playerData[p.idx].grabDelay <= 0 and -- doesn't have grab delay
			not p:mem(0x36,FIELD_BOOL) and -- not underwater/in quicksand
			p.forcedState <= 0
		) then
			hangblocks.playerData[p.idx].grabbing = true
			hangblocks.playerData[p.idx].currentBlock = v
		end
	end
end

return hangblocks