local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_NamePlates", true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- Lua API
local floor = math.floor

local borderSize = 5
local width, health, cast, gap = 96, 12, 12, 4
local trivialwidth, trivialheight =  72, 8
local spell = 36 
parent:RegisterTheme("Warcraft", {
	size = { width, health + gap + cast },
	place = { "TOPLEFT", -floor(width/2), -6 }, -- position relative to center of the original plate frame --floor((health + gap + cast)/2)
	bars = {
		health = {
			size = { width, health },
			place = { "TOPLEFT", 0, 0 },
			color = gUI4:GetColors("reaction")[5],
			textures = {
				glow = gUI4:GetMedia("StatusBar", "Glow", 96, 12, "Warcraft"),
				backdrop = gUI4:GetMedia("StatusBar", "Backdrop", 128, 16, "Warcraft"), 
				bar = gUI4:GetMedia("StatusBar", "Normal", 128, 16, "Warcraft"),
				overlay = gUI4:GetMedia("StatusBar", "Overlay", 128, 16, "Warcraft"),
				threat = gUI4:GetMedia("StatusBar", "Threat", 128, 16, "Warcraft")
			}
		},
		cast = {
			size = { width, cast },
			place = { "TOPLEFT", 0, -(health + gap) },
			color = gUI4:GetColors("chat", "normal"),
			textures = {
				glow = gUI4:GetMedia("StatusBar", "Glow", 96, 12, "Warcraft"), -- gUI4:GetMedia("Texture", "Empty"), -- 
				backdrop = gUI4:GetMedia("StatusBar", "Backdrop", 128, 16, "Warcraft"), -- gUI4:GetMedia("Texture", "Blank"), --
				bar = gUI4:GetMedia("StatusBar", "Normal", 128, 16, "Warcraft"),
				overlay = gUI4:GetMedia("StatusBar", "Overlay", 128, 16, "Warcraft")
			}
		},
		absorb = {
				size = { width, health },
				place = { "TOPLEFT", 0, 0 },
				color = gUI4:GetColors("healpredict", "absorb"),
				textures = {
					glow = gUI4:GetMedia("StatusBar", "Glow", 96, 12, "Warcraft"), -- gUI4:GetMedia("Texture", "Empty"), -- 
					backdrop = gUI4:GetMedia("StatusBar", "Backdrop", 128, 16, "Warcraft"), -- gUI4:GetMedia("Texture", "Blank"), --
					bar = gUI4:GetMedia("StatusBar", "Normal", 128, 16, "Warcraft"),
					overlay = gUI4:GetMedia("StatusBar", "Overlay", 128, 16, "Warcraft")
				}
		},
		trivial = {
			size = { trivialwidth, trivialheight },
			place = { "TOPLEFT", floor((width - trivialwidth)/2), 0 },
			color = gUI4:GetColors("chat", "normal"),
			textures = {
				glow = gUI4:GetMedia("StatusBar", "Glow", 72, 8, "Warcraft"),
				backdrop = gUI4:GetMedia("StatusBar", "Backdrop", 64, 8, "Warcraft"),
				bar = gUI4:GetMedia("StatusBar", "Normal", 64, 8, "Warcraft"),
				overlay = gUI4:GetMedia("StatusBar", "Overlay", 64, 8, "Warcraft"),
				threat = gUI4:GetMedia("StatusBar", "Threat", 64, 8, "Warcraft")
			}
		}
	},
	widgets = {
		auras = {
			place = { "TOP", 0, gap + 12 + gap + 28 }, -- above the name
			rowsize = math.ceil((width + 4)/(28 + 2)), -- maximum number of auras per row
			padding = 2, -- space between auras
			button = {
				size = { 28, 28 },
				anchor = "BOTTOMLEFT", 
				icon = {
					size = { 22, 22 }, -- should be main size - 6
					texCoord = { 5/64, 59/64, 5/64, 59/64 },
					place = { "TOPLEFT", 2, -2 } -- relative to the scaffold, which is 1px inset into the button
				},
				time = {
					place = { "TOPLEFT", 1, -1 }, 
					fontObject = GameFontNormalSmall,
					fontStyle = "THINOUTLINE",
					fontSize = 9,
					shadowOffset = { 1.25, -1.25 },
					shadowColor = { 0, 0, 0, 1 }
				},
				count = {
					place = { "BOTTOMRIGHT", -1, 1 }, 
					fontObject = GameFontNormalSmall,
					fontStyle = "THINOUTLINE",
					fontSize = 9,
					shadowOffset = { 1.25, -1.25 },
					shadowColor = { 0, 0, 0, 1 }
				}
			}
		},
		name = {
			size = 12,
			fontobject = GameFontNormal,
			fontstyle = nil,
			shadowoffset = { .75, -.75 },
			shadowcolor = { 0, 0, 0, 1 },
			place = { "TOP", 0, 12 + gap },
			color = gUI4:GetColors("chat", "offwhite")
		},
		level = {
			size = 12, 
			fontobject = TextStatusBarText,
			fontstyle = nil,
			shadowoffset = { .75, -.75 },
			shadowcolor = { 0, 0, 0, 1 },
			place = { "TOPLEFT", trivialwidth + gap, floor((12 - trivialheight)/2) },
			color = gUI4:GetColors("chat", "offwhite")
		},
		skullicon = {
			size = { 16, 16 },
			place = { "TOPLEFT", width + gap, 0 },
			texture = ""
		},
		health = {
			size = health, 
			fontobject = TextStatusBarText,
			fontstyle = nil,
			shadowoffset = { .75, -.75 },
			shadowcolor = { 0, 0, 0, 1 },
			place = { "TOP", 4, -4 },
			color = gUI4:GetColors("chat", "offwhite")
		},
		spellname = {
			size = 12, 
			fontobject = GameFontNormal,
			fontstyle = nil,
			shadowoffset = { .75, -.75 },
			shadowcolor = { 0, 0, 0, 1 },
			place = { "TOP", 0, -(cast + gap) },
			color = gUI4:GetColors("chat", "offwhite")
		},
		spellicon = {
			size = { 36, 36 },
			place = { "BOTTOMLEFT", -(36 + gap), floor(((health + gap + cast) - 36)/2) },
			icon = {
				size = { 32, 32 },
				place = { "TOPLEFT", 2, -2 },
				texcoord = { 5/64, 59/64, 5/64, 59/64 }
			},
			textures = {
				border = gUI4:GetMedia("Button", "CastBorderNormal", 36, 36, "Warcraft"),
				shield = gUI4:GetMedia("Button", "CastBorderShield", 36, 36, "Warcraft")
			}
		},
		pvpicon = {
		},
		raidicon = {
			size = { 32, 32 },
			place = { "TOP", 0, 32 + gap + health },
			texture = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetPath()
		}
	}
})



