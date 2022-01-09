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
local GetFriendshipID
local populate
local friendships = {}
local WoW51 = (select(4, GetBuildInfo())) >= 50100

populate = function()
	local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold
	for factionID = 1100, 1500 do
		if (WoW51) then
			friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
			if (friendID) then
				friendships[GetFactionInfoByID(factionID)] = factionID
			end
		else
			friendID, friendRep, friendMaxRep, friendText, friendTexture, friendTextLevel, friendThreshold = GetFriendshipReputationByID(factionID)
			if (friendID) then
				friendships[GetFactionInfoByID(factionID)] = factionID
			end
		end
	end
end
populate()

GetFriendshipID = function()
	if not(UnitExists("target")) or (UnitIsPlayer("target")) then 
		return 
	end
	return friendships[UnitName("target")]
end

Update = function(self, event, ...)
	local FriendshipBar = self.FriendshipBar
	local factionID = GetFriendshipID()
	if (factionID) then
		local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold
		if (WoW51) then
			friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
		else
			friendID, friendRep, friendMaxRep, friendText, friendTexture, friendTextLevel, friendThreshold = GetFriendshipReputationByID(factionID)
		end
		-- FriendshipBar:SetStatusBarColor(unpack(C.friendship[floor(friendRep/8400) + 1])) -- this is fugly
		FriendshipBar:SetMinMaxValues(0, min(friendMaxRep - friendThreshold, 8400))
		FriendshipBar:SetValue(friendRep - friendThreshold)
		FriendshipBar:Show()
		if (FriendshipBar.text) then
			FriendshipBar.text:SetText(friendTextLevel)
			FriendshipBar.text:Show()
		end
	else
		FriendshipBar:Hide()
		FriendshipBar.text:Hide()
	end
end

Path = function(self, ...)
	return (self.FriendshipBar.Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

Disable = function(self)
	if (self.FriendshipBar) then
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Path)
		self:UnregisterEvent("UPDATE_FACTION", Path)
	end
end

Enable = function(self, unit)
	local FriendshipBar = self.FriendshipBar
	if (FriendshipBar) then 
		FriendshipBar.__owner = self
		FriendshipBar.ForceUpdate = ForceUpdate	
	
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Path)
		self:RegisterEvent("UPDATE_FACTION", Path)
		Path(self, "PLAYER_TARGET_CHANGED")
		
		return true
	end
end

oUF:AddElement("FriendshipBar", Path, Enable, Disable)
