--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow

local parent = gUI:GetModule("Chat")
local module = parent:NewModule("URLCopy")

local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local db
local getURL, parseURL, onHyperlinkShow
local curLink
local WoW51 = (select(4, GetBuildInfo())) >= 50100

getURL = function(msg)
	if (usecolor) then
		if (usebracket) then
			return "|cff"..color.."|Hurl:"..msg.."|h["..msg.."]|h|r "
		else
			return "|cff"..color.."|Hurl:"..msg.."|h"..msg.."|h|r "
		end
	else
		if (usebracket) then
			return "|Hurl:"..msg.."|h["..msg.."]|h "
		else
			return "|Hurl:"..msg.."|h"..msg.."|h "
		end
	end
end

parseURL = function(self, event, msg, ...)
	local newMsg, found = gsub(msg, "(%a+)://(%S+)%s?", getURL("%1://%2"))
	if (found > 0) then 
		return false, newMsg, ... 
	end
	
	newMsg, found = gsub(msg, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", getURL("www.%1.%2"))
	if (found > 0) then 
		return false, newMsg, ... 
	end

	newMsg, found = gsub(msg, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", getURL("%1@%2%3%4"))
	if (found > 0) then 
		return false, newMsg, ... 
	end
end

onHyperlinkShow = function(self, link, text, button)
	if ((link):sub(1, 3) == "url") then
		local editBox = ChatEdit_ChooseBoxForSend()
		curLink = (link):sub(5)
		if not(editBox:IsShown()) then
			ChatEdit_ActivateChat(editBox)
		end
		editBox:Insert(curLink)
		editBox:HighlightText()
		curLink = nil
		return
	end
	
	-- this is the original Blizzard function,
	-- as we copied it to our local at the start
	ChatFrame_OnHyperlinkShow(self, link, text, button)
end

module.OnInit = function(self)
	db = self:GetParent():GetCurrentOptionsSet() -- get the chat settings
end

module.OnEnable = function(self)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", parseURL)

	if (WoW51) then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", parseURL)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", parseURL)
	else
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", parseURL)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", parseURL)
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", parseURL)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", parseURL)

	-- prehook Blizzards function
	_G.ChatFrame_OnHyperlinkShow = onHyperlinkShow
end

module.OnDisable = function(self)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_GUILD", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_OFFICER", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", parseURL)

	if (WoW51) then
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", parseURL)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", parseURL)
	else
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BATTLEGROUND", parseURL)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", parseURL)
	end
	
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER", parseURL)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_CONVERSATION", parseURL)
	
	_G.ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
end