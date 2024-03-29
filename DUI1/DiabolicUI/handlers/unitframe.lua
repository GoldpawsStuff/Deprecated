local _, Engine = ...
local Handler = Engine:NewHandler("UnitFrame")
local Orb = Engine:GetHandler("Orb")
local StatusBar = Engine:GetHandler("StatusBar")

-- Lua API
local _G = _G
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_format = string.format
local string_match = string.match
local table_insert = table.insert
local table_remove = table.remove
local tonumber = tonumber

-- Blizzard API
local CreateFrame = _G.CreateFrame
local FriendsDropDown = _G.FriendsDropDown
local GameTooltip = _G.GameTooltip 
local ToggleDropDownMenu = _G.ToggleDropDownMenu

-- Client version constants
local ENGINE_MOP = Engine:IsBuild("MoP")

local UnitFrames = {} -- unitframe registry
local Elements = {} -- element registry
local Events = {} -- registry of frame and element event callbacks
local FrequentUpdates = {} -- registry of frame updates


-- UnitFrame Right Click Menus
--------------------------------------------------------------------------
-- get rid of stuff we don't want from the dropdown menus
-- * this appears to be causing taint for elements other than set/clear focus
-- * blizzard added fixes/secure menus for 3rd party frames in 5.2.0(?)
if not ENGINE_MOP then
	local UnWanted = {
		["SET_FOCUS"] = true,
		["CLEAR_FOCUS"] = true,

		-- WotLK
		["LOCK_FOCUS_FRAME"] = true,
		["UNLOCK_FOCUS_FRAME"] = true,
	
		-- Cata
		["MOVE_PLAYER_FRAME"] = true,
		["LOCK_PLAYER_FRAME"] = true,
		["UNLOCK_PLAYER_FRAME"] = true,
		["RESET_PLAYER_FRAME_POSITION"] = true,
		["PLAYER_FRAME_SHOW_CASTBARS"] = true,
		
		["MOVE_TARGET_FRAME"] = true,
		["LOCK_TARGET_FRAME"] = true,
		["UNLOCK_TARGET_FRAME"] = true,
		["TARGET_FRAME_BUFFS_ON_TOP"] = true,
		["RESET_TARGET_FRAME_POSITION"] = true
	}

	local UnitPopupMenus = _G.UnitPopupMenus
	for id,menu in pairs(UnitPopupMenus) do
		for i = #menu, 1, -1 do
			local option = UnitPopupMenus[id][i]
			if option and UnWanted[option] then
				table_remove(UnitPopupMenus[id], i)
			end
		end
	end
end

local UnitFrameMenu = function(self)
	if not self.unit then 
		return
	end
	if self.unit == "targettarget" or self.unit == "focustarget" or self.unit == "pettarget" then
		return
	end
	local unit = self.unit:gsub("(.)", strupper, 1)
	if _G[unit.."FrameDropDown"] then
		ToggleDropDownMenu(1, nil, _G[unit.."FrameDropDown"], "cursor")
		return
		
	elseif self.unit:match("party") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
		return
		
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
	end
end


-- Handler Updates
--------------------------------------------------------------------------
local OnEvent = function(self, event, ...)
end

local OnUpdate = function(self, elapsed)
	for object, elements in pairs(FrequentUpdates) do
		for element, frequency in pairs(elements) do
			if frequency.hz then
				frequency.elapsed = frequency.elapsed + elapsed
				if frequency.elapsed >= frequency.hz then
					Elements[element].Update(object, "FREQUENT", elapsed)
					frequency.elapsed = 0
				end
			else
				Elements[element].Update(object, "FREQUENT", elapsed)
			end
		end
	end
end




-- Unitframe Template
--------------------------------------------------------------------------
local UnitFrame = Engine:CreateFrame("Button")
local UnitFrame_MT = { __index = UnitFrame }

-- store some meta methods
local RegisterEvent = UnitFrame_MT.__index.RegisterEvent
local UnregisterEvent = UnitFrame_MT.__index.UnregisterEvent
local UnregisterAllEvents = UnitFrame_MT.__index.UnregisterAllEvents
local IsEventRegistered = UnitFrame_MT.__index.IsEventRegistered


UnitFrame.OnEvent = function(self, event, ...)
	if (not self:IsShown()) or (not Events[self]) or (not Events[self][event]) then
		return
	end
	
	local events = Events[self][event]

	for i = 1, #events do
		events[i](self, event, ...)
	end
end

UnitFrame.RegisterEvent = function(self, event, func)
	-- create the event registry if it doesn't exist
	if not Events[self] then
		Events[self] = {}
	end
	if not Events[self][event] then
		Events[self][event] = {}
	end
	
	local events = Events[self][event]

	if #events > 0 then
		-- silently fail for duplicate calls
		for i = #events, 1, -1 do
			if events[i] == func then
				return
			end
		end
	end

	-- insert the function into the event's registry
	table_insert(events, func)

	-- register the event
	if not IsEventRegistered(self, event) then
		RegisterEvent(self, event)
	end
end

UnitFrame.UnregisterEvent = function(self, event, func)
	-- silently fail if the event isn't even registered
	if not Events[self] or not Events[self][event] then
		return
	end

	local events = Events[self][event]

	if #events > 0 then
		-- find the function's id 
		for i = #events, 1, -1 do
			if events[i] == func then
				events[i] = nil -- remove the function from the event's registry
				if #events == 0 then
					UnregisterEvent(self, event) 
				end
			end
		end
	end
end

UnitFrame.UnregisterAllEvents = function(self)
	if not Events[self] then 
		return
	end
	for event, funcs in pairs(Events[self]) do
		for i = #funcs, 1, -1 do
			funcs[i] = nil
		end
	end
	UnregisterAllEvents(self)
end

UnitFrame.UpdateAllElements = function(self)
	if not self._enabledelements then
		return
	end
	for element in pairs(self._enabledelements) do
		Elements[element].Update(self, "PLAYER_ENTERING_WORLD")
	end
end

UnitFrame.EnableElement = function(self, element)
	if not self._elements then
		self._elements = {}
		self._enabledelements = {}
	end
	
	-- avoid duplicates
	local found
	for i = 1, #self._elements do
		if self._elements[i] == element then
			found = true
			break
		end
	end
	if not found then
		if Elements[element].Enable(self, self.unit) then
			table_insert(self._elements, element)
			self._enabledelements[element] = true
		end
	end
end

UnitFrame.DisableElement = function(self, element)
	-- silently fail if the element hasn't been enabled for the frame
	if not self._enabledelements or self._enabledelements[element] then
		return
	end
	
	Elements[element].Disable(self, self.unit)

	for i = #self._elements, 1, -1 do
		if self._elements[i] == element then
			self._elements[i] = nil
		end
	end
	
	self._enabledelements[element] = nil
	
	if FrequentUpdates[self][element] then
		-- remove the element's frequent update entry
		FrequentUpdates[self][element].elapsed = nil
		FrequentUpdates[self][element].hz = nil
		FrequentUpdates[self][element] = nil
		
		-- Remove the frame object's frequent update entry
		-- if no elements require it anymore.
		local count = 0
		for i,v in pairs(FrequentUpdates[self]) do
			count = count + 1
		end
		if count == 0 then
			FrequentUpdates[self] = nil
		end
		
		-- Disable the entire script handler if no elements
		-- on any frames require frequent updates. 
		count = 0
		for i,v in pairs(FrequentUpdates) do
			count = count + 1
		end
		if count == 0 then
			if Handler:GetScript("OnUpdate") then
				Handler:SetScript("OnUpdate", nil)
			end
		end
	end
end

UnitFrame.EnableFrequentUpdates = function(self, element, frequency)
	if not FrequentUpdates[self] then
		FrequentUpdates[self] = {}
	end
	FrequentUpdates[self][element] = { elapsed = 0, hz = tonumber(frequency) }
	if not Handler:GetScript("OnUpdate") then
		Handler:SetScript("OnUpdate", OnUpdate)
	end
end

UnitFrame.OnEnter = function(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:SetUnit(self.unit)
	end
	local r, g, b = GameTooltip_UnitColor(self.unit)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
end

UnitFrame.OnLeave = function(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end

UnitFrame.OnAttributeChanged = function(self, name, value)
	if (name == "unit") then
		self.unit = value
		self:UpdateAllElements()
	end
end

UnitFrame.GetRealUnit = function(self)
	return self:GetAttribute("real_unit")
end



-- Handler API
--------------------------------------------------------------------------
-- until we can build this into the Engine
local scriptHandlers = {}
local scriptFrame
Handler.SetScript = function(self, scriptHandler, script)
	scriptHandlers[scriptHandler] = script
	if scriptHandler == "OnUpdate" then
		if not scriptFrame then
			scriptFrame = CreateFrame("Frame", nil, Engine:GetFrame())
		end
		if script then 
			scriptFrame:SetScript("OnUpdate", function(self, ...) 
				script(Handler, ...) 
			end)
		else
			scriptFrame:SetScript("OnUpdate", nil)
		end
	end
end

Handler.GetScript = function(self, scriptHandler)
	return scriptHandlers[scriptHandler]
end

-- spawn and style a new unitframe
-- if the 'nonSecure' argument is true, 
Handler.New = function(self, unit, parent, styleFunc, nonSecure, ...)
	local secure = not nonSecure
	local object = setmetatable(Engine:CreateFrame("Button", nil, parent, secure and "SecureUnitButtonTemplate" or nil), UnitFrame_MT)
	object.CreateFrame = UnitFrame.CreateFrame
	object:SetFrameStrata("LOW")

	object.unit = unit 
	object.id = tonumber((string_match(unit, "%d+"))) -- the index of numbered units

	-- Apply these script before the styling function, 
	-- so the styling has the option to override them.
	object:SetScript("OnEnter", UnitFrame.OnEnter)
	object:SetScript("OnLeave", UnitFrame.OnLeave)
	object:RegisterForClicks("AnyUp")
	
	-- Apply the custom style function if it exists
	if styleFunc then
		styleFunc(object, object.unit, object.id, ...) -- pass both the unitid and unit index to the styling function
	end
	
	-- Parse the unitframe for known elements
	for element in pairs(Elements) do
		object:EnableElement(element, object.unit)
	end

	-- Store the actual unit for later,
	-- as it's needed by frames that sometimes change their unit,
	-- like pet and player frames when the player has a vehicle UI.
	object:SetAttribute("real_unit", unit)

	-- left click to target
	object:SetAttribute("unit", unit) 
	object:SetAttribute("*type1", "target")

	-- right click for menu
	if ENGINE_MOP then
		-- Secure menus, but has redundant stuff like unlocking the frames, 
		-- which can't be done at all with our custom frames. 
		object:SetAttribute("*type2", "togglemenu")
	else
		-- Tainted menus, but set focus is removed, so nothing bad ever happens.
		-- Frame unlocking and all that jazz have also been removed.
		object:SetAttribute("*type2", "menu")
		object.menu = UnitFrameMenu
	end
	
	-- alt left click to focus
	if unit == "focus" then
		object:SetAttribute("alt-type1", "macro")
		object:SetAttribute("macrotext", "/clearfocus")
	else
		object:SetAttribute("alt-type1", "focus")
	end
	
	-- These units won't get events fired for themselves,
	-- so we need to manually force their updates, 
	-- or stuff like their names will very often be wrong.
	if (unit:match("%w+target")) or (unit:match("(boss)%d?$") == "boss") then
	end

	object:SetScript("OnEvent", UnitFrame.OnEvent)
	object:SetScript("OnAttributeChanged", UnitFrame.OnAttributeChanged)
	object:HookScript("OnShow", UnitFrame.UpdateAllElements) 


	if (unit == "target") then
		object:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame.UpdateAllElements)
	elseif (unit == "mouseover") then
		object:RegisterEvent("UPDATE_MOUSEOVER_UNIT", UnitFrame.UpdateAllElements)
	elseif (unit == "focus") then
		object:RegisterEvent("PLAYER_FOCUS_CHANGED", UnitFrame.UpdateAllElements)
	elseif (unit:match("boss%d?$")) then
		object:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", object.UpdateAllElements, true)
		object:RegisterEvent("UNIT_TARGETABLE_CHANGED", UnitFrame.UpdateAllElements)
	elseif (unit:match("arena%d?$")) then
		object:RegisterEvent("ARENA_OPPONENT_UPDATE", UnitFrame.UpdateAllElements)
	elseif (unit:match("%w+target")) then
		local timer = 0
		local OnUpdate = function(self, elapsed)
			if not self.unit then
				return
			end
			timer = timer + elapsed
			if timer >= .5 then
				self:UpdateAllElements()
				timer = 0
			end
		end
		object:SetScript("OnUpdate", OnUpdate)
	end

	-- When we have a vehicleUI, we switch the player frame to vehicle, and pet frame to player. 
	if (unit == "player") or (unit == "playerpet") or (unit == "pet") then
		local VehicleUpdater = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
		VehicleUpdater:SetFrameRef("unitframe", object)
		VehicleUpdater:SetAttribute("real-unit", unit)
		VehicleUpdater:SetAttribute("unit", unit)
		VehicleUpdater.UpdateUnit = function(self, unit) object.unit = unit end

	
		--VehicleUpdater:SetAttribute("_onstate-vis", [[
		--	if newstate == "hide" then
		--		self:Hide();
		--	elseif newstate == "show" then
		--		self:Show();
		--	end
		--]])


		if (unit == "player") then
			VehicleUpdater:SetAttribute("_onstate-vehicleupdate", [[

				-- figure out if we have a new unit, and which
				local unit = self:GetAttribute("unit"); 
				local newUnit = (newstate == "invehicle") and "vehicle" or "player"; 

				-- update lua unit
				control:CallMethod("UpdateUnit", newUnit); 

				-- update secure unit
				self:GetFrameRef("unitframe"):SetAttribute("unit", newUnit); 

			]])

			-- We never hide the player unitframe. Ever. 
			RegisterStateDriver(object, "visibility", "show")
		else
			VehicleUpdater:SetAttribute("_onstate-vehicleupdate", [[

				-- figure out if we have a new unit, and which
				local unit = self:GetAttribute("unit"); 
				local newUnit = (newstate == "invehicle") and "player" or self:GetAttribute("real-unit"); 

				-- update lua unit
				control:CallMethod("UpdateUnit", newUnit); 

				-- update secure unit
				self:GetFrameRef("unitframe"):SetAttribute("unit", newUnit); 
			]])

			-- Pet frames are used as player frames when we have a vehicleui
			RegisterStateDriver(object, "visibility", "[@pet,exists][vehicleui]show;hide")
		end
	
		-- Register our vehicleswitcher
		--RegisterStateDriver(VehicleUpdater, "vehicleupdate", (ENGINE_MOP and "[overridebar][possessbar][shapeshift]" or "[bonusbar:5]") .. "[vehicleui] invehicle; notinvehicle")
		RegisterStateDriver(VehicleUpdater, "vehicleupdate", (ENGINE_MOP and "[possessbar][shapeshift]" or "[bonusbar:5]") .. "[vehicleui] invehicle; notinvehicle")
	else
		-- Other units only need their own existence checks. 
		RegisterStateDriver(object, "visibility", string_format("[@%s,exists]show;hide", object.unit))
	end

	-- Store the unitframe in the registry
	UnitFrames[object] = true 
	
	return object	
end

-- spawn and style a new group header
Handler.NewHeader = function(self, visibility_macro, parent, styleFunc)
end

-- register a widget/element
Handler.RegisterElement = function(self, element, enableFunc, disableFunc, updateFunc)
	Elements[element] = setmetatable({
		Enable = enableFunc,
		Disable = disableFunc,
		Update = updateFunc
	}, Element_MT)
end

Handler.OnEnable = function(self)
end
