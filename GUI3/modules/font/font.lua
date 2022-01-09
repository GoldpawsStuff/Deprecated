--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Fonts")

local L, C, F, M, db
local SetFont, SetGUISFonts, SetBlizzFonts
local latin, fonts
local gameLocale = GAME_LOCALE or GetLocale()

local defaults = {}

-- custom fontobjects to be changed
--
-- in time these will replace all the Blizzard font objects, 
-- thus allowing us to implement a font changer that only affects our own fonts,
-- leaving other addons free to use the Blizzard fonts as they please
-- without our changes affecting them. On my TODO list.
local GUISFonts = {
	text = {
		-- text
		-- 10px
		gUI_TextFontExtraTiny;
		gUI_TextFontExtraTinyWhite;
		gUI_TextFontExtraTinyBoldOutline;
		gUI_TextFontExtraTinyBoldOutlineWhite;

		-- 12px
		gUI_TextFontTiny;
		gUI_TextFontTinyWhite;
		gUI_TextFontTinyDisabled;
		gUI_TextFontTinyBoldOutline;
		gUI_TextFontTinyBoldOutlineWhite;

		-- 14px
		gUI_TextFontSmall;
		gUI_TextFontTinyWhite;
		gUI_TextFontSmallDisabled;
		gUI_TextFontSmallBoldOutline;
		gUI_TextFontSmallBoldOutlineWhite;

		-- 16px
		gUI_TextFontNormal;
		gUI_TextFontNormalWhite;
		gUI_TextFontNormalBoldOutline;
		gUI_TextFontNormalBoldOutlineWhite;

		-- 18px
		gUI_TextFontLarge;
		gUI_TextFontLargeWhite;
		gUI_TextFontLargeBoldOutline;
		gUI_TextFontLargeBoldOutlineWhite;

		-- damage, actionbars, stuff
		-- 9px
		gUI_DisplayFontMicro;
		gUI_DisplayFontMicroOutline;
		gUI_DisplayFontMicroOutlineWhite;
		
		-- 10px
		gUI_DisplayFontExtraTiny;
		gUI_DisplayFontExtraTinyWhite;
		gUI_DisplayFontExtraTinyOutline;
		gUI_DisplayFontExtraTinyOutlineWhite;
		
		-- 12px
		gUI_DisplayFontTiny;
		gUI_DisplayFontTinyWhite;
		gUI_DisplayFontTinyOutline;
		gUI_DisplayFontTinyOutlineWhite;

		-- 14px
		gUI_DisplayFontSmall;
		gUI_DisplayFontSmallWhite;
		gUI_DisplayFontSmallOutline;
		gUI_DisplayFontSmallOutlineWhite;

		-- 16px
		gUI_DisplayFontNormal;
		gUI_DisplayFontNormalWhite;
		gUI_DisplayFontNormalOutline;
		gUI_DisplayFontNormalOutlineWhite;
		
		-- 20px
		gUI_DisplayFontLarge;
		gUI_DisplayFontLargeWhite;
		gUI_DisplayFontLargeOutline;
		gUI_DisplayFontLargeOutlineWhite;
		
		-- 22px
		gUI_DisplayFontLargeBoldOutline;
		
		-- 32px
		gUI_DisplayFontEnormousBoldOutline;
		gUI_DisplayFontEnormousBoldOutlineWhite;
	};
	
	-- unitframes
	unitframes = {
		gUI_UnitFrameFont10;
		gUI_UnitFrameFont12;
		gUI_UnitFrameFont14;
		gUI_UnitFrameFont20;
		gUI_UnitFrameFont22;
	};
}

--
-- :SetFont(fontObject, font, size, style, offsetX, offsetY, shadowAlpha)
-- 	@param fontObject <table(fontObject)> the actual font object to edit
-- 	@param font <string, nil> the new font to set
-- 	@param size <number, nil> the size of the font
-- 	@param style <string, nil> the style e.g "OUTLINE", "THINOUTLINE"
-- 	@param offsetX <number, nil> horizontal offset of the shadow
-- 	@param offsetY <number, nil> vertical offset of the shadow
-- 	@param shadowAlpha <number, nil> alpha of the shadow
-- 	@return <fontObject>
module.SetFont = function(self, fontObject, font, size, style, offsetX, offsetY, shadowAlpha, r, g, b)
	self:argCheck(fontObject, 1, "table")
	self:argCheck(font, 2, "string", "nil")
	self:argCheck(size, 3, "number", "nil")
	self:argCheck(style, 4, "string", "nil")
	self:argCheck(offsetX, 5, "number", "nil")
	self:argCheck(offsetY, 6, "number", "nil")
	self:argCheck(shadowAlpha, 7, "number", "nil")
	
	local oldFont, oldSize, oldStyle = fontObject:GetFont()
	local oldoffsetX, oldoffsetY = fontObject:GetShadowOffset()

	if (oldFont == font) and (oldSize == size) and (oldStyle == style) then
		return
	end
	
	size = size or oldSize
	if (font == M("Font", "PT Sans Narrow")) or (font == M("Font", "PT Sans Narrow Bold")) then
		if (size < 14) then
			size = 14
		end
		-- if (size == 12) then
			-- size = 14
		-- elseif (size < 12) then 
			-- size = 12
		-- end
	end

	fontObject:SetFont(font or oldFont, size, style or oldStyle)
	fontObject:SetShadowOffset(offsetX or oldoffsetX or 0, offsetY or oldoffsetY or 0)
	fontObject:SetShadowColor(0, 0, 0, shadowAlpha or 1)
	
	if (r) and (g) and (b) then
		fontObject:SetTextColor(r, g, b)
	end
	
	return fontObject
end

module.SetGUISFonts = function(self)
	if (latin[gameLocale]) then return end

	local header = fonts[gameLocale].header
	local header = fonts[gameLocale].header
	local header = fonts[gameLocale].header
	local text = fonts[gameLocale].text
	local textBold = fonts[gameLocale].textBold
	local damage = fonts[gameLocale].damage

	for i,fontObject in pairs(GUISFonts.text) do 
		self:SetFont(fontObject, text) 
	end

	for i,fontObject in pairs(GUISFonts.unitframes) do 
		self:SetFont(fontObject, header) 
	end
end

module.SetBlizzFonts = function(self)
	local header = fonts[gameLocale].header
	local text = fonts[gameLocale].text
	local textBold = fonts[gameLocale].textBold
	local damage = fonts[gameLocale].damage

	UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 14
	CHAT_FONT_HEIGHTS = { 12, 14, 16, 18, 20 } 
	
	UNIT_NAME_FONT = header 
	-- NAMEPLATE_FONT = header -- bugs out, hides the font completely
	DAMAGE_TEXT_FONT = damage -- this is the damage that is NOT a part of the fct texts
	STANDARD_TEXT_FONT = text
	
	-- chat frames
	-- as a general rule I want this to be clear and easy to read. like a webpage.
	-- self:SetFont(ChatFontNormal, textBold, nil, "THINOUTLINE", 1.25, -1.25, 0.35) -- v2
	self:SetFont(ChatFontNormal, text, nil, nil, .75, -.75, 1) -- v3

	-- tooltips (todo: fix the moneyfonts)
	self:SetFont(GameTooltipHeader, text, 14, nil, nil, .75, -.75) -- original size is 14
	self:SetFont(Tooltip_Med, text, 14, nil, nil, .75, -.75) -- original is 12
	self:SetFont(Tooltip_Small, text, 12, nil, nil, .75, -.75) -- original is 10...?
	
	self:SetFont(SystemFont_OutlineThick_WTF, header, 32, "OUTLINE", 2.5, -2.5, 0.5) -- 32px e.g. "Dalaran"
	
	-- zone names
	-- our thickest and most visible fonts. all elements here are very temporary
	self:SetFont(ZoneTextFont, header, 32, "OUTLINE", 2.5, -2.5, 0.5) -- 32px e.g. "Dalaran"
	self:SetFont(SubZoneTextFont, header, 24, "OUTLINE", 2.5, -2.5, 0.75) --28px e.g. "Krasus' Landing"
	self:SetFont(PVPInfoTextFont, header, 18, "OUTLINE", 1.5, -1.5, 0.5) -- 18px .... wtf is this?
	self:SetFont(PVPArenaTextString, header, 18, "OUTLINE", 1.5, -1.5, 0.5) --22px e.g. "Sanctuary"
	
	-- worldmap
	self:SetFont(WorldMapFrameAreaLabel, header, 32, "THINOUTLINE", 2.5, -2.5, 0.5) -- 32px e.g. "Dalaran"
	self:SetFont(WorldMapFrameAreaDescription, header, 22, "THINOUTLINE", 2.5, -2.5, 0.5) 
	self:SetFont(WorldMapFrameAreaPetLevels, header, 18, "THINOUTLINE", 2.5, -2.5, 0.5) 

	-- raid warnings
	-- I gave these a visible shadow to match their outline, 
	-- as these are all very temporary and are meant to be seen
	self:SetFont(RaidWarningFrameSlot1, header, nil, "THINOUTLINE", 2.5, -2.5)
	self:SetFont(RaidWarningFrameSlot2, header, nil, "THINOUTLINE", 2.5, -2.5)
	self:SetFont(RaidBossEmoteFrameSlot1, header, nil, "THINOUTLINE", 2.5, -2.5)
	self:SetFont(RaidBossEmoteFrameSlot2, header, nil, "THINOUTLINE", 2.5, -2.5)
	
	-- error frame
	-- quest updates are also fed to the error frame
	-- I used the bold font, yet a less distinct shadow than the raid warnings, 
	-- as I want these updates to be visible, but not "in your face"
	self:SetFont(ErrorFont, header, 18, "THINOUTLINE", .75, -.75, .5)

	-- damage
	-- this is the fct damage
	self:SetFont(CombatTextFont, damage, 25, "THINOUTLINE", 1.5, -1.5, .5) -- the blizzard font is 25, and keeping it this way gave me the smoothest result. except crits, which always suck
	
	-- get rid of the weird and unreadable quest/mail font
	self:SetFont(MailFont_Large, header, nil, nil, 0, 0, 0)
	self:SetFont(MailTextFontNormal, text)
	self:SetFont(QuestFont, text)
	self:SetFont(QuestFontHighlight, textBold)
	self:SetFont(QuestFontNormalSmall, text)
	self:SetFont(QuestFontLeft, text)
	self:SetFont(QuestFont_Large, header, nil, nil, 0, 0, 0)
	self:SetFont(QuestFont_Shadow_Huge, header, nil, nil, nil, 0, 0, 0)
	self:SetFont(QuestFont_Shadow_Small, header, nil, nil, nil, 0, 0, 0)
	self:SetFont(QuestFont_Super_Huge, header, nil, nil, nil, 0, 0, 0)
	
	-- numbers
	self:SetFont(NumberFontNormal, header, 12)
	self:SetFont(NumberFontNormalLarge, header, 14)
	self:SetFont(NumberFontNormalSmallGray, header, 12) -- default hotkey font
	-- self:SetFont(NumberFont_OutlineThick_Mono_Small, header, 12, "THINOUTLINE")
	-- self:SetFont(NumberFont_Outline_Huge, header, 28, "THINOUTLINE")
	-- self:SetFont(NumberFont_Outline_Large, header, 14, "THINOUTLINE")
	-- self:SetFont(NumberFont_Outline_Med, header, 12, "THINOUTLINE")
	self:SetFont(NumberFont_OutlineThick_Mono_Small, header, 12, nil, 1, -1, 0.75)
	self:SetFont(NumberFont_Outline_Huge, header, 28, "THINOUTLINE", 0.75, -0.75)
	self:SetFont(NumberFont_Outline_Large, header, 14, nil, 1, -1, 0.75)
	self:SetFont(NumberFont_Outline_Med, header, 12, nil, 1, -1, 0.75)

	-- system fonts
	self:SetFont(FriendsFont_Normal, text)
	self:SetFont(FriendsFont_Large, textBold)
	self:SetFont(FriendsFont_Small, text)
	self:SetFont(FriendsFont_UserText, text)
	self:SetFont(GameFontNormal, text)
	self:SetFont(GameFontDisable, text)
	self:SetFont(GameFontHighlight, text)
	self:SetFont(NumberFont_Shadow_Med, header)
	self:SetFont(NumberFont_Shadow_Small, header)
	self:SetFont(SystemFont_Large, textBold)
	self:SetFont(SystemFont_Med1, text)
	self:SetFont(SystemFont_Med3, text)
	self:SetFont(SystemFont_OutlineThick_Huge2, header, nil, "THINOUTLINE")
	self:SetFont(SystemFont_Outline_Small, textBold, nil, "THINOUTLINE")
	self:SetFont(SystemFont_Shadow_Huge1, header, nil, "THINOUTLINE")
	self:SetFont(SystemFont_Shadow_Large, text)
	self:SetFont(SystemFont_Shadow_Med1, text)
	self:SetFont(SystemFont_Shadow_Med3, text)
	self:SetFont(SystemFont_Shadow_Outline_Huge2, textBold, nil, "THINOUTLINE")
	self:SetFont(SystemFont_Shadow_Small, text)
	self:SetFont(SystemFont_Small, text)
	self:SetFont(SystemFont_Tiny, text, 12)
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	
	latin = {
		deDE = true;
		enUS = true;
		enGB = true;
		esES = true;
		esMX = true;
		frFR = true;
		itIT = true;
		ptBR = true;
		ptPT = true;
		ruRU = true; -- our fonts covers both latin and cyrillic
	}
	
	fonts = setmetatable({
		-- ruRU = { 
			-- header = M("Font", "PT Sans Narrow Bold");
			-- text = M("Font", "PT Sans Narrow");
			-- textBold = M("Font", "PT Sans Narrow Bold");
			-- damage = M("Font", "PT Sans Narrow");
		-- };
		koKR = {
			header = [[Fonts\2002.TTF]];
			text = [[Fonts\2002.TTF]];
			textBold = [[Fonts\2002.TTF]];
			damage = [[Fonts\2002.TTF]];
		};
		zhCN = {
			header = [[Fonts\ARHei.TTF]];
			text = [[Fonts\ARKai_T.TTF]];
			textBold = [[Fonts\ARKai_T.TTF]];
			damage = [[Fonts\ARKai_C.TTF]];
		};
		zhTW = {
			header = [[Fonts\bLEI00D.ttf]];
			text = [[Fonts\bLEI00D.ttf]];
			textBold = [[Fonts\bLEI00D.ttf]];
			damage = [[Fonts\bLEI00D.ttf]];
		};
		default = {
			header = M("Font", "PT Sans Narrow Bold");
			text = M("Font", "PT Sans Narrow");
			textBold = M("Font", "PT Sans Narrow Bold");
			damage = M("Font", "PT Sans Narrow Bold");
		};
	}, { __index = function(t,k) return rawget(t,k) or rawget(t,"default") end })
	
	-- it is important to call all the font changes prior to PLAYER_LOGIN, 
	-- or not all blizzard elements will get properly changed
	self:SetBlizzFonts()
	self:SetGUISFonts()
end
