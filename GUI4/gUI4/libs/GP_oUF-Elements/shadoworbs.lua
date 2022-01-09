local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996
if LEGION then
	return
end

-- WoW API
local GetSpecialization = GetSpecialization
local IsPlayerSpell = IsPlayerSpell
local UnitLevel = UnitLevel
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local widget = "ShadowOrbsWidget"
local isPriest = select(2, UnitClass("player")) == "PRIEST"
local showShadowOrbs = GetSpecialization() == SPEC_PRIEST_SHADOW
local enhancedShadowOrbsSpellID = 157217
local vehicleHide = UnitHasVehicleUI("player")

local Update = function(self, event, ...)
	local arg1, arg2 = ...
	local ShadowOrbs = self[widget]
	if ShadowOrbs.PreUpdate then
		ShadowOrbs:PreUpdate()
	end
	if event == "PLAYER_ENTERING_WORLD" then
		vehicleHide = UnitHasVehicleUI("player")
		showShadowOrbs = GetSpecialization() == SPEC_PRIEST_SHADOW
	elseif (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and arg1 == "player" then
		vehicleHide = self.unit ~= "player"
	elseif event == "PLAYER_LEVEL_UP" then
		if UnitLevel("player") >= SHADOW_ORBS_SHOW_LEVEL then
			self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
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
			vehicleHide = UnitHasVehicleUI("player")
			showShadowOrbs = GetSpecialization() == SPEC_PRIEST_SHADOW
		end
	elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
		showShadowOrbs = GetSpecialization() == SPEC_PRIEST_SHADOW
	end
	local min = UnitPower("player", SPELL_POWER_SHADOW_ORBS) or 0
	-- local max = IsPlayerSpell(157217) and 5 or 3
	for i = 1, min do
		ShadowOrbs[i]:Show()
	end
	if min < #ShadowOrbs then
		for i = min + 1, #ShadowOrbs do
			ShadowOrbs[i]:Hide()
		end
	end
	if min > 0 and showShadowOrbs and not vehicleHide then
		ShadowOrbs:Show()
	else
		ShadowOrbs:Hide()
	end
	if ShadowOrbs.PostUpdate then
		ShadowOrbs:PostUpdate(min)
	end
end

local Path = function(self, ...)
	return (self[widget].Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'SHADOW_ORBS')
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
		self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
	end
end

local Enable = function(self, unit)
	local ShadowOrbs = self[widget]
	if ShadowOrbs then 
		if not isPriest then 
			ShadowOrbs:Hide()
			return
		end		
		ShadowOrbs.__owner = self
		ShadowOrbs.ForceUpdate = ForceUpdate		
		if UnitLevel("player") < SHADOW_ORBS_SHOW_LEVEL then
			self:RegisterEvent("PLAYER_LEVEL_UP", Path)
			ShadowOrbs:Hide()
		else
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
		end
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)
