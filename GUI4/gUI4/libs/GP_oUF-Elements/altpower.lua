local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

-- Lua API
local floor = math.floor
local select = select

-- WoW API
local UnitAlternatePowerInfo = UnitAlternatePowerInfo
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitAlternatePowerTextureInfo = UnitAlternatePowerTextureInfo
local ALTERNATE_POWER_INDEX = ALTERNATE_POWER_INDEX

local widget = "AltPowerBarWidget"

--[[ :UpdateTooltip()

 The function called when the widget is hovered. Used to populate the tooltip.

 Arguments

 self - The AltPowerBar element.
]]
local UpdateTooltip = function(self)
	if not self.unit then return end
	if not self.powerName or not self.powerTooltip then
		local barType, min, startInset, endInset, smooth, hideFromOthers, showOnRaid, opaqueSpark, opaqueFlash, anchorTop, powerName, powerTooltip, costString, barID = UnitAlternatePowerInfo(self.unit) -- anchorTop got inserted as 10th return... when?
		self.powerName = powerName
		self.powerTooltip = powerTooltip
		if not self.powerName or not self.powerTooltip then 
			return
		end
	end
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:SetText(self.powerName, 1, 1, 1)
		GameTooltip:AddLine(self.powerTooltip, nil, nil, nil, 1)
		GameTooltip:Show()
	end
end

local OnEnter = function(self)
	if(not self:IsVisible()) then return end

	if (not GameTooltip:IsForbidden()) then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		self:UpdateTooltip()
	end
end

local OnLeave = function()
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end

local PowerTextures = {
	["INTERFACE\\UNITPOWERBARALT\\STONEGUARDJASPER_HORIZONTAL_FILL.BLP"] = { 1, .4, 0 },
	["INTERFACE\\UNITPOWERBARALT\\MAP_HORIZONTAL_FILL.BLP"] = { .97, .81, 0 },
	["INTERFACE\\UNITPOWERBARALT\\STONEGUARDCOBALT_HORIZONTAL_FILL.BLP"] = { .1, .4, .95 },
	["INTERFACE\\UNITPOWERBARALT\\STONEGUARDJADE_HORIZONTAL_FILL.BLP"] = { .13, .55, .13 },
	["INTERFACE\\UNITPOWERBARALT\\STONEGUARDAMETHYST_HORIZONTAL_FILL.BLP"] = { .67, 0, 1 }
}

local UpdatePower = function(self, event, unit, powerType)
	if(self.unit ~= unit or powerType ~= 'ALTERNATE') then return end

	local altpowerbar = self[widget]

	--[[ :PreUpdate()

	 Called before the element has been updated.

	 Arguments

	 self - The AltPowerBar element.
	 ]]
	if(altpowerbar.PreUpdate) then
		altpowerbar:PreUpdate()
	end

	local _, r, g, b
	if (altpowerbar.colorTexture) then
		-- _, r, g, b = UnitAlternatePowerTextureInfo(unit, 2)

		local texture, r, g, b = UnitAlternatePowerTextureInfo(unit, 2, 0) -- 2 = status bar index, 0 = displayed bar
		if texture and PowerTextures[texture] then
			r, g, b = PowerTextures[texture].r, PowerTextures[texture].g, PowerTextures[texture].b
		else
			r, g, b = unpack(ns:GetColors("reaction")[5])
		end
		
	end

	local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)

  local barType, min, startInset, endInset, smooth, hideFromOthers, showOnRaid, opaqueSpark, opaqueFlash, anchorTop, powerName, powerTooltip, costString, barID = UnitAlternatePowerInfo(self.unit) -- anchorTop got inserted as 10th return... when?
	altpowerbar.barType = barType
	altpowerbar.powerName = powerName
	altpowerbar.powerTooltip = powerTooltip
	altpowerbar.bar:SetMinMaxValues(min, max)
	altpowerbar.bar:SetValue(math.min(math.max(cur, min), max))

	if (b) then
		altpowerbar.bar:SetStatusBarColor(r, g, b)
	end
	
	local value = altpowerbar.value or altpowerbar.bar.value
	if value then
		value:SetText(cur.." / "..max)
	end

	--[[ :PostUpdate(min, cur, max)

	 Called after the element has been updated.

	 Arguments

	 self - The AltPowerBar element.
	 min  - The minimum possible power value for the active type.
	 cur  - The current power value.
	 max  - The maximum possible power value for the active type.
	]]
	if(altpowerbar.PostUpdate) then
		return altpowerbar:PostUpdate(min, cur, max)
	end
end


--[[ Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]
local Path = function(self, ...)
	return (self[widget].Override or UpdatePower)(self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit, 'ALTERNATE')
end

local Toggler = function(self, event, unit)
	if(unit ~= self.unit) then return end
	local altpowerbar = self[widget]

	local barType, _, _, _, _, hideFromOthers, showOnRaid = UnitAlternatePowerInfo(unit)
	if(barType and (showOnRaid and (UnitInParty(unit) or UnitInRaid(unit)) or not hideFromOthers or unit == 'player' or self.realUnit == 'player')) then
		self:RegisterEvent('UNIT_POWER', Path)
		self:RegisterEvent('UNIT_MAXPOWER', Path)

		ForceUpdate(altpowerbar)
		altpowerbar:Show()
	else
		self:UnregisterEvent('UNIT_POWER', Path)
		self:UnregisterEvent('UNIT_MAXPOWER', Path)

		altpowerbar:Hide()
	end
	-- print(altpowerbar:IsShown())
end

local Enable = function(self, unit)
	local altpowerbar = self[widget]
	if(altpowerbar) then
		altpowerbar.__owner = self
		altpowerbar.ForceUpdate = ForceUpdate
    altpowerbar.unit = unit

		self:RegisterEvent('UNIT_POWER_BAR_SHOW', Toggler)
		self:RegisterEvent('UNIT_POWER_BAR_HIDE', Toggler)

		altpowerbar:Hide()

		if(altpowerbar:IsMouseEnabled()) then
			if(not altpowerbar:GetScript('OnEnter')) then
				altpowerbar:SetScript('OnEnter', OnEnter)
			end
			altpowerbar:SetScript('OnLeave', OnLeave)

			if(not altpowerbar.UpdateTooltip) then
				altpowerbar.UpdateTooltip = UpdateTooltip
			end
		end

		if(unit == 'player') then
			PlayerPowerBarAlt:UnregisterEvent'UNIT_POWER_BAR_SHOW'
			PlayerPowerBarAlt:UnregisterEvent'UNIT_POWER_BAR_HIDE'
			PlayerPowerBarAlt:UnregisterEvent'PLAYER_ENTERING_WORLD'
		end

		return true
	end
end

local Disable = function(self, unit)
	local altpowerbar = self[widget]
	if(altpowerbar) then
		altpowerbar:Hide()
		self:UnregisterEvent('UNIT_POWER_BAR_SHOW', Toggler)
		self:UnregisterEvent('UNIT_POWER_BAR_HIDE', Toggler)

		if(unit == 'player') then
			PlayerPowerBarAlt:RegisterEvent'UNIT_POWER_BAR_SHOW'
			PlayerPowerBarAlt:RegisterEvent'UNIT_POWER_BAR_HIDE'
			PlayerPowerBarAlt:RegisterEvent'PLAYER_ENTERING_WORLD'
		end
	end
end

oUF:AddElement(widget, Toggler, Enable, Disable)

