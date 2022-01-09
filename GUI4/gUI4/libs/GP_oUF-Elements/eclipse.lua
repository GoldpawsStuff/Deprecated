local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996
if LEGION then
	return
end

-- Lua API
local select = select

-- WoW API
local GetShapeshiftFormID = GetShapeshiftFormID
local GetSpecialization = GetSpecialization
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

-- local ECLIPSE_BAR_BUFF = GetSpellInfo(79577) 
local ECLIPSE_BAR_SOLAR_BUFF = GetSpellInfo(171744)
local ECLIPSE_BAR_LUNAR_BUFF = GetSpellInfo(171743)
local SPELL_POWER_ECLIPSE = SPELL_POWER_ECLIPSE
local MOONKIN_FORM = MOONKIN_FORM
local spell_moonfire = GetSpellInfo(8921)
local spell_sunfire = GetSpellInfo(93402)
local spell_wrath = GetSpellInfo(5176)
local spell_starfire = GetSpellInfo(2912)

local widget = "EclipseWidget"
local isDruid = select(2, UnitClass("player")) == "DRUID"

local function UNIT_POWER(self, event, unit, powerType)
	if self.unit ~= unit or (event == "UNIT_POWER_FREQUENT" and powerType ~= "ECLIPSE") then return end

	local eb = self[widget]

	local power = UnitPower("player", SPELL_POWER_ECLIPSE)
	local maxPower = UnitPowerMax("player", SPELL_POWER_ECLIPSE)

	if eb.LunarBar then
		eb.LunarBar:SetMinMaxValues(-maxPower, maxPower)
		-- eb.LunarBar:SetValue(power)
		eb.LunarBar:SetValue(power * -1)
	end

	if eb.SolarBar then
		eb.SolarBar:SetMinMaxValues(-maxPower, maxPower)
		-- eb.SolarBar:SetValue(power * -1)
		eb.SolarBar:SetValue(power)
	end
	
	if eb.Value then
		if eb.hasSolarEclipse then
			eb.Value:SetText(ECLIPSE_BAR_SOLAR_BUFF)
		elseif eb.hasLunarEclipse then
			eb.Value:SetText(ECLIPSE_BAR_LUNAR_BUFF)
		else
			eb.Value:SetFormattedText("%d%%", abs(power))
		end
	end
	
	if eb.Guide then
		if eb.hasLunarEclipse then
			eb.Guide:SetText(spell_moonfire)
		elseif eb.hasSolarEclipse then
			eb.Guide:SetText(spell_sunfire)
		else
			if power < 0 then
				eb.Guide:SetText(spell_starfire)
			elseif power > 0 then
				eb.Guide:SetText(spell_wrath)
			else
				if eb.direction == "sun" then
					eb.Guide:SetText(spell_wrath)
				else
					eb.Guide:SetText(spell_starfire)
				end
			end
		end
	end

	if eb.PostUpdatePower then
		return eb:PostUpdatePower(unit, power, maxPower)
	end
end

local function UPDATE_VISIBILITY(self, event)
	local eb = self[widget]

	-- check form/mastery
	local showBar
	local form = GetShapeshiftFormID()
	if not form then
		local ptt = GetSpecialization()
		if ptt and ptt == 1 then -- player has balance spec
			showBar = true
		end
	elseif form == MOONKIN_FORM then
		showBar = true
	end

	if UnitHasVehicleUI("player") then
		showBar = false
	end

	if showBar then
		eb:Show()
	else
		eb:Hide()
	end

	if eb.PostUpdateVisibility then
		return eb:PostUpdateVisibility(self.unit)
	end
end

local function UNIT_AURA(self, event, unit)
	if self.unit ~= unit then return end
	local eb = self[widget]

	local hasSolarEclipse = not not UnitBuff(unit, ECLIPSE_BAR_SOLAR_BUFF)
	local hasLunarEclipse = not not UnitBuff(unit, ECLIPSE_BAR_LUNAR_BUFF)

	if eb.hasSolarEclipse == hasSolarEclipse and eb.hasLunarEclipse == hasLunarEclipse then return end
	eb.hasSolarEclipse = hasSolarEclipse
	eb.hasLunarEclipse = hasLunarEclipse
	
	eb:ForceUpdate()

	if eb.PostUnitAura then
		return eb:PostUnitAura(unit)
	end
end

local function ECLIPSE_DIRECTION_CHANGE(self, event, direction)
	local eb = self[widget]
	eb.directionIsLunar = direction == "moon"
	eb.direction = direction
	if eb.PostDirectionChange then
		return eb:PostDirectionChange(self.unit)
	end
end

local function Update(self, event, ...)
	UNIT_POWER(self, event, ...)
	UNIT_AURA(self, event, ...)
	ECLIPSE_DIRECTION_CHANGE(self, event)
	return UPDATE_VISIBILITY(self, event)
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate", element.__owner.unit, "ECLIPSE")
end

local function Disable(self)
	local eb = self[widget]
	if eb then
		eb:Hide()
		self:UnregisterEvent("ECLIPSE_DIRECTION_CHANGE", ECLIPSE_DIRECTION_CHANGE)
		self:UnregisterEvent("PLAYER_TALENT_UPDATE", UPDATE_VISIBILITY)
		self:UnregisterEvent("UNIT_AURA", UNIT_AURA)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", UNIT_POWER)
		self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM", UPDATE_VISIBILITY)
	end
end

local function Enable(self, unit)
	local eb = self[widget]
	if eb then
		if not isDruid then
			eb:Hide()
			return
		end
		eb.__owner = self
		eb.ForceUpdate = ForceUpdate
		self:RegisterEvent("ECLIPSE_DIRECTION_CHANGE", ECLIPSE_DIRECTION_CHANGE, true)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", UPDATE_VISIBILITY, true)
		self:RegisterEvent("UNIT_AURA", UNIT_AURA)
		self:RegisterEvent("UNIT_POWER_FREQUENT", UNIT_POWER)
		self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", UPDATE_VISIBILITY, true)
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)

