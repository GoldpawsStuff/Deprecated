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

local OnUpdate
local UpdateType, UpdateRune, UpdateVisibility
local ForceUpdate, Update, Enable, Disable
local runemap = { 1, 2, 5, 6, 3, 4 }

OnUpdate = function(self, elapsed)
	local duration = self.duration + elapsed
	if(duration >= self.max) then
		return self:SetScript("OnUpdate", nil)
	else
		self.duration = duration
		return self:SetValue(duration)
	end
end

UpdateType = function(self, event, rid, alt)
	local runes = self.RuneBar
	local rune = runes[runemap[rid]]
	local colors = self.colors.runes[GetRuneType(rid) or alt]
	local r, g, b = colors[1], colors[2], colors[3]

	rune:SetStatusBarColor(r, g, b)

	if(rune.bg) then
		local mu = rune.bg.multiplier or 1
		rune.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	if(runes.PostUpdateType) then
		return runes:PostUpdateType(rune, rid, alt)
	end
end

UpdateRune = function(self, event, rid)
	local runes = self.RuneBar
	local rune = runes[runemap[rid]]
	if(not rune) then return end

	local start, duration, runeReady = GetRuneCooldown(rid)
	if(runeReady) then
		rune:SetMinMaxValues(0, 1)
		rune:SetValue(1)
		rune:SetScript("OnUpdate", nil)
	else
		rune.duration = GetTime() - start
		rune.max = duration
		rune:SetMinMaxValues(1, duration)
		rune:SetScript("OnUpdate", OnUpdate)
	end

	if(runes.PostUpdateRune) then
		return runes:PostUpdateRune(rune, rid, start, duration, runeReady)
	end
end

Update = function(self, event)
	for i=1, 6 do
		UpdateRune(self, event, i)
	end
end

ForceUpdate = function(element)
	return Update(element.__owner, 'ForceUpdate')
end

UpdateVisibility = function(self, event, arg1)
	if (arg1 ~= "player") then return end
	local runes = self.RuneBar
	if (self.unit ~= "player") then
		runes:Hide()
	else
		runes:Show()
	end
end

Enable = function(self, unit)
	local runes = self.RuneBar
	if(runes and unit == 'player') then
		runes.__owner = self
		runes.ForceUpdate = ForceUpdate

		for i=1, 6 do
			local rune = runes[runemap[i]]
			if(rune:IsObjectType'StatusBar' and not rune:GetStatusBarTexture()) then
				rune:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
			end

			-- From my minor testing this is a okey solution. A full login always remove
			-- the death runes, or at least the clients knowledge about them.
			UpdateType(self, nil, i, math.floor((i+1)/2))
		end

		self:RegisterEvent("RUNE_POWER_UPDATE", UpdateRune, true)
		self:RegisterEvent("RUNE_TYPE_UPDATE", UpdateType, true)
		self:RegisterEvent("UNIT_DISPLAYPOWER", UpdateVisibility)
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", UpdateVisibility)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", UpdateVisibility)

		-- oUF leaves the vehicle events registered on the player frame, so
		-- buffs and such are correctly updated when entering/exiting vehicles.
		--
		-- This however makes the code also show/hide the RuneFrame.
		RuneFrame.Show = RuneFrame.Hide
		RuneFrame:Hide()

		tinsert(self.__elements, Update)
		
		return true
	end
end

Disable = function(self)
	RuneFrame.Show = nil
	RuneFrame:Show()

	self:UnregisterEvent("RUNE_POWER_UPDATE", UpdateRune)
	self:UnregisterEvent("RUNE_TYPE_UPDATE", UpdateType)
end

oUF:AddElement("RuneBar", Update, Enable, Disable)
