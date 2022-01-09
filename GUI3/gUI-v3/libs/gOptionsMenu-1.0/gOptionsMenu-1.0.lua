--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gOptionsMenu-1.0", 22
local gOM, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gOM) then return end 

assert(LibStub("gCore-4.0"), MAJOR .. ": Cannot find an instance of gCore-4.0")

local _G = _G
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget
local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
local format, tonumber, tostring = string.format, tonumber, tostring
local strfind, gsub, strjoin, strlen, strmatch = string.find, string.gsub, string.join, string.len, string.match
local select, ipairs, pairs, next, type, unpack = select, ipairs, pairs, next, type, unpack

local CreateFrame = CreateFrame
local GetAddOnMetadata = GetAddOnMetadata
local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local StaticPopup_Show = StaticPopup_Show

gOM.scheduler = gOM.scheduler or LibStub("gCore-4.0"):NewAddon(MAJOR)
gOM.menus = gOM.menus or {} -- these refer to Blizzard interface menus only
gOM.optionsMenu = gOM.optionsMenu or {} -- these contain the non-blizzard menus
gOM.groups = gOM.groups or {}
gOM.widgetPool = gOM.widgetPool or {}

local Widgets
local GetWidgetPool, GetWidget, GetObjectPadding
local New, Create, CreateGroup, CreateWidget
local GetName, RegisterAsWidget, RegisterAsGroup
local SetTooltipScripts
local sortByOrder, applyEmbeds
local RegisterAsOptionsMenu, GetOptionsMenu
local RegisterOptionsMenuWidgetClass, RegisterOptionsMenuWithBlizzard, OpenToBlizzardOptionsMenu
local RefreshBlizzardOptionsMenu

local menus, optionsMenu, widgetPool, groups = gOM.menus, gOM.optionsMenu, gOM.widgetPool, gOM.groups
local noop = noop or function() end
local containerWidth, containerHeight = 623, 568
local groupName, widgetName = MAJOR .. "OptionsGroup", MAJOR .. "Widget"
local groupCount, widgetCount = 0, 0
local C = { index = { 1, 1, 1 }, value = { 1, .82, 0 }, disabled = { .40, .40, .40 } }
local types = { ["group"] = true, ["widget"] = true }

-- localization
local L = {}
L["Copy settings from another character"] = true
L["This will copy all settings for the addon and all its sub-modules from the selected character to your currently active character"] = true
L["This will only copy the settings for this specific sub-module from the selected character to your currently active character"] = true

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

-- attempt to avoid the bug that opens to a blizzard menu instead of the addon menu
-- when names are identical
local GetSafeName = function(name)
	argCheck(name, 1, "string")
	return "|cFFFFFFFF" .. name .. "|r"
end

------------------------------------------------------------------------------------------------------------
-- 	Shared Functions
------------------------------------------------------------------------------------------------------------
sortByOrder = function(a, b)
	if (a) and (b) then
		if (a.order) and (b.order) then
			if (a.order) ~= (b.order) then
				return ((a.order) < (b.order))
			elseif (a.msg) and (b.msg) then
				return ((a.msg) < (b.msg))
			end
		end
	end
end

RegisterAsWidget = function(object)
	object.type = "widget"
	
	local methods = {
		-- dummy holders to avoid nil errors
		Enable = function(self) self.disabled = false end;
		Disable = function(self) self.disabled = true end;
		IsEnabled = function(self) return not(self.disabled) end;
		SetValue = noop;
		GetValue = noop;
	}
	for method,func in pairs(methods) do
		-- don't overwrite existing methods
		if not(object[method]) then
			object[method] = func
		end
	end
	return object
end

RegisterAsGroup = function(object)
	object.type = "group"
	
	-- generic methods for all groups
	-- will be overwritten by user methods and values
	local methods = {
		get = function(self) 
			return self:GetValue()
		end;
		
		set = function(self) 
			local value = self:get()
			for i = 1, #self.children do
				if (i == value) then
					self.children[i]:SetValue(true)
				else
					self.children[i]:SetValue(false)
				end
			end
		end;
		
		-- having a 'refresh' function in every group will effectively
		-- make it refresh itself and all child objects, no matter where 
		-- in the menu tree we are
		refresh = function(self)
			for i = 1, #self.children do
				if (self.children[i].refresh) then
					self.children[i]:refresh()
				end
			end
		end;
		
		GetValue = function(self)
			return self.selected
		end;
		
		SetValue = function(self, value)
			self.selected = value
		end;

		Enable = function(self) 
			self.disabled = false
			for _,widget in pairs(self.children) do
				widget:Enable()
			end
		end;
		
		Disable = function(self) 
			self.disabled = true
			for _,widget in pairs(self.children) do
				widget:Disable()
			end
		end;
		
		IsEnabled = function(self)
			return not(self.disabled)
		end;
		--[[
		-- add our sort function
		Sort = function(self) 
			local previousWidget
			local point, rpoint, vpoint, vrpoint, x, y, j
			local padding = self.padding or 8
			local maxWidth, maxHeight = self:GetWidth(), self:GetHeight()
			local currentWidth, currentHeight, lineHeight = 0, 0, 0
			local i = 1
			local sortX = self["growth-x"] or "LEFT"
			local sortY = self["growth-y"] or "DOWN"
			
			if (sortX == "LEFT") then
				point = "LEFT"
				rpoint = "RIGHT"
				x = padding
				
			elseif (sortX == "RIGHT") then
				point = "RIGHT"
				rpoint = "LEFT"
				x = -padding
			else
				error(("'%s' is an illegal value for 'growth-x'. Valid values are 'LEFT' and 'RIGHT'."):format(sortX))
			end
			
			if (sortY == "DOWN") then
				vpoint = "TOP"
				vrpoint = "BOTTOM"
				y = -padding
				
			elseif (sortY == "UP") then
				vpoint = "BOTTOM"
				vrpoint = "TOP"
				y = padding
			else
				error(("'%s' is an illegal value for 'growth-y'. Valid values are 'DOWN' and 'UP'."):format(sortX))
			end
			
			while (i <= #self.children) do
				-- end of the line, move on to the next
				if ((currentWidth + self.children[i]:GetWidth()) > maxWidth) then
					currentHeight = currentHeight + lineHeight + padding
					lineHeight = 0
					previousWidget = nil
				end
				
				if((currentHeight + self.children[i]:GetHeight()) < maxHeight) then
					lineHeight = max(lineHeight, self.children[i]:GetHeight())
					
					self.children[i]:ClearAllPoints()

					if (i == 1) then
						-- first widget in the container
						self.children[i]:SetPoint(vpoint .. point, self, vpoint .. point, 0, 0)
						
					elseif (previousWidget) then
						self.children[i]:SetPoint(point, self.children[previousWidget], rpoint, x, 0)
						
					else
						-- first widget on the current line
						if (vpoint == "TOP") then
							self.children[i]:SetPoint(vpoint .. point, self, vpoint .. point, 0, -currentHeight)
							
						elseif (vpoint == "BOTTOM") then
							self.children[i]:SetPoint(vpoint .. point, self, vpoint .. point, 0, currentHeight)
						end
					end
				
					self.children[i]:Show()
					
					previousWidget = i
					
					-- move on to the next widget
					i = i + 1
				else
					-- container height exceded, break here
					break
				end
			end
			
			-- overflow. Hide remaining widgets
			if (i <= #self.children) then
				for j = i, #self.children do
					self.children[j]:Hide()
				end
			end
		end;
		]]--
	}
	for method,func in pairs(methods) do
		object[method] = func
	end
	
	-- table for pointers to named children
	object.child = {}
	
	-- table for numeric/indexed child listings
	-- used for radiobutton/dropdown/tab functions etc
	object.children = {}
	return object
end

GetName = function(type)
	if (type == "group") then
		groupCount = groupCount + 1
		return groupName .. groupCount
		
	elseif (type == "widget") then
		widgetCount = widgetCount + 1
		return widgetName .. widgetCount
	end
end

SetTooltipScripts = function(self, hook)
	local SetScript = hook and "HookScript" or "SetScript"
	
	self[SetScript](self, "OnEnter", function(self)
		if (self.tooltipText) then
			GameTooltip:SetOwner(self, self.tooltipOwnerPoint or "ANCHOR_RIGHT")

			if (type(self.tooltipText) == "string") then
				GameTooltip:SetText(self.tooltipText, 1.0, .82, .0, 1.0, 1)
				
			elseif (type(self.tooltipText) == "table") then
				for i = 1, #self.tooltipText do
					if (i == 1) then
						GameTooltip:SetText(self.tooltipText[i], 1.0, 1.0, 1.0, 1.0, 1)
					else
						GameTooltip:AddLine(self.tooltipText[i], 1.0, .82, .0, 1.0)
					end
				end
			end
			
			if (self.tooltipRequirement) then
				GameTooltip:AddLine(self.tooltipRequirement, 1.0, .0, .0, 1.0)
			end

			GameTooltip:Show()
		end
	end)
	
	self[SetScript](self, "OnLeave", function(self)
		GameTooltip:Hide()
	end)
end

------------------------------------------------------------------------------------------------------------
-- 	Widgets
------------------------------------------------------------------------------------------------------------
-- make sure all objects are represented here, or it will bug out
ObjectPadding = {
	-- text objects
	Title = { x = { before = 0, after = 0 }, y = { before = 16, after = 16 } };
	Header = { x = { before = 0, after = 0 }, y = { before = 16, after = 8 } };
	Text = { x = { before = 8, after = 0 }, y = { before = 0, after = 8 } };
	
	-- image objects
	Texture = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
	
	-- frame groups
	Frame = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
	ScrollFrame = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };

	-- input widgets
	Button = { x = { before = 8, after = 8 }, y = { before = 8, after = 8 } };
	CheckButton = { x = { before = 8, after = 0 }, y = { before = 4, after = 4 } };
	ColorSelect = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
	Dropdown = { x = { before = -8, after = 0 }, y = { before = 0, after = 0 } }; --negative padding to make up for our dropdown styling...? (needed here?)
	EditBox = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
	RadioButton = { x = { before = 8, after = 0 }, y = { before = 4, after = 4 } };
	Slider = { x = { before = 16, after = 16 }, y = { before = 16, after = 16 } };
	StatusBar = { x = { before = 16, after = 16 }, y = { before = 8, after = 8 } };
	TabButton = { x = { before = 0, after = 0 }, y = { before = 0, after = 0 } };
}
Widgets = {
	-- use for page titles
	Title = function(parent, msg, name, ...)
		local self = parent:CreateFontString(name, "ARTWORK")
		self.isEnabled = true
		self:SetFontObject(SystemFont_Large)
		self:SetTextColor(unpack(C["value"]))
		self:SetJustifyH("LEFT")
		self:SetWordWrap(true)
		self:SetNonSpaceWrap(true)
		self:SetText(msg)

		self.Enable = function(self) 
			self.isEnabled = true
			self:SetTextColor(unpack(C["value"]))
		end

		self.Disable = function(self) 
			self.isEnabled = false
			self:SetTextColor(unpack(C["disabled"]))
		end

		self.IsEnabled = function(self) return self.isEnabled end
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end
		
		return self, ...
	end;

	-- use for paragraph headers
	Header = function(parent, msg, name, ...)
		local self = parent:CreateFontString(name, "ARTWORK")
		self.isEnabled = true
		self:SetFontObject(SystemFont_Med3)
		self:SetTextColor(unpack(C["index"]))
		self:SetJustifyH("LEFT")
		self:SetWordWrap(true)
		self:SetNonSpaceWrap(true)
		self:SetText(msg)
		
		self.Enable = function(self) 
			self.isEnabled = true
			self:SetTextColor(unpack(C["index"]))
		end

		self.Disable = function(self) 
			self.isEnabled = false
			self:SetTextColor(unpack(C["disabled"]))
		end

		self.IsEnabled = function(self) return self.isEnabled end

		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("LEFT", parent, "RIGHT", 8, 0)
		end

		return self, ...
	end;

	-- use for normal text
	Text = function(parent, msg, name, ...)
		local self = parent:CreateFontString(name, "ARTWORK")
		self.isEnabled = true
		self:SetFontObject(GameFontWhite)
		self:SetTextColor(unpack(C["index"]))
		self:SetJustifyH("LEFT")
		self:SetWordWrap(true)
		self:SetNonSpaceWrap(true)
		self:SetText((type(msg) == "table") and tconcat(msg, "|n") or msg)
		
		self.Enable = function(self) 
			self.isEnabled = true
			self:SetTextColor(unpack(C["index"]))
		end

		self.Disable = function(self) 
			self.isEnabled = false
			self:SetTextColor(unpack(C["disabled"]))
		end

		self.IsEnabled = function(self) return self.isEnabled end
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("LEFT", parent, "RIGHT", 8, 0)
		end

		return self, ...
	end;
	
	Texture = function(parent, msg, name, ...)
		local self = parent:CreateTexture(name, "ARTWORK")
		self:SetSize(32, 32)
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("LEFT", parent, "RIGHT", 8, 0)
		end

		return self, ...
	end;

	Button = function(parent, msg, name, ...)
		local self = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
		self:SetSize(80, 22)
		self:SetText(msg)
		
		self:SetScript("OnClick", function(self)
			if (self.set) then
				self:set()
				
			elseif (self.parent.set) then
				self.parent:set()
			end
		end)

		SetTooltipScripts(self)
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end
		
		return self, ...
	end;

	CheckButton = function(parent, msg, name, ...)
		local self = CreateFrame("CheckButton", name, parent, "OptionsBaseCheckButtonTemplate")  -- OptionsBaseCheckButtonTemplate?
		
		local text = self:CreateFontString(name .. "Text", "ARTWORK")
		text:SetFontObject(GameFontWhite)
		text:SetPoint("LEFT", self, "RIGHT", 8, 0)
		text:SetTextColor(unpack(C["index"]))
		text:SetWordWrap(true)
		text:SetNonSpaceWrap(true)
		text:SetText(msg)
		self.text = text	

		self.refresh = function(self, option)
			if (self.get) then
				self:SetChecked(option or self:get())
				
			elseif (self.parent.get) then
				self:SetChecked(option or self.parent:get())
			end

			if (self.onrefresh) then
				self:onrefresh()
			end
		end

		self:SetScript("OnShow", function(self) self:refresh() end)
		self:SetScript("OnEnable", function(self) self.text:SetTextColor(unpack(C["index"])) end)
		self:SetScript("OnDisable", function(self) self.text:SetTextColor(unpack(C["disabled"])) end)
		self:SetScript("OnClick", function(self)
			if (self:GetChecked()) then
				PlaySound("igMainMenuOptionCheckBoxOn")
			else
				PlaySound("igMainMenuOptionCheckBoxOff")
			end
			
			if (self.set) then
				self:set()
				
			elseif (self.parent.set) then
				self.parent:set()
			end
		end)
		
		SetTooltipScripts(self)
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self, ...
	end;

	Frame = function(parent, name, ...)
		local self = CreateFrame("Frame", name, parent or UIParent)
		self:SetSize(containerWidth, containerHeight)
		self:EnableMouse(false)
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self
	end;

	ScrollFrame = function(parent, name, ...)
		local self = CreateFrame("ScrollFrame", name, parent or UIParent) -- "UIPanelScrollFrameTemplate"
		self:SetSize(containerWidth - 32 - 16, containerHeight - 32)
		self:EnableMouseWheel(true)
		
		self.ScrollChild = CreateFrame("Frame", name .. "ScrollChild", self)
		self.ScrollChild:SetSize(self:GetSize())
		self.ScrollChild:SetAllPoints(self)
		
		self:SetScrollChild(self.ScrollChild)
		self:SetVerticalScroll(0)
		
		self.ScrollBar = CreateFrame("Slider", name .. "ScrollBar", self, "UIPanelScrollBarTemplate")
		self.ScrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 6, -16)
		self.ScrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 6, 16)
		self.ScrollBar:SetWidth(16)
		self.ScrollBar:SetMinMaxValues(0, 0)
		self.ScrollBar:SetValue(0)
		self.ScrollBar:SetObeyStepOnDrag(true)

		self.ScrollBar.up = _G[name .. "ScrollBarScrollUpButton"]
		self.ScrollBar.up:Disable()
		self.ScrollBar.up:SetScript("OnClick", function(self)
			local ScrollBar = self:GetParent()
			local ScrollFrame = self:GetParent():GetParent()
			local scrollStep = ScrollFrame.scrollStep or (ScrollBar:GetHeight() / 3)

			ScrollBar:SetValue(min(0, ScrollBar:GetValue() - scrollStep))
			
			PlaySound("UChatScrollButton")
		end)
		
		self.ScrollBar.down = _G[name .. "ScrollBarScrollDownButton"]
		self.ScrollBar.down:Disable()
		self.ScrollBar.down:SetScript("OnClick", function(self)
			local ScrollBar = self:GetParent()
			local ScrollFrame = self:GetParent():GetParent()
			local scrollStep = ScrollFrame.scrollStep or (ScrollFrame:GetHeight() / 3)

			ScrollBar:SetValue(min(ScrollFrame:GetVerticalScrollRange(), ScrollBar:GetValue() + scrollStep))

			PlaySound("UChatScrollButton")
		end)
		
		self.Update = function(self, forced)
			local w, h = self:GetSize()
			local sW, sH = self.ScrollChild:GetSize()

			if (forced) then
				if (w ~= sW) then
					self.ScrollChild:SetWidth(w)
				end

				if (h ~= sH) then
					self.ScrollChild:SetHeight(h)
				end
				
				self:UpdateScrollChildRect()
			end

			local min, max, value = 0, self:GetVerticalScrollRange(), self:GetVerticalScroll()
			
			if (forced) then
				if (value > max) then
					value = max
				end
				
				if (value < min) then
					value = min
				end
				
				self.ScrollBar:SetMinMaxValues(min, max)
			end
			
			if (value <= min) then
				if (self.ScrollBar.up:IsEnabled()) then
					self.ScrollBar.up:Disable()
				end

				if not(self.ScrollBar.down:IsEnabled()) then
					self.ScrollBar.down:Enable()
				end
				
			elseif (value >= max) then
				if (self.ScrollBar.down:IsEnabled()) then
					self.ScrollBar.down:Disable()
				end
				
				if not(self.ScrollBar.up:IsEnabled()) then
					self.ScrollBar.up:Enable()
				end
			else
				if not(self.ScrollBar.up:IsEnabled()) then
					self.ScrollBar.up:Enable()
				end

				if not(self.ScrollBar.down:IsEnabled()) then
					self.ScrollBar.down:Enable()
				end
			end
		end

		self.ScrollBar:SetScript("OnValueChanged", function(self, value)
			self:GetParent():SetVerticalScroll(value)
			self:GetParent():Update()
		end)
		
		self:SetScript("OnMouseWheel", function(self, delta)
			if (delta > 0) then
				if (self.ScrollBar.up:IsEnabled()) then
					self.ScrollBar:SetValue(max(0, self.ScrollBar:GetValue() - 20))
				end
				
			elseif (delta < 0) then
				if (self.ScrollBar.down:IsEnabled()) then
					self.ScrollBar:SetValue(min(self:GetVerticalScrollRange(), self.ScrollBar:GetValue() + 20))
				end
			end
		end)
		
		-- we schedule a timer to update the frame contents 1/5 second after it's shown
		-- we only do this the first time
		local once
		self:SetScript("OnShow", function(self) 
			if not(once) then
				gOM.scheduler:ScheduleTimer(1/5, function() self:Update() end)
				once = true
			end
		end)
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self, self:GetScrollChild()
	end;
	
	ColorSelect = function(parent, msg, name, ...)
		local self = CreateFrame("ColorSelect", name, parent)

		SetTooltipScripts(self)
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self, ...
	end;

	Dropdown = function(parent, msg, name, args, width, ...)
		local width = width or 100
		local self = CreateFrame("Button", name, parent, "UIDropDownMenuTemplate")
		self:SetHitRectInsets(-26, 0, 0, 0)
		
		SetTooltipScripts(self)
		
		local label = self:CreateFontString(name .. "Label", "ARTWORK")
		label:SetFontObject(GameFontWhite)
		label:SetPoint("LEFT", self, "RIGHT", 0, 0)
		label:SetText(msg)
		self.label = label
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end
		
		local onclick = function(self)
			-- select the item you clicked on
			UIDropDownMenu_SetSelectedID(_G[name], self:GetID())

			-- fire off the button's 'set' function, and pass the ID along
			_G[name].set(_G[name], self:GetID())
			_G[name].selectedID = self:GetID()
		end
		
		self.args = CopyTable(args)
		self.refresh = function(self, option)
			if (self.get) then
				self.selectedID = self:get()
			end
			
			option = option or self.selectedID
			
			if (option) and (self.args[option]) then
				_G[name .. "Text"]:SetText(self.args[option])
			end

			if (self.onrefresh) then
				self:onrefresh()
			end
		end
		
		self.set = function(self, option) self:init() end
		self.get = function(self) return UIDropDownMenu_GetSelectedID(self) end
		self.init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end
		
		self:HookScript("OnShow", function(self) self:refresh() end)
--		self:HookScript("OnHide", function(self) self:refresh() end)
		
		local info = {}
		local init = function(self, level)
--			for i,v in pairs(args) do
			for i = 1, #args do
				wipe(info)
		
				info = UIDropDownMenu_CreateInfo()
				info.text = args[i] -- v
				info.value = i
				info.func = onclick

				UIDropDownMenu_AddButton(info, level)
			end
		end

		UIDropDownMenu_Initialize(self, init)
		UIDropDownMenu_SetWidth(self, width)
		UIDropDownMenu_SetButtonWidth(self, width)
		UIDropDownMenu_JustifyText(self, "LEFT")
		UIDropDownMenu_SetSelectedID(self, 1) -- selecting option #1 as default

		return self, ...
	end;

	EditBox = function(parent, msg, name, args, ...)
		local self = CreateFrame("Frame", nil, parent)
		self:EnableMouse(true)
		self:SetSize(90, 14)
		self:SetScript("OnMouseDown", function(self) self.editBox:Show() end)

		local text = self:CreateFontString(name .. "Text", "ARTWORK")
		text:SetFontObject(NumberFontNormal)
		text:SetPoint("BOTTOMLEFT", 0, 2)
		text:SetJustifyH("LEFT")
		text:SetJustifyV("BOTTOM")
		text:SetText("")
		text:SetTextColor(unpack(C["value"]))
		self.text = text
		
		local suffix = self:CreateFontString(name .. "TextSuffix", "ARTWORK")
		suffix:SetFontObject(GameFontWhite)
		suffix:SetPoint("BOTTOMLEFT", text, "BOTTOMRIGHT")
		suffix:SetJustifyH("LEFT")
		suffix:SetJustifyV("BOTTOM")
		suffix:SetTextColor(unpack(C["index"]))
		suffix:SetText(msg)
		self.suffix = suffix
		
		local editBox = CreateFrame("EditBox", nil, self)
		editBox.parent = self
		editBox:Hide()
		editBox:SetSize(self:GetWidth() + 8, self:GetHeight() + 8)
		editBox:SetPoint("BOTTOMLEFT", -4, -2)
		editBox:SetJustifyH("LEFT")
		editBox:SetJustifyV("BOTTOM")
		editBox:SetTextInsets(4, 4, 0, 0)
		editBox:SetFontObject(gUI_UnitFrameFont14)
		editBox:SetAutoFocus(false)
		editBox:SetNumeric((args) and args.numeric)
		
		editBox.Refresh = function(self) 
			if (self.parent.get) then
				if (self:IsNumeric()) then
					self:SetNumber(self.parent:get())
				else
					self:SetText(self.parent:get())
				end
			else
				if (self:IsNumeric()) then
					self:SetNumber("")
				else
					self:SetText("")
				end
			end
		end

		editBox:SetScript("OnHide", function(self) 
			self.parent.text:Show()
			self.parent.suffix:Show()
		end)
		
		editBox:SetScript("OnShow", function(self) 
			self.parent.text:Hide()
			self.parent.suffix:Hide()
			
			self:Refresh()
			self:SetFocus()
			self:HighlightText()
		end)
		
		editBox:SetScript("OnEditFocusLost", editBox.Hide)
		editBox:SetScript("OnEscapePressed", editBox.Hide)
		editBox:SetScript("OnEnterPressed", function(self) 
			self:Hide()
			
			local msg = self:IsNumeric() and self:GetNumber() or self:GetText()
			if (msg) then
				if (self.parent.set) then
					self.parent:set(msg)
				end
			end
			
			self.parent:refresh()
		end)
		
		self.editBox = editBox
		
		SetTooltipScripts(self)
		
		self.refresh = function(self)
			if (self.get) then
				self.text:SetText(self.get())
			else
				self.text:SetText("")
			end
			
			if (self.editBox:IsShown()) then
				self.editBox:Refresh()
			end
			
			if (self.onrefresh) then
				self:onrefresh()
			end
		end
		
		self:HookScript("OnSizeChanged", function(self) 
			self.editBox:SetSize(self:GetWidth() + 8, self:GetHeight() + 8)
		end)
		
		self.Enable = function(self) 
			self.isEnabled = true
			self:EnableMouse(true)
			self.text:SetTextColor(unpack(C["value"]))
			self.suffix:SetTextColor(unpack(C["index"]))
		end

		self.Disable = function(self) 
			self.isEnabled = false
			self:EnableMouse(false)
			self.text:SetTextColor(unpack(C["disabled"]))
			self.suffix:SetTextColor(unpack(C["disabled"]))
			if (self.editBox:IsShown()) then
				self.editBox:Hide()
			end
		end

		self.IsEnabled = function(self) return self.isEnabled end
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self, ...
	end;

	RadioButton = function(parent, msg, name, ...)
		local self = CreateFrame("CheckButton", name, parent, "UIRadioButtonTemplate")

		local text = self:CreateFontString(name .. "Text", "ARTWORK")
		text:SetFontObject(GameFontWhite)
		text:SetPoint("LEFT", self, "RIGHT", 8, 0)
		text:SetTextColor(unpack(C["index"]))
		text:SetWordWrap(true)
		text:SetNonSpaceWrap(true)
		text:SetText(msg)
		self.text = text	

		self.refresh = function(self, option)
			if (self.get) then
				self:SetChecked(option or self:get())
				
			elseif (self.parent.get) then
				self:SetChecked(option or self.parent:get())
			end

			if (self.onrefresh) then
				self:onrefresh()
			end
		end

		self:SetScript("OnShow", function(self) self:refresh() end)
		self:SetScript("OnEnable", function(self) self.text:SetTextColor(unpack(C["index"])) end)
		self:SetScript("OnDisable", function(self) self.text:SetTextColor(unpack(C["disabled"])) end)
		self:SetScript("OnClick", function(self)
			if (self:GetChecked()) then
				PlaySound("igMainMenuOptionCheckBoxOn")
			else
				PlaySound("igMainMenuOptionCheckBoxOff")
			end
			
			if (self.set) then
				self:set()
				
			elseif (self.parent.set) then
				self.parent:set()
			end
		end)

		SetTooltipScripts(self)
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self, ...
	end;

	Slider = function(parent, msg, name, orientation, ...)
		orientation = orientation or "HORIZONTAL"
		
		local self = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
		self:SetObeyStepOnDrag(true)
		self:SetOrientation(orientation)
		
		self.low = _G[name .. "Low"]
		self.high = _G[name .. "High"]
		self.text = _G[name .. "Text"]
		
		self.refresh = function(self, option)
			if (self.get) then
				local value = self:get()
				if (value) then
					self:SetValue(value)
				end
			end
		end

		self.ondisable = function(self)
			self:SetAlpha(3/4)
			self:EnableMouse(false)
		end
		
		self.onenable = function(self)
			self:SetAlpha(1)
			self:EnableMouse(true)
		end
		
		self.init = function(self, min, max)
			local value = self:get()
			min = min or self.min
			max = max or self.max
			self:SetMinMaxValues(min, max)
			self.low:SetText(min)
			self.high:SetText(max)
			self:SetValue(value)
			self:SetValueStep(self.step or 1)
			self.text:SetText((self.string or "%d"):format(value))
			if (self:IsEnabled()) then
				self:onenable()
			else
				self:ondisable()
			end
		end			

		self:SetScript("OnShow", function(self) self:refresh() end)
		
		self:SetScript("OnValueChanged", function(self, value)
			if (self.set) then
				self:set(value)
			end
		end)
		
		SetTooltipScripts(self)

		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self, ...
	end;

	StatusBar = function(parent, msg, name, ...)
		local self = CreateFrame("StatusBar", name, parent)
		
		SetTooltipScripts(self)
		
		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self, ...
	end;
	
	TabButton = function(parent, msg, name, ...)
		local self = CreateFrame("CheckButton", name, parent, "TabButtonTemplate")

		if (...) then
			self:SetPoint(...)
		else
			self:SetPoint("TOPLEFT")
		end

		return self, ...
	end;
}

--
-- retrieve the current widget pool
--
-- the addon object pool will inherit from the library pool,
-- and the module pools will all inherit from the ancestrial addon pool,
-- meaning an addon only needs register its widget in the top level object
GetWidgetPool = function(self)
	if not(self.__optionsWidgetPool) then
		if (self:IsModule()) then
			self.__optionsWidgetPool = {
				ObjectPadding = setmetatable({}, { __index = self:GetAncestor().__optionsWidgetPool.ObjectPadding });
				Widgets = setmetatable({}, { __index = self:GetAncestor().__optionsWidgetPool.Widgets });
			}
		else
			self.__optionsWidgetPool = {
				ObjectPadding = setmetatable({}, { __index = ObjectPadding });
				Widgets = setmetatable({}, { __index = Widgets });
			}
		end
	end
	return self.__optionsWidgetPool
end

-- proxy functions to retrieve widgets creators and padding values
GetWidget = function(self, widget)
	return GetWidgetPool(self).Widgets[widget]
end
GetObjectPadding = function(self, widget)
	return GetWidgetPool(self).ObjectPadding[widget]
end

--
-- register a new widget class with the library
--
-- :RegisterAsWidgetClass(name, func[, xbefore[, xafter[, ybefore[, yafter]]]])
-- 	@param name <string> unique name of the widget class
-- 	@param func <function> the function to be called upon widget instance creation
-- 	@param xbefore <number> horizontal pre-padding
-- 	@param xafter <number> horizontal post-padding
-- 	@param ybefore <number> vertical pre-padding
-- 	@param yafter <number> vertical post-padding
gOM.RegisterAsWidgetClass = function(self, name, func, xbefore, xafter, ybefore, yafter)
	argCheck(name, 1, "string")
	argCheck(func, 2, "function")
	argCheck(xbefore, 3, "number", "nil")
	argCheck(xafter, 3, "number", "nil")
	argCheck(ybefore, 3, "number", "nil")
	argCheck(yafter, 3, "number", "nil")
	
	if (Widgets[name]) then
		error(("There already exists a widget class named '%s'"):format(name), 2)
	end
	
	Widgets[name] = func
	ObjectPadding[name] = {
		x = { before = xbefore or 0, after = xafter or 0 },
		y = { before = ybefore or 0, after = yafter or 0 }
	}
end

------------------------------------------------------------------------------------------------------------
-- 	Item Creation
------------------------------------------------------------------------------------------------------------
CreateWidget = function(self, element, parent, msg, ...)
	argCheck(parent, 1, "table")
	
	if not(GetWidget(self, element)) or not(parent.type == "group") then
		return
	end
	
	-- need to create a dummy to hold the methods, 
	-- as we need to pass along some selected values to the widget creation
	-- TODO: Find a better way, this is amateurish at best
	local methodHolder = {}
	if (...) then
		for i = 1, select("#", ...), 2 do 
			local key, value = select(i, ...) 
			methodHolder[key] = value
		end
	end
	
	local widget = RegisterAsWidget(GetWidget(self, element)(parent, msg, GetName("widget"), methodHolder.args, methodHolder.width))
	
	-- add the methods we collected previously to our widget
	for key,value in pairs(methodHolder) do
		widget[key] = value
	end

	-- create navigational pointers
	widget.parent = parent
	
	if (widget.name) and (widget.name ~= "") then
		-- just in case the parent for some reason isn't a 'real' group
		widget.parent.child = widget.parent.child or {}

		-- add the widget to our parent's 'child' table
		widget.parent.child[widget.name] = widget
	end

	widgetPool[widget] = true
	
	return widget
end

CreateGroup = function(self, parent, ...)
	-- use a frame as the holder for our group
	local group = RegisterAsGroup(GetWidget(self, "Frame")(parent, GetName("group")))
	
	if (...) then
		for i = 1, select("#", ...), 2 do 
			local key, value = select(i, ...) 
			group[key] = value
		end
	end
	
	-- create navigational pointers
	if (parent ~= UIParent) then
		group.parent = parent
		
		if (group.name) and (group.name ~= "") then
			-- just in case the parent for some reason isn't a group
			group.parent.child = group.parent.child or {}
			
			-- add the group to our parent's 'child' table
			group.parent.child[group.name] = group
		end
	end
	
	groups[group] = true
	
	return group
end

--
-- format:
--		local group = Create("group", parent, msg, ...)
--		local widget = Create("widget", element, parent, msg, ...)
--
-- example:
--		local group = Create("group", "SetValue", function(self, choice) self.widget[choice]:SetValue(true) end)
-- 	local widget = group:Create("widget", "CheckButton", )
Create = function(self, type, ...)
	if not(types[type]) then 
		return
	end
	
	local object
	if (type == "group") then
		object = CreateGroup(self, ...)
		
		-- add a :Create() method to the group for easier creation
		if not(object.Create) then
			object.Create = function(object, self, ...) 
				local child = Create(self, ...) 
				
				-- insert the new child into the group's indexed widget pool
				tinsert(object.children, child)
				
				return child
			end
		end
		
	elseif (type == "widget") then
		object = CreateWidget(self, ...)
		local parent = select(2, ...)
		
		-- insert the new widget into its parent group's indexed widget pool
		if (parent.children) then
			tinsert(parent.children, object)
		end
	end
	
	return object
end


-- in this function we translate the menuTable to widgets, groups and frames
New = function(self, menuTable, ...)
	argCheck(menuTable, 1, "table")
	
	local useScrollFrame = ...
	local self, menuTable = self, menuTable
	local scrollframe, inset, halfWidth, fullWidth, firstWidget

	local panel = GetWidget(self, "Frame")(UIParent, GetName("group"))
	panel:Hide()

	-- ScrollFrames get messed up texture and frame order, and weird distortions
	-- unless there is a real space issue, never ever use them for anything but text!!
	if (useScrollFrame) then
		scrollframe, inset = GetWidget(self, "ScrollFrame")(panel, GetName("group"))

		scrollframe:SetWidth(panel:GetWidth() - 32 - 16)
		scrollframe:SetHeight(panel:GetHeight() - 32)
		scrollframe:SetPoint("TOPLEFT", 16, -16)
		scrollframe:SetPoint("BOTTOMRIGHT", -32, 16)

		fullWidth = panel:GetWidth() - 32 - 16
	else
		inset = CreateFrame("Frame", nil, panel)
		inset:SetWidth(panel:GetWidth() - 32)
		inset:SetHeight(panel:GetHeight() - 32)
		inset:SetPoint("TOPLEFT", 16, -16)
		inset:SetPoint("BOTTOMRIGHT", -16, 16)

		fullWidth = panel:GetWidth() - 32
	end
	halfWidth = fullWidth/2
	
	-- add a :Create() method to the panel for easier creation
	if not(inset.Create) then
		inset.Create = function(object, self, type, element, parent, msg, ...) 
			local child = Create(self, type, element, parent, msg, ...) 
			
			-- insert the new child into the group's indexed widget pool
			tinsert(object.children, child)
			
			return child
		end
	end

	-- doing this to grab generic group methods
	panel.inset = RegisterAsGroup(inset)
	
	local init = {}
	local bottomPadding = 0
	local previous -- need to define previous here
	
	local traverse
	traverse = function(self, panel, menuTable)
		local types = types
		local self, panel, menuTable = self, panel, menuTable
		-- local order = {}
		-- for i = 1, #menuTable do
			-- tinsert(order, { index = i, order = menuTable[i].order })
		-- end
		-- sort(order, sortByOrder)
		sort(menuTable, sortByOrder)
		
		local object
		for i = 1, #menuTable do
			local item = menuTable[i]
			-- local item = menuTable[order[i].index]
			if (item) and (item.type) and (types[item.type]) then

				if (item.type == "group") then
					if (panel.type == "group") then
						object = panel:Create(self, "group", panel, "name", item.name)
					else
						object = Create(self, "group", panel, "name", item.name)
					end

					object.element = "Frame"
					
					if (item.virtual) then
						object:SetSize(0.00001, 0.00001)
					end
					
				elseif (item.type == "widget") then
					if (panel.type == "group") then
						object = panel:Create(self, "widget", item.element, panel, item.msg, "name", item.name, "args", item.args)
					else
						object = Create(self, "widget", item.element, panel, item.msg, "name", item.name, "args", item.args)
					end
					
					if not(object) then
						error(("No widget type named '%s' exists! Capitalization typo?"):format(item.element), 2)
					end
					
					object.element = item.element
					
					-- scrollframes distort graphics and messes with layers
					-- we need some fixes if we're using one
					-- if (useScrollFrame) then
						-- if (object.GetUIShadowFrame) and (object:GetUIShadowFrame()) then
							-- object:GetUIShadowFrame():Hide()
						-- end
					-- end

					if (item.desc) then
						object.tooltipText = item.desc
					end
				end
				
				-- size and position of the item
				object.width = item.width or "full"
				if (object.width == "full") then
					object.newLine = true
				
				-- last item on a line
				elseif (object.width == "last") then
					object.newLine = true
				
				-- two halves in a row
				elseif (object.width == "half") and ((previous) and (previous.width == "half")) then
					-- only change to a new line if the previous object didn't
					if not(previous.newLine) then
						object.newLine = true
					end
				end
				
				-- need to keep track of bottom padding on each line, 
				-- and make the last item on each line have the maximum bottom padding
				
				-- grab values for object padding
				local pad = GetObjectPadding(self, object.element)
				
				local lastPad
				if (previous) then
					lastPad = GetObjectPadding(self, previous.element)
				end
				
				local indent = item.indented and 32 or 0
				
				-- first element of the group
				if (i == 1) then
					-- check if there is a previous group to make room for
					if (previous) and (firstWidget) then
						object:ClearAllPoints()
						object:SetPoint("LEFT", panel, "LEFT", indent + (pad.x.before), 0)
						object:SetPoint("TOP", previous, "BOTTOM", 0, -(pad.y.before + max(lastPad.y.after, bottomPadding)))
					else
						object:ClearAllPoints()
						object:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
					end
					
					bottomPadding = pad.y.after
					
				else
					-- first item on a new line
					if (object.width == "full") or (previous.newLine) then
						object:ClearAllPoints()
						object:SetPoint("LEFT", panel, "LEFT", indent + (pad.x.before), 0)
						object:SetPoint("TOP", previous, "BOTTOM", 0, -(pad.y.before + max(lastPad.y.after, bottomPadding)))
						
						bottomPadding = pad.y.after
						
						-- second item on a half line
					elseif (previous.width == "half") then
						object:ClearAllPoints()
						object:SetPoint("LEFT", panel, "LEFT", halfWidth + indent + (pad.x.before), 0)
						object:SetPoint("TOP", previous, "TOP", 0, 0)
						
						bottomPadding = max(pad.y.after, bottomPadding)

						-- minimum size, no overflow checking here so use with caution!! achtung achtung!
					elseif (previous.width == "minimum") then
						object:ClearAllPoints()
						object:SetPoint("TOPLEFT", previous, "TOPRIGHT", (pad.x.before + lastPad.x.after), 0)
						
						bottomPadding = max(pad.y.after, bottomPadding)
					end
				end
				
				-- set the width of text objects, to enable wrapping
				if (object.element == "Text") then
					if (object.width == "half") then
						object:SetWidth(halfWidth - (pad.x.before + pad.x.after))
						
					elseif (object.width == "full") then 
						object:SetWidth(fullWidth - (pad.x.before + pad.x.after))
					end
				end
				
				object.string = item.string or object.string
				object.step = item.step or object.step
				object.max = item.max or object.max
				object.min = item.min or object.min
				object.get = item.get or object.get
				object.set = item.set or object.set
				object.onenable = item.onenable or object.onenable
				object.ondisable = item.ondisable or object.ondisable
				object.init = item.init or object.init
				object.onrefresh = item.onrefresh or object.onrefresh
				object.onshow = item.onshow or object.onshow
				object.onhide = item.onhide or object.onhide

				if (object.init) then
					tinsert(init, object)
				end

				if (object:IsObjectType("Frame")) then
					if (object.onenable) then
						object:HookScript("OnEnable", object.onenable) 
					end
					
					if (object.ondisable) then
						object:HookScript("OnDisable", object.ondisable) 
					end
											
					if (object.onshow) then
						object:HookScript("OnShow", object.onshow)
					end
					
					if (object.onhide) then
						object:HookScript("OnHide", object.onhide) 
					end
				end

				-- set the pointer to the current object before iterating over the sub-group
				previous = object

				-- the first widget have been drawn, now it is ok to indent before an item
				if (item.type == "widget") and not(firstWidget) then
					firstWidget = true
				end
				
				if (item.type == "group") then
					traverse(self, object, item.children)
				end
			end
		end
	end
	
	traverse(self, inset, menuTable)
	
	for _,object in pairs(init) do
		object.init(object)
	end
	init = nil
	
	-- blizzard menu compatible refresh function
	panel.refresh = function(self) 
		local topLevel = self.inset.children 
		for i = 1, #topLevel do
			if (topLevel[i].refresh) then
				topLevel[i]:refresh()
			end
		end
	end
	
	return panel
end

------------------------------------------------------------------------------------------------------------
-- 	Library API
------------------------------------------------------------------------------------------------------------

--[[

	Source: http://wowprogramming.com/docs/api/InterfaceOptions_AddCategory
	
	panel - The menu frame itself
	panel.name - string (required) - The name of the AddOn or group of configuration options. This is the text that will display in the AddOn options list.
	panel.parent - string (optional) - Name of the parent of the AddOn or group of configuration options. This identifies "panel" as the child of another category. If the parent category doesn't exist, "panel" will be displayed as a regular category.
	panel.okay - function (optional) - This method will run when the player clicks "okay" in the Interface Options.
	panel.cancel - function (optional) - This method will run when the player clicks "cancel" in the Interface Options. Use this to revert their changes.
	panel.default - function (optional) - This method will run when the player clicks "defaults". Use this to revert their changes to your defaults.
	panel.refresh - function (optional) - This method will run when the Interface Options frame calls its OnShow function and after defaults have been applied via the panel.default method described above. Use this to refresh your panel's UI in case settings were changed without player interaction.
	
	-- register it with blizzard
	InterfaceOptions_AddCategory(panel)
	
	-- open to a menu, or sub-category
	InterfaceOptionsFrame_OpenToCategory(panel.name)
	
]]--

-- external usage:
-- 	local gOM = LibStub("gOptionsMenu-1.0")
-- 	gOM:RegisterWithBlizzard(panel, name[, ...])
--
-- combined usage:
-- 	local gOM = LibStub("gOptionsMenu-1.0")
-- 	local panel = gOM:RegisterWithBlizzard(gOM:New(menuTable), name[, ...])
local BlizzardMenuQueue = {}
local BlizzardMenus = {}
gOM.RegisterWithBlizzard = function(self, panel, name, ...)
	argCheck(panel, 1, "table")
	argCheck(name, 2, "string")
	
	if (BlizzardMenus[panel]) then
		error(("The optionsmenu named '%s' has already been registered with Blizzard"):format(name), 2)
	end
	
	panel.name = GetSafeName(name)
	if (...) then
		for i = 1, select("#", ...), 2 do 
			local key, value = select(i, ...) 
			panel[key] = value
		end
	end

	-- directly create the menu if we're already logged in, 
	-- or if it is lacking a parent object, thus indicating it's a top level menu. 
	if (IsLoggedIn()) or not(panel.parent) then
		InterfaceOptions_AddCategory(panel)
		BlizzardMenus[panel] = true
	else
		-- queue it up to be added later
		-- if we don't do this, sub-menus won't find their parents
		tinsert(BlizzardMenuQueue, panel)
	end
	return panel
end

gOM.Open = function(self, name)
	argCheck(name, 1, "string")
	if not(menus[name]) or not(menus[name].name) then
		return
	end
	InterfaceOptionsFrame_OpenToCategory(menus[name].name)
end

gOM.GetMenuTable = function(self, name)
	return menus[name].inset -- or menus[name]
end

gOM.Refresh = function(self, name)
	if (menus[name]) and (menus[name].refresh) then
		menus[name]:refresh()
	end
end

do
	local SetSail = function(menu, childName)
		return (menu) and (menu.child) and (menu.child[childName])
	end
	
	gOM.GetMenuObject = function(self, name, ...)
		local position = self:GetMenuTable(name)
		if not(position) then
			return
		end
		
		for i = 1, select("#", ...) do
			position = SetSail(position, (select(i, ...)))
		end
		
		return position
	end
end

gOM.ApplyToAllChildren = function(self, menuObject, func, ...)
	if not(menuObject) or not(menuObject.children) then
		return
	end
	
	for i = 1, #menuObject.children do
		func(menuObject.children[i], ...)
	end
end

gOM.ApplyMethodToAllChildren = function(self, menuObject, method, ...)
	if not(menuObject) or not(menuObject.children) then
		return
	end
	
	for i = 1, #menuObject.children do
		if (menuObject.children[i][method]) then
			menuObject.children[i][method](menuObject.children[i], ...)
		end
	end
end

gOM.AddProfileSelectionToMenu = function(self, object, menuTable)
	argCheck(menuTable, 1, "table")
	argCheck(menuTable[1], 2, "table")
	argCheck(menuTable[1].children, 3, "table")
	local selectProfileHeader = {
		type = "widget";
		element = "Title";
		order = -1000; -- negative values since we don't expect user modules to have this
		msg = L["Copy settings from another character"]; -- this can be localized by addons
	}
	local profileDescription = {
		type = "widget";
		element = "Text";
		order = -999;
		msg = object:IsModule() and L["This will only copy the settings for this specific sub-module from the selected character to your currently active character"] or L["This will copy all settings for the addon and all its sub-modules from the selected character to your currently active character"];
	}
	local profileDropDown = { 
		type = "widget";
		element = "Dropdown";
		name = "selectProfileDropdown";
		order = selectProfileHeader.order + 5; -- will improve on this later 
		width = "minimum";
		msg = nil;
		desc = nil;
		args = {  };
	}
	local profiles = object:GetOptionsProfiles()
	for profileName, moduleDB in pairs(profiles) do tinsert(profileDropDown.args, profileName) end
	table.sort(profileDropDown.args) -- sort profile list by name
	local applyProfile
	applyProfile = function(self, profile)
		if (self:GetGlobalForOptions()) then
			self:SetCurrentOptionsSetToProfile(profile)
			if (self.RefreshBlizzardOptionsMenu) then 
				self:RefreshBlizzardOptionsMenu() 
			end
			if (self.PostUpdateSettings) then 
				self:PostUpdateSettings() 
			end
			for i,v in self:IterateModules() do
				applyProfile(v, profile)
			end
		end
	end
	local applyProfileButton = {
		type = "widget";
		element = "Button";
		name = "applyProfileButton";
		width = "minimum";
		order = profileDropDown.order + 5;
		msg = APPLY;
		desc = nil;
		set = function(self)
			local profile = self.parent.child.selectProfileDropdown.args[self.parent.child.selectProfileDropdown:get()]
			if (profile) then
				gOM.scheduler:FireCallback("GCORE_RESTART_SCHEDULED")
				applyProfile(object, profile)
			end
		end;
		get = noop;
	}
	
	local insertPoint = menuTable[1].children
	tinsert(insertPoint, selectProfileHeader)
	tinsert(insertPoint, profileDescription)
	tinsert(insertPoint, profileDropDown)
	tinsert(insertPoint, applyProfileButton)
	return menuTable
end

-- our complete cop out; 
-- we simply hand the whole localization table to whomever asks...
gOM.GetLocale = function(self) return L end

------------------------------------------------------------------------------------------------------------
-- 	Event Handling
------------------------------------------------------------------------------------------------------------
gOM.scheduler.OnInit = function(self)
	local w, h = InterfaceOptionsFrame:GetWidth() or 0, InterfaceOptionsFrame:GetHeight() or 0
	if (w < 858) or (h < 660) then
		InterfaceOptionsFrame:SetSize(858, 660)

		InterfaceOptionsFrameAddOns:SetSize(175, 569)
		InterfaceOptionsFrameAddOns:ClearAllPoints()
		InterfaceOptionsFrameAddOns:SetPoint("TOPLEFT", 22, -40)

		InterfaceOptionsFrameCategories:SetSize(175, 569)
		InterfaceOptionsFrameCategories:ClearAllPoints()
		InterfaceOptionsFrameCategories:SetPoint("TOPLEFT", 22, -40)
		
		InterfaceOptionsFramePanelContainer:ClearAllPoints()
		InterfaceOptionsFramePanelContainer:SetPoint("TOPLEFT", InterfaceOptionsFrameCategories, "TOPRIGHT", 16, 0)
		InterfaceOptionsFramePanelContainer:SetPoint("BOTTOMLEFT", InterfaceOptionsFrameCategories, "BOTTOMRIGHT", 16, 1)
		InterfaceOptionsFramePanelContainer:SetPoint("RIGHT", -22, 0)
	end
	-- InterfaceOptionsFrame:HookScript("OnHide", function() F.RestartIfScheduled() end)
end

gOM.Enable = function(self)
	-- sort the menus by their display names
	sort(BlizzardMenuQueue, function(a,b)
		if (a) and (b) then
			if (a.name) and (b.name) then
				return (a.name < b.name)
			end
		end
	end)
	
	-- NOW we add the menus, in alphabetical order
	local panel
	while (#BlizzardMenuQueue > 0) do
		panel = tremove(BlizzardMenuQueue, 1)
	-- for i = 1, #BlizzardMenuQueue do
		if (BlizzardMenus[panel]) then
			error(("The optionsmenu named '%s' has already been registered with Blizzard"):format(panel.name), 2)
		end
		BlizzardMenus[panel] = true
		InterfaceOptions_AddCategory(panel)
		menus[panel.name] = panel
	end
end

-- menus should be added by modules prior to his, 
-- preferably in their OnInit() function.
gOM.scheduler.OnEnable = function(self)
	gOM:Enable()
end

------------------------------------------------------------------------------------------------------------
-- 	Embedded API for addons/modules
------------------------------------------------------------------------------------------------------------
RegisterAsOptionsMenu = function(self, ...)
	local panel = New(self, ...)
	if (self:IsModule()) then
		local menu = self:GetAncestor():GetOptionsMenu()
		if not(menu) then
			error("Cannot register an options menu unless the top addon object also has an options menu", 2)
		end
		panel.parent = menu.name
	else
		panel.parent = nil
	end
	optionsMenu[self] = panel
	-- self.__optionsMenu = panel
	return panel
end

GetOptionsMenu = function(self)
	return optionsMenu[self]
	-- return self.__optionsMenu
end

RegisterOptionsMenuWithBlizzard = function(self, panel, name, ...)
	argCheck(panel, 1, "table")
	argCheck(name, 2, "string")
	-- if (self:IsModule()) then
		-- error(("Error attempting to register the optionsmenu named '%s' with Blizzard: Function only available to top level addon objects, not modules!"):format(name), 2)
	-- end
	return gOM:RegisterWithBlizzard(panel, name, ...)
end

-- all-in-one function to register a menu, add profile copying, and convert it to a blizzard menu
RegisterAsBlizzardOptionsMenu = function(self, menuTable, name, ...)
	argCheck(menuTable, 1, "table")
	argCheck(name, 2, "string")
	return self:RegisterOptionsMenuWithBlizzard(self:RegisterAsOptionsMenu(gOM:AddProfileSelectionToMenu(self, menuTable), true), name, ...)
end

-- opens directly to our own blizzard addon menu
OpenToBlizzardOptionsMenu = function(self)
	local menu = self:GetOptionsMenu()
	if (menu) and (menu.name) then
		PlaySound("igMainMenuOption")
		HideUIPanel(_G["GameMenuFrame"])
		InterfaceOptionsFrame_OpenToCategory(menu.name)
	end
end

-- update the contents of the blizzard menu
-- use this when settings change, or when chat commands are used that change them
RefreshBlizzardOptionsMenu = function(self)
	local menu = self:GetOptionsMenu()
	if (menu) and (menu.name) then
		gOM:Refresh(menu.name)
		-- if (menu.refresh) then
			-- menu:refresh()
		-- end
	end
end

--
-- same as gOM:RegisterAsWidgetClass(), but for the current addon/module only
-- widgets here can be overwritten
RegisterOptionsMenuWidgetClass = function(self, name, func, xbefore, xafter, ybefore, yafter)
	argCheck(name, 1, "string")
	argCheck(func, 2, "function")
	argCheck(xbefore, 3, "number", "nil")
	argCheck(xafter, 3, "number", "nil")
	argCheck(ybefore, 3, "number", "nil")
	argCheck(yafter, 3, "number", "nil")

	GetWidgetPool(self).Widgets[name] = func
	GetWidgetPool(self).ObjectPadding[name] = {
		x = { before = xbefore or 0, after = xafter or 0 },
		y = { before = ybefore or 0, after = yafter or 0 }
	}
end

--
-- allthough the entire library API can be accessed, 
-- there should never be any need for anything else than 
-- the embedded functionality
local mixins = {
	RegisterAsOptionsMenu = RegisterAsOptionsMenu;
	GetOptionsMenu = GetOptionsMenu;
	RegisterOptionsMenuWidgetClass = RegisterOptionsMenuWidgetClass;
	RegisterOptionsMenuWithBlizzard = RegisterOptionsMenuWithBlizzard;
	RegisterAsBlizzardOptionsMenu = RegisterAsBlizzardOptionsMenu;
	OpenToBlizzardOptionsMenu = OpenToBlizzardOptionsMenu;
	RefreshBlizzardOptionsMenu = RefreshBlizzardOptionsMenu;
} 

gOM.Embed = function(self, target) 
	for i, v in pairs(mixins) do
		target[i] = v
	end
	return target
end
