--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local Carbonite = IsAddOnLoaded("Carbonite")
local MapInMap = NxData and NxData.MapMMOwn
if (Carbonite) and (MapInMap) then
	return
end

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Minimap")

local floor, min = math.floor, math.min
local ipairs, select, unpack = ipairs, select, unpack
local tinsert, tsort = table.insert, table.sort

local ExpandAllFactionHeaders = ExpandAllFactionHeaders
local GetFactionInfo = GetFactionInfo
local GetNumFactions = GetNumFactions
local GetWatchedFactionInfo = GetWatchedFactionInfo
local GetXPExhaustion = GetXPExhaustion
local HasNewMail = HasNewMail
local ReputationFrame_Update = ReputationFrame_Update
local SetSelectedFaction = SetSelectedFaction
local ToggleCharacter = ToggleCharacter
local UnitFactionGroup = UnitFactionGroup
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax

local L, C, F, M, db

-- panels
local MAX_DOCKS = 3
local DOCK_WIDTH = MINIMAP_SIZE -- actual visible width is 6px more, due to outside borders
local dockParent = Minimap -- will make this movable sooner or later

-- minimap
local initMap
local updateCoordinates
local updateZone, updateDifficulty
local getTime, updateTime
local updateDock
local zoneText, zoneTextButton
local difficulty, mapClock, calendar, coordinates

local defaults = {
	-- minimap position
	position = { "TOPLEFT", "UIParent", "TOPLEFT", 8, -8 };

	useMouseWheelZoom = true;
	useButtonBag = true;
	useMiddleMenu = true;

	showDifficulty = true;
	showNewEvents = true;
	
	showLocation = true;
	showCalendar = true;
	showClock = true;
		use24hrClock = true;
		useSeconds = false;
		useGameTime = false;
	-- showCoordinates = true;
	-- showMapButton = true;

	-- visible on hover
	showCalendarOnHover = true; -- hide this fugly thing by default
	showClockOnHover = false;
	showLocationOnHover = false;
}

------------------------------------------------------------------------------------------------------------
-- 	Minimap
------------------------------------------------------------------------------------------------------------
-- updates time
getTime = function()
	local h,m,s,suffix, msg
	if (db.useGameTime) then
		h, m = GetGameTime()
		if (db.use24hrClock) then
			suffix = ""
		else
			if (h > 12) then
				h = h - 12
				suffix = " " .. TIMEMANAGER_PM
			else
				suffix = " " .. TIMEMANAGER_AM
			end
		end
		msg = ("%02d:%02d%s"):format(h, m, suffix)
	else
		if (db.use24hrClock) then
			h = "%H"
			suffix = ""
		else
			h = "%I"
			suffix = " %p"
		end
		if (db.useSeconds) then
			s = ":%S"
		else
			s = ""
		end
		msg = date(h .. ":%M" .. s .. suffix)
	end
	return msg
end

local CALENDAR_WEEKDAY_NAMES = {
	WEEKDAY_SUNDAY,
	WEEKDAY_MONDAY,
	WEEKDAY_TUESDAY,
	WEEKDAY_WEDNESDAY,
	WEEKDAY_THURSDAY,
	WEEKDAY_FRIDAY,
	WEEKDAY_SATURDAY
}

local CALENDAR_FULLDATE_MONTH_NAMES = {
	FULLDATE_MONTH_JANUARY,
	FULLDATE_MONTH_FEBRUARY,
	FULLDATE_MONTH_MARCH,
	FULLDATE_MONTH_APRIL,
	FULLDATE_MONTH_MAY,
	FULLDATE_MONTH_JUNE,
	FULLDATE_MONTH_JULY,
	FULLDATE_MONTH_AUGUST,
	FULLDATE_MONTH_SEPTEMBER,
	FULLDATE_MONTH_OCTOBER,
	FULLDATE_MONTH_NOVEMBER,
	FULLDATE_MONTH_DECEMBER,
}

getDate = function()
	local weekday = CALENDAR_WEEKDAY_NAMES[tonumber(date("%w")) + 1]
	local day = date("%d")
	local month = CALENDAR_FULLDATE_MONTH_NAMES[tonumber(date("%m"))]
	local year = date("%Y")
	return weekday, day, month, year
end

updateTime = function()
	if (mapClock:IsVisible()) then
		mapClock:SetText(getTime())
	end
end

-- update player coordinates
updateCoordinates = function()
	if not(coordinates:IsVisible()) then return end
	local x, y = GetPlayerMapPosition("player")
	if ((x == 0) and (y == 0)) or not x or not y then
		coordinates:SetAlpha(0)
	else
		coordinates:SetAlpha(1)
		coordinates:SetFormattedText("%.2f %.2f", x*100, y*100)
	end
end

-- update the zone title
updateZone = function(self, event, ...)
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	local zoneName = GetZoneText()
	local subzoneName = GetSubZoneText()
	local minimapZoneName = GetMinimapZoneText()

	zoneText[1]:SetText(minimapZoneName)
	zoneText[2]:SetText("")
	zoneText[3]:SetText("")
	if (pvpType == "sanctuary") then
		zoneText[1]:SetTextColor(0.41, 0.8, 0.94)
	elseif (pvpType == "arena") then
		zoneText[1]:SetTextColor(1.0, 0.1, 0.1)
	elseif (pvpType == "friendly") then
		zoneText[1]:SetTextColor(0.1, 1.0, 0.1)
	elseif (pvpType == "hostile") then
		zoneText[1]:SetTextColor(1.0, 0.1, 0.1)
	elseif (pvpType == "contested") then
		zoneText[1]:SetTextColor(1.0, 0.7, 0.0)
	elseif (pvpType == "combat") then
		zoneText[1]:SetTextColor(1.0, 0.1, 0.1)
	else
		zoneText[1]:SetTextColor(1.0, 0.9294, 0.7607)
	end
	
	-- reposition the clickable button
	local msg
	local last = 1
	for i = 2, 3 do
		msg = zoneText[i]:GetText()
		if (msg) and (msg ~= "") then
			last = i
		end
	end
	zoneTextButton:ClearAllPoints()
	zoneTextButton:SetPoint("TOP", zoneText[1], "TOP", 0, 0)
	zoneTextButton:SetPoint("LEFT", zoneText[1], "LEFT", 0, 0)
	zoneTextButton:SetPoint("RIGHT", zoneText[1], "RIGHT", 0, 0)
	zoneTextButton:SetPoint("BOTTOM", zoneText[last], "BOTTOM", 0, 0)
	
	-- local desc = 3
	-- if (subzoneName == zoneName) then 
		-- subzoneName = "" 
		-- desc = 2
		-- zoneText[3]:SetText("")
	-- end
		
	-- zoneText[1]:SetTextColor(1, 1, 1)
	-- zoneText[1]:SetText(zoneName)
	-- zoneText[2]:SetText(subzoneName)
	-- if (pvpType == "sanctuary") then
		-- zoneText[2]:SetTextColor(0.41, 0.8, 0.94)
		-- zoneText[3]:SetTextColor(0.41, 0.8, 0.94)
		-- zoneText[desc]:SetText(SANCTUARY_TERRITORY)
	-- elseif (pvpType == "arena") then
		-- zoneText[2]:SetTextColor(1.0, 0.1, 0.1)
		-- zoneText[3]:SetTextColor(1.0, 0.1, 0.1)
		-- zoneText[desc]:SetText(FREE_FOR_ALL_TERRITORY)
	-- elseif (pvpType == "friendly") then
		-- zoneText[2]:SetTextColor(0.1, 1.0, 0.1)
		-- zoneText[3]:SetTextColor(0.1, 1.0, 0.1)
		-- zoneText[desc]:SetText(format(FACTION_CONTROLLED_TERRITORY, factionName))
	-- elseif (pvpType == "hostile") then
		-- zoneText[2]:SetTextColor(1.0, 0.1, 0.1)
		-- zoneText[3]:SetTextColor(1.0, 0.1, 0.1)
		-- zoneText[desc]:SetText(format(FACTION_CONTROLLED_TERRITORY, factionName))
	-- elseif (pvpType == "contested") then
		-- zoneText[2]:SetTextColor(1.0, 0.7, 0.0)
		-- zoneText[3]:SetTextColor(1.0, 0.7, 0.0)
		-- zoneText[desc]:SetText(CONTESTED_TERRITORY)
	-- elseif (pvpType == "combat") then
		-- zoneText[2]:SetTextColor(1.0, 0.1, 0.1)
		-- zoneText[3]:SetTextColor(1.0, 0.1, 0.1)
		-- zoneText[desc]:SetText(COMBAT_ZONE)
	-- else
		-- zoneText[2]:SetTextColor(1.0, 0.9294, 0.7607)
		-- zoneText[3]:SetTextColor(1.0, 0.9294, 0.7607)
		-- zoneText[desc]:SetText("")
	-- end

end

-- update the instance difficulty
updateDifficulty = function(self, event, ...)
	local inInstance, instanceType = IsInInstance()

	local text = ""
	if (inInstance) then
		local name, type, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = GetInstanceInfo()
		
		local isHeroic
		if (instanceType == "party") then
			if (difficultyIndex == 1) then
				text = "5"
			elseif (difficultyIndex == 2) then
				text = "5"
				isHeroic = true
			end
		elseif (instanceType == "raid") then
			if (difficultyIndex == 1) then
				if (maxPlayers == 40) then
					text = "40"
				else
					text = "10"
				end
			elseif (difficultyIndex == 2) then
				text = "25"
			elseif (difficultyIndex == 3) then
				text = "10" 
				isHeroic = true
			elseif (difficultyIndex == 4) then
				text = "25"
				isHeroic = true
			end
		end
		
		-- for instances with dynamic difficulty, where the difficulty can be changed inside
		-- (Icecrown Citadel)
		if isDynamic then
			if (dynamicDifficulty == 1) then
				isHeroic = true
			end
		end
		
		-- add the heroic skull icon if this is any form of heroic
		if isHeroic then 
			text = text .. M("Iconstring", "HeroicSkull")
		end
	end
	
	difficulty:SetText(text)
	
	-- if (GuildInstanceDifficulty) then 
		-- gUI:HideObject(GuildInstanceDifficulty)
	-- end
end

-- updates all positions, not actually a dock yet
updateDock = function()
	-- calendar
	calendar:ClearAllPoints()
	calendar:SetPoint("BOTTOMLEFT", 2, 2)

	-- clock
	mapClock:ClearAllPoints()
	mapClock:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 4)
	-- mapClock:SetPoint("TOP", zoneTextButton, "BOTTOM", 0, -4) -- under the zone name
	
	-- location
	zoneText[1]:ClearAllPoints()
	zoneText[1]:SetPoint("TOP", Minimap, "TOP", 0, -6)
	
	-- mail
	if (mapClock:IsVisible()) and (mapClock:GetAlpha() > 0) then
		MiniMapMailFrame:ClearAllPoints()
		MiniMapMailFrame:SetPoint("BOTTOM", mapClock, "TOP", 0, 4) -- above the clock
		-- MiniMapMailFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 4, 4) -- bottomleft corner
		-- MiniMapMailFrame:SetPoint("TOP", zoneTextButton, "BOTTOM", 0, 0) -- under the zone name
		-- MiniMapMailFrame:SetPoint("BOTTOM", calendar, "TOP", 0, 0) -- above calendar
		-- MiniMapMailFrame:SetPoint("BOTTOMLEFT", calendar, "BOTTOMRIGHT", 0, 0) -- left of the calendar
	else 
		MiniMapMailFrame:ClearAllPoints()
		MiniMapMailFrame:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 4)
	end
	
	-- coordinates

	-- map
	
	-- new events
	
	-- queue status
	QueueStatusMinimapButton:ClearAllPoints()
	QueueStatusMinimapButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 2, -2) -- very large padding on this one
end

initMap = function(self)
	-- local minimap = CreateFrame("Frame", nil, gUI:GetAttribute("parent"), "SecureHandlerStateTemplate") -- and this is secure... why?
	local minimap = CreateFrame("Frame", nil, gUI:GetAttribute("parent"))
	minimap:SetSize(MINIMAP_SIZE, MINIMAP_SIZE) -- default is 140x140
	minimap:SetFrameStrata("BACKGROUND")
	minimap:SetFrameLevel(50)
	
	gUI:SetUITemplate(minimap, "backdrop")
	gUI:CreateUIShadow(minimap) 
	
	self:PlaceAndSave(minimap, "Minimap", db.position, unpack(defaults.position))
	self:AddObjectToFrameGroup(minimap, "uipanels")
	
	Minimap:SetParent(minimap)
	Minimap:SetMaskTexture(M("Mask", "gUI™ Square"))
	-- Minimap:SetFrameStrata("BACKGROUND")
	-- Minimap:SetFrameLevel(50)
	-- Minimap:SetPlayerTextureHeight(48) -- removed in 5.2
	-- Minimap:SetPlayerTextureWidth(48) -- removed in 5.2
	Minimap:ClearAllPoints()
	Minimap:SetSize(MINIMAP_SIZE - 6, MINIMAP_SIZE - 6) 
	Minimap:SetPoint("TOPLEFT", 3, -3)
	Minimap:SetPoint("BOTTOMRIGHT", -3, 3)
	
	-- load the clock, this is far simpler then waiting for it
	-- seems a bit outlandish though, we force load it to forcefully disable it.
	-- "Wake up Mrs Robinson, it's time for you to go to sleep!"
	if not(IsAddOnLoaded("Blizzard_TimeManager")) then LoadAddOn("Blizzard_TimeManager") end
	
	-- hide objects we don't want
	gUI:HideObjects( 
		GameTimeFrame, 
		TimeManagerClockButton,
		MinimapBorder, 
		MinimapBorderTop, 
		MinimapCluster,
		MiniMapMailBorder, 
		MinimapBackdrop, -- MinimapCompassTexture
		MinimapNorthTag, 
		MiniMapTracking, 
		MiniMapTrackingButton, 
		MiniMapVoiceChatFrame, 
		MiniMapWorldMapButton, 
		MinimapZoomIn, 
		MinimapZoomOut, 
		MinimapZoneTextButton, 
		MiniMapInstanceDifficulty, -- 3.3
		GuildInstanceDifficulty, -- 4.0.6
		QueueStatusMinimapButtonBorder -- 5.0.4
	)

	-- the new waiting texture just doesn't suit anything at all
	-- so for now we're merely making it look like the default eye
	LFG_EYE_TEXTURES["unknown"] = LFG_EYE_TEXTURES["default"] -- this was needed in 4.3 at least

	QueueStatusMinimapButton:SetParent(Minimap)
	-- QueueStatusMinimapButton:ClearAllPoints()
	-- QueueStatusMinimapButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
	
	local positionQueueFrame = function(self)
		local point, rpoint, x, y
		if ((GetScreenWidth() - minimap:GetRight()) > minimap:GetLeft()) then
			if ((GetScreenHeight() - minimap:GetTop()) > minimap:GetBottom()) then
				point, rpoint, x, y = "BOTTOMLEFT", "TOPRIGHT", 4, 4
			else
				point, rpoint, x, y = "TOPLEFT", "BOTTOMRIGHT", 4, -4
			end
		else
			if ((GetScreenHeight() - minimap:GetTop()) > minimap:GetBottom()) then
				point, rpoint, x, y = "BOTTOMRIGHT", "TOPLEFT", -4, 4
			else
				point, rpoint, x, y = "TOPRIGHT", "BOTTOMLEFT", -4, -4
			end
		end
		if (point) and (rpoint) and (x) and (y) then
			self:ClearAllPoints()
			self:SetPoint(point, minimap, rpoint, x, y)
		end
	end
	QueueStatusFrame:HookScript("OnShow", positionQueueFrame)
	
	gUI:DisableTextures(QueueStatusFrame)
	gUI:SetUITemplate(QueueStatusFrame, "backdrop")
	
	-- mouse wheel zooming
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(self, d)
		if not(db.useMouseWheelZoom) then return end
		if (d > 0) then
			Minimap:SetZoom(min(Minimap:GetZoomLevels(), Minimap:GetZoom() + 1))
		elseif (d < 0) then
			Minimap:SetZoom(max(0, Minimap:GetZoom() - 1))
		end
	end)
	
	MiniMapMailFrame:SetSize(24, 24)
	MiniMapMailFrame:SetParent(Minimap)
	-- MiniMapMailFrame:ClearAllPoints()
	-- MiniMapMailFrame:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 20) -- 4
	MiniMapMailIcon:SetTexture(M("Icon", "gUI™ MailBox2"))
	MiniMapMailIcon:SetAllPoints(MiniMapMailFrame)

	-- shaded edges
	local shade = Minimap:CreateTexture()
	shade:SetDrawLayer("BORDER", 2)
	shade:SetTexture(M("Background", "gUI™ LargeShade"))
	shade:SetVertexColor(0, 0, 0)
	shade:SetAlpha(1/3)
	shade:ClearAllPoints()
	shade:SetPoint("TOPLEFT", -1, 1)
	shade:SetPoint("BOTTOMRIGHT", 1, -1)
	
-- PVPHonor_UpdateQueueStatus	
	zoneTextButton = CreateFrame("Frame", nil, Minimap)
	zoneTextButton:EnableMouse(true)
	zoneTextButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	zoneTextButton:SetScript("OnEnter", function() 
		local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
		local zoneName = GetZoneText()
		local subzoneName = GetSubZoneText()
		if (subzoneName == zoneName) then subzoneName = "" end
		
		GameTooltip:SetOwner(Minimap, "ANCHOR_PRESERVE")
		GameTooltip:ClearAllPoints()
		if ((GetScreenWidth() - minimap:GetRight()) > minimap:GetLeft()) then
			GameTooltip:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 12, 0)
		else
			GameTooltip:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -12, 0)
		end
		GameTooltip:AddLine(zoneName, 1.0, 1.0, 1.0 )
		
		if (pvpType == "sanctuary") then
			GameTooltip:AddLine(subzoneName, 0.41, 0.8, 0.94 )	
			GameTooltip:AddLine(SANCTUARY_TERRITORY, 0.41, 0.8, 0.94)
		elseif (pvpType == "arena") then
			GameTooltip:AddLine(subzoneName, 1.0, 0.1, 0.1 )	
			GameTooltip:AddLine(FREE_FOR_ALL_TERRITORY, 1.0, 0.1, 0.1)
		elseif (pvpType == "friendly") then
			GameTooltip:AddLine(subzoneName, 0.1, 1.0, 0.1 )
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 0.1, 1.0, 0.1)
		elseif (pvpType == "hostile") then
			GameTooltip:AddLine(subzoneName, 1.0, 0.1, 0.1 );	
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 1.0, 0.1, 0.1)
		elseif (pvpType == "contested") then
			GameTooltip:AddLine(subzoneName, 1.0, 0.7, 0.0 )
			GameTooltip:AddLine(CONTESTED_TERRITORY, 1.0, 0.7, 0.0)
		elseif (pvpType == "combat") then
			GameTooltip:AddLine(subzoneName, 1.0, 0.1, 0.1 )
			GameTooltip:AddLine(COMBAT_ZONE, 1.0, 0.1, 0.1)
		else
			GameTooltip:AddLine(subzoneName, 1.0, 0.9294, 0.7607)
		end
		GameTooltip:Show()
	end)
	
	zoneText = {}
	for i = 1,3 do
		zoneText[i] = zoneTextButton:CreateFontString(nil, "OVERLAY")
		zoneText[i]:ClearAllPoints()
		if (i == 1) then
			zoneText[i]:SetPoint("TOP", Minimap, "TOP", 0, -6)
		else
			zoneText[i]:SetPoint("TOP", zoneText[i-1], "BOTTOM", 0, -2)
		end
		zoneText[i]:SetWidth(Minimap:GetWidth() - 4)
		zoneText[i]:SetNonSpaceWrap(false)
		zoneText[i]:SetFontObject(gUI_TextFontSmallBoldOutline)
		zoneText[i]:SetJustifyH("CENTER")
		zoneText[i]:SetJustifyV("BOTTOM")
	end
	zoneTextButton:SetAllPoints(zoneText[1])
	
	-- make a custom calendar button. wohoo!
	calendar = CreateFrame("Frame", nil, Minimap)
	calendar:SetFrameLevel(calendar:GetFrameLevel() + 2) -- want it above the title and other stuff
	calendar:SetSize(24, 24)
	calendar.icon = calendar:CreateTexture()
	calendar.icon:SetDrawLayer("ARTWORK")
	calendar.icon:SetAllPoints()
	calendar.icon:SetTexture(M("Icon", "GlyphIcons"))
	calendar.icon:SetTexture(M("Icon", "GlyphIcons"))
	calendar.icon:SetVertexColor(1, 0.82, 0)
	
	-- don't ask
	local x, y = 12, 2
	calendar.icon:SetTexCoord((x-1)*32/512, (x)*32/512, (y-1)*32/512, (y)*32/512)
	
	calendar:SetScript("OnMouseDown", function(self, button) 
		if (button == "LeftButton") then
			ToggleCalendar() 
		end
	end)
	calendar:SetScript("OnEnter", function(self) 
		GameTooltip:SetOwner(Minimap, "ANCHOR_PRESERVE")
		GameTooltip:ClearAllPoints()
		if ((GetScreenWidth() - minimap:GetRight()) > minimap:GetLeft()) then
			GameTooltip:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -12)
		else
			GameTooltip:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -12)
		end
		local weekday, day, month, year = getDate()
		GameTooltip:AddLine(("%s, %s %s, %s"):format(weekday, month, day, year), 1.0, 1.0, 1.0 )
		GameTooltip:AddLine(L["<Left-Click to toggle the Calendar>"], unpack(C.value))
		GameTooltip:Show()
	end)
	calendar:SetScript("OnLeave", function() GameTooltip:Hide() end)
	
	-- make a custom clock
	mapClock = Minimap:CreateFontString(nil, "OVERLAY")
	mapClock:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 4)
	mapClock:SetFontObject(gUI_DisplayFontTinyOutlineWhite)
	mapClock:SetJustifyH("CENTER")
	mapClock:SetJustifyV("BOTTOM")
	
	local clickClock = CreateFrame("Frame", nil, Minimap)
	clickClock:SetAllPoints(mapClock)
	clickClock:SetScript("OnMouseDown", function(self) 
		StopwatchFrame:SetShown(not(StopwatchFrame:IsShown()))
	end)
	
	StopwatchFrame:ClearAllPoints()
	StopwatchFrame:SetPoint("CENTER")
	
	-- create our own instance difficulty overlay
	difficulty = Minimap:CreateFontString(nil, "HIGHLIGHT")
	difficulty:SetFontObject(gUI_DisplayFontLargeBoldOutline)
	difficulty:SetTextColor(unpack(C["index"]))
	difficulty:SetJustifyH("CENTER")
	difficulty:SetPoint("CENTER", Minimap, "CENTER", 0, 0)

	-- add our middleclick menu
	do
		local menuFrame = CreateFrame("Frame", "MinimapMiddleClickMenu", Minimap, "UIDropDownMenuTemplate")
		local menuList = {}
		tinsert(menuList, {
				text = L["Calendar"];
				notCheckable = true;
				func = function() ToggleCalendar() end;
			})
		tinsert(menuList, {
				text = CHARACTER_BUTTON;
				notCheckable = true;
				func = function() ToggleCharacter("PaperDollFrame") end
			})
		tinsert(menuList, {
				text = SPELLBOOK_ABILITIES_BUTTON;
				notCheckable = true;
				func = function() if not(InCombatLockdown()) then ToggleFrame(SpellBookFrame) end end
			})
		tinsert(menuList, {
				text = TALENTS_BUTTON;
				notCheckable = true;
				func = function() 
					if not(InCombatLockdown()) then
						if not(PlayerTalentFrame) then LoadAddOn("Blizzard_TalentUI") end 
						if not(GlyphFrame) then LoadAddOn("Blizzard_GlyphUI") end 
						if not(PlayerTalentFrame:IsShown()) then ShowUIPanel(PlayerTalentFrame) end
					end
				end
			})
		tinsert(menuList, {
				text = ACHIEVEMENT_BUTTON; 
				notCheckable = true;
				func = function() ToggleAchievementFrame() end;
			})
		tinsert(menuList, {
				text = QUESTLOG_BUTTON;
				notCheckable = true;
				func = function() ToggleFrame(QuestLogFrame) end
			})
		if not((IsTrialAccount) and (IsTrialAccount())) then
			tinsert(menuList, {
				-- text = (IsInGuild()) and GUILD or LOOKINGFORGUILD;
				text = GUILD; -- bugs out sometimes, so better just having it say "Guild"
				notCheckable = true;
				func = function() 
					if (IsInGuild()) then
						GuildFrame_LoadUI()
						if ( GuildFrame_Toggle ) then
							GuildFrame_Toggle()
						end
					else
						ToggleGuildFinder()
					end
				end
			})
		end
		tinsert(menuList, {
				text = PLAYER_V_PLAYER;
				notCheckable = true;
				func = function() 
					if (tonumber((select(2, GetBuildInfo()))) >= 16650) then
						TogglePVPUI()
					else
						TogglePVPFrame()
						-- ToggleFrame(PVPFrame) 
					end
				end
			})
		tinsert(menuList, {
				text = DUNGEONS_BUTTON; 
				notCheckable = true;
				func = function() 
					-- ToggleLFDParentFrame() 
					PVEFrame_ToggleFrame()
				end;
			})
		tinsert(menuList, {
				text = MOUNTS_AND_PETS;
				notCheckable = true;
				func = function() 
					TogglePetJournal()
				end
			})
		tinsert(menuList, {
				text = ENCOUNTER_JOURNAL;
				notCheckable = true;
				func = function() 
					if (UnitLevel("player") >= SHOW_LFD_LEVEL) then
						ToggleEncounterJournal() 
					end
				end
			})
		tinsert(menuList, {
				text = SOCIAL_BUTTON; 
				notCheckable = true;
				func = function() ToggleFriendsFrame(1) end
			})
		tinsert(menuList, {
				text = HELP_BUTTON;
				notCheckable = true;
				func = function() ToggleHelpFrame() end;
			})

		Minimap:SetScript("OnMouseUp", function(self, button)
			if (button == "RightButton") then
				ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self)
				
			elseif (button == "MiddleButton") then
				if (db.useMiddleMenu) then
					if (DropDownList1:IsShown()) then
						DropDownList1:Hide()
					else
						EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
					end
				end
			else
				Minimap_OnClick(self)
			end
		end)
		
		-- throw in a chatcommand for those that can't middleclick the minimap
		self:CreateChatCommand({ "mapmenu", "minimapmenu" }, function() EasyMenu(menuList, menuFrame, Minimap, 0, 0, "MENU", 2) end)
	end
	
	-- set up hover functionality for selected objects
	do
		local onMouse = {
			[calendar] = function() return db.showCalendarOnHover end;
			[mapClock] = function() return db.showClockOnHover end;
			[zoneTextButton] = function() return db.showLocationOnHover end;
		}
		
		-- set up the objects
		for i,v in pairs(onMouse) do
			i.fadeDuration = 0.5
			i.fadeDelay = 0.5
			i.fading = v() and 0 or nil
		end
		
		local apply = function(func, ...)
			for i,v in pairs(onMouse) do
				func(i, ...)
			end
		end
		
		local onMouseOver = function(self)
			if not(onMouse[self]()) then return end
			if (self.faded) or (self.fading) then -- only update if we are fading down, or faded out
				self.faded = nil
				self.fading = nil
				self:SetAlpha(1)
				updateDock()
			end
		end
		
		local onMouseAway = function(self, elapsed)
			if (onMouse[self]()) then
				if not(self.faded) then
					self.fading = (self.fading or 0) + elapsed
					if (self.fading >= self.fadeDelay) then
						if ((self.fading - self.fadeDelay) >= self.fadeDuration) then
							self.fading = nil
						else
							self:SetAlpha(max(0, 1 - (self.fading - self.fadeDelay)/self.fadeDuration))
						end
					end
				end
				if not(self.fading) and not(self.faded) then
					self:SetAlpha(0)
					self.faded = true
					updateDock()
				end
			else
				if (self.faded) or (self.fading) then
					self.fading = nil
					self.faded = nil
					self:SetAlpha(1)
					updateDock()
				end
			end
		end

		local Fade = function(self, elapsed)
			if (MouseIsOver(self)) then
				apply(onMouseOver)
			else
				apply(onMouseAway, elapsed)
			end
		end

		local OnUpdate = function(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed
			if (self.elapsed > 0.01) then
				Fade(self, self.elapsed)
				self.elapsed = 0
			end
		end

		minimap:SetScript("OnUpdate", OnUpdate)
	end

	-- tone down the bugsack icon
	local fixBugSack
	self:RegisterEvent("ADDON_LOADED", function(self, event, addon) 
		-- make the bugsack icon prettier
		if not(fixBugSack) and (LibDBIcon10_BugSack) then
			local a, b = LibDBIcon10_BugSack, { LibDBIcon10_BugSack:GetRegions() }
			b[2]:SetTexture("")
			b[3]:SetTexture("")
			b[2].SetTexture = self.noop
			b[3].SetTexture = self.noop
			a:SetHighlightTexture("")
			a.SetHighlightTexture = self.noop
			a:ClearAllPoints()
			a:SetPoint("LEFT", Minimap, "LEFT", 0, 0)
			a.SetPoint = self.noop
			a:SetParent(Minimap)
			
			a:SetAlpha(1/3)
			a:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
			a:HookScript("OnLeave", function(self) self:SetAlpha(1/3) end)
						
			fixBugSack = true
		end
	end)

	self:ScheduleRepeatingTimer(1, updateTime)
	self:RegisterBucketEvent({
		"PLAYER_DIFFICULTY_CHANGED";
		"PLAYER_ENTERING_WORLD";
		"ZONE_CHANGED_NEW_AREA";
	}, updateDifficulty)
	self:RegisterBucketEvent({
		"PLAYER_ENTERING_WORLD";
		"ZONE_CHANGED";
		"ZONE_CHANGED_INDOORS";
		"ZONE_CHANGED_NEW_AREA";
	}, updateZone)
		
end

module.PostUpdateSettings = function(self)
	if (mapClock) then mapClock:SetShown(db.showClock) end
	if (coordinates) then coordinates:SetShown(db.showCoordinates) end
	if (difficulty) then difficulty:SetShown(db.showDifficulty) end
	if (calendar) then calendar:SetShown(db.showCalendar) end
	if (zoneTextButton) then zoneTextButton:SetShown(db.showLocation) end
	
	updateZone()
	updateDifficulty()
	updateDock()
	
	self:RefreshBlizzardOptionsMenu()
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	
	initMap(self)
	
	self:PostUpdateSettings()

	-- kill off blizzard options
	gUI:KillOption(true, InterfaceOptionsStatusTextPanelXP)
	
	-- the options menu
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
					msg = L["Minimap"];
				};
				{
					type = "widget";
					element = "Text";
					order = 2;
					msg = L["The Minimap is a miniature map of your closest surrounding areas, allowing you to easily navigate as well as quickly locate elements such as specific vendors, or a herb or ore you are tracking. If you wish to change the position of the Minimap, you can unlock it for movement with |cFF4488FF/glock|r."];
				};
				{
					type = "group";
					order = 5;
					virtual = true;
					children = {
						{ -- clock
							type = "widget";
							element = "CheckButton";
							name = "showClock";
							order = 1;
							width = "full"; 
							msg = L["Display the clock"];
							desc = nil;
							set = function(self) 
								db.showClock = not(db.showClock)
								self:init()
								module:PostUpdateSettings()
							end;
							get = function() return db.showClock end;
							init = function(self) 
								if (db.showClock) then
									self.parent.child.use24hrClock:Enable()
									self.parent.child.useSeconds:Enable()
									self.parent.child.showClockOnHover:Enable()
								else
									self.parent.child.use24hrClock:Disable()
									self.parent.child.useSeconds:Disable()
									self.parent.child.showClockOnHover:Disable()
								end
							end;
						};
						{ -- on hover only
							type = "widget";
							element = "CheckButton";
							name = "showClockOnHover";
							indented = true;
							order = 2;
							width = "full"; 
							msg = L["Only show the clock when hovering over the Minimap"];
							desc = nil;
							set = function(self) 
								db.showClockOnHover = not(db.showClockOnHover)
								module:PostUpdateSettings()
							end;
							get = function() return db.showClockOnHover end;
						};
						{ -- 24hour clock
							type = "widget";
							element = "CheckButton";
							name = "use24hrClock";
							indented = true;
							order = 5;
							width = "full"; 
							msg = L["Use 24 hour time"];
							desc = nil;
							set = function(self) 
								db.use24hrClock = not(db.use24hrClock)
								module:PostUpdateSettings()
							end;
							get = function() return db.use24hrClock end;
						};
						{ -- seconds
							type = "widget";
							element = "CheckButton";
							name = "useSeconds";
							indented = true;
							order = 6;
							width = "full"; 
							msg = L["Show seconds"];
							desc = nil;
							set = function(self) 
								db.useSeconds = not(db.useSeconds)
								module:PostUpdateSettings()
							end;
							get = function() return db.useSeconds end;
						};
						{ -- server time
							type = "widget";
							element = "CheckButton";
							name = "useGameTime";
							indented = true;
							order = 7;
							width = "full"; 
							msg = L["Display the server time instead of the local time"];
							desc = nil;
							set = function(self) 
								db.useGameTime = not(db.useGameTime)
								self:init()
								module:PostUpdateSettings()
							end;
							get = function() return db.useGameTime end;
							init = function(self)
								if (db.useGameTime) then
									self.parent.child.useSeconds:Disable()
								else
									self.parent.child.useSeconds:Enable()
								end
							end
						};
						-- { -- coordinates
							-- type = "widget";
							-- element = "CheckButton";
							-- name = "showCoordinates";
							-- order = 5;
							-- width = "full"; 
							-- msg = L["Display the current player coordinates on the Minimap when available"];
							-- desc = nil;
							-- set = function(self) 
								-- db.showCoordinates = not(db.showCoordinates)
								-- module:PostUpdateSettings()
							-- end;
							-- get = function() return db.showCoordinates end;
						-- };
						{ -- zone text
							type = "widget";
							element = "CheckButton";
							name = "showLocation";
							order = 10;
							width = "full"; 
							msg = L["Display the current location"];
							desc = nil;
							set = function(self) 
								db.showLocation = not(db.showLocation)
								self:init()
								module:PostUpdateSettings()
							end;
							get = function() return db.showLocation end;
							init = function(self) 
								if (db.showLocation) then
									self.parent.child.showLocationOnHover:Enable()
								else
									self.parent.child.showLocationOnHover:Disable()
								end
							end;
						};
						{ -- on hover only
							type = "widget";
							element = "CheckButton";
							name = "showLocationOnHover";
							indented = true;
							order = 11;
							width = "full"; 
							msg = L["Only show the current location when hovering over the Minimap"];
							desc = nil;
							set = function(self) 
								db.showLocationOnHover = not(db.showLocationOnHover)
								module:PostUpdateSettings()
							end;
							get = function() return db.showLocationOnHover end;
						};
						{ -- calendar button
							type = "widget";
							element = "CheckButton";
							name = "showCalendar";
							order = 20;
							width = "full"; 
							msg = L["Display the calendar button"];
							desc = nil;
							set = function(self) 
								db.showCalendar = not(db.showCalendar)
								self:init()
								module:PostUpdateSettings()
							end;
							get = function() return db.showCalendar end;
							init = function(self) 
								if (db.showCalendar) then
									self.parent.child.showCalendarOnHover:Enable()
								else
									self.parent.child.showCalendarOnHover:Disable()
								end
							end;
						};
						{ -- on hover only
							type = "widget";
							element = "CheckButton";
							name = "showCalendarOnHover";
							indented = true;
							order = 21;
							width = "full"; 
							msg = L["Only show the calendar button when hovering over the Minimap"];
							desc = nil;
							set = function(self) 
								db.showCalendarOnHover = not(db.showCalendarOnHover)
								module:PostUpdateSettings()
							end;
							get = function() return db.showCalendarOnHover end;
						};
						{ -- mousewheelzoom
							type = "widget";
							element = "CheckButton";
							name = "useMouseWheelZoom";
							order = 100;
							width = "full"; 
							msg = L["Use the Mouse Wheel to zoom in and out"];
							desc = nil;
							set = function(self) 
								db.useMouseWheelZoom = not(db.useMouseWheelZoom)
							end;
							get = function() return db.useMouseWheelZoom end;
						};
						-- { -- blizzard: rotate minimap
							-- type = "widget";
							-- element = "CheckButton";
							-- name = "rotateMinimap";
							-- order = 11;
							-- width = "full"; 
							-- msg = L["Rotate Minimap"];
							-- desc = L["Check this to rotate the entire minimap instead of the player arrow."];
							-- set = function(self) 
								-- SetCVar("rotateMinimap", (tonumber(GetCVar("rotateMinimap")) == 1) and 0 or 1)
								-- Minimap_UpdateRotationSetting() --InterfaceOptionsDisplayPanelRotateMinimap.cvar
							-- end;
							-- get = function() return tonumber(GetCVar("rotateMinimap")) == 1 end;
						-- };	
						-- { -- instance difficulty overlay
							-- type = "widget";
							-- element = "CheckButton";
							-- name = "showInstanceDifficultyOverlay";
							-- order = 15;
							-- width = "full"; 
							-- msg = L["Display the difficulty of the current instance when hovering over the Minimap"];
							-- desc = nil;
							-- set = function(self) 
								-- db.showInstanceDifficultyOverlay = not(db.showInstanceDifficultyOverlay)
							-- end;
							-- get = function() return db.showInstanceDifficultyOverlay end;
						-- };
						{ -- middleclick menu
							type = "widget";
							element = "CheckButton";
							name = "useMiddleMenu";
							order = 120;
							width = "full"; 
							msg = L["Display the shortcut menu when clicking the middle mouse button on the Minimap"];
							desc = nil;
							set = function(self) 
								db.useMiddleMenu = not(db.useMiddleMenu)
							end;
							get = function() return db.useMiddleMenu end;
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
	self:RegisterAsBlizzardOptionsMenu(menuTable, L["Minimap"], "default", restoreDefaults)
end

module.OnDisable = function(self)
	Minimap:SetMaskTexture(M("Mask", "gUI™ Circle")) -- reset the texture to avoid the square remaining in the cache
end
