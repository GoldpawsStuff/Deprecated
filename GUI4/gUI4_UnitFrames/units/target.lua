local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local parent = gUI4:GetModule("gUI4_UnitFrames")
if not parent then return end

local module = parent:NewModule("Target", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

-- Lua API
local unpack, tostring = unpack, tostring

local defaults = {
	profile = {
		locked = true,
		auras = {
			-- visibility
			showBuffs = true, -- display buffs
			showDebuffs = true, -- display debuffs
			onlyInCombat = true, -- display all auras when not engaged in combat, ignoring all filters
			-- always show
			alwaysShowBossDebuffs = true, -- always show boss debuffs. overrides other choices
			alwaysShowStealable = true, -- always display stealable buffs. overrides other choices
			-- always hide
			onlyPlayer = false, -- only display buffs and debuffs cast by the player
			onlyShortBuffs = true, -- only display short buffs (less than 60 seconds)
			showConsolidated = false, -- show stuff that wow would consolidate
			showTimeless = false, -- display static auras with no timer, like presences, shapes, zone buffs, etc
		},
		position = {}
	}
}

local function scaffolding(self, unit)
	-- statusbars
	self.Health = LMP:NewChain("StatusBar", nil, self) :SetFrameLevel(self:GetFrameLevel() + 1) :SetPostUpdate(ns.postUpdateHealth) .__EndChain
	self.Health.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints() .__EndChain
	self.Health.Glow = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Health.Border = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Health.Highlight = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 2) .__EndChain
	self.Health.Overlay = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain

	self.Power = LMP:NewChain("StatusBar", nil, self) :SetFrameLevel(self:GetFrameLevel() + 2) .__EndChain
	self.Power.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints() .__EndChain
	self.Power.Glow = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Power.Border = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Power.Highlight = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 2) .__EndChain
	-- self.Power.Overlay = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain

	-- move this to profile or theme or both?
	self.Health.colorHealth = false
	self.Health.colorClass = true
	self.Health.colorClassPet = false
	self.Health.colorPetAsPlayer = false -- let's keep this one to the player pet frame only
	self.Health.colorReaction = true
	self.Health.colorDisconnected = true
	self.Health.colorTapping = true
	self.Health.colorSmooth = true

	self.Health.Smoother = true
	self.Health.frequentUpdates = true
	-- self.Health.SpiritHealer = self.SpiritHealer -- connect the spirithealer artwork
	self.Health.Override = gUI4:GetFunction("UpdateHealthBar")
	
	self.Power.colorPower = true
	self.Power.colorClass = false
	self.Power.colorClassNPC = false
	self.Power.colorSmooth = false
	self.Power.colorReaction = true
	self.Power.colorDisconnected = true
	self.Power.colorTapping = true
	self.Power.displayAltPower = true
	self.Power.Smoother = true
	self.Power.frequentUpdates = true
	self.Power.Override = gUI4:GetFunction("UpdatePowerBar")
	
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

	-- power spark
	self.Power.Spark = LMP:NewChain(self.Power:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
	
	-- castbar
	self.Castbar = LMP:NewChain("StatusBar", nil, self) :SetFrameLevel(self:GetFrameLevel() + 3) .__EndChain
	self.Castbar.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) .__EndChain
	self.Castbar.BackdropFrame = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetAllPoints(self.Castbar.OverlayFrame) .__EndChain
	self.Castbar.Glow = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Castbar.Border = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Castbar.Highlight = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 2) .__EndChain
	self.Castbar.Overlay = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain
	-- self.Castbar.SafeZone = LMP:NewChain(self.Castbar:CreateTexture()) :SetDrawLayer("OVERLAY") :SetAllPoints(self.Castbar) :SetAlpha(1/4) .__EndChain
	self.Castbar.Icon = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) :SetTexCoord(5/64, 59/64, 5/64, 59/64) .__EndChain
	self.Castbar.Icon.Glow = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Castbar.Icon.Border = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Castbar.Icon.Overlay = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain

	-- portrait
	self.Portrait = LMP:NewChain(CreateFrame("PlayerModel", nil, self)) :SetAlpha(1) .__EndChain
	self.Portrait.PostUpdate = gUI4:GetFunction("PostUpdatePortrait")
	self.Portrait.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints(self.Portrait) .__EndChain
	tinsert(self.__elements, gUI4:GetFunction("HidePortrait"))

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
	self.Buffs = CreateFrame("Frame", nil, self)
	self.Buffs.GetSettings = function() return module.db.profile.auras end
	self.Buffs.PostUpdateIcon = gUI4:GetFunction("PostUpdateAuraIcon")
	self.Buffs.PostCreateIcon = gUI4:GetFunction("PostCreateAuraIcon")
	self.Buffs.CustomFilter = ns.CustomAuraFilter
	self.Buffs.disableCooldown = true
	self.Buffs:HookScript("OnHide", function(self)
		-- visibleBuffs visibleAuras visibleDebuffs createdIcons
		if not self.visibleBuffs then return end
		for i = 1, self.visibleBuffs do
			local button = type(self[i]) == "table" and self[i]
			if button then
				
			end
		end
		for i = self.visibleBuffs, self.createdIcons do
			local button = type(self[i]) == "table" and self[i]
			if button and button.StopFlash then
				button:StopFlash()
				button:StopAllFades()
				button:RawHide()
				button:SetAlpha(0)
			end
		end
	end)
	self.Buffs:HookScript("OnShow", function(self)
		if not self.visibleBuffs then return end
		for i = 1, self.visibleBuffs do
			local button = type(self[i]) == "table" and self[i]
			if button then
				
			end
		end
		for i = self.visibleBuffs, self.createdIcons do
			local button = type(self[i]) == "table" and self[i]
			if button and button.StopFlash  then
				button:StopFlash()
				button:StopAllFades()
				button:RawHide()
				button:SetAlpha(0)
			end
		end
	end)
	
	self.Debuffs = CreateFrame("Frame", nil, self)
	self.Debuffs.GetSettings = function() return module.db.profile.auras end
	self.Debuffs.PostUpdateIcon = gUI4:GetFunction("PostUpdateAuraIcon")
	self.Debuffs.PostCreateIcon = gUI4:GetFunction("PostCreateAuraIcon")
	self.Debuffs.CustomFilter = ns.CustomAuraFilter
	self.Debuffs.disableCooldown = false
	self.Debuffs:HookScript("OnHide", function(self)
		-- visibleBuffs visibleAuras visibleDebuffs createdIcons
		if not self.visibleDebuffs then return end
		for i = 1, self.visibleDebuffs do
			local button = type(self[i]) == "table" and self[i]
			if button then
				
			end
		end
		for i = self.visibleDebuffs, self.createdIcons do
			local button = type(self[i]) == "table" and self[i]
			if button and button.StopFlash then
				button:StopFlash()
				button:StopAllFades()
				button:RawHide()
				button:SetAlpha(0)
			end
		end
	end)
	self.Debuffs:HookScript("OnShow", function(self)
		if not self.visibleDebuffs then return end
		for i = 1, self.visibleDebuffs do
			local button = type(self[i]) == "table" and self[i]
			if button then
				
			end
		end
		for i = self.visibleDebuffs, self.createdIcons do
			local button = type(self[i]) == "table" and self[i]
			if button and button.StopFlash then
				button:StopFlash()
				button:StopAllFades()
				button:RawHide()
				button:SetAlpha(0)
			end
		end
	end)
	local previousTarget
	self:RegisterEvent("PLAYER_TARGET_CHANGED", function(self)
		-- hidden frames functions properly when shown, 
		-- so we need to focus on frames that were visible when 
		-- the target change occured
		if not self:IsVisible() then 
			previousTarget = nil
			return 
		end
		local name, realm = UnitName("target")
		if not(name) then 
			return 
		else
			previousTarget = name
		end
		local Buffs = self.Buffs
		if Buffs.createdIcons then
			for i = 1, Buffs.createdIcons do
				local button = type(Buffs[i]) == "table" and Buffs[i]
				if button and button.StopFlash then
					button:StopFlash()
					button:StopAllFades()
					button:RawHide()
					button:SetAlpha(0)
				end
			end
			self.Buffs:ForceUpdate()
		end
		local Debuffs = self.Debuffs
		if Debuffs.createdIcons then
			for i = 1, Debuffs.createdIcons do
				local button = type(Debuffs[i]) == "table" and Debuffs[i]
				if button and button.StopFlash then
					button:StopFlash()
					button:StopAllFades()
					button:RawHide()
					button:SetAlpha(0)
				end
			end
			self.Debuffs:ForceUpdate()
		end
	end)
	
	-- fontstrings
	self.CombatFeedbackText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(NumberFontNormalHuge) .__EndChain
	self.HealthText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(TextStatusBarText) .__EndChain
	self.NameText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(GameFontNormalSmall) :SetWordWrap(false) :SetNonSpaceWrap(false) .__EndChain
	self.PowerText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(TextStatusBarText) .__EndChain
	self.LeaderText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(GameFontNormal) .__EndChain
	self.LootText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(GameFontNormal) .__EndChain
	self.Castbar.Time = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(TextStatusBarText) .__EndChain
	self.Castbar.CustomTimeText = function(self, duration)
		if self.casting then
			self.Time:SetFormattedText("%.1f", self.max - duration)
		elseif self.channeling then
			self.Time:SetFormattedText("%.1f", duration)
		end
	end
	
	-- widgets
	self.Leader = LMP:NewChain(self.IconFrame:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.Assistant = LMP:NewChain(self.IconFrame:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.MasterLooter = LMP:NewChain(self.IconFrame:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
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
	self.Power.frame = self
	self.PowerText.frame = self
	self.LeaderText.frame = self
	self.LootText.frame = self
	
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Target", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
end

function module:OnEnable()
	if not self.loaded then
		self:AddUnit("target", scaffolding, self.db.profile)
		self.loaded = true
	end
end
