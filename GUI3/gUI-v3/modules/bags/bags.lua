--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...
local cargBags = cargBags or ns.cargBags

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Bags", "gDB-2.0")
local EquipList = module:NewDataBase("EquipList")
local Sorting = module:NewDataBase("Sorting")

local ceil = math.ceil
local tinsert = table.insert
local ipairs, pairs, select, unpack = ipairs, pairs, select, unpack
local format, strfind, strsplit = string.format, string.find, string.split
local tonumber = tonumber
local type = type
local print = print
local cresume, ccreate = coroutine.resume, coroutine.create
local cstatus, cyield = coroutine.status, coroutine.yield
local wipe = wipe

local ClearCursor = ClearCursor
local CloseAllBags = CloseAllBags
local CloseBankFrame = CloseBankFrame
local ContainerIDToInventoryID = ContainerIDToInventoryID
local CreateFrame = CreateFrame
local GetBankSlotCost = GetBankSlotCost
local GetContainerItemDurability = GetContainerItemDurability
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemID = GetContainerItemID
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetContainerNumSlots = GetContainerNumSlots
local GetMoney = GetMoney
local GetNumBankSlots = GetNumBankSlots
local GetNumWatchedTokens = GetNumWatchedTokens
local GetInventoryItemLink = GetInventoryItemLink
local GetInventorySlotInfo = GetInventorySlotInfo
local GetItemFamily = GetItemFamily
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetScreenWidth = GetScreenWidth
local PickupContainerItem = PickupContainerItem
local PlaySound = PlaySound
local PutItemInBag = PutItemInBag
local RGBToHex = function(...) return module:RGBToHex(...) end -- shortcuts galore today
local StaticPopup_Show = StaticPopup_Show
local UnitClass, UnitLevel = UnitClass, UnitLevel
local UpdateBagSlotStatus = UpdateBagSlotStatus
local GameTooltip = GameTooltip
local UIParent = UIParent
local GetPoint = function(...) return module:GetObjectPosition(...) end

local gABT = LibStub("gActionButtons-3.0")

local L, C, F, M, db
local Types, Bags, Container, Button, BagButton
local SHOW, BYPASS, HIDE, MODULE_TOOLTIP
local MIN_SCALE, MAX_SCALE = 1, 1.6
local MIN_BUTTON_SIZE, MAX_BUTTON_SIZE = 29, 46

local currentBagContents = {}
local ContainerList = {}
local bagContainerIDs = { 0, 1, 2, 3, 4 }
local bankContainerIDs = { -1, 5, 6, 7, 8, 9, 10, 11 }
local newItemsSinceReset = {}
local _,playerClass = UnitClass("player")
local playerName = GetUnitName("player")

-- bank column map
local bankMap = {
	Bank_Sets = 1,
	Bank_Gizmos = 2,
	Bank_Misc = 2,
	Bank_Armor = 1,
	Bank_Weapons = 1,
	Bank_Gems = 2,
	Bank_Glyphs = 2,
	Bank_Quest = 2,
	Bank_Consumables = 3,
	Bank_Trade = 3
}

-- these are the default settings
-- editing them will not change any in-game settings
local defaults = {
	-- the bags don't use the global position saving functions
	-- this is because some users prefer to have the bags unlocked at all times
	points = {
		Main = { "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -6, 170 };
		Bank = { "TOPLEFT", "UIParent", "TOPLEFT", 6, -6 };
	};

	autorestack = false; -- automatically restack bags/bank when opened
	autorestackcrafted = false; -- automatically restack when crafting or looting items (like Gems)
	compressemptyspace = true; -- compress the empty space to a maximum one row
	orderSort = true; -- sort items within each category 
	locked = true; -- whether or not the bags are locked into place
	scale = 1; -- scale of the bags (valid scales are from 1.0 to 2.0)
	bagWidth = 9; -- width of the bag containers in slots. values from 9 to 16 will be allowed
	bankWidth = { 8, 8, 8 }; -- widths of the 3 columns of bank containters (8 to 24 slots allowed)

	colorNoEquip = true; -- color items you can't equip in red
	showDurability = true; -- show the durability percentage on damaged items
	
	showgloss = true;
	showshade = true;
	glossalpha = 1/2;
	shadealpha = 1/2;
	buttonSize = 29;
	
	 -- activate all-in-one bags. will disable category selection alltogether.
	 -- all options below this one will be disregarded if it is set to 'true'
	-- allInOne = false;
	
	-- 1 = show, 2 = bypass, 3 = hide
	bagDisplay = {
		-- bags
		["Main_NewItems"] = 1;
		["Main_Sets"] = 1;
		["Main_Armor"] = 1;
		["Main_Weapons"] = 1;
		["Main_Gizmos"] = 1;
		["Main_Quest"] = 1;
		["Main_Glyphs"] = 1;
		["Main_Gems"] = 1;
		["Main_Consumables"] = 1;
		["Main_Trade"] = 1;
		["Main_Misc"] = 1;
		["Main_Junk"] = 1;
		
		-- bank
		["Bank_Sets"] = 1;
		["Bank_Armor"] = 1;
		["Bank_Weapons"] = 1;
		["Bank_Gizmos"] = 1;
		["Bank_Quest"] = 1;
		["Bank_Glyphs"] = 1;
		["Bank_Gems"] = 1;
		["Bank_Consumables"] = 1;
		["Bank_Trade"] = 1;
		["Bank_Misc"] = 1;
	};
	
	-- we store these two in the saved settings
	-- to make "new" items stick through sessions
	bagContents = {}; -- table of the contents of your bags + backpack
	scannedSinceReset = false; -- whether or not the initial scan of the bags has been done

	-- categories to be included in the 'new items' sorting
	newItemDisplay = {
		["Main_Armor"] = true;
		["Main_Weapons"] = true;
		["Main_Gizmos"] = true;
		["Main_Quest"] = true;
		["Main_Glyphs"] = true;
		["Main_Gems"] = true;
		["Main_Consumables"] = true;
		["Main_Trade"] = true;
		["Main_Misc"] = true;
		["Main_Junk"] = true;
	};

	-- http://www.wowpedia.org/API_TYPE_Quality
	newitemrarity = 1; -- minimum rarity to be sorted into the New Items category (1 = common/white, 2 = uncommon/green)
}

-- we grab the localized names here, as we need them for the equiplist and the menu
Types = cargBags:GetLocalizedTypes()

-- equipped item slots
local inventorySlots = {
	"HeadSlot"; "NeckSlot"; "ShoulderSlot"; "BackSlot"; "ChestSlot"; "ShirtSlot"; "TabardSlot"; "WristSlot"; "HandsSlot"; "WaistSlot"; "LegsSlot"; "FeetSlot"; "Finger0Slot"; "Finger1Slot"; "Trinket0Slot"; "Trinket1Slot"; "MainHandSlot"; "SecondaryHandSlot"; "Bag0Slot"; "Bag1Slot"; "Bag2Slot"; "Bag3Slot"; 
}

-- smart positioning of the game tooltip
local PlaceGameTooltip = function(anchor, horTip)
	GameTooltip:SetOwner(anchor, "ANCHOR_PRESERVE")
	GameTooltip:ClearAllPoints()
	
	if (horTip) then
		if (GetScreenWidth() - anchor:GetRight()) > anchor:GetLeft() then
			GameTooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
		else
			GameTooltip:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -8, 0)
		end
	else
		if (GetScreenHeight() - anchor:GetTop()) > anchor:GetBottom() then
			GameTooltip:SetPoint("BOTTOM", anchor, "TOP", 0, 8)
		else
			GameTooltip:SetPoint("TOP", anchor, "BOTTOM", 0, -8)
		end
	end
end

local restackThread, restackTimer

-- define containers using Blizzard globals, for safety and future compability
local stackContainers = { bags = { 0 }; bank = { BANK_CONTAINER }; }
for i = 1, NUM_BAG_SLOTS, 1 do 
	tinsert(stackContainers.bags, i) 
end

for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS, 1 do 
	tinsert(stackContainers.bank, i) 
end

local yBagID, ySlot
local stackYield = function(location, bagID, slot)
	yBagID, ySlot = bagID, slot
	restackTimer = restackTimer or ScheduleTimer(function()
		if (type(restackThread) == "thread") and (cstatus(restackThread) == "suspended") then
			local locked = true
			if ((yBagID) and (ySlot)) then
				locked = select(3, GetContainerItemInfo(yBagID, ySlot))
			end
			
			if not(locked) then 
				-- not strictly sure this is a source of combat taint, but adding it just in case. for now.
				-- I got a taint report indicating this _might_ be the case.
				local safecall = function()
					cresume(restackThread) 
				end
				F.SafeCall(safecall)
			end
		end
	end, 0.1)
	
	cyield()
end

local RestackRun = function(location, item, silent)
	if (location == "resume") then
		if (type(restackThread) == "thread") and (cstatus(restackThread) == "suspended") then
			if not(InCombatLockdown()) then
				print(L["Resuming restack operation"])
				cresume(restackThread)
			end
		else
			print(L["No running restack operation to resume"])
		end
	end
	
	if (type(restackThread) ~= "thread") or (cstatus(restackThread) == "dead") then
		restackThread = ccreate(function()
			local _
			local bagID, itemID, itemCount, locked
			local name, itemLink, itemType, itemSubType, itemStackCount, itemEquipLoc
			local bagType, sbagID, sbagType, sitemType
			local found, fBagID, fSlot, fLocked, fDone
			local rBagID, rItemID
			local rItemCount, rLocked, rItemType, rItemSubType, rItemStackCount
		
			local changed = true
			while (changed) do
				changed = false
				
				for bagNum = 1, #stackContainers[location], 1 do
					bagID = stackContainers[location][bagNum]
					
					for slot = 1, GetContainerNumSlots(bagID) do
						itemID = GetContainerItemID(bagID, slot)
						if (itemID) then
							
							_, itemCount, locked, _, _ = GetContainerItemInfo(bagID, slot)
							name, itemLink, _, _, _, itemType, itemSubType, itemStackCount, itemEquipLoc, _, _ = GetItemInfo(itemID) 
							
							-- wait for the current slot to become unlocked before proceding
							if (locked) then
								stackYield(location, bagID, slot)
							end

							-- move profession items into professionbags
							if not(itemEquipLoc == "INVTYPE_BAG") then
								bagType = (bagID ~= 0 and bagID~= -1) and GetItemFamily(GetInventoryItemLink("player", ContainerIDToInventoryID(bagID))) or 0
								
								for _, sbag in ipairs(stackContainers[location]) do
									if (sbag > 0) and (GetContainerNumFreeSlots(sbag) > 0) then
										sbagID = ContainerIDToInventoryID(sbag)
										sbagType = GetItemFamily(GetInventoryItemLink("player", sbagID))
										sitemType = GetItemFamily(itemLink)

										if (sbagType > 0) and (sbagType == sitemType) and (bagType == 0) then
											PickupContainerItem(bagID, slot)
											PutItemInBag(sbagID)

											stackYield(location, bagID, slot)

											break
										end
									end
								end	
							end
							
							-- partial stack discovered
							found, fBagID, fSlot, fLocked, fDone = nil, nil, nil, nil, nil
							if (itemStackCount > itemCount) then
								
								while true do
									-- backtrack through the bags for another partial match
									for rBagNum = #stackContainers[location], 1, -1 do
										rBagID = stackContainers[location][rBagNum]
										if (found) or (fDone) then 
											break 
										end
										
										for rSlot = GetContainerNumSlots(rBagID), 1, -1 do
											if (rBagID == bagID) and (rSlot == slot) then
												fDone = true
												break
											end
											
											rItemID = GetContainerItemID(rBagID, rSlot)
											if (rItemID) and (rItemID == itemID) then
												local _, rItemCount, rLocked, _, _ = GetContainerItemInfo(rBagID, rSlot)
												local _, _, _, _, _, rItemType, rItemSubType, rItemStackCount, _, _, _ = GetItemInfo(rItemID) 
												
												if (rItemStackCount > rItemCount) then
													found = true
													fLocked = rLocked
													fBagID, fSlot = rBagID, rSlot
													break
												end
											end
										end
									end
									
									fLocked = (found) and (select(3, GetContainerItemInfo(fBagID, fSlot))) or false
									if (fLocked) then
										stackYield(location, fBagID, fSlot)
									else
										break
									end
								end

								if (found) then
									ClearCursor()
									
									PickupContainerItem(bagID, slot)
									PickupContainerItem(fBagID, fSlot)
									
									ClearCursor()
									
									changed = true
									break
								end
							end
						end
					end
				end
			end
			if (restackTimer) then
				CancelTimer(restackTimer)
				restackTimer = nil
			end
		end)
		cresume(restackThread)
	else
		if not(silent) then
			print(L["Restack is already running, use |cFF4488FF/restackbags resume|r if stuck"])
		end
	end
end

--
-- a function to restack all the items in the given bags
-- bags: 
local RestackBags = function(location)
	if not(location) then return end

	RestackRun(location)
end

-- only run the update process if the bags are actually visible
local updateAllContainers = function(self, event, ...)
	if not(Bags:GetContainer("Main")) or not(Bags:GetContainer("Main"):IsShown() or Bags:GetContainer("Bank"):IsShown()) then 
		return 
	end
	
	-- part of Problem2 described below. we perform this check to avoid double sorting and waste of time.
	if (event == "BAG_UPDATE") and not(Bags:GetContainer("Bank"):IsShown()) then
		return
	
	-- for our restack feature
	elseif (event == "CHAT_MSG_LOOT") then
		local msg, sender, language, channelString, target, flags, _, channelNumber, channelName, _, counter = ...
		
		local _,_,player, item = strfind(msg, ( gsub(LOOT_ITEM, "%%s", "(.+)") ) ) 
		if not player then
			_,_,item = strfind(msg, ( gsub(LOOT_ITEM_SELF, "%%s", "(.+)") ) )
			player = playerName
		end

		if (player ~= playerName) then
			return
		end
	end
	
	Bags:OnEvent("BAG_UPDATE")

	-- Problem1: PLAYERBANKBAGSLOTS_CHANGED isn't always registered due to it being a bucket event
	-- so we need to manually check for whether the bank frame is shown instead of checking for the event
	--
	-- Problem2: Some times, for some weird Blizzard reason, PLAYERBANKBAGSLOTS_CHANGED doesn't fire at all
	-- when you deposit items in your bank, just BAG_UPDATE. So we need to make this check every time. 
	if (Bags:GetContainer("Bank"):IsShown()) then
		for name,container in pairs(ContainerList) do
			if (name:find("Bank")) then
				container:OnContentsChanged()
			end
		end
	end
end
module.updateAllContainers = updateAllContainers

local updateAllLayouts = function(self)
	-- resort and update layout and visibility
	-- need to do this manually and in the same order as they are initially created
	local bank = { "Bank_Sets", "Bank_Misc", "Bank_Armor", "Bank_Weapons", "Bank_Gizmos", "Bank_Quest", "Bank_Glyphs", "Bank_Gems", "Bank_Trade", "Bank_Consumables" }
	
	local main = { "Main_NewItems", "Main_Sets", "Main_Gizmos", "Main_Junk", "Main_Quest", "Main_Misc", "Main_Armor", "Main_Weapons", "Main_Gems", "Main_Glyphs", "Main_Consumables", "Main_Trade" }

	local fix = function(i)
		local container = Bags:GetContainer(i)
		if (container) then
			if (db.bagDisplay[i] == 1) then
				container:Show()
			else
				container:Hide()
			end
			container:OnContentsChanged()
		end
	end
	
	for i = 1, #bank do fix(bank[i]) end
	if (Bags:GetContainer("Bank")) and (Bags:GetContainer("Bank"):IsShown()) then
		Bags:GetContainer("Bank"):OnContentsChanged()
	end
	
	for i = 1, #main do fix(main[i]) end
	if (Bags:GetContainer("Main")) and (Bags:GetContainer("Main"):IsShown()) then
		Bags:GetContainer("Main"):OnContentsChanged()
	end
	
	-- now we fire the main update function to fire off cargBags events and functions
	self:updateAllContainers()
end
module.updateAllLayouts = updateAllLayouts

-- "remember" all the items currently in the bags and inventory
local RememberBagContents = function()
	-- abort if we've already scanned the bags, or no bag data is available yet
	if (db.scannedSinceReset) or (GetContainerNumSlots(BACKPACK_CONTAINER) == 0) then
		return
	end
	
	wipe(newItemsSinceReset)
	wipe(db.bagContents)
	wipe(currentBagContents)
	
	local slotId, textureName
	local itemLink
	local Id, Unique, _
 
	-- scan equipped items
	for _, slotName in pairs(inventorySlots) do
		slotId, textureName = GetInventorySlotInfo(slotName)
		
		if (slotId) then
			itemLink = GetInventoryItemLink("player", slotId)
			if (itemLink) then
				-- _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name
				_, _, _, _, Id, _, _, _, _, _, _, Unique, _, _, _ = strfind(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				Id, Unique = tonumber(Id), tonumber(Unique)
				if (Id) and (Unique) then
					db.bagContents[Id] = db.bagContents[Id] or {}
					db.bagContents[Id][Unique] = true
				end
			end
		end
	end
	
	-- scan bags and backpack
	for _,bagID in pairs(bagContainerIDs) do
		for slotID = 1, GetContainerNumSlots(bagID) do
			itemLink = GetContainerItemLink(bagID, slotID)
			if (itemLink) then
				_, _, _, _, Id, _, _, _, _, _, _, Unique, _, _, _ = strfind(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
				Id, Unique = tonumber(Id), tonumber(Unique)
				if (Id) and (Unique) then
					db.bagContents[Id] = db.bagContents[Id] or {}
					db.bagContents[Id][Unique] = true
				end
			end
		end
	end
	
	db.scannedSinceReset = true
end

-- wipe the new items list and rescan the bags and inventory
local ResetNewItems = function()
	db.scannedSinceReset = false
	RememberBagContents()
	updateAllContainers()
end

local CreateButton = function(button)
	gABT:GetStyleFunction()(button)

	button:SetSize(db.buttonSize, db.buttonSize)
	button.Gloss:SetAlpha(gUI:GetGlossAlpha(true))
	button.Shade:SetAlpha(gUI:GetShadeAlpha(true))
	button.Gloss:SetShown(db.showgloss)
	button.Shade:SetShown(db.showshade)

	button.Border = _G[button:GetName().."NormalTexture"]
	button.Cooldown = _G[button:GetName().."Cooldown"]
	button.Count = _G[button:GetName().."Count"]
	button.Icon = _G[button:GetName().."IconTexture"]
	button.Quest = _G[button:GetName().."IconQuestTexture"]

	button.NewItem = _G[button:GetName().."NewItemTexture"]
	if (button.NewItem) then
		button.NewItem:Hide()
		button.NewItem.Show = button.NewItem.Hide
	end
	
	local Durability = button:CreateFontString(button:GetName() .. "Durability", "OVERLAY")
	Durability:SetJustifyH("CENTER")
	Durability:SetJustifyV("MIDDLE")
	Durability:SetPoint("CENTER", button, "CENTER", 1, 0)
	Durability:SetFontObject(gUI_DisplayFontTinyOutlineWhite)
	Durability:Hide()
	
	
	button.Durability = Durability
		
	if (button.Quest) then
		button.Quest:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		button.Quest:SetAllPoints(button.Icon)
		button.Quest:SetBlendMode("BLEND")
		button.Quest:SetDrawLayer("OVERLAY")
	end
	
	button.glowAlpha = 0.55
	button.glowBlend = "ADD"
	button.glowCoords = { 16/64, 47/64, 16/64, 47/64 }
end

local highlightFunction = function(button, match)
	button:SetAlpha(match and 1 or 0.1)
end

--
-- ToDO: add name as a criteria after itemlevel
--
-- our own quite glorious sort function
-- ItemRarity > ItemLevel > ItemID > StackSize > BagType > BagID
local sorts = cargBags.classes.Container.sorts
sorts.smartSort = function(a, b)
	local aItemID, bItemID
	local aRarity, bRarity
	local aLevel, bLevel
	local aCount, bCount
	local aBagType, bBagType
	
	aItemID, bItemID = GetContainerItemID(a.bagID, a.slotID) or 0, GetContainerItemID(b.bagID, b.slotID) or 0
	aRarity, bRarity = aItemID and (select(3, GetItemInfo(aItemID))) or 0, bItemID and (select(3, GetItemInfo(bItemID))) or 0
	if (aRarity == bRarity) then
		aLevel, bLevel = aItemID and (select(4, GetItemInfo(aItemID))) or 1, bItemID and (select(4, GetItemInfo(bItemID))) or 1
		if (aLevel == bLevel) then
			if (aItemID == bItemID) then
				aCount, bCount = (select(2,GetContainerItemInfo(a.bagID, a.slotID))) or 1, (select(2,GetContainerItemInfo(b.bagID, b.slotID))) or 1
				if (aCount == bCount) then
					aBagType, bBagType = (select(2, GetContainerNumFreeSlots(a.bagID))) or 0, (select(2, GetContainerNumFreeSlots(b.bagID))) or 0
					if (aBagType == bBagType) then
						return (a.bagID < b.bagID)
					else
						return (aBagType < bBagType) 
					end
				else
					return (aCount > bCount)
				end
			else
				return (aItemID > bItemID)
			end
		else
			return (aLevel > bLevel)
		end
	else
		return (aRarity > bRarity)
	end
end

-- sorted by bag and slot
sorts.indexSort = function(a, b)
	if (a.bagID == b.bagID) then
		return (a.slotID < b.slotID)
	else
		return (a.bagID < b.bagID)
	end
end

--
-- our new layout function
-- * empty spaces are compressed
local layouts = cargBags.classes.Container.layouts
layouts.smartGrid = function(self, columns, spacing, xOffset, yOffset)
	columns, spacing = columns or 8, spacing or 5
	xOffset, yOffset = xOffset or 0, yOffset or 0

	local width, height = 0, 0
	local col, row = 0, 0
	local shown = 0
	
	local bagType, lastBagType
	local itemID, lastItemID
	local newButton, xPos, yPos
	
	for i, button in ipairs(self.buttons) do

		if (i == 1) then 
			width, height = button:GetSize()
		end
		
		itemID = GetContainerItemID(button.bagID, button.slotID) or 0
		bagType = (select(2, GetContainerNumFreeSlots(button.bagID)))
		
		newButton = false
		if ((itemID == 0) and (itemID == lastItemID) and (bagType == lastBagType)) then
			if (shown ~= 0) and not(shown % columns == 0) then
				newButton = true
			end
		else
			newButton = true
		end
		
		if (newButton) or not(db.compressemptyspace) then
			shown = shown + 1
			
			col = shown % columns
			row = ceil(shown/columns)

			if (col == 0) then col = columns end

			xPos = (col-1) * (width + spacing)
			yPos = -1 * (row-1) * (height + spacing)

			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", self, "TOPLEFT", xPos+xOffset, yPos+yOffset)
			button:Show()
		else
			button:Hide()
		end
		
		lastBagType = bagType
		lastItemID = itemID
	end

	return columns * (width+spacing)-spacing, row * (height+spacing)-spacing
end

local createCloseButton = function(parent, tooltip, closeFunction, ...)
	tooltip = tooltip or CLOSE

	local close = CreateFrame("Button", parent:GetName() and parent:GetName() .. "CloseButton" or nil, parent)
	close:SetNormalTexture(M("Button", "gUI™ CloseButton"))
	close:SetPushedTexture(M("Button", "gUI™ CloseButtonDown"))
	close:SetHighlightTexture(M("Button", "gUI™ CloseButtonHighlight"))
	close:SetDisabledTexture(M("Button", "gUI™ CloseButtonDisabled"))
	close:EnableMouse(true)
	close:SetSize(16, 16)

	close:SetScript("OnClick", closeFunction)
	
	close:SetScript("OnEnter", function(self)
		PlaceGameTooltip(self, false)
		GameTooltip:AddLine(L["Hide"], 1, 1, 1)
		GameTooltip:AddLine(tooltip)
		GameTooltip:Show()
	end)
	
	close:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	close:SetScript("OnShow", function(self)
		self:SetFrameLevel(self:GetParent():GetFrameLevel() + 5)
	end)

	if (...) then
		close:ClearAllPoints()
		close:SetPoint(...)
	end
	
	
	parent.UICloseButton = close
	
	return close
end

local restackBags = function()
	if (db.autorestackcrafted) then
		RestackRun("bags", nil, true)
	end
end

local restackBank = function()
	if (db.autorestack) then
		RestackRun("bank", nil, true)
	end
end

local init_cargBags = function(self)
	local db = db

	-- hiding the Blizzard bags completely
	do
		local bag
		for i = 1, 5 do
			bag = _G["ContainerFrame" .. i]
			bag:Hide()
			bag.Show = bag.Hide
		end
	end
	
	Bags = cargBags:NewImplementation(self:GetName() .. "Frame") 
	Bags:RegisterBlizzard()
	
	Container = Bags:GetContainerClass()
	Button = Bags:GetItemButtonClass()
	BagButton = Bags:GetBagButtonClass()

	Button:Scaffold("Default")
	
	Button.OnCreate = function(self, tpl)
		CreateButton(self)
	end

	Button.OnUpdate = function(self, item)
		local RGBToHex = RGBToHex
		local bagType = (select(2, GetContainerNumFreeSlots(self.bagID)))
		
		local itemID
		if (item) then
			itemID = GetContainerItemID(item.bagID, item.slotID)
			
			-- cargBags is missing this
			-- it is needed for the inspect cursor to properly display
			if (itemID) then
				self.hasItem = 1
			else
				self.hasItem = nil
			end
		end
		
		if (self.Quest) then
			self.Quest:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			self.Quest:SetAllPoints(self.Icon)
			self.Quest:SetBlendMode("BLEND")
		end

		local hex, texture
		local blend = "BLEND"
		local r, g, b, a = gUI:GetBackdropBorderColor()
		local tL, tR, tT, tB = 5/64, 59/64, 5/64, 59/64

		if ((item) and ((item.questID) and (not item.questActive))) then
			texture = TEXTURE_ITEM_QUEST_BANG
			r, g, b, a = 1, 1, 1, 1

		elseif ((item) and ((item.questID) or (item.isQuestItem))) then
			texture = TEXTURE_ITEM_QUEST_BORDER
			r, g, b, a = 1, 1, 1, 1
			
		elseif ((item) and ((item.rarity) and (item.rarity > 1) and (self.glowTex))) then
			a, r, g, b, hex = self.glowAlpha, GetItemQualityColor(item.rarity)
			texture = self.glowTex
			blend = self.glowBlend
			tL, tR, tT, tB = unpack(self.glowCoords)
		end

		-- color items red when you can't equip them
		if (db.colorNoEquip) and ((item) and (self.glowTex)) then
			if (itemID) then
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemID) 
				
				local canUse = true
				if (_G[itemEquipLoc]) and ((itemType == Types["Armor"]) or (itemType == Types["Weapon"])) then
					local classEquiplist = EquipList[playerClass]
					local classException = EquipList.EXCEPTIONS[playerClass]
					local canWear = (classEquiplist[itemType]) and (classEquiplist[itemType][itemSubType])
					
					if (canWear) then
						if (itemMinLevel) and (itemMinLevel > UnitLevel("player")) then
							canUse = false
						end
						
						if (classException) and (classException[itemSubType]) and (classException[itemSubType] > UnitLevel("player")) then
							canUse = false
						end
					else
						canUse = false
					end
				end
				
				if (not canUse) then
					self.Icon:SetVertexColor(C.range.r, C.range.g, C.range.b)

					a, r, g, b = self.glowAlpha, C.range.r, C.range.g, C.range.b
					texture = self.glowTex
					blend = self.glowBlend
					tL, tR, tT, tB = unpack(self.glowCoords)
				else
					self.Icon:SetVertexColor(1, 1, 1)
				end
			end
		end

		if (texture) then
			self.Quest:SetTexture(texture)
			self.Quest:SetTexCoord(tL, tR, tT, tB)
			self.Quest:SetBlendMode(blend)
			self.Quest:SetVertexColor(r, g, b, a)
			self.Quest:Show()
		else
			self.Quest:Hide()
		end
		
		-- show the durability display on damage items
		if (db.showDurability) and (itemID) then
			local current, maximum = GetContainerItemDurability(item.bagID, item.slotID)
			if (maximum) and (maximum > 0) and (current < maximum) then 	-- only show if the item is damaged
				local r, g, b = F.GetDurabilityColor(current, maximum)

				self.Durability:SetText(("|cFF%s%d%%|r"):format(RGBToHex(r, g, b), (current or 0)/maximum * 100))
				self.Durability:Show()
			else
				self.Durability:Hide()
			end
		else
			self.Durability:Hide()
		end
		
		-- update gloss and shade layers
		self.Gloss:SetAlpha(gUI:GetGlossAlpha(true))
		self.Shade:SetAlpha(gUI:GetShadeAlpha(true))

		if (db.showgloss) and (self.hasItem) then
			if not(self.Gloss:IsShown()) then
				self.Gloss:Show()
			end
		elseif not(db.showgloss) or not(self.hasItem) then
			if (self.Gloss:IsShown()) then
				self.Gloss:Hide()
			end
		end
	
		if (db.showshade) then
			if not(self.Shade:IsShown()) then
				self.Shade:Show()
			end
		elseif not(db.showshade) then
			if (self.Shade:IsShown()) then
				self.Shade:Hide()
			end
		end
		
		-- update button sizes
		local w, h = self:GetSize()
		if (w ~= db.buttonSize) or (h ~= db.buttonSize) then
			self:SetSize(db.buttonSize, db.buttonSize)
		end
		
		-- color the borders, backdrop and overlay of the slots
		if (item) and (item.rarity) and (item.rarity > 1) then
			local r, g, b, hex = GetItemQualityColor(item.rarity)
			self:SetBackdropBorderColor(r * 4/5, g * 4/5, b * 4/5, 1)
			self:SetBackdropColor(C["backdrop"][1], C["backdrop"][2], C["backdrop"][3], 1)
			
		elseif (item) and (((item.isQuestItem) or (item.questID)) or ((item.questID) and (not item.questActive))) then
			self:SetBackdropBorderColor(0.8, 0.8, 0.5, 1)
			self:SetBackdropColor(C["backdrop"][1], C["backdrop"][2], C["backdrop"][3], 1)
			
		elseif ((item) and not(item.texture)) and (bagType == 256) then
			self:SetBackdropBorderColor(1, 0.7, 0.1, 1)
			self:SetBackdropColor(C["backdrop"][1], C["backdrop"][2], C["backdrop"][3], 1)
			
		elseif ((item) and not(item.texture)) and (bagType and bagType > 4) then
			self:SetBackdropBorderColor(1, 0.65, 0.1, 1)
			self:SetBackdropColor(C["backdrop"][1], C["backdrop"][2], C["backdrop"][3], 1)
			
		elseif (self.bagID >= 0) and (self.bagID <= 4) then
			self:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
			self:SetBackdropColor(C["backdrop"][1], C["backdrop"][2], C["backdrop"][3], 1)
			
		else 
			local r, g, b = gUI:GetBackdropBorderColor()
			self:SetBackdropBorderColor(r, g, b * 2, 1)
			self:SetBackdropColor(C["backdrop"][1], C["backdrop"][2], C["backdrop"][3] * 2, 1)
		end
		
	end
	
	BagButton.OnCreate = function(self, bagID)
		CreateButton(self)
		
		self:GetCheckedTexture():SetVertexColor(1, 1, 1, 3/4)
		self:GetCheckedTexture():SetTexCoord(5/64, 59/64, 5/64, 59/64)
		
		local freespace = self:CreateFontString(nil, "OVERLAY")
		freespace:SetFontObject(gUI_DisplayFontMicroOutlineWhite)
		freespace:SetJustifyH("CENTER")
		freespace:SetJustifyV("BOTTOM")
		freespace:SetPoint("BOTTOM", self, "BOTTOM", 1, 5)
		
		local i = "|cFF" ..RGBToHex(unpack(C["index"]))
		local v = "|cFF" ..RGBToHex(unpack(C["value"]))
		local display = v ..  "%s|r" .. i .. "(|r" .. v .. "%s|r" .. i .. ")|r"
		
		local Update = function()
			local bagID = self.bagID or bagID
			
			if (bagID) then
				local free, max = GetContainerNumFreeSlots(bagID), GetContainerNumSlots(bagID)
				self.FreeSpace:SetText(display:format(free, max))
			else
				self.FreeSpace:SetText("")
			end
		end
		self.FreeSpace = freespace
		
		self:HookScript("OnShow", Update)

		module:RegisterBucketEvent({ "PLAYERBANKBAGSLOTS_CHANGED", "BAG_UPDATE" }, Update, 0.1)
	end
	
	-- used by several functions
	local top, bottom, space = 24, 32, 8
	
	Container.OnContentsChanged = function(self)
		-- just in case this gets called before initialization is complete
		if not(self.ReadyToGo) then
			return
		end
	
		if (db.orderSort) then
			self:SortButtons("smartSort")
		else
			self:SortButtons("indexSort")
		end
		
		-- adjust the width of bags and bank separately
		local name = self.name
		if (name:find("Main")) then
			self.Settings.Columns = db.bagWidth
		elseif not(name == "Bank") then
			-- retrieve right size settings for the current containers column
			self.Settings.Columns = floor(db.bankWidth[bankMap[name]]) -- failsafe to fix the floating point bug with sliders introduced in 5.4.1
		end

		local columns = self.Settings.Columns
		local currencies = self.currencies
		local extra = 0

		if (name == "Main") and (currencies) then
			extra = (currencies:GetText() ~= "") and (currencies:GetHeight() + 8) or 0
		end

		
		local _, height = self:LayoutButtons("smartGrid", columns, 2, space, -(space + top + extra))
		local width = (2 + db.buttonSize) * columns - 2
		
		if not(self:IsShown()) then
			height = 0
		end

		if (name == "Main") or (name == "Bank") then
			self:SetSize(width + space * 2, height + top + bottom + space * 2 + extra)
			self:SetAlpha(1)

			self.UICloseButton:SetFrameStrata(self:GetFrameStrata())
			
		elseif (height <= 0) then
			self:SetSize(width + space * 2, 0.01);
			self:SetAlpha(0)
			
			self.UICloseButton:SetFrameStrata("BACKGROUND")
						
		else
			self:SetSize(width + space * 2, height + top + space * 2)
			self:SetAlpha(1)

			self.UICloseButton:SetFrameStrata(self:GetFrameStrata())
		end
	end

	Container.OnCreate = function(self, name, settings)
		self.Settings = settings

		self:EnableMouse(true)
		self:SetClampedToScreen(true)
		self:SetParent(settings.Parent or Bags)
		self:SetFrameStrata("HIGH")
		self:SetFrameLevel(strfind(name, "Bank") and 50 or 70)
		self:SetScript("OnShow", function(self) self:OnContentsChanged() end)
		
		-- the stacking/dock 'trick'
		-- our containers are all set 0 pixels apart, and reduced to 0 height when hidden
		-- the space between them is a visual trick achieved by using an indented backdrop
		gUI:SetUITemplate(self, "insetbackdrop") 
		
		if not(ContainerList[name]) then ContainerList[name] = self end
		
		if (strfind(name, "Bank")) then
			self:SetBackdropBorderColor(C["bank"][1]/3, C["bank"][2]/3, C["bank"][3]/3)
			self:SetBackdropColor(C["bank"][1]/5, C["bank"][2]/5, C["bank"][3]/5, 0.75) -- gUI:GetPanelAlpha()
		else
			self:SetBackdropColor(C.background[1], C.background[2], C.background[3], 0.75) -- gUI:GetPanelAlpha()
			self:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
		end
		
		if (settings.Movable) then
			self:SetMovable(true)
			self:RegisterForClicks("LeftButton", "RightButton")
			
			self:SetScript("OnMouseDown", function(self)
				if not(db.locked) then
					self:StartMoving()
				end
			end)
			
			self:SetScript("OnMouseUp",  function(self)
				self:StopMovingOrSizing()
				db.points[settings.Name and settings.Name or name] = { GetPoint(self) }
			end)
		end

		settings.Columns = settings.Columns or 8
		self:SetScale(db.scale and db.scale or settings.Scale and settings.Scale or 1)
		
		local title = self:CreateFontString(nil, "OVERLAY")
		title:SetFontObject(gUI_TextFontSmallBoldOutline)
		title:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -12)
		title:SetText("|cFF" .. RGBToHex(unpack(C["value"])) .. self.Settings.Name .. "|r")
		
		if (name == "Main_NewItems") then
			local tex = M("Button", "RefreshArrow") -- "Interface\\Transmogrify\\Textures.blp"
			local texcoords = { 2/128, 33/128, 263/512, 294/512 }
--			local texcoords = { 24/128, 47/128, 297/512, 320/512 }
			local sortButton = CreateFrame("Button", nil, self)
			sortButton:SetNormalTexture(tex)
			sortButton:SetDisabledTexture(tex)
			sortButton:SetHighlightTexture(tex)
			sortButton:SetPushedTexture(tex)
--			sortButton:GetNormalTexture():SetTexCoord(unpack(texcoords))
--			sortButton:GetDisabledTexture():SetTexCoord(unpack(texcoords))
--			sortButton:GetHighlightTexture():SetTexCoord(unpack(texcoords))
--			sortButton:GetPushedTexture():SetTexCoord(unpack(texcoords))
			sortButton:SetSize(16, 16)
			sortButton:SetPoint("LEFT", title, "RIGHT", 8, 2)
			sortButton:SetHitRectInsets(-8, -8, -8, -8)
			sortButton:SetScript("OnClick", function(self, button) 
				if (button == "LeftButton") then 
					ResetNewItems() 
				end
			end)
			
			sortButton:SetScript("OnEnter", function(self) 
				PlaceGameTooltip(self, false)
				GameTooltip:AddLine(L["Click to sort"])
				GameTooltip:Show()
			end)
			
			sortButton:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)
			
		end

		if (name == "Main") or (name == "Bank") then
			local close = createCloseButton(self, L["Close all your bags"], function() 
				if (Bags:AtBank()) then 
					CloseBankFrame()
				else 
					CloseAllBags()
				end 
			end, "TOPRIGHT", -6, -8)
			
			local infoFrame = CreateFrame("Button", nil, self)
			infoFrame:SetPoint("BOTTOMLEFT", 10, 3)
			infoFrame:SetPoint("BOTTOMRIGHT", -10, 3)
			infoFrame:SetHeight(bottom)

			-- gold
			local money = self:SpawnPlugin("TagDisplay", "[money]", self)
			money:SetFontObject(gUI_DisplayFontTinyWhite)
			money.iconValues = "0:0:2:0"
			money:SetPoint("TOPRIGHT", self, "TOPRIGHT", -40, -12)
			
			-- bottom info stuff
			do
				local freespace = self:SpawnPlugin("TagDisplay", "[space:free/max]", infoFrame)
				freespace:SetFontObject(gUI_DisplayFontLargeOutlineWhite) 
				freespace:SetPoint("LEFT", infoFrame, "LEFT")
				freespace.bags = cargBags:ParseBags(settings.Bags)
				
				local freespacelabel = infoFrame:CreateFontString(nil, "OVERLAY")
				freespacelabel:SetFontObject(gUI_TextFontExtraTinyBoldOutline)
				freespacelabel:SetText(L["Free"]:lower())
				freespacelabel:SetPoint("TOPLEFT", freespace, "TOPRIGHT", 0, 0)
				
				local spacegraph = CreateFrame("StatusBar", nil, infoFrame)
				spacegraph:SetBackdrop({ bgFile = M("Statusbar", "gUI™ ProgressBar") })
				spacegraph:SetBackdropColor(1, 1, 1, 0.2)
				spacegraph:SetSize(80, 20)
				spacegraph:SetPoint("BOTTOMLEFT", infoFrame, "BOTTOMLEFT", 72 + 16, 8)

				spacegraph.bar = spacegraph:CreateTexture(nil, "OVERLAY")
				spacegraph.bar:SetSize(spacegraph:GetSize())
				spacegraph.bar:SetPoint("BOTTOMLEFT", spacegraph, "BOTTOMLEFT", 0, 0)
				spacegraph.bar:SetTexture(M("Statusbar", "gUI™ ProgressBar"))

				local bags = (name == "Main" and bagContainerIDs) or (name == "Bank" and bankContainerIDs) or {}
				local setFree = function()
					local free, total, used = 0, 0, 0
					for _,i in pairs(bags) do
						free, total, used = free + GetContainerNumFreeSlots(i), total + GetContainerNumSlots(i), total - free
					end
					
					-- let's avoid division by zero, as this function gets called very early on
					if (total) and (total > 0) then
						free = free / total
					else
						free = 1
					end
					
					spacegraph.bar:SetWidth(((free > 0) and free or 0.0001) * 80)
					spacegraph.bar:SetTexCoord(0, 0, 0, 1, free, 0, free, 1)
				end
				setFree()

				spacegraph:SetScript("OnEvent", setFree)
				spacegraph:RegisterEvent("BAG_UPDATE")
				if (name == "Bank") then 
					spacegraph:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
					spacegraph:RegisterEvent("BANKFRAME_OPENED");
				end
			end

			-- search field
			do
				local search = self:SpawnPlugin("SearchBar", infoFrame)
				search.highlightFunction = highlightFunction
				search.isGlobal = true
				search:ClearAllPoints()
				search:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 3, 0)
				search:SetPoint("BOTTOMRIGHT", infoFrame, "BOTTOMRIGHT", -3, 0)

				-- skin the search box properly
				gUI:KillObject(search.Center)
				gUI:KillObject(search.Left)
				gUI:KillObject(search.Right)
				search:SetFrameLevel(search:GetFrameLevel() + 5)

				-- local searchBackdrop = CreateFrame("Frame", nil, search)
				-- searchBackdrop:SetFrameLevel(search:GetFrameLevel() - 1)
				-- gUI:SetUITemplate(searchBackdrop, "backdrop")
				local searchBackdrop = gUI:SetUITemplate(search, "editbox", -5, -3, 5, 3)
				if (strfind(name, "Bank")) then
					local r, g, b = gUI:GetBackdropBorderColor()
					searchBackdrop:SetBackdropBorderColor(r * 5/4, g * 5/4, b * 2 * 5/4, 1)
					searchBackdrop:SetBackdropColor(C["bank"][1], C["bank"][2], C["bank"][3], gUI:GetPanelAlpha())
				else
					searchBackdrop:SetBackdropColor(C["overlay"][1], C["overlay"][2], C["overlay"][3], gUI:GetPanelAlpha())
					searchBackdrop:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				end
				
				infoFrame:SetScript("OnEnter", function(self)
					PlaceGameTooltip(self, false)
					GameTooltip:AddLine(L["<Left-Click to search for items in your bags>"])
					GameTooltip:Show()
				end)
				
				infoFrame:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
				
				self.search = search
			end
			
			-- bagbar
			do
				local bagBar = self:SpawnPlugin("BagBar", settings.Bags)
				bagBar:SetFrameStrata(self:GetFrameStrata())
				bagBar:SetFrameLevel(self:GetFrameLevel() + 20)
				bagBar:Hide()

				local width, height = bagBar:LayoutButtons("grid", (name == "Main") and 4 or (name == "Bank") and 7, 4, space * 1/2, -space * 1/2)
				bagBar:SetSize(width + space, height + space)
				bagBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -space * 1/2, -space * 1/2)
				bagBar.highlightFunction = highlightFunction
				bagBar.isGlobal = true

				gUI:SetUITemplate(bagBar, "backdrop")
				if (strfind(name, "Bank")) then
					local r, g, b = gUI:GetBackdropBorderColor()
					bagBar:SetBackdropBorderColor(r * 5/4, g * 5/4, b * 2 * 5/4, 1)
					bagBar:SetBackdropColor(C["bank"][1], C["bank"][2], C["bank"][3], 9/10)
				else
					bagBar:SetBackdropColor(C["overlay"][1], C["overlay"][2], C["overlay"][3], 9/10)
					bagBar:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				end
			
				bagBar.Button = CreateFrame("Button", nil, infoFrame)
				bagBar.Button:SetNormalTexture(M("Button", "gUI™ BagIcon"))
				bagBar.Button:SetPushedTexture(M("Button", "gUI™ BagIcon"))
				bagBar.Button:SetHighlightTexture(M("Button", "gUI™ BagIconHighlight"))
				bagBar.Button:SetDisabledTexture(M("Button", "gUI™ BagIconDisabled"))
				bagBar.Button:EnableMouse(true)
				bagBar.Button:SetSize(32, 32)
				bagBar.Button:SetPoint("BOTTOMRIGHT", infoFrame, "BOTTOMRIGHT", 3, 1)
				bagBar.Button:SetScript("OnClick", function() 
					if (bagBar:IsShown()) then
						bagBar:Hide()
					else
						bagBar:Show()
					end
				end)
				bagBar.Button:SetScript("OnEnter", function(self)
					PlaceGameTooltip(self, false)
					GameTooltip:AddLine(L["<Left-Click to toggle display of the Bag Bar>"])
					GameTooltip:Show()
				end)
				bagBar.Button:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
				
				self.bagBar = bagBar
			end
			
			-- restack
			do
				local restackButton = CreateFrame("Button", nil, infoFrame)
				restackButton:SetNormalTexture(M("Button", "gUI™ BagRestackIcon"))
				restackButton:SetDisabledTexture(M("Button", "gUI™ BagRestackIconDisabled"))
				restackButton:SetHighlightTexture(M("Button", "gUI™ BagRestackIconHighlight"))
				restackButton:SetPushedTexture(M("Button", "gUI™ BagRestackIcon"))
				
				restackButton:SetSize(64, 32)
				restackButton:SetPoint("BOTTOMRIGHT", infoFrame, "BOTTOMRIGHT", -38 + 6, -1)
				local this = self
				restackButton:SetScript("OnClick", function(self, button) 
					if (button == "LeftButton") then
						local location = (this.name == "Main") and "bags" or (this.name == "Bank") and "bank"
						
						RestackBags(location)
					end
				end)
				restackButton:SetScript("OnEnter", function(self) 
					PlaceGameTooltip(self, false)
					GameTooltip:AddLine((self:IsEnabled()) and L["<Left-Click to restack the items in your bags>"] or L["Restack is already running, use |cFF4488FF/restackbags resume|r if stuck"])
					GameTooltip:Show()
				end)
				restackButton:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
			end
			
			-- currency display
			if (name == "Main") then
				local currencies = self:SpawnPlugin("TagDisplay", "[currencies]", infoFrame)
				currencies:SetFontObject(gUI_DisplayFontTinyWhite)
				currencies.iconValues = "0:0:2:1"
				currencies:SetPoint("TOPRIGHT", money, "BOTTOMRIGHT", 0, -8)
				currencies:SetJustifyH("RIGHT")

				currencies.clickframe = CreateFrame("Button", nil, infoFrame)
				currencies.clickframe:SetFrameLevel(infoFrame:GetFrameLevel() + 5)
				currencies.clickframe:SetAllPoints(currencies)
			
				currencies.clickframe:SetScript("OnClick", function(self) 
					ToggleCharacter("TokenFrame")
				end)
				
				currencies.clickframe:SetScript("OnEnter", function(self)
					PlaceGameTooltip(self, false)
					GameTooltip:AddLine(L["<Left-Click to open the currency frame>"])
					GameTooltip:Show()
				end)
				
				currencies.clickframe:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)

				self.currencies = currencies
				
				-- this little magic is to make sure the currency display as well as the height of the bag
				-- is updated dynamically when we change our tracked currencies
				local main = self
				local update = function()
					if (main.updating) then 
						return 
					else
						main.updating = true
					end

					currencies.tokens = GetNumWatchedTokens()
					currencies.forceEvent("CURRENCY_DISPLAY_UPDATE") -- we wrote this little function into cargBags. We're outlaws!

					main:ScheduleContentCallback()

					main.updating = nil
				end
				hooksecurefunc("ManageBackpackTokenFrame", update)
				hooksecurefunc("BackpackTokenFrame_Update", update)
			end

			-- bank slot purchasebutton
			if (name == "Bank") then
				local purchase = CreateFrame("Frame", nil, infoFrame)
				
				BankFramePurchaseButton:SetParent(purchase)
				BankFramePurchaseButton:SetFrameStrata(self:GetFrameStrata())
				BankFramePurchaseButton:SetFrameLevel(self:GetFrameLevel() + 5)
				BankFramePurchaseButton:ClearAllPoints()
				BankFramePurchaseButton:SetPoint("RIGHT", self.bagBar.text, "LEFT", -36, 2)
				BankFramePurchaseButton:SetScript("OnClick", function(self) 
					PlaySound("igMainMenuOption")
					StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
				end)
				
				local numSlots, full = GetNumBankSlots()
				local cost = GetBankSlotCost(numSlots)
				local purchasecolor
				BankFrame.nextSlotCost = cost

				if (GetMoney() >= cost) then
					purchasecolor = "|cFFFFFFFF"
				else
					purchasecolor = "|cFFFF0000"
				end			
				purchase.text = purchase:CreateFontString(nil, "OVERLAY")
				purchase.text:SetFontObject(gUI_TextFontSmallBoldOutline)
				purchase.text:SetPoint("RIGHT", BankFramePurchaseButton, "LEFT", -12, 0)
				purchase.text:SetText(purchasecolor..COSTS_LABEL.."  "..module:Tag(("[money:%d]"):format(cost)).."|r")
				
				purchase:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
				purchase:SetScript("OnEvent", function(self) 
					local numSlots, full = GetNumBankSlots()
					local cost = GetBankSlotCost(numSlots)
					local purchasecolor
					BankFrame.nextSlotCost = cost

					if (GetMoney() >= cost) then
						purchasecolor = "|cFFFFFFFF"
					else
						purchasecolor = "|cFFFF0000"
					end	
					
					self.text:SetText(purchasecolor..COSTS_LABEL.."  "..module:Tag(("[money:%d]"):format(cost)).."|r")

					if full then
						self:Hide()
					end

					UpdateBagSlotStatus()
				end)

				if (full) then
					purchase:Hide()
				end
			end
			
			-- category selection dropdowns
			do
				local configMenulist
				local configMenuFrame = CreateFrame("Frame", module:GetName() .. name .. "DropDown", self, "UIDropDownMenuTemplate")
				if (name == "Main") then
					configMenulist = function() 
						local menu = {
							{
								text = L["New Items"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_NewItems"] == 1;
										func = function() module:Toggle("Main_NewItems", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_NewItems"] == 2;
										func = function() module:Toggle("Main_NewItems", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_NewItems"] == 3;
										func = function() module:Toggle("Main_NewItems", 3) end; 
									};
								};
							};
							{
								text = L["Equipment Sets"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Sets"] == 1;
										func = function() module:Toggle("Main_Sets", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Sets"] == 2;
										func = function() module:Toggle("Main_Sets", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Sets"] == 3;
										func = function() module:Toggle("Main_Sets", 3) end; 
									};
								};
							};
							{
								text = Types["Armor"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Armor"] == 1;
										func = function() module:Toggle("Main_Armor", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Armor"] == 2;
										func = function() module:Toggle("Main_Armor", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Armor"] == 3;
										func = function() module:Toggle("Main_Armor", 3) end; 
									};
								};
							};
							{
								text = Types["Weapon"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Weapons"] == 1;
										func = function() module:Toggle("Main_Weapons", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Weapons"] == 2;
										func = function() module:Toggle("Main_Weapons", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Weapons"] == 3;
										func = function() module:Toggle("Main_Weapons", 3) end; 
									};
								};
							};
							{
								text = L["Gizmos"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Gizmos"] == 1;
										func = function() module:Toggle("Main_Gizmos", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Gizmos"] == 2;
										func = function() module:Toggle("Main_Gizmos", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Gizmos"] == 3;
										func = function() module:Toggle("Main_Gizmos", 3) end; 
									};
								};
							};
							{
								text = Types["Quest"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Quest"] == 1;
										func = function() module:Toggle("Main_Quest", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Quest"] == 2;
										func = function() module:Toggle("Main_Quest", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Quest"] == 3;
										func = function() module:Toggle("Main_Quest", 3) end; 
									};
								};
							};
							{
								text = Types["Glyph"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Glyphs"] == 1;
										func = function() module:Toggle("Main_Glyphs", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Glyphs"] == 2;
										func = function() module:Toggle("Main_Glyphs", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Glyphs"] == 3;
										func = function() module:Toggle("Main_Glyphs", 3) end; 
									};
								};
							};
							{
								text = Types["Gem"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Gems"] == 1;
										func = function() module:Toggle("Main_Gems", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Gems"] == 2;
										func = function() module:Toggle("Main_Gems", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Gems"] == 3;
										func = function() module:Toggle("Main_Gems", 3) end; 
									};
								};
							};
							{
								text = Types["Consumable"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Consumables"] == 1;
										func = function() module:Toggle("Main_Consumables", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Consumables"] == 2;
										func = function() module:Toggle("Main_Consumables", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Consumables"] == 3;
										func = function() module:Toggle("Main_Consumables", 3) end; 
									};
								};
							};
							{
								text = Types["Trade Goods"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Trade"] == 1;
										func = function() module:Toggle("Main_Trade", 1) end; };
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Trade"] == 2;
										func = function() module:Toggle("Main_Trade", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Trade"] == 3;
										func = function() module:Toggle("Main_Trade", 3) end; 
									};
								};
							};
							{
								text = Types["Miscellaneous"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Misc"] == 1;
										func = function() module:Toggle("Main_Misc", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Misc"] == 2;
										func = function() module:Toggle("Main_Misc", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Misc"] == 3;
										func = function() module:Toggle("Main_Misc", 3) end; 
									};
								};
							};
							{
								text = Types["Junk"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true;
										checked = db.bagDisplay["Main_Junk"] == 1;
										func = function() module:Toggle("Main_Junk", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Junk"] == 2;
										func = function() module:Toggle("Main_Junk", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Main_Junk"] == 3;
										func = function() module:Toggle("Main_Junk", 3) end; 
									};
								};
							};
						}
						sort(menu, function(a, b) return a.text < b.text end)
						
						return menu
					end

					-- give the panels access. maybe.
					module.GetEasyMenu = configMenulist
					
				elseif (name == "Bank") then
					configMenulist = function() 
						local menu = {
							{
								text = L["Equipment Sets"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Sets"] == 1;
										func = function() module:Toggle("Bank_Sets", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Sets"] == 2;
										func = function() module:Toggle("Bank_Sets", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Sets"] == 3;
										func = function() module:Toggle("Bank_Sets", 3) end; 
									};
								};
							};
							{
								text = Types["Armor"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Armor"] == 1;
										func = function() module:Toggle("Bank_Armor", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Armor"] == 2;
										func = function() module:Toggle("Bank_Armor", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Armor"] == 3;
										func = function() module:Toggle("Bank_Armor", 3) end; 
									};
								};
							};
							{
								text = Types["Weapon"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Weapons"] == 1;
										func = function() module:Toggle("Bank_Weapons", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Weapons"] == 2;
										func = function() module:Toggle("Bank_Weapons", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Weapons"] == 3;
										func = function() module:Toggle("Bank_Weapons", 3) end; 
									};
								};
							};
							{
								text = L["Gizmos"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Gizmos"] == 1;
										func = function() module:Toggle("Bank_Gizmos", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Gizmos"] == 2;
										func = function() module:Toggle("Bank_Gizmos", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Gizmos"] == 3;
										func = function() module:Toggle("Bank_Gizmos", 3) end; 
									};
								};
							};
							{
								text = Types["Quest"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Quest"] == 1;
										func = function() module:Toggle("Bank_Quest", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Quest"] == 2;
										func = function() module:Toggle("Bank_Quest", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Quest"] == 3;
										func = function() module:Toggle("Bank_Quest", 3) end; 
									};
								};
							};
							{
								text = Types["Glyph"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Glyphs"] == 1;
										func = function() module:Toggle("Bank_Glyphs", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Glyphs"] == 2;
										func = function() module:Toggle("Bank_Glyphs", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Glyphs"] == 3;
										func = function() module:Toggle("Bank_Glyphs", 3) end; 
									};
								};
							};
							{
								text = Types["Gem"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Gems"] == 1;
										func = function() module:Toggle("Bank_Gems", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Gems"] == 2;
										func = function() module:Toggle("Bank_Gems", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Gems"] == 3;
										func = function() module:Toggle("Bank_Gems", 3) end; 
									};
								};
							};
							{
								text = Types["Consumable"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Consumables"] == 1;
										func = function() module:Toggle("Bank_Consumables", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Consumables"] == 2;
										func = function() module:Toggle("Bank_Consumables", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Consumables"] == 3;
										func = function() module:Toggle("Bank_Consumables", 3) end; 
									};
								};
							};
							{
								text = Types["Trade Goods"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Trade"] == 1;
										func = function() module:Toggle("Bank_Trade", 1) end; };
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Trade"] == 2;
										func = function() module:Toggle("Bank_Trade", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Trade"] == 3;
										func = function() module:Toggle("Bank_Trade", 3) end; 
									};
								};
							};
							{
								text = Types["Miscellaneous"]; hasArrow = true; notCheckable = true;
								menuList = {
									{ 
										text = SHOW; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Misc"] == 1;
										func = function() module:Toggle("Bank_Misc", 1) end; 
									};
									{ 
										text = BYPASS; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Misc"] == 2;
										func = function() module:Toggle("Bank_Misc", 2) end; 
									};
									{ 
										text = HIDE; tooltipText = MODULE_TOOLTIP; isNotRadio = true; 
										checked = db.bagDisplay["Bank_Misc"] == 3;
										func = function() module:Toggle("Bank_Misc", 3) end; 
									};
								};
							};
						}
						sort(menu, function(a, b) return a.text < b.text end)
						
						return menu
					end
				end
				
				local configButton = CreateFrame("Button", module:GetName() .. name .. "CategorySelectionButton", self)
				configButton:SetNormalTexture(M("Button", "gUI™ ArrowDown"))
				configButton:SetPushedTexture(M("Button", "gUI™ ArrowDown"))
				configButton:SetHighlightTexture(M("Button", "gUI™ ArrowDownHighlight"))
				configButton:SetDisabledTexture(M("Button", "gUI™ ArrowDownDisabled"))
				configButton:SetSize(24, 24)
				configButton:SetPoint("LEFT", title, "RIGHT", 8, 0)
				configButton:SetHitRectInsets(-8, -8, -8, -8)

				configButton:SetScript("OnMouseUp", function(self, button)
					if (button == "LeftButton") then
						EasyMenu(configMenulist(), configMenuFrame, configButton, 10, 0, "MENU", 2)
					end
				end)

				configButton:SetScript("OnEnter", function(self)
					PlaceGameTooltip(self, false)
					GameTooltip:AddLine(L["<Left-Click to open the category selection menu>"])
					GameTooltip:Show()
				end)
				
				configButton:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
			end

		else

			local bName = name
			local close = createCloseButton(self, L["Close this category and keep it hidden"], function(self) 
				module:Toggle(bName, 3)
			end, "TOPRIGHT", -6, -8)
			
			local bypass = CreateFrame("Button", self:GetName() and self:GetName() .. "BypassButton" or nil, self)
			bypass:SetNormalTexture(M("Button", "gUI™ GroupLootPass"))
			bypass:SetPushedTexture(M("Button", "gUI™ GroupLootPassDown"))
			bypass:SetHighlightTexture(M("Button", "gUI™ GroupLootPass"))
			bypass:SetDisabledTexture(M("Button", "gUI™ GroupLootPass"))
			bypass:EnableMouse(true)
			bypass:SetSize(16, 16)

			bypass:SetScript("OnClick", function(self) 
				module:Toggle(bName, 2)
			end)
			
			bypass:SetScript("OnEnter", function(self)
				PlaceGameTooltip(self, false)
				GameTooltip:AddLine(L["Bypass"], 1, 1, 1)
				GameTooltip:AddLine(L["Close this category and show its contents in the main container"])
				GameTooltip:Show()
			end)
			
			bypass:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			bypass:SetScript("OnShow", function(self)
				self:SetFrameLevel(self:GetParent():GetFrameLevel() + 5)
			end)

			bypass:SetPoint("TOPRIGHT", close, "TOPLEFT", -4, 0)
			
			self.UIBypassButton = bypass

			if (db.bagDisplay[name] == 3) or (db.bagDisplay[name] == 2) then
				self:Hide()
			else
				if not(strfind(name, "Bank")) then
					self:Show()
				end
			end
		end
		
		-- our own little fail-safe
		-- updating won't start until this value is true
		self.ReadyToGo = true
	end

	Bags.OnInit = function(self)

		local INVERTED = -1
		
		-- generic hide filters
		local hideEmpty = function(item) return (item.texture ~= nil) end
		local hideJunk = function(item) return not(item.rarity) or (item.rarity > 0) end
		
		-- generic show filters
		local onlyBags = function(item) return (item.bagID >= 0) and (item.bagID <= 4) end
		local onlyBank = function(item) return (item.bagID == -1) or ((item.bagID >= 5) and (item.bagID <= 11)) end
		local onlyConsumables = function(item) return (item.type) and (item.type == Types["Consumable"]) end
		local onlyEpics = function(item) return (item.rarity) and (item.rarity > 3) end
		local onlyGems = function(item) return (item.type) and (item.type == Types["Gem"]) end
		local onlyGlyphs = function(item) return (item.type) and (item.type == Types["Glyph"]) end
		local onlyJunk = function(item) return (item.rarity) and (item.rarity == 0) end
		local onlyRareEpics = function(item) return (item.rarity) and (item.rarity > 3) end

		-- exception list filter
		local check = function(item, category)
			local itemID = GetContainerItemID(item.bagID, item.slotID)
			if (itemID) and (Sorting[itemID]) then
				if (Sorting[itemID] == category) then
					return true, true
				else
					return true, false
				end
			else
				return false, true
			end
		end
		
		-- generic filters
		local onlyQuest = function(item) 
			local a, b = check(item, "quest")
			return (b) and (((item.type) and (item.type == Types["Quest"])) or (a))
		end

		local onlyArmor = function(item) 
			local a, b = check(item, "armor")
			return (b) and (((item.type) and (item.type == Types["Armor"])) or (a))
		end 
		
		local onlyTradeGoods = function(item) 
			local a, b = check(item, "trade")
			return (b) and (((item.type) and (item.type == Types["Trade Goods"])) or (item.type and (item.type == Types["Recipe"]) or (a))) -- or (item.type and (item.type == Types["Battle Pets"])) 
		end
		
		local onlyWeapon = function(item) 
			return (item.type) and (item.type == Types["Weapon"]) 
		end
		
		local onlyGizmos = function(item) 
			local a, b = check(item, "gizmos")
			return (b) and (a)
		end
		
		local onlyMisc = function(item) 
			local a, b = check(item, "misc")
			return (b) and (((item.type) and ((item.type == Types["Miscellaneous"]) or (item.type == Types["Reagent"]))) or (a))
		end
		
		local onlyItemSets = function(item)
			return cargBags.itemKeys["setID"](item)
		end

		local onlyNewItems = function(item)
			local itemLink = GetContainerItemLink(item.bagID, item.slotID)
			if not(itemLink) then -- or (db.autosortnew == 1) then
				return
			end

			local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = strfind(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
			Id, Unique = tonumber(Id), tonumber(Unique)
			
			if (Id) and (Unique) and not(db.bagContents[Id] and db.bagContents[Id][Unique]) then
				newItemsSinceReset[Id] = newItemsSinceReset[Id] or {}
				newItemsSinceReset[Id][Unique] = true

				-- hide it if it's below our chosen rarity, or not in a selected category
				if ((item.rarity) and (item.rarity < db.newitemrarity)) 
					or (onlyItemSets(item))
					or (not(db.newItemDisplay["Main_Armor"]) and (onlyArmor(item)))
					or (not(db.newItemDisplay["Main_Weapons"]) and (onlyWeapon(item)))
					or (not(db.newItemDisplay["Main_Gizmos"]) and (onlyGizmos(item)))
					or (not(db.newItemDisplay["Main_Quest"]) and (onlyQuest(item)))
					or (not(db.newItemDisplay["Main_Glyphs"]) and (onlyGlyphs(item)))
					or (not(db.newItemDisplay["Main_Gems"]) and (onlyGems(item)))
					or (not(db.newItemDisplay["Main_Consumables"]) and (onlyConsumables(item)))
					or (not(db.newItemDisplay["Main_Trade"]) and (onlyTradeGoods(item)))
					or (not(db.newItemDisplay["Main_Misc"]) and (onlyMisc(item)))
					or (not(db.newItemDisplay["Main_Junk"]) and (onlyJunk(item))) then
				
					return
				else
					return true
				end
			else
				return
			end
		end
		
		-- bank filters
		local useBankFilter = function(item, category) 
			local setting = db.bagDisplay[category]
			return ((setting == 1) or (setting == 3)) and onlyBank(item) and hideEmpty(item) 
		end
		
		local Bank_onlyItemSets = function(item) return useBankFilter(item, "Bank_Sets") and onlyItemSets(item) end
		local Bank_onlyGizmos = function(item) return useBankFilter(item, "Bank_Gizmos") and onlyGizmos(item) end
		local Bank_onlyMisc = function(item) return useBankFilter(item, "Bank_Misc") and onlyMisc(item) end
		local Bank_onlyArmor = function(item) return useBankFilter(item, "Bank_Armor") and onlyArmor(item) end
		local Bank_onlyWeapon = function(item) return useBankFilter(item, "Bank_Weapons") and onlyWeapon(item) end
		local Bank_onlyGems = function(item) return useBankFilter(item, "Bank_Gems") and onlyGems(item) end
		local Bank_onlyGlyphs = function(item) return useBankFilter(item, "Bank_Glyphs") and onlyGlyphs(item) end
		local Bank_onlyQuest = function(item) return useBankFilter(item, "Bank_Quest") and onlyQuest(item) end
		local Bank_onlyConsumables = function(item) return useBankFilter(item, "Bank_Consumables") and onlyConsumables(item) end
		local Bank_onlyTradeGoods = function(item) return useBankFilter(item, "Bank_Trade") and onlyTradeGoods(item) end
		
		-- bag filters
		local useBagFilter = function(item, category) 
			local setting = db.bagDisplay[category]
			return ((setting == 1) or (setting == 3)) and onlyBags(item) and hideEmpty(item) 
		end
		
		local Main_NewItems = function(item) return useBagFilter(item, "Main_NewItems") and onlyNewItems(item) end
		local Main_onlyItemSets = function(item) return useBagFilter(item, "Main_Sets") and onlyItemSets(item) end
		local Main_onlyGizmos = function(item) return useBagFilter(item, "Main_Gizmos") and onlyGizmos(item) end
		local Main_onlyJunk = function(item) return useBagFilter(item, "Main_Junk") and onlyJunk(item) end
		local Main_onlyMisc = function(item) return useBagFilter(item, "Main_Misc") and onlyMisc(item) end
		local Main_onlyArmor = function(item) return useBagFilter(item, "Main_Armor") and onlyArmor(item) end
		local Main_onlyWeapon = function(item) return useBagFilter(item, "Main_Weapons") and onlyWeapon(item) end
		local Main_onlyGems = function(item) return useBagFilter(item, "Main_Gems") and onlyGems(item) end
		local Main_onlyGlyphs = function(item) return useBagFilter(item, "Main_Glyphs") and onlyGlyphs(item) end
		local Main_onlyQuest = function(item) return useBagFilter(item, "Main_Quest") and onlyQuest(item) end
		local Main_onlyConsumables = function(item) return useBagFilter(item, "Main_Consumables") and onlyConsumables(item) end
		local Main_onlyTradeGoods = function(item) return useBagFilter(item, "Main_Trade") and onlyTradeGoods(item) end

		-- bank containers
		local banksets = Container:New("Bank_Sets", { Bags = "bankframe+bank"; Name = L["Equipment Sets"]; Columns = db.bankWidth[bankMap.Bank_Sets]; })
			banksets:SetFilter(Bank_onlyItemSets, true)
			banksets:Hide()

		local bankgizmos = Container:New("Bank_Gizmos", { Bags = "bankframe+bank"; Name = L["Gizmos"]; Columns = db.bankWidth[bankMap.Bank_Gizmos]; })
			bankgizmos:SetFilter(Bank_onlyGizmos, true)
			bankgizmos:Hide()

		local bankmisc = Container:New("Bank_Misc", { Bags = "bankframe+bank"; Name = Types["Miscellaneous"]; Columns = db.bankWidth[bankMap.Bank_Misc]; })
			bankmisc:SetFilter(Bank_onlyMisc, true)
			bankmisc:Hide()

		local bankarmor = Container:New("Bank_Armor", { Bags = "bankframe+bank"; Name = Types["Armor"]; Columns = db.bankWidth[bankMap.Bank_Armor]; })
			bankarmor:SetFilter(Bank_onlyArmor, true)
			bankarmor:Hide()

		local bankweapons = Container:New("Bank_Weapons", { Bags = "bankframe+bank"; Name = Types["Weapon"]; Columns = db.bankWidth[bankMap.Bank_Weapons]; })
			bankweapons:SetFilter(Bank_onlyWeapon, true)
			bankweapons:Hide()

		local bankgems = Container:New("Bank_Gems", { Bags = "bankframe+bank"; Name = Types["Gem"]; Columns = db.bankWidth[bankMap.Bank_Gems]; })
			bankgems:SetFilter(Bank_onlyGems, true)
			bankgems:Hide()

		local bankglyphs = Container:New("Bank_Glyphs", { Bags = "bankframe+bank"; Name = Types["Glyph"]; Columns = db.bankWidth[bankMap.Bank_Glyphs]; })
			bankglyphs:SetFilter(Bank_onlyGlyphs, true)
			bankglyphs:Hide()

		local bankquest = Container:New("Bank_Quest", { Bags = "bankframe+bank"; Name = Types["Quest"]; Columns = db.bankWidth[bankMap.Bank_Quest]; })
			bankquest:SetFilter(Bank_onlyQuest, true)
			bankquest:Hide()

		local bankconsumables = Container:New("Bank_Consumables", { Bags = "bankframe+bank"; Name = Types["Consumable"]; Columns = db.bankWidth[bankMap.Bank_Consumables]; })
			bankconsumables:SetFilter(Bank_onlyConsumables, true)
			bankconsumables:Hide()

		local banktrade = Container:New("Bank_Trade", { Bags = "backpack+bags"; Name = Types["Trade Goods"]; Columns = db.bankWidth[bankMap.Bank_Trade]; })
			banktrade:SetFilter(Bank_onlyTradeGoods, true)
			banktrade:Hide()

		local bank = Container:New("Bank", { Bags = "bankframe+bank"; Name = L["Bank"]; Columns = 17; Movable = true; })
			bank:SetFilter(onlyBank, true)
			bank:Hide()

		-- bag containers
		local mainnew = Container:New("Main_NewItems", { Bags = "backpack+bags"; Name = L["New Items"]; Columns = db.bagWidth; })
			mainnew:SetFilter(Main_NewItems, true)
			
		local mainsets = Container:New("Main_Sets", { Bags = "backpack+bags"; Name = L["Equipment Sets"]; Columns = db.bagWidth; })
			mainsets:SetFilter(Main_onlyItemSets, true)

		local maingizmos = Container:New("Main_Gizmos", { Bags = "backpack+bags"; Name = L["Gizmos"]; Columns = db.bagWidth; })
			maingizmos:SetFilter(Main_onlyGizmos, true)

		local mainjunk = Container:New("Main_Junk", { Bags = "backpack+bags"; Name = Types["Junk"]; Columns = db.bagWidth; })
			mainjunk:SetFilter(Main_onlyJunk, true)

		local mainquest = Container:New("Main_Quest", { Bags = "backpack+bags"; Name = Types["Quest"]; Columns = db.bagWidth; })
			mainquest:SetFilter(Main_onlyQuest, true)

		local mainmisc = Container:New("Main_Misc", { Bags = "backpack+bags"; Name = Types["Miscellaneous"]; Columns = db.bagWidth; })
			mainmisc:SetFilter(Main_onlyMisc, true)

		local mainarmor = Container:New("Main_Armor", { Bags = "backpack+bags"; Name = Types["Armor"]; Columns = db.bagWidth; })
			mainarmor:SetFilter(Main_onlyArmor, true)
			mainarmor:SetFilter(hideJunk, true)

		local mainweapons = Container:New("Main_Weapons", { Bags = "backpack+bags"; Name = Types["Weapon"]; Columns = db.bagWidth; })
			mainweapons:SetFilter(Main_onlyWeapon, true)

		local maingems = Container:New("Main_Gems", { Bags = "backpack+bags"; Name = Types["Gem"]; Columns = db.bagWidth; })
			maingems:SetFilter(Main_onlyGems, true)

		local mainglyphs = Container:New("Main_Glyphs", { Bags = "backpack+bags"; Name = Types["Glyph"]; Columns = db.bagWidth; })
			mainglyphs:SetFilter(Main_onlyGlyphs, true)

		local mainconsumables = Container:New("Main_Consumables", { Bags = "backpack+bags"; Name = Types["Consumable"]; Columns = db.bagWidth; })
			mainconsumables:SetFilter(Main_onlyConsumables, true)

		local maintrade = Container:New("Main_Trade", { Bags = "backpack+bags"; Name = Types["Trade Goods"]; Columns = db.bagWidth; })
			maintrade:SetFilter(Main_onlyTradeGoods, true)

		local main = Container:New("Main", {  Bags = "backpack+bags"; Name = L["Main"]; Columns = db.bagWidth; Movable = true; })
			main:SetFilter(onlyBags, true)
	
		main:SetPoint(unpack(db.points["Main"]))
		
		mainnew:SetPoint("BOTTOMRIGHT", mainjunk, "TOPRIGHT", 0, 0)
		mainmisc:SetPoint("BOTTOMRIGHT", maintrade, "TOPRIGHT", 0, 0)
		maintrade:SetPoint("BOTTOMRIGHT", mainconsumables, "TOPRIGHT", 0, 0)
		mainconsumables:SetPoint("BOTTOMRIGHT", main, "TOPRIGHT", 0, 0) -- bottom top container
		mainsets:SetPoint("BOTTOMRIGHT", main, "BOTTOMLEFT", 0, 0) -- bottom side container
		mainarmor:SetPoint("BOTTOMRIGHT", mainsets, "TOPRIGHT", 0, 0)
		mainweapons:SetPoint("BOTTOMRIGHT", mainarmor, "TOPRIGHT", 0, 0)
		maingems:SetPoint("BOTTOMRIGHT", mainweapons, "TOPRIGHT", 0, 0)
		mainglyphs:SetPoint("BOTTOMRIGHT", maingems, "TOPRIGHT", 0, 0)
		mainquest:SetPoint("BOTTOMRIGHT", mainglyphs, "TOPRIGHT", 0, 0)
		maingizmos:SetPoint("BOTTOMRIGHT", mainquest, "TOPRIGHT", 0, 0)
		mainjunk:SetPoint("BOTTOMRIGHT", maingizmos, "TOPRIGHT", 0, 0)

		bank:SetPoint(unpack(db.points["Bank"]))
		
		-- banksets:SetPoint("TOPLEFT", bank, "BOTTOMLEFT", 0, 0) -- top left bottom container
		-- bankarmor:SetPoint("TOPLEFT", banksets, "BOTTOMLEFT", 0, 0)
		-- bankweapons:SetPoint("TOPLEFT", bankarmor, "BOTTOMLEFT", 0, 0)
		-- bankconsumables:SetPoint("TOPLEFT", bank, "TOPRIGHT", 0, 0) -- top side container
		-- banktrade:SetPoint("TOPLEFT", bankconsumables, "BOTTOMLEFT", 0, 0)
		-- bankgems:SetPoint("TOPRIGHT", bank, "BOTTOMRIGHT", 0, 0) -- top right bottom container
		-- bankglyphs:SetPoint("TOPRIGHT", bankgems, "BOTTOMRIGHT", 0, 0)
		-- bankquest:SetPoint("TOPRIGHT", bankglyphs, "BOTTOMRIGHT", 0, 0)
		-- bankmisc:SetPoint("TOPRIGHT", bankquest, "BOTTOMRIGHT", 0, 0)
		-- bankgizmos:SetPoint("TOPRIGHT", bankmisc, "BOTTOMRIGHT", 0, 0)

		-- column 1
		banksets:SetPoint("TOPLEFT", bank, "BOTTOMLEFT", 0, 0) 
		bankarmor:SetPoint("TOPLEFT", banksets, "BOTTOMLEFT", 0, 0)
		bankweapons:SetPoint("TOPLEFT", bankarmor, "BOTTOMLEFT", 0, 0)
		
		-- column 2
		bankgems:SetPoint("TOPLEFT", banksets, "TOPRIGHT", 0, 0) 
		bankglyphs:SetPoint("TOPRIGHT", bankgems, "BOTTOMRIGHT", 0, 0)
		bankquest:SetPoint("TOPRIGHT", bankglyphs, "BOTTOMRIGHT", 0, 0)
		bankmisc:SetPoint("TOPRIGHT", bankquest, "BOTTOMRIGHT", 0, 0)
		bankgizmos:SetPoint("TOPRIGHT", bankmisc, "BOTTOMRIGHT", 0, 0)

		-- column 3
		bankconsumables:SetPoint("TOPLEFT", bankgems, "TOPRIGHT", 0, 0) 
		banktrade:SetPoint("TOPLEFT", bankconsumables, "BOTTOMLEFT", 0, 0)
		

		main:HookScript("OnShow", function() 
			if (db.autorestack) then
				RestackRun("bags", nil, true)
			end
		end)
	end

	Bags.OnBankOpened = function(self)
		-- the order here is crucial, as each category "grabs" their items once opened. 
		if (db.bagDisplay["Bank_Sets"] == 1) then self:GetContainer("Bank_Sets"):Show() end
		if (db.bagDisplay["Bank_Misc"] == 1) then self:GetContainer("Bank_Misc"):Show() end
		if (db.bagDisplay["Bank_Armor"] == 1) then self:GetContainer("Bank_Armor"):Show() end
		if (db.bagDisplay["Bank_Weapons"] == 1) then self:GetContainer("Bank_Weapons"):Show() end
		if (db.bagDisplay["Bank_Gizmos"] == 1) then self:GetContainer("Bank_Gizmos"):Show() end
		if (db.bagDisplay["Bank_Quest"] == 1) then self:GetContainer("Bank_Quest"):Show() end
		if (db.bagDisplay["Bank_Glyphs"] == 1) then self:GetContainer("Bank_Glyphs"):Show() end
		if (db.bagDisplay["Bank_Gems"] == 1) then self:GetContainer("Bank_Gems"):Show() end
		if (db.bagDisplay["Bank_Trade"] == 1) then self:GetContainer("Bank_Trade"):Show() end
		if (db.bagDisplay["Bank_Consumables"] == 1) then self:GetContainer("Bank_Consumables"):Show() end
		
		-- the main bank container can't be bypassed or hidden, always show
		self:GetContainer("Bank"):Show()
	end

	Bags.OnBankClosed = function(self)
		self:GetContainer("Bank"):Hide()
		self:GetContainer("Bank_Sets"):Hide()
		self:GetContainer("Bank_Armor"):Hide()
		self:GetContainer("Bank_Weapons"):Hide()
		self:GetContainer("Bank_Gizmos"):Hide()
		self:GetContainer("Bank_Quest"):Hide()
		self:GetContainer("Bank_Glyphs"):Hide()
		self:GetContainer("Bank_Gems"):Hide()
		self:GetContainer("Bank_Consumables"):Hide()
		self:GetContainer("Bank_Trade"):Hide()
		self:GetContainer("Bank_Misc"):Hide()
	end

	Bags.SetScale = function(self, scale)
		self:GetContainer("Bank"):SetScale(scale)
		self:GetContainer("Bank_Sets"):SetScale(scale)
		self:GetContainer("Bank_Armor"):SetScale(scale)
		self:GetContainer("Bank_Weapons"):SetScale(scale)
		self:GetContainer("Bank_Gizmos"):SetScale(scale)
		self:GetContainer("Bank_Quest"):SetScale(scale)
		self:GetContainer("Bank_Glyphs"):SetScale(scale)
		self:GetContainer("Bank_Gems"):SetScale(scale)
		self:GetContainer("Bank_Consumables"):SetScale(scale)
		self:GetContainer("Bank_Trade"):SetScale(scale)
		self:GetContainer("Bank_Misc"):SetScale(scale)

		self:GetContainer("Main"):SetScale(scale)
		self:GetContainer("Main_Sets"):SetScale(scale)
		self:GetContainer("Main_Armor"):SetScale(scale)
		self:GetContainer("Main_Weapons"):SetScale(scale)
		self:GetContainer("Main_Gizmos"):SetScale(scale)
		self:GetContainer("Main_Quest"):SetScale(scale)
		self:GetContainer("Main_Glyphs"):SetScale(scale)
		self:GetContainer("Main_Gems"):SetScale(scale)
		self:GetContainer("Main_Consumables"):SetScale(scale)
		self:GetContainer("Main_Trade"):SetScale(scale)
		self:GetContainer("Main_Misc"):SetScale(scale)
		self:GetContainer("Main_Junk"):SetScale(scale)
		self:GetContainer("Main_NewItems"):SetScale(scale)
	end
end

module.SaveBagContents = function(self)
	currentBagContents = self:DuplicateTable(db.bagContents)
end

module.RestoreBagContents = function(self)
	db.bagContents = self:DuplicateTable(currentBagContents)
end

module.RestoreDefaults = function(self)
	-- backup the remembered  
	self:SaveBagContents()
	
	-- restore all defaults
	self:ResetCurrentOptionsSetToDefaults()
	
	-- repopulate the remembered items table
	self:RestoreBagContents()
	
	-- reposition main containers
	Bags:GetContainer("Main"):SetPoint(unpack(db.points["Main"]))
	Bags:GetContainer("Bank"):SetPoint(unpack(db.points["Bank"]))

	-- update all container content
	self:updateAllLayouts()
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults, true) -- get the gUI environment 
	
	db.showshade = true
	db.showgloss = true
	
	-- fix the "issue" where B is bound to "open all bags" and doesn't toggle the bags
	local fixBagBind = function()
		local keys
		local firstSet = GetCurrentBindingSet()
		local oldAction, newAction = "OPENALLBAGS", "TOGGLEBACKPACK"
		
		-- set 1 = account, 2 = character
		for bindingSet = 1, 2 do
			LoadBindings(bindingSet)
			keys = { GetBindingKey(oldAction) }
			if (keys) then
				local key
				for i = 1, #keys do
					key = keys[i]
					if (key) and (key == "B") then
						SetBinding(keys[i], newAction)
						SaveBindings(bindingSet)
					end
				end
			end
		end

		-- load the original binding set
		if (firstSet == 1) or (firstSet == 2) then
			LoadBindings(firstSet)
		end
	end
	self:RegisterEvent("PLAYER_ENTERING_WORLD", fixBagBind)
	self:RegisterEvent("VARIABLES_LOADED", fixBagBind)
	
	-- make sure gActionButtons-3.0 is ready to go
	gUI:SetUpButtonStyling()

	init_cargBags(self)
	
	self:RegisterEvent("CHAT_MSG_LOOT", restackBags)
	self:RegisterEvent("BANKFRAME_OPENED", restackBank)
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY", updateAllContainers)
	self:RegisterBucketEvent({
--		"BAG_UPDATE",
--		"PLAYERBANKBAGSLOTS_CHANGED",
--		"PLAYERBANKSLOTS_CHANGED",
		"AUCTION_MULTISELL_UPDATE",
		"CHAT_MSG_LOOT",
		"GUILDBANKBAGSLOTS_CHANGED",
		"PLAYER_INVENTORY_CHANGED",
		"TRADE_SKILL_UPDATE"
	}, updateAllContainers, 0.1)
	
	local slashHandler = function(cmd, opt)
		if (cmd == "lock") then
			db.locked = true
		elseif (cmd == "unlock") then
			db.locked = false
		elseif (cmd == "toggle") then
			db.locked = not(db.locked)
		elseif (cmd == "reset") then
			db.locked = true
			db.points["Main"] = defaults.points["Main"]
			if (Bags:GetContainer("Main")) then 
				Bags:GetContainer("Main"):ClearAllPoints()
				Bags:GetContainer("Main"):SetPoint(unpack(db.points["Main"]))
			end
			db.points["Bank"] = defaults.points["Bank"]
			if (Bags:GetContainer("Bank")) then 
				Bags:GetContainer("Bank"):ClearAllPoints()
				Bags:GetContainer("Bank"):SetPoint(unpack(db.points["Bank"]))
			end
			for container, _ in pairs(db.bagDisplay) do
				db.bagDisplay[container] = defaults.bagDisplay[container]
				module:Toggle(container, db.bagDisplay[container])
			end
		elseif (cmd == "scale") then
			opt = tonumber(opt)
			if (opt >= MIN_SCALE) and (opt <= MAX_SCALE) then
				db.scale = opt
				if (Bags:GetContainer("Main")) then
					Bags:SetScale(opt)
				end
			else
				print(("/scalebags x |cffff0000(%.1f <= x <= %.1f)|r"):format(MIN_SCALE, MAX_SCALE))
			end
		end
	end
	
	self:CreateChatCommand("scalebags", function(opt) slashHandler("scale", opt) end)
	self:CreateChatCommand("resetbags", function() slashHandler("reset") end)
	self:CreateChatCommand("lockbags", function() slashHandler("lock") end)
	self:CreateChatCommand("togglebags", function() slashHandler("toggle") end)
	self:CreateChatCommand("unlockbags", function() slashHandler("unlock") end)
	self:CreateChatCommand("compressbags", function() 
		if not(db.compressemptyspace) then
			db.compressemptyspace = true
			print(L["Empty bag slots will now be compressed"])
			Bags:GetContainer("Main"):OnContentsChanged()
			Bags:GetContainer("Bank"):OnContentsChanged()
			updateAllContainers()
		else
			db.compressemptyspace = false
			print(L["Empty bag slots will no longer be compressed"])
--			Bags:GetContainer("Main"):OnContentsChanged()
--			Bags:GetContainer("Bank"):OnContentsChanged()
			self:updateAllLayouts()
			self:RefreshBlizzardOptionsMenu()
		end
	end)
	self:CreateChatCommand("restackbags", function(opt) 
		if (opt == "resume") then
			RestackBags("resume") 
		end
	end)
	self:CreateChatCommand("setnewitemthreshold", function(rarity)
		rarity = tonumber(rarity)
		if not(rarity) or (floor(rarity) < 0) or (floor(rarity) > 7) then
			return
		end
		db.newitemrarity = floor(rarity)
		self:updateAllLayouts()
		self:RefreshBlizzardOptionsMenu()
	end)

	-- mainly for development purposes
	self:CreateChatCommand("resetnewitems", function() ResetNewItems() end)
	self:CreateChatCommand("forgetallitems", function() 
		db.scannedSinceReset = true
		wipe(db.bagContents)
		wipe(currentBagContents)
		updateAllContainers()
	end)

	-- kill blizzard options
	gUI:KillOption(true, InterfaceOptionsDisplayPanelShowFreeBagSpace)

	-- options menu
	do
		SHOW = "|cFF00FF00" .. L["Show"] .. "|r"
		BYPASS = "|cFFFFD100" .. L["Bypass"] .. "|r"
		HIDE = "|cFFFF0000" .. L["Hide"] .. "|r"
		MODULE_TOOLTIP = { 
			L["Container Display"], " ", 
			SHOW, "|cFFFFFFFF" .. L["Show this category and its contents"] .. "|r", " ", 
			BYPASS, "|cFFFFFFFF" .. L["Hide this category, and display its contents in the main container instead"] .. "|r", " ", 
			HIDE, "|cFFFFFFFF" .. L["Hide this category and all its contents completely"] .. "|r"
		}

		local menuTable = {
			{
				type = "group";
				name = module:GetName();
				order = 1;
				virtual = true;
				children = {
					{ -- title
						type = "widget";
						element = "Title";
						order = 1;
						msg = L["Bags"];
					};
					{ -- subtext
						type = "widget";
						element = "Text";
						order = 2;
						msg = L["A character can store items in its backpack, bags and bank. Here you can configure the appearance and behavior of these."];
					};

					{ -- general
						type = "widget";
						element = "Header";
						order = 10;
						msg = L["General"];
					};
					{ -- lock bags
						type = "widget";
						element = "CheckButton";
						name = "lockBags";
						order = 15;
						msg = L["Lock the bags into place"];
						desc = nil;
						set = function(self) 
							db.locked = not(db.locked)
						end;
						get = function() return db.locked end;
						init = function(self) 
						end;
					};
					{ -- show durability
						type = "widget";
						element = "CheckButton";
						name = "showDurability";
						order = 20;
						msg = L["Show Durability"];
						desc = L["This will display durability on damaged items in your bags"];
						set = function(self) 
							db.showDurability = not(db.showDurability)
							module:updateAllLayouts()
						end;
						get = function() return db.showDurability end;
						init = function(self) 
						end;
					};
					{ -- color unequippable items red
						type = "widget";
						element = "CheckButton";
						name = "colorNoEquip";
						order = 25;
						msg = L["Color unequippable items red"];
						desc = L["This will color equippable items in your bags that you are unable to equip red"];
						set = function(self) 
							db.colorNoEquip = not(db.colorNoEquip)
							module:updateAllLayouts()
						end;
						get = function() return db.colorNoEquip end;
						init = function(self) 
						end;
					};

					{ -- presets
						type = "widget";
						element = "Header";
						order = 100;
						msg = L["Layout Presets"];
					};
					-- { -- presets description
						-- type = "widget";
						-- element = "Text";
						-- width = "half";
						-- order = 105;
						-- msg = L[""];
					-- };
					-- { -- all in one description
						-- type = "widget";
						-- element = "Text";
						-- width = "half";
						-- order = 110;
						-- msg = L["The bags can be configured to work as one large 'all-in-one' container, with no categories, no sorting and no empty space compression. If you wish to have that type of layout, click the button:"];
					-- };
					{ -- all in one shortcut
						type = "widget";
						order = 115;
						name = "applyAllInOne";
						msg = L["Apply 'All In One' Layout"];
						desc = L["Click here to automatically configure the bags and bank to be displayed as large unsorted containers."];
						element = "Button";
						set = function(self)
							db.orderSort = false
							db.compressemptyspace = false
							db.bagWidth = 16
							for i,v in pairs(db.bagDisplay) do
								db.bagDisplay[i] = 2
								local container = Bags:GetContainer(name)
								if (container) then
									container:OnContentsChanged()
								end
							end
							module:updateAllLayouts()
							module:RefreshBlizzardOptionsMenu()
						end;
						init = function(self)
							self:SetWidth(self:GetFontString():GetStringWidth() + 48)
						end;
					};
					-- { -- default layout description
						-- type = "widget";
						-- element = "Text";
						-- width = "half";
						-- order = 120;
						-- msg = L["The bags can be configured to work as one large 'all-in-one' container, with no categories, no sorting and no empty space compression. If you wish to have that type of layout, click the button:"];
					-- };
					{ -- default layout shortcut
						type = "widget";
						order = 125;
						name = "applyGoldpawsLayout";
						msg = L["Apply %s's Layout"]:format(L["Goldpaw"]);
						desc = L["Click here to apply the default layout with categories, sorting and empty space compression."];
						element = "Button";
						set = function(self)
							db.orderSort = defaults.orderSort
							db.compressemptyspace = defaults.compressemptyspace
							db.bagWidth = defaults.bagWidth
							for i,v in pairs(db.bagDisplay) do
								db.bagDisplay[i] = defaults.bagDisplay[i]
								local container = Bags:GetContainer(name)
								if (container) then
									container:OnContentsChanged()
								end
							end
							module:updateAllLayouts()
							module:RefreshBlizzardOptionsMenu()
						end;
						init = function(self)
							self:SetWidth(self:GetFontString():GetStringWidth() + 48)
						end;
					};

					{ -- buttonsize and bagscale
						type = "group";
						order = 130;
						name = "buttonsize";
						virtual = true;
						children = {
							{
								type = "widget";
								element = "Header";
								order = 10;
								width = "half";
								msg = L["Slot Button Size"];
							};
							{ -- bag scale text
								type = "widget";
								element = "Header";
								width = "half";
								order = 11;
								msg = L["Bag Scale"];
							};
							{ -- button size
								type = "widget";
								element = "Slider";
								name = "buttonSize";
								order = 50;
								width = "half";
								msg = nil;
								desc = L["Sets the size of the slot buttons in your bags. Does not affect the overall scale."];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.buttonSize = value
										
										module:updateAllLayouts()
									end
								end;
								get = function(self)
									return db.buttonSize
								end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_BUTTON_SIZE, MAX_BUTTON_SIZE, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
							{ -- bag scale
								type = "widget";
								element = "Slider";
								name = "bagScale";
								order = 51;
								width = "half";
								msg = nil;
								desc = L["Sets the overall scale of the bags"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%.1f"):format(value))
										db.scale = value
										
										if (Bags:GetContainer("Main")) then
											Bags:SetScale(value)
										end
									end
								end;
								get = function(self)
									return db.scale
								end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_SCALE, MAX_SCALE, self:get()
									self:SetValue(value)
									self:SetValueStep(0.1)
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)
									
									self.text:SetText(("%.1f"):format(value))

									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
						};
					};			
					
					{ -- bag slot width text
						type = "widget";
						element = "Header";
						width = "full";
						order = 205;
						msg = L["Bag Width"];
					};
					{ -- bag slot width
						type = "widget";
						element = "Slider";
						name = "bagContainerSlotWidth";
						order = 210;
						width = "full";
						msg = nil;
						desc = L["Sets the number of horizontal slots in the bag containers. Does not apply to the bank."];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.bagWidth = value
								
								module:updateAllLayouts()
							end
						end;
						get = function(self)
							return db.bagWidth
						end;
						ondisable = function(self)
							self:SetAlpha(3/4)
							self.low:SetTextColor(unpack(C["disabled"]))
							self.high:SetTextColor(unpack(C["disabled"]))
							self.text:SetTextColor(unpack(C["disabled"]))
							
							self:EnableMouse(false)
						end;
						onenable = function(self)
							self:SetAlpha(1)
							self.low:SetTextColor(unpack(C["value"]))
							self.high:SetTextColor(unpack(C["value"]))
							self.text:SetTextColor(unpack(C["index"]))
							
							self:EnableMouse(true)
						end;
						init = function(self)
							local min, max, value = 9, 16, self:get()
							self:SetMinMaxValues(min, max)
							self.low:SetText(min)
							self.high:SetText(max)

							self:SetValue(value)
							self:SetValueStep(1)
							self.text:SetText(("%d"):format(value))
							
							if (self:IsEnabled()) then
								self:onenable()
							else
								self:ondisable()
							end
						end;
					};
					
					{ -- bank column 1 text
						type = "widget";
						element = "Header";
						width = "half";
						order = 215;
						msg = L["Bank Column %d Width"]:format(1);
					};
					{ -- bank column 2 text
						type = "widget";
						element = "Header";
						width = "half";
						order = 220;
						msg = L["Bank Column %d Width"]:format(2);
					}; 
					{ -- bank column 1 width
						type = "widget";
						element = "Slider";
						name = "bankColumn1SlotWidth";
						order = 221;
						width = "half";
						msg = nil;
						desc = L["Sets the number of horizontal slots in the given column of bank containers."];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.bankWidth[1] = value
								
								module:updateAllLayouts()
							end
						end;
						get = function(self)
							return db.bankWidth[1]
						end;
						ondisable = function(self)
							self:SetAlpha(3/4)
							self.low:SetTextColor(unpack(C["disabled"]))
							self.high:SetTextColor(unpack(C["disabled"]))
							self.text:SetTextColor(unpack(C["disabled"]))
							
							self:EnableMouse(false)
						end;
						onenable = function(self)
							self:SetAlpha(1)
							self.low:SetTextColor(unpack(C["value"]))
							self.high:SetTextColor(unpack(C["value"]))
							self.text:SetTextColor(unpack(C["index"]))
							
							self:EnableMouse(true)
						end;
						init = function(self)
							local min, max, value = 8, 24, self:get()
							self:SetMinMaxValues(min, max)
							self.low:SetText(min)
							self.high:SetText(max)

							self:SetValue(value)
							self:SetValueStep(1)
							self.text:SetText(("%d"):format(value))
							
							if (self:IsEnabled()) then
								self:onenable()
							else
								self:ondisable()
							end
						end;
					};
					{ -- bank column 2 width
						type = "widget";
						element = "Slider";
						name = "bankColumn2SlotWidth";
						order = 222;
						width = "half";
						msg = nil;
						desc = L["Sets the number of horizontal slots in the given column of bank containers."];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.bankWidth[2] = value
								
								module:updateAllLayouts()
							end
						end;
						get = function(self)
							return db.bankWidth[2]
						end;
						ondisable = function(self)
							self:SetAlpha(3/4)
							self.low:SetTextColor(unpack(C["disabled"]))
							self.high:SetTextColor(unpack(C["disabled"]))
							self.text:SetTextColor(unpack(C["disabled"]))
							
							self:EnableMouse(false)
						end;
						onenable = function(self)
							self:SetAlpha(1)
							self.low:SetTextColor(unpack(C["value"]))
							self.high:SetTextColor(unpack(C["value"]))
							self.text:SetTextColor(unpack(C["index"]))
							
							self:EnableMouse(true)
						end;
						init = function(self)
							local min, max, value = 8, 24, self:get()
							self:SetMinMaxValues(min, max)
							self.low:SetText(min)
							self.high:SetText(max)

							self:SetValue(value)
							self:SetValueStep(1)
							self.text:SetText(("%d"):format(value))
							
							if (self:IsEnabled()) then
								self:onenable()
							else
								self:ondisable()
							end
						end;
					};

					{ -- bank column 3 text
						type = "widget";
						element = "Header";
						width = "full";
						order = 225;
						msg = L["Bank Column %d Width"]:format(3);
					};
					{ -- bank column 3 width
						type = "widget";
						element = "Slider";
						name = "bankColumn3SlotWidth";
						order = 226;
						width = "full";
						msg = nil;
						desc = L["Sets the number of horizontal slots in the given column of bank containers."];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.bankWidth[3] = value
								
								module:updateAllLayouts()
							end
						end;
						get = function(self)
							return db.bankWidth[3]
						end;
						ondisable = function(self)
							self:SetAlpha(3/4)
							self.low:SetTextColor(unpack(C["disabled"]))
							self.high:SetTextColor(unpack(C["disabled"]))
							self.text:SetTextColor(unpack(C["disabled"]))
							
							self:EnableMouse(false)
						end;
						onenable = function(self)
							self:SetAlpha(1)
							self.low:SetTextColor(unpack(C["value"]))
							self.high:SetTextColor(unpack(C["value"]))
							self.text:SetTextColor(unpack(C["index"]))
							
							self:EnableMouse(true)
						end;
						init = function(self)
							local min, max, value = 8, 24, self:get()
							self:SetMinMaxValues(min, max)
							self.low:SetText(min)
							self.high:SetText(max)

							self:SetValue(value)
							self:SetValueStep(1)
							self.text:SetText(("%d"):format(value))
							
							if (self:IsEnabled()) then
								self:onenable()
							else
								self:ondisable()
							end
						end;
					};
					
					
					{ -- restack
						type = "widget";
						element = "Header";
						order = 230;
						msg = L["Restack"];
					};
					{ -- restack on bag/bank open
						type = "widget";
						element = "CheckButton";
						order = 235;
						name = "restackOnOpen";
						msg = L["Automatically restack items when opening your bags or the bank"];
						desc = nil;
						set = function(self) 
							db.autorestack = not(db.autorestack)
						end;
						get = function() return db.autorestack end;
						init = function(self) 
						end;
					};
					{ -- restack when looting/crafting
						type = "widget";
						element = "CheckButton";
						order = 240;
						name = "restackOnCraftedOrLoot";
						msg = L["Automatically restack when looting or crafting items"];
						desc = nil;
						set = function(self) 
							db.autorestackcrafted = not(db.autorestackcrafted)
						end;
						get = function() return db.autorestackcrafted end;
						init = function(self) 
						end;
					};
					{ -- sorting
						type = "widget";
						element = "Header";
						order = 245;
						msg = L["Sorting"];
					};
					{ -- sort container contents
						type = "widget";
						element = "CheckButton";
						order = 250;
						name = "sortContainerContents";
						msg = L["Sort the items within each container"];
						desc = L["Sorts the items inside each container according to rarity, item level, name and quanity. Disable to have the items remain in place."];
						set = function(self, value) 
							if (value) then
								db.orderSort = value
							else
								db.orderSort = not(db.orderSort)
							end
							
							self:onrefresh()
							module:updateAllLayouts()
						end;
						onrefresh = function(self) 
							if not(db.orderSort) then
								if (db.compressemptyspace) then
									db.compressemptyspace = false
									self.parent.child.compressEmptySlots:SetChecked(false)
								end
								
								if (self.parent.child.compressEmptySlots:IsEnabled()) then
									self.parent.child.compressEmptySlots:Disable()
								end
							else
								if not(self.parent.child.compressEmptySlots:IsEnabled()) then
									self.parent.child.compressEmptySlots:Enable()
								end
							end
						end;
						get = function() return db.orderSort end;
						init = function(self) self:onrefresh() end;
					};
					{ -- compress empty slots
						type = "widget";
						element = "CheckButton";
						order = 255;
						name = "compressEmptySlots";
						indented = true;
						msg = L["Compress empty bag slots"];
						desc = L["Compress empty slots down to maximum one row of each type."];
						set = function(self) 
							db.compressemptyspace = not(db.compressemptyspace)
							
							module:updateAllLayouts()
						end;
						get = function() return db.compressemptyspace end;
						init = function(self) 
						end;
						ondisable = function(self)
							self:SetAlpha(3/4)
							self.text:SetTextColor(unpack(C["disabled"]))
							self:EnableMouse(false)
						end;
						onenable = function(self)
							self:SetAlpha(1)
							self.text:SetTextColor(unpack(C["index"]))
							self:EnableMouse(true)
						end;
					};
					{ -- bags category selection
						type = "group";
						order = 260;
						name = "bagDisplay";
						virtual = true;
						children = {
							{
								type = "widget";
								element = "Title";
								order = 10;
								width = "full";
								msg = L["Categories"] .. " (" .. L["Bags"] .. ")";
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = L["New Items"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_NewItems", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_NewItems"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = L["Equipment Sets"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Sets", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Sets"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Armor"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Armor", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Armor"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Weapon"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Weapons", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Weapons"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = L["Gizmos"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Gizmos", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Gizmos"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Quest"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Quest", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Quest"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Glyph"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Glyphs", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Glyphs"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Gem"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Gems", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Gems"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Consumable"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Consumables", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Consumables"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Trade Goods"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Trade", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Trade"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Miscellaneous"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Misc", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Misc"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Junk"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Main_Junk", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Main_Junk"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							
						};
					};

					{ -- new items title
						type = "widget";
						element = "Title";
						order = 300;
						msg = L["New Items"];
					};
					{ -- new items description
						type = "widget";
						element = "Text";
						order = 305;
						msg = L["The 'New Items' category will display newly acquired items if enabled. Here you can set which categories and rarities to include."];
					};
					
					{ -- new items rarity threshold text
						type = "widget";
						element = "Text";
						order = 310;
						width = "minimum";
						msg = L["Minimum item quality"];
					};
					
					{ -- new items rarity threshold
						type = "widget";
						element = "Dropdown";
						order = 315;
						name = "newItemsRarityThreshold";
						width = "minimum";
						msg = nil;
						desc = L["Choose the minimum item rarity to be included in the 'New Items' category."];
						args = { F.GetRarityText(0), F.GetRarityText(1), F.GetRarityText(2), F.GetRarityText(3), F.GetRarityText(4), F.GetRarityText(5), F.GetRarityText(6), F.GetRarityText(7) };
						set = function(self, option)
							db.newitemrarity = UIDropDownMenu_GetSelectedID(self) - 1
							module:updateAllLayouts()
						end;
						get = function(self) return db.newitemrarity + 1 end;
						init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
					};
					{ -- new items category selection
						type = "group";
						order = 320;
						name = "newItemsCategorySelection";
						virtual = true;
						children = {
							{ -- armor
								type = "widget";
								element = "CheckButton";
								order = 100;
								msg = Types["Armor"];
								width = "half";
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Armor"] = not(db.newItemDisplay["Main_Armor"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Armor"] end;
								init = function(self) end;
							};
							{ -- weapons
								type = "widget";
								element = "CheckButton";
								order = 100;
								msg = Types["Weapon"];
								width = "half";
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Weapons"] = not(db.newItemDisplay["Main_Weapons"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Weapons"] end;
								init = function(self) end;
							};
							{ -- gizmos
								type = "widget";
								element = "CheckButton";
								order = 100;
								msg = L["Gizmos"];
								width = "half";
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Gizmos"] = not(db.newItemDisplay["Main_Gizmos"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Gizmos"] end;
								init = function(self) end;
							};
							{ -- quest
								type = "widget";
								element = "CheckButton";
								order = 100;
								msg = Types["Quest"];
								width = "half";
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Quest"] = not(db.newItemDisplay["Main_Quest"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Quest"] end;
								init = function(self) end;
							};
							{ -- glyphs
								type = "widget";
								element = "CheckButton";
								order = 100;
								msg = Types["Glyph"];
								width = "half";
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Glyphs"] = not(db.newItemDisplay["Main_Glyphs"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Glyphs"] end;
								init = function(self) end;
							};
							{ -- gems
								type = "widget";
								element = "CheckButton";
								order = 100;
								width = "half";
								msg = Types["Gem"];
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Gems"] = not(db.newItemDisplay["Main_Gems"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Gems"] end;
								init = function(self) end;
							};
							{ -- consumables
								type = "widget";
								element = "CheckButton";
								order = 100;
								width = "half";
								msg = Types["Consumable"];
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Consumables"] = not(db.newItemDisplay["Main_Consumables"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Consumables"] end;
								init = function(self) end;
							};
							{ -- trade goods
								type = "widget";
								element = "CheckButton";
								order = 100;
								width = "half";
								msg = Types["Trade Goods"];
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Trade"] = not(db.newItemDisplay["Main_Trade"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Trade"] end;
								init = function(self) end;
							};
							{ -- misc
								type = "widget";
								element = "CheckButton";
								order = 100;
								width = "half";
								msg = Types["Miscellaneous"];
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Misc"] = not(db.newItemDisplay["Main_Misc"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Misc"] end;
								init = function(self) end;
							};
							{ -- junk
								type = "widget";
								element = "CheckButton";
								order = 100;
								width = "half";
								msg = Types["Junk"];
								desc = nil;
								set = function(self) 
									db.newItemDisplay["Main_Junk"] = not(db.newItemDisplay["Main_Junk"])
									module:updateAllLayouts()
								end;
								get = function() return db.newItemDisplay["Main_Junk"] end;
								init = function(self) end;
							};
						};
					};
					
					{ -- bank category selection
						type = "group";
						order = 400;
						name = "bankDisplay";
						virtual = true;
						children = {
							{
								type = "widget";
								element = "Title";
								order = 10;
								width = "full";
								msg = L["Categories"] .. " (" .. L["Bank"] .. ")";
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = L["Equipment Sets"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Sets", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Sets"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Armor"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Armor", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Armor"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Weapon"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Weapons", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Weapons"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = L["Gizmos"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Gizmos", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Gizmos"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Quest"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Quest", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Quest"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Glyph"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Glyphs", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Glyphs"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Gem"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Gems", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Gems"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Consumable"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Consumables", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Consumables"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Trade Goods"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Trade", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Trade"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ 
								type = "widget";
								element = "Dropdown";
								order = 100;
								width = "half";
								msg = Types["Miscellaneous"];
								desc = MODULE_TOOLTIP;
								args = { SHOW, BYPASS, HIDE };
								set = function(self, option)
									module:Toggle("Bank_Misc", UIDropDownMenu_GetSelectedID(self))
								end;
								get = function(self) return db.bagDisplay["Bank_Misc"] end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
						};
						
					};
				};
			};
		}
		local restoreDefaults = function()
			if (InCombatLockdown()) then 
				print(L["Can not apply default settings while engaged in combat."])
				return
			end
			self:RestoreDefaults()
		end
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["Bags"], "default", restoreDefaults)
	end
end

module.Toggle = function(self, name, option)
	local container = Bags:GetContainer(name)
	if not(container) then
		return
	end
	
	-- show
	if (option == 1) then
		db.bagDisplay[name] = option
		container:Show()
		container:OnContentsChanged()
		
	-- bypass
	elseif (option == 2) then
		db.bagDisplay[name] = option
		container:Hide()
		container:OnContentsChanged()
	
	-- hide
	elseif (option == 3) then
		db.bagDisplay[name] = option
		container:Hide()
		container:OnContentsChanged()
	end
	
	-- all containers need to be updated, due to content changes caused by bypass
	self:updateAllLayouts()
	
	-- update the menus
	self:RefreshBlizzardOptionsMenu()
	
	-- lame hack to keep the dropdown updated
	-- not pretty, but it gets the job done
	if (DropDownList1:IsShown()) then
		DropDownList1:Hide()
	end
end

module.OnEnable = function(self)
	-- store the initial content of the bags and equipped inventory,
	-- only do this if there are no saved contents
	
	-- fix betatesting chaos
	for itemID,list in pairs(db.bagContents) do
		if (list == true) then
			db.bagContents[itemID] = nil
		end
	end
	
	if not(db.scannedSinceReset) then 
		RememberBagContents()
	end

	-- log in, enter combat, open bags, exit combat ==> TAINTED BAGS!!
	--
	-- attempting to remedy the issue by forcing the initialization of the bags
	-- this needs to happen after PLAYER_LOGIN
	Bags:Show()
	Bags:Hide()
end

module.OnDisable = function(self)
	for itemID,list in pairs(newItemsSinceReset) do
		if (list) then
			for unique,value in pairs(list) do
				if (db.bagContents[itemID]) then
					db.bagContents[itemID][unique] = nil
				end
			end
		end
	end
end
