local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local module = parent:NewModule("ErrorFrame", "GP_AceEvent-3.0")

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local LibWin = GP_LibStub("GP_LibWindow-1.1")
local T, hasTheme
local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

-- Lua API
local type = type

-- WoW API
local GetTime = GetTime
local UIErrorsFrame = UIErrorsFrame

local defaults = {
	profile = {
		locked = true,
		position = {
			point = "TOP",
			x = 0,
			y = -20
		}
	}
}

local function updateConfig() 
	T = parent:GetActiveTheme().errorframe
end

local HZ = 2.0 -- time in seconds between each identical error message
local lastError 
local lastTime = 0
local messageInfo = {} 
local messageInfoDefault = { r = 1, g = .82, b = .04 } 
function module:Message(msg, r, g, b)
	local now = GetTime()
	if msg == lastError and (lastTime + HZ) > now then
		return
	end
	lastError = msg
	lastTime = now
	if type(r) == "table" then
		UIErrorsFrame:AddMessage(msg, r.r, r.g, r.b)
	elseif r then 
		messageInfo.r = r
		messageInfo.g = g
		messageInfo.b = b
		UIErrorsFrame:AddMessage(msg, messageInfo)
	else
		UIErrorsFrame:AddMessage(msg, messageInfoDefault.r, messageInfoDefault.g, messageInfoDefault.b)
	end
end

local warningInfo = {} -- just use the same table every time this is called with a custom color
local warningInfoDefault = { r = .85, g = .15, b = .04 } -- keep defaults separated, so we don't have to set them
function module:RaidWarning(msg, r, g, b)
	if type(r) == "table" then
		RaidNotice_AddMessage(RaidWarningFrame, msg, r)
	elseif r then 
		warningInfo.r = r
		warningInfo.g = g
		warningInfo.b = b
		RaidNotice_AddMessage(RaidWarningFrame, msg, warningInfo)
	else
		RaidNotice_AddMessage(RaidWarningFrame, msg, warningInfoDefault)
	end
end

local noticeInfo = {} -- just use the same table every time this is called with a custom color
local noticeInfoDefault = ChatTypeInfo["RAID_BOSS_EMOTE"] -- keep defaults separated, so we don't have to set them
function module:RaidNotice(msg, r, g, b)
	if type(r) == "table" then
		RaidNotice_AddMessage(RaidBossEmoteFrame, msg, r)
	elseif r then
		noticeInfo.r = r
		noticeInfo.g = g
		noticeInfo.b = b
		RaidNotice_AddMessage(RaidBossEmoteFrame, msg, noticeInfo)
	else
		RaidNotice_AddMessage(RaidBossEmoteFrame, msg, noticeInfoDefault)
	end
end

function module:UI_ERROR_MESSAGE(event, ...)
	local msg = LEGION and select(2, ...) or select(1, ...)
	if not msg then return end
	self:Message(msg, warningInfoDefault)
end

function module:UI_INFO_MESSAGE(event, ...)
	local msg = LEGION and select(2, ...) or select(1, ...)
	if not msg then return end
	self:Message(msg, messageInfoDefault)
end

function module:PET_BATTLE_OPENING_START()
	LMP:Place(self.frame, self.frame.petBattlePos)
end

local positionCallbacks = {}
function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	if not self.frame then return end
	updateConfig()
	for callback in pairs(positionCallbacks) do
		self:UnregisterMessage(callback, "UpdatePosition")
	end
	wipe(positionCallbacks)
	for callback in pairs(T.positionCallbacks) do
		positionCallbacks[callback] = true
	end
	for callback in pairs(positionCallbacks) do
		self:RegisterMessage(callback, "UpdatePosition")
	end
	LMP:NewChain(self.frame) :SetSize(unpack(T.size)) :EndChain()
	LMP:NewChain(self.frame.messageFrame) :SetFontObject(T.fontobject) :SetShadowColor(unpack(T.shadowcolor)) :SetShadowOffset(unpack(T.shadowoffset)) :SetTimeVisible(T.timevisible) :SetFadeDuration(T.fadeduration) :EndChain()
	hasTheme = true
	self:ApplySettings()
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings()
	if not self.frame then return end
	updateConfig()
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.frame then return end
	updateConfig()
	local db = self.db.profile
	if db.locked then
		LMP:Place(self.frame, T.place)
	else
		LibWin.RegisterConfig(self.frame, db.position)
		if db.position.x then
			-- code to restore position here
			-- self.frame:LoadPosition()
			LibWin.RestorePosition(self.frame)
		else
			LMP:Place(self.frame, T.place)
			-- code to save position here
			-- self.frame:SavePosition()
			-- self.frame:LoadPosition()
			LibWin.SavePosition(self.frame)
			LibWin.RestorePosition(self.frame)
		end
	end
end
-- no secure frame is moved (I think), so it's safe to let this move during combat
-- since the extraactionbutton sometimes appear during combat, this is needed
-- module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:Lock()
end

function module:Unlock()
end

function module:ResetLock()
	-- if UnitAffectingCombat("player") then return end
	-- if not hasTheme then return end
	-- if not self.frame then return end
	-- updateConfig()
	-- local db = self.db.profile
	-- db.position.point = nil
	-- db.position.y = nil
	-- db.position.x = nil
	-- db.locked = true
	-- wipe(db.position)
	-- self:ApplySettings()
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("ErrorFrame", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4_ErrorFrameHolder", UIParent)) :SetMovable(true) .__EndChain
	self.frame.messageFrame = LMP:NewChain(UIErrorsFrame) :SetParent(self.frame) :ClearAllPoints() :SetPoint("TOPLEFT", self.frame, 0, 0) :SetPoint("BOTTOMRIGHT", self.frame, 0, 0) .__EndChain
	self.frame.petBattlePos = { "TOP", 0, -130 }

	UIErrorsFrame.ClearAllPoints = function() end
	UIErrorsFrame.SetPoint = function() end
	UIErrorsFrame.SetAllPoints = function() end
	UIErrorsFrame:SetAlpha(.75)
	
	RaidWarningFrame:ClearAllPoints()
	RaidWarningFrame:SetPoint("TOP", self.frame, "BOTTOM", 0, -10)
	RaidWarningFrame:SetAlpha(.75)
	
	self:ApplySettings()
	
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
end

function module:OnEnable()
	UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("UI_INFO_MESSAGE")
	self:RegisterEvent("PET_BATTLE_OPENING_START")
	self:RegisterEvent("PET_BATTLE_CLOSE", "UpdatePosition")
end

function module:OnDisable()
	UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	UIErrorsFrame:RegisterEvent("UI_INFO_MESSAGE")
	self:UnregisterEvent("UI_ERROR_MESSAGE")
	self:UnregisterEvent("UI_INFO_MESSAGE")
	self:UnregisterEvent("PET_BATTLE_OPENING_START")
	self:UnregisterEvent("PET_BATTLE_CLOSE", "UpdatePosition")
end

