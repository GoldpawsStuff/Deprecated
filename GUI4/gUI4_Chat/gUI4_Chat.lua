local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T

BINDING_HEADER_GUI4_CHAT = L["Goldpaw's Chat"]

-- Lua API
local _G = _G
local tostring = tostring
local ipairs, pairs = ipairs, pairs

local defaults = {
	profile = {
	}
}
local deprecated_settings = {
	bubbles = true,
	chatframes = true,
	sounds = true,
	abbreviations = true,
	filters = true,
	modules = true
}

local function updateConfig()
	T = module:GetActiveTheme()
end

function module:ApplySettings()
end

function module:SetupOptions()
	for name, mod in self:IterateModules() do
		if mod.SetupOptions then
			mod:SetupOptions()
		end
	end	
	
	gUI4:RegisterModuleOptions("FAQ", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["Chat"],
			args = gUI4:GenerateFAQOptionsTable(
				L["\n|cffffd200" .. "I can't see any public chat!" .. "|r"],
				L["This is because you allowed Goldpaw's UI to automatically set up the chat windows the way Goldpaw has them when you first ran the UI on this character. Your public chat should be in the 3rd chat tab now, in the window named 'General'. To change settings for this, you have to manually do it the same way it has always been done in WoW. You right click the chat tab, and use the Blizzard options from there."],
				L["\n|cffffd200" .. "I can't see any loot!" .. "|r"],
				L["The answer to this is the same as the previous one, except that the loot has been moved to the 4th tab, and is called 'Loot'. This too is just a normal Blizzard chat window, and can be configured or removed through the normal Blizzard chat settings available by right clicking on its tab header, like anything else."],
				L["\n|cffffd200" .. "How can I scroll to the top or bottom of the chat frames?" .. "|r"],
				L["By holding down the Shift key while moving the mouse wheel upwards or downwards, the chat frame will scroll to the very top or bottom."],
				L["\n|cffffd200" .. "I can't click on any links in the chat frames!" .. "|r"],
				L["You've probably made the window non-interactive. This is a Blizzard setting which can be changed by right clicking on the chat window's tab header, and selecting 'Make interactive'. Be more careful what you click in the future!"]
				-- L["\n|cffffd200" .. "" .. "|r"],
				-- L[""],
			)
		}
	})

end

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_Chat_DB", defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end
	for i in pairs(deprecated_settings) do
		if self.db.profile[i] ~= nil then
			self.db.profile[i] = nil
		end
	end
	updateConfig()
end


function module:OnEnable()
	for name, mod in self:IterateModules() do
		mod:Enable()
	end
end

function module:OnDisable()
end
