local ADDON = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon(ADDON, true)
if not gUI4 then return end

local lib = {}
lib.texture = gUI4:CreateMediaLibrary("Texture")
lib.frame = gUI4:CreateMediaLibrary("Frame")
lib.button = gUI4:CreateMediaLibrary("Button")
lib.border = gUI4:CreateMediaLibrary("Border")
lib.statusbar = gUI4:CreateMediaLibrary("StatusBar")
lib.sound = gUI4:CreateMediaLibrary("Sound")
lib.font = gUI4:CreateMediaLibrary("Font")
lib.emoticon = gUI4:CreateMediaLibrary("Emoticon")


-- :CreateMedia()
	-- :SetTheme() -- names the theme the media belongs to
	-- :SetName() -- sets a name for your media. doesn't need to be unique, but you should set different elements to all items with the same name
	-- :SetElement() -- names what kind of element of the media it is ("Normal", "Highlight", "Glow" etc)
	-- :SetAlpha() -- preferred alpha of the media 
	-- :SetColor() -- preferred color of the media 
	-- :SetInset() -- insets used for backdrops 
	-- :SetOffset() -- offset used for backdrops that needs to be outside of the frame 
	-- :SetPath() -- file path of the media
	-- :SetPrefix() -- custom prefix for the media item, mainly used for myself to identify gUI3 media
	-- :SetPoint() -- where the media will be placed relative to its parent
	-- :SetSize() -- size of the displayed media
	-- :SetGridSlotSize() -- sets the size of a grid, which in combination with :SetSize() and :SetTexSize() can be used to calculate texcoords
	-- :SetGridItemTexCoord() -- sets the pixel offsets of each grid item from the top left corner of each grid slot
	-- :SetTexCoord() -- texcoords of the displayed media
	-- :SetTexSize() -- pixel sizes of the entire media file
	-- :WriteProtect() -- close the entry for further modifications. this is what 3rd parties should be using. 
	-- :ConstructPath() -- only meant for internal usage, only compatible with default gUI4 media. use :SetPath() instead. 
	-- :Close() -- class both :ConstructPath() and :WriteProtect() in one go


--		UnitFrames
------------------------------------------------------------------------------
do
	-- frames
	do
		--	300 x 74 Warcraft - player/target health+power (11px)
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -106, 38) :SetSize(300, 74) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -106, 38) :SetSize(300, 74) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -106, 38) :SetSize(300, 74) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Threat") :SetPoint("TOPLEFT", -106, 38) :SetSize(300, 74) :SetTexSize(512, 128) :Close()

		--	300 x 70 Warcraft - player/target health+power (7px)
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -106, 38) :SetSize(300, 70) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -106, 38) :SetSize(300, 70) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -106, 38) :SetSize(300, 70) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Threat") :SetPoint("TOPLEFT", -106, 38) :SetSize(300, 70) :SetTexSize(512, 128) :Close()

    -- 192x51 Warcraft - boss/party/arena
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -32, 39) :SetSize(192, 51) :SetTexSize(256, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -32, 39) :SetSize(192, 51) :SetTexSize(256, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -32, 39) :SetSize(192, 51) :SetTexSize(256, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Threat") :SetPoint("TOPLEFT", -32, 39) :SetSize(192, 51) :SetTexSize(256, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Target") :SetPoint("TOPLEFT", -32, 39) :SetSize(192, 51) :SetTexSize(256, 128) :Close()
    
    -- 192x16 Warcraft - boss altpower
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -32, 24) :SetSize(192, 16) :SetTexSize(256, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -32, 24) :SetSize(192, 16) :SetTexSize(256, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -32, 24) :SetSize(192, 16) :SetTexSize(256, 64) :Close()
    
		-- 148x40 Warcraft - pet/pettarget/tot/tottarget/focus/focustarget health
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -54, 12) :SetSize(148, 40) :SetTexSize(256, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -54, 12) :SetSize(148, 40) :SetTexSize(256, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -54, 12) :SetSize(148, 40) :SetTexSize(256, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Threat") :SetPoint("TOPLEFT", -54, 12) :SetSize(148, 40) :SetTexSize(256, 64) :Close()

		--	80 x 36 Warcraft - raid health only
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -24, 14) :SetSize(80, 36) :SetTexSize(128, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -24, 14) :SetSize(80, 36) :SetTexSize(128, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -24, 14) :SetSize(80, 36) :SetTexSize(128, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Threat") :SetPoint("TOPLEFT", -24, 14) :SetSize(80, 36) :SetTexSize(128, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Target") :SetPoint("TOPLEFT", -24, 14) :SetSize(80, 36) :SetTexSize(128, 64) :Close()
    
		--	80 x 51 Warcraft - raid health+power
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -24, 7) :SetSize(80, 51) :SetTexSize(128, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -24, 7) :SetSize(80, 51) :SetTexSize(128, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -24, 7) :SetSize(80, 51) :SetTexSize(128, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Threat") :SetPoint("TOPLEFT", -24, 7) :SetSize(80, 51) :SetTexSize(128, 64) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Target") :SetPoint("TOPLEFT", -24, 7) :SetSize(80, 51) :SetTexSize(128, 64) :Close()
	end

	-- statusbars
	do
		-- big awesome health bar
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(512, 64) :SetElement("Normal") :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(512, 64) :SetElement("Overlay") :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(512, 64) :SetElement("Backdrop") :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(512, 64) :SetElement("Threat") :Close() 
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(512, 64) :SetElement("Power") :Close()

		-- dry, glowing power bar
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(512, 64) :SetElement("Dark") :Close()

		-- bar sparks
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(128, 128) :SetTexSize(128, 128) :SetElement("Spark") :SetPoint("RIGHT", 64, 0) :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(128, 128) :SetTexSize(128, 128) :SetElement("SparkReverse") :SetPoint("LEFT", -64, 0) :Close()
	end

	-- auras
	do
		-- general button shade used for auras 
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("Shade") :SetSize(64, 64) :SetTexSize(64, 64) :Close()
	end

	-- icons
	do
		-- spirit healer
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("SpiritHealer") :SetSize(280, 170) :SetTexSize(512, 256) :SetPoint("TOPLEFT", -111, 43) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("SpiritHealerGlowing") :SetSize(280, 170) :SetTexSize(512, 256) :SetPoint("TOPLEFT", -111, 43) :Close()
    
		-- group role icons
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("RoleIconGrid") :SetGridSlotSize(32, 32) :SetNumGridItems(3) :SetPoint("CENTER", 0, 0) :SetSize(32, 32) :SetTexSize(64, 64) :Close()
    
	end

	-- class resources
	do
		-- v4 default
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourcePill") :SetSize(128, 32) :SetTexSize(128, 32) :SetPoint("TOPLEFT", 0, 0) :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourcePillGloss") :SetAlpha(.75) :SetSize(128, 32) :SetTexSize(128, 32) :SetPoint("TOPLEFT", 0, 0) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetSize(252, 23) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 21) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop3Notches") :SetSize(252, 23) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 21) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop4Notches") :SetSize(252, 23) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 21) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop5Notches") :SetSize(252, 23) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 21) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop6Notches") :SetSize(252, 23) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 21) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetSize(252, 36) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 14) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetSize(252, 36) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 14) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetSize(252, 26) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130 -6, 14 +6) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetSize(252, 26) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130 -6, 14 +6) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop4NotchesBar") :SetSize(252, 26) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 14) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop5NotchesBar") :SetSize(252, 26) :SetTexSize(512, 64) :SetPoint("TOPLEFT", -130, 14) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourcePill") :SetSize(48, 13) :SetTexSize(48, 13) :SetPoint("TOPLEFT", 0, 0) :SetPath(gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"):GetPath()) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourcePill") :SetSize(48, 11) :SetTexSize(48, 11) :SetPoint("TOPLEFT", 0, 0) :SetPath(gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"):GetPath()) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourcePill") :SetSize(48, 3) :SetTexSize(48, 3) :SetPoint("TOPLEFT", 0, 0) :SetPath("BLANK") :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourcePill") :SetSize(46, 1) :SetTexSize(46, 1) :SetPoint("TOPLEFT", 0, 0) :SetPath("BLANK") :Close()

		
		-- combo points & anticipation
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("RedOrb") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -14, 13) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("RedOrbSmall") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -41, 41) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ComboPoints5") :SetSize(256, 128) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -25, 40) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ComboPoints10") :SetSize(256, 128) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -25, 40) :Close()
		
		-- chi
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("GreenOrb") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -14, 13) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ComboPoints4") :SetSize(256, 128) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -46, 40) :Close()
		
		-- shadow orbs
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("PurpleOrb") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -14, 13) :Close()
		
		-- soul shards
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("SoulShardEmpty") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("SoulShardFull") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		
		-- arcane charges
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("BlueOrb") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -14, 13) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ComboPoints4WithBar") :SetSize(256, 128) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -46, 40) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ComboPoints5WithBar") :SetSize(256, 128) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -25, 40) :Close()
		
		-- burning embers
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourceBarBackdrop") :SetSize(196, 28) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -30, 50) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourceBarOverlay4Parts") :SetSize(196, 28) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -30, 50) :Close()

		-- holy power
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("GoldOrb") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -14, 13) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("GoldOrbSmall") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -41, 41) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ComboPoints3Orb") :SetSize(256, 128) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -66, 40) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ComboPoints3_2Orb") :SetSize(256, 128) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -66, 40) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourceBarOverlay3Parts") :SetSize(196, 28) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -30, 50) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourceBarOverlay5Parts") :SetSize(196, 28) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -30, 50) :Close()
		
		-- demonic fury
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourceBarOverlay1Part") :SetSize(196, 28) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -30, 50) :Close()
	
		-- runes
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("BloodRuneEmpty") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("BloodRuneFull") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("FrostRuneEmpty") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("FrostRuneFull") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("UnholyRuneEmpty") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("UnholyRuneFull") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("DeathRuneEmpty") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("DeathRuneFull") :SetSize(64, 64) :SetTexSize(64, 64) :SetPoint("TOPLEFT", -13, 6) :Close()
		
		-- eclipse
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("ResourceBarOverlay2Parts") :SetSize(196, 28) :SetTexSize(256, 128) :SetPoint("TOPLEFT", -30, 50) :Close()
		
	end
end


--		Actionbar Backdrops
------------------------------------------------------------------------------
do
	-- 36x36 buttons
	do
		--	474x168 Warcraft - 36x36 buttons, 3 bars + rep & xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 62) :SetSize(474, 168) :SetTexSize(512, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 62) :SetSize(474, 168) :SetTexSize(512, 256) :Close()

		--	474x150 Warcraft - 36x36 buttons, 3 bars + rep or xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 62) :SetSize(474, 150) :SetTexSize(512, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 62) :SetSize(474, 150) :SetTexSize(512, 256) :Close()

		--	474x132 Warcraft - 36x36 buttons, 3 bars (no rep/xp)
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -19, 62) :SetSize(474, 132) :SetTexSize(512, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 62) :SetSize(474, 132) :SetTexSize(512, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 62) :SetSize(474, 132) :SetTexSize(512, 256) :Close()

		--	474x130 Warcraft - 36x36 buttons, 2 bars + rep & xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 130) :SetTexSize(512, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 130) :SetTexSize(512, 256) :Close()

		--	474x112 Warcraft - 36x36 buttons, 2 bars + rep or xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 112) :SetTexSize(512, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 112) :SetTexSize(512, 256) :Close()

		--	474x94 Warcraft - 36x36 buttons, 2 bars (no rep/xp)
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 94) :SetTexSize(512, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 94) :SetTexSize(512, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 94) :SetTexSize(512, 256) :Close()

		--	474x92 Warcraft - 36x36 buttons, 1 bar + rep & xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 92) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 92) :SetTexSize(512, 128) :Close()

		--	474x74 Warcraft - 36x36 buttons, 1 bar + rep or xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 74) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 74) :SetTexSize(512, 128) :Close()

		--	474x56 Warcraft - 36x36 buttons, 1 bar (no rep/xp)
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 56) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 56) :SetTexSize(512, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -19, 17) :SetSize(474, 56) :SetTexSize(512, 128) :Close()
	end

	-- 44x44 buttons
	do
		--	570x192 Warcraft - 44x44 buttons, 3 bars + rep & xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 192) :SetTexSize(1024, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 192) :SetTexSize(1024, 256) :Close()

		--	570x174 Warcraft - 44x44 buttons, 3 bars + rep or xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 174) :SetTexSize(1024, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 174) :SetTexSize(1024, 256) :Close()

		--	570x156 Warcraft - 44x44 buttons, 3 bars (no rep/xp)
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 156) :SetTexSize(1024, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 156) :SetTexSize(1024, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 156) :SetTexSize(1024, 256) :Close()

		--	570x146 Warcraft - 44x44 buttons, 2 bars + rep & xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 146) :SetTexSize(1024, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 146) :SetTexSize(1024, 256) :Close()

		--	570x128 Warcraft - 44x44 buttons, 2 bars + rep or xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 128) :SetTexSize(1024, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 128) :SetTexSize(1024, 256) :Close()

		--	570x110 Warcraft - 44x44 buttons, 2 bars (no rep/xp)
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 110) :SetTexSize(1024, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 110) :SetTexSize(1024, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 50) :SetSize(570, 110) :SetTexSize(1024, 256) :Close()

		--	570x100 Warcraft - 44x44 buttons, 1 bar + rep & xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 14) :SetSize(570, 100) :SetTexSize(1024, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 14) :SetSize(570, 100) :SetTexSize(1024, 128) :Close()

		--	570x82 Warcraft - 44x44 buttons, 1 bar + rep or xp
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 14) :SetSize(570, 82) :SetTexSize(1024, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 14) :SetSize(570, 82) :SetTexSize(1024, 128) :Close()

		--	570x64 Warcraft - 44x44 buttons, 1 bar (no rep/xp)
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Backdrop") :SetPoint("TOPLEFT", -227, 14) :SetSize(570, 64) :SetTexSize(1024, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Border") :SetPoint("TOPLEFT", -227, 14) :SetSize(570, 64) :SetTexSize(1024, 128) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -227, 14) :SetSize(570, 64) :SetTexSize(1024, 128) :Close()
	end
	
	-- xp/rep bar spark
	do
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(16, 16) :SetTexSize(16, 16) :SetElement("Spark") :SetPoint("RIGHT", 8, 0) :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(16, 16) :SetTexSize(16, 16) :SetElement("SparkReverse") :SetPoint("LEFT", -8, 0) :Close()		
	end
end


-- 		Minimap
------------------------------------------------------------------------------
do
	-- 160x160 circular
	do
		-- Warcraft w/cogwheels
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("CircularNormal") :SetPoint("TOPLEFT", -48, 48) :SetSize(160, 160) :SetTexSize(256, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("CircularBackdrop") :SetPoint("TOPLEFT", -48, 48) :SetSize(160, 160) :SetTexSize(256, 256) :Close()
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("CircularCompassOverlay") :SetPoint("TOPLEFT", -48, 48) :SetSize(160, 160) :SetTexSize(256, 256) :Close()
		
		-- Warcraft w/o cogwheel
		lib.frame:CreateMedia() :SetTheme("Warcraft") :SetElement("CircularRing") :SetPoint("TOPLEFT", -48, 48) :SetSize(160, 160) :SetTexSize(256, 256) :Close()
		
		-- circular mask
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetName("CircularMask") :SetPath(gUI4:GetMediaPath("Texture", "gUI4_MinimapCircularMask.tga")) :SetSize(256, 256) :SetPoint("TOPLEFT", 0, 0) :SetTexSize(256, 256) :Close()

		-- cogwheel animation
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("CogGrid") :SetGridSlotSize(204, 204) :SetNumGridItems(20) :SetPoint("TOPLEFT", -22, 22) :SetSize(160, 160) :SetTexSize(1024, 1024) :Close()

		-- plus sign for MBB
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("WhitePlus") :SetSize(32, 32) :SetPoint("TOPLEFT", 0, 0) :SetTexSize(32, 32) :Close()
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("WhitePlusRounded") :SetSize(32, 32) :SetPoint("TOPLEFT", 0, 0) :SetTexSize(32, 32) :Close()
    
		-- garrison swords
		lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("GarrisonIconGrid") :SetGridSlotSize(64, 64) :SetNumGridItems(4) :SetPoint("TOPLEFT", 0, 0) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
    
	end
end


-- 		ActionButtons
------------------------------------------------------------------------------
do
	--	36 x 36 Warcraft
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("WeaponSlot") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("WeaponSlotHighlight") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("BagSlot") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("BagSlotHighlight") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("EmptySlot") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("EmptySlotHighlight") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Checked") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("CheckedHighlight") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()

	--	44 x 44 Warcraft
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("WeaponSlot") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("WeaponSlotHighlight") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("BagSlot") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("BagSlotHighlight") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("EmptySlot") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("EmptySlotHighlight") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Checked") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("CheckedHighlight") :SetPoint("TOPLEFT", -10, 10) :SetSize(44, 44) :SetTexSize(64, 64) :Close()

	--	64 x 64 Warcraft
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Highlight") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("WeaponSlot") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("WeaponSlotHighlight") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("BagSlot") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("BagSlotHighlight") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("EmptySlot") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("EmptySlotHighlight") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("Checked") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
	lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("CheckedHighlight") :SetPoint("TOPLEFT", -32, 32) :SetSize(64, 64) :SetTexSize(128, 128) :Close()
end


-- 		CastBars
------------------------------------------------------------------------------
do
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("PlayerCastBarBackdrop") :SetSize(196, 28) :SetTexSize(256, 64) :SetPoint("TOPLEFT", -48, 18) :Close()
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("PlayerCastBar") :SetSize(196, 28) :SetTexSize(256, 64) :SetPoint("TOPLEFT", -48, 18) :Close()

	lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(512, 64) :SetElement("Resource") :Close()
	lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(512, 64) :SetElement("ResourceOverlay") :Close()
end


-- 		Tooltips
------------------------------------------------------------------------------
do
	lib.border:CreateMedia() :SetTheme("Warcraft") :SetElement("Tooltip") :SetInset(6) :SetOffset(6) :SetSize(256,32) :Close()
end


-- 		NamePlates
------------------------------------------------------------------------------
do
	-- full nameplates
	do
		-- health & castbars
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(128, 16) :SetElement("Normal") :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(128, 16) :SetElement("Overlay") :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(128, 16) :SetElement("Backdrop") :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(128, 16) :SetElement("Threat") :Close()
		
		-- outside glows
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(128, 16) :SetElement("Glow") :SetColor(0, 0, 0, .5) :SetTexSize(256, 64) :SetPoint("TOPLEFT", -64, 24) :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(96, 12) :SetElement("Glow") :SetColor(0, 0, 0, .5) :SetTexSize(256, 64) :SetPoint("TOPLEFT", -80, 26) :Close()
		
		-- spellcast icons
		lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("CastBorderNormal") :SetPoint("TOPLEFT", -14, 14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
		lib.button:CreateMedia() :SetTheme("Warcraft") :SetElement("CastBorderShield") :SetPoint("BOTTOMLEFT", -14, -14) :SetSize(36, 36) :SetTexSize(64, 64) :Close()
	end

	-- trivial nameplates
	do
		-- healthbars
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(64, 8) :SetElement("Normal") :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(64, 8) :SetElement("Overlay") :SetAlpha(.5) :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(64, 8) :SetElement("Backdrop") :SetTexSize(64, 8) :Close()
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(64, 8) :SetElement("Threat") :SetAlpha(.75) :Close()

		-- outside glows
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(64, 8) :SetElement("Glow") :SetColor(0, 0, 0, .5) :SetTexSize(128, 32) :SetPoint("TOPLEFT", -32, 12) :Close() 
		lib.statusbar:CreateMedia() :SetTheme("Warcraft") :SetSize(72, 8) :SetElement("Glow") :SetColor(0, 0, 0, .5) :SetTexSize(128, 32) :SetPoint("TOPLEFT", -28, 12) :Close() 
	end
end


-- 		General Textures
------------------------------------------------------------------------------
do
	-- general blank texture used in backdrops and other things
	lib.texture:CreateMedia() :SetTheme("Blizzard") :SetName("Blank") :SetPath([[Interface\ChatFrame\ChatFrameBackground]]) :Close()
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetName("Blank") :SetPath([[Interface\ChatFrame\ChatFrameBackground]]) :Close()

	-- empty texture to hide stuff
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetName("Empty") :SetSize(.001, .001) :SetTexSize(.001, .001) :SetPoint("TOPLEFT", 0, 0) :SetPath(gUI4:GetMediaPath("Texture", "gUI4_Texture_16x16_Empty.tga")) :Close()
	
	-- stuff
	lib.texture:CreateMedia() :SetTheme("Blizzard") :SetName("Alliance Logo Large") :SetPath(gUI4:GetMediaPath("Texture", "Blizzard_AllianceLogo.tga")) :SetSize(256, 256) :SetPoint("TOPLEFT", 0, 0) :SetTexSize(256, 256) :Close()
	lib.texture:CreateMedia() :SetTheme("Blizzard") :SetName("Horde Logo Large") :SetPath(gUI4:GetMediaPath("Texture", "Blizzard_HordeLogo.tga")) :SetSize(256, 256) :SetPoint("TOPLEFT", 0, 0) :SetTexSize(256, 256) :Close()
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("FactionAlliance") :SetSize(32, 32) :SetTexSize(32, 32) :Close()
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("FactionHorde") :SetSize(32, 32) :SetTexSize(32, 32) :Close()
	
end	


-- 		Icon Grids
------------------------------------------------------------------------------
do
	-- character classes
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("CharacterClassesGrid") :SetSize(56, 56) :SetGridSlotSize(64, 64) :SetGridItemTexCoord(0, 55, 0, 55) :SetTexSize(256, 256) :Close()

	-- timer numbers
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("Normal") :SetName("Big Timer Numbers") :SetPath(gUI4:GetMediaPath("Texture", "gUI4_BigTimerNumbers_Warcraft.tga")) :SetSize(256, 170) :SetGridSlotSize(256, 170) :SetTexSize(1024, 512) :Close()
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetElement("Glow") :SetName("Big Timer Numbers") :SetPath(gUI4:GetMediaPath("Texture", "gUI4_BigTimerNumbersGlow_Warcraft.tga")) :SetSize(256, 170) :SetGridSlotSize(256, 170) :SetTexSize(1024, 512) :Close()

	-- raid icons 
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(64, 64) :SetElement("RaidIconGrid") :SetTexSize(256, 256) :SetGridSlotSize(64, 64) :SetPoint("CENTER", 0, 0) :SetNumGridItems(8) :Close()
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(64, 64) :SetElement("RaidIconGlowGrid") :SetTexSize(256, 256) :SetGridSlotSize(64, 64) :SetPoint("CENTER", 0, 0) :SetNumGridItems(8) :Close()

	-- player state icons 
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(64, 64) :SetElement("StateIconGrid") :SetTexSize(128, 128) :SetGridSlotSize(64, 64) :SetPoint("CENTER", 0, 0) :SetNumGridItems(4) :Close()

	-- world state icons
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(32, 32) :SetElement("WorldStateGrid") :SetTexSize(128, 128) :SetGridSlotSize(32, 32) :SetPoint("TOPLEFT", 0, 0) :SetNumGridItems(7) :Close()

	-- expand/collapse for quest tracker
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(32, 32) :SetElement("TrackerButtonGrid") :SetTexSize(64, 64) :SetGridSlotSize(32, 32) :SetPoint("TOPRIGHT", 0, 6) :SetNumGridItems(4) :Close()
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(32, 32) :SetElement("TrackerButtonDisabled") :SetTexSize(32, 32) :SetPoint("TOPLEFT", 0, 0) :Close() -- disabled

	-- expand/collapse for UI panels (group leader tools)
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(32, 64) :SetElement("PanelArrowGrid") :SetTexSize(64, 64) :SetGridSlotSize(32, 64) :SetPoint("TOPRIGHT", 0, 0) :SetNumGridItems(2) :Close()

	-- smartbar
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(32, 32) :SetElement("SmartBarGrid") :SetTexSize(512, 256) :SetGridSlotSize(64, 64) :SetPoint("TOPLEFT", 0, 0) :SetNumGridItems(32) :Close()
	lib.texture:CreateMedia() :SetTheme("Warcraft") :SetSize(32, 32) :SetElement("SmartBarGridHighlight") :SetTexSize(512, 256) :SetGridSlotSize(64, 64) :SetPoint("TOPLEFT", 0, 0) :SetNumGridItems(32) :Close()
end


-- 		Sounds
------------------------------------------------------------------------------
do
	lib.sound:CreateMedia() :SetName("Whisper") :SetPath(gUI4:GetMediaPath("Sound", "chat_whisper.mp3")) :Close()
end


-- 		Fonts
------------------------------------------------------------------------------
do
	lib.font:CreateMedia() :SetName("DejaVuSans") :SetPath(gUI4:GetMediaPath("Font", "DejaVuSans.ttf")) :Close()
	lib.font:CreateMedia() :SetName("DejaVuSans-Bold") :SetPath(gUI4:GetMediaPath("Font", "DejaVuSans-Bold.ttf")) :Close()
	lib.font:CreateMedia() :SetName("DejaVuSansCondensed") :SetPath(gUI4:GetMediaPath("Font", "DejaVuSansCondensed.ttf")) :Close()
	lib.font:CreateMedia() :SetName("DejaVuSansCondensed-Bold") :SetPath(gUI4:GetMediaPath("Font", "DejaVuSansCondensed-Bold.ttf")) :Close()
	lib.font:CreateMedia() :SetName("DejaVuSans-ExtraLight") :SetPath(gUI4:GetMediaPath("Font", "DejaVuSans-ExtraLight.ttf")) :Close()
end


-- 		Emoticons
------------------------------------------------------------------------------
do
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("angry") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_angry.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("balloon") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_balloon.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("big_grin") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_big-grin.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("bomb") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_bomb.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("broken_heart") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_broken-heart.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("cake") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_cake.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("cat") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_cat.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("clock") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_clock.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("clown") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_clown.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("cold") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_cold.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("confused") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_confused.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("cool") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_cool.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("crying") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_crying.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("crying2") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_crying2.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("dead") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_dead.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("devil") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_devil.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("dizzy") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_dizzy.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("dog") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_dog.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("dont_tell_anyone") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_don't-tell-anyone.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("drinks") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_drinks.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("drooling") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_drooling.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("flower") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_flower.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("ghost") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_ghost.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("gift") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_gift.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("girl") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_girl.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("goodbye") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_goodbye.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("heart") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_heart.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("hug") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_hug.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("kiss") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_kiss.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("laughing") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_laughing.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("ligthbulb") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_ligthbulb.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("loser") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_loser.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("love") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_love.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("mail") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_mail.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("music") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_music.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("nerd") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_nerd.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("night") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_night.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("ninja") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_ninja.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("not_talking") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_not-talking.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("on_the_phone") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_on-the-phone.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("party") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_party.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("pig") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_pig.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("poo") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_poo.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("rainbow") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_rainbow.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("rainning") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_rainning.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sacred") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sacred.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sad") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sad.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("scared") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_scared.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sick") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sick.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sick2") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sick2.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("silly") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_silly.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sleeping") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sleeping.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sleeping2") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sleeping2.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sleepy") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sleepy.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sleepy2") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sleepy2.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("smile") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_smile.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("smoking") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_smoking.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("smug") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_smug.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("stars") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_stars.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("straight_face") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_straight-face.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sun") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sun.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("sweating") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_sweating.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("thinking") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_thinking.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("tongue") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_tongue.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("vomit") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_vomit.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("wave") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_wave.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("whew") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_whew.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("win") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_win.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("winking") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_winking.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("yawn") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_yawn.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("yawn2") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_yawn2.tga")) :Close()
	lib.emoticon:CreateMedia() :SetTheme("Default") :SetName("zombie") :SetPath(gUI4:GetMediaPath("Emoticon", "emoticon_zombie.tga")) :Close()
end
