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
local update, specUpdate

update = function(self)
	local DemonicFury = self.DemonicFury

	local power = UnitPower("player", SPELL_POWER_DEMONIC_FURY)
	local maxPower = UnitPowerMax("player", SPELL_POWER_DEMONIC_FURY)
	
	DemonicFury:SetValue(power)
	DemonicFury:SetMinMaxValues(0, maxPower)
	
	if (power == 0) then
		DemonicFury:Hide()
	else
		DemonicFury:Show()
	end
end

specUpdate = function(self)
	if (self.spec == SPEC_WARLOCK_DEMONOLOGY) then
		self.DemonicFury:Show()
		update(self)
	else
		self.DemonicFury:Hide()
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
	elseif (event == "UNIT_POWER") and (arg1 == "player") and (arg2 == "DEMONIC_FURY") then
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
	return (self.DemonicFury.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'DEMONIC_FURY')
end

Disable = function(self)
	local DemonicFury = self.DemonicFury
	if (DemonicFury) then 
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
	local DemonicFury = self.DemonicFury
	if (DemonicFury) then 
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
		tinsert(self.__elements, update)
		Path(self, "PLAYER_TALENT_UPDATE") -- force a talent check
	end
end

oUF:AddElement("DemonicFury", Path, Enable, Disable)

