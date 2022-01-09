local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996
if LEGION then
	return
end

local GetSpecialization = GetSpecialization
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local widget = "DemonicFuryWidget"
local isWarlock = select(2, UnitClass("player")) == "WARLOCK"
local showDemonicFury = GetSpecialization() == SPEC_WARLOCK_DEMONOLOGY

local Update = function(self, event, ...)
	local arg1, arg2 = ...
	local DemonicFury = self[widget]
	if DemonicFury.PreUpdate then
		DemonicFury:PreUpdate()
	end
	showDemonicFury = GetSpecialization() == SPEC_WARLOCK_DEMONOLOGY
	if showDemonicFury and not DemonicFury:IsShown() then
		DemonicFury:Show()
	elseif DemonicFury:IsShown() and not showDemonicFury then
		DemonicFury:Hide()
	end
	local min = UnitPower("player", SPELL_POWER_DEMONIC_FURY)
	local max = UnitPowerMax("player", SPELL_POWER_DEMONIC_FURY)
	DemonicFury.bar:SetValue(min)
	DemonicFury.bar:SetMinMaxValues(0, max)
	local value = DemonicFury.value or DemonicFury.bar.value
	if value then
		value:SetFormattedText("%d/%d", min, max)
	end
	if DemonicFury.PostUpdate then
		DemonicFury:PostUpdate(min)
	end
end

local Path = function(self, ...)
	return (self[widget].Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'DEMONIC_FURY')
end

local Disable = function(self)
	local DemonicFury = self[widget]
	if DemonicFury then 
		self:UnregisterEvent("UNIT_POWER", Path)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:UnregisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:UnregisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:UnregisterEvent("GLYPH_ADDED", Path)
		self:UnregisterEvent("GLYPH_UPDATED", Path)
	end
end

local Enable = function(self, unit)
	local DemonicFury = self[widget]
	if DemonicFury then 
		if not isWarlock then
			DemonicFury:Hide()
			return
		end
		DemonicFury.__owner = self
		DemonicFury.ForceUpdate = ForceUpdate		
		self:RegisterEvent("UNIT_POWER", Path)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:RegisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:RegisterEvent("GLYPH_ADDED", Path)
		self:RegisterEvent("GLYPH_UPDATED", Path)
		Path(self, "PLAYER_TALENT_UPDATE") -- force a talent check
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)

