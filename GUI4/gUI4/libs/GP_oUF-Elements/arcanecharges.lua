local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

-- Lua API
local floor = math.floor
local select = select

-- WoW API
local GetSpecialization = GetSpecialization
local GetTime = GetTime
local UnitDebuff = UnitDebuff
local UnitLevel = UnitLevel

local widget = "ArcaneChargesWidget"
local isMage = select(2, UnitClass("player")) == "MAGE"
local arcaneChargeSpellID = 36032
local showCharges = GetSpecialization() == 1
local vehicleHide

local function formatTime(s)
	if s > 5 then
		return "%1d", floor(s)
	elseif s > 3 then
		return "|cffcc6622%1d|r", floor(s)
	else
		return "|cffcc0000%.1f|r", s
	end
end

local updateTimer = function(self, elapsed)
	if not self.expire then return end
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed > 0.1 then	
		local time = self.expire - GetTime()
		if time > 0 then
			self:SetValue(time)
			if self.value then
				self.value:SetFormattedText(formatTime(time))
			end
		else
			self:SetScript("OnUpdate", nil)
		end
		self.elapsed = 0
	end		
end

local update = function(self)
	local unit = self.unit or "player"
	local ArcaneCharges = self[widget]
	local duration, expire
	local charges = 0
	
	if LEGION then
		charges = UnitPower("player", SPELL_POWER_ARCANE_CHARGES)
	else
		for i = 1, 40 do
			local count, _, full, expirationTime, _, _, _, spellID = select(4, UnitDebuff(unit, i))
			if spellID == arcaneChargeSpellID then
				charges = count or 0
				duration = full
				expire = expirationTime
				break
			end
		end	
	end
	for i = 1, charges do
		ArcaneCharges[i]:Show()
	end
	if charges < #ArcaneCharges then
		for i = charges + 1, #ArcaneCharges do
			ArcaneCharges[i]:Hide()
		end
	end
	if charges > 0 and showCharges and not vehicleHide then
		if not LEGION then
			ArcaneCharges.timer.expire = expire
			ArcaneCharges.timer:SetValue(expire - GetTime())
			ArcaneCharges.timer:SetMinMaxValues(0, duration)
			ArcaneCharges.timer:SetScript("OnUpdate", updateTimer)
		end
		ArcaneCharges:Show()
	else
		if not LEGION then
			ArcaneCharges.timer:SetValue(0)
			ArcaneCharges.timer:SetScript("OnUpdate", nil)
		end
		ArcaneCharges:Hide()
	end
end

local Path, Update, ForceUpdate, Enable, Disable
Path = function(self, ...)
	return (self[widget].Override or Update) (self, ...)
end

ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'HOLY_POWER')
end

Update = function(self, event, ...)
	local arg1, arg2 = ...
	local ArcaneCharges = self[widget]
	if event == "PLAYER_ENTERING_WORLD" then
		vehicleHide = UnitHasVehicleUI("player")
		showCharges = GetSpecialization() == 1
	elseif (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and arg1 == "player" then
		vehicleHide = self.unit ~= "player"
	elseif event == "PLAYER_LEVEL_UP" then
		if UnitLevel("player") == 10 then
			self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
			self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
			self:RegisterEvent("UNIT_AURA", Path)
			self:RegisterEvent("UNIT_ENTERED_VEHICLE", Path)
			self:RegisterEvent("UNIT_EXITED_VEHICLE", Path)
			showCharges = GetSpecialization() == 1
		end
	elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
		showCharges = GetSpecialization() == 1
	end
	update(self)
end

Disable = function(self)
	if self[widget] then
		if LEGION then
			self:UnregisterEvent("UNIT_POWER_FREQUENT", Update)
			self:UnregisterEvent("UNIT_MAXPOWER", Update)
			self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
			self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Path)
			self:UnregisterEvent("UNIT_EXITED_VEHICLE", Path)
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
		else
			self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
			self:UnregisterEvent("UNIT_AURA", Path)
			self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Path)
			self:UnregisterEvent("UNIT_EXITED_VEHICLE", Path)
			self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
		end
	end
end

Enable = function(self, unit)
	local ArcaneCharges = self[widget]
	if ArcaneCharges then 
		if not isMage then 
			ArcaneCharges:Hide()
			return
		end
		ArcaneCharges.__owner = self
		ArcaneCharges.ForceUpdate = ForceUpdate	
		
		if LEGION then
			self:RegisterEvent("UNIT_POWER_FREQUENT", Update)
			self:RegisterEvent("UNIT_MAXPOWER", Update)
			self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
			self:RegisterEvent("UNIT_ENTERED_VEHICLE", Path)
			self:RegisterEvent("UNIT_EXITED_VEHICLE", Path)
			self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
			showCharges = GetSpecialization() == 1
			vehicleHide = UnitHasVehicleUI("player")
		else
			if UnitLevel("player") < 10 then
				self:RegisterEvent("PLAYER_LEVEL_UP", Path)
				ArcaneCharges:Hide()
			else
				self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
				self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Path)
				self:RegisterEvent("UNIT_AURA", Path)
				self:RegisterEvent("UNIT_ENTERED_VEHICLE", Path)
				self:RegisterEvent("UNIT_EXITED_VEHICLE", Path)
				self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
				showCharges = GetSpecialization() == 1
				vehicleHide = UnitHasVehicleUI("player")
			end
		end
		
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)
