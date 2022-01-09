--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Panels", "gPanel-3.0")
local actionbars = gUI:GetModule("Actionbars")

local floor, min = math.floor, math.min
local ipairs, select, unpack = ipairs, select, unpack
local tinsert, tsort = table.insert, table.sort

local BNGetFriendInfo = BNGetFriendInfo
local BNGetNumFriends = BNGetNumFriends
local BNGetToonInfo = BNGetToonInfo
local CanGuildInvite = CanGuildInvite
local CreateFrame = CreateFrame
local EasyMenu = EasyMenu
local ExpandAllFactionHeaders = ExpandAllFactionHeaders
local GetFactionInfo = GetFactionInfo
local GetFramerate = GetFramerate
local GetFriendInfo = GetFriendInfo
local GetInventoryItemDurability = GetInventoryItemDurability
local GetMoney = GetMoney
local GetNetStats = GetNetStats
local GetNumFactions = GetNumFactions
local GetNumFriends = GetNumFriends
local GetNumGuildMembers = GetNumGuildMembers
local GetRealmName = GetRealmName
local GetWatchedFactionInfo = GetWatchedFactionInfo
local GetXPExhaustion = GetXPExhaustion
local GuildRoster = GuildRoster
local HasNewMail = HasNewMail
local IsInGuild = IsInGuild
local LoadAddOn = LoadAddOn
local ReputationFrame_Update = ReputationFrame_Update
local SetSelectedFaction = SetSelectedFaction
local StaticPopup_Show = StaticPopup_Show
local ToggleCharacter = ToggleCharacter
local UnitFactionGroup = UnitFactionGroup
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax

local L, C, F, M, db 
local panels, backdrops = {}, {}

local defaults = {
	backdrops = {
		bottom = {
			show = true;
			place = { "TOPLEFT", "UIParent", "BOTTOM", -189, 76 };
			size = { 378, 68 };
			anchors = {
				TOPLEFT = "ActionButton1";
				BOTTOMRIGHT = "MultiBarBottomLeftButton12";
			};
		};
		left = {
			show = true;
			place = { "BOTTOMRIGHT", "UIParent", "BOTTOM", -192, 8 };
			size = { 99, 68 };
			anchors = {
				TOPLEFT = "MultiBarBottomRightButton1";
				BOTTOMRIGHT = "MultiBarBottomRightButton6";
			};
		};
		right = {
			show = true;
			place = { "BOTTOMRIGHT", "UIParent", "BOTTOM", 291, 8 };
			size = { 99, 68 };
			anchors = {
				TOPLEFT = "MultiBarBottomRightButton7";
				BOTTOMRIGHT = "MultiBarBottomRightButton12";
			};
		};
		-- side = {
			-- show = true;
			-- place = {};
			-- size = {};
		-- };
	};

	panels = {
		left = {
			show = true;
			place = { "BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 8, 8 };
			plugins = { "friends", "netstats", "guild" };
		};
		right = {
			show = true;
			place = { "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -8, 8 };
			plugins = { "bagspace", "gold", "durability" };
		};
	};
	
	-- netstats plugin
	showChatLatency = false;
	showCastLatency = true;
	showFPS = true;
}

-- retrieve an icon from the grid
local grid = {
	bug = { 3, 1}; comment = { 6, 1}; folder = { 9, 1}; move = { 12, 1}; 
	about = { 3, 2}; attach = { 6, 2}; stop = { 9, 2}; calendar = { 12, 2}; 
	clean = { 3, 3}; cogs = { 6, 3}; coins = { 9, 3}; download = { 12, 3}; 
	euro = { 3, 4}; exclamation = { 6, 4}; star = { 9, 4}; female = { 12, 4}; 
	film = { 3, 5}; gamepad = { 6, 5}; gbp = { 9, 5}; group = { 12, 5}; 
	info = { 3, 6}; iphone = { 6, 6}; keyboard = { 9, 6}; lightbulb = { 12, 6}; 
	link = { 3, 7}; place = { 6, 7}; mail = { 9, 7}; male = { 12, 7}; 
	musicnote = { 3, 8}; check = { 6, 8}; circlecheck = { 9, 8}; paw = { 12, 8}; 
	pen = { 3, 9}; person = { 6, 9}; question = { 9, 9}; unchecked = { 12, 9}; 
	circleunchecked = { 3, 10}; search = { 6, 10}; settings = { 9, 10}; graph = { 12, 10}; 
	tag = { 3, 11}; clock = { 6, 11}; trash = { 9, 11}; usd = { 12, 11}; 
	wand = { 3, 12}; widescreen = { 6, 12}; zoomin = { 9, 12}; zoomout = { 12, 12}; 
}

local GetTexCoord = function(icon)
	local x, y = unpack(grid[icon])
	return (x-1)*32/512, (x)*32/512, (y-1)*32/512, (y)*32/512
end

local GetIcon = function()
	return M("Icon", "GlyphIcons")
end

local Register = function()
	local gPanel = LibStub("gPanel-3.0")
	gPanel:SetFontObject(gUI_DisplayFontTiny) 

	local color = function(msg, isValue)
		if (type(msg) == "number") then
			msg = tostring(msg)
		elseif (type(msg) ~= "string") then 
			msg = ""
		end
		local color
		if (isValue) then
			color = module:RGBToHex(C.value[1], C.value[2], C.value[3])
		else
			color = module:RGBToHex(C.index[1], C.index[2], C.index[3])
		end
		return "|cFF" .. color .. msg .. "|r"
	end
	
	local slots = { "HeadSlot", "ShoulderSlot", "ChestSlot", "WaistSlot", "WristSlot", "HandsSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot" }

	local BFriends = {}
	local green = { r = 0.35, g = 0.75, b = 1 }
	local red = { r = 0, g = 1, b = 0 }
	local white = { r = 1, g = 1, b = 1 }
	gPanel:RegisterTooltip("friends", function(self) 
		
		local tsort = table.sort
		local BFriends = BFriends
		local friendTable = F.getFriendTable()
		local BNfriendTable = F.getBNFriendTable()
		local localClass, classc, lvlcol, zonecol, left, right
		local friendsOnline = 0
	
		wipe(BFriends)
		
		GameTooltip:AddLine(FRIENDS, unpack(C["index"]))
		GameTooltip:AddLine(" ")
		
		-- create bnet list
		for i = 1, #BNfriendTable do
			if (BNfriendTable[i].isOnline) then
				friendsOnline = friendsOnline + 1
				
				if (BNfriendTable[i].client == BNET_CLIENT_WOW) then
					-- temporarily store the character name if it is the same realm and faction as the player
					if (BNfriendTable[i].realmName == clientRealm) then -- (BNfriendTable[i].isFriend)
						if ((playerFaction == "Alliance") and (BNfriendTable[i].faction == 1)) or ((playerFaction == "Horde") and (BNfriendTable[i].faction == 0)) then
							BFriends[BNfriendTable[i].toonName] = true
						end
					end
					
					for k,v in pairs(LOCALIZED_CLASS_NAMES_MALE) do 
						if (BNfriendTable[i].class == v) then 
							localClass = k 
						end 
					end

					-- feminine class localization
					if (clientLocale ~= "enUS") then 
						for k,v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do 
							if (BNfriendTable[i].class == v) then 
								localClass = k 
							end 
						end
					end
					
					classc = RAID_CLASS_COLORS[localClass] or green
					lvlcol = (BNfriendTable[i].level) and (tonumber(BNfriendTable[i].level)) and GetQuestDifficultyColor(tonumber(BNfriendTable[i].level)) or white
					zonecol = (GetRealZoneText() == BNfriendTable[i].zoneName) and green or white
					
					left = "|cFF" .. module:RGBToHex(lvlcol.r, lvlcol.g, lvlcol.b) .. BNfriendTable[i].level .. "|r|cFFFFFFFF:|r "
					left = left .. "|cFF" .. module:RGBToHex(classc.r, classc.g, classc.b)
					left = left .. BNfriendTable[i].toonName .. " " .. (BNfriendTable[i].AFK and CHAT_FLAG_AFK or "") .. (BNfriendTable[i].DND and CHAT_FLAG_DND or "") .. "|r"
					left = left .. color("(" .. BNfriendTable[i].presenceName .. ")", true)

					if (BNfriendTable[i].noteText) and (BNfriendTable[i].noteText ~= "") then 
						left = left.. color("(" .. BNfriendTable[i].noteText .. ")", true) 
					end

					if (BNfriendTable[i].realmName == clientRealm) then
						right = "|cFF" .. module:RGBToHex(zonecol.r, zonecol.g, zonecol.b) .. BNfriendTable[i].zoneName .. "|r"
					else
						right = BNfriendTable[i].gameText
					end
					GameTooltip:AddDoubleLine(left, right)
				else
					left = ""
					
					if (BNfriendTable[i].presenceName) then
						left = left .. "|cFFFFFFFF" .. BNfriendTable[i].presenceName .. "|r"
					end

					if (BNfriendTable[i].toonName) then
						left = left .. " |cFFFFFFFF(|r"..BNfriendTable[i].toonName.."|cFFFFFFFF)|r" or ""
					end

					if (BNfriendTable[i].noteText) then
						left = left ..  "|cFF00FF00 "..BNfriendTable[i].noteText.." |r"
					end
					
					right = ""
					
					if (BNfriendTable[i].client) then
						right = right .. " " .. BNfriendTable[i].client
					end
					
					if (BNfriendTable[i].gameText) then
						right = right .. "|cFFFF7D0A ("..BNfriendTable[i].gameText..") |r"
					end
					
					if (left ~= "") then
						GameTooltip:AddDoubleLine(left, right)
					end
				end
			end
		end
		
		-- create friends list
		for i = 1, #friendTable do
			if (friendTable[i].connected) and not(BFriends[friendTable[i].name]) then 
				friendsOnline = friendsOnline + 1

				for k,v in pairs(LOCALIZED_CLASS_NAMES_MALE) do 
					if (friendTable[i].class == v) then 
						localClass = k 
					end 
				end

				-- feminine class localization
				if (clientLocale ~= "enUS") then 
					for k,v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do 
						if (friendTable[i].class == v) then 
							localClass = k 
						end 
					end
				end

				classc = localClass and RAID_CLASS_COLORS[localClass] or green
				lvlcol = friendTable[i].level and GetQuestDifficultyColor(friendTable[i].level) or white
				zonecol = (GetRealZoneText() == friendTable[i].area) and green or white

				left = "|cFF" .. module:RGBToHex(lvlcol.r, lvlcol.g, lvlcol.b) .. friendTable[i].level .. "|r"
				left = left .. "|cFFFFFFFF:|r |cFF" .. module:RGBToHex(classc.r, classc.g, classc.b) .. friendTable[i].name .. " " .. friendTable[i].status .. "|r"

				if (friendTable[i].note) then 
					left = left .. "|cFFFFFFFF (" .. friendTable[i].note .. ") |r" 
				end

				right = "|cFF" .. module:RGBToHex(zonecol.r, zonecol.g, zonecol.b) .. friendTable[i].area .. "|r"

				GameTooltip:AddDoubleLine(left, right)
			end
		end
		
		if (friendsOnline == 0) then
			GameTooltip:AddLine(NOT_APPLICABLE, unpack(C["index"]))
		end

		GameTooltip:AddLine(" ")
		-- GameTooltip:AddLine(L["<Left-Click to toggle Friends pane>"], unpack(C["value"]))
		-- GameTooltip:AddLine(L["<Right-Click for options>"], unpack(C["value"]))
		-- GameTooltip:Show()

		
		GameTooltip:AddLine(L["<Left-Click to toggle Friends pane>"], unpack(C.value))
		GameTooltip:Show()
	end)

	do
		local white = "|cFFFFFFFF"
		local green = "|cFF00FF00"
		local yellow = "|cFFFFD200"
		local close = "|r"
		local r, g, b = unpack(C.index)
		local r2, g2, b2 = unpack(C.value)

		gPanel:RegisterTooltip("netstats", function(self) 
			local down, up, home, world = GetNetStats()
			local stat = yellow .. "%d|r|cFFFFFFFF%s|r" .. close

			GameTooltip:AddLine(L["Network Stats"], r, g, b)
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(L["World latency %s:"]:format(green .. L["(Combat, Casting, Professions, NPCs, etc)"] .. close), stat:format(world, MILLISECONDS_ABBR), r, g, b, r2, g2, b2)
			GameTooltip:AddDoubleLine(L["Home latency %s:"]:format(green .. L["(Chat, Auction House, etc)"] .. close), stat:format(home, MILLISECONDS_ABBR), r, g, b, r2, g2, b2)
			GameTooltip:Show()
		end)
	end

	gPanel:RegisterTooltip("guild", function(self) 
		local numberofguildies = GetNumGuildMembers(false)
		if not(numberofguildies) or (numberofguildies < 1) then
			return
		end

		local guildTable = F.updateGuildTable()
		
		local maxDisplayedGuildies = 30
		local displayedGuildies = min(maxDisplayedGuildies, #guildTable)
		local gmotd = GetGuildRosterMOTD()
		local level = GetGuildLevel()
		local gender = UnitSex("player")
		local name, description, standingID, barMin, barMax, barValue, _, _, _, _, _, _, _, repToCap, weeklyCap = GetGuildFactionInfo()
		local r, g, b = unpack(C["index"])
		local r2, g2, b2 = unpack(C["value"])
		local col = "|cFF" .. module:RGBToHex(r2, g2, b2)
		
		if not(standingID == 8) then 
			local r = C["FACTION_BAR_COLORS"][standingID].r 
			local g = C["FACTION_BAR_COLORS"][standingID].g 
			local b = C["FACTION_BAR_COLORS"][standingID].b 
			
			name = name .. " (|cFF" .. module:RGBToHex(r, g, b) .. GetText("FACTION_STANDING_LABEL" .. standingID, gender) .. "|r)"
		end
		
		local nameString = ((level == 25) and "%s" or "%s [" .. col .. level .. "|r]"):format(name or GetGuildInfo("player") or NOT_APPLICABLE)
		local onlineString = ("%d".. "|cFFFFFFFF/|r" .. "%d"):format(#guildTable, numberofguildies)
		
		GameTooltip:AddDoubleLine(nameString, onlineString, r, g, b, r2, g2, b2)

		if (gmotd) and not(gmotd == "") then
			if (gmotd:len() >= 64) then
				local c, p, i, j
				local h = 64
				for i = 64,1, -1 do
					c = gmotd:sub(i, i)
					if (c == " ") then
						for j = i, 1, -1 do
							c = gmotd:sub(j, j)
							if (c ~= " ") then
								h = j
								break
							end
						end
						break
					end
				end
				GameTooltip:AddLine(gmotd:sub(1, h) .. "...", ChatTypeInfo["GUILD"].r, ChatTypeInfo["GUILD"].g, ChatTypeInfo["GUILD"].b)
			else
				GameTooltip:AddLine(gmotd, ChatTypeInfo["GUILD"].r, ChatTypeInfo["GUILD"].g, ChatTypeInfo["GUILD"].b)
			end
		end
		
		GameTooltip:AddLine(" ")

		if (level ~= 25) then
			local current, remaining, daily, dailymax = UnitGetGuildXP("player")
			local nextlevel = current + remaining
			
			if (nextlevel) and (dailymax) and not((nextlevel == 0) or (dailymax == 0)) then 
				local totalpercent = col .. tostring(ceil((current / nextlevel) * 100)) .. "|r"
				local dailypercent = col .. tostring(ceil((daily / dailymax) * 100)) .. "|r"
				local current = col .. module:Tag(("[shortvalue:%d]"):format(current)) .. "|r"
				local nextlevel = col .. module:Tag(("[shortvalue:%d]"):format(nextlevel)) .. "|r"
				local daily = col .. module:Tag(("[shortvalue:%d]"):format(daily)) .. "|r"
				local dailymax = col .. module:Tag(("[shortvalue:%d]"):format(dailymax)) .. "|r"
				
				GameTooltip:AddLine(("%s:"):format(GUILD_EXPERIENCE), unpack(C["index"]))
				GameTooltip:AddLine(GUILD_EXPERIENCE_CURRENT:format(current, nextlevel, totalpercent), r, g, b)
				GameTooltip:AddLine(GUILD_EXPERIENCE_DAILY:format(daily, dailymax, dailypercent), r, g, b)
				GameTooltip:AddLine(" ")
			end
		end
		
		if not(standingID == 8) then 
			local percent = col .. tostring(floor(((barValue - barMin) / (barMax - barMin)) * 100)) .. "|r"
			barValue = col .. module:Tag(("[shortvalue:%d]"):format(barValue - barMin)) .. "|r"
			barMax = col .. module:Tag(("[shortvalue:%d]"):format(barMax - barMin)) .. "|r"
			
			GameTooltip:AddLine(("%s:"):format(GUILD_REPUTATION), r, g, b)
			GameTooltip:AddLine(GUILD_EXPERIENCE_CURRENT:format(barValue, barMax, percent), r, g, b)
			
			if (repToCap) and (weeklyCap) and not(weeklyCap == 0) then
				percent = col .. tostring(floor(((weeklyCap - repToCap) / weeklyCap) * 100)) .. "|r"
				repToCap = col .. module:Tag(("[shortvalue:%d]"):format(weeklyCap - repToCap)) .. "|r"
				weeklyCap = col .. module:Tag(("[shortvalue:%d]"):format(weeklyCap)) .. "|r"

				GameTooltip:AddLine(GUILD_REPUTATION_WEEKLY:format(repToCap, weeklyCap, percent), r, g, b)
			end
			
			GameTooltip:AddLine(" ")
		end
		
		-- create the guild listing
		for i = 1, displayedGuildies do
			GameTooltip:AddDoubleLine(guildTable[i][1], guildTable[i][2], guildTable[i][3], guildTable[i][4], guildTable[i][5], guildTable[i][6], guildTable[i][7], guildTable[i][8])
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["<Left-Click to toggle Guild pane>"], r2, g2, b2)
		-- GameTooltip:AddLine(L["<Right-Click for options>"], r2, g2, b2)
		GameTooltip:Show()
	end)

	gPanel:RegisterTooltip("bagspace", function(self) 
		local name, link, invID
		local min, max, free, total, used = 0, 0, 0, 0, 0
		local r, g, b = unpack(C["index"])
		local r2, g2, b2 = unpack(C["value"])
		local space = "%d|cFF" .. module:RGBToHex(r, g, b) .. "/|r%d"
		
		GameTooltip:AddLine(L["Bags"], unpack(C["index"]))
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(NAME, L["Free/Max"], r2, g2, b2, r2, g2, b2)

		for i = 0, NUM_BAG_SLOTS do
			invID = not(i == 0) and ContainerIDToInventoryID(i) 
			link = GetBagName(i)
			free = GetContainerNumFreeSlots(i)
			total = GetContainerNumSlots(i)
			
			if (total) and (total > 0) then
				GameTooltip:AddDoubleLine(link, space:format(free, total), r, g, b, r2, g2, b2)
			else
				GameTooltip:AddLine(L["No container equipped in slot %d"]:format(i), 1, 0, 0)
			end
		end
		
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["<Left-Click to toggle backpack>"], r2, g2, b2)
		GameTooltip:Show()
	end)

	local currencyBag, currencyList = {}, {}
	local nameSort = function(a,b) return a.name < b.name end
	gPanel:RegisterTooltip("currencies", function(self) 
		GameTooltip:AddLine(L["Tracked Currencies"], unpack(C["index"]))
		GameTooltip:AddLine(" ")

		local watchedTokens = GetNumWatchedTokens()
		local displayedTokens = 0
		
		wipe(currencyBag)
		wipe(currencyList)
		
		local r, g, b
		local name, count, icon
		
		-- update the backpack currency list
		for i = 1, watchedTokens  do
			name, count, icon = GetBackpackCurrencyInfo(i)
			if (count) then
				currencyBag[name] = true
				tinsert(currencyList, { name = name, count = count, icon = icon })
				displayedTokens = displayedTokens + 1
			end
		end

		-- iterate and update our custom tracked currency list
		-- local name, currentAmount, texture, earnedThisWeek, weeklyMax, totalMax, isDiscovered
		-- for id,_ in pairs(GUIS_DB["panels"].trackedCurrencies) do
			-- name, currentAmount, texture, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo(id)
			-- if not(currencyBag[name]) then
				-- tinsert(currencyList, { name = name, count = currentAmount, icon = "Interface\\Icons\\" .. texture })
			-- end
		-- end
		
		tsort(currencyList, nameSort)
		
		-- list the currencies
		for i = 1, #currencyList do
			r, g, b = (currencyList[i].count > 0) and unpack(C["index"]) or unpack({ 0.4, 0.4, 0.4 })
			
			GameTooltip:AddDoubleLine(("|cFFFFFFFF%s|r"):format(currencyList[i].name), ("|cFFFFFFFF%d|r |T%s:0:0:0:0|t"):format(currencyList[i].count, currencyList[i].icon), r, g, b, unpack(C["value"]) )
		end

		if (#currencyList == 0) then
			GameTooltip:AddLine(NOT_APPLICABLE, unpack(C["index"]))
		end
		
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["<Left-Click to toggle Currency frame>"], unpack(C.value))
		-- GameTooltip:AddLine(L["<Right-Click for options>"], unpack(C["value"]))
		GameTooltip:Show()
	end)

	gPanel:RegisterTooltip("restricted-account", function(self) 
		GameTooltip:AddLine(ERR_RESTRICTED_ACCOUNT, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
		GameTooltip:Show()
	end)
	
	gPanel:RegisterTooltip("restricted-pandaren", function(self) 
		GameTooltip:AddLine(FEATURE_NOT_AVAILBLE_PANDAREN, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
		GameTooltip:Show()
	end)

	local dummy = CreateFrame("GameTooltip")
	gPanel:RegisterTooltip("durability", function(self)
		GameTooltip:AddLine(DURABILITY, unpack(C.index))
		GameTooltip:AddLine(" ")
		
		local eqcurrent, eqtotal, eqcost = 0, 0, 0
		for _, slot in ipairs(slots) do
			local item = _G["Character" .. slot]
			local exist, _, cost = dummy:SetInventoryItem("player", item:GetID())
			local current, total = GetInventoryItemDurability(item:GetID())

			if exist and cost and cost > 0 then
				eqcost = eqcost + cost
			end

			if current and total then
				eqcurrent = eqcurrent + current
				eqtotal = eqtotal + total
			end
		end

		local bgcurrent, bgtotal, bgcost = 0, 0, 0
		for bag = 0, 4 do
			for slot = 1, GetContainerNumSlots(bag) do
				local cooldown, cost = dummy:SetBagItem(bag, slot)
				local current, total = GetContainerItemDurability(bag, slot)

				if cost and cost > 0 then
					bgcost = bgcost + cost
				end

				if current and total and current > 0 and total > 0 then
					bgcurrent = bgcurrent + current
					bgtotal = bgtotal + total
				end
			end
		end
		bgcost = max(bgcost, 0)
		
		-- division by zero cause funny funny results
		-- if total durabilities are 0, there are no items to show
		bgcurrent 	= bgtotal == 0 and 1 or bgcurrent
		bgtotal 	= bgtotal == 0 and 1 or bgtotal
		eqcurrent 	= eqtotal == 0 and 1 or eqcurrent
		eqtotal 	= eqtotal == 0 and 1 or eqtotal

		GameTooltip:AddDoubleLine("|cFFFFFFFF"..CURRENTLY_EQUIPPED..": (|r" .. ("%d"):format(eqcurrent / eqtotal * 100) .. "|cFFFFFFFF%)|r", module:Tag("|cFFFFFFFF[money:" .. eqcost .. "]|r"))
		GameTooltip:AddDoubleLine("|cFFFFFFFF"..L["Bags"]..": (|r" .. ("%d"):format(bgcurrent / bgtotal * 100) .. "|cFFFFFFFF%)|r", module:Tag("|cFFFFFFFF[money:" .. bgcost .. "]|r"))
		GameTooltip:AddDoubleLine("|cFFFFFFFF"..L["Total"]..": (|r" .. ("%d"):format((bgcurrent + eqcurrent) / (bgtotal + eqtotal) * 100) .. "|cFFFFFFFF%)|r", module:Tag("|cFFFFFFFF[money:" .. (eqcost + bgcost) .. "]|r"))
		
		-- if (loadModule("GUIS-gUI: Merchant")) then -- deprecated
			-- GameTooltip:AddLine(" ")
			-- GameTooltip:AddLine(L["<Right-Click for options>"], unpack(C["value"]))
		-- end

		GameTooltip:Show()
	end)	
		
	gPanel:RegisterPlugin("friends", {
		tooltip = "friends";
		disabledTooltip = nil;
		interval = nil;
		events = {
			"FRIENDLIST_UPDATE";
			-- "PLAYER_ENTERING_WORLD";
			"BN_FRIEND_ACCOUNT_ONLINE";
			"BN_FRIEND_ACCOUNT_OFFLINE";
			"BN_FRIEND_TOON_OFFLINE";
			"BN_FRIEND_TOON_ONLINE";
			"BN_TOON_NAME_UPDATED";
			"BN_FRIEND_INFO_CHANGED";
		};
		scripts = nil;
		Update = function(self, event, ...) 
			local numberOfFriends = GetNumFriends()
			local online, total = 0, 0
			
			-- local realm friends
			if (numberOfFriends > 0) then
				local name, level, class, area, connected, status, note
				for i = 1, numberOfFriends do
					name, level, class, area, connected, status, note = GetFriendInfo(i)
					total = total + 1
					if (connected == 1) then
						online = online + 1
					end
				end
			end

			-- battlenet friends
			local numBNetTotal, numBNetOnline = BNGetNumFriends()
			online = online + numBNetOnline
			total = total + numBNetTotal
		
			local text = ""
			-- text = text .. color(FRIENDS .. ": ")
			text = text .. color((online), true)
			text = text .. color("/")
			text = text .. color((total), true)

			self:SetText(text)
		end;
		OnEvent = function(self, event, ...) 
			self:Update(event, ...)
		end;
		func = function(self)
			ToggleFriendsFrame(1) 
		end;
		OnLoad = function(self) 
			self:SetTexture(GetIcon())
			self:SetVertexColor(1, 0.82, 0)
			self:SetTexCoord(GetTexCoord("group"))
			self:SetText()
		end;
	})

	gPanel:RegisterPlugin("netstats", {
		tooltip = true;
		disabledTooltip = nil;
		interval = 5; -- slow interval
		events = nil;
		scripts = nil;
		Update = function(self, elapsed) 
			local down, up, chat, cast = GetNetStats()
			local msg = ""
			
			local gotContent
			-- if (db.showChatLatency) then
				-- msg = msg .. color(chat, true)
				-- msg = msg .. color(MILLISECONDS_ABBR)
				-- gotContent = true
			-- end
			
			-- if (db.showCastLatency) then
				if (gotContent) then
					msg = msg .. color(" - ")
				end
				msg = msg .. color(cast, true)
				msg = msg .. color(MILLISECONDS_ABBR)
				gotContent = true
			-- end
			
			-- if (db.showFPS) then
				if (gotContent) then
					msg = msg .. color(" - ")
				end
				msg = msg .. color(floor(GetFramerate()), true)
				msg = msg .. color(FPS_ABBR)
				gotContent = true
			-- end
			
			self:SetText(gotContent and msg or NOT_APPLICABLE)
			self:SetVertexColor(F.ColorGradient(cast, max(500, cast), 0, 1, 0, 1, 1, 0, 1, 0, 0))
		end;
		OnEvent = nil;
		OnLoad = function(self) 
			self:SetTexture(GetIcon())
			self:SetVertexColor(1, 0.82, 0)
			self:SetTexCoord(GetTexCoord("widescreen"))
		end;
		func = function(self)
		end;
	})

	gPanel:RegisterPlugin("guild", {
		tooltip = "guild";
		disabledTooltip = nil;
		interval = 15;
		events = {
			"PLAYER_GUILD_UPDATE";
			"GUILDTABARD_UPDATE";
			"GUILD_ROSTER_UPDATE"; 
			"NEUTRAL_FACTION_SELECT_RESULT";
		};
		scripts = {
			OnDisable = function(self) 
				-- self.emblem:Hide()
				-- self.background:Hide()
			end;
		};
		Update = function(self) 
			GuildRoster()
			-- self:OnEvent("PLAYER_GUILD_UPDATE")
		end;
		PostUpdate = function(self)
			if (IsInGuild()) or not(self:GetText()) then
			-- if ((IsInGuild()) and (not(self.emblem:IsShown()) or not(self.background:IsShown()))) or not(self:GetText()) then
				self:OnEvent("PLAYER_GUILD_UPDATE")
			end
		end;
		OnEvent = function(self, event, ...) 
			if (event == "PLAYER_ENTERING_WORLD") then
				if (IsInGuild()) and not(GuildFrame) then 
					LoadAddOn("Blizzard_GuildUI") 
				end
			end
			
			if (event == "NEUTRAL_FACTION_SELECT_RESULT") then
				self.tooltip = "guild"
				-- self:SetDesaturated(false)
			end
		
			if (event == "PLAYER_GUILD_UPDATE") or (event == "GUILDTABARD_UPDATE") or (event == "PLAYER_ENTERING_WORLD") then
				-- local bkgR, bkgG, bkgB, borderR, borderG, borderB, emblemR, emblemG, emblemB, emblemFilename = GetGuildLogoInfo("player")
				-- if (emblemFilename) and (IsInGuild()) then
					-- self:SetTexture(gUI:GetBlankTexture()) 
					-- self:SetTexCoord(0, 1, 0, 1)
					-- self.icon:SetAlpha(0)
					-- self.emblem:Show()
					-- self.background:Show()
					-- self.clickFrame:SetAllPoints(self.emblem)
					-- SetSmallGuildTabardTextures("player", self.emblem, self.background)
				-- else
					-- self:SetTexture(GetIcon())
					-- self:SetTexCoord(GetTexCoord("group"))
					-- self:SetText()
					-- self:SetVertexColor(1, 0.82, 0)
					-- self.icon:SetAlpha(1)
					-- self.emblem:Hide()
					-- self.background:Hide()
				-- end
			end
			
			if (event == "PLAYER_GUILD_UPDATE") or (event == "GUILD_ROSTER_UPDATE") or (event == "PLAYER_ENTERING_WORLD") then
				if (IsInGuild()) then
					F.updateGuildTable()
					local total, online = GetNumGuildMembers(true), #F.getGuildTable()
					
					-- self:SetText(L["Guild: %s"]:format(color(online, true) .. color("/") .. color(total, true)))
					self:SetText(color(online, true) .. color("/") .. color(total, true))
				else
					self:SetText(L["No Guild"])
				end
			end
		end;
		func = function(self) ToggleGuildFrame() end;
		OnLoad = function(self) 
			self:SetVertexColor(1, 0.82, 0)
			self:SetTexture(GetIcon())
			self:SetTexCoord(GetTexCoord("group"))
			-- self.icon:SetAlpha(1)
			
			-- if not(self.background) then
				-- local background = self:CreateTexture(nil, "ARTWORK")
				-- background:Hide()
				-- background:SetTexture([[Interface\Buttons\UI-MicroButton-Guild-Banner]])
				-- background:SetSize(22, 40)
				-- background:SetPoint("CENTER", self.icon, "CENTER", 0, 7)
				-- self.background = background
			-- end
			-- if not(self.emblem) then
				-- local emblem = self:CreateTexture(nil, "OVERLAY")
				-- emblem:Hide()
				-- emblem:SetTexture([[Interface\GuildFrame\GuildEmblems_01]])
				-- emblem:SetSize(12, 12)
				-- emblem:SetPoint("CENTER", self.icon, "CENTER", 0, 1)
				-- self.emblem = emblem
			-- end
			if (IsTrialAccount()) then
				self:SetText()
				-- self:SetDesaturated(true)
				self.tooltip = "restricted-account"
			else 
				local factionGroup = UnitFactionGroup("player")
				if (factionGroup) and (factionGroup == "Neutral") then
					self:SetText()
					-- self:SetDesaturated(true)
					self.tooltip = "restricted-pandaren"
				end
			end
		end;
	})

	gPanel:RegisterPlugin("bagspace", {
		tooltip = "bagspace";
		disabledTooltip = nil;
		interval = nil;
		events = {
			"PLAYER_LOGIN"; 
			"BAG_UPDATE";
		};
		scripts = nil;
		Update = function(self) 
			local text = ""
			-- text = text .. color(L["Bags"]..": ")
			text = text .. module:Tag(color("[free:backpack+bags]", true))
			text = text .. module:Tag(color("/"))
			text = text .. module:Tag(color("[max:backpack+bags]", true))
			self:SetText(text)
		end;
		OnEvent = function(self, event, ...) 
			self:Update()
		end;
		OnLoad = function(self) 
			self:SetTexture(M("Button", "gUI™ BagIcon"))
		end;
		func = function(self) OpenAllBags() end;
	})

	gPanel:RegisterPlugin("gold", {
		tooltip = "currencies";
		disabledTooltip = nil;
		interval = nil;
		events = {
			"ADDON_LOADED";
			"PLAYER_MONEY";
			"PLAYER_ENTERING_WORLD";
			"PLAYER_LOGIN";
		};
		scripts = nil;
		Update = function(self) 
			local money = GetMoney()
			-- if (money >= 10000) then
				-- money = floor(money/100) * 100
			-- end
			
			-- if (money >= 1000000) then
				-- money = floor(money/10000) * 10000
			-- end
					
			self:SetText(module:Tag(color(("[money:%s]"):format(money), false)))
		end;
		OnEvent = function(self, event, ...) 
			self:Update()
		end;
		func = function(self) 
			ToggleCharacter("TokenFrame")
		end;
	})

	gPanel:RegisterPlugin("durability", {
		tooltip = "durability";
		disabledTooltip = nil;
		interval = nil;
		events = {
			"UPDATE_INVENTORY_DURABILITY";
			"PLAYER_LOGIN";
			"PLAYER_ENTERING_WORLD";
		};
		scripts = nil;
		Update = function(self) 
			self.current = 0
			self.total = 0

			for _, slot in ipairs(slots) do
				local item = _G["Character" .. slot]
				local current, total = GetInventoryItemDurability(item:GetID())
				
				if current and total then
					self.current = self.current + current
					self.total = self.total + total
				end
			end
			
			local percent = 100
			if (self.total > 0) then
				percent = max(0, self.current / self.total * 100)
			end
			
			local text = ""
			-- text = text .. color(ARMOR .. ": ")
			text = text .. color("%d", true):format(percent)
			text = text .. color("%")
	
			self:SetText(text)
			self:SetVertexColor(F.ColorGradient(percent, 100))
		end;
		OnLoad = function(self) 
			self:SetTexture(GetIcon())
			self:SetTexCoord(GetTexCoord("person"))
			self:SetVertexColor(F.ColorGradient(100, 100))
		end;
		OnEvent = function(self, event, ...) 
			self:Update()
		end;
	})
end

module.PostUpdatePanelSize = function(self)
	panels.left:SetSize(F.fixPanelWidth(), F.fixPanelHeight())
	panels.right:SetSize(F.fixPanelWidth(), F.fixPanelHeight())
end

module.PostUpdateSettings = function(self)
	for name, info in pairs(db.backdrops) do
		backdrops[name]:SetShown((actionbars) and (actionbars:GetLayout() == 1) and info.show)
	end
	
	-- update panel content and visibility
	local panel, cell, plugin
	for name, info in pairs(db.panels) do
		panel = panels[name]
		panel:SetSize(F.fixPanelWidth(), F.fixPanelHeight())

		-- update visibility
		if (info.show ~= panel:IsShown()) then
			panel:SetShown(info.show)
			if (panel:IsShown()) then
				panel:Update()
			end
		end
		
		-- check for changed plugins
		for cellNum = 1, panel:GetNumActiveCells() do
			cell = panel:GetCell(cellNum)
			for pluginNum = 1, cell:GetNumPlugins() do
				plugin = cell:GetPlugin(pluginNum)
				if (info.plugins[cellNum]) and (plugin:GetAction() ~= info.plugins[cellNum]) then
					plugin:SetAction(info.plugins[cellNum])
				end
			end
		end
	end
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	-- gUIDB = gUI:GetCurrentOptionsSet() -- we modify global options here
	
	Register() -- register plugins and tooltips with gPanel
	
	-- name references for the framehandler
	local names = {
		backdrops = {
			bottom = L["Bottom Backdrop"];
			left = L["Bottom Left Backdrop"];
			right = L["Bottom Right Backdrop"];
			side = L["Side Backdrop"];
		};
		panels = {
			left = L["Left Infopanel"];
			right = L["Right Infopanel"];
		};
	}

	-- create the movable backdrops
	local backdrop
	for name, info in pairs(db.backdrops) do
		backdrop = CreateFrame("Frame", nil, gUI:GetAttribute("vehiclehider"))
		backdrop:SetFrameStrata("BACKGROUND")
		backdrop:SetFrameLevel(10)
		backdrop:SetSize(unpack(info.size))
		backdrop:SetShown((actionbars) and (actionbars:GetLayout() == 1) and info.show)
	
		gUI:SetUITemplate(backdrop, "backdrop")
		gUI:CreateUIShadow(backdrop)
		gUI:PlaceAndSave(backdrop, names.backdrops[name], db.backdrops[name].place, unpack(defaults.backdrops[name].place))
		gUI:AddObjectToFrameGroup(backdrop, "uipanels")
		
		backdrops[name] = backdrop
	end
	
	-- create the infopanels
	local panel, candy, cell, plugin
	for name, info in pairs(db.panels) do
		panel = self:CreateUIPanel(name, gUI:GetAttribute("parent"))
		panel:SetFrameStrata("BACKGROUND")
		panel:SetFrameLevel(10)
		-- panel:SetSize(unpack(info.size))
		panel:SetShown(info.show)
		panel:SetPanelSize(#info.plugins, 1)
		panel:SetSize(F.fixPanelWidth(), F.fixPanelHeight())

		-- local gloss = gUI:SetUITemplate(panel, "gloss")
		-- gloss:SetPoint("TOPLEFT", 3, -3)
		-- gloss:SetPoint("BOTTOMRIGHT", -3, 3)
		-- gloss:SetAlpha(gUI:GetGlossAlpha(true))

		-- local shade = gUI:SetUITemplate(panel, "shade")
		-- shade:SetPoint("TOPLEFT", 3, -3)
		-- shade:SetPoint("BOTTOMRIGHT", -3, 3)
		
		for i = 1, #info.plugins do
			cell = panel:NewCell()
			cell:SetMaxPlugins(1)
			cell:SetJustifyH(i == 1 and "LEFT" or i == #info.plugins and "RIGHT" or "CENTER")			
			cell:SetJustifyV("MIDDLE")	
			cell:SpawnPlugin(info.plugins[i])
		end
		
		gUI:SetUITemplate(panel, "backdrop")
		gUI:CreateUIShadow(panel)
		gUI:PlaceAndSave(panel, names.panels[name], db.panels[name].place, unpack(defaults.panels[name].place))
		gUI:AddObjectToFrameGroup(panel, "uipanels")
		
		panels[name] = panel
	end

	-- make sure sizes update when the user changes scale or screen size
	self:RegisterEvent("PLAYER_ENTERING_WORLD", self.PostUpdatePanelSize)
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", self.PostUpdatePanelSize)
	self:RegisterEvent("UI_SCALE_CHANGED", self.PostUpdatePanelSize)
	
	self:PostUpdateSettings()
	
	-- optionsmenu
	do
		local menuTable = {
			{
				type = "group";
				name = module:GetName();
				order = 1;
				virtual = true;
				children = {
					{
						type = "widget";
						element = "Title";
						order = 1;
						msg = L["Panels & Backdrops"];
					};
					{
						type = "widget";
						element = "Text";
						order = 2;
						msg = L["UI Panels are special frames providing information about the game as well allowing you to easily change settings. Here you can configure the visibility and behavior of these panels. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."];
					};
					{
						type = "group";
						order = 5;
						virtual = true;
						children = {
							{
								type = "widget";
								element = "Header";
								order = 1;
								msg = L["Visible Panels"];
							};
							{
								type = "widget";
								element = "Text";
								order = 2;
								msg = L["Here you can decide which of the UI panels should be visible. They can still be moved with |cFF4488FF/glock|r when hidden."];
							};
							{
								type = "group";
								order = 5;
								virtual = true;
								children = {
									{ 
										type = "widget";
										element = "CheckButton";
										name = "showBottomRightPanel";
										order = 20;
										width = "full"; 
										msg = L["Show the bottom right UI panel"];
										desc = nil;
										set = function(self) 
											db.panels.right.show = not(db.panels.right.show)
											module:PostUpdateSettings()
										end;
										get = function() return db.panels.right.show end;
									};
									{ 
										type = "widget";
										element = "CheckButton";
										name = "showBottomLeftPanel";
										order = 30;
										width = "full"; 
										msg = L["Show the bottom left UI panel"];
										desc = nil;
										set = function(self) 
											db.panels.left.show = not(db.panels.left.show)
											module:PostUpdateSettings()
										end;
										get = function() return db.panels.left.show end;
									};
								};
							};
							{
								type = "group";
								order = 10;
								virtual = true;
								children = {
									{
										type = "widget";
										element = "Header";
										order = 100;
										msg = L["Visible Backdrops"];
									};
									{
										type = "widget";
										element = "Text";
										order = 101;
										msg = L["Here you can decide which of the backdrops should be visible."];
									};
									{ 
										type = "widget";
										element = "CheckButton";
										name = "showBottomBackdrop";
										order = 110;
										width = "full"; 
										msg = L["Bottom Backdrop"];
										desc = nil;
										set = function(self) 
											db.backdrops.bottom.show = not(db.backdrops.bottom.show)
											module:PostUpdateSettings()
										end;
										get = function() return db.backdrops.bottom.show end;
									};
									{ 
										type = "widget";
										element = "CheckButton";
										name = "showBottomLeftBackdrop";
										order = 120;
										width = "full"; 
										msg = L["Bottom Left Backdrop"];
										desc = nil;
										set = function(self) 
											db.backdrops.left.show = not(db.backdrops.left.show)
											module:PostUpdateSettings()
										end;
										get = function() return db.backdrops.left.show end;
									};
									{ 
										type = "widget";
										element = "CheckButton";
										name = "showBottomRightBackdrop";
										order = 130;
										width = "full"; 
										msg = L["Bottom Right Backdrop"];
										desc = nil;
										set = function(self) 
											db.backdrops.right.show = not(db.backdrops.right.show)
											module:PostUpdateSettings()
										end;
										get = function() return db.backdrops.right.show end;
									};
								};
							};
						};
					};
				};
			};
		}
		local restoreDefaults = function()
			if (InCombatLockdown()) then 
				print(L["Can not apply default settings while engaged in combat."])
				return
			end
			self:ResetCurrentOptionsSetToDefaults()
		end
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["Panels & Backdrops"], "default", restoreDefaults)
	end
end

module.OnEnable = function(self)
end

module.OnDisable = function(self)
end
