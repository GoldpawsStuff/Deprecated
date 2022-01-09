local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Minimap", true)
if not parent then return end

parent:RegisterTheme("Warcraft", {
	size = { 160, 160 }, 
	place = function() return "TOPRIGHT", "UIParent", "TOPRIGHT", -(gUI4:GetMinimumRightOffset() + 10), -(gUI4:GetMinimumTopOffset() + 10) end,
	mapSize = { 136, 136 }, 
	mapPlace = { "TOPLEFT", 12, -12 }, 
	alpha = 1,
	allowRotatingMinimap = true,
	compassSize = { 365/140*136, 365/140*136 }, 
	mask = gUI4:GetMedia("Texture", "CircularMask"),
	model = {
		enable = true,
		size = { 320, 320 },
		place = { "CENTER" }, 
		distanceScale = 1.7, 
		position = { 0, 0, .1 },
		rotation = 0, 
		zoom = 0,
		id = 32368,
		alpha = .1
	},
	textures = {
		cogwheel = gUI4:GetMedia("Texture", "CogGrid", 160, 160, "Warcraft"), 
		ring = gUI4:GetMedia("Frame", "CircularRing", 160, 160, "Warcraft"),
		compass = gUI4:GetMedia("Frame", "CircularCompassOverlay", 160, 160, "Warcraft"),
		-- glow = gUI4:GetMedia("Frame", "CircularGlow", 160, 160, "Warcraft"),
		backdrop = gUI4:GetMedia("Frame", "CircularBackdrop", 160, 160, "Warcraft"),
		-- gloss = gUI4:GetMedia("Frame", "CircularGloss", 160, 160, "Warcraft"),
		-- shade = gUI4:GetMedia("Frame", "CircularShade", 160, 160, "Warcraft"),
		border = gUI4:GetMedia("Frame", "CircularNormal", 160, 160, "Warcraft")
	},
	widgets = {
		buttonbag = {
		
		},
		mail = {
			size = { 24, 16 }, 
			place = function() return "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -gUI4:GetMinimumRightOffset(), gUI4:GetMinimumBottomOffset() end, -- position of the mailframe
			icon = {
				place = { "TOPLEFT", -20, 24 }, -- position of the icon texture relative to the custom mailframe
				textures = {
					newmail = gUI4:GetMedia("Texture", "SmartBarGrid", 32, 32, "Warcraft"):GetGridItem(20),
					newmailhighlight = gUI4:GetMedia("Texture", "SmartBarGridHighlight", 32, 32, "Warcraft"):GetGridItem(20),
				}
			},
			message = {
				place = { "TOP", 0, -(10 + 10) }, -- text position relativ to the icon texture
				-- place = { "CENTER", 0, 0 }, -- text position relativ to the icon texture
				fontobject = GameFontNormalSmall,
				fontsize = 9,
				fontstyle = nil,
				shadowcolor = { 0, 0, 0, 1 },
				shadowoffset = { .75, -.75 }
			}
		},
		time = {
			message = {
				place = { "BOTTOM", 0, 20 }, 
				fontobject = TextStatusBarText,
				fontsize = 12,
				fontstyle = nil,
				shadowcolor = { 0, 0, 0, 1 },
				shadowoffset = { 1.25, -1.25 }
			}
		},
    eye = {
      place = { "CENTER", -62, -66 }, -- position relative to the minimap
    },
    garrison = {
      size = { 64, 64 },
      place = { "CENTER", 74, -62 }, -- position relative to the minimap
      fadeInDuration = 1.25,
      fadeOutDuration = 0.75,
      icon = {
				place = { "TOPLEFT", 0, 0 }, -- position of the icon texture relative to the holder
				textures = {
					normal = gUI4:GetMedia("Texture", "GarrisonIconGrid", 64, 64, "Warcraft"):GetGridItem(1),
					highlight = gUI4:GetMedia("Texture", "GarrisonIconGrid", 64, 64, "Warcraft"):GetGridItem(2),
          glow = gUI4:GetMedia("Texture", "GarrisonIconGrid", 64, 64, "Warcraft"):GetGridItem(3),
          redglow = gUI4:GetMedia("Texture", "GarrisonIconGrid", 64, 64, "Warcraft"):GetGridItem(4)
        }
      }
    }
	}
})
