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
local module = parent:NewModule("Emoticons")
local E = gUI:GetDataBase("emoticons")
local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local db
local emoticonFilter, symbolFilter
local WoW51 = (select(4, GetBuildInfo())) >= 50100

local symbols = {
	-- normal shortcuts
	["%(c%)"] = "©";
	["%(copy%)"] = "©";
	["%(eur%)"] = "€";
	["%(euro%)"] = "€";
	["%(gbp%)"] = "£";
	["%(r%)"] = "®";
	["%(reg%)"] = "®";
	["%(tm%)"] = "™";
	["%(trade%)"] = "™";
	["%(usd%)"] = "$";
	
	-- exists in pt sans narrow, not in waukegan ldo
	["%!="] = "≠";
	["%~="] = "≠";
	["<>"] = "≠";
	["~~"] = "≈";
	["%(sqrt%)"] = "√";
	["%(integr%)"] = "∫";
	["%(sigma%)"] = "∑";
	["%(omega%)"] = "Ω";
	["%(delta%)"] = "∆";
	["%(inf%)"] = "∞";

	-- doesn't exist in either
--	["%(inter%)"] = "∩"; 
--	["%(lomega%)"] = "ω";
--	["%(phi%)"] = "Φ";
--	["%(psi%)"] = "Ψ";
--	["%(theta%)"] = "θ";
--	["%(lambda%)"] = "Λ";
--	["%(llambda%)"] = "λ";

	-- backwards compatibility to make 
	-- some of the items sent by WoWDings readable
--	["≠"] = "~="; -- exists in pt sans narrow
--	["≈"] = "~~"; -- exists in pt sans narrow
}

----------------------------------------------------------------------------------
-- Chat filters
----------------------------------------------------------------------------------
emoticonFilter = function(self, event, msg, ...)
	local new 
	new = F.EmoTheString(msg)
	if (new) then
		return false, new, ...
	end
end

symbolFilter = function(self, event, msg, ...)
	local symbols = symbols
	
	local pattern, symbol, new
	for pattern,symbol in pairs(symbols) do
		if (strfind(msg, pattern)) then
			new = gsub(new or msg, pattern, symbol)
		end
	end

	if (new) then
		return false, new, ...
	end
end

module.OnInit = function(self)
	db = self:GetParent():GetCurrentOptionsSet() -- get the chat settings
end

module.OnEnable = function(self)
	if (WoW51) then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", emoticonFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", emoticonFilter)
	else
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", emoticonFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", emoticonFilter)
	end
	
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_ALERT", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_BROADCAST", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_CONVERSATION", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_BOSS_WHISPER", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", emoticonFilter)
	--	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", emoticonFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", emoticonFilter)
		
	if (WoW51) then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", symbolFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", symbolFilter)
	else
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", symbolFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", symbolFilter)
	end
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_ALERT", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_BROADCAST", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_CONVERSATION", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_BOSS_WHISPER", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", symbolFilter)
	--	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", symbolFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", symbolFilter)
end

module.OnDisable = function(self)
	if (WoW51) then
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", emoticonFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", emoticonFilter)
	else
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BATTLEGROUND", emoticonFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", emoticonFilter)
	end
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_CONVERSATION", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_ALERT", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_BROADCAST", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_CONVERSATION", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_GUILD", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_OFFICER", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_BOSS_WHISPER", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_WARNING", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", emoticonFilter)
	--	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", emoticonFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", emoticonFilter)
		
	if (WoW51) then
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", symbolFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", symbolFilter)
	else
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BATTLEGROUND", symbolFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", symbolFilter)
	end
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_CONVERSATION", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_ALERT", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_BROADCAST", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_CONVERSATION", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_GUILD", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_OFFICER", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_BOSS_WHISPER", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_WARNING", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", symbolFilter)
	--	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", symbolFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", symbolFilter)
end