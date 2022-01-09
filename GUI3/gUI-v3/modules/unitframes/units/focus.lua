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
local module = unitframes:NewModule("Focus")
local style = addon .. "_Focus"

local L, C, F, M, db, unitDB
local Style

local settings = {
	size = { 126, 30 };
	portraitsize = { 40, 40 };
	powerbarsize = 6;
	iconsize = 14;
	aura = {
		size = 20;
		gap = 0;
		height = 2;
		width = 9;
	};
}

local defaults = {
	pos = { "CENTER", "UIParent", "CENTER", -300, -70 };
}

Style = function(self, unit)
	F.AllFrames(self, unit)

	self:SetSize(unpack(settings.size))

	--------------------------------------------------------------------------------------------------
	--		Power
	--------------------------------------------------------------------------------------------------
	local Power = CreateFrame("StatusBar", nil, self)
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
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetPoint("TOP", 0, 0)
	Health:SetPoint("BOTTOM", Power, "TOP", 0, 1)
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
	--		Heal Prediction
	--------------------------------------------------------------------------------------------------
	local myBar = CreateFrame("StatusBar", nil, self.Health)
	myBar:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	myBar:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	myBar:SetWidth(self:GetWidth())
	myBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	myBar:SetStatusBarColor(0, 1, 0.5, 0.25)

	local otherBar = CreateFrame("StatusBar", nil, self.Health)
	otherBar:SetPoint("TOPLEFT", myBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	otherBar:SetPoint("BOTTOMLEFT", myBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
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
	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetAllPoints(Health)
	Castbar:SetFrameLevel(Health:GetFrameLevel() + 1)
	Castbar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	Castbar:SetStatusBarColor(1.0, 1.0, 1.0, 0.33)

	self.Castbar = Castbar

	--------------------------------------------------------------------------------------------------
	--		Texts and Values
	--------------------------------------------------------------------------------------------------
	local healthValue = self.InfoFrame:CreateFontString()
	healthValue:SetShown(unitDB.showHealth)
	healthValue:SetFontObject(gUI_UnitFrameFont14)
	healthValue:SetPoint("RIGHT", self.Health, "RIGHT", -3, 0)
	healthValue:SetJustifyH("RIGHT")
	healthValue.frequentUpdates = 1/4

	self:Tag(healthValue, "[gUI™ health]")
	
	self.healthValue = healthValue

	local Name = self.InfoFrame:CreateFontString()
	Name:SetFontObject(gUI_UnitFrameFont14)
	Name:SetTextColor(1, 1, 1)
	Name:SetJustifyH("LEFT")
	Name:SetSize(self:GetWidth() - 40, (select(2, Name:GetFont())))
	Name:SetPoint("LEFT", self.Health, "LEFT", 3, 0)

	self:Tag(Name, "[gUI™ name]")
	
	self.Name = Name

	--------------------------------------------------------------------------------------------------
	--		Icons
	--------------------------------------------------------------------------------------------------
	local RaidIcon = self.IconFrame:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(settings.iconsize * 0.75, settings.iconsize * 0.75)
	RaidIcon:SetPoint("CENTER", self, "TOP")
	RaidIcon:SetTexture(M("Icon", "RaidTarget"))

	self.RaidIcon = RaidIcon
	
	local IconStack = self.IconFrame:CreateFontString()
	IconStack:SetFontObject(gUI_UnitFrameFont12)
	IconStack:SetTextColor(1, 1, 1)
	IconStack:SetJustifyH("LEFT")
	IconStack:SetJustifyV("TOP")
	IconStack:SetPoint("TOPLEFT", self, "TOPLEFT", 0, (select(2, IconStack:GetFont())) - 2)
	
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
	
	if (unit == "focus") then
		--------------------------------------------------------------------------------------------------
		--		Auras
		--------------------------------------------------------------------------------------------------
		local AuraHolder = CreateFrame("Frame", nil, self)
		self.AuraHolder = AuraHolder
		
		local Auras = CreateFrame("Frame", nil, self.AuraHolder)
		
		Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -3, 3)
		Auras:SetSize(settings.aura.width * settings.aura.size + (settings.aura.width - 1) * settings.aura.gap, settings.aura.height * settings.aura.size + (settings.aura.height - 1) * settings.aura.gap)

		Auras.size = settings.aura.size
		Auras.spacing = settings.aura.gap

		Auras.initialAnchor = "BOTTOMLEFT"
		Auras["growth-y"] = "UP"
		Auras["growth-x"] = "RIGHT"

--			Auras.buffFilter = "HELPFUL RAID PLAYER"
--			Auras.debuffFilter = "HARMFUL"
--			Auras.CustomFilter = F.CustomAuraFilter

		Auras.PostUpdateIcon = F.PostUpdateAura
		Auras.PostCreateIcon = F.PostCreateAura

		self.Auras = Auras

		--------------------------------------------------------------------------------------------------
		--		Cast Icon
		--------------------------------------------------------------------------------------------------
		local Icon = self.Castbar:CreateTexture(nil, "OVERLAY")
		Icon:SetPoint("TOPRIGHT", self, "TOPLEFT", -8, 0)
		Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		Icon:SetSize(self:GetHeight(), self:GetHeight())
		
		local IconBackdrop = CreateFrame("Frame", nil, self.Castbar)
		IconBackdrop:SetAllPoints(Icon)
		gUI:SetUITemplate(IconBackdrop, "border")
		gUI:SetUITemplate(IconBackdrop, "gloss")
		gUI:SetUITemplate(IconBackdrop, "shade")
		gUI:CreateUIShadow(IconBackdrop)
		
		self.Castbar.Icon = Icon
		
	elseif (unit == "focustarget") then
		self.Name:ClearAllPoints()
		self.Name:SetPoint("RIGHT", self.Health, "RIGHT", -2, 0)
		self.Name:SetJustifyH("RIGHT")
		
		self.healthValue:ClearAllPoints()
		self.healthValue:SetPoint("LEFT", self.Health, "LEFT", 2, 0)
	end

end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	unitDB = self:GetParent():GetCurrentOptionsSet()
	
	oUF:RegisterStyle(style, Style)
	oUF:Factory(function(self)
		self:SetActiveStyle(style)

		local focus = self:Spawn("focus")
		focus:SetParent(gUI:GetAttribute("parent"))
		
		module:PlaceAndSave(focus, L["Focus"], db.pos, unpack(defaults.pos))
		module:AddObjectToFrameGroup(focus, "unitframes")	

		local focustarget = self:Spawn("focustarget")
		focustarget:SetParent(gUI:GetAttribute("parent"))
		focustarget:SetPoint("LEFT", focus, "RIGHT", 12, 0)
	end)
end

module.OnEnable = function(self)
	
end

module.OnDisable = function(self)
end