local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("ActionBars", "GP_AceEvent-3.0", "GP_AceConsole-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local GAB10 = GP_LibStub("LibButtonGUI4-1.0")
local T, hasTheme

local StateBar = parent.StateBar
local ActionBar = setmetatable({}, { __index = StateBar })
local ActionBar_MT = { __index = ActionBar }

-- Lua API
local select, ipairs, pairs = select, ipairs, pairs
local tonumber, tostring = tonumber, tostring

-- WoW  API
local GetAccountExpansionLevel = GetAccountExpansionLevel
local GetCVarBool = GetCVarBool
local UnitAffectingCombat = UnitAffectingCombat
local UnitClass = UnitClass
local UnitLevel = UnitLevel
local VehicleExit = VehicleExit

local playerLevel = UnitLevel("player")
local _, playerClass = UnitClass("player")
local accountLevel = GetAccountExpansionLevel()
local MAX_PLAYER_LEVEL = accountLevel and MAX_PLAYER_LEVEL_TABLE[accountLevel] or 999

local defaults = {
	profile = {
		bars = {
			["**"] = {
				enabled = true,
				locked = true,
				barWidth = NUM_ACTIONBAR_BUTTONS,
				buttons = NUM_ACTIONBAR_BUTTONS,
				skin = "Warcraft",
				skinSize = "medium",
				growthX = "RIGHT",
				growthY = "DOWN",
				showMacrotext = false,
				showHotkey = true,
				showEquipped = false,
				showGrid = false,
				flyoutDir = "UP",
				position = {},
				alpha = 1,
				visibility = {}
			},
			[1] = {
				showGrid = true,
				paging = {
					
				}
			},
			[BOTTOMLEFT_ACTIONBAR_PAGE] = { -- 6
				enabled = false, -- gUI4.DEBUG
				showGrid = true,
				visibility = {
					possess = true,
					overridebar = true,
					vehicleui = true
				}
			},
			[BOTTOMRIGHT_ACTIONBAR_PAGE] = { -- 5
				enabled = false,
				showGrid = true,
				visibility = {
					possess = true,
					overridebar = true,
					vehicleui = true
				}
			},
			[RIGHT_ACTIONBAR_PAGE] = { -- 3
				enabled = false,
				barWidth = 1,
				tooltipAnchor = true,
				flyoutDir = "LEFT",
				visibility = {
					possess = true,
					overridebar = true,
					vehicleui = true
				}
			},
			[LEFT_ACTIONBAR_PAGE] = { -- 4
				enabled = false,
				barWidth = 1,
				tooltipAnchor = true,
				flyoutDir = "LEFT",
				visibility = {
					possess = true,
					overridebar = true,
					vehicleui = true
				}
			}
		}
	}
}

local defaultButtonSettings = { 
	outOfRangeColoring = "button",
	tooltip = "enabled",
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
function ActionBar:ApplySettings()
	StateBar.ApplySettings(self)
	self:UpdateButtons()
	self:UpdateButtonSettings()
end

local exitButton = {
	func = function(button)
		VehicleExit()
	end,
	texture = "Interface\\Icons\\Spell_Shadow_SacrificialShield",
	tooltip = LEAVE_VEHICLE,
}

function ActionBar:UpdateButtons()
	local settings = self:GetSettings()
	local buttons = self.buttons or {}
	local numbuttons = settings.buttons
	
	-- add buttons if needed
	for i = (#buttons+1), numbuttons do
		local absid = (self.id - 1) * 12 + i
		buttons[i] = GAB10:CreateButton("action", absid, "GUI4Button"..absid, self, nil)
		buttons[i]:SetFrameStrata("LOW")
		local id = absid%12
		if id == 0 then
			id = 12
		end
		for k = 1,14 do
			buttons[i]:SetState(k, "action", (k - 1) * 12 + id)
		end
		buttons[i]:SetState(0, "action", absid)
	end

	-- show current buttons
	for i = 1, numbuttons do
		buttons[i]:SetParent(self)
		buttons[i]:Show()
		buttons[i]:SetAttribute("statehidden", nil)
		buttons[i]:UpdateAction()
		if i == 12 then
			buttons[i]:SetState(11, "custom", exitButton)
			buttons[i]:SetState(12, "custom", exitButton)
		end
	end
	
	
	-- hide extra buttons
	for i = (numbuttons + 1), #buttons do
		buttons[i]:Hide()
		buttons[i]:SetParent(UIParent)
		buttons[i]:SetAttribute("statehidden", true)
	end
	
	self.numbuttons = numbuttons
	self.buttons = buttons
	
	self:UpdateLayout()
	self:UpdateStateDriver()
end

function ActionBar:UpdateButtonSettings()
	if not self.buttonSettings then 
		self.buttonSettings = defaultButtonSettings
	end
	local settings = self:GetSettings()
	
	self.buttonSettings.clickOnDown = GetCVarBool("ActionButtonUseKeyDown") -- parent.db.profile.clickOnDown
	-- self.buttonSettings.hideElements.macro = false
	-- self.buttonSettings.hideElements.hotkey = false
	-- self.buttonSettings.hideElements.equipped = false
	self.buttonSettings.hideElements.macro = not settings.showMacrotext 
	self.buttonSettings.hideElements.hotkey = not settings.showHotkey 
	self.buttonSettings.hideElements.equipped = not settings.showEquipped 
	self.buttonSettings.showGrid = settings.showGrid
	self.buttonSettings.flyoutDirection = settings.flyoutDir
	self.buttonSettings.tooltipAnchor = settings.tooltipAnchor
	for i, button in self:GetAll() do
		self.buttonSettings.keyBoundTarget = parent:GetBindingTable()[self.id][i]
		button:UpdateConfig(self.buttonSettings)
	end
	
	-- self:ForAll("UpdateConfig", self.buttonSettings)
	self:ForAll("SetAttribute", "buttonlock", GetCVarBool("lockActionBars")) -- parent.db.profile.buttonLock
	self:ForAll("UpdateState")
end


------------------------------------------------------------------------
-- 	Main 
------------------------------------------------------------------------
local positionCallbacks = {}
function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	updateConfig()
	for callback in pairs(positionCallbacks) do
		self:UnregisterMessage(callback, "UpdatePosition")
	end
	wipe(positionCallbacks)
	for id, callbacks in pairs(T.positionCallbacks) do
		for _, callback in ipairs(callbacks) do
			positionCallbacks[callback] = true
		end
	end
	for callback in pairs(positionCallbacks) do
		self:RegisterMessage(callback, "UpdatePosition")
	end
	-- if self.actionbars then
		-- for id, bar in pairs(self.actionbars) do 
			-- if bar then
				-- bar:UpdateSkin(); print("updating", bar:GetName())
			-- end
		-- end
	-- end
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	updateConfig()
	if self.actionbars then
		for id, bar in pairs(self.actionbars) do 
			if bar then
				local db = self.db.profile.bars[id]
				bar:ApplySettings(db)
				if db.enabled then 
					bar:Enable()
					if db.locked then
						if T.setOffset then
							T.setOffset(bar, id, db.skinSize) 
						end
					end
				else
					bar:Disable()
					if T.setOffset then
						T.setOffset(bar, id, nil) 
					end
				end
			end
		end
		-- send messages to other modules about visible bars
		local bottomleft, bottomright = GUI4Bar6, GUI4Bar5
		local right, left = GUI4Bar3, GUI4Bar4
		if bottomright and self.db.profile.bars[BOTTOMRIGHT_ACTIONBAR_PAGE].enabled then
			self:SendMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", 3)
		elseif bottomleft and self.db.profile.bars[BOTTOMLEFT_ACTIONBAR_PAGE].enabled then
			self:SendMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", 2)
		else
			self:SendMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", 1)
		end
		if left and self.db.profile.bars[LEFT_ACTIONBAR_PAGE].enabled then 
			self:SendMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", 2)
		elseif right and self.db.profile.bars[RIGHT_ACTIONBAR_PAGE].enabled then
			self:SendMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", 1)
		else
			self:SendMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", 0)
		end
	end
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.actionbars then return end
	updateConfig()
	for id, bar in pairs(self.actionbars) do 
		if bar then
			local db = self.db.profile.bars[id]
			if db.locked and db.enabled then
				if T.setOffset then
					T.setOffset(bar, id, db.skinSize) 
				end
				bar:ClearAllPoints()
				bar:SetPoint(T.place(id, db.skinSize))
			else
				if T.setOffset then
					T.setOffset(bar, id, nil) 
				end
			end
		end
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:SetSmallButtons(small)
	updateConfig()
	if self.actionbars then
		for id, bar in pairs(self.actionbars) do 
			if bar then
				local db = self.db.profile.bars[id]
				if small then
					db.skinSize = "small"
				else
					db.skinSize = "medium"
				end
			end
		end
		parent:SetActiveTheme(parent.db.profile.skin)
	end
end
module.SetSmallButtons = gUI4:SafeCallWrapper(module.SetSmallButtons)

function module:New(id, settingsFunc)
	return setmetatable(StateBar:New(tostring(id), (L["Bar %s"]):format(id), settingsFunc), ActionBar_MT)
end

function module:Lock()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
end

function module:ResetLock()
	-- if UnitAffectingCombat("player") then return end
	-- if not self.bar then return end
	-- updateConfig() 
	-- self:ApplySettings()
end

function module:ForAll(method, ...)
	if not self.actionbars then return end
	for id, bar in pairs(self.actionbars) do
		if type(method) == "string" and bar[method] then
			bar[method](bar, ...)
		elseif type(method) == "function" then
			method(bar, ...)
		end
	end
end

-- function module:OnEvent(event, ...)
	-- if event == "ACTIONBAR_SHOWGRID" then
		-- self:ForAll("ShowGrid")
	-- elseif event == "ACTIONBAR_HIDEGRID" then
		-- self:ForAll("HideGrid")
	-- end
-- end

function module:GrabBinds()
	if InCombatLockdown() or not self.actionbars then return end
	for id, bar in pairs(self.actionbars) do
		ClearOverrideBindings(bar)
		for i,button in bar:GetAll() do
			local action = parent:GetBindingTable()[bar.id][i]
			for k = 1, select("#", GetBindingKey(action)) do
			local key = select(k, GetBindingKey(action))
				if key and key ~= "" then
					SetOverrideBindingClick(bar, false, key, button:GetName())
				end				
			end
		end
	end
end

function module:SetBottomBars(n)
	if InCombatLockdown() then 
		UIErrorsFrame:AddMessage(L["You can't change number of visible actionbars while engaged in combat!"], 1, .82, 0)
		return 
	end
	n = tonumber(n)
	-- local bottomleft, bottomright = GUI4Bar6, GUI4Bar5
	if n == 1 then
		-- if bottomright then bottomright:Disable() end
		-- if bottomleft then bottomleft:Disable() end
		self.db.profile.bars[BOTTOMLEFT_ACTIONBAR_PAGE].enabled = false
		self.db.profile.bars[BOTTOMRIGHT_ACTIONBAR_PAGE].enabled = false
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", 1)
	elseif n == 2 then
		-- if bottomright then bottomright:Disable() end
		-- if bottomleft then bottomleft:Enable() end
		self.db.profile.bars[BOTTOMLEFT_ACTIONBAR_PAGE].enabled = true
		self.db.profile.bars[BOTTOMRIGHT_ACTIONBAR_PAGE].enabled = false
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", 2)
	elseif n == 3 then
		-- if bottomright then bottomright:Enable() end
		-- if bottomleft then bottomleft:Enable() end
		self.db.profile.bars[BOTTOMLEFT_ACTIONBAR_PAGE].enabled = true
		self.db.profile.bars[BOTTOMRIGHT_ACTIONBAR_PAGE].enabled = true
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", 3)
	elseif n == 4 then
		self.db.profile.bars[BOTTOMLEFT_ACTIONBAR_PAGE].enabled = true
		self.db.profile.bars[BOTTOMRIGHT_ACTIONBAR_PAGE].enabled = true
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", 3)
		self.db.profile.bars[LEFT_ACTIONBAR_PAGE].enabled = false
		self.db.profile.bars[RIGHT_ACTIONBAR_PAGE].enabled = true
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", 1)
	elseif n == 5 then
		self.db.profile.bars[BOTTOMLEFT_ACTIONBAR_PAGE].enabled = true
		self.db.profile.bars[BOTTOMRIGHT_ACTIONBAR_PAGE].enabled = true
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", 3)
		self.db.profile.bars[LEFT_ACTIONBAR_PAGE].enabled = true
		self.db.profile.bars[RIGHT_ACTIONBAR_PAGE].enabled = true
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", 2)
	else
		print(L["Usage: '/setbars n' - where 'n' is the number of bottom action bars, from 1 to 3."])
	end
	self:ApplySettings()
end

function module:SetSideBars(n)
	if InCombatLockdown() then 
		UIErrorsFrame:AddMessage(L["You can't change number of visible actionbars while engaged in combat!"], 1, .82, 0)
		return 
	end
	n = tonumber(n)
	-- local right, left = GUI4Bar3, GUI4Bar4
	if n == 0 then
		-- if left then left:Disable() end
		-- if right then right:Disable() end
		self.db.profile.bars[LEFT_ACTIONBAR_PAGE].enabled = false
		self.db.profile.bars[RIGHT_ACTIONBAR_PAGE].enabled = false
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", 0)
	elseif n == 1 then
		-- if left then left:Disable() end
		-- if right then right:Enable() end
		self.db.profile.bars[LEFT_ACTIONBAR_PAGE].enabled = false
		self.db.profile.bars[RIGHT_ACTIONBAR_PAGE].enabled = true
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", 1)
	elseif n == 2 then
		-- if left then left:Enable() end
		-- if right then right:Enable() end
		self.db.profile.bars[LEFT_ACTIONBAR_PAGE].enabled = true
		self.db.profile.bars[RIGHT_ACTIONBAR_PAGE].enabled = true
		-- self:SendMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", 2)
	else
		print(L["Usage: '/setsidebars n' - where 'n' is the number of side action bars, from 0 to 2."])
	end
	self:ApplySettings()
end

function module:GetSideBars()
	local n = 0
	if self.db.profile.bars[RIGHT_ACTIONBAR_PAGE].enabled then
		n = n + 1
		if self.db.profile.bars[LEFT_ACTIONBAR_PAGE].enabled then
			n = n + 1
		end
	end
	return n
end

function module:GetBottomBars()
	local n = 1
	if self.db.profile.bars[BOTTOMLEFT_ACTIONBAR_PAGE].enabled then
		n = n + 1
		if self.db.profile.bars[BOTTOMRIGHT_ACTIONBAR_PAGE].enabled then
			n = n + 1
		end
	end
	return n
end

function module:SetSmallBars()
	if InCombatLockdown() then 
		UIErrorsFrame:AddMessage(L["You can't configure actionbars while engaged in combat!"], 1, .82, 0)
		return 
	end
	self:SetSmallButtons(true)
end

function module:SetBigBars()
	if InCombatLockdown() then 
		UIErrorsFrame:AddMessage(L["You can't configure actionbars while engaged in combat!"], 1, .82, 0)
		return 
	end
	self:SetSmallButtons(false)
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("ActionBars", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()

	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterMessage("GUI4_XPBAR_ENABLED", "UpdatePosition")
	self:RegisterMessage("GUI4_XPBAR_DISABLED", "UpdatePosition")
	self:RegisterMessage("GUI4_REPUTATIONBAR_ENABLED", "UpdatePosition")
	self:RegisterMessage("GUI4_REPUTATIONBAR_DISABLED", "UpdatePosition")

	self:RegisterChatCommand("smallbars", "SetSmallBars")
	self:RegisterChatCommand("bigbars", "SetBigBars")
	self:RegisterChatCommand("setbars", "SetBottomBars")
	self:RegisterChatCommand("setsidebars", "SetSideBars")
end

local visibilityCallbacks = {
	[1] = "GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED",
	[BOTTOMLEFT_ACTIONBAR_PAGE] = "GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED",
	[BOTTOMRIGHT_ACTIONBAR_PAGE] = "GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED",
	[LEFT_ACTIONBAR_PAGE] = "GUI4_NUM_ACTIONBARS_SIDE_CHANGED",
	[RIGHT_ACTIONBAR_PAGE] = "GUI4_NUM_ACTIONBARS_SIDE_CHANGED"
}
local function onVisibility(self)
	local callback = visibilityCallbacks[tonumber(self.id)]
	if callback then
		module:SendMessage(callback)
	end
end

function module:CVAR_UPDATE(event, arg1, arg2)
	if arg1 == "ACTION_BUTTON_USE_KEY_DOWN" or arg1 == "LOCK_ACTIONBAR_TEXT" then
		self:UpdateButtonSettings()
	end
end
module.CVAR_UPDATE = gUI4:SafeCallWrapper(module.CVAR_UPDATE) -- needed for bar update?

function module:UpdateButtonSettings()
	if self.actionbars then
		for id, bar in pairs(self.actionbars) do 
			if bar then
				bar:UpdateButtonSettings()
			end
		end
	end
end
module.UpdateButtonSettings = gUI4:SafeCallWrapper(module.UpdateButtonSettings)

function module:OnEnable()
	updateConfig()
	self.actionbars = {}
	for id, settings in pairs(self.db.profile.bars) do 
		if tonumber(id) then -- just to avoid the 'nil' bug with **
			local id = id
			self.actionbars[id] = self:New(id, function() return self.db.profile.bars[id] end)
			if visibilityCallbacks[id] then
				self.actionbars[id]:HookScript("OnShow", onVisibility)
				self.actionbars[id]:HookScript("OnHide", onVisibility)
			end
			parent:GetFadeManager():RegisterObject(self.actionbars[id])
			tinsert(parent.bars, self.actionbars[id])
			self:SendMessage("GUI4_ACTIONBAR_CREATED", self.actionbars[id])
		end
	end
	self:RegisterEvent("CVAR_UPDATE")
	self:RegisterEvent("UPDATE_BINDINGS", "GrabBinds")
	self:ApplySettings()
	self:GrabBinds()
end

function module:OnDisable()
end
