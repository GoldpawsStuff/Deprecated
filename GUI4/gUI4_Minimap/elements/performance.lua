local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Minimap", true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local module = parent:NewModule("Performance", "GP_AceEvent-3.0")

-- Lua API
local floor = math.floor

-- WoW API
local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local GameTooltip = GameTooltip

local HZ = 1 -- update frequence of the performance stats in seconds
local msg = {
	text = "%d" .. MILLISECONDS_ABBR .. " - " .. "%d" .. FPS_ABBR,
	stat = gUI4:GetColorCode("chat", "normal") .. "%d|r" .. gUI4:GetColorCode("chat", "highlight") .. "%s|r",
	title = gUI4:GetColorCode("chat", "highlight") .. L["Network Stats"] .. "|r",
	world = L["World latency %s:"]:format(gUI4:GetColorCode("chat", "green") .. L["(Combat, Casting, Professions, NPCs, etc)"] .. "|r"), 
	home = L["Home latency %s:"]:format(gUI4:GetColorCode("chat", "green") .. L["(Chat, Auction House, etc)"] .. "|r")
}

local defaults = {
	profile = {
	}
}

local function onEnter(self)
	local _, _, home, world = GetNetStats()
	if world and world ~= 0 then
		if (not GameTooltip:IsForbidden()) then
			LMP:PlaceTip(self)
			LMP:NewChain(GameTooltip) :AddLine(msg.title) :AddDoubleLine(msg.world, msg.stat:format(world, MILLISECONDS_ABBR), gUI4:GetColors("chat", "normal")[1], gUI4:GetColors("chat", "normal")[2], gUI4:GetColors("chat", "normal")[3]) :AddDoubleLine(msg.home, msg.stat:format(home, MILLISECONDS_ABBR), gUI4:GetColors("chat", "normal")[1], gUI4:GetColors("chat", "normal")[2], gUI4:GetColors("chat", "normal")[3]) :Show() :EndChain()
		end
	end
end
local function onUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed > HZ then
		self.elapsed = 0
		local _, _, chat, cast = GetNetStats()
		local fps = floor(GetFramerate())
		if not cast or cast == 0 then
			cast = chat
		end
		self.text:SetFormattedText(msg.text, cast, fps)
		if (not GameTooltip:IsForbidden()) then
			if GameTooltip:IsVisible() and GameTooltip:GetOwner() == self then
				onEnter(self)
			end
		end
	end
end

local function onLeave(self) 
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide() 
	end
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Performance", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	self.frame = parent:RegisterWidget("performance", LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapPerformanceFrame", parent:GetWidgetFrame())) :Hide() :SetScript("OnUpdate", onUpdate) :SetScript("OnEnter", onEnter) :SetScript("OnLeave", onLeave) .__EndChain)
	self.frame.text = LMP:NewChain("FontString", "GUI4_MinimapPerformanceText", self.frame) :SetFontObject(GameFontNormalSmall) :SetDrawLayer("ARTWORK") :SetFontSize(12) :SetFontStyle() :SetShadowOffset(.75, -.75) :SetShadowColor(0, 0, 0, 1) :SetPoint("TOP", parent:GetWidgetFrame(), "BOTTOM", 0, -32) :SetTextColor(unpack(gUI4:GetColors("chat", "gray"))) .__EndChain
	self.frame:SetAllPoints(self.frame.text)
end

function module:OnEnable()
	self.frame:Show()
end

function module:OnDisable()
	self.frame:Hide()
end
