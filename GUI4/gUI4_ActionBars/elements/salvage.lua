local addon = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("Salvage", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local GAB10 = GP_LibStub("LibButtonGUI4-1.0")
local B = GP_LibStub("LibBabble-SubZone-3.0")
local BL = B:GetLookupTable()

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

-- Lua API
local max = math.max
local strlower = string.lower
local tostring = tostring
local setmetatable = setmetatable
local ipairs, select, unpack = ipairs, select, unpack
local tinsert, wipe = table.insert, table.wipe

-- WoW API
local C_Garrison = C_Garrison
local GetInstanceInfo = GetInstanceInfo
local GetItemCount = GetItemCount
local GetLocale = GetLocale
local GetMinimapZoneText = GetMinimapZoneText
local IsInInstance = IsInInstance
local UnitAffectingCombat = UnitAffectingCombat
local UnitFactionGroup = UnitFactionGroup

local ButtonBar = parent.ButtonBar
local Salvage = setmetatable({}, { __index = ButtonBar })
parent.Salvage = Salvage

local T, hasTheme
local gameLocale = GetLocale()
local playerFaction = UnitFactionGroup("player")

local salvageItems = {
	[1] = 114116, -- Bag of Salvaged Goods
	[2] = 114119, -- Crate of Salvage
	[3] = 114120, -- Big Crate of Salvage
	[4] = 139593, -- Sack of Salvaged Goods (Legion)
	[5] = 139594, -- Salvage Crate (Legion)
	[6] = 140590, -- Large Crate of Salvage (Legion)
	[7] = 120301, -- Yellow Follower Armor
	[8] = 120302 -- Yellow Follower Weapon
}

local mineItems = {
	[1] = 118903, -- Preserved Mining Pick
	[2] = 118897 -- Miner's Coffee
}

local garrisonMapID = {
	[1152] = true, -- Horde Garrison Level 1
	[1330] = true, -- Horde Garrison Level 2
	[1153] = true, -- Horde Garrison Level 3
	[1154] = true, -- Horde Garrison Level 4
	[1158] = true, -- Alliance Garrison Level 1
	[1331] = true, -- Alliance Garrison Level 2
	[1159] = true, -- Alliance Garrison Level 3
	[1160] = true, -- Alliance Garrison Level 4
}

-- http://wow.gamepedia.com/BuildingID
local salvageBuildings = {
	[52] = true, -- Salvage Yard Level 1
	[140] = true, -- Salvage Yard Level 2
	[141] = true -- Salvage Yard Level 3
}

local mineBuildings = {
	[61] = true, -- Lunarfall Excavation/Frostwall Mines Level 1
	[62] = true, -- Lunarfall Excavation/Frostwall Mines Level 2
	[63] = true -- Lunarfall Excavation/Frostwall Mines Level 3
}

local MINES = playerFaction == "Horde" and BL["Frostwall Mine"] or BL["Lunarfall Excavation"]
local SALVAGE_YARD = BL["Salvage Yard"]

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		barWidth = 5,
		buttons = 5,
		skin = "Warcraft", 
		skinSize = "large",
		growthX = "RIGHT",
		growthY = "DOWN",
		showMacrotext = false,
		showHotkey = true,
		showEquipped = true,
		showGrid = false,
		flyoutDir = "UP",
		position = {},
		alpha = 1,
		visibility = {
			possess = true,
			overridebar = true,
			vehicleui = true
		}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme()
end

------------------------------------------------------------------------
-- 	Action Bar Template
------------------------------------------------------------------------
function Salvage:ApplySettings()
	ButtonBar.ApplySettings(self)
	-- self:UpdateButtons()
	self:UpdateButtonSettings()
end

function Salvage:UpdateButtonSettings()
end

function Salvage:ApplyVisibilityDriver()
end

function module:Lock()
	self.bar.overlay:StartFadeOut()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	self.bar.overlay:SetAlpha(0)
	self.bar.overlay:Show()
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not self.bar then return end
	updateConfig() 
	self.db.profile.position.point = nil
	self.db.profile.position.y = nil
	self.db.profile.position.x = nil
	self.db.profile.locked = true
	wipe(self.db.profile.position)
	self:ApplySettings()
end

function module:UpdateTheme(_, _, addonName)
	if addonName ~= tostring(parent) then return end
	updateConfig()
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	if not self.bar then return end
	updateConfig() 
	self.bar:ApplySettings()
	self.bar:UpdateLayout()
	-- self.bar:UpdateButtonSettings()
	self.bar:ForAll("Update")
	self:UpdatePosition() 
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.bar then return end
	updateConfig() 
	if self.db.profile.locked then
		self.bar:ClearAllPoints()
		self.bar:SetPoint(T.place("Salvage", self.db.profile.skinSize))
		if not self.db.profile.position.x then
			self.bar:RegisterConfig(self.db.profile.position)
			self.bar:SavePosition()
		end
	else
		self.bar:RegisterConfig(self.db.profile.position)
		if self.db.profile.position.x then
			self.bar:LoadPosition()
		else
			self.bar:ClearAllPoints()
			self.bar:SetPoint(T.place("Salvage", self.db.profile.skinSize))
			self.bar:SavePosition()
			self.bar:LoadPosition()
		end
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Salvage", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	self.fadeManager = parent:GetFadeManager() 
end

function module:UpdateButtonDisplay()
	local numButtons = 0
	local buttonList = self.inSalvageYard and salvageItems or self.inMines and mineItems
	if buttonList then
		for _, itemID in ipairs(buttonList) do
			if GetItemCount(itemID) > 0 then 
				numButtons = numButtons + 1
				for k = 0,14 do
					self.bar.buttons[numButtons]:SetState(k, "item", itemID)
				end
				self.bar.buttons[numButtons]:Show()
			end
		end
	end
	-- hide unused buttons
	if numButtons < #self.bar.buttons then
		for i = numButtons + 1, #self.bar.buttons do
			self.bar.buttons[i]:Hide()
		end
	end
end
module.UpdateButtonDisplay = gUI4:SafeCallWrapper(module.UpdateButtonDisplay)

function module:UpdateBarDisplay()
	local inSalvageYard, inMines
	if self.db.profile.enabled then
		local inGarrison = garrisonMapID[(select(8,GetInstanceInfo()))]
		if inGarrison then
			local buildings = C_Garrison.GetBuildings(LEGION and LE_GARRISON_TYPE_6_0) -- get owned buildings
			for i = 1, #buildings do
				if salvageBuildings[buildings[i].buildingID] and buildings[i].plotID then -- if the building lacks a plot/placement, we don't really have it
					local buildingID, buildingName, texturePrefix, icon, description, rank, currencyID, currencyAmount, goldAmount, timeRequirement, needsPlan, isPreBuilt, possSpecs, upgrades, canUpgrade, isMaxLevel, hasFollowerSlot, knownSpecs, currentSpec, specCooldown, isBeingBuilt, timeStarted, buildDuration, timeRemainingText, canCompleteBuild = C_Garrison.GetOwnedBuildingInfo(buildings[i].plotID)
					if not(isBeingBuilt or canCompleteBuild) then -- make sure the building isn't currently being built or upgraded
						hasSalvageYard = true
					end
				end
				if mineBuildings[buildings[i].buildingID] then -- mines don't have a plotID! none of the "static" ones have
					local buildingID, buildingName, texturePrefix, icon, description, rank, currencyID, currencyAmount, goldAmount, timeRequirement, needsPlan, isPreBuilt, possSpecs, upgrades, canUpgrade, isMaxLevel, hasFollowerSlot, knownSpecs, currentSpec, specCooldown, isBeingBuilt, timeStarted, buildDuration, timeRemainingText, canCompleteBuild = C_Garrison.GetOwnedBuildingInfo(buildings[i].plotID)
					if not(isBeingBuilt or canCompleteBuild) then -- make sure the building isn't currently being built or upgraded
						hasMines = true
					end
				end
				if hasMines and hasSalvageYard then -- skip the rest of the checks if we've found both buildings
					break
				end
			end

			-- no idea whether these names are localized or not. poor documentation, and I can't be arsed to look much more into the Blizzard Lua :S
			local minesName = select(2, C_Garrison.GetBuildingInfo(61))
			local salvageYardName = select(2, C_Garrison.GetBuildingInfo(52))

			-- this one IS localized! 
			local currentZone = GetMinimapZoneText()

			-- ignore instance info and all that, go strictly by minimap zone names
			inSalvageYard = hasSalvageYard and (currentZone == SALVAGE_YARD or currentZone == salvageYardName or strlower(currentZone) == strlower(salvageYardName))
			inMines = hasMines and (currentZone == MINES or currentZone == minesName or strlower(currentZone) == strlower(minesName))
		end

	end
	local hasButtons = inSalvageYard or inMines
	local hasButtonsUI = self.inSalvageYard or self.inMines
	self.inSalvageYard = inSalvageYard
	self.inMines = inMines
	if hasButtons and not hasButtonsUI then
		self:RegisterEvent("BAG_UPDATE", "UpdateButtonDisplay")
		self:UpdateButtonDisplay()
		self.bar:Show()
	elseif hasButtonsUI and not hasButtons then
		self:UnregisterEvent("BAG_UPDATE")
		self.bar:Hide()
	end
end
module.UpdateBarDisplay = gUI4:SafeCallWrapper(module.UpdateBarDisplay)

function module:OnEnable()
	if not self.bar then
		self.bar = setmetatable(ButtonBar:New("Salvage", L["Salvage Crates and Garrison Mine Tools"], function() return self.db.profile end), { __index = Salvage })
		-- self.fadeManager:RegisterObject(self.bar)
		self.bar.overlay = gUI4:GlockThis(self.bar, L["Salvage Crates and Garrison Mine Tools"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "actionbars")))
		self.bar.UpdatePosition = function(self) module:UpdatePosition() end
		tinsert(parent.bars, self.bar)
		self.bar.buttons = {}
		for i = 1, max(#salvageItems, #mineItems) do
			self.bar.buttons[i] = GAB10:CreateButton("action", i, "GUI4SalvageButton"..i, self.bar, nil)
			self.bar.buttons[i]:SetFrameStrata("LOW")
			self.bar.buttons[i]:DisableDragNDrop(true)
			self.bar.buttons[i]:Hide()
		end
		self:RegisterEvent("ZONE_CHANGED", "UpdateBarDisplay")
		self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateBarDisplay")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateBarDisplay")
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBarDisplay")
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateBarDisplay")
		self:RegisterEvent("PLAYER_LOGIN", "UpdateBarDisplay")
		self:RegisterEvent("CHANNEL_UI_UPDATE", "UpdateBarDisplay")
		self:RegisterEvent("GARRISON_BUILDING_UPDATED", "UpdateBarDisplay")
	end
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:UpdateTheme()
	self:UpdateBarDisplay()
end

function module:OnDisable()
end