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
local module = unitframes:NewModule("Raid")
local R = unitframes:GetDataBase("auras")
local RaidGroups = unitframes:GetDataBase("raidgroups")

local _G = _G
local setmetatable, rawget = setmetatable, rawget
local unpack, select, tinsert = unpack, select, table.insert
local tonumber = tonumber
local strsplit = string.split

local CreateFrame = CreateFrame

local L, C, F, M, db, unitDB
local Shared, HideBlizzard
local Raid10, Raid15, Raid25, Raid40, Raid40Small

local class = (select(2, UnitClass("player")))
local dispelFilter = ({
    DRUID = { Magic = true, Curse = true, Poison = true },
    MAGE = { Curse = true },
	MONK = { Magic = true, Poison = true, Disease = true },
    PALADIN = { Magic = true, Poison = true, Disease = true },
    PRIEST = { Magic = true, Disease = true },
    SHAMAN = { Magic = true, Curse = true },
})[select(2, UnitClass("player"))]

local dispelPrio = {
	["Magic"] = 4,
	["Curse"] = 3,
	["Disease"] = 2,
	["Poison"] = 1,
}

local settings = {
	-- using this for 10-15. this is the slim narrow format
	raid10 = {
		size = { 96, 16 };
		powerbarsize = 2;
		iconsize = 12;
		aura = { 
			size = 16;
			gap = 4;
			height = 1;
			width = 6;
		};
		columnSpacing = 8;
		maxColumns = 15;
		unitsPerColumn = 1;
		point = "LEFT";
		columnAnchorPoint = "TOP";
		groupBy = "GROUP";
		groupFilter = "1,2,3,4,5,6,7,8";
		groupingOrder = "1,2,3,4,5,6,7,8";
		showSolo = false;
	};

	-- this is 16-40 for healers
	raid40 = {
		size = { 64, 36 };
		powerbarsize = 2;
		iconsize = 12;
		maxColumns = 8;
		unitsPerColumn = 5;
		point = "LEFT";
		columnAnchorPoint = "TOP";
		groupBy = "GROUP";
		groupFilter = "1,2,3,4,5,6,7,8";
		groupingOrder = "1,2,3,4,5,6,7,8";
		showSolo = false;
	};
	
	-- this is 16-40 tiny DPS layout
	raid40small = {
		size = { 64, 8 };
		powerbarsize = 1;
		iconsize = 12;
		maxColumns = 2; 
		unitsPerColumn = 20;
		columnSpacing = 56;
		point = "TOP";
		columnAnchorPoint = "LEFT";
		groupBy = "GROUP";
		groupFilter = "1,2,3,4,5,6,7,8";
		groupingOrder = "1,2,3,4,5,6,7,8";
		showSolo = false;
	};
}

local defaults = {
	frames = {
		raid10 = {
			pos = { "LEFT", "UIParent", "LEFT", 12, 0 }; -- "TOPLEFT", "UIParent", "TOPLEFT", 12, -250
		};
		raid40 = {
			pos = { "LEFT", "UIParent", "LEFT", 12, 0 }; -- "TOPLEFT", "UIParent", "TOPLEFT", 12, -250
		};
		raid40small = {
			pos = { "LEFT", "UIParent", "LEFT", 12, 0 }; -- "TOPLEFT", "UIParent", "TOPLEFT", 12, -250
		};
	};
	
}

local iconList = {
	["default"] = "[gUI™ leader][gUI™ masterlooter][gUI™ maintank][gUI™ mainassist]";
}
setmetatable(iconList, { __index = function(t, i) return rawget(t, i) or rawget(t, "default") end })

--------------------------------------------------------------------------------------------------
--		Shared Frame Styles
--------------------------------------------------------------------------------------------------
Shared = function(self, unit, info, noPower)
	F.AllFrames(self, unit)
	F.CreateTargetBorder(self, unit)
	
	--------------------------------------------------------------------------------------------------
	--		Power
	--------------------------------------------------------------------------------------------------
	if not(noPower) then
		local Power = CreateFrame("StatusBar", nil, self)
		Power:SetHeight(info.powerbarsize)
		Power:SetPoint("BOTTOM", 0, 0)
		Power:SetPoint("LEFT", 0, 0)
		Power:SetPoint("RIGHT", 0, 0)
		Power:SetStatusBarTexture(gUI:GetStatusBarTexture())
		gUI:SetUITemplate(Power, "gloss")
		-- gUI:SetUITemplate(Power, "shade")
		
		local PowerBackground = Power:CreateTexture(nil, "BACKGROUND")
		PowerBackground:SetAllPoints(Power)
		PowerBackground:SetTexture(gUI:GetStatusBarTexture())

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
	end

	--------------------------------------------------------------------------------------------------
	--		Health
	--------------------------------------------------------------------------------------------------
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetStatusBarTexture(gUI:GetStatusBarTexture())
	if (noPower) then
		Health:SetAllPoints(self)
	else
		Health:SetPoint("TOP", 0, 0)
		Health:SetPoint("BOTTOM", self.Power, "TOP", 0, 1)
		Health:SetPoint("LEFT", 0, 0)
		Health:SetPoint("RIGHT", 0, 0)
	end
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
	--		IconFrame
	--------------------------------------------------------------------------------------------------
	local RaidIcon = self.IconFrame:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(info.iconsize, info.iconsize)
	RaidIcon:SetPoint("CENTER", self, "TOP", 0, 0)
	RaidIcon:SetTexture(M("Icon", "RaidTarget"))

	self.RaidIcon = RaidIcon

	local IconStack = self.IconFrame:CreateFontString()
	IconStack:SetFontObject(gUI_UnitFrameFont12)
	IconStack:SetTextColor(1, 1, 1)
	IconStack:SetJustifyH("LEFT")
	IconStack:SetJustifyV("TOP")
	IconStack:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0) 
	
	self.IconStack = IconStack

	self:Tag(self.IconStack, iconList[unit])
	
	local ReadyCheck = self.IconFrame:CreateTexture(nil, "OVERLAY")
	ReadyCheck:SetPoint("CENTER", self, "CENTER", 0, 0)
	ReadyCheck:SetSize(16, 16)

	self.ReadyCheck = ReadyCheck
	
	--------------------------------------------------------------------------------------------------
	--		Range
	--------------------------------------------------------------------------------------------------
	local Range = {
		insideAlpha = 1.0;
		outsideAlpha = 0.3;
	}
	self.Range = Range
end

--------------------------------------------------------------------------------------------------
--		Raid10
--------------------------------------------------------------------------------------------------
Raid10 = function(self, unit)
	
	Shared(self, unit, settings.raid10)

	--------------------------------------------------------------------------------------------------
	--		Texts and Values
	--------------------------------------------------------------------------------------------------
	local Name = self.InfoFrame:CreateFontString()
	Name:SetFontObject(gUI_UnitFrameFont12) -- gUI_UnitFrameFont14 for old 10p frames
	Name:SetTextColor(1, 1, 1)
	Name:SetSize(self:GetWidth() - 40, (select(2, Name:GetFont())))
	Name:SetJustifyH("LEFT")
	Name:SetPoint("LEFT", self.Health, "LEFT", 3, 0)

	self:Tag(Name, "[gUI™ grouprole][gUI™ name]")

	self.Name = Name
	
	local healthValue = self.InfoFrame:CreateFontString()
	healthValue:SetShown(unitDB.showHealth)
	healthValue:SetFontObject(gUI_UnitFrameFont12)
	healthValue:SetPoint("RIGHT", self.Health, "RIGHT", -3, 0)
	healthValue:SetJustifyH("RIGHT")
	healthValue.frequentUpdates = 1/4

	self:Tag(healthValue, "[gUI™ health]")
	
	self.healthValue = healthValue
	
	--------------------------------------------------------------------------------------------------
	--		Auras
	--------------------------------------------------------------------------------------------------
	local AuraHolder = CreateFrame("Frame", nil, self)
	self.AuraHolder = AuraHolder
	
	local Auras = CreateFrame("Frame", nil, self.AuraHolder)
	Auras:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", 8, 0)
	Auras:SetSize(settings.raid10.aura.width * settings.raid10.aura.size + (settings.raid10.aura.width - 1) * settings.raid10.aura.gap, settings.raid10.aura.height * settings.raid10.aura.size + (settings.raid10.aura.height - 1) * settings.raid10.aura.gap)
	Auras.size = settings.raid10.aura.size
	Auras.spacing = settings.raid10.aura.gap
	Auras.numDebuffs = settings.raid10.aura.width * settings.raid10.aura.height
	Auras.numBuffs = settings.raid10.aura.width * settings.raid10.aura.height

	Auras.initialAnchor = "BOTTOMLEFT"
	Auras["growth-y"] = "UP"
	Auras["growth-x"] = "RIGHT"
	Auras.onlyShowPlayer = false
	
	Auras.buffFilter = "HELPFUL RAID PLAYER"
	Auras.debuffFilter = "HARMFUL"

	Auras.PostUpdateIcon = F.PostUpdateAura
	Auras.PostCreateIcon = F.PostCreateAura

	self.Auras = Auras

	--------------------------------------------------------------------------------------------------
	--		Raid Debuffs
	--------------------------------------------------------------------------------------------------
	local RaidDebuffs = CreateFrame("Frame", nil, self.InfoFrame)
	local debuffSize = min(unpack(settings.raid10.size)) + 10
	
	RaidDebuffs:SetSize(debuffSize, debuffSize)
	RaidDebuffs:SetPoint("CENTER", self)
	gUI:SetUITemplate(RaidDebuffs, "backdrop")
	
	RaidDebuffs.icon = RaidDebuffs:CreateTexture(nil, "OVERLAY")
	RaidDebuffs.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	RaidDebuffs.icon:SetPoint("TOP", RaidDebuffs, 0, -3)
	RaidDebuffs.icon:SetPoint("RIGHT", RaidDebuffs, -3, 0)
	RaidDebuffs.icon:SetPoint("BOTTOM", RaidDebuffs, 0, 3)
	RaidDebuffs.icon:SetPoint("LEFT", RaidDebuffs, 3, 0)
	RaidDebuffs.icon:SetDrawLayer("ARTWORK")

	RaidDebuffs.cd = CreateFrame("Cooldown", nil, RaidDebuffs)
	RaidDebuffs.cd:SetAllPoints(RaidDebuffs.icon)
	RaidDebuffs.cd:SetReverse(true)

	RaidDebuffs.count = RaidDebuffs:CreateFontString(nil, "OVERLAY")
	RaidDebuffs.count:SetFontObject(gUI_UnitFrameFont10)
	RaidDebuffs.count:SetPoint("BOTTOMRIGHT", RaidDebuffs, "BOTTOMRIGHT", 2, 0)
	RaidDebuffs.count:SetTextColor(unpack(C["value"]))
	
	RaidDebuffs.DispelFilter = dispelFilter
	RaidDebuffs.DispelPriority = dispelPrio
	RaidDebuffs.ShowDispelableDebuff = true
	RaidDebuffs.FilterDispelableDebuff = true
	RaidDebuffs.MatchByspellIDToName = true
	RaidDebuffs.ShowBossDebuff = true
	-- BossDebuffPriority = 0
	
	RaidDebuffs.SetDebuffTypeColor = RaidDebuffs.SetBackdropBorderColor
	RaidDebuffs.Debuffs = R.RaidDebuffs

	local PostUpdate = function(self, event)
		local button = self.RaidDebuffs
		
		-- we don't want those "1"'s cluttering up the display
		if (button) then
			local count = tonumber(button.count:GetText())
			if (count) and (count > 1) then
				f.count:SetText(count)
				f.count:Show()
			else
				f.count:Hide()
			end
		end
	end
	
	gUI:SetUITemplate(RaidDebuffs, "gloss", RaidDebuffs.icon)
	gUI:SetUITemplate(RaidDebuffs, "shade", RaidDebuffs.icon)
	gUI:CreateUIShadow(RaidDebuffs)

	self.RaidDebuffs = RaidDebuffs
	self.RaidDebuffs.PostUpdate = PostUpdate
	
	--------------------------------------------------------------------------------------------------
	--		Grid Indicators
	--------------------------------------------------------------------------------------------------
	local GUISIndicators = CreateFrame("Frame", nil, self.InfoFrame) -- using the InfoFrame to get them top level
	GUISIndicators:SetShown(unitDB.showGridIndicators)
	GUISIndicators:SetPoint("TOPLEFT", self, "TOPLEFT", -4, 4)
	GUISIndicators:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 4, -4)

	GUISIndicators.fontObject = gUI_UnitFrameFont10
	GUISIndicators.width = settings.raid10.size[2]
	GUISIndicators.indicatorSize = 6
	GUISIndicators.symbolSize = 8
	GUISIndicators.frequentUpdates = 1/4
	
	self.GUISIndicators = GUISIndicators
end

--------------------------------------------------------------------------------------------------
--		Raid40
--------------------------------------------------------------------------------------------------
Raid40 = function(self, unit)
	
	Shared(self, unit, settings.raid40)

	--------------------------------------------------------------------------------------------------
	--		Texts and Values
	--------------------------------------------------------------------------------------------------
	local Name = self.InfoFrame:CreateFontString()
	Name:SetFontObject(gUI_UnitFrameFont12)
	Name:SetTextColor(1, 1, 1)
	Name:SetSize(self:GetWidth() - 16, (select(2, Name:GetFont())))
	Name:SetJustifyH("CENTER")
	Name:SetPoint("TOP", self.Health, "TOP", 0, -5)

	self:Tag(Name, "[gUI™ nameshort]")

	self.Name = Name
	
	local healthValue = self.InfoFrame:CreateFontString()
	healthValue:SetShown(unitDB.showHealth)
	healthValue:SetFontObject(gUI_UnitFrameFont12)
	healthValue:SetPoint("BOTTOM", self.Health, "BOTTOM", 0, 3)
	healthValue.frequentUpdates = 1/4

	self:Tag(healthValue, "[gUI™ grouprole][gUI™ healthshort]")
	
	self.healthValue = healthValue

	--------------------------------------------------------------------------------------------------
	--		Raid Debuffs
	--------------------------------------------------------------------------------------------------
	local RaidDebuffs = CreateFrame("Frame", nil, self.InfoFrame)
	local debuffSize = min(unpack(settings.raid40.size)) - 16
	
	RaidDebuffs:SetSize(debuffSize, debuffSize)
	RaidDebuffs:SetPoint("BOTTOM", self, 0, 4)
	gUI:SetUITemplate(RaidDebuffs, "backdrop")
	
	RaidDebuffs.icon = RaidDebuffs:CreateTexture(nil, "OVERLAY")
	RaidDebuffs.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	RaidDebuffs.icon:SetPoint("TOP", RaidDebuffs, 0, -3)
	RaidDebuffs.icon:SetPoint("RIGHT", RaidDebuffs, -3, 0)
	RaidDebuffs.icon:SetPoint("BOTTOM", RaidDebuffs, 0, 3)
	RaidDebuffs.icon:SetPoint("LEFT", RaidDebuffs, 3, 0)
	RaidDebuffs.icon:SetDrawLayer("ARTWORK")

	RaidDebuffs.cd = CreateFrame("Cooldown", nil, RaidDebuffs)
	RaidDebuffs.cd:SetAllPoints(RaidDebuffs.icon)
	RaidDebuffs.cd:SetReverse(true)

	RaidDebuffs.count = RaidDebuffs:CreateFontString(nil, "OVERLAY")
	RaidDebuffs.count:SetFontObject(gUI_UnitFrameFont10)
	RaidDebuffs.count:SetPoint("BOTTOMRIGHT", RaidDebuffs, "BOTTOMRIGHT", 2, 0)
	RaidDebuffs.count:SetTextColor(unpack(C["value"]))
	
	RaidDebuffs.DispelFilter = dispelFilter
	RaidDebuffs.DispelPriority = dispelPrio
	RaidDebuffs.ShowDispelableDebuff = true
	RaidDebuffs.FilterDispelableDebuff = true
	RaidDebuffs.MatchByspellIDToName = true
	RaidDebuffs.ShowBossDebuff = true
	-- BossDebuffPriority = 0
	
	RaidDebuffs.SetDebuffTypeColor = RaidDebuffs.SetBackdropBorderColor
	RaidDebuffs.Debuffs = R.RaidDebuffs

	local PostUpdate = function(self, event)
		local button = self.RaidDebuffs
		
		-- we don't want those "1"'s cluttering up the display
		if (button) then
			local count = tonumber(button.count:GetText())
			if (count) and (count > 1) then
				f.count:SetText(count)
				f.count:Show()
			else
				f.count:Hide()
			end
		end
	end
	
	gUI:SetUITemplate(RaidDebuffs, "gloss", RaidDebuffs.icon)
	gUI:SetUITemplate(RaidDebuffs, "shade", RaidDebuffs.icon)
	gUI:CreateUIShadow(RaidDebuffs)

	self.RaidDebuffs = RaidDebuffs
	self.RaidDebuffs.PostUpdate = PostUpdate

	--------------------------------------------------------------------------------------------------
	--		Grid Indicators
	--------------------------------------------------------------------------------------------------
	local GUISIndicators = CreateFrame("Frame", nil, self.Health)
	GUISIndicators:SetShown(unitDB.showGridIndicators)
	GUISIndicators:SetAllPoints(self.Health)

	GUISIndicators.fontObject = gUI_UnitFrameFont10
	GUISIndicators.width = settings.raid40.size[2]
	GUISIndicators.indicatorSize = 6
	GUISIndicators.symbolSize = 8
	GUISIndicators.frequentUpdates = 1/4
	
	self.GUISIndicators = GUISIndicators
end

Raid40Small = function(self, unit)
	
	Shared(self, unit, settings.raid40small, true)

	--------------------------------------------------------------------------------------------------
	--		Texts and Values
	--------------------------------------------------------------------------------------------------
	local Name = self.InfoFrame:CreateFontString()
	Name:SetFontObject(gUI_UnitFrameFont12)
	Name:SetTextColor(1, 1, 1)
	Name:SetJustifyH("LEFT")
	Name:SetPoint("LEFT", self, "RIGHT", 6, 0)

	self:Tag(Name, "[gUI™ namesmartsize]")

	self.Name = Name
	
	local healthValue = self.InfoFrame:CreateFontString()
	healthValue:SetShown(unitDB.showHealth)
	healthValue:SetFontObject(gUI_UnitFrameFont10)
	healthValue:SetPoint("CENTER", self.Health, "CENTER", 0, 0)
	healthValue.frequentUpdates = 1/4

	self:Tag(healthValue, "[gUI™ healthshort]")
	
	self.healthValue = healthValue
	
	-- I don't like this, but it has to be somewhere
	local groupRoleIcon = self.InfoFrame:CreateFontString()
	groupRoleIcon:SetFontObject(gUI_UnitFrameFont10)
	groupRoleIcon:SetPoint("LEFT", self.Health, "LEFT", 2, 0)
	groupRoleIcon.frequentUpdates = 1/4
		
	self:Tag(groupRoleIcon, "[gUI™ grouprole]")
	
	self.groupRoleIcon = groupRoleIcon

	--------------------------------------------------------------------------------------------------
	--		Raid Debuffs
	--------------------------------------------------------------------------------------------------
	local RaidDebuffs = CreateFrame("Frame", nil, self.InfoFrame)
	local debuffSize = min(unpack(settings.raid40small.size)) + 10
	
	RaidDebuffs:SetSize(debuffSize, debuffSize)
	RaidDebuffs:SetPoint("CENTER", self)
	gUI:SetUITemplate(RaidDebuffs, "backdrop")
	
	RaidDebuffs.icon = RaidDebuffs:CreateTexture(nil, "OVERLAY")
	RaidDebuffs.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	RaidDebuffs.icon:SetPoint("TOP", RaidDebuffs, 0, -3)
	RaidDebuffs.icon:SetPoint("RIGHT", RaidDebuffs, -3, 0)
	RaidDebuffs.icon:SetPoint("BOTTOM", RaidDebuffs, 0, 3)
	RaidDebuffs.icon:SetPoint("LEFT", RaidDebuffs, 3, 0)
	RaidDebuffs.icon:SetDrawLayer("ARTWORK")

	RaidDebuffs.cd = CreateFrame("Cooldown", nil, RaidDebuffs)
	RaidDebuffs.cd:SetAllPoints(RaidDebuffs.icon)
	RaidDebuffs.cd:SetReverse(true)

	RaidDebuffs.count = RaidDebuffs:CreateFontString(nil, "OVERLAY")
	RaidDebuffs.count:SetFontObject(gUI_UnitFrameFont10)
	RaidDebuffs.count:SetPoint("BOTTOMRIGHT", RaidDebuffs, "BOTTOMRIGHT", 2, 0)
	RaidDebuffs.count:SetTextColor(unpack(C["value"]))
	
	RaidDebuffs.DispelFilter = dispelFilter
	RaidDebuffs.DispelPriority = dispelPrio
	RaidDebuffs.ShowDispelableDebuff = true
	RaidDebuffs.FilterDispelableDebuff = true
	RaidDebuffs.MatchByspellIDToName = true
	RaidDebuffs.ShowBossDebuff = true
	-- BossDebuffPriority = 0
	
	RaidDebuffs.SetDebuffTypeColor = RaidDebuffs.SetBackdropBorderColor
	RaidDebuffs.Debuffs = R.RaidDebuffs

	local PostUpdate = function(self, event)
		local button = self.RaidDebuffs
		
		-- we don't want those "1"'s cluttering up the display
		if (button) then
			local count = tonumber(button.count:GetText())
			if (count) and (count > 1) then
				f.count:SetText(count)
				f.count:Show()
			else
				f.count:Hide()
			end
		end
	end
	
	gUI:SetUITemplate(RaidDebuffs, "gloss", RaidDebuffs.icon)
	gUI:SetUITemplate(RaidDebuffs, "shade", RaidDebuffs.icon)
	gUI:CreateUIShadow(RaidDebuffs)

	self.RaidDebuffs = RaidDebuffs
	self.RaidDebuffs.PostUpdate = PostUpdate

	--------------------------------------------------------------------------------------------------
	--		Grid Indicators
	--------------------------------------------------------------------------------------------------
	local GUISIndicators = CreateFrame("Frame", nil, self.Health)
	GUISIndicators:SetShown(unitDB.showGridIndicators)
	GUISIndicators:SetAllPoints(self.Health)

	GUISIndicators.fontObject = gUI_UnitFrameFont10
	GUISIndicators.width = settings.raid40small.size[2]
	GUISIndicators.indicatorSize = 6
	GUISIndicators.symbolSize = 8
	GUISIndicators.onlyBuffs = true
	GUISIndicators.frequentUpdates = 1/4
	
	self.GUISIndicators = GUISIndicators
end

module.PostUpdateSettings = function(self)

end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	unitDB = self:GetParent():GetCurrentOptionsSet()
	
	--------------------------------------------------------------------------------------------------
	--		Register our styles with oUF, and spawn the frames
	--------------------------------------------------------------------------------------------------
	local headerData = {}
	local initialConfigFunction = [[
		self:SetWidth(%d)
		self:SetHeight(%d)
		-- self:SetFrameStrata("LOW")
		%s
	]]
	
	local getHeaderSize = function(info)
		local w, h = unpack(info.size)
		local x, y
		
		if (info.columnAnchorPoint == "TOP") or (info.columnAnchorPoint == "BOTTOM") then
			x = w*info.unitsPerColumn + ( (info.unitsPerColumn-1) * (10) )

			if (info.columnSpacing) then
				y = h*info.maxColumns + (info.maxColumns * info.columnSpacing)
			else
				y = h*info.maxColumns + ((info.maxColumns-1) * 10)
			end
			
		elseif (info.columnAnchorPoint == "LEFT") or (info.columnAnchorPoint == "RIGHT") then
			y = h*info.unitsPerColumn + ((info.unitsPerColumn-1) * 10)
			
			if (info.columnSpacing) then
				x = w*info.maxColumns + (info.maxColumns * info.columnSpacing)
			else
				x = w*info.maxColumns + ((info.maxColumns-1) * 10)
			end
		end

		return x, y
	end

	local getHeaderData = function(db, visibility)
		wipe(headerData)
		
		headerData = {
			db.showSolo and "solo" or F.GetHeaderVisibility(visibility), 
			"oUF-initialConfigFunction", initialConfigFunction:format(db.size[1], db.size[2], F.GetFocusMacroString()), 
			"showRaid", true,
			"showParty", true, 
			"showPlayer", true,	
			"showSolo", db.showSolo, 
			"yOffset", -(db.yOffset or 10), 
			"xoffset", 10, 
			"point", db.point, 
			"groupFilter", db.groupFilter, 
			"groupingOrder", db.groupingOrder, 
			"groupBy", db.groupBy, 
			"maxColumns", db.maxColumns, 
			"unitsPerColumn", db.unitsPerColumn, 
			"columnSpacing", db.columnSpacing or 10, 
			"columnAnchorPoint", db.columnAnchorPoint
		}
		
		return unpack(headerData)
	end
	
	-- we need an extra holder to avoid resizing of the movable anchor,
	-- and also to make the frame a slave of the UIs pet battle hider
	local getHolder = function(header, w, h)
		local holder = CreateFrame("Frame", nil, gUI:GetAttribute("parent"))
		holder:SetFrameStrata("LOW")
		holder:SetFrameLevel(1)
		holder:SetSize(w, h)
		header:SetParent(holder)
		header:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
		return holder, header
	end
	
	-- 2-15 layout
	oUF:RegisterStyle(addon.."10", Raid10)
	oUF:Factory(function(self)
		self:SetActiveStyle(addon.."10")

		local w, h = getHeaderSize(settings.raid10)
		local header = self:SpawnHeader("GUIS_Raid10", nil, getHeaderData(settings.raid10, "raid10"))
		local holder = getHolder(header, w, h)

		module:PlaceAndSave(holder, L["15 Player Raid"], db.frames.raid10.pos, unpack(defaults.frames.raid10.pos))
		module:AddObjectToFrameGroup(holder, "unitframes")
		
		RaidGroups["10"] = header
	end)

	-- 16-40 healer layout
	oUF:RegisterStyle(addon.."40_GRID", Raid40)
	oUF:Factory(function(self)
		self:SetActiveStyle(addon.."40_GRID")
		
		local w, h = getHeaderSize(settings.raid40)
		local header = self:SpawnHeader("GUIS_Raid40", nil, getHeaderData(settings.raid40, "raid40"))
		local holder = getHolder(header, w, h)

		module:PlaceAndSave(holder, L["40 Player Raid Healer"], db.frames.raid40.pos, unpack(defaults.frames.raid40.pos))
		module:AddObjectToFrameGroup(holder, "unitframes")

		RaidGroups["40GRID"] = header
	end)
	
	-- 16-40 dps layout
	oUF:RegisterStyle(addon.."40_DPS", Raid40Small)
	oUF:Factory(function(self)
		self:SetActiveStyle(addon.."40_DPS")
		
		local w, h = getHeaderSize(settings.raid40small)
		local header = self:SpawnHeader("GUIS_Raid40Small", nil, getHeaderData(settings.raid40small, "raid40dps"))
		local holder = getHolder(header, w, h)

		module:PlaceAndSave(holder, L["40 Player Raid DPS"], db.frames.raid40small.pos, unpack(defaults.frames.raid40small.pos))
		module:AddObjectToFrameGroup(holder, "unitframes")

		RaidGroups["40DPS"] = header
	end)
	
end
