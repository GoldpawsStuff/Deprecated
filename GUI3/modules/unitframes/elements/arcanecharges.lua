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
local registerEvents, updateCharge, update, specUpdate

local patch, build, released, toc = GetBuildInfo()
build = tonumber(build)

-- patch 5.3 reduced charges to 4
local MAX_CHARGES = (build >= 16837) and 4 or 6

registerEvents = function(self)
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
	self:RegisterEvent("UNIT_AURA", Path)
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", Path)
	self:RegisterEvent("UNIT_EXITED_VEHICLE", Path)
	tinsert(self.__elements, update)
	Path(self, "ACTIVE_TALENT_GROUP_CHANGED") 
end

updateCharge = function(self, elapsed)
	if not(self.expire) then return end
	self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed > 0.1) then	
		local time = self.expire - GetTime()
		if (time > 0) then
			self:SetValue(time)
			self:SetAlpha(1)
		else
			self:SetAlpha(0)
			self:SetScript("OnUpdate", nil)
		end
		self.elapsed = 0
	end		
end

update = function(self)
	local unit = self.unit or "player"
	local ArcaneCharges = self.ArcaneCharges
	local min, max = 0, MAX_CHARGES
	local duration, expire

	for i = 1, 40 do
		local count, _, start, time, _, _, _, spellID = select(4, UnitDebuff(unit, i))
		if (spellID == 36032) then
			min = count or 0
			duration = start
			expire = time
		end
	end	

	for i = 1, max do
		if (duration) and (expire) then
			ArcaneCharges[i]:SetMinMaxValues(0, duration)
			ArcaneCharges[i].duration = duration
			ArcaneCharges[i].expire = expire
		end
		
		if (i <= min) then
			ArcaneCharges[i]:SetValue(duration)
			ArcaneCharges[i]:SetScript("OnUpdate", updateCharge)
		else
			ArcaneCharges[i]:SetValue(0)
			ArcaneCharges[i]:SetAlpha(0)
			ArcaneCharges[i]:SetScript("OnUpdate", nil)
		end
	end		
end

specUpdate = function(self)
	local ArcaneCharges = self.ArcaneCharges
	local spec = GetSpecialization()
	if (spec == 1) then
		ArcaneCharges:Show()
	else
		ArcaneCharges:Hide()
	end
end

Update = function(self, event, ...)
	local arg1, arg2 = ...
	local ArcaneCharges = self.ArcaneCharges
	
	if ((event == "UNIT_ENTERED_VEHICLE") or (event == "UNIT_EXITED_VEHICLE")) and (arg1 == "player") then
		if (self.unit ~= "player") then
			ArcaneCharges:Hide()
		else
			ArcaneCharges:Show()
		end
	elseif (event == "PLAYER_LEVEL_UP") then
		local level = UnitLevel("player")
		if (level == 10) then
			self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
			registerEvents(self)
			specUpdate(self)
			update(self)
		end
	elseif (event == "ACTIVE_TALENT_GROUP_CHANGED") then
		specUpdate(self)
		update(self)
	else
		update(self)
	end
end

Path = function(self, ...)
	return (self.ArcaneCharges.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'HOLY_POWER')
end

Disable = function(self)
	if (self.ArcaneCharges) then
		self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:UnregisterEvent("UNIT_AURA", Path)
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Path)
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", Path)
		self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
	end
end

Enable = function(self, unit)
	local ArcaneCharges = self.ArcaneCharges
	if (ArcaneCharges) then 
		ArcaneCharges.__owner = self
		ArcaneCharges.ForceUpdate = ForceUpdate		

		local level = UnitLevel("player")
		if (level < 10) then
			self:RegisterEvent("PLAYER_LEVEL_UP", Path)
			self:Hide()
		else
			registerEvents(self)
		end
	end
end

oUF:AddElement("ArcaneCharges", Path, Enable, Disable)
