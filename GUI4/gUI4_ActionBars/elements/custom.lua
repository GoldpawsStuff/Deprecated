local addon = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("Custom", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local GAB10 = GP_LibStub("LibButtonGUI4-1.0")

-- Lua API
local setmetatable = setmetatable
local tostring = tostring
local unpack = unpack
local tconcat, tinsert, wipe = table.concat, table.insert, table.wipe

-- WoW API
local GetItemInfo = _G.GetItemInfo
local GetProfessionInfo = _G.GetProfessionInfo
local GetProfessions = _G.GetProfessions
local GetSpellInfo = _G.GetSpellInfo
local RegisterStateDriver = _G.RegisterStateDriver
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnregisterStateDriver = _G.UnregisterStateDriver

local ButtonBar = parent.ButtonBar
local Custom = setmetatable({}, { __index = ButtonBar })
parent.Custom = Custom

local T, hasTheme

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
			possess = true,
			overridebar = true,
			vehicleui = true
		}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme()
end

local fishingButton = {
	func = function() end,
	texture = "Interface\\Icons\\INV_Fishingpole_02",
	tooltip = _G.PROFESSIONS_FISHING,
}

-- turns out spell- and itemnames are localized in macros. Thank you René Künzel for making me aware! :)
-- sometimes the item info isn't fully available at startup for some users, so we attempt to update these later on instead
local fishing_condition, fishing_spellname
local function updateFishingVariables()
	if not fishing_condition then
		fishing_condition = select(7, GetItemInfo(6256)) 
	end
	if not fishing_spellname then
		fishing_spellname = GetSpellInfo(131474) 
	end
	if fishing_condition and fishing_spellname then
		return true
	end
end

 -- force an early query to cache the items in the client so they're available on the second request later on
updateFishingVariables()

------------------------------------------------------------------------
-- 	Action Bar Template
------------------------------------------------------------------------
function Custom:ApplySettings()
	ButtonBar.ApplySettings(self)
	-- self:UpdateButtons()
	self:UpdateButtonSettings()
end

function Custom:UpdateButtonSettings()
end

function Custom:ApplyVisibilityDriver()
	updateFishingVariables()
	if not (fishing_condition and fishing_spellname) then
		return
	end
	local settings = self:GetSettings()
	self.driver = {}
	tinsert(self.driver, ("[nocombat,novehicleui,equipped:%s]show"):format(fishing_condition))
	tinsert(self.driver, "hide")
	-- tinsert(self.driver, "show")
	if settings.enabled then
		UnregisterStateDriver(self, "visibility")
		RegisterStateDriver(self, "visibility", tconcat(self.driver, ";"))
	else
		UnregisterStateDriver(self, "visibility")
		RegisterStateDriver(self, "visibility", "hide")
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

function module:UpdateTheme(_, _, addonName)
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
		self.bar:SetPoint(T.place("Custom", self.db.profile.skinSize))
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
			self.bar:SetPoint(T.place("Custom", self.db.profile.skinSize))
			self.bar:SavePosition()
			self.bar:LoadPosition()
		end
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Custom", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	self.fadeManager = parent:GetFadeManager() 
end

function module:GetFishingSkillInfo()
	local _, _, _, fishing, _, _ = GetProfessions()
	if fishing then
		local name, _, _, _, _, _, _ = GetProfessionInfo(fishing)
		return true, name
	end
	return false, _G.PROFESSIONS_FISHING
end

function module:GetCurrentFishingSkill()
	local _, _, _, fishing, _, _ = GetProfessions()
	if fishing then
		local _, _, rank, skillmax, _, _, _, mods = GetProfessionInfo(fishing)
		return rank, mods, skillmax
	end
	return 0, 0, 0
end

function module:UpdateFishingButton(event, ...)
	if not updateFishingVariables() then 
		if event == "PLAYER_ENTERING_WORLD" then
			self:RegisterEvent("UNIT_AURA", "UpdateFishingButton")
		end
		return 
	end
	self.bar.buttons[1]:SetAttribute("type", "macro")
	self.bar.buttons[1]:SetAttribute("macrotext", ("/cast [equipped:%s]%s"):format(fishing_condition, fishing_spellname))
	-- self.bar.buttons[1]:SetAttribute("macrotext", ("/cast [equipped:%s,nochanneling:%s]%s"):format(fishing_condition, fishing_spellname, fishing_spellname))
	self.bar.buttons[1]:DisableDragNDrop(true)
	if (event == "PLAYER_ENTERING_WORLD") or (event == "UNIT_AURA") then
		self:UnregisterEvent(event)
		self.bar:ApplyVisibilityDriver()
	end
end
module.UpdateFishingButton = gUI4:SafeCallWrapper(module.UpdateFishingButton)

function module:OnEnable()
	if not self.bar then
		self.bar = setmetatable(ButtonBar:New("Custom", L["Fishing"], function() return self.db.profile end), { __index = Custom })
		-- self.fadeManager:RegisterObject(self.bar)
		self.bar.overlay = gUI4:GlockThis(self.bar, L["Fishing"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "actionbars")))
		self.bar.UpdatePosition = function(self) module:UpdatePosition() end
		tinsert(parent.bars, self.bar)
		self.bar.buttons = {}
		self.bar.buttons[1] = GAB10:CreateButton("action", 1, "GUI4CustomButton1", self.bar, nil)
		self.bar.buttons[1]:SetFrameStrata("LOW")
		self.bar.buttons[1]:DisableDragNDrop(true)
		self.bar:Hide()
		for k = 0,14 do
			self.bar.buttons[1]:SetState(k, "custom", fishingButton)
		end
		if updateFishingVariables() then
			self:UpdateFishingButton()
		else
			self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateFishingButton")
		end
	end
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:UpdateTheme()
end

function module:OnDisable()
end
