local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_CastBars", true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- *copied from the unitframe module
-- vertical offsets from the bottom of the screen
local baseOffset = 80 
local idealTotalOffset = 297 
-- local idealTotalOffset = 321 -- high enough for all 3 bars + xp + rep to be visible without changing the position 
local function getBasePosition()
	return baseOffset + gUI4:GetBottomOffset()
	-- return math.max(idealTotalOffset, baseOffset + gUI4:GetBottomOffset())
end

local barOffset = 230 -- 240 -- 160
parent:RegisterTheme("Warcraft", {
	castbars = {
		positionCallbacks = {},
		bars = {
			player = {
				size = { 252, 36 },
				-- place = function() return "BOTTOM", "UIParent", "BOTTOM", 0, getBasePosition() + floor((74 - 20)/2) end, -- between the player/target frames
				place = function() return "BOTTOM", "UIParent", "BOTTOM", 0, gUI4:GetBottomOffset() + 30 end,
				-- place = function() return "BOTTOM", "UIParent", "BOTTOM", 0, getBasePosition() - (iconSize + borderSize*2) end, -- below the player/target frames
				textures = {
					backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 36, "Warcraft"),
					overlay = gUI4:GetMedia("Frame", "Normal", 252, 36, "Warcraft")
				},
				bar = {
					size = { 240, 24 },
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
				},
				widgets = { -- all widgets are positioned relative to the bar
					name = {
						size = 10, 
						maxwidth = 200, 
						justify = "LEFT",
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "LEFT", 10, 0 },
						color = gUI4:GetColors("chat", "offwhite")
					},
					title = nil,
					time = {
						size = 10, 
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "RIGHT", -10, 0 },
						color = gUI4:GetColors("chat", "offwhite")
					},
					delay = {
						size = 8, 
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "BOTTOMRIGHT", 0, -4 },
						color = gUI4:GetColors("chat", "gray")
					},
					shield = {
						size = { 36, 36 },
						place = { "BOTTOMLEFT", -4, -6 }, 
						textures = {
							shield = gUI4:GetMedia("Button", "CastBorderShield", 36, 36, "Warcraft")
						}
					},
					-- icon = {
						-- size = { iconSize, iconSize },
						-- place = { "TOPLEFT", -(borderSize*2 + iconSize + gap ), 0 },
						-- texcoord = { 5/64, 59/64, 5/64, 59/64 }
					-- }
				}
			},
			target = {
				size = { 252, 36 },
				place = function() return "CENTER", "UIParent", "CENTER", 0, barOffset-36 end,
				textures = {
					backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 36, "Warcraft"),
					overlay = gUI4:GetMedia("Frame", "Normal", 252, 36, "Warcraft")
				},
				bar = {
					size = { 240, 24 },
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
				},
				widgets = { -- all widgets are positioned relative to the bar
					name = {
						size = 10, 
						maxwidth = 200, 
						justify = "LEFT",
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "LEFT", 10, 2 },
						color = gUI4:GetColors("chat", "offwhite")
					},
					title = {
						size = 8, 
						maxwidth = 200, 
						justify = "LEFT",
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "LEFT", 10, -8 },
						color = gUI4:GetColors("chat", "normal")
					},
					time = {
						size = 10, 
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "RIGHT", -10, 0 },
						color = gUI4:GetColors("chat", "offwhite")
					},
					delay = {
						size = 8, 
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "BOTTOM", 0, -4 },
						color = gUI4:GetColors("chat", "gray")
					},
					shield = {
						size = { 36, 36 },
						place = { "BOTTOMLEFT", -4, -6 }, 
						textures = {
							shield = gUI4:GetMedia("Button", "CastBorderShield", 36, 36, "Warcraft")
						}
					},
					-- icon = {
						-- size = { iconSize, iconSize },
						-- place = { "TOPLEFT", -(borderSize*2 + iconSize + gap ), 0 },
						-- texcoord = { 5/64, 59/64, 5/64, 59/64 }
					-- }
				}
			},
			focus = {
				size = { 252, 36 },
				place = function() return "CENTER", "UIParent", "CENTER", 0, barOffset end,
				textures = {
					backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 36, "Warcraft"),
					overlay = gUI4:GetMedia("Frame", "Normal", 252, 36, "Warcraft")
				},
				bar = {
					size = { 240, 24 },
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
				},
				widgets = { -- all widgets are positioned relative to the bar
					name = {
						size = 10, 
						maxwidth = 200, 
						justify = "LEFT",
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "LEFT", 10, 2 },
						color = gUI4:GetColors("chat", "offwhite")
					},
					title = {
						size = 8, 
						maxwidth = 200, 
						justify = "LEFT",
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "LEFT", 10, -8 },
						color = gUI4:GetColors("chat", "normal")
					},
					time = {
						size = 10, 
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "RIGHT", -10, 0 },
						color = gUI4:GetColors("chat", "offwhite")
					},
					delay = {
						size = 8, 
						fontobject = GameFontNormal,
						fontstyle = nil,
						shadowoffset = { 1.25, -1.25 },
						shadowcolor = { 0, 0, 0, 1 },
						place = { "BOTTOM", 0, -4 },
						color = gUI4:GetColors("chat", "gray")
					},
					shield = {
						size = { 36, 36 },
						place = { "BOTTOMLEFT", -4, -6 }, 
						textures = {
							shield = gUI4:GetMedia("Button", "CastBorderShield", 36, 36, "Warcraft")
						}
					},
					-- icon = {
						-- size = { iconSize, iconSize },
						-- place = { "TOPLEFT", -(borderSize*2 + iconSize + gap ), 0 },
						-- texcoord = { 5/64, 59/64, 5/64, 59/64 }
					-- }
				}
			}
		}
	},
	timers = {
		size = { 252, 36 },
		place = function() return "CENTER", "UIParent", "CENTER", 0, barOffset-36*2 end, -- -20
		padding = 0,
		positionCallbacks = {},
		textures = {
			backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 36, "Warcraft"),
			overlay = gUI4:GetMedia("Frame", "Normal", 252, 36, "Warcraft")
		},
		bar = {
			size = { 240, 24 },
			place = { "TOPLEFT", 6, -6 },
			color = gUI4:GetColors("chat", "dimred"),
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
			alpha = .25,
			texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
		},
		widgets = { -- all widgets are positioned relative to the bar
			name = {
				size = 10, 
				maxwidth = 200, 
				justify = "LEFT",
				fontobject = GameFontNormal,
				fontstyle = nil,
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, 1 },
				place = { "LEFT", 10, 0 },
				color = gUI4:GetColors("chat", "offwhite")
			},
			time = {
				size = 10, 
				fontobject = GameFontNormal,
				fontstyle = nil,
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, 1 },
				place = { "RIGHT", -10, 0 },
				color = gUI4:GetColors("chat", "offwhite")
			},
			delay = {
				size = 8, 
				fontobject = GameFontNormal,
				fontstyle = nil,
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, 1 },
				place = { "BOTTOM", 0, -4 },
				color = gUI4:GetColors("chat", "gray")
			},
			-- icon = {
				-- size = { iconSize, iconSize },
				-- place = { "TOPLEFT", -(borderSize*2 + iconSize + gap ), 0 },
				-- texcoord = { 5/64, 59/64, 5/64, 59/64 }
			-- }
		}
	}
})



