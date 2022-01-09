--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...
local oUF = ns.oUF or oUF 

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local unitframes = gUI:GetModule("Unitframes")
local module = unitframes:NewModule("Target")
local style = addon .. "_Target"

local L, C, F, M, db, unitDB
local Style
local _STATE

local settings = {
	size = { 210, 68 };
	healthbarsize = 9;
	powerbarsize = 9;
	iconsize = 16;
	aura = {
		size = 27;
		gap = 0;
		height = 3;
		width = 8;
	};
}

local playerClass = select(2, UnitClass("player"))

local defaults = {
	pos = { "BOTTOMLEFT", "UIParent", "BOTTOM", 78, 86 };
}

Style = function(self, unit)
	F.AllFrames(self, unit)

	self:SetSize(unpack(settings.size))

	--------------------------------------------------------------------------------------------------
	--		Power
	--------------------------------------------------------------------------------------------------
	local Power = F.ReverseBar(self)
	
	Power:SetHeight(settings.powerbarsize)
	Power:SetPoint("BOTTOM", 0, 0)
	Power:SetPoint("LEFT", 0, 0)
	Power:SetPoint("RIGHT", 0, 0)
	Power:SetStatusBarTexture(gUI:GetStatusBarTexture())
	Power:SetFrameLevel(15)

	gUI:SetUITemplate(Power, "gloss")
	-- gUI:SetUITemplate(Power, "shade")
	
	local PowerTopLine = Power:CreateTexture(nil, "OVERLAY")
	PowerTopLine:SetPoint("LEFT", Power)
	PowerTopLine:SetPoint("RIGHT", Power)
	PowerTopLine:SetPoint("BOTTOM", Power, "TOP")
	PowerTopLine:SetHeight(1)
	PowerTopLine:SetTexture(unpack(C["background"]))

	local PowerBackground = Power:CreateTexture(nil, "BACKGROUND")
	PowerBackground:SetAllPoints(Power)
	PowerBackground:SetTexture(gUI:GetStatusBarTexture())

	local powerValue = self.InfoFrame:CreateFontString()
	powerValue:SetShown(unitDB.showPower)
	powerValue:SetFontObject(gUI_UnitFrameFont14)
	powerValue:SetPoint("TOPLEFT", Power, 2, 0)
	powerValue:SetJustifyH("LEFT")
	powerValue.frequentUpdates = 1/4
	self:Tag(powerValue, "[gUI™ power]")

	self.powerValue = powerValue

	Power.frequentUpdates = 1/4
	Power.colorTapping = true
	Power.colorDisconnected = true
	Power.colorPower = true
	Power.Smooth = true

	PowerBackground.multiplier = 1/3

	self.Power = Power
	self.Power.bg = PowerBackground
	
	--------------------------------------------------------------------------------------------------
	--		Health
	--------------------------------------------------------------------------------------------------
	local Health = F.ReverseBar(self)
	Health:SetHeight(settings.healthbarsize)
	Health:SetPoint("BOTTOM", self.Power, "TOP", 0, 1)
	Health:SetPoint("LEFT", 0, 0)
	Health:SetPoint("RIGHT", 0, 0)
	Health:SetStatusBarTexture(gUI:GetStatusBarTexture())

	gUI:SetUITemplate(Health, "gloss")
	-- gUI:SetUITemplate(Health, "shade")

	local HealthTopLine = Health:CreateTexture(nil, "OVERLAY")
	HealthTopLine:SetPoint("LEFT", Health)
	HealthTopLine:SetPoint("RIGHT", Health)
	HealthTopLine:SetPoint("BOTTOM", Health, "TOP")
	HealthTopLine:SetHeight(1)
	HealthTopLine:SetTexture(unpack(C["background"]))

	local HealthBackground = Health:CreateTexture(nil, "BACKGROUND")
	HealthBackground:SetAllPoints(Health)
	HealthBackground:SetTexture(gUI:GetStatusBarTexture())

	Health.frequentUpdates = 1/4
	Health.colorTapping = true
	Health.colorDisconnected = true
	Health.colorClass = true
	Health.colorSmooth = true
	Health.Smooth = true

	HealthBackground.multiplier = 1/3

	self.Health = Health
	self.Health.bg = HealthBackground

	--------------------------------------------------------------------------------------------------
	--		Friendship
	--------------------------------------------------------------------------------------------------
	local Friendship = F.ReverseBar(self, true)
	Friendship:SetStatusBarTexture(gUI:GetStatusBarTexture())
	Friendship:SetStatusBarColor(0, 0.6, 0)
	Friendship:SetFrameLevel(self.Power:GetFrameLevel())
	Friendship:SetHeight(settings.powerbarsize)
	Friendship:SetPoint("LEFT", self, "LEFT", 0, 0)
	Friendship:SetPoint("RIGHT", self, "RIGHT", 0, 0)
	Friendship:SetPoint("BOTTOM", self, "BOTTOM", 0, (settings.powerbarsize + 1)*2)

	gUI:SetUITemplate(Friendship, "gloss")
	-- gUI:SetUITemplate(Friendship, "shade")
	
	local FriendshipTopLine = Friendship:CreateTexture(nil, "OVERLAY")
	FriendshipTopLine:SetPoint("LEFT", Friendship)
	FriendshipTopLine:SetPoint("RIGHT", Friendship)
	FriendshipTopLine:SetPoint("BOTTOM", Friendship, "TOP")
	FriendshipTopLine:SetHeight(1)
	FriendshipTopLine:SetTexture(unpack(C["background"]))

	local FriendshipBackground = Friendship:CreateTexture(nil, "BACKGROUND")
	FriendshipBackground:SetAllPoints(Friendship)
	FriendshipBackground:SetTexture(gUI:GetStatusBarTexture())
	FriendshipBackground:SetVertexColor(0, 0.2, 0, 1)

	self.FriendshipBar = Friendship
	self.FriendshipBar.bg = FriendshipBackground

	--------------------------------------------------------------------------------------------------
	--		Portrait
	--------------------------------------------------------------------------------------------------
	local Portrait = CreateFrame("PlayerModel", nil, self)
	Portrait:SetPoint("TOP", 0, 0)
	Portrait:SetPoint("LEFT", 0, 0)
	Portrait:SetPoint("RIGHT", 0, 0)
	Portrait:SetPoint("BOTTOM", self.Health, "TOP", 0, 1)
	Portrait:SetAlpha(1)

	Portrait.Shade = Portrait:CreateTexture(nil, "OVERLAY")
	Portrait.Shade:SetTexture(0, 0, 0, 3/4)
	Portrait.Shade:SetPoint("TOPLEFT", -1, 1)
	Portrait.Shade:SetPoint("BOTTOMRIGHT", 1, -1)

	-- Portrait.Overlay = Portrait:CreateTexture(nil, "OVERLAY")
	-- Portrait.Overlay:SetTexture(M("Background", "gUI™ UnitShader"))
	-- Portrait.Overlay:SetVertexColor(0, 0, 0, 1)
	-- Portrait.Overlay:SetAllPoints(Portrait.Shade)
	
	self.Portrait = Portrait
	self.Portrait.PostUpdate = F.PostUpdatePortrait		

	tinsert(self.__elements, F.HidePortrait)
	
	--------------------------------------------------------------------------------------------------
	--		Heal Prediction
	--------------------------------------------------------------------------------------------------
	local myBar = F.ReverseBar(self.Health)
	myBar:SetPoint("TOPRIGHT", self.Health:GetStatusBarTexture(), "TOPLEFT", 0, 0)
	myBar:SetPoint("BOTTOMRIGHT", self.Health:GetStatusBarTexture(), "BOTTOMLEFT", 0, 0)
	myBar:SetWidth(self:GetWidth())
	myBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	myBar:SetStatusBarColor(0, 1, 0.5, 0.25)

	local otherBar = F.ReverseBar(self.Health)
	otherBar:SetPoint("TOPRIGHT", myBar:GetStatusBarTexture(), "TOPLEFT", 0, 0)
	otherBar:SetPoint("BOTTOMRIGHT", myBar:GetStatusBarTexture(), "BOTTOMLEFT", 0, 0)
	otherBar:SetWidth(self:GetWidth())
	otherBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	otherBar:SetStatusBarColor(0, 1, 0, 0.25)

	self.HealPrediction = {
		myBar = myBar;
		otherBar = otherBar;
		maxOverflow = 1;
	}
	
	--------------------------------------------------------------------------------------------------
	--		Castbar
	--------------------------------------------------------------------------------------------------
	local Castbar = F.ReverseBar(self)
	Castbar:SetAllPoints(Portrait)
	Castbar:SetFrameLevel(Portrait:GetFrameLevel() + 1)
	Castbar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	Castbar:SetStatusBarColor(1.0, 1.0, 1.0, 0.33)

	local Icon = Castbar:CreateTexture(nil, "OVERLAY")
	Icon:SetPoint("TOPLEFT", Castbar, "TOPRIGHT", 8, 0)
	Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	Icon:SetSize(settings.iconsize, settings.iconsize)
	Castbar.Icon = Icon
	
	local IconBackdrop = CreateFrame("Frame", nil, Castbar)
	IconBackdrop:SetAllPoints(Icon)
	gUI:SetUITemplate(IconBackdrop, "border")
	gUI:SetUITemplate(IconBackdrop, "gloss")
	gUI:SetUITemplate(IconBackdrop, "shade")
	gUI:CreateUIShadow(IconBackdrop)

	local Time = Castbar:CreateFontString()
	Time:SetFontObject(gUI_UnitFrameFont14)
	Time:SetJustifyH("LEFT")
	Time:SetTextColor(1, 1, 1, 1)
	Time:SetPoint("TOPLEFT", IconBackdrop, "BOTTOMLEFT", -3, -4)
	Castbar.Time = Time

	local CustomTimeText = function(self, duration)
		if (self.casting) then
			self.Time:SetFormattedText("%.1f", self.max - duration)
		elseif (self.channeling) then
			self.Time:SetFormattedText("%.1f", duration)
		end
	end
	Castbar.CustomTimeText = CustomTimeText
	
	self.Castbar = Castbar

	--------------------------------------------------------------------------------------------------
	--		Texts and Values
	--------------------------------------------------------------------------------------------------
	local healthValue = self.InfoFrame:CreateFontString()
	healthValue:SetShown(unitDB.showHealth)
	healthValue:SetFontObject(gUI_UnitFrameFont14)
	healthValue:SetPoint("BOTTOMLEFT", Health, 2, 1)
	healthValue:SetJustifyH("LEFT")
	healthValue.frequentUpdates = 1/4

	self:Tag(healthValue, "[gUI™ health]")
	
	self.healthValue = healthValue

	local FriendshipText = self.InfoFrame:CreateFontString()
	FriendshipText:SetFontObject(gUI_TextFontTinyBoldOutlineWhite)
	FriendshipText:SetPoint("CENTER", self.FriendshipBar, "CENTER", 0, 1)
	FriendshipText:SetJustifyH("CENTER")
	self.FriendshipBar.text = FriendshipText

	local Name = self.InfoFrame:CreateFontString()
	Name:SetFontObject(gUI_UnitFrameFont20)
	Name:SetTextColor(1, 1, 1)
	Name:SetJustifyH("RIGHT")
	Name:SetSize(self:GetWidth() - 40, (select(2, Name:GetFont())))
	Name:SetPoint("TOPRIGHT", self.Portrait, "TOPRIGHT", -3, -3)
	self:Tag(Name, "[gUI™ name]")
	
	self.Name = Name

	local NameInfo = self.InfoFrame:CreateFontString()
	NameInfo:SetFontObject(gUI_UnitFrameFont12)
	NameInfo:SetTextColor(1, 1, 1)
	NameInfo:SetPoint("TOPRIGHT", self.Name, "BOTTOMRIGHT", 0, 1)
	NameInfo:SetJustifyH("RIGHT")
	self:Tag(NameInfo, "[race] [raidcolor][smartclass]|r [difficulty][smartlevel][gUI™ pvp]|r")

	self.NameInfo = NameInfo

	--------------------------------------------------------------------------------------------------
	--		Icons
	--------------------------------------------------------------------------------------------------
	local RaidIcon = self.IconFrame:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(settings.iconsize * 0.75, settings.iconsize * 0.75)
	RaidIcon:SetPoint("CENTER", self, "TOP")
	RaidIcon:SetTexture(M("Icon", "RaidTarget"))

	self.RaidIcon = RaidIcon
	
	local IconStack = self.IconFrame:CreateFontString()
	IconStack:SetFontObject(gUI_UnitFrameFont14)
	IconStack:SetTextColor(1, 1, 1)
	IconStack:SetJustifyH("RIGHT")
	IconStack:SetJustifyV("TOP")
	IconStack:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, (select(2, IconStack:GetFont())) - 2)
	
	self.IconStack = IconStack
	
	self:Tag(self.IconStack, "[gUI™ quest][gUI™ leader][gUI™ masterlooter][gUI™ maintank][gUI™ mainassist]")
	
	--------------------------------------------------------------------------------------------------
	--		Spell Range
	--------------------------------------------------------------------------------------------------
	local SpellRange = {
		insideAlpha = 1.0; 
		outsideAlpha = 0.33; 
	}
	self.SpellRange = SpellRange

	--------------------------------------------------------------------------------------------------
	--		Threat
	--------------------------------------------------------------------------------------------------
	local threatValue = self.InfoFrame:CreateFontString()
	threatValue:SetFontObject(gUI_UnitFrameFont14)
	threatValue:SetPoint("TOPRIGHT", self.Power, -2, 0)
	threatValue:SetJustifyH("RIGHT")
	
	self:Tag(threatValue, "[gUI™ threat]")
	
	self.threatValue = threatValue

	--------------------------------------------------------------------------------------------------
	--		CombatFeedback
	--------------------------------------------------------------------------------------------------
	local CombatFeedbackText = self.InfoFrame:CreateFontString()
	CombatFeedbackText:SetFontObject(gUI_UnitFrameFont22)
	CombatFeedbackText:SetPoint("CENTER", Portrait)
	CombatFeedbackText.colors = C["feedbackcolors"]
	
	self.CombatFeedbackText = CombatFeedbackText

	--------------------------------------------------------------------------------------------------
	--		Combo Points
	--------------------------------------------------------------------------------------------------
	local CPoints = CreateFrame("Frame", nil, self)
	CPoints:SetHeight(settings.powerbarsize)
	CPoints:SetPoint("LEFT", self, "LEFT", 0, 0)
	CPoints:SetPoint("RIGHT", self, "RIGHT", 0, 0)
	CPoints:SetPoint("BOTTOM", self, "BOTTOM", 0, (settings.powerbarsize + 1)*2)
	CPoints:SetFrameLevel(self.Power:GetFrameLevel())

	for i = 1, MAX_COMBO_POINTS do
		CPoints[i] = CreateFrame("StatusBar", nil, CPoints)
		CPoints[i]:SetSize(floor((self:GetWidth() - (MAX_COMBO_POINTS - 1)) / MAX_COMBO_POINTS), settings.powerbarsize)
		CPoints[i]:SetStatusBarTexture(gUI:GetStatusBarTexture())
		CPoints[i]:SetStatusBarColor(unpack(C["combopointcolors"][i]))
		CPoints[i]:SetMinMaxValues(0, 1)
		CPoints[i]:SetValue(1)
		CPoints[i].shine = F.Shine:New(CPoints[i], nil, nil, 3)
		CPoints[i]:HookScript("OnShow", function(self) self.shine:Start() end)

		gUI:SetUITemplate(CPoints[i], "gloss")
		-- gUI:SetUITemplate(CPoints[i], "shade")
		
		CPoints[i].bg = CPoints[i]:CreateTexture(nil, "BORDER")
		CPoints[i].bg:SetTexture(gUI:GetStatusBarTexture())
		CPoints[i].bg:SetPoint("TOP", CPoints[i], "TOP", 0, 1)
		CPoints[i].bg:SetPoint("BOTTOM", CPoints[i], "BOTTOM", 0, 0)
		CPoints[i].bg:SetPoint("RIGHT", CPoints[i], "RIGHT", 1, 0)
		CPoints[i].bg:SetPoint("LEFT", CPoints[i], "LEFT", -1, 0)
		CPoints[i].bg:SetVertexColor(0, 0, 0, 1)

		if (i == 1) then
			CPoints[i]:SetPoint("TOPLEFT", CPoints, "TOPLEFT", 0, 0)
		elseif (i == MAX_COMBO_POINTS) then
			CPoints[i]:SetPoint("BOTTOMRIGHT", CPoints, "BOTTOMRIGHT", 0, 0)
		else
			CPoints[i]:SetPoint("LEFT", CPoints[i - 1], "RIGHT", 1, 0)
		end
	end

	self.CPoints = CPoints

	--------------------------------------------------------------------------------------------------
	--		Icons
	--------------------------------------------------------------------------------------------------
	-- Combat Icon
	local Combat = self.IconFrame:CreateTexture(nil, "OVERLAY")
	Combat:SetSize(settings.iconsize * 2, settings.iconsize * 2)
	Combat:SetPoint("CENTER", self.Health)

	self.Combat = Combat
	
	--------------------------------------------------------------------------------------------------
	--		Auras
	--------------------------------------------------------------------------------------------------
	local AuraHolder = CreateFrame("Frame", nil, self)
	AuraHolder:SetShown(unitDB.showTargetAuras)
	self.AuraHolder = AuraHolder
	
	local Auras = CreateFrame("Frame", nil, self.AuraHolder)
	-- Auras:SetFrameStrata(self:GetFrameStrata())
	-- Auras:SetFrameLevel(self:GetFrameLevel() - 1)
	Auras:ClearAllPoints()
	Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -3, 3)
	Auras:SetSize(settings.aura.width * settings.aura.size + (settings.aura.width - 1) * settings.aura.gap, settings.aura.height * settings.aura.size + (settings.aura.height - 1) * settings.aura.gap)

	Auras.size = settings.aura.size
	Auras.spacing = settings.aura.gap
	Auras.showStealableBuffs = playerClass == "MAGE"

	Auras.initialAnchor = "BOTTOMLEFT"
	Auras["growth-y"] = "UP"
	Auras["growth-x"] = "RIGHT"

	Auras.CustomFilter = F.CustomAuraFilter
	Auras.PostUpdateIcon = F.PostUpdateAura
	Auras.PostCreateIcon = F.PostCreateAura

	local force = function(parent, self)
		self["UNIT_AURA"](self, "UNIT_AURA", "target")
	end
	local set = function(self)
		module:ScheduleTimer(1/3, force, self)
	end
	self:RegisterEvent("PLAYER_REGEN_ENABLED", set)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", set)

	self.Auras = Auras
end

module.PostUpdateSettings = function(self, event, ...)
	return _STATE and (unitDB.showEmbeddedClassBar and _STATE:SetAlpha(1) or _STATE:SetAlpha(0))
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	unitDB = self:GetParent():GetCurrentOptionsSet()

	oUF:RegisterStyle(style, Style)
	oUF:Factory(function(self)
		self:SetActiveStyle(style)

		local frame = self:Spawn("target")
		frame:SetParent(gUI:GetAttribute("parent"))
		
		-- complete copout
		-- the combopoints are the only class resource shown on the target
		_STATE = frame.CPoints

		module:PlaceAndSave(frame, L["Target"], db.pos, unpack(defaults.pos))
		module:AddObjectToFrameGroup(frame, "unitframes")
		module:PostUpdateSettings()
	end)
	
end

module.OnEnable = function(self)
	
end

module.OnDisable = function(self)
end