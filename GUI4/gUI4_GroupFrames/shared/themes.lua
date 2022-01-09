local _,ns = ...

local gUI4 = _G.GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local parent = gUI4:GetModule("gUI4_GroupFrames", true)
if not parent then return end

-- Lua API
local _G = _G
local floor = math.floor

-- WoW API
local NumberFontNormalHuge = _G.NumberFontNormalHuge
local GameFontNormalSmall = _G.GameFontNormalSmall
local TextStatusBarText = _G.TextStatusBarText

-- just to illustrate the reason for the sizes and positions below better
-- 		*do NOT change these values, they are not meant to be editable, 
-- 		 they are all linked to specific media files identified by these sizes!
local borderSize = 6 
local frameWidth = 80
local health = 31 
local divider = 4
local power = 4

local T = {}

-- Just putting this here for now, 
-- since they'll all be using the exact same at the start. 
local groupauras = {

	-- size of each aura
	size = { 24, 24 },

	-- spawn point where they'll grow from
	place = { "CENTER", 0, 0 },

	-- gap between the auras in any direction
	gap = 4,

	-- indicates rows and columns
	height = 1, width = 2
}

do
	local partyWidth, partyHeight, partyHealth, partyPower = 192, 51, 24, 4
	T.Group5 = {
		size = { partyWidth, partyHeight },
		place = function() 
			local LeaderTools = _G.gUI4_GroupFramesRaidLeaderToolsFrame
			if LeaderTools then 
				return "TOPLEFT", LeaderTools, "TOPRIGHT", 4, -4 -- must match the negative value of the LeaderTools
			else
				return "TOPLEFT", "UIParent", "TOPLEFT", gUI4:GetLeftOffset("TOP"), -(gUI4:GetTopOffset("LEFT") + 108)
			end
		end,
		aurasaturation = .85,
		header = {
			columnSpacing = 10,
			maxColumns = 5,
			unitsPerColumn = 1,
			point = "LEFT",
			columnAnchorPoint = "TOP",
			groupBy = "GROUP",
			groupFilter = "1,2,3,4,5,6,7,8",
			groupingOrder = "1,2,3,4,5,6,7,8",
			showSolo = false -- only enable this for testing purposes
		},
		textures = {
			backdrop = gUI4:GetMedia("Frame", "Backdrop", partyWidth, partyHeight, "Warcraft"),
			border = gUI4:GetMedia("Frame", "Normal", partyWidth, partyHeight, "Warcraft"),
			highlight = gUI4:GetMedia("Frame", "Highlight", partyWidth, partyHeight, "Warcraft"),
			target = gUI4:GetMedia("Frame", "Target", partyWidth, partyHeight, "Warcraft"),
			threat = false,
			glow = false,
			shade = false,
			gloss = false,
			overlay = false
		},
		bars = {
			health = {
				size = { partyWidth - borderSize*2, partyHealth },
				place = { "TOPLEFT", borderSize, -borderSize },
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
					size = { partyWidth, partyHealth },
					place = { "TOPLEFT", -borderSize, borderSize }
				},
				textures = {
					threat = gUI4:GetMedia("Frame", "Threat", partyWidth, partyHeight, "Warcraft"),
				}
			},
			power = {
				size = { partyWidth - borderSize*2, partyPower },
				place = { "TOPLEFT", borderSize, -(borderSize + partyHealth + borderSize - 1 + borderSize ) },
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
					size = { partyWidth, partyPower },
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
				size = { partyWidth - borderSize*2, partyHealth },
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
					texture = gUI4:GetMedia("StatusBar", "Spark", 128, 128, "Warcraft"),
				},
				texframe = {
					size = { partyWidth, partyHeight },
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
				place = { "TOPLEFT", (borderSize + 10), -(borderSize + floor((partyHealth - 10)/2)) },
				fontobject = GameFontNormalSmall,
				fontstyle = nil, 
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 },
				color = { .79, .79, .79 },
				tag = "[gUI4: SmartName:Medium]"
			},
			healthtext = {
				size = 10,
				place = { "TOPRIGHT", -(borderSize + 10), -(borderSize + floor((partyHealth - 10)/2)) },
				fontobject = TextStatusBarText,
				fontstyle = nil, 
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 },
				color = { .79, .79, .79 },
				tag = "[gUI4: Health:Simple]"
			}
		},
		widgets = {
			-- iconstack
			iconstack = {
				size = { 16, 16 },
				place = { "TOPLEFT", floor(borderSize/2), borderSize + 2 },
				showLeader = true,
				showAssistant = true,
				showMainTank = true,
				showMainAssist = true,
				showMasterLooter = true
			},
			-- raid marker
			raidicon = {
				size = { 16, 16 },
				place = { "TOP", 0, borderSize },
				texture = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetPath()
			},
			-- group role
			grouprole = {
				size = { 32, 32 },
				place = { "BOTTOM", 0, -(borderSize + 2) },
				showTank = true,
				showHealer = true,
				showDPS = false,
				textures = {
					tank = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(1),
					heal = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(2),
					dps = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(3)
				}
			},
			-- ready check
			readycheck = {
				size = { 32, 32 },
				place = { "CENTER", 0, 0 },
			},
			groupauras = groupauras,
			-- priority based raid debuffs
			raiddebuff = {
				size = { 32, 32 },
				place = { "CENTER", 0, 0 },
			},
			auras = {
				auraSize = 24, 
				padding = 2,
				columns = 8,
				rows = 2,
				place = { "TOPLEFT", partyWidth + 10, -borderSize },
				initialAnchor = "TOPLEFT",
				growthy = "DOWN",
				growthx = "RIGHT",
				onlyShowPlayer = false
			} 
			
		},
		
		iconsize = 12,
		aura = { 
			size = 16,
			gap = 4,
			height = 1,
			width = 6,
		}
	}
end


do
	local health = health
	T.Raid15 = {
		size = { frameWidth, borderSize + health + divider + power + borderSize },
		place = function() 
			local LeaderTools = _G.gUI4_GroupFramesRaidLeaderToolsFrame
			if LeaderTools then 
				return "TOPLEFT", LeaderTools, "TOPRIGHT", 6, 0 -- must match the negative value of the LeaderTools
			else
				return "TOPLEFT", "UIParent", "TOPLEFT", gUI4:GetLeftOffset("TOP"), -(gUI4:GetTopOffset("LEFT") + 108)
			end
		end,
		aurasaturation = .85,
		header = {
			columnSpacing = 6,
			maxColumns = 5,
			unitsPerColumn = 3,
			point = "TOP",
			columnAnchorPoint = "LEFT",
			groupBy = "GROUP",
			groupFilter = "1,2,3,4,5,6,7,8",
			groupingOrder = "1,2,3,4,5,6,7,8",
			showSolo = false -- only enable this for testing purposes
		},
		textures = {
			backdrop = gUI4:GetMedia("Frame", "Backdrop", 80, 51, "Warcraft"),
			border = gUI4:GetMedia("Frame", "Normal", 80, 51, "Warcraft"),
			highlight = gUI4:GetMedia("Frame", "Highlight", 80, 51, "Warcraft"),
			target = gUI4:GetMedia("Frame", "Target", 80, 51, "Warcraft"),
			threat = gUI4:GetMedia("Frame", "Threat", 80, 51, "Warcraft")
		},
		bars = {
			health = {
				size = { frameWidth - borderSize*2, health },
				place = { "TOPLEFT", borderSize, -borderSize },
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
					size = { frameWidth, health },
					place = { "TOPLEFT", -borderSize, borderSize }
				},
				textures = {
					threat = gUI4:GetMedia("Frame", "Threat", 80, 51, "Warcraft")
				}
			},
			power = {
				size = { frameWidth - borderSize*2, power },
				place = { "TOPLEFT", borderSize, -(borderSize + health + divider) },
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
					size = { frameWidth, power },
					place = { "TOPLEFT", -borderSize, borderSize }
				},
				textures = {
				}
			}, 
		},
		widgets = {
			-- iconstack
			iconstack = {
				size = { 16, 16 },
				place = { "TOPLEFT", floor(borderSize/2), borderSize + 2 },
				showLeader = true,
				showAssistant = true,
				showMainTank = true,
				showMainAssist = true,
				showMasterLooter = true
			},
			-- raid marker
			raidicon = {
				size = { 16, 16 },
				place = { "TOP", 0, borderSize },
				texture = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetPath()
			},
			-- group role
			grouprole = {
				size = { 32, 32 },
				place = { "BOTTOM", 0, -(borderSize + 2) },
				showTank = true,
				showHealer = true,
				showDPS = false,
				textures = {
					tank = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(1),
					heal = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(2),
					dps = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(3)
				}
			},
			-- ready check
			readycheck = {
				size = { 32, 32 },
				place = { "CENTER", 0, 0 },
			},
			groupauras = groupauras,
			-- priority based raid debuffs
			raiddebuff = {
				size = { 32, 32 },
				place = { "CENTER", 0, 0 },
			}
		},
		fontstrings = {
			combatfeedbacktext = {
				size = 12,
				place = { "BOTTOM", 0, 0 }, 
				fontobject = NumberFontNormalHuge,
				fontstyle = "THINOUTLINE", 
				shadowoffset = { 1.5, -1.5 },
				shadowcolor = { 0, 0, 0, .35 },
				color = { .79, .79, .79 }
			},
			nametext = {
				size = 8,
				place = { "TOPLEFT", (borderSize + 4), -(borderSize + 4) },
				fontsize = 8,
				fontobject = GameFontNormalSmall,
				fontstyle = nil, 
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 },
				color = { .79, .79, .79 },
				tag = "[gUI4: Name:Tiny]"
			},
			healthtext = {
				size = 10,
				place = { "BOTTOMRIGHT", -(borderSize + 4), borderSize + power + divider + 4 },
				fontobject = TextStatusBarText,
				fontstyle = nil, 
				fontsize = 10,
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 },
				color = { .79, .79, .79 },
				tag = "[gUI4: Health:Simple]"
			},
		},
		
		iconsize = 12,
		aura = { 
			size = 16,
			gap = 4,
			height = 1,
			width = 6,
		},
	}
end

do
	local health = health
	T.Raid25 = {
		size = { frameWidth, borderSize + health + divider + power + borderSize },
		place = function() 
			local LeaderTools = _G.gUI4_GroupFramesRaidLeaderToolsFrame
			if LeaderTools then 
				return "TOPLEFT", LeaderTools, "TOPRIGHT", 6, 0 -- must match the negative value of the LeaderTools
			else
				return "TOPLEFT", "UIParent", "TOPLEFT", gUI4:GetLeftOffset("TOP"), -(gUI4:GetTopOffset("LEFT") + 108)
			end
		end,
		aurasaturation = .85,
		header = {
			columnSpacing = 6,
			maxColumns = 5,
			unitsPerColumn = 5,
			point = "LEFT",
			columnAnchorPoint = "TOP",
			groupBy = "GROUP",
			groupFilter = "1,2,3,4,5,6,7,8",
			groupingOrder = "1,2,3,4,5,6,7,8",
			showSolo = false -- only enable this for testing purposes
		},
		textures = {
			backdrop = gUI4:GetMedia("Frame", "Backdrop", 80, 51, "Warcraft"),
			border = gUI4:GetMedia("Frame", "Normal", 80, 51, "Warcraft"),
			highlight = gUI4:GetMedia("Frame", "Highlight", 80, 51, "Warcraft"),
			target = gUI4:GetMedia("Frame", "Target", 80, 51, "Warcraft"),
			threat = gUI4:GetMedia("Frame", "Threat", 80, 51, "Warcraft")
		},
		bars = {
			health = {
				size = { frameWidth - borderSize*2, health },
				place = { "TOPLEFT", borderSize, -borderSize },
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
					size = { frameWidth, health },
					place = { "TOPLEFT", -borderSize, borderSize }
				},
				textures = {
					threat = gUI4:GetMedia("Frame", "Threat", 80, 51, "Warcraft")
				}
			},
			power = {
				size = { frameWidth - borderSize*2, power },
				place = { "TOPLEFT", borderSize, -(borderSize + health + divider) },
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
					size = { frameWidth, power },
					place = { "TOPLEFT", -borderSize, borderSize }
				},
				textures = {
				}
			}
		},
		widgets = {
			-- iconstack
			iconstack = {
				size = { 16, 16 },
				place = { "TOPLEFT", floor(borderSize/2), borderSize + 2 },
				showLeader = true,
				showAssistant = true,
				showMainTank = true,
				showMainAssist = true,
				showMasterLooter = true
			},
			-- raid marker
			raidicon = {
				size = { 16, 16 },
				place = { "TOP", 0, borderSize },
				texture = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetPath()
			},
			-- group role
			grouprole = {
				size = { 32, 32 },
				place = { "BOTTOM", 0, -(borderSize + 2) },
				showTank = true,
				showHealer = true,
				showDPS = false,
				textures = {
					tank = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(1),
					heal = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(2),
					dps = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(3)
				}
			},
			-- ready check
			readycheck = {
				size = { 32, 32 },
				place = { "CENTER", 0, 0 },
			},
			groupauras = groupauras,
			-- priority based raid debuffs
			raiddebuff = {
				size = { 32, 32 },
				place = { "CENTER", 0, 0 },
			}
		},
		fontstrings = {
			combatfeedbacktext = {
				size = 12,
				place = { "BOTTOM", 0, 0 }, 
				fontobject = NumberFontNormalHuge,
				fontstyle = "THINOUTLINE", 
				shadowoffset = { 1.5, -1.5 },
				shadowcolor = { 0, 0, 0, .35 },
				color = { .79, .79, .79 }
			},
			nametext = {
				size = 8,
				place = { "TOPLEFT", (borderSize + 4), -(borderSize + 4) },
				fontsize = 8,
				fontobject = GameFontNormalSmall,
				fontstyle = nil, 
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 },
				color = { .79, .79, .79 },
				tag = "[gUI4: Name:Tiny]"
			},
			healthtext = {
				size = 10,
				place = { "BOTTOMRIGHT", -(borderSize + 4), borderSize + power + divider + 4 },
				fontobject = TextStatusBarText,
				fontstyle = nil, 
				fontsize = 10,
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 },
				color = { .79, .79, .79 },
				tag = "[gUI4: Health:Simple]"
			},
		},
		
		iconsize = 12,
		aura = { 
			size = 16,
			gap = 4,
			height = 1,
			width = 6,
		},
	}
end

do
	local health = 24
	local power = 0
	local divider = 0
	
	T.Raid40 = {
		size = { frameWidth, borderSize + health + divider + power + borderSize },
		place = function() 
			local LeaderTools = _G.gUI4_GroupFramesRaidLeaderToolsFrame
			if LeaderTools then 
				return "TOPLEFT", LeaderTools, "TOPRIGHT", 6, 0 -- must match the negative value of the LeaderTools
			else
				return "TOPLEFT", "UIParent", "TOPLEFT", gUI4:GetLeftOffset("TOP"), -(gUI4:GetTopOffset("LEFT") + 108)
			end
		end,
		aurasaturation = .85,
		header = {
			columnSpacing = 6,
			maxColumns = 8,
			unitsPerColumn = 5,
			point = "LEFT",
			columnAnchorPoint = "TOP",
			groupBy = "GROUP",
			groupFilter = "1,2,3,4,5,6,7,8",
			groupingOrder = "1,2,3,4,5,6,7,8",
			showSolo = false -- only enable this for testing purposes
		},
		textures = {
			glow = false,
			backdrop = gUI4:GetMedia("Frame", "Backdrop", 80, 36, "Warcraft"),
			border = gUI4:GetMedia("Frame", "Normal", 80, 36, "Warcraft"),
			highlight = gUI4:GetMedia("Frame", "Highlight", 80, 36, "Warcraft"),
			target = gUI4:GetMedia("Frame", "Target", 80, 36, "Warcraft"),
			threat = gUI4:GetMedia("Frame", "Threat", 80, 36, "Warcraft")
		},
		bars = {
			health = {
				size = { frameWidth - borderSize*2, health },
				place = { "TOPLEFT", borderSize, -borderSize },
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
					size = { frameWidth, health },
					place = { "TOPLEFT", -borderSize, borderSize }
				},
				textures = {
					threat = gUI4:GetMedia("Frame", "Threat", 80, 36, "Warcraft")
				}
			}
		},
		widgets = {
			-- iconstack
			iconstack = {
				size = { 16, 16 },
				place = { "TOPLEFT", floor(borderSize/2), borderSize + 2 },
				showLeader = true,
				showAssistant = true,
				showMainTank = true,
				showMainAssist = true,
				showMasterLooter = true
			},
			-- raid marker
			raidicon = {
				size = { 16, 16 },
				place = { "TOP", 0, borderSize },
				texture = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetPath()
			},
			-- group role
			grouprole = {
				size = { 32, 32 },
				place = { "BOTTOM", 0, -(borderSize * 2) },
				showTank = true,
				showHealer = true,
				showDPS = false,
				textures = {
					tank = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(1),
					heal = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(2),
					dps = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(3)
				}
			},
			-- ready check
			readycheck = {
				size = { 32, 32 },
				place = { "CENTER", 0, 0 },
			},
			groupauras = groupauras,
			-- priority based raid debuffs
			raiddebuff = {
				size = { 32, 32 },
				place = { "CENTER", 0, 0 },
			}
		},
		fontstrings = {
			combatfeedbacktext = {
				size = 12,
				place = { "BOTTOM", 0, 0 }, 
				fontobject = NumberFontNormalHuge,
				fontstyle = "THINOUTLINE", 
				shadowoffset = { 1.5, -1.5 },
				shadowcolor = { 0, 0, 0, .35 },
				color = { .79, .79, .79 }
			},
			nametext = {
				size = 8,
				place = { "TOPLEFT", (borderSize + 4), -(borderSize + 4) },
				fontsize = 8,
				fontobject = GameFontNormalSmall,
				fontstyle = nil, 
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 },
				color = { .79, .79, .79 },
				tag = "[gUI4: Name:Tiny]"
			},
			healthtext = {
				size = 10,
				place = { "BOTTOMRIGHT", -(borderSize + 4), borderSize + power + divider + 4 },
				fontobject = TextStatusBarText,
				fontstyle = nil, 
				fontsize = 10,
				shadowoffset = { 1.25, -1.25 },
				shadowcolor = { 0, 0, 0, .75 },
				color = { .79, .79, .79 },
				tag = "[gUI4: Health:Simple]"
			}
		},
		
		iconsize = 12,
		aura = { 
			size = 16,
			gap = 4,
			height = 1,
			width = 6,
		},
	}
end

local frameWidth = 260
local contentWidth = 220
local contentIndent = floor((frameWidth - contentWidth)/2)
local buttonSize, markerSize, roleSize = 40, 48, 64
local roleOffset, markerOffset, buttonOffset = 50, 110, 220
local frameHeight = contentIndent*4 + roleSize + markerSize*2 + buttonSize*4

T.LeaderTools = {
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
	backdropcolor = { 0, 0, 0, .85 }, 
	backdropbordercolor = { .75, .75, .75, 1 }, 
	backdrophighlightcolor = { .05, .05, .05, .85 },
	backdropborderhighlightcolor = { 1, 1, 1, 1 }, 
	button = {
		size = { 48, 64 },
		place = function()
			return "TOPLEFT", "UIParent", "TOPLEFT", gUI4:GetLeftOffset("TOP") - 48, -(gUI4:GetTopOffset("LEFT") + 108 - 4) 
		end,
		--place = function() return "RIGHT", "UIParent", "LEFT", 24, 0 end,
		textures = {
			open = gUI4:GetMedia("Texture", "PanelArrowGrid", 32, 64, "Warcraft"):GetGridItem(1),
			close = gUI4:GetMedia("Texture", "PanelArrowGrid", 32, 64, "Warcraft"):GetGridItem(2)
		}
	},
	frame = {
		size = { frameWidth, frameHeight },
		--place = function() return "CENTER", "UIParent", "CENTER", 0, 0 end
		place = function()
			return "TOPLEFT", "UIParent", "TOPLEFT", gUI4:GetLeftOffset("TOP") - 4, -(gUI4:GetTopOffset("LEFT") + 108 - 4) -- where the raidframes are
			--return "TOPLEFT", "UIParent", "TOPLEFT", gUI4:GetLeftOffset("TOP") + 20 + 424, -(gUI4:GetTopOffset("LEFT") + 108)
		end
	},
	raidmembers = {
		size = 12,
		place = { "TOP", 0, -20 }, 
		fontobject = GameFontNormal,
		fontstyle = "THINOUTLINE", 
		shadowoffset = { 1.5, -1.5 },
		shadowcolor = { 0, 0, 0, .35 },
		color = gUI4:GetColors("chat", "normal")
	},
	rolecounts = {
		size = { contentWidth, roleSize },
		place = { "TOPLEFT", contentIndent, -roleOffset }, 
		roles = {
			tank = {
				size = { contentWidth/3, roleSize },
				place = { "TOPLEFT", 0, 0 },
				icon = {
					size = { 32, 32 },
					place = { "TOPLEFT", (contentWidth/3/2)-32, 0 },
					texture = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(1)
				},
				label = {
					size = 10,
					place = { "TOPLEFT", (contentWidth/3/2)-32+8, -36 }, 
					fontobject = GameFontNormal,
					fontstyle = "THINOUTLINE", 
					shadowoffset = { 1.5, -1.5 },
					shadowcolor = { 0, 0, 0, .35 },
					color = gUI4:GetColors("chat", "normal")
				},
				count = {
					size = 14,
					place = { "TOPLEFT", (contentWidth/3/2), -((32-14)/2) }, 
					fontobject = NumberFontNormal,
					fontstyle = "THINOUTLINE", 
					shadowoffset = { 1.5, -1.5 },
					shadowcolor = { 0, 0, 0, .35 },
					color = gUI4:GetColors("chat", "highlight")
				}
			},
			healer = {
				size = { contentWidth/3, roleSize },
				place = { "TOPLEFT", contentWidth/3, 0 },
				icon = {
					size = { 32, 32 },
					place = { "TOPLEFT", (contentWidth/3/2)-32, 0 },
					texture = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(2)
				},
				label = {
					size = 10,
					place = { "TOPLEFT", (contentWidth/3/2)-32+8, -36 }, 
					fontobject = GameFontNormal,
					fontstyle = "THINOUTLINE", 
					shadowoffset = { 1.5, -1.5 },
					shadowcolor = { 0, 0, 0, .35 },
					color = gUI4:GetColors("chat", "normal")
				},
				count = {
					size = 14,
					place = { "TOPLEFT", (contentWidth/3/2), -((32-14)/2) }, 
					fontobject = NumberFontNormal,
					fontstyle = "THINOUTLINE", 
					shadowoffset = { 1.5, -1.5 },
					shadowcolor = { 0, 0, 0, .35 },
					color = gUI4:GetColors("chat", "highlight")
				}
			},
			damager = {
				size = { contentWidth/3, roleSize },
				place = { "TOPLEFT", contentWidth/3 * 2, 0 },
				icon = {
					size = { 32, 32 },
					place = { "TOPLEFT", (contentWidth/3/2)-32, 0 },
					texture = gUI4:GetMedia("Texture", "RoleIconGrid", 32, 32, "Warcraft"):GetGridItem(3)
				},
				label = {
					size = 10,
					place = { "TOPLEFT", (contentWidth/3/2)-32+8, -36 }, 
					fontobject = GameFontNormal,
					fontstyle = "THINOUTLINE", 
					shadowoffset = { 1.5, -1.5 },
					shadowcolor = { 0, 0, 0, .35 },
					color = gUI4:GetColors("chat", "normal")
				},
				count = {
					size = 14,
					place = { "TOPLEFT", (contentWidth/3/2), -((32-14)/2) }, 
					fontobject = NumberFontNormal,
					fontstyle = "THINOUTLINE", 
					shadowoffset = { 1.5, -1.5 },
					shadowcolor = { 0, 0, 0, .35 },
					color = gUI4:GetColors("chat", "highlight")
				}
			}
		}
	},
	rolecheck = {
		size = { contentWidth, buttonSize },
		place = { "TOPLEFT", contentIndent, -buttonOffset }
	},
	readycheck = {
		size = { contentWidth - buttonSize, buttonSize },
		place = { "TOPLEFT", contentIndent, -(buttonOffset + buttonSize) }
	},
	worldmarkers = {
		size = { buttonSize, buttonSize },
		place = { "TOPLEFT", contentIndent + (contentWidth - buttonSize), -(buttonOffset + buttonSize) }
	},
	disbandgroup = {
		size = { contentWidth/2, buttonSize },
		place = { "TOPLEFT", contentIndent, -(buttonOffset + buttonSize + buttonSize) }
	},
	raidcontrol = {
		size = { contentWidth/2, buttonSize },
		place = { "TOPLEFT", contentIndent + (contentWidth/2), -(buttonOffset + buttonSize*2) }
	},
	convert = {
		size = { contentWidth, buttonSize },
		place = { "TOPLEFT", contentIndent, -(buttonOffset + buttonSize*3) }
	},
	raidmarkers = {
		size = { markerSize*4, markerSize*2 },
		place = { "TOPLEFT", contentIndent + (contentWidth - markerSize*4)/2, -markerOffset },
		[1] = {
			size = { markerSize, markerSize },
			place = { "TOPLEFT", 0, 0 },
			disabledSaturation = 0,
			textures = {
				enabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(1),
				highlight = gUI4:GetMedia("Texture", "RaidIconGlowGrid", 64, 64, "Warcraft"):GetGridItem(1),
				disabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(1)
			}
		},
		[2] = {
			size = { markerSize, markerSize },
			place = { "TOPLEFT", markerSize, 0 },
			disabledSaturation = 0,
			textures = {
				enabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(2),
				highlight = gUI4:GetMedia("Texture", "RaidIconGlowGrid", 64, 64, "Warcraft"):GetGridItem(2),
				disabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(2)
			}
		},
		[3] = {
			size = { markerSize, markerSize },
			place = { "TOPLEFT", markerSize*2, 0 },
			disabledSaturation = 0,
			textures = {
				enabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(3),
				highlight = gUI4:GetMedia("Texture", "RaidIconGlowGrid", 64, 64, "Warcraft"):GetGridItem(3),
				disabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(3)
			}
		},
		[4] = {
			size = { markerSize, markerSize },
			place = { "TOPLEFT", markerSize*3, 0 },
			disabledSaturation = 0,
			textures = {
				enabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(4),
				highlight = gUI4:GetMedia("Texture", "RaidIconGlowGrid", 64, 64, "Warcraft"):GetGridItem(4),
				disabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(4)
			}
		},
		[5] = {
			size = { markerSize, markerSize },
			place = { "TOPLEFT", 0, -markerSize },
			disabledSaturation = 0,
			textures = {
				enabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(5),
				highlight = gUI4:GetMedia("Texture", "RaidIconGlowGrid", 64, 64, "Warcraft"):GetGridItem(5),
				disabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(5)
			}
		},
		[6] = {
			size = { markerSize, markerSize },
			place = { "TOPLEFT", markerSize, -markerSize },
			disabledSaturation = 0,
			textures = {
				enabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(6),
				highlight = gUI4:GetMedia("Texture", "RaidIconGlowGrid", 64, 64, "Warcraft"):GetGridItem(6),
				disabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(6)
			}
		},
		[7] = {
			size = { markerSize, markerSize },
			place = { "TOPLEFT", markerSize*2, -markerSize },
			disabledSaturation = 0,
			textures = {
				enabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(7),
				highlight = gUI4:GetMedia("Texture", "RaidIconGlowGrid", 64, 64, "Warcraft"):GetGridItem(7),
				disabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(7)
			}
		},
		[8] = {
			size = { markerSize, markerSize },
			place = { "TOPLEFT", markerSize*3, -markerSize },
			disabledSaturation = 0,
			textures = {
				enabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(8),
				highlight = gUI4:GetMedia("Texture", "RaidIconGlowGrid", 64, 64, "Warcraft"):GetGridItem(8),
				disabled = gUI4:GetMedia("Texture", "RaidIconGrid", 64, 64, "Warcraft"):GetGridItem(8)
			}
		}
	}
}

parent:RegisterTheme("Warcraft", T)