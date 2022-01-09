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
local module = unitframes:NewModule("Party")
local R = unitframes:GetDataBase("auras")
local UnitFrames = module:NewDataBase("unitframes")

local setmetatable, rawget = setmetatable, rawget
local unpack, select, tinsert = unpack, select, table.insert

local L, C, F, M, db, unitDB
local Style, party

local settings = {
	showSolo = false;

	size = { 168, 36 }; -- 120, 16

	iconsize = 16;
	aura = {
		size = 20;
		gap = 4;
		height = 2;
		width = 6;
	};

	portraitSize = { 36, 36 };
	healthBarSize = { 120, 11};
	powerBarSize = { 120, 4};
}	

local defaults = {
	place = { "LEFT", "UIParent", "LEFT", 12, 0 } -- "TOPLEFT", "UIParent", "TOPLEFT", 12, -250
}

-- color portrait borders according to LFDRole
local LFDRoleOverride = function(self, event)
	if (not self.LFDRole) then return end

	local role = UnitGroupRolesAssigned(self.unit)
	if (not role) then return end

	if (role == "TANK") then
		self.LFDRole:SetBackdropBorderColor(unpack(C["role"]["tank"]))
		
	elseif (role == "HEALER") then
		self.LFDRole:SetBackdropBorderColor(unpack(C["role"]["heal"]))
		
--	elseif (role == "DAMAGER") then
--		self.LFDRole:SetBackdropBorderColor(unpack(C["role"]["dps"]))
		
	else
		self.LFDRole:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
		
	end
end

--------------------------------------------------------------------------------------------------
--		Shared Frame Styles
--------------------------------------------------------------------------------------------------
Style = function(self, unit)
	F.AllFrames(self, unit)
	F.CreateTargetBorder(self, unit)

	--------------------------------------------------------------------------------------------------
	--		Health
	--------------------------------------------------------------------------------------------------
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetSize(unpack(settings.healthBarSize))
	Health:SetPoint("BOTTOMRIGHT", 0, settings.powerBarSize[2] + 1)
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
	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetSize(unpack(settings.powerBarSize))
	Power:SetPoint("BOTTOMRIGHT")
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
	PortraitHolder:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)

	PortraitHolder.Border = gUI:SetUITemplate(PortraitHolder, "outerbackdrop")
	gUI:CreateUIShadow(PortraitHolder.Border)
		
	-- we color the bordor of the portraits to indicate role
	self.LFDRole = PortraitHolder.Border
	self.LFDRole.Override = LFDRoleOverride

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
	Name:SetJustifyH("LEFT")
	Name:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 8)

	self:Tag(Name, "[gUI™ name]")

	self.Name = Name
	
	local healthValue = self.InfoFrame:CreateFontString()
	healthValue:SetShown(unitDB.showHealth)
	healthValue:SetFontObject(gUI_UnitFrameFont14)
	healthValue:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, 8)
	healthValue:SetJustifyH("RIGHT")
	healthValue.frequentUpdates = 1/4

	self:Tag(healthValue, "[gUI™ health]")
	
	self.healthValue = healthValue
	self.Name:SetPoint("RIGHT", self.healthValue, "LEFT", -8, 0) -- prevent overlaps
	
	--------------------------------------------------------------------------------------------------
	--		Icons
	--------------------------------------------------------------------------------------------------
	local RaidIcon = self.IconFrame:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(settings.iconsize, settings.iconsize)
	RaidIcon:SetPoint("CENTER", self.Health, "TOP", 0, 4)
	RaidIcon:SetTexture(M("Icon", "RaidTarget"))

	self.RaidIcon = RaidIcon
	
	local IconStack = self.IconFrame:CreateFontString()
	IconStack:SetFontObject(gUI_UnitFrameFont12)
	IconStack:SetTextColor(1, 1, 1)
	IconStack:SetJustifyH("LEFT")
	IconStack:SetJustifyV("TOP")
	IconStack:SetPoint("TOPLEFT", self.Portrait, "TOPLEFT", 0, (select(2, IconStack:GetFont())) - 2)
	
	self.IconStack = IconStack

	self:Tag(self.IconStack, "[gUI™ leader][gUI™ masterlooter][gUI™ maintank][gUI™ mainassist]")

	--------------------------------------------------------------------------------------------------
	--		CombatFeedback
	--------------------------------------------------------------------------------------------------
	local CombatFeedbackText = self.InfoFrame:CreateFontString()
	CombatFeedbackText:SetFontObject(gUI_UnitFrameFont22)
	CombatFeedbackText:SetPoint("CENTER", Health)
	CombatFeedbackText.colors = C["feedbackcolors"]
		
	self.CombatFeedbackText = CombatFeedbackText
	
	--------------------------------------------------------------------------------------------------
	--		Range
	--------------------------------------------------------------------------------------------------
	local Range = {
		insideAlpha = 1.0;
		outsideAlpha = 0.3;
	}
	self.Range = Range
	
	--------------------------------------------------------------------------------------------------
	--		Grid Indicators
	--------------------------------------------------------------------------------------------------
	local GUISIndicators = CreateFrame("Frame", nil, self.InfoFrame) -- using the InfoFrame to get them top level
	GUISIndicators:SetPoint("TOPLEFT", self.Health, "TOPLEFT", 0, 0)
	GUISIndicators:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
	GUISIndicators:SetShown(unitDB.showGridIndicators)

	GUISIndicators.fontObject = gUI_UnitFrameFont10
	GUISIndicators.width = settings.size[2]
	GUISIndicators.indicatorSize = 6
	GUISIndicators.symbolSize = 8
	GUISIndicators.frequentUpdates = 1/4
	
	self.GUISIndicators = GUISIndicators

	--------------------------------------------------------------------------------------------------
	--		Auras
	--------------------------------------------------------------------------------------------------
	local Auras = CreateFrame("Frame", nil, self)
	Auras:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 8, 0)
	Auras:SetSize(settings.aura.width * settings.aura.size + (settings.aura.width - 1) * settings.aura.gap, settings.aura.height * settings.aura.size + (settings.aura.height - 1) * settings.aura.gap)
	Auras.size = settings.aura.size
	Auras.spacing = settings.aura.gap
	Auras.numBuffs = settings.aura.width * settings.aura.size
	Auras.numDebuffs = settings.aura.width * settings.aura.size

	Auras.initialAnchor = "BOTTOMLEFT"
	Auras["growth-y"] = "UP"
	Auras["growth-x"] = "RIGHT"
	Auras.onlyShowPlayer = false
	
	Auras.buffFilter = "HELPFUL RAID PLAYER"
	Auras.debuffFilter = "HARMFUL"

	Auras.PostUpdateIcon = F.PostUpdateAura
	Auras.PostCreateIcon = F.PostCreateAura

	self.Auras = Auras
	
	-- reposition border
	self.FrameBorder:ClearAllPoints()
	self.FrameBorder:SetPoint("TOPLEFT", self.Health, "TOPLEFT", -3, 3)
	self.FrameBorder:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMRIGHT", 3, -3)
end

module.PostUpdateSettings = function(self)
	
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	unitDB = self:GetParent():GetCurrentOptionsSet() -- in theory the shared options for unitframes
	
	oUF:RegisterStyle(addon.."Party", Style)
	oUF:Factory(function(self)
		self:SetActiveStyle(addon.."Party")
		
		local holder = CreateFrame("Frame", nil, gUI:GetAttribute("parent"))
		holder:SetFrameStrata("LOW")
		holder:SetFrameLevel(1)
		holder:SetSize(settings.size[1], settings.size[2]*5 + 20*4)

		party = self:SpawnHeader("GUIS_Party", nil, 
			settings.showSolo and "solo" or F.GetHeaderVisibility("party"), 
			"oUF-initialConfigFunction", ([[
				self:SetWidth(%d)
				self:SetHeight(%d)
				-- self:SetFrameStrata("LOW")
				%s
			]]):format(settings.size[1], settings.size[2], 
			F.GetFocusMacroString()), 
			"showPlayer", unitDB.showPlayer, -- retrieving this from the parent saved settings
			"showSolo", settings.showSolo, 
			"groupBy", "GROUP",
			"groupFilter", "1,2,3,4,5,6,7,8",
			"groupingOrder", "1,2,3,4,5,6,7,8", 
			"showRaid", true, 
			"showParty", true, 
			"yOffset", -20
		)

		party:SetParent(holder)
		party:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
		
		module:PlaceAndSave(holder, L["Party"], db.place, unpack(defaults.place))
		module:AddObjectToFrameGroup(holder, "unitframes")
	end)
end
