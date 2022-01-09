local addon,ns = ...
local build = tonumber((select(2, GetBuildInfo())))
local LEGION = build >= 22124 

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0", "GP_AceHook-3.0")

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LibWin = GP_LibStub("GP_LibWindow-1.1")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local C = gUI4:GetColors()
local T, hasTheme

-- Lua API
local _G = _G
local strmatch, strfind, gsub = string.match, string.find, string.gsub
local abs, max, floor = math.abs, math.max, math.floor
local type, tonumber, tostring = type, tonumber, tostring
local pairs, ipairs, select, unpack = pairs, ipairs, select, unpack
local tinsert, tconcat = table.insert, table.concat

-- WoW API
local GetContainerItemID = GetContainerItemID
local GetGuildInfo = GetGuildInfo
local GetItemInfo = GetItemInfo
local GetLootSlotLink = GetLootSlotLink
local GetMouseFocus = GetMouseFocus
local GetQuestDifficultyColor = GetQuestDifficultyColor
local GetQuestGreenRange = GetQuestGreenRange
local GetRaidTargetIndex = GetRaidTargetIndex
local GetRealmName = GetRealmName
local GetSpellInfo = GetSpellInfo
local UnitAffectingCombat = UnitAffectingCombat
local UnitAura = UnitAura
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitCreatureType = UnitCreatureType
local UnitDebuff = UnitDebuff
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitName = UnitName
local UnitIsAFK = UnitIsAFK
local UnitIsDND = UnitIsDND 
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsPVPSanctuary = UnitIsPVPSanctuary
local UnitIsTapDenied = UnitIsTapDenied
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList
local UnitIsUnit = UnitIsUnit
local UnitLevel = UnitLevel
local UnitPlayerControlled = UnitPlayerControlled
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitPVPName = UnitPVPName
local UnitRace = UnitRace
local UnitReaction = UnitReaction

local GameTooltip = GameTooltip
local ItemRefTooltip = ItemRefTooltip
local UIParent = UIParent

local info, bars, currentData = {}, {}, {}
local backdrops, styled = {}, {}
local nameString, infoString = {}, {}

local _LEVEL = UnitLevel("player")
local _ANCHOR, _IS_COLOR_BLIND, _CURRENT_TOOLTIP

local enchantColor = { 0, 0.8, 1 }

local function topattern(str, plain)
	str = str:gsub("%%%d?$?c", ".+")
	str = str:gsub("%%%d?$?d", "%%d+")
	str = str:gsub("%%%d?$?s", ".+")
	str = str:gsub("([%(%)])", "%%%1")
	return plain and str or ("^" .. str)
end
local _STRINGS = {
	AFK = C.afk.colorCode..CHAT_FLAG_AFK.."|r",
	DEAD = "|cff888888"..DEAD.."|r",
	DND = C.dnd.colorCode..CHAT_FLAG_DND.."|r",
	DURABILITY = topattern(DURABILITY_TEMPLATE),
	ENCHANTED = "^" .. gsub(ENCHANTED_TOOLTIP_LINE, "%%s", "(.+)"), -- topattern(ENCHANTED_TOOLTIP_LINE)
	EQUIPMENT_SETS = "^" .. gsub(EQUIPMENT_SETS, "%%s", "(.+)"),
	GHOST = "|cff888888"..L["Ghost"].."|r",
	ITEM_LEVEL = "^" .. gsub(ITEM_LEVEL, "%%d", "(.+)"), -- topattern(ITEM_LEVEL)
	ITEM_SET_BONUS = topattern(ITEM_SET_BONUS),
	ITEM_SET_BONUS_GRAY = topattern(ITEM_SET_BONUS_GRAY),
	ITEM_SET_NAME = topattern(ITEM_SET_NAME),
	ITEM_SOCKETABLE = ITEM_SOCKETABLE,
	ITEM_SOULBOUND = ITEM_SOULBOUND,
	ITEM_UNIQUE = ITEM_UNIQUE,
	ITEM_UNIQUE_EQUIPPABLE = ITEM_UNIQUE_EQUIPPABLE,
	ITEM_VENDOR_STACK_BUY = ITEM_VENDOR_STACK_BUY,
	MADE_BY = "^" .. gsub(ITEM_CREATED_BY, "%%s", "(.+)"), -- topattern(ITEM_CREATED_BY)
	OFFLINE = "|cff888888"..PLAYER_OFFLINE.."|r",
	REQ_CLASS = topattern(ITEM_CLASSES_ALLOWED),
	REQ_LEVEL = topattern(ITEM_MIN_LEVEL),
	REQ_RACE = topattern(ITEM_RACES_ALLOWED),
	REQ_REPUTATION = topattern(ITEM_REQ_REPUTATION),
	REQ_SKILL = topattern(ITEM_REQ_SKILL),
	SELL_PRICE = SELL_PRICE,
	TRANSMOGRIFIED = "^" .. gsub(TRANSMOGRIFIED, "%%s", "(.+)"),
	TRANSMOGRIFIED_ENCHANT = "^" .. gsub(TRANSMOGRIFIED_ENCHANT, "%%s", "(.+)"),
	TRANSMOGRIFIED_HEADER = TRANSMOGRIFIED_HEADER, -- topattern(TRANSMOGRIFIED_HEADER),
	UNIT_YOU = UNIT_YOU,
	UNIQUE_MULTIPLE = topattern(ITEM_UNIQUE_MULTIPLE),
	UPGRADE_LEVEL = topattern(ITEM_UPGRADE_TOOLTIP_FORMAT),
	YES = "|cffcceeff" .. YES .. "|r",
	YOU = "|cffff0000" .. UNIT_YOU:upper() .. "|r",
	
	notSpecified = "Not specified", 
	guildString = C.guild.colorCode.."<%s>".."|r",
	titleString = C.guild.colorCode.."<%s>".."|r",
	percentageString = "|cffc9c9c9%d%%|r",
	fullString = "|cffc9c9c9%s|r",
	missingString = "|cffc9c9c9%d%%|r |cff666666-|r |cffcc5555%s|r",
	classificationStrings = {
		elite = "%s|cffff0000+|r",
		rare = "%s |cff0070dd"..ITEM_QUALITY3_DESC.."|r",
		rareelite = "%s |cff0070dd"..ITEM_QUALITY3_DESC.."|r|cffff0000+|r",
		worldboss = "|cffff0000"..BOSS.."|r", -- level not displayed here, just the text
		normal = "%s",
		minus = "-%s",
		trivial = "~%s"
	}
}
local _PETTEXTURES = { 
	"BorderTopLeft", 
	"BorderTopRight", 
	"BorderBottomRight", 
	"BorderBottomLeft", 
	"BorderTop", 
	"BorderRight", 
	"BorderBottom", 
	"BorderLeft", 
	"Background" 
}
local _TOOLTIPS = {
	"GameTooltip",
	"ShoppingTooltip1",
	"ShoppingTooltip2",
	"ShoppingTooltip3",
	"ItemRefTooltip",
	"ItemRefShoppingTooltip1",
	"ItemRefShoppingTooltip2",
	"ItemRefShoppingTooltip3",
	--"WorldMapTooltip",
	--"WorldMapCompareTooltip1",
	--"WorldMapCompareTooltip2",
	--"WorldMapCompareTooltip3",
	--"AtlasLootTooltip",
	--"QuestHelperTooltip",
	--"QuestGuru_QuestWatchTooltip",
	--"TRP2_MainTooltip",
	--"TRP2_ObjetTooltip",
	--"TRP2_StaticPopupPersoTooltip",
	--"TRP2_PersoTooltip",
	--"TRP2_MountTooltip",
	--"AltoTooltip",
	--"AltoScanningTooltip",
	--"ArkScanTooltipTemplate", 
	--"NxTooltipItem",
	--"NxTooltipD",
	--"DBMInfoFrame",
	--"DBMRangeCheck",
	--"DatatextTooltip",
	"VengeanceTooltip",
	"FishingBuddyTooltip",
	"FishLibTooltip",
	--"HealBot_ScanTooltip",
	--"hbGameTooltip",
	--"PlateBuffsTooltip",
	--"LibGroupInSpecTScanTip",
	--"RecountTempTooltip",
	--"VuhDoScanTooltip",
	--"XPerl_BottomTip", 
	"EventTraceTooltip",
	"FrameStackTooltip",
	"PetBattlePrimaryUnitTooltip",
	"PetBattlePrimaryAbilityTooltip"
}
local _DROPDOWNS = {
	"ChatMenu",
	"EmoteMenu",
	"LanguageMenu",
	"VoiceMacroMenu",
	-- PetBattleUnitFrameDropDown
}

local defaults = {
	profile = {
		locked = true,
		skin = "Warcraft",
		
		-- all tooltips
		hideBlank = true,
		hideSpellID = false,
		
		-- unit tooltips
		showPlayerRealm = false,
		showPlayerTitle = false,
		showPlayerGender = false,
		showPowerBar = true,
		showTarget = true,

		-- item tooltips
		hideTransmogDescription = true,
		hideTransmogLabelOnly = true,
		hideSetListItems = true,
		hideRequirements = false,
		hideRequirementsMet = true,
		hideEnchantMent = true,
		hideEnchantMentLabelOnly = true,
		hideEquipmentManagerSets = false,
		hideItemCrafter = true,
		hideItemLevel = false,
		hideItemID = false,
		hideItemValue = false,

		
		hideSetBonuses = false,
		
		-- hideRightClickBuy = true,
		-- hideRightClickSocket = true,
		-- hideDurability = false,
		-- hideRaidDifficulty = false,
		-- hideSoulbound = false,
		-- hideUnique = false,
		-- hideUpgradeLevel = false,

		position = {}
	}
}
local deprecated_settings = {
	hideEquipmentSets = true,
	hideMadeBy = true,
	hideReforged = true,
	hideSetItems = true,
	hideSellValue = true,
	hideTransmog = true,
	hideTransmogLabel = true
}


-----------------------------------------------------------------------------
-- local functions
-----------------------------------------------------------------------------
local function updateConfig()
	T = module:GetActiveTheme()
end

local function short(value)
	value = tonumber(value)
	if not value then return "" end
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif (value >= 1e3) or (value <= -1e3) then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return floor(tostring(value))
	end	
end

local function getlevelcolor(level)
	level = level - _LEVEL
	if level > 4 then
		return C.chat.dimred
	elseif level > 2 then
		return C.chat.orange
	elseif level >= -2 then
		return C.chat.normal
	elseif level >= -GetQuestGreenRange() then
		return C.chat.offgreen
	else
		return C.chat.gray
	end
end

local function showItemRefIcon()
	local frame = GUI4_ItemRefIcon
	local tip = ItemRefTooltip
	
	frame:Hide()

	local link = select(2, tip:GetItem())
	local icon = link and GetItemIcon(link)

	if not icon then 
		tip.hasIcon = nil
		return 
	end
	
	local rarity = select(3, GetItemInfo(link))
	if rarity and rarity > 1 then
		-- local r, g, b = GetItemQualityColor(rarity)
		-- frame:SetBackdropBorderColor(r, g, b, 1)
		tip.hasIcon = true
	else
		-- frame:SetBackdropBorderColor(defaultR, defaultG, defaultB, 1)
		tip.hasIcon = nil
	end

	frame.icon:SetTexture(icon)
	frame:Show()
end


-----------------------------------------------------------------------------
-- tooltip data registry
-----------------------------------------------------------------------------
local function getData(tip, field)
	if not currentData[tip] then
		return 
	end
	if _CURRENT_TOOLTIP ~= tip then
		_CURRENT_TOOLTIP = tip
	end
	return currentData[tip][field]
end

local function clearData(tip, field)
	if not currentData[tip] then 
		return
	end
	if not field then
		wipe(currentData[tip])
		return
	end
	currentData[tip][field] = nil
end

local function setData(tip, field, value)
	if not currentData[tip] then
		currentData[tip] = {}
	end
	if _CURRENT_TOOLTIP ~= tip then
		_CURRENT_TOOLTIP = tip
	end
	currentData[tip][field] = value
end


-----------------------------------------------------------------------------
-- gametooltip size/space post updates
-----------------------------------------------------------------------------
-- empty lines have a height of 0, but they are located 2 pixels below the previous line by default, 
-- thus creating an extra large space between lines unless we handle it. So we handle it.
local function ReAlignLines(self, fixHeight)
	local name = self:GetName()
	local this, next
	if self.NumLines then
		for i = 2, self:NumLines() do
			local line = _G[name .. "TextLeft" .. i]
			local text = line:GetText()
			line:ClearAllPoints()
			line:SetPoint("TOPLEFT", _G[name .. "TextLeft" .. (i-1)], "BOTTOMLEFT", 0, (text and text ~= "") and -2 or 0)
		end
		if fixHeight then
			local last = _G[name .. "TextLeft" .. self:NumLines()]
			if last then 
				local top, bottom = self:GetTop(), last:GetBottom()
				if top and bottom then
					local height = self:GetHeight()
					local newheight = top - bottom
					if abs(height - newheight) > 2 then
						height = newheight + 10 -- default padding of the tips
						setData(self, "tipHeight", floor(height + .5 + (getData(self, "barOffset") or 0)))
						self:SetHeight(getData(self, "tipHeight"))
					end
				end
			end
		end
	end
end

-- tooltips can have imperfect sizes, but this will make their borders fuzzy
-- here we attempt in various ways to lock the sizes to actual pixels.
local function UpdateSize(self)
	local tooltip = self or GameTooltip
	ReAlignLines(tooltip)
	local width = tooltip:GetWidth()
	local height = tooltip:GetHeight()
	if tooltip.NumLines then
		tipLines = tooltip:NumLines()
		if tipLines > 0 then
			local last = _G[tooltip:GetName() .. "TextLeft" .. tipLines]
			if last then 
				local top, bottom = tooltip:GetTop(), last:GetBottom()
				if top and bottom then
					newheight = top - bottom
					if abs(height - newheight) > 2 then
						height = newheight + 10 -- default padding of the tips
					end
				end
			end
		end
	end
	setData(tooltip, "tipWidth", floor(width + .5))
	setData(tooltip, "tipHeight", floor(height + .5 + (getData(tooltip, "barOffset") or 0)))
end


-----------------------------------------------------------------------------
-- statusbars
-----------------------------------------------------------------------------
local function UpdateBarOffset(self)
	local offset = 0
	for element, bar in pairs(bars) do
		if bar:IsShown() then
			offset = offset + bar:GetHeight() + 4
		end
	end
	if offset > 0 then
		setData(self, "barOffset", offset)
	else
		setData(self, "barOffset", nil)
	end
	UpdateSize(self)
end

local function UpdateBars(self)
	if bars.health:IsShown() then
		local min, max = UnitHealth(info.unit), UnitHealthMax(info.unit)
		bars.health:SetMinMaxValues(0, max)
		bars.health:SetValue(min)
		bars.health:SetStatusBarColor(unpack(info.color))
		if info.isGhost then	
			bars.health.value:SetText(_STRINGS.GHOST)	
		elseif info.isDead or min == 0 then
			bars.health.value:SetText(_STRINGS.DEAD)	
		elseif info.isPlayer and not info.isConnected then
			bars.health.value:SetText(_STRINGS.OFFLINE)	
		elseif min < max then
			if min > 1 then
				bars.health.value:SetFormattedText(_STRINGS.missingString, floor(min / max * 100), short(min))
			else -- gates have 0 to 1 health
				bars.health.value:SetFormattedText(_STRINGS.percentageString, floor(min / max * 100))
			end
		elseif min > 0 then -- min == max is sort of implicit here
			bars.health.value:SetFormattedText(_STRINGS.fullString, short(min))
		else
			-- bars.health:Hide()
			-- UpdateBarOffset(self)
		end
	end
	if bars.power:IsShown() then
		local min, max = UnitPower(info.unit), UnitPowerMax(info.unit)
		local _, powerType = UnitPowerType(info.unit)
		bars.power:SetMinMaxValues(0, max)
		bars.power:SetValue(min)
		bars.power:SetStatusBarColor(unpack(C.power[powerType])) -- only color by the actual powertype, not the stored reference one
		if info.isGhost or info.isDead then -- shouldn't show, but you never know
			bars.power.value:SetText("")
		elseif min == max then
			bars.power.value:SetFormattedText(_STRINGS.fullString, short(min))
		elseif min > 0 then
			bars.power.value:SetFormattedText(_STRINGS.missingString, floor(min / max * 100), short(min))
		else
			bars.power.value:SetText(short(0))
			-- bars.power:Hide()
			-- UpdateBarOffset(self)
		end
	end
end

local function SetUpBars(self, unit)
	local health, power = false, false
	local oldHealth = not not bars.health:IsShown()
	local oldPower = not not bars.power:IsShown()
	if info.unit and UnitExists(info.unit) then
		if info.isGhost or info.isDead then
			health = true
		else
			local powerType, powerTypeString = UnitPowerType(info.unit)
			if powerType ~= info.powerType then
				info.powerType = powerType
				if module.db.profile.showPowerBar and C.power[powerTypeString] and (info.isPlayer or UnitPowerMax(info.unit) > 0) then -- player power should always be visible
					health = true
					power = true
				elseif UnitHealth(info.unit) > 0 then -- the tooltip gets reset when a unit die, so no risk of weird size changes here. this is a fresh tooltip.
					health = true
				else
				end
			end
		end
	end
	if power then
		LMP:NewChain(bars.power) :ClearAllPoints() :SetPoint("BOTTOMLEFT", 6, 6) :SetPoint("BOTTOMRIGHT", -6, 6) :Show() :EndChain()
		LMP:NewChain(bars.health) :ClearAllPoints() :SetPoint("BOTTOMLEFT", bars.power, "TOPLEFT", 0, 4) :SetPoint("BOTTOMRIGHT", bars.power, "TOPRIGHT", 0, 4) :Show() :EndChain()
	elseif health then
		LMP:NewChain(bars.health) :ClearAllPoints() :SetPoint("BOTTOMLEFT", 6, 6) :SetPoint("BOTTOMRIGHT", -6, 6) :Show() :EndChain()
		bars.power:Hide()
	else
		bars.health:Hide()
		bars.power:Hide()
	end
	GameTooltipStatusBar:Hide() -- hide the default statusbar, we're only using our own
	UpdateBars(self) -- update bar values
	UpdateBarOffset(self) -- update offsets
	--UpdateSize(self) 
end


-----------------------------------------------------------------------------
-- gather data
-- 	*note that unit tooltips are unique, and can use the unique 'info' table, 
-- 	 while items tooltips can be compare tips and various, so they require the 
--	 use of the setData/getData per tooltip system to track their data instead!
-----------------------------------------------------------------------------

-- update the unit tooltip's current unit
local function UpdateUnit(self)
	wipe(info)
	local _, unit = self:GetUnit()
	if not unit then
		local focus = GetMouseFocus()
		unit = focus and focus:GetAttribute("unit")
	end
	if (not unit) and UnitExists("mouseover") then
		unit = "mouseover"
	end
	if unit and UnitIsUnit(unit, "mouseover") then
		unit = "mouseover"
	end
	info.unit = unit
	return info.unit
end

local function GetDifficulty(self)
	local color
	if info.isBoss then
		color = getlevelcolor(_LEVEL + 4)
	elseif info.level and info.level > 0 then
		color = getlevelcolor(info.level)
	end
	info.difficultyColor = color or getlevelcolor(_LEVEL)
end

local function GetUnitColor(self)
	local color
	if info.unit then
		if info.isDead then 
			color = C.dead
		elseif info.isPlayer then
			if not info.isConnected then
				color = C.disconnected
			elseif info.class then
				color = C.class[info.class]
			end
		elseif info.reaction then
			if info.isTapped then
				color = C.tapped
			else
				color = C.reaction[info.reaction]
			end
		end
	end
	info.color = color or C.chat.normal
end

local function GetUnitData(self)
	local unit = info.unit
	if not unit or not UnitExists(unit) then return end

	info.guid = UnitGUID(unit)
	info.name, info.realm = UnitName(unit)
	info.faction = UnitFactionGroup(unit)
	info.level = UnitLevel(unit)
	info.raceName, info.race = UnitRace(unit)
	info.raidTarget = GetRaidTargetIndex(unit)
	info.isFriend = UnitIsFriend("player", unit)
	info.isEnemy = UnitIsEnemy("player", unit)
	info.isPlayer = UnitIsPlayer(unit)
	info.isDead = UnitIsDead(unit)
	info.isGhost = UnitIsGhost(unit)
	
	if info.isPlayer then
		info.pvp = UnitIsPVP(unit)
		info.ffa = UnitIsPVPFreeForAll(unit)
		info.pvpName = UnitPVPName(unit)
		info.afk = UnitIsAFK(unit)
		info.dnd = UnitIsDND(unit)
		info.guild = GetGuildInfo(unit)
		info.genderID = UnitSex(unit)
		info.gender = info.genderID == 3 and FEMALE or MALE
		info.className, info.class = UnitClass(unit)
		info.isConnected = UnitIsConnected(unit)
		info.levelIndex = info.guild and 3 or 2 + (_IS_COLOR_BLIND and 1 or 0)		
	else
		info.classification = UnitClassification(unit)
		info.creatureType = UnitCreatureFamily(unit) or UnitCreatureType(unit)
		info.isWildPet = UnitIsWildBattlePet(unit)
		info.isBattlePet = UnitIsBattlePetCompanion(unit)
		info.isTapped = LEGION and UnitIsTapDenied(unit) or not LEGION and (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit))
		info.reaction = UnitReaction(unit, "player")
		if info.isBattlePet or info.isWildPet then
			info.level = UnitBattlePetLevel(unit)
		end
		if info.level == -1 then
			info.classification = "worldboss"
			info.isBoss = true
		end
		if not info.creatureType or info.creatureType == _STRINGS.notSpecified then
			info.creatureType = UNKNOWN -- "Unknown" looks far better than "Not specified"
		end
		local titleIndex
		for i = 2, self:NumLines() do
			local line = _G["GameTooltipTextLeft"..i]
			if line then
				local text = line:GetText()
				if text and (text:find(LEVEL) or (info.creatureType and text:find(info.creatureType))) then
					info.levelIndex = i
					if i > 2 + (_IS_COLOR_BLIND and 1 or 0) then 
						titleIndex = i - 1
					end
					break
				end
			end
		end
		if titleIndex then
			info.title = _G["GameTooltipTextLeft"..titleIndex]:GetText()
			info.titleIndex = titleIndex
		end
	end
end

local function GetTarget(self)
	if not info.unit then return end
	local target = info.unit .. "target"
	if UnitExists(target) and not(UnitIsUnit(info.unit, "player") or UnitIsUnit(target, "player"))then
		info.target = target
		info.targetName, info.targetRealm = UnitName(target)
	else
		info.target = nil
		info.targetName = nil
		info.targetRealm = nil
	end
end

local function GetTargetedBy(self)
end

-- update spellID or itemID for item tooltips
local function UpdateItem(self)
	wipe(info)
	local name, link = self:GetItem()
	if link then
		if link:find("^spell:") then
			local spellID = string.sub(link, 7)
			if spellID then
				setData(self, "spellID", spellID)
				return true
			end
		elseif link:match("item[%-?%d:]+") then
			local itemString = link:match("item[%-?%d:]+")
			if itemString then
				local _, itemID = strsplit(":", itemString)
				if itemID then
					setData(self, "itemID", itemID)
					return true
				end
			end
		end
	end	
end

local function GetItemData(self)
	if not getData(self, "itemID") then return end
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(getData(self, "itemID"))
	setData(self, "itemName", itemName)
	setData(self, "itemLink", itemLink)
	setData(self, "itemRarity", itemRarity)
	setData(self, "itemLevel", itemLevel)
	setData(self, "itemMinLevel", itemMinLevel)
	setData(self, "itemType", itemType)
	setData(self, "itemSubType", itemSubType)
	setData(self, "itemStackCount", itemStackCount)
	setData(self, "itemEquipLoc", itemEquipLoc)
	setData(self, "itemTexture", itemTexture)
	setData(self, "itemSellPrice", itemSellPrice)
	setData(self, "itemColor", C.quality[itemRarity])
end

local function UpdateSpell(self)
	local spellName, spellRank, spellID = self:GetSpell()
	if spellID then
		setData(self, "spellID", spellID)
		return true
	end
end

local function GetSpellData(self)
	if not getData(self, "spellID") then return end 
	local spellName, spellRank, spellIcon, spellCastTime, spellMinRange, spellMaxRange, spellID = GetSpellInfo(getData(self, "spellID"))
	setData(self, "spellName", spellName)
	setData(self, "spellRank", spellRank)
	setData(self, "spellIcon", spellIcon)
	setData(self, "spellCastTime", spellCastTime)
	setData(self, "spellMinRange", spellMinRange)
	setData(self, "spellMaxRange", spellMaxRange)
end


-----------------------------------------------------------------------------
-- extra lines
-----------------------------------------------------------------------------

local function addInfoLine(self, label, info, colCode1, colCode2)
	if not info or not label then return end
	self:AddDoubleLine((colCode1 or "|cff0099ff").. label .."|r", (colCode2 or "|cff88ccff") .. info .. "|r")
end

local function addItemID(self, itemID)
	local storedItemID = getData(self, "itemID") or itemID
	if not storedItemID then -- in case this has been called outside of item tooltips, for some reason
		return 
	end
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(storedItemID)
	if not itemName then -- in case the item just doesn't exist for some weird reason
		return 
	end
	if not module.db.profile.hideItemLevel then
		addInfoLine(self, L["Item Level: "], getData(self, "itemLevel") or itemLevel)
	end
	if not module.db.profile.hideItemID then
		addInfoLine(self, L["Item ID: "], storedItemID)
	end
	if (not module.db.profile.hideItemValue) and itemSellPrice and itemSellPrice > 0 then
		addInfoLine(self, ("%s:"):format(SELL_PRICE), GetCoinTextureString(itemSellPrice), nil, "|cffffffff")
	end
	self:Show()
end

local function addItemCrafter(self)
	if module.db.profile.hideItemCrafter then return end
	addInfoLine(self, L["Item crafter: "], getData(self, "currentItemCrafter"))
	self:Show()
end

local function addEquipmentManagerSetList(self)
	if module.db.profile.hideEquipmentManagerSets then return end
	addInfoLine(self, L["Item Sets: "], getData(self, "currentEquipmentManagerList"))
	self:Show()
end

local function addSpellID(self, spellID)
	if module.db.profile.hideSpellID then return end
	-- horrible, horrible fix. this file is a mess. will deal later.
	local owner = self:GetOwner()
	local ghetto = owner and owner:GetName() and owner:GetName():find("PlayerTalentFrameTalents")
	if not ghetto or (ghetto and not self.talentFrameSpellIDSet) then
		addInfoLine(self, L["Spell ID: "], getData(self, "spellID") or spellID)
		self.talentFrameSpellIDSet = true
		self:Show()
	end
end

local function addCasterName(self, caster)
	local name
	caster = getData(self, "casterName" or caster)
	if caster == "player" then
		name = _STRINGS.UNIT_YOU
	else
		name = UnitName(caster) or caster
	end
	addInfoLine(self, L["Caster: "], name)
	self:Show()
end

local function addBossDebuff(self, isBossDebuff)
	addInfoLine(self, L["Boss Debuff: "], _STRINGS.YES)
	self:Show()
end


-----------------------------------------------------------------------------
-- styling
-----------------------------------------------------------------------------
local function styleBackdrop(backdrop, owner)
	updateConfig()
	LMP:NewChain(backdrop) :ClearAllPoints() :SetPoint("TOPLEFT", owner, -T.tooltip.offset, T.tooltip.offset) :SetPoint("BOTTOMRIGHT", T.tooltip.offset, -T.tooltip.offset) :SetBackdrop(nil) :SetBackdrop(T.tooltip.backdrop) :SetBackdropColor(unpack(T.colors.backdrop)) :SetBackdropBorderColor(unpack(T.colors.border)) :EndChain()
end

local function createBackdrop(self)
	self:SetBackdrop(nil)
	self.SetBackdrop = function() end
	for _,t in ipairs(_PETTEXTURES) do
		if self[t] then
			self[t]:SetTexture("")
		end
	end
	backdrops[self] = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetFrameLevel(self:GetFrameLevel()) .__EndChain
	if hasTheme then
		styleBackdrop(backdrops[self], self)
	end
	hooksecurefunc(self, "SetFrameStrata", function(self) backdrops[self]:SetFrameLevel(self:GetFrameLevel()) end)
	hooksecurefunc(self, "SetFrameLevel", function(self) backdrops[self]:SetFrameLevel(self:GetFrameLevel()) end)
	hooksecurefunc(self, "SetParent", function(self) backdrops[self]:SetFrameLevel(self:GetFrameLevel()) end)
end

local function style(self)
	if not backdrops[self] then
		createBackdrop(self)
	end
	styled[self] = true
end

local function styleTooltip(self)
	if styled[self] then return end
	style(self)	
end

local function styleMenu(self)
	if styled[self] then return end
	style(self)	
end


-----------------------------------------------------------------------------
-- hooks
-----------------------------------------------------------------------------
local function SetDefaultAnchor(tooltip, owner)
	if ((tooltip == GameTooltip) and (GameTooltip:IsForbidden())) then
			return
	end
	if owner == UIParent then 
		tooltip:ClearAllPoints()
		tooltip:SetPoint(_ANCHOR:GetPoint())
	end
end

local function SetBagItem(self, bag, slot)
	local itemID = GetContainerItemID(bag, slot)
	if itemID then
		-- addItemID(self, itemID)
		setData(self, "itemID", itemID)
	end
end

local function SetHyperlink(self, link)
	if link then
		if link:find("^spell:") then
			local spellID = string.sub(link, 7)
			if spellID then
				-- addSpellID(ItemRefTooltip, spellID)
				setData(self, "spellID", spellID)
			end
		elseif link:match("item[%-?%d:]+") then
			local itemString = link:match("item[%-?%d:]+")
			if itemString then
				local _, itemID = strsplit(":", itemString)
				if itemID then
					-- addItemID(self, itemID)
					setData(self, "itemID", itemID)
				end
			end
		end
	end		
end

local function SetInventoryItem(self, unit, invSlot, nameOnly)
	local link = GetInventoryItemLink(unit, invSlot) 
	if link then
		local itemString = link:match("item[%-?%d:]+")
		if itemString then
			local _, itemID = strsplit(":", itemString)
			if itemID then
				-- addItemID(self, itemID)
				setData(self, "itemID", itemID)
			end
		end
	end		
end

local function SetItemRef(link, text, button, chatFrame)
	-- we're leaving this to ItemRefTooltip:SetHyperlink() instead
	-- if link:find("^spell:") then
		-- local spellID = string.sub(link, 7)
		-- if spellID then
			-- if getData(ItemRefTooltip, "spellID") ~= tonumber(spellID) then
				-- addSpellID(ItemRefTooltip, spellID)
			-- end
		-- end
	-- elseif link:match("item[%-?%d:]+") then
		-- local itemString = link:match("item[%-?%d:]+")
		-- if itemString then
			-- local _, itemID = strsplit(":", itemString)
			-- if itemID then
				-- if getData(ItemRefTooltip, "itemID") ~= tonumber(itemID) then
					-- addItemID(ItemRefTooltip, itemID)
				-- end
			-- end
		-- end
	-- end
	-- showItemRefIcon()
end

local function SetLootItem(self, index)
	local link = GetLootSlotLink(index)
	if link then
		local itemString = link:match("item[%-?%d:]+")
		if itemString then
			local _, itemID = strsplit(":", itemString)
			if itemID then
				-- addItemID(self, itemID)
				setData(self, "itemID", itemID)
			end
		end
	end		
end

local function SetUnitAura(self,...)
	local spellID = select(11, UnitAura(...))
	if spellID then 
		-- addSpellID(self, spellID) 
		setData(self, "spellID", spellID)
	end
	local caster = select(8, UnitAura(...))
	if caster then 
		-- addCasterName(self, caster) 
		setData(self, "casterName", caster)
	end
	local isBossDebuff = select(13, UnitAura(...))
	if isBossDebuff then 
		-- addBossDebuff(self, isBossDebuff) 
		setData(self, "isBossDebuff", true)
	end
	-- print("aura", spellID, caster, isBossDebuff)
	if getData(self, "spellID") then
		addSpellID(self)
	end
	if getData(self, "casterName") then
		addCasterName(self)
	end
	if getData(self, "isBossDebuff") then
		addSpellID(self)
	end
	clearData(self)
	self:Show()
	UpdateSize(self)
end

local function SetUnitDebuff(self,...)
	local spellID = select(11,UnitDebuff(...))
	if spellID then 
		-- addSpellID(self,spellID) 
		setData(self, "spellID", spellID)
	end
	local caster = select(8,UnitDebuff(...))
	if caster then 
		-- addCasterName(self,caster) 
		setData(self, "casterName", caster)
	end
	local isBossDebuff = select(13, UnitDebuff(...))
	if isBossDebuff then 
		-- addBossDebuff(self, isBossDebuff) 
		setData(self, "isBossDebuff", true)
	end
	-- print("debuff", spellID, caster, isBossDebuff)
	if getData(self, "spellID") then
		addSpellID(self)
	end
	if getData(self, "casterName") then
		addCasterName(self)
	end
	if getData(self, "isBossDebuff") then
		addSpellID(self)
	end
	clearData(self)
	self:Show()
	UpdateSize(self)	
end

local function clean(self, line, text, queued)
	GameTooltip_ClearMoney(self)
	if text == " " and module.db.profile.hideBlank then
		return line:SetText("")
	end

	local enchantment = strmatch(text, _STRINGS.ENCHANTED)
	if enchantment then
		if module.db.profile.hideEnchantMent then
			if module.db.profile.hideEnchantMentLabelOnly then
				line:SetText(enchantment)
				line:SetTextColor(unpack(enchantColor))
				return 
			else
				return line:SetText("")
			end
		else
			line:SetTextColor(unpack(enchantColor)) -- colorize the line no matter what. 
			return
		end
	end	

	if module.db.profile.hideTransmogDescription then
		-- queued
		
		if text == _STRINGS.TRANSMOGRIFIED_HEADER then
			return line:SetText(""), not module.db.profile.hideTransmogLabelOnly
		else 
			local illusion = strmatch(text, _STRINGS.TRANSMOGRIFIED)
			if illusion then
				if module.db.profile.hideTransmogLabelOnly then
					return line:SetText(illusion)
				else
					return line:SetText("")
				end
			end
			local illusion = strmatch(text, _STRINGS.TRANSMOGRIFIED_ENCHANT)
			if illusion then
				if module.db.profile.hideTransmogLabelOnly then
					return line:SetText(illusion)
				else
					return line:SetText("")
				end
			end
			if queued then
				return line:SetText("")
			end
		end
	
		-- local illusion = strmatch(text, _STRINGS.TRANSMOGRIFIED_ENCHANT)
		-- if illusion then
			-- if module.db.profile.hideTransmogLabelOnly then
				-- return line:SetText(illusion)
			-- else
				-- return line:SetText("")
			-- end
		-- elseif text == _STRINGS.TRANSMOGRIFIED_HEADER then
			-- return line:SetText(""), not module.db.profile.hideTransmogLabelOnly
		-- else 
			-- local illusion = strmatch(text, _STRINGS.TRANSMOGRIFIED)
			-- if illusion then
				-- if module.db.profile.hideTransmogLabelOnly then
					-- return line:SetText(illusion)
				-- else
					-- return line:SetText("")
				-- end
			-- end
		-- end
	end

	-- gear sets (like Gladiator's Sanctuary or Cenarion Rayment and so on)
	if getData(self, "inSetList") then
		-- identify and hide the list of items in the gear set
		if strmatch(text, "^ .") then 
			if module.db.profile.hideSetListItems then
				line:SetText("")
			end
			return
		else
			setData(self, "inSetList", nil)
		end
	elseif strmatch(text, _STRINGS.ITEM_SET_NAME) then
		setData(self, "inSetList", true)
		return
	end
	
	-- equipment sets in the equipment manager that the item is part of
	if strmatch(text, _STRINGS.EQUIPMENT_SETS) then
		setData(self, "currentEquipmentManagerList", strmatch(text, _STRINGS.EQUIPMENT_SETS))
		line:SetText("")
		return
	end

	-- who made the item if it's crafted
	if strmatch(text, _STRINGS.MADE_BY) then
		setData(self, "currentItemCrafter", strmatch(text, _STRINGS.MADE_BY))
		line:SetText("")
		return
	end

	-- item level as returned by the tip 
	if strmatch(text, _STRINGS.ITEM_LEVEL) then
		setData(self, "itemLevel", strmatch(text, _STRINGS.ITEM_LEVEL))
		line:SetText("")
		return
	end
	
	-- if (text == _STRINGS.ITEM_SOCKETABLE and module.db.profile.hideRightClickSocket)
	-- or (text == _STRINGS.ITEM_SOULBOUND and module.db.profile.hideSoulbound)
	-- or (text == _STRINGS.ITEM_VENDOR_STACK_BUY and module.db.profile.hideRightClickBuy)
	-- or (module.db.profile.hideRaidDifficulty and raidDifficultyLabels[text])
	-- or (module.db.profile.hideDurability and strmatch(text, _STRINGS.DURABILITY))
	-- or (strmatch(text, _STRINGS.ITEM_LEVEL)) -- module.db.profile.hideItemLevel
	-- or (module.db.profile.hideItemCrafter and strmatch(text, _STRINGS.MADE_BY))
	-- or (module.db.profile.hideUpgradeLevel and strmatch(text, _STRINGS.UPGRADE_LEVEL))
	-- or (module.db.profile.hideUnique and (text == _STRINGS.ITEM_UNIQUE or text == _STRINGS.ITEM_UNIQUE_EQUIPPABLE or strmatch(text, _STRINGS.UNIQUE_MULTIPLE)))
	-- or (module.db.profile.hideSetBonuses and (strmatch(text, _STRINGS.ITEM_SET_BONUS) or strmatch(text, _STRINGS.ITEM_SET_BONUS_GRAY)))
	-- or (strfind(text, _STRINGS.SELL_PRICE)) then -- module.db.profile.hideItemValue -- we hide the original sell value no matter what 
	if strfind(text, _STRINGS.SELL_PRICE) then
		line:SetText("")
		return 
	end

	if module.db.profile.hideRequirements and (
		strmatch(text, _STRINGS.REQ_CLASS)
		or strmatch(text, _STRINGS.REQ_RACE)
		or strmatch(text, _STRINGS.REQ_LEVEL)
		or strmatch(text, _STRINGS.REQ_REPUTATION)
		or strmatch(text, _STRINGS.REQ_SKILL)
	) then
		if module.db.profile.hideRequirementsMet then
			local r, g, b = line:GetTextColor()
			if g > .9 and b > .9 then
				line:SetText("")
			end
		else
			line:SetText("")
		end
		return 
	end

	if strmatch(text, "^%+%d+") then
		local r, g, b = line:GetTextColor()
		if r < 0.1 and g > 0.9 and b < 0.1 then
			line:SetTextColor(unpack(C.chat.green))
		end
		return 
	end
end

-- clean up item tips
local function OnTooltipSetItem(self)
	if not UpdateItem(self) then return end
	GetItemData(self)

	local tooltipName = self:GetName()
	local cmd, queue
	for i = 2, self:NumLines() do
		local line = _G[tooltipName .. "TextLeft" .. i]
		if line then 
			local text = line:GetText()
			if text then
				local previous = _G[tooltipName .. "TextLeft" .. (i-1)]
				local previoustext = previous:GetText()
				if previoustext and previoustext == text then
					queue = true -- queue a removal of duplicate lines. this also keeps several blank lines from showing in a row.
				end
				if queue then 
					queue = false
					clean(self, line, text, true)
				else
					cmd, queue = clean(self, line, text)
				end
			end
		end
	end
	if getData(self, "currentEquipmentManagerList") then
		addEquipmentManagerSetList(self)
	end
	if getData(self, "currentItemCrafter") then
		addItemCrafter(self)
	end
	if getData(self, "itemID") then
		addItemID(self)
	end
	clearData(self)
	self:Show()
	UpdateSize(self)
end

-- clean up unit tips
local function OnTooltipSetUnit(self)
	local unit = UpdateUnit(self)
	if not unit then 
		self:Hide()
		return 
	end
	
	wipe(nameString)
	wipe(infoString)
	
	self:SetMinimumWidth(120) -- just doesn't look good below this
	
	GetUnitData(self) -- get info about the info
	GetUnitColor(self) -- update name/health color of the unit
	GetDifficulty(self) -- update level coloring
	GetTarget(self) -- update unit target
	
	-- this can sometimes happen when hovering over battlepets
	if not info.name or not info.color then
		self:Hide()
		return
	end
	
	-- clean up the tip
	for i = 1, self:NumLines() do
		local line = _G["GameTooltipTextLeft"..i]
		if line then
			line:SetTextColor(unpack(C.chat.gray)) -- .5, .5, .5
			local text = line:GetText()
			if text then
				if text == PVP_ENABLED then
					line:SetText("")
				end
				if text == FACTION_ALLIANCE or text == FACTION_HORDE then
					line:SetText("")
				end
				if text == " " then
					local nextLine = _G["GameTooltipTextLeft"..(i + 1)]
					if nextLine then
						local nextText = nextLine:GetText()
						if nextText == COALESCED_REALM_TOOLTIP or nextText == INTERACTIVE_REALM_TOOLTIP then
							line:SetText("")
							nextLine:SetText(nil)
						end
					end
				end
			end
		end
	end
	
	if info.isPlayer then
		if info.ffa then
			tinsert(nameString, "|TInterface\\TargetingFrame\\UI-PVP-FFA:16:12:-2:1:64:64:6:34:0:40|t")
		elseif info.pvp and info.faction then
			if info.faction == "Horde" then
				tinsert(nameString, "|TInterface\\TargetingFrame\\UI-PVP-Horde:16:16:-4:0:64:64:0:40:0:40|t")
			else
				tinsert(nameString, "|TInterface\\TargetingFrame\\UI-PVP-"..info.faction..":16:12:-2:1:64:64:6:34:0:40|t")
			end
		end
		if module.db.profile.showPlayerTitle then
      if info.pvpName then
        tinsert(nameString, info.color.colorCode..info.pvpName.."|r")
      end
		else
			tinsert(nameString, info.color.colorCode..info.name.."|r")
		end
		if info.afk then
			tinsert(nameString, _STRINGS.AFK)
		elseif info.dnd then 
			tinsert(nameString, _STRINGS.DND)
		end
		if info.guild then
			_G.GameTooltipTextLeft2:SetFormattedText(_STRINGS.guildString, info.guild)
		end
		if info.level > 0 then
			tinsert(infoString, info.difficultyColor.colorCode..info.level.."|r")
		else
			tinsert(infoString, "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16:-2:1|t")
		end
		if module.db.profile.showPlayerGender then
			tinsert(infoString, info.gender)
		end
		tinsert(infoString, info.raceName)
		tinsert(infoString, info.color.colorCode..info.className.."|r")
	else
		if info.isBoss then
			tinsert(nameString, "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16:-2:1|t")
		end
		tinsert(nameString, info.color.colorCode..info.name.."|r")
		if info.titleIndex then
			_G["GameTooltipTextLeft"..info.titleIndex]:SetFormattedText(_STRINGS.titleString, info.title)
		end
		if info.creatureType == _STRINGS.notSpecified and info.level == 1 or not info.level then
		elseif info.isBoss then
			tinsert(infoString, _STRINGS.classificationStrings.worldboss)
		else
			tinsert(infoString, _STRINGS.classificationStrings[info.classification]:format(info.difficultyColor.colorCode..info.level.."|r"))
			tinsert(infoString, info.creatureType)
		end
	end
	
	_G.GameTooltipTextLeft1:SetText(tconcat(nameString, " "))
	if info.levelIndex then
		_G["GameTooltipTextLeft"..info.levelIndex]:SetText(tconcat(infoString, " "))
	end

	if info.target and module.db.profile.showTarget then 
		if not info.targetIndex then
			info.targetIndex = self:NumLines() + 1
			local color 
			if UnitIsDead(info.target) then 
				color = C.dead
			elseif UnitIsPlayer(info.target) then
				if not UnitIsConnected(info.target) then
					color = C.disconnected
				else
					local class = select(2, UnitClass(info.target))
					if class then
						color = C.class[class]
					else
						color = C.chat.normal
					end
				end
			else
				local tapped = LEGION and UnitIsTapDenied(unit) or not LEGION and (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit))
				local reaction = UnitReaction(info.target, "player")
				if tapped then
					color = C.tapped
				elseif reaction then 
					color = C.reaction[reaction]
				else
					color = C.chat.normal
				end
			end
			self:AddDoubleLine("|cffffd100"..L["Targeting: "].."|r", color.colorCode.."[" .. info.targetName .. "]|r") 
		end
	elseif info.targetIndex then
		_G["GameTooltipTextRight"..info.targetIndex]:SetText(nil)
		_G["GameTooltipTextLeft"..info.targetIndex]:SetText(nil)
	end
	self:Show()
	SetUpBars(self, unit) -- update the unit's health and power bars
end

-- not automatically called on SetUnitAura or SetUnitDebuff
local function OnTooltipSetSpell(self)
	if not UpdateSpell(self) then return end
	GetSpellData(self)
	if getData(self, "spellID") then
		addSpellID(self)
	end
	if getData(self, "casterName") then
		addCasterName(self)
	end
	if getData(self, "isBossDebuff") then
		addItemID(self)
	end
	clearData(self)
	self:Show()
	UpdateSize(self)
end

-- reset the entire tip
local function OnTooltipCleared(self)
	wipe(info)
	clearData(self)
	for element, bar in pairs(bars) do
		bar:Hide()
	end
end

local function OnShow(self)
	UpdateSize(self)
	if self:IsOwned(UIParent) and not self:GetUnit() then
		setData(self, "scheduleRefresh", nil)
	end
end

local function OnHide(self)
	wipe(info)
	clearData(self)
	for element, bar in pairs(bars) do
		bar:Hide()
	end
	self.talentFrameSpellIDSet = nil
end

local function OnItemRefHide(self)
	clearData(self)
end

local function OnUpdate(self)
	-- correct backdrop color for world frame tips
	if getData(self, "scheduleRefresh") then
		setData(self, "scheduleRefresh", false)
	end
	
	-- instantly hide tips instead of fading
	if getData(self, "scheduleHide") 
	or (info.unit and not UnitExists("mouseover")) -- fading unit tips
	or (self:GetAlpha() < 1 ) then -- fading structure tips (walls, gates, etc)
		self:Show() -- this kills the blizzard fading
		self:Hide()
		setData(self, "scheduleHide", false)
	end
	
	-- check if number of lines have changed, and update if needed
	if getData(self, "tipLines") ~= self:NumLines() then
		setData(self, "tipLines", self:NumLines())
		UpdateSize(self)
	end
	
	-- check if the tip size has changed, and correct the size if it has
	local height, tipHeight = self:GetHeight(), getData(self, "tipHeight")
	if tipHeight and abs(height - tipHeight) > .01 then
		self:SetHeight(tipHeight)
	end
	local width, tipWidth = self:GetWidth(), getData(self, "tipWidth")
	if tipWidth and abs(width - tipWidth) > .01 then -- reduced from .1 to .01 to prevent the tooltip lines from "jumping"
		self:SetWidth(tipWidth)
	end
	
	-- lock the tooltip to our anchor
	local point, owner, relpoint, x, y = self:GetPoint()
	if owner == UIParent then
		--self:SetOwner(owner, "ANCHOR_NONE") 
		self:ClearAllPoints()
		self:SetPoint(_ANCHOR:GetPoint())
	end
end

local function UpdateStatusBar(self)
	local min = GameTooltipStatusBar:GetValue()
	local _, max = GameTooltipStatusBar:GetMinMaxValues()
	bars.health:SetMinMaxValues(0, max)
	bars.health:SetValue(min)
	bars.health:SetStatusBarColor(unpack(gUI4:GetColors("health")))
	if min == 0 then
		bars.health.value:SetText(_STRINGS.DEAD)	
	elseif min < max then
		bars.health.value:SetFormattedText(_STRINGS.missingString, floor(min / max * 100), short(min))
	elseif min > 0 then
		bars.health.value:SetFormattedText(_STRINGS.fullString, short(min))
	end
end

local function SetUpStatusBar(self)
	local min = GameTooltipStatusBar:GetValue()
	local _, max = GameTooltipStatusBar:GetMinMaxValues()
	if min > 0 then -- the tooltip gets reset when a unit die, so no risk of weird size changes here. this is a fresh tooltip.
		LMP:NewChain(bars.health) :ClearAllPoints() :SetPoint("BOTTOMLEFT", 6, 6) :SetPoint("BOTTOMRIGHT", -6, 6) :Show() :EndChain()
	else
		bars.health:Hide()
		bars.power:Hide()
	end
	-- UpdateStatusBar(self)
	UpdateBarOffset(self)
	UpdateSize(self)
end

local function StatusBarOnShow(self)
	if info.unit then return end 
	info.isGate = true
	if not bars.health:IsShown() then
		bars.health:Show()
		SetUpStatusBar(self)
		UpdateStatusBar(self)
	else
		UpdateStatusBar(self)
	end
	GameTooltipStatusBar:Hide()
end

local function StatusBarOnHide(self)
	if info.unit then return end
end

local function StatusBarOnValueChanged(self)
	if info.unit then return end 
	UpdateStatusBar(self)
end

function module:CreateHooks()
	GameTooltip:HookScript("OnUpdate", OnUpdate)
	GameTooltip:HookScript("OnShow", OnShow)
	GameTooltip:HookScript("OnHide", OnHide)
	GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
	GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
	GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
	hooksecurefunc(GameTooltip, "SetBagItem", SetBagItem)
	hooksecurefunc(GameTooltip, "SetHyperlink", SetHyperlink)
	hooksecurefunc(GameTooltip, "SetInventoryItem", SetInventoryItem)
	hooksecurefunc(GameTooltip, "SetLootItem", SetLootItem)
	hooksecurefunc(GameTooltip, "SetUnitAura", SetUnitAura)
	hooksecurefunc(GameTooltip, "SetUnitDebuff", SetUnitDebuff)
	
	ShoppingTooltip1:HookScript("OnTooltipCleared", OnTooltipCleared)
	ShoppingTooltip1:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	hooksecurefunc(ShoppingTooltip1, "SetBagItem", SetBagItem)
	hooksecurefunc(ShoppingTooltip1, "SetHyperlink", SetHyperlink)
	hooksecurefunc(ShoppingTooltip1, "SetInventoryItem", SetInventoryItem)
	hooksecurefunc(ShoppingTooltip1, "SetLootItem", SetLootItem)
	hooksecurefunc(ShoppingTooltip1, "SetUnitAura", SetUnitAura)
	hooksecurefunc(ShoppingTooltip1, "SetUnitDebuff", SetUnitDebuff)

	ShoppingTooltip2:HookScript("OnTooltipCleared", OnTooltipCleared)
	ShoppingTooltip2:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	hooksecurefunc(ShoppingTooltip2, "SetBagItem", SetBagItem)
	hooksecurefunc(ShoppingTooltip2, "SetHyperlink", SetHyperlink)
	hooksecurefunc(ShoppingTooltip2, "SetInventoryItem", SetInventoryItem)
	hooksecurefunc(ShoppingTooltip2, "SetLootItem", SetLootItem)
	hooksecurefunc(ShoppingTooltip2, "SetUnitAura", SetUnitAura)
	hooksecurefunc(ShoppingTooltip2, "SetUnitDebuff", SetUnitDebuff)
	

	hooksecurefunc("GameTooltip_SetDefaultAnchor", SetDefaultAnchor)
	-- hooksecurefunc("SetItemRef", SetItemRef)
	hooksecurefunc(ItemRefTooltip, "SetHyperlink", SetHyperlink)
	ItemRefTooltip:HookScript("OnHide", OnItemRefHide)
	
	-- this allows us to track unitless tips with healthbars (walls, gates, etc)
	GameTooltipStatusBar:HookScript("OnShow", StatusBarOnShow)
	GameTooltipStatusBar:HookScript("OnHide", StatusBarOnHide)
	GameTooltipStatusBar:HookScript("OnValueChanged", StatusBarOnValueChanged)
	
	self.CreateHooks = nil
end

function module:StyleTooltips()
	for _, name in ipairs(_TOOLTIPS) do
		local tooltip = _G[name]
		if tooltip and not styled[tooltip] then
			styleTooltip(tooltip)
		end
	end
	-- for tradeskillmaster and other addons using LibExtraTip
	local lib, version = GP_LibStub("LibExtraTip-1", true) 
	if lib then
		hooksecurefunc(lib, "GetFreeExtraTipObject", function()
			local n = 1
			local tooltip = _G["LibExtraTip_1_"..version.."Tooltip"..n]
			while tooltip do
				if not styled[tooltip] then
					styleTooltip(tooltip)
					if tooltip.MatchSize then
						-- replace resizing functionality with our own, to avoid the right side text bouncing back and forth
						-- tested with LibExtraTip build 328
						local function fixRight(tooltip, shift)
							local rights, rightname
							rights = tooltip.Right
							if not rights then
								rightname = tooltip:GetName().."TextRight"
							end
							for line = 1, tooltip:NumLines() do
								local right
								if rights then
									right = rights[line]
								else
									right = _G[rightname..line]
								end
								if right and right:IsVisible() then
									for index = 1, right:GetNumPoints() do
										local point, relativeTo, relativePoint, xofs, yofs = right:GetPoint(index)
										if xofs then
											right:SetPoint(point, relativeTo, relativePoint, xofs + shift, yofs)
										end
									end
								end
							end
						end
						function tooltip:MatchSize()
							local p = self.parent
							local pw = floor(p:GetWidth() + .5) -- update: using rounded numbers
							local w = floor(self:GetWidth() + .5) -- update: using rounded numbers
							local d = pw - w
							if d > 1 then -- update: using a delta of 1 insted of .005
								self.sizing = true
								self:SetWidth(pw)
								fixRight(self, d)
							elseif d < 1 then -- update: using a delta of 1 insted of .005
								local reg = lib.tooltipRegistry[p]
								if not reg.NoColumns then
									self.sizing = true
									p:SetWidth(w)
									UpdateSize(p) -- update: updating our own size reference to avoid this being reset at the next OnUpdate
									fixRight(p, -d)
								end
							end
						end	
					end
				end
				n = n + 1
				tooltip = _G["LibExtraTip_1_"..version.."Tooltip"..n]
			end
		end)
	end
end

function module:StyleMenus()
	for _, name in ipairs(_DROPDOWNS) do
		local menu = _G[name]
		if menu and not styled[menu] then
			styleMenu(menu)
		end
	end
	
	-- initial styling of menus and backdrops
	self.numDropdowns = UIDROPDOWNMENU_MAXLEVELS
	for i = 1, self.numDropdowns do
		local menu =  _G["DropDownList" .. i .. "MenuBackdrop"]
		local dropdown = _G["DropDownList" .. i .. "Backdrop"]
		if menu and not styled[menu] then
			styleMenu(menu)
		end
		if dropdown and not styled[dropdown] then
			styleMenu(dropdown)
		end
	end

	-- since only the first 2 dropdown levels are created upon login,
	-- we're going to hook ourself into the creation process for the rest
	if not self.styleDropdowns then
		self.styleDropdowns = function(level, index)
			local num = UIDROPDOWNMENU_MAXLEVELS
			if num > self.numDropdowns then
				for i = self.numDropdowns+1, num do
					local menu =  _G["DropDownList" .. i .. "MenuBackdrop"]
					local dropdown = _G["DropDownList" .. i .. "Backdrop"]
					if menu and not styled[menu] then
						styleMenu(menu)
					end
					if dropdown and not styled[dropdown] then
						styleMenu(dropdown)
					end
				end
				self.numDropdowns = num
			end
		end
		hooksecurefunc("UIDropDownMenu_CreateFrames", self.styleDropdowns)
	end
end

function module:PLAYER_LEVEL_UP(event, level)
	_LEVEL = level
end

function module:VARIABLES_LOADED()
	_IS_COLOR_BLIND = GetCVar("colorblindMode") == "1"
	self.variablesLoaded = true
	if self.enteredWorld then
		self:CreateHooks()
	end
	self:UnregisterEvent("VARIABLES_LOADED")
end

function module:CVAR_UPDATE(event, var, value)
	if var == "USE_COLORBLIND_MODE" then
		_IS_COLOR_BLIND = value == "1"
	end
end

function module:PLAYER_ENTERING_WORLD()
	self.enteredWorld = true
	if self.variablesLoaded then
		self:CreateHooks()
	end
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function module:Lock()
	_ANCHOR.overlay:StartFadeOut()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	_ANCHOR.overlay:SetAlpha(0)
	_ANCHOR.overlay:Show()
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not hasTheme then return end
	if not _ANCHOR then return end
	updateConfig()
	self.db.profile.position.point = nil
	self.db.profile.position.y = nil
	self.db.profile.position.x = nil
	self.db.profile.locked = true
	wipe(self.db.profile.position)
	self:ApplySettings()
end

function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(self) then return end
	if not _ANCHOR then return end
	updateConfig()
	
	-- update backdrops
	for owner, backdrop in pairs(backdrops) do
		styleBackdrop(backdrop, owner)
	end
	
	-- update bars
	for element, bar in pairs(bars) do
		LMP:NewChain(bar) :SetHeight(T.bar.size) :SetStatusBarTexture(T.bar.textures.normal:GetPath()) :SetBackdropTexture(T.bar.textures.backdrop:GetPath()) :SetBackdropMultiplier(T.bar.backdropmultiplier) :EndChain() -- :SetOverlayTexture(T.bar.textures.overlay:GetPath())
		LMP:NewChain(bar.value) :SetFontObject(T.bar.value.fontobject) :SetHeight(T.bar.value.size) :SetFontSize(T.bar.value.fontsize or T.bar.value.size) :SetShadowColor(unpack(T.bar.value.shadowcolor)) :SetShadowOffset(unpack(T.bar.value.shadowoffset)) :SetFontStyle(T.bar.value.fontstyle) :EndChain()
	end
	
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	if not _ANCHOR then return end 
	updateConfig()
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not _ANCHOR then return end
	updateConfig()
	if self.db.profile.locked then
		LMP:Place(_ANCHOR, T.place)
		if not self.db.profile.position.x then
			_ANCHOR:RegisterConfig(self.db.profile.position)
			_ANCHOR:SavePosition()
		end
	else
		_ANCHOR:RegisterConfig(self.db.profile.position)
		if self.db.profile.position.x then
			_ANCHOR:LoadPosition()
		else
			LMP:Place(_ANCHOR, T.place)
			_ANCHOR:SavePosition()
			_ANCHOR:LoadPosition()
		end
	end	
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Tooltips", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["General"],
			args = {
				group0 = {
					type = "header",
					width = "full",
					order = 1,
					name = L["All Tooltips"]
				},
			
				hideBlank = {
					type = "toggle",
					width = "full",
					order = 21,
					name = L["Hide blank lines."],
					desc = L["Removes blank or empty lines from the tooltip."],
					get = function() return self.db.profile.hideBlank end,
					set = function(info, value) self.db.profile.hideBlank = value end
				},
				
				group1 = {
					type = "header",
					width = "full",
					order = 100,
					name = L["Unit Tooltips"]
				},
				title1 = {
					type = "description",
					width = "full",
					order = 110,
					name = L["|n|cffffd200" .. "Unit Names" .. "|r"]
				},
				description1 = {
					type = "description",
					width = "full",
					order = 111,
					name = L["Select how a character's name is displayed in the tooltip and what elements are included.|n|n"]
				},
				showPlayerRealm = {
					type = "toggle",
					width = "full",
					order = 112,
					name = L["Show player realm."],
					desc = L["Displays the realm name of players next to their name."],
					get = function() return self.db.profile.showPlayerRealm end,
					set = function(info, value) self.db.profile.showPlayerRealm = value end
				},
				showPlayerTitle = {
					type = "toggle",
					width = "full",
					order = 113,
					name = L["Show player title."],
					desc = L["Displays the currently selected title of players next to their name."],
					get = function() return self.db.profile.showPlayerTitle end,
					set = function(info, value) self.db.profile.showPlayerTitle = value end
				},
				showPlayerGender = {
					type = "toggle",
					width = "full",
					order = 114,
					name = L["Show player gender."],
					desc = L["Displays the gender of player characters next to their level, race and class."],
					get = function() return self.db.profile.showPlayerGender end,
					set = function(info, value) self.db.profile.showPlayerGender = value end
				},
				title1b = {
					type = "description",
					width = "full",
					order = 120,
					name = L["|n|cffffd200" .. "Additional Unit Info" .. "|r"]
				},
				description1b = {
					type = "description",
					width = "full",
					order = 121,
					name = L["Choose whether or not to show additional unit info like who the unit is targeting, it's current power and so on.|n|n"]
				},
				showPowerBar = {
					type = "toggle",
					width = "full",
					order = 122,
					name = L["Show power bars."],
					desc = L["Displays power bars below the unit health bar when available."],
					get = function() return self.db.profile.showPowerBar end,
					set = function(info, value) self.db.profile.showPowerBar = value end
				},
				showTarget = {
					type = "toggle",
					width = "full",
					order = 123,
					name = L["Show unit target."],
					desc = L["Displays who or what the unit is currently targeting."],
					get = function() return self.db.profile.showTarget end,
					set = function(info, value) self.db.profile.showTarget = value end
				},

				group2 = {
					type = "header",
					width = "full",
					order = 200,
					name = L["Item Tooltips"]
				},

				title3c = {
					type = "description",
					width = "full",
					order = 201,
					name = L["|n|cffffd200" .. "Item Information" .. "|r"]
				},
				description3c = {
					type = "description",
					width = "full",
					order = 202,
					name = L["Toggle general information about the item's power or price."]
				},

				hideItemLevel = {
					type = "toggle",
					width = "full",
					order = 204,
					name = L["Hide item level."],
					desc = L["Hides the item level describing the overall power of this item from the tooltip."],
					get = function() return self.db.profile.hideItemLevel end,
					set = function(info, value) self.db.profile.hideItemLevel = value end
				},
				hideItemID = {
					type = "toggle",
					width = "full",
					order = 205,
					name = L["Hide item ID."],
					desc = L["Hides the item ID of this item from the tooltip. Item IDs are used to identify items by the game, as well as most fansites like www.wowhead.com and similar."],
					get = function() return self.db.profile.hideItemID end,
					set = function(info, value) self.db.profile.hideItemID = value end
				},
				hideItemValue = {
					type = "toggle",
					width = "full",
					order = 206,
					name = L["Hide sell value."],
					desc = L["Hides the sell value of this item from the tooltip."],
					get = function() return self.db.profile.hideItemValue end,
					set = function(info, value) self.db.profile.hideItemValue = value end
				},
				hideItemCrafter = {
					type = "toggle",
					width = "full",
					order = 207,
					name = L["Hide item crafter."],
					desc = L["Hides who the crafter of the current items is."],
					get = function() return self.db.profile.hideItemCrafter end,
					set = function(info, value) self.db.profile.hideItemCrafter = value end
				},
				
				title3b = {
					type = "description",
					width = "full",
					order = 210,
					name = L["|n|cffffd200" .. "Item Sets & Bonuses" .. "|r"]
				},
				description3b = {
					type = "description",
					width = "full",
					order = 211,
					name = L["Toggle information about what equipment manager sets you have included this item in, as well as what gear sets this item belongs to and what bonuses they bring."]
				},

				hideEquipmentManagerSets = {
					type = "toggle",
					width = "full",
					order = 212,
					name = L["Hide Equipment Manager sets the item is part of."],
					desc = L["Hides what Equipment Manager sets the item is a part of."],
					get = function() return self.db.profile.hideEquipmentManagerSets end,
					set = function(info, value) self.db.profile.hideEquipmentManagerSets = value end
				},
				hideSetListItems = {
					type = "toggle",
					width = "full",
					order = 213,
					name = L["Hide the list of items in the current gear set."],
					desc = L["Hides the list of items in item sets such as Cenarion Rayment and Gladiator's Sanctuary. Only the set name and number of current items will be displayed."],
					get = function() return self.db.profile.hideSetListItems end,
					set = function(info, value) self.db.profile.hideSetListItems = value end
				},

				title3 = {
					type = "description",
					width = "full",
					order = 220,
					name = L["|n|cffffd200" .. "Item Transmogrification" .. "|r"]
				},
				description3 = {
					type = "description",
					width = "full",
					order = 221,
					name = L["Item transmogrification is when an item is made to look like something else. This can also apply to illusions like custom weapon enchant glows created with the Enchanter's Study in your Garrison."]
				},
				hideTransmogDescription = {
					type = "toggle",
					width = "full",
					order = 222,
					name = L["Hide transmogrifications."],
					desc = L["Hides the transmogrification description from items that have been transmogrified to look like something else."],
					get = function() return self.db.profile.hideTransmogDescription end,
					set = function(info, value) self.db.profile.hideTransmogDescription = value end
				},
				hideTransmogLabelOnly = {
					type = "toggle",
					width = "full",
					order = 223,
					name = L["Only hide the transmogrification labels."],
					desc = L["Only hides the label indicating that an item has been transmogrified. Does not affect the transmogrification description itself."],
					disabled = function() return not self.db.profile.hideTransmogDescription end,
					get = function() return self.db.profile.hideTransmogLabelOnly end,
					set = function(info, value) self.db.profile.hideTransmogLabelOnly = value end
				},
				
				title4 = {
					type = "description",
					width = "full",
					order = 230,
					name = L["|n|cffffd200" .. "Item Enchantments" .. "|r"]
				},
				description4 = {
					type = "description",
					width = "full",
					order = 231,
					name = L["Item enchantments can refer to any sort added or created enhancement on an item."]
				},
				hideEnchantMent = {
					type = "toggle",
					width = "full",
					order = 233,
					name = L["Hide enchantments."],
					desc = L["Hides all enchantments on this item."],
					get = function() return self.db.profile.hideEnchantMent end,
					set = function(info, value) self.db.profile.hideEnchantMent = value end,
				},
				hideEnchantMentLabelOnly = {
					type = "toggle",
					width = "full",
					order = 234,
					name = L["Only hide the enchantment label."],
					desc = L["Only hides the label indicating that it's an enchantment, but displays the enchantment details."],
					disabled = function() return not self.db.profile.hideEnchantMent end,
					get = function() return self.db.profile.hideEnchantMentLabelOnly end,
					set = function(info, value) self.db.profile.hideEnchantMentLabelOnly = value end
				},
				
				title5 = {
					type = "description",
					width = "full",
					order = 240,
					name = L["|n|cffffd200" .. "Item Requirements" .. "|r"]
				},
				description5 = {
					type = "description",
					width = "full",
					order = 241,
					name = L["Some items have requirements in order to use them. This can include level, race, class, reputation and a variety of other things."]
				},
				hideRequirements = {
					type = "toggle",
					width = "full",
					order = 242,
					name = L["Hide requirements."],
					desc = L["Hides all requirements to wear this item, like race, class or level."],
					get = function() return self.db.profile.hideRequirements end,
					set = function(info, value) 
						self.db.profile.hideRequirements = value 
					end,
				},
				hideRequirementsMet = {
					type = "toggle",
					width = "full",
					order = 243,
					name = L["Only hide met requirements."],
					desc = L["Hides requirements to wear this item if they are met, but displays them otherwise."],
					disabled = function() return not self.db.profile.hideRequirements end,
					get = function() return self.db.profile.hideRequirementsMet end,
					set = function(info, value) self.db.profile.hideRequirementsMet = value end
				},
				
				title5 = {
					type = "description",
					width = "full",
					order = 240,
					name = L["|n|cffffd200" .. "Item Requirements" .. "|r"]
				},
				description5 = {
					type = "description",
					width = "full",
					order = 241,
					name = L["Some items have requirements in order to use them. This can include level, race, class, reputation and a variety of other things."]
				},
				
				
				
		-- hideRightClickBuy = true,
		-- hideRightClickSocket = true,

		-- hideDurability = false,
		-- hideRaidDifficulty = false,
		-- hideSetBonuses = false,

		-- hideSoulbound = false,
		-- hideUnique = false,
		-- hideUpgradeLevel = false,				
				
			}
		}
	})
end

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_Tooltip_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end

	for i in pairs(deprecated_settings) do
		if self.db.profile[i] ~= nil then
			self.db.profile[i] = nil
		end
	end
	updateConfig()
	
	-- anchor
	_ANCHOR = LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :SetSize(64, 64) .__EndChain
	_ANCHOR.overlay = gUI4:GlockThis(_ANCHOR, L["Tooltip"], function() return self.db.profile end, unpack(C.glock.floaters))
	_ANCHOR.UpdatePosition = function() module:UpdatePosition() end
	_ANCHOR.GetSettings = function() return self.db.profile end

	-- custom bars
	bars.health = LMP:NewChain("StatusBar", nil, GameTooltip) :Hide() .__EndChain
	bars.health.parent = GameTooltip
	bars.health.value = LMP:NewChain("FontString", nil, bars.health) :SetFontObject(TextStatusBarText) :SetFontSize(12) :SetFontStyle(nil) :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", 4) :SetJustifyH("CENTER") :SetJustifyV("MIDDLE") :SetPoint("CENTER", 0, 0) .__EndChain
	bars.health:SetScript("OnEvent", function(self, event, unit)
		if not self:IsVisible() then return end
		if unit == info.unit then
			UpdateBars(self.parent)
		end
	end)
	bars.health:RegisterEvent("UNIT_HEALTH")
	bars.health:RegisterEvent("UNIT_MAXHEALTH")

	bars.power = LMP:NewChain("StatusBar", nil, GameTooltip) :Hide() .__EndChain
	bars.power.parent = GameTooltip
	bars.power.value = LMP:NewChain("FontString", nil, bars.power) :SetFontObject(TextStatusBarText) :SetFontSize(12) :SetFontStyle(nil) :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", 4) :SetJustifyH("CENTER") :SetJustifyV("MIDDLE") :SetPoint("CENTER", 0, 0) .__EndChain
	bars.power:SetScript("OnEvent", function(self, event, unit)
		if not self:IsVisible() then return end
		if (event == "UPDATE_SHAPESHIFT_FORM" and info.unit == "player") or (unit == info.unit) then
			UpdateBars(self.parent)
		end
	end)
	bars.power:RegisterEvent("UNIT_POWER")
	bars.power:RegisterEvent("UNIT_MAXPOWER")
	bars.power:RegisterEvent("UNIT_DISPLAYPOWER")
	bars.power:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("CVAR_UPDATE")
	self:RegisterEvent("ADDON_LOADED", "StyleTooltips")
end

function module:OnEnable()
	_LEVEL = UnitLevel("player")
	self:StyleMenus()
	self:StyleTooltips()
	self:SetActiveTheme(self.db.profile.skin)
end

function module:OnDisable()
end
