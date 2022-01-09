local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Auras", true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local bSlotSize, bSize = 40, 36
local bCols, bRows, rowGap = 12, 3, 8
local dSlotSize, dSize = 32, 28
local dCols, dRows = 12, 3

parent:RegisterTheme("Warcraft", {
	buffs = {
		size = { bSlotSize * bCols, bSlotSize * bRows },
		place = { "TOPRIGHT", -(20 + 20 + 160 + 20 + 20), -(20 + 20) },
		icons = {
			size = bSize - 6,
			texCoord = { 5/64, 59/64, 5/64, 59/64 },
			place = { "TOPLEFT", 2, -2 } -- relative to the scaffold, which is 1px inset into the button
		},
		fonts = {
			time = {
				place = { "TOPLEFT", 1, -1 }, 
				fontObject = GameFontNormalSmall,
				fontStyle = "THINOUTLINE",
				fontSize = 10,
				shadowOffset = { 1.25, -1.25 },
				shadowColor = { 0, 0, 0, 1 }
			},
			count = {
				place = { "BOTTOMRIGHT", -1, 1 }, 
				fontObject = GameFontNormalSmall,
				fontStyle = "THINOUTLINE",
				fontSize = 10,
				shadowOffset = { 1.25, -1.25 },
				shadowColor = { 0, 0, 0, 1 }
			}
		},
		attributes = {
			minWidth = bSlotSize * bCols,
			minHeight = bSlotSize * bRows,
			xOffset = -bSlotSize, 
			wrapAfter = bCols,
			wrapYOffset = -bSlotSize -- -(bSlotSize + timeFontSize + timeGap + rowGap )
		}
	}, 
	consolidation = {
		size = { bSize, bSize },
		place = { "TOPRIGHT", bSlotSize, 0 }, -- relative to the buff frame
		attributes = {
			minWidth = 1 * bSlotSize,
			wrapAfter = 1,
			wrapYOffset = -bSlotSize
		}
	},
	debuffs = {
		size = { dSlotSize * dCols, dSlotSize * dRows },
		place = { "TOPRIGHT", -(20 + 20 + 160 + 20 + 20), -(20 + 20 + (bSlotSize * bRows) + 20) },
		icons = {
			size = dSize - 6,
			texCoord = { 5/64, 59/64, 5/64, 59/64 },
			place = { "TOPLEFT", 2, -2 } -- relative to the scaffold, which is 1px inset into the button
		},
		fonts = {
			time = {
				place = { "TOPLEFT", 1, -1 }, 
				fontObject = GameFontNormalSmall,
				fontStyle = "THINOUTLINE",
				fontSize = 10,
				shadowOffset = { 1.25, -1.25 },
				shadowColor = { 0, 0, 0, 1 }
			},
			count = {
				place = { "BOTTOMRIGHT", -1, 1 }, 
				fontObject = GameFontNormalSmall,
				fontStyle = "THINOUTLINE",
				fontSize = 10,
				shadowOffset = { 1.25, -1.25 },
				shadowColor = { 0, 0, 0, 1 }
			}
		},
		attributes = {
			minWidth = dSlotSize * dCols,
			minHeight = dSlotSize * dRows,
			xOffset = -dSlotSize, 
			wrapAfter = dCols,
			wrapYOffset = -dSlotSize -- -(bSlotSize + timeFontSize + timeGap + rowGap )
		}
	}
})
