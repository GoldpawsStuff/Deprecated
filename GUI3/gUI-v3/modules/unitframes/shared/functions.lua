--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...
local oUF = ns.oUF or oUF 

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local _G = _G
local strfind, gsub, strupper = string.find, string.gsub, string.upper
local pairs, select, unpack = pairs, select, unpack
local tinsert, tremove = table.insert, table.remove
local setmetatable = setmetatable
local rawget = rawget

local CreateFrame = CreateFrame
local GetNetStats = GetNetStats
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidTargetIndex = GetRaidTargetIndex
local GetSpellInfo = GetSpellInfo
local IsControlKeyDown = IsControlKeyDown
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitIsGroupAssistant = UnitIsGroupAssistant
local IsShiftKeyDown = IsShiftKeyDown
local SetRaidTarget = SetRaidTarget
local ToggleDropDownMenu = ToggleDropDownMenu
local UnitAura = UnitAura
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists
local UnitIsFriend = UnitIsFriend
local UnitIsConnected= UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible
local UnitPlayerControlled = UnitPlayerControlled
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitThreatSituation = UnitThreatSituation

local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors")
local F = gUI:GetDataBase("functions")
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local unitframes = gUI:GetModule("Unitframes")
local R = unitframes:GetDataBase("auras")
local RaidGroups = unitframes:GetDataBase("raidgroups")
local UnitFrames = unitframes:GetDataBase("unitframes")
local ORD = ns.oUF_RaidDebuffs or oUF_RaidDebuffs

local unitIsPlayer = { player = true, pet = true, vehicle = true }

-- don't mix stuff here, or you'll end up with multiple raid frames at once
local visibility = {
	-- never show
	hide = "custom hide";
	
	-- 2-5 player group frames
	party1to5 = "custom [@raid6,exists] hide; show";

	-- 10 player styled frames, vertical display, sorted from top to bottom
	raid2to10 = "custom [@raid11,exists] hide; [@raid2,exists][@party1,exists] show; hide";
	raid6to10 = "custom [@raid11,exists] hide; [@raid6,exists] show; hide";

	-- 15 player styled battleground frames, vertical display, sorted from top to bottom
	 raid2to15 = "custom [@raid16,exists] hide; [@raid2,exists][@party1,exists] show; hide";
	 raid6to15 = "custom [@raid16,exists] hide; [@raid6,exists] show; hide";
	
	-- 40 player styled gridlike frames, sorted horizontally by player, vertically by group (if full groups), starts at the topleft
	raid2to40 = "custom [@raid2,exists][@party1,exists] show; hide"; -- will display for all groups with 2 or more members
	raid6to40 = "custom [@raid6,exists] show; hide"; -- will display for raids with 6 or more players 
	raid11to40 = "custom [@raid11,exists] show; hide"; -- will display for raids with 11 or more players 
	raid16to40 = "custom [@raid16,exists] show; hide"; -- will display for raids with 16 or more players
}

-- returns the visibility macro conditionals for the given header type
-- this needs to fire on the following events to be accurate:
-- 	PLAYER_ALIVE, ACTIVE_TALENT_GROUP_CHANGED, PLAYER_TALENT_UPDATE, TALENTS_INVOLUNTARILY_RESET 
F.GetHeaderVisibility = function(type)
	if not(type) then return end
	
	local driver
	local isHealer = F.IsPlayerHealer()
	local db = unitframes:GetCurrentOptionsSet()
	local useRaidForParty = db.showRaidFramesInParty -- indicates that same frames should be used for party as for 6-15p raids
	local useLargeRaidForSmallRaid = db.showGridFramesAlways -- indicates that same frames should be used for 6-15p raids as 16-40p raids
	local useHealerLayout = db.useGridFrames -- indicates that grid/healer frames should be used for 16-40p raid
	local useSpecLayout = db.autoSpec -- indicates that the frames should be automatically decided based on player role

	if (type == "party") then 
		if (useRaidForParty) then
			driver = visibility.hide -- hide the party frames when we have chose to use the raid frames instead
		else
			driver = visibility.party1to5 -- use party frames
		end
	elseif (type == "raid10") then
		if (useLargeRaidForSmallRaid) then
			driver = visibility.hide -- hide the small raid frames when we have chose to use the large raid frames for all raids
		else
			if (useRaidForParty) then
				driver = visibility.raid2to15 -- use these frames for small raids and party
			else
				driver = visibility.raid6to15 -- use these frames for small raids, but not party
			end
		end
	elseif (type == "raid40dps") then
		if (useSpecLayout) then -- base visibility on player role
			if (isHealer) then 
				driver = visibility.hide -- hide these frames if the player is a healer
			else
				if (useLargeRaidForSmallRaid) then
					if (useRaidForParty) then
						driver = visibility.raid2to40 -- use these frames for all raids, and party
					else
						driver = visibility.raid6to40 -- use these frames for all raids, but not party
					end
				else
					driver = visibility.raid16to40 -- use these frames only for large raids
				end
			end
		else
			if (useHealerLayout) then
				driver = visibility.hide -- hide these frames when grid/healer frames are manually chosen
			else
				if (useLargeRaidForSmallRaid) then
					if (useRaidForParty) then
						driver = visibility.raid2to40 -- use these frames for all raids, and party
					else
						driver = visibility.raid6to40 -- use these frames for all raids, but not party
					end
				else
					driver = visibility.raid16to40 -- use these frames only for large raids
				end
			end
		end
	elseif (type == "raid40grid") then
		if (useSpecLayout) then
			if (isHealer) then
				if (useLargeRaidForSmallRaid) then
					if (useRaidForParty) then
						driver = visibility.raid2to40 -- use these frames for all raids, and party
					else
						driver = visibility.raid6to40 -- use these frames for all raids, but not party
					end
				else
					driver = visibility.raid16to40 -- use these frames only for large raids
				end
			else
				driver = visibility.hide
			end
		else
			if (useHealerLayout) then
				if (useLargeRaidForSmallRaid) then
					if (useRaidForParty) then
						driver = visibility.raid2to40 -- use these frames for all raids, and party
					else
						driver = visibility.raid6to40 -- use these frames for all raids, but not party
					end
				else
					driver = visibility.raid16to40 -- use these frames only for large raids
				end
			else
				driver = visibility.hide -- hide these frames when tiny/dps frames are manually chosen
			end
		end
	end
	return driver
end

-- update the visibility of all group (raid/party) frames according to stored settings
F.updateAllVisibility = function()
	local Raid10, Raid40DPS, Raid40GRID = RaidGroups["10"], RaidGroups["40DPS"], RaidGroups["40GRID"]
	if (F.combatAbort(true)) then 
		return 
	end
	
	if (GUIS_Party) then 
		F.changeVisibilityAttributeDriver(GUIS_Party, F.GetHeaderVisibility("party"))
	end
	
	if (Raid10) then
		F.changeVisibilityAttributeDriver(Raid10, F.GetHeaderVisibility("raid10"))
	end
	
	if (Raid40DPS) then
		F.changeVisibilityAttributeDriver(Raid40DPS, F.GetHeaderVisibility("raid40dps"))
	end
	
	if (Raid40GRID) then
		F.changeVisibilityAttributeDriver(Raid40GRID, F.GetHeaderVisibility("raid40grid"))
	end
end

-- returns true and prints out an error message if in combat
F.combatAbort = function(silent)
	if (InCombatLockdown()) then
		if not silent then 
			print(L["UnitFrames cannot be configured while engaged in combat"])
		end
		return true
	end
end

-- change the visibility conditionals of the given header
F.changeVisibilityAttributeDriver = function(header, visibility)
	if (F.combatAbort()) then return end
	
	local type, list = strsplit(" ", visibility, 2)
	if (list) and (type == "custom") then
		UnregisterAttributeDriver(header, "state-visibility")
		RegisterAttributeDriver(header, "state-visibility", list)
	end 
end

F.UpdateAuraFilter = function(self)
	local auras = self.Auras
	
	if (auras) and (auras.__owner) and (self == auras.__owner) and (auras.__owner.unit) then
		auras:ForceUpdate()
	end
end

-- decide the spacing between the Minimappanels and the group frames based on screen height
F.GetGroupSpacing = function()
	local h = GetScreenHeight() or 0
	
	return (h > 990) and 40 or (h > 890) and 20 or (h == 0) and 20 or 0
end

F.UnitFrameMenu = function(self)
	if (self.unit == "targettarget") or (self.unit == "focustarget") or (self.unit == "pettarget") then
		return
	end
	
	local unit = self.unit:gsub("(.)", strupper, 1)

	if _G[unit.."FrameDropDown"] then
		ToggleDropDownMenu(1, nil, _G[unit.."FrameDropDown"], "cursor")
		return
		
	elseif (self.unit:match("party")) then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
		return
		
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
	end
end

-- get rid of stuff we don't want from the dropdown menus
-- * this appears to be causing taint for elements other than set/clear focus
-- * blizzard added fixes/secure menus for 3rd party frames in 5.2?
-- do 
	-- local UnWanted = {
		-- ["SET_FOCUS"] = true;
		-- ["CLEAR_FOCUS"] = true;
	-- }
	-- for id,menu in pairs(UnitPopupMenus) do
		-- for index, option in pairs(UnitPopupMenus[id]) do
			-- if (UnWanted[option]) then
				-- tremove(UnitPopupMenus[id], index)
			-- end
		-- end
	-- end
-- end

-- attempt to replace the default raid target icons from unitmenus
-- *will have to see if this taints them
-- do
	-- for i = 1,8 do
		-- UnitPopupButtons["RAID_TARGET_" .. i].icon = M("Icon", "RaidTarget")
	-- end
-- end

-- our magic ReverseBar, which is horizontal mirror image of 'normal' bars
do
	local PostUpdateHealth = function(self, unit, min, max)
		if (UnitIsDeadOrGhost(unit)) then 
			self:SetValue(0) 
		end
	end

	local OnUpdate = function(Updater)
		Updater:Hide()
		local bar = Updater:GetParent()
		local min, max = bar:GetMinMaxValues()
		local value = bar:GetValue()
		local tex = bar:GetStatusBarTexture()
		
		-- 4.3 fix
		local size = ((max) and (max > 0)) and (max - value)/max or 1
		
		tex:ClearAllPoints()
		tex:SetPoint("BOTTOMRIGHT")
		tex:SetPoint("TOPLEFT", bar, "TOPLEFT", size * bar:GetWidth(), 0)
	end
	
	local OnChanged = function(bar)
		bar.Updater:Show()
	end

	F.ReverseBar = function(self, noPostUpdate)
		local bar = CreateFrame("StatusBar", nil, self)
		bar.Updater = CreateFrame("Frame", nil, bar)
		bar.Updater:Hide()
		bar.Updater:SetScript("OnUpdate", OnUpdate)
		bar:SetScript("OnSizeChanged", OnChanged)
		bar:SetScript("OnValueChanged", OnChanged)
		bar:SetScript("OnMinMaxChanged", OnChanged)
		
		if not(noPostUpdate) then
			bar.PostUpdate = PostUpdateHealth
		end
		
		return bar
	end
end

F.PostCreateAura = function(element, button)
	gUI:SetUITemplate(button, "backdrop")
	-- gUI:CreateUIShadow(button)

	button.icon:ClearAllPoints()
	button.icon:SetPoint("TOP", button, 0, -3)
	button.icon:SetPoint("RIGHT", button, -3, 0)
	button.icon:SetPoint("BOTTOM", button, 0, 3)
	button.icon:SetPoint("LEFT", button, 3, 0)
	button.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	button.icon:SetDrawLayer("ARTWORK")
	
	button.count:SetFontObject(gUI_DisplayFontTinyOutlineWhite)

	local layer, subLayer = button.icon:GetDrawLayer()
	
	gUI:SetUITemplate(button, "shade", button.icon)
	gUI:SetUITemplate(button, "gloss", button.icon)
	
	button.shade = button.Shade
	button.gloss = button.Gloss
	
	button.cd:SetReverse()
	button.cd:SetAllPoints(button.icon)

	button.overlay:SetTexture("")
end

F.PostUpdateAura = function(element, unit, button, index)
	local name, _, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unit, index, button.filter)
	if (unit == "player") then
		if (unitIsPlayer[unitCaster]) then
			button:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
			button.icon:SetDesaturated(false)
		elseif (isBossDebuff) then
			local color = DebuffTypeColor[debuffType] 
			if not(color) or not(color.r) or not(color.g) or not(color.b) then
				color = { r = 0.7, g = 0, b = 0 }
			end
			button:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			if (unitCaster == "vehicle") then
				button:SetBackdropBorderColor(0, 3/4, 0, 1)
			else
				if (color) and (color.r) and (color.g) and (color.b) then
					button:SetBackdropBorderColor(color.r, color.g, color.b)
				else
					button:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				end
			end
		end
	
	elseif (unit == "target") then
		-- desaturate auras not cast by the player or a boss
		-- color borders by magic type if cast by the player or a boss
		if (unitIsPlayer[unitCaster]) or (isBossDebuff) then
			local color = DebuffTypeColor[debuffType] 
			if (color) and (color.r) and (color.g) and (color.b) then
				button:SetBackdropBorderColor(color.r, color.g, color.b)
			else
				button:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
			end
			button.icon:SetDesaturated(false)
		else
			if (unitCaster == "vehicle") then
				button:SetBackdropBorderColor(0, 3/4, 0, 1)
			else
				button:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
			end
			local db = unitframes:GetCurrentOptionsSet()
			if (db.desaturateNonPlayerAuras) then
				button.icon:SetDesaturated(true)
			end
		end
	else
		if (unitCaster == "vehicle") then
			button:SetBackdropBorderColor(0, 3/4, 0, 1)
		else
			if (isBossDebuff) then
				local color = DebuffTypeColor[debuffType] or { r = 0.7, g = 0, b = 0 }
				button:SetBackdropBorderColor(color.r, color.g, color.b)
			else
				button:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
			end
		end
	end
end

F.SetAuraWatchSpell = function(auras, spellInfo, aurasize)
	local spellID, point, color, anyUnit = unpack(spellInfo)
	aurasize = aurasize or 2

	local icon = CreateFrame("Frame", nil, auras)
	icon.spellID = spellID
	icon.anyUnit = anyUnit
	icon:SetWidth(6 * aurasize)
	icon:SetHeight(6 * aurasize)
	icon:SetPoint(point, 0, 0)

	local tex = icon:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints(icon)
	tex:SetTexture(gUI:GetBlankTexture())
	
	if (color) then
		tex:SetVertexColor(unpack(color))
	else
		tex:SetVertexColor(0.8, 0.8, 0.8)
	end

	local count = icon:CreateFontString(nil, "OVERLAY")
	count:SetFontObject(gUI_UnitFrameFont10)
	count:SetPoint("CENTER", unpack(R.AuraIndicatorOffsets[point]))
	icon.count = count

	auras.icons[spellID] = icon
end

F.CreateTargetBorder = function(self, unit)
	local TargetBorder = CreateFrame("Frame", nil, ((unit == "party") or (unit == "raid")) and self:GetParent() or self)
	TargetBorder:Hide()
	TargetBorder:SetPoint("TOPLEFT", self, -5, 5)
	TargetBorder:SetPoint("BOTTOMRIGHT", self, 5, -5)
	TargetBorder.parent = self
	gUI:SetUITemplate(TargetBorder, "targetborder")
	
	self.TargetBorder = TargetBorder

	TargetBorder:RegisterEvent("PLAYER_TARGET_CHANGED")
	TargetBorder:RegisterEvent("GROUP_ROSTER_UPDATE")
	TargetBorder:RegisterEvent("PLAYER_REGEN_DISABLED")
	TargetBorder:SetScript("OnEvent", function(self, event, ...) F.PostUpdateTargetBorder(self.parent, event, ...) end) 

	F.PostUpdateTargetBorder(self)
	
	return TargetBorder
end

F.PostUpdateTargetBorder = function(self, event, arg1)
	local TargetBorder = self.TargetBorder
	if not(TargetBorder) then
		return 
	end
	if (self.unit) and (UnitIsUnit(self.unit, "target")) and (self:IsShown()) then
		TargetBorder:Show()
	else
		TargetBorder:Hide()
	end
end

F.ThreatOverride = function(self, event, unit)
	if (unit ~= self.unit) then return end

	unit = unit or self.unit
	local status = UnitThreatSituation(unit)

	if (status and status > 0) then
		local r, g, b = GetThreatStatusColor(status)
		self.FrameBorder:SetBackdropBorderColor(r * 5/5, g * 5/5, b * 5/5, 0.75)
		gUI:SetUIShadowColor(self.FrameBorder, r * 1/3, g * 1/3, b * 1/3, 0.75)
	else
		self.FrameBorder:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
		gUI:SetUIShadowColor(self.FrameBorder, C["shadow"][1], C["shadow"][2], C["shadow"][3], 0.75)
	end
	
	if (not self.FrameBorder:IsShown()) then
		self.FrameBorder:Show()
	end
end

-- worgen faces. not worgen crotches.
F.PostPortraitUpdate = function(self, unit)
	if (self:GetModel()) and (self:GetModel().find) and (self:GetModel():lower():find("worgenmale")) then
		self:SetCamera(1)
	end
end
	
-- Hide portraits when not available, instead of having a big weird questionmark
F.HidePortrait = function(self, unit)
	if (self.unit == "target") then
		if (not UnitExists(self.unit)) or (not UnitIsConnected(self.unit)) or (not UnitIsVisible(self.unit)) then
			self.Portrait:SetAlpha(0)
			if (self.Portrait.Border) then
				self.Portrait.Border:SetAlpha(0)
			end
		else
			F.PostUpdatePortrait(self.Portrait, unit)
		end
	end
end

-- Update the portrait alpha
F.PostUpdatePortrait = function(self, unit)
	self:SetAlpha(0)
	self:SetAlpha(1)
	if (self.Border) then
		self.Border:SetAlpha(1)
	end
	F.PostPortraitUpdate(self, unit)
end

-- set focus shortcuts
do
	local focusModifier = { [1] = "shift-", [2] = "ctrl-", [3] = "alt-", [4] = "*" }
	
	F.GetFocusMacroKey = function()
		local db = unitframes:GetCurrentOptionsSet()
		return focusModifier[db.focusKey] .. "type" .. db.focusButton
	end

	F.GetFocusMacroString = function()
		return ([[self:SetAttribute("%s", "macro")]]):format(F.GetFocusMacroKey())
	end
	
	F.ResetAllFocusMacros = function(self)
		if (InCombatLockdown()) or not(self) then return end
		for i = 1,#focusModifier do
			for mouse = 1, 31 do
				self:SetAttribute(focusModifier[i] .. "-type" .. mouse, nil)
			end
		end
	end
	
	F.PostUpdateFocusMacro = function(self, unit)
		self, unit = self, self.unit or unit
		if (InCombatLockdown()) or not(self) or not(unit) then return end
		F.ResetAllFocusMacros(self)
		local db = unitframes:GetCurrentOptionsSet()
		if (db.shiftToFocus) then
			if (unit == "focus") then
				self:SetAttribute(F.GetFocusMacroKey(), "macro")
				self:SetAttribute("macrotext", "/clearfocus")
			else
				self:SetAttribute(F.GetFocusMacroKey(), "focus")
			end
		end
	end
end

-- apply the function 'func' with arguments ... to all registered unitframes
F.ApplyToAllUnits = function(func, ...)
	for name, frame in pairs(UnitFrames) do
		func(frame, ...)
	end
end

-- callback for option updates
F.PostUpdateOptions = function(self, unit)
	self, unit = self, self.unit or unit
	if not(self) or not(unit) then return end
	local db = unitframes:GetCurrentOptionsSet()
	if (self.healthValue) then self.healthValue:SetShown(db.showHealth) end
	if (self.powerValue) then self.powerValue:SetShown(db.showPower) end
	if (self.DruidManaValue) then self.DruidManaValue:SetShown(db.showPower) end
	if (self.AltPowerValue) then self.AltPowerValue:SetShown(db.showPower) end
	if (self.EclipseBar) then self.EclipseBar.Text:SetShown(db.showPower) end
	if (self.DemonicFuryValue) then self.DemonicFuryValue:SetShown(db.showPower) end
	if (self.GUISIndicators) then self.GUISIndicators:SetShown(db.showGridIndicators) end
	if (self.AuraHolder) and ((unit == "player") or (unit == "target")) then
		if (unit == "player") then
			self.AuraHolder:SetShown(db.showPlayerAuras)
		elseif (unit == "target") then
			self.AuraHolder:SetShown(db.showTargetAuras)
		end
	end
end

F.AllFrames = function(self, unit, nonInteractive, noShadow)
	-- store our frames in a global table
	UnitFrames[self:GetName()] = self
	
	-- clicks and hoverscripts
	if not(nonInteractive) then
		if (unit) then
			self:RegisterForClicks("AnyUp")
			self:SetScript("OnEnter", UnitFrame_OnEnter)
			self:SetScript("OnLeave", UnitFrame_OnLeave)
			
			-- set the focus macros
			-- party/raid do this in their secure headers
			if not(unit:find("party")) and not(unit:find("raid")) then
				F.PostUpdateFocusMacro(self, unit)
			end

			-- right-click menu
			-- self.menu = F.UnitFrameMenu

			-- Threat
			-- Yeah, a little hackish. Deal with it.
			self.Threat = {
				Hide = noop;
				IsObjectType = noop;
				Override = F.ThreatOverride;
			}
		end
	end
	
	-- colors
	self.colors = C.oUF

	-- texts and other info
	local InfoFrame = CreateFrame("Frame", nil, self)
	InfoFrame:SetFrameLevel(30)
	self.InfoFrame = InfoFrame

	-- icons
	local IconFrame = CreateFrame("Frame", nil, self)
	IconFrame:SetFrameLevel(60)
	self.IconFrame = IconFrame

	-- Frame borders and shadows
	if not(noShadow) then
		self.FrameBorder = gUI:SetUITemplate(self, "outerbackdrop")
		self.FrameBorder:SetBackdropColor(0,0,0,gUI:GetPanelAlpha())
		gUI:CreateUIShadow(self.FrameBorder)
	end
end

