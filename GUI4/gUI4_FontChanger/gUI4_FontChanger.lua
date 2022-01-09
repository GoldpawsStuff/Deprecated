local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gameLocale = GAME_LOCALE or GetLocale()
local cyrillic = gameLocale == "ruRU"
local latin = gameLocale == "enUS" 
	or gameLocale == "enGB"
	or gameLocale == "deDE"
	or gameLocale == "esES"
	or gameLocale == "esMX"
	or gameLocale == "frFR"
	or gameLocale == "itIT"
	or gameLocale == "ptBR"
	or gameLocale == "ptPT"

-- if the client can't use this, just bail out 
if not(latin or cyrillic) then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

function module:SetFont(fontObject, font, size, style, shadowX, shadowY, shadowA, r, g, b, shadowR, shadowG, shadowB)
	local oldFont, oldSize, oldStyle  = fontObject:GetFont()
	if not size then
		size = oldSize
	end
	if not style then
		style = (oldStyle == "OUTLINE") and "THINOUTLINE" or oldStyle -- keep outlines thin
	end
	fontObject:SetFont(font, size, style)
	if shadowX and shadowY then
		fontObject:SetShadowOffset(shadowX, shadowY)
		fontObject:SetShadowColor(shadowR or 0, shadowG or 0, shadowB or 0, shadowA or 1)
	end
	if r and g and b then
		fontObject:SetTextColor(r, g, b)
	end
	return fontObject	
end

local hooked 
function module:HookCombatText()
	-- combat font
	COMBAT_TEXT_HEIGHT = 16
	COMBAT_TEXT_CRIT_MAXHEIGHT = 24
	COMBAT_TEXT_CRIT_MINHEIGHT = 16
	COMBAT_TEXT_SCROLLSPEED = 3

	self:SetFont(CombatTextFont, gUI4:GetMedia("Font", "DejaVuSans"):GetPath(), 16, "THINOUTLINE", 2.5, -2.5, .35) -- floating combat text

	hooksecurefunc("CombatText_UpdateDisplayedMessages", function() 
		if COMBAT_TEXT_FLOAT_MODE == "1" then
			COMBAT_TEXT_LOCATIONS.startY = 484
			COMBAT_TEXT_LOCATIONS.endY = 709
		end
	end)
end

function module:OnInitialize()
	local normal = gUI4:GetMedia("Font", "DejaVuSans"):GetPath()
	local bold = gUI4:GetMedia("Font", "DejaVuSans-Bold"):GetPath()
	local narrow = gUI4:GetMedia("Font", "DejaVuSansCondensed"):GetPath()
	local narrowBold = gUI4:GetMedia("Font", "DejaVuSansCondensed-Bold"):GetPath()
	local light = gUI4:GetMedia("Font", "DejaVuSans-ExtraLight"):GetPath()
	local damage = narrowBold 

	-- Game engine fonts (fonts rendered by 3D engine - not the UI - in the game world)
	UNIT_NAME_FONT = narrow 
	--DAMAGE_TEXT_FONT = bold -- let's drop this, blizzard fixed the damage text in Legion!
	STANDARD_TEXT_FONT = normal
	
	-- *The following need the string to be the global name of a fontobject. weird. 
	-- *Dropping this in Legion, nameplates are completely hidden and remade here.
	-- NAMEPLATE_FONT = "GameFontWhite" -- 12
	-- NAMEPLATE_SPELLCAST_FONT = "GameFontWhiteTiny" -- 9

	-- default values
	UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 14
	CHAT_FONT_HEIGHTS = { 12, 13, 14, 15, 16, 18, 20, 22 }

	-------------------------------------------------------------------------------
	--	Fonts.xml
	-------------------------------------------------------------------------------
	-- Friz Quadrata
	self:SetFont(SystemFont_Tiny, normal)
	self:SetFont(SystemFont_Small, narrow) -- player/target name, level, timer text
	self:SetFont(SystemFont_Outline_Small, narrow) -- statusbartext (player/target health, mana, etc)
	self:SetFont(SystemFont_Outline, normal)
	self:SetFont(SystemFont_Shadow_Small, normal)
	self:SetFont(SystemFont_InverseShadow_Small, normal)
	self:SetFont(SystemFont_Med1, normal)
	self:SetFont(SystemFont_Shadow_Med1, normal)
	self:SetFont(SystemFont_Shadow_Med1_Outline, normal)
	self:SetFont(SystemFont_Med2, normal)
	self:SetFont(SystemFont_Shadow_Med2, normal)
	self:SetFont(SystemFont_Med3, normal)
	self:SetFont(SystemFont_Shadow_Med3, normal)
	self:SetFont(SystemFont_Large, normal)
	self:SetFont(SystemFont_Shadow_Large, normal)
	self:SetFont(SystemFont_Shadow_Large_Outline, normal)
	self:SetFont(SystemFont_Huge1, normal)
	self:SetFont(SystemFont_Shadow_Huge1, normal)
	self:SetFont(SystemFont_OutlineThick_Huge2, narrowBold) 
	self:SetFont(SystemFont_Shadow_Outline_Huge2, narrow)
	self:SetFont(SystemFont_Shadow_Huge3, normal)
	self:SetFont(SystemFont_OutlineThick_Huge4, normal)
	self:SetFont(SystemFont_OutlineThick_WTF, normal)
	-- self:SetFont(GameTooltipHeader, normal)
	self:SetFont(SpellFont_Small, normal)
	self:SetFont(InvoiceFont_Med, normal)
	self:SetFont(InvoiceFont_Small, normal)
	-- self:SetFont(Tooltip_Med, normal)
	-- self:SetFont(Tooltip_Small, normal)
	self:SetFont(AchievementFont_Small, normal)
	self:SetFont(ReputationDetailFont, normal)
	self:SetFont(FriendsFont_Normal, normal)
	self:SetFont(FriendsFont_Small, normal)
	self:SetFont(FriendsFont_Large, normal)
	self:SetFont(GameFont_Gigantic, normal)
	self:SetFont(ChatBubbleFont, normal)

	-- I decided that the tooltip title should be the same size as the rest
	self:SetFont(GameTooltipHeader, normal, 12)
	self:SetFont(Tooltip_Med, normal, 12)
	self:SetFont(Tooltip_Small, normal, 10)
	
	-- Arial Narrow
	self:SetFont(FriendsFont_UserText, narrow)
	self:SetFont(NumberFont_Shadow_Small, narrow)
	self:SetFont(NumberFont_OutlineThick_Mono_Small, narrow)
	self:SetFont(NumberFont_Shadow_Med, narrow)
	self:SetFont(NumberFont_Normal_Med, narrow) 
	self:SetFont(NumberFont_Outline_Med, narrow) -- bagnon stack count (NumberFontNormal)
	self:SetFont(NumberFont_Outline_Large, narrow)
	
	-- skurri
	self:SetFont(NumberFont_Outline_Huge, narrowBold) -- player/target feedback
	
	-- Morpheus
	-- self:SetFont(QuestFont_Large, narrowBold, nil, "", 0, 0, 0)
	-- self:SetFont(QuestFont_Shadow_Huge, narrowBold, nil, "", 0, 0, 0)
	-- self:SetFont(QuestFont_Super_Huge, narrowBold, nil, "", 0, 0, 0)
	-- self:SetFont(DestinyFontLarge, narrowBold)
	-- self:SetFont(CoreAbilityFont, narrowBold)
	-- self:SetFont(DestinyFontHuge, narrowBold)
	-- self:SetFont(QuestFont_Shadow_Small, narrowBold, nil, "", 0, 0, 0)
	-- self:SetFont(MailFont_Large, narrowBold, nil, "", 0, 0, 0)
	
	-------------------------------------------------------------------------------
	--	Frequently visible exceptions
	-------------------------------------------------------------------------------
	-- error frame/quest updates
	self:SetFont(ErrorFont, narrow, 12, "", .75, -.75, .5)

	-- raid warnings
	self:SetFont(RaidWarningFrameSlot1, narrow, 12, "", .75, -.75, .75)
	self:SetFont(RaidWarningFrameSlot2, narrow, 12, "", .75, -.75, .75)
	self:SetFont(RaidBossEmoteFrameSlot1, narrow, 12, "", .75, -.75, .75)
	self:SetFont(RaidBossEmoteFrameSlot2, narrow, 12, "", .75, -.75, .75)
	
	RaidBossEmoteFrame.timings["RAID_NOTICE_MIN_HEIGHT"] = 12
	RaidBossEmoteFrame.timings["RAID_NOTICE_MAX_HEIGHT"] = 12
	RaidBossEmoteFrame.timings["RAID_NOTICE_SCALE_UP_TIME"] = 0
	RaidBossEmoteFrame.timings["RAID_NOTICE_SCALE_DOWN_TIME"] = 0
	
	RaidWarningFrame.timings["RAID_NOTICE_MIN_HEIGHT"] = 12
	RaidWarningFrame.timings["RAID_NOTICE_MAX_HEIGHT"] = 12
	RaidWarningFrame.timings["RAID_NOTICE_SCALE_UP_TIME"] = 0
	RaidWarningFrame.timings["RAID_NOTICE_SCALE_DOWN_TIME"] = 0

	RaidWarningFrame:SetSize(640, 48)
	RaidBossEmoteFrame:SetSize(640, 56)
	
	-- SystemFont_Shadow_Huge3:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
	-- SystemFont_Shadow_Huge3:SetShadowOffset(1,-1)
	-- SystemFont_Shadow_Huge3:SetShadowColor(0,0,0,0.6)

	-- zone names
	self:SetFont(ZoneTextFont, narrow, 32, "", 1.25, -1.25, .75)
	self:SetFont(SubZoneTextFont, narrow, 24, "", 1.25, -1.25, .75)
	self:SetFont(PVPInfoTextFont, narrow, 16, "", 1.25, -1.25, .75) 
	-- self:SetFont(PVPArenaTextString, narrow, 18, "OUTLINE", 1.5, -1.5, 0.5) -- this is set to PVPInfoTextFont anyway

	if IsAddOnLoaded("Blizzard_CombatText") then
		self:HookCombatText()
	else
		self:RegisterEvent("ADDON_LOADED", function(self, event, addon, ...) 
			if addon == "Blizzard_CombatText" then
				self:HookCombatText()
				self:UnregisterEvent("ADDON_LOADED")
			end
		end)
	end

	-- chat font
	self:SetFont(ChatFontNormal, narrow, nil, nil, .75, -.75, 1) -- chat frames (narrow has roughly same width as the default chat font)
	
	-- numbers
	self:SetFont(NumberFontNormal, narrow, 12, "", 1.25, -1.25, 1)
	
end
