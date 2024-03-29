local ADDON, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(ADDON)

-- The styles listed here are meant to skin
-- Blizzard elements we can't replace, like the gamemenu,
-- ...or Blizzard elements we can't be arsed to replace, like the rest. 
Engine:NewStaticConfig("Blizzard", {
	altpower = {
		position = { "CENTER", "UICenter", "CENTER", 0, -120 }
	},
	character = {
		itemLevel = {
			point = { "TOPLEFT", 4, -4 },
			fontObject = DiabolicFont_SansBold12ThinOutline, -- DiabolicFont_SansBold10,
			shadeTexture = path .. [[textures\DiabolicUI_Tooltip_Header_TitleBackground.tga]]
		}
	},
	containers = {

	},
	durability = {
		position = { "CENTER", "UICenter", "CENTER", 190, 0 }
	},
	gamemenu = {
		capture_mouse = false,
		dim = false,
		dim_color = { 0, 0, 0, .75 },
		button_spacing = 4,
		button_anchor_wod = {
			position = "TOP",
			anchor = "UICenter", 
			rposition = "TOP",
			xoffset = 0, -- 0 when TOP, 88 when anchored TOPLEFT 
			yoffset = -200 -- -260 -293
		},
		button_anchor = {
			position = "TOP",
			anchor = "UICenter", 
			rposition = "TOP",
			xoffset = 0, -- 0 when TOP, 88 when anchored TOPLEFT 
			yoffset = -240 -- -260 -293
		},
		resume_button_anchor = {
			position = "BOTTOM",
			anchor = "UICenter", 
			rposition = "BOTTOM",
			xoffset = 0,
			yoffset = 160 -- Diablo value is 78
		},
		show_logo = false,
		logo = {
			size = { 480, 240 },
			texture_size = { 1024, 512 },
			texture = path .. [[textures\DiabolicUI_Logo.tga]],
			position = {
				point = "TOP", 
				anchor = "UICenter",
				rpoint = "TOP", 
				xoffset = 0, -- 0 when TOP, 16ish when anchored TOPLEFT
				yoffset = 0 -- -20
			},
		},
		show_model = false,
		model = {
			size = { 600, 800 },
			position = {
				point = "CENTER", 
				anchor = "UICenter",
				rpoint = "CENTER", 
				xoffset = 0, 
				yoffset = 0
			}
		},
		window = {
			insets = { 6, 6, 6, 6 }, -- left, right, top, bottom
			backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = path .. [[textures\DiabolicUI_Tooltip_Border.tga]],
				edgeSize = 32,
				tile = false,
				tileSize = 0,
				insets = {
					left = 23,
					right = 23,
					top = 23,
					bottom = 23
				}
			},
			backdrop_color = { 0, 0, 0, .95 },
			backdrop_border_color = { 1, 1, 1, 1 },
		}
	},
	ghostframe = {
		position = { "CENTER", "UIParent", "CENTER", 0, -50 }
	},
	levelup = {
		position = { "TOP", 0, -250 }
	},
	-- also applies to the new TimerTrackers in ... uh... WoD? MoP? :/
	mirrortimers = {
		position = { "TOP", "UIParent", "TOP", 0, -300 }, -- default anchor -180
		positionOffsetByOne = { "TOP", "UIParent", "TOP", 0, -(300 + 50) }, -- notch it 1 bar down (give room for the capture bar)
		padding = 50, -- padding from one bar to the next
		font_object = DiabolicTooltipNormal,
		backdrop_texture = path .. [[textures\DiabolicUI_Target_227x15_Backdrop.tga]],
		texture = path .. [[textures\DiabolicUI_Target_195x13_Border.tga]],
		texture_size = { 512, 64 },
		texture_position = { "TOP", 0, 25 },
		statusbar_texture = path .. [[statusbars\DiabolicUI_StatusBar_512x64_Dark_Warcraft.tga]],
		spark_size = { 128, 128 },
		spark_texture = path .. [[statusbars\DiabolicUI_StatusBar_128x128_Spark_Warcraft.tga]]
	},
	talkinghead = {
		position = { "TOP", "UICenter", "TOP", 0, -330 },
		size = { 570, 155 } -- size taken from Blizzard_TalkingHeadUI.xml
	},
	tracker = {
		togglebutton = {
			size = { 22, 21 },
			--position = { "TOPRIGHT", -5, 0 }, -- blizzard "TOPRIGHT", -12, -5
			position = { "TOPRIGHT", 0, 0 }, -- blizzard "TOPRIGHT", -12, -5
			texture_size = { 32, 32 },
			texture = path .. [[textures\DiabolicUI_ExpandCollapseButton_22x21.tga]],
			texture_disabled = path .. [[textures\DiabolicUI_ExpandCollapseButton_22x21_Disabled.tga]]
		},
		title = {
			--position = Engine:IsBuild("WoD") and 
			--	-- if this is set before the ObjectiveTracker addon is loaded, it fails
			--	{ "TOPRIGHT", ObjectiveTrackerFrame.HeaderMenu.MinimizeButton, "TOPLEFT", -16, 0 }
			--	 or 
			--	{ "TOPRIGHT", "WatchFrameCollapseExpandButton", "TOPLEFT", -16, 0 },
			position = { "TOPRIGHT", "WatchFrameCollapseExpandButton", "TOPLEFT", -16, 0 },
			font_object = DiabolicWatchFrameHeader
		},
		line = {
			font_object = DiabolicWatchFrameNormal
		},
		colors = {
			title = { 1, 1, 1 },
			title_disabled = { .5, .5, .5 },
			quest_title = { 229/255, 178/255, 25/255, .9 },
			quest_title_highlight = { 255/255, 234/255, 137/255, 1 },
			line = { 240/250, 240/255, 240/255, .9 },
			line_highlight = { 1, 1, 1, 1 }
		}
	},
	tooltips = {
		position = { "BOTTOMRIGHT", -(30 + 8), 20 + 55 + 20 + 10 }, -- relative to UICenter
		--position = { "BOTTOMRIGHT", -8, 12 }, -- relative to UICenter
		offsets = { 8, 8, 8, 8 + 4 },
		backdrop = {
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = path .. [[textures\DiabolicUI_Tooltip_Small.tga]],
			edgeSize = 32,
			tile = false,
			tileSize = 0,
			insets = {
				left = 6,
				right = 6,
				top = 6,
				bottom = 6
			}
		},
		backdrop_color = { 0, 0, 0, .95 },
		backdrop_border_color = { 1, 1, 1, 1 },
		dummy_backdrop = {
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
			tile = false,
			edgeSize = 16,
			insets = { 
				left = 5,
				right = 4,
				top = 5,
				bottom = 4
			}
		},
		dummy_backdrop_color = { 0, 0, 0, .95 },
		dummy_backdrop_border_color = { .3, .3, .3, 1 },
		statusbar = {
			size = 3,
			offsets = { -2, -2, 0, -(1 - 4) }, -- make the bar align to the backdrop border edges
			texture = path .. [[statusbars\DiabolicUI_StatusBar_512x64_Dark_Warcraft.tga]]
		}
	},
	totembar = {
		position = { "BOTTOM", "Main", "TOP", 0, 60 }
	},
	vehicleseat = {
		position = { "CENTER", "UIParent", "CENTER", -224, 0 }
	}
})
