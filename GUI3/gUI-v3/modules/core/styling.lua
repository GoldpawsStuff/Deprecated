--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Styling")
module:SetDefaultModuleState(false) 

local skins, addons = {}, {}

-- each key corresponds to a submodule name
-- submodule skins will only be applied if both a submodule and a setting exist
local defaults = {
	-- blizzard skins
	AlertFrames = true;
	AutoCompleteBox = true;
	Character = true;
	ColorPickerFrame = true;
	DressUpFrame = true;
	DungeonFinder = true;
	Friends = true;
	GameMenuFrame = true;
	GhostFrame = true;
	GossipFrame = true;
	GuildInvite = true;
	GuildRegistrar = true;
	ItemText = true;
	Mailbox = true;
	MerchantFrame = true;
	Petitions = true;
	PvP = true;
	OpacityFrame = true;
	QuestFrame = true;
	QuestFrameGreeting = true;
	ReadyCheckFrame = true;
	RolePollPopup = true;
	StackSplitFrame = true;
	StaticPopup = true;
	Tabard = true;
	TaxiFrame = true;
	TicketStatusFrameButton = true;
	TradeFrame = true;
	Tutorials = true;
	WatchFrame = true;
	WorldStateScore = true;
	WorldStateScoreFrame = true;

	-- blizzard addon skins
	Blizzard_AchievementUI = true;
	Blizzard_ArchaeologyUI = true;
	Blizzard_AuctionUI = true;
	Blizzard_BarbershopUI = true;
	Blizzard_BlackMarketUI = true;
	Blizzard_Calendar = true;
	Blizzard_DebugTools = true;
	Blizzard_EncounterJournal = true;
	Blizzard_GuildBankUI = true;
	Blizzard_GuildControlUI = true;
	Blizzard_GuildUI = true;
	Blizzard_InspectUI = true;
	Blizzard_ItemAlterationUI = true;
	Blizzard_ItemSocketingUI = true;
	Blizzard_ItemUpgradeUI = true;
	Blizzard_LookingForGuildUI = true;
	Blizzard_MacroUI = true;
	Blizzard_MovePad = true;
	Blizzard_ReforgingUI = true;
	Blizzard_TradeSkillUI = true;
	Blizzard_TrainerUI = true;
	Blizzard_VoidStorageUI = true;
	
	-- 3rd party addon skins
	-- AuctionLite = true;
	-- ["DBM-Core"] = true;
	-- Healium = true;
	Omen = true;
	-- Postal = true;
	Recount = true;
	Skada = true;
}

-- register a skin func of a blizzard element available at startup
module.RegisterSkin = function(self, element, enable)
	self:argCheck(element, 1, "string")
	self:argCheck(enable, 2, "function")
	skins[element] = enable
end

-- this should also be used for blizzard addons, not just 3rd party
module.RegisterAddOnSkin = function(self, addon, enable)
	self:argCheck(addon, 1, "string")
	self:argCheck(enable, 2, "function")
	addons[addon] = enable
end

module.OnInit = function(self)
	local L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	
	-- db = defaults -- cop out. We're not giving skin choices anymore, just enforcing them! :)

	-- base options menu
	local menu = {
		{
			type = "group";
			name = module:GetName();
			order = 1;
			virtual = true;
			children = {
				{ -- menu title
					type = "widget";
					element = "Title";
					order = 1;
					msg = L["Skins"];
				};
				{ -- subtext
					type = "widget";
					element = "Text";
					order = 2;
					msg = L["Here you can decide which elements should be skinned to match the rest of the UI, and which should keep their default appearance."] .. " " .. L["Changing these settings requires the UI to be reloaded in order to complete."];
				};
			};
		};
	}

	-- add menu options and enable or queue the skin functions as needed
	for _,v in self:IterateModules() do
		if (db[v.name] ~= nil) then
			local v = v 
			v:Init() -- fire off the module's init function, and register its skinning function
			tinsert(menu[1].children, {
				type = "widget";
				element = "CheckButton";
				name = v.name;
				width = "half"; -- half width here, or too messy?
				order = 10; -- same order for all, to activate alphanumeric sorting
				msg = v:GetAttribute("name") or v.name; -- localized name if available, module name otherwise
				desc = v:GetAttribute("description"); -- localized description if available, nothing otherwise
				set = function(self) 
					db[v.name] = not(db[v.name]) 
					F.ScheduleRestart() -- always schedule a restart query after a skin change
				end;
				get = function() return db[v.name] end;
			})
			if (db[v.name] == true) then
				if (skins[v.name]) then
					skins[v.name](v) -- apply skin function
				elseif (addons[v.name]) then
					gUI:HookAddOn(v.name, addons[v.name]) -- let the addon monitor handle this one
				end
			end
		end
	end

	local restoreDefaults = function()
		if (InCombatLockdown()) then 
			print(L["Can not apply default settings while engaged in combat."])
			return
		end
		self:ResetCurrentOptionsSetToDefaults()
	end
	self:RegisterAsBlizzardOptionsMenu(menu, L["Skins"], "default", restoreDefaults)
end
