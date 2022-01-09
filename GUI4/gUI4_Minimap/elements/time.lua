local addon = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule(addon, true)
if not parent then return end

local module = parent:NewModule("Time", "GP_AceEvent-3.0")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
--local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local T, hasTheme

-- Lua API
local date = _G.date
local tostring = tostring
local unpack = unpack

-- WoW API
local CreateFrame = _G.CreateFrame
local GetGameTime = _G.GetGameTime
local TextStatusBarText = _G.TextStatusBarText
local TIMEMANAGER_AM = _G.TIMEMANAGER_AM
local TIMEMANAGER_PM = _G.TIMEMANAGER_PM

local defaults = {
	profile = {
		useGameTime = false, 
		use24hrClock = true
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().widgets.time
end

local time12, time24 = "%d:%02d%s", "%02d:%02d"
local function getTimeData()
	local h, m
	if module.db.profile.useGameTime then
		h, m = GetGameTime()
	else
		local dateTable = date("*t")
		h = dateTable.hour
		m = dateTable.min 
	end
	if module.db.profile.use24hrClock then
		return time24, h, m
	else
		-- 12-hour clock: https://en.wikipedia.org/wiki/12-hour_clock
		if (h < 12) then										
			if (h == 0) then
				return time12, h + 12, m, TIMEMANAGER_AM 		-- Midnight to one, displayed as 12AM
			else
				return time12, h, m, TIMEMANAGER_AM 			-- One to noon (0100 to 1159), same in both 12- and 24-hour clocks. AM.
			end
		else 													
			if (h == 12) then
				return time12, h, m, TIMEMANAGER_PM 			-- Noon to 1PM - 1200-1259, displayed as 12PM 
			elseif h < 24 then
				return time12, h - 12, m, TIMEMANAGER_PM 		-- 1PM to Midnight - 1300-2359, displayed as (hour-12)PM 
			else 
				return time12, h - 12, m, TIMEMANAGER_AM 		-- Midnight (start of the NEXT day, listed as 12AM)
			end
		end
	end
end

local hz = 1/2
local function OnUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed > hz then 
		self.text:SetFormattedText(getTimeData())
		self.elapsed = 0
	end
end

function module:UpdateTheme(_, _, addonName)
	if addonName ~= tostring(parent) then return end
	if not self.frame then return end 
	updateConfig()
	LMP:NewChain(self.frame.text) :ClearAllPoints() :SetPoint(unpack(T.message.place)) :SetFontObject(T.message.fontobject) :SetFontSize(T.message.fontsize) :SetFontStyle(T.message.fontstyle) :SetShadowOffset(unpack(T.message.shadowoffset)) :SetShadowColor(unpack(T.message.shadowcolor)) :SetTextColor(unpack(gUI4:GetColors("chat", "offwhite"))) :EndChain()
	hasTheme = true
	self:ApplySettings()
end	
	
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
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Time", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	self.frame = parent:RegisterWidget("time", LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapTimeFrame", parent:GetWidgetFrame())) :Hide() :SetAllPoints() :SetScript("OnUpdate", OnUpdate) .__EndChain)
	self.frame.text = LMP:NewChain("FontString", "GUI4_MinimapTime", self.frame) :SetFontObject(TextStatusBarText) :SetDrawLayer("OVERLAY", 3) .__EndChain

	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
end

function module:OnEnable()
	self.frame:Show()
end

function module:OnDisable()
	self.frame:Hide()
end
