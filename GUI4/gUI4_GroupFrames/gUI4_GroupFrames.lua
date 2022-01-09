local addon, ns = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T 

-- Lua API
local _G = _G

-- WoW API
local CreateFrame = _G.CreateFrame
local GetNumRaidMembers = _G.GetNumRaidMembers
local hooksecurefunc = _G.hooksecurefunc
local PartyMemberFrame_UpdateMember = _G.PartyMemberFrame_UpdateMember
local UnitAffectingCombat = _G.UnitAffectingCombat
local UIParent = _G.UIParent

local hooked, hidden = {}, {}

local defaults = {
	profile = {
		showGroupAuras = true,
		skin = "Warcraft"
	}
}

local function updateConfig()
	T = module:GetActiveTheme()
end

-- we're using custom handling of frames, and need to bypass oUF's disabling
oUF.DisableBlizzard = function() end

local hider = CreateFrame("Frame")
hider:Hide()

function module:GetVisibilityMacro(from, to)
	if not to then 
		to = from
		from = 2
	end
	local macro = "custom "
	if to < 40 then
		macro = macro .. "[@raid"..(to + 1)..",exists] hide; "
	end
	if from > 2 then
		macro = macro .. "[@raid"..from..",exists] show; "
	else
		macro = macro .. "[@raid2,exists][@party1,exists] show; "
	end
	macro = macro .. "hide"
	return macro
end

function module:DisableBlizzard()
	-- dropdowns cause taint through the blizz compact unit frames, so we disable them
	-- http://www.wowinterface.com/forums/showpost.php?p=261589&postcount=5
	if _G.CompactUnitFrameProfiles then
		_G.CompactUnitFrameProfiles:UnregisterAllEvents()
	end
	if _G.CompactRaidFrameManager and (_G.CompactRaidFrameManager:GetParent() ~= hider) then
		_G.CompactRaidFrameManager:SetParent(hider)
	end
	for i = 1, 4 do
		gUI4:DisableUnitFrame("party"..i)
	end
	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

function module:Place(...)
	LMP:Place(...)
end
module.Place = gUI4:SafeCallWrapper(module.Place)

function module:Lock()
	for _, mod in self:IterateModules() do
		mod:Lock()
	end
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	for _, mod in self:IterateModules() do
		mod:Unlock()
	end
end


function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	for _, mod in self:IterateModules() do
		mod:ResetLock()
	end
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Auras", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["GroupFrames"],
			args = {
				showGroupAuras = {
					type = "toggle",
					width = "full",
					order = 10,
					name = L["Display important auras on the Group Frames."],
					desc = L["Shows important auras such as boss debuffs, dispellable debuffs for dispellers  and Disc Priest Atonement on the Group Frames."],
					get = function() 
						return self.db.profile.showGroupAuras
					end,
					set = function(_, value)
						self.db.profile.showGroupAuras = value
						self:ApplySettings()
					end
				},

				group5header = {
					type = "header",
					name = L["5 Player Groups"],
					order = 101,
				},
				group5visibilityheader = {
					type = "description",
					name = L["\n|cffffd200" .. "5 Player Group Aura Visibility" .. "|r"],
					order = 102,
				},
				group5visibilitydescription = {
					type = "description",
					name = L["Select whether or not to show the 5 player group aura widgets. Deselecting a widget will override all other settings."],
					order = 103,
				},
				showAuras = {
					order = 105,
					type = "toggle",
					width = "full",
					name = L["Display buffs and debuffs on the 5 Player Group Frames."],
					desc = L["Shows the normal buffs and debuffs on the 5 Player Group Frames."],
					get = function()
						local group5 = self:GetModule("Group5")
						if group5 then
							return group5.db.profile.auras.showAuras
						end
					end,
					set = function(info, value) 
						local group5 = self:GetModule("Group5")
						if group5 then
							group5.db.profile.auras.showAuras = value
							group5:ApplySettings()
						end
					end,
					width = "full"
				}
			}
		}
	})
	
	gUI4:RegisterModuleOptions("Groups", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["General"],
			args = {
				showGroupAuras = {
					type = "toggle",
					width = "full",
					order = 10,
					name = L["Display important auras on the Group Frames."],
					desc = L["Shows important auras such as boss debuffs, dispellable debuffs for dispellers  and Disc Priest Atonement on the Group Frames."],
					get = function() 
						return self.db.profile.showGroupAuras
					end,
					set = function(_, value)
						self.db.profile.showGroupAuras = value
						self:ApplySettings()
					end
				}
			}
		}
	})
	
	gUI4:RegisterModuleOptions("FAQ", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["GroupFrames"],
			args = gUI4:GenerateFAQOptionsTable(
			L["\n|cffffd200" .. "How can I toggle the display of debuffs on the Group Frames?" .. "|r"],
			L["To toggle this option, open the /gui options menu, go to the Auras submenu, and then choose the Group Frames tab."]
			)
		}
	})
	
end

-- fire off theme updates for all submodules
function module:UpdateTheme(_, _, addonName)
	if addonName ~= tostring(self) then return end
	for _, mod in self:IterateModules() do
		mod:UpdateTheme()
	end
	self:ApplySettings()
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings()
	for _, mod in self:IterateModules() do
		mod:ApplySettings()
	end
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

-- update position of all frames
function module:UpdatePosition()
	for _, mod in self:IterateModules() do
		mod:UpdatePosition()
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_GroupFrames_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end
	updateConfig()
	
	self:DisableBlizzard()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "DisableBlizzard")
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
end

function module:OnEnable()
	for _, mod in self:IterateModules() do
		mod:Enable()
	end
	self:SetActiveTheme(self.db.profile.skin) 
end
