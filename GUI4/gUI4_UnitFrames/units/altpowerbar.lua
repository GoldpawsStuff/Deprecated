local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local parent = gUI4:GetModule("gUI4_UnitFrames")
if not parent then return end

local module = parent:NewModule("AltPowerBar", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

-- Lua API
local unpack = unpack 

local defaults = {
	profile = {
		alwaysVisible = true,
		locked = true,
		position = {}
	}
}

local function scaffolding(self, unit)
	self:EnableMouse(false)
	
	self.AltPowerBarHolder = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetAllPoints() .__EndChain

	self.AltPowerBarWidget = LMP:NewChain(CreateFrame("Frame", nil, self.AltPowerBarHolder)) :EnableMouse(true) .__EndChain
	self.AltPowerBarWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.AltPowerBarWidget)) :SetFrameLevel(self.AltPowerBarWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
	self.AltPowerBarWidget.bar = LMP:NewChain("StatusBar", nil, self.AltPowerBarWidget) .__EndChain
	self.AltPowerBarWidget.bar.value = LMP:NewChain("FontString", nil, self.AltPowerBarWidget.bar) :SetFontObject(GameFontNormal) .__EndChain
	self.AltPowerBarWidget.bar.overlay = LMP:NewChain(self.AltPowerBarWidget.bar:CreateTexture()) :SetDrawLayer("ARTWORK", -2) :SetAllPoints() .__EndChain
	self.AltPowerBarWidget.backdrop = LMP:NewChain(self.AltPowerBarWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
	self.AltPowerBarWidget.overlay = LMP:NewChain(self.AltPowerBarWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
	
	self.AltPowerBarWidget.colorTexture = true

	gUI4:ApplySmoothing(self.AltPowerBarWidget.bar)
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("AltPowerBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
end

function module:OnEnable()
	self:AddUnit("player", scaffolding, self.db.profile)
end
