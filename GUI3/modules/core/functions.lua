--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Functions")

module.OnInit = function(self)
	local db = gUI:GetCurrentOptionsSet()
	local L, C, F, M = gUI:GetEnvironment()
	
	local modf = math.modf
	local tinsert = table.insert
	local tconcat = table.concat
	local tonumber = tonumber
	local tremove = table.remove
	local unpack = unpack
	local select = select
	local setmetatable = setmetatable
	
	local BNGetFriendInfo = BNGetFriendInfo
	local BNGetNumFriends = BNGetNumFriends
	local BNGetToonInfo = BNGetToonInfo
	local GetAddOnMetadata = GetAddOnMetadata
	local GetBuildInfo = GetBuildInfo
	local GetFriendInfo = GetFriendInfo
	local GetGuildRosterInfo = GetGuildRosterInfo
	local GetItemQualityColor = GetItemQualityColor
	local GetNumFriends = GetNumFriends
	local GetNumGuildMembers = GetNumGuildMembers
	local GetNumWorldPVPAreas = GetNumWorldPVPAreas
	local GetQuestDifficultyColor = GetQuestDifficultyColor
	local GetRealZoneText = GetRealZoneText
	local GetScreenWidth = GetScreenWidth
	local GetSpecialization = GetSpecialization
	local GetSpecializationRole = GetSpecializationRole
	local GetWorldPVPAreaInfo = GetWorldPVPAreaInfo
	local IsInInstance = IsInInstance
	local strsplit = strsplit
	local UIFrameFade = UIFrameFade
	local UIFrameFadeIn = UIFrameFadeIn
	local UIFrameFadeRemoveFrame = UIFrameFadeRemoveFrame
	local UIFrameIsFading = UIFrameIsFading

	local localizedClass, class = UnitClass("player")
	
	--------------------------------------------------------------------------------------------------
	--		Chat Icons
	--------------------------------------------------------------------------------------------------
	local E = gUI:GetDataBase("emoticons")

	-- have to insert them in a specific order, or emoticons won't be detected correctly.
	-- 	e.g. :( will be detected, but not >:(
	--		* simple rule; the most advanced first, the simple ones at the end

	-- these need to come first
	tinsert(E, { "O:%-%)", M("Icon", "Emoticon: Angel")})
	tinsert(E, { "O:%)", M("Icon", "Emoticon: Angel")})
	tinsert(E, { "3:%)", M("Icon", "Emoticon: Devil")})
	tinsert(E, { "3:%-%)", M("Icon", "Emoticon: Devil")})
	tinsert(E, { ">:%(", M("Icon", "Emoticon: Grumpy")})
	tinsert(E, { ">:%-%(", M("Icon", "Emoticon: Grumpy")})
	tinsert(E, { ">:o", M("Icon", "Emoticon: Upset")})
	tinsert(E, { ">:%-o", M("Icon", "Emoticon: Upset")})
	tinsert(E, { ">:O", M("Icon", "Emoticon: Upset")})
	tinsert(E, { ">:%-O", M("Icon", "Emoticon: Upset")})

	-- these last
	tinsert(E, { "O%.o", M("Icon", "Emoticon: Confused")})
	tinsert(E, { "o%.O", M("Icon", "Emoticon: Confused")})
	tinsert(E, { ":'%(", M("Icon", "Emoticon: Cry")})
	tinsert(E, { ":%(", M("Icon", "Emoticon: Frown")})
	tinsert(E, { ":%-%(", M("Icon", "Emoticon: Frown")})
	--tinsert(E, { ":%[", M("Icon", "Emoticon: Frown")}) -- this messes with player links sometimes
	tinsert(E, { "=%(", M("Icon", "Emoticon: Frown")})
	tinsert(E, { ":%-O", M("Icon", "Emoticon: Gasp")})
	tinsert(E, { ":O", M("Icon", "Emoticon: Gasp")})
	tinsert(E, { ":%-o", M("Icon", "Emoticon: Gasp")})
	tinsert(E, { ":o", M("Icon", "Emoticon: Gasp")})
	tinsert(E, { "8%)", M("Icon", "Emoticon: Glasses")})
	tinsert(E, { "8%-%)", M("Icon", "Emoticon: Glasses")})
	tinsert(E, { "B%)", M("Icon", "Emoticon: Glasses")})
	tinsert(E, { "B%-%)", M("Icon", "Emoticon: Glasses")})
	tinsert(E, { ":D", M("Icon", "Emoticon: Grin")})
	tinsert(E, { ":%-D", M("Icon", "Emoticon: Grin")})
	tinsert(E, { "=D", M("Icon", "Emoticon: Grin")})
	tinsert(E, { "<3", M("Icon", "Emoticon: Heart")})
	tinsert(E, { "%^_%^", M("Icon", "Emoticon: Kiki")})
	tinsert(E, { ":%*", M("Icon", "Emoticon: Kiss")})
	tinsert(E, { ":%-%*", M("Icon", "Emoticon: Kiss")})
	tinsert(E, { ":%)", M("Icon", "Emoticon: Smile")})
	tinsert(E, { ":%-%)", M("Icon", "Emoticon: Smile")})
	--tinsert(E, { ":%]", M("Icon", "Emoticon: Smile")}) -- links can be messed up by this
	tinsert(E, { "=%)", M("Icon", "Emoticon: Smile")})
	tinsert(E, { "%-_%-", M("Icon", "Emoticon: Squint")})
	tinsert(E, { "8||", M("Icon", "Emoticon: Sunglasses")})
	tinsert(E, { "8%-||", M("Icon", "Emoticon: Sunglasses")})
	tinsert(E, { "B||", M("Icon", "Emoticon: Sunglasses")})
	tinsert(E, { "B%-||", M("Icon", "Emoticon: Sunglasses")})
	tinsert(E, { ":p", M("Icon", "Emoticon: Tongue")})
	tinsert(E, { ":%-P", M("Icon", "Emoticon: Tongue")})
	tinsert(E, { ":P", M("Icon", "Emoticon: Tongue")})
	tinsert(E, { ":%-p", M("Icon", "Emoticon: Tongue")})
	tinsert(E, { "=P", M("Icon", "Emoticon: Tongue")})
	-- tinsert(E, { "[^https]:%/", M("Icon", "Emoticon: Unsure")})
	-- tinsert(E, { "[^http]:%/", M("Icon", "Emoticon: Unsure")})
	-- tinsert(E, { "[^ftp]:%/", M("Icon", "Emoticon: Unsure")})
	tinsert(E, { ":%-%/", M("Icon", "Emoticon: Unsure")})
	-- tinsert(E, { "[^file]:%\\", M("Icon", "Emoticon: Unsure")})
	tinsert(E, { ":%-%\\", M("Icon", "Emoticon: Unsure")})
	tinsert(E, { ";%)", M("Icon", "Emoticon: Wink")})
	tinsert(E, { ";%-%)", M("Icon", "Emoticon: Wink")})

	-- friz quadrata smilies
	tinsert(E, { "☺", M("Icon", "Emoticon: Smile")})
	tinsert(E, { "☻", M("Icon", "Emoticon: Gasp")})

	-- arrows
	tinsert(E, { "←", M("Button", "gUI™ ArrowLeft")})
	tinsert(E, { "<%-", M("Button", "gUI™ ArrowLeft")})
	tinsert(E, { "<<", M("Button", "gUI™ ArrowLeft")})
	tinsert(E, { "→", M("Button", "gUI™ ArrowRight")})
	tinsert(E, { "%->", M("Button", "gUI™ ArrowRight")})
	tinsert(E, { ">>", M("Button", "gUI™ ArrowRight")})
	tinsert(E, { "↑", M("Button", "gUI™ ArrowUp")})
	tinsert(E, { "%(^%)", M("Button", "gUI™ ArrowUp")})
	tinsert(E, { "↓", M("Button", "gUI™ ArrowDown")})
	tinsert(E, { "%(v%)", M("Button", "gUI™ ArrowDown")})
	
	-- convert the table for faster texture conversion
	for i = 1, #E do
		E[E[i][1]] = E[i][2]
	end

	F.EmoticonToTexture = function(msg)
		return "|T" .. msg .. ":0:0:0:0:16:16:0:16:0:16:255:255:255|t"
	end
	
	F.EmoTheString = function(msg)
		local E = E
		local i, new
		for i = 1, #E do
			if (strfind((msg), E[i][1])) then
				new = (new or msg):gsub(E[i][1], F.EmoticonToTexture(E[i][2]))
			end
		end
		return new
	end
	
	--------------------------------------------------------------------------------------------------
	--		Panels, Layouts, Sizes
	--------------------------------------------------------------------------------------------------
	-- Decide the width and height of our bottom panels. 
	-- The height also applies to the editbox(es),
	-- while the width functions only as a minimum width for chatframes/editboxes
	--
	-- These functions really aren't working before PLAYER_ENTERING_WORLD, 
	-- which is why we'll register them as callbacks in the relevant modules
	F.fixPanelWidth = function()
		local w = GetScreenWidth()

		-- experimental sizes. wild guesswork.
		-- everything assumes uiscaling turned off
		if (w >= 1600) then
			return 404 -- used to be 440
		elseif (w >= 1440) then
			return 360 -- used to be 380
		else
			return 320
		end
	end

	-- this should be modified by the global font size when and if I implement that
	F.fixPanelHeight = function()
		return 24
	end

	-- return the panel positions for all modules to use
	F.fixPanelPosition = function(panel)
		if (panel == "BottomLeft") then
			return "BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 8, 8
			
		elseif (panel == "BottomRight") then
			return "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -8, 8
		end
	end

	-- will use this for more than just chatframes
	F.GetDefaultChatFrameHeight = function()
		return 120
	end

	F.GetDefaultChatFrameWidth = function()
		return F.fixPanelWidth() - 3*2
	end
	
	--------------------------------------------------------------------------------------------------
	--		Friends- and Guild
	--------------------------------------------------------------------------------------------------
	local BNfriendTable = {}
	local friendTable = {}
	local guildTable = {}
	local friendSort, BNSort
	local RGBToHex = function(...) return gUI:RGBToHex(...) end
	local tsort = table.sort
	
	-- Friend tables
	-- Not using bucket events here, as each fired event is for a different change

	-- friends sorted by online -> name
	friendSort = function(a, b)
		if (a.connected == b.connected) then
			return ((a.name) and (b.name)) and (a.name < b.name) -- sometimes these are nil
		else
			return (a.connected)
		end
	end

	-- BN friends sorted by online ( game client -> toonname -> surname -> given name ) -> offline ( lastonline -> surname -> given name )
	BNSort = function(a, b)
		if (a.isOnline == b.isOnline) then
			-- online
			if (a.isOnline) then
				if (a.client == b.client) then
					if (a.toonName == b.toonName) then
						return (a.presenceName < b.presenceName)
					else
						return (a.toonName < b.toonName)
					end
				else
					return (a.client < b.client)
				end
			else
				-- offline
				if (a.lastOnline == b.lastOnline) then
					return (a.presenceName < b.presenceName)
				else
					-- last online was the time() when the player was last online
					return (a.lastOnline > b.lastOnline)
				end
			end
		else
			return (a.isOnline)
		end
	end

	F.updateFriendTable = function(self, event, ...)
		local numberOfFriends = GetNumFriends()
		local update = (numberOfFriends == #friendTable)
		if not(update) then
			wipe(friendTable)
		end
		if (numberOfFriends > 0) then
			local name, level, class, area, connected, status, note
			for i = 1, numberOfFriends do
				name, level, class, area, connected, status, note = GetFriendInfo(i)
				
				if (update) then
					friendTable[i] = {
						index = i;
						name = name or UNKNOWN;
						level = level;
						class = class;
						area = area or UNKNOWN;
						connected = (connected == 1);
						status = status or "";
						note = note or "";
					}
				else
					tinsert(friendTable, {
						index = i;
						name = name or UNKNOWN;
						level = level;
						class = class;
						area = area or UNKNOWN;
						connected = (connected == 1);
						status = status or "";
						note = note or "";
					})
				end
			end
		end
		tsort(friendTable, friendSort)
		return friendTable
	end
	gUI:RegisterEvent("PLAYER_ENTERING_WORLD", F.updateFriendTable)
	gUI:RegisterEvent("FRIENDLIST_UPDATE", F.updateFriendTable)

	F.updateBNFriendTable = function()
		local numBNetTotal, numBNetOnline = BNGetNumFriends()
		local update = (numBNetTotal == #BNfriendTable) 
		
		-- 5.0.5
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, broadcastText, noteText, isRIDFriend, broadcastTime, canSoR
		local hasFocus, _, client, realmName, realmID, faction, race, class, guild, zoneName, level, gameText 
		
		if not(update) then
			wipe(BNfriendTable)
		end
		for i = 1, numBNetTotal do
			presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, broadcastText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfo(i)
			
			-- hasFocus, toonName, client, realmName, realmID, faction, race, class, guild, zoneName, level, gameText, broadcastText, broadcastTime, canSoR, toonID = BNGetToonInfo(presenceID)
			hasFocus, _, client, realmName, realmID, faction, race, class, guild, zoneName, level, gameText, _, _, _, _ = BNGetToonInfo(presenceID)
		
		local info = {
				-- friend info
				presenceID = presenceID; -- A unique numeric identifier for the friend during this session
				presenceName = presenceName; -- visible "full" name (real name or BattleTag name)
				battleTag = battleTag; -- full BattleTag
				isBattleTagPresence = isBattleTagPresence; -- boolean, whether or not the person is known by their BattleTag
				toonName = toonName; -- The name of the logged in toon/character
				toonID = toonID; -- A unique numeric identifier for the friend's character during this session.
				client = client; -- either "WoW" (BNET_CLIENT_WOW), "S2" (BNET_CLIENT_S2), or "D3" (BNET_CLIENT_D3)
				isOnline = isOnline; -- boolean
				lastOnline = lastOnline; -- nil = online, otherwise number of seconds since the friend was online
				isAFK = isAFK; -- boolean
				isDND = isDND; -- boolean
				broadcastText = broadcastText; -- the friend's broadcast text
				noteText = noteText; -- the player's notes about this friend
				isRIDFriend = isRIDFriend; -- RealID = true, BattleTag = false
				broadcastTime = broadcastTime; -- time since friend's last broadcast
				canSoR = canSoR; -- can we send this account a scroll of ress?

				-- toon info
				realmName = realmName; -- The name of the logged in realm.
				realmID = realmID; -- The ID for the logged in realm.
				faction = faction; -- The faction name (i.e., "Alliance" or "Horde").
				race = race; -- The localized race name (e.g., "Blood Elf").
				class = class; -- The localized class name (e.g., "Death Knight").
				level = level; -- The current level (e.g., "90"). STRING
				zoneName = zoneName; -- The localized zone name (e.g., "The Undercity").
				gameText = gameText; -- For WoW, returns "zoneName - realmName". For StarCraft 2 and Diablo 3, returns the location or activity the player is currently engaged in.
			}
				
			if (update) then
				BNfriendTable[i] = info
			else
				tinsert(BNfriendTable, info)
			end
		end
		tsort(BNfriendTable, BNSort)
		return BNfriendTable
	end
	gUI:RegisterEvent("BN_FRIEND_INFO_CHANGED", F.updateBNFriendTable)
	gUI:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE", F.updateBNFriendTable)
	gUI:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE", F.updateBNFriendTable)
	gUI:RegisterEvent("BN_TOON_NAME_UPDATED", F.updateBNFriendTable)
	gUI:RegisterEvent("BN_FRIEND_TOON_ONLINE", F.updateBNFriendTable)
	gUI:RegisterEvent("BN_FRIEND_TOON_OFFLINE", F.updateBNFriendTable)
	gUI:RegisterEvent("PLAYER_ENTERING_WORLD", F.updateBNFriendTable)

	F.getFriendTable = function()
		return friendTable
	end

	F.getBNFriendTable = function()
		return BNfriendTable
	end

	-- Guild table
	do
		local lvl = { r = C.index[1], g = C.index[2], b = C.index[3] }
		local zonecolor = { r = C.index[1], g = C.index[2], b = C.index[3] }
		local left = "|cFF%s%d|r|cFF" .. RGBToHex(unpack(C.value)) .. ":|r %s %s"
		local leftnote = left .. "|cFF" .. RGBToHex(unpack(C.index)) .. " (|r|cFF" .. RGBToHex(unpack(C.value)) .. "%s" .. "|r|cFF" .. RGBToHex(unpack(C.index)) .. ") |r" 
		local MOBILE_BUSY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-BusyMobile:14:14:0:0:16:16:0:16:0:16|t"
		local MOBILE_AWAY_ICON = "|TInterface\\ChatFrame\\UI-ChatIcon-ArmoryChat-AwayMobile:14:14:0:0:16:16:0:16:0:16|t"
		local MOBILE_ONLINE_ICON = ChatFrame_GetMobileEmbeddedTexture(73/255, 177/255, 73/255)
		local mobileLeft = "|cFF%s%d|r|cFF" .. RGBToHex(unpack(C.value)) .. ":|r %s %s"
		local mobileLeftNote = mobileLeft .. "|cFF" .. RGBToHex(unpack(C.index)) .. " (|r|cFF" .. RGBToHex(unpack(C.value)) .. "%s" .. "|r|cFF" .. RGBToHex(unpack(C.index)) .. ") |r" 

		-- TODO: simplify this, provide non-formatted information
		F.updateGuildTable = function()
			local lvl, zonecolor, C = lvl, zonecolor, C
			local numberofguildies = GetNumGuildMembers(false)
			local onlineGuildies = 0
			if (numberofguildies) and (numberofguildies > 0) then
				wipe(guildTable)
			end
			local zoneR, zoneG, zoneB, classR, classG, classB
			local name, rank, rankIndex, level, class, zone, note, officernote, connected, status, classFileName, achievementPoints, achievementRank, isMobile
			for i = 1, numberofguildies do
				name, rank, rankIndex, level, class, zone, note, officernote, connected, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(i)
				-- mobile armory, and not logged into the game
				if (isMobile) and not(connected) then
					zone = REMOTE_CHAT
					onlineGuildies = onlineGuildies + 1
					lvl = GetQuestDifficultyColor(level)
					zoneR, zoneG, zoneB = .5, 1, .5
					status = (status == 1 and MOBILE_AWAY_ICON) or (status == 2 and MOBILE_BUSY_ICON) or MOBILE_ONLINE_ICON
					tinsert(guildTable, {
						(note == "") and mobileLeft:format(RGBToHex(lvl.r, lvl.g, lvl.b), level, status, name)
							or mobileLeftNote:format(RGBToHex(lvl.r, lvl.g, lvl.b), level, status, name, note),
						zone, 
						classFileName and C.RAID_CLASS_COLORS[classFileName].r or C.RAID_CLASS_COLORS.UNKNOWN, 
						classFileName and C.RAID_CLASS_COLORS[classFileName].g or C.RAID_CLASS_COLORS.UNKNOWN, 
						classFileName and C.RAID_CLASS_COLORS[classFileName].b or C.RAID_CLASS_COLORS.UNKNOWN, 
						zoneR, zoneG, zoneB
					})
				end
				-- logged into the game
				if (connected == 1) then
					onlineGuildies = onlineGuildies + 1
					lvl = GetQuestDifficultyColor(level)
					if (GetRealZoneText() == zone) then 
						zoneR, zoneG, zoneB = 0, 1, 0
					else
						zoneR, zoneG, zoneB = unpack(C.index)
					end
					status = (status == 1 and CHAT_FLAG_AFK) or (status == 2 and CHAT_FLAG_DND) or ""
					tinsert(guildTable, {
						(note == "") and left:format(RGBToHex(lvl.r, lvl.g, lvl.b), level, name, status)
							or leftnote:format(RGBToHex(lvl.r, lvl.g, lvl.b), level, name, status, note), 
						zone, 
						classFileName and C.RAID_CLASS_COLORS[classFileName].r or C.RAID_CLASS_COLORS.UNKNOWN, 
						classFileName and C.RAID_CLASS_COLORS[classFileName].g or C.RAID_CLASS_COLORS.UNKNOWN, 
						classFileName and C.RAID_CLASS_COLORS[classFileName].b or C.RAID_CLASS_COLORS.UNKNOWN, 
						zoneR, zoneG, zoneB
					})
				end
			end
			
			return guildTable
		end
	end

	-- update the guild table every 15 secs (limited by wow)
	-- self:ScheduleRepeatingTimer(15, function() GuildRoster() end)
	-- hooksecurefunc("GuildRoster", F.updateGuildTable)

	F.getGuildTable = function()
		return guildTable
	end

	--------------------------------------------------------------------------------------------------
	--		Combat Log
	--------------------------------------------------------------------------------------------------
	-- parse and return the info from "COMBAT_LOG_EVENT_UNFILTERED"
	-- 	@param eventType <string> arg2 from COMBAT_LOG_EVENT_UNFILTERED
	-- 	@param ... <vararg> arg9 and onwards from COMBAT_LOG_EVENT_UNFILTERED
	F.simpleParseLog = function(eventType, ...)
		local amount, healed, critical, spellId, spellSchool, missType, _
		if (eventType == "SWING_DAMAGE") then
				_, _, _, amount, _, _, _, _, critical = ...
			
		elseif (eventType == "SPELL_DAMAGE") or (eventType == "SPELL_PERIODIC_DAMAGE") then
				_, _, _, spellId, _, spellSchool, amount, _, _, _, _, _, critical = ...

			if (eventType == "SPELL_PERIODIC_DAMAGE") then
			end
			
		elseif (eventType == "RANGE_DAMAGE") then
				_, _, _, spellId, _, _, amount, _, _, _, _, _, critical = ...
			
		elseif (eventType == "SWING_MISSED") then
				_, _, _, missType, _ = ...
			
		elseif (eventType == "SPELL_MISSED") or (eventType == "RANGE_MISSED") then
				_, _, _, spellId, _, _, missType, _ = ...
			
		elseif (eventType == "SPELL_HEAL") or (eventType== "SPELL_PERIODIC_HEAL") then
				_, _, _, _, _, _, healed, _, _, _ = ...
		end
		return amount or 0, healed or 0, critical, spellId, spellSchool, missType
	end
	
	--------------------------------------------------------------------------------------------------
	--		Character and Area Info
	--------------------------------------------------------------------------------------------------
	-- returns true if the player is in a PvP instance
	F.IsInPvPInstance = function()
		local inInstance, instanceType = IsInInstance()
		return ((inInstance) and ((instanceType == "pvp") or (instanceType == "arena")))
	end

	-- returns true if the player is in an arena
	F.IsInArena = function()
		local inInstance, instanceType = IsInInstance()
		return ((inInstance) and (instanceType == "arena"))
	end

	-- return true if the player is in a World PvP event (Wintergrasp and Tol Barad, and any other they might add)
	F.IsInWorldPvP = function()
		local realZoneName = GetRealZoneText()

		local localizedName, isActive, canQueue, startTime, canEnter
		for pvpID = 1, GetNumWorldPVPAreas() do
			_, localizedName, isActive, canQueue, startTime, canEnter = GetWorldPVPAreaInfo(pvpID)
			if (isActive) and (localizedName == realZoneName) then
				return true
			end
		end
	end

	-- returns true if the player is in a PvP event
	-- this includes Battlegrounds, Arena, Wintergrasp and Tol Barad
	F.IsInPvPEvent = function()
		return (F.IsInPvPInstance()) or (F.IsInWorldPvP())
	end
	
	-- returns true if the player is in any homemade group (not BG made ones)
	F.IsInHomeGroup = function()
		return (GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 0)
	end
	
	-- returns true if the player is in a homemade raid (not a BG made one)
	F.IsInHomeRaid = function()
		return (IsInRaid()) and (F.IsInHomeGroup())
	end

	-- returns true if the player is in a homemade party, but NOT a raid
	F.IsInHomeParty = function()
		return not(IsInRaid()) and (F.IsInHomeGroup())
	end

	-- returns true if the player is a raid officer/leader (can set raid marks etc)
	F.IsLeader = function()
		return ((GetNumGroupMembers() > 0) or (GetNumSubgroupMembers() > 0)) and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))
	end

	-- returns true if the player is a raid officer/leader, and NOT in a PvP instance or World Event
	F.IsLeaderInPvE = function()
		if (F.IsLeader()) and not(F.IsInPvPEvent()) then
			return true
		end
	end

	-- returns true if the player is a raid officer/leader in a PvP instance or Event
	F.IsLeaderInPvP = function()
		if (F.IsLeader()) and (F.IsInPvPEvent()) then
			return true
		end
	end

	-- only works after the "PLAYER_ALIVE" event!
	F.GetPlayerSpec = function()
		return GetSpecialization() or 0
	end

	-- returns true of the player (or the optional class) is a healerclass
	-- does not check for spec
	F.IsHealerClass = function(classOrNil)
		local class = classOrNil or class
		if (class == "DRUID") or (class == "PALADIN") or (class == "PRIEST") or (class == "SHAMAN") or (class == "MONK") then
			return true
		end
	end

	-- returns true if the player is currently specced as a healer
	F.IsPlayerHealer = function()
		return (GetSpecializationRole(F.GetPlayerSpec()) == "HEALER")
	end

	-- returns true if the player is currently specced as a tank
	F.IsPlayerTank = function()
		return (GetSpecializationRole(F.GetPlayerSpec()) == "TANK")
	end

	-- returns true if the player is currently specced as DPS
	F.IsPlayerDPS = function()
		return (GetSpecializationRole(F.GetPlayerSpec()) == "DAMAGER")
	end

	--------------------------------------------------------------------------------------------------
	--		Taint Handling
	--------------------------------------------------------------------------------------------------
	local safeQueue = {}
	do
		local parseQueue = function(self, event, ...)
			local next
			while (#safeQueue > 0) do
				if (InCombatLockdown()) then
					break
				end
				next = tremove(safeQueue, 1)
				next[1](select(2, next))
			end
		end
		gUI:RegisterEvent("PLAYER_REGEN_ENABLED", parseQueue)
	end
		
	F.SafeCall = function(func, ...)
		if not(InCombatLockdown()) then
			func(...) 
		else
			tinsert(safeQueue, { func, ... })
		end
	end
	
	--------------------------------------------------------------------------------------------------
	--		Version Control
	--------------------------------------------------------------------------------------------------
	-- function used to get the Blizzard build
	-- going to be needing this with all that crap on the 4.3 PTR
	-- @return true if the current WoW version is equal to or greater than the input values
	F.IsBuild = function(version, subversion, tinyversion, build)
		gUI:argCheck(version, 1, "number", "nil")
		gUI:argCheck(subversion, 1, "number", "nil")
		gUI:argCheck(tinyversion, 1, "number", "nil")
		gUI:argCheck(build, 1, "number", "nil")
		local gameversion, gamebuild, gamedate, gametocversion = GetBuildInfo()
		local v, s, t = strsplit(".", gameversion)
		if (tonumber(v) >= tonumber(version) or 0) 
		and (tonumber(s) >= (tonumber(subversion) or 0)) 
		and (tonumber(t) >= (tonumber(tinyversion) or 0)) then
			return true
		end
	end
	
	-- returns version, subversion, and Curse build number of the addon if available
	-- clear out letters and clutter, and convert to numbers
	local tbl = {}
	local clean = function(...)
		if not(...) then
			return 0
		end
		wipe(tbl)
		local n
		for i = 1, select("#", ...) do
			n = select(i, ...)
			n = tostring(n) -- make sure it's a string
			n = n:gsub("%D", "") -- remove anything not a number
			n = tonumber(n) -- transform it back to a number
			tinsert(tbl, n or 0) -- don't insert nil values, make them zeroes
		end
		return unpack(tbl)
	end

	-- split a version string
	local version = function(v)
		gUI:argCheck(v, 1, "number", "string", "nil")
		if not(v) then
			return
		else
			v = v:gsub("-", ".") -- consider a minus sign to be the same as a period/dot
			return clean(strsplit(".", v)) -- split it and get the numbers from it
		end
	end

	-- this function is changed from v2 to v3 since we'll be using a different version scheme now
	-- now we will be listing version and subversion in the .toc entry, and build will be from curse
	F.GetVersion = function(test)
		gUI:argCheck(test, 1, "number", "string", "nil")
		local curse = test or GetAddOnMetadata(addon, "X-Curse-Packaged-Version")
		local toc = GetAddOnMetadata(addon, "Version")
		local v,s = version(toc)
		local b = version(curse)
		return v or 0, s or 0, b or 0
	end

	--------------------------------------------------------------------------------------------------
	--		Optionsmenus
	--------------------------------------------------------------------------------------------------
	local containerWidth, containerHeight = 623, 568
	local SetTooltipScripts = function(self, hook)
		local SetScript = hook and "HookScript" or "SetScript"
		
		self[SetScript](self, "OnEnter", function(self)
			if (self.tooltipText) then
				GameTooltip:SetOwner(self, self.tooltipOwnerPoint or "ANCHOR_RIGHT")

				if (type(self.tooltipText) == "string") then
					GameTooltip:SetText(self.tooltipText, 1.0, .82, .0, 1.0, 1)
					
				elseif (type(self.tooltipText) == "table") then
					for i = 1, #self.tooltipText do
						if (i == 1) then
							GameTooltip:SetText(self.tooltipText[i], 1.0, 1.0, 1.0, 1.0, 1)
						else
							GameTooltip:AddLine(self.tooltipText[i], 1.0, .82, .0, 1.0)
						end
					end
				end
				
				if (self.tooltipRequirement) then
					GameTooltip:AddLine(self.tooltipRequirement, 1.0, .0, .0, 1.0)
				end

				GameTooltip:Show()
			end
		end)
		
		self[SetScript](self, "OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end
		
	------------------------------------------------------------------------------------------------------------
	-- 	Widgets
	------------------------------------------------------------------------------------------------------------
	local ObjectPadding = {
		-- text objects
		Title = { x = { before = 0, after = 0 }, y = { before = 16, after = 16 } };
		Header = { x = { before = 0, after = 0 }, y = { before = 16, after = 8 } };
		Text = { x = { before = 0, after = 0 }, y = { before = 0, after = 8 } };
		
		-- image objects
		Texture = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
		
		-- frame groups
		Frame = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
		ScrollFrame = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };

		-- input widgets
		Button = { x = { before = 8, after = 8 }, y = { before = 8, after = 8 } };
		CheckButton = { x = { before = 8, after = 0 }, y = { before = 4, after = 4 } };
		ColorSelect = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
		Dropdown = { x = { before = 8, after = 0 }, y = { before = 0, after = 0 } };
		EditBox = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
		RadioButton = { x = { before = 8, after = 0 }, y = { before = 4, after = 4 } };
		Slider = { x = { before = 16, after = 16 }, y = { before = 16, after = 16 } };
		StatusBar = { x = { before = 16, after = 16 }, y = { before = 8, after = 8 } };
		TabButton = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
	}
	
	local Widgets = {
		-- use for page titles
		Title = function(parent, msg, name, ...)
			local self = parent:CreateFontString(name, "ARTWORK")
			self.isEnabled = true
			self:SetFontObject(gUI_TextFontLarge)
			self:SetTextColor(unpack(C["value"]))
			self:SetJustifyH("LEFT")
			self:SetWordWrap(true)
			self:SetNonSpaceWrap(true)
			self:SetText(msg)

			self.Enable = function(self) 
				self.isEnabled = true
				self:SetTextColor(unpack(C["value"]))
			end

			self.Disable = function(self) 
				self.isEnabled = false
				self:SetTextColor(unpack(C["disabled"]))
			end

			self.IsEnabled = function(self) return self.isEnabled end
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end
			
			return self, ...
		end;

		-- use for paragraph headers
		Header = function(parent, msg, name, ...)
			local self = parent:CreateFontString(name, "ARTWORK")
			self.isEnabled = true
			self:SetFontObject(gUI_TextFontNormal)
			self:SetTextColor(unpack(C["index"]))
			self:SetJustifyH("LEFT")
			self:SetWordWrap(true)
			self:SetNonSpaceWrap(true)
			self:SetText(msg)
			
			self.Enable = function(self) 
				self.isEnabled = true
				self:SetTextColor(unpack(C["index"]))
			end

			self.Disable = function(self) 
				self.isEnabled = false
				self:SetTextColor(unpack(C["disabled"]))
			end

			self.IsEnabled = function(self) return self.isEnabled end

			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("LEFT", parent, "RIGHT", 8, 0)
			end

			return self, ...
		end;

		-- use for normal text
		Text = function(parent, msg, name, ...)
			local self = parent:CreateFontString(name, "ARTWORK")
			self.isEnabled = true
			self:SetFontObject(gUI_TextFontSmallWhite)
			self:SetTextColor(unpack(C["index"]))
			self:SetJustifyH("LEFT")
			self:SetWordWrap(true)
			self:SetNonSpaceWrap(true)
			self:SetText((type(msg) == "table") and tconcat(msg, "|n") or msg)
			
			self.Enable = function(self) 
				self.isEnabled = true
				self:SetTextColor(unpack(C["index"]))
			end

			self.Disable = function(self) 
				self.isEnabled = false
				self:SetTextColor(unpack(C["disabled"]))
			end

			self.IsEnabled = function(self) return self.isEnabled end
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("LEFT", parent, "RIGHT", 8, 0)
			end

			return self, ...
		end;
		
		Texture = function(parent, msg, name, ...)
			local self = parent:CreateTexture(name, "ARTWORK")
			self:SetSize(32, 32)
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("LEFT", parent, "RIGHT", 8, 0)
			end

			return self, ...
		end;

		Button = function(parent, msg, name, ...)
			local self = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
			self:SetSize(80, 22)
			self:SetText(msg)
			gUI:SetUITemplate(self, "button", true)
			
			self:SetScript("OnClick", function(self)
				if (self.set) then
					self:set()
					
				elseif (self.parent.set) then
					self.parent:set()
				end
			end)

			SetTooltipScripts(self)
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end
			
			return self, ...
		end;

		CheckButton = function(parent, msg, name, ...)
			local self = CreateFrame("CheckButton", name, parent, "OptionsBaseCheckButtonTemplate")  -- OptionsBaseCheckButtonTemplate?
			
			local text = self:CreateFontString(name .. "Text", "ARTWORK")
			text:SetFontObject(gUI_TextFontSmallWhite)
			text:SetPoint("LEFT", self, "RIGHT", 8, 0)
			text:SetTextColor(unpack(C["index"]))
			text:SetWordWrap(true)
			text:SetNonSpaceWrap(true)
			text:SetText(msg)
			self.text = text	
			gUI:SetUITemplate(self, "checkbutton"):SetBackdropColor(nil, nil, nil, gUI:GetOverlayAlpha())

			self.refresh = function(self, option)
				if (self.get) then
					self:SetChecked(option or self:get())
					
				elseif (self.parent.get) then
					self:SetChecked(option or self.parent:get())
				end

				if (self.onrefresh) then
					self:onrefresh()
				end
			end

			self:SetScript("OnShow", function(self) self:refresh() end)
			self:SetScript("OnEnable", function(self) self.text:SetTextColor(unpack(C["index"])) end)
			self:SetScript("OnDisable", function(self) self.text:SetTextColor(unpack(C["disabled"])) end)
			self:SetScript("OnClick", function(self)
				if (self:GetChecked()) then
					PlaySound("igMainMenuOptionCheckBoxOn")
				else
					PlaySound("igMainMenuOptionCheckBoxOff")
				end
				
				if (self.set) then
					self:set()
					
				elseif (self.parent.set) then
					self.parent:set()
				end
			end)
			
			SetTooltipScripts(self)
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self, ...
		end;

		Frame = function(parent, name, ...)
			local self = CreateFrame("Frame", name, parent or UIParent)
			self:SetSize(containerWidth, containerHeight)
			self:EnableMouse(false)
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self
		end;

		ScrollFrame = function(parent, name, ...)
			local self = CreateFrame("ScrollFrame", name, parent or UIParent) -- "UIPanelScrollFrameTemplate"
			self:SetSize(containerWidth - 32 - 16, containerHeight - 32)
			self:EnableMouseWheel(true)
			
			self.ScrollChild = CreateFrame("Frame", name .. "ScrollChild", self)
			self.ScrollChild:SetSize(self:GetSize())
			self.ScrollChild:SetAllPoints(self)
			
			self:SetScrollChild(self.ScrollChild)
			self:SetVerticalScroll(0)
			
			self.ScrollBar = CreateFrame("Slider", name .. "ScrollBar", self, "UIPanelScrollBarTemplate")
			self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 6, -16)
			self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 6, 16)
			self.ScrollBar:SetWidth(16)
			self.ScrollBar:SetMinMaxValues(0, 0)
			self.ScrollBar:SetValue(0)
			if self.ScrollBar.SetObeyStepOnDrag then self.ScrollBar:SetObeyStepOnDrag(true) end

			self.ScrollBar.up = _G[name .. "ScrollBarScrollUpButton"]
			self.ScrollBar.up:Disable()
			self.ScrollBar.up:SetScript("OnClick", function(self)
				local ScrollBar = self:GetParent()
				local ScrollFrame = self:GetParent():GetParent()
				local scrollStep = ScrollFrame.scrollStep or (ScrollBar:GetHeight() / 3)

				ScrollBar:SetValue(min(0, ScrollBar:GetValue() - scrollStep))
				
				PlaySound("UChatScrollButton")
			end)
			
			self.ScrollBar.down = _G[name .. "ScrollBarScrollDownButton"]
			self.ScrollBar.down:Disable()
			self.ScrollBar.down:SetScript("OnClick", function(self)
				local ScrollBar = self:GetParent()
				local ScrollFrame = self:GetParent():GetParent()
				local scrollStep = ScrollFrame.scrollStep or (ScrollFrame:GetHeight() / 3)

				ScrollBar:SetValue(min(ScrollFrame:GetVerticalScrollRange(), ScrollBar:GetValue() + scrollStep))

				PlaySound("UChatScrollButton")
			end)
			gUI:SetUITemplate(self.ScrollBar, "scrollbar")
			
			self.Update = function(self, forced)
				local w, h = self:GetSize()
				local sW, sH = self.ScrollChild:GetSize()

				if (forced) then
					if (w ~= sW) then
						self.ScrollChild:SetWidth(w)
					end

					if (h ~= sH) then
						self.ScrollChild:SetHeight(h)
					end
					
					self:UpdateScrollChildRect()
				end

				local min, max, value = 0, self:GetVerticalScrollRange(), self:GetVerticalScroll()
				
				if (forced) then
					if (value > max) then
						value = max
					end
					
					if (value < min) then
						value = min
					end
					
					self.ScrollBar:SetMinMaxValues(min, max)
				end
				
				if (value <= min) then
					if (self.ScrollBar.up:IsEnabled()) then
						self.ScrollBar.up:Disable()
					end

					if not(self.ScrollBar.down:IsEnabled()) then
						self.ScrollBar.down:Enable()
					end
					
				elseif (value >= max) then
					if (self.ScrollBar.down:IsEnabled()) then
						self.ScrollBar.down:Disable()
					end
					
					if not(self.ScrollBar.up:IsEnabled()) then
						self.ScrollBar.up:Enable()
					end
				else
					if not(self.ScrollBar.up:IsEnabled()) then
						self.ScrollBar.up:Enable()
					end

					if not(self.ScrollBar.down:IsEnabled()) then
						self.ScrollBar.down:Enable()
					end
				end
			end

			self.ScrollBar:SetScript("OnValueChanged", function(self, value)
				self:GetParent():SetVerticalScroll(value)
				self:GetParent():Update()
			end)
			
			self:SetScript("OnMouseWheel", function(self, delta)
				if (delta > 0) then
					if (self.ScrollBar.up:IsEnabled()) then
						self.ScrollBar:SetValue(max(0, self.ScrollBar:GetValue() - 20))
					end
					
				elseif (delta < 0) then
					if (self.ScrollBar.down:IsEnabled()) then
						self.ScrollBar:SetValue(min(self:GetVerticalScrollRange(), self.ScrollBar:GetValue() + 20))
					end
				end
			end)
			
			-- we schedule a timer to update the frame contents 1/5 second after it's shown
			-- we only do this the first time
			local once
			self:SetScript("OnShow", function(self) 
				if not(once) then
					gUI:ScheduleTimer(1/5, function() self:Update(true) end)
					once = true
				end
			end)
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self, self:GetScrollChild()
		end;
		
		ColorSelect = function(parent, msg, name, ...)
			local self = CreateFrame("ColorSelect", name, parent)

			SetTooltipScripts(self)
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self, ...
		end;

		Dropdown = function(parent, msg, name, args, width, ...)
			local width = width or 100
			local self = CreateFrame("Button", name, parent, "UIDropDownMenuTemplate")
			self:SetHitRectInsets(-26, 0, 0, 0)
			gUI:SetUITemplate(self, "dropdown", true)
			
			SetTooltipScripts(self)
			
			local label = self:CreateFontString(name .. "Label", "ARTWORK")
			label:SetFontObject(gUI_TextFontSmallWhite)
			label:SetPoint("LEFT", self, "RIGHT", 0, 0)
			label:SetText(msg)
			self.label = label
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end
			
			local onclick = function(self)
				-- select the item you clicked on
				UIDropDownMenu_SetSelectedID(_G[name], self:GetID())

				-- fire off the button's 'set' function, and pass the ID along
				_G[name].set(_G[name], self:GetID())
				_G[name].selectedID = self:GetID()
			end
			
			self.args = CopyTable(args)
			self.refresh = function(self, option)
				if (self.get) then
					self.selectedID = self:get()
				end
				
				option = option or self.selectedID
				
				if (option) and (self.args[option]) then
					_G[name .. "Text"]:SetText(self.args[option])
				end

				if (self.onrefresh) then
					self:onrefresh()
				end
			end
			self.set = function(self, option) self:init() end
			self.get = function(self) return UIDropDownMenu_GetSelectedID(self) end
			self.init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end
			
			self:HookScript("OnShow", function(self) self:refresh() end)
	--		self:HookScript("OnHide", function(self) self:refresh() end)
			
			local info = {}
			local init = function(self, level)
	--			for i,v in pairs(args) do
				for i = 1, #args do
					wipe(info)
			
					info = UIDropDownMenu_CreateInfo()
					info.text = args[i] -- v
					info.value = i
					info.func = onclick

					UIDropDownMenu_AddButton(info, level)
				end
			end

			UIDropDownMenu_Initialize(self, init)
			UIDropDownMenu_SetWidth(self, width)
			UIDropDownMenu_SetButtonWidth(self, width)
			UIDropDownMenu_JustifyText(self, "LEFT")
			UIDropDownMenu_SetSelectedID(self, 1) -- selecting option #1 as default

			return self, ...
		end;

		EditBox = function(parent, msg, name, args, ...)
			local self = CreateFrame("Frame", nil, parent)
			self:EnableMouse(true)
			self:SetSize(90, 14)
			self:SetScript("OnMouseDown", function(self) self.editBox:Show() end)

			local text = self:CreateFontString(name .. "Text", "ARTWORK")
			text:SetFontObject(gUI_DisplayFontSmall)
			text:SetPoint("BOTTOMLEFT", 0, 2)
			text:SetJustifyH("LEFT")
			text:SetJustifyV("BOTTOM")
			text:SetText("")
			text:SetTextColor(unpack(C["value"]))
			self.text = text
			
			local suffix = self:CreateFontString(name .. "TextSuffix", "ARTWORK")
			suffix:SetFontObject(gUI_TextFontSmallWhite)
			suffix:SetPoint("BOTTOMLEFT", text, "BOTTOMRIGHT")
			suffix:SetJustifyH("LEFT")
			suffix:SetJustifyV("BOTTOM")
			suffix:SetTextColor(unpack(C["index"]))
			suffix:SetText(msg)
			self.suffix = suffix
			
			local editBox = CreateFrame("EditBox", nil, self)
			editBox.parent = self
			editBox:Hide()
			editBox:SetSize(self:GetWidth() + 8, self:GetHeight() + 8)
			editBox:SetPoint("BOTTOMLEFT", -4, -2)
			editBox:SetJustifyH("LEFT")
			editBox:SetJustifyV("BOTTOM")
			editBox:SetTextInsets(4, 4, 0, 0)
			editBox:SetFontObject(gUI_DisplayFontSmall)
			editBox:SetAutoFocus(false)
			editBox:SetNumeric((args) and args.numeric)
			
			gUI:SetUITemplate(self, "editbox")
			
			editBox.Refresh = function(self) 
				if (self.parent.get) then
					if (self:IsNumeric()) then
						self:SetNumber(self.parent:get())
					else
						self:SetText(self.parent:get())
					end
				else
					if (self:IsNumeric()) then
						self:SetNumber("")
					else
						self:SetText("")
					end
				end
			end

			editBox:SetScript("OnHide", function(self) 
				self.parent.text:Show()
				self.parent.suffix:Show()
			end)
			
			editBox:SetScript("OnShow", function(self) 
				self.parent.text:Hide()
				self.parent.suffix:Hide()
				
				self:Refresh()
				self:SetFocus()
				self:HighlightText()
			end)
			
			editBox:SetScript("OnEditFocusLost", editBox.Hide)
			editBox:SetScript("OnEscapePressed", editBox.Hide)
			editBox:SetScript("OnEnterPressed", function(self) 
				self:Hide()
				
				local msg = self:IsNumeric() and self:GetNumber() or self:GetText()
				if (msg) then
					if (self.parent.set) then
						self.parent:set(msg)
					end
				end
				
				self.parent:refresh()
			end)
			
			self.editBox = editBox
			
			SetTooltipScripts(self)
			
			self.refresh = function(self)
				if (self.get) then
					self.text:SetText(self.get())
				else
					self.text:SetText("")
				end
				
				if (self.editBox:IsShown()) then
					self.editBox:Refresh()
				end
				
				if (self.onrefresh) then
					self:onrefresh()
				end
			end
			
			self:HookScript("OnSizeChanged", function(self) 
				self.editBox:SetSize(self:GetWidth() + 8, self:GetHeight() + 8)
			end)
			
			self.Enable = function(self) 
				self.isEnabled = true
				self:EnableMouse(true)
				self.text:SetTextColor(unpack(C["value"]))
				self.suffix:SetTextColor(unpack(C["index"]))
			end

			self.Disable = function(self) 
				self.isEnabled = false
				self:EnableMouse(false)
				self.text:SetTextColor(unpack(C["disabled"]))
				self.suffix:SetTextColor(unpack(C["disabled"]))
				if (self.editBox:IsShown()) then
					self.editBox:Hide()
				end
			end

			self.IsEnabled = function(self) return self.isEnabled end
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self, ...
		end;

		RadioButton = function(parent, msg, name, ...)
			local self = CreateFrame("CheckButton", name, parent, "UIRadioButtonTemplate")

			local text = self:CreateFontString(name .. "Text", "ARTWORK")
			text:SetFontObject(gUI_TextFontSmallWhite)
			text:SetPoint("LEFT", self, "RIGHT", 8, 0)
			text:SetTextColor(unpack(C["index"]))
			text:SetWordWrap(true)
			text:SetNonSpaceWrap(true)
			text:SetText(msg)
			self.text = text	
			gUI:SetUITemplate(self, "radiobutton"):SetBackdropColor(nil, nil, nil, gUI:GetOverlayAlpha())

			self.refresh = function(self, option)
				if (self.get) then
					self:SetChecked(option or self:get())
					
				elseif (self.parent.get) then
					self:SetChecked(option or self.parent:get())
				end

				if (self.onrefresh) then
					self:onrefresh()
				end
			end

			self:SetScript("OnShow", function(self) self:refresh() end)
			self:SetScript("OnEnable", function(self) self.text:SetTextColor(unpack(C["index"])) end)
			self:SetScript("OnDisable", function(self) self.text:SetTextColor(unpack(C["disabled"])) end)
			self:SetScript("OnClick", function(self)
				if (self:GetChecked()) then
					PlaySound("igMainMenuOptionCheckBoxOn")
				else
					PlaySound("igMainMenuOptionCheckBoxOff")
				end
				
				if (self.set) then
					self:set()
					
				elseif (self.parent.set) then
					self.parent:set()
				end
			end)

			SetTooltipScripts(self)
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self, ...
		end;

		Slider = function(parent, msg, name, orientation, ...)
			orientation = orientation or "HORIZONTAL"
			
			local self = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
			if self.SetObeyStepOnDrag then self:SetObeyStepOnDrag(true) end
			self:SetOrientation(orientation)
			gUI:SetUITemplate(self, "slider")
			
			self.low = _G[name .. "Low"]
			self.low:SetFontObject(gUI_DisplayFontExtraTiny)

			self.high = _G[name .. "High"]
			self.high:SetFontObject(gUI_DisplayFontExtraTiny)

			self.text = _G[name .. "Text"]
			self.text:SetFontObject(gUI_DisplayFontTiny)
			
			self.refresh = function(self, option)
				if (self.get) then
					local value = self:get()
					if (value) then
						self:SetValue(value)
					end
				end
			end
			
			self.ondisable = function(self)
				self:SetAlpha(3/4)
				self.low:SetTextColor(unpack(C["disabled"]))
				self.high:SetTextColor(unpack(C["disabled"]))
				self.text:SetTextColor(unpack(C["disabled"]))
				self:EnableMouse(false)
			end
			
			self.onenable = function(self)
				self:SetAlpha(1)
				self.low:SetTextColor(unpack(C["value"]))
				self.high:SetTextColor(unpack(C["value"]))
				self.text:SetTextColor(unpack(C["index"]))
				self:EnableMouse(true)
			end
			
			self.init = function(self, min, max)
				local value = self:get()
				min = min or self.min
				max = max or self.max
				self:SetMinMaxValues(min, max)
				self.low:SetText(min)
				self.high:SetText(max)
				self:SetValue(value)
				self:SetValueStep(self.step or 1)
				self.text:SetText((self.string or "%d"):format(value))
				if (self:IsEnabled()) then
					self:onenable()
				else
					self:ondisable()
				end
			end			

			self:SetScript("OnShow", function(self) self:refresh() end)
			
			self:SetScript("OnValueChanged", function(self, value)
				if (self.set) then
					self:set(value)
				end
			end)
			
			SetTooltipScripts(self)

			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self, ...
		end;

		StatusBar = function(parent, msg, name, ...)
			local self = CreateFrame("StatusBar", name, parent)
			gUI:SetUITemplate(self, "statusbar", true)
			
			SetTooltipScripts(self)
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self, ...
		end;
		
		TabButton = function(parent, msg, name, ...)
			local self = CreateFrame("CheckButton", name, parent, "TabButtonTemplate")
			gUI:SetUITemplate(self, "tab")
			
			if (...) then
				self:SetPoint(...)
			else
				self:SetPoint("TOPLEFT")
			end

			return self, ...
		end;
	}
	
	local padding
	for name, func in pairs(Widgets) do
		padding = ObjectPadding[name]
		gUI:RegisterOptionsMenuWidgetClass(name, func, padding.x.before, padding.x.after, padding.y.before, padding.y.after)
	end
	
	-- game menu buttons
	local menuButtons = {}
	local topButton 
	F.AddGameMenuButton = function(name, msg, onclick)
		-- create our menu button
		local button = CreateFrame("Button", "GameMenuButton" .. name or "", GameMenuFrame, "GameMenuButtonTemplate")
		button:SetText(msg)
		button:SetScript("OnClick", onclick)

		-- find the top blizzard button
		-- this should be both backwards and forward compatible, and quite possible work with other addons as well
		if not(topButton) then
			for i = 1, GameMenuFrame:GetNumChildren() do
				local child = select(i, GameMenuFrame:GetChildren())
				local _, b, c, _, _ = child:GetPoint()
				if (b == GameMenuFrame) and (c == "TOP") then
					topButton = child
					break
				end
			end
		end
		
		-- decide where exactly to put our new button
		if (#menuButtons == 0) then
			-- take blizzard's top button's place
			button:SetPoint(topButton:GetPoint())
		else
			-- but it below the last of our custom buttons
			button:SetPoint("TOP", menuButtons[#menuButtons], "BOTTOM", 0, 0)
		end
		
		-- move the rest of the menu buttons down
		-- they will always come 16 points under our last custom button
		topButton:ClearAllPoints()
		topButton:SetPoint("TOP", button, "BOTTOM", 0, -16)
		
		-- make a global reference to our button
		_G["GameMenuButton" .. name or ""] = button
		
		-- increase the size of the GameMenuFrame to make place for our new button
		GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + button:GetHeight() + ((#menuButtons == 0) and 16 or 0))

		-- add it to our list
		tinsert(menuButtons, button)
	end

	F.GetGameMenuButtons = function(self)
		return menuButtons
	end

	-- restart scheduling
	F.red = function(msg)
		gUI:argCheck(msg, 1, "string")
		return "|cFFFF0000" .. msg .. "|r"
	end

	F.green = function(msg)
		gUI:argCheck(msg, 1, "string")
		return "|cFF00FF00" .. msg .. "|r"
	end

	F.yellow = function(msg)
		gUI:argCheck(msg, 1, "string")
		return "|cFFFFD100" .. msg .. "|r"
	end

	-- make text red. very advanced function. oh yeah.
	F.warning = function(...) return F.red(...) end
	
	-- schedule a restart, without actually doing anything
	local scheduledRestart
	F.ScheduleRestart = function()
		scheduledRestart = true
	end
	self:RegisterCallback("GCORE_RESTART_SCHEDULED", F.ScheduleRestart) -- voila, library integration!
	
	-- cancel the scheduled restart
	F.CancelRestart = function()
		scheduledRestart = nil
		print(L["You can reload the user interface at any time with |cFF4488FF/rl|r or |cFF4488FF/reload|r"])
	end

	-- popup a restart request if one has been scheduled previously
	local warned
	F.RestartIfScheduled = function()
		if (scheduledRestart) and not(warned) then
			StaticPopup_Show("GUIS_RESTART_REQUIRED_FOR_CHANGES")
			warned = true
		end
	end
	
	--------------------------------------------------------------------------------------------------
	--		Styling
	--------------------------------------------------------------------------------------------------
	
	-- http://www.wowpedia.com/ColorGradient
	local ColorGradient = function(a, b, ...)
		local perc
		if(b == 0) then
			perc = 0
		else
			perc = a / b
		end

		if perc >= 1 then
			local r, g, b = select(select('#', ...) - 2, ...)
			return r, g, b
		elseif perc <= 0 then
			local r, g, b = ...
			return r, g, b
		end

		local num = select('#', ...) / 3
		local segment, relperc = modf(perc*(num-1))
		local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

		return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
	end
	
	-- proxy function that uses a basic red-yellow-green gradient if no other is specified
	F.ColorGradient = function(a, b, ...)
		if (...) then
			return ColorGradient(a, b, ...)
		else
			return ColorGradient(a, b, 1, 0, 0, 1, 1, 0, 0, 1, 0)
		end
	end

	F.GetDurabilityColor = function(min, max)
		gUI:argCheck(min, 1, "number", "nil")
		gUI:argCheck(max, 1, "number", "nil")
		if ((max) and (max > 0)) then
			return F.ColorGradient(min or 0, max)
		else
			return 1, 1, 1
		end
	end

	F.GetRarityText = function(rarity)
		gUI:argCheck(rarity, 1, "number")
		local r, g, b, hex = GetItemQualityColor(rarity)
		return "|c" .. hex .. _G["ITEM_QUALITY" .. rarity .. "_DESC"] .. "|r"
	end
	
	-- fullscreen fading
	local fullscreenfader = CreateFrame("Frame", nil, UIParent)
	fullscreenfader:Hide()
	fullscreenfader:SetAlpha(0)
	fullscreenfader:SetAllPoints(UIParent)
	fullscreenfader:SetFrameStrata("HIGH")
	fullscreenfader:SetFrameLevel(129)
	fullscreenfader.texture = fullscreenfader:CreateTexture(nil, "BACKGROUND")
	fullscreenfader.texture:SetTexture(0, 0, 0)
	fullscreenfader.texture:SetAlpha(3/4)
	fullscreenfader.texture:SetAllPoints(fullscreenfader)

	F.FullScreenFadeOut = function(force)
		local startAlpha
		if (UIFrameIsFading(fullscreenfader)) then 
			UIFrameFadeRemoveFrame(fullscreenfader)
		end
		if (force) then
			fullscreenfader.texture:SetAlpha(1)
			fullscreenfader:SetAlpha(1)
			fullscreenfader:Show()
		else
			fullscreenfader.texture:SetAlpha(3/4)
			UIFrameFadeIn(fullscreenfader, (1 - fullscreenfader:GetAlpha()) * 3.5, fullscreenfader:GetAlpha(), 1)
		end
	end

	local finishedFunc = function() fullscreenfader:Hide() end
	F.FullScreenFadeIn = function()
		local startAlpha
		if (UIFrameIsFading(fullscreenfader)) then 
			UIFrameFadeRemoveFrame(fullscreenfader)
		end
		-- UIFrameFadeOut(fullscreenfader, 1.5, fullscreenfader:GetAlpha() or 1, 0)
		
		local fadeInfo = {}
		fadeInfo.mode = "OUT"
		fadeInfo.startAlpha = fullscreenfader:GetAlpha()
		fadeInfo.endAlpha = 0
		fadeInfo.timeToFade = fullscreenfader:GetAlpha() * 1.5
		fadeInfo.finishedFunc = finishedFunc -- this is why we do it manually

		UIFrameFade(fullscreenfader, fadeInfo)
	end
	
	--------------------------------------------------------------------------------------------------
	--		Action Buttons
	--------------------------------------------------------------------------------------------------
	-- using blizzard keys from GlobalStrings.lua (wow patch 5.0.5)
	-- this avoids all localization issues
	local keys = {
		-- [KEY_APOSTROPHE] =; -- "'";
		-- [KEY_BACKSLASH] =; -- "\\";
		[KEY_BACKSPACE] = L["Bs"]; -- "Backspace";
		[KEY_BACKSPACE_MAC] = L["Del"]; -- "Delete";
		[KEY_BUTTON1] = L["M"] .. 1; -- "Left Mouse Button";
		[KEY_BUTTON10] = L["M"] .. 10; -- "Mouse Button 10";
		[KEY_BUTTON11] = L["M"] .. 11; -- "Mouse Button 11";
		[KEY_BUTTON12] = L["M"] .. 12; -- "Mouse Button 12";
		[KEY_BUTTON13] = L["M"] .. 13; -- "Mouse Button 13";
		[KEY_BUTTON14] = L["M"] .. 14; -- "Mouse Button 14";
		[KEY_BUTTON15] = L["M"] .. 15; -- "Mouse Button 15";
		[KEY_BUTTON16] = L["M"] .. 16; -- "Mouse Button 16";
		[KEY_BUTTON17] = L["M"] .. 17; -- "Mouse Button 17";
		[KEY_BUTTON18] = L["M"] .. 18; -- "Mouse Button 18";
		[KEY_BUTTON19] = L["M"] .. 19; -- "Mouse Button 19";
		[KEY_BUTTON2] = L["M"] .. 2; -- "Right Mouse Button";
		[KEY_BUTTON20] = L["M"] .. 20; -- "Mouse Button 20";
		[KEY_BUTTON21] = L["M"] .. 21; -- "Mouse Button 21";
		[KEY_BUTTON22] = L["M"] .. 22; -- "Mouse Button 22";
		[KEY_BUTTON23] = L["M"] .. 23; -- "Mouse Button 23";
		[KEY_BUTTON24] = L["M"] .. 24; -- "Mouse Button 24";
		[KEY_BUTTON25] = L["M"] .. 25; -- "Mouse Button 25";
		[KEY_BUTTON26] = L["M"] .. 26; -- "Mouse Button 26";
		[KEY_BUTTON27] = L["M"] .. 27; -- "Mouse Button 27";
		[KEY_BUTTON28] = L["M"] .. 28; -- "Mouse Button 28";
		[KEY_BUTTON29] = L["M"] .. 29; -- "Mouse Button 29";
		[KEY_BUTTON3] = L["M"] .. 3; -- "Middle Mouse";
		[KEY_BUTTON30] = L["M"] .. 30; -- "Mouse Button 30";
		[KEY_BUTTON31] = L["M"] .. 31; -- "Mouse Button 31";
		[KEY_BUTTON4] = L["M"] .. 4; -- "Mouse Button 4";
		[KEY_BUTTON5] = L["M"] .. 5; -- "Mouse Button 5";
		[KEY_BUTTON6] = L["M"] .. 6; -- "Mouse Button 6";
		[KEY_BUTTON7] = L["M"] .. 7; -- "Mouse Button 7";
		[KEY_BUTTON8] = L["M"] .. 8; -- "Mouse Button 8";
		[KEY_BUTTON9] = L["M"] .. 9; -- "Mouse Button 9";
		-- [KEY_COMMA] =; -- ",";
		[KEY_DELETE] = L["Del"]; -- "Delete";
		[KEY_DELETE_MAC] = L["Del"]; -- "Del";
		[KEY_DOWN] = L["Dn"]; -- "Down Arrow";
		[KEY_END] = L["End"]; -- "End";
		-- [KEY_ENTER] =; -- "Enter";
		-- [KEY_ENTER_MAC] =; -- "Return";
		-- [KEY_ESCAPE] =; -- "Escape";
		[KEY_HOME] = L["Home"]; -- "Home";
		[KEY_INSERT] = L["Ins"]; -- "Insert";
		-- [KEY_INSERT_MAC] =; -- "Help";
		[KEY_LEFT] = L["Lt"]; -- "Left Arrow";
		-- [KEY_LEFTBRACKET] =; -- "[";
		-- [KEY_MINUS] =; -- "-";
		[KEY_MOUSEWHEELDOWN] = L["WD"]; -- "Mouse Wheel Down";
		[KEY_MOUSEWHEELUP] = L["WU"]; -- "Mouse Wheel Up";
		[KEY_NUMLOCK] = L["NL"]; -- "Num Lock";
		[KEY_NUMLOCK_MAC] = L["Clr"]; -- "Clear";
		[KEY_NUMPAD0] = L["N"] .. 0; -- "Num Pad 0";
		[KEY_NUMPAD1] = L["N"] .. 1; -- "Num Pad 1";
		[KEY_NUMPAD2] = L["N"] .. 2; -- "Num Pad 2";
		[KEY_NUMPAD3] = L["N"] .. 3; -- "Num Pad 3";
		[KEY_NUMPAD4] = L["N"] .. 4; -- "Num Pad 4";
		[KEY_NUMPAD5] = L["N"] .. 5; -- "Num Pad 5";
		[KEY_NUMPAD6] = L["N"] .. 6; -- "Num Pad 6";
		[KEY_NUMPAD7] = L["N"] .. 7; -- "Num Pad 7";
		[KEY_NUMPAD8] = L["N"] .. 8; -- "Num Pad 8";
		[KEY_NUMPAD9] = L["N"] .. 9; -- "Num Pad 9";
		[KEY_NUMPADDECIMAL] = L["N"] .. "."; -- "Num Pad .";
		[KEY_NUMPADDIVIDE] = L["N"] .. "/"; -- "Num Pad /";
		[KEY_NUMPADMINUS] = L["N"] .. "-"; -- "Num Pad -";
		[KEY_NUMPADMULTIPLY] = L["N"] .. "*"; -- "Num Pad *";
		[KEY_NUMPADPLUS] = L["N"] .. "+"; -- "Num Pad +";
		[KEY_PAGEDOWN] = L["PD"]; -- "Page Down";
		[KEY_PAGEUP] = L["PU"]; -- "Page Up";
		-- [KEY_PAUSE] =; -- "Pause";
		-- [KEY_PAUSE_MAC] =; -- "F15";
		-- [KEY_PERIOD] =; -- ".";
		-- [KEY_PLUS] =; -- "+";
		-- [KEY_PRINTSCREEN] =; -- "Print Screen";
		-- [KEY_PRINTSCREEN_MAC] =; -- "F13";
		[KEY_RIGHT] = L["Rt"]; -- "Right Arrow";
		-- [KEY_RIGHTBRACKET] =; -- "]";
		[KEY_SCROLLLOCK] = L["SL"]; -- "Scroll Lock";
		-- [KEY_SCROLLLOCK_MAC] =; -- "F14";
		-- [KEY_SEMICOLON] =; -- ";";
		-- [KEY_SLASH] =; -- "/";
		[KEY_SPACE] = L["Spc"]; -- "Spacebar";
		[KEY_TAB] = L["Tab"]; -- "Tab";
		-- [KEY_TILDE] =; -- "~";
		[KEY_UP] = L["Up"]; -- "Up Arrow";
	}
	
	F.ShortenHotKey = function(key)
		if (key) then
			local s = "" -- "-"
			
			for e,l in pairs(keys) do
				-- key = key:gsub("(" .. e .. ")", l)
				key = key:gsub(e, l)
			end
				
			-- doesn't work on all?
			key = key:gsub("a%-", L["A"]:lower())
			key = key:gsub("c%-", L["C"]:lower())
			key = key:gsub("s%-", L["S"]:lower())
			return key
		end
	end
	
	--------------------------------------------------------------------------------------------------
	--		Shine
	--------------------------------------------------------------------------------------------------
	--
	-- usage:
	-- 	local shineFrame = F.Shine:New(target, maxAlpha, duration, scale)
	-- 	shineFrame:Start()
	--		shineFrame:Hide()
	local MAXALPHA = 1
	local SCALE = 5 -- too huge for this?
	local DURATION = 0.75
	local TEXTURE = M("Texture", "CooldownStar") -- [[Interface\Cooldown\star4]]

	local New = function(frameType, parentClass)
		gUI:argCheck(frameType, 1, "string")
		gUI:argCheck(parentClass, 2, "table", "nil")
		local class = CreateFrame(frameType)
		class.mt = { __index = class }
		if (parentClass) then
			class = setmetatable(class, { __index = parentClass })
			class.super = function(self, method, ...)
				parentClass[method](self, ...)
			end
		end
		class.Bind = function(self, obj) return setmetatable(obj, self.mt) end
		return class
	end

	local Shine = New("Frame")
	Shine.New = function(self, parent, maxAlpha, duration, scale)
		local f = self:Bind(CreateFrame("Frame", nil, parent)) 
		f:Hide()
		f:SetScript("OnHide", f.OnHide)
		f:SetAllPoints(parent)
		f:SetToplevel(true)

		f.animation = f:CreateShineAnimation(maxAlpha, duration, scale)

		local icon = f:CreateTexture(nil, "OVERLAY")
		icon:SetPoint("CENTER")
		icon:SetBlendMode("ADD")
		icon:SetAllPoints(f)
		icon:SetTexture(TEXTURE)

		return f
	end

	local animation_OnFinished = function(self)
		local parent = self:GetParent()
		if (parent:IsShown()) then
			parent:Hide()
		end
	end

	Shine.CreateShineAnimation = function(self, maxAlpha, duration, scale)
		local MAXALPHA = maxAlpha or MAXALPHA
		local SCALE = scale or SCALE
		local DURATION = duration or DURATION

		local g = self:CreateAnimationGroup()
		g:SetLooping("NONE")
		g:SetScript("OnFinished", animation_OnFinished)

		local startTrans = g:CreateAnimation("Alpha")
		startTrans:SetChange(-1) -- make it 0, no matter the maxAlpha
		startTrans:SetDuration(0)
		startTrans:SetOrder(0)

		local grow = g:CreateAnimation("Scale")
		grow:SetOrigin("CENTER", 0, 0)
		grow:SetScale(SCALE, SCALE)
		grow:SetDuration(DURATION/2)
		grow:SetOrder(1)

		local brighten = g:CreateAnimation("Alpha")
		brighten:SetChange(MAXALPHA)
		brighten:SetDuration(DURATION/2)
		brighten:SetOrder(1)

		local shrink = g:CreateAnimation("Scale")
		shrink:SetOrigin("CENTER", 0, 0)
		shrink:SetScale(-SCALE, -SCALE)
		shrink:SetDuration(DURATION/2)
		shrink:SetOrder(2)

		local fade = g:CreateAnimation("Alpha")
		fade:SetChange(-MAXALPHA)
		fade:SetDuration(DURATION/2)
		fade:SetOrder(2)

		return g
	end

	Shine.OnHide = function(self)
		if (self.animation:IsPlaying()) then
			self.animation:Finish()
		end
		self:Hide()
	end

	Shine.Start = function(self)
		if (self.animation:IsPlaying()) then
			self.animation:Finish()
		end
		self:Show()
		self.animation:Play()
	end
	
	F.Shine = Shine

end
