
-- Lua API
local _G = _G

-- WoW API
local CreateFrame = _G.CreateFrame
local EnumerateFrames = _G.EnumerateFrames

-------------------------------------------------------------------------------
--	Emergency WoD Fixes
-------------------------------------------------------------------------------
local function addapi(object)
	local mt = getmetatable(object).__index
	if not object.SetLossOfControlCooldown then mt.SetLossOfControlCooldown = object.SetCooldown end
end

local handled = {}
local object = CreateFrame("Cooldown")
addapi(object)

object = EnumerateFrames()
while object do
	if not handled[object:GetObjectType()] then
		addapi(object)
		handled[object:GetObjectType()] = true
	end
	object = EnumerateFrames(object)
end


