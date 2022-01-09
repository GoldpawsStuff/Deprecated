--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gPanel-3.0", 9
local gPanel, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gPanel) then return end 

local assert, error = assert, error
local pairs, select = pairs, select
local tinsert, tremove, wipe = tinsert, tremove, wipe
local strmatch = string.match
local min, max, floor = math.min, math.max, math.floor
local type = type

gPanel.panels = gPanel.panels or {} -- active panels
gPanel.plugins = gPanel.plugins or {} -- available plugin templates
gPanel.tooltips = gPanel.tooltips or {} -- available tooltip templates
gPanel.pool = gPanel.pool or {} -- stack of available frames. recycling ftw!
gPanel.fontObject = gPanel.fontObject or GameFontNormal
gPanel.iconSize = gPanel.iconSize or 14

local PANEL, CELL, PLUGIN, TOOLTIP
local Push, Pull, Init

--
-- argCheck(value, num[, nobreak], ...)
-- 	@param value <any> the argument to check
-- 	@param num <number> the number of the argument in your function 
-- 	@param nobreak <boolean> optional. if true, then a non-breaking error will fired instead
-- 	@param ... <string> list of argument types
local argCheck = function(value, num, ...)
	assert(type(num) == "number", "Bad argument #2 to 'argCheck' (number expected, got " .. type(num) .. ")")
	
	local nobreak
	for i = 1, select("#", ...) do
		if (i == 1) and (select(i, ...) == true) then
			nobreak = true
		else
			if (type(value) == select(i, ...)) then return end
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

local New = function(target, source)
	argCheck(target, 1, "table", "nil")
	argCheck(source, 2, "table")
	if not(target) then
		target = {}
	end
	for i,v in pairs(source) do
		target[i] = v
	end
	return target
end

------------------------------------------------------------------------------------------------------------
-- 	Panels
------------------------------------------------------------------------------------------------------------
PANEL = {
	NewCell = function(self)
		local cell = New({}, CELL)
		cell.max = 1 -- 1 plugin per cell as default
		cell.justifyH = "LEFT"
		cell.justifyV = "TOP"
		cell.plugins = {}
		cell.parent = self
		cell.index = #self.cells + 1
		tinsert(self.cells, cell)
		return cell, #self.cells
	end;

	GetCell = function(self, index)
		argCheck(index, 1, "number")
		return self.cells[index]
	end;
	
	-- returns the maximum allowed number of cells based on panel size
	GetMaxCells = function(self)
		return self:GetPanelWidth() * self:GetPanelHeight()
	end;

	-- returns the number of registered cells
	GetNumCells = function(self)
		return #self.cells
	end;
	
	-- this returns the allowed max number, not the actual
	GetNumActiveCells = function(self)
		return min(self:GetNumCells(), self:GetMaxCells())
	end;
	
	SetCellPadding = function(self, padding)
		argCheck(padding, 1, "number")
		self.padding = padding
	end;
	
	GetCellPadding = function(self)
		return self.padding or 10
	end;

	-- updates the panel layout and size
	-- will hide any overflow cells, and disable their plugins
	Update = function(self)
		if not(IsLoggedIn()) then return end
		
		local active, allowed, total = self:GetNumActiveCells(), self:GetMaxCells(), self:GetNumCells()
		local w, h = self:GetPanelWidth(), self:GetPanelHeight()
		local padding = self:GetCellPadding()
		local cellWidth = self:GetWidth() / w
		local cellHeight = self:GetHeight() / h
		local i, j, cell, plugin, prevPlugin, numPlugins, justifyH, justifyV, offset
		local row, column, first, firstCell, size
		local point, parent, rpoint, x, y
		local edgePadding = 10
		local contentSize

		-- disable any overflow plugins
		if (total > allowed) then
			for i = allowed + 1, total do
				cell = self:GetCell(i)
				for j = 1, cell:GetNumPlugins() do
					plugin = cell:GetPlugin(j)
					plugin:Disable()
					plugin:ClearAllPoints()
					plugin:Hide()
				end
			end
		end
		
		-- iterate visible cells, and arrange their plugins
		for i = 1, active do
			cell = self:GetCell(i)
			numPlugins = cell:GetNumPlugins()
			justifyH, justifyV = cell:GetJustifyH(), cell:GetJustifyV()
			offset = 0
			
			-- clear all plugin positions before reanchoring
			for j = 1, numPlugins do
				plugin = cell:GetPlugin(j)
				size = plugin.msg:GetWidth() + (plugin:GetTexture() and (gPanel.iconSize + 4) or 0)
				plugin:SetSize(size, cellHeight)
				-- plugin.clickFrame:SetSize(cellWidth/numPlugins, cellHeight)
			end
			
			-- get the cell position in the panel
			-- values here start at 0, for purposes of easy math
			row = floor((i-1)/w)
			column = (i-1)%w
			
			-- position plugins within the cell
			for j = 1, numPlugins do
				plugin = cell:GetPlugin(j)
				first = j == 1 -- or j%w == 1 -- first plugin, not cell
				
				if (justifyH == "LEFT") then
					if (first) then
						if (justifyV == "TOP") then
							point, parent, rpoint, x, y = justifyV .. justifyH, self, justifyV .. justifyH, column*cellWidth, -(row*cellHeight)
						elseif (justifyV == "BOTTOM") then
							point, parent, rpoint, x, y = justifyV .. justifyH, self, justifyV .. justifyH, column*cellWidth, -((row+1) * cellHeight)
						elseif (justifyV == "MIDDLE") then
							point, parent, rpoint, x, y = justifyH, self, justifyH, column*cellWidth, 0
						end
					else
						if (justifyV == "TOP") then
							point, parent, rpoint, x, y = "TOPLEFT", prevPlugin, "TOPRIGHT", padding, 0
						elseif (justifyV == "BOTTOM") then
							point, parent, rpoint, x, y = "BOTTOMLEFT", prevPlugin, "BOTTOMRIGHT", padding, 0
						elseif (justifyV == "MIDDLE") then
							point, parent, rpoint, x, y = "LEFT", prevPlugin, "RIGHT", padding, 0
						end
					end
				elseif (justifyH == "RIGHT") then
					if (first) then
						if (justifyV == "TOP") then
							point, parent, rpoint, x, y = justifyV .. justifyH, self, justifyV .. justifyH, -((w-(column+1))*cellWidth), -(row*cellHeight)
						elseif (justifyV == "BOTTOM") then
							point, parent, rpoint, x, y = justifyV .. justifyH, self, justifyV .. justifyH, -((w-(column+1))*cellWidth), -((row+1) * cellHeight)
						elseif (justifyV == "MIDDLE") then
							point, parent, rpoint, x, y = justifyH, self, justifyH, -((w-(column+1))*cellWidth), 0
						end
					else
						if (justifyV == "TOP") then
							point, parent, rpoint, x, y = "TOPRIGHT", prevPlugin, "TOPLEFT", -padding, 0
						elseif (justifyV == "BOTTOM") then
							point, parent, rpoint, x, y = "BOTTOMRIGHT", prevPlugin, "BOTTOMLEFT", -padding, 0
						elseif (justifyV == "MIDDLE") then
							point, parent, rpoint, x, y = "RIGHT", prevPlugin, "LEFT", -padding, 0
						end
					end
				elseif (justifyH == "CENTER") then
					if (first) then
						if (numPlugins == 1) then
							offset = plugin.clickFrame:GetWidth() / 2
						else
							local dummy
							for k = 1, numPlugins do
								dummy = cell:GetPlugin(k)
								offset = offset + dummy.clickFrame:GetWidth()
							end
							offset = offset + (numPlugins - 1) * padding
							offset = offset/2
						end
	
						if (justifyV == "TOP") then
							point, parent, rpoint, x, y = "TOPLEFT", self, "TOPLEFT", column*cellWidth + cellWidth/2 - offset, -(row*cellHeight)
						elseif (justifyV == "BOTTOM") then
							point, parent, rpoint, x, y = "BOTTOMLEFT", self, "BOTTOMLEFT", column*cellWidth + cellWidth/2 - offset, -((row+1) * cellHeight)
						elseif (justifyV == "MIDDLE") then
							point, parent, rpoint, x, y = "LEFT", self, "LEFT", column*cellWidth + cellWidth/2 - offset, 0
						end
					else
						if (justifyV == "TOP") then
							point, parent, rpoint, x, y = "TOPLEFT", prevPlugin, "TOPRIGHT", padding, 0
						elseif (justifyV == "BOTTOM") then
							point, parent, rpoint, x, y = "BOTTOMLEFT", prevPlugin, "BOTTOMRIGHT", padding, 0
						elseif (justifyV == "MIDDLE") then
							point, parent, rpoint, x, y = "LEFT", prevPlugin, "RIGHT", padding, 0
						end
					end
				end
				
				if (column == 0) then
					x = x + edgePadding
				elseif (column == w - 1) then
					x = x - edgePadding
				end
				plugin:ClearAllPoints()
				plugin:SetPoint(point, parent, rpoint, x, y)
				prevPlugin = plugin.clickFrame
			end
		end
	end;
	
	SetPanelWidth = function(self, width)
		argCheck(width, 1, "number")
		self.width = width
		self:Update()
	end;

	SetPanelHeight = function(self, height)
		argCheck(height, 1, "number")
		self.height = height
		self:Update()
	end;

	SetPanelSize = function(self, width, height)
		argCheck(width, 1, "number")
		argCheck(height, 2, "number")
		self.width = width
		self.height = height
		self:Update()
	end;
	
	GetPanelWidth = function(self)
		return self.width or 1
	end;

	GetPanelHeight = function(self)
		return self.height or 1
	end;

	GetPanelSize = function(self)
		return self.width or 1, self.height or 1
	end;
	
}

Pull = function(parent)
	if (#gPanel.pool > 0) then
		local frame = tremove(gPanel.pool, 1)
		frame:SetParent(parent or UIParent)
		return frame
	else
		return CreateFrame("Frame", nil, parent or UIParent)
	end
end

Push = function(plugin)
	tinsert(gPanel.pool, Init(plugin))
end

Init = function(parent, plugin)
	plugin.tooltip = nil
	plugin.disabledTooltip = nil
	plugin.tooltipPosition = nil 
	plugin.type = nil
	plugin.interval = nil
	plugin.Update = nil
	plugin.OnLoad = nil
	plugin.OnEvent = nil
	plugin.elapsed = nil
	plugin.parent = parent
	plugin.func = nil
	plugin.menu = nil

	if (plugin.events) then
		wipe(plugin.events)
	else
		plugin.events = {}
	end

	if (plugin.scripts) then
		wipe(plugin.scripts)
	else
		plugin.scripts = {}
	end
	
	if (plugin.msg) then
		plugin.msg:SetText("")
		plugin.msg:ClearAllPoints()
		plugin.msg:SetPoint("LEFT", plugin, "LEFT")
	else
		local msg = plugin:CreateFontString(nil, "BACKGROUND")
		msg:SetFontObject(gPanel.fontObject)
		msg:SetPoint("LEFT", plugin, "LEFT")
		plugin.msg = msg
	end
	
	if (plugin.icon) then
		plugin.icon:SetTexture("")
		plugin.icon:ClearAllPoints()
		plugin.icon:SetPoint("LEFT", plugin, "LEFT")
	else
		local icon = plugin:CreateTexture(nil, "ARTWORK")
		icon:SetSize(gPanel.iconSize, gPanel.iconSize)
		icon:SetPoint("LEFT", plugin, "LEFT")
		plugin.icon = icon
	end
	
	if not(plugin.clickFrame) then
		local click = CreateFrame("Frame", nil, plugin)
		click:SetPoint("TOP", plugin.msg, "TOP", 0, 0)
		click:SetPoint("BOTTOM", plugin.msg, "BOTTOM", 0, 0)
		click:SetPoint("LEFT", plugin.icon, "LEFT", 0, 0)
		click:SetPoint("RIGHT", plugin.msg, "RIGHT", 0, 0)
		plugin.clickFrame = click
	end
	plugin.clickFrame.frame = plugin
	
	return plugin
end

------------------------------------------------------------------------------------------------------------
-- 	Cells
------------------------------------------------------------------------------------------------------------
CELL = {
	SetMaxPlugins = function(self, max)
		argCheck(max, 1, "number")
		if (max >= 0) then
			self.max = max
		end
	end;
	
	GetMaxPlugins = function(self)
		return self.max
	end;
	
	GetNumPlugins = function(self)
		return #self.plugins
	end;
	
	GetID = function(self)
		return self.index
	end;
	
	SetJustifyH = function(self, justify)
		argCheck(justify, 1, "string")
		if (justify ~= "LEFT") and (justify ~= "CENTER") and (justify ~= "RIGHT") then
			error(("SetJustifyH(justify): 'justify' - unknown value '%s' "):format(justify), 2)
		end
		self.justifyH = justify
	end;

	SetJustifyV = function(self, justify)
		argCheck(justify, 1, "string")
		if (justify ~= "TOP") and (justify ~= "MIDDLE") and (justify ~= "BOTTOM") then
			error(("SetJustifyV(justify): 'justify' - unknown value '%s' "):format(justify), 2)
		end
		self.justifyV = justify
	end;

	GetJustifyH = function(self)
		return self.justifyH or "LEFT"
	end;

	GetJustifyV = function(self)
		return self.justifyV or "TOP"
	end;

	-- spawns a plugin object, with an optional template type
	SpawnPlugin = function(self, type)
		argCheck(type, 1, "string", "nil")
		if (self:GetNumPlugins() == self:GetMaxPlugins()) then
			error(("SpawnPlugin(type) - The maximum allowed number of plugins (%d) is already spawned"):format(self:GetMaxPlugins()), 2)
		end
		local parent = self:GetParent()
		local plugin = Init(self, New(Pull(parent), PLUGIN)) -- set up an empty plugin with no type attached
		tinsert(self.plugins, plugin)
		
		if (type) then
			if (gPanel.plugins[type]) then
				plugin:SetAction(type)
			else
				error(("SpawnPlugin: No plugin template named '%s' registered"):format(type), 2)
			end
		end
		return plugin, #self.plugins
	end;

	KillPlugin = function(self, index)
		argCheck(index, 1, "number", "nil")
		if not(self.plugins[index]) then
			error(("KillPlugin(index) - Illegal 'index' (%d)"):format(index), 2)
		end
		self.plugins[index]:Disable() 
		Push(tremove(self.plugins, index))
	end;
	
	GetPlugin = function(self, index)
		argCheck(index, 1, "number", "nil")
		if not(self.plugins[index]) then
			error(("GetPlugin(index) - Illegal 'index' (%d)"):format(index), 2)
		end
		return self.plugins[index]
	end;

	GetParent = function(self)
		return self.parent
	end;
}

------------------------------------------------------------------------------------------------------------
-- 	Plugins
-----------------------------------------------------------------------------------------------------------
local PlaceTooltip, OnScript, OnEnter, OnLeave, OnMouseDown, OnEvent, OnUpdate, OnShow
do
	PlaceTooltip = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE")
		GameTooltip:ClearAllPoints()
		if ((GetScreenWidth() - self:GetRight()) > self:GetLeft()) then 			-- object on left side
			if ((GetScreenHeight() - self:GetTop()) > self:GetBottom()) then
				GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 8) 					-- bottom left side
			else 
				GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -8) 					-- top left side
			end
		else 																		-- object on right side
			if ((GetScreenHeight() - self:GetTop()) > self:GetBottom()) then 
				GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 8) 					-- bottom right side
			else 
				GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -8) 					-- top right side
			end
		end
	end

	OnScript = function(self, handler, ...)
		if (self.scripts) and (self.scripts[handler]) then
			self.scripts[handler](self, ...)
		end
	end

	OnEnter = function(self)
		if not(self:IsVisible()) then
			return
		end
		if (self.frame:IsEnabled()) and (self.frame.tooltip) then
			PlaceTooltip(self)
			gPanel.tooltips[self.frame.tooltip](self.frame)
		elseif not(self.frame:IsEnabled()) and (self.frame.disabledTooltip) then
			PlaceTooltip(self)
			gPanel.tooltips[self.frame.disabledTooltip](self.frame)
		end
		OnScript(self.frame, "OnEnter")
	end

	OnLeave = function(self)
		if not(self:IsVisible()) then
			return
		end
		if (self.frame.tooltip) or (self.frame.disabledTooltip) then
			GameTooltip:Hide()
		end
		OnScript(self.frame, "OnLeave")
	end

	OnMouseDown = function(self, button)
		if not((self.frame:IsEnabled()) and (self:IsVisible())) then
			return
		end
		if (button == "LeftButton") then
			if (self.frame.func) then
				self.frame.func(self.frame)
			end
		elseif (button == "RightButton") then
			if (self.frame.menu) then
				self.frame.menu(self.frame)
			end
		end
		OnScript(self, "OnMouseDown", button)
	end

	OnEvent = function(self, event, ...) 
		if (self:IsEnabled()) and (self:IsShown()) then
			if (event == "PLAYER_ENTERING_WORLD") then
				if (self.Update) then
					self:Update(event)
				end
			end
			if (self.OnEvent) then
				self:OnEvent(event, ...)
			end
			if (self.PostUpdate) then
				self:PostUpdate(event, ...)
			end
		end
	end

	OnUpdate = function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if (self.elapsed > (self.interval or 1)) then
			if (self.Update) then
				self:Update(elapsed or "OnUpdate")
			end
			if (self.PostUpdate) then
				self:PostUpdate("OnUpdate", elapsed)
			end
			self.elapsed = 0
		end
	end
	
	OnShow = function(self)
		OnEvent(self, "PLAYER_ENTERING_WORLD")
		self:PostUpdateSize()
	end

	PLUGIN = {
		-- set the plugin type to be shown in the plugin
		SetAction = function(self, type)
			argCheck(type, 1, "string")

			local template = gPanel.plugins[type]
			if not(template) then
				error(("SetAction: No plugin template named '%s' registered"):format(type), 2)
			end
			
			self:Disable() -- disable the old plugin
			
			self.type = type
			self.interval = template.interval
			self.tooltip = (template.tooltip == true) and type or template.tooltip
			self.disabledTooltip = (template.disabledTooltip == true) and type or template.disabledTooltip	
			self.func = template.func
			self.menu = template.menu
			self.Update = template.Update
			self.PostUpdate = template.PostUpdate
			self.OnLoad = template.OnLoad
			self.OnEvent = template.OnEvent
			
			wipe(self.scripts)
			if (template.scripts) then
				for handler, method in pairs(template.scripts) do
					self.scripts[handler] = method
				end
			end
		
			wipe(self.events)
			if (template.events) then
				for i = 1, #template.events do
					tinsert(self.events, template.events[i])
				end
			end
			
			self:Enable() -- enable the new plugin 
		end;
		
		GetAction = function(self)
			return self.type
		end;

		Enable = function(self)
			self.enabled = true
			self:RegisterEvent("PLAYER_ENTERING_WORLD") -- always register this
			if (self.events) and (#self.events > 0) then
				for index,event in pairs(self.events) do
					self:RegisterEvent(event)
				end
			end
			if (self.scripts) and (#self.scripts > 0) then
				for handler,func in pairs(self.scripts) do
					self:SetScript(handler, func)
				end
			end
			
			self.clickFrame:EnableMouse(true)
			self.clickFrame:SetScript("OnEnter", OnEnter)
			self.clickFrame:SetScript("OnLeave", OnLeave)
			self.clickFrame:SetScript("OnMouseDown", OnMouseDown)
			self:SetScript("OnShow", OnShow)
			self:SetDesaturated(false)
			
			if (self.OnLoad) then 
				self:OnLoad() 
			end
			if (self.interval) then 
				self:SetScript("OnUpdate", OnUpdate) 
			end
			self:SetScript("OnEvent", OnEvent)
			
			self:Update("OnEnable") 
			self:PostUpdateSize()
		end;

		Disable = function(self)
			self.enabled = nil
			self:UnregisterAllEvents()
			self.clickFrame:EnableMouse(false)
			self.clickFrame:SetScript("OnEnter", nil)
			self.clickFrame:SetScript("OnLeave", nil)
			self.clickFrame:SetScript("OnMouseDown", nil)
			self:SetScript("OnShow", nil)
			self:SetScript("OnUpdate", nil)
			self:SetScript("OnEvent", nil)
			if (self.scripts) and (#self.scripts > 0) then
				for handler,func in pairs(self.scripts) do
					self:SetScript(handler, nil)
				end
			end
			self:SetDesaturated(true)
			self:SetText(nil)
			self:SetTexture(nil)
		end;
		
		PostUpdateSize = function(self)
			local size = self.msg:GetWidth() + (self:GetTexture() and (gPanel.iconSize + 4) or 0)
			self:SetWidth(size)
			self:GetParent():Update() -- need to update parent panel layout on sizechanges
		end;

		IsEnabled = function(self)
			return self.enabled
		end;
		
		SetText = function(self, msg)
			argCheck(msg, 1, "string", "nil")
			self.msg:SetText(msg or "")
			if not(msg) or (msg == "") then
				self.clickFrame:SetAllPoints(self.icon)
			else
				self.clickFrame:SetPoint("TOP", self.msg, "TOP", 0, 0)
				self.clickFrame:SetPoint("BOTTOM", self.msg, "BOTTOM", 0, 0)
				self.clickFrame:SetPoint("LEFT", self.icon, "LEFT", 0, 0)
				self.clickFrame:SetPoint("RIGHT", self.msg, "RIGHT", 0, 0)
			end
			self:PostUpdateSize()
		end;
		
		GetText = function(self)
			return ((self.msg:GetText() ~= nil) and (self.msg:GetText() ~= "")) and self.msg:GetText()
		end;

		SetTexture = function(self, path)
			argCheck(path, 1, "string", "nil")
			self.icon:SetTexture(path or "")
			self.msg:ClearAllPoints()
			if (self.icon:GetTexture()) then
				self.msg:SetPoint("LEFT", self, "LEFT", gPanel.iconSize + 4, 0)
			else
				self.msg:SetPoint("LEFT", self, "LEFT", 0, 0)
			end
			self:PostUpdateSize()
		end;

		GetTexture = function(self)
			return ((self.icon:GetTexture() ~= nil) and (self.icon:GetTexture() ~= "")) and self.icon:GetTexture()
		end;
		
		SetTexCoord = function(self, ...)
			return self.icon:SetTexCoord(...)
		end;
		
		GetTexCoord = function(self)
			return self.icon:GetTexCoord()
		end;
		
		SetVertexColor = function(self, ...)
			return self.icon:SetVertexColor(...)
		end;
		
		GetVertexColor = function(self)
			return self.icon:GetVertexColor()
		end;
		
		SetDesaturated = function(self, n)
			argCheck(n, 1, "boolean", "nil")
			return (self:GetTexture()) and self.icon:SetDesaturated(n)
		end;
		
		SetTooltipPosition = function(self, position)
			argCheck(position, 1, "string", "nil")
			if (position) and (position ~= "VERTICAL") and (position ~= "HORIZONTAL") then
				error(("SetTooltipPosition(position) - 'position' must be 'VERTICAL' or 'HORIZONTAL', got '%s' "):format(position), 2)
			end
			self.tooltipPosition = position
		end;
		
	}
end

------------------------------------------------------------------------------------------------------------
-- 	Library API
------------------------------------------------------------------------------------------------------------

-- plugin template format:
--
-- 	plugin = {
-- 		tooltip = "<string>" -- name of the tooltip template
-- 		disabledTooltip = "<string>"; -- optional name of the tooltip template to call when disabled
-- 		interval = <number> -- optional minimum interval for the OnUpdate handler, will default to 1 sec
-- 		events = { "Event1", "Event2", ... }; -- list of events to listen for
-- 		scripts = { ["Handler"] = function(self, ...) end, ... }; -- extra script handlers
-- 		func = <function>(self) -- optional function to call when left-clicking
-- 		menu = <function>(self) -- optional function to call when right-clicking
-- 		Update = <function>(self) update function for the content. also used for the optional OnUpdate handler
-- 		OnEvent = <function>(self, event, ...) end -- optional event handler
-- 		OnLoad = <function>(self) -- optional function to call when initially created 
-- 	}
--
-- :RegisterPlugin(type, plugin)
-- 	@param type <string> unique name of the plugin template
-- 	@param plugin <table> the plugin table, format described above
gPanel.RegisterPlugin = function(self, type, plugin)
	argCheck(type, 1, "string")
	argCheck(plugin, 2, "table")
	if (gPanel.plugins[type]) then
		error(("RegisterPlugin: A plugin template named '%s' is already registered"):format(type), 2)
	end
	gPanel.plugins[type] = plugin
end

-- :RegisterTooltip(type, func)
-- 	@param type <string> unique name of the tooltip template
-- 	@param func <table> the tooltip function to be called, the plugin object is passed as 'self'
gPanel.RegisterTooltip = function(self, type, func)
	argCheck(type, 1, "string")
	argCheck(func, 2, "function")
	if (gPanel.tooltips[type]) then
		error(("RegisterTooltip: A tooltip template named '%s' is already registered"):format(type), 2)
	end
	gPanel.tooltips[type] = func
end

gPanel.SetFontObject = function(self, fontObject)
	argCheck(fontObject, 1, "table")
	if not(fontObject.GetObjectType) or (fontObject:GetObjectType() ~= "Font") then
		error("SetFontObject(fontObject) - Invalid 'fontObject'", 2)
	end
	self.fontObject = fontObject
end

local eventFrame = CreateFrame("Frame", nil, UIParent)
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if (event == "PLAYER_LOGIN") then
		for module,panels in pairs(gPanel.panels) do
			for i = 1, #panels do
				panels[i]:Update()
			end
		end
	end
end)
eventFrame:RegisterEvent("PLAYER_LOGIN")

------------------------------------------------------------------------------------------------------------
-- 	Embedded API
------------------------------------------------------------------------------------------------------------
local numPanels = 0
gPanel.New = function(self, name, parent)
	argCheck(name, 1, "string", "nil")
	argCheck(parent, 2, "table", "nil")

	if (name) and (self.__uiPanels) and (self.__uiPanels[name]) then
		error(("NewPanel([name[, parent]]): 'name' - A panel named '%s' already exists!"):format(name), 2)
	end
	
	local panel = New(CreateFrame("Frame", nil, parent or UIParent), PANEL)
	panel.cells = {}
	panel.width = 1
	panel.height = 1
	
	numPanels = numPanels + 1

	if not(gPanel.panels[self]) then
		gPanel.panels[self] = {}
	end
	tinsert(gPanel.panels[self], panel)
	
	if not(self.__uiPanels) then
		self.__uiPanels = {}
	end
	if (name) then
		self.__uiPanels[name] = panel
	end
	tinsert(self.__uiPanels, panel) 
	
	-- panel:SetScript("OnShow", panel.Update)
	-- panel:SetScript("OnHide", panel.Update) -- uh... really?
	panel:SetScript("OnSizeChanged", panel.Update)

	return panel
end

gPanel.Get = function(self, name)
	argCheck(name, 1, "string")
	if not(self.__uiPanels) or not(self.__uiPanels[name]) then
		error(("GetUIPanel(name): 'name' - no panel called '%s' registered"):format(name), 2)
	end
	return self.__uiPanels[name]
end

local mixins = { 
	CreateUIPanel = "New";
	GetUIPanel = "Get";
}
gPanel.Embed = function(self, target) 
	for i, v in pairs(mixins) do
		target[i] = self[v]
	end
	return target
end
