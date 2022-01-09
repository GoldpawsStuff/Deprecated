local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996
if LEGION then
	return
end

-- Lua API
local floor = math.floor
local select = select

-- WoW API
local GetSpecialization = GetSpecialization
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local widget = "BurningEmbersWidget"
local isWarlock = select(2, UnitClass("player")) == "WARLOCK"
local showBurningEmbers = GetSpecialization() == SPEC_WARLOCK_DESTRUCTION
local inVehicle = UnitHasVehicleUI("player")

local Update = function(self, event, ...)
	local arg1, arg2 = ...
	local BurningEmbers = self[widget]
	if BurningEmbers.PreUpdate then
		BurningEmbers:PreUpdate()
	end
	if event == "PLAYER_ENTERING_WORLD"
	or event == "UNIT_ENTERED_VEHICLE"
	or event == "UNIT_EXITED_VEHICLE" then
		inVehicle = UnitHasVehicleUI("player")
	end
	showBurningEmbers = GetSpecialization() == SPEC_WARLOCK_DESTRUCTION
	if showBurningEmbers and not inVehicle and not BurningEmbers:IsShown() then
		BurningEmbers:Show()
	elseif (inVehicle or not showBurningEmbers) and BurningEmbers:IsShown() then
		BurningEmbers:Hide()
	end
	local min = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
	local max = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS, true)
	local numEmbers = floor(min / MAX_POWER_PER_EMBER)
	local maxEmbers = floor(max / MAX_POWER_PER_EMBER)
	local rest = min%MAX_POWER_PER_EMBER
	for i = 1, maxEmbers do
		if i <= numEmbers then
			BurningEmbers[i]:SetValue(MAX_POWER_PER_EMBER)
			BurningEmbers[i]:SetMinMaxValues(0, MAX_POWER_PER_EMBER)
		elseif i == numEmbers + 1 then
			BurningEmbers[i]:SetValue(rest)
			BurningEmbers[i]:SetMinMaxValues(0, MAX_POWER_PER_EMBER)
		else
			BurningEmbers[i]:SetValue(0)
			BurningEmbers[i]:SetMinMaxValues(0, MAX_POWER_PER_EMBER)
		end
		local value = BurningEmbers[i].value
		if value then
			local current
			if i <= numEmbers then
				value:SetAlpha(1)
				value:SetFormattedText("%d", MAX_POWER_PER_EMBER)
			elseif i == numEmbers + 1 then
				if rest > 0 then
					value:SetAlpha(.75)
					value:SetFormattedText("|cff888888%d|r", rest)
				else
					value:SetAlpha(.75)
					value:SetText("|cff8888880|r")
				end
			else
				value:SetAlpha(.75)
				value:SetText("|cff8888880|r")
			end
		end
	end
	if BurningEmbers.PostUpdate then
		BurningEmbers:PostUpdate(min)
	end
end

local Path = function(self, ...)
	return (self[widget].Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'BURNING_EMBERS')
end

local Disable = function(self)
	local BurningEmbers = self[widget]
	if BurningEmbers then 
		self:UnregisterEvent("UNIT_POWER", Path)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Path)
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", Path)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:UnregisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:UnregisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:UnregisterEvent("GLYPH_ADDED", Path)
		self:UnregisterEvent("GLYPH_UPDATED", Path)
	end
end

local Enable = function(self, unit)
	local BurningEmbers = self[widget]
	if BurningEmbers then 
		if not isWarlock then
			BurningEmbers:Hide()
			return
		end
		BurningEmbers.__owner = self
		BurningEmbers.ForceUpdate = ForceUpdate		
		self:RegisterEvent("UNIT_POWER", Path)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", Path)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", Path)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:RegisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:RegisterEvent("GLYPH_ADDED", Path)
		self:RegisterEvent("GLYPH_UPDATED", Path)
		Path(self, "PLAYER_TALENT_UPDATE") -- force a talent check
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)
