local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("StanceBar", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local GAB10 = GP_LibStub("LibButtonGUI4-1.0")

local ButtonBar = parent.ButtonBar
local StanceBar = setmetatable({}, { __index = ButtonBar })
parent.StanceBar = StanceBar

local T, hasTheme

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		barWidth = NUM_STANCE_SLOTS,
		buttons = NUM_STANCE_SLOTS,
		skin = "Warcraft",
		skinSize = "small",
		growthX = "RIGHT",
		growthY = "DOWN",
		showMacrotext = false,
		showHotkey = true,
		showEquipped = true,
		showGrid = false,
		flyoutDir = "UP",
		alpha = 1,
		visibility = {},
		position = {}
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

local function setMinimumSize(self)
	updateConfig()
	local width, height = self:GetSize()
	if width and height then
		if module.db.profile then
			local size = T[module.db.profile.skinSize].size
			if width < size or height < size then
				self:SetSize(size, size)
			end
		end
	end
end

function StanceBar:UpdateStanceButtons()
	local buttons = self.buttons or {}
	local numForms = GetNumShapeshiftForms()
	local buttonsAdded = (numForms > #buttons)
	local buttonsChanged = numForms ~= #buttons

	for i = (#buttons+1), numForms do
		-- buttons[i] = StanceButton:New(i, self)
		buttons[i] = GAB10:CreateButton("stance", i, nil, self, nil)
		buttons[i]:SetState(0, "stance", i)
	end
	for i = 1, numForms do
		buttons[i]:SetParent(self)
		buttons[i]:Show()
		buttons[i]:SetAttribute("statehidden", nil)
		buttons[i]:UpdateAction()
	end
	for i = numForms+1, #buttons do
		buttons[i]:Hide()
		buttons[i]:SetParent(UIParent)
		buttons[i]:SetAttribute("statehidden", true)
	end
	self.buttons = buttons
	self:UpdateLayout()
	setMinimumSize(self)
	if buttonsAdded then
		module:GrabBinds()
	end
	if buttonsChanged then
		if numForms == 0 then
			gUI4:SetTopOffset(self, 0, "LEFT")
			self.disabled = true
		else
			gUI4:SetTopOffset(self, self:GetHeight() + 10, "LEFT")
			self.disabled = false
		end
	end
end
StanceBar.UpdateStanceButtons = gUI4:SafeCallWrapper(StanceBar.UpdateStanceButtons)

function StanceBar:ApplySettings(settings)
	ButtonBar.ApplySettings(self, settings)
	-- self:UpdateButtons()
	self:UpdateButtonSettings()
end

function StanceBar:UpdateButtonSettings()
	if not self.buttonSettings then 
		self.buttonSettings = defaultButtonSettings
	end
	
	self.buttonSettings.clickOnDown = GetCVarBool("ActionButtonUseKeyDown") -- parent.db.profile.clickOnDown
	-- self.buttonSettings.hideElements.macro = false
	-- self.buttonSettings.hideElements.hotkey = false
	-- self.buttonSettings.hideElements.equipped = false
	self.buttonSettings.hideElements.macro = not module.db.profile.showMacrotext 
	self.buttonSettings.hideElements.hotkey = not module.db.profile.showHotkey 
	self.buttonSettings.hideElements.equipped = not module.db.profile.showEquipped 
	self.buttonSettings.showGrid = module.db.profile.showGrid
	self.buttonSettings.flyoutDirection = module.db.profile.flyoutDir
	for i, button in self:GetAll() do
		self.buttonSettings.keyBoundTarget = parent:GetBindingTable()[self.id][i]
		button:UpdateConfig(self.buttonSettings)
	end
	
	-- self:ForAll("UpdateConfig", self.buttonSettings)
	-- self:ForAll("SetAttribute", "buttonlock", GetCVarBool("lockActionBars")) -- parent.db.profile.buttonLock
	self:ForAll("UpdateState")
end

function StanceBar:OnEvent(event, arg1)
	if event == "PLAYER_REGEN_ENABLED" then
		if self.updateStateOnCombatLeave and not InCombatLockdown() then
			self.updateStateOnCombatLeave = nil
			self:UpdateStanceButtons()
		end
	else
		if InCombatLockdown() then
			self.updateStateOnCombatLeave = true
			self:ForAll("Update")
		else
			self:UpdateStanceButtons()
		end
	end
end

function module:Lock()
	self.bar.overlay:StartFadeOut()
end

function module:Unlock()
	if InCombatLockdown() or self.bar.disabled then return end
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
	if not(self.bar) or InCombatLockdown() or not self:IsEnabled() then return end
	updateConfig() 
	self.bar:ApplySettings(self.db.profile)
	self.bar:UpdateLayout()
	setMinimumSize(self.bar)
	-- self.bar:UpdateButtonSettings()
	self.bar:ForAll("Update")
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.bar or InCombatLockdown() then return end
	updateConfig()
	if self.db.profile.locked then
		self.bar:ClearAllPoints()
		self.bar:SetPoint(T.place("Stance", self.db.profile.skinSize))
		if not self.db.profile.position.x then
			self.bar:RegisterConfig(self.db.profile.position)
			self.bar:SavePosition()
		end
	else
		self.bar:RegisterConfig(self.db.profile.position)
		if self.db.profile.position.x then
			self.bar:LoadPosition()
		else
			self.bar:ClearAllPoints()
			self.bar:SetPoint(T.place("Stance", self.db.profile.skinSize))
			self.bar:SavePosition()
			self.bar:LoadPosition()
		end
	end	
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("StanceBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self.fadeManager = parent:GetFadeManager()
	
	self.bar = setmetatable(ButtonBar:New("Stance", L["Stance Bar"], function() return self.db.profile end), { __index = StanceBar })
	self.fadeManager:RegisterObject(self.bar)
	self.bar.buttons = {}
	self.bar.overlay = gUI4:GlockThis(self.bar, L["Stance Bar"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "actionbars")))
	self.bar.UpdatePosition = function(self) module:UpdatePosition() end
	self.bar.GetSettings = function() return self.db.profile end
	tinsert(parent.bars, self.bar)
	self.bar:SetScript("OnEvent", StanceBar.OnEvent)
	self.bar:UpdateStanceButtons()
	self.bar:Enable()
	self.bar:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.bar:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	self.bar:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	self.bar:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
	self.bar:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	self.bar:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self.bar:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self.bar:RegisterEvent("UPDATE_SHAPESHIFT_USABLE")
	self.bar:RegisterEvent("UPDATE_POSSESS_BAR")
	-- self.bar:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN") -- let the lib handle this one
	self.bar:RegisterEvent("PLAYER_REGEN_ENABLED")
	
	-- self:RegisterMessage("GUI4_BOTTOM_OFFSET_CHANGED", "UpdatePosition")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("CVAR_UPDATE")
	self:RegisterEvent("UPDATE_BINDINGS", "GrabBinds")
	self:GrabBinds()
	
	self:ApplySettings()
end

function module:CVAR_UPDATE(event, arg1, arg2)
	if arg1 == "ACTION_BUTTON_USE_KEY_DOWN" or arg1 == "LOCK_ACTIONBAR_TEXT" then
		self.bar:UpdateButtonSettings()
	end
end
module.CVAR_UPDATE = gUI4:SafeCallWrapper(module.CVAR_UPDATE) -- needed for bar update?

function module:GrabBinds()
	if InCombatLockdown() or not self.actionbars then return end
	ClearOverrideBindings(self.bar)
	for i,button in self.bar:GetAll() do
		local action = self.bar.bindingTable[self.bar.id][i]
		for k = 1, select("#", GetBindingKey(action)) do
		local key = select(k, GetBindingKey(action))
			if key and key ~= "" then
				SetOverrideBindingClick(self.bar, false, key, button:GetName())
			end				
		end
	end
end

function module:OnEnable()
	-- self:UpdateTheme() 
end

function module:OnDisable()
end
