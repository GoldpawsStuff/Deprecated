local addon,ns = ...

local gUI4 = _G.GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local parent = gUI4:GetModule("gUI4_UnitFrames", true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local T = {}
local playerClass = select(2, UnitClass("player"))

-- just to illustrate the reason for the sizes and positions below better
-- 		*do NOT change these values, they are not meant to be editable, 
-- 		 they are all linked to specific media files identified by these sizes!
local borderSize = 6 
local padding = 4
local barWidth = 300
local hugeBar = 52
local bigBar = 44 -- 44
local mediumBar = 36 
local powerBar = 26
local smallBar = 19
local mediumSmallBar = 23
local smallFrame = 40

-- player sizes
local health = hugeBar -- hugeBar
local power = mediumSmallBar -- smallBar
local portrait = 0 -- smallBar + (hugeBar - bigBar)
local auraSize, auraPadding = 28, 2
local debuffCols, debuffRows = 9, 40

-- frame offsets 
local healthOffset = 0
local powerOffset = health - 1
local portraitOffset = 0

-- vertical offsets from the bottom of the screen
local baseOffset = 80 -- 51
local idealTotalOffset = 297 
-- local idealTotalOffset = 321 -- actionbars can change without moving the unitframes now
local function getBasePosition()
	return baseOffset + gUI4:GetBottomOffset()
	-- return math.max(idealTotalOffset, baseOffset + gUI4:GetBottomOffset())
end

T.Player = {
	size = { 300, 74 },
	place = function() return "BOTTOMRIGHT", "UIParent", "BOTTOM", -210, getBasePosition() end,
	aurasaturation = .85,
	textures = {
		glow = false,
		backdrop = gUI4:GetMedia("Frame", "Backdrop", 300, 74, "Warcraft"),
		border = gUI4:GetMedia("Frame", "Normal", 300, 74, "Warcraft"),
		shade = false,
		gloss = false,
		highlight = gUI4:GetMedia("Frame", "Highlight", 300, 74, "Warcraft"),
		overlay = false,
		threat = gUI4:GetMedia("Frame", "Threat", 300, 74, "Warcraft"),
	},
	bars = {
		health = {
			size = { barWidth - borderSize*2, health - borderSize*2 },
			place = { "TOPLEFT", borderSize, -(healthOffset + borderSize) },
			bar = { 
				backdropmultiplier = 1,
				textures = {
					backdrop = gUI4:GetMedia("StatusBar", "Backdrop", 512, 64, "Warcraft"),
					normal = gUI4:GetMedia("StatusBar", "Normal", 512, 64, "Warcraft"),
					overlay = gUI4:GetMedia("StatusBar", "Overlay", 512, 64, "Warcraft"),
					glow = gUI4:GetMedia("StatusBar", "Glow", 512, 64, "Warcraft")
				}
			},
			spark = {
				alpha = .5,
				texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
			},
			texframe = {
				size = { barWidth, health },
				place = { "TOPLEFT", -borderSize, borderSize }
			},
			textures = {
				-- glow = gUI4:GetMedia("Frame", "Glow", barWidth, health, "Warcraft"),
				-- backdrop = false, -- gUI4:GetMedia("Frame", "Backdrop", barWidth, health, "Warcraft"),
				-- border = gUI4:GetMedia("Frame", "Normal", barWidth, health, "Warcraft"),
				-- shade = gUI4:GetMedia("Frame", "Shade", barWidth, health, "Warcraft"),
				-- highlight = gUI4:GetMedia("Frame", "Highlight", barWidth, health, "Warcraft"),
				-- overlay = gUI4:GetMedia("Frame", "Overlay", barWidth, health, "Warcraft"),
				-- threat = gUI4:GetMedia("Frame", "Threat", barWidth, health, "Warcraft")
				threat = gUI4:GetMedia("Frame", "Threat", 300, 74, "Warcraft"),
			}
		},
		power = {
			size = { barWidth - borderSize*2, power - borderSize*2 },
			place = { "TOPLEFT", borderSize, -(powerOffset + borderSize) },
			bar = {
				backdropmultiplier = .3,
				textures = {
					backdrop = gUI4:GetMedia("StatusBar", "Backdrop", 512, 64, "Warcraft"), -- Dark
					normal = gUI4:GetMedia("StatusBar", "Normal", 512, 64, "Warcraft"), 
					overlay = gUI4:GetMedia("StatusBar", "Overlay", 512, 64, "Warcraft"),
					glow = gUI4:GetMedia("StatusBar", "Glow", 512, 64, "Warcraft")
				}
			},
			spark = {
				alpha = .5,
				texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
			},
			texframe = {
				size = { barWidth, power },
				place = { "TOPLEFT", -borderSize, borderSize }
			},
			textures = {
				-- glow = gUI4:GetMedia("Frame", "Glow", barWidth, power, "Warcraft"),
				-- backdrop = false, -- gUI4:GetMedia("Frame", "Backdrop", barWidth, power, "Warcraft"),
				-- border = gUI4:GetMedia("Frame", "Normal", barWidth, power, "Warcraft"),
				-- shade = gUI4:GetMedia("Frame", "Shade", barWidth, power, "Warcraft"),
				-- highlight = gUI4:GetMedia("Frame", "Highlight", barWidth, power, "Warcraft"),
				-- overlay = gUI4:GetMedia("Frame", "Overlay", barWidth, power, "Warcraft"),
				-- threat = gUI4:GetMedia("Frame", "Threat", barWidth, power, "Warcraft")
			}
		}, 
		castbar = {
			alpha = .1,
			size = { barWidth - borderSize*2, health - borderSize*2 },
			place = { "TOPLEFT", borderSize, -(healthOffset + borderSize) },
			bar = { 
				backdropmultiplier = false,
				textures = {
					backdrop = false, 
					normal = gUI4:GetMedia("Texture", "Blank"),
					overlay = false, 
					glow = false
				}
			},
			spark = {
				alpha = 1,
				texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
			},
			texframe = {
				size = { barWidth, health },
				place = { "TOPLEFT", -borderSize, borderSize }
			},
			textures = {
				glow = false, 
				backdrop = false, 
				border = false, 
				shade = false, 
				highlight = false, 
				overlay = false, 
				threat = false, 
			}
		}
	},
	widgets = {
		combat = {
			size = { 64, 64 },
			place = { "TOPLEFT", (barWidth-64)/2, - (health + portrait - 64)/2 - borderSize/2 }, 
			texture = gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetPath(),
			glowtexture = gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetPath(),
			texcoord = { gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetGridTexCoord(2) },
			glowtexcoord = { gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetGridTexCoord(4) }
		},
		resting = {
			size = { 32, 32 },
			attachToChild = "NameText", attachPoint = "RIGHT",
			place = { "LEFT", 1, -3 }, 
			texture = gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetPath(),
			glowtexture = gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetPath(),
			texcoord = { gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetGridTexCoord(1) },
			glowtexcoord = { gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetGridTexCoord(2) }
		},
		-- gUI4:GetMedia("Texture", "Rested", 64, 64, "Warcraft"), 
		-- since blizzard keeps insisting on putting the butt fugly default icon over our heads, we don't need more visible
		-- raidicon = {
			-- size = { 64, 64 },
			-- place = { "TOPRIGHT", 64, -(health-64)/2 },
			-- texture = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetPath()
		-- },
		combopoints = false,
		rare = false,
		elite = false,
		boss = false,
		auras = false,
		debuffs = {
			auraSize = 28, 
			padding = 2,
			columns = 8,
			rows = 3,
			place = { "TOPRIGHT", -(barWidth + 10), -borderSize },
			initialAnchor = "TOPRIGHT",
			growthy = "DOWN",
			growthx = "LEFT",
			onlyShowPlayer = false
		},
		buffs = {
			auraSize = 28, 
			padding = 2,
			columns = floor(barWidth - 10*2)/(28 + 2), -- should fit underneath the frames nicely. in theory.
			rows = 2,
			place = { "TOPRIGHT", -10, -(health + power + portrait +10) },
			initialAnchor = "TOPRIGHT",
			growthy = "DOWN",
			growthx = "LEFT",
			onlyShowPlayer = true,
			onlyShort = true
		},
    -- master looter
    looticon = {
      size = { 16, 16 },
      place = { "TOPRIGHT", -floor(borderSize/2), borderSize + 2 },
      texture = [[Interface\GroupFrame\UI-Group-MasterLooter]]
    },
    -- group leader
    leadericon = {
      size = { 16, 16 },
      place = { "TOPLEFT", floor(borderSize/2), borderSize + 2 },
      texture = [[Interface\GroupFrame\UI-Group-LeaderIcon]]
    },
    -- group assistant
    assisticon = {
      size = { 16, 16 },
      place = { "TOPLEFT", floor(borderSize/2), borderSize + 2 },
      texture = [[Interface\GroupFrame\UI-Group-AssistantIcon]]
    },
		-- portrait = {
			-- size = { barWidth, portrait },
			-- place = { "TOPLEFT", 0, -(portraitOffset) },
			-- alpha = 1,
			-- textures = {
				-- glow = gUI4:GetMedia("Frame", "Glow", barWidth, portrait, "Warcraft"),
				-- backdrop = gUI4:GetMedia("Frame", "Backdrop", barWidth, portrait, "Warcraft"),
				-- border = gUI4:GetMedia("Frame", "Normal", barWidth, portrait, "Warcraft"),
				-- shade = gUI4:GetMedia("Frame", "Shade", barWidth, portrait, "Warcraft"),
				-- highlight = gUI4:GetMedia("Frame", "Highlight", barWidth, portrait, "Warcraft"),
				-- overlay = gUI4:GetMedia("Frame", "Overlay", barWidth, portrait, "Warcraft"),
				-- threat = gUI4:GetMedia("Frame", "Threat", barWidth, portrait, "Warcraft")
			-- }
		-- },
		-- pvptimer = {
			-- size = { 22, 22 },
			-- place = { "TOPLEFT", (borderSize + 10), -floor((portrait + (health - 22)/2))},
			-- icon = {
				-- size = 22,
				-- place = { "TOPLEFT", 0, 0 },
				-- fontobject = TextStatusBarText,
				-- fontstyle = nil, 
				-- shadowoffset = { 1.25, -1.25 },
				-- shadowcolor = { 0, 0, 0, .75 },
				-- color = { .79, .79, .79 }
			-- },
			-- time = {
				-- size = 12,
				-- rpoint = "Icon",
				-- place = { "TOPLEFT", 22 + 4, -floor((22 - 12)/2) },
				-- fontobject = TextStatusBarText,
				-- fontstyle = nil, 
				-- shadowoffset = { 1.25, -1.25 },
				-- shadowcolor = { 0, 0, 0, .75 },
				-- color = { .79, .79, .79 }
			-- }
		-- },		
		raidgroup = {
		},
		spirithealer = false,
		trinkets = false
	},
	fontstrings = {
		combatfeedbacktext = {
			size = 18,
			place = { "BOTTOMLEFT", (barWidth + 10), (portrait + health + power) + 10 }, -- "TOP", 0, -((bigBar - 18)/2)
			fontobject = NumberFontNormalHuge,
			fontstyle = "THINOUTLINE", 
			shadowoffset = { 1.5, -1.5 },
			shadowcolor = { 0, 0, 0, .35 },
			color = { .79, .79, .79 }
		},
		nametext = {
			size = 22,
			place = { "TOPLEFT", (borderSize + 10), -floor((portrait + (health - 22)/2))},
			fontsize = 12,
			fontobject = GameFontNormalSmall,
			fontstyle = nil, 
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, .75 },
			color = { .79, .79, .79 },
			tag = "[gUI4: SmartName:Long]" -- [gUI4: PvP:Player]
		},
		healthtext = {
			size = 32,
			place = { "TOPRIGHT", -(borderSize + 10), -floor(healthOffset + (health - 32)/2) },
			fontobject = TextStatusBarText,
			fontstyle = nil, 
			fontsize = 12,
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, .75 },
			color = { .79, .79, .79 },
			tag = "[gUI4: Health]"
		},
		druidmanatext = {
			size = 12,
			place = { "TOPLEFT", borderSize + 10, -floor((health + (power - 12)/2)) }, -- { "TOPLEFT", (borderSize + 10), -floor(healthOffset + (health - 32)/2) },
			fontobject = TextStatusBarText,
			fontstyle = nil, 
			fontsize = 10,
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, .75 },
			color = { .79, .79, .79 },
			tag = "[gUI4: DruidMana]"
		},
		-- powertext = {
			-- size = 12,
			-- place = { "TOPLEFT", (barWidth-12)/2, -floor((health + (power - 12)/2)) },
			-- fontobject = TextStatusBarText,
			-- fontstyle = nil, 
			-- shadowoffset = { 1.25, -1.25 },
			-- shadowcolor = { 0, 0, 0, .75 },
			-- color = { .79, .79, .79 },
			-- tag = "[gUI4: Power]"
		-- },
		leadertext = {
			size = 16,
			place = { "TOPLEFT", borderSize + 4, floor(borderSize + 16/3) },
			fontobject = GameFontNormal, 
			fontstyle = nil,
			shadowoffset = { 1.5, -1.5 },
			shadowcolor = { 0, 0, 0, .35 },
			color = { .79, .79, .79 },
			tag = "" -- [gUI4: Leader][gUI4: MainTank][gUI4: MainAssist]
		},
		loottext = {
			size = 16,
			place = { "TOPRIGHT", -(borderSize + 4), floor(borderSize + 16/3) },
			fontobject = GameFontNormal, 
			fontstyle = nil,
			shadowoffset = { 1.5, -1.5 },
			shadowcolor = { 0, 0, 0, .35 },
			color = { .79, .79, .79 },
			tag = "" -- [gUI4: MasterLooter]
		}

	}
}

T.Target = setmetatable({
	size = T.Player.size,
	place = function() return "BOTTOMLEFT", "UIParent", "BOTTOM", 210, getBasePosition() end,
	bars = setmetatable({
		health = setmetatable({
			size = T.Player.bars.health.size, 
			growth = "LEFT",
			spark = setmetatable({
				texture = gUI4:GetMedia("StatusBar", "SparkReverse", 128, 128, "Warcraft")
			}, { __index = T.Player.bars.health.spark })
		}, { __index = T.Player.bars.health }),
		power = setmetatable({
			size = T.Player.bars.power.size, 
			growth = "LEFT",
			spark = setmetatable({
				texture = gUI4:GetMedia("StatusBar", "SparkReverse", 128, 128, "Warcraft")
			}, { __index = T.Player.bars.power.spark })
		}, { __index = T.Player.bars.power }),
		castbar = setmetatable({
			size = T.Player.bars.castbar.size, 
			growth = "LEFT",
			spark = setmetatable({
				texture = gUI4:GetMedia("StatusBar", "SparkReverse", 128, 128, "Warcraft")
			}, { __index = T.Player.bars.castbar.spark })
		}, { __index = T.Player.bars.castbar })
	}, { __index = T.Player.bars }),
	fontstrings = setmetatable({
		combatfeedbacktext = setmetatable({
			place = { "BOTTOMRIGHT", -(barWidth + 10), (portrait + health + power) + 10 }, 
			shadowoffset = T.Player.fontstrings.combatfeedbacktext.shadowoffset,
			shadowcolor = T.Player.fontstrings.combatfeedbacktext.shadowcolor,
			color = T.Player.fontstrings.combatfeedbacktext.color,
		}, { __index = T.Player.fontstrings.combatfeedbacktext }),
		healthtext = setmetatable({
			place = { "TOPLEFT", (borderSize + 10), -floor(healthOffset + (health - 32)/2)},
			shadowoffset = T.Player.fontstrings.healthtext.shadowoffset,
			shadowcolor = T.Player.fontstrings.healthtext.shadowcolor,
			color = T.Player.fontstrings.healthtext.color,
			tag = "[gUI4: Health:Reverse]"
		}, { __index = T.Player.fontstrings.healthtext }),
		leadertext = setmetatable({
			place = { "TOPRIGHT", -(borderSize + 4), floor(borderSize + 16/3) },
			shadowoffset = T.Player.fontstrings.leadertext.shadowoffset,
			shadowcolor = T.Player.fontstrings.leadertext.shadowcolor,
			color = T.Player.fontstrings.leadertext.color,
			tag = "" -- [gUI4: MainAssist][gUI4: MainTank][gUI4: Leader]
		}, { __index = T.Player.fontstrings.leadertext }),
		loottext = setmetatable({
			place = { "TOPLEFT", borderSize + 4, floor(borderSize + 16/3) },
			shadowoffset = T.Player.fontstrings.loottext.shadowoffset,
			shadowcolor = T.Player.fontstrings.loottext.shadowcolor,
			color = T.Player.fontstrings.loottext.color,
			tag = "" -- [gUI4: MasterLooter]
		}, { __index = T.Player.fontstrings.loottext }),
		nametext = setmetatable({
			size = 22,
			place = { "TOPRIGHT", -(borderSize + 10), -floor((portrait + (health - 22)/2))},
			fontsize = 12,
			fontobject = GameFontNormalSmall,
			fontstyle = nil, 
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, .75 },
			color = { .79, .79, .79 },
			tag = "[gUI4: SmartName:Long:Reverse]" -- [gUI4: PvP:Player]
		}, { __index = T.Player.fontstrings.nametext }),
	}, { __index = T.Player.fontstrings }),
	widgets = setmetatable({
		raidicon = setmetatable({
			size = { 32, 32 },
			place = { "TOPLEFT", floor((barWidth-32)/2), -floor((borderSize-32)/2) }, 
			texture = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetPath()
		}, { __index = T.Player.widgets.raidicon }),
    -- master looter
    looticon = setmetatable({
      size = { 16, 16 },
      place = { "TOPLEFT", floor(borderSize/2), borderSize + 2 },
      texture = [[Interface\GroupFrame\UI-Group-MasterLooter]]
    }, { __index = T.Player.widgets.raidicon }),
    -- group leader
    leadericon =setmetatable({
      size = { 16, 16 },
      place = { "TOPRIGHT", -floor(borderSize/2), borderSize + 2 },
      texture = [[Interface\GroupFrame\UI-Group-LeaderIcon]]
    }, { __index = T.Player.widgets.raidicon }),
    -- group assistant
    assisticon = setmetatable({
      size = { 16, 16 },
      place = { "TOPRIGHT", -floor(borderSize/2), borderSize + 2 },
      texture = [[Interface\GroupFrame\UI-Group-AssistantIcon]]
    }, { __index = T.Player.widgets.raidicon }),
		buffs = setmetatable({
			place = { "TOPLEFT", (barWidth + 10), -borderSize },
			initialAnchor = "TOPLEFT",
			growthy = "DOWN",
			growthx = "RIGHT",
			onlyShowPlayer = false,
			onlyShort = true
		}, { __index = T.Player.widgets.debuffs }), -- buffs & debuffs on opposite places... 
		debuffs = setmetatable({
			place = { "TOPLEFT", 10, -(health + power + portrait +10) },
			initialAnchor = "TOPLEFT",
			growthy = "DOWN",
			growthx = "RIGHT",
			onlyShowPlayer = false,
			onlyShort = false
		}, { __index = T.Player.widgets.buffs }),
	}, { __index = T.Player.widgets }),
}, { __index = T.Player })

T.Pet = {
	size = { floor((T.Player.size[1] - padding)/2), smallFrame },
	place = function() 
		local load = parent.db.profile.modules[parent:GetModule("Player"):GetName()]
		local anchor = gUI4_UnitPlayer
		if load and anchor then
			return "BOTTOMLEFT", anchor, "TOPLEFT", 0, padding
		else
			return "BOTTOMRIGHT", "UIParent", "BOTTOM", -floor((210 + T.Player.size[1]/2 + padding/2)), getBasePosition() + T.Player.size[2] + padding 
		end
	end,
	aurasaturation = .75,
	bars = {
		health = {
			size = { floor((T.Target.size[1] - padding)/2) - borderSize*2, smallFrame - borderSize*2 },
			place = { "TOPLEFT", borderSize, -borderSize },
			bar = { 
				backdropmultiplier = false,
				textures = {
					backdrop = T.Player.bars.health.bar.textures.backdrop,
					normal = T.Player.bars.health.bar.textures.normal,
					overlay = T.Player.bars.health.bar.textures.overlay,
					glow = T.Player.bars.health.bar.textures.glow
				}
			},
			spark = {
				alpha = T.Player.bars.health.spark.alpha,
				texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
			},
			texframe = {
				size = { floor((T.Target.size[1] - padding)/2), smallFrame },
				place = { "TOPLEFT", -borderSize, borderSize },
			},
			textures = {
				glow = gUI4:GetMedia("Frame", "Glow", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				backdrop = false, -- gUI4:GetMedia("Frame", "Backdrop", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				border = gUI4:GetMedia("Frame", "Normal", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				shade = gUI4:GetMedia("Frame", "Shade", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				highlight = gUI4:GetMedia("Frame", "Highlight", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Overlay", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				threat = gUI4:GetMedia("Frame", "Threat", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft")
			}
		}, 
		castbar = {
			alpha = .1,
			size = { floor((T.Target.size[1] - padding)/2) - borderSize*2, smallFrame - borderSize*2 },
			place = { "TOPLEFT", borderSize, -borderSize },
			bar = { 
				backdropmultiplier = false,
				textures = {
					backdrop = false, 
					normal = gUI4:GetMedia("Texture", "Blank"),
					overlay = false, 
					glow = false, 
				}
			},
			spark = {
				alpha = 1,
				texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
			},
			texframe = {
				size = { barWidth, health },
				place = { "TOPLEFT", -borderSize, borderSize }
			},
			textures = {
				glow = false, 
				backdrop = false, 
				border = false, 
				shade = false, 
				highlight = false, 
				overlay = false, 
				threat = false, 
			}
		}
	},
	fontstrings = {
		combatfeedbacktext = {
			size = 18,
			place = { "BOTTOMLEFT", 0, smallFrame + 10 }, -- "TOP", 0, -((bigBar - 18)/2)
			fontobject = NumberFontNormalHuge,
			fontstyle = "THINOUTLINE", 
			shadowoffset = { 1.5, -1.5 },
			shadowcolor = { 0, 0, 0, .35 },
			color = { .79, .79, .79 }
		},
		nametext = {
			size = 10,
			place = { "LEFT", (borderSize + 10), 0 },
			fontobject = GameFontNormalSmall,
			fontstyle = nil, 
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, .75 },
			color = { .79, .79, .79 },
			tag = "[gUI4: SmartName:Short]" -- [gUI4: PvP:Small]
		},
		healthtext = {
			size = 10,
			place = { "RIGHT", -(borderSize + 10), 0 },
			fontobject = TextStatusBarText,
			fontstyle = nil, 
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, .75 },
			color = { .79, .79, .79 },
			tag = "[gUI4: Health:Percentage]"
		}
	},
	widgets = {
		auras = {
			auraSize = 28, 
			padding = 2,
			columns = 8,
			rows = 2,
			place = { "TOPRIGHT", -(floor((T.Player.size[1] - padding)/2) + 10), -borderSize },
			initialAnchor = "TOPRIGHT",
			growthy = "UP",
			growthx = "LEFT",
			onlyShowPlayer = false
		}
	}
}

T.PetTarget = setmetatable({
	place = function() 
		local load = parent.db.profile.modules[parent:GetModule("Player"):GetName()]
		local anchor = gUI4_UnitPlayer
		if load and anchor then
			return "BOTTOMRIGHT",  anchor, "TOPRIGHT", 0, padding
		else
			return "BOTTOMRIGHT", "UIParent", "BOTTOM", -210, getBasePosition() + T.Player.size[2] + padding
		end
	end, 
	-- place = function() return "BOTTOMRIGHT", "UIParent", "BOTTOM", -150, getBasePosition() + T.Player.size[2] + padding end
}, { __index = T.Pet })

T.ToT = {
	size = T.Pet.size,
	aurasaturation = .75,
	place = function() 
		local load = parent.db.profile.modules[parent:GetModule("Target"):GetName()]
		local anchor = gUI4_UnitTarget
		if load and anchor then
			return "BOTTOMRIGHT", anchor, "TOPRIGHT", 0, padding
		else
			return "BOTTOMLEFT", "UIParent", "BOTTOM", floor(210 + T.Target.size[1]/2 + padding/2), getBasePosition() + T.Target.size[2] + padding 
		end
	end,
	bars = {
		health = {
			size = { floor((T.Target.size[1] - padding)/2) - borderSize*2, smallFrame - borderSize*2 },
			place = { "TOPLEFT", borderSize, -borderSize },
			growth = "LEFT",
			bar = { 
				backdropmultiplier = false,
				textures = {
					backdrop = T.Player.bars.health.bar.textures.backdrop,
					normal = T.Player.bars.health.bar.textures.normal,
					overlay = T.Player.bars.health.bar.textures.overlay,
					glow = T.Player.bars.health.bar.textures.glow
				}
			},
			spark = {
				alpha = T.Player.bars.health.spark.alpha,
				texture = gUI4:GetMedia("StatusBar", "SparkReverse", 128, 128, "Warcraft"),
			},
			texframe = {
				size = { floor((T.Target.size[1] - padding)/2), smallFrame },
				place = { "TOPLEFT", -borderSize, borderSize },
			},
			textures = {
				glow = gUI4:GetMedia("Frame", "Glow", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				backdrop = false, -- gUI4:GetMedia("Frame", "Backdrop", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				border = gUI4:GetMedia("Frame", "Normal", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				shade = gUI4:GetMedia("Frame", "Shade", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				highlight = gUI4:GetMedia("Frame", "Highlight", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Overlay", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft"),
				threat = gUI4:GetMedia("Frame", "Threat", floor((T.Target.size[1] - padding)/2), smallFrame, "Warcraft")
			}
		}, 
		castbar = {
			alpha = .1,
			size = { floor((T.Target.size[1] - padding)/2) - borderSize*2, smallFrame - borderSize*2 },
			place = { "TOPLEFT", borderSize, -borderSize },
			growth = "LEFT",
			bar = { 
				backdropmultiplier = false,
				textures = {
					backdrop = false, 
					normal = gUI4:GetMedia("Texture", "Blank"),
					overlay = false, 
					glow = false, 
				}
			},
			spark = {
				alpha = 1,
				texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
			},
			texframe = {
				size = { barWidth, health },
				place = { "TOPLEFT", -borderSize, borderSize }
			},
			textures = {
				glow = false, 
				backdrop = false, 
				border = false, 
				shade = false, 
				highlight = false, 
				overlay = false, 
				threat = false, 
			}
		}
	},
	fontstrings = {
		combatfeedbacktext = {
			size = 18,
			place = { "BOTTOMRIGHT", -(barWidth + 10), (portrait + health + power) + 10 }, -- "TOP", 0, -((bigBar - 18)/2)
			fontobject = NumberFontNormalHuge,
			fontstyle = "THINOUTLINE", 
			shadowoffset = { 1.5, -1.5 },
			shadowcolor = { 0, 0, 0, .35 },
			color = { .79, .79, .79 }
		},
		nametext = {
			size = 10,
			place = { "RIGHT", -(borderSize + 10), 0 },
			fontobject = GameFontNormalSmall,
			fontstyle = nil, 
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, .75 },
			color = { .79, .79, .79 },
			tag = "[gUI4: SmartName:Short:Reverse]" -- [gUI4: PvP:Small]
		},
		healthtext = {
			size = 10,
			place = { "LEFT", (borderSize + 10), 0 },
			fontobject = TextStatusBarText,
			fontstyle = nil, 
			shadowoffset = { 1.25, -1.25 },
			shadowcolor = { 0, 0, 0, .75 },
			color = { .79, .79, .79 },
			tag = "[gUI4: Health:Percentage]"
		}
	},
	widgets = {
		auras = {
			auraSize = 28, 
			padding = 2,
			columns = 8,
			rows = 2,
			place = { "TOPLEFT", (floor((T.Target.size[1] - padding)/2) + 10), -borderSize },
			initialAnchor = "TOPLEFT",
			growthy = "UP",
			growthx = "RIGHT",
			onlyShowPlayer = false
		}
	}
}
T.ToT.fontstrings.combatfeedbacktext.place = { "BOTTOMRIGHT", 0, smallFrame + 10 }

T.ToTTarget = setmetatable({
	place = function() 
		local load = parent.db.profile.modules[parent:GetModule("Target"):GetName()]
		local anchor = gUI4_UnitTarget
		if load and anchor then
			return "BOTTOMLEFT", anchor, "TOPLEFT", 0, padding
		else
			return "BOTTOMLEFT", "UIParent", "BOTTOM", 210, getBasePosition() + T.Target.size[2] + padding
		end
	end,
	-- place = function() return "BOTTOMLEFT", "UIParent", "BOTTOM", 150, getBasePosition() + T.Target.size[2] + padding end,
}, { __index = T.ToT })
T.ToTTarget.fontstrings.combatfeedbacktext.place = { "BOTTOMRIGHT", 0, smallFrame + 10 }

T.Focus = setmetatable({
	place = function() return "RIGHT", "UIParent", "CENTER", -450, 0 end,
}, { __index = T.Pet })

T.FocusTarget = setmetatable({
	place = function() return "RIGHT", "UIParent", "CENTER", -450 + padding + T.Focus.size[1], 0 end,
}, { __index = T.Pet })

local maxWidth, maxHeight = 0, 0
for type,size in pairs(ALT_POWER_BAR_PLAYER_SIZES) do
	maxWidth = math.max(size.x, maxWidth) 
	maxHeight = math.max(size.y, maxHeight) 
end
T.AltPowerBar = {
	-- development = true, 
	-- size = { maxWidth, maxHeight }, -- this is the max size used by blizzard 
	size = { 252, 36 },
	place = function() return "BOTTOM", "UIParent", "BOTTOM", 0, gUI4:GetBottomOffset() + 66 + 36 + 30 end, -- above castbars and resources
	widgets = {
		altpower = {
			size = { 252, 36 },
			place = { "TOPLEFT", 0, 0 },
			bar = {
				size = { 240, 24 },
				place = { "BOTTOMLEFT", 6, 6 },
				color = gUI4:GetColors("reaction")[5],
				textures = {
					normal = gUI4:GetMedia("StatusBar", "Resource", 512, 64, "Warcraft"),
					overlay = gUI4:GetMedia("StatusBar", "ResourceOverlay", 512, 64, "Warcraft")
				},
				value = {
					size = 10,
					fontobject = TextStatusBarText,
					fontstyle = nil,
					shadowoffset = { .75, -.75 },
					shadowcolor = { 0, 0, 0, 1 },
					color = gUI4:GetColors("chat", "offwhite"),
					place = { "BOTTOMRIGHT", -4, 4 }
				}
			},
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 36, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 36, "Warcraft")
			}
		}
	}
}

T.ClassBar = { 
	-- development = true, 
	-- strata = "MEDIUM",
	-- level = 10,
	size = { 252, 36 }, -- keep width dividable by 60, to allow it to be split in 2, 3, 4, 5 and 6 parts
	place = function() return "BOTTOM", "UIParent", "BOTTOM", 0, gUI4:GetBottomOffset() + 66 end, -- above the castbar
	widgets = {
		combopoints = { 
			size = { 240, 14 }, 
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			points = {
				{
					size = { 48, 13 },
					place = { "TOPLEFT", 0, 0 },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 48, 13, "Warcraft")
				},
				{
					size = { 48, 13 },
					place = { "TOPLEFT", 48, 0 },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 48, 13, "Warcraft")
				},
				{
					size = { 48, 13 },
					place = { "TOPLEFT", 48*2, 0 },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 48, 13, "Warcraft")
				},
				{
					size = { 48, 13 },
					place = { "TOPLEFT", 48*3, 0 },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 48, 13, "Warcraft")
				},
				{
					size = { 48, 13 },
					place = { "TOPLEFT", 48*4, 0 },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 48, 13, "Warcraft")
				},
				{
					size = { 46, 1 },
					place = { "TOPLEFT", 1, -(13 + 3) },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 46, 1, "Warcraft")
				},
				{
					size = { 46, 1 },
					place = { "TOPLEFT", 48 + 1, -(13 + 3) },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 46, 1, "Warcraft")
				},
				{
					size = { 46, 1 },
					place = { "TOPLEFT", 48*2 + 1, -(13 + 3) },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 46, 1, "Warcraft")
				},
				{
					size = { 46, 1 },
					place = { "TOPLEFT", 48*3 + 1, -(13 + 3) },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 46, 1, "Warcraft")
				},
				{
					size = { 46, 1 },
					place = { "TOPLEFT", 48*4 + 1, -(13 + 3) },
					texture = gUI4:GetMedia("Texture", "ResourcePill", 46, 1, "Warcraft")
				}
			},
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			}
		},
		runes = {
			size = { 240, 14 },
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			}
		},
		totems = {
			size = { 240, 14 },
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			values = {
				size = 10,
				fontobject = TextStatusBarText,
				fontstyle = nil,
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, 1 },
				color = gUI4:GetColors("chat", "offwhite"),
				place = { "BOTTOMRIGHT", -4, 1 }
			},
			spark = {
				alpha = .5,
				texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
			},
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			}
		},
		eclipsebar = {
			size = { 252, 36 }, -- size of the widget
			place = { "BOTTOMLEFT", 0, 0 }, -- relative to the widgetframe
			bar = {
				size = { 240, 24 },
				place = { "BOTTOMLEFT", 6, 6 },
				colors = {
					lunar = gUI4:GetColors("power", "ECLIPSE").negative,
					solar = gUI4:GetColors("power", "ECLIPSE").positive
				},
				textures = {
					normal = gUI4:GetMedia("StatusBar", "Resource", 512, 64, "Warcraft"),
					overlay = gUI4:GetMedia("StatusBar", "ResourceOverlay", 512, 64, "Warcraft")
				},
				spark = {
					alpha = .5,
					texture = gUI4:GetMedia("StatusBar", "SparkReverse", 128, 128, "Warcraft"), -- reverse version because it's on the solarbar (which is reversed)
				},
				value = {
					size = 14,
					fontobject = TextStatusBarText,
					fontstyle = nil,
					shadowoffset = { .75, -.75 },
					shadowcolor = { 0, 0, 0, 1 },
					color = gUI4:GetColors("chat", "offwhite"),
					place = { "CENTER", 0, 0 }
				},
				guide = {
					size = 9,
					fontobject = TextStatusBarText,
					fontstyle = nil,
					shadowoffset = { .75, -.75 },
					shadowcolor = { 0, 0, 0, 1 },
					color = gUI4:GetColors("chat", "offwhite"),
					place = { "BOTTOM", 0, -2 }
				}
			},
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 36, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 36, "Warcraft")
			}
		},
		arcanecharges = {
			size = { 240, 14 },
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			},
			bar = {
				size = { 238, 2},
				place = { "BOTTOMLEFT", 1, -3 },
				color = gUI4:GetColors("power", "ARCANE_CHARGE"),
				multiplier = 1/3,
				textures = {
					backdrop = gUI4:GetMedia("StatusBar", "Backdrop", 512, 64, "Warcraft"),
					normal = gUI4:GetMedia("StatusBar", "Power", 512, 64, "Warcraft")
				},
				value = {
					size = 12,
					fontobject = TextStatusBarText,
					fontstyle = nil,
					shadowoffset = { 1.25, -1.25 },
					shadowcolor = { 0, 0, 0, 1 },
					color = gUI4:GetColors("chat", "offwhite"),
					place = { "CENTER", 0, 0 }
				},
			}
		},
		chi = {
			size = { 240, 14 },
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			}
		},
		holypower = {
			size = { 240, 14 },
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			}
		},
		shadoworbs = {
			size = { 240, 14 },
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			}
		},
		burningembers = {
			size = { 240, 14 }, -- size of the widget
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			values = {
				size = 8,
				fontobject = TextStatusBarText,
				fontstyle = nil,
				shadowoffset = { .75, -.75 },
				shadowcolor = { 0, 0, 0, 1 },
				color = gUI4:GetColors("chat", "offwhite"),
				place = { "BOTTOMRIGHT", -4, 3 }
			},
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			}
		},
		soulshards = {
			size = { 240, 14 },
			place = { "BOTTOMLEFT", 6, 6 }, -- relative to the widgetframe
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 26, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 26, "Warcraft"),
				pill = gUI4:GetMedia("StatusBar", "ResourcePill", 128, 32, "Warcraft"),
				pillgloss = gUI4:GetMedia("StatusBar", "ResourcePillGloss", 128, 32, "Warcraft")
			}
		},
		demonicfury = {
			size = { 252, 36 }, -- size of the widget
			place = { "BOTTOMLEFT", 0, 0 }, -- relative to the widgetframe
			bar = {
				size = { 240, 24 },
				place = { "BOTTOMLEFT", 6, 6 },
				color = gUI4:GetColors("power", "DEMONIC_FURY"),
				textures = {
					normal = gUI4:GetMedia("StatusBar", "Resource", 512, 64, "Warcraft"),
					overlay = gUI4:GetMedia("StatusBar", "ResourceOverlay", 512, 64, "Warcraft")
				},
				spark = {
					alpha = .5,
					texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"), 
				},
				value = {
					size = 10,
					fontobject = TextStatusBarText,
					fontstyle = nil,
					shadowoffset = { .75, -.75 },
					shadowcolor = { 0, 0, 0, 1 },
					color = gUI4:GetColors("chat", "offwhite"),
					place = { "BOTTOMRIGHT", -4, 4 }
				}
			},
			textures = {
				backdrop = gUI4:GetMedia("Frame", "Backdrop", 252, 36, "Warcraft"),
				overlay = gUI4:GetMedia("Frame", "Normal", 252, 36, "Warcraft"),
			}
		}
	}
}

local bossWidth, bossHeight, bossHealth, bossPower = 192, 51, 24, 4
T.Boss = { 
	-- development = true, 
	size = { bossWidth, bossHeight },
  place = { "CENTER", "UIParent", "CENTER", 650, -32 },
  aurasaturation = .75,
	textures = {
    backdrop = gUI4:GetMedia("Frame", "Backdrop", bossWidth, bossHeight, "Warcraft"),
    border = gUI4:GetMedia("Frame", "Normal", bossWidth, bossHeight, "Warcraft"),
    highlight = gUI4:GetMedia("Frame", "Highlight", bossWidth, bossHeight, "Warcraft"),
    target = gUI4:GetMedia("Frame", "Target", bossWidth, bossHeight, "Warcraft"),
    threat = false,
		glow = false,
		shade = false,
		gloss = false,
		overlay = false
	},
  bars = {
    health = {
      size = { bossWidth - borderSize*2, bossHealth },
      place = { "TOPLEFT", borderSize, -borderSize },
      growth = "LEFT",
      bar = { 
        backdropmultiplier = false,
        textures = {
          backdrop = T.Player.bars.health.bar.textures.backdrop,
          normal = T.Player.bars.health.bar.textures.normal,
          overlay = T.Player.bars.health.bar.textures.overlay,
          glow = T.Player.bars.health.bar.textures.glow
        }
      },
      spark = {
        alpha = T.Player.bars.health.spark.alpha,
        texture = gUI4:GetMedia("StatusBar", "SparkReverse", 128, 128, "Warcraft"),
      },
      texframe = {
        size = { bossWidth, bossHealth + borderSize*2 },
        place = { "TOPLEFT", -borderSize, borderSize },
      },
      textures = {
        glow = false, 
        backdrop = false, 
        border = false, 
        shade = false, 
        highlight = false, 
        overlay = false, 
        threat = false
      }
    }, 
		power = {
			size = { bossWidth - borderSize*2, bossPower },
			place = { "TOPLEFT", borderSize, -(borderSize + bossHealth + borderSize -1 + borderSize) },
			bar = {
				backdropmultiplier = .3,
				textures = {
					backdrop = T.Player.bars.power.bar.textures.backdrop,
          normal = T.Player.bars.power.bar.textures.normal,
          overlay = T.Player.bars.power.bar.textures.overlay,
          glow = T.Player.bars.power.bar.textures.glow
				}
			},
			spark = {
				alpha = .5,
				texture = gUI4:GetMedia("StatusBar", "SparkReverse", 128, 128, "Warcraft"),
			},
			texframe = {
				size = { bossWidth, bossPower },
				place = { "TOPLEFT", -borderSize, borderSize }
			},
			textures = {
        glow = false, 
        backdrop = false, 
        border = false, 
        shade = false, 
        highlight = false, 
        overlay = false, 
        threat = false
			}
		}, 
    castbar = {
      alpha = .1,
      size = { bossWidth - borderSize*2, bossHealth },
      place = { "TOPLEFT", borderSize, -borderSize },
      growth = "LEFT",
      bar = { 
        backdropmultiplier = false,
        textures = {
          backdrop = false, 
          normal = gUI4:GetMedia("Texture", "Blank"),
          overlay = false, 
          glow = false
        }
      },
      spark = {
        alpha = 1,
        texture = gUI4:GetMedia("StatusBar", "SparkReverse", 128, 128, "Warcraft"),
      },
      texframe = {
        size = { bossWidth, bossHeight },
        place = { "TOPLEFT", -borderSize, borderSize }
      },
      textures = {
        glow = false, 
        backdrop = false, 
        border = false, 
        shade = false, 
        highlight = false, 
        overlay = false, 
        threat = false
      }
    }
  },

  fontstrings = {
    combatfeedbacktext = {
      size = 14,
      place = { "BOTTOM", 0, 0 }, 
      fontobject = NumberFontNormalHuge,
      fontstyle = "THINOUTLINE", 
      shadowoffset = { 1.5, -1.5 },
      shadowcolor = { 0, 0, 0, .35 },
      color = { .79, .79, .79 }
    },
    nametext = {
      size = 10,
			place = { "TOPRIGHT", -(borderSize + 10), -(borderSize + floor((bossHealth - 10)/2)) },
      fontobject = GameFontNormalSmall,
      fontstyle = nil, 
      shadowoffset = { 1.25, -1.25 },
      shadowcolor = { 0, 0, 0, .75 },
      color = { .79, .79, .79 },
      tag = "[gUI4: SmartName:Medium:Reverse]" -- [gUI4: PvP:Small]
    },
    healthtext = {
      size = 10,
			place = { "TOPLEFT", (borderSize + 10), -(borderSize + floor((bossHealth - 10)/2)) },
      fontobject = TextStatusBarText,
      fontstyle = nil, 
      shadowoffset = { 1.25, -1.25 },
      shadowcolor = { 0, 0, 0, .75 },
      color = { .79, .79, .79 },
      tag = "[gUI4: Health:Percentage]"
    }
  },
  widgets = {
    auras = {
      auraSize = 24, 
      padding = 2,
      columns = 8,
      rows = 2,
      place = { "TOPRIGHT", -(bossWidth + 10), -borderSize },
      initialAnchor = "TOPRIGHT",
      growthy = "DOWN",
      growthx = "LEFT",
      onlyShowPlayer = false
    } 
  }
}

for i = 1, MAX_BOSS_FRAMES do
	local place
	if i == 1 then 
		place = { "CENTER", "UIParent", "CENTER", 650, -32 }
	else
		local id = i
		place = function() 
			local anchor = _G["gUI4_UnitBoss"..(id - 1)]
			if anchor then
				return "BOTTOMRIGHT",  anchor, "TOPRIGHT", 0, 10
--				return "CENTER", 450, 0 + (id - 1) * (padding + T.Boss.size[2])
	--		else
			end
		end
	end
	T["Boss"..i] = { 
		size = T.Boss.size, 
		place = place
	}
end

parent:RegisterTheme("Warcraft", T)

