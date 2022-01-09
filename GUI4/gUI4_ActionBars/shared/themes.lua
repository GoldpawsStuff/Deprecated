local ADDON = ...
local GP_LibStub = GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule(ADDON, true)
if not parent then return end

-- Lua API
local _G = _G
local tostring = tostring

-- WoW API
local BOTTOMLEFT_ACTIONBAR_PAGE = BOTTOMLEFT_ACTIONBAR_PAGE
local BOTTOMRIGHT_ACTIONBAR_PAGE = BOTTOMRIGHT_ACTIONBAR_PAGE
local LEFT_ACTIONBAR_PAGE = LEFT_ACTIONBAR_PAGE
local RIGHT_ACTIONBAR_PAGE = RIGHT_ACTIONBAR_PAGE

-- automatic placement of bars, which obeys gUI4s global edge offsets
-- external themes can access this (though I recommend making your own functions) with: 
-- 	local place = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4"):GetModule("gUI4_ActionBars"):GetTheme("Warcraft").place
local function place(id, skinSize)
	id = tostring(id)
	local db = parent:GetActiveTheme()[skinSize or "small"]
	if id == "1" then 
		return "BOTTOM", 0, gUI4:GetBottomPreOffset() + db.backdropOffset -- the extra 11px is the backdrop, which is visible when locked
	elseif id == tostring(BOTTOMLEFT_ACTIONBAR_PAGE) then
		return "BOTTOM", 0, gUI4:GetBottomPreOffset() + db.backdropOffset + db.size + db.padding
	elseif id == tostring(BOTTOMRIGHT_ACTIONBAR_PAGE) then
		return "BOTTOM", 0, gUI4:GetBottomPreOffset() + db.backdropOffset + (db.size + db.padding)*2
	elseif id == tostring(RIGHT_ACTIONBAR_PAGE) then
		return "RIGHT", -gUI4:GetMinimumRightOffset(), -60
	elseif id == tostring(LEFT_ACTIONBAR_PAGE) then
		return "RIGHT", -(gUI4:GetMinimumRightOffset() + db.size + db.padding), -60
	elseif id == "Pet" then
		-- return "BOTTOM", 0, 260 - db.size -- this is always the topmost object in the offset hierarchy
		return "BOTTOM", 0, gUI4:GetBottomOffset() - db.size -- this is always the topmost object in the offset hierarchy
	elseif id == "Stance" then
		return "TOPLEFT", gUI4:GetMinimumLeftOffset(), -gUI4:GetMinimumTopOffset()
	elseif id == "Extra" then
		-- return "TOP", 0, -gUI4:GetMinimumTopOffset() -- also just a placeholder
		return "CENTER", 300, 0
	elseif id == "VehicleExit" then
		return "CENTER", 300, 64 + 20
	elseif id == "Custom" then
		return "CENTER", 128, -64 -- 300, 64 + 20
	elseif id == "Salvage" then
    if skinSize == "large" then
      return "CENTER", 352, -64
    else
      return "CENTER", 256 + 20, -(64 + (64-36)/2)
    end
	elseif id == "XP" then
		return "BOTTOM", 0, gUI4:GetMinimumBottomOffset()
	elseif id == "Artifact" then
		return "BOTTOM", 0, gUI4:GetMinimumBottomOffset()
	elseif id == "Reputation" then
		local showXP = parent:IsXPBarVisible()
		local showArtifact = parent:IsArtifactBarVisible()
		if showXP or showArtifact then
			local db = parent:GetActiveTheme().xp[skinSize or "small"]
			return "BOTTOM", 0, gUI4:GetMinimumBottomOffset() + db.size[2]
		else
			return "BOTTOM", 0, gUI4:GetMinimumBottomOffset()
		end
	end
end

-- function called to set the gUI4 screen offset for the element.
-- by using optional funcs like this, the themes can decide whether or not to fire offset messages
local function setOffset(element, id, skinSize)
	id = tostring(id)
	local db = parent:GetActiveTheme()[skinSize or "small"]
	if id == "1" then 
		gUI4:SetOffset("BOTTOM", element, skinSize and (db.size + db.backdropOffset*2) or 0, "CENTER")
	elseif id == tostring(BOTTOMLEFT_ACTIONBAR_PAGE) then
		gUI4:SetOffset("BOTTOM", element, skinSize and (db.size + db.padding) or 0, "CENTER")
	elseif id == tostring(BOTTOMRIGHT_ACTIONBAR_PAGE) then
		gUI4:SetOffset("BOTTOM", element, skinSize and (db.size + db.padding) or 0, "CENTER")
	elseif id == tostring(RIGHT_ACTIONBAR_PAGE) then
		gUI4:SetOffset("RIGHT", element, skinSize and (db.size + gUI4:GetMinimumRightOffset()) or 0, "MIDDLE")
	elseif id == tostring(LEFT_ACTIONBAR_PAGE) then
		gUI4:SetOffset("RIGHT", element, skinSize and (db.size + db.padding) or 0, "MIDDLE")
	elseif id == "Pet" then
		gUI4:SetOffset("BOTTOM", element, skinSize and (db.size + db.petBarOffset) or 0, "CENTER")
	elseif id == "Stance" then
		gUI4:SetOffset("TOP", element, skinSize and (db.size + db.backdropOffset) or 0, "LEFT")
	elseif id == "Extra" then
		-- gUI4:SetOffset("TOP", element, skinSize and (db.size) or 0, "CENTER")
	elseif id == "VehicleExit" then
	elseif id == "Custom" then
	elseif id == "Salvage" then
	elseif id == "XP" then
		local db = parent:GetActiveTheme().xp[skinSize or "small"]
		gUI4:SetPreOffset("BOTTOM", element, skinSize and (db.offset) or 0, "CENTER")
	elseif id == "Reputation" then
		local db = parent:GetActiveTheme().rep[skinSize or "small"]
		gUI4:SetPreOffset("BOTTOM", element, skinSize and (db.offset) or 0, "CENTER")
	elseif id == "Artifact" then
		local db = parent:GetActiveTheme().rep[skinSize or "small"]
		gUI4:SetPreOffset("BOTTOM", element, skinSize and (db.offset) or 0, "CENTER")
	end
end

parent:RegisterTheme("Warcraft", {
	place = place,
	setOffset = setOffset, 
	positionCallbacks = { -- position updates will be fired for these addon messages
		["1"] = { "GUI4_BOTTOM_PREOFFSET_CHANGED" }, 
		[BOTTOMLEFT_ACTIONBAR_PAGE] = { "GUI4_BOTTOM_PREOFFSET_CHANGED" }, 
		[BOTTOMRIGHT_ACTIONBAR_PAGE] = { "GUI4_BOTTOM_PREOFFSET_CHANGED" }, 
		[RIGHT_ACTIONBAR_PAGE] = { "GUI4_RIGHT_PREOFFSET_CHANGED" }, 
		[LEFT_ACTIONBAR_PAGE] = { "GUI4_RIGHT_PREOFFSET_CHANGED" }, 
		["Pet"] = { "GUI4_BOTTOM_PREOFFSET_CHANGED" }, 
		["Stance"] = { "GUI4_TOP_PREOFFSET_CHANGED" }, 
		["Extra"] = {}, -- "GUI4_TOP_PREOFFSET_CHANGED"
		["VehicleExit"] = {}, 
		["Custom"] = {},
    ["Salvage"] = {}
	},
	positionMessagesToFire	 = { -- position messages will be fired when the relevant modules are moved
		["1"] = { GUI4_BOTTOM_OFFSET_CHANGED = "CENTER" }, 
		[BOTTOMLEFT_ACTIONBAR_PAGE] = { GUI4_BOTTOM_PREOFFSET_CHANGED = "CENTER" }, 
		[BOTTOMRIGHT_ACTIONBAR_PAGE] = { GUI4_BOTTOM_PREOFFSET_CHANGED = "CENTER" }, 
		[RIGHT_ACTIONBAR_PAGE] = { GUI4_RIGHT_PREOFFSET_CHANGED = "MIDDLE" }, 
		[LEFT_ACTIONBAR_PAGE] = { GUI4_RIGHT_PREOFFSET_CHANGED = "MIDDLE" }, 
		["Pet"] = { GUI4_BOTTOM_OFFSET_CHANGED = "CENTER" }, 
		["Stance"] = { GUI4_TOP_OFFSET_CHANGED = "LEFT" }, 
		["Extra"] = {}, -- GUI4_TOP_PREOFFSET_CHANGED = "CENTER" 
		["VehicleExit"] = {}, 
		["Custom"] = {},
    ["Salvage"] = {}
	},
	small = {
		size = 36, -- buttonsize
		padding = 2, -- padding between buttons and bars
		saturation = .75, -- amount of saturation on the spell icons
		backdropOffset = 10, -- offset from backdrop edges to actionbars
		petBarOffset = 10, -- extra offset fed to gUI4:SetBottomOffset() when petbar is enabled
		icon = {
			size = { 26, 26 }, 
			texCoord = { 5/65, 59/64, 5/64, 59/64 },
			place = { "TOPLEFT", 5, -5 }
		},
		normal = gUI4:GetMedia("Button", "Normal", 36, 36, "Warcraft"),
		highlight = gUI4:GetMedia("Button", "Highlight", 36, 36, "Warcraft"),
		-- weaponslot = gUI4:GetMedia("Button", "WeaponSlot", 36, 36, "Warcraft"), 
		-- weaponslothighlight = gUI4:GetMedia("Button", "WeaponSlotHighlight", 36, 36, "Warcraft"), 
		-- bagslot = gUI4:GetMedia("Button", "BagSlot", 36, 36, "Warcraft"), 
		-- bagslothighlight = gUI4:GetMedia("Button", "BagSlotHighlight", 36, 36, "Warcraft"), 
		-- emptyslot = gUI4:GetMedia("Button", "EmptySlot", 36, 36, "Warcraft"), 
		-- emptyslothighlight = gUI4:GetMedia("Button", "EmptySlotHighlight", 36, 36, "Warcraft"), 
		empty = gUI4:GetMedia("Button", "WeaponSlot", 36, 36, "Warcraft"), 
		emptyhighlight = gUI4:GetMedia("Button", "WeaponSlotHighlight", 36, 36, "Warcraft"), 
		checked = gUI4:GetMedia("Button", "Checked", 36, 36, "Warcraft"),
		checkedhighlight = gUI4:GetMedia("Button", "CheckedHighlight", 36, 36, "Warcraft")
	},
	medium = {
		size = 44, 
		padding = 2, 
		saturation = 1, -- amount of saturation on the spell icons
		backdropOffset = 10, -- offset from backdrop edges to actionbars
		petBarOffset = 10, -- extra offset fed to gUI4:SetBottomOffset() when petbar is enabled
		icon = {
			size = { 32, 32 }, 
			texCoord = { 5/65, 59/64, 5/64, 59/64 },
			place = { "TOPLEFT", 6, -6 }
		},
		normal = gUI4:GetMedia("Button", "Normal", 44, 44, "Warcraft"),
		highlight = gUI4:GetMedia("Button", "Highlight", 44, 44, "Warcraft"),
		-- weaponslot = gUI4:GetMedia("Button", "WeaponSlot", 44, 44, "Warcraft"), 
		-- weaponslothighlight = gUI4:GetMedia("Button", "WeaponSlotHighlight", 44, 44, "Warcraft"), 
		-- bagslot = gUI4:GetMedia("Button", "BagSlot", 44, 44, "Warcraft"), 
		-- bagslothighlight = gUI4:GetMedia("Button", "BagSlotHighlight", 44, 44, "Warcraft"), 
		-- emptyslot = gUI4:GetMedia("Button", "EmptySlot", 44, 44, "Warcraft"), 
		-- emptyslothighlight = gUI4:GetMedia("Button", "EmptySlotHighlight", 44, 44, "Warcraft"), 
		empty = gUI4:GetMedia("Button", "WeaponSlot", 44, 44, "Warcraft"), 
		emptyhighlight = gUI4:GetMedia("Button", "WeaponSlotHighlight", 44, 44, "Warcraft"), 
		checked = gUI4:GetMedia("Button", "Checked", 44, 44, "Warcraft"),
		checkedhighlight = gUI4:GetMedia("Button", "CheckedHighlight", 44, 44, "Warcraft")
	},	
	large = {
		size = 64, 
		padding = 4, 
		saturation = .75, -- amount of saturation on the spell icons
		backdropOffset = 10, -- offset from backdrop edges to actionbars
		petBarOffset = 10, -- extra offset fed to gUI4:SetBottomOffset() when petbar is enabled
		icon = {
			size = { 52, 52 }, 
			texCoord = { 5/65, 59/64, 5/64, 59/64 },
			place = { "TOPLEFT", 6, -6 }
		},
		normal = gUI4:GetMedia("Button", "Normal", 64, 64, "Warcraft"),
		highlight = gUI4:GetMedia("Button", "Highlight", 64, 64, "Warcraft"),
		-- weaponslot = gUI4:GetMedia("Button", "WeaponSlot", 64, 64, "Warcraft"), 
		-- weaponslothighlight = gUI4:GetMedia("Button", "WeaponSlotHighlight", 64, 64, "Warcraft"), 
		-- bagslot = gUI4:GetMedia("Button", "BagSlot", 64, 64, "Warcraft"), 
		-- bagslothighlight = gUI4:GetMedia("Button", "BagSlotHighlight", 64, 64, "Warcraft"), 
		-- emptyslot = gUI4:GetMedia("Button", "EmptySlot", 64, 64, "Warcraft"), 
		-- emptyslothighlight = gUI4:GetMedia("Button", "EmptySlotHighlight", 64, 64, "Warcraft"), 
		empty = gUI4:GetMedia("Button", "WeaponSlot", 64, 64, "Warcraft"), 
		emptyhighlight = gUI4:GetMedia("Button", "WeaponSlotHighlight", 64, 64, "Warcraft"), 
		checked = gUI4:GetMedia("Button", "Checked", 64, 64, "Warcraft"),
		checkedhighlight = gUI4:GetMedia("Button", "CheckedHighlight", 64, 64, "Warcraft")
	},
	backdrop = {
		place = function() return "BOTTOM", 0, gUI4:GetMinimumBottomOffset() end, 
		sideplace = function() return "BOTTOM", -gUI4:GetMinimumRightOffset(), 0  end, 
		positionCallbacks = {
			GUI4_BOTTOM_PREOFFSET_CHANGED = true
		},
		small = {
			-- bottom bars
			--------------------------------------------------------------------------------
			-- 1 actionbar
			gUI4:GetMedia("Frame", "Backdrop", 474, 56, "Warcraft"), 
			gUI4:GetMedia("Frame", "Border", 474, 56, "Warcraft"), 
			gUI4:GetMedia("Frame", "Highlight", 474, 56, "Warcraft"), 	-- highlight
			gUI4:GetMedia("Frame", "Backdrop", 474, 56, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Border", 474, 74, "Warcraft"), 		-- xp/rep bar
			gUI4:GetMedia("Frame", "Highlight", 474, 74, "Warcraft"), 	-- xp/rep bar, highlight
			gUI4:GetMedia("Frame", "Backdrop", 474, 56, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Border", 474, 92, "Warcraft"), 		-- xp & rep bars
			gUI4:GetMedia("Frame", "Highlight", 474, 92, "Warcraft"), 	-- xp & rep bars, highlight
			-- 2 actionbars
			gUI4:GetMedia("Frame", "Backdrop", 474, 94, "Warcraft"), 
			gUI4:GetMedia("Frame", "Border", 474, 94, "Warcraft"), 
			gUI4:GetMedia("Frame", "Highlight", 474, 94, "Warcraft"), 	-- highlight
			gUI4:GetMedia("Frame", "Backdrop", 474, 94, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Border", 474, 112, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Highlight", 474, 112, "Warcraft"), 	-- xp/rep bar, highlight
			gUI4:GetMedia("Frame", "Backdrop", 474, 94, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Border", 474, 130, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Highlight", 474, 130, "Warcraft"), 	-- xp & rep bars, highlight
			-- 3 actionbars
			gUI4:GetMedia("Frame", "Backdrop", 474, 132, "Warcraft"), 
			gUI4:GetMedia("Frame", "Border", 474, 132, "Warcraft"), 
			gUI4:GetMedia("Frame", "Highlight", 474, 132, "Warcraft"), 	-- highlight
			gUI4:GetMedia("Frame", "Backdrop", 474, 132, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Border", 474, 150, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Highlight", 474, 150, "Warcraft"), 	-- xp/rep bar, highlight
			gUI4:GetMedia("Frame", "Backdrop", 474, 132, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Border", 474, 168, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Highlight", 474, 168, "Warcraft"), 	-- xp & rep bars, highlight
			-- side bars
			--------------------------------------------------------------------------------
		},
		medium = {
			-- bottom bars
			--------------------------------------------------------------------------------
			-- 1 actionbar
			gUI4:GetMedia("Frame", "Backdrop", 570, 64, "Warcraft"), 
			gUI4:GetMedia("Frame", "Border", 570, 64, "Warcraft"), 
			gUI4:GetMedia("Frame", "Highlight", 570, 64, "Warcraft"), 	-- highlight
			gUI4:GetMedia("Frame", "Backdrop", 570, 64, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Border", 570, 82, "Warcraft"), 		-- xp/rep bar
			gUI4:GetMedia("Frame", "Highlight", 570, 82, "Warcraft"), 	-- xp/rep bar, highlight
			gUI4:GetMedia("Frame", "Backdrop", 570, 64, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Border", 570, 100, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Highlight", 570, 100, "Warcraft"), 	-- xp & rep bars, highlight
			-- 2 actionbars
			gUI4:GetMedia("Frame", "Backdrop", 570, 110, "Warcraft"), 
			gUI4:GetMedia("Frame", "Border", 570, 110, "Warcraft"), 
			gUI4:GetMedia("Frame", "Highlight", 570, 110, "Warcraft"), 	-- highlight
			gUI4:GetMedia("Frame", "Backdrop", 570, 110, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Border", 570, 128, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Highlight", 570, 128, "Warcraft"), 	-- xp/rep bar, highlight
			gUI4:GetMedia("Frame", "Backdrop", 570, 110, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Border", 570, 146, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Highlight", 570, 146, "Warcraft"), 	-- xp & rep bars, highlight
			-- 3 actionbars
			gUI4:GetMedia("Frame", "Backdrop", 570, 156, "Warcraft"), 
			gUI4:GetMedia("Frame", "Border", 570, 156, "Warcraft"), 
			gUI4:GetMedia("Frame", "Highlight", 570, 156, "Warcraft"), 	-- highlight
			gUI4:GetMedia("Frame", "Backdrop", 570, 156, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Border", 570, 174, "Warcraft"), 	-- xp/rep bar
			gUI4:GetMedia("Frame", "Highlight", 570, 174, "Warcraft"), 	-- xp/rep bar, highlight
			gUI4:GetMedia("Frame", "Backdrop", 570, 156, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Border", 570, 192, "Warcraft"), 	-- xp & rep bars
			gUI4:GetMedia("Frame", "Highlight", 570, 192, "Warcraft"), 	-- xp & rep bars, highlight
		}
	},

	xp = {
		small = {
			size = { 474, 19 },
			place = place,
			setOffset = setOffset,
			positionCallbacks = {}, 
			offset = 18, -- extra space added below the actionbars when the xp bar is active
			textures = false,
			statusbar = {
				size = { 462, 7 },
				place = { "TOPLEFT", 6, -6 },
				hitrectinsets = { -6, -6, -6, -6 },
				color = {
					xp = gUI4:GetColors("xp"), 
					restedxp = gUI4:GetColors("restedxp"), 
					restedbonus = gUI4:GetColors("restedbonus")
				},
				texture = gUI4:GetMedia("StatusBar", "Dark", 512, 64, "Warcraft"),
				spark = {
					size = { 16, 7 },
					texture = gUI4:GetMedia("StatusBar", "Spark", 16, 16, "Warcraft")
				},
				tooltip = { 
					point = "BOTTOMLEFT", 
					rpoint = "BOTTOMRIGHT", 
					x = 10, 
					y = 0 
				}
			}
		},
		medium = {
			size = { 570, 19 },
			place = place, 
			setOffset = setOffset,
			positionCallbacks = {}, 
			offset = 18, -- extra space added below the actionbars when the xp bar is active
			textures = false,
			statusbar = {
				size = { 558, 7 },
				place = { "TOPLEFT", 6, -6 },
				hitrectinsets = { -6, -6, -6, -6 },
				color = {
					xp = gUI4:GetColors("xp"), 
					restedxp = gUI4:GetColors("restedxp"), 
					restedbonus = gUI4:GetColors("restedbonus")
				},
				texture = gUI4:GetMedia("StatusBar", "Dark", 512, 64, "Warcraft"),
				spark = {
					size = { 16, 7 },
					texture = gUI4:GetMedia("StatusBar", "Spark", 16, 16, "Warcraft")
				},
				tooltip = { 
					point = "BOTTOMLEFT", 
					rpoint = "BOTTOMRIGHT", 
					x = 10, 
					y = 0 
				}
			}
		}
	},
	rep = {
		small = {
			size = { 474, 19 },
			place = place,
			setOffset = setOffset,
			positionCallbacks = {}, 
			offset = 18, -- extra space added below the actionbars when the rep bar is active
			textures = false,
			statusbar = {
				size = { 462, 7 },
				place = { "TOPLEFT", 6, -6 },
				hitrectinsets = { -6, -6, -6, -6 },
				texture = gUI4:GetMedia("StatusBar", "Dark", 512, 64, "Warcraft"),
				spark = {
					size = { 16, 7 },
					texture = gUI4:GetMedia("StatusBar", "Spark", 16, 16, "Warcraft")
				},
				tooltip = { 
					point = "BOTTOMLEFT", 
					rpoint = "BOTTOMRIGHT", 
					x = 10, 
					y = 0 
				}
			}
		},
		medium = {
			size = { 570, 19 },
			place = place, 
			setOffset = setOffset,
			positionCallbacks = {}, 
			offset = 18, -- extra space added below the actionbars when the xp bar is active
			textures = false,
			statusbar = {
				size = { 558, 7 },
				place = { "TOPLEFT", 6, -6 },
				hitrectinsets = { -6, -6, -6, -6 },
				texture = gUI4:GetMedia("StatusBar", "Dark", 512, 64, "Warcraft"),
				spark = {
					size = { 16, 7 },
					texture = gUI4:GetMedia("StatusBar", "Spark", 16, 16, "Warcraft")
				},
				tooltip = { 
					point = "BOTTOMLEFT", 
					rpoint = "BOTTOMRIGHT", 
					x = 10, 
					y = 0 
				}
			}
		}
	}
})
