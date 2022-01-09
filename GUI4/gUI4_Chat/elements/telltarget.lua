local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Chat", true)
if not parent then return end

local module = parent:NewModule("TellTarget", "GP_AceConsole-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local T

BINDING_NAME_GUI4_CHAT_TELLTARGET = L["Whisper your Target"]
BINDING_NAME_GUI4_CHAT_TELLFOCUS = L["Whisper your Focus Target"]

-- wow api
local ChatFrame_SendTell = ChatFrame_SendTell
local SendChatMessage = SendChatMessage
local UnitExists = UnitExists
local UnitIsSameServer = UnitIsSameServer
local UnitName = UnitName

local function updateConfig()
	T = parent:GetActiveTheme()
end

local getUnitName = function(unit)
	if UnitExists(unit) then 
		local unitname, realm = UnitName(unit)
		if unitname then 
			unitname = unitname:gsub(" ", "")
			if not(UnitIsSameServer("player", unit)) then
				unitname = unitname .. "-" .. realm:gsub(" ", "")
			end
			return unitname
		end
	end
end

local sendTell = function(unit, msg)
	if UnitExists(unit) then
		local unitname = getUnitName(unit)
		if unitname then
			SendChatMessage(msg, "WHISPER", nil, unitname)
		end
	end
end

local OnTextChanged = function(self)
	local text = self:GetText()
	if text:len() < 5 then
		if (text:sub(1, 4) == "/tt ") or (text:sub(1, 4) == "/wt ") then
			local unitname = getUnitName("target")
			if unitname then
				ChatFrame_SendTell(unitname, SELECTED_CHAT_FRAME)
			end
		elseif (text:sub(1, 4) == "/tf ") or (text:sub(1, 4) == "/wf ") then
			local unitname = getUnitName("focus")
			if unitname then
				ChatFrame_SendTell(unitname, SELECTED_CHAT_FRAME)
			end
		end
	end
end

function module:ApplySettings()
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("TellTarget", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()
	
	for i = 1, NUM_CHAT_WINDOWS do
		_G[("ChatFrame%dEditBox"):format(i)]:HookScript("OnTextChanged", OnTextChanged)
	end

	self:RegisterChatCommand("tt", function(msg) sendTell("target", msg) end)
	self:RegisterChatCommand("tf", function(msg) sendTell("focus", msg) end)	
	self:RegisterChatCommand("wt", function(msg) sendTell("target", msg) end)
	self:RegisterChatCommand("wf", function(msg) sendTell("focus", msg) end)	
end
