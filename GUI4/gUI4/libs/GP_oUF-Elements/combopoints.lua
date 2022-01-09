local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

-- WoW API
local GetComboPoints = GetComboPoints
local IsPlayerSpell = IsPlayerSpell
local UnitBuff = UnitBuff
local UnitHasVehicleUI = UnitHasVehicleUI
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local widget = "ComboPointsWidget"

local playerClass = select(2, UnitClass("player"))
local isDruid = playerClass == "DRUID"
local catformBuffName = GetSpellInfo(768)
local superCatformBuffname = GetSpellInfo(228545) -- 171745 does not exist anymore
local anticipationBuffName = GetSpellInfo(115189) -- rogue points need a major update here
local anticipationSpellID = 114015
local checkAnticipation

local Update = function(self, event, unit)
	if unit == "pet" then return end

	local cpoints = self[widget]
	local apoints = cpoints and self[widget].Anticipation

	if checkAnticipation then
		cpoints.hasAnticipation = true
	else
		cpoints.hasAnticipation = false
	end
	
	if cpoints.PreUpdate then
		cpoints:PreUpdate()
	end

	if apoints and apoints.PreUpdate then
		apoints:PreUpdate()
	end

	local vehicle = UnitHasVehicleUI("player")
	local combo_unit = vehicle and "vehicle" or "player"
	local display = (isDruid and (select(4, UnitBuff("player", catformBuffName, nil)) or select(4, UnitBuff("player", superCatformBuffname, nil)))) or vehicle or not isDruid 
	
	local cp, ap
	if LEGION then
		cp = UnitPower(combo_unit, SPELL_POWER_COMBO_POINTS)
		cp_max = UnitPowerMax(combo_unit, SPELL_POWER_COMBO_POINTS)
		if cp_max > 5 then
			if cp > 5 then
				ap = cp - 5
			else
				ap = 0
			end
		else
			ap = 0
		end
	else
		cp = GetComboPoints(combo_unit, "target") 
		ap = apoints and checkAnticipation and select(4, UnitBuff("player", anticipationBuffName, nil)) or 0
	end

	if apoints then
		for i = 1, 5 do
			if ap >= i then
				cpoints[i+5]:Show()
			else
				cpoints[i+5]:Hide()
			end
		end
	end

	if display and ((cp > 0) or (ap > 0)) then
		cpoints:Show()
	else
		cpoints:Hide()
	end
	for i = 1, 5 do
		if cp >= i then
			cpoints[i]:Show()
		else
			cpoints[i]:Hide()
		end
	end
	
	if apoints and apoints.PostUpdate then
		apoints:PostUpdate(ap)
	end
	if cpoints.PostUpdate then
		return cpoints:PostUpdate(cp)
	end
end

local Path = function(self, ...)
	return (self[widget].Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function SPELLS_CHANGED(self, event, unit)
	local hasAnticipation = IsPlayerSpell(anticipationSpellID)
	if hasAnticipation or isDruid then 
		self:RegisterEvent("UNIT_AURA", Path, true)
		if hasAnticipation and not checkAnticipation then
			checkAnticipation = true
			Update(self, event, unit)
		end
	else
		if not isDruid then
			self:UnregisterEvent("UNIT_AURA", Path, true)
		end
		if checkAnticipation then
			checkAnticipation = false
			Update(self, event, unit)
		end
	end
end

local Enable = function(self)
	local cpoints = self[widget]
	if cpoints then
		cpoints.__owner = self
		cpoints.ForceUpdate = ForceUpdate
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Path, true)
		if LEGION then
			self:RegisterEvent("UNIT_POWER_FREQUENT", Update)
			self:RegisterEvent("UNIT_MAXPOWER", Update)
		else
			self:RegisterEvent("UNIT_COMBO_POINTS", Update)
			self:RegisterEvent("SPELLS_CHANGED", SpellsChanged)
			if HasAnticipation then
				self:RegisterEvent("UNIT_AURA", Update)
			end
		end

		return true
	end
end

local Disable = function(self)
	local cpoints = self[widget]
	if cpoints then
		cpoints:Hide()
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Path)
		if LEGION then
			self:UnregisterEvent("UNIT_POWER_FREQUENT", Update)
			self:UnregisterEvent("UNIT_MAXPOWER", Update)
		else
			self:UnregisterEvent("UNIT_COMBO_POINTS", Update)
			self:UnregisterEvent("SPELLS_CHANGED", SpellsChanged)
			if checkAnticipation then
				self:UnregisterEvent("UNIT_AURA", Update)
			end
		end
	end
end

oUF:AddElement(widget, Path, Enable, Disable)

