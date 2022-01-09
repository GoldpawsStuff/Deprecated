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
local WoW51 = (select(4, GetBuildInfo())) >= 50100

local Path, Update, ForceUpdate, Enable, Disable
local arrange, update, specUpdate

arrange = function(self)
	local LightForce = self.LightForce
	
	local light = UnitPower("player", SPELL_POWER_CHI or SPELL_POWER_LIGHT_FORCE)
	local maxLight = UnitPowerMax("player", SPELL_POWER_CHI or SPELL_POWER_LIGHT_FORCE)
	
	for i = 1, maxLight do
		LightForce[i]:Show()
	end
	
	if (maxLight < #LightForce) then
		for i = maxLight + 1, #LightForce do
			LightForce[i]:Hide()
		end
	end

	for i = 1, maxLight do
		LightForce[i]:SetWidth((self:GetWidth() - (maxLight - 1)) / maxLight)
		if (i == 1) then
			LightForce[i]:SetPoint("TOPLEFT", LightForce, "TOPLEFT", 0, 0)
		elseif (i == maxLight) then
			LightForce[i]:SetPoint("BOTTOMRIGHT", LightForce, "BOTTOMRIGHT", 0, 0)
		else
			LightForce[i]:SetPoint("LEFT", LightForce[i - 1], "RIGHT", 1, 0)
		end
	end
end

update = function(self)
	local LightForce = self.LightForce

	local light = UnitPower("player", SPELL_POWER_CHI or SPELL_POWER_LIGHT_FORCE)
	local maxLight = UnitPowerMax("player", SPELL_POWER_CHI or SPELL_POWER_LIGHT_FORCE)
	
	for i = 1, light do
		LightForce[i]:SetValue(1)
		LightForce[i]:Show()
	end
	
	if (light < maxLight) then
		for i = light + 1, maxLight do
			LightForce[i]:SetValue(0)
			LightForce[i]:Hide()
		end
	end
end

specUpdate = function(self)
	self.LightForce:Show()
	arrange(self)
	update(self)			
end

Update = function(self, event, ...)
	local arg1, arg2 = ...
	if (event == "PLAYER_TALENT_UPDATE") 
	or (event == "ACTIVE_TALENT_GROUP_CHANGED") 
	or (event == "CHARACTER_POINTS_CHANGED") 
	or (event == "GLYPH_ADDED") 
	or (event == "GLYPH_UPDATED") then
		-- local spec = GetSpecialization()
		-- if (spec ~= self.spec) then
			-- self.spec = spec
		-- end
		specUpdate(self)
	
	elseif ((event == "UNIT_ENTERED_VEHICLE") or (event == "UNIT_EXITED_VEHICLE")) and (arg1 == "player") then
		local LightForce = self.LightForce
		if (self.unit ~= "player") then
			LightForce:Hide()
		else
			LightForce:Show()
		end

	-- power updated
	elseif (event == "UNIT_POWER") and (arg1 == "player") and ((WoW51) and arg2 == "CHI") or ((arg2 == "LIGHT_FORCE") or (arg2 == "DARK_FORCE")) then
		update(self)
	
	-- power type changed (entered vehicle, etc)
	elseif (event == "UNIT_DISPLAYPOWER") and (arg1 == "player") then
		update(self)

	
	-- initial update
	elseif (event == "PLAYER_ENTERING_WORLD") then
		-- local spec = GetSpecialization()
		-- if (spec ~= self.spec) then
			-- self.spec = spec
		-- end
		specUpdate(self)
	end		
end

Path = function(self, ...)
	return (self.LightForce.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit, (WoW51) and "CHI" or "LIGHT_FORCE")
end

Disable = function(self)
	local LightForce = self.LightForce
	if (LightForce) then 
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
	local LightForce = self.LightForce
	if (LightForce) then 
		LightForce.__owner = self
		LightForce.ForceUpdate = ForceUpdate		
	
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
		
		arrange(self)
		update(self)
		tinsert(self.__elements, update)
		-- Path(self, "PLAYER_TALENT_UPDATE"); -- force a talent check
	end
end

oUF:AddElement("LightForce", Path, Enable, Disable)
