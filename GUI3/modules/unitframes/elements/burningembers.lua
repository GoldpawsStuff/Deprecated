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
	local BurningEmbers = self.BurningEmbers
	
	local maxPower = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS, true)
	local power = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
	local numEmbers = power / MAX_POWER_PER_EMBER
	local numBars = floor(maxPower / MAX_POWER_PER_EMBER)
	
	for i = 1, numBars do
		BurningEmbers[i]:Show()
	end
	
	if (numBars < #BurningEmbers) then
		for i = numBars + 1, #BurningEmbers do
			BurningEmbers[i]:Hide()
		end
	end

	for i = 1, numBars do
		BurningEmbers[i]:SetWidth((self:GetWidth() - (numBars - 1)) / numBars)
		if (i == 1) then
			BurningEmbers[i]:SetPoint("TOPLEFT", BurningEmbers, "TOPLEFT", 0, 0)
		elseif (i == numBars) then
			BurningEmbers[i]:SetPoint("BOTTOMRIGHT", BurningEmbers, "BOTTOMRIGHT", 0, 0)
		else
			BurningEmbers[i]:SetPoint("LEFT", BurningEmbers[i - 1], "RIGHT", 1, 0)
		end
	end
end

update = function(self)
	local BurningEmbers = self.BurningEmbers

	local maxPower = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS, true)
	local power = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
	local numEmbers = floor(power / MAX_POWER_PER_EMBER)
	local maxEmbers = floor(maxPower / MAX_POWER_PER_EMBER)
	
	for i = 1, numEmbers do
		BurningEmbers[i]:SetValue(MAX_POWER_PER_EMBER)
	end

	if (numEmbers < maxEmbers) then
		for i = 1, maxEmbers - numEmbers do
			if (i == 1) then
				BurningEmbers[i + numEmbers]:SetValue(power%MAX_POWER_PER_EMBER)
			else
				BurningEmbers[i + numEmbers]:SetValue(0)
			end
		end
	end
end

specUpdate = function(self)
	if (self.spec == SPEC_WARLOCK_DESTRUCTION) then
		self.BurningEmbers:Show()
		arrange(self)
		update(self)
	else
		self.BurningEmbers:Hide()
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
	elseif (event == "UNIT_POWER") and (arg1 == "player") and (arg2 == "BURNING_EMBERS") then
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
	return (self.BurningEmbers.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'BURNING_EMBERS')
end

Disable = function(self)
	local BurningEmbers = self.BurningEmbers
	if (BurningEmbers) then 
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
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
	local BurningEmbers = self.BurningEmbers
	if (BurningEmbers) then 
		BurningEmbers.__owner = self
		BurningEmbers.ForceUpdate = ForceUpdate		
	
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
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

oUF:AddElement("BurningEmbers", Path, Enable, Disable)
