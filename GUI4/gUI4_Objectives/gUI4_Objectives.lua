local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat

local defaults = {
	profile = {
	}
}

-- style the level up displays?
-- LevelUpDisplay
-- LevelUpDisplay.blackBg
-- LevelUpDisplay.gLine
-- LevelUpDisplay.gLine2
-- LevelUpDisplay.spellFrame
-- LevelUpDisplay.spellFrame.icon
-- LevelUpDisplaySide

function module:Lock()
	for name, mod in self:IterateModules() do
		if mod:IsEnabled() then
			mod:Lock()
		end
	end
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	for name, mod in self:IterateModules() do
		if mod:IsEnabled() then
			mod:Unlock()
		end
	end
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	for name, mod in self:IterateModules() do
		if mod:IsEnabled() and mod.ResetLock then
			mod:ResetLock()
		end
	end
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_Objectives_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end
end

function module:OnEnable()
	for name, mod in self:IterateModules() do
		mod:Enable()
	end
	self:SetActiveTheme(self.db.profile.skin) -- fires off :UpdateTheme()
end

function module:OnDisable()
end
