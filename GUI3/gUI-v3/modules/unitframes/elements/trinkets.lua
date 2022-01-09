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

local arenaFrame = {} -- { [unit] = frame }
local arenaGUID  = {} -- { [guid] = unitID }
local usedTrinkets = {} -- { [guid] = boolean }
local trinketFrame = {} -- { [guid] = unique frame for OnUpdate per guid } ... bad idea?

local SendMessage = function(msg)
	if (F.IsInHomeGroup()) and (F.IsInArena()) then
		SendChatMessage(msg, "PARTY")
	end
end
 
local TrinketUpdate = function(self, elapsed)
	if (self.endTime >= GetTime()) then
		usedTrinkets[self.guid] = false
		local unit = arenaGUID[self.guid]
		local frame = arenaFrame[unit]
		if (unit) and (frame) then
			if (frame.PvPTrinket.trinketUpAnnounce) then
				local name, class = UnitName(unit), UnitClass(unit)
				if (name) and (class) then
					SendMessage(L["Trinket ready: "] .. name .. " " .. class)
				end
			end
		end
		self:SetScript("OnUpdate", nil)
	end
end

local GetTrinketIcon = function(unit)
	if (UnitFactionGroup(unit) == "Alliance") then
		return [[Interface\Icons\INV_Jewelry_TrinketPVP_01]]
	else
		return [[Interface\Icons\INV_Jewelry_TrinketPVP_02]]
	end
end

local TrinketUsed = function(self, guid, time)
	local PvPTrinket = self.PvPTrinket

	local unit = arenaGUID[guid]
	if (unit) and (unit == self.unit) then
		CooldownFrame_SetTimer(PvPTrinket.cooldownFrame, GetTime(), time, 1)
		if (PvPTrinket.trinketUseAnnounce) then
			local name, class = UnitName(unit), UnitClass(unit)
			if (name) and (class) then
				local message = (time == 120) and L["Trinket used: "] or L["WotF used: "]
				SendMessage(message .. name .. " " .. class)
			end
		end
	end

	usedTrinkets[guid] = true -- register that this guid has a trinket cooldown

	if not(trinketFrame[guid]) then 
		trinketFrame[guid] = CreateFrame("Frame", nil, UIParent) -- create a new frame for this guid 
	end
	
	trinketFrame[guid].endTime = GetTime() + time
	trinketFrame[guid].guid = guid
	trinketFrame[guid]:SetScript("OnUpdate", TrinketUpdate)
end

local UpdateVisibility = function()
	-- if (F.IsInArena()) then
		local guid, unit
		for i, frame in pairs(arenaFrame) do
			unit = frame.unit or i
			if (unit) then
				guid = UnitGUID(unit) 
				if (frame:IsShown()) and (guid) and (usedTrinkets[guid]) and (trinketFrame[guid]) and (trinketFrame[guid].guid == guid) then
					frame.PvPTrinket:Show()
				else
					frame.PvPTrinket:Hide()
				end
			else
				frame.PvPTrinket:Hide()
			end
		end
	-- else
		-- for unit, frame in pairs(arenaFrame) do
			-- frame.PvPTrinket:Hide()
		-- end
	-- end
end


local Update = function(self, event, ...)
	-- visibility handling, we don't want trinkets in BGs. impossible to track properly
	if (event == "ZONE_CHANGED_NEW_AREA") then
		UpdateVisibility()

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName = ...

		if (eventType == "SPELL_CAST_SUCCESS") and (sourceGUID) then
			-- enemy trinket usage (every man for himself, pvp trinket)
			if (spellID == 59752) or (spellID == 42292) then
				TrinketUsed(self, sourceGUID, 120)
			end
			
			-- WotF
			if (spellID == 7744) then
				TrinketUsed(self, sourceGUID, 30); -- activates a 30 sec cooldown shared with similar effects
			end
		end
	elseif (event == "ARENA_OPPONENT_UPDATE") then
		local unit, type = ...
		if (type == "seen") then
			if (unit == self.unit) then
				arenaGUID[UnitGUID(unit)] = unit
				self.PvPTrinket.Icon:SetTexture(GetTrinketIcon(unit))
				UpdateVisibility()
			end
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		UpdateVisibility()
		for k, v in pairs(trinketFrame) do
			v:SetScript("OnUpdate", nil)
		end
		for k, v in pairs(arenaFrame) do
			CooldownFrame_SetTimer(v.PvPTrinket.cooldownFrame, 1, 1, 1)
		end
		wipe(arenaGUID)
		wipe(usedTrinkets)
		wipe(trinketFrame)
	end
end

Path = function(self, ...)
	return (self.PvPTrinket.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

Disable = function(self)
	if (self.PvPTrinket) then
		arenaFrame[self.unit] = nil
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED", Path)
		self:UnregisterEvent("ARENA_OPPONENT_UPDATE", Path)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", Path)
	end
end

Enable = function(self, unit)
	local PvPTrinket = self.PvPTrinket
	if (PvPTrinket) then 
		PvPTrinket.__owner = self
		PvPTrinket.ForceUpdate = ForceUpdate

		PvPTrinket:Hide() -- start out hidden
		
		PvPTrinket.cooldownFrame = PvPTrinket.cooldownFrame or CreateFrame("Cooldown", nil, PvPTrinket)
		PvPTrinket.cooldownFrame:SetAllPoints(PvPTrinket)

		PvPTrinket.Icon = PvPTrinket.Icon or PvPTrinket:CreateTexture(nil, "BORDER")
		PvPTrinket.Icon:SetAllPoints(PvPTrinket)
		PvPTrinket.Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)

		arenaFrame[self.unit or unit] = self

		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", Path)
		self:RegisterEvent("ARENA_OPPONENT_UPDATE", Path)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", Path)
		
		UpdateVisibility()
	end
end

oUF:AddElement("PvPTrinket", Path, Enable, Disable)

oUF.Tags.Methods["gUI™ trinket"] = function(unit)
	if usedTrinkets[UnitGUID(unit)] or not UnitIsPlayer(unit) then return end
	return string.format("|T%s:20:20:0:0|t", GetTrinketIcon(unit))
end
