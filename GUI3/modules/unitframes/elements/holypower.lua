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
local registerEvents, arrange, update, specUpdate

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

arrange = function(self)
	local HolyPower = self.HolyPower
	local power = UnitPower("player", SPELL_POWER_HOLY_POWER) or 0
	local maxPower = UnitPowerMax("player", SPELL_POWER_HOLY_POWER)
	
	for i = 1, maxPower do
		HolyPower[i]:Show()
	end
	
	if (maxPower < #HolyPower) then
		for i = maxPower + 1, #HolyPower do
			HolyPower[i]:Hide()
		end
	end

	for i = 1, maxPower do
		HolyPower[i]:SetWidth((self:GetWidth() - (maxPower - 1)) / maxPower)
		if (i == 1) then
			HolyPower[i]:SetPoint("TOPLEFT", HolyPower, "TOPLEFT", 0, 0)
		elseif (i == maxPower) then
			HolyPower[i]:SetPoint("BOTTOMRIGHT", HolyPower, "BOTTOMRIGHT", 0, 0)
		else
			HolyPower[i]:SetPoint("LEFT", HolyPower[i - 1], "RIGHT", 1, 0)
		end
	end
end

update = function(self)
	local HolyPower = self.HolyPower
	if (HolyPower) then
		local min = UnitPower("player", SPELL_POWER_HOLY_POWER) or 0
		local max = UnitPowerMax("player", SPELL_POWER_HOLY_POWER)
		if (min > 0) then
			for i = 1, min do
				HolyPower[i]:SetValue(1)
				HolyPower[i]:Show()
			end
		end
		if (min < max) then
			for i = min + 1, max do
				HolyPower[i]:SetValue(0)
				HolyPower[i]:Hide()
			end
		end
	end
end

specUpdate = function(self)
	arrange(self)
	update(self)			
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
	
	-- leveled up, orbs available at 9
	elseif (event == "PLAYER_LEVEL_UP") and (UnitLevel("player") >= PALADINPOWERBAR_SHOW_LEVEL) then
		if (UnitLevel("player") == PALADINPOWERBAR_SHOW_LEVEL) then
			self:Show()
			registerEvents(self)
			
		elseif (UnitLevel("player") == 85) then
			self:UnregisterEvent("PLAYER_LEVEL_UP"); -- keep it to 85 and Boundless Conviction
			Path(self, "PLAYER_TALENT_UPDATE") 
		end
		
		-- power updated
	elseif (event == "UNIT_POWER") and (arg1 == "player") and (arg2 == "HOLY_POWER") then
		update(self)
	
	-- power type changed (entered vehicle, etc)
	elseif (event == "UNIT_DISPLAYPOWER") and (arg1 == "player") then
		update(self)

	elseif ((event == "UNIT_ENTERED_VEHICLE") or (event == "UNIT_EXITED_VEHICLE")) and (arg1 == "player") then
		local HolyPower = self.HolyPower
		if (self.unit ~= "player") then
			HolyPower:Hide()
		else
			HolyPower:Show()
		end
		
	-- initial update
	elseif (event == "PLAYER_ENTERING_WORLD") then
		
	end
end

Path = function(self, ...)
	return (self.HolyPower.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'HOLY_POWER')
end

Disable = function(self)
	if (self.HolyPower) then
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
	local HolyPower = self.HolyPower
	if (HolyPower) then 
		HolyPower.__owner = self
		HolyPower.ForceUpdate = ForceUpdate		
	
		local level = UnitLevel("player")
		if (level < 85 ) then
			self:RegisterEvent("PLAYER_LEVEL_UP", Path)
		end
		if (level < PALADINPOWERBAR_SHOW_LEVEL) then
			self:Hide()
		else
			registerEvents(self)
		end
	end
end

oUF:AddElement("HolyPower", Path, Enable, Disable)

