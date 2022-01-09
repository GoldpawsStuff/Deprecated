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
local module = unitframes:NewModule("ClassBar")
local style = addon .. "_ClassBar"

local L, C, F, M, db, unitDB
local _STATE, currentState

local _, class = UnitClass("player")
local patch, build, released, toc = GetBuildInfo()
build = tonumber(build)
	
local settings = {
	size = { 210, 16 }
}

local defaults = {
	pos = { "BOTTOM", "UIParent", "BOTTOM", 0, 300 };
}

local new = function(self)
	local frame = CreateFrame("Frame", nil, self)
	frame:SetSize(self:GetSize())
	frame:SetPoint("CENTER", self, "CENTER", 0, 0)
	
	return frame
end

local getSize = function(object, num)
	return (object:GetWidth() - (num - 1) * 1) / num, object:GetHeight()
end

local addStyling = function(self, border)
	if (border) then
		self.FrameBorder = gUI:SetUITemplate(self, "outerbackdrop")
		self.FrameBorder:SetBackdropColor(0,0,0, gUI:GetPanelAlpha())
	end
	gUI:CreateUIShadow(self.FrameBorder or self)
end

local Style = function(self, unit)
	F.AllFrames(self, unit, true, true)

	self:SetFrameStrata("LOW")
	self:SetFrameLevel(5)
	
	-- make sure this frame doesn't react to hover or clicks
	self:RegisterForClicks()
	self:EnableMouse(false)

	self:SetSize(unpack(settings.size))
	
	--------------------------------------------------------------------------------------------------
	--		Combo Points
	--------------------------------------------------------------------------------------------------
	local CPoints = new(self)

	for i = 1, MAX_COMBO_POINTS do
		CPoints[i] = CreateFrame("StatusBar", nil, CPoints)
		CPoints[i]:SetSize(getSize(CPoints, MAX_COMBO_POINTS))
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

		addStyling(CPoints[i])

		if (i == 1) then
			CPoints[i]:SetPoint("TOPLEFT", CPoints, "TOPLEFT", 0, 0)
		elseif (i == MAX_COMBO_POINTS) then
			CPoints[i]:SetPoint("BOTTOMRIGHT", CPoints, "BOTTOMRIGHT", 0, 0)
		else
			CPoints[i]:SetPoint("LEFT", CPoints[i - 1], "RIGHT", 1, 0)
		end
	end

	self.CPoints = CPoints

	-- local overlay = F.Shine:New(CPoints)
	-- overlay:SetAllPoints(CPoints)
	-- CPoints[MAX_COMBO_POINTS].overlay = overlay

	-- CPoints[MAX_COMBO_POINTS]:SetScript("OnShow", function(self) self.overlay:Start() end)
	-- CPoints[MAX_COMBO_POINTS]:SetScript("OnHide", function(self) self.overlay:Hide() end)

	--------------------------------------------------------------------------------------------------
	--		Mage Arcane Charges
	--------------------------------------------------------------------------------------------------
	if (class == "MAGE") then
		local ArcaneCharges = new(self)

		-- patch 5.3 reduced charges to 4
		local ARCANE_CHARGES_FULL = (build >= 16837) and 4 or 6
		for i = 1, ARCANE_CHARGES_FULL do
			ArcaneCharges[i] = CreateFrame("StatusBar", nil, ArcaneCharges)
			ArcaneCharges[i]:SetSize(getSize(ArcaneCharges, ARCANE_CHARGES_FULL))
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
			
			addStyling(ArcaneCharges[i])

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
			TotemBar[i]:SetSize(getSize(TotemBar, 4))
			
			TotemBar[i].StatusBar = CreateFrame("StatusBar", nil, TotemBar[i])
			TotemBar[i].StatusBar:SetSize(getSize(TotemBar, 4))
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
			RuneBar[i]:SetSize(getSize(RuneBar, 6))
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

			addStyling(RuneBar[i])
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
		EclipseBar:SetHeight(self:GetHeight() * 1.5) -- bigger and better
		
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
		EclipseBar.Text:SetDrawLayer("OVERLAY", 1)
		EclipseBar.Text:SetShown(unitDB.showPower)
		EclipseBar.Text:SetFontObject(gUI_UnitFrameFont20)
		EclipseBar.Text:SetPoint("CENTER", EclipseBar)
		EclipseBar.Text:SetTextColor(1, 1, 1, 1)
		
		local directionArrow = EclipseBar.SolarBar:CreateTexture()
		directionArrow:SetDrawLayer("OVERLAY", -1)
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
		
		local moon = CreateFrame("Frame", nil, EclipseBar)
		moon:SetSize(EclipseBar:GetHeight(), EclipseBar:GetHeight())
		moon:SetPoint("RIGHT", EclipseBar, "LEFT", -8, 0)
		moon.texture = moon:CreateTexture(nil, "BACKGROUND")
		moon.texture:SetAllPoints()
		moon.texture:SetTexture([[Interface\Icons\Ability_Druid_Eclipse]])
		moon.texture:SetTexCoord(59/64, 5/64, 5/64, 59/64)
		addStyling(moon, true)
		EclipseBar.moon = moon
	
		local sun = CreateFrame("Frame", nil, EclipseBar)
		sun:SetSize(EclipseBar:GetHeight(), EclipseBar:GetHeight())
		sun:SetPoint("LEFT", EclipseBar, "RIGHT", 8, 0)
		sun.texture = sun:CreateTexture(nil, "BACKGROUND")
		sun.texture:SetAllPoints()
		sun.texture:SetTexture([[Interface\Icons\Ability_Druid_EclipseOrange]])
		sun.texture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		addStyling(sun, true)
		EclipseBar.sun = sun

		local PostUnitAura = function(self, unit)
			if self.hasSolarEclipse then
				local r, g, b = C.PowerBarColor["ECLIPSE"].positive.r, C.PowerBarColor["ECLIPSE"].positive.g, C.PowerBarColor["ECLIPSE"].positive.b
				self.sun.FrameBorder:SetBackdropBorderColor(r, g, b)
				gUI:SetUIShadowColor(self.sun.FrameBorder, r * 1/3, g * 1/3, b * 1/3, 0.75)
				
				self.moon.FrameBorder:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				gUI:SetUIShadowColor(self.moon.FrameBorder, C.shadow[1], C.shadow[2], C.shadow[3], 0.75)
				
			elseif self.hasLunarEclipse then
				local r, g, b = C.PowerBarColor["ECLIPSE"].negative.r, C.PowerBarColor["ECLIPSE"].negative.g, C.PowerBarColor["ECLIPSE"].negative.b
				self.sun.FrameBorder:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				gUI:SetUIShadowColor(self.sun.FrameBorder, C.shadow[1], C.shadow[2], C.shadow[3], 0.75)

				self.moon.FrameBorder:SetBackdropBorderColor(r, g, b)
				gUI:SetUIShadowColor(self.moon.FrameBorder, r * 1/3, g * 1/3, b * 1/3, 0.75)
			else
				self.sun.FrameBorder:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				self.moon.FrameBorder:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				gUI:SetUIShadowColor(self.sun.FrameBorder, C.shadow[1], C.shadow[2], C.shadow[3], 0.75)
				gUI:SetUIShadowColor(self.moon.FrameBorder, C.shadow[1], C.shadow[2], C.shadow[3], 0.75)
			end
		end
		EclipseBar.PostUnitAura = PostUnitAura
		
		local shine = F.Shine:New(EclipseBar)
		EclipseBar.Shine = shine
		local PostDirectionChange = function(self, unit)
			self.Shine:Start()
		end
		EclipseBar.PostDirectionChange = PostDirectionChange
		
		addStyling(EclipseBar, true)
		
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
				BurningEmbers[i]:SetSize(getSize(BurningEmbers, 4))
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

				addStyling(BurningEmbers[i])
				
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
				SoulShards[i]:SetSize(getSize(SoulShards, 4))
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
				
				-- SoulShards[i].bg = SoulShards[i]:CreateTexture(nil, "BORDER")
				-- SoulShards[i].bg:SetTexture(gUI:GetStatusBarTexture())
				-- SoulShards[i].bg:SetPoint("TOP", SoulShards[i], "TOP", 0, 1)
				-- SoulShards[i].bg:SetPoint("BOTTOM", SoulShards[i], "BOTTOM", 0, 0)
				-- SoulShards[i].bg:SetPoint("RIGHT", SoulShards[i], "RIGHT", 1, 0)
				-- SoulShards[i].bg:SetPoint("LEFT", SoulShards[i], "LEFT", -1, 0)
				-- SoulShards[i].bg:SetVertexColor(C.PowerBarColor.SOUL_SHARDS.r/3, C.PowerBarColor.SOUL_SHARDS.g/3, C.PowerBarColor.SOUL_SHARDS.b/3, 1)

				addStyling(SoulShards[i])
				
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

			local DemonicFuryBackground = DemonicFury:CreateTexture(nil, "BACKGROUND")
			DemonicFuryBackground:SetAllPoints()
			DemonicFuryBackground:SetTexture(gUI:GetStatusBarTexture())
			DemonicFuryBackground:SetVertexColor(C.PowerBarColor.DEMONIC_FURY.r/3, C.PowerBarColor.DEMONIC_FURY.g/3, C.PowerBarColor.DEMONIC_FURY.b/3)
			
			local DemonicFuryValue = DemonicFury:CreateFontString(nil, "OVERLAY")
			-- DemonicFuryValue:SetShown(unitDB.showPower)
			DemonicFuryValue:SetFontObject(gUI_UnitFrameFont20)
			DemonicFuryValue:SetPoint("CENTER")
			DemonicFuryValue.frequentUpdates = 1/4
			self.DemonicFuryValue = DemonicFuryValue
			
			addStyling(DemonicFury, true)

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
			ShadowOrbs[i]:SetSize(getSize(ShadowOrbs, max))
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

			addStyling(ShadowOrbs[i])
			
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
			LightForce[i]:SetSize(getSize(LightForce, MAX_HARMONY))
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

			-- LightForce[i].bg = LightForce[i]:CreateTexture(nil, "BORDER")
			-- LightForce[i].bg:SetTexture(gUI:GetStatusBarTexture())
			-- LightForce[i].bg:SetPoint("TOP", LightForce[i], "TOP", 0, 1)
			-- LightForce[i].bg:SetPoint("BOTTOM", LightForce[i], "BOTTOM", 0, 0)
			-- LightForce[i].bg:SetPoint("RIGHT", LightForce[i], "RIGHT", 1, 0)
			-- LightForce[i].bg:SetPoint("LEFT", LightForce[i], "LEFT", -1, 0)
			-- LightForce[i].bg:SetVertexColor(C.Chi[i][1]/3, C.Chi[i][2]/3, C.Chi[i][3]/3, 1)
			
			addStyling(LightForce[i])

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
			HolyPower[i]:SetSize(getSize(HolyPower, HOLY_POWER_FULL))
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

			-- HolyPower[i].bg = HolyPower[i]:CreateTexture(nil, "BORDER")
			-- HolyPower[i].bg:SetTexture(gUI:GetStatusBarTexture())
			-- HolyPower[i].bg:SetPoint("TOP", HolyPower[i], "TOP", 0, 1)
			-- HolyPower[i].bg:SetPoint("BOTTOM", HolyPower[i], "BOTTOM", 0, 0)
			-- HolyPower[i].bg:SetPoint("RIGHT", HolyPower[i], "RIGHT", 1, 0)
			-- HolyPower[i].bg:SetPoint("LEFT", HolyPower[i], "LEFT", -1, 0)
			-- HolyPower[i].bg:SetVertexColor(C.PowerBarColor.HOLY_POWER.r/3, C.PowerBarColor.HOLY_POWER.g/3, C.PowerBarColor.HOLY_POWER.b/3, 1)

			addStyling(HolyPower[i])
			
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

end

module.PostUpdateSettings = function(self, event, ...)
	if unitDB.showFloatingClassBar then 
		if unitDB.showFloatingClassBarAlways then
			_STATE:SetAlpha(1)
		else
			if event == "PLAYER_REGEN_DISABLED" then
				_STATE:SetAlpha(1)
			elseif event == "PLAYER_REGEN_ENABLED" then
				_STATE:SetAlpha(0)
			elseif InCombatLockdown() then
				_STATE:SetAlpha(1)
			else
				_STATE:SetAlpha(0)
			end
		end
	else
		_STATE:SetAlpha(0)
	end
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	unitDB = self:GetParent():GetCurrentOptionsSet()
	
	-- create the statebar
	-- _STATE = CreateFrame("Frame", nil, gUI:GetAttribute("parent"), "SecureHandlerStateTemplate")
	_STATE = CreateFrame("Frame", nil, gUI:GetAttribute("parent"))

	-- save the initial state, and apply it
	-- currentState = getState()
	-- RegisterStateDriver(_STATE, "visibility", currentState)

	oUF:RegisterStyle(style, Style)
	oUF:Factory(function(self)
		self:SetActiveStyle(style)

		local frame = self:Spawn("player")
		frame:SetParent(_STATE)
		-- frame:SetParent(gUI:GetAttribute("parent"))

		module:PlaceAndSave(frame, L["Player Class Bar"], db.pos, unpack(defaults.pos))
		module:AddObjectToFrameGroup(frame, "unitframes")
		module:PostUpdateSettings()
	end)

	self:RegisterEvent("PLAYER_REGEN_DISABLED", module.PostUpdateSettings)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", module.PostUpdateSettings)

end

module.OnEnable = function(self)
	
end

module.OnDisable = function(self)
end