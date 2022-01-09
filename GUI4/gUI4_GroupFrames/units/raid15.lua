local addon,ns = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local parent = gUI4:GetModule(addon, true)
if not parent then return end

local module = parent:NewModule("Raid15", "GP_AceEvent-3.0")
-- local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme

-- Lua API
local tonumber = tonumber
local pairs, unpack = pairs, unpack
local wipe = table.wipe

-- WoW API
local CreateFrame = _G.CreateFrame
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitFrame_OnEnter = _G.UnitFrame_OnLeave
local UnitFrame_OnLeave = _G.UnitFrame_OnLeave
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitIsUnit = _G.UnitIsUnit

-- WoW objects
local GameFontNormalSmall = _G.GameFontNormalSmall
local NumberFontNormalHuge = _G.NumberFontNormalHuge
local TextStatusBarText = _G.TextStatusBarText
local UIParent = _G.UIParent

-- WoW strings
local COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE15PLAYERS = _G.COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE15PLAYERS 

local mirror = {
	BOTTOM = "TOP",
	BOTTOMLEFT = "TOPRIGHT",
	BOTTOMRIGHT = "TOPLEFT",
	CENTER = "CENTER",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	TOP = "BOTTOM",
	TOPLEFT = "BOTTOMRIGHT",
	TOPRIGHT = "BOTTOMLEFT"
}

local defaults = {
	profile = {
		skin = "Warcraft",
		locked = true,
		enabled = true,
		position = {}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().Raid15
end

-------------------------------------------------------------------------------
--	Style/Theme Updates
-------------------------------------------------------------------------------
local function UpdateTexture(tex, db)
	if db then
		tex:SetTexture(db:GetPath())
		tex:SetSize(db:GetTexSize())
		tex:SetVertexColor(unpack(db:GetColor()))
		tex:SetAlpha(db:GetAlpha())
		tex:SetTexCoord(db:GetTexCoord())
		tex:ClearAllPoints()
		tex:SetPoint(db:GetPoint())
	else
		tex:SetSize(.001, .001)
		tex:SetAlpha(0)
		tex:SetTexture("")
		tex:Hide()
	end
end

local function UpdateBar(bar, db)
	if db.alpha then
		bar:SetAlpha(db.alpha)
	else
		bar:SetAlpha(1)
	end
	if db.sparkle then
		if bar.Sparkle then
			bar.Sparkle:Show()
			bar.Sparkle:SetAlpha(tonumber(db.sparkle) or .1)
		end
	else
		if bar.Sparkle then
			bar.Sparkle:Hide()
		end
	end
	if db.size then
		bar:SetSize(unpack(db.size))
	else
		bar:SetSize(bar:GetParent():GetSize())
	end
	if db.growth then
		bar:SetGrowth(db.growth)
	else
		bar:SetGrowth("RIGHT")
	end
	if db.place then
		bar:ClearAllPoints()
		bar:SetPoint(unpack(db.place))
	else
		bar:ClearAllPoints()
		bar:SetAllPoints(bar:GetParent())
	end
	if db.bar.textures.backdrop then
		bar:SetBackdropTexture(db.bar.textures.backdrop:GetPath())
		if db.bar.backdropmultiplier then
			bar:SetBackdropMultiplier(db.bar.backdropmultiplier)
		else
			bar:SetBackdropMultiplier(nil)
		end
	else
		bar:SetBackdropTexture("")
	end
	if db.bar.textures.normal then
		bar:SetStatusBarTexture(db.bar.textures.normal:GetPath())
	else
		bar:SetStatusBarTexture("") -- weird. but might have a bar with only overlay and spark? :/
	end
	if db.bar.textures.overlay then
		bar:SetOverlayTexture(db.bar.textures.overlay:GetPath())
	else
		bar:SetOverlayTexture("")
	end
	if db.bar.textures.glow then
		bar:SetThreatTexture(db.bar.textures.glow:GetPath())
	else
		bar:SetThreatTexture("")
	end	
	if bar.Threat then
		if db.textures.threat then 
			UpdateTexture(bar.Threat, db.textures.threat)
			bar.Threat.enabled = true
		else
			bar.Threat.enabled = false
			bar.Threat:Hide()
		end
	end
	if bar.Spark then
		if db.spark then
			bar.Spark:SetSize(db.spark.texture:GetTexSize(), bar:GetHeight())
			bar.Spark:SetTexture(db.spark.texture:GetPath())
			bar.Spark:SetAlpha(db.spark.alpha)
			bar.Spark:ClearAllPoints()
			bar.Spark:SetPoint(db.spark.texture:GetPoint(), bar:GetStatusBarTexture(), db.spark.texture:GetPoint())
		else
			bar.Spark:SetTexture("")
		end
	end
end

local function UpdateFontString(fontString, db, anchor)
	if db then
		fontString:ClearAllPoints()
		if anchor then
			local point, x, y = unpack(db.place)
			fontString:SetPoint(point, anchor, point, x, y)
		else
			fontString:SetPoint(unpack(db.place))
		end
		fontString:SetHeight(db.size)
		fontString:SetFontObject(db.fontobject)
		fontString:SetFontSize(db.fontsize or db.size)
		fontString:SetFontStyle(db.fontstyle)
		fontString:SetShadowOffset(unpack(db.shadowoffset))
		fontString:SetShadowColor(unpack(db.shadowcolor))
		fontString:SetTextColor(unpack(db.color))
		if fontString.frame and fontString.frame.Tag then
			fontString.frame:Tag(fontString, db.tag or "")
		end
	else
		if fontString.frame and fontString.frame.Tag then
			fontString.frame:Tag(fontString, "")
		end
		fontString:SetText("")
	end
end


local function UpdateStyle(self)
	updateConfig()
	
	--	Frame
	-------------------------------------------------------------------------------
	UpdateTexture(self.Backdrop, T.textures.backdrop)
	UpdateTexture(self.Border, T.textures.border)
	UpdateTexture(self.Highlight, T.textures.highlight)
	UpdateTexture(self.TargetBorder.Border, T.textures.target)
	
	--	Bars
	-------------------------------------------------------------------------------
	UpdateBar(self.Health, T.bars.health)
	UpdateBar(self.Power, T.bars.power)
	
	--	Texts
	-------------------------------------------------------------------------------
	UpdateFontString(self.NameText, T.fontstrings.nametext)
	UpdateFontString(self.HealthText, T.fontstrings.healthtext)
	
	--	Widgets
	-------------------------------------------------------------------------------
	
	-- raid icon
	self.RaidIcon:SetSize(unpack(T.widgets.raidicon.size))
	self.RaidIcon:ClearAllPoints()
	self.RaidIcon:SetPoint(unpack(T.widgets.raidicon.place))
	self.RaidIcon:SetTexture(T.widgets.raidicon.texture)
	
	-- icon stack
	self.IconStackWidget:SetSize(unpack(T.widgets.iconstack.size))
	self.IconStackWidget:ClearAllPoints()
	self.IconStackWidget:SetPoint(unpack(T.widgets.iconstack.place))
	self.IconStackWidget.Leader:SetSize(unpack(T.widgets.iconstack.size))
	self.IconStackWidget.Assistant:SetSize(unpack(T.widgets.iconstack.size))
	self.IconStackWidget.MainTank:SetSize(unpack(T.widgets.iconstack.size))
	self.IconStackWidget.MainAssist:SetSize(unpack(T.widgets.iconstack.size))
	self.IconStackWidget.MasterLooter:SetSize(unpack(T.widgets.iconstack.size))
	self.IconStackWidget.showLeader = T.widgets.iconstack.showLeader
	self.IconStackWidget.showAssistant = T.widgets.iconstack.showAssistant
	self.IconStackWidget.showMainTank = T.widgets.iconstack.showMainTank
	self.IconStackWidget.showMainAssist = T.widgets.iconstack.showMainAssist
	self.IconStackWidget.showMasterLooter = T.widgets.iconstack.showMasterLooter
	if self.IconStackWidget.ForceUpdate then
		self.IconStackWidget:ForceUpdate()
	end
	
	-- group role icon
	self.GroupRole:SetSize(unpack(T.widgets.grouprole.size))
	self.GroupRole:ClearAllPoints()
	self.GroupRole:SetPoint(unpack(T.widgets.grouprole.place))
	self.GroupRole.Tank:SetSize(unpack(T.widgets.grouprole.size))
	self.GroupRole.Tank:SetTexture(T.widgets.grouprole.textures.tank:GetPath())
	self.GroupRole.Tank:SetTexCoord(T.widgets.grouprole.textures.tank:GetTexCoord())
	self.GroupRole.Tank:ClearAllPoints()
	self.GroupRole.Tank:SetPoint(T.widgets.grouprole.textures.tank:GetPoint())
	self.GroupRole.Healer:SetSize(unpack(T.widgets.grouprole.size))
	self.GroupRole.Healer:SetTexture(T.widgets.grouprole.textures.heal:GetPath())
	self.GroupRole.Healer:SetTexCoord(T.widgets.grouprole.textures.heal:GetTexCoord())
	self.GroupRole.Healer:ClearAllPoints()
	self.GroupRole.Healer:SetPoint(T.widgets.grouprole.textures.heal:GetPoint())
	self.GroupRole.DPS:SetSize(unpack(T.widgets.grouprole.size))
	self.GroupRole.DPS:SetTexture(T.widgets.grouprole.textures.dps:GetPath())
	self.GroupRole.DPS:SetTexCoord(T.widgets.grouprole.textures.dps:GetTexCoord())
	self.GroupRole.DPS:ClearAllPoints()
	self.GroupRole.DPS:SetPoint(T.widgets.grouprole.textures.dps:GetPoint())
	self.GroupRole.showTank = T.widgets.grouprole.showTank
	self.GroupRole.showHealer = T.widgets.grouprole.showHealer
	self.GroupRole.showDPS = T.widgets.grouprole.showDPS
	if self.GroupRole.ForceUpdate then
		self.GroupRole:ForceUpdate()
	end
	
	-- readycheck icon
	self.ReadyCheck:SetSize(unpack(T.widgets.readycheck.size))
	self.ReadyCheck:ClearAllPoints()
	self.ReadyCheck:SetPoint(unpack(T.widgets.readycheck.place))
	
	-- raiddebuffs
	self.GroupAuras:SetSize(unpack(T.widgets.raiddebuff.size))
	self.GroupAuras:ClearAllPoints()
	self.GroupAuras:SetPoint(unpack(T.widgets.raiddebuff.place))
	
	-- heal prediction
	local predict = self.HealPrediction
	local width = self.Health:GetWidth()
	local growth = self.Health:GetGrowth()
	if predict.myBar then
		LMP:NewChain(predict.myBar) :SetWidth(width) :SetGrowth(growth) :ClearAllPoints() :SetPoint("TOP", self.Health:GetStatusBarTexture(), "TOP") :SetPoint("BOTTOM", self.Health:GetStatusBarTexture(), "BOTTOM") :SetPoint(mirror[growth], self.Health:GetStatusBarTexture(), growth) :EndChain()
	end
	if predict.otherBar then
		LMP:NewChain(predict.otherBar) :SetWidth(width) :SetGrowth(growth) :ClearAllPoints() :SetPoint("TOP", self.Health:GetStatusBarTexture(), "TOP") :SetPoint("BOTTOM", self.Health:GetStatusBarTexture(), "BOTTOM") :SetPoint(mirror[growth], self.Health:GetStatusBarTexture(), growth) :EndChain()
	end
	if predict.absorbBar then
		LMP:NewChain(predict.absorbBar) :SetWidth(width) :SetGrowth(growth) :ClearAllPoints() :SetPoint("TOP", self.Health:GetStatusBarTexture(), "TOP") :SetPoint("BOTTOM", self.Health:GetStatusBarTexture(), "BOTTOM") :SetPoint(mirror[growth], self.Health:GetStatusBarTexture(), growth) :EndChain()
	end
	if predict.healAbsorbBar then
		LMP:NewChain(predict.healAbsorbBar) :SetWidth(width) :SetGrowth(growth) :ClearAllPoints() :SetPoint("TOP", self.Health:GetStatusBarTexture(), "TOP") :SetPoint("BOTTOM", self.Health:GetStatusBarTexture(), "BOTTOM") :SetPoint(mirror[growth], self.Health:GetStatusBarTexture(), growth) :EndChain()
	end
end

-------------------------------------------------------------------------------
--	UnitFrame Prototype
-------------------------------------------------------------------------------
local function updateTarget(self)
	local TargetBorder = self.TargetBorder
	if not TargetBorder then
		return 
	end
	if self.unit and UnitIsUnit(self.unit, "target") and self:IsShown() then
		TargetBorder:Show()
	else
		TargetBorder:Hide()
	end
end

local function showHighlight(self)
	local highlight = self.Highlight
	local border = self.Border
	if highlight then
		highlight:Show()
		if border then
			border:Hide()
		end
	end
end

local function hideHighlight(self)
	local highlight = self.Highlight
	local border = self.Border
	if highlight then
		if border then
			border:Show()
		end
		highlight:Hide()
	end
end

local function onEnter(self)
	showHighlight(self)
	UnitFrame_OnEnter(self)
end

local function onLeave(self)
	hideHighlight(self)
	UnitFrame_OnLeave(self)
end

local allFrames = {}
local function Style(self, unit)
	allFrames[self] = true
	
	self.colors = gUI4:GetColors()
	
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", onEnter)
	self:SetScript("OnLeave", onLeave)
	
	self.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetFrameLevel(self:GetFrameLevel() + 10) :SetAllPoints() .__EndChain
	self.InfoFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints() .__EndChain
	self.IconFrame = LMP:NewChain(CreateFrame("Frame", nil, self.InfoFrame)) :SetAllPoints() .__EndChain
	self.PrioFrame = LMP:NewChain(CreateFrame("Frame", nil, self.IconFrame)) :SetAllPoints() .__EndChain
	
	-- target border
	self.TargetBorder = LMP:NewChain(CreateFrame("Frame", nil, ((unit == "party") or (unit == "raid")) and self:GetParent() or self)) :SetFrameLevel(self:GetFrameLevel() + 10) :SetPoint("TOPLEFT", self, 0, 0) :SetPoint("BOTTOMRIGHT", 0, 0) :Hide() .__EndChain
	self.TargetBorder.parent = self
	self.TargetBorder:RegisterEvent("PLAYER_TARGET_CHANGED")
	self.TargetBorder:RegisterEvent("GROUP_ROSTER_UPDATE")
	self.TargetBorder:RegisterEvent("PLAYER_REGEN_DISABLED")
	self.TargetBorder:SetScript("OnEvent", function(self, event, ...) updateTarget(self.parent, event, ...) end) 
	self.TargetBorder.Border = LMP:NewChain(self.TargetBorder:CreateTexture()) :SetDrawLayer("BORDER", 3) :SetAllPoints(self.TargetBorder) .__EndChain
	
	self.Glow = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Backdrop = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("BACKGROUND", -1) :SetAllPoints() .__EndChain
	self.Shade = LMP:NewChain(self.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", 1) :SetAllPoints() .__EndChain
	self.Border = LMP:NewChain(self.OverlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 0) :SetAllPoints() .__EndChain
	self.Highlight = LMP:NewChain(self.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 1) :SetBlendMode("BLEND") :SetAllPoints() .__EndChain
	self.Overlay = LMP:NewChain(self.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 2) :SetAllPoints() .__EndChain
	self.SpiritHealer = LMP:NewChain(self.IconFrame:CreateTexture()) :Hide() :SetDrawLayer("OVERLAY", 7) :SetAlpha(.5) :SetAllPoints() .__EndChain
	
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
	
	-- threat
	self.Health.Threat = LMP:NewChain(self.Health.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", 4) :SetAllPoints() :Hide() .__EndChain
	self.Power.Threat = LMP:NewChain(self.Power.BackdropFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", -6) :SetAllPoints() :Hide() .__EndChain
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
	
	-- fontstrings
	self.CombatFeedbackText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(NumberFontNormalHuge) .__EndChain
	self.HealthText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(TextStatusBarText) .__EndChain
	self.NameText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("ARTWORK") :SetFontObject(GameFontNormalSmall) :SetWordWrap(false) :SetNonSpaceWrap(false) .__EndChain
	self.PowerText = LMP:NewChain("FontString", nil, self.InfoFrame) :SetDrawLayer("OVERLAY") :SetFontObject(TextStatusBarText) .__EndChain
	
	-- widgets
	-- *note: fonstring textures doesn't respond well to fading, so we're using "real" textures for all that
	self.ReadyCheck = LMP:NewChain(self.OverlayFrame:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.IconStackWidget = LMP:NewChain(CreateFrame("Frame", nil, self.IconFrame)) :SetPoint("TOPLEFT", 2, 8) :SetSize(16, 16) .__EndChain
	self.IconStackWidget.Leader = LMP:NewChain(self.IconStackWidget:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.IconStackWidget.Assistant = LMP:NewChain(self.IconStackWidget:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.IconStackWidget.MainTank = LMP:NewChain(self.IconStackWidget:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.IconStackWidget.MainAssist = LMP:NewChain(self.IconStackWidget:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.IconStackWidget.MasterLooter = LMP:NewChain(self.IconStackWidget:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.GroupRole = LMP:NewChain(CreateFrame("Frame", nil, self.IconFrame)) :SetPoint("BOTTOM", 0, 0) :SetSize(16, 16) .__EndChain
	self.GroupRole.Tank = LMP:NewChain(self.GroupRole:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.GroupRole.Healer = LMP:NewChain(self.GroupRole:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.GroupRole.DPS = LMP:NewChain(self.GroupRole:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.RaidIcon = LMP:NewChain(self.IconFrame:CreateTexture()) :SetDrawLayer("OVERLAY") .__EndChain
	self.UnitRange = { insideAlpha = 1, outsideAlpha = .5 }
	self.HealPrediction = { 
		myBar = LMP:NewChain("StatusBar", nil, self) :SetStatusBarTexture(1, 1, 1, .3) :SetStatusBarColor(unpack(self.colors.healpredict.predict)) .__EndChain,
		otherBar = LMP:NewChain("StatusBar", nil, self) :SetStatusBarTexture(1, 1, 1, .3) :SetStatusBarColor(unpack(self.colors.healpredict.predictOther)) .__EndChain,
		absorbBar = LMP:NewChain("StatusBar", nil, self) :SetStatusBarTexture(1, 1, 1, .3) :SetStatusBarColor(unpack(self.colors.healpredict.absorb)) .__EndChain,
		healAbsorbBar = LMP:NewChain("StatusBar", nil, self) :SetStatusBarTexture(1, 1, 1, .3) :SetStatusBarColor(unpack(self.colors.healpredict.absorbOther)) .__EndChain,
		maxOverflow = 1, 
		frequentUpdates = true 
	}
	
	--		Raid Debuffs
	--------------------------------------------------------------------------------------------------
	self.GroupAuras = CreateFrame("Frame", nil, self.PrioFrame)
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
	
	self.GroupAuras.PostUpdate = function(self)
		local button = self.GroupAuras
		-- we don't want those "1"'s cluttering up the display
		if button then
			local count = tonumber(button.count:GetText())
			if count and count > 1 then
				f.count:SetText(count)
				f.count:Show()
			else
				f.count:Hide()
			end
		end
	end 
	
	-- frame references 
	self.CombatFeedbackText.frame = self
	self.Health.frame = self
	self.HealthText.frame = self
	self.NameText.frame = self
	self.Power.frame = self
	self.PowerText.frame = self
	
	-- just for development
	--local backdrop = self:CreateTexture(nil, "BACKGROUND")
	--backdrop:SetAllPoints(self)
	--backdrop:SetTexture(0,0,0,.75)
	
	-- if a theme has been set, style the frame now
	if hasTheme then
		UpdateStyle(self)
	end
	
end

--local positionCallbacks = {}
function module:UpdateTheme()
	updateConfig()
	-- if no theme has been set, spawn the frame headers
	if not hasTheme then
		self:SpawnFrames()
	end
	-- update the theme of all existing frames
	for frame in pairs(allFrames) do
		UpdateStyle(frame)
	end
	hasTheme = true
end

function module:ApplySettings()
	updateConfig()
	for frame in pairs(allFrames) do
		if parent.db.profile.showGroupAuras then
			frame:EnableElement("GroupAuras")
		else
			frame:DisableElement("GroupAuras")
		end
	end
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	updateConfig()
	local db = self.db.profile
	if db.locked then
		LMP:Place(self.frame, T.place)
		if not db.position.x then
			self.frame:RegisterConfig(db.position)
			self.frame:SavePosition()
		end
	else
		self.frame:RegisterConfig(db.position)
		if db.position.x then
			self.frame:LoadPosition()
		else
			LMP:Place(self.frame, T.place)
			self.frame:SavePosition()
			self.frame:LoadPosition()
		end
	end	
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:Lock()
	self.overlay:StartFadeOut()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	self.overlay:SetAlpha(0)
	self.overlay:Show()
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	local db = self.db.profile
	db.position.point = nil
	db.position.y = nil
	db.position.x = nil
	db.locked = true
	wipe(db.position)
	self:ApplySettings()
end

function module:SpawnFrames()
	oUF:RegisterStyle(addon.."Raid15", Style)
	oUF:SetActiveStyle(addon.."Raid15")
	local T = T
	local db = T.header
	local header = oUF:SpawnHeader(addon.."Raid15", nil, 
	db.showSolo and "solo" or parent:GetVisibilityMacro(6,15), 
	"oUF-initialConfigFunction", ([[
	self:SetWidth(%d)
	self:SetHeight(%d)
	]]):format(unpack(T.size)), 
	"showRaid", true,
	"showParty", true, 
	"showPlayer", true,	
	"showSolo", db.showSolo, 
	"yOffset", -(db.yOffset or 6), 
	"xoffset", 6, 
	"point", db.point, 
	"groupFilter", db.groupFilter, 
	"groupingOrder", db.groupingOrder, 
	"groupBy", db.groupBy, 
	"maxColumns", db.maxColumns, 
	"unitsPerColumn", db.unitsPerColumn, 
	"columnSpacing", db.columnSpacing or 6, 
	"columnAnchorPoint", db.columnAnchorPoint
	)
	header:ClearAllPoints()
	header:SetPoint("TOPLEFT", module.frame, 0, 0)
	self.fadeManager:RegisterObject(header)
	self.frame:SetSize(T.size[1]*db.unitsPerColumn + (db.columnSpacing or 6)*(db.unitsPerColumn-1), 
	T.size[2]*db.maxColumns + (db.yOffset or 6)*(db.maxColumns-1) )

	self:RegisterMessage("GUI4_LEADERTOOLS_SHOWN", "UpdateForcedState")
	self:RegisterMessage("GUI4_LEADERTOOLS_HIDDEN", "UpdateForcedState")
end

function module:UpdateForcedState(event)
	if event == "GUI4_LEADERTOOLS_SHOWN" then
		self.fadeManager:SetUserForced(true)
	elseif event == "GUI4_LEADERTOOLS_HIDDEN" then
		self.fadeManager:SetUserForced(false)
	end
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Raid15", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	updateConfig()
	
	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame.UpdatePosition = function() self:UpdatePosition() end
	self.fadeManager = LMP:NewChain(gUI4:CreateFadeManager("UnitFrames: Raid15")) :SetFrameStrata("LOW") :SetFrameLevel(100) :Enable() .__EndChain
	self.overlay = gUI4:GlockThis(self.frame, COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATE15PLAYERS, function() return module.db.profile end, unpack(gUI4:GetColors("glock", "unitframes"))) 
	
end

function module:OnEnable()
	
end

function module:OnDisable()
end