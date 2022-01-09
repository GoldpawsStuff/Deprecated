local _, gUI4 = ...

-- Lua API
local _G = _G
local pairs = pairs
local abs, max, min = math.abs, math.max, math.min

-- WoW API
local CreateFrame = _G.CreateFrame
local GetFramerate = _G.GetFramerate
local WorldFrame = _G.WorldFrame

local Smooth = {}
local updater, updating
local forceUpdate

local function smooth(self, value)
	local _, max = self:GetMinMaxValues()
	if value == self:GetValue() or (self._max and self._max ~= max) then
		Smooth[self] = nil
		self:SetValue_(value)
	else
		Smooth[self] = value
	end
	self._max = max
end

local function onUpdate()
	if forceUpdate then
		for bar, value in pairs(Smooth) do
			bar:SetValue(value)
		end
		forceUpdate = nil
	end

	local limit = 30/GetFramerate()
	for bar, value in pairs(Smooth) do
		local current = bar:GetValue() -- current value of the bar
		local new = current and (current + min((value-current)/3, max(value-current, limit))) or value
		bar:SetValue_(new)
		if current == value or abs(new - value) < 2 then
			bar:SetValue_(value)
			Smooth[bar] = nil
		end
	end
end

local function startSmoothing()
	if updating then return end
	if not updater then
		updater = CreateFrame("Frame", nil, WorldFrame)
	end
	updater:SetScript("OnUpdate", onUpdate)
	updating = true
end

function gUI4:ApplySmoothing(bar)
	bar.SetValue_ = bar.SetValue
	bar.SetValue = smooth
	forceUpdate = true
end

gUI4:AddEvent("PLAYER_ENTERING_WORLD", startSmoothing)
