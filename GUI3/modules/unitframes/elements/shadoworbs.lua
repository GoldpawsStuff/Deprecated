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
local registerEvents, update, specUpdate

registerEvents = function(self)
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
	tinsert(self.__elements, update)
	Path(self, "PLAYER_TALENT_UPDATE") 
end

update = function(self)
	local ShadowOrbs = self.ShadowOrbs
	if (ShadowOrbs) then
		local min = UnitPower("player", SPELL_POWER_SHADOW_ORBS) or 0
		local max = PRIEST_BAR_NUM_ORBS
		for i = 1, min do
			self.ShadowOrbs[i]:SetValue(1)
			self.ShadowOrbs[i]:Show()
		end
		if (min < max) then
			for i = min + 1, max do
				self.ShadowOrbs[i]:SetValue(0)
				self.ShadowOrbs[i]:Hide()
			end
		end
	end
end

specUpdate = function(self)
	if (self.spec == SPEC_PRIEST_SHADOW) then
		self.ShadowOrbs:Show()
		update(self)
	else
		self.ShadowOrbs:Hide()
	end
end

Update = function(self, event, ...)
	local arg1, arg2 = ...
	
	-- changed spec
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
	
	-- leveled up, orbs available at 10
	elseif (event == "PLAYER_LEVEL_UP") and (UnitLevel("player") >= SHADOW_ORBS_SHOW_LEVEL) then
		self:Show()
		registerEvents(self)
		
	elseif ((event == "UNIT_ENTERED_VEHICLE") or (event == "UNIT_EXITED_VEHICLE")) and (arg1 == "player") then
		if (self.unit == "player") and (self.spec == SPEC_PRIEST_SHADOW) then
			self.ShadowOrbs:Show()
		else
			self.ShadowOrbs:Hide()
		end
		
	-- power updated
	elseif (event == "UNIT_POWER") and (arg1 == "player") and (arg2 == "SHADOW_ORBS") then
		update(self)
	
	-- power type changed (entered vehicle, etc)
	elseif (event == "UNIT_DISPLAYPOWER") and (arg1 == "player") then
		update(self)
	
	-- initial update
	elseif (event == "PLAYER_ENTERING_WORLD") then
		
	end
end

Path = function(self, ...)
	return (self.ShadowOrbs.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'SHADOW_ORBS')
end

Disable = function(self)
	if (self.ShadowOrbs) then
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

Enable = function(self, unit)
	local ShadowOrbs = self.ShadowOrbs
	if (ShadowOrbs) then 
		ShadowOrbs.__owner = self
		ShadowOrbs.ForceUpdate = ForceUpdate		
	
		if ( UnitLevel("player") < SHADOW_ORBS_SHOW_LEVEL ) then
			self:RegisterEvent("PLAYER_LEVEL_UP", Path)
			self:Hide()
		else
			registerEvents(self)
		end
	end
end

oUF:AddElement("ShadowOrbs", Path, Enable, Disable)
