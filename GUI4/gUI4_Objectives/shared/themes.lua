local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

parent:RegisterTheme("Warcraft", {
	errorframe = {
		size = { 512, 36 }, -- 36 is the default, 18 keeps it at a single line
		place = function() return "TOP", 0, -gUI4:GetTopOffset("CENTER") end,
		positionCallbacks = { 
			GUI4_TOP_OFFSET_CHANGED = "CENTER" 
		},
		positionMessagesToFire = {
		},
		fontobject = GameFontNormal,
		shadowcolor = { 0, 0, 0, 1 },
		shadowoffset = { .75, -.75 }, 
		timevisible = 5, 
		fadeduration = 3
	},
	floaters = {
		durability = {
			place = function() return "CENTER", 160 + 60/2, 0 end,
		},
		graveyard = {
			size = { 280, 170 },
			place = function() return "CENTER", 0, -50 end,
			icon = {
				backdrop = false,
				size = { 280, 170 }
			},
			text = {
				place = { "CENTER" },
				msg = RETURN_TO_GRAVEYARD,
				color = gUI4:GetColors("chat", "offwhite"),
				fontobject = GameFontNormalSmall,
				fontsize = 10, 
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 }
			},
			content = {
				backdrop = {
				},
			},
			textures = {
				spirithealer = gUI4:GetMedia("Texture", "SpiritHealer", 280, 170, "Warcraft"),
				spirithealerglowing = gUI4:GetMedia("Texture", "SpiritHealerGlowing", 280, 170, "Warcraft")
			}
		},
		vehicleseat = {
			place = function() return "CENTER", -(160 + 128/2), 0 end,
		},
		talkinghead = {
			place = function() return "TOP", 0, -60 end,
		}
	},
	tracker = {
		place = function() return "RIGHT", -gUI4:GetRightOffset("MIDDLE"), -60 end, -- add some extra air
		positionCallbacks = { 
			GUI4_RIGHT_OFFSET_CHANGED = "MIDDLE" 
		},
		positionMessagesToFire = {
		},
		textures = {
			expandcollapse = gUI4:GetMedia("Texture", "TrackerButtonGrid", 32, 32, "Warcraft"), -- grid expected
			disabled = gUI4:GetMedia("Texture", "TrackerButtonDisabled", 32, 32, "Warcraft"), -- single texture
			highlight = false
		}
	},
	zonetext = {
		size = { 512, 128 }, 
		place = function() return "CENTER", 0, 164 end, 
		alpha = 1,
		zonetext = {
			fontobject = ZoneTextFont,
			fontsize = 32,
			fontstyle = nil, 
			color = { 1, 1, 1 },
			shadowcolor = { 0, 0, 0, .75 },
			shadowoffset = { 1.25, -1.25 }
		},
		zonepvptext = {
			fontobject = PVPInfoTextFont,
			fontsize = 16,
			fontstyle = nil, 
			color = { 1, 1, 1 },
			shadowcolor = { 0, 0, 0, .75 },
			shadowoffset = { 1.25, -1.25 }
		},
		subzonetext = {
			fontobject = SubZoneTextFont,
			fontsize = 24,
			fontstyle = nil, 
			color = { 1, 1, 1 },
			shadowcolor = { 0, 0, 0, .75 },
			shadowoffset = { 1.25, -1.25 }
		},
		subzonepvptext = {
			fontobject = PVPInfoTextFont,
			fontsize = 16,
			fontstyle = nil, 
			color = { 1, 1, 1 },
			shadowcolor = { 0, 0, 0, .75 },
			shadowoffset = { 1.25, -1.25 }
		},
		autofollowtext = {
			fontobject = GameFontNormal,
			fontsize = 20,
			fontstyle = nil, 
			color = { 1, 1, 1 },
			shadowcolor = { 0, 0, 0, .75 },
			shadowoffset = { 1.25, -1.25 }
		},
		positionCallbacks = { 
		},
		positionMessagesToFire = {
		},
	},
	capturebar = {
		size = { 252, 26 }, -- same size as class resource bars
		-- size = { 160, 16 }, -- 136
		-- place = function() return "TOPRIGHT", "UIParent", "TOPRIGHT", -(gUI4:GetMinimumRightOffset() + 10), -(gUI4:GetMinimumTopOffset() + 10 + (160 + 16 + 12*2 + 16)) end, -- next to minimap
		-- place = function() return "BOTTOM", "UIParent", "BOTTOM", 0, gUI4:GetBottomOffset() + 66 + 36 + 10 end, -- above the class resource bar
		place = function() return "CENTER", "UIParent", "CENTER", 0, 230 + 36 + 10 end, -- above the focus cast bar -- 240 + 30 + 26
		textures = {
			backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
			overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft")
		},
		bar = {
			size = { 240, 14 },
			place = { "TOPLEFT", 6, -6 },
			color = gUI4:GetColors("chat", "offgreen"),
			backdropColor = { 0, 0, 0 },
			backdropAlpha = .5,
			backdropMultiplier = nil,
			overlayColor = { 1, 1, 1 },
			overlayAlpha = 1, 
			textures = {
				backdrop = gUI4:GetMedia("Texture", "Blank"),
				normal = gUI4:GetMedia("StatusBar", "Resource", 512, 64, "Warcraft"),
				overlay = gUI4:GetMedia("StatusBar", "ResourceOverlay", 512, 64, "Warcraft"),
				-- border = gUI4:GetMedia("Frame", "Normal", 512, 64, "Warcraft"),
				glow = gUI4:GetMedia("StatusBar", "Glow", 512, 64, "Warcraft"),
				spark = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft")
			}
		},
		spark = {
			alpha = .5,
			texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
		}
	},
	worldstate = {
		size = { 200, 32 },
		place = function() return "TOP", 0, -gUI4:GetTopPreOffset("CENTER") end, -- -16
		positionCallbacks = { -- will update position when this fires
			GUI4_TOP_PREOFFSET_CHANGED = "CENTER" 
		},
		positionMessagesToFire = { -- will fire the index message when changing position, with the value as arg1/justify
			GUI4_TOP_OFFSET_CHANGED = "CENTER"
		},
		hitrects = { 4, 4, 4, 4 }, -- custom hitrects for icons
		height = 24, -- custom frameheight for each worldstate item. 
		textures = {
			horde = gUI4:GetMedia("Texture", "WorldStateGrid", 32, 32, "Warcraft"):GetGridItem(2), -- gUI4:GetMedia("Texture", "FactionHorde", 32, 32, "Warcraft"),
			hordeflag = gUI4:GetMedia("Texture", "WorldStateGrid", 32, 32, "Warcraft"):GetGridItem(4), 
			hordetower = gUI4:GetMedia("Texture", "WorldStateGrid", 32, 32, "Warcraft"):GetGridItem(6),
			alliance = gUI4:GetMedia("Texture", "WorldStateGrid", 32, 32, "Warcraft"):GetGridItem(1), -- gUI4:GetMedia("Texture", "FactionAlliance", 32, 32, "Warcraft")
			allianceflag = gUI4:GetMedia("Texture", "WorldStateGrid", 32, 32, "Warcraft"):GetGridItem(3),
			alliancetower = gUI4:GetMedia("Texture", "WorldStateGrid", 32, 32, "Warcraft"):GetGridItem(5),
			neutraltower = gUI4:GetMedia("Texture", "WorldStateGrid", 32, 32, "Warcraft"):GetGridItem(7)
		}
	}
})
