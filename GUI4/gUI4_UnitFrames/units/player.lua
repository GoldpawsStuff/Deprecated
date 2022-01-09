local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local parent = gUI4:GetModule("gUI4_UnitFrames", true)
if not parent then return end

local module = parent:NewModule("Player", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

-- Lua API
local unpack = unpack 

local playerClass = select(2, UnitClass("player"))

local defaults = {
	profile = {
		locked = true,
		auras = {
			-- visibility
			-- showAuras = true,
			showBuffs = true, -- display buffs
			showDebuffs = true, -- display debuffs
			onlyInCombat = true, -- display all auras when not engaged in combat, ignoring all filters
			-- always show
			alwaysShowBossDebuffs = true, -- always show boss debuffs. overrides other choices
			alwaysShowStealable = false, -- always display stealable buffs. overrides other choices
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
	showAuras = true,
	-- showBuffs = true,
	-- showDebuffs = true,
	-- alwaysShowStealable = true
}

local function scaffolding(self, unit)

	-- Just for testing purposes, comment out when done
	-- I needed this to test my new GroupAuras plugin without being in a group
	--[[ 
	self.GroupAuras = CreateFrame("Frame", nil, self)
	self.GroupAuras:SetFrameLevel(self:GetFrameLevel() + 50)
	self.GroupAuras:Hide()
	self.GroupAuras:SetSize(32, 32)
	self.GroupAuras:SetPoint("CENTER", 0, 0)
	self.GroupAuras:SetBackdrop({
		bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		edgeSize = 1,
		insets = { 
			left = -1, 
			right = -1, 
			top = -1, 
			bottom = -1
		}
	})
	self.GroupAuras:SetBackdropColor(0, 0, 0, 1)
	self.GroupAuras:SetBackdropBorderColor(.3, .3, .3, 1) -- just initial, will be debuff colored anyway
	
	self.GroupAuras.icon = self.GroupAuras:CreateTexture(nil, "OVERLAY")
	self.GroupAuras.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	self.GroupAuras.icon:SetPoint("TOP", self.GroupAuras, 0, -3)
	self.GroupAuras.icon:SetPoint("RIGHT", self.GroupAuras, -3, 0)
	self.GroupAuras.icon:SetPoint("BOTTOM", self.GroupAuras, 0, 3)
	self.GroupAuras.icon:SetPoint("LEFT", self.GroupAuras, 3, 0)
	self.GroupAuras.icon:SetDrawLayer("ARTWORK")
	
	self.GroupAuras.cd = CreateFrame("Cooldown", nil, self.GroupAuras)
	self.GroupAuras.cd:SetAllPoints(self.GroupAuras.icon)
	self.GroupAuras.cd:SetReverse(true)
	
	self.GroupAuras.count = self.GroupAuras:CreateFontString(nil, "OVERLAY")
	self.GroupAuras.count:SetFontObject(TextStatusBarText)
	self.GroupAuras.count:SetPoint("BOTTOMRIGHT", self.GroupAuras, "BOTTOMRIGHT", 2, 0)
	self.GroupAuras.count:SetTextColor(.79, .79, .79)
	
	self.GroupAuras.SetDebuffTypeColor = self.GroupAuras.SetBackdropBorderColor
	]]--

	-- statusbars
	self.Health = LMP:NewChain("StatusBar", nil, self) :SetFrameLevel(self:GetFrameLevel() + 1) :SetPostUpdate(ns.postUpdateHealth) .__EndChain
	
	self.Health.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints() .__EndChain
	self.Health.BackdropFrame = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetAllPoints(self.Health.OverlayFrame) .__EndChain
	self.Health.Glow = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain -- "BACKGROUND", -7
	self.Health.Border = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Health.Highlight = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 2) .__EndChain
	self.Health.Overlay = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain

	self.Power = LMP:NewChain("StatusBar", nil, self) :SetFrameLevel(self:GetFrameLevel() + 2) .__EndChain
	self.Power.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints() .__EndChain
	self.Power.BackdropFrame = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetAllPoints(self.Power.OverlayFrame) .__EndChain
	self.Power.Glow = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain -- "BACKGROUND", -7
	self.Power.Border = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Power.Highlight = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 2) .__EndChain
	-- self.Power.Overlay = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain

	-- move this to profile or theme or both?
	self.Health.colorHealth = false
	self.Health.colorClass = true
	self.Health.colorClassPet = false
	self.Health.colorPetAsPlayer = true
	self.Health.colorReaction = false
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
	self.Power.Smoother = true
	self.Power.frequentUpdates = true
	self.Power.Override = gUI4:GetFunction("UpdatePowerBar")
	
	-- low health pulse
	if LEGION then 
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
	self.Castbar.SafeZone = LMP:NewChain(self.Castbar:CreateTexture()) :SetDrawLayer("OVERLAY") :SetAllPoints(self.Castbar) :SetAlpha(1/4) .__EndChain
	self.Castbar.Icon = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) :SetTexCoord(5/64, 59/64, 5/64, 59/64) .__EndChain
	self.Castbar.Icon.Glow = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Castbar.Icon.Border = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Castbar.Icon.Overlay = LMP:NewChain(self.Castbar.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain

	-- cast spark
	self.Castbar.Spark = LMP:NewChain(self.Castbar:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
	
	-- portrait
	self.Portrait = LMP:NewChain(CreateFrame("PlayerModel", nil, self)) :SetAlpha(1) .__EndChain
	self.Portrait.PostUpdate = gUI4:GetFunction("PostUpdatePortrait")
	self.Portrait.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints(self.Portrait) .__EndChain
	-- self.Portrait.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) .__EndChain
	self.Portrait.BackdropFrame = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetAllPoints(self.Portrait.OverlayFrame) .__EndChain
	self.Portrait.Glow = LMP:NewChain(self.Portrait.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Portrait.Border = LMP:NewChain(self.Portrait.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
	self.Portrait.Highlight = LMP:NewChain(self.Portrait.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 2) .__EndChain
	self.Portrait.Overlay = LMP:NewChain(self.Portrait.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("ARTWORK", 3) .__EndChain
	tinsert(self.__elements, gUI4:GetFunction("HidePortrait"))
	
	-- threat
	self.Health.Threat = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 4) :SetAllPoints() :Hide() .__EndChain
	self.Power.Threat = LMP:NewChain(self.Power.BackdropFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -6) :SetAllPoints() :Hide() .__EndChain
	-- self.Health.Threat = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 3) :SetAllPoints() :Hide() .__EndChain
	-- self.Power.Threat = LMP:NewChain(self.Power.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 3) :SetAllPoints() :Hide() .__EndChain
	self.Threat = {
		Hide = function() 
			self.Health.Threat:Hide()
			self.Power.Threat:Hide()
		end,
		Show = function() 
			if self.Health.Threat.enabled then
				self.Health.Threat:Show()
			end
			if self.Power.Threat.enabled then
				self.Power.Threat:Show()
			end
		end,
		SetVertexColor = function(frame, ...) 
			self.Health.Threat:SetVertexColor(...)
			self.Power.Threat:SetVertexColor(...)
		end,
		IsObjectType = function()
		end
	}
	
	-- auras
	self.Buffs = CreateFrame("Frame", nil, self)
	self.Buffs:SetSize(64,64)
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
	self.Debuffs:SetSize(64,64)
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
			if button and button.StopFlash  then
				button:StopFlash()
				button:StopAllFades()
				button:RawHide()
				button:SetAlpha(0)
			end
		end
	end)
	local updateBuffs = function(self)
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
	end
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", updateBuffs)
	self:RegisterEvent("UNIT_EXITED_VEHICLE", updateBuffs)
	
	-- self.Buffs:SetBackdrop({
		-- bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		-- edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		-- edgeSize = 1,
		-- insets = { 
			-- left = -1, 
			-- right = -1, 
			-- top = -1, 
			-- bottom = -1
		-- }
	-- })
	-- self.Buffs:SetBackdropBorderColor(0, 0, 0, 1)
	-- self.Buffs:SetBackdropColor(0, 0, 0, .5)
	
	-- self.Debuffs:SetBackdrop({
		-- bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		-- edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		-- edgeSize = 1,
		-- insets = { 
			-- left = -1, 
			-- right = -1, 
			-- top = -1, 
			-- bottom = -1
		-- }
	-- })
	-- self.Debuffs:SetBackdropBorderColor(0, 0, 0, 1)
	-- self.Debuffs:SetBackdropColor(0, 0, 0, .5)
	
	-- fontstrings
	self.CombatFeedbackText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(NumberFontNormalHuge) .__EndChain
	self.HealthText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(TextStatusBarText) .__EndChain
	self.NameText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(GameFontNormalSmall) :SetWordWrap(false) :SetNonSpaceWrap(false) .__EndChain
	-- self.NameText.frequentUpdates = .05 -- for the PvP timer
	self.PowerText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(TextStatusBarText) .__EndChain
	if playerClass == "DRUID" then
		self.DruidManaText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(TextStatusBarText) .__EndChain
		self.DruidManaText.frame = self
	end
	self.LeaderText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(GameFontNormal) .__EndChain
	self.LootText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(GameFontNormal) .__EndChain
	self.Castbar.SafeZone.Delay = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(GameFontNormalSmall) :SetTextColor(0.5, 0.5, 0.5, 1) .__EndChain
	self.Castbar.Time = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(TextStatusBarText) .__EndChain
	local MILLISECONDS_ABBR = MILLISECONDS_ABBR
	local GetNetStats = GetNetStats
	self.Castbar.CustomTimeText = function(self, duration)
		if self.SafeZone then
			self.SafeZone.Delay:SetFormattedText("|r|cFF888888%d" .. MILLISECONDS_ABBR .. "|r", (select(4, GetNetStats())))
		end
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
	self.Combat = LMP:NewChain(self.IconFrame:CreateTexture(nil, "OVERLAY"))  .__EndChain -- :Hide() :SetAlpha(0)
	self.Resting = LMP:NewChain(self.IconFrame:CreateTexture(nil, "OVERLAY")) .__EndChain -- :Hide() :SetAlpha(0)
	self.RaidIcon = LMP:NewChain(self.IconFrame:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.UnitRange = { insideAlpha = 1, outsideAlpha = .75 }
	-- self.PvPTimer = LMP:NewChain(CreateFrame("Frame", nil, self.InfoFrame)) .__EndChain
	-- self.PvPTimer.Icon = LMP:NewChain("FontString", nil, self.PvPTimer) :SetDrawLayer("ARTWORK") :SetFontObject(GameFontNormalLarge) .__EndChain
	-- self.PvPTimer.Time = LMP:NewChain("FontString", nil, self.PvPTimer) :SetDrawLayer("ARTWORK") :SetFontObject(TextStatusBarText) .__EndChain
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
	self.CastbarDelayText = self.Castbar.SafeZone.Delay
	self.CastbarDelayText.frame = self
	self.CombatFeedbackText.frame = self
	self.Health.frame = self
	self.HealthText.frame = self
	self.NameText.frame = self
	self.Power.frame = self
	self.PowerText.frame = self
	self.LeaderText.frame = self
	self.LootText.frame = self
	-- self.PvPTimer.frame = self
	-- self.PvPTimer.Icon.frame = self
	-- self.PvPTimer.Time.frame = self
	
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Player", defaults)
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
		-- gUI4:DisableUnitFrame("player")
		self:AddUnit("player", scaffolding, self.db.profile)
		self.loaded = true
	end
end
