﻿local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local parent = gUI4:GetModule("gUI4_UnitFrames")
if not parent then return end

local module = parent:NewModule("Pet", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

-- Lua API
local unpack = unpack 

local defaults = {
	profile = {
		locked = true,
		auras = {
			showAuras = true,
			-- showBuffs = true, -- display buffs
			-- showDebuffs = true, -- display debuffs
			onlyInCombat = true, -- display all auras when not engaged in combat, ignoring all filters
			-- always show
			alwaysShowBossDebuffs = true, -- always show boss debuffs. overrides other choices
			-- alwaysShowStealable = true, -- always display stealable buffs. overrides other choices
			-- always hide
			onlyPlayer = false, -- only display buffs and debuffs cast by the player
			onlyShortBuffs = true, -- only display short buffs (less than 60 seconds)
			showConsolidated = false, -- show stuff that wow would consolidate
			showTimeless = false, -- display static auras with no timer, like presences, shapes, zone buffs, etc
		},
		position = {}
	}
}

local deprecated = {
	showBuffs = true,
	showDebuffs = true,
	alwaysShowStealable = true
}

local function scaffolding(self, unit)
	-- statusbars
	self.Health = LMP:NewChain("StatusBar", nil, self) :SetFrameLevel(self:GetFrameLevel() + 1) :SetPostUpdate(ns.postUpdateHealth) .__EndChain
	self.Health.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints() .__EndChain
	self.Health.Glow = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Health.Border = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Health.Highlight = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 2) .__EndChain
	self.Health.Overlay = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain

	-- move this to profile or theme or both?
	self.Health.colorHealth = true
	self.Health.colorClass = true
	self.Health.colorClassPet = false
	self.Health.colorPetAsPlayer = true -- the pet is always there, so make its color more fitting
	self.Health.colorReaction = true
	self.Health.colorDisconnected = true
	self.Health.colorTapping = true
	self.Health.colorSmooth = true

	self.Health.Smoother = true
	self.Health.frequentUpdates = true
	-- self.Health.SpiritHealer = self.SpiritHealer -- connect the spirithealer artwork
	self.Health.Override = gUI4:GetFunction("UpdateHealthBar")
	
	-- low health pulse
	local build = tonumber((select(2, GetBuildInfo())))
	if build >= 22124 then -- Legion
		self.Health.Pulse = LMP:NewChain(self.Health:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 1) :SetAllPoints(self.Health:GetStatusBarTexture()) :SetBlendMode("BLEND") :SetColorTexture(1,0,0,.5) .__EndChain
		self.Health.Pulse.Anim = LMP:NewChain(self.Health.Pulse:CreateAnimationGroup()) :SetLooping("REPEAT") .__EndChain
		self.Health.Pulse.Anim.start = LMP:NewChain(self.Health.Pulse.Anim:CreateAnimation("Alpha")) :SetToAlpha(0) :SetDuration(0) :SetSmoothing("IN") :SetOrder(0) .__EndChain
		self.Health.Pulse.Anim.fadeIn = LMP:NewChain(self.Health.Pulse.Anim:CreateAnimation("Alpha")) :SetToAlpha(.5) :SetDuration(.5) :SetOrder(1) .__EndChain
		self.Health.Pulse.Anim.fadeOut = LMP:NewChain(self.Health.Pulse.Anim:CreateAnimation("Alpha")) :SetToAlpha(0) :SetDuration(.5) :SetOrder(2) .__EndChain
		self.Health.Pulse.Anim:Play()
	else
		self.Health.Pulse = LMP:NewChain(self.Health:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 1) :SetAllPoints(self.Health:GetStatusBarTexture()) :SetBlendMode("BLEND") :SetTexture(1,0,0,.5) .__EndChain
		self.Health.Pulse.Anim = LMP:NewChain(self.Health.Pulse:CreateAnimationGroup()) :SetLooping("REPEAT") .__EndChain
		self.Health.Pulse.Anim.start = LMP:NewChain(self.Health.Pulse.Anim:CreateAnimation("Alpha")) :SetChange(-1) :SetDuration(0) :SetSmoothing("IN") :SetOrder(0) .__EndChain
		self.Health.Pulse.Anim.fadeIn = LMP:NewChain(self.Health.Pulse.Anim:CreateAnimation("Alpha")) :SetChange(.5) :SetDuration(.5) :SetOrder(1) .__EndChain
		self.Health.Pulse.Anim.fadeOut = LMP:NewChain(self.Health.Pulse.Anim:CreateAnimation("Alpha")) :SetChange(-.5) :SetDuration(.5) :SetOrder(2) .__EndChain
		self.Health.Pulse.Anim:Play()
	end
	
	-- health spark
	self.Health.Spark = LMP:NewChain(self.Health:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain

	-- castbar
	self.Castbar = LMP:NewChain("StatusBar", nil, self) :SetFrameLevel(self:GetFrameLevel() + 3) .__EndChain
	self.Castbar.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) .__EndChain
	self.Castbar.BackdropFrame = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetAllPoints(self.Castbar.OverlayFrame) .__EndChain
	self.Castbar.Glow = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Castbar.Border = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Castbar.Highlight = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 2) .__EndChain
	self.Castbar.Overlay = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain
	self.Castbar.SafeZone = LMP:NewChain(self.Castbar:CreateTexture()) :SetDrawLayer("OVERLAY") :SetAllPoints(self.Castbar) :SetAlpha(1/4) .__EndChain
	self.Castbar.Icon = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) :SetTexCoord(5/64, 59/64, 5/64, 59/64) .__EndChain
	self.Castbar.Icon.Glow = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Castbar.Icon.Border = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Castbar.Icon.Overlay = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain
	self.Castbar.Time = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(TextStatusBarText) .__EndChain
	self.Castbar.CustomTimeText = function(self, duration)
		if self.casting then
			self.Time:SetFormattedText("%.1f", self.max - duration)
		elseif self.channeling then
			self.Time:SetFormattedText("%.1f", duration)
		end
	end

	-- threat
	self.Health.Threat = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 4) :SetAllPoints() :Hide() .__EndChain
	self.Threat = {
		Hide = function() 
			self.Health.Threat:Hide()
		end,
		Show = function() 
			if self.Health.Threat.enabled then
				self.Health.Threat:Show()
			end
		end,
		SetVertexColor = function(frame, ...) 
			self.Health.Threat:SetVertexColor(...)
		end,
		IsObjectType = function()
		end
	}
  
	-- auras
	self.Auras = CreateFrame("Frame", nil, self)
	self.Auras.GetSettings = function() return module.db.profile.auras end
	self.Auras.PostUpdateIcon = gUI4:GetFunction("PostUpdateAuraIcon")
	self.Auras.PostCreateIcon = gUI4:GetFunction("PostCreateAuraIcon")
	self.Auras.CustomFilter = ns.CustomAuraFilter
	self.Auras.disableCooldown = true
	self.Auras:HookScript("OnHide", function(self)
		-- visibleBuffs visibleAuras visibleDebuffs createdIcons
		if not self.visibleAuras then return end
		for i = 1, self.visibleAuras do
			local button = type(self[i]) == "table" and self[i]
			if button then
				
			end
		end
		for i = self.visibleAuras, self.createdIcons do
			local button = type(self[i]) == "table" and self[i]
			if button and button.StopFlash then
				button:StopFlash()
				button:StopAllFades()
				button:RawHide()
				button:SetAlpha(0)
			end
		end
	end)
	self.Auras:HookScript("OnShow", function(self)
		if not self.visibleAuras then return end
		for i = 1, self.visibleAuras do
			local button = type(self[i]) == "table" and self[i]
			if button then
				
			end
		end
		for i = self.visibleAuras, self.createdIcons do
			local button = type(self[i]) == "table" and self[i]
			if button and button.StopFlash  then
				button:StopFlash()
				button:StopAllFades()
				button:RawHide()
				button:SetAlpha(0)
			end
		end
	end)
	
	-- fontstrings
	self.CombatFeedbackText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(NumberFontNormalHuge) .__EndChain
	self.HealthText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(TextStatusBarText) .__EndChain
	self.NameText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(GameFontNormalSmall) :SetWordWrap(false) :SetNonSpaceWrap(false) .__EndChain

	-- widgets
	self.RaidIcon = LMP:NewChain(self.IconFrame:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.UnitRange = { insideAlpha = 1, outsideAlpha = .75 }
	self.HealPrediction = { 
		myBar = LMP:NewChain("StatusBar", nil, self) :SetStatusBarTexture(1, 1, 1, .3) :SetStatusBarColor(unpack(self.colors.healpredict.predict)) .__EndChain,
		otherBar = LMP:NewChain("StatusBar", nil, self) :SetStatusBarTexture(1, 1, 1, .3) :SetStatusBarColor(unpack(self.colors.healpredict.predictOther)) .__EndChain,
		absorbBar = LMP:NewChain("StatusBar", nil, self) :SetStatusBarTexture(1, 1, 1, .3) :SetStatusBarColor(unpack(self.colors.healpredict.absorb)) .__EndChain,
		healAbsorbBar = LMP:NewChain("StatusBar", nil, self) :SetStatusBarTexture(1, 1, 1, .3) :SetStatusBarColor(unpack(self.colors.healpredict.absorbOther)) .__EndChain,
		maxOverflow = 1, 
		frequentUpdates = true 
	}
	
	-- frame references 
	self.CastbarText = self.Castbar.Time
	self.CastbarText.frame = self
	self.CombatFeedbackText.frame = self
	self.Health.frame = self
	self.HealthText.frame = self
	self.NameText.frame = self
	
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Pet", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	for i in pairs(deprecated) do
		if self.db.profile[i] ~= nil then
			self.db.profile[i] = nil
		end
	end
end

function module:OnEnable()
	if not self.loaded then
		self:AddUnit("pet", scaffolding, self.db.profile)
		self.loaded = true
	end
end

function module:OnDisable()
	
end
