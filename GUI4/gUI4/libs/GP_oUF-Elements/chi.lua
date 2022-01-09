local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local IsPlayerSpell = IsPlayerSpell
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local widget = "ChiWidget"
local ascensionSpellID = 115396
local empoweredChiSpellID = 157411
local isMonk = select(2, UnitClass("player")) == "MONK"
local inVehicle = UnitHasVehicleUI("player")
local hasChiBar = GetSpecialization() == 3
local showChi

local Update = function(self, event, ...)
	local arg1, arg2 = ...
	local Chi = self[widget]
	if Chi.PreUpdate then
		Chi:PreUpdate()
	end
	if event == "PLAYER_ENTERING_WORLD"
	or event == "ACTIVE_TALENT_GROUP_CHANGED" then
		hasChiBar = GetSpecialization() == 3
	end
	if hasChiBar then
		local chi = UnitPower("player", SPELL_POWER_CHI)
		showChi = chi > 0
		if event == "PLAYER_ENTERING_WORLD"
		or event == "PLAYER_TALENT_UPDATE"
		or event == "ACTIVE_TALENT_GROUP_CHANGED" then
			if IsPlayerSpell(ascensionSpellID) then
				Chi.hasAscension = true
			else
				Chi.hasAscension = false
			end
			if IsPlayerSpell(empoweredChiSpellID) then
				Chi.hasEmpoweredChi = true
			else
				Chi.hasEmpoweredChi = false
			end
		end
		if event == "PLAYER_ENTERING_WORLD"
		or event == "UNIT_ENTERED_VEHICLE"
		or event == "UNIT_EXITED_VEHICLE" then
			inVehicle = UnitHasVehicleUI("player")
		end
		for i = 1, chi do
			Chi[i]:Show()
		end
		if chi < #Chi then
			for i = chi + 1, #Chi do
				Chi[i]:Hide()
			end
		end
		if showChi and not inVehicle and not Chi:IsShown() then
			Chi:Show()
		elseif (inVehicle or not showChi) and Chi:IsShown() then
			Chi:Hide()
		end
	else
		Chi:Hide()
	end
	if Chi.PostUpdate then
		Chi:PostUpdate(chi)
	end
end

local Path = function(self, ...)
	return (self[widget].Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit, "CHI")
end

local Disable = function(self)
	local Chi = self[widget]
	if Chi then 
		self:UnregisterEvent("UNIT_POWER", Path)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:UnregisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:UnregisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:UnregisterEvent("GLYPH_ADDED", Path)
		self:UnregisterEvent("GLYPH_UPDATED", Path)
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Path)
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", Path)
	end
end

local Enable = function(self, unit)
	local Chi = self[widget]
	if Chi then 
		if not isMonk then 
			Chi:Hide()
			return
		end
		Chi.__owner = self
		Chi.ForceUpdate = ForceUpdate
		hasChiBar = GetSpecialization() == 3
		self:RegisterEvent("UNIT_POWER", Path)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Path)		
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", Path)
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
		self:RegisterEvent("CHARACTER_POINTS_CHANGED", Path)
		self:RegisterEvent("GLYPH_ADDED", Path)
		self:RegisterEvent("GLYPH_UPDATED", Path)
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", Path)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", Path)
		Path(self, "PLAYER_TALENT_UPDATE")
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)
