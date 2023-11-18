--Novarender
--Makes NPCs bounce off walls, floors, and ceilings, intended for noblockcollision and nogravity NPCs.

-- Usage:
--1. Register an NPC ID to use the script by calling Bounce.registerID(id, callback) within an npc-n.lua file.
-- * Bounce.registerID(id, callback)
--     id: NPC ID to register
--	   callback: a function that is called whenever the NPC bounces off a surface. Called like callback(v, angle) -- v is the individual NPC, angle is the surface angle bounced off of.
--       How to use callback: Most commonly, you would define your own function to pass as the `callback`. More explained below.
--2. Set the velocity of newly spawned NPCs using Bounce.setVelocity(v, newSpeed, newAngle) at some point, otherwise they will stay in place.
-- * Bounce.setVelocity(v, newSpeed, newAngle)
--	   v: NPC you want to set the speed and direction of
--	   newSpeed, newAngle: The new speed and angle of the NPC -- the NPC's velocity is now like a vector with this magnitude and angle.

--Callback & functions you can use
-- ** WARNING: All functions use radians and screen-space angles. This means that visually, they are flipped (negated).
-- The callback is the function you provide that controls what happens once the NPC bounces off a surface. By default, it does nothing and passes through the surface.
-- You can have the NPC bounce off of the surface by using the Bounce.bounce(v, angle) function -- one of the main features of this script. An example of this is:
	-- function bounceOffWall(v, angle)
	-- 	Bounce.bounce(v, angle)
	-- end
-- Then, pass it to the registering function like this: Bounce.registerID(id, bounceOffWall)
-- Aside from this, there are other functions that Bounce has to offer such as setSpeed, setAngle and setVelocity. These are detailed below but you can also pick them apart yourself further down.
-- * One example of not having the NPC bounce off of the surface is an NPC that splits on contact. When the NPC touches the surface, it dies and spawns multiple new NPCs. Bounce is useful in this regard because you can spawn the new NPCs in the direction away from the surface that was collided with.


--= * Functions * =--

-- Bounce.registerID(id, callback)
--	 id: NPC ID to register
--	 callback: a function that is called whenever the NPC bounces off a surface. Called like callback(v, angle) -- v is the individual NPC, angle is the surface angle bounced off of.
--	   How to use callback: Most commonly, you would define your own function to pass as the `callback`. More explained above.

-- Bounce.setSpeed(v, newSpeed)
--	 v: NPC you want to set the speed of
--	 newSpeed: new speed of the NPC. The NPC maintains its current angle of momentum, so this function only affects the speed of that movement.

-- Bounce.setAngle(v, newAngle)
--	 v: NPC you want to set the direction angle of
--	 newAngle: new angle of the NPC's movement. The NPC maintains its current speed, but is redirected in this direction.
--     ** Uses radians and screen-space! This means that the angle is flipped, or negated, visually.

-- Bounce.setVelocity(v, newSpeed, newAngle)
--	 v: NPC you want to set the speed and direction of
--	 newSpeed, newAngle: The new speed and angle of the NPC -- the NPC's velocity is now like a vector with this magnitude and angle.
--     ** Uses radians and screen-space! This means that the angle is flipped, or negated, visually.


local Bounce = { id="Novarender Bounce v1.0" }

local npcMan = require("npcManager")

function Bounce.registerID(id, callback)
	npcMan.registerEvent(id,Bounce,"onTickNPC")
	Bounce.initIDData(id, callback)
end
Bounce.idData = {}

function Bounce.initIDData(id, callback)
	local d = {}

	d.callback = callback
    
	Bounce.idData[id] = d
end

function Bounce.NPCdata(v)
	local d = v.data
	local settings = d._settings
	local config = NPC.config[v.id]

	if not d.bounceInit then
		d.bounceInit = true
		d.bufferBlocks = {}
	end

	return d
end

local function dist(x, y)
	return math.sqrt(x*x + y*y)
end 

--= - = - = - =

function Bounce.setSpeed(v, newSpeed)
	local velChange = newSpeed / dist(v.speedX, v.speedY)
	v.speedX = v.speedX * velChange
	v.speedY = v.speedX * velChange
end

function Bounce.setAngle(v, newAngle)
	local velocity = vector(dist(v.speedX, v.speedY), 0):rotate(newAngle * 180/math.pi)
	v.speedX = velocity.x
	v.speedY = velocity.y
end

function Bounce.setVelocity(v, newSpeed, newAngle) --Radians
	local velocity = vector(newSpeed, 0):rotate(newAngle * 180/math.pi)
	v.speedX = velocity.x
	v.speedY = velocity.y
end

function Bounce.bounce(v, angle)
	local oldAngle = math.atan2(v.speedY, v.speedX)
	local newAngle = 2*angle - oldAngle --Calculate angle of deflection

	Bounce.setAngle(v, newAngle)
end

function Bounce.onTickNPC(v)
	local d = Bounce.NPCdata(v)
	local settings = d._settings
	local config = NPC.config[v.id]

	local collidingBlocks = Colliders.getColliding {
		a = v,
		b = Block.SOLID .. Block.SEMISOLID,
		btype = Colliders.BLOCK
	}
	-- table.append(collidingBlocks, Colliders.getColliding {
	-- 	a = v,
	-- 	btype = Colliders.NPC
	-- }) --I don't know how to get this to work

	local oldBuffer = d.bufferBlocks --Store last frame's buffer for reference, but reset current one for writing
	d.bufferBlocks = {}
	
	if #collidingBlocks > 0 then --Colliding with something

		--Step 1: Determine angle of colliding surface

		local bAngle
		local clippingAreas = {}
		for _,b in ipairs(collidingBlocks) do
			local isSemisolid = Block.SEMISOLID_MAP[b.id]
			local collides = true

			if isSemisolid and v.speedY <= 0 then collides = false end

			if not oldBuffer[b] and collides then
				local c = Block.config[b.id]
				
				local slope = 0
				if c.floorslope ~= 0 then slope = c.floorslope end
				if c.ceilingslope ~= 0 then slope = c.ceilingslope end

				if slope ~= 0 then --Doesn't work with other sides of slope blocks (or semisolid slopes), but it should work for most other cases. If needed, the collision system for this can be rewritten.
					bAngle = math.atan2(b.height, b.width) * slope
					break
				else --Vertical or horizontal check
					local clippingArea = {
						width  = math.min(v.x + v.width, b.x + b.width) - math.max(v.x, b.x),
						height = math.min(v.y + v.height, b.y + b.height) - math.max(v.y, b.y)
					}

					if isSemisolid then 
						collides = v.y < b.y and clippingArea.width > clippingArea.height --NPC must collide with the top of the block
					end

					if collides then 																																												--Never gonna give you up, never gonna let you down, never gonna run around and hurt you
						table.insert(clippingAreas, clippingArea)
					end
				end
			end

			if collides then d.bufferBlocks[b] = true end --Even if it was in the previous frame's buffer, it still gets added. It can't get out of the buffer until the block's hitbox is exited.
		end

		if not bAngle then
			if #clippingAreas == 0 then return end --All blocks collided with on this frame were skipped b/c of block buffer (bAngle check prior to this passes for sloped blocks)

			local max = 1
			local mA = 0
			for k,v in ipairs(clippingAreas) do --Pick out best colliding block by comparing collision area
				local area = v.width*v.height
				if area > mA then
					max = k
					mA = area
				end
			end

			local cBlockArea = clippingAreas[max] --Intersection with colliding block

			if cBlockArea.width > cBlockArea.height then --Uses this trick I learned where you compare the dimensions of the overlapping area: Taller than wide means a side collision, and wider than tall means a ceiling/floor collision. Usually.
				bAngle = 0
			else
				bAngle = math.pi/2
			end
		end

		--bAngle is the colliding surface/block angle

		Bounce.idData[v.id].callback(v, bAngle) --Now we can return it!
	end
end

return Bounce


--Changelog
--v1.0 -- basic functioning complete. NPC is able to bounce off walls and have its momentum controlled.

--Possible updates
--Add collision with block-like NPCs
--Fix mysterious collision jank spotted in the North
--Add proper collision for slope blocks
--Add an Advance mode that can be enabled to allow moving layers and conveyor belts to give more or less momentum to the NPC bouncing off of them. This would supply an extra argument to the callback that can be used in Bounce.bounce().