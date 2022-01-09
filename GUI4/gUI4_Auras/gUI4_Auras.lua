local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 22124 
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- Lua API
local tostring = tostring

-- WoW API
local GetCVarBool = GetCVarBool
local UnitAffectingCombat = UnitAffectingCombat
local BuffFrame = BuffFrame
local ConsolidatedBuffs = ConsolidatedBuffs
local TemporaryEnchantFrame = TemporaryEnchantFrame

local defaults = {
	profile = {
		flash = true,
		cooldown = false,
		timerbar = true,
		timertext = false
	}
}

function module:GetFadeManager()
	if not self.fademanager then
		self.fademanager = LMP:NewChain(gUI4:CreateFadeManager("Auras")) :Enable() .__EndChain
		-- self.fademanager = LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :SetAllPoints() .__EndChain
		self.fademanager:SetSize(8,8)
		self.fademanager:SetFrameStrata("LOW")
		-- self.fademanager:ApplySettings()
	end
	return self.fademanager
end

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

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Auras", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = "Floating",
			args = {
				buffheader = {
					type = "header",
					name = L["Player Buffs"],
					order = 1,
				},
				buffdescription = {
					type = "description",
					name = L["Here you can change the settings for the benefitial player auras located next to the minimap by default."],
					order = 2,
				},
				buffenable = {
					type = "toggle",
					name = L["Enable Player Buffs"],
					desc = L["Toggle the display of benefitial player auras next to the minimap. Disable if you don't wish to track these, or have another way of tracking them that you prefer."],
					order = 3,
					get = function() return self:GetModule("Buffs").db.profile.enabled end,
					set = function(info, value) 
						local buffs = self:GetModule("Buffs")
						if value then
							buffs.db.profile.enabled = true
							buffs:Enable()
						else
							buffs.db.profile.enabled = false
							buffs:Disable()
						end
					end
				},
				consolidate = not LEGION and {
					order = 10,
					type = "toggle",
					name = L["Consolidate Buffs"],
					desc = L["Consolidate long term buffs into a separate container."],
					get = function() return self:GetModule("Buffs").db.profile.consolidate end,
					set = function(info, value) 
						local buffs = self:GetModule("Buffs")
						if value then 
							buffs.db.profile.consolidate = true
						else 
							buffs.db.profile.consolidate = false
						end
						buffs.frame:SetAttribute("consolidateTo", buffs.db.profile.consolidate and 1)
					end,
					width = "full"
				} or nil,
				debuffheader = {
					type = "header",
					name = L["Player Debuffs"],
					order = 101,
				},
				debuffdescription = {
					type = "description",
					name = L["Here you can change the settings for the harmful player auras located next to the minimap by default."],
					order = 102,
				},
				debuffenable = {
					type = "toggle",
					name = L["Enable Player Debuffs"],
					desc = L["Toggle the display of harmful player auras next to the minimap. Disable if you don't wish to track these, or have another way of tracking them that you prefer."],
					order = 103,
					get = function() return self:GetModule("Debuffs").db.profile.enabled end,
					set = function(info, value) 
						local debuffs = self:GetModule("Debuffs")
						if value then
							debuffs.db.profile.enabled = true
							debuffs:Enable()
						else
							debuffs.db.profile.enabled = false
							debuffs:Disable()
						end
					end
				},
				colorborders = {
					order = 110,
					type = "toggle",
					name = L["Color Debuff Borders"],
					desc = L["Enable to color the border of harmful auras in the color of their school of magic. Disable to color everything red."],
					get = function() return self:GetModule("Debuffs").db.profile.colorborder end,
					set = function(info, value) 
						local debuffs = self:GetModule("Debuffs")
						if value then 
							debuffs.db.profile.colorborder = true
						else 
							debuffs.db.profile.colorborder = false
						end
						debuffs:UpdateAllButtons()
					end,
					width = "full"
				}				
			}
		}
	})
end

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_Auras_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end
end

function module:OnEnable()
	BuffFrame:Hide()
	TemporaryEnchantFrame:Hide()
	if not LEGION then
		ConsolidatedBuffs:Hide()
	end
	BuffFrame:UnregisterAllEvents()
	self:SetActiveTheme(self.db.profile.skin)
end

function module:OnDisable()
	BuffFrame:Show()
	if not LEGION and GetCVarBool("consolidateBuffs") then
		ConsolidatedBuffs:Show()
	end
	TemporaryEnchantFrame:Show()
	BuffFrame:RegisterEvent("UNIT_AURA")
end
