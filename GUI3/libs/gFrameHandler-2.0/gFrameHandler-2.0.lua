--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gFrameHandler-2.0", 18
local gFH, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gFH) then return end 

assert(LibStub("gCore-4.0"), MAJOR .. ": Cannot find an instance of gCore-4.0")

local type, tonumber = type, tonumber
local print, gsub = print, gsub
local floor = math.floor
local tinsert, tremove = table.insert, table.remove
local pairs, unpack = pairs, unpack
local setmetatable = setmetatable

local CreateFrame = CreateFrame
local GetScreenHeight = GetScreenHeight
local GetScreenWidth = GetScreenWidth
local InCombatLockdown = InCombatLockdown
local IsLoggedIn = IsLoggedIn

gFH.scheduler = gFH.scheduler or LibStub("gCore-4.0"):NewAddon(MAJOR)
gFH.frame = gFH.frame or CreateFrame("Frame", MAJOR .. "_MasterFrame", UIParent, "SecureHandlerStateTemplate") -- secure parent frame for all anchors
gFH.queue = gFH.queue or {} -- startup and combat queue
gFH.anchors = gFH.anchors or {} -- current anchors
gFH.objects = gFH.objects or {} -- currently managed objects
gFH.defaults = gFH.defaults or {} -- default positions for the managed objects
gFH.groups = gFH.groups or {} -- frame groups for lock/unlock
gFH.objectToGroup = gFH.objectToGroup or {} -- reference table to save us some searching
gFH.objectsByModule = gFH.objectsByModule or {} -- local reference table for each module/addon
gFH.customFuncs = gFH.customFuncs or {} -- custom functions for dropdowns, and their callbacks

local noop = noop or function() end

-- global lock status. 
-- if one or more frames are unlocked, this is 'true'
-- if all are locked, this is 'nil
local UNLOCKED

local anchorFont = SystemFont_Outline
local titleFont = GameFontNormalLarge
local textFont = GameFontNormal

-- localization
local L = {}
do
	-- anchor tooltips
	L["<Left-Click and drag to move the frame>"] = true
	L["<Left-Click+Shift to lock into position>"] = true
	L["<Right-Click for options>"] = true

	-- anchor dropdown menus
	L["Lock"] = true
	L["Center horizontally"] = true
	L["Center vertically"] = true
	L["Cancel current position changes"] = true
	L["Reset to default position"] = true

	-- guide window
	L["Configuration Mode"] = true
	L["Frames are now unlocked for movement."] = true
	L["<Left-Click once to raise a frame to the front>"] = true
	L["<Left-Click and drag to move a frame>"] = true
	L["<Left-Click+Shift to lock a frame into position>"] = true
	L["<Right-Click a frame for additional options>"] = true
	L["<Left-Click to toggle this category>"] = true
	L["<Shift-Click to reset all frames in this category>"] = true
	L["Reset all frames to their default positions"] = true
	L["Cancel all current position changes"] = true
	L["Lock all frames"] = true
	
	-- messages
	L["The frame '%s' is now locked"] = true
	L["The group '%s' is now locked"] = true
	L["All frames '%s' are now locked"] = true
	L["The frame '%s' is now unlocked"] = true
	L["The group '%s' is now unlocked"] = true
	L["All frames are now unlocked"] = true
	L["All frames are now locked"] = true
	L["No registered frames to unlock"] = true	
	L["The group '%s' is empty"] = true
	
	-- can't be bothered with gLocale here YET, so we're faking it
	-- the locales are replaced by gUI™ anyway
	for i,v in pairs(L) do
		if (v == true) then
			L[i] = i
		end
	end
end

--
-- argCheck(value, num[, nobreak], ...)
-- 	@param value <any> the argument to check
-- 	@param num <number> the number of the argument in your function 
-- 	@param nobreak <boolean> optional. if true, then a non-breaking error will fired instead
-- 	@param ... <string,nil> list of argument types. a 'nil' value will be treated as the text 'nil'
local argCheck = function(value, num, ...)
	assert(type(num) == "number", "Bad argument #2 to 'argCheck' (number expected, got " .. type(num) .. ")")
	
	local nobreak, t
	for i = 1, select("#", ...) do
		if (i == 1) and (select(i, ...) == true) then
			nobreak = true
		else
			t = select(i, ...) 
			if (type(value) == t) then return end
		end
	end

	local types = strjoin(", ", ...)
	local name = strmatch(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	
	if (nobreak) then
		geterrorhandler()(("Bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
	else
		error(("Bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Shared Functions
------------------------------------------------------------------------------------------------------------
local round = function(n) return floor(n * 1e5 + .5) / 1e5 end

local getRGBFromHex = function(hex) 
	if (hex:len() ~= 6) then
		error(("Only 6 digit hex numbers are allowed, got '%s' instead"):format(hex), 2)
	end
	return (tonumber(hex:strsub(1,2), 16) or 0)/255, (tonumber(hex:strsub(3,4), 16) or 0)/255, (tonumber(hex:strsub(5,6), 16) or 0)/255
end

local placeTip = function(anchor, isHorizontal)
	GameTooltip:SetOwner(anchor, "ANCHOR_PRESERVE")
	GameTooltip:ClearAllPoints()
	
	if (isHorizontal) then
		if (GetScreenWidth() - anchor:GetRight()) > anchor:GetLeft() then
			GameTooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
		else
			GameTooltip:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -8, 0)
		end
	else
		if (GetScreenHeight() - anchor:GetTop()) > anchor:GetBottom() then
			GameTooltip:SetPoint("BOTTOM", anchor, "TOP", 0, 8)
		else
			GameTooltip:SetPoint("TOP", anchor, "BOTTOM", 0, -8)
		end
	end
end

--
-- Attempting to make the display names more readable
-- Will have to work a bit on this one
--
-- My search patterns suck, I really need to update my skills there a bit
local tchelper = function(first, rest) return first:upper() .. rest:lower() end
local getName = function(object)
	if not(object.GetName) or not(object:GetName()) or (object:GetName() == "") then return end
	
	local name = object:GetName()
	
	-- remove clutter
	name = gsub(name, "(GUIS_ActionBar_%d+_)", "ActionBar ")
	name = gsub(name, "(oUF_)", "")
	name = gsub(name, "(oUF)", "")
	name = gsub(name, "(GUIS)", "")
	name = gsub(name, "(gUI_)", "")
	name = gsub(name, "(gUI)", "")
	name = gsub(name, "(gUI™)", "")
	name = gsub(name, "(: )", "")
	name = gsub(name, "(:)", "")
	name = gsub(name, "(-)", " ")
	name = gsub(name, "(_)", " ")
	
	while (name:find("  ")) do name = gsub(name, "  ", " ") end -- shrink spaces

	name = gsub(name, "(%l)(%u)", function(l, u) return l .. " " .. u end) -- separate words
	name = gsub(name, "(%a)([%w_']*)", tchelper) -- capitalize each word
	
	return name
end

local doCustomCalls = function(object, method)
	if (gFH.customFuncs[object]) then
		for msg, info in pairs(gFH.customFuncs[object]) do
			if (info[method]) then
				info[method](object)
			end
		end
	end
end

-- anchor and context menus
local firstCustomIndex = 6 -- where custom menu options will be inserted
do
	local hitRect, clampRect = -8, -8
	local defaultR, defaultG, defaultB = 1, 1, 1
	local hoverAlpha, noHoverAlpha = 4/5, 2/3
	local numAnchors = 0
	createAnchor = function(object, name)
		if (gFH.anchors[object]) then
			return gFH.anchors[object] -- return existing anchor if we have one
		end
		
		numAnchors = numAnchors + 1

		-- create the anchor frame
		local anchor = CreateFrame("Frame", nil, gFH.frame)
		anchor:Hide()
		anchor:SetFrameStrata("DIALOG")
		anchor:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
		anchor:SetHitRectInsets(hitRect, hitRect, hitRect, hitRect)
		anchor:SetClampRectInsets(clampRect, clampRect, clampRect, clampRect)
		anchor:SetClampedToScreen(false) -- this would screw up multimonitor setups
		anchor:EnableMouse(true)
		anchor:SetMovable(true)
		anchor:SetUserPlaced(true)
		anchor:RegisterForDrag("LeftButton")
		anchor.object = object
		anchor.name = name or getName(object) or ""

		-- visible title
		local title = anchor:CreateFontString(nil, "OVERLAY")
		title:SetPoint("CENTER", anchor, "CENTER")
		title:SetFontObject(anchorFont)
		title:SetText(anchor.name)
		title:SetTextColor(1, 1, 1, 1)
		anchor.title = title
		
		-- damn dropdowns must have a framename
		-- ToDo: write a better dropdown library
		local dropName = MAJOR .. "_Anchor_" .. numAnchors .. "-" .. anchor.name .. "_DropDown"
		anchor.dropdown = CreateFrame("Frame", dropName, anchor, "UIDropDownMenuTemplate")
		anchor.menu = {
			{ -- 1
				text = L["Lock"];
				notCheckable = true;
				func = function() 
					gFH:LockObjectPosition(anchor.object) 
				end;
			};
			{ text = "", notCheckable = true; func = noop }; -- 2
			{ -- 3
				text = L["Center horizontally"];
				notCheckable = true;
				func = function() 
					gFH:CenterObjectHorizontally(anchor.object)
					anchor:Update()
				end;
			};
			{ -- 4
				text = L["Center vertically"];
				notCheckable = true;
				func = function()
					gFH:CenterObjectVertically(anchor.object)
					anchor:Update()
				end;
			};
			{ text = "", notCheckable = true; func = noop }; -- 5
			{ -- 6 + ((numCustom) and (numCustom + 1) or 0)
				text = L["Reset to default position"];
				notCheckable = true;
				func = function() 
					-- gFH:ResetObjectToDefaultPosition(anchor.object) -- this will save the position as well
					gFH:SetObjectPosition(anchor.object, gFH:GetDefaultObjectPosition(anchor.object)) -- defaults are unscaled
					doCustomCalls(anchor.object, "reset")
					anchor:Update()
				end;
			};
			{ -- 7
				text = L["Cancel current position changes"];
				notCheckable = true;
				func = function() 
					gFH:ResetObjectToSavedPosition(anchor.object) 
					doCustomCalls(anchor.object, "cancel")
					anchor:Update()
				end;
			};
		}
		
		anchor.Update = function(self)
			self:SetSize(self.object:GetSize())
			self:ClearAllPoints()
			self:SetPoint(gFH:GetObjectPosition(self.object))
			-- gFH:SetObjectPosition(self.object, gFH:GetObjectPosition(self.object))
			
			if (self.group) and (gFH.groups[self.group]) then
				if (gFH.groups[self.group].fontObject) and (gFH.groups[self.group].fontObject ~= self.title:GetFontObject()) then
					self.title:SetFontObject(gFH.groups[self.group].fontObject)
				end
				self.r = gFH.groups[self.group].r
				self.g = gFH.groups[self.group].g
				self.b = gFH.groups[self.group].b
			else
				self.r = defaultR
				self.g = defaultG
				self.b = defaultB
			end
			self:SetBackdropColor(self.r, self.g, self.b, MouseIsOver(self, hitRect, hitRect, hitRect, hitRect) and hoverAlpha or noHoverAlpha)
			doCustomCalls(self.object, "update")
		end

		anchor:SetScript("OnShow", function(self) 
			doCustomCalls(self.object, "show")
			self.oldPosition = { gFH:GetSavedObjectPosition(self.object) }
			self:Update()
			self:SetFrameLevel(50)
		end)
		
		anchor:SetScript("OnHide", function(self)
			-- only store position if the parent frame still is visible
			-- if it's hidden, it was interrupted by combat, 
			-- and we need to keep the saved and old positions!
			if (gFH.frame:IsShown()) then
				doCustomCalls(self.object, "hide")
				gFH:SetSavedObjectPosition(self.object, gFH:GetObjectPosition(self))
				self.oldPosition = nil
			end
		end)
		
		-- tooltip and hover
		anchor:SetScript("OnEnter", function(self) 
			self:SetBackdropColor(self.r, self.g, self.b, hoverAlpha)
			placeTip(self)
			GameTooltip:AddLine(self.title:GetText(), 1, 1, 1)
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["<Left-Click and drag to move the frame>"])
			GameTooltip:AddLine(L["<Left-Click+Shift to lock into position>"])
			GameTooltip:AddLine(L["<Right-Click for options>"])
			GameTooltip:Show()
		end)

		anchor:SetScript("OnLeave", function(self) 
			self:SetBackdropColor(self.r, self.g, self.b, noHoverAlpha)
			GameTooltip:Hide()
		end)
		
		anchor:SetToplevel(true)
		anchor:SetScript("OnMouseDown", function(self, button) 
			if (button == "LeftButton") then
				if (IsShiftKeyDown()) then
					gFH:LockObjectPosition(self.object)
				end
			elseif (button == "RightButton") then
				EasyMenu(self.menu, self.dropdown, "cursor", 0, 0, "MENU", 2)
			end
		end)

		anchor:SetScript("OnDragStart", function(self)
			self:StartMoving()
			self.oldAlpha = self.object:GetAlpha()
			self.object:SetAlpha(0)
		end)

		anchor:SetScript("OnDragStop", function(self) 
			self:StopMovingOrSizing()
			-- gFH:SetObjectPosition(self.object, gFH:GetObjectPosition(self)) -- keep it safe
			self.object:ClearAllPoints()
			self.object:SetPoint(gFH:GetObjectPosition(self)) -- keep it safe
			self.object:SetAlpha(self.oldAlpha)
			self.oldAlpha = nil
		end)
	
		gFH.anchors[object] = anchor

		return gFH.anchors[object]
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Library API (not embedded)
------------------------------------------------------------------------------------------------------------
gFH.RestoreAllSavedPositions = function(self)
	for object, position in pairs(self.objects) do
		self:SetObjectPosition(object, unpack(position))
	end
end

gFH.ClearAllSavedPositions = function(self)
	-- and we'll be needing this... when?
end

-- our complete cop out; 
-- we simply hand the whole localization table to whomever asks...
gFH.GetLocale = function(self) return L end

gFH.AddMessage = function(self, msg, r, g, b)
	if (msg) then
		UIErrorsFrame:AddMessage(msg, r or 1, g or 1, b or 1)
	end
end

-- guide window
-- do not create until needed
gFH.OpenGuide = function(self)
	self:GetGuideWindow():Show()
	self:GetGuideWindow():Update()
end

gFH.CloseGuide = function(self)
	if (self.guide) and (self.guide:IsShown()) then
		self.guide:Hide()
	end
end

-- callback to update guide visibility
gFH.UpdateGuide = function(self)
	if (UNLOCKED) then
		self:OpenGuide()
	else
		self:CloseGuide()
	end
end

-- returns the guide window, creates it if it doesn't exist
gFH.GetGuideWindow = function(self)
	if not(self.guide) then
	
		local guide = CreateFrame("Frame", nil, gFH.frame); guide:Hide()
		guide:SetSize(50, 50) -- initial size. will be adjusted by content
		guide:SetPoint("TOP", "UIParent", "TOP", 0, -75)
		guide:SetFrameStrata("DIALOG")
		guide:SetToplevel(true)
		guide:EnableMouse(true)
		guide:SetClampedToScreen(true)
		guide:SetMovable(true)
		guide:SetUserPlaced(true)
		guide:RegisterForDrag("LeftButton")
		guide:SetScript("OnDragStart", function(self) self:StartMoving() end)
		guide:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
		guide:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background";
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Background";
			edgeSize = 2;
		})
		guide:SetBackdropBorderColor(0, 0, 0, 1)
		guide:SetBackdropColor(0, 0, 0, 0.75)
		
		local title = guide:CreateFontString(nil, "ARTWORK")
		title:SetFontObject(titleFont) 
		title:SetText(L["Configuration Mode"])
		title:SetTextColor(1, 0.82, 0)
		title:SetPoint("TOP", 0, -20)
		guide.title = title
		
		local color = function(hexCol, msg) return "|cFF" .. hexCol .. msg .. "|r" end
		guide.color = color
		
		local description = {}
		description[1] = guide:CreateFontString(nil, "ARTWORK")
		description[1]:SetFontObject(textFont) 
		description[1]:SetTextColor(1, 1, 1)
		description[1]:SetPoint("TOP", title, "BOTTOM", 0, -12)
		description[1]:SetText(L["Frames are now unlocked for movement."])
		
		local groupHolder = CreateFrame("Frame", nil, guide)
		groupHolder:SetSize(1, 1)
		groupHolder:SetPoint("TOP", description[1], "BOTTOM", 0, -10)
		guide.groupHolder = groupHolder

		description[2] = guide:CreateFontString(nil, "ARTWORK")
		description[2]:SetFontObject(textFont) 
		description[2]:SetTextColor(1, 1, 1)
		description[2]:SetPoint("TOP", groupHolder, "BOTTOM", 0, -10)
		description[2]:SetText(color("00FF00", L["<Left-Click once to raise a frame to the front>"]))

		description[3] = guide:CreateFontString(nil, "ARTWORK")
		description[3]:SetFontObject(textFont) 
		description[3]:SetTextColor(1, 1, 1)
		description[3]:SetPoint("TOP", description[2], "BOTTOM", 0, -2)
		description[3]:SetText(color("00FF00", L["<Left-Click and drag to move a frame>"]))

		description[4] = guide:CreateFontString(nil, "ARTWORK")
		description[4]:SetFontObject(textFont) 
		description[4]:SetTextColor(1, 1, 1)
		description[4]:SetPoint("TOP", description[3], "BOTTOM", 0, -2)
		description[4]:SetText(color("00FF00", L["<Left-Click+Shift to lock a frame into position>"]))

		description[5] = guide:CreateFontString(nil, "ARTWORK")
		description[5]:SetFontObject(textFont) 
		description[5]:SetTextColor(1, 1, 1)
		description[5]:SetPoint("TOP", description[4], "BOTTOM", 0, -2)
		description[5]:SetText(color("00FF00", L["<Right-Click a frame for additional options>"]))

		guide.description = description
		
		local getButton = function(tooltip)
			local b = CreateFrame('CheckButton', nil, guide)
			b:SetSize(120, 25)
			b:SetBackdrop({ 
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground"; 
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground";
				edgeSize = 1
			})
			b:SetBackdropBorderColor(0, 0, 0, 1)
			b:SetBackdropColor(0, 0, 0, 0.5)
			b:SetNormalFontObject(textFont)
			b:SetHighlightFontObject(textFont)
			b:SetDisabledFontObject(textFont)
			b:SetHighlightTexture("")
			b:SetScript("OnEnter", function(self)
				self:SetBackdropBorderColor(0.55, 0.55, 0.55)
				self:SetBackdropColor(0.25, 0.25, 0.25)
				placeTip(self)
				GameTooltip:AddLine(tooltip)
				GameTooltip:Show()
			end)
			b:SetScript("OnLeave", function(self) 
				self:SetBackdropBorderColor(0.15, 0.15, 0.15)
				self:SetBackdropColor(0, 0, 0)
				GameTooltip:Hide() 
			end)
			return b
		end
		
		local okay = getButton(L["Lock all frames"])
		okay:SetPoint("BOTTOMRIGHT", -20, 20)
		okay:SetText(OKAY)
		okay:SetScript("OnClick", function() 
			for object, anchor in pairs(gFH.anchors) do
				if (anchor:IsShown()) then
					anchor:Hide()
				end
			end
			gFH:CloseGuide()
		end)
		guide.okay = okay
		
		local cancel = getButton(L["Cancel all current position changes"])
		cancel:SetPoint("BOTTOMLEFT", 20, 20)
		cancel:SetText(CANCEL)
		cancel:SetScript("OnClick", function() 
			for object, anchor in pairs(gFH.anchors) do
				if (anchor:IsShown()) then
					gFH:ResetObjectToSavedPosition(anchor.object) 
					doCustomCalls(object, "cancel")
					anchor:Update()
				end
			end
		end)
		guide.cancel = cancel

		local reset = getButton(L["Reset all frames to their default positions"])
		reset:SetPoint("BOTTOM", 0, 20)
		reset:SetText(RESET)
		reset:SetScript("OnClick", function() 
			for object, anchor in pairs(gFH.anchors) do
				if (anchor:IsShown()) then
					gFH:SetObjectPosition(anchor.object, gFH:GetDefaultObjectPosition(anchor.object)) -- need SetObject because default pos is unscaled
					doCustomCalls(object, "reset")
					anchor:Update()
				end
			end
		end)
		guide.reset = reset

		-- update groups and status
		local update = function(self)
			-- calculate and update window size
			local width = 0
			width = max(width, self.title:GetStringWidth())
			for i = 1, #self.description do
				width = max(width, self.description[i]:GetStringWidth())
			end
			width = max(width, self.okay:GetWidth() + self.reset:GetWidth() + self.cancel:GetWidth() + 40)
			
			-- resize strings
			self.title:SetWidth(width)
			for i = 1, #self.description do
				self.description[i]:SetWidth(width)
			end
			
			if not(self.groups) then
				self.groups = {}
			end
			
			local r, g, b, name, group, fontObject
			for name, group in pairs(gFH.groups) do
				r, g, b = gFH:GetFrameGroupColor(name)
				local makeGroup
				for object,enabled in pairs(group.objects) do
					if (enabled) then
						makeGroup = true
					end
				end
				if (makeGroup) then
					if not(self.groups[name]) then
						local group = group
						local anchorFont = group.fontObject or anchorFont
						local name, r, g, b = name, r, g, b
						local new = CreateFrame('CheckButton', nil, guide) --'OptionsButtonTemplate'
						new:SetText("|cFFFFFFFF" .. group.name or name .. "|r")
						new:SetBackdrop({ 
							bgFile = "Interface\\ChatFrame\\ChatFrameBackground"; 
							edgeFile = "Interface\\ChatFrame\\ChatFrameBackground";
							edgeSize = 1;
						})
						new:SetBackdropBorderColor(0, 0, 0, 1)
						new:SetBackdropColor(r, g, b, 0.75)
						new:SetNormalFontObject(anchorFont)
						new:SetHighlightFontObject(anchorFont)
						new:SetDisabledFontObject(anchorFont)
						new:SetHighlightTexture("")
						new:SetSize(self.okay:GetWidth(), (select(2, anchorFont:GetFont())) * 2.5)
						new:SetScript("OnClick", function(self) 
							if (IsShiftKeyDown()) then
								local anchor, object, enabled
								for object, enabled in pairs(group.objects) do
									anchor = gFH.anchors[object]
									if (anchor) and (anchor:IsShown()) then
										gFH:SetObjectPosition(anchor.object, gFH:GetDefaultObjectPosition(anchor.object)) -- need SetObject since default pos is unscaled
										anchor:Update()
									end
								end
							else
								gFH:ToggleObjectPositionLock(name) 
							end
						end)
						new:SetScript("OnEnter", function(self)
							placeTip(self)
							GameTooltip:AddLine(self:GetText(), 1, 1, 1)
							if (group.desc) then 
								if (group.desc:find("|r")) then
									local many = { gFH.scheduler:Split("(|r)", group.desc) } -- gCore's Split supports patterns and all
									for i = 1, #many do
										GameTooltip:AddLine(many[i])
									end
								else
									GameTooltip:AddLine(group.desc)
								end
							end
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine(self:GetParent().color("00FF00", L["<Left-Click to toggle this category>"]))
							GameTooltip:AddLine(self:GetParent().color("00FF00", L["<Shift-Click to reset all frames in this category>"]))
							GameTooltip:Show()
						end)
						new:SetScript("OnLeave", function(self)
							GameTooltip:Hide()
						end)
						self.groups[name] = new
						tinsert(self.groups, 1, new)
					end
					local anchor, object, enabled, active
					for object, enabled in pairs(group.objects) do
						anchor = gFH.anchors[object]
						if (anchor) and (anchor:IsShown()) then
							active = true
						end
					end
					if (active) then
						self.groups[name]:SetAlpha(3/4)
					else
						self.groups[name]:SetAlpha(1/4)
					end
				end
			end
			
			-- arrange buttons
			local prev = self.groupHolder
			local bWidth = 0
			for i = 1, #self.groups do 
				bWidth = max(bWidth, self.groups[i]:GetTextWidth() + 40)
			end 
			for i = 1, #self.groups do
				group = self.groups[i]
				group:ClearAllPoints()
				self.groups[i]:SetWidth(bWidth) 
				if (i == 1) then
					group:SetPoint("TOP", prev, "TOP", 0, 0)
				elseif (i%3 == 2) then
					group:SetPoint("RIGHT", prev, "LEFT", -8, 0)
				elseif (i%3 == 0) then
					group:SetPoint("LEFT", prev, "RIGHT", 16 + prev:GetWidth(), 0)
				elseif (i%3 == 1) then
					group:SetPoint("TOPRIGHT", prev, "BOTTOMLEFT", -8, -8)
				end
				prev = group
			end
			
			local top = self.groupHolder:GetTop()
			local bottom = prev:GetBottom() 
			
			self.groupHolder:SetHeight(top-bottom)

			-- resize window
			self:SetWidth(max(width + 40, bWidth*3 + 8*2 + 40))
			self:SetHeight(self:GetTop() - self.description[#self.description]:GetBottom() + 20*2 + self.reset:GetHeight())
		end
		guide.Update = update
		
		guide:HookScript("OnShow", function(self) 
			self:Update()
			gFH.scheduler:FireCallback("GFH_GUIDE_WINDOW_SHOWN") 
		end)
		guide:HookScript("OnHide", function(self) gFH.scheduler:FireCallback("GFH_GUIDE_WINDOW_HIDDEN") end)

		self.guide = guide
	end
	self.guide:Update()
	return self.guide
end

------------------------------------------------------------------------------------------------------------
-- 	Embedded API for addons/modules
------------------------------------------------------------------------------------------------------------
--
-- combines ClearAllPoints and SetPoint, but taint-free
-- :SetObjectPosition(object, point, anchor, rpoint, x, y)
-- 	@return <table> pointer to the table with the saved position for this object
gFH.SetObjectPosition = function(self, object, ...)
	argCheck(object, 1, "table")

	if (InCombatLockdown()) then
		tinsert(gFH.queue, { object, ... })
	else
		-- we need to break down this, and retrieve the separate values,
		-- because otherwise objects will get out of sync when the uiscale or windowsize changes!
		
		local useScale = tonumber(GetCVar("useUiScale")) == 1
		if (useScale) then
			
			local points = { ... }
			local point, parent, rpoint, x, y
			
			if (#points == 1) then
				point = points[1]
				parent = "UIParent"
				rpoint = points[1]
				x = 0
				y = 0
			elseif (#points == 3) then
				point = points[1]
				parent = "UIParent"
				rpoint = points[1]
				x = points[2]
				y = points[3]
			elseif (#points == 4) then
				point = points[1]
				parent = "UIParent"
				rpoint = points[2]
				x = points[3]
				y = points[4]
			elseif (#points == 5) then
				point = points[1]
				parent = points[2]
				rpoint = points[3]
				x = points[4]
				y = points[5]
			end
			
			local UIScale = UIParent:GetEffectiveScale()
			local objectScale = object:GetEffectiveScale()
			local mult = UIScale / objectScale
			
			object:ClearAllPoints()
			object:SetPoint(point, "UIParent", rpoint, round(x * mult), round(y * mult))
			return
			
		else
			object:ClearAllPoints()
			object:SetPoint(...)
			return
		end
	end
end

gFH.GetScaledPosition = function(self, object, ...)
end

gFH.GetUnscaledPosition = function(self, object, ...)
end

--
-- returns 'real' position
gFH.GetObjectPosition = function(self, object)
	argCheck(object, 1, "table")

	local UIcenterX, UIcenterY = UIParent:GetCenter()
	local objectX, objectY = object:GetCenter()

	if not(objectX) then return end

	local UIScale = UIParent:GetEffectiveScale()
	local objectScale = object:GetEffectiveScale()

	local UIWidth, UIHeight = UIParent:GetRight(), UIParent:GetTop()

	-- 25% of the screen is considered left, 50% center, 25% right
	-- 25% is considered top, 50% middle, 25% bottom
	--
	-- was initially 33.33%, but due to some of the actionbars getting out of sync on small screens in windowed mode, 
	-- we lowered it to 25% to have them in the clear. 
	local LEFT = UIWidth * 1/4 
	local RIGHT = UIWidth * 3/4
	local BOTTOM = UIHeight * 1/4
	local TOP = UIHeight * 3/4

	local point, x, y
	if (objectX >= RIGHT) then
		point = "RIGHT"
		x = object:GetRight() - UIWidth
	elseif (objectX <= LEFT) then
		point = "LEFT"
		x = object:GetLeft()
	else
		x = objectX - UIcenterX
	end

	if (objectY >= TOP) then
		point = "TOP" .. (point or "")
		y = object:GetTop() - UIHeight
	elseif (objectY <= BOTTOM) then
		point = "BOTTOM" .. (point or "")
		y = object:GetBottom()
	else
		y = objectY - UIcenterY
	end
	
	if not(point) then 
		point = "CENTER" 
	end

	local useScale = tonumber(GetCVar("useUiScale")) == 1
	if (useScale) then
		return point, "UIParent", point, round(x * (UIScale / objectScale)),  round(y * (UIScale / objectScale))
	else
		return point, "UIParent", point, x, y
	end
end

gFH.CenterObject = function(self, object)
	self:SetObjectPosition(object, "CENTER", "UIParent", "CENTER", 0, 0) -- unscaled position, but strictly irrelevant since it's in dead center
end

gFH.CenterObjectHorizontally = function(self, object)
	local UIcenterX, UIcenterY = UIParent:GetCenter()
	local objectX, objectY = object:GetCenter()
	if not(objectX) then return end
	local scale = UIParent:GetEffectiveScale() / object:GetEffectiveScale()
	-- self:SetObjectPosition(object, "CENTER", "UIParent", "CENTER", 0,  round((objectY-UIcenterY) * scale))
	self:SetObjectPosition(object, "CENTER", "UIParent", "CENTER", 0,  objectY-UIcenterY) -- need to keep it unscaled with SetObject
end

gFH.CenterObjectVertically = function(self, object)
	local UIcenterX, UIcenterY = UIParent:GetCenter()
	local objectX, objectY = object:GetCenter()
	if not(objectX) then return end

	local scale = UIParent:GetEffectiveScale() / object:GetEffectiveScale()

	-- self:SetObjectPosition(object, "CENTER", "UIParent", "CENTER", round((objectX-UIcenterX) * scale), 0)
	self:SetObjectPosition(object, "CENTER", "UIParent", "CENTER", objectX-UIcenterX, 0) -- need to keep it unscaled with SetObject
end

gFH.SetSavedObjectPosition = function(self, object, ...)
	argCheck(object, 1, "table")
	if (gFH.objects[object]) then
		wipe(gFH.objects[object]) 
	else
		gFH.objects[object] = {}
	end
	local p
	if (...) then
		for i = 1, select("#", ...) do 
			p = select(i, ...)
			if (type(p) == "table") then
				p = p:GetName() or p -- attempt to store name instead of the frame
			end
			gFH.objects[object][i] = p
		end
	else
		local a, b, c, d, e = self:GetObjectPosition(object)
		gFH.objects[object][1] = a
		gFH.objects[object][2] = b
		gFH.objects[object][3] = c
		gFH.objects[object][4] = d
		gFH.objects[object][5] = e
	end
	return gFH.objects[object]
end

gFH.GetSavedObjectPosition = function(self, object)
	argCheck(object, 1, "table")
	if ((gFH.objects[object])) then
		return unpack(gFH.objects[object])
	end
end

gFH.SetSavedObjectPositionTable = function(self, object, tbl)
	argCheck(object, 1, "table")
	argCheck(tbl, 2, "table")
	gFH.objects[object] = tbl
	return gFH.objects[object]
end

gFH.GetSavedObjectPositionTable = function(self, object)
	argCheck(object, 1, "table")
	return gFH.objects[object]
end

gFH.SetDefaultObjectPosition = function(self, object, ...)
	argCheck(object, 1, "table")
	if not(gFH.defaults[object]) then 
		gFH.defaults[object] = {}
	end
	for i = 1, select("#", ...) do 
		p = select(i, ...)
		if (type(p) == "table") then
			p = p:GetName() or p -- attempt to store name instead of the frame
		end
		gFH.defaults[object][i] = p
	end
end

gFH.GetDefaultObjectPosition = function(self, object)
	argCheck(object, 1, "table")
	if (gFH.defaults[object]) then
		return unpack(gFH.defaults[object])
	end
end

gFH.IsObjectInDefaultPosition = function(self, object)
	argCheck(object, 1, "table")
end

gFH.IsObjectInSavedPosition = function(self, object)
	argCheck(object, 1, "table")
end

gFH.ObjectHasSavedPosition = function(self, object)
	argCheck(object, 1, "table")
	return (gFH.objects[object]) and (#gFH.objects[object] > 0)
end

gFH.ObjectHasDefaultPosition = function(self, object)
	argCheck(object, 1, "table")
	return (gFH.defaults[object]) and (#gFH.defaults[object] > 0)
end

gFH.CreateObjectAnchor = function(self, object, name)
	argCheck(object, 1, "table")
	argCheck(name, 2, "string", "nil")
	return createAnchor(object, name)
end

--
-- adds a custom function to the anchor right-click menu
-- 	*inserted in reverse order, the last you register will appear first
--
-- :AddCustomFunctionToObjectAnchor(object, msg, func[, choices, showCallback, resetCallback, cancelCallback])
-- 	@param object <table> the object in question
-- 	@param msg <string> the message to display in the dropdown entry
-- 	@param func <function> to function to be called with arguments (object[, selection])
-- 	@param choices <table, nil> table of entries for a 2nd level dropdown. Selection (starting from 1) will be passed to func(object, selectionID)
-- 	@param showCallback <function, nil> function to call when object anchor is shown, and the object unlocked. 'object' is passed as arg 
-- 	@param resetCallback <function, nil> function to call when the object is reset to default position. 'object' is passed as arg 
-- 	@param cancelCallback <function, nil> function to call when the changes are cancelled. 'object' is passed as arg 
-- 	@param updateCallback <function, nil> function to call when the anchor updates. 'object' is passed as arg 
-- 	@param hideCallback <function, nil> function to call when the frame is locked. 'object' is passed as arg 
gFH.AddCustomFunctionToObjectAnchor = function(self, object, msg, func, choices, showCallback, resetCallback, cancelCallback, updateCallback, hideCallback)
	argCheck(object, 1, "table")
	argCheck(msg, 2, "string")
	argCheck(func, 3, "function")
	argCheck(choices, 3, "table", "nil")
	argCheck(showCallback, 4, "function", "nil")
	argCheck(resetCallback, 5, "function", "nil")
	argCheck(cancelCallback, 6, "function", "nil")

	if not(gFH.anchors[object]) then
		error("Object has no anchor yet!", 2)
	end
	
	if not(gFH.anchors[object].customFunctions) then
		gFH.anchors[object].customFunctions = 0
		
		-- insert a space AFTER the custom functions
		tinsert(gFH.anchors[object].menu, firstCustomIndex, { text = "", notCheckable = true; func = noop })
	end

	if not(gFH.customFuncs[object]) then
		gFH.customFuncs[object] = {}
	end
	
	gFH.customFuncs[object][msg] = {
		func = func;
		show = showCallback;
		reset = resetCallback;
		cancel = cancelCallback;
		update = updateCallback;
		hide = hideCallback;
	}
	
	if (choices) then
		local entry = {
			text = msg;
			notCheckable = true; 
			hasArrow = true;
			menuList = {};
		}
		for i = 1, #choices do
			argCheck(choices[i], i, "string")
			
			local index = i
			tinsert(entry.menuList, {
				text = choices[index];
				notCheckable = true; 
				func = function()
					func(object, index) -- call the provided function, passing the frame and selectionID as the arguments
					gFH.anchors[object]:Update() -- update anchor
				end;
			})
		end
		tinsert(gFH.anchors[object].menu, firstCustomIndex, entry)
	else
		tinsert(gFH.anchors[object].menu, firstCustomIndex, {
			text = msg;
			notCheckable = true; 
			func = function() 
				func(object) -- call the provided function, passing the frame as the argument
				gFH.anchors[object]:Update() -- update anchor
			end;
		})
	end
	gFH.anchors[object].customFunctions = gFH.anchors[object].customFunctions + 1
end

do
	-- updates the lock status of all objects and groups
	local updateAllLocks = function()
		UNLOCKED = nil 

		-- check groups
		for name, group in pairs(gFH.groups) do
			gFH.groups[name].UNLOCKED = nil 
			for object,_ in pairs(group.objects) do
				if (gFH.anchors[object]:IsShown()) then
					gFH.groups[name].UNLOCKED = true
					UNLOCKED = true 
					break
				end
			end
		end
		
		-- check single items if the listed groups all were locked
		-- this doesn't happen in gUI v3 since all objects are in groups there, but it is still possible
		if not(UNLOCKED) then
			for object,anchor in pairs(gFH.anchors) do
				if not(group) or (anchor.group == group) then
					if (anchor:IsShown()) then
						UNLOCKED = true
						break
					end
				end
			end
		end
		
		gFH:UpdateGuide() 
	end

	gFH.UnlockObjectPosition = function(self, objectOrGroup)
		argCheck(objectOrGroup, 1, "table", "string", "nil")
		
		updateAllLocks() 

		-- unlock single object
		if (type(objectOrGroup) == "table") then
			if not(gFH.anchors[objectOrGroup]) then
				error("Object has no anchor yet!", 2)
			end
			gFH.anchors[objectOrGroup]:Show()
			gFH:AddMessage((L["The frame '%s' is now unlocked"]):format(gFH.anchors[objectOrGroup].name), 1, 0.1, 0.1)
			updateAllLocks()
			
		-- unlock group 
		elseif (type(objectOrGroup) == "string") then
			if not(gFH.groups[objectOrGroup]) then
				error(("Undefined frame group '%s'"):format(objectOrGroup, 2))
			end
			local unlocked
			for object,anchor in pairs(gFH.anchors) do
				if (anchor.group == objectOrGroup) then
					anchor:Show()
					unlocked = true
				end
			end
			if (unlocked) then
				gFH:AddMessage((L["The group '%s' is now unlocked"]):format(objectOrGroup), 1, 0.1, 0.1)
			else
				gFH:AddMessage((L["The group '%s' is empty"]):format(objectOrGroup), 1, 0.1, 0.1)
			end
			updateAllLocks()
			
		-- unlock all
		else
			local unlocked
			for object,anchor in pairs(gFH.anchors) do
				anchor:Show()
				unlocked = true
			end
			if (unlocked) then
				gFH:AddMessage(L["All frames are now unlocked"], 1, 0.1, 0.1)
			else
				gFH:AddMessage(L["No registered frames to unlock"], 1, 0.1, 0.1)
			end
			updateAllLocks()
		end
	end

	gFH.LockObjectPosition = function(self, objectOrGroup)
		argCheck(objectOrGroup, 1, "table", "string", "nil")
		
		-- single object lock
		if (type(objectOrGroup) == "table") then
			if not(gFH.anchors[objectOrGroup]) then
				error("Object has no anchor yet!", 2)
			end
			gFH.anchors[objectOrGroup]:Hide()
			gFH:AddMessage((L["The frame '%s' is now locked"]):format(gFH.anchors[objectOrGroup].name), 0.1, 1, 0.1)
			updateAllLocks()
			
		-- group lock
		elseif (type(objectOrGroup) == "string") then
			if not(gFH.groups[objectOrGroup]) then
				error(("Undefined frame group '%s'"):format(objectOrGroup, 2))
			end
			for object,anchor in pairs(gFH.anchors) do
				if (anchor.group == objectOrGroup) then
					anchor:Hide()
				end
			end
			gFH:AddMessage((L["The group '%s' is now locked"]):format(objectOrGroup), 0.1, 1, 0.1)
			updateAllLocks()
			
		-- lock all
		else
			for object,anchor in pairs(gFH.anchors) do
				anchor:Hide()
			end
			gFH:AddMessage(L["All frames are now locked"], 0.1, 1, 0.1)
			updateAllLocks()
		end
	end

	gFH.ToggleObjectPositionLock = function(self, objectOrGroup)
		argCheck(objectOrGroup, 1, "table", "string", "nil")
		
		updateAllLocks()
		
		-- single object toggling
		if (type(objectOrGroup) == "table") then
			if (gFH.anchors[objectOrGroup]:IsShown()) then
				gFH:LockObjectPosition(objectOrGroup)
			else
				gFH:UnlockObjectPosition(objectOrGroup)
			end
			return
		end
		
		-- group toggling
		if (type(objectOrGroup) == "string") then
			if (gFH.groups[objectOrGroup].UNLOCKED) then
				gFH:LockObjectPosition(objectOrGroup)
			else
				gFH:UnlockObjectPosition(objectOrGroup)
			end
			return 
		end
		
		-- all
		if (UNLOCKED) then
			gFH:LockObjectPosition()
		else
			gFH:UnlockObjectPosition()
		end
	end
end

gFH.ResetObjectToDefaultPosition = function(self, objectOrGroup)
	argCheck(objectOrGroup, 1, "table", "string", "nil")
	if (type(objectOrGroup) == "table") then
		self:SetSavedObjectPosition(objectOrGroup, self:GetDefaultObjectPosition(objectOrGroup))
		self:SetObjectPosition(objectOrGroup, self:GetDefaultObjectPosition(objectOrGroup)) -- default pos is unscaled
	elseif (type(objectOrGroup) == "string") then
	else
	end
end

gFH.ResetObjectToSavedPosition = function(self, objectOrGroup)
	argCheck(objectOrGroup, 1, "table", "string", "nil")
	if (type(objectOrGroup) == "table") then
		-- self:SetObjectPosition(objectOrGroup, self:GetSavedObjectPosition(objectOrGroup)) -- saved pos is.... scaled?
		objectOrGroup:ClearAllPoints()
		objectOrGroup:SetPoint(self:GetSavedObjectPosition(objectOrGroup))
	elseif (type(objectOrGroup) == "string") then
	else
	end
end

--
-- register a new framegroup
-- does nothing if the group exists already
-- color settings will only be applied to new groups
gFH.RegisterFrameGroup = function(self, group, r, g, b, fontObject, displayName, description)
	argCheck(group, 1, "string")
	if (gFH.groups[group]) then return end
	gFH.groups[group] = { r = 1, g = 1, b = 1, objects = {}, name = displayName, desc = description }
	if (r) then
		self:SetFrameGroupColor(group, r, g, b)
	end
	if (fontObject) then
		self:SetFrameGroupFontObject(group, fontObject)
	end
end

-- returns 'true' if the group exists, 'nil' otherwise
gFH.FrameGroupExist = function(self, group)
	argCheck(group, 1, "string")
	if (gFH.groups[group]) then
		return true
	end
end

gFH.SetFrameGroupColor = function(self, group, r, g, b)
	argCheck(group, 1, "string")
	argCheck(r, 2, "number", "string")
	
	if not(gFH.groups[group]) then
		error(("Undefined frame group '%s'"):format(group, 2))
	end
	
	if (type(r) == "number") then
		argCheck(g, 3, "number")
		argCheck(b, 4, "number")
	else
		r, g, b = getRGBFromHex(r)
	end

	gFH.groups[group].r = r
	gFH.groups[group].g = g
	gFH.groups[group].b = b
end

gFH.GetFrameGroupColor = function(self, group)
	argCheck(group, 1, "string")
	if not(gFH.groups[group]) then
		error(("Undefined frame group '%s'"):format(group, 2))
	end
	return gFH.groups[group].r, gFH.groups[group].g, gFH.groups[group].b
end

gFH.SetFrameGroupFontObject = function(self, group, fontObject)
	argCheck(group, 1, "string")
	argCheck(fontObject, 2, "table")
	if not(gFH.groups[group]) then
		error(("Undefined frame group '%s'"):format(group, 2))
	end
	gFH.groups[group].fontObject = fontObject
end

gFH.GetFrameGroupFontObject = function(self, group)
	argCheck(group, 1, "string")
	if not(gFH.groups[group]) then
		error(("Undefined frame group '%s'"):format(group, 2))
	end
	return gFH.groups[group].fontObject
end

gFH.AddObjectToFrameGroup = function(self, object, group)
	argCheck(object, 1, "table")
	argCheck(group, 2, "string")
	if not(gFH.groups[group]) then
		error(("Undefined frame group '%s'"):format(group, 2))
	end
	if not(gFH.anchors[object]) then
		error(("Can't assign to frame group '%s', object has no anchor yet!"):format(group, 2))
	end
	gFH.anchors[object].group = group
	gFH.objectToGroup[object] = group
	gFH.groups[group].objects[object] = true
end

gFH.RemoveObjectFromFrameGroup = function(self, object, group)
	argCheck(object, 1, "table")
	argCheck(group, 2, "string")
	if not(gFH.groups[group]) then
		error(("Undefined frame group '%s'"):format(group, 2))
	end
	gFH.objectToGroup[object] = nil
	gFH.groups[group].objects[object] = nil
end

--
-- restore all objects belonging to 'self' to their defaults
gFH.ResetAllObjectsToDefaults = function(self)
	if not(gFH.objectsByModule[self]) then
		return
	end
	for object, enabled in pairs(gFH.objectsByModule[self]) do
		self:ResetObjectToDefaultPosition(object)
	end
end

--
-- all-in-one function that registers default position, sets the saved position table, and positions object
-- 	*if the 'saved' position table already contains a position, that is where the object will be placed, 
-- 	otherwise the object will be placed in the 'default' position, and that will be stored as the 'saved' position
gFH.PlaceAndSave = function(self, object, name, tbl, ...)
	argCheck(object, 1, "table")
	argCheck(name, 2, "string", "nil")
	argCheck(tbl, 3, "table")
	
	if not(gFH.objectsByModule[self]) then
		gFH.objectsByModule[self] = {}
	end
	gFH.objectsByModule[self][object] = true -- add the current object to the local reference table
	
	self:SetDefaultObjectPosition(object, ...) -- register given position as the default position
	self:SetSavedObjectPositionTable(object, tbl) -- register the given table as the table the position is stored in
	self:CreateObjectAnchor(object, name) -- create the anchor for movement
	if (self:ObjectHasSavedPosition(object)) then -- object already has a stored position in the given table?
		-- self:SetObjectPosition(object, unpack(gFH.objects[object])) -- set the position to the stored one
		object:ClearAllPoints()
		object:SetPoint(unpack(gFH.objects[object]))
		
	else -- no saved position. this actually never happens in gUI v3
		self:SetSavedObjectPosition(object, ...) -- save the object at the given position
		self:SetObjectPosition(object, ...) -- position the object as instructed
	end
end

local mixins = {
	"GetObjectPosition", "SetObjectPosition", "SetDefaultObjectPosition", "GetDefaultObjectPosition",
	"SetSavedObjectPosition", "GetSavedObjectPosition", "SetSavedObjectPositionTable", "GetSavedObjectPositionTable",
	"CenterObject", "CenterObjectHorizontally", "CenterObjectVertically",
	"IsObjectInDefaultPosition", "IsObjectInSavedPosition", "ObjectHasSavedPosition", "ObjectHasDefaultPosition",
	"UnlockObjectPosition", "LockObjectPosition", "ToggleObjectPositionLock", "ResetObjectToDefaultPosition", "ResetObjectToSavedPosition",
	"RegisterFrameGroup", "FrameGroupExist",
	"AddObjectToFrameGroup", "RemoveObjectFromFrameGroup", 
	"SetFrameGroupColor", "GetFrameGroupColor",
	"SetFrameGroupFontObject", "GetFrameGroupFontObject",
	"CreateObjectAnchor",
	"AddCustomFunctionToObjectAnchor",
	"PlaceAndSave"
} 

gFH.Embed = function(self, target) 
	for i, v in pairs(mixins) do
		target[v] = self[v]
	end
	return target
end

------------------------------------------------------------------------------------------------------------
-- 	Event Handling
------------------------------------------------------------------------------------------------------------
gFH.scheduler.OnInit = function(self)
	-- use a state handler to maintain a taint free environment
	-- this also allows us to pick up where we left off when the combat ends
	RegisterStateDriver(gFH.frame, "visibility", "[combat][petbattle] hide; show") -- hide in pet battles as well
end

gFH.scheduler.OnEnable = function(self)
	gFH:RestoreAllSavedPositions()
end

gFH.scheduler.OnEnter = function(self)
end

-- just in case the user logouts or something with /glock open
gFH.scheduler.OnDisable = function(self)
	gFH:LockObjectPosition() -- lock and save all objects on logout
end

-- just in case we're dealing with objects that blizzard have moved around
local restoreAll = function(self, event, ...)
	gFH:RestoreAllSavedPositions()
end

-- even with our secure parent handler, we need to run through the queue on combat end
gFH.scheduler.PLAYER_REGEN_ENABLED = function(self)
	-- if not(gFH.frame:IsShown()) then gFH.frame:Show() end -- redisplay the parent frame
	while (#gFH.queue > 0) do gFH:SetObjectPosition(unpack(tremove(gFH.queue, 1))) end
end

gFH.scheduler:RegisterEvent("DISPLAY_SIZE_CHANGED", restoreAll)
gFH.scheduler:RegisterEvent("UI_SCALE_CHANGED", restoreAll)
gFH.scheduler:RegisterEvent("VARIABLES_LOADED", restoreAll)
gFH.scheduler:RegisterEvent("PLAYER_REGEN_ENABLED")
