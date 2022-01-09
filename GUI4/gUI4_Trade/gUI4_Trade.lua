local addon,_ = ...

local gUI4 = _G.GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local LMP = _G.GP_LibStub("GP_LibMediaPlus-1.0")
local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local T, hasTheme

local defaults = {
	profile = {
		skin = "Warcraft",
		locked = true,
		point = {}
	}
}

local function updateConfig()
	T = module:GetActiveTheme()
end


function module:UpdateTheme(_, _, addonName)
	if addonName ~= tostring(self) then return end
	if not self.frame then return end 
	updateConfig()
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	if not self.frame then return end 
	updateConfig()
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	updateConfig()
	if self.db.profile.locked then
		LMP:Place(self.frame, T.place)
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:GetFrame()
	return self.frame
end

function module:GetWidgetFrame()
	return self.frame.scaffold.border
end

function module:Lock()
end

function module:Unlock()
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Merchants & Trade", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["Merchants"],
			args = {
				-- header1 = {
					-- type = "header",
					-- width = "full",
					-- order = 1,
					-- name = L["CastBars"]
				-- },
				-- description1 = {
					-- type = "description",
					-- width = "full",
					-- order = 2,
					-- name = L["Toggle the visibility of the on-screen floating castbars."]
				-- },
				autorepair = {
					type = "toggle",
					width = "full",
					order = 10,
					name = L["Automatically repair your equipment."],
					desc = L["Automatically repair your equipment when visiting a merchant with repair capabilities. This is limited by your available funds."],
					get = function() 
						local Merchant = self:GetModule("Merchant")
						return Merchant.db.profile.autorepair
					end,
					set = function(_, value)
						local Merchant = self:GetModule("Merchant")
						Merchant.db.profile.autorepair = value
					end
				},
				guildrepair = {
					type = "toggle",
					width = "full",
					order = 11,
					name = L["Use guild funds to repair."],
					desc = L["Use guild funds to repair your gear when available, instead of using your personal gold. This is limited by your daily available funds set by the guild master of your guild."],
					get = function() 
						local Merchant = self:GetModule("Merchant")
						return Merchant.db.profile.guildrepair
					end,
					set = function(_, value)
						local Merchant = self:GetModule("Merchant")
						Merchant.db.profile.guildrepair = value
					end
				},
				autosell = {
					type = "toggle",
					width = "full",
					order = 20,
					name = L["Automatically sell garbage."],
					desc = L["Automatically sells gray quality loot in your inventory when visiting a merchant."],
					get = function() 
						local Merchant = self:GetModule("Merchant")
						return Merchant.db.profile.autosell
					end,
					set = function(_, value)
						local Merchant = self:GetModule("Merchant")
						Merchant.db.profile.autosell = value
					end
				},				
				detailedreport = {
					type = "toggle",
					width = "full",
					order = 21,
					name = L["Display a detailed sales report."],
					desc = L["Displays a detailed report of every item sold when enabled. Disabled to just show the profit or expenses as a total."],
					get = function() 
						local Merchant = self:GetModule("Merchant")
						return Merchant.db.profile.detailedreport
					end,
					set = function(_, value)
						local Merchant = self:GetModule("Merchant")
						Merchant.db.profile.detailedreport = value
					end
				},				
				
			}
		}
	})
end

function module:OnInitialize()
	self.db = _G.GP_LibStub("GP_AceDB-3.0"):New("gUI4_Trade_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end
	updateConfig()
	

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

function module:OnDisable()
end
