local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Tooltip", true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local path = ([[Interface\AddOns\%s\media\]]):format(addon)

parent:RegisterTheme("Warcraft", {
	place = { "BOTTOMRIGHT", -20, 20 + 32 + 10 }, 
	bar = {
		size = 10,
		color = { 63/255, 114/255, 25/255 },
		backdropmultiplier = 1,
		textures = {
			backdrop = gUI4:GetMedia("StatusBar", "Backdrop", 512, 64, "Warcraft"),
			normal = gUI4:GetMedia("StatusBar", "Power", 512, 64, "Warcraft"),
			overlay = gUI4:GetMedia("StatusBar", "ResourceOverlay", 512, 64, "Warcraft")
		},
		value = {
			size = 12,
			fontobject = TextStatusBarText,
			fontstyle = nil,
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, 1 },
			color = gUI4:GetColors("chat", "offwhite"),
			place = { "CENTER", 0, 0 }
		}
	},
	colors = {
		backdrop = { 0, 0, 0, .75 },
		border = { 1, 1, 1, 1 },
		itemBonus = { .15, .75, .15 },
		itemEnchant = { 0, .8, 1 },
		itemReforge = { 1, 0.5, 1 },
	},
	tooltip = {
		backdrop = {
			bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),  
			edgeFile = gUI4:GetMedia("Border", "Tooltip", 256, 32, "Warcraft"):GetPath(), 
			edgeSize = 32,
			insets = {
				top = 5.5,
				left = 5.5,
				bottom = 5.5,
				right = 5.5
			}
		},
		offset = 6
	},
	
	
	raidIconSize = 24,
	raidIconTexture = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetPath(),
	raidIconPoint = "TOP",
	raidIconX = 0, 
	raidIconY = 16, 
	itemRefIconSize = 48, 
	itemRefIconX = -4,
	itemRefIconY = 6,
	itemRefIconInset = 10,
	itemRefIconTexCoord = { 5/65, 59/64, 5/64, 59/64 },
	itemRefBackdrop = {
		bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),  
		edgeFile = gUI4:GetMedia("Border", "Tooltip", 256, 32, "Warcraft"):GetPath(), 
		edgeSize = 32,
		insets = {
			left = 7, 
			right = 7, 
			top = 7,
			bottom = 7
		}
	},
	itemRefBackdropColor = { 0, 0, 0, .85 },
	itemRefBorderColor = { .77, .77, .77, 1 }
})

parent:RegisterTheme("Blizzard", {
	place = { "BOTTOMRIGHT", -20, 20 + 32 + 10 }, 
	backdrop = {
		bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),  
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
		edgeSize = 16,
	},
	backdropOffset = 0, -- extra space needed for the backdrop frame
	backdropInsets = 2.5,
	backdropColor = { 0, 0, 0 },
	backdropAlpha = .85,
	borderColor = { .25, .25, .25 },
	barTexture = gUI4:GetMedia("StatusBar", "Power", 512, 64, "Warcraft"):GetPath(),
	barSize = 6,
	barInsets = 8,
	barColor = { 63/255, 114/255, 25/255 },
	barBackdropMultiplier = 1/4,
	barBackdropAlpha = 1/2,
	raidIconSize = 16,
	raidIconTexture = [[Interface\TARGETINGFRAME\UI-RaidTargetingIcons.blp]],
	raidIconPoint = "TOP",
	raidIconX = 0, 
	raidIconY = 6, 
	itemRefIconSize = 48, 
	itemRefIconX = -4,
	itemRefIconY = 6,
	itemRefIconInset = 10,
	itemRefIconTexCoord = { 5/65, 59/64, 5/64, 59/64 },
	itemRefBackdrop = {
		bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),  
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
		edgeSize = 32,
		insets = {
			left = 2.5,
			right = 2.5,
			top = 2.5,
			bottom = 2.5
		}
	},
	itemRefBackdropColor = { 0, 0, 0, .85 },
	itemRefBorderColor = { .77, .77, .77, 1 }
})

parent:RegisterTheme("Clean", {
	place = { "BOTTOMRIGHT", -20, 20 + 32 + 10 }, 
	backdrop = {
		bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),  
		edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(), 
		edgeSize = 1,
	},
	backdropOffset = 0, -- extra space needed for the backdrop frame
	backdropInsets = -1,
	backdropColor = { 0, 0, 0 },
	backdropAlpha = .85,
	borderColor = { .15, .15, .15 },
	barTexture = gUI4:GetMedia("StatusBar", "Power", 512, 64, "Warcraft"):GetPath(),
	barSize = 6,
	barInsets = 6,
	barColor = { 63/255, 114/255, 25/255 },
	barBackdropMultiplier = 1/4,
	barBackdropAlpha = 1/2,
	raidIconSize = 16,
	raidIconTexture = [[Interface\TARGETINGFRAME\UI-RaidTargetingIcons.blp]],
	raidIconPoint = "TOP",
	raidIconX = 0, 
	raidIconY = 9, 
	itemRefIconSize = 48, 
	itemRefIconX = -4,
	itemRefIconY = 6,
	itemRefIconInset = 10,
	itemRefIconTexCoord = { 5/65, 59/64, 5/64, 59/64 },
	itemRefBackdrop = {
		bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),  
		edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(), 
		edgeSize = 1,
		insets = {
			left = -1,
			right = -1,
			top = -1,
			bottom = -1
		}
	},
	itemRefBackdropColor = { 0, 0, 0, .85 },
	itemRefBorderColor = { .15, .15, .15, 1 }
})

