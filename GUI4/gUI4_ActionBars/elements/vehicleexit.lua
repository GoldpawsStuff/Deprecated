local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local version, build, date, tocversion = GetBuildInfo()
build = tonumber(build)

local module = parent:NewModule("VehicleExitBar", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local GAB10 = GP_LibStub("LibButtonGUI4-1.0")

-- Lua API
local tostring = tostring
local pairs, unpack = pairs, unpack
local tconcat, tinsert = table.concat, table.insert

-- WoW API
local CanExitVehicle = CanExitVehicle
local TaxiRequestEarlyLanding = TaxiRequestEarlyLanding
local UnitAffectingCombat = UnitAffectingCombat
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitOnTaxi = UnitOnTaxi
local VehicleExit = VehicleExit

local T, hasTheme
local ButtonBar = parent.ButtonBar
local VehicleExitBar = setmetatable({}, { __index = ButtonBar })
parent.VehicleExitBar = VehicleExitBar

local TaxiExitBar
if build >= 19678 then -- 6.1
	TaxiExitBar = setmetatable({}, { __index = ButtonBar })
	parent.TaxiExitBar = TaxiExitBar
end

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		barWidth = 1,
		buttons = 1,
		skin = "Warcraft", 
		skinSize = "large",
		growthX = "RIGHT",
		growthY = "DOWN",
		showMacrotext = false,
		showHotkey = true,
		showEquipped = true,
		showGrid = false,
		flyoutDir = "UP",
		position = {},
		alpha = 1,
		visibility = {
			vehicleui = true,
			novehicle = true
		}	
		-- bars = {
			-- vehicle = {
				-- enabled = true,
				-- locked = true,
				-- barWidth = 1,
				-- buttons = 1,
				-- skin = "Warcraft", 
				-- skinSize = "large",
				-- growthX = "RIGHT",
				-- growthY = "DOWN",
				-- showMacrotext = false,
				-- showHotkey = true,
				-- showEquipped = true,
				-- showGrid = false,
				-- flyoutDir = "UP",
				-- position = {},
				-- alpha = 1,
				-- visibility = {
					-- vehicleui = true,
					-- novehicle = true
				-- }
			-- },
			-- taxi = {
				-- enabled = true,
				-- locked = true,
				-- barWidth = 1,
				-- buttons = 1,
				-- skin = "Warcraft", 
				-- skinSize = "large",
				-- growthX = "RIGHT",
				-- growthY = "DOWN",
				-- showMacrotext = false,
				-- showHotkey = true,
				-- showEquipped = true,
				-- showGrid = false,
				-- flyoutDir = "UP",
				-- position = {},
				-- alpha = 1,
				-- visibility = {}
			-- }
		-- }
	}
}
local deprecated_settings = {
	bars = true
	-- enabled = true,
	-- locked = true,
	-- barWidth = true,
	-- buttons = true,
	-- skin = true, 
	-- skinSize = true,
	-- growthX = true,
	-- growthY = true,
	-- showMacrotext = true,
	-- showHotkey = true,
	-- showEquipped = true,
	-- showGrid = true,
	-- flyoutDir = true,
	-- position = true,
	-- alpha = true,
	-- tooltip = true,
	-- visibility = true
}

local defaultButtonSettings = { 
	outOfRangeColoring = "button",
	tooltip = "disabled",
	tooltipAnchor = false,
	showGrid = false,
	saturation = 1,
	desaturateUnusable = true,
	colors = {
		range = { .8, .1, .1 },
		mana = { .5, .5, 1 },
		unusable = { .5, .5, .5 }, 
	},
	hideElements = {
		macro = false,
		hotkey = false,
		equipped = false,
	},
	keyBoundTarget = false,
	clickOnDown = false,
	flyoutDirection = "UP"
}

local function updateConfig()
	T = parent:GetActiveTheme()
end

------------------------------------------------------------------------
-- 	Action Bar Template
------------------------------------------------------------------------
function VehicleExitBar:ApplySettings()
	ButtonBar.ApplySettings(self)
	-- self:UpdateButtons()
	self:UpdateButtonSettings()
end

function VehicleExitBar:UpdateButtonSettings()
end

function VehicleExitBar:ApplyVisibilityDriver()
	self.driver = {}
	-- tinsert(self.driver, "[petbattle]hide")
	tinsert(self.driver, "[vehicleui]hide")
	tinsert(self.driver, "[target=vehicle,exists,canexitvehicle]show")
	tinsert(self.driver, "hide")
	if module.db.profile.enabled then
		UnregisterStateDriver(self, "visibility")
		RegisterStateDriver(self, "visibility", tconcat(self.driver, ";"))
	else
		UnregisterStateDriver(self, "visibility")
		RegisterStateDriver(self, "visibility", "hide")
	end
end

function TaxiExitBar:ApplySettings()
	ButtonBar.ApplySettings(self, module.db.profile)
	-- self:UpdateButtons()
	self:UpdateButtonSettings()
end

function TaxiExitBar:UpdateButtonSettings()
	if not self.buttonSettings then 
		self.buttonSettings = defaultButtonSettings
	end
	self.buttonSettings.clickOnDown = GetCVarBool("ActionButtonUseKeyDown") -- parent.db.profile.clickOnDown
	self.buttonSettings.tooltipAnchor = self.buttonSettings.tooltipAnchor
	for i, button in self:GetAll() do
		-- self.buttonSettings.keyBoundTarget = parent:GetBindingTable()[self.id][i]
		button:UpdateConfig(self.buttonSettings)
	end
	
	-- self:ForAll("UpdateConfig", self.buttonSettings)
	-- self:ForAll("SetAttribute", "buttonlock", GetCVarBool("lockActionBars")) -- parent.db.profile.buttonLock
	-- self:ForAll("UpdateState")
end

function TaxiExitBar:ApplyVisibilityDriver()
	self.driver = {}
	-- tinsert(self.driver, "[petbattle]hide")
	tinsert(self.driver, "[vehicleui][target=vehicle,exists,canexitvehicle]hide")
	tinsert(self.driver, "show")
	if module.db.profile.enabled then
		UnregisterStateDriver(self.taxibarhider, "visibility")
		RegisterStateDriver(self.taxibarhider, "visibility", tconcat(self.driver, ";"))
	else
		UnregisterStateDriver(self.taxibarhider, "visibility")
		RegisterStateDriver(self.taxibarhider, "visibility", "hide")
	end
end

function module:Lock()
	self.bar.overlay:StartFadeOut()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	self.bar.overlay:SetAlpha(0)
	self.bar.overlay:Show()
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not self.bar then return end
	updateConfig() 
	self.db.profile.position.point = nil
	self.db.profile.position.y = nil
	self.db.profile.position.x = nil
	self.db.profile.locked = true
	wipe(self.db.profile.position)
	self:ApplySettings()
end

function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	updateConfig()
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	if not self.bar then return end
	updateConfig() 
	self.bar:ApplySettings(self.db.profile)
	self.bar:UpdateLayout()
	-- self.bar:UpdateButtonSettings()
	self.bar:ForAll("Update")
	self.taxibar:ApplySettings(self.db.profile)
	self.taxibar:UpdateLayout()
	-- self.bar:UpdateButtonSettings()
	self.taxibar:ForAll("Update")
	self:UpdatePosition() 
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.bar then return end
	if self.db.profile.locked then
		self.bar:ClearAllPoints()
		self.bar:SetPoint(T.place("VehicleExit", self.db.profile.skinSize))
		-- self.taxibar:ClearAllPoints()
		-- self.taxibar:SetPoint(T.place("VehicleExit", self.db.profile.skinSize))
		if not self.db.profile.position.x then
			self.bar:RegisterConfig(self.db.profile.position)
			self.bar:SavePosition()
			-- self.taxibar:RegisterConfig(self.db.profile.position)
			-- self.taxibar:SavePosition()
		end
	else
		self.bar:RegisterConfig(self.db.profile.position)
		-- self.taxibar:RegisterConfig(self.db.profile.position)
		if self.db.profile.position.x then
			self.bar:LoadPosition()
			self.taxibar:LoadPosition()
		else
			self.bar:ClearAllPoints()
			self.bar:SetPoint(T.place("VehicleExit", self.db.profile.skinSize))
			self.bar:SavePosition()
			self.bar:LoadPosition()
			-- self.taxibar:ClearAllPoints()
			-- self.taxibar:SetPoint(T.place("VehicleExit", self.db.profile.skinSize))
			-- self.taxibar:SavePosition()
			-- self.taxibar:LoadPosition()
		end
	end
	self.taxibar:ClearAllPoints()
	self.taxibar:SetPoint("CENTER", self.bar, "CENTER", 0, 0)
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("VehicleExitBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	for i in pairs(deprecated_settings) do
		if self.db.profile[i] ~= nil then
			self.db.profile[i] = nil
		end
	end
	self.fadeManager = parent:GetFadeManager() 
end

local exitButton = {
	func = function(self)
		VehicleExit()
	end,
	texture = "Interface\\Icons\\Spell_Shadow_SacrificialShield",
	tooltip = LEAVE_VEHICLE
}

local taxiExitButton = {
	func = function(self)
		if UnitOnTaxi("player") then
			TaxiRequestEarlyLanding()
			self:GetParent():Hide() -- this is the bar, right? :/
		end
	end,
	texture = "Interface\\Icons\\Spell_Shadow_SacrificialShield"
}
taxiExitButton.func = gUI4:SafeCallWrapper(taxiExitButton.func)

function module:UpdateTaxiButtonVisibility()
	if UnitOnTaxi("player") then
	-- if UnitOnTaxi("player") and CanExitVehicle() and not UnitHasVehicleUI("player") then
		self.taxibar:Show()
		self.taxibar.buttons[1]:Enable()
	else
		self.taxibar:Hide()
	end
end
module.UpdateTaxiButtonVisibility = gUI4:SafeCallWrapper(module.UpdateTaxiButtonVisibility)

function module:PLAYER_ENTERING_WORLD()
	self.bar:ApplyVisibilityDriver()
	self.taxibar:ApplyVisibilityDriver()
	self:UpdateTaxiButtonVisibility()
end

function module:OnEnable()
	if not self.bar then
		self.bar = setmetatable(ButtonBar:New("VehicleExitBar", L["Exit Vehicle"], function() return self.db.profile end), { __index = VehicleExitBar })
		self.fadeManager:RegisterObject(self.bar)
		self.bar.overlay = gUI4:GlockThis(self.bar, L["Exit Vehicle"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "actionbars")))
		self.bar.UpdatePosition = function(self) module:UpdatePosition() end
		tinsert(parent.bars, self.bar)
		self.bar.buttons = {}
		self.bar.buttons[1] = GAB10:CreateButton("action", 1, "GUI4VehicleExitButton1", self.bar, nil)
		self.bar.buttons[1]:SetFrameStrata("LOW")
		for k = 0,14 do
			self.bar.buttons[1]:SetState(k, "custom", exitButton)
		end
	end
	if build >= 19678 then -- 6.1
		-- the taxi exit button needs to be a separate object
		-- the vehicle exit button can be toggled in combat, while using a flightpath only occurs out of combat
		-- thus we need to toggle the taxi exit button manually / not securely, while the vehicle exit is done by a secure driver
		if not self.taxibar then
			self.taxibarhider = CreateFrame("Frame", "GUI4TaxiExitBarHider", UIParent, "SecureHandlerStateTemplate")
			self.taxibarhider:SetAllPoints()
			self.taxibar = setmetatable(ButtonBar:New("TaxiExitBar", TAXI_CANCEL, function() return self.db.profile end), { __index = TaxiExitBar })
			self.taxibar.SavePosition = function() end -- a little hack to avoid this bar causing LibWin to bug out
			self.taxibar.LoadPosition = function() end -- (we've slaved this bar to the exit vehicle button, but the LibWin functionality is built into its scaffold)
			self.taxibar:SetParent(self.taxibarhider)
			self.taxibar:ClearAllPoints()
			self.taxibar:SetPoint("CENTER", self.bar, "CENTER", 0, 0)
			self.taxibar.taxibarhider = self.taxibarhider
			-- self.taxibar:SetAllPoints(self.bar)
			self.fadeManager:RegisterObject(self.taxibar)
			-- self.taxibar.overlay = gUI4:GlockThis(self.taxibar, L["Exit Vehicle"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "actionbars")))
			-- self.taxibar.UpdatePosition = function(self) module:UpdatePosition() end
			-- tinsert(parent.bars, self.taxibar) -- 
			self.taxibar.buttons = {}
			self.taxibar.buttons[1] = GAB10:CreateButton("action", 1, "GUI4TaxiExitButton1", self.taxibar, nil)
			self.taxibar.buttons[1]:SetFrameStrata("LOW")
			for k = 0,14 do
				self.taxibar.buttons[1]:SetState(k, "custom", taxiExitButton)
			end
			self.taxibar.buttons[1]:HookScript("OnEnter", function(self)
				if UnitOnTaxi("player") then
					if (not GameTooltip:IsForbidden()) then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(TAXI_CANCEL, 1, 1, 1)
						GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
						GameTooltip:Show()
					end
				end
			end)
			self.taxibar.buttons[1]:HookScript("OnLeave", function(self)
				if (not GameTooltip:IsForbidden()) then
					GameTooltip:Hide()
				end
			end)
		end
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "UpdateTaxiButtonVisibility")
		self:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR", "UpdateTaxiButtonVisibility")
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", "UpdateTaxiButtonVisibility")
		self:RegisterEvent("UNIT_EXITED_VEHICLE", "UpdateTaxiButtonVisibility")
		self:RegisterEvent("VEHICLE_UPDATE", "UpdateTaxiButtonVisibility")
		self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	end
	self:UpdateTheme()
end

function module:OnDisable()
end
