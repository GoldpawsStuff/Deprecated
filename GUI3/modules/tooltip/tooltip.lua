--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Tooltips")

local _G = _G
local pairs, select, unpack = pairs, select, unpack

local CreateFrame = CreateFrame
local GetGuildInfo = GetGuildInfo
local GetItemIcon = GetItemIcon
local GetQuestDifficultyColor = GetQuestDifficultyColor
local GetRealmName = GetRealmName
local InCombatLockdown = InCombatLockdown
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitCreatureType = UnitCreatureType
local UnitExists = UnitExists
local UnitIsAFK = UnitIsAFK
local UnitIsDND = UnitIsDND
local UnitIsPlayer = UnitIsPlayer
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPVPName = UnitPVPName
local UnitRace = UnitRace
local UnitReaction = UnitReaction
local GameTooltip = GameTooltip
local GameTooltipStatusBar = GameTooltipStatusBar
local RAID_CLASS_COLORS
local FACTION_BAR_COLORS

-- since we use it a lot
local RGBToHex = function(...) return module:RGBToHex(...) end

local L, C, F, M, db
local CLASSIFICATION
local styleMenu, styleTooltip, styleStatusBar, styleItemRef, showItemRefIcon
local SetDefaultAnchor, OnValueChanged, OnTooltipSetUnit
local OnShow, OnEvent, OnUpdate, OnHide
local OnMenuShow, OnMenuEvent
local SetColor, GetColor

local RARE = ITEM_QUALITY3_DESC
local tooltipAnchor
local currentTooltip

local onlyStyle = {
	DropDownList1Backdrop;
	DropDownList2Backdrop;
	DropDownList1MenuBackdrop;
	DropDownList2MenuBackdrop;
	ChatMenu;
	EmoteMenu;
	LanguageMenu;
	VoiceMacroMenu;
}

local tips = {
	-- ConsolidatedBuffsTooltip;
	-- FriendsTooltip; -- this don't need updating, just skin it
	GameTooltip; 
	ItemRefTooltip; 
	ShoppingTooltip1; 
	ShoppingTooltip2; 
	ShoppingTooltip3;
	WorldMapTooltip; 
	WorldMapCompareTooltip1;
	WorldMapCompareTooltip2;
	WorldMapCompareTooltip3;
}	

local defaults = {
	anchortocursor = 0; -- 0 = default pos (can be moved by the user), 1 = always to mouse, 2 = only anchor units
	hidewhilecombat = false; -- 0 = always show, 1 = hide in combat
	showtitle = true; -- show player titles
	showrealm = true; -- show realm names for other realms
	showhealth = true; -- show health values on the health bars
	colorborder = true; -- color borders and bars after unit class, reaction, etc
	place = { "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -8, 190 }; -- coming soon
}

GetColor = function(self, unit)
	local mouse = GetMouseFocus()
	local unit = unit or (select(2, self:GetUnit())) or (mouse and mouse:GetAttribute("unit")) 
	
	local r, g, b
	local hasClass = (unit) and select(2, UnitClass(unit))
	local hasReaction = (unit) and UnitReaction(unit, "player")
	local isPlayer = (unit) and UnitIsPlayer(unit)
	local isTapped = (unit) and UnitIsTapped(unit)
	local isTappedByPlayer = (unit) and UnitIsTappedByPlayer(unit)
	local isConnected = (unit) and UnitIsConnected(unit)
	local isDead = (unit) and UnitIsDead(unit)
	
	if (isDead) or ((isPlayer) and not(isConnected)) then
		r, g, b = unpack(C.dead)
	elseif (isPlayer) and (hasClass) then
		r, g, b = RAID_CLASS_COLORS[hasClass].r, RAID_CLASS_COLORS[hasClass].g, RAID_CLASS_COLORS[hasClass].b
	elseif (hasReaction) then
		r, g, b = FACTION_BAR_COLORS[hasReaction].r, FACTION_BAR_COLORS[hasReaction].g, FACTION_BAR_COLORS[hasReaction].b
	else
		local _, link = self.GetItem and self:GetItem()
		local quality = (link) and select(3, GetItemInfo(link))
		if (quality) and (quality >= 2) then
			r, g, b = GetItemQualityColor(quality)
		end
	end
	
	if not(r) or not(g) or not(b) then
		-- fix the border color of signs, chairs, etc
		-- part of the "blue background" problem
		if not(unit) and (self:GetAnchorType() == "ANCHOR_CURSOR") then
			return gUI:GetBackdropBorderColor()
		end
		-- the tooltip loses its unit attribute when you cancel your target or move the mouse away, 
		-- yet it still remains visible while it fades out
		-- we need to avoid it losing its bordercolor when this happens
		if not(unit) and (self.unit) then
			return self:GetBackdropBorderColor()
		else
			return gUI:GetBackdropBorderColor()
		end
	end
	self.unit = unit -- not strictly sure this is needed
		
	return r, g, b
end

SetColor = function(self)
	local r, g, b = GetColor(self)
	local r2, g2, b2 = gUI:GetBackdropColor()
	local a = gUI:GetPanelAlpha()
	
	self:SetBackdropColor(r2, g2, b2, a)

	if (db.colorborder) then
		self:SetBackdropBorderColor(r, g, b)
		GameTooltipStatusBar:SetStatusBarColor(r, g, b)
	else
		self:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
		GameTooltipStatusBar:SetStatusBarColor(unpack(C.health))
	end
end

showItemRefIcon = function()
	local frame = _G.ItemLinkIcon
	local tip = _G.ItemRefTooltip
	
	frame:Hide()

	local link = (select(2, tip:GetItem()))
	local icon = link and GetItemIcon(link)

	if not(icon) then 
		tip.hasIcon = nil
		return 
	end
	
	local rarity = (select(3, GetItemInfo(link)))
	if (rarity) and (rarity > 1) then
		local r, g, b = GetItemQualityColor(rarity)
		frame:SetBackdropBorderColor(r, g, b, 1)
		tip.hasIcon = true
	else
		frame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1) -- don't use the gUI border here
		tip.hasIcon = nil
	end

	frame.icon:SetTexture(icon)
	frame:Show()
end

OnMenuShow = function(self)
	self:SetScale(UIParent:GetScale() / self:GetEffectiveScale()) -- avoid some tooltips being LAAAARGE
	self:SetBackdrop(M("Backdrop", "SimpleBorder")) -- bugs out on macro tooltips and various others with our normal border texture
	self:SetBackdropColor(gUI:GetBackdropColor())
	self:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
end

OnMenuEvent = function(self)
end

styleMenu = function(self)
	if not(self) then return end
	self:HookScript("OnShow", OnMenuShow)
	self:HookScript("OnEvent", OnMenuEvent)
end

styleTooltip = function(self)
	if not(self) then return end
	self:HookScript("OnShow", OnShow)
	self:HookScript("OnEvent", OnEvent)
end

styleStatusBar = function()
	local r, g, b = gUI:GetBackdropColor()
	GameTooltipStatusBar:ClearAllPoints()
	GameTooltipStatusBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -5)
	GameTooltipStatusBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", 0, -5)
	GameTooltipStatusBar:SetStatusBarTexture(gUI:GetStatusBarTexture())

	GameTooltipStatusBar:SetBackdrop({ bgFile = gUI:GetStatusBarTexture() })
	GameTooltipStatusBar:SetBackdropColor(r, g, b, 1/2)
	GameTooltipStatusBar:SetHeight(8)
	GameTooltipStatusBar:SetStatusBarColor(unpack(C.health)) -- just initial update

	gUI:SetUITemplate(GameTooltipStatusBar, "gloss")
	-- gUI:SetUITemplate(GameTooltipStatusBar, "shade"):SetAlpha(0.1)
	gUI:CreateUIShadow(GameTooltipStatusBar) -- the shadow will function as a border here

	GameTooltipStatusBar.Text = GameTooltipStatusBar:CreateFontString()
	GameTooltipStatusBar.Text:SetDrawLayer("OVERLAY", 4)
	GameTooltipStatusBar.Text:SetFontObject(gUI_DisplayFontSmallOutlineWhite)
	GameTooltipStatusBar.Text:SetJustifyH("CENTER")
	GameTooltipStatusBar.Text:SetJustifyV("MIDDLE")
	GameTooltipStatusBar.Text:SetPoint("CENTER", GameTooltipStatusBar , "CENTER", 0, 0)
end

styleItemRef = function()
	-- create a nice icon for itemlinks
	local ItemLinkIcon = CreateFrame("Frame", "ItemLinkIcon", ItemRefTooltip)
	ItemLinkIcon:SetPoint("TOPRIGHT", ItemRefTooltip, "TOPLEFT", -4, 0)
	ItemLinkIcon:SetSize(38, 38)
	gUI:SetUITemplate(ItemLinkIcon, "backdrop")

	ItemLinkIcon.icon = ItemLinkIcon:CreateTexture("icon", "ARTWORK")
	ItemLinkIcon.icon:ClearAllPoints()
	ItemLinkIcon.icon:SetPoint("TOPLEFT", ItemLinkIcon, 3, -3)
	ItemLinkIcon.icon:SetPoint("BOTTOMRIGHT", ItemLinkIcon, -3, 3)
	ItemLinkIcon.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	gUI:SetUITemplate(ItemLinkIcon, "gloss", ItemLinkIcon.icon)
	gUI:SetUITemplate(ItemLinkIcon, "shade", ItemLinkIcon.icon)
	
	ItemRefCloseButton:SetNormalTexture(M("Button", "gUI™ CloseButton"))
	ItemRefCloseButton:SetPushedTexture(M("Button", "gUI™ CloseButtonDown"))
	ItemRefCloseButton:SetHighlightTexture(M("Button", "gUI™ CloseButtonHighlight"))
	ItemRefCloseButton:SetDisabledTexture(M("Button", "gUI™ CloseButtonDisabled"))
	ItemRefCloseButton:SetSize(16, 16)
	ItemRefCloseButton:ClearAllPoints()
	ItemRefCloseButton:SetPoint("TOPRIGHT", ItemRefTooltip, "TOPRIGHT", -4, -4)
end

SetDefaultAnchor = function(self, owner)
	self:SetOwner(owner, "ANCHOR_NONE")
end

OnTooltipSetUnit = function(self)
	local lines = self:NumLines()
	local focus = GetMouseFocus()
	local unit = (select(2, self:GetUnit())) or (focus and focus:GetAttribute("unit"))
	if (not unit) then 
		self:Hide() 
		return 
	end
	
	self.unit = unit
	
	local r, g, b = GetColor(self, unit)
	local level = UnitLevel(unit)
	local levelColor = (level ~= -1) and GetQuestDifficultyColor(level) or C.boss
	local race = UnitRace(unit)
	local name, realm = UnitName(unit)
	local classification = UnitClassification(unit)
	local creatureType = UnitCreatureType(unit)
	local isPlayer = UnitIsPlayer(unit)

	if (db.showtitle) then
		name = UnitPVPName(unit)
	end
	
	if (name) then
		_G.GameTooltipTextLeft1:SetFormattedText("|cFF%s%s|r", RGBToHex(r, g, b), name)
	end
	
	if (isPlayer) then
		local afk = UnitIsAFK(unit)
		local dnd = UnitIsDND(unit)
		local guild = GetGuildInfo(unit)
		local blind = tonumber(GetCVar("colorblindMode")) == 1
		local n = guild and 3 or 2 + (blind and 1 or 0)
				
		if (afk) then
			self:AppendText(("|cFF%s %s|r"):format(RGBToHex(r, g, b), CHAT_FLAG_AFK))
		elseif (dnd) then 
			self:AppendText(("|cFF%s %s|r"):format(RGBToHex(r, g, b), CHAT_FLAG_DND))
		end
		
		if (realm) and (realm ~= "") then 
			_G.GameTooltipTextLeft1:SetFormattedText("|cFF%s%s|r|cFF%s - %s|r", RGBToHex(r, g, b), name or "", RGBToHex(C.realm[1], C.realm[2], C.realm[3]), realm)
		end

		if (guild) then
			_G.GameTooltipTextLeft2:SetFormattedText("|cFF%s<%s>|r", RGBToHex(C.guild[1], C.guild[2], C.guild[3]), GetGuildInfo(unit))
		end

		_G[("GameTooltipTextLeft%d"):format(n)]:SetFormattedText("|cFF%s%s|r %s", RGBToHex(levelColor.r, levelColor.g, levelColor.b), level ~= -1 and level or "", race or "")

	else
		if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
			level = UnitBattlePetLevel(unit)
		end
		
		for i = 2, lines do
			local line = _G[("GameTooltipTextLeft%d"):format(i)]
			
			if (line) and (line:GetText():find(LEVEL) or (creatureType and line:GetText():find(creatureType))) then
				classification = ((level == -1) and (classification == "elite")) and "worldboss" or classification
				
				local text = ""
				if (classification ~= "worldboss") and (level > 0) then
					text = text .. "|cFF" .. RGBToHex(levelColor.r, levelColor.g, levelColor.b) .. level .. "|r"
				end
				
				if (CLASSIFICATION[classification]) then
					text = text .. CLASSIFICATION[classification] .. " "
					
				elseif ((classification ~= "worldboss") and (level > 0)) then
					text = text .. " "
				end
				
				if (creatureType) then
					text = text .. creatureType
				end
				line:SetText(text)
				break
			end
		end
	end

	if (UnitExists(unit .. "target")) and ((unit ~= "player")) then
		local r, g, b = GetColor(self, unit .. "target")
		local name, realm = UnitName(unit .. "target")
		GameTooltip:AddLine(((name == (select(1, UnitName("player")))) and ((realm == nil) or (realm == (GetRealmName())))) and "|cFFFF0000>> " .. strupper(UNIT_YOU) .. " <<|r" or ">> " .. name .. " <<", r, g, b)
	end
	
	-- doesn't work anymore. it have to be hooked into the OnShow handler. bother?
	-- if (self:GetWidth() < 120) then
		-- self:SetWidth(120)
	-- end
end

OnValueChanged = function(self, value)
	if not(value) then return end
	local min, max = self:GetMinMaxValues()
	if (value < min) or (value > max) then return end
	local unit = select(2, GameTooltip:GetUnit())
	local focus = GetMouseFocus()
	local unit = unit or (focus and focus:GetAttribute("unit"))
	local isConnected, isDead, isPlayer
	local text = ""
	if (db.showhealth) then
		if (unit) then 
			min, max = UnitHealth(unit), UnitHealthMax(unit)
			isDead = UnitIsDead(unit) or UnitIsGhost(unit)
			isConnected = (unit) and UnitIsConnected(unit)
			isPlayer = UnitIsPlayer(unit)
		end
		if (isDead) or (value == 0) then
			text = DEAD
		elseif ((isPlayer) and not(isConnected)) then
			text = PLAYER_OFFLINE
		elseif (value < max) then
			text = module:Tag(("|cffffffff%d%%|r |cffD7BEA5-|r |cffffffff%s|r"):format(floor(value / max * 100), ("[shortvalue:%d]"):format(value)))
		else
			text = module:Tag("|cffffffff" .. ("[shortvalue:%d]"):format(max) .. "|r")
		end
	end
	self.Text:SetText(text)
end

OnHide = function(self)
	self.unit = nil
end

OnShow = function(self)
	self:SetScale(UIParent:GetScale() / self:GetEffectiveScale()) -- avoid some tooltips being LAAAARGE
	self:SetBackdrop(M("Backdrop", "SimpleBorder")) -- bugs out on macro tooltips and various others with our normal border texture
	SetColor(self)
	self.scheduleRefresh = true -- blue background fix for world items like signs, chairs, etc
	if (db.hidewhilecombat) then
		if (InCombatLockdown()) then
			self:Hide()
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		else
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
		end
	end
end

OnEvent = function(self, event, ...)
	if (db.hidewhilecombat) then
		if (event == "PLAYER_REGEN_DISABLED") then 
			self:Hide()
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		elseif (event == "PLAYER_REGEN_ENABLED") then 
			self:Show()
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
		end
	end
end

OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed < 0.01) then
		return
	end
	if (self.scheduleRefresh) then
		SetColor(self)
	end
	if (self:GetAnchorType() ~= "ANCHOR_NONE") then
		return
	end
	if (db.anchortocursor == 1) or ((db.anchortocursor == 2) and UnitExists("mouseover")) then
		local x, y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		local tooltipWidth = self:GetWidth()
		local tooltipHeight = self:GetHeight()
		local top = UIParent:GetTop()
		local mX, mY = x / scale - (tooltipWidth / 2), y / scale + 30

		-- put the tip below the mouse if the tooltip would move outside the screen otherwise
		if (mY + tooltipHeight > top) then
			mY = mY - tooltipHeight - 60
		end

		self:ClearAllPoints()
		self:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", mX, mY)
	else
		self:ClearAllPoints()
		self:SetPoint(unpack(db.place))
	end

	self.elapsed = 0 
end

module.PostUpdateSettings = function(self)
	self:PlaceAndSave(tooltipAnchor, L["Tooltip"], db.place, unpack(defaults.place))
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	
	RAID_CLASS_COLORS = C.RAID_CLASS_COLORS
	FACTION_BAR_COLORS = C.FACTION_BAR_COLORS

	CLASSIFICATION = {
		elite = ("|cFF%s+|r"):format(RGBToHex(C.boss.r, C.boss.g, C.boss.b));
		rare = ("|cFF%s %s|r"):format(RGBToHex(C.rare[1], C.rare[2], C.rare[3]) , RARE);
		rareelite = ("|cFF%s+ %s|r"):format(RGBToHex(C.boss.r, C.boss.g, C.boss.b), RARE);
		worldboss = ("|cFF%s%s|r"):format(RGBToHex(C.boss.r, C.boss.g, C.boss.b), BOSS);
	}
	
	-- positioning
	do
		tooltipAnchor = CreateFrame("Frame", nil, UIParent)
		tooltipAnchor:SetSize(160, 100)
		tooltipAnchor:SetPoint(unpack(db.place))
		self:PlaceAndSave(tooltipAnchor, L["Tooltip"], db.place, unpack(defaults.place))
		self:AddObjectToFrameGroup(tooltipAnchor, "floaters")
	end
	
	-- skin the Blizzard debug tools tooltips
	local skinDebugTools = function(self, event, addon)
		if not(addon == "Blizzard_DebugTools") then
			return
		end
		styleTooltip(EventTraceTooltip)
		styleTooltip(FrameStackTooltip)
		self:UnregisterEvent(event)
	end
	
	gUI:SetUITemplate(FriendsTooltip, "backdrop")

	-- since only the first 2 dropdown levels are created upon login,
	-- we're going to hook ourself into the creation process instead
	local extraStyled = {}
	local skinDropDown = function(level, index)
		for i = 3, UIDROPDOWNMENU_MAXLEVELS do
			local menu = "DropDownList" .. i .. "MenuBackdrop"
			local dropdown = "DropDownList" .. i .. "Backdrop"
			
			if (_G[menu]) and not(extraStyled[menu]) then
				if (styleMenu(_G[menu])) then
					extraStyled[menu] = true
				end
			end
			
			if (_G[dropdown]) and not(extraStyled[dropdown]) then
				if (styleMenu(_G[dropdown])) then
					extraStyled[dropdown] = true
				end
			end
		end
	end

	-- style all the registered tooltips and dropdowns
	for _,tooltip in pairs(tips) do styleTooltip(tooltip) end
	for _,tooltip in pairs(onlyStyle) do styleMenu(tooltip) end

	styleItemRef() -- style the item ref frame
	styleStatusBar() -- style the statusbar
	
	-- pretty pretty shadows
	gUI:CreateUIShadow(GameTooltip)
	gUI:CreateUIShadow(ShoppingTooltip1)
	gUI:CreateUIShadow(ShoppingTooltip2)
	gUI:CreateUIShadow(ShoppingTooltip3)
	gUI:CreateUIShadow(SmallTextTooltip)

	GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
	GameTooltip:HookScript("OnUpdate", OnUpdate)
	GameTooltip:HookScript("OnHide", OnHide)
	GameTooltipStatusBar:SetScript("OnValueChanged", OnValueChanged)

	hooksecurefunc("UIDropDownMenu_CreateFrames", skinDropDown)
	hooksecurefunc("SetItemRef", showItemRefIcon)
	hooksecurefunc("GameTooltip_SetDefaultAnchor", SetDefaultAnchor)
	self:RegisterEvent("ADDON_LOADED", skinDebugTools)
	
	-- create the options menu
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
						msg = L["Tooltips"];
					};
					{
						type = "widget";
						element = "Text";
						order = 2;
						msg = L["Here you can change the settings for the game tooltips"];
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
								msg = L["Visibility"];
							};
							{ -- hide in combat
								type = "widget";
								element = "CheckButton";
								name = "hidewhilecombat";
								order = 5;
								width = "full"; 
								msg = L["Hide while engaged in combat"];
								desc = nil;
								set = function(self) 
									db.hidewhilecombat = not(db.hidewhilecombat)
								end;
								get = function() return db.hidewhilecombat end;
							};
							{
								type = "widget";
								element = "Header";
								order = 19;
								msg = L["Elements"];
							};
							{ -- healthbar text
								type = "widget";
								element = "CheckButton";
								name = "colorborder";
								order = 50;
								width = "full"; 
								msg = L["Color unit tooltips borders and healthbars according to player class or NPC reaction"];
								desc = nil;
								set = function(self) 
									db.colorborder = not(db.colorborder)
								end;
								get = function() return db.colorborder end;
							};
							{ -- healthbar text
								type = "widget";
								element = "CheckButton";
								name = "showhealth";
								order = 60;
								width = "full"; 
								msg = L["Show values on the tooltip healthbar"];
								desc = nil;
								set = function(self) 
									db.showhealth = not(db.showhealth)
								end;
								get = function() return db.showhealth end;
							};
							{ -- titles
								type = "widget";
								element = "CheckButton";
								name = "showtitle";
								order = 70;
								width = "full"; 
								msg = L["Show player titles in the tooltip"];
								desc = nil;
								set = function(self) 
									db.showtitle = not(db.showtitle)
								end;
								get = function() return db.showtitle end;
							};
							{ -- realm
								type = "widget";
								element = "CheckButton";
								name = "showrealm";
								order = 80;
								width = "full"; 
								msg = L["Show player realms in the tooltip"];
								desc = nil;
								set = function(self) 
									db.showrealm = not(db.showrealm)
								end;
								get = function() return db.showrealm end;
							};
							{
								type = "widget";
								element = "Header";
								order = 100;
								msg = L["Positioning"];
							};
							{
								type = "widget";
								element = "Text";
								order = 101;
								msg = L["Choose what tooltips to anchor to the mouse cursor, instead of displaying in their default positions:"];
							};
							{ -- nameplates
								type = "widget";
								element = "Dropdown";
								order = 110;
								msg = nil;
								desc = {
									"|cFFFFFFFF" .. NONE .. "|r",
									"|cFFFFD100" .. L["All tooltips will be displayed in their default positions."] .. "|r", 
									" ",
									"|cFFFFFFFF" .. ALL .. "|r",
									"|cFFFFD100" .. L["All tooltips will be anchored to the mouse cursor."] .. "|r", 
									" ",
									"|cFFFFFFFF" .. L["Only Units"] .. "|r",
									"|cFFFFD100" .. L["Only unit tooltips will be anchored to the mouse cursor, while other tooltips will be displayed in their default positions."] .. "|r"
								};
								args = { NONE, ALL, L["Only Units"] };
								set = function(self, option)
									db.anchortocursor = UIDropDownMenu_GetSelectedID(self) - 1
								end;
								get = function(self) return db.anchortocursor + 1 end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
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
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["Tooltips"], "default", restoreDefaults)
	end
end

module.OnEnable = function(self)
end

module.OnDisable = function(self)
end
