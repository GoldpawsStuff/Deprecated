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
local module = unitframes:NewModule("Arena")
local R = unitframes:GetDataBase("auras")
local UnitFrames = module:NewDataBase("unitframes")


local setmetatable, rawget = setmetatable, rawget
local unpack, select, tinsert = unpack, select, table.insert

local L, C, F, M, db, unitDB
local RealFrames, PrepFrames
local MAX_ARENA_ENEMIES = 5 -- not a global until Blizzard_ArenaUI is loaded. and it won't. ever.

local settings = {
	size = { 168, 36 };
	iconSize = 16;
	portraitSize = { 36, 36 };
	healthBarSize = { 120, 11};
	powerBarSize = { 120, 4};
	trinketSize = { 24, 24 };
}	

local defaults = {
	pos = { "LEFT", "UIParent", "CENTER", 320, 0 };
}

--------------------------------------------------------------------------------------------------
--		Prep Frames
--------------------------------------------------------------------------------------------------
local PostUpdatePrepFrame = function(self)
	if (self.spec) and (self.class) then
		local color = C.RAID_CLASS_COLORS[self.class]
		self.Name:SetText(self.spec .. " - |c" .. color.colorStr .. LOCALIZED_CLASS_NAMES_MALE[self.class] .. "|r")
		self.Health:SetStatusBarColor(color.r, color.g, color.b)
	end
	if (self.icon) then
		SetPortraitToTexture(self.Portrait, self.icon)
	end
end

local UpdatePrepFrames = function(self)
	local numOpps = GetNumArenaOpponentSpecs()
	if (numOpps > 0) then
		local frame
		local id, spec, description, icon, background, role, class
		for i = 1, MAX_ARENA_ENEMIES do
			frame = _G["GUIS_ArenaPrep"..i]
			if (i <= numOpps) then 
				local specID = GetArenaOpponentSpec(i) -- http://www.wowpedia.org/API_GetInspectSpecialization
				if (specID > 0) then 
					id, spec, description, icon, background, role, class = GetSpecializationInfoByID(specID)
					frame.class = class
					frame.spec = spec
					frame.role = role
					frame.icon = icon
					frame:PostUpdate()
					frame:Show()
				else
					frame:Hide()
				end
			else
				frame:Hide()
			end
		end
	else
		local frame
		for i = 1, MAX_ARENA_ENEMIES do
			frame = _G["GUIS_ArenaPrep"..i]
			frame:Hide()
		end
	end
end

PrepFrames = function(self)
	-- colors
	self.colors = C.oUF

	-- texts and other info
	local InfoFrame = CreateFrame("Frame", nil, self)
	InfoFrame:SetFrameLevel(30)
	self.InfoFrame = InfoFrame

	-- Frame borders and shadows
	self.FrameBorder = gUI:SetUITemplate(self, "outerbackdrop")
	gUI:CreateUIShadow(self.FrameBorder)
	
	--------------------------------------------------------------------------------------------------
	--		Health
	--------------------------------------------------------------------------------------------------
	local Health = F.ReverseBar(self)
	Health:SetSize(settings.healthBarSize[1], settings.healthBarSize[2] + 1 + settings.powerBarSize[2])
	Health:SetPoint("BOTTOMLEFT", 0, 0)
	Health:SetStatusBarTexture(gUI:GetStatusBarTexture())
	Health:SetMinMaxValues(0, 1)
	Health:SetValue(1)
	gUI:SetUITemplate(Health, "gloss")
	-- gUI:SetUITemplate(Health, "shade")
	self.Health = Health

	--------------------------------------------------------------------------------------------------
	--		Texts and Values
	--------------------------------------------------------------------------------------------------
	local Name = self.InfoFrame:CreateFontString()
	Name:SetFontObject(gUI_UnitFrameFont14)
	Name:SetTextColor(1, 1, 1)
	-- Name:SetSize(settings.size[1] - 40, (select(2, Name:GetFont())))
	Name:SetJustifyH("RIGHT")
	Name:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, 8)
	self.Name = Name

	--------------------------------------------------------------------------------------------------
	--		Portrait
	--------------------------------------------------------------------------------------------------
	local PortraitHolder = CreateFrame("Frame", nil, self)
	PortraitHolder:SetSize(unpack(settings.portraitSize))
	PortraitHolder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)

	PortraitHolder.Border = gUI:SetUITemplate(PortraitHolder, "outerbackdrop")
	gUI:CreateUIShadow(PortraitHolder.Border)
		
	-- local Portrait = CreateFrame("PlayerModel", nil, PortraitHolder)
	local Portrait = PortraitHolder:CreateTexture(nil, "ARTWORK")
	Portrait:SetAllPoints(PortraitHolder)
	Portrait:SetAlpha(1)
	Portrait.Border = PortraitHolder.Border
	
	Portrait.Shade = PortraitHolder:CreateTexture(nil, "OVERLAY")
	Portrait.Shade:SetTexture(0, 0, 0, 1/2)
	Portrait.Shade:SetPoint("TOPLEFT", -1, 1)
	Portrait.Shade:SetPoint("BOTTOMRIGHT", 1, -1)

	Portrait.Overlay = PortraitHolder:CreateTexture(nil, "OVERLAY")
	Portrait.Overlay:SetTexture(M("Background", "gUI™ UnitShader"))
	Portrait.Overlay:SetVertexColor(0, 0, 0, 1)
	Portrait.Overlay:SetAllPoints(Portrait.Shade)

	self.Portrait = Portrait
	
	-- reposition border
	self.FrameBorder:ClearAllPoints()
	self.FrameBorder:SetPoint("TOPLEFT", self.Health, "TOPLEFT", -3, 3)
	self.FrameBorder:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMRIGHT", 3, -3)
end

--------------------------------------------------------------------------------------------------
--		Real Frames
--------------------------------------------------------------------------------------------------
RealFrames = function(self, unit)
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
	--		Icons
	--------------------------------------------------------------------------------------------------
	local RaidIcon = self.IconFrame:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(settings.iconSize, settings.iconSize)
	RaidIcon:SetPoint("CENTER", self.Health, "TOP", 0, 4)
	RaidIcon:SetTexture(M("Icon", "RaidTarget"))

	self.RaidIcon = RaidIcon
	
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
	
	--------------------------------------------------------------------------------------------------
	--		PvP Trinkets
	--------------------------------------------------------------------------------------------------
	local PvPTrinket = CreateFrame("Frame", nil, self)
	PvPTrinket:SetSize(unpack(settings.trinketSize))
	PvPTrinket:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -12, 0)
	PvPTrinket.trinketUseAnnounce = true
	PvPTrinket.trinketUpAnnounce = true
		
	PvPTrinket.Border = gUI:SetUITemplate(PvPTrinket, "outerbackdrop")
	gUI:CreateUIShadow(PvPTrinket.Border)

	self.PvPTrinket = PvPTrinket
	
	-- reposition border
	self.FrameBorder:ClearAllPoints()
	self.FrameBorder:SetPoint("TOPLEFT", self.Health, "TOPLEFT", -3, 3)
	self.FrameBorder:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMRIGHT", 3, -3)
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	unitDB = self:GetParent():GetCurrentOptionsSet()
	
	oUF:RegisterStyle(addon.."Arena", RealFrames)
	oUF:Factory(function(self)
		self:SetActiveStyle(addon.."Arena")
		
		local w, h = settings.size[1], settings.size[2]*MAX_ARENA_ENEMIES + 20*(MAX_ARENA_ENEMIES-1)
		local arena = CreateFrame("Frame", "GUIS_Arena", gUI:GetAttribute("parent"))
		arena:SetFrameStrata("LOW")
		arena:SetFrameLevel(1)
		arena:SetSize(w, h)

		module:PlaceAndSave(arena, L["Arena"], db.pos, unpack(defaults.pos))
		module:AddObjectToFrameGroup(arena, "unitframes")

		for i = 1, MAX_ARENA_ENEMIES do
			arena[i] = oUF:Spawn("arena"..i, "GUIS_Arena" .. i)
			arena[i]:SetParent(gUI:GetAttribute("parent"))
			if (i == 1) then
				arena[i]:SetPoint("TOPRIGHT", arena, "TOPRIGHT", 0, 0)
			else
				arena[i]:SetPoint("TOPRIGHT", arena[i - 1], "BOTTOMRIGHT", 0, -20)
			end
			arena[i]:SetSize(unpack(settings.size))
		end
		
		-- welcome to another episode in "Let's Dumb Down Our Skills!"
		local arenaPrep = CreateFrame("Frame", "GUIS_ArenaPrep", gUI:GetAttribute("parent"))
		arenaPrep:Hide()
		
		for i = 1, MAX_ARENA_ENEMIES do
			arenaPrep[i] = CreateFrame("Frame", "GUIS_ArenaPrep" .. i, arenaPrep)
			arenaPrep[i]:Hide()
			arenaPrep[i]:SetAllPoints(arena[i])
			arenaPrep[i]:SetSize(unpack(settings.size))
			arenaPrep[i].PostUpdate = PostUpdatePrepFrame
			PrepFrames(arenaPrep[i])
		end
		
		arenaPrep.UpdatePrepFrames = UpdatePrepFrames
		arenaPrep.OnEvent = function(self, event, ...) 
			if (event == "PLAYER_ENTERING_WORLD") then
				local numOpps = GetNumArenaOpponentSpecs()
				if (numOpps and numOpps > 0) then
					self:OnEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
				end
			elseif (event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS") then
				self:UpdatePrepFrames()
				self:Show()
			elseif (event == "ARENA_OPPONENT_UPDATE") then	
				local frame
				for i = 1, MAX_ARENA_ENEMIES do
					frame = _G["GUIS_ArenaPrep" .. i]
					frame:Hide()
				end
				self:Hide()
			end
		end
		
		arenaPrep:SetScript("OnEvent", arenaPrep.OnEvent)
		arenaPrep:RegisterEvent("PLAYER_ENTERING_WORLD")
		arenaPrep:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
		arenaPrep:RegisterEvent("ARENA_OPPONENT_UPDATE")
	end)
end

module.OnEnable = function(self)
end

module.OnDisable = function(self)
end