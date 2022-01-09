--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

if (select(4, GetBuildInfo())) < 50001 then
	print(("gUI™ requires WoW patch 5.0.1 or higher, and you only have %s, bailing out!"):format((GetBuildInfo())))
	return
end

-- get rid of ourselves
local WOD = select(4, GetBuildInfo()) >= 60000
if WOD then
	for i = 1, GetNumAddOns() do
		-- WoD doesn't appear to support addonName as input(?)
		local name, title, notes, url, loadable, reason, security, newVersion = GetAddOnInfo(i)
		if name == "gUI4" and url then
			return
		end
	end
else
	local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo("gUI4")
	if enabled then
		return
	end
end

-- Lothrik's fix for the 5.4.1 super taint
-- *this will CAUSE taint in the talent/glyphUI in other patches! 
-- http://us.battle.net/wow/en/forum/topic/10388659115#7
-- C_StorePublic.IsDisabledByParentalControls = noop

local gUI = LibStub("gCore-4.0"):NewAddon(addon, "gDB-2.0", "gMedia-4.0", "gFrameHandler-2.0", "gPanel-3.0", "gOptionsMenu-1.0")
if not(gUI) then return end

gUI:SetDefaultModuleState(false) -- allow modules to be manually enabled, preventing them from firing OnInit prematurely
gUI:SetDefaultModuleLibraries("gFrameHandler-2.0", "gOptionsMenu-1.0") -- give all our modules default access to these libraries
gUI:NewDataBase("colors")
gUI:NewDataBase("emoticons")
gUI:NewDataBase("functions")

gUI:SetAttribute("dummy", CreateFrame("Frame")); gUI:GetAttribute("dummy"):Hide() -- taintfree way of hiding objects
gUI:SetAttribute("parent", CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")) -- top level frame hidden in pet battles
gUI:SetAttribute("combathider", CreateFrame("Frame", nil, gUI:GetAttribute("parent"), "SecureHandlerStateTemplate")) -- hidden in combat
gUI:SetAttribute("vehiclehider", CreateFrame("Frame", nil, gUI:GetAttribute("parent"), "SecureHandlerStateTemplate")) -- hidden in vehicles
gUI:SetAttribute("savedvariablesglobal", "gUI3_DB") -- saved variables global name, as set in the .toc file
gUI:SetAttribute("title", GetAddOnMetadata(addon, "Title")) -- display name of the addon
gUI:SetAttribute("version", GetAddOnMetadata(addon, "Version")) -- addon version
gUI:SetAttribute("curseversion", GetAddOnMetadata(addon, "X-Curse-Packaged-Version")) -- curse packaged version/build
gUI:SetAttribute("realm", GetRealmName()) -- current realm name
gUI:SetAttribute("name", UnitName("player")) -- player name
gUI:SetAttribute("class", select(2, UnitClass("player"))) -- player class file name
gUI:SetAttribute("classID", select(3, UnitClass("player"))) -- player class ID
gUI:SetAttribute("class-local", UnitClass("player")) -- localized player class display name
gUI:SetAttribute("faction", UnitFactionGroup("player")) -- english player faction name
gUI:SetAttribute("faction-local", select(2, UnitFactionGroup("player"))) -- localized player faction name
gUI:SetAttribute("http-web", "www.friendlydruid.com")
gUI:SetAttribute("http-download", "www.curse.com/addons/wow/gUI-v3")
gUI:SetAttribute("http-facebook", "www.facebook.com/goldpawsgui")
gUI:SetAttribute("http-twitter", "twitter.com/friendlydruid")
gUI:SetAttribute("http-youtube", "www.youtube.com/user/FriendlyDruidTV")
gUI:SetAttribute("http-email", "goldpaw@friendlydruid.com")

local L, C, F, M, db
local CreateFloaters
local TEST_MODE 
local noop = noop or gUI.noop
local moduleDisplayName = {}

-- globals, yay!!
_G.MINIMAP_SIZE = 160

--------------------------------------------------------------------------------------------------
--		default settings
--------------------------------------------------------------------------------------------------
local defaults = {
	-- version control
	initialized = false; -- will be true when user has run through install tutorial once
	version = 0; -- version of gUIv3 (this is NOT 3, but rather whatever is listed in the .toc file)
	build = 0; -- build number as reported by the Curse Packager
	temporaryDisabled = false;
	
	-- master layout
	-- mainly used by the actionbar module, but more will follow
	layout = 1;

	gold = 0; -- your character's gold. on the merchant- and bag modules' TODO lists.
	
	-- global styles. work in progress.
	panelAlpha = 0.75;

	-- frame positions
	floaters = {
		GUIS_WorldStateScore = { "TOP", "UIParent", "TOP", 0, -12 };
		-- GUIS_TicketStatus = { "TOPLEFT", "UIParent", "TOPLEFT", 180, -50 };
		GUIS_ObjectiveTracker = { "RIGHT", "UIParent", "RIGHT", -80, 0 }; -- "TOPRIGHT", "UIParent", "TOPRIGHT", -80, -210
		GUIS_VehicleSeat = { "CENTER", "UIParent", "CENTER", -200, 110 };
		GUIS_Durability = { "CENTER", "UIParent", "CENTER", -200, -10 };
		GUIS_GhostFrame = { "CENTER", "UIParent", "CENTER", 0, 100 };
		GUIS_ExtraActionBar = { "CENTER", "UIParent", "CENTER", 0, -50 };
		GUIS_PlayerPowerBarAlt = { "CENTER", "UIParent", "CENTER", 0, -150 };
		GUIS_AchievementAlertFrame = { "BOTTOM", "UIParent", "BOTTOM", 0, 250 };
	};
	
	-- enabled modules 
	-- switching to boolean from v3 build 59
	enabledModules = {
		Actionbars = true;
		Auras = true;
		Bags = true;
		Castbars = true;
		Chat = true;
		Combat = true;
		CombatLogs = true;
		DeveloperTools = true;
		Fonts = true;
		Loot = true; -- error?
		Map = true;
		Merchant = true;
		Minimap = true;
		Nameplates = true;
		Panels = true;
		Tooltips = true;
		Unitframes = true;
	};
}

local autoDisable = {
	Actionbars = {
		Bartender4 = true;
		Dominos = true;
		RazerAnansi = true;
		RazerNaga = true;
	};
	Auras = {
		ElkBuffBars = true;
		SatrinaBuffFrame = true;
	};
	Bags = {
		AdiBags = true;
		ArkInventory = true;
		Bagnon = true;
		Baggins = true;
		BaudBag = true;
		cargBags_Nivaya = true;
		cargBags_Simplicity = true;
		Combuctor = true;
		famBags = true;
		OneBag3 = true;
		OneBank3 = true;
		TBag = true;
	};
	Castbars = {
		Quartz = true;
	};
	Chat = {
		Chatter = true;
		["Prat-3.0"] = true;
	};
	Unitframes = {
		ag_UnitFrames = true;
		PitBull4 = true;
		ShadowedUnitFrames = true;
		XPerl = true;
	};
	Minimap = {
		-- Carbonite = true;
		SexyMap = true;
	};
	Nameplates = {
		Aloft = true;
		DocsUI_Nameplates = true;
		Headline = true;
		knameplates = true;
		Kui_Nameplates = true;
		mNameplates = true;
		TidyPlates = true;
		["Healers-Have-To-Die"] = true;
	};
	Tooltips = {
		StarTip = true;
		TinyTip = true;
		TipTac = true;
	};
}

--------------------------------------------------------------------------------------------------
--		Floaters
--------------------------------------------------------------------------------------------------
-- don't call this until PLAYER_LOGIN, to get sizes correct
do
	local fixAchievementAnchor, fixDungeonAnchor, fixTicketStrata
	local Glue, CreateHolder

	Glue = function(frame, target, ...)
		if (...) then
			frame:ClearAllPoints()
			frame:SetPoint(...)
		else
			frame:ClearAllPoints()
			frame:SetAllPoints(target)
		end

		frame.ClearAllPoints = noop
		frame.SetAllPoints = noop
		frame.SetPoint = noop
		
		return frame
	end
	
	CreateHolder = function(name, w, h, displayName, framegroup)
		local frame = CreateFrame("Frame", name, gUI:GetAttribute("parent")) -- hide in petbattles
		frame:SetSize(w, h)
		-- frame:PlaceAndSave(...)
		
		gUI:PlaceAndSave(frame, displayName or name, db.floaters[name], unpack(defaults.floaters[name]))
		gUI:AddObjectToFrameGroup(frame, framegroup or "floaters")
		
		_G[name] = frame
		
		return frame
	end

	fixAchievementAnchor = function()
		local previous, frame
		for i = 1, MAX_ACHIEVEMENT_ALERTS do
			frame = _G[("AchievementAlertFrame%d"):format(i)]

			if (frame) then
				frame:SetPoint("BOTTOM", (previous and (previous:IsShown())) and previous or _G["GUIS_AchievementAlertFrame"], previous and "TOP" or "BOTTOM", 0, previous and 10 or 0)
				previous = frame
			end		
		end
	end

	fixDungeonAnchor = function()
		local frame
		for i = MAX_ACHIEVEMENT_ALERTS, 1, -1 do
			frame = _G[("AchievementAlertFrame%d"):format(i)]

			if (frame) and (frame:IsShown()) then
				DungeonCompletionAlertFrame1:ClearAllPoints()
				DungeonCompletionAlertFrame1:SetPoint("BOTTOM", frame, "TOP", 0, 10)
				return
			end
			
			DungeonCompletionAlertFrame1:ClearAllPoints()
			DungeonCompletionAlertFrame1:SetPoint("BOTTOM", _G["GUIS_AchievementAlertFrame"], "TOP", 0, 10) -- our custom frame
		end
	end

	fixTicketStrata = function(self)
		if (self:IsShown()) then
			self:SetFrameStrata("DIALOG")
		else
			self:SetFrameStrata("BACKGROUND")
		end
	end
	
	CreateFloaters = function()
		-- world scores (battleground scores, dungeon/raid waves etc)
		local GUIS_WorldStateScore = CreateHolder("GUIS_WorldStateScore", 48, 48, L["WorldStateScore"])
		Glue(WorldStateAlwaysUpFrame, nil, "TOP", GUIS_WorldStateScore, "TOP", 0, 0):SetFrameStrata("BACKGROUND")

		-- vehicle seat indicator
		Glue(VehicleSeatIndicator, CreateHolder("GUIS_VehicleSeat", 128, 128, L["Vehicle"]))

		-- return to graveyard
		Glue(GhostFrame, CreateHolder("GUIS_GhostFrame", 130, 46, L["Ghost"]))

		-- durability indicator
		Glue(DurabilityFrame, CreateHolder("GUIS_Durability", 60, 64, L["Durability"]))

		-- achievement and dungeon completion alerts
		CreateHolder("GUIS_AchievementAlertFrame", 300, 88, L["Achievement and Dungeon Alert Frame"])
		
		hooksecurefunc("AlertFrame_FixAnchors", fixAchievementAnchor)
		hooksecurefunc("AlertFrame_FixAnchors", fixDungeonAnchor)
		
		gUI:RegisterEvent("ACHIEVEMENT_EARNED", fixAchievementAnchor)
		
		-- GM ticket status frame
		-- Glue(TicketStatusFrame, CreateHolder("GUIS_TicketStatus", 208, 75, L["Tickets"]))
		
		-- our alt bar bugs out in MoP, as it appears in vehicles
		-- TODO: Make a separate object for this bar alon
		Glue(PlayerPowerBarAlt, CreateHolder("GUIS_PlayerPowerBarAlt", 256, 64, L["Alternate Power"], "castbars"))
		
		-- ExtraActionButton1
		-- Glue(ExtraActionBarFrame, CreateHolder("GUIS_ExtraActionBar", 64, 64, "CENTER", "UIParent", "CENTER", 0, -150))

		local extraFrame = CreateHolder("GUIS_ExtraActionBar", 64, 64, L["ExtraActionButton"])
		ExtraActionBarFrame:SetParent(gUI:GetAttribute("parent"))
		ExtraActionBarFrame:ClearAllPoints()
		ExtraActionBarFrame:SetPoint("CENTER", extraFrame, "CENTER", 0, 0)
		ExtraActionBarFrame.ignoreFramePositionManager = true

		-- totally ripped off idea (roth) to remove the style texture.
		local noway = function(self, tex)
			if (strsub(tex, 1, 9):lower() == "interface") then
				self:SetTexture("")
			end
		end
		ExtraActionButton1.style:SetTexture("")
		hooksecurefunc(ExtraActionButton1.style, "SetTexture", noway)
		
		fixTicketStrata(TicketStatusFrame)

		TicketStatusFrame:HookScript("OnShow", fixTicketStrata)
		TicketStatusFrame:HookScript("OnHide", fixTicketStrata)

		-- objectives tracker
		do
			GUIS_ObjectiveTracker = CreateFrame("Frame", "GUIS_ObjectiveTracker", gUI:GetAttribute("parent"))
			GUIS_ObjectiveTracker:SetSize(250, 400)
			gUI:PlaceAndSave(GUIS_ObjectiveTracker, L["Objectives"], db.floaters["GUIS_ObjectiveTracker"], unpack(defaults.floaters["GUIS_ObjectiveTracker"]))
			gUI:AddObjectToFrameGroup(GUIS_ObjectiveTracker, "floaters")
			
			WatchFrame:SetParent(GUIS_ObjectiveTracker) 
			WatchFrame:SetFrameStrata("BACKGROUND")
			WatchFrame:ClearAllPoints()
			WatchFrame:SetPoint("TOPLEFT", GUIS_ObjectiveTracker, 32, -2.5)
			WatchFrame:SetPoint("BOTTOMRIGHT", GUIS_ObjectiveTracker, 4,0)
			WatchFrame.ClearAllPoints = noop
			WatchFrame.SetAllPoints = noop
			WatchFrame.SetPoint = noop

			local collapse = function()
				for i = 1, MAX_BOSS_FRAMES do
					if (UnitExists("boss" .. i)) then
						return true
					end
				end
				local frame
				for i = 1, 5 do
					frame = _G["GUIS_ArenaPrep" .. i] 
					if (UnitExists("arena" .. i)) or ((frame) and (frame:IsVisible())) then
						return true
					end
				end
			end
			local updateWatchFrameCollapseExpand = function()
				if (collapse()) then
					if not(WatchFrame.collapsed) then
						WatchFrame.expandLater = true
						WatchFrame_CollapseExpandButton_OnClick(WatchFrame_CollapseExpandButton)
						return
					end
				elseif (WatchFrame.collapsed) and (WatchFrame.expandLater) then
					WatchFrame.expandLater = nil
					WatchFrame_CollapseExpandButton_OnClick(WatchFrame_CollapseExpandButton)
					return
				end
			end
			gUI:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", updateWatchFrameCollapseExpand)
			gUI:RegisterEvent("PLAYER_ENTERING_WORLD", updateWatchFrameCollapseExpand)
			gUI:RegisterEvent("PLAYER_REGEN_ENABLED", updateWatchFrameCollapseExpand)
			gUI:RegisterEvent("UNIT_TARGETABLE_CHANGED", updateWatchFrameCollapseExpand)
			
			-- these events are related to flag and orb carrying in various BGs, and also makes arenaframe visible
			gUI:RegisterEvent("UPDATE_WORLD_STATES", updateWatchFrameCollapseExpand)
			gUI:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", updateWatchFrameCollapseExpand)
			gUI:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", updateWatchFrameCollapseExpand)
			gUI:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", updateWatchFrameCollapseExpand)
			
			-- there events are related to arena prep frames
			gUI:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", updateWatchFrameCollapseExpand)
			gUI:RegisterEvent("ARENA_OPPONENT_UPDATE", updateWatchFrameCollapseExpand)
			
			local expanded, normal = 350, 250
			local updateWatchFrameWidth = function(self, event, cvar)
				local update = nil
				if (event == "PLAYER_ENTERING_WORLD") then
					update = true
				elseif (event == "CVAR_UPDATE") then
					if (cvar == "WATCH_FRAME_WIDTH_TEXT") then
						if not(WatchFrame.userCollapsed) then
							update = true
						end
					end
				elseif not(event) then
					if not(WatchFrame.userCollapsed) then
						update = true
					end
				end
				if (update) then
					local width = tonumber(GetCVar("watchFrameWidth"))
					if (width == 0) then
						GUIS_ObjectiveTracker:SetSize(normal, GetScreenHeight() - 470)
					elseif (width == 1) then
						GUIS_ObjectiveTracker:SetSize(expanded, GetScreenHeight() - 470)
					end
				end
			end
			updateWatchFrameWidth()
			
			gUI:RegisterEvent("CVAR_UPDATE", updateWatchFrameWidth)
			gUI:RegisterEvent("PLAYER_ENTERING_WORLD", updateWatchFrameWidth)
		end
	end
end

--------------------------------------------------------------------------------------------------
--		Error Handling (moved to the core in v3)
--------------------------------------------------------------------------------------------------
do
	local useWhiteListOnly -- not generally something we want to do
	local lastError, lastTime

	local HZ = 2.0 -- time in seconds between each identical error message

	-- set a whitelist and a blacklist
	-- using constants to avoid localization issues
	-- http://www.wowpedia.org/WoW_Constants/Errors
	local whiteList = {
		[ ERR_BAG_FULL ] = true, -- That bag is full.
		[ ERR_BAG_IN_BAG ] = true, -- Can't put non-empty bags in other bags. 
		[ ERR_BANK_FULL ] = true, -- Your bank is full 
		[ ERR_FISH_ESCAPED ] = true, -- Your fish got away! 
		[ ERR_INV_FULL ] = true, -- Inventory is full. 
		[ ERR_ITEM_CANT_BE_DESTROYED ] = true, -- That item cannot be destroyed. 
		[ ERR_ITEM_MAX_COUNT ] = true, -- You can't carry any more of those items.
		[ ERR_LOGOUT_FAILED ] = true, -- You can't logout now. 
		[ ERR_LOOT_WHILE_INVULNERABLE ] = true, -- Cannot loot while invulnerable. 
		[ ERR_MOUNT_LOOTING ] = true, -- You can't mount while looting! 
		[ ERR_MOUNT_SHAPESHIFTED ] = true, -- You can't mount while shapeshifted! 
		[ ERR_MOUNT_TOOFARAWAY ] = true, -- That mount is too far away!  
		[ ERR_MUST_EQUIP_ITEM ] = true, -- You must equip that item to use it.  
		[ ERR_MUST_REPAIR_DURABILITY ] = true, -- You must repair that item's durability to use it. 
		[ ERR_NO_SLOT_AVAILABLE ] = true, -- No equipment slot is available for that item. 
		[ ERR_NOT_ENOUGH_MONEY ] = true, -- You don't have enough money. 
		[ ERR_NOT_EQUIPPABLE ] = true, -- This item cannot be equipped. 
		[ ERR_NOT_IN_COMBAT ] = true, -- You can't do that while in combat 
		[ ERR_NOT_WHILE_SHAPESHIFTED ] = true, -- You can't do that while shapeshifted.  
		[ ERR_PASSIVE_ABILITY ] = true, -- You can't put a passive ability in the action bar. 
		[ ERR_PET_SPELL_DEAD ] = true, -- Your pet is dead. 
		[ ERR_QUEST_LOG_FULL ] = true, -- Your quest log is full.  
		[ ERR_TAXINOPATHS ] = true, -- You don't know any flight locations connected to this one. 
		[ ERR_TAXINOSUCHPATH ] = true, -- There is no direct path to that destination! 
		[ ERR_TAXINOTENOUGHMONEY ] = true, -- You don't have enough money! 
		[ ERR_TAXIPLAYERALREADYMOUNTED ] = true, -- You are already mounted! Dismount first. 
		[ ERR_TAXIPLAYERBUSY ] = true, -- You are busy and can't use the taxi service now. 
		[ ERR_TAXIPLAYERMOVING ] = true, -- You are moving. 
		[ ERR_TAXIPLAYERSHAPESHIFTED ] = true, -- You can't take a taxi while disguised! 
		[ ERR_TAXISAMENODE ] = true, -- You are already there! 
		[ ERR_TOOBUSYTOFOLLOW ] = true, -- You're too busy to follow anything! 
		[ ERR_TRADE_BAG_FULL ] = true, -- Trade failed, you don't have enough space. 
		[ ERR_TRADE_MAX_COUNT_EXCEEDED ] = true, -- You have too many of a unique item. 
		[ ERR_TRADE_TARGET_MAX_COUNT_EXCEEDED ] = true, -- Your trade partner has too many of a unique item. 
		[ ERR_TRADE_QUEST_ITEM ] = true, -- You can't trade a quest item.  
		[ SPELL_FAILED_NO_MOUNTS_ALLOWED ] = true, -- You can't mount here.
		[ SPELL_FAILED_ONLY_BATTLEGROUNDS ] = true, -- Can only use in battlegrounds
	}

	local blackList = {
		[ ERR_ABILITY_COOLDOWN ] = true, -- Ability is not ready yet.
		[ ERR_ATTACK_CHARMED ] = true, -- Can't attack while charmed. 
		[ ERR_ATTACK_CONFUSED ] = true, -- Can't attack while confused.
		[ ERR_ATTACK_DEAD ] = true, -- Can't attack while dead. 
		[ ERR_ATTACK_FLEEING ] = true, -- Can't attack while fleeing. 
		[ ERR_ATTACK_PACIFIED ] = true, -- Can't attack while pacified. 
		[ ERR_ATTACK_STUNNED ] = true, -- Can't attack while stunned.
		[ ERR_AUTOFOLLOW_TOO_FAR ] = true, -- Target is too far away.
		[ ERR_BADATTACKFACING ] = true, -- You are facing the wrong way!
		[ ERR_BADATTACKPOS ] = true, -- You are too far away!
		[ ERR_CLIENT_LOCKED_OUT ] = true, -- You can't do that right now.
		[ ERR_ITEM_COOLDOWN ] = true, -- Item is not ready yet. 
		[ ERR_OUT_OF_ENERGY ] = true, -- Not enough energy
		[ ERR_OUT_OF_FOCUS ] = true, -- Not enough focus
		[ ERR_OUT_OF_HEALTH ] = true, -- Not enough health
		[ ERR_OUT_OF_MANA ] = true, -- Not enough mana
		[ ERR_OUT_OF_RAGE ] = true, -- Not enough rage
		[ ERR_OUT_OF_RANGE ] = true, -- Out of range.
		[ ERR_SPELL_COOLDOWN ] = true, -- Spell is not ready yet.
		[ ERR_SPELL_FAILED_ALREADY_AT_FULL_HEALTH ] = true, -- You are already at full health.
		[ ERR_SPELL_OUT_OF_RANGE ] = true, -- Out of range.
		[ ERR_USE_TOO_FAR ] = true, -- You are too far away.
		[ SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW ] = true, -- You can't do that right now.
		[ SPELL_FAILED_CASTER_AURASTATE ] = true, -- You can't do that yet
		[ SPELL_FAILED_CASTER_DEAD ] = true, -- You are dead
		[ SPELL_FAILED_CASTER_DEAD_FEMALE ] = true, -- You are dead
		[ SPELL_FAILED_CHARMED ] = true, -- Can't do that while charmed
		[ SPELL_FAILED_CONFUSED ] = true, -- Can't do that while confused
		[ SPELL_FAILED_FLEEING ] = true, -- Can't do that while fleeing
		[ SPELL_FAILED_ITEM_NOT_READY ] = true, -- Item is not ready yet
		[ SPELL_FAILED_NO_COMBO_POINTS ] = true, -- That ability requires combo points
		[ SPELL_FAILED_NOT_BEHIND ] = true, -- You must be behind your target.
		[ SPELL_FAILED_NOT_INFRONT ] = true, -- You must be in front of your target.
		[ SPELL_FAILED_OUT_OF_RANGE ] = true, -- Out of range
		[ SPELL_FAILED_PACIFIED ] = true, -- Can't use that ability while pacified
		[ SPELL_FAILED_SPELL_IN_PROGRESS ] = true, -- Another action is in progress
		[ SPELL_FAILED_STUNNED ] = true, -- Can't do that while stunned
		[ SPELL_FAILED_UNIT_NOT_INFRONT ] = true, -- Target needs to be in front of you.
		[ SPELL_FAILED_UNIT_NOT_BEHIND ] = true, -- Target needs to be behind you.
	}

	gUI.UI_ERROR_MESSAGE = function(self, event, msg)
		if not(msg) then return end
		
		local now = GetTime()
		if (msg == lastError) and ((lastTime + HZ) > now) then
			return
		end
		
		if (not(useWhiteListOnly) and not(blackList[msg])) or ((useWhiteListOnly) and (whiteList[msg])) then
			self:UIErrorMessage(msg, C["error"][1], C["error"][2], C["error"][3])
		end
		
		lastError, lastTime = msg, now
	end

	gUI.UI_INFO_MESSAGE = function(self, event, msg)
		if not(msg) then return end
		self:UIErrorMessage(msg, C["value"][1], C["value"][2], C["value"][3])
	end

	gUI.EnableErrorFilter = function(self)
		UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
		UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE")
		self:RegisterEvent("UI_ERROR_MESSAGE")
		self:RegisterEvent("UI_INFO_MESSAGE")
	end

	gUI.DisableErrorFilter = function(self)
		UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
		UIErrorsFrame:RegisterEvent("UI_INFO_MESSAGE")
		self:UnregisterEvent("UI_ERROR_MESSAGE")
		self:UnregisterEvent("UI_INFO_MESSAGE")
	end

end

--------------------------------------------------------------------------------------------------
--		gUI™ API
--------------------------------------------------------------------------------------------------
-- other modules can use this to check if the UI has been initialized (run once)
gUI.HasRunOnce = function(self)
	return db.initialized
end

-- /install 
gUI.InstallAll = function(self)

end

local me = {
	Draenor = {
		Goldpaw = true;
		Aleman = true;
		Blitzee = true;
		Bottie = true;
		Caddie = true;
		Midgarsgorm = true;
		Pandalane = true;
		Pinkcuffs = true;
		Raindancer = true;
		Sunstreak = true;
		Worgnina = true;
	};
}

gUI.IsMe = function(self)
	return (me[self:GetAttribute("realm")]) and (me[self:GetAttribute("realm")][self:GetAttribute("name")])
end

gUI.SetLayout = function(self, layout)
	self:argCheck(layout, 1, "number", "nil")
	if (layout) and (layouts[layout]) and (db.layout ~= layout) then
		db.layout = layout
		gUI:FireCallback("GUIV3_LAYOUT_CHANGED", layout)
	end
end

gUI.GetLayout = function(self)
	return db.layout
end

gUI.GetGold = function(self)

end

gUI.GetModuleName = function(self, name)
	self:argCheck(name, 1, "string")
	return moduleDisplayName[name] or name
end

-- 
-- all-in-one function that retrieves all databases, set up module defaults and returns current options set
--	intended for sub-modules and external addons after main databases have been initialized
--
-- gUI:GetEnvironment([t, defaults[, noClean]])
-- 	@param t <table> the 'self' object of the module that calls it
-- 	@param defaults <table> the defaults table for the module that calls it
-- 	@param noClean <boolean, nil> 'true' if db entries not in the defaults shouldn't be purged
-- 	@return L, C, F, M[, db] <tables> the current locale, the color database, the function library, media library and the module db
-- 		*while L, C and F are all tables, M is a function call and should have the format local media = M(type, name)
-- 		*the module db is the current settings of the given 'self' module based on char and realm. 
do
	local M = function(folder, file) return gUI:GetMedia(folder, file) end 
	gUI.GetEnvironment = function(self, t, defaults, noClean)
		local L = L or LibStub("gLocale-2.0"):GetLocale(addon)
		local C = C or self:GetDataBase("colors", true)
		local F = F or self:GetDataBase("functions", true)
		local db = ((t) and (defaults)) and t:InitializeCurrentOptionsSet(self:GetAttribute("savedvariablesglobal"), defaults, noClean)
		return L, C, F, M, db
	end
end

--------------------------------------------------------------------------------------------------
--		Startup and Initialization
--------------------------------------------------------------------------------------------------
--	anti-taint measures,
-- and various other blizzard (and other addon) fixes
gUI.WarOnTaint = function(self)
	local patch, build, released, toc = GetBuildInfo()
	build = tonumber(build)

	-- Fix known tainted popups that easily can be fixed. pop. fix. snap. crackle?
	--
	-- This is basically any addon that fails to add the "preferredIndex = 3" setting to their popups, 
	-- yet defines their popups before calling them so it is possible to remedy the situation for us.
	-- "gUI™ - cleaning up other people's mess since 2010"
	--
	-- Known unfixable/too clunky to bother addons: 
	--		TradeSkillMaster
	--
	do
		local popsinners = {
			BugSack = {
				["BugSackSendBugs"] = true;
			};
			Postal = {
				["POSTAL_NEW_PROFILE"] = true;
				["POSTAL_DELETE_MAIL"] = true;
				["POSTAL_DELETE_MONEY"] = true;
			};
			AuctionLite = {
				["AL_FAST_SCAN"] = true;
				["AL_CANCEL_NOTE"] = true;
				["AL_CANCEL_CONFIRM"] = true;
				["AL_NEW_FAVORITES_LIST"] = true;
				["AL_CLEAR_DATA"] = true;
				["AL_VENDOR_WARNING"] = true;
			};
		}
		local popfix = function(self, event, addon)
			if not(addon) or not(popsinners[addon]) then
				return
			end
			for sinner,_ in pairs(popsinners) do
				if (IsAddOnLoaded(sinner)) then
					for pop,_ in pairs(popsinners[sinner]) do
						if (StaticPopupDialogs[pop]) then
							StaticPopupDialogs[pop].preferredIndex = STATICPOPUP_NUMDIALOGS -- 5.4.1 taint
						end					
					end
					popsinners[sinner] = nil
				end
			end
			-- this one has no specific addon, so we keep checking
			if (StaticPopupDialogs["ACECONFIGDIALOG30_CONFIRM_DIALOG"]) and not(StaticPopupDialogs["ACECONFIGDIALOG30_CONFIRM_DIALOG"].preferredIndex == STATICPOPUP_NUMDIALOGS) then
				StaticPopupDialogs["ACECONFIGDIALOG30_CONFIRM_DIALOG"].preferredIndex = STATICPOPUP_NUMDIALOGS
			end
		end
		
		-- initial call
		popfix()
		
		-- make a callback for other addons
		self:RegisterEvent("ADDON_LOADED", popfix)
	end
	
	-- the damn SearchLFGLeave() taint
	-- I got this idea on February 16th, 2012. 
	--
	-- as of 5.0.4 I'm not sure this is still needed
	LFRParentFrame:SetScript("OnHide", nil)

	-- TalentFrame/Glyph taint
	-- existed in 4.3.0
	--
	-- the frame will become tainted if closed by clicking the keybind to toggle it.
	-- the problem with this is that it also affects glyphs, making it impossible to change them.
	--
	-- opening the window again, then closing it with Esc, will magically remove the taint. Weird.
	--
	-- so our fix, is to take the keybind used to toggle the talentframe, and move it to a custom keybind
	-- that only opens the frame, not toggles it. This will force the user to use Esc or the closebutton 
	-- to close the frame, and thus prevents the taint from happening.
	do
		local fixTalents = function()
			local keys
			local firstSet = GetCurrentBindingSet()
			local oldAction, newAction = "TOGGLETALENTS", "GUISSHOWTALENTS"
			
			-- set 1 = account, 2 = character
			for bindingSet = 1, 2 do
				LoadBindings(bindingSet)

				keys = { GetBindingKey(oldAction) }
				if (keys) then
					local key
					for i = 1, #keys do
						key = keys[i]
						if (key) then
							SetBinding(keys[i], newAction)
							SaveBindings(bindingSet)
						end
					end
				end
			end
			
			-- load the original binding set
			if (firstSet == 1) or (firstSet == 2) then
				LoadBindings(firstSet)
			end
		end
		
		-- 5.0.4
		-- revert to the blizzard bind instead, it's not the source of taint any longer
		local revertTalents = function()
			local keys
			local firstSet = GetCurrentBindingSet()
			local oldAction, newAction = "GUISSHOWTALENTS", "TOGGLETALENTS"
			
			-- set 1 = account, 2 = character
			for bindingSet = 1, 2 do
				LoadBindings(bindingSet)

				keys = { GetBindingKey(oldAction) }
				if (keys) then
					local key
					for i = 1, #keys do
						key = keys[i]
						if (key) then
							SetBinding(keys[i], newAction)
							SaveBindings(bindingSet)
						end
					end
				end
			end
			
			-- load the original binding set
			if (firstSet == 1) or (firstSet == 2) then
				LoadBindings(firstSet)
			end
		end
		
		self:RegisterEvent("PLAYER_ENTERING_WORLD", revertTalents)
		self:RegisterEvent("VARIABLES_LOADED", revertTalents)
	end
	
	-- just to avoid the unitframes being messed with in combat
	do
		local hideOptions = function()
			if (InterfaceOptionsFrame:IsShown()) then
				InterfaceOptionsFrame:Hide()
			end
		end
		self:RegisterEvent("PLAYER_REGEN_DISABLED", hideOptions)
	end
	
	-- WorldMap taint
	-- 
	-- the blobframe and poi-objects sometimes cause taint in combat.
	-- for some reasons these objects seems to sometimes become insecure,
	-- by the mere existence of other addons.
	-- so we go with a "better safe than sorry" philosophy here as always
	-- update April 17th, 2013: removed the whole mapskin and all fixes. too many bugs and taints
	if (build < 16837) then
		local WorldMapQuestShowObjectivesShow = WorldMapQuestShowObjectives.Show
		local WorldMapTitleButtonShow = WorldMapTitleButton.Show
		local WorldMapBlobFrameShow = WorldMapBlobFrame.Show
		local WorldMapPOIFrameShow = WorldMapPOIFrame.Show
			
		local taintMeNot = function(self, event)
			local miniWorldMap = GetCVarBool("miniWorldMap")
			local quest = WorldMapQuestShowObjectives:GetChecked()

			if (event == "PLAYER_ENTERING_WORLD") then
				if not(miniWorldMap) then
					ToggleFrame(WorldMapFrame)
					ToggleFrame(WorldMapFrame)
				end
				
			elseif (event == "PLAYER_REGEN_DISABLED") then
				WorldMapFrameSizeDownButton:Disable()
				WorldMapFrameSizeUpButton:Disable()
				
				if (quest) then
					if WorldMapFrame:IsShown() then
						HideUIPanel(WorldMapFrame)
					end

					if not(miniWorldMap) and (WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE) then
						WorldMapFrame_SetFullMapView()
					end

					WatchFrame.showObjectives = nil
					WorldMapTitleButton:Hide()
					WorldMapBlobFrame:Hide()
					WorldMapPOIFrame:Hide()

					WorldMapQuestShowObjectives.Show = gUI.noop
					WorldMapTitleButton.Show = gUI.noop
					WorldMapBlobFrame.Show = gUI.noop
					WorldMapPOIFrame.Show = gUI.noop

					WatchFrame_Update()
				end
				WorldMapQuestShowObjectives:Hide()
				
			elseif (event == "PLAYER_REGEN_ENABLED") then
				WorldMapFrameSizeDownButton:Enable()
				WorldMapFrameSizeUpButton:Enable()
				
				if (quest) then
					WorldMapQuestShowObjectives.Show = WorldMapQuestShowObjectivesShow
					WorldMapTitleButton.Show = WorldMapTitleButtonShow
					WorldMapBlobFrame.Show = WorldMapBlobFrameShow
					WorldMapPOIFrame.Show = WorldMapPOIFrameShow

					WorldMapTitleButton:Show()

					WatchFrame.showObjectives = true

					if not(miniWorldMap) and (WORLDMAP_SETTINGS.size == WORLDMAP_FULLMAP_SIZE) then
						WorldMapFrame_SetFullMapView()
					end

					WorldMapBlobFrame:Show()
					WorldMapPOIFrame:Show()

					WatchFrame_Update()
					
					if not(miniWorldMap) and (WorldMapFrame:IsShown()) and (WORLDMAP_SETTINGS.size == WORLDMAP_FULLMAP_SIZE) then
						HideUIPanel(WorldMapFrame)
						ShowUIPanel(WorldMapFrame)
					end
				end
				WorldMapQuestShowObjectives:Show()
			end
		end
		WorldMapFrame:HookScript("OnEvent", taintMeNot)
		WorldMapFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		WorldMapFrame:RegisterEvent("PLAYER_REGEN_ENABLED") 
		WorldMapFrame:RegisterEvent("PLAYER_REGEN_DISABLED") 
	end
end

gUI.FixBlizzardBugs = function(self)
	local wow_version, wow_build, wow_data, tocversion = GetBuildInfo()
	wow_build = tonumber(wow_build)

	-- Fix incorrect translations in the German Locale.  For whatever reason
	-- Blizzard changed the oneletter time abbreviations to be 3 letter in
	-- the German Locale.
	if GetLocale() == "deDE" then
		-- This one confirmed still bugged as of Mists of Pandaria build 16030
		DAY_ONELETTER_ABBR = "%d d"
	end

	-- fixes the issue with InterfaceOptionsFrame_OpenToCategory not actually opening the Category (and not even scrolling to it)
	-- Confirmed still broken in Mists of Pandaria as of build 17538 (5.4.1)
	do
		local function get_panel_name(panel)
			local tp = type(panel)
			local cat = INTERFACEOPTIONS_ADDONCATEGORIES
			if tp == "string" then
				for i = 1, #cat do
					local p = cat[i]
					if p.name == panel then
						if p.parent then
							return get_panel_name(p.parent)
						else
							return panel
						end
					end
				end
			elseif tp == "table" then
				for i = 1, #cat do
					local p = cat[i]
					if p == panel then
						if p.parent then
							return get_panel_name(p.parent)
						else
							return panel.name
						end
					end
				end
			end
		end

		local function InterfaceOptionsFrame_OpenToCategory_Fix(panel)
			if doNotRun or InCombatLockdown() then return end
			local panelName = get_panel_name(panel)
			if not panelName then return end -- if its not part of our list return early
			local noncollapsedHeaders = {}
			local shownpanels = 0
			local mypanel
			local t = {}
			local cat = INTERFACEOPTIONS_ADDONCATEGORIES
			for i = 1, #cat do
				local panel = cat[i]
				if not panel.parent or noncollapsedHeaders[panel.parent] then
					if panel.name == panelName then
						panel.collapsed = true
						t.element = panel
						InterfaceOptionsListButton_ToggleSubCategories(t)
						noncollapsedHeaders[panel.name] = true
						mypanel = shownpanels + 1
					end
					if not panel.collapsed then
						noncollapsedHeaders[panel.name] = true
					end
					shownpanels = shownpanels + 1
				end
			end
			local Smin, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
			if shownpanels > 15 and Smin < Smax then 
			  local val = (Smax/(shownpanels-15))*(mypanel-2)
			  InterfaceOptionsFrameAddOnsListScrollBar:SetValue(val)
			end
			doNotRun = true
			InterfaceOptionsFrame_OpenToCategory(panel)
			doNotRun = false
		end

		hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", InterfaceOptionsFrame_OpenToCategory_Fix)
	end

	-- Avoid taint from the UIFrameFlash usage of the chat frames.  More info here:
	-- http://forums.wowace.com/showthread.php?p=324936

	-- Fixed by embedding LibChatAnims


	-- Fix an issue where the PetJournal drag buttons cannot be clicked to link a pet into chat
	-- The necessary code is already present, but the buttons are not registered for the correct click
	-- Confirmed still broken in Mists of Pandaria as of build 17538 (5.4.1)
	if true then
			local frame = CreateFrame("Frame")
			frame:RegisterEvent("ADDON_LOADED")
			frame:SetScript("OnEvent", function(self, event, name)
					if event == "ADDON_LOADED" and name == "Blizzard_PetJournal" then
				for i=1,3 do
					local d = _G["PetJournalLoadoutPet"..i]
					d = d and d.dragButton
					if d then d:RegisterForClicks("LeftButtonUp") end
				end
					end
			end)
	end

	--
	-- missing currency tab button in the character frame 
	-- 
	-- the currency tab gets hidden when it shouldn't sometimes,
	-- because the TokenUI fails to retrieve the list of your available currencies.
	-- let's remedy this by forcing an update, much later in the startup process than
	-- when the blizzard addons are started. 
	if (wow_build >= 16016) then
		local fixTokens
		fixTokens = function(self, event, ...)
			self:UnregisterEvent(event, fixTokens)
			TokenFrame_LoadUI()
			TokenFrame_Update()
		end
		gUI:RegisterEvent("PLAYER_ENTERING_WORLD", fixTokens)
		gUI:RegisterEvent("PLAYER_ALIVE", fixTokens)
	end
	
end

gUI.PostUpdateSettings = function(self)

end

gUI.CleanUp = function(self)

end

gUI.OnInit = function(self)
	db = self:InitializeCurrentOptionsSet(self:GetAttribute("savedvariablesglobal"), defaults) -- get the settings for the root addon on this char
	self:CleanUp() -- fix deprecated settings and stuff

	--------------------------------------------------------------------------------------------------
	--		chat commands #1 (don't require gUI to be active)
	--------------------------------------------------------------------------------------------------
	self:CreateChatCommand("fixlog", CombatLogClearEntries)
	self:CreateChatCommand("leaveparty", LeaveParty)
	self:CreateChatCommand("rc", DoReadyCheck)
	self:CreateChatCommand("rl", ReloadUI)
	self:CreateChatCommand("gm", ToggleHelpFrame)
	self:CreateChatCommand({"release", "repop"}, RepopMe)

	self:CreateChatCommand("enablegui", function()
		db.temporaryDisabled = false
		ReloadUI()
	end)

	self:CreateChatCommand("disablegui", function()
		db.temporaryDisabled = true
		ReloadUI()
	end)

	self:CreateChatCommand({"spec1", "mainspec"}, function() 
		if (GetNumSpecGroups() == 1) then return end
		if (GetActiveSpecGroup() ~= 1) then 
			gUI:RaidWarning(L["Activating Primary Specialization"])
			SetActiveSpecGroup(1) 
		end
	end)

	self:CreateChatCommand({"spec2", "offspec"}, function() 
		if (GetNumSpecGroups() == 1) then return end
		if (GetActiveSpecGroup() ~= 2) then 
			gUI:RaidWarning(L["Activating Secondary Specialization"])
			SetActiveSpecGroup(2) 
		end
	end)

	self:CreateChatCommand("togglespec", function()
		if (GetNumSpecGroups() == 1) then return end
		if (GetActiveSpecGroup() == 1) then
			gUI:RaidWarning(L["Activating Secondary Specialization"])
			SetActiveSpecGroup(2)
		else
			gUI:RaidWarning(L["Activating Primary Specialization"])
			SetActiveSpecGroup(1)
		end
	end)

	-- bail out if the UI is disabled
	if (db.temporaryDisabled) then
		print(self:GetEnvironment()["%s has been temporarily disabled. Type /enablegui to enable it."]:format(self:GetAttribute("title")))
		self:Kill()
		return 
	end
	
	--------------------------------------------------------------------------------------------------
	--		vehicle and pet battle hiding
	--------------------------------------------------------------------------------------------------
	self:GetAttribute("parent"):SetFrameStrata("BACKGROUND")
	self:GetAttribute("vehiclehider"):SetFrameStrata("BACKGROUND")
	RegisterStateDriver(self:GetAttribute("parent"), "visibility", "[petbattle] hide; show")
	RegisterStateDriver(self:GetAttribute("combathider"), "visibility", "[combat] hide; show")
	RegisterStateDriver(self:GetAttribute("vehiclehider"), "visibility", "[vehicleui][possessbar][overridebar] hide; show")

	--------------------------------------------------------------------------------------------------
	--		non-optional modules
	--------------------------------------------------------------------------------------------------
	self:GetModule("Media"):Init() -- media library
	self:GetModule("Colors"):Init() -- color database
	self:GetModule("Tags"):Init() -- string tags
	self:GetModule("Functions"):Init() -- 'global' functions
	self:GetModule("API"):Init() -- gUIs skinning & styling API
	
	L, C, F, M = self:GetEnvironment() -- all databases are ready after this point
	
	self:FixBlizzardBugs() -- work around known bugs until Blizzard fix them
	-- self:WarOnTaint() -- the war against taint rages on
	
	--------------------------------------------------------------------------------------------------
	-- 	submodule display names
	--------------------------------------------------------------------------------------------------
	moduleDisplayName["Actionbars"] = L["ActionBars"]
	moduleDisplayName["Auras"] = L["Auras"]
	moduleDisplayName["Bags"] = L["Bags"]
	moduleDisplayName["Castbars"] = L["Castbars"]
	moduleDisplayName["Chat"] = L["Chat"]
	moduleDisplayName["CombatLogs"] = L["CombatLogs"]
	moduleDisplayName["DeveloperTools"] = L["Developer Tools"]
	moduleDisplayName["Fonts"] = L["Fonts"]
	moduleDisplayName["Loot"] = L["Loot"]
	moduleDisplayName["Map"] = L["Map"]
	moduleDisplayName["Merchant"] = L["Merchants"]
	moduleDisplayName["Minimap"] = L["Minimap"]
	moduleDisplayName["Nameplates"] = L["Nameplates"]
	moduleDisplayName["Panels"] = L["Panels & Backdrops"]
	-- moduleDisplayName["Styling"] = L["Skins"]
	moduleDisplayName["Tooltips"] = L["Tooltips"]
	moduleDisplayName["Unitframes"] = L["UnitFrames"]

	--------------------------------------------------------------------------------------------------
	--		gFrameHandler
	--------------------------------------------------------------------------------------------------
	-- localize it
	-- star class sucky coding
	local gFH = LibStub("gFrameHandler-2.0")
	for key,locale in pairs(gFH:GetLocale()) do
		if (L[key]) then -- this will fire off a non-breaking error if unknown...
			gFH:GetLocale()[key] = L[key]
		end
	end
	
	-- set up frame groups for /glock coloring (TODO: localize)
	self:RegisterFrameGroup("unitframes", 1, 0.5, 0.1, gUI_TextFontNormalBoldOutlineWhite, L["Unitframes"], L["Frames like the player, target, raid, focus, pet etc"])
	self:RegisterFrameGroup("actionbars", 0.5, 1, 0.5, gUI_TextFontNormalBoldOutlineWhite, L["Actionbars"], L["Frames containing shortcut buttons to abilities, macros etc"])
	self:RegisterFrameGroup("uipanels", 0.5, 0.5, 1, gUI_TextFontNormalBoldOutlineWhite, L["Panels"], L["Various UI panels providing information, |rincluding the minimap and bottom left and right infopanels"]) 
	self:RegisterFrameGroup("floaters", 1, 1, 0.5, gUI_TextFontNormalBoldOutlineWhite, L["Floaters"], L["Various uncategorized elements like the objective tracker, |rthe durability frame, the vehicle seat indicator etc"])
	self:RegisterFrameGroup("buffs", 1, 0.5, 1, gUI_TextFontNormalBoldOutlineWhite, L["Auras"], L["Your buffs and debuffs"]) 
	self:RegisterFrameGroup("castbars", 1, 0.5, 0.5, gUI_TextFontNormalBoldOutlineWhite, L["Castbars"], L["Unit castbars, mirror timers, BG timers, etc"]) 

	--------------------------------------------------------------------------------------------------
	--		optionsmenu
	--------------------------------------------------------------------------------------------------
	local gOM = LibStub("gOptionsMenu-1.0")
	for key,locale in pairs(gOM:GetLocale()) do
		if (L[key]) then -- this will fire off a non-breaking error if unknown...
			gOM:GetLocale()[key] = L[key]
		end
	end

	-- disable blizzard menus and stuff
	self:KillOption(true, Advanced_UseUIScale)
	self:KillOption(true, Advanced_UIScaleSlider)
	
	local menuTable = {
		{
			type = "group";
			name = gUI:GetName();
			order = 1;
			virtual = true;
			children = {
				{
					type = "widget";
					element = "Title";
					order = 1;
					msg = L["General"];
				};
				{ -- blizzard settings
					type = "group";
					order = 5;
					virtual = true;
					children = {
						{
							type = "widget";
							element = "Header";
							order = 1;
							msg = L["UI Scale"];
						};
						{
							type = "widget";
							element = "CheckButton";
							order = 5;
							msg = L["Use UI Scale"];
							desc = { L["UI Scale"], L["Check to use the UI Scale Slider, uncheck to use the system default scale."], " ", F.warning(L["Using custom UI scaling is not recommended. It will produce fuzzy borders and incorrectly sized objects."]) };
							set = function(self) 
								if not(self:GetChecked()) then
									SetCVar("useUiScale", 0)
									self.parent.child.uiSlider:Disable()
									
								else
									SetCVar("useUiScale", 1)
									self.parent.child.uiSlider:Enable()
								end
							end;
							get = function() return (tonumber(GetCVar("useUiScale")) == 1) end;
							init = function(self) 
								gUI:RegisterEvent("PLAYER_ENTERING_WORLD", function() 
									self:SetChecked(tonumber(GetCVar("useUiScale")) == 1)
								end)
							end;
						};
						{
							type = "widget";
							element = "Slider";
							name = "uiSlider";
							order = 10;
							width = "minimum";
							msg = nil;
							desc = { L["UI Scale"], L["Changes the size of the game’s user interface."], " ", F.warning(L["Using custom UI scaling is not recommended. It will produce fuzzy borders and incorrectly sized objects."]) };
							set = function(self, value) 
								if not(self.parent.child.applyButton:IsEnabled()) then
									self.parent.child.applyButton:Enable()
								end
								
								self.text:SetText(("%.2f"):format(value))
							end;
							get = function(self)
								return tonumber(GetCVar("uiScale"))
							end;
							ondisable = function(self)
								self:SetAlpha(3/4)
								self.low:SetTextColor(unpack(C["disabled"]))
								self.high:SetTextColor(unpack(C["disabled"]))
								self.text:SetTextColor(unpack(C["disabled"]))
								
								self:EnableMouse(false)

								if (self.parent.child.applyButton:IsEnabled()) then
									self.parent.child.applyButton:Disable()
								end
							end;
							onenable = function(self)
								self:SetAlpha(1)
								self.low:SetTextColor(unpack(C["value"]))
								self.high:SetTextColor(unpack(C["value"]))
								self.text:SetTextColor(unpack(C["index"]))
								
								self:EnableMouse(true)

								if (self:GetValue() ~= tonumber(GetCVar("useUiScale"))) then
									if not(self.parent.child.applyButton:IsEnabled()) then
										self.parent.child.applyButton:Enable()
									end
								end
							end;
							init = function(self)
								if (tonumber(GetCVar("useUiScale")) ~= 1) then
									self:Disable()
								end
								
								local min, max, value = 0.64, 1, self:get()
								self:SetMinMaxValues(min, max)
								self.low:SetText(min)
								self.high:SetText(max)

								if (value) then
									self:SetValue(value)
									self.text:SetText(("%.2f"):format(value))
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								else
									local self = self
									local update
									update = function() 
										local min, max, value = 0.64, 1, self:get()
										self:SetMinMaxValues(min, max)
										self:SetValue(value) 
										self.text:SetText(("%.2f"):format(value))
										if (self:IsEnabled()) then
											self:onenable()
										else
											self:ondisable()
										end
										gUI:UnregisterEvent("PLAYER_ENTERING_WORLD", update)
									end
									gUI:RegisterEvent("PLAYER_ENTERING_WORLD", update)
								end
							end;
						};
						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 100;
							msg = L["Apply"];
							desc = { L["Apply the new UI scale."], " ", F.warning(L["Using custom UI scaling is not recommended. It will produce fuzzy borders and incorrectly sized objects."]) };
							set = function(self)
								SetCVar("uiScale", self.parent.child.uiSlider:GetValue())
								--RestartGx()
							end;
							get = noop;
							init = function(self)
								if (tonumber(GetCVar("useUiScale")) ~= 1) then
									self:Disable()
								end
							end;
						};
					};
				};
				{ -- global styling
					type = "group";
					order = 10;
					virtual = true;
					children = {
						{
							type = "widget";
							element = "Header";
							order = 1;
							msg = L["Global Styles"];
						};
						{
							type = "widget";
							element = "Header";
							order = 5;
							indented = true;
							width = "full";
							msg = L["Backdrop Opacity"];
						};
						{ -- bar width
							type = "widget";
							element = "Slider";
							name = "panelAlpha";
							order = 10;
							width = "half";
							min = 0.6;
							max = 1.0;
							step = 0.01;
							string = "%.2f";
							msg = nil;
							desc = { L["Backdrop Opacity"], L["Set the level of transparency for all backdrops"] };
							set = function(self, value) 
								if (value) then
									self.text:SetText((self.string):format(value))
									gUI:SetPanelAlpha(tonumber(value))
								end
							end;
							get = function(self) return gUI:GetPanelAlpha() end;
						};
					};
				};
				{ -- module selection
					type = "group";
					order = 20;
					virtual = true;
					children = {
						{
							type = "widget";
							element = "Title";
							order = 1;
							msg = L["Module Selection"]; 
						};
						{
							type = "widget";
							element = "Text";
							order = 5;
							msg = L["Choose which modules that should be loaded"] .. " - " .. F.warning(L["Requires the UI to be reloaded!"]);
						};
						
						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 9;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Actionbars"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Actionbars"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 10;
							width = "last";
							msg = L["ActionBars"];
							set = function(self) 
								db.enabledModules["Actionbars"] = not(db.enabledModules["Actionbars"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Actionbars"] end;
						};
						
						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 19;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Auras"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Auras"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 20;
							width = "last";
							msg = L["Auras"];
							set = function(self) 
								db.enabledModules["Auras"] = not(db.enabledModules["Auras"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Auras"] end;
						};

						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 29;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Bags"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Bags"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 30;
							width = "last";
							msg = L["Bags"];
							set = function(self) 
								db.enabledModules["Bags"] = not(db.enabledModules["Bags"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Bags"] end;
						};

						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 39;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Castbars"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Castbars"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 40;
							width = "last";
							msg = L["Castbars"];
							set = function(self) 
								db.enabledModules["Castbars"] = not(db.enabledModules["Castbars"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Castbars"] end;
						};

						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 49;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Chat"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Chat"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 50;
							width = "last";
							msg = L["Chat"];
							set = function(self) 
								db.enabledModules["Chat"] = not(db.enabledModules["Chat"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Chat"] end;
						};

						-- {
							-- type = "widget";
							-- element = "Button";
							-- name = "applyButton";
							-- width = "minimum";
							-- order = 9;
							-- msg = L["Settings"];
							-- desc = { L["Adjust the settings for this module"] };
							-- set = function(self)
								-- gUI:GetModule("CombatLogs"):OpenToBlizzardOptionsMenu() 
							-- end;
							-- get = noop;
							-- init = function(self)
								-- if (db.enabledModules["CombatLogs"]) then
									-- self:Enable()
								-- else
									-- self:Disable()
								-- end
							-- end;
						-- };						
						-- {
							-- type = "widget";
							-- element = "CheckButton";
							-- order = 60;
							-- width = "last";
							-- msg = L["CombatLog"];
							-- set = function(self) 
								-- db.enabledModules["CombatLogs"] = not(db.enabledModules["CombatLogs"])
								-- F.ScheduleRestart()
							-- end;
							-- get = function() return db.enabledModules["CombatLogs"] end;
						-- };

						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 69;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Minimap"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Minimap"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 70;
							width = "last";
							msg = L["Minimap"];
							set = function(self) 
								db.enabledModules["Minimap"] = not(db.enabledModules["Minimap"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Minimap"] end;
						};

						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 79;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Nameplates"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Nameplates"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 80;
							width = "last";
							msg = L["Nameplates"];
							set = function(self) 
								db.enabledModules["Nameplates"] = not(db.enabledModules["Nameplates"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Nameplates"] end;
						};

						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 89;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Tooltips"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Tooltips"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 90;
							width = "last";
							msg = L["Tooltips"];
							set = function(self) 
								db.enabledModules["Tooltips"] = not(db.enabledModules["Tooltips"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Tooltips"] end;
						};

						{
							type = "widget";
							element = "Button";
							name = "applyButton";
							width = "minimum";
							order = 99;
							msg = L["Settings"];
							desc = { L["Adjust the settings for this module"] };
							set = function(self)
								gUI:GetModule("Unitframes"):OpenToBlizzardOptionsMenu() 
							end;
							get = noop;
							init = function(self)
								if (db.enabledModules["Unitframes"]) then
									self:Enable()
								else
									self:Disable()
								end
							end;
						};						
						{
							type = "widget";
							element = "CheckButton";
							order = 100;
							width = "last";
							msg = L["UnitFrames"];
							set = function(self) 
								db.enabledModules["Unitframes"] = not(db.enabledModules["Unitframes"])
								F.ScheduleRestart()
							end;
							get = function() return db.enabledModules["Unitframes"] end;
						};

					};
				};
			};
		};
	}
	
	-- we need to iterate through the modules here
	local restoreDefaults = function()
		if (InCombatLockdown()) then 
			print(L["Can not apply default settings while engaged in combat."])
			return
		end
		
		-- reset our own options
		self:ResetCurrentOptionsSetToDefaults()

		-- iterate all our children for common reset functions
		for name, child in self:IterateModules() do
			if (child.RestoreDefaults) then
				child:RestoreDefaults()
			elseif (child.ResetCurrentOptionsSetToDefaults) then
				child:ResetCurrentOptionsSetToDefaults()
			end
		end
		
		-- request a restart if one of the modules need it
		F.RestartIfScheduled()
	end
	self:RegisterAsBlizzardOptionsMenu(menuTable, gUI:GetAttribute("title"), "default", restoreDefaults)
	
	-- hook the restart check to the hiding of the menu frame
	InterfaceOptionsFrame:HookScript("OnHide", function() F.RestartIfScheduled() end)
	
	-- add a button to the game menu 
	-- F.AddGameMenuButton("GUISOptions", gUI:GetAttribute("title"), function() self:OpenToBlizzardOptionsMenu() end)

	--------------------------------------------------------------------------------------------------
	--		chat commands #2 (require gUI to be active)
	--------------------------------------------------------------------------------------------------
	self:CreateChatCommand("install", function() 
		PlaySound("igMainMenuOption")
		securecall("CloseAllWindows")
		gUI:InstallAll()
	end)

	self:CreateChatCommand("resetinstalltutorial", function() 
		db.initialized = nil
		ReloadUI()
	end)

	local glock = function(group)
		if (InCombatLockdown()) then 
			gUI:UIErrorMessage(L["Frames cannot be moved while engaged in combat"], C["error"][1], C["error"][2], C["error"][3])
			return 
		end
		
		-- if an invalid group is specified, just toggle all locks,
		-- no need to fire off errors for this chat command
		if (group) and (gUI:FrameGroupExist(group)) then
			gUI:ToggleObjectPositionLock(group)
		else
			gUI:ToggleObjectPositionLock()
		end
	end
	self:CreateChatCommand("glock", glock)
	_G.GUIS_ToggleMovableFrames = glock -- globals for keybind functionality

	self:CreateChatCommand("gui", function() 
		gUI:OpenToBlizzardOptionsMenu() 
	end)

	--------------------------------------------------------------------------------------------------
	--		localized keybind display text
	--------------------------------------------------------------------------------------------------
	-- general
	_G["BINDING_HEADER_GUISKEYBINDSMAIN"] = gUI:GetAttribute("title") .. " " .. (gUI:GetAttribute("curseversion") or gUI:GetAttribute("version")) or ""
	_G["BINDING_NAME_GUISRELOADUI"] = L["Reload the user interface"] 
	_G["BINDING_NAME_GUISTOGGLECALENDAR"] = L["Toggle Calendar"]
	_G["BINDING_NAME_GUISTOGGLECUSTOMERSUPPORT"] = L["Blizzard Customer Support"] 
	_G["BINDING_NAME_GUISTOGGLEMOVABLEFRAMES"] = L["Toggle movable frames"]
	_G["BINDING_NAME_GUISTOGGLEKEYBINDMODE"] = L["Toggle hover keybind mode"]

	-- actionbars
	-- _G["BINDING_NAME_GUISEXITVEHICLE"] = BINDING_NAME_VEHICLEEXIT

	-- chat
	_G["BINDING_NAME_GUISTELLTARGET"] = L["Whisper target"]
	_G["BINDING_NAME_GUISTELLFOCUS"] = L["Whisper focus"]

	-- talentframe anti-taint keybind
	-- _G["BINDING_NAME_GUISSHOWTALENTS"] = L["Show Talent Pane"]

	-- fixes or additions to other 3rd party addons (meaning not mine)
	_G["BINDING_HEADER_GUIS3RDPARTYBINDS"] = gUI:GetAttribute("title") .. " - " .. L["Additional Keybinds"]
	_G["BINDING_NAME_GUISTSMFIX505"] = L["TSM Post/Cancel"] -- my TSM macro, it seems to be gone from the addon ..?

	--------------------------------------------------------------------------------------------------
	--		popup windows
	--------------------------------------------------------------------------------------------------
	StaticPopupDialogs["GUIS_RESTART_REQUIRED_FOR_CHANGES"] = {
		text = L["The user interface needs to be reloaded for the changes to take effect. Do you wish to reload it now?"],
		button1 = L["Yes"],
		button2 = L["No"],
		OnAccept = function() ReloadUI() end,
		OnCancel = function() F.CancelRestart() end,
		exclusive = 1,
		hideOnEscape = 0,
		showAlert = 1,
		timeout = 0,
		whileDead = 1,
		preferredIndex = STATICPOPUP_NUMDIALOGS
	}

	StaticPopupDialogs["GUI_QUERY_INSTALL"] = {
		text = L["This is the first time you're running %s on this character. Would you like to run the install tutorial now?"]:format(gUI:GetAttribute("title")),
		button1 = L["Yes"],
		button2 = L["No"],
		OnAccept = function() 
			db.initialized = true
			PlaySound("igMainMenuOption")
			securecall("CloseAllWindows")
			F.FullScreenFadeIn()
			gUI:InstallAll()
		end,
		OnCancel = function() 
			db.initialized = false
			PlaySound("igMainMenuOption")
			HideUIPanel(_G["GameMenuFrame"])
			F.FullScreenFadeIn()
			print(L["Setup aborted. Type |cFF4488FF/install|r to restart the tutorial."])
		end,
		exclusive = 1,
		hideOnEscape = 0,
		showAlert = 1,
		timeout = 0,
		whileDead = 1,
		preferredIndex = STATICPOPUP_NUMDIALOGS
	}
	
	self:PostUpdateSettings() -- initial update of elements according to saved settings

	-- floaters, panels, etc. 
	-- this must be done before module initialization, 
	-- as some of these create needed additional gUI functionality
	CreateFloaters()
	
	self:GetModule("Styling"):Init() -- UI styling

	-- init modules according to settings
	local module
	for name, enabled in pairs(db.enabledModules) do
		if (enabled) then
			module = self:GetModule(name, true) 
			if (module) then
				local enable = true
				if (autoDisable[name]) then
					for addon, disable in pairs(autoDisable[name]) do
						if (IsAddOnLoaded(addon)) then
							enable = nil
							break
						end
					end
				end
				if (enable) then 
					module:Init()
				end
			end
		end
	end
end

gUI.OnEnable = function(self)
	db.gold = GetMoney() -- retrieve current gold on login

	-- fix the objectives tracker height, make it larger for larger screens!
	if (GUIS_ObjectiveTracker) then
		GUIS_ObjectiveTracker:SetHeight(400 + max(0, GetScreenHeight() - 850))
	end

	-- enable modules according to settings
	local module
	for name, enabled in pairs(db.enabledModules) do
		if (enabled) then
			module = self:GetModule(name, true) 
			if (module) then
				local enable = true
				if (autoDisable[name]) then
					for addon, disable in pairs(autoDisable[name]) do
						if (IsAddOnLoaded(addon)) then
							print(L["The '%s' module was disabled due to the addon '%s' being loaded."]:format(self:GetModuleName(name), addon))
							enable = nil
							break
						end
					end
				end
				if (enable) then					
					module:Enable()
				end
			end
		end
	end
	
	-- decide if the install query should be shown, and when
	-- local queryInstall = function() 
		-- F.FullScreenFadeOut()
		-- StaticPopup_Show("GUI_QUERY_INSTALL")
	-- end
	-- local queueQuery = function() self:ScheduleTimer(5, queryInstall) end
	
	-- local v, s, b = F.GetVersion()
	-- local version = tonumber(tostring(v) .. "." .. tostring(s) or "0") 
	
	-- if (TEST_MODE) or not(db.initialized) or (db.version < version) or (db.build < b) then
		-- if (InCinematic()) then
			-- self:RegisterEvent("CINEMATIC_STOP", queueQuery)
		-- else
			-- queueQuery(15)
		-- end
	-- end

	-- enable integrated modules
	self:EnableErrorFilter()
	
	-- annoying welcome message
	print(L["%s loaded and ready"]:format(self:GetAttribute("title")))
	print(L["|cFF4488FF/glock|r to activate config mode"])
	print(L["|cFF4488FF/bind|r to activate binding mode"])
	print(L["|cFF4488FF/gui|r for additional options"])
end

gUI.OnDisable = function(self)
	db.gold = GetMoney() -- store current gold on logout
end

if not(_G.gUI) then
	_G.gUI = gUI
end