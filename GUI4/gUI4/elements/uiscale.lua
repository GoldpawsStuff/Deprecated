local _, gUI4 = ...

-- Lua API
local _G = _G

-- WoW API
local CreateFrame = _G.CreateFrame
local hooksecurefunc = _G.hooksecurefunc
local IsLoggedIn = _G.IsLoggedIn
local GetCVar = _G.GetCVar
local SetCVar = _G.SetCVar
local UIParent = _G.UIParent

local LMP = _G.GP_LibStub("GP_LibMediaPlus-1.0")

local locked
function gUI4:FixScale()
	locked = true
	SetCVar("useUiScale", nil) -- secure call after some patch
	locked = false
end
gUI4.FixScale = gUI4:SafeCallWrapper(gUI4.FixScale)

local once
function gUI4:SetUpScaleFixing(...)
	-- we're not going to accept UI scaling whatsoever, because it breaks our textures.
	-- blizzard antialias the edges of all textures which isn't in a perfect coordinate, 
	-- and we're simply not going to figure out perfect coordinates in weird scalings.
	local hidden = LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :Hide() .__EndChain
	_G.Advanced_UseUIScale:SetParent(hidden)
	_G.Advanced_UIScaleSlider:SetParent(hidden)
	if GetCVar("useUiScale") == "1" then
		gUI4:FixScale()
	end
	local function setCVar(var)
		if locked then return end -- avoid stack overflow
		if var == "useUiScale" then
			locked = true
			gUI4:FixScale()
		end
	end
	hooksecurefunc("SetCVar", setCVar)
	
	if not once then
		once = true
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "SetUpScaleFixing")
	end
end
gUI4.SetUpScaleFixing = gUI4:SafeCallWrapper(gUI4.SetUpScaleFixing)

if IsLoggedIn() then
	once = true
	-- gUI4:SetUpScaleFixing()
else
	-- gUI4:AddEvent("PLAYER_ENTERING_WORLD", "SetUpScaleFixing")
end
