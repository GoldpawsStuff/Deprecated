--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local parent = gUI:GetModule("Chat")
local module = parent:NewModule("BattleNetLinks")

local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local db
local AddLinkColors, GetLinkColor

-- Originally written by P3lim (http://www.wowinterface.com/downloads/info19210-RealLinks.html)
GetLinkColor = function(data)
	local type, id, arg1 = strmatch(data, "(%w+):(%d+):(%d+)")
	if not(type) then 
		return "|cffffff88" 
	end
	if (type == "item") then
		local quality = (select(3, GetItemInfo(id)))
		if (quality) then
			return "|c" .. (select(4, GetItemQualityColor(quality)))
		else
			return "|cffffff88"
		end
	elseif (type == "quest") then
		local color = GetQuestDifficultyColor(arg1)
		return format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
		
	elseif (type == "spell") then
		return "|cff71d5ff"
		
	elseif (type == "achievement") then
		return "|cffffff00"
		
	elseif (type == "trade") or (type == "enchant") then
		return "|cffffd000"
		
	elseif (type == "instancelock") then
		return "|cffff8000"
		
	elseif (type == "glyph") then
		return "|cff66bbff"
		
	elseif (type == "talent") then
		return "|cff4e96f7"
		
	elseif (type == "levelup") then
		return "|cffFF4E00"
		
	elseif (type == "battlepet") then
		local _, _, level, rarity = strmatch(data, "(%w+):(%d+):(%d+):(%d+)")
		if (rarity) then
			return "|c" .. (select(4, GetItemQualityColor(rarity)))
		else
			return "|cffffff88"
		end
	else
		-- companions, other stuff we haven't included yet, 
		-- or items that haven't been cached
		return "|cffffff88" 
	end
end

AddLinkColors = function(self, event, msg, ...)
	local data = strmatch(msg, "|H(.-)|h(.-)|h")
	if (data) then
		return false, gsub(msg, "|H(.-)|h(.-)|h", GetLinkColor(data) .. "|H%1|h%2|h|r"), ...
	else
		return false, msg, ...
	end
end

module.OnInit = function(self)
	db = self:GetParent():GetCurrentOptionsSet() -- get the chat settings
end

module.OnEnable = function(self)
	-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", AddLinkColors) -- development purposes
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", AddLinkColors)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", AddLinkColors)
end

module.OnDisable = function(self)
	-- ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", AddLinkColors) -- development purposes
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER", AddLinkColors)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", AddLinkColors)
end