--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...
local oUF = ns.oUF or oUF 

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local unitframes = gUI:GetModule("Unitframes")
local R = unitframes:GetDataBase("auras")
local RaidGroups = unitframes:GetDataBase("raidgroups")
local UnitFrames = unitframes:GetDataBase("unitframes")

local Path, Update, ForceUpdate, Enable, Disable
local arrange, update, specUpdate

arrange = function(self)
	local SoulShards = self.SoulShards
	
	local numShards = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
	local maxShards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS )
	
	for i = 1, maxShards do
		SoulShards[i]:Show()
	end
	
	if (maxShards < #SoulShards) then
		for i = maxShards + 1, #SoulShards do
			SoulShards[i]:Hide()
		end
	end

	for i = 1, maxShards do
		SoulShards[i]:SetWidth((self:GetWidth() - (maxShards - 1)) / maxShards)
		if (i == 1) then
			SoulShards[i]:SetPoint("TOPLEFT", SoulShards, "TOPLEFT", 0, 0)
		elseif (i == maxShards) then
			SoulShards[i]:SetPoint("BOTTOMRIGHT", SoulShards, "BOTTOMRIGHT", 0, 0)
		else
			SoulShards[i]:SetPoint("LEFT", SoulShards[i - 1], "RIGHT", 1, 0)
		end
	end
end

update = function(self)
	local SoulShards = self.SoulShards

	local numShards = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
	local maxShards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS )
	
	for i = 1, numShards do
		SoulShards[i]:SetValue(1)
		SoulShards[i]:Show()
	end
	
	if (numShards < maxShards) then
		for i = numShards + 1, maxShards do
			SoulShards[i]:SetValue(0)
			SoulShards[i]:Hide()
		end
	end
end

specUpdate = function(self)
	if (self.spec == SPEC_WARLOCK_AFFLICTION) then
		self.SoulShards:Show()
		arrange(self)
		update(self)
	else
		self.SoulShards:Hide()
	end
end

Update = function(self, event, ...)
	local arg1, arg2 = ...
	if (event == "PLAYER_TALENT_UPDATE") 
	or (event == "ACTIVE_TALENT_GROUP_CHANGED") 
	or (event == "CHARACTER_POINTS_CHANGED") 
	or (event == "GLYPH_ADDED") 
	or (event == "GLYPH_UPDATED") then
		local spec = GetSpecialization()
		if (spec ~= self.spec) then
			self.spec = spec
		end
		specUpdate(self)
	
	-- power updated
	elseif (event == "UNIT_POWER") and (arg1 == "player") and (arg2 == "SOUL_SHARDS") then
		update(self)
	
	-- power type changed (entered vehicle, etc)
	elseif (event == "UNIT_DISPLAYPOWER") and (arg1 == "player") then
		update(self)
	
	-- initial update
	elseif (event == "PLAYER_ENTERING_WORLD") then
		local spec = GetSpecialization()
		if (spec ~= self.spec) then
			self.spec = spec
		end
		specUpdate(self)
		
	end		
end

Path = function(self, ...)
	return (self.SoulShards.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'SOUL_SHARDS')
end

Disable = function(self)
	local SoulShards = self.SoulShards
	if (SoulShards) then 
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

Enable = function(self, unit)
	local SoulShards = self.SoulShards
	if (SoulShards) then 
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
		tinsert(self.__elements, update)
		Path(self, "PLAYER_TALENT_UPDATE") -- force a talent check
	end
end

oUF:AddElement("SoulShards", Path, Enable, Disable)
