local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

local UnitHasVehicleUI = UnitHasVehicleUI
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local widget = "HolyPowerWidget"
local isPaladin = select(2, UnitClass("player")) == "PALADIN"
local inVehicle = UnitHasVehicleUI("player")
local showHolyPower

local Update = function(self, event, ...)
	local arg1, arg2 = ...
	local HolyPower = self[widget]
	if HolyPower.PreUpdate then
		HolyPower:PreUpdate()
	end
	if event == "PLAYER_LEVEL_UP" then
		if UnitLevel("player") == 85 then
			self:UnregisterEvent("PLAYER_LEVEL_UP") -- keep it to 85 and Boundless Conviction
		end
	end
	if event == "PLAYER_ENTERING_WORLD"
	or event == "UNIT_ENTERED_VEHICLE"
	or event == "UNIT_EXITED_VEHICLE" then
		inVehicle = UnitHasVehicleUI("player")
	end
	local min = UnitPower("player", SPELL_POWER_HOLY_POWER) or 0
	-- local max = UnitPowerMax("player", SPELL_POWER_HOLY_POWER)
	if min > 0 then
		for i = 1, min do
			HolyPower[i]:Show()
		end
		showHolyPower = true
	else
		showHolyPower = false
	end
	if min < #HolyPower then
		for i = min + 1, #HolyPower do
			HolyPower[i]:Hide()
		end
	end
	if showHolyPower and not inVehicle and not HolyPower:IsShown() then
		HolyPower:Show()
	elseif (inVehicle or not showHolyPower) and HolyPower:IsShown() then
		HolyPower:Hide()
	end
	if HolyPower.PostUpdate then
		return HolyPower:PostUpdate(min)
	end
end

local Path = function(self, ...)
	return (self[widget].Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'HOLY_POWER')
end

local Disable = function(self)
	if self[widget] then
		self:UnregisterEvent("UNIT_POWER", Path)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:UnregisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:UnregisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:UnregisterEvent("GLYPH_ADDED", Path)
		self:UnregisterEvent("GLYPH_UPDATED", Path)
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Path)
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", Path)
	end
end

local Enable = function(self, unit)
	local HolyPower = self[widget]
	if HolyPower then 
		if not isPaladin then
			HolyPower:Hide()
			return
		end
		HolyPower.__owner = self
		HolyPower.ForceUpdate = ForceUpdate		
		if UnitLevel("player") < 85 then
			self:RegisterEvent("PLAYER_LEVEL_UP", Path)
		end
		self:RegisterEvent("UNIT_POWER", Path)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:RegisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:RegisterEvent("GLYPH_ADDED", Path)
		self:RegisterEvent("GLYPH_UPDATED", Path)
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", Path)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", Path)
		Path(self, "PLAYER_TALENT_UPDATE") 
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)

