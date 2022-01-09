local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("PetBar", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local GAB10 = GP_LibStub("LibButtonGUI4-1.0")
local T, hasTheme

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat

local ButtonBar = parent.ButtonBar
local PetBar = setmetatable({}, { __index = ButtonBar })
parent.PetBar = PetBar

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		barWidth = NUM_PET_ACTION_SLOTS,
		buttons = NUM_PET_ACTION_SLOTS,
		skin = "Warcraft", 
		skinSize = "small",
		-- buttonSize = 36, padding = 2, -- the theme will take care of these 2 
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
			nopet = true -- hide it when no pet is active
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
function PetBar:ApplySettings()
	ButtonBar.ApplySettings(self)
	-- self:UpdateButtons()
	self:UpdateButtonSettings()
end

function PetBar:UpdateButtonSettings()
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
	for i, button in self:GetAll() do
		self.buttonSettings.keyBoundTarget = parent:GetBindingTable()[self.id][i]
		button:UpdateConfig(self.buttonSettings)
	end
	
	-- self:ForAll("UpdateConfig", self.buttonSettings)
	self:ForAll("SetAttribute", "buttonlock", GetCVarBool("lockActionBars")) -- parent.db.profile.buttonLock
	self:ForAll("UpdateState")
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
	self.bar:ApplySettings()
	self.bar:UpdateLayout()
	-- self.bar:UpdateButtonSettings()
	self.bar:ForAll("Update")
	self:UpdatePosition() 
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.bar then return end
	updateConfig() 
	if self.db.profile.locked then
		self.bar:ClearAllPoints()
		self.bar:SetPoint(T.place("Pet", self.db.profile.skinSize))
		if not self.db.profile.position.x then
			self.bar:RegisterConfig(self.db.profile.position)
			self.bar:SavePosition()
		end
		if self.db.profile.enabled then 
			gUI4:SetBottomOffset(self.bar, T[self.db.profile.skinSize].size + T[self.db.profile.skinSize].petBarOffset) -- changing the bottom offset will fire off :UpdatePosition()
		else
			gUI4:SetBottomOffset(self.bar, nil)
		end
	else
		self.bar:RegisterConfig(self.db.profile.position)
		gUI4:SetBottomOffset(self.bar, nil)
		if self.db.profile.position.x then
			self.bar:LoadPosition()
		else
			self.bar:ClearAllPoints()
			self.bar:SetPoint(T.place("Pet", self.db.profile.skinSize))
			self.bar:SavePosition()
			self.bar:LoadPosition()
		end
	end
	-- self.db.profile.position.y = gUI4:GetBottomOffset() - T[self.db.profile.skinSize].size
	-- self.bar:SavePosition()
	-- self.bar:LoadPosition()
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("PetBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if self.db.profile.visibility.vehicleuipet then
		self.db.profile.visibility.vehicleuipet = nil
	end
	self.fadeManager = parent:GetFadeManager() 
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
				-- print(key)
				SetOverrideBindingClick(self.bar, false, key, button:GetName())
			end				
		end
	end
end

function module:OnEnable()
	if not self.bar then
		self.bar = setmetatable(ButtonBar:New("Pet", L["Pet Bar"], function() return self.db.profile end), { __index = PetBar })
		self.bar.overlay = gUI4:GlockThis(self.bar, L["Pet Bar"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "actionbars")))
		self.bar.UpdatePosition = function(self) module:UpdatePosition() end
		self.fadeManager:RegisterObject(self.bar)
		tinsert(parent.bars, self.bar)
		self.bar.buttons = {}
		for id = 1, NUM_PET_ACTION_SLOTS do
			self.bar.buttons[id] = GAB10:CreateButton("pet", id, nil, self.bar, nil)
			self.bar.buttons[id]:SetState(0, "pet", id)
		end
	end
	self:RegisterMessage("GUI4_BOTTOM_OFFSET_CHANGED", "UpdatePosition")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("CVAR_UPDATE")
	self:RegisterEvent("UPDATE_BINDINGS", "GrabBinds")
	self:GrabBinds()
	self:UpdateTheme()
end
