local _, gUI4 = ...

-------------------------------------------------------------------------------
--	Screen Edge Offsets, for automatic/locked placement of frames
-- 	 *well that escalated quickly. whatever happened to "just simple offsets"? 
-------------------------------------------------------------------------------
-- addon messages:
-- 	GUI4_TOP_OFFSET_CHANGED 
-- 	GUI4_BOTTOM_OFFSET_CHANGED  
-- 	GUI4_LEFT_OFFSET_CHANGED 
-- 	GUI4_RIGHT_OFFSET_CHANGED  
-- 	arg1 = totalOffset, arg2 = justify

local minOffset = { TOP = 20, BOTTOM = 20, LEFT = 20, RIGHT = 20 } -- default space from screen edges
local preOffsets = { -- what lies between the actionbars and the minimum offsets
	TOP = { LEFT = {}, CENTER = {}, RIGHT = {} }, 
	BOTTOM = { LEFT = {}, CENTER = {}, RIGHT = {} }, 
	LEFT = { TOP = {}, MIDDLE = {}, BOTTOM = {} }, 
	RIGHT = { TOP = {}, MIDDLE = {}, BOTTOM = {} } 
} 
local offsets = { -- what lies between the preoffsets and the unitframes. typically actionbars and clickable buttons
	TOP = { LEFT = {}, CENTER = {}, RIGHT = {} }, 
	BOTTOM = { LEFT = {}, CENTER = {}, RIGHT = {} }, 
	LEFT = { TOP = {}, MIDDLE = {}, BOTTOM = {} }, 
	RIGHT = { TOP = {}, MIDDLE = {}, BOTTOM = {} } 
} 
local fallbackJustify = { -- default justification if none is given. since I already wrote half an UI without it...
	TOP = "CENTER",
	BOTTOM = "CENTER",
	LEFT = "MIDDLE", 
	RIGHT = "MIDDLE"
}
local function getPreOffset(side, justify)
	if not justify then justify = fallbackJustify[side] end
	local extraOffset = 0
	for _,size in pairs(preOffsets[side][justify]) do
		extraOffset = extraOffset + size
	end
	return extraOffset
end
local function getOffset(side, justify)
	if not justify then justify = fallbackJustify[side] end
	local extraOffset = 0
	for _,size in pairs(offsets[side][justify]) do
		extraOffset = extraOffset + size
	end
	return extraOffset
end
local function setPreOffset(side, element, offset, justify)
	if not justify then justify = fallbackJustify[side] end
	if preOffsets[side][justify][element] == offset then return end
	preOffsets[side][justify][element] = offset
	gUI4:SendMessage("GUI4_PREOFFSET_CHANGED", minOffset[side] + getPreOffset(side, justify), justify, side)
	gUI4:SendMessage("GUI4_OFFSET_CHANGED", minOffset[side] + getPreOffset(side, justify) + getOffset(side, justify), justify, side)
	gUI4:SendMessage("GUI4_"..side.."_OFFSET_CHANGED", minOffset[side] + getPreOffset(side, justify) + getOffset(side, justify), justify)
	gUI4:SendMessage("GUI4_"..side.."_PREOFFSET_CHANGED", minOffset[side] + getPreOffset(side, justify), justify)
end
local function setOffset(side, element, offset, justify)
	if not justify then justify = fallbackJustify[side] end
	if offsets[side][justify][element] == offset then return end
	offsets[side][justify][element] = offset
	gUI4:SendMessage("GUI4_OFFSET_CHANGED", minOffset[side] + getPreOffset(side, justify) + getOffset(side, justify), justify, side)
	gUI4:SendMessage("GUI4_"..side.."_OFFSET_CHANGED", minOffset[side] + getPreOffset(side, justify) + getOffset(side, justify), justify)
end

-- and an element between the edges and the actionbars
function gUI4:SetTopPreOffset(element, offset, justify) setPreOffset("TOP", element, offset, justify) end
function gUI4:SetBottomPreOffset(element, offset, justify) setPreOffset("BOTTOM", element, offset, justify) end
function gUI4:SetLeftPreOffset(element, offset, justify) setPreOffset("LEFT", element, offset, justify) end
function gUI4:SetRightPreOffset(element, offset, justify) setPreOffset("RIGHT", element, offset, justify) end

-- add an element between the actionbars and the unitframes
function gUI4:SetTopOffset(element, offset, justify) setOffset("TOP", element, offset, justify) end
function gUI4:SetBottomOffset(element, offset, justify) setOffset("BOTTOM", element, offset, justify) end
function gUI4:SetLeftOffset(element, offset, justify) setOffset("LEFT", element, offset, justify) end
function gUI4:SetRightOffset(element, offset, justify) setOffset("RIGHT", element, offset, justify) end

-- get complete offsets
function gUI4:GetTopOffset(justify) return minOffset.TOP + getPreOffset("TOP", justify) + getOffset("TOP", justify) end
function gUI4:GetBottomOffset(justify) return minOffset.BOTTOM + getPreOffset("BOTTOM", justify) + getOffset("BOTTOM", justify) end
function gUI4:GetLeftOffset(justify) return minOffset.LEFT + getPreOffset("LEFT", justify) + getOffset("LEFT", justify) end
function gUI4:GetRightOffset(justify) return minOffset.RIGHT + getPreOffset("RIGHT", justify) + getOffset("RIGHT", justify) end

-- get offset from screen edges to actionbars
function gUI4:GetTopPreOffset(justify) return minOffset.TOP + getPreOffset("TOP", justify) end
function gUI4:GetBottomPreOffset(justify) return minOffset.BOTTOM + getPreOffset("BOTTOM", justify) end
function gUI4:GetLeftPreOffset(justify) return minOffset.RIGHT + getPreOffset("LEFT", justify) end
function gUI4:GetRightPreOffset(justify) return minOffset.LEFT + getPreOffset("RIGHT", justify) end

-- get the minimum offset from the screen edges
function gUI4:GetMinimumTopOffset() return minOffset.TOP end
function gUI4:GetMinimumBottomOffset() return minOffset.BOTTOM end
function gUI4:GetMinimumLeftOffset() return minOffset.LEFT end
function gUI4:GetMinimumRightOffset() return minOffset.RIGHT end

local function getSide(msg)
	local isPreOffset
	local side, found = msg:gsub("GUI4_(%a+)_OFFSET_CHANGED", "%1")
	if found == 0 or not found then 
		side, found = msg:gsub("GUI4_(%a+)_PREOFFSET_CHANGED", "%1")
		isPreOffset = true
	end
	return side, isPreOffset
end

-- should have gone with these from the start. oh well. 
-- ToDo: rewrite everything to use them. will do. 
function gUI4:SetOffset(sideOrEvent, element, offset, justify)
	local isPreOffset
	if not(offsets[sideOrEvent]) then
		sideOrEvent, isPreOffset = getSide(sideOrEvent)
	end
	if isPreOffset then 
		self:SetPreOffset(sideOrEvent, element, offset, justify)
		return
	end
	setOffset(sideOrEvent, element, offset, justify)
end
function gUI4:SetPreOffset(sideOrEvent, element, offset, justify)
	local isPreOffset
	if not(preOffsets[sideOrEvent]) then
		sideOrEvent, isPreOffset = getSide(sideOrEvent)
	else
		isPreOffset = true
	end
	if not isPreOffset then 
		self:SetOffset(sideOrEvent, element, offset, justify)
		return
	end
	setPreOffset(sideOrEvent, element, offset, justify)
end 
function gUI4:GetOffset(sideOrEvent, justify)
	local isPreOffset
	if not(offsets[sideOrEvent]) then
		sideOrEvent, isPreOffset = getSide(sideOrEvent)
	end
	if isPreOffset then 
		return self:GetPreOffset(sideOrEvent, justify)
	end
	return minOffset[sideOrEvent] + getPreOffset(sideOrEvent, justify) + getOffset(sideOrEvent, justify)
end
function gUI4:GetPreOffset(sideOrEvent, justify)
	local isPreOffset
	if not(offsets[sideOrEvent]) then
		sideOrEvent, isPreOffset = getSide(sideOrEvent)
	else
		isPreOffset = true
	end
	if not isPreOffset then 
		return self:GetOffset(sideOrEvent, justify)
	end
	return minOffset[sideOrEvent] + getPreOffset(sideOrEvent, justify)
end
function gUI4:GetMinimumOffset(sideOrEvent)
	if not(offsets[sideOrEvent]) then
		sideOrEvent = getSide(sideOrEvent)
	end
	return minOffset[sideOrEvent]
end
