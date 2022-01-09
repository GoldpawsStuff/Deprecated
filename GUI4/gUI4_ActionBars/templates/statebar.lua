local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_ActionBars = gUI4:GetModule("gUI4_ActionBars", true)
if not gUI4_ActionBars then return end

local ButtonBar = gUI4_ActionBars.ButtonBar
local StateBar = setmetatable({}, { __index = ButtonBar })
local StateBar_MT = { __index = StateBar }

gUI4_ActionBars.StateBar = StateBar

local _, playerClass = UnitClass("player")
local common = "[vehicleui:12] 12; [possessbar] 12; [overridebar] 14; [shapeshift] 13; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6"
local stances = {
	["DRUID"] = "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10",
	["ROGUE"] = "[bonusbar:1] 7"
}

local stateDriver
if stances[playerClass] then
	stateDriver = common .. "; " .. stances[playerClass] .. "; [form] 1; 1"
else
	stateDriver = common .. "; [form] 1; 1"
end

function StateBar:ApplySettings()
	ButtonBar.ApplySettings(self)
end

function StateBar:UpdateStateDriver()
	local settings = self:GetSettings()
	local paging = settings.paging
	local driver
	if tostring(self.id) == "1" then 
		driver = stateDriver
	end
	
	if driver then
		self:SetAttribute("_onstate-page", [[
			if newstate == "possess" or newstate == "11" then
				if HasVehicleActionBar() then
					newstate = GetVehicleBarIndex()
				elseif HasOverrideActionBar() then
					newstate = GetOverrideBarIndex()
				elseif HasTempShapeshiftActionBar() then
					newstate = GetTempShapeshiftBarIndex()
				else
					newstate = nil
				end
				if not newstate then
					newstate = 12
				end
			end
			self:SetAttribute("state", newstate)
			control:ChildUpdate("state", newstate)
		]])
	end
	UnregisterStateDriver(self, "page")
	self:SetAttribute("state-page", "0")
	RegisterStateDriver(self, "page", driver or "0")
end

function StateBar:New(id, name, settingsFunc)
	return setmetatable(ButtonBar:New(id, name, settingsFunc), StateBar_MT)
end
