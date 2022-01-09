local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

-- Lua API

-- WoW API
local CheckInteractDistance = CheckInteractDistance
local GetSpellInfo = GetSpellInfo
local IsInGroup = IsInGroup
local IsSpellInRange = IsSpellInRange
local IsSpellKnown = IsSpellKnown
local UnitIsConnected = UnitIsConnected
local UnitCanAssist = UnitCanAssist
local UnitCanAttack = UnitCanAttack
local UnitIsUnit = UnitIsUnit
local UnitPlayerOrPetInRaid = UnitPlayerOrPetInRaid
local UnitIsDead = UnitIsDead
local UnitOnTaxi = UnitOnTaxi
local UnitInRange = UnitInRange

local HZ = 1/30
local _, unitClass = UnitClass("player")
local objects = {}
local ranges = {}
local frame
local helpSpellName, harmSpellName

local helpID = ({
	DEATHKNIGHT = { 47541 }, -- Death Coil(40yd) - Starter
	DRUID = { 5185 }, -- Healing Touch(40yd) - Lvl 3
	-- HUNTER = {},
	MAGE = { 475 }, -- Remove Curse(40yd) - Lvl 30
	MONK = { 116670 }, -- Vivify (40yd) - Lvl 28
	PALADIN = { 85673 }, -- Word of Glory(40yd) - Lvl 9
	PRIEST = { 2061 }, -- Flash Heal(40yd) - Lvl 3
	-- ROGUE = {},
	SHAMAN = { 331 }, -- Healing Wave(40yd) - Lvl 7
	WARLOCK = { 5697 }, -- Unending Breath(30yd) - Lvl 16
	-- WARRIOR = {}
})[unitClass]

local harmID = ({
	DEATHKNIGHT = { 47541 }, -- Death Coil(30yd) - Starter
	DRUID = { 5176 }, -- Wrath(40yd) - Starter
	HUNTER = { 75 }, -- Auto Shot(5-40yd) - Starter
	MAGE = { 133 }, -- Fireball(40yd) - Starter
	-- MONK = {},
	PALADIN = {
		62124, -- Hand of Reckoning(30yd) - Lvl 14
		879, -- Exorcism(30yd) - Lvl 18
	},
	PRIEST = { 589 }, -- Shadow Word: Pain(40yd) - Lvl 4
	-- ROGUE = {},
	SHAMAN = { 403 }, -- Lightning Bolt(30yd) - Starter
	WARLOCK = { 686 }, -- Shadow Bolt(40yd) - Starter
	WARRIOR = { 355 } -- Taunt(30yd) - Lvl 12
})[unitClass]

local function IsInRange(unit)
	if UnitIsConnected(unit) then
		if UnitCanAssist("player", unit) then
			if helpSpellName and not UnitIsDead(unit) then
				return IsSpellInRange(helpSpellName, unit) == 1
			elseif not UnitOnTaxi("player") then 
				if IsInGroup() then 
					if UnitIsUnit(unit, "player") or UnitIsUnit(unit, "pet") then
						return UnitInRange(unit)
					end
				elseif UnitPlayerOrPetInParty(unit) or UnitPlayerOrPetInRaid(unit) then
					return UnitInRange(unit)
				end
			end
		elseif harmSpellName and not UnitIsDead(unit) and UnitCanAttack("player", unit) then
			return IsSpellInRange(harmSpellName, unit) == 1
		end
		return CheckInteractDistance(unit, 4) 
	end
end

local function UpdateRange(self)
	local InRange = not not IsInRange(self.unit) 
	if ranges[self] ~= InRange then 
		ranges[self] = InRange
		local UnitRange = self.UnitRange
		if UnitRange.Update then
			UnitRange.Update(self, InRange)
		else
			self:SetAlpha(UnitRange[InRange and "insideAlpha" or "outsideAlpha"])
		end
	end
end

local seconds = 0
local function OnUpdate(self, elapsed)
	seconds = seconds + elapsed
	if seconds >= HZ then
		seconds = 0
		for Object in pairs(objects) do
			if Object:IsVisible() then
				UpdateRange(Object)
			end
		end
	end
end

local function GetSpellName(spellIDs)
	if spellIDs then
		for _, ID in ipairs(spellIDs) do
			if IsSpellKnown(ID) then
				return GetSpellInfo(ID)
			end
		end
	end
end

local function OnSpellsChanged()
	helpSpellName, harmSpellName = GetSpellName(helpID), GetSpellName(harmID)
end


local function Update(self, event, unit)
	if event ~= "OnTargetUpdate" then 
		ranges[self] = nil 
		UpdateRange(self) 
	end
end


local function ForceUpdate(self)
	return Update(self.__owner, "ForceUpdate", self.__owner.unit)
end

local function Disable(self)
	objects[self] = nil
	ranges[self] = nil
	if not next(objects) then
		frame:Hide()
		frame:UnregisterEvent("SPELLS_CHANGED")
	end
end

local function Enable(self, unit)
	local unitrange = self.UnitRange
	if unitrange then
		if self.Range then 
			self:DisableElement("Range")
			self.Range = nil 
		end
		unitrange.__owner = self
		unitrange.ForceUpdate = ForceUpdate
		if not frame then
			frame = CreateFrame("Frame")
			frame:SetScript("OnUpdate", OnUpdate)
			frame:SetScript("OnEvent", OnSpellsChanged)
		end
		if not next(objects) then 
			frame:Show()
			frame:RegisterEvent("SPELLS_CHANGED")
			OnSpellsChanged() 
		end
		objects[self] = true
		return true
	end
end

oUF:AddElement("UnitRange", Update, Enable, Disable)