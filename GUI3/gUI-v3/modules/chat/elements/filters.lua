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
local module = parent:NewModule("Filters")

local strfind = string.find
local strmatch = string.match

local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local db
local noYellSpam, noTradeSpam, noWeirdGroupSpam, noWhisperSpam
local learnFilter, sleepFilter, sleepFilterCheck

-- goldspam in /yell
local gold = "gold"
local goldSpam = { "%$", "www", "%.com", "%.net", "%.org", ",còm", ",cóm" }

-- account theft
local URLChecker = "www%d*([%s*%.*%s*]+)([%a%d]+)([%s*%.*%s*]+)([%a%d]+)"
local suspiciousContent = { "abnormal", "verify", "confirm", "login", "account", "visit" }
local suspiciousOpeners = { "^(%[(gm|game([%s]*)master)+%])" }

-- /print ("gm"):find("^[%[*([gm|gamemaster|game master]+)%]*]+")

-- other /yell spam
-- 	*feel free to email me any other offensive or dead annoying crap that 
-- 	are spammed by people on a regular basis, and I'll add it to the list if it's fitting
local yellSpam = { "anal", "cunt", "rape", "dirge", "murloc", "{rt%d}", "{star}", "{circle}", "{diamond}", "{triangle}", "{moon}", "{square}", "{cross}" }

-- always enable profanity. stupid filter. 
local dirtyTalk = function() SetCVar("profanityFilter", 0) end

noWhisperSpam = function(self, event, ...)
	local msg, author, lang, _, _, status, _, _, _, _, lineID, GUID = ...
	
	-- make sure real GM messages always come through
	if (status == "GM") then
		return
	end
	
	-- identify bad openers
	local opener
	for _, word in ipairs(suspiciousOpeners) do
		if (strfind(msg:lower(), word)) then
			opener = true
			print("found an opener")
			break
		end
	end
	
	-- identify URLs
	local url
	if (strfind(msg, URLChecker)) then
		url = true
		print("found an url")
	end
	
	-- identify bad content
	local content = 0
	for _, word in ipairs(suspiciousContent) do
		if (strfind(msg:lower(), word)) then
			content = content + 1
		end
	end
	
	-- filter this out if we have a bad opener plus an url or suspicious content
	if (opener) then
		if (content > 0) or (url) then
			return true
		end
	end

end

noWeirdGroupSpam = function(self, event, msg)
	if (strfind(msg, (ERR_TARGET_NOT_IN_GROUP_S:gsub("%%s", "(.+)")))) then
		return true
	end
end

noTradeSpam = function(selv, event, msg, ...)
	-- check for gold spammers
	-- we do this by checking for URLs combined with the keyword 'gold'
	if (strfind(msg:lower(), gold)) then
		for _, word in ipairs(goldSpam) do
			if (strfind(msg:lower(), word)) then
				return true
			end
		end
	end

	-- check for retarded spam by people dragging 
	-- the average IQ of the entire human race down
	for _, word in ipairs(yellSpam) do
		if (strfind(msg:lower(), word)) then
			return true
		end
	end	
end

noYellSpam = function(self, event, msg, ...)
	-- check for gold spammers
	-- we do this by checking for URLs combined with 'gold'
	if (strfind(msg:lower(), gold)) then
		for _, word in ipairs(goldSpam) do
			if (strfind(msg:lower(), word)) then
				return true
			end
		end
	end
	
	-- check for retarded spam by people dragging 
	-- the average IQ of the entire human race down
	for _, word in ipairs(yellSpam) do
		if (strfind(msg:lower(), word)) then
			return true
		end
	end
end

-- TODO: create searches based on WoWs localized global strings for these functions
learnFilter = function(self, event, arg)
	 if strfind(arg, "You have unlearned") or strfind(arg, "You have learned a new spell:") or strfind(arg, "You have learned a new ability:") or strfind(arg, "Your pet has unlearned") then
		  return true
	 end
end

sleepFilter = function(self, event, arg1)
	 if strfind(arg1, "falls asleep. Zzzzzzz.") then
		return true
	 end
end

-- http://www.wowpedia.org/API_SetMapByID
local city = {
	[301] = true; -- Stormwind City
	[321] = true; -- Orgrimmar
	[341] = true; -- Ironforge
	[362] = true; -- Thunder Bluff
	[381] = true; -- Darnassus
	[382] = true; -- Undercity
	[471] = true; -- The Exodar
	[480] = true; -- Silvermoon City
	[481] = true; -- Shattrath City
	[504] = true; -- Dalaran
	[684] = true; -- Gilneas
}

-- enable sleep filter only in cities
sleepFilterCheck = function()
	SetMapToCurrentZone()
	if (city[(GetCurrentMapAreaID())]) then 
		ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", sleepFilter)
	else
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", sleepFilter)
	end
end

module.OnInit = function(self)
	db = self:GetParent():GetCurrentOptionsSet() -- get the chat settings
end

module.OnEnable = function(self)
	-- activate learning spam filter (when changing spec)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", learnFilter)
	
	-- activate whisper spam (usually by account thieves)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", noWhisperSpam)
	
	-- sometimes when leaving raidgroups, we're flooded with "is not in your party"-messages
	-- since we're not actually getting any errors, just system messages, we simply hide the spam. For now.
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", noWeirdGroupSpam)

	-- clean up the /yell and trade channel a bit
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", noTradeSpam)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", noYellSpam)

	-- check whether to activate sleep spam filter or not
	self:RegisterEvent("PLAYER_ENTERING_WORLD", sleepFilterCheck)
	self:RegisterEvent("ZONE_CHANGED_INDOORS", sleepFilterCheck)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", sleepFilterCheck)
	
	-- keep profanity visible 
	-- *EDIT: no longer needed, but still keeping it for easy configuration purposes
	self:RegisterEvent("CVAR_UPDATE", dirtyTalk)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", dirtyTalk)
end

module.OnDisable = function(self)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", learnFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", noWhisperSpam)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", noWeirdGroupSpam)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", noTradeSpam)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", noYellSpam)

	self:UnregisterEvent("PLAYER_ENTERING_WORLD", sleepFilterCheck)
	self:UnregisterEvent("ZONE_CHANGED_INDOORS", sleepFilterCheck)
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", sleepFilterCheck)
	self:UnregisterEvent("CVAR_UPDATE", dirtyTalk)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", dirtyTalk)
end