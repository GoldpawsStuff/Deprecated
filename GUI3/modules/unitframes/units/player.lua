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
local module = unitframes:NewModule("Player")
local style = addon .. "_Player"

local L, C, F, M, db, unitDB
local Style, PostUpdateDruidMana
local _STATE

local localizedClass, class = UnitClass("player")
local race = select(2, UnitRace("player"))

local patch, build, released, toc = GetBuildInfo()
build = tonumber(build)

local settings = {
	size = { 210, 68 }; -- 66
	healthbarsize = 9; -- 9
	powerbarsize = 9; -- 9
	classbarsize = 9; -- 7
	iconsize = 16; -- 16
	aura = {
		size = 27; -- 27
		gap = 0;
		height = 3;
		width = 8; -- 8
	};
}

local iconList = setmetatable({
	default = "[gUI™ quest][gUI™ leader][gUI™ masterlooter][gUI™ maintank][gUI™ mainassist]";
	target = "[gUI™ mainassist][gUI™ maintank][gUI™ masterlooter][gUI™ leader][gUI™ quest]";
}, { __index = function(t, i) return rawget(t, i) or rawget(t, "default") end })

local defaults = {
	pos = { "BOTTOMRIGHT", "UIParent", "BOTTOM", -78, 86 };
}

PostUpdateDruidMana = function(self, event, unit, powertype)
	--only the player frame will have this unit enabled
	--i mainly place this check for UNIT_DISPLAYPOWER and entering a vehicle
	if(unit ~= "player" or (powertype and powertype ~= "MANA")) then return end

	local druidmana = self.DruidMana
	if(druidmana.PreUpdate) then druidmana:PreUpdate(unit) end

	local min, max = UnitPower("player", SPELL_POWER_MANA), UnitPowerMax("player", SPELL_POWER_MANA)
	druidmana:SetMinMaxValues(0, max)
	druidmana:SetValue(min)

	--check form
	if(UnitPowerType("player") == SPELL_POWER_MANA) or (min == max) then
		return druidmana:Hide()
	else
		druidmana:Show()
	end
end

local new = function(self)
	if not(_STATE) then
		_STATE = CreateFrame("Frame", nil, self)
		_STATE:SetSize(settings.size[1], settings.classbarsize)
		_STATE:SetPoint("LEFT", self, "LEFT", 0, 0)
		_STATE:SetPoint("RIGHT", self, "RIGHT", 0, 0)
		_STATE:SetPoint("BOTTOM", self.Health, "TOP", 0, 1)
		-- _STATE:SetFrameLevel(0)
	end

	local frame = CreateFrame("Frame", nil, _STATE)
	frame:SetSize(_STATE:GetSize())
	frame:SetAllPoints()
	frame:SetFrameLevel(self.Power:GetFrameLevel())
	
	return frame
end

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

	local powerValue = self.InfoFrame:CreateFontString()
	powerValue:SetShown(unitDB.showPower)
	powerValue:SetFontObject(gUI_UnitFrameFont14)
	powerValue:SetPoint("TOPRIGHT", Power, -2, 0)
	powerValue:SetJustifyH("RIGHT")
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
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetHeight(settings.healthbarsize)
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
	Castbar:SetAllPoints(Portrait)
	Castbar:SetFrameLevel(Portrait:GetFrameLevel() + 1)
	Castbar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	Castbar:SetStatusBarColor(1.0, 1.0, 1.0, 0.33)

	local Icon = Castbar:CreateTexture(nil, "OVERLAY")
	Icon:SetPoint("TOPRIGHT", Castbar, "TOPLEFT", -8, 0)
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
	Time:SetJustifyH("RIGHT")
	Time:SetTextColor(1, 1, 1, 1)
	Time:SetPoint("TOPRIGHT", IconBackdrop, "BOTTOMRIGHT", 3, -4)
	Castbar.Time = Time
	
	local SafeZone = Castbar:CreateTexture(nil, "OVERLAY")
	SafeZone:SetAllPoints(Castbar)
	SafeZone:SetAlpha(1/4)
	Castbar.SafeZone = SafeZone
	
	local Delay = Castbar:CreateFontString()
	Delay:SetDrawLayer("OVERLAY")
	Delay:SetFontObject(gUI_UnitFrameFont12)
	Delay:SetJustifyH("RIGHT")
	Delay:SetTextColor(0.5, 0.5, 0.5, 1)
	Delay:SetPoint("TOPRIGHT", Castbar, "TOPRIGHT", -3, -3)
	
	SafeZone.Delay = Delay

	local CustomTimeText = function(self, duration)
		if (self.SafeZone) then
			self.SafeZone.Delay:SetFormattedText("|r|cFF888888%d" .. MILLISECONDS_ABBR .. "|r", (select(4, GetNetStats())))
		end

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
	healthValue:SetPoint("BOTTOMRIGHT", Health, -2, 1)
	healthValue:SetJustifyH("RIGHT")
	healthValue.frequentUpdates = 1/4

	self:Tag(healthValue, "[gUI™ health]")
	
	self.healthValue = healthValue

	local Name = self.InfoFrame:CreateFontString()
	Name:SetFontObject(gUI_UnitFrameFont20)
	Name:SetTextColor(1, 1, 1)
	Name:SetJustifyH("LEFT")
	Name:SetSize(self:GetWidth() - 40, (select(2, Name:GetFont())))
	Name:SetPoint("TOPLEFT", self.Portrait, "TOPLEFT", 3, -3)
	self:Tag(Name, "[gUI™ name]" .. ((unit == "player") and "[gUI™ resting]" or ""))
	
	self.Name = Name

	local NameInfo = self.InfoFrame:CreateFontString()
	NameInfo:SetFontObject(gUI_UnitFrameFont12)
	NameInfo:SetTextColor(1, 1, 1)
	NameInfo:SetPoint("TOPLEFT", self.Name, "BOTTOMLEFT", 0, 1)
	self:Tag(NameInfo, "[gUI™ pvp][level] [race] [raidcolor][smartclass]|r")

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
	IconStack:SetJustifyH((unit == "target") and "RIGHT" or "LEFT")
	IconStack:SetJustifyV("TOP")
	IconStack:SetPoint((unit == "target") and "TOPRIGHT" or "TOPLEFT", self, (unit == "target") and "TOPRIGHT" or "TOPLEFT", 0, (select(2, IconStack:GetFont())) - 2)
	
	self.IconStack = IconStack
	
	self:Tag(self.IconStack, "[gUI™ quest][gUI™ leader][gUI™ masterlooter][gUI™ maintank][gUI™ mainassist]")
	
	--------------------------------------------------------------------------------------------------
	--		Vengeance (for tanks)
	--------------------------------------------------------------------------------------------------
	local vengeanceValue = self.InfoFrame:CreateFontString()
	vengeanceValue:SetFontObject(gUI_UnitFrameFont14)
	vengeanceValue:SetPoint("TOPLEFT", self.Power, 2, 0)
	vengeanceValue:SetJustifyH("LEFT")
	
	self:Tag(vengeanceValue, "[gUI™ vengeance]")
	
	self.vengeanceValue = vengeanceValue
	
	--------------------------------------------------------------------------------------------------
	--		Druid Feral Mana
	--------------------------------------------------------------------------------------------------
	if (class == "DRUID") then
		local DruidMana = CreateFrame("StatusBar", self:GetName() .. "DruidMana", self)
		DruidMana:SetFrameLevel(self.Power:GetFrameLevel())
		DruidMana:SetHeight(settings.classbarsize)
		DruidMana:SetPoint("LEFT", self, "LEFT", 0, 0)
		DruidMana:SetPoint("RIGHT", self, "RIGHT", 0, 0)
		DruidMana:SetPoint("BOTTOM", self.Health, "TOP", 0, 1)
		DruidMana:SetStatusBarTexture(gUI:GetStatusBarTexture())
		DruidMana:GetStatusBarTexture():SetHorizTile(false)
		DruidMana:SetStatusBarColor(C.PowerBarColor["MANA"].r, C.PowerBarColor["MANA"].g, C.PowerBarColor["MANA"].b)
		gUI:SetUITemplate(DruidMana, "gloss")
		-- gUI:SetUITemplate(DruidMana, "shade")
			
		local DruidManaTopLine = DruidMana:CreateTexture(nil, "OVERLAY")
		DruidManaTopLine:SetPoint("LEFT", DruidMana)
		DruidManaTopLine:SetPoint("RIGHT", DruidMana)
		DruidManaTopLine:SetPoint("BOTTOM", DruidMana, "TOP")
		DruidManaTopLine:SetHeight(1)
		DruidManaTopLine:SetTexture(unpack(C["background"]))

		local DruidManaBackground = DruidMana:CreateTexture(nil, "BACKGROUND")
		DruidManaBackground:SetAllPoints(DruidMana)
		DruidManaBackground:SetTexture(gUI:GetStatusBarTexture())
		DruidManaBackground:SetVertexColor(C.PowerBarColor["MANA"].r/3, C.PowerBarColor["MANA"].g/3, C.PowerBarColor["MANA"].b/3)
		
		local DruidManaValue = self.Power:CreateFontString()
		DruidManaValue:SetShown(unitDB.showPower)
		DruidManaValue:SetFontObject(gUI_UnitFrameFont14)
		DruidManaValue:ClearAllPoints()
		DruidManaValue:SetPoint("BOTTOMLEFT", self.Health, 2, 1)
		DruidManaValue:SetJustifyH("LEFT")
		DruidManaValue.frequentUpdates = 1/4

		self:Tag(DruidManaValue, "[gUI™ druid]")
		
		DruidMana.Override = PostUpdateDruidMana

		self.DruidManaValue = DruidManaValue
		self.DruidMana = DruidMana
	end
	
	--------------------------------------------------------------------------------------------------
	--		Mage Arcane Charges
	--------------------------------------------------------------------------------------------------
	if (class == "MAGE") then
		local ArcaneCharges = new(self)

		-- patch 5.3 reduced charges to 4
		local ARCANE_CHARGES_FULL = (build >= 16837) and 4 or 6
		for i = 1, ARCANE_CHARGES_FULL do
			ArcaneCharges[i] = CreateFrame("StatusBar", nil, ArcaneCharges)
			ArcaneCharges[i]:SetSize((self:GetWidth() - (ARCANE_CHARGES_FULL - 1)) / ARCANE_CHARGES_FULL, settings.classbarsize)
			ArcaneCharges[i]:SetStatusBarTexture(gUI:GetStatusBarTexture())
			ArcaneCharges[i]:SetStatusBarColor(C.PowerBarColor.ARCANE_CHARGE.r, C.PowerBarColor.ARCANE_CHARGE.g, C.PowerBarColor.ARCANE_CHARGE.b, 1) 
			ArcaneCharges[i]:SetMinMaxValues(0, 1)
			ArcaneCharges[i]:SetValue(0)
			ArcaneCharges[i].shine = F.Shine:New(ArcaneCharges[i], nil, nil, 3)
			ArcaneCharges[i]:HookScript("OnValueChanged", function(self, value) 
				local min, max = self:GetMinMaxValues()
				if (value == max) then 
					self.shine:Start() 
				end
			end)
			
			gUI:SetUITemplate(ArcaneCharges[i], "gloss")
			-- gUI:SetUITemplate(ArcaneCharges[i], "shade")

			ArcaneCharges[i].bg = ArcaneCharges[i]:CreateTexture(nil, "BORDER")
			ArcaneCharges[i].bg:SetTexture(gUI:GetStatusBarTexture())
			ArcaneCharges[i].bg:SetPoint("TOP", ArcaneCharges[i], "TOP", 0, 1)
			ArcaneCharges[i].bg:SetPoint("BOTTOM", ArcaneCharges[i], "BOTTOM", 0, 0)
			ArcaneCharges[i].bg:SetPoint("RIGHT", ArcaneCharges[i], "RIGHT", 1, 0)
			ArcaneCharges[i].bg:SetPoint("LEFT", ArcaneCharges[i], "LEFT", -1, 0)
			ArcaneCharges[i].bg:SetVertexColor(C.PowerBarColor.ARCANE_CHARGE.r/3, C.PowerBarColor.ARCANE_CHARGE.g/3, C.PowerBarColor.ARCANE_CHARGE.b/3, 1)

			if (i == 1) then
				ArcaneCharges[i]:SetPoint("TOPLEFT", ArcaneCharges, "TOPLEFT", 0, 0)
			elseif (i == ARCANE_CHARGES_FULL) then
				ArcaneCharges[i]:SetPoint("BOTTOMRIGHT", ArcaneCharges, "BOTTOMRIGHT", 0, 0)
			else
				ArcaneCharges[i]:SetPoint("LEFT", ArcaneCharges[i - 1], "RIGHT", 1, 0)
			end
		end
		self.ArcaneCharges = ArcaneCharges	
	end
	
	--------------------------------------------------------------------------------------------------
	--		TotemBar
	--------------------------------------------------------------------------------------------------
	if (class == "SHAMAN") then
		local TotemBar = new(self)

		TotemBar.UpdateColors = true

		for i = 1, 4 do
			TotemBar[i] = CreateFrame("Frame", nil, TotemBar)
			TotemBar[i]:SetSize((self:GetWidth() - 3) / 4, settings.classbarsize)
			
			TotemBar[i].StatusBar = CreateFrame("StatusBar", nil, TotemBar[i])
			TotemBar[i].StatusBar:SetSize((self:GetWidth() - 3) / 4, settings.classbarsize)
			TotemBar[i].StatusBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
			TotemBar[i].StatusBar:SetAllPoints(TotemBar[i])
			gUI:SetUITemplate(TotemBar[i].StatusBar, "gloss")
			-- gUI:SetUITemplate(TotemBar[i].StatusBar, "shade")
			
			TotemBar[i].Background = TotemBar[i]:CreateTexture(nil, "BORDER")
			TotemBar[i].Background:SetTexture(gUI:GetStatusBarTexture())
			TotemBar[i].Background:SetPoint("TOP", TotemBar[i], "TOP", 0, 1)
			TotemBar[i].Background:SetPoint("BOTTOM", TotemBar[i], "BOTTOM", 0, -1)
			TotemBar[i].Background:SetPoint("RIGHT", TotemBar[i], "RIGHT", 1, 0)
			TotemBar[i].Background:SetPoint("LEFT", TotemBar[i], "LEFT", -1, 0)
			TotemBar[i].Background:SetVertexColor(0, 0, 0, 1)

			TotemBar[i].bg = TotemBar[i]:CreateTexture(nil, "BORDER")
			TotemBar[i].bg:SetAllPoints(TotemBar[i].StatusBar)
			TotemBar[i].bg:SetTexture(gUI:GetStatusBarTexture())
			TotemBar[i].bg.multiplier = 1/3
		end
		
		TotemBar[1]:SetPoint("TOPLEFT", TotemBar, "TOPLEFT", 0, 0)
		TotemBar[2]:SetPoint("TOPLEFT", TotemBar[1], "TOPRIGHT", 1, 0)
		TotemBar[3]:SetPoint("TOPLEFT", TotemBar[2], "TOPRIGHT", 1, 0)
		TotemBar[4]:SetPoint("TOPLEFT", TotemBar[3], "TOPRIGHT", 1, 0)
		TotemBar[4]:SetPoint("BOTTOMRIGHT", TotemBar, "BOTTOMRIGHT", 0, 0)
		
		self.TotemBar = TotemBar
	end

	--------------------------------------------------------------------------------------------------
	--		RuneBar
	--------------------------------------------------------------------------------------------------
	if (class == "DEATHKNIGHT") then
		local RuneBar = new(self)
		
		for i = 1, 6 do
			RuneBar[i] = CreateFrame("StatusBar", nil, RuneBar)
			RuneBar[i]:SetSize((self:GetWidth() - 5) / 6, settings.classbarsize)
			RuneBar[i]:SetStatusBarTexture(gUI:GetStatusBarTexture())
			RuneBar[i].shine = F.Shine:New(RuneBar[i], nil, nil, 3)
			RuneBar[i]:HookScript("OnValueChanged", function(self, value) 
				if (value == 1) then 
					self.shine:Start() 
				end
			end)

			gUI:SetUITemplate(RuneBar[i], "gloss")
			-- gUI:SetUITemplate(RuneBar[i], "shade")
		
			RuneBar[i].Background = RuneBar[i]:CreateTexture(nil, "BORDER")
			RuneBar[i].Background:SetTexture(gUI:GetStatusBarTexture())
			RuneBar[i].Background:SetPoint("TOP", RuneBar[i], "TOP", 0, 1)
			RuneBar[i].Background:SetPoint("BOTTOM", RuneBar[i], "BOTTOM", 0, -1)
			RuneBar[i].Background:SetPoint("RIGHT", RuneBar[i], "RIGHT", 1, 0)
			RuneBar[i].Background:SetPoint("LEFT", RuneBar[i], "LEFT", -1, 0)
			RuneBar[i].Background:SetVertexColor(0, 0, 0, 1)

			RuneBar[i].bg = RuneBar[i]:CreateTexture(nil, "BORDER")
			RuneBar[i].bg:SetAllPoints(RuneBar[i])
			RuneBar[i].bg:SetTexture(gUI:GetStatusBarTexture())
			RuneBar[i].bg.multiplier = 1/3
		end
		
		RuneBar[1]:SetPoint("TOPLEFT", RuneBar, "TOPLEFT", 0, 0)
		RuneBar[2]:SetPoint("TOPLEFT", RuneBar[1], "TOPRIGHT", 1, 0)
		RuneBar[3]:SetPoint("TOPLEFT", RuneBar[2], "TOPRIGHT", 1, 0)
		RuneBar[4]:SetPoint("TOPLEFT", RuneBar[3], "TOPRIGHT", 1, 0)
		RuneBar[5]:SetPoint("TOPLEFT", RuneBar[4], "TOPRIGHT", 1, 0)
		RuneBar[6]:SetPoint("TOPLEFT", RuneBar[5], "TOPRIGHT", 1, 0)
		RuneBar[6]:SetPoint("BOTTOMRIGHT", RuneBar, "BOTTOMRIGHT", 0, 0)
		
		self.RuneBar = RuneBar
	end

	--------------------------------------------------------------------------------------------------
	--		EclipseBar
	--------------------------------------------------------------------------------------------------
	if (class == "DRUID") then
		local EclipseBar = new(self)
		EclipseBar:SetSize(self:GetWidth(), settings.classbarsize + 1)
		
		EclipseBar.bg = EclipseBar:CreateTexture(nil, "BORDER")
		EclipseBar.bg:SetTexture(gUI:GetStatusBarTexture())
		EclipseBar.bg:SetAllPoints(EclipseBar)
		EclipseBar.bg:SetVertexColor(0, 0, 0, 1)
		
		EclipseBar.LunarBar = CreateFrame("StatusBar", nil, EclipseBar)
		EclipseBar.LunarBar:SetPoint("LEFT", EclipseBar, "LEFT", 0, 0)
		EclipseBar.LunarBar:SetPoint("TOP", EclipseBar, "TOP", 0, -1)
		EclipseBar.LunarBar:SetPoint("BOTTOM", EclipseBar, "BOTTOM", 0, 0)
		EclipseBar.LunarBar:SetWidth(EclipseBar:GetWidth())
		EclipseBar.LunarBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
		EclipseBar.LunarBar:SetStatusBarColor(C.PowerBarColor["ECLIPSE"].negative.r, C.PowerBarColor["ECLIPSE"].negative.g, C.PowerBarColor["ECLIPSE"].negative.b, 1)
		
		EclipseBar.SolarBar = CreateFrame("StatusBar", nil, EclipseBar)
		EclipseBar.SolarBar:SetPoint("LEFT", EclipseBar.LunarBar:GetStatusBarTexture(), "RIGHT", 0, 0)
		EclipseBar.SolarBar:SetPoint("TOP", EclipseBar, "TOP", 0, -1)
		EclipseBar.SolarBar:SetPoint("BOTTOM", EclipseBar, "BOTTOM", 0, 0)
		EclipseBar.SolarBar:SetWidth(EclipseBar:GetWidth())
		EclipseBar.SolarBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
		EclipseBar.SolarBar:SetStatusBarColor(C.PowerBarColor["ECLIPSE"].positive.r, C.PowerBarColor["ECLIPSE"].positive.g, C.PowerBarColor["ECLIPSE"].positive.b, 1)		

		local power = UnitPower(unit, SPELL_POWER_ECLIPSE)
		local maxPower = UnitPowerMax(unit, SPELL_POWER_ECLIPSE)
		EclipseBar.LunarBar:SetMinMaxValues(-maxPower, maxPower)
		EclipseBar.LunarBar:SetValue(power)
		EclipseBar.SolarBar:SetMinMaxValues(-maxPower, maxPower)
		EclipseBar.SolarBar:SetValue(power * -1)

		gUI:SetUITemplate(EclipseBar.SolarBar, "gloss", EclipseBar)
		-- gUI:SetUITemplate(EclipseBar.SolarBar, "shade", EclipseBar)

		EclipseBar.Text = EclipseBar.SolarBar:CreateFontString()
		EclipseBar.Text:SetShown(unitDB.showPower)
		EclipseBar.Text:SetFontObject(gUI_UnitFrameFont14)
		EclipseBar.Text:SetPoint("BOTTOMLEFT", self.Health, 2, 1)
		EclipseBar.Text:SetTextColor(1, 1, 1, 1)
		
		local directionArrow = EclipseBar.SolarBar:CreateTexture(nil, "OVERLAY")
		directionArrow:SetSize(24, 24)
		directionArrow:SetTexture([[Interface\PlayerFrame\UI-DruidEclipse]])
		directionArrow:SetBlendMode("ADD")
		EclipseBar.directionArrow = directionArrow

		local PostUpdatePower = function(self, unit)
			local power = UnitPower(unit, SPELL_POWER_ECLIPSE)
			local maxPower = UnitPowerMax(unit, SPELL_POWER_ECLIPSE)
			local direction = GetEclipseDirection()
			self.directionArrow:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS[direction]))
			local x = (power / maxPower) * (self:GetWidth() / 2)
			if (direction == "moon") then
				self.directionArrow:SetPoint("CENTER", self, x + 1, 1)
			elseif (direction == "sun") then
				self.directionArrow:SetPoint("CENTER", self, x - 1, 1)
			else
				self.directionArrow:SetPoint("CENTER", self, x, 1)
			end
		end
		EclipseBar.PostUpdatePower = PostUpdatePower
		
		local shine = F.Shine:New(EclipseBar)
		EclipseBar.Shine = shine
		local PostDirectionChange = function(self, unit)
			self.Shine:Start()
		end
		EclipseBar.PostDirectionChange = PostDirectionChange
		
		self:Tag(EclipseBar.Text, "[pereclipse]%")
		
		self.EclipseBar = EclipseBar
	end

	--------------------------------------------------------------------------------------------------
	--		Warlocks
	--------------------------------------------------------------------------------------------------
	if (class == "WARLOCK") then
		-- destruction
		do
			local BurningEmbers = new(self)
			
			local max = 4
			for i = 1, max do
				BurningEmbers[i] = CreateFrame("StatusBar", nil, BurningEmbers)
				BurningEmbers[i]:SetSize((self:GetWidth() - (max - 1)) / max, settings.classbarsize)
				BurningEmbers[i]:SetStatusBarTexture(gUI:GetStatusBarTexture())
				BurningEmbers[i]:SetStatusBarColor(C.PowerBarColor.BURNING_EMBERS.r, C.PowerBarColor.BURNING_EMBERS.g, C.PowerBarColor.BURNING_EMBERS.b, 1)
				BurningEmbers[i]:SetMinMaxValues(0, MAX_POWER_PER_EMBER)
				BurningEmbers[i]:SetValue(0)
				BurningEmbers[i].shine = F.Shine:New(BurningEmbers[i], nil, nil, 3)
				BurningEmbers[i]:HookScript("OnValueChanged", function(self, value) 
					if (value == MAX_POWER_PER_EMBER) then 
						self.shine:Start() 
					end
				end)	
				
				gUI:SetUITemplate(BurningEmbers[i], "gloss")
				-- gUI:SetUITemplate(BurningEmbers[i], "shade")
				
				BurningEmbers[i].bg = BurningEmbers[i]:CreateTexture(nil, "BORDER")
				BurningEmbers[i].bg:SetTexture(gUI:GetStatusBarTexture())
				BurningEmbers[i].bg:SetPoint("TOP", BurningEmbers[i], "TOP", 0, 1)
				BurningEmbers[i].bg:SetPoint("BOTTOM", BurningEmbers[i], "BOTTOM", 0, 0)
				BurningEmbers[i].bg:SetPoint("RIGHT", BurningEmbers[i], "RIGHT", 1, 0)
				BurningEmbers[i].bg:SetPoint("LEFT", BurningEmbers[i], "LEFT", -1, 0)
				BurningEmbers[i].bg:SetVertexColor(C.PowerBarColor.BURNING_EMBERS.r/3, C.PowerBarColor.BURNING_EMBERS.g/3, C.PowerBarColor.BURNING_EMBERS.b/3, 1)

				if (i == 1) then
					BurningEmbers[i]:SetPoint("TOPLEFT", BurningEmbers, "TOPLEFT", 0, 0)
				elseif (i == max) then
					BurningEmbers[i]:SetPoint("BOTTOMRIGHT", BurningEmbers, "BOTTOMRIGHT", 0, 0)
				else
					BurningEmbers[i]:SetPoint("LEFT", BurningEmbers[i - 1], "RIGHT", 1, 0)
				end
			end
			self.BurningEmbers = BurningEmbers
		end
		
		-- affliction
		do
			local SoulShards = new(self)
			
			local max = 4
			for i = 1, max do
				SoulShards[i] = CreateFrame("StatusBar", nil, SoulShards)
				SoulShards[i]:SetSize((self:GetWidth() - (max - 1)) / max, settings.classbarsize)
				SoulShards[i]:SetStatusBarTexture(gUI:GetStatusBarTexture())
				SoulShards[i]:SetStatusBarColor(C.PowerBarColor.SOUL_SHARDS.r, C.PowerBarColor.SOUL_SHARDS.g, C.PowerBarColor.SOUL_SHARDS.b, 1)
				SoulShards[i]:SetMinMaxValues(0, 1)
				SoulShards[i]:SetValue(0)
				SoulShards[i].shine = F.Shine:New(SoulShards[i], nil, nil, 3)
				SoulShards[i]:HookScript("OnValueChanged", function(self, value) 
					if (value == 1) then 
						self.shine:Start() 
					end
				end)
				
				gUI:SetUITemplate(SoulShards[i], "gloss")
				-- gUI:SetUITemplate(SoulShards[i], "shade")
				
				SoulShards[i].bg = SoulShards[i]:CreateTexture(nil, "BORDER")
				SoulShards[i].bg:SetTexture(gUI:GetStatusBarTexture())
				SoulShards[i].bg:SetPoint("TOP", SoulShards[i], "TOP", 0, 1)
				SoulShards[i].bg:SetPoint("BOTTOM", SoulShards[i], "BOTTOM", 0, 0)
				SoulShards[i].bg:SetPoint("RIGHT", SoulShards[i], "RIGHT", 1, 0)
				SoulShards[i].bg:SetPoint("LEFT", SoulShards[i], "LEFT", -1, 0)
				SoulShards[i].bg:SetVertexColor(C.PowerBarColor.SOUL_SHARDS.r/3, C.PowerBarColor.SOUL_SHARDS.g/3, C.PowerBarColor.SOUL_SHARDS.b/3, 1)

				if (i == 1) then
					SoulShards[i]:SetPoint("TOPLEFT", SoulShards, "TOPLEFT", 0, 0)
				elseif (i == max) then
					SoulShards[i]:SetPoint("BOTTOMRIGHT", SoulShards, "BOTTOMRIGHT", 0, 0)
				else
					SoulShards[i]:SetPoint("LEFT", SoulShards[i - 1], "RIGHT", 1, 0)
				end
			end
			self.SoulShards = SoulShards
		end
		
		-- demonology
		do
			local DemonicFury = CreateFrame("StatusBar", nil, new(self))
			DemonicFury:SetAllPoints()
			DemonicFury:SetStatusBarTexture(gUI:GetStatusBarTexture())
			DemonicFury:SetStatusBarColor(C.PowerBarColor.DEMONIC_FURY.r, C.PowerBarColor.DEMONIC_FURY.g, C.PowerBarColor.DEMONIC_FURY.b, 1)
			gUI:SetUITemplate(DemonicFury, "gloss")
			-- gUI:SetUITemplate(DemonicFury, "shade")

			local DemonicFuryTopLine = DemonicFury:CreateTexture(nil, "OVERLAY")
			DemonicFuryTopLine:SetPoint("LEFT", DemonicFury)
			DemonicFuryTopLine:SetPoint("RIGHT", DemonicFury)
			DemonicFuryTopLine:SetPoint("BOTTOM", DemonicFury, "TOP")
			DemonicFuryTopLine:SetHeight(1)
			DemonicFuryTopLine:SetTexture(unpack(C["background"]))

			local DemonicFuryBackground = DemonicFury:CreateTexture(nil, "BACKGROUND")
			DemonicFuryBackground:SetAllPoints(DemonicFury)
			DemonicFuryBackground:SetTexture(gUI:GetStatusBarTexture())
			DemonicFuryBackground:SetVertexColor(C.PowerBarColor.DEMONIC_FURY.r/3, C.PowerBarColor.DEMONIC_FURY.g/3, C.PowerBarColor.DEMONIC_FURY.b/3)
			
			local DemonicFuryValue = self.Power:CreateFontString()
			DemonicFuryValue:SetShown(unitDB.showPower)
			DemonicFuryValue:SetFontObject(gUI_UnitFrameFont14)
			DemonicFuryValue:ClearAllPoints()
			DemonicFuryValue:SetPoint("BOTTOMLEFT", self.Health, 2, 1)
			DemonicFuryValue:SetJustifyH("LEFT")
			DemonicFuryValue.frequentUpdates = 1/4
			self.DemonicFuryValue = DemonicFuryValue

			self:Tag(DemonicFuryValue, "[gUI™ demonicfury]")

			self.DemonicFury = DemonicFury
		end
	end
	
	--------------------------------------------------------------------------------------------------
	--		Priests
	--------------------------------------------------------------------------------------------------
	if (class == "PRIEST") then
		-- SPELL_POWER_SHADOW_ORBS
		local ShadowOrbs = new(self)
		
		local max = PRIEST_BAR_NUM_ORBS
		for i = 1, max do
			ShadowOrbs[i] = CreateFrame("StatusBar", nil, ShadowOrbs)
			ShadowOrbs[i]:SetSize((self:GetWidth() - (max - 1)) / max, settings.classbarsize)
			ShadowOrbs[i]:SetStatusBarTexture(gUI:GetStatusBarTexture())
			ShadowOrbs[i]:SetStatusBarColor(C.PowerBarColor.SHADOW_ORBS.r, C.PowerBarColor.SHADOW_ORBS.g, C.PowerBarColor.SHADOW_ORBS.b, 1)
			ShadowOrbs[i]:SetMinMaxValues(0, 1)
			ShadowOrbs[i]:SetValue(0)
			ShadowOrbs[i].shine = F.Shine:New(ShadowOrbs[i], nil, nil, 3)
			ShadowOrbs[i]:HookScript("OnValueChanged", function(self, value) 
				if (value == 1) then 
					self.shine:Start() 
				end
			end)
			
			gUI:SetUITemplate(ShadowOrbs[i], "gloss")
			-- gUI:SetUITemplate(ShadowOrbs[i], "shade")
			
			ShadowOrbs[i].bg = ShadowOrbs[i]:CreateTexture(nil, "BORDER")
			ShadowOrbs[i].bg:SetTexture(gUI:GetStatusBarTexture())
			ShadowOrbs[i].bg:SetPoint("TOP", ShadowOrbs[i], "TOP", 0, 1)
			ShadowOrbs[i].bg:SetPoint("BOTTOM", ShadowOrbs[i], "BOTTOM", 0, 0)
			ShadowOrbs[i].bg:SetPoint("RIGHT", ShadowOrbs[i], "RIGHT", 1, 0)
			ShadowOrbs[i].bg:SetPoint("LEFT", ShadowOrbs[i], "LEFT", -1, 0)
			ShadowOrbs[i].bg:SetVertexColor(C.PowerBarColor.SHADOW_ORBS.r/3, C.PowerBarColor.SHADOW_ORBS.g/3, C.PowerBarColor.SHADOW_ORBS.b/3)

			if (i == 1) then
				ShadowOrbs[i]:SetPoint("TOPLEFT", ShadowOrbs, "TOPLEFT", 0, 0)
			elseif (i == max) then
				ShadowOrbs[i]:SetPoint("BOTTOMRIGHT", ShadowOrbs, "BOTTOMRIGHT", 0, 0)
			else
				ShadowOrbs[i]:SetPoint("LEFT", ShadowOrbs[i - 1], "RIGHT", 1, 0)
			end
		end
		self.ShadowOrbs = ShadowOrbs
	end

	--------------------------------------------------------------------------------------------------
	--		Monk Chi!
	--------------------------------------------------------------------------------------------------
	if (class == "MONK") then
		local LightForce = new(self)

		local MAX_HARMONY = 5
		for i = 1, MAX_HARMONY do
			LightForce[i] = CreateFrame("StatusBar", nil, LightForce)
			LightForce[i]:SetSize((self:GetWidth() - (MAX_HARMONY - 1)) / MAX_HARMONY, settings.classbarsize)
			LightForce[i]:SetStatusBarTexture(gUI:GetStatusBarTexture())
			LightForce[i]:SetStatusBarColor(unpack(C.Chi[i]))
			LightForce[i]:SetMinMaxValues(0, 1)
			LightForce[i]:SetValue(0)
			LightForce[i].shine = F.Shine:New(LightForce[i], nil, nil, 3)
			LightForce[i]:HookScript("OnValueChanged", function(self, value) 
				if (value == 1) then 
					self.shine:Start() 
				end
			end)

			gUI:SetUITemplate(LightForce[i], "gloss")
			-- gUI:SetUITemplate(LightForce[i], "shade")

			LightForce[i].bg = LightForce[i]:CreateTexture(nil, "BORDER")
			LightForce[i].bg:SetTexture(gUI:GetStatusBarTexture())
			LightForce[i].bg:SetPoint("TOP", LightForce[i], "TOP", 0, 1)
			LightForce[i].bg:SetPoint("BOTTOM", LightForce[i], "BOTTOM", 0, 0)
			LightForce[i].bg:SetPoint("RIGHT", LightForce[i], "RIGHT", 1, 0)
			LightForce[i].bg:SetPoint("LEFT", LightForce[i], "LEFT", -1, 0)
			LightForce[i].bg:SetVertexColor(C.Chi[i][1]/3, C.Chi[i][2]/3, C.Chi[i][3]/3, 1)

			if i == 1 then
				LightForce[i]:SetPoint("TOPLEFT", LightForce, "TOPLEFT", 0, 0)
			elseif i == MAX_HARMONY then
				LightForce[i]:SetPoint("BOTTOMRIGHT", LightForce, "BOTTOMRIGHT", 0, 0)
			else
				LightForce[i]:SetPoint("LEFT", LightForce[i - 1], "RIGHT", 1, 0)
			end
		end
		self.LightForce = LightForce
	end

	--------------------------------------------------------------------------------------------------
	--		Holy Power
	--------------------------------------------------------------------------------------------------
	if (class == "PALADIN") then
		local HolyPower = new(self)

		local HOLY_POWER_FULL = 5 -- can get 5 at level 85
		for i = 1, HOLY_POWER_FULL do
			HolyPower[i] = CreateFrame("StatusBar", nil, HolyPower)
			HolyPower[i]:SetSize((self:GetWidth() - (HOLY_POWER_FULL - 1)) / HOLY_POWER_FULL, settings.classbarsize)
			HolyPower[i]:SetStatusBarTexture(gUI:GetStatusBarTexture())
			HolyPower[i]:SetStatusBarColor(C.PowerBarColor.HOLY_POWER.r, C.PowerBarColor.HOLY_POWER.g, C.PowerBarColor.HOLY_POWER.b, 1)
			HolyPower[i]:SetMinMaxValues(0, 1)
			HolyPower[i]:SetValue(0)
			HolyPower[i].shine = F.Shine:New(HolyPower[i], nil, nil, 3)
			HolyPower[i]:HookScript("OnValueChanged", function(self, value) 
				if (value == 1) then 
					self.shine:Start() 
				end
			end)
			
			gUI:SetUITemplate(HolyPower[i], "gloss")
			-- gUI:SetUITemplate(HolyPower[i], "shade")

			HolyPower[i].bg = HolyPower[i]:CreateTexture(nil, "BORDER")
			HolyPower[i].bg:SetTexture(gUI:GetStatusBarTexture())
			HolyPower[i].bg:SetPoint("TOP", HolyPower[i], "TOP", 0, 1)
			HolyPower[i].bg:SetPoint("BOTTOM", HolyPower[i], "BOTTOM", 0, 0)
			HolyPower[i].bg:SetPoint("RIGHT", HolyPower[i], "RIGHT", 1, 0)
			HolyPower[i].bg:SetPoint("LEFT", HolyPower[i], "LEFT", -1, 0)
			HolyPower[i].bg:SetVertexColor(C.PowerBarColor.HOLY_POWER.r/3, C.PowerBarColor.HOLY_POWER.g/3, C.PowerBarColor.HOLY_POWER.b/3, 1)

			if i == 1 then
				HolyPower[i]:SetPoint("TOPLEFT", HolyPower, "TOPLEFT", 0, 0)
			elseif i == HOLY_POWER_FULL then
				HolyPower[i]:SetPoint("BOTTOMRIGHT", HolyPower, "BOTTOMRIGHT", 0, 0)
			else
				HolyPower[i]:SetPoint("LEFT", HolyPower[i - 1], "RIGHT", 1, 0)
			end
		end
		self.HolyPower = HolyPower
	end

	--------------------------------------------------------------------------------------------------
	--		CombatFeedback
	--------------------------------------------------------------------------------------------------
	local CombatFeedbackText = self.InfoFrame:CreateFontString()
	CombatFeedbackText:SetFontObject(gUI_UnitFrameFont22)
	CombatFeedbackText:SetPoint("CENTER", Portrait)
	CombatFeedbackText.colors = C["feedbackcolors"]
	
	self.CombatFeedbackText = CombatFeedbackText

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
	AuraHolder:SetShown(unitDB.showPlayerAuras)
	self.AuraHolder = AuraHolder
	
	local Auras = CreateFrame("Frame", nil, self.AuraHolder)
	-- Auras:SetFrameStrata(self:GetFrameStrata())
	-- Auras:SetFrameLevel(self:GetFrameLevel() - 1)
	Auras:ClearAllPoints()
	Auras:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 3, 3)
	Auras:SetSize(settings.aura.width * settings.aura.size + (settings.aura.width - 1) * settings.aura.gap, settings.aura.height * settings.aura.size + (settings.aura.height - 1) * settings.aura.gap)

	Auras.size = settings.aura.size
	Auras.spacing = settings.aura.gap

	Auras.initialAnchor = "BOTTOMRIGHT"
	Auras["growth-y"] = "UP"
	Auras["growth-x"] = "LEFT"
	
	Auras.CustomFilter = F.CustomAuraFilter
	Auras.PostUpdateIcon = F.PostUpdateAura
	Auras.PostCreateIcon = F.PostCreateAura

	local force = function(parent, self)
		self["UNIT_AURA"](self, "UNIT_AURA", "player")
	end
	local set = function(self)
		module:ScheduleTimer(1/3, force, self)
	end
	self:RegisterEvent("PLAYER_REGEN_ENABLED", set)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", set)

	self.Auras = Auras
end

module.PostUpdateSettings = function(self, event, ...)
	if not _STATE then return end
	if unitDB.showEmbeddedClassBar then
		_STATE:SetAlpha(1)
	else
		_STATE:SetAlpha(0)
	end
end 

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	unitDB = self:GetParent():GetCurrentOptionsSet()
	
	oUF:RegisterStyle(style, Style)
	oUF:Factory(function(self)
		self:SetActiveStyle(style)

		local frame = self:Spawn("player")
		frame:SetParent(gUI:GetAttribute("parent"))

		module:PlaceAndSave(frame, L["Player"], db.pos, unpack(defaults.pos))
		module:AddObjectToFrameGroup(frame, "unitframes")		
		module:PostUpdateSettings()
	end)
end

module.OnEnable = function(self)
	
end

module.OnDisable = function(self)
end