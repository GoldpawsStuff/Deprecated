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
local module = unitframes:NewModule("Boss")
local R = unitframes:GetDataBase("auras")
local UnitFrames = module:NewDataBase("unitframes")

local setmetatable, rawget = setmetatable, rawget
local unpack, select, tinsert = unpack, select, table.insert

local L, C, F, M, db, unitDB
local Style

local settings = {
	size = { 168, 36 };
	portraitSize = { 36, 36 };
	healthBarSize = { 120, 11};
	powerBarSize = { 120, 4};
	iconSize = 16;
	aura = {
		size = 20;
		gap = 4;
		height = 2;
		width = 6;
	};
}	

local defaults = {
	pos = { "LEFT", "UIParent", "CENTER", 320, 0 };
}

--------------------------------------------------------------------------------------------------
--		Shared Frame Styles
--------------------------------------------------------------------------------------------------
Style = function(self, unit)
	F.AllFrames(self, unit)
	F.CreateTargetBorder(self, unit)
	
	--------------------------------------------------------------------------------------------------
	--		Health
	--------------------------------------------------------------------------------------------------
	local Health = F.ReverseBar(self)
	Health:SetSize(unpack(settings.healthBarSize))
	Health:SetPoint("BOTTOMLEFT", 0, settings.powerBarSize[2] + 1)
	Health:SetStatusBarTexture(gUI:GetStatusBarTexture())
	gUI:SetUITemplate(Health, "gloss")
	-- gUI:SetUITemplate(Health, "shade")
		
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
	--		Power
	--------------------------------------------------------------------------------------------------
	local Power = F.ReverseBar(self)
	Power:SetSize(unpack(settings.powerBarSize))
	Power:SetPoint("BOTTOMLEFT")
	Power:SetStatusBarTexture(gUI:GetStatusBarTexture())
	Power:SetFrameLevel(15)
	gUI:SetUITemplate(Power, "gloss")
	-- gUI:SetUITemplate(Power, "shade")

	Health:SetPoint("BOTTOM", Power, "TOP", 0, 1)

	local PowerBackground = Power:CreateTexture(nil, "BACKGROUND")
	PowerBackground:SetAllPoints(Power)
	PowerBackground:SetTexture(gUI:GetStatusBarTexture())

	local PowerTopLine = Power:CreateTexture(nil, "OVERLAY")
	PowerTopLine:SetPoint("BOTTOMRIGHT", Power, "TOPRIGHT")
	PowerTopLine:SetPoint("BOTTOMLEFT", Power, "TOPLEFT")
	PowerTopLine:SetHeight(1)
	PowerTopLine:SetTexture(unpack(C["background"]))

	Power.frequentUpdates = 1/4
	Power.colorTapping = true
	Power.colorDisconnected = true
	Power.colorPower = true
	Power.colorClass = true
	Power.colorReaction = true
	Power.Smooth = true

	PowerBackground.multiplier = 1/3

	self.Power = Power
	self.Power.bg = PowerBackground

	--------------------------------------------------------------------------------------------------
	--		Portrait
	--------------------------------------------------------------------------------------------------
	local PortraitHolder = CreateFrame("Frame", nil, self)
	PortraitHolder:SetSize(unpack(settings.portraitSize))
	PortraitHolder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)

	PortraitHolder.Border = gUI:SetUITemplate(PortraitHolder, "outerbackdrop")
	gUI:CreateUIShadow(PortraitHolder.Border)
		
	local Portrait = CreateFrame("PlayerModel", nil, PortraitHolder)
	Portrait:SetAllPoints(PortraitHolder)
	Portrait:SetAlpha(1)
	Portrait.Border = PortraitHolder.Border
	
	Portrait.Shade = Portrait:CreateTexture(nil, "OVERLAY")
	Portrait.Shade:SetTexture(0, 0, 0, 1/2)
	Portrait.Shade:SetPoint("TOPLEFT", -1, 1)
	Portrait.Shade:SetPoint("BOTTOMRIGHT", 1, -1)

	Portrait.Overlay = Portrait:CreateTexture(nil, "OVERLAY")
	Portrait.Overlay:SetTexture(M("Background", "gUI™ UnitShader"))
	Portrait.Overlay:SetVertexColor(0, 0, 0, 1)
	Portrait.Overlay:SetAllPoints(Portrait.Shade)

	self.Portrait = Portrait
	self.Portrait.PostUpdate = F.PostUpdatePortrait		
	
	tinsert(self.__elements, F.HidePortrait)
	
	--------------------------------------------------------------------------------------------------
	--		Texts and Values
	--------------------------------------------------------------------------------------------------
	local Name = self.InfoFrame:CreateFontString()
	Name:SetFontObject(gUI_UnitFrameFont14)
	Name:SetTextColor(1, 1, 1)
	Name:SetSize(settings.size[1] - 40, (select(2, Name:GetFont())))
	Name:SetJustifyH("RIGHT")
	Name:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, 8)

	self:Tag(Name, "[gUI™ name]")

	self.Name = Name
	
	local healthValue = self.InfoFrame:CreateFontString()
	healthValue:SetShown(unitDB.showHealth)
	healthValue:SetFontObject(gUI_UnitFrameFont14)
	healthValue:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 8)
	healthValue:SetJustifyH("LEFT")
	healthValue.frequentUpdates = 1/4
	
	self:Tag(healthValue, "[gUI™ health]")
	
	self.healthValue = healthValue
	self.Name:SetPoint("LEFT", self.healthValue, "RIGHT", 8, 0) -- prevent overlaps
	
	--------------------------------------------------------------------------------------------------
	--		Alternate Power
	--------------------------------------------------------------------------------------------------
	local AltPowerBar = CreateFrame("StatusBar", self:GetName() .. "AltPowerBar", self.Health)
	AltPowerBar:SetFrameLevel(5)
	AltPowerBar:SetSize(unpack(settings.powerBarSize))
	AltPowerBar:SetPoint("BOTTOM", self.Health, "BOTTOM", 0, 0)
	AltPowerBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	AltPowerBar:GetStatusBarTexture():SetHorizTile(false)
	AltPowerBar:SetStatusBarColor(163/255,  24/255,  24/255)
	AltPowerBar:EnableMouse(true)
	gUI:SetUITemplate(AltPowerBar, "gloss")
	-- gUI:SetUITemplate(AltPowerBar, "shade")

	local AltPowerBackground = AltPowerBar:CreateTexture(nil, "BACKGROUND")
	AltPowerBackground:SetAllPoints(AltPowerBar)
	AltPowerBackground:SetTexture(gUI:GetStatusBarTexture())
	AltPowerBackground:SetVertexColor(163/255/3,  24/255/3,  24/255/3)

	local AltPowerTopLine = AltPowerBar:CreateTexture(nil, "OVERLAY")
	AltPowerTopLine:SetPoint("LEFT", AltPowerBar)
	AltPowerTopLine:SetPoint("RIGHT", AltPowerBar)
	AltPowerTopLine:SetPoint("BOTTOM", AltPowerBar, "TOP")
	AltPowerTopLine:SetHeight(1)
	AltPowerTopLine:SetTexture(unpack(C["background"]))

	local AltPowerValue = AltPowerBar:CreateFontString()
	AltPowerValue:SetShown(unitDB.showPower)
	AltPowerValue:SetFontObject(gUI_UnitFrameFont14)
	AltPowerValue:ClearAllPoints()
	AltPowerValue:SetPoint("CENTER", AltPowerBar, "CENTER", 0, 0)
	AltPowerValue:SetJustifyH("CENTER")
	AltPowerValue.frequentUpdates = 1/4

	self:Tag(AltPowerValue, "[gUI™ altpower]")

	self.AltPowerValue = AltPowerValue
	self.AltPowerBar = AltPowerBar

	--------------------------------------------------------------------------------------------------
	--		Icons
	--------------------------------------------------------------------------------------------------
	local RaidIcon = self.IconFrame:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(settings.iconSize, settings.iconSize)
	RaidIcon:SetPoint("CENTER", self.Health, "TOP", 0, 4)
	RaidIcon:SetTexture(M("Icon", "RaidTarget"))

	self.RaidIcon = RaidIcon
	
	local IconStack = self.IconFrame:CreateFontString()
	IconStack:SetFontObject(gUI_UnitFrameFont12)
	IconStack:SetTextColor(1, 1, 1)
	IconStack:SetJustifyH("RIGHT")
	IconStack:SetJustifyV("TOP")
	IconStack:SetPoint("TOPRIGHT", self.Portrait, "TOPRIGHT", 0, (select(2, IconStack:GetFont())) - 2)
	
	self.IconStack = IconStack

	self:Tag(self.IconStack, "[gUI™ quest]")

	--------------------------------------------------------------------------------------------------
	--		Auras
	--------------------------------------------------------------------------------------------------
	local AuraHolder = CreateFrame("Frame", nil, self)
	self.AuraHolder = AuraHolder
	
	local Auras = CreateFrame("Frame", nil, self)
	Auras:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -8, 0)
	Auras:SetSize(settings.aura.width * settings.aura.size + (settings.aura.width - 1) * settings.aura.gap, settings.aura.height * settings.aura.size + (settings.aura.height - 1) * settings.aura.gap)
	Auras.size = settings.aura.size
	Auras.spacing = settings.aura.gap
	Auras.numBuffs = settings.aura.width * settings.aura.size
	Auras.numDebuffs = 0

	Auras.initialAnchor = "BOTTOMRIGHT"
	Auras["growth-y"] = "UP"
	Auras["growth-x"] = "LEFT"
	Auras.showStealableBuffs = playerClass == "MAGE"
	
	Auras.buffFilter = "HELPFUL"
	Auras.debuffFilter = "HARMFUL"

	Auras.PostUpdateIcon = F.PostUpdateAura
	Auras.PostCreateIcon = F.PostCreateAura

	self.Auras = Auras

	--------------------------------------------------------------------------------------------------
	--		CombatFeedback
	--------------------------------------------------------------------------------------------------
	local CombatFeedbackText = self.InfoFrame:CreateFontString()
	CombatFeedbackText:SetFontObject(gUI_UnitFrameFont22)
	CombatFeedbackText:SetPoint("CENTER", Health)
	CombatFeedbackText.colors = C["feedbackcolors"]
		
	self.CombatFeedbackText = CombatFeedbackText
	
	--------------------------------------------------------------------------------------------------
	--		Spell Range
	--------------------------------------------------------------------------------------------------
	local SpellRange = {
		insideAlpha = 1.0; 
		outsideAlpha = 0.33; 
	}
	self.SpellRange = SpellRange
	
	-- reposition border
	self.FrameBorder:ClearAllPoints()
	self.FrameBorder:SetPoint("TOPLEFT", self.Health, "TOPLEFT", -3, 3)
	self.FrameBorder:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMRIGHT", 3, -3)	
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	unitDB = self:GetParent():GetCurrentOptionsSet()
	
	oUF:RegisterStyle(addon.."Boss", Style)
	oUF:Factory(function(self)
		self:SetActiveStyle(addon.."Boss")
		
		local w, h = settings.size[1], settings.size[2]*MAX_BOSS_FRAMES + 20*(MAX_BOSS_FRAMES-1)
		local boss = CreateFrame("Frame", "GUIS_Arena", gUI:GetAttribute("parent"))
		boss:SetFrameStrata("LOW")
		boss:SetFrameLevel(1)
		boss:SetSize(w, h)

		module:PlaceAndSave(boss, L["Boss"], db.pos, unpack(defaults.pos))
		module:AddObjectToFrameGroup(boss, "unitframes")

		for i = 1, MAX_BOSS_FRAMES do
			boss[i] = oUF:Spawn("boss"..i, "GUIS_Boss"..i)
			boss[i]:SetParent(gUI:GetAttribute("parent"))
			if (i == 1) then
				boss[i]:SetPoint("TOPRIGHT", boss, "TOPRIGHT", 0, 0)
			else
				boss[i]:SetPoint("TOPRIGHT", boss[i - 1], "BOTTOMRIGHT", 0, -20)
			end
			boss[i]:SetSize(unpack(settings.size))
		end
	end)
	
end
