-- retroResolution.lua - v1.0 (January 2023)
-- by PlumberGraduate
-- Simulates the resolution of the SNES by applying a subtle pixelation filter to the game.

local retroResolution = {}

retroResolution.renderPriority = 5

local screenBuffer = Graphics.CaptureBuffer(800,600)
local shader = Shader()
shader:compileFromFile(nil, "retroResolution.frag")

function retroResolution.onInitAPI()
    registerEvent(retroResolution, "onCameraUpdate")
	registerEvent(retroResolution, "onDraw")
end

function retroResolution.onCameraUpdate()
	local p1Camera = Camera.get()[1]
	local p2Camera = Camera.get()[2]
	
	p1Camera.x = p1Camera.x + p1Camera.x % 2
	p1Camera.y = p1Camera.y - p1Camera.y % 2
	p2Camera.x = p2Camera.x + p2Camera.x % 2
	p2Camera.y = p2Camera.y - p2Camera.y % 2
end

function retroResolution.onDraw()
	screenBuffer:captureAt(retroResolution.renderPriority)
	Graphics.drawScreen{
		texture = screenBuffer,
		shader = shader,
		priority = retroResolution.renderPriority
	}
end

return retroResolution