--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Media")

module.OnInit = function(self)
	--------------------------------------------------------------------------------------------------
	--		media library
	--------------------------------------------------------------------------------------------------
	local path = ([[Interface\AddOns\%s\media\]]):format(addon) -- retrieve the actual filepath no matter the addon name
	gUI:SetDefaultMediaPath(path) -- tell gMedia to look for this addon's media in our default media folder
	
	-------------------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------------------
	--
	-- 	The media is only registered in the main addon object, but available to all submodules
	-- 		*the 'gUI™'-prefixes indicates that I made that media and it may not be used without written permission
	-- 		*taking bets on when I'll go completely mental from all the 'gUI™'-names
	--
	-------------------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------------------
	
	-- backgrounds
	gUI:NewMedia("Background", "gUI™ Gloss", [[backgrounds\Gloss64x64.tga]])
	gUI:NewMedia("Background", "gUI™ LargeGloss", [[backgrounds\Gloss256x256.tga]])
	gUI:NewMedia("Background", "gUI™ Shade", [[backgrounds\Shade64x64.tga]])
	gUI:NewMedia("Background", "gUI™ LargeShade", [[backgrounds\Shade256x256.tga]])
	gUI:NewMedia("Background", "gUI™ UnitShader", [[backgrounds\UnitShader256x64.tga]])
	gUI:NewMedia("Background", "gUI™ ItemButton", [[backgrounds\ItemButton32x32.tga]])
	gUI:NewMedia("Background", "gUI™ VoidStorage", [[backgrounds\VoidStorage32x32.tga]])
	
	-- borders
	gUI:NewMedia("Border", "gUI™ GlowBorder", [[borders\gUI-GlowBorder128x16.tga]])
	gUI:NewMedia("Border", "gUI™ GlowBorderLarge", [[borders\gUI-GlowBorder256x32.tga]])
	gUI:NewMedia("Border", "gUI™ PixelBorder", [[borders\gUI-PixelBorder128x16.tga]])
	gUI:NewMedia("Border", "gUI™ PixelBorderIndented", [[borders\gUI-PixelBorder128x16-2px-Indented.tga]])

	-- buttons
	gUI:NewMedia("Button", "gUI™ BagIcon", [[buttons\BagIcon32x32.tga]])
	gUI:NewMedia("Button", "gUI™ BagIconDisabled", [[buttons\BagIconDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ BagIconHighlight", [[buttons\BagIconHighlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ BagRestackIcon", [[buttons\BagRestackIcon64x32.tga]])
	gUI:NewMedia("Button", "gUI™ BagRestackIconDisabled", [[buttons\BagRestackIconDisabled64x32.tga]])
	gUI:NewMedia("Button", "gUI™ BagRestackIconHighlight", [[buttons\BagRestackIconHighlight64x32.tga]])
	
	-- buttons: arrows
	gUI:NewMedia("Button", "gUI™ ArrowBottom", [[buttons\ArrowBottom32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowBottomDisabled", [[buttons\ArrowBottomDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowBottomHighlight", [[buttons\ArrowBottomHighlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowTop", [[buttons\ArrowTop32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowTopDisabled", [[buttons\ArrowTopDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowTopHighlight", [[buttons\ArrowTopHighlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowFirst", [[buttons\ArrowFirst32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowFirstDisabled", [[buttons\ArrowFirstDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowFirstHighlight", [[buttons\ArrowFirstHighlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowLast", [[buttons\ArrowLast32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowLastDisabled", [[buttons\ArrowLastDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowLastHighlight", [[buttons\ArrowLastHighlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowRight", [[buttons\ArrowRight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowRightDisabled", [[buttons\ArrowRightDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowRightHighlight", [[buttons\ArrowRightHighlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowLeft", [[buttons\ArrowLeft32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowLeftDisabled", [[buttons\ArrowLeftDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowLeftHighlight", [[buttons\ArrowLeftHighlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowUp", [[buttons\ArrowUp32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowUpDisabled", [[buttons\ArrowUpDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowUpHighlight", [[buttons\ArrowUpHighlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowDown", [[buttons\ArrowDown32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowDownDisabled", [[buttons\ArrowDownDisabled32x32.tga]])
	gUI:NewMedia("Button", "gUI™ ArrowDownHighlight", [[buttons\ArrowDownHighlight32x32.tga]])

	-- buttons: window navigation
	gUI:NewMedia("Button", "gUI™ CloseButton", [[buttons\gUI-CloseButton32x32-Up.tga]])
	gUI:NewMedia("Button", "gUI™ CloseButtonDown", [[buttons\gUI-CloseButton32x32-Down.tga]])
	gUI:NewMedia("Button", "gUI™ CloseButtonDisabled", [[buttons\gUI-CloseButton32x32-Disabled.tga]])
	gUI:NewMedia("Button", "gUI™ CloseButtonHighlight", [[buttons\gUI-CloseButton32x32-Highlight.tga]])
	gUI:NewMedia("Button", "RefreshArrow", [[buttons\RefreshArrow32x32.tga]])
	gUI:NewMedia("Button", "StopSign", [[buttons\StopSign32x32.tga]])

	-- buttons: grouploot
	gUI:NewMedia("Button", "gUI™ GroupLootGreed", [[buttons\UI-GroupLoot-Coin-Up32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootGreedDown", [[buttons\UI-GroupLoot-Coin-Down32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootGreedHighlight", [[buttons\UI-GroupLoot-Coin-Highlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootDisenchant", [[buttons\UI-GroupLoot-DE-Up32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootDisenchantDown", [[buttons\UI-GroupLoot-DE-Down32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootDisenchantHighlight", [[buttons\UI-GroupLoot-DE-Highlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootNeed", [[buttons\UI-GroupLoot-Dice-Up32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootNeedDown", [[buttons\UI-GroupLoot-Dice-Down32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootNeedHighlight", [[buttons\UI-GroupLoot-Dice-Highlight32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootPass", [[buttons\UI-GroupLoot-Pass-Up32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootPassDown", [[buttons\UI-GroupLoot-Pass-Down32x32.tga]])
	gUI:NewMedia("Button", "gUI™ GroupLootPassHighlight", [[buttons\UI-GroupLoot-Pass-Highlight32x32.tga]])
	
	-- icons
	gUI:NewMedia("Icon", "gUI™ GridIndicator", [[icons\GridIndicatorSquare32x32.tga]])
	gUI:NewMedia("Icon", "gUI™ MailBox2", [[icons\Mailbox2-32x32.tga]])
	gUI:NewMedia("Icon", "Calendar", [[icons\Calendar_32x32.tga]])
	gUI:NewMedia("Icon", "Cog", [[icons\Cog32x32.tga]])
	gUI:NewMedia("Icon", "FactionAlliance", [[icons\Faction-Alliance32x32.tga]])
	gUI:NewMedia("Icon", "FactionHorde", [[icons\Faction-Horde32x32.tga]])
	gUI:NewMedia("Icon", "RaidTarget", [[icons\UI-RaidTargetingIcons.tga]]) -- hank the tank's icons
	gUI:NewMedia("Icon", "GlyphIcons", [[icons\glyphicons.tga]]) 

	-- icons: emoticons
	gUI:NewMedia("Icon", "Emoticon: Angel", [[icons\Emoticon-angel16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Confused", [[icons\Emoticon-confused16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Cry", [[icons\Emoticon-cry16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Devil", [[icons\Emoticon-devil16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Frown", [[icons\Emoticon-frown16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Gasp", [[icons\Emoticon-gasp16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Glasses", [[icons\Emoticon-glasses16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Grin", [[icons\Emoticon-grin16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Grumpy", [[icons\Emoticon-grumpy16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Heart", [[icons\Emoticon-heart16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Kiki", [[icons\Emoticon-kiki16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Kiss", [[icons\Emoticon-kiss16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Smile", [[icons\Emoticon-smile16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Squint", [[icons\Emoticon-squint16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Sunglasses", [[icons\Emoticon-sunglasses16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Tongue", [[icons\Emoticon-tongue16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Unsure", [[icons\Emoticon-unsure16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Upset", [[icons\Emoticon-upset16x16.tga]])
	gUI:NewMedia("Icon", "Emoticon: Wink", [[icons\Emoticon-wink16x16.tga]])
	
	-- masks (white on transparent objects)
	gUI:NewMedia("Mask", "gUI™ Circle", [[textures\gUI-MinimapMask256x256-Circle.tga]])
	gUI:NewMedia("Mask", "gUI™ Square", [[textures\gUI-MinimapMask256x256-Square.tga]])
	gUI:NewMedia("Mask", "gUI™ RoundedSquare", [[textures\gUI-MinimapMask256x256-RoundedSquare.tga]])
	
	-- statusbars
	gUI:NewMedia("Statusbar", "gUI™ StatusBar", [[statusbars\gUI-StatusBar.tga]])
	gUI:NewMedia("Statusbar", "gUI™ ProgressBar", [[statusbars\progressbar.tga]])
	
	-- textures
	gUI:NewMedia("Texture", "gUI™ BigNumbers", [[textures\gUI-BigTimerNumbers.tga]])
	gUI:NewMedia("Texture", "gUI™ BigNumbersGlow", [[textures\gUI-BigTimerNumbersGlow.tga]])
	gUI:NewMedia("Texture", "BubbleTexture", [[textures\bubbleTex.tga]])
	gUI:NewMedia("Texture", "CooldownStar", [[textures\star4.tga]])
	gUI:NewMedia("Texture", "CooldownStarburst", [[textures\starburst.tga]])
	
	-- v3 fonts
	gUI:NewMedia("Font", "Oswald Light", [[fonts\Oswald-Light.ttf]])
	gUI:NewMedia("Font", "Oswald Regular", [[fonts\Oswald-Regular.ttf]])
	gUI:NewMedia("Font", "Oswald Bold", [[fonts\Oswald-Bold.ttf]])
	gUI:NewMedia("Font", "PT Sans Narrow", [[fonts\PT Sans Narrow.ttf]])
	gUI:NewMedia("Font", "PT Sans Narrow Bold", [[fonts\PT Sans Narrow Bold.ttf]])
	gUI:NewMedia("Font", "PT Serif", [[fonts\PT Serif.ttf]])
	gUI:NewMedia("Font", "PT Serif Bold", [[fonts\PT Serif Bold.ttf]])
	gUI:NewMedia("Font", "Ubuntu Light", [[fonts\Ubuntu-L.ttf]])
	gUI:NewMedia("Font", "Ubuntu Bold", [[fonts\Ubuntu-B.ttf]])
	gUI:NewMedia("Font", "Ubuntu Medium", [[fonts\Ubuntu-M.ttf]])
	gUI:NewMedia("Font", "Ubuntu Condensed", [[fonts\Ubuntu-C.ttf]])

	-- v2 fonts
	gUI:NewMedia("Font", "Big Noodle Titling", [[fonts\BigNoodleTitling.ttf]])
	gUI:NewMedia("Font", "TrashHand", [[fonts\TrashHand.ttf]])

	-- v1 fonts
	-- gUI:NewMedia("Font", "Righteous Kill Condensed", [[fonts\RighteousKill-Condensed.ttf]])

	-- sounds
	gUI:NewMedia("Sound", "Chat Whisper", [[sounds\chat_whisper.mp3]])

	-- backdrops
	gUI:NewMedia("Backdrop", "SimpleBorder", {
		bgFile = gUI:GetMedia("Background", "Blank"); 
		edgeFile = gUI:GetMedia("Background", "Blank"); 
		edgeSize = 1;
		insets = { 
			bottom = -1; 
			left = -1; 
			right = -1; 
			top = -1; 
		};
	})

	gUI:NewMedia("Backdrop", "PixelBorder", {
		edgeFile = gUI:GetMedia("Border", "gUI™ PixelBorder"); 
		edgeSize = 8;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})

	gUI:NewMedia("Backdrop", "PixelBorder-Blank", {
		bgFile = gUI:GetMedia("Background", "Blank"); 
		edgeFile = gUI:GetMedia("Border", "gUI™ PixelBorder"); 
		edgeSize = 8;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})

	gUI:NewMedia("Backdrop", "PixelBorder-Blank-Indented", {
		bgFile = gUI:GetMedia("Background", "Blank"); 
		edgeFile = gUI:GetMedia("Border", "gUI™ PixelBorderIndented"); 
		edgeSize = 8;
		insets = { 
			bottom = 2; 
			left = 2; 
			right = 2; 
			top = 2; 
		};
	})

	gUI:NewMedia("Backdrop", "TargetBorder", {
		edgeFile = gUI:GetMedia("Background", "Blank"); 
		edgeSize = 2;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})
	
	gUI:NewMedia("Backdrop", "HighlightBorder", {
		bgFile = gUI:GetMedia("Background", "Blank"); 
		edgeFile = gUI:GetMedia("Background", "Blank"); 
		edgeSize = 2;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})
	
	gUI:NewMedia("Backdrop", "StatusBarBorder", {
		bgFile = gUI:GetMedia("Statusbar", "gUI™ StatusBar"); 
		edgeFile = gUI:GetMedia("Border", "gUI™ PixelBorder"); 
		edgeSize = 8;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})
	
	gUI:NewMedia("Backdrop", "TinyGlow", {
		edgeFile = gUI:GetMedia("Border", "gUI™ GlowBorder"); 
		edgeSize = 3;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})

	gUI:NewMedia("Backdrop", "SmallGlow", {
		edgeFile = gUI:GetMedia("Border", "gUI™ GlowBorder"); 
		edgeSize = 5;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})

	gUI:NewMedia("Backdrop", "Glow", {
		edgeFile = gUI:GetMedia("Border", "gUI™ GlowBorder"); 
		edgeSize = 16;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})

	gUI:NewMedia("Backdrop", "HugeGlow", {
		edgeFile = gUI:GetMedia("Border", "gUI™ GlowBorderLarge"); 
		edgeSize = 32;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})

	gUI:NewMedia("Backdrop", "ItemButton", {
		bgFile = gUI:GetMedia("Background", "gUI™ ItemButton");
		edgeFile = gUI:GetMedia("Border", "gUI™ PixelBorder"); 
		edgeSize = 8;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})

	gUI:NewMedia("Backdrop", "VoidStorageButton", {
		bgFile = gUI:GetMedia("Background", "gUI™ VoidStorage");
		edgeFile = gUI:GetMedia("Border", "gUI™ PixelBorder"); 
		edgeSize = 8;
		insets = { 
			bottom = 0; 
			left = 0; 
			right = 0; 
			top = 0; 
		};
	})
	
	-- register some stuff with LibSharedMedia-3.0 
	local LSM = LibStub("LibSharedMedia-3.0", true)
	if (LSM) then
		LSM:Register("border", "gUI™ PixelBorder", path .. [[borders\gUI-PixelBorder128x16.tga]])
		LSM:Register("border", "gUI™ PixelBorderIndented", path .. [[borders\gUI-PixelBorder128x16-2px-Indented.tga]])
		LSM:Register("font", "Oswald Light", path .. [[fonts\Oswald-Light.ttf]])
		LSM:Register("font", "Oswald Regular", path .. [[fonts\Oswald-Regular.ttf]])
		LSM:Register("font", "Oswald Bold", path .. [[fonts\Oswald-Bold.ttf]])
		LSM:Register("font", "PT Sans Narrow", path .. [[fonts\PT Sans Narrow.ttf]])
		LSM:Register("font", "PT Sans Narrow Bold", path .. [[fonts\PT Sans Narrow Bold.ttf]])
		LSM:Register("statusbar", "gUI™ StatusBar", path .. [[statusbars\gUI-StatusBar.tga]])
	end
	-- [[Interface\AddOns\gUI-v3\media\fonts\PT Sans Narrow.ttf]]
	-- LibStub("LibSharedMedia-3.0", true):List("statusbar")
	
end
