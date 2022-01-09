local addon, gUI4 = ...

-- Lua API
local _G = _G
local ipairs = ipairs
local tonumber = tonumber

-- WoW API
local CloseAllBags = _G.CloseAllBags
local CloseBag = _G.CloseBag
local GetContainerNumSlots = _G.GetContainerNumSlots
local IsBagOpen = _G.IsBagOpen
local IsOptionFrameOpen = _G.IsOptionFrameOpen
local OpenBackpack = _G.OpenBackpack
local OpenBag = _G.OpenBag
local BankFrame = _G.BankFrame
local ToggleFrame = _G.ToggleFrame

local UIParent = _G.UIParent

local _, build = _G.GetBuildInfo()
build = tonumber(build)


-- Turns out we can avoid the spellbook taint
-- by opening it once before we login. Thanks TukUI! :)
-- NB! taiting the GameTooltip taints the spellbook too, so DON'T! o.O
-- NB2! The blizzard nameplates in Legion taints the tooltip if friendly debuffs are shown! >:(
local cleenex = CreateFrame("Frame")
cleenex:RegisterEvent("ADDON_LOADED")
cleenex:SetScript("OnEvent", function(self, _, what)

	-- Forcefully disable this, as the 7.3.0 secure friendly nameplates in dungeons
	-- will make GameTooltip secure, causing a neverending amount of bugs. 
	-- This happens on specs that can dispel when hovering over nameplate auras.
	if (build >= 24500) and (what == "Blizzard_NamePlates") then
		SetCVar("nameplateShowDebuffsOnFriendly", 0)
		self.fixedNamePlates = true
	end

	-- Goldpaw's UI Core is loaded
	if (what == addon) then
		_G.ToggleFrame(_G.SpellBookFrame)
		if (build < 19678) then -- don't load this in 6.1, it's not there!
			_G.PetJournal_LoadUI()
		end
	end

	if (not self.fixedNamePlates) then
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

local hidden = CreateFrame("Frame")
hidden:Hide()

---------------------------------------------------------------
-- Blizzard_NamePlates (Legion 7.3.0)
---------------------------------------------------------------
-- If these are enabled the GameTooltip will become protected, 
-- and all sort of taints and bugs will occur.
-- This happens on specs that can dispel when hovering over nameplate auras.
-- We create our own auras anyway, so we don't need these. 
if LEGION_730 then
	SetCVar("nameplateShowDebuffsOnFriendly", 0) 
end


-------------------------------------------------------------------------------
--	Open Bags
-------------------------------------------------------------------------------
-- blizzard's baghandling just doesn't cut it
-- we wish for all backpack/bag hotkeys and buttons to toggle all bags, always
local function OpenAllBags()
	if (not UIParent:IsShown()) or IsOptionFrameOpen() then
		return
	end
	if (not BankFrame:IsShown()) then
		if (IsBagOpen(0)) then
			CloseAllBags()
		else
			for i = 0, NUM_BAG_FRAMES, 1 do
				OpenBag(i)
			end
		end
	else 
		local bagsOpen = 0
		local totalBags = 0
		
		-- check for open bank bags
		for i = NUM_BAG_FRAMES + 1, NUM_CONTAINER_FRAMES, 1 do
			if (GetContainerNumSlots(i) > 0) then		
				totalBags = totalBags + 1
			end
			if (IsBagOpen(i)) then
				CloseBag(i)
				bagsOpen = bagsOpen + 1
			end
		end 
		if (bagsOpen < totalBags) or (totalBags == 0) then
			for i = 0, NUM_CONTAINER_FRAMES, 1 do
				OpenBag(i)
			end
		else 
			CloseAllBags()
		end
	end
end

-- replace blizzard's bag opening functions
local otherBagsLoaded
for _,bags in ipairs({ "ArkInventory", "Bagnon", "OneBag3", "BagForce", "Tbag", "Tbag-Shefki" }) do
	if gUI4:IsAddOnEnabled(bags) then
		otherBagsLoaded = true
		break
	end
end
if (not otherBagsLoaded) then
	_G.OpenBackpack = OpenAllBags
	_G.OpenAllBags = OpenAllBags
	_G.ToggleBackpack = OpenAllBags
	_G.ToggleBag = OpenAllBags
else
	OpenAllBags = nil
end


-------------------------------------------------------------------------------
--	PvP Queue Popup
-------------------------------------------------------------------------------
-- remove the 'leave queue' button from pvp popups,
-- forcing the user to have to right-click the lfg-eye instead
if (PVPReadyDialog) then
	PVPReadyDialog.leaveButton:Hide()
	PVPReadyDialog.enterButton:ClearAllPoints()
	PVPReadyDialog.enterButton:SetPoint("BOTTOM", PVPReadyDialog, "BOTTOM", 0, 25)
	PVPReadyDialog.label:SetPoint("TOP", 0, -22)
end


-------------------------------------------------------------------------------
--	Interface Options Panels
-------------------------------------------------------------------------------
-- remove an entire blizzard options panel, 
-- and disable its automatic cancel/okay functionality
-- this is needed, or the option will be reset when the menu closes
-- it is also a major source of taint related to the Compact group frames!
function gUI4:KillPanel(i, panel)
	if i then
		local cat = _G["InterfaceOptionsFrameCategoriesButton" .. i]
		if cat then
			cat:SetScale(0.00001)
			cat:SetAlpha(0)
		end
	end
	if panel then
		panel:SetParent(hidden)
		if panel.UnregisterAllEvents then
			panel:UnregisterAllEvents()
		end
		panel.cancel = function() end
		panel.okay = function() end
		panel.refresh = function() end
	end
end

-- remove a blizzard menu option, 
-- and disable its automatic cancel/okay functionality
-- this is needed, or the option will be reset when the menu closes
-- it is also a major source of taint related to the Compact group frames!
function gUI4:KillOption(shrink, option)
	if not(option) or not(option.IsObjectType) or not(option:IsObjectType("Frame")) then
		return
	end
	option:SetParent(hidden)
	if option.UnregisterAllEvents then
		option:UnregisterAllEvents()
	end
	if shrink then
		option:SetHeight(0.00001)
	end
	option.cvar = ""
	option.uvar = ""
	option.value = nil
	option.oldValue = nil
	option.defaultValue = nil
	option.setFunc = function() end
end

for _, db in ipairs({
	{ _G.InterfaceOptionsCombatPanelTargetOfTarget, true, "gUI4_UnitFrames" },
	{ _G.InterfaceOptionsActionBarsPanelBottomRight, true, "gUI4_ActionBars" },
	{ _G.InterfaceOptionsActionBarsPanelBottomLeft, true, "gUI4_ActionBars" },
	{ _G.InterfaceOptionsActionBarsPanelRight, true, "gUI4_ActionBars" },
	{ _G.InterfaceOptionsActionBarsPanelRightTwo, true, "gUI4_ActionBars" },
	{ _G.InterfaceOptionsActionBarsPanelAlwaysShowActionBars, true, "gUI4_ActionBars" },
	{ _G.InterfaceOptionsNamesPanelUnitNameplatesMakeLarger, true, "gUI4_NamePlates" },
	{ _G.InterfaceOptionsNamesPanelUnitNameplatesAggroFlash, true, "gUI4_NamePlates" },
	{ _G.InterfaceOptionsNamesPanelUnitNameplatesPersonalResourceOnEnemy, true, "gUI4_NamePlates" }
}) do
	local abort
	for i = 3, #db do
		if (not gUI4:IsAddOnEnabled(db[i])) then
			abort = true
			break
		end
	end
	if (not abort) then
		gUI4:KillOption(db[2], db[1])
	end
end

-- no full panels to remove anymore after Legion
for _, db in ipairs({
}) do
	local abort
	for i = 3, #db do
		if not gUI4:IsAddOnEnabled(db[i]) then
			abort = true
			break
		end
	end
	if (not abort) then
		gUI4:KillPanel(db[2], db[1])
	end
end
