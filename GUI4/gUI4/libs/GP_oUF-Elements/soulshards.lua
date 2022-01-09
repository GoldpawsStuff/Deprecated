local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

local GetSpecialization = GetSpecialization
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local widget = "SoulShardsWidget"
local isWarlock = select(2, UnitClass("player")) == "WARLOCK"
local showSoulShards = LEGION or GetSpecialization() == SPEC_WARLOCK_AFFLICTION

local Update = function(self, event, ...)
	local arg1, arg2 = ...
	local SoulShards = self[widget]
	if SoulShards.PreUpdate then
		SoulShards:PreUpdate()
	end
	showSoulShards = LEGION or GetSpecialization() == SPEC_WARLOCK_AFFLICTION
	if showSoulShards and not SoulShards:IsShown() then
		SoulShards:Show()
	elseif SoulShards:IsShown() and not showSoulShards then
		SoulShards:Hide()
	end
	local numShards = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
	local maxShards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
	for i = 1, numShards do
		SoulShards[i]:Show()
	end
	if numShards < maxShards then
		for i = numShards + 1, maxShards do
			SoulShards[i]:Hide()
		end
	end
	if SoulShards.PostUpdate then
		SoulShards:PostUpdate(min)
	end
end

local Path = function(self, ...)
	return (self[widget].Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'SOUL_SHARDS')
end

local Disable = function(self)
	local SoulShards = self[widget]
	if SoulShards then 
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
	local SoulShards = self[widget]
	if SoulShards then 
		if not isWarlock then
			SoulShards:Hide()
			return
		end
		SoulShards.__owner = self
		SoulShards.ForceUpdate = ForceUpdate
		self:RegisterEvent("UNIT_POWER", Path)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:RegisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:RegisterEvent("GLYPH_ADDED", Path)
		self:RegisterEvent("GLYPH_UPDATED", Path)
		Path(self, "PLAYER_TALENT_UPDATE")
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)
