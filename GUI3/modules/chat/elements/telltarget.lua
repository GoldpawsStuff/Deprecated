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
local module = parent:NewModule("TellTarget")

local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local db
local OnTextChanged
local sendTell, sendMacroTell

sendTell = function(who)
	if not(UnitExists(who)) then return end
	local unitname, realm = UnitName(who)
	if (unitname) then 
		unitname = gsub(unitname, " ", "") 
	end
	if (unitname) and (not UnitIsSameServer("player", who)) then
		unitname = unitname .. "-" .. gsub(realm, " ", "")
	end
	return unitname
end

sendMacroTell = function(who, msg)
	if not(UnitExists(who)) then return end
	SendChatMessage(msg, "WHISPER", nil, sendTell(who))
end

OnTextChanged = function(self)
	local text = self:GetText()
	if (strlen(text) < 5) then
		if (strsub(text, 1, 4) == "/tt ") or (strsub(text, 1, 4) == "/wt ") then
			ChatFrame_SendTell((sendTell("target") or ""), SELECTED_CHAT_FRAME)
		elseif (strsub(text, 1, 4) == "/tf ") or (strsub(text, 1, 4) == "/wf ") then
			ChatFrame_SendTell((sendTell("focus") or ""), SELECTED_CHAT_FRAME)
		end
	end
end

module.OnInit = function(self)
	db = self:GetParent():GetCurrentOptionsSet() -- get the chat settings

	for i = 1, NUM_CHAT_WINDOWS do
		_G[("ChatFrame%dEditBox"):format(i)]:HookScript("OnTextChanged", OnTextChanged)
	end

	-- these chat commands exists for the purpose of user macros
	self:CreateChatCommand({"tt", "wt"}, function(msg) sendMacroTell("target", msg) end)
	self:CreateChatCommand({"tf", "wf"}, function(msg) sendMacroTell("focus", msg) end)
end

module.OnEnable = function(self)
end

module.OnDisable = function(self)
end