--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gCore-4.0", 25
local gCore, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gCore) then return end 

local _G = _G
local pcall = pcall
local loadstring, assert, error = loadstring, assert, error
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget
local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
local format, tonumber, tostring = string.format, tonumber, tostring
local strfind, gsub, strjoin, strlen, strmatch = string.find, string.gsub, string.join, string.len, string.match
local select, ipairs, pairs, next, type, unpack = select, ipairs, pairs, next, type, unpack

gCore.frame = gCore.frame or CreateFrame("Frame", "gCore40Frame") -- one frame to rule them all
gCore.addons = gCore.addons or {} -- all top level addon objects
gCore.dead = gCore.dead or {} -- dead objects
gCore.initialized = gCore.initialized or {} -- list of initialized objects
gCore.status = gCore.status or {} -- current status of all objects as returned by object:IsEnabled()
gCore.initQueue = gCore.initQueue or {} -- successfully created objects awaiting to be initialized
gCore.enableQueue = gCore.enableQueue or {} -- successfully initialized objects awaiting to be enabled
gCore.heap = gCore.heap or {} -- task scheduler priority queue
gCore.tableCache = gCore.tableCache or nil  -- cache of empty tables
gCore.numTables = gCore.numTables or 0 -- number of cached tables

local getSmartTable
getSmartTable = function() return setmetatable({}, { __index = function(self, key) self[key] = getSmartTable() return self[key] end }) end

gCore.events = gCore.events or getSmartTable() -- blizzard events and custom callbacks
gCore.buckets = gCore.buckets or {} -- bucket list
gCore.bucketEvents = gCore.bucketEvents or {} -- eventlist for the bucket list
gCore.tagPool = gCore.tagPool or {} -- global tag pool

-- locals for embedded addon/module API
local New
local GetName, GetParent
local NewAddon, GetAddon
local NewModule, GetModule, IterateModules
local EnableModule, DisableModule
local SetDefaultModuleState, GetDefaultModuleState
local SetDefaultModuleLibraries
local Kill, Init, Enable, Disable, IsEnabled, SetEnabled, IsInitialized
local SetAttribute, GetAttribute
local EmbedLibrary, EmbedLibraries, IterateEmbeds
local RegisterCallback, UnregisterCallback, UnregisterAllCallbacks, FireCallback
local RegisterEvent, RegisterAllEvents, UnregisterEvent, UnregisterAllEvents
local RegisterBucketEvent, UnregisterBucketEvent, UnregisterAllBucketEvents
local ScheduleTimer, ScheduleRepeatingTimer, CancelTimer, CancelAllTimers
local Abbreviate, RGB, RGBToHex, Split, Tag, RegisterTag, UnregisterTag 
local DuplicateTable, CleanTable, ValidateTable, CountTable, AddToTable
local RegisterGlobalForOptions, RegisterDefaultsForOptions, GetGlobalForOptions, GetDefaultsForOptions
local GetOptionsSet, GetCurrentOptionsSet, SetCurrentOptionsSetToProfile, ResetCurrentOptionsSetToDefaults
local ValidateCurrentOptionsSet, InitializeCurrentOptionsSet
local GetOptionsProfiles
local GetAncestor, GetFamilyTree
local CreateChatCommand
local RaidNotice, RaidWarning, UIErrorMessage

local MODULE

local noop = function() return end

_G.noop = noop -- global reference to our noop function

--
-- A little internal error handling mainly to prevent the module
-- from breaking from errors during the startup process
--	
local safeCall = function(func, ...)
	-- just a little fail-safe to avoid breaking the fail-safe...
	if type(func) == "function" then
		local ret = { pcall(func, ...) }
		
		if (ret[1]) then 
			if (#ret > 1) then
				return select(2, ret)
			end
		else
			-- fire a non-breaking error to the client, 
			-- but continue execution as otherwise normal
			geterrorhandler()(ret[2], 2)
			
			local module = ...
			if (module) and (module.GetName) then
				print(("The module '%s' has caused a problem."):format(module:GetName()))
			end
			
			-- also print the error massage to the chat,
			-- mainly because I want people to report these errors!
			print(ret[2])
		end
	end
end

--
-- a local strjoin duplicate that allows 'nil' values
-- 'nil' values will be listed as the text 'nil'
--
local smartJoin = function(separator, ...)
	local s = ""
	local n = select("#", ...)
	for i = 1, n do
		s = s .. (select(i, ...) or "nil")
		if (i < n) then
			s = s .. separator
		end
	end
	return s
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
			t = select(i, ...) or "nil" -- just a little fail-safe in case I forget the quotes
			if (type(value) == t) then return end
		end
	end

	local types = smartJoin(", ", ...)
	local name = strmatch(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	
	--
	-- note on offsets:
	-- 	an offset of 2 lists the line arcCheck was called from
	-- 	an offset of 3 lists the line the function argCheck was in was called from
	if (nobreak) then
		geterrorhandler()(("Bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
	else
		error(("Bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Root gCore API
------------------------------------------------------------------------------------------------------------

--	:New(old)
-- 	@param old <table> old object to inherit from
-- 	@return <table> which inherits from old
New = function(old)
	return (old) and setmetatable({}, { __index = old }) or {}
end

-- creates a new addon object
--
-- :NewAddon(name[, lib, lib, lib, ...])
-- 	@param name <string> unique name of the addon object. use the real/folder name of your addon to automatically initialize it
-- 	@param lib <string> any number of libraries to be included in your addon object
-- 	@return <table> your new addon object
gCore.NewAddon = function(self, name, ...)
	argCheck(name, 1, "string")
	
	if (self.addons[name]) then
		error(("An addon object named '%s' already exists"):format(name), 2)
	end
	
	local object = New(MODULE) -- create a new module with all common embeds
	object.name = name
	object.embeds = {}; -- list of embedded libraries
	object.modules = {}; -- list of child modules
	object.initQueue = {}; 
	object.enableQueue = {}; 
	object.__defaultModuleLibraries = {}; -- default embeds for child modules
	object.__isModule = nil -- not really need, just leaving it here for reference

	object:SetEnabledState(true) -- addon objects must always be enabled
	object:SetDefaultModuleState(true) -- child modules are enabled by default

	if (...) then 	object:EmbedLibraries(select(1, ...)) end -- embed libraries
	
	self.addons[name] = object -- insert object into the main addon pool
	
	if (self.initQueue) then
		tinsert(self.initQueue, object) -- insert the new addon into the parent's initQueue
	end
	
	return object
end

-- retrieves the 'name' addon object or 'nil' if none exist
--
-- gCore:GetAddon(name)
-- 	@param name <string> name of the top level addon object
-- 	@return <table,nil> the addon object, or 'nil' if it doesn't exist
gCore.GetAddon = function(self, name)
	argCheck(name, 1, "string")
	return self.addons[name]
end

--
-- default state of gCore top level addons is always 'enabled'
-- this cannot be changed
gCore.GetDefaultModuleState = function(self) return true end
gCore.SetDefaultModuleState = noop

--
-- gCore:IterateAddons()
-- 	@return <iterator> iterator over all gCore top level addons for use with for..in..
gCore.IterateAddons = function(self) return pairs(self.addons) end

--
-- shortcuts for events and scripts
gCore.SetScript = function(self, handler, script) 
	self.frame:SetScript(handler, script) 
end

gCore.GetScript = function(self, handler) 
	return self.frame:GetScript(handler) 
end

gCore.HasScript = function(self, handler) 
	return self.frame:HasScript(handler) 
end

gCore.RegisterEvent = function(self, event) 
	return self.frame:RegisterEvent(event) 
end

gCore.UnregisterEvent = function(self, event) 
	return self.frame:UnregisterEvent(event) 
end

gCore.IsEventRegistered = function(self, event) 
	return self.frame:IsEventRegistered(event) 
end

gCore.GetName = function(self)
	return MAJOR
end

------------------------------------------------------------------------------------------------------------
-- 	Table API
------------------------------------------------------------------------------------------------------------
--
-- various functions to create, recycle, and manage tables
-- the design intent is to lower memory usage, and provide common tools for data validation
-- 
-- only use the table cache for tables that are very frequently created/destroyed, 
-- the normal lua garbage collector can handle 'normal' tables
--

-- push a table into the stack, and wipe it clean
PushTable = function(self, t)
	wipe(t) -- clean out the table contents
	t.next = gCore.tableCache
	gCore.tableCache = t
	gCore.numTables = gCore.numTables + 1
end

-- retrieve an empty table from the stack
PopTable = function(self)
	local t = gCore.tableCache

	if (t) then
		gCore.tableCache = t.next
		gCore.numTables = gCore.numTables - 1
	end
	
	return t
end

-- retrieve an empty table from the stack, or create a fresh one
GetTable = function(self)
	return PopTable(self) or {}
end

--
-- deletes entries in the target table that aren't found in source
--
-- :CleanTable(target, source[, iteratechildren])
-- 	@param target <table> target table
-- 	@param source <table> source table
-- 	@param iteratechildren <boolean> 'true' if child tables should be iterated as well
-- 	@return <table> target table
CleanTable = function(self, target, source, iteratechildren)
	argCheck(target, 1, "table")
	argCheck(source, 2, "table")
	argCheck(iteratechildren, 3, "boolean", "nil")
	
	for i,v in pairs(target) do
		if (source[i] == nil) then
			target[i] = nil
		end
		
		if (iteratechildren) and (type(target[i]) == "table") and (type(source[i]) == "table") then
			self:CleanTable(target[i], source[i], iteratechildren)
		end
	end
	
	return target
end

--
-- fills in the holes in the target table with values from source
-- will clean out unknown keys unless 'noClean' is set to 'true'
--
-- this function is mainly intended for validating saved settings, 
-- and killing off deprecated entries
--
-- :ValidateTable(target, source[, noClean]) 
-- 	@param target <table> target table
-- 	@param source <table> source table
-- 	@param noClean <boolean>
-- 	@return <table> target table
ValidateTable = function(self, target, source, noClean) 
	argCheck(target, 1, "table")
	argCheck(source, 2, "table")
	argCheck(noClean, 3, "boolean", "nil")
	
	for i,v in pairs(source) do
		if (target[i] == nil) or (type(target[i]) ~= type(v)) then
			if (type(v) == "table") then
				target[i] = CopyTable(v) -- blizzard copytable function. might replace it with my own later on.
			else
				target[i] = v
			end
		elseif (type(target[i]) == "table") then
			target[i] = self:ValidateTable(target[i], v, noClean)
		end
	end
	
	if not(noClean) then
		self:CleanTable(target, source, true)
	end
	
	return target
end

--
-- duplicates the source table
-- differs from CopyTable() as this allows copying to existing tables,
-- it also removes entries from dest not found in source.
-- 
-- :DuplicateTable(source[, dest])
-- 	@param source <table> table to be duplicated/copied
-- 	@param dest <table> optional table to duplicate/copy to. If omitted, CopyTable will be called instead
-- 	@return <table> dest or a new table
DuplicateTable = function(self, source, dest)
	argCheck(source, 1, "table")
	argCheck(dest, 2, "table", "nil")

	if not(dest) then
		return CopyTable(source)
	end

	-- remove keys from dest that don't exist in source
	self:CleanTable(dest, source)

	-- set all the keys and values in dest to match source
	for key, val in pairs(source) do
		if (type(source[key]) == "table") then
			if not(type(dest[key]) == "table") then
				dest[key] = CopyTable(source[key]) -- this iterates child tables as well
			else
				self:DuplicateTable(source[key], dest[key])
			end
		else
			dest[key] = source[key]
		end
	end
	
	return dest
end

--
-- counts the total number of elements in a given table
--
-- :CountTable(t)
-- 	@param t <table> table to count
-- 	@return <number> number of elements in the table, 0 if empty
CountTable = function(self, t)
	argCheck(t, 1, "table")
	
	local n = 0
	for i,j in pairs(t) do
		n = n + 1
	end
	return n
end

--
-- adds elements to a table starting at the key [#t + 1]
--
-- :AddToTable(t, ...)
-- 	@param t <table> the table to add '...' to
--		@param ... <any> the elements to be added
AddToTable = function(self, t, ...)
	argCheck(t, 1, "table")
	
	for i = #t + 1, #t + 1 + select("#", ...) do
		t[i] = select(i, ...)
	end
end


------------------------------------------------------------------------------------------------------------
-- 	String Tag API
------------------------------------------------------------------------------------------------------------
local getTagPool = function()
	return gCore.tagPool 
end

--
-- our split function supports patterns
-- we used it for our tag function
Split = function(self, separator, str)
	argCheck(separator, 1, "string")
	argCheck(str, 2, "string")

	local t = GetTable() -- a new table for each call to avoid conflicting instances
	
	local pattern = "(.-)" .. separator
	local last_end = 1
	local s, e, cap = strfind(str, pattern, 1)
	
	while (s) do
		if (s ~= 1) or (cap ~= "") then
			tinsert(t, cap)
		end
		
		last_end = e + 1
		s, e, cap = strfind(str, pattern, last_end)
	end
	
	if (last_end <= #str) then
		cap = strsub(str, last_end)
		tinsert(t, cap)
	end
	
	return unpack(t)
end

RegisterTag = function(self, tag, func)
	argCheck(tag, 1, "string")
	argCheck(func, 2, "function")
	getTagPool()[tag] = func
end

UnregisterTag = function(self, tag)
	argCheck(tag, 1, "string")
	if (getTagPool()[tag]) then
		getTagPool()[tag] = nil
	end
end

--
-- :Tag(str)
-- 	@param str <string> string to be encoded
-- 	@return <string> the encoded string
Tag = function(self, str)
	argCheck(str, 1, "string")
	return (str:gsub("%[([^%]:]+):?(.-)%]", function(a, b) 
		return getTagPool()[a](self:Split("[,]+", b)) 
	end))
end


------------------------------------------------------------------------------------------------------------
-- 	String Conversion API
------------------------------------------------------------------------------------------------------------

--
-- Converts numeric rgba input values to a hexadecimal string
-- rgba values are automatically limited to the interval 0-1
--
-- :RGBToHex(r, g, b, a)
-- 	@param r <number> the red component, ranging from 0-1
-- 	@param g <number> the green component, ranging from 0-1
-- 	@param b <number> the blue component, ranging from 0-1
-- 	@param a <number> the opacity of the color, ranging from 0-1
-- 	@return <string> the color value in hex
do
	local rgb = function(n)
		return max(0, min(1, (n or 0)))
	end

	RGBToHex = function(self, r, g, b, a)
		argCheck(r, 1, "number")
		argCheck(g, 2, "number")
		argCheck(b, 3, "number")
		argCheck(a, 4, "number", "nil")
		
		if (a) then
			return format("%02x%02x%02x%02x", rgb(a) * 255, rgb(r) * 255, rgb(g) * 255, rgb(b) * 255)
		else
			return format("%02x%02x%02x", rgb(r) * 255, rgb(g) * 255, rgb(b) * 255)
		end
	end
end

--
-- Colors a string in a given color. Does not remove existing formatting.
-- rgb values are automatically limited to the interval 0-1
--
-- :RGB(str, r, g, b)
-- 	@param str <string> the string to be colored
-- 	@param r <number> the red component, ranging from 0-1
-- 	@param g <number> the green component, ranging from 0-1
-- 	@param b <number> the blue component, ranging from 0-1
-- 	@return <string> the colored string
RGB = function(self, str, r, g, b)
	argCheck(str, 1, "string")
	argCheck(r, 2, "number")
	argCheck(g, 3, "number")
	argCheck(b, 4, "number")
	
	return "|cFF" .. RGBToHex(r, g, b) .. str .. "|r"
end

--
-- Abbreviate a string to only show its uppercase letters
--
Abbreviate = function(self, str)
	argCheck(str, 1, "string")
	return (strlen(str) > 0) and (gsub(str, "[%l]", "")) or ""
end


------------------------------------------------------------------------------------------------------------
-- 	Event API
------------------------------------------------------------------------------------------------------------
-- these events will always be checked for, and can't be unregistered from gCore
local reservedEvents = {
	["ADDON_LOADED"] = true;
	["PLAYER_LOGIN"] = true;
	["PLAYER_ENTERING_WORLD"] = true;
	["PLAYER_LOGOUT"] = true;
}
local OnEvent, IsEvent
do
	local EVENT_FRAME = CreateFrame("Frame") -- making a separate frame for this, as we don't want to spam our OnEvent handler with all events
	EVENT_FRAME:RegisterAllEvents()

	-- returns true if 'event' is a blizzard event, false/nil for custom
	-- using a self learning metatable to speed up the process for multiple calls
	IsEvent = setmetatable({}, { __index = function(self, key)
		if (EVENT_FRAME:IsEventRegistered(key)) then
			self[key] = true
		else
			self[key] = false
		end
		return self[key]
	end })
	
	local initProxy
	initProxy = function(parent, event, ...)
		if not(parent:GetDefaultModuleState()) then return end
		local object
		while (#parent.initQueue > 0) do
			object = tremove(parent.initQueue, 1)
			if not(gCore.initialized[object]) and not(gCore.dead[object]) then
				gCore.initialized[object] = true
				
				safeCall(object.OnInit, object, event, ...)
				
				if not(gCore.dead[object]) then
					if not(parent.enableQueue) then
						parent.enableQueue = {}
					end
					tinsert(parent.enableQueue, object)

					if (object.initQueue) and (object:GetDefaultModuleState()) then
						initProxy(object, event, ...)
					end
				end
			end
		end
	end
	
	local enableProxy
	enableProxy = function(parent, event, ...)
		if not(parent:GetDefaultModuleState()) then return end

		local object
		while (#parent.enableQueue > 0) do
			object = tremove(parent.enableQueue, 1)
			if not(gCore.dead[object]) then
				safeCall(object.Enable, object, event, ...)
				-- only iterate through descendants if the default modulestate is 'enabled'
				if (object.enableQueue) and (object:GetDefaultModuleState()) then
					enableProxy(object, event, ...)
				end
			end
		end
	end
	
	local methodProxy
	methodProxy = function(t, method, event, ...)
		local object
		for i,v in pairs(t) do
			-- only fire this method if the object is enabled
			if (v:IsEnabled()) then
				v[method](v, event, ...)
				-- descendants will not be iterated unless the object is 'enabled'
				if (v.modules) then
					methodProxy(v.modules, method, event, ...)
				end
			end
		end
	end
	
	-- the callback system should fire off this as well, thus handling all events through the same handler
	OnEvent = function(self, event, ...)
		local arg1 = ...
		if (reservedEvents[event]) then
			if ((event == "ADDON_LOADED") and (arg1 ~= "Blizzard_DebugTools")) or (event == "PLAYER_LOGIN") then
				
				-- always empty the initqueues on startup events
				initProxy(gCore, event, ...)

				-- since addons can be loaded after the login event
				-- we check for actual login status rather than the login event itself
				if (IsLoggedIn()) then
					enableProxy(gCore, event, ...)
				end
			end
			
			if (event == "PLAYER_ENTERING_WORLD") then
				methodProxy(gCore.addons, "OnEnter", event, ...)
			end
			
			if (event == "PLAYER_LOGOUT") then
				methodProxy(gCore.addons, "OnDisable", event, ...)
			end
		end
		
		-- see if the event is registered in any of our addons
		-- 	*it should be noted that even the reserved events can be registered manually 
		-- 	and checked for using the event handler
		if (gCore.events[event]) then
			for object, funcs in pairs(gCore.events[event]) do
				for _, func in pairs(funcs) do
					if (type(func) == "function") then
						func(object, event, ...)
					else
						if not(object[event]) then
							error(("No function named '%s' in the object '%s'"):format(event, object:GetName()), 2)
						end
						object[event](object, event, ...)
					end
				end
			end
		end
		
		if (gCore.bucketEvents[event]) then
			-- iterate through all buckets containing the specified event
			local time = GetTime()
			for _, bucket in pairs(gCore.bucketEvents[event]) do
				-- see if the bucket is ready to be called, or still on cooldown
				if not(bucket.last) or (bucket.last + bucket.interval < time) then
					bucket.last = time
					bucket.func(bucket.parent, event, ...)
				end
			end
		end
	end
end

--
-- register an event 
-- object:RegisterEvent(event[, func])
-- 	@param event <string> name of the blizzard event to listen for
-- 	@param func <function> optional function to call. object[event] will be called if 'nil'
-- 	@return <function,nil> a reference to the optional function. used to unregister
RegisterEvent = function(self, event, func)
	argCheck(event, 1, "string")
	argCheck(func, 2, "function", "nil")

	if not(IsEvent[event]) then
		error((":RegisterEvent(event[, func]) - 'event' - The event '%s' is not a valid blizzard event"):format(event), 2)
	end

	if not(gCore:IsEventRegistered(event)) then 
		gCore:RegisterEvent(event) 
	end
	
	if (func) then
		for i = #gCore.events[event][self], 1, -1 do
			if (gCore.events[event][self][i] == func) then -- avoid duplicate entries of the same function
				return func -- return the pointer to the existing function for duplicate calls
			end
		end
		tinsert(gCore.events[event][self], func)
		return func
	else
		for _,isTrue in pairs(gCore.events[event][self]) do
			if (isTrue == true) then
				return
			end
		end
		tinsert(gCore.events[event][self], true) -- insert this dummy value to keep the table populated
	end
end

--
-- not really sure I want this
RegisterAllEvents = function(self)
end

--
-- unregister an event from the 'self' object
-- :UnregisterEvent(event[, func])
-- 	@param event <string> the name of the blizzard event to unregister
UnregisterEvent = function(self, event, func)
	argCheck(event, 1, "string")
	argCheck(func, 2, "function", "nil")

	if not(IsEvent[event]) then
		error((":UnregisterEvent(event) - 'event' - The event '%s' is not a valid blizzard event"):format(event), 2)
	end

	if (func) then
		for i = #gCore.events[event][self], 1, -1 do -- iterate backwards to allow usage of tremove
			if (gCore.events[event][self][i] == func) then
				tremove(gCore.events[event][self], i) -- found a match, now get rid of it
				break -- just break, don't return just yet
			end
		end
	else
		wipe(gCore.events[event][self]) -- no func was given, removing all entries for this custom callback event
	end
	
	-- unregister the event from the handler itself
	if not(reservedEvents[event]) and (self:CountTable(gCore.events[event]) == 0) then
		gCore:UnregisterEvent(event)
	end
end

--
-- unregisters all blizzard events registered by the 'self' object
-- :UnregisterAllEvents([func])
-- 	@param func <function> if provided, will only unregister callbacks pointing to this specific function
UnregisterAllEvents = function(self, func)
	argCheck(func, 1, "function", "nil")

	-- we have to iterate through the entire list every time, so fairly slow for now
	for event, objects in pairs(gCore.events) do
		if (IsEvent[event]) then -- only check for blizzard events, we need to leave the custom callbacks alone
			for object, funcs in pairs(objects) do
				if (object == self) then
					self:UnregisterEvent(event, func)
				end
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Bucket Event API
------------------------------------------------------------------------------------------------------------
--
-- register a bucket event
-- 	*buckets will fire for the first occurence of any of the 'events'
--		then the bucket will be unable to fire again until 'interval' seconds has passed
--
-- :RegisterBucketEvent(events, func, interval)
-- 	@param events <table,string> table of event names, or just single eventname as a string
-- 	@param func <function> function to call when the bucket fires. NOT optional!
-- 	@param interval <number> minimum number of seconds between each time the bucket will fire
RegisterBucketEvent = function(self, events, func, interval)
	argCheck(events, 1, "table", "string")
	argCheck(func, 2, "function") 
	argCheck(interval, 3, "number", "nil") 
	
	-- we need a fresh table here, to make sure its ID is unique for this session
	local bucket = {
		events = (type(events) == "string") and { events } or events;
		func = func;
		interval = interval or 0.1;
		parent = self;
	}
	gCore.buckets[bucket] = true 
	
	for _,event in pairs(events) do
		if (IsEvent[event]) and not(gCore:IsEventRegistered(event)) then -- register the event with the handler
			gCore:RegisterEvent(event)
		end
		if not(gCore.bucketEvents[event]) then
			gCore.bucketEvents[event] = {}
		end
		tinsert(gCore.bucketEvents[event], bucket) -- insert a pointer to this bucket in the bucket event list
	end
	
	return bucket
end

--
-- unregister a single bucket event from the 'self' object
-- :UnregisterBucketEvent(bucket)
-- 	@param bucket <table> the table returned by :RegisterBucketEvent()
UnregisterBucketEvent = function(self, bucket)
	argCheck(bucket, 1, "table")
	if not(gCore.buckets[bucket]) then
		error(("Bucket not found"), 2)
	end
	
	-- remove all pointers to this bucket from the bucket event list
	for event,_ in pairs(bucket.events) do
		local v
		for i = #gCore.bucketEvents[event], 1, -1 do
			v = gCore.bucketEvents[event][i]
			if (v == bucket) then
				tremove(gCore.bucketEvents[event], i)
			end
		end
	end
	gCore.buckets[bucket] = nil -- remove bucket reference from bucket list
	wipe(bucket) -- clean out the contents of the bucket
	bucket = nil -- kill the table altogether
end

--
-- removes all buckets registered by the 'self' object
-- object:UnregisterAllBucketEvents()
UnregisterAllBucketEvents = function(self)
	for bucket,_ in pairs(gCore.buckets) do
		if (bucket.parent == self) then
			self:UnregisterBucketEvent(self)
		end
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Custom Callback API
------------------------------------------------------------------------------------------------------------
--
-- the callback system in gCore-4.0 uses the same handler as the event system
-- the only thing that separates them is that the callback system only allows custom events, 
-- while the event system only allows blizzard events
--
-- also, the functionality in gCore-3.0 that allowed for multiple callbacks to be registered 
-- by the same module for the same event now applies to both events and callbacks,
-- but only works if a function is provided by both the :Register and :Unregister -calls
--

--
-- :RegisterCallback(event[, func])
-- 	@param event <string> name of the blizzard event to listen for
-- 	@param func <function> optional function to call. object[event] will be called if 'nil'
-- 	@return <function,nil> a reference to the optional function. used to unregister
RegisterCallback = function(self, event, func)
	argCheck(event, 1, "string")
	argCheck(func, 2, "function", "nil")
	
	if (IsEvent[event]) then
		error(("RegisterCallback(event[, func]): 'event' - '%s' is a blizzard event, please use :RegisterEvent() for it"):format(event), 2)
		return 
	end
	
	if (func) then
		for i = #gCore.events[event][self], 1, -1 do
			if (gCore.events[event][self][i] == func) then -- avoid duplicate entries of the same function
				return func -- return the pointer to the existing function for duplicate calls
			end
		end
		tinsert(gCore.events[event][self], func)
		return func
	else
		for _,isTrue in pairs(gCore.events[event][self]) do
			if (isTrue == true) then
				return
			end
		end
		tinsert(gCore.events[event][self], true) -- insert this dummy value to keep the table populated
	end
end

--
-- :UnregisterCallback(event[, func])
-- 	@param event <string> the name of the blizzard event to unregister
-- 	@param func <function> if provided, will only remove entries referencing this specific function
UnregisterCallback = function(self, event, func)
	argCheck(event, 1, "string")
	argCheck(func, 2, "function", "nil")

	if (IsEvent[event]) then
		error(("UnregisterCallback(event): 'event' - '%s' is a blizzard event, please use :UnregisterEvent() for it"):format(event), 2)
		return 
	end

	if (func) then
		for i = #gCore.events[event][self], 1, -1 do -- iterate backwards to allow usage of tremove
			if (gCore.events[event][self][i] == func) then
				tremove(gCore.events[event][self], i) -- found a match, now get rid of it
				return
			end
		end
	else
		wipe(gCore.events[event][self]) -- no func was given, removing all entries for this custom callback event
	end
end

--
-- unregisters all custom callbacks registered by the 'self' object
-- :UnregisterAllCallbacks([func])
-- 	@param func <function> if provided, will only unregister callbacks pointing to this specific function
UnregisterAllCallbacks = function(self, func)
	argCheck(func, 1, "function", "nil")

	-- we have to iterate through the entire list every time, so fairly slow for now
	for event, objects in pairs(gCore.events) do
		if not(IsEvent[event]) then -- exclude all blizzard events, only check the custom callback events
			for object,_ in pairs(objects) do
				if (object == self) then
					self:UnregisterCallback(event, func)
				end
			end
		end
	end
end

--
-- fire a custom callback
--
-- :FireCallback(event)
-- 	@param event <string> name of the (custom) event
FireCallback = function(self, event, ...)
	argCheck(event, 1, "string")

	if (IsEvent[event]) then
		error(("FireCallback(event[, ...]): 'event' - '%s' is a blizzard event, and can't be manually fired"):format(event), 2)
	end
	
	return gCore:GetScript("OnEvent")(self, event, ...)
end

------------------------------------------------------------------------------------------------------------
-- 	Task Scheduler API
------------------------------------------------------------------------------------------------------------
--
-- totally inspired by Paul Emmerich's great work in Deadly Boss Mods (http://www.curse.com/addons/wow/deadly-boss-mods)
--

do
	-- using a simplified binary min heap for our scheduling
	local heap = gCore.heap -- get a local pointer to the heap
	local firstFree = CountTable(gCore, heap) + 1
	local moveUp, moveDown, insert, remove, deleteMin
	local getMin, getLeft, getRight, getParent
	
	-- heap navigation
	getMin = function() return heap[1] end -- first/min element
	getLeft = function(i) return 2 * i end -- left child of index i
	getRight = function(i) return 2 * i + 1 end -- right child of index i
	getParent = function(i) return floor(i / 2) end -- parent of index i

	-- moves an element up
	moveUp = function(i)
		local parent = getParent(i)
		while (i > 1) and (heap[parent].time > heap[i].time) do
			heap[i], heap[parent] = heap[parent], heap[i] 
			i = parent
			parent = getParent(i)
		end
	end
	
	-- moves an element down
	moveDown = function(i)
		local j
		while (2 * i < firstFree) do 
			if (getRight(i) == firstFree) then 
				j = getLeft(i)
			elseif (heap[getLeft(i)].time < heap[getRight(i)].time) then 
				j = getLeft(i)
			else 
				j = getRight(i) 
			end

			if heap[i].time <= heap[j].time then 
				return
			end
			
			heap[i], heap[j] = heap[j], heap[i]
			i = j
		end
	end
	
	-- adds an element to the heap, and moves it up to where it belongs
	insert = function(element)
		heap[firstFree] = element
		moveUp(firstFree)
		firstFree = firstFree + 1
	end
	
	-- removes element(s) from the heap
	remove = function(parent, func, ...)
		local v, match
		local foundMatch = false
		for i = #heap, 1, -1 do 
			v = heap[i]
			if (not(func) or (func == v.func)) and (not(parent) or (parent == v.parent)) then
				match = true -- partial match found
				
				-- scan for unequal arguments
				if (func) then
					for i = 1, select("#", ...) do
						if (select(i, ...) ~= v[i]) then
							match = false
							break
						end
					end
				end
				
				if (match) then
					tremove(heap, i)
					firstFree = firstFree - 1
					foundMatch = true
				end
			end
		end
		
		if (foundMatch) then
			for i = floor((firstFree - 1) / 2), 1, -1 do
				moveDown(i)
			end
		end
	end
	
	-- deletes the top/min element from the heap
	deleteMin = function()
		firstFree = firstFree - 1 -- decrease total number of elements
		heap[1] = heap[firstFree] -- put the last index at the top
		heap[firstFree] = nil -- remove the last index, as it's now on the top
		moveDown(1) -- move the new top/min index down where it belongs
	end
	
	-- decide when the next available interval 'i' is after 's'
	local getNext = function(s, i)
		local t = GetTime()
		return t + (i - (t-s)%i)
	end
	
	gCore.frame:SetScript("OnUpdate", function(self, elapsed) 
		local time = GetTime()
		
		-- execute any and all tasks that has reached or exceded their appointed time
		local nextTask = getMin() -- get a pointer to the top/min task
		while (nextTask) and (nextTask.time <= time) do
			deleteMin() -- remove the top/min task from our heap, does not affect our 'nextTask' pointer
			nextTask.func(nextTask.parent, unpack(nextTask)) -- fire off the scheduled function with its stored arguments

			-- repeating timer?
			if (nextTask.interval) then
			
				-- neverending timer
				if not(nextTask.duration) then 
					gCore:Schedule(nextTask.parent, getNext(nextTask.time, nextTask.interval), nextTask.func, nextTask.interval, nil, nil, unpack(nextTask))
				
				-- timer with remaining duration
				elseif (nextTask.duration >= nextTask.interval) then
					gCore:Schedule(nextTask.parent, getNext(nextTask.time, nextTask.interval), nextTask.func, nextTask.interval, nextTask.duration - nextTask.interval, nextTask.endFunc, unpack(nextTask))

				-- timer that has run out of time... uh...
				elseif (nextTask.endFunc) then
					gCore:Schedule(nextTask.parent, nextTask.time + nextTask.duration, nextTask.endFunc)
				end
				
			end
			
			PushTable(self, nextTask) -- put our table in the stack for later use
			nextTask = getMin() -- refresh our pointer to the top/min task
		end
	end)
	
	--
	-- task scheduler. can be run directly from gCore, does not require 'addons' or 'modules'.
	--
	-- :Schedule(parent, time, func, interval, duration, endFunc, ...)
	-- 	@param parent <table,nil> the addon or module that schedule the timer
	-- 	@param time <number> actual point in time to run 'func'
	-- 	@param func <function> the function to run
	-- 	@param interval <number> interval for repeating timers
	-- 	@param duration <number> maximum duration for repeating timers
	-- 	@param endFunc <function, nil> function to be called after 'duration' ends
	-- 	@param ... <any> function arguments passed to 'func'
	gCore.Schedule = function(self, parent, time, func, interval, duration, endFunc, ...)
		local v = GetTable(self)
		v.time = time
		v.func = func
		v.interval = interval
		v.duration = duration
		v.endFunc = endFunc
		v.parent = parent -- the addon or module that scheduled it
		
		AddToTable(self, v, ...) -- store function arguments
		
		insert(v) -- into the heap with it
	end
	
	--
	-- :Unschedule(parent, func, ...)
	-- 	@param parent <table,nil> the addon or module that scheduled the timer
	-- 	@param func <function> the function to look for. if omitted, all timers by 'parent' will be removed
	-- 	@param ... <any> the exact same function parameters as were passed to :Schedule()
	gCore.Unschedule = function(self, parent, func, ...)
		argCheck(parent, 1, "table", "nil")
		argCheck(func, 2, "function", "nil")
		remove(parent, func, ...) 
	end
	
	--
	-- cancel all timers by all addons and modules
	--
	-- :UnscheduleAll()
	gCore.UnscheduleAll = function(self)
		remove() 
	end
end

local getTask = function(self)
	if not(self.__scheduledTasks) then
		self.__scheduledTasks = {}
	end
	return self.__scheduledTasks
end

local defaultInterval = 0.1

--
-- schedule a task
--
-- :ScheduleTimer(delay, func[, ...])
-- 	@param delay <number, nil> an initial delay before the timer starts running
-- 	@param func <function, nil> the function to be called, with '...' as its arguments
-- 	@param ... <any> optional argument list for 'func' passed (self, ...)
-- 	@return <number> a handle to be used with :CancelTimer(handle)
ScheduleTimer = function(self, delay, func, ...)
	argCheck(delay, 1, "number")
	argCheck(func, 2, "function")
	gCore:Schedule(self, delay + GetTime(), func, nil, nil, nil, ...)
end

--
-- schedule a repeating task
--
-- :ScheduleRepeatingTimer(interval, func[, delay[, duration[, endFunc[, ...]]]])
-- 	@param interval <number, nil> the interval in seconds. defaults to 0.1s if not given
-- 	@param func <function, nil> the function to be called on each interval, with '...' as its arguments
-- 	@param delay <number, nil> an initial delay before the timer starts running
-- 	@param duration <number, nil> a maximum duration for the timer to run in seconds
-- 	@param endFunc <function> a function to be called after the timer has finished, or been cancelled. no arguments can be passed.
-- 	@param ... <any> optional argument list for 'func' passed (self, ...)
-- 	@return <number> a handle to be used with :CancelTimer(handle)
ScheduleRepeatingTimer = function(self, interval, func, delay, duration, endFunc, ...)
	argCheck(interval, 1, "number", "nil")
	argCheck(func, 2, "function")
	argCheck(delay, 3, "number", "nil")
	argCheck(duration, 4, "number", "nil")
	argCheck(endFunc, 5, "function", "nil")
	gCore:Schedule(self, GetTime() + (delay or 0), func, interval or defaultInterval, duration, endFunc, ...)
end

--
-- cancel a scheduled task
--
-- :CancelTimer(func, ...)
CancelTimer = function(self, func, ...)
	argCheck(func, 1, "function")
	gCore:Unschedule(self, func, ...)
end

CancelAllTimers = function(self)
	gCore:Unschedule(self)
end

------------------------------------------------------------------------------------------------------------
-- 	SavedVariables Handling
------------------------------------------------------------------------------------------------------------
--
-- Note: The commands and handling of options by the modules is a temporary solution, 
-- while the structure of the savedvariables table is intended to be permanent, 
-- thus allowing me to easily upgrade the API later on. yay me.
--
-- 	Main problems with the current implementation:
-- 		- no implicit way to know what settings truly belongs to the 'self' object, and there should be.
-- 		- every module needs to tell itself where it lies in the addon/module hierachy. idiotic.
-- 		- any module can alter any other module's settings. this is messing with my zen.
--			- the [, module, module, module, ...] arguments are insanely clunky. like duplo where I wanted lego.
--
-- 	Reasons for the mess:
-- 		- it was faster for me to write it this way... *cough*
--
--		ToDo:
-- 		- allow only the main addon object to register globals
-- 		- create implicit functionality that gives each module direct access to ONLY its own settings
-- 		- create better ways of seeing the whole gCore addon object family tree, so to speak, 
-- 			as well as the current objects place in it. navigation within the table?
--
-- 
-- this is how the savedvariables global table will appear
--	local protoTypeMasterDB = {
--		-- the profile DB is identical in structure with the "charName" DBs listed below,
--		-- as they need to contain all the info that is found on a single character, 
--		-- both for the root addon object and all nested modules
--		["profiles"] = {
--			profileName = { -- this too is a 'protoTypeModuleDB' object
--				["generic"] = settings; -- root addon settings
--				["modules"] = {
--					moduleName = protoTypeModuleDB; -- forever nesting structure for module settings
--				};
--			};
--		};
--		["settings"] = {
--			realmName = {
--				charName = protoTypeModuleDB; -- list of addons/modules nested inside each other as below
--			};
--		};
--	}
--
-- this is the structure of the tables used by the "charName" and "moduleName" indexes
--	local protoTypeModuleDB = {
--		["generic"] = settings; -- settings for 'moduleName', these are what matches the structure of your local 'defaults'
--		["modules"] = {
--			moduleName = protoTypeModuleDB; -- forever nesting structure
--		};
--	}
--
-- all actual settings is stored in the ["generic"] indexes, which does NOT contain nested modules.
-- this is to avoid ValidateTable cleaning out sub-module settings from the saved variables
--
--

--
-- returns/formats a root DB for an addon object
local createRootDB = function(global)
	argCheck(global, 1, "string")

	if not(_G[global]) then _G[global] = {} end
	if not(_G[global].settings) then _G[global].settings = {} end
	if not(_G[global].profiles) then _G[global].profiles = {} end

	return _G[global]
end

local getGlobal = function(self)
	local db = _G[self.__savedVariablesGlobal]
	if not(db) then
		error("No global for saved variables has been registered yet, please use :RegisterGlobalForOptions(global) to do so", 2)
	end
	return db
end

--
-- returns/formats a module DB for a module object
local createModuleDB = function(db)
	argCheck(db, 1, "table", "nil")
	db = db or {}
	db.generic = db.generic or {}
	db.modules = db.modules or {}
	return db
end

--
-- returns realmName, charName
local GetRealmChar
do
	local realm = GetRealmName()
	local char = UnitName("player")
	GetRealmChar = function()
		return realm, char
	end
end

--
-- create a generic name for a character profile
-- any argument omitted will default to the current setting
local generateProfileName = function(realm, char)
	argCheck(realm, 1, "string", "nil")
	argCheck(char, 2, "string", "nil")
	local prealm, pchar = GetRealmChar()
	return (realm or prealm) .. " - " .. (char or pchar)
end

-- update the list of profiles, and return it
-- this list will include both stored custom profiles, 
-- as well as shortcuts to other character's settings
local updateLocalProfilesList = function(self)
	local db = getGlobal(self)
	wipe(self.__savedVariablesProfiles) -- we can safely wipe this table, as all the info is in the global table anyway

	-- insert stored custom profiles
	for i,v in pairs(db.profiles) do 
		self.__savedVariablesProfiles[i] = v
	end
	
	local playerRealm, playerChar = GetRealmChar()
	
	-- insert all stored character profiles
	for realm, chars in pairs(db.settings) do
		for char,_ in pairs(chars) do
			if not((realm == playerRealm) and (char == playerChar)) then -- ignore ourselves
				self.__savedVariablesProfiles[generateProfileName(realm, char)] = self:GetOptionsSet(realm, char, true) -- the pointer is to the specific module's options, if any
			end
		end
	end
	return self.__savedVariablesProfiles
end

--
-- register global variable for saved settings
-- as well as a table of default values
-- *default values will NOT be saved as a part of the table
--
-- :RegisterGlobalForOptions(global, defaults)
-- 	@param global <string> name of the global variable used for saved settings
-- 	@param defaults <table> table of default values
RegisterGlobalForOptions = function(self, global)
	if (gCore.dead[self]) then return end
	argCheck(global, 1, "string")
	createRootDB(global)
	self.__savedVariablesGlobal = global
	self.__savedVariablesDefaults = {} -- pointers to defaults for the current- and submodules
	self.__savedVariablesProfiles = {} -- pointers to the profiles
end

GetGlobalForOptions = function(self)
	if (gCore.dead[self]) then return end
	return self.__savedVariablesGlobal
end

--
-- register default settings for the root addon, or given module
--
-- :RegisterDefaultsForOptions(defaults[, module, module, module, ...])
-- 	@param defaults <table> default settings
RegisterDefaultsForOptions = function(self, defaults, ...)
	if (gCore.dead[self]) then return end
	argCheck(defaults, 1, "table")

	local db = getGlobal(self)
	local path = self.__savedVariablesDefaults
	local family = self:GetFamilyTree(true, not(self:IsModule()), true)
	
	-- make 'path' point to the correct sub-table,
	-- and create and missing ones
	if (family) then
		local module, newpath
		for i = 1, #family do
			module = family[i] -- get the next nested module
			argCheck(module, i, "string") -- validate it
			
			newpath = path -- point 'newpath' to the current path
			
			if not(newpath.modules) then newpath.modules = {} end -- create a table for nested modules
			if not(newpath.modules[module]) then newpath.modules[module] = {} end -- create a table for the current module

			path = newpath.modules[module] -- point the main path to the nested module
		end
	end
	
	path.defaults = defaults -- point the 'default' key of the current path to the provided defaults
end

--
-- returns defaults for root addon or given module
--
-- :GetDefaultsForOptions([module, module, module, ...])
-- 	@return <table> the original defaults table as given to :RegisterDefaultsForOptions()
GetDefaultsForOptions = function(self, ...)
	if (gCore.dead[self]) then return end

	local db = getGlobal(self)
	local path = self.__savedVariablesDefaults
	local family = self:GetFamilyTree(true, not(self:IsModule()), true)

	-- iterate down the table tree until we get where we want
	-- bug out if something is missing. accept no inaccuracies here.
	if (family) then
		local module, newpath
		for i = 1, #family do
			module = family[i] -- get the next nested module
			argCheck(module, i, "string") -- validate it
			
			newpath = path -- point 'newpath' to the current path
			if not(newpath.modules) then error("Illegal path, module library doesn't exist!", 2) end
			if not(newpath.modules[module]) then error("Illegal path, the module settings don't exist!", 2) end
			
			path = newpath.modules[module] -- point the main path to the nested module
		end
	end
	return path.defaults	
end

--
-- returns a specific options set
-- no arguments here are optional, and very little error checking is done
-- use with caution, as this function won't (yet) think for you
GetOptionsSet = function(self, realm, char, silent)
	if (gCore.dead[self]) then return end

	argCheck(realm, 1, "string")
	argCheck(char, 2, "string")
	
	local db = getGlobal(self)
	local path = db.settings[realm][char]
	local family = self:GetFamilyTree(true, not(self:IsModule()), true)

	if (family) then
		local module, newpath
		for i = 1, #family do
			module = family[i] -- get the next nested module
			argCheck(module, i, "string") -- validate it
			
			newpath = path -- point 'newpath' to the current path
			if not(newpath.modules) then return silent or error("Illegal path, module library doesn't exist!", 2) end
			if not(newpath.modules[module]) then return silent or error("Illegal path, the module settings don't exist!", 2) end
			
			path = newpath.modules[module] -- point the main path to the nested module
		end
	end
	return path.generic
end

--
-- return the current options set based on realm, char
-- *if called from within a sub-module, the settings for that module
-- will be returned instead of the main addon settings
--
-- if the requested settings does not exist, they will be created
-- IF and only IF you have registered defaults for those settings in advance!
--
-- :GetCurrentOptionsSet([module, module, module...])
-- 	@param module <string> optional name of module to get settings from
-- 	@return <table> pointer to the current options set
GetCurrentOptionsSet = function(self)
	if (gCore.dead[self]) then return end
	return self:GetOptionsSet(GetRealmChar())
end

--
-- set the current options set to the profile named 'profile'
--
-- :SetCurrentOptionsSetToProfile(profile[,module, module, module...])
-- 	@param profile <string,table> name of the saved custom profile to copy from, or pointer to the profile itself
SetCurrentOptionsSetToProfile = function(self, profile, ...)
	if (gCore.dead[self]) then return end

	argCheck(profile, 1, "string", "table")
	-- this must fire off some sort of callback about changed options,
	-- 	preferably the same callback as used by the menu system
	-- this must not change the table the current set points to, just the values within it,
	-- 	or it will break the functionality of various menus and stuff
	
	local source
	if (type(profile) == "string") then
		local profiles = self:GetOptionsProfiles()
		if not(profiles[profile]) then
			error(("Unknown options profile '%s' requested"):format(profile), 2)
		end
		source = profiles[profile]
	else
		source = profile
	end
	
	if (source) then
		local defaults = self:GetDefaultsForOptions()
		local db = self:GetCurrentOptionsSet()
		
		-- bug reported Dec 30, 2012: 'source' will sometimes be nil/boolean
		-- not strictly sure why this happens, a problem with :GetOptionsProfiles() maybe?
		if (type(source) ~= "table") then
			source = defaults
		end
		self:DuplicateTable(source, db)
		self:ValidateTable(db, defaults)
	end
end

--
-- reset saved settings to their defaults
-- also calls the reset function of gFrameHandler-2.0, 
-- and the refresh function of gOptionsMenu-1.0
ResetCurrentOptionsSetToDefaults = function(self)
	if (gCore.dead[self]) then return end

	local defaults = self:GetDefaultsForOptions() -- get the defaults
	local db = self:GetCurrentOptionsSet() -- get the current settings
	if (defaults) and (db) then
		self:DuplicateTable(defaults, db) -- reset current to a duplicate of the defaults
	end

	-- gFrameHandler-2.0 integration
	if (self.ResetAllObjectsToDefaults) then
		self:ResetAllObjectsToDefaults() -- reset all objects to their default positions
	end

	-- gOptionsMenu-1.0 integration
	if (self.RefreshBlizzardOptionsMenu) then
		self:RefreshBlizzardOptionsMenu() -- refresh options menus to match current saved settings
	end
	
	-- call the module's own post update function
	if (self.PostUpdateSettings) then
		self:PostUpdateSettings() -- this is where each module puts their own post updates
	end
	
	return db
end

--
-- validate your current options set with the current registered defaults
-- will fill in missing values with what is found in the 'defaults' table
--
-- will bug out if the 'defaults' for the requested object doesn't exist, 
-- so call this after both :RegisterGlobalForOptions() and :RegisterDefaultsForOptions()
ValidateCurrentOptionsSet = function(self, noClean)
	if (gCore.dead[self]) then return end

	local db = getGlobal(self)
	local family = self:GetFamilyTree(true, not(self:IsModule()), true)
	local defaults = self:GetDefaultsForOptions(family) -- get the defaults for the current addon/module
	local realm, char = GetRealmChar() -- get info about the current char

	-- huzzah!
	if not(db.settings[realm]) then db.settings[realm] = {} end
	if not(db.settings[realm][char]) then db.settings[realm][char] = {} end

	local path = db.settings[realm][char] -- and here we are... now
	
	-- iterate and create whatever is missing
	if (family) then 
		local module, newpath
		for i = 1, #family do
			module = family[i] -- get the next nested module
			argCheck(module, i, "string") -- validate it
			
			newpath = path -- point 'newpath' to the current path
			
			if not(newpath.modules) then newpath.modules = {} end -- create a table for nested modules
			if not(newpath.modules[module]) then newpath.modules[module] = {} end -- create a table for the current module
			
			path = newpath.modules[module] -- point the main path to the nested module
		end
	end
	
	-- kill off all faulty tables in our current path. keep the database clean!
	for i,v in pairs(path) do
		if (i ~= "generic") and (i ~= "modules") then
			path[i] = nil
		end
	end
	
	-- return or create the generic settings table for this specific addon or module
	if (path.generic) then
		return self:ValidateTable(path.generic, defaults, noClean)
	else
		path.generic = self:DuplicateTable(defaults)
		return path.generic
	end
end

do
	-- using this function to clean up old entries
	local factions = { Alliance = true, Horde = true, Neutral = true }
	ValidateDatabase = function(self)
		if (gCore.dead[self]) then return end

		local db = getGlobal(self)
		local family = self:GetFamilyTree(true, not(self:IsModule()), true)
		local defaults = self:GetDefaultsForOptions(family) -- get the defaults for the current addon/module
	
		for realm, chars in pairs(db.settings) do
			for char, content in pairs(chars) do
				-- remove old faction databases
				if (char) and (factions[char]) then
					db.settings[realm][char] = nil
				end
			end
		end
	end
end
--
-- all-in-one function for addons and modules 
-- to get their settings and validate them
InitializeCurrentOptionsSet = function(self, global, defaults, noClean)
	if (gCore.dead[self]) then return end

	argCheck(global, 1, "string")
	argCheck(defaults, 2, "table")
	
	self:RegisterGlobalForOptions(global)
	self:RegisterDefaultsForOptions(defaults)
	self:ValidateDatabase()
	self:ValidateCurrentOptionsSet(noClean)

	return self:GetCurrentOptionsSet()
end

--
-- returns a table of all profiles in the format [profileName] = protoTypeModuleDB (pointer to)
--
-- :GetOptionsProfiles()
-- 	@return <table> table of profiles; { [profileName] = protoTypeModuleDB(pointer to); }
GetOptionsProfiles = function(self, ...)
	return updateLocalProfilesList(self)
end

------------------------------------------------------------------------------------------------------------
-- 	Module API
------------------------------------------------------------------------------------------------------------
--
-- creates a new module
--
-- :NewModule(name, ...)
-- 	@param name <string> the name of the new module
-- 	@return <table> the new module object. nil if it fails.
NewModule = function(self, name, ...)
	argCheck(name, 1, "string")

	if (self.modules) and (self.modules[name]) then
		error(("A module named '%s' already exists in the addon object '%s'"):format(name, self:GetName()), 2)
		return
	end

	local object = New(MODULE) -- create a new module with all common embeds

	object.name = name
	object.parent = self -- pointer to the parent object
	object.embeds = {}; -- list of embedded libraries
	object.modules = {}; -- list of child modules
	object.initQueue = {}; 
	object.enableQueue = {}; 
	object.__defaultModuleLibraries = {}; -- default embeds for child modules
	object.__isModule = true -- this is a module, let others know
	object:SetDefaultModuleState(true) -- child modules are enabled by default
	
	-- embed libraries
	if (...) then
		object:EmbedLibraries(...) 
	end
	
	-- embed default libraries as optionally specified 
	if (self.__defaultModuleLibraries) then
		object:EmbedLibraries(unpack(self.__defaultModuleLibraries))
	end

	self.modules[name] = object -- insert the module into the parent's module pool

	if (self.initQueue) then
		tinsert(self.initQueue, object) -- insert the new module into the parent's initQueue
	end
	
	return object
end

--
-- return whether the 'self' object is a module or not
-- :IsModule()
-- 	@return <boolean, nil> 'true' for modules, 'false' or 'nil' for addon objects
IsModule = function(self)
	return self.__isModule
end

--
-- simple functionality to store attributes in the current object, 
-- without risking interference with existing methods
--
-- :SetAttribute(attribute, value)
-- 	@param attribute <string> the name of the value
-- 	@param value <any> the value you wish to store
SetAttribute = function(self, attribute, value)
	argCheck(attribute, 1, "string")
	if not(self.__attributes) then
		self.__attributes = {}
	end
	local oldvalue = self.__attributes[attribute]
	self.__attributes[attribute] = value
	self:FireCallback("GCORE_ATTRIBUTE_CHANGED", self, attribute, value, oldvalue)
end

--
-- retrieve an attribute from the current object
--
-- :GetAttribute(attribute, value)
-- 	@param attribute <string> the name of the value
-- 	@return <any> the contents of the attribute you requested, or 'nil' if it doesn't exist
GetAttribute = function(self, attribute)
	argCheck(attribute, 1, "string")
	if not(self.__attributes) then
		self.__attributes = {}
	end
	return self.__attributes[attribute]
end

-- 
-- retrieve the module name
--
-- :GetName()
-- 	@return <string> the internal module name
GetName = function(self, ...)
	return self.name
end

--
-- returns the parent addon/module
-- addon objects return 'nil' here
--
-- :GetParent()
-- 	@return <table> parent object
GetParent = function(self, ...)
	return self.parent
end

--
-- returns the addon object which is the topmost object in the hierarchy
-- :GetAncestor()
-- 	@return <table> the topmost object in the hierarchy, or 'self' if we're on top
GetAncestor = function(self)
	return gCore:GetAddon(self:GetFamilyTree())
end

--
-- returns the whole family tree leading to the 'self' object
-- first return value is the name of the top level addon for use with :GetAddon(name)
-- all following values (if any) are the names of the subsequent modules for use with :GetModule(name)
--
-- this function is intended to help create implicit functionality for options and optionsmenus
--
-- :GetFamilyTree([skipancestor[, skipself]])
-- 	@param skipancestor <boolean> if 'true', the top level object is omitted from the results
-- 	@param skipself <boolean> if 'true', the 'self' object is omitted from the results
-- 	@return name, name, name, name, ... <string> 
GetFamilyTree = function(self, skipancestor, skipself, asTable)
	local family = {}
	if not(skipself) then
		tinsert(family, 1, self:GetName())
	end
	local child
	local parent = self:GetParent()
	while (parent) do
		child = parent
		parent = child:GetParent()
		if (skipancestor) then
			if (parent) then
				tinsert(family, 1, child:GetName())
			end
		else
			tinsert(family, 1, child:GetName())
		end
	end
	
	if (#family > 0) then
		if (asTable) then
			return family
		else
			return unpack(family)
		end
	else
		return nil
	end
end

--
-- completely stop an object
-- :Kill()
Kill = function(self, ...)
	-- stop queued initialization
	if not(self:IsModule()) then
		for i = #gCore.initQueue, 1, -1 do
			if (gCore.initQueue[i] == self) then
				tremove(gCore.initQueue, i)
			end
		end
		for i = #gCore.enableQueue, 1, -1 do
			if (gCore.enableQueue[i] == self) then
				print("found self at index", i)
				tremove(gCore.enableQueue, i)
			end
		end
	end

	wipe(self.initQueue) 
	wipe(self.enableQueue) 
	
	-- iterate through children to disable them first
	if (self.modules) then
		local child
		for i = #self.modules, 1, -1 do
			child = tremove(self.modules, i)
			child:Kill()
		end
	end

	-- disable everything
	self:CancelAllTimers()
	self:UnregisterAllEvents()
	self:UnregisterAllBucketEvents()
	self:UnregisterAllCallbacks()

	gCore.dead[self] = true
	
	return self:Disable()
	-- self = nil
end

SetEnabledState = function(self, state)
	argCheck(state, 1, "boolean", "nil")
	self.__isEnabled = state
end

--
-- manually init a module
-- :Init()
Init = function(self, ...)
	if (self:IsInitialized()) or (gCore.dead[self]) then
		return
	end
	gCore.initialized[self] = true
	return self:OnInit(...)
end

--
-- manually enable a module
-- *will NOT enable descendants
-- *will fire off :OnInit() if it hasn't been done
-- :Enable()
Enable = function(self, ...)
	if (gCore.dead[self]) then return end
	if not(self:IsInitialized()) then
		self:Init()
	end
	self:SetEnabledState(true)
	gCore.status[self] = true
	return self:OnEnable(...)
end

--
-- manually disable a module
-- will also disable all descendants
-- :Disable()
Disable = function(self, ...)
	if (gCore.dead[self]) then return end
	self:SetEnabledState(false)
	-- iterate through children to disable them first
	if (self.modules) then
		local child
		for i = 1, #self.modules do
			child = self.modules[i]
			if (child:IsEnabled()) then
				child:Disable()
			end
		end
	end
	gCore.status[self] = nil
	return self:OnDisable(...)
end

SetEnabled = function(self, state, ...)
	if (state) then
		self:Enable(...)
	else
		self:Disable(...)
	end
end

--
-- return a module's current status
-- :IsEnabled()
-- 	@return <boolean,nil> 'true' if the module currently is enabled
IsEnabled = function(self, ...)
	return self.__isEnabled
end

IsInitialized = function(self, ...)
	return gCore.initialized[self]
end

--
-- retrieve a child module
-- :GetModule(name[, silent])
-- 	@param name <string> name of the module
-- 	@param silent <boolean> true to silently fail and return 'nil' when not found
-- 	@return <table> the child module
GetModule = function(self, name, silent)
	argCheck(name, 1, "string")
	if not(self.modules[name]) then
		if (silent) then
			return
		end
		error((":GetModule(name): 'name' - Cannot find a module named '%s'."):format(tostring(name)), 2)
	end
	return self.modules[name]
end

--
-- enable a child module
-- :EnableModule(name)
-- 	@param name <string> name of the module
EnableModule = function(self, name)
	argCheck(name, 1, "string")
	local module = self:GetModule(name)
	if not(module) then
		error((":GetModule(name): 'name' - Cannot find a module named '%s'."):format(tostring(name)), 2)
	end
	if (gCore.dead[module]) then return end
	return module:Enable()
end

--
-- disable a child module
-- will also disable 
-- :DisableModule(name)
-- 	@param name <string> name of the module
DisableModule = function(self, name)
	argCheck(name, 1, "string")
	local module = self:GetModule(name)
	if not(module) then
		error((":GetModule(name): 'name' - Cannot find a module named '%s'."):format(tostring(name)), 2)
	end
	if (gCore.dead[module]) then return end
	return module:Disable()
end

--
-- sets the default enabled state of child modules
-- 	*this only works prior to ADDON_LOADED and PLAYER_LOGIN
-- 	as it doesn't prevent modules from loading, it only excludes them
-- 	from the initial :OnEnable() call
--
-- :SetDefaultModulesState(state)
-- 	@param state <boolean,nil> 'true' automatically enables child modules
SetDefaultModuleState = function(self, state)
	argCheck(state, 1, "boolean", "nil")
	self.__defaultModuleState = state
end

--
-- returns the default enabled state of child modules
-- :GetDefaultModuleState()
-- 	@return <boolean> 'true' if child modules are enabled by default
GetDefaultModuleState = function(self)
	return self.__defaultModuleState
end

--
-- object:IterateModules()
-- 	@return <iterator> iterator over child modules for use with for..in..
IterateModules = function(self) return pairs(self.modules) end

--
-- object:IterateEmbeds()
-- 	@return <iterator> iterator over object embeds for use with for..in..
IterateEmbeds = function(self) return pairs(self.embeds) end

--
-- sets a list of libraries to embed in all child modules
-- this is in addition to any libraries listed in the :NewModule() call itself
-- :SetDefaultModuleLibraries([libraryName[,libraryName[, ... etc etc ]]])
SetDefaultModuleLibraries = function(self, ...) self.__defaultModuleLibraries = { ... } end

EmbedLibrary = function(object, name, offset)
	argCheck(name, 1, "string")
	argCheck(offset, 2, "number", "nil")
	
	local lib = LibStub:GetLibrary(name, true)
	if not(lib) then
		error(("Cannot find a library instance of %s"):format(name), offset or 2)
		return
	elseif (type(lib.Embed) == "function") then
		lib:Embed(object)
		if (object.embeds) then
			object.embeds[name] = true
		end
		return true
	else
		error(("Usage: EmbedLibrary(name): 'name' - Library '%s' is not Embed capable"):format(name), offset or 2)
		return
	end
end

EmbedLibraries = function(object, ...)
	if not(...) then return end
	for i = 1, select("#", ...) do
		EmbedLibrary(object, select(i, ...), 4)
	end
end

CreateChatCommand = function(self, commands, func)
	argCheck(commands, 1, "table", "string")
	argCheck(func, 2, "function")
	
	if not(self.__chatCommandPool) then self.__chatCommandPool = {} end
	
	local name = MAJOR .. "_" .. self:GetName() .. "ChatCommand_" .. (self:CountTable(self.__chatCommandPool) + 1)
	self.__chatCommandPool[name] = { 
		GetCommands = function()
			if (type(commands) == "table") then
				return unpack(commands)
			else
				return commands
			end
		end;
		func = function(args) 
			args = gsub(args, "[%s]+", " ")
			func(strsplit(" ", args))
		end;
	}

	_G.SlashCmdList[name] = self.__chatCommandPool[name].func
	
	if (type(commands) == "table") then 
		for i,v in pairs(commands) do
			if (type(v) ~= "string") then
				geterrorhandler()((self:GetName() .. ": CreateChatCommand(commands, func) 'commands' - values in this table must be strings, got %s at commands[%s]"):format(type(v), tostring(i)), 2)
				return 
			end
			_G["SLASH_" .. name .. i] = "/" .. v
		end
	elseif (type(commands) == "string") then 
		_G["SLASH_" .. name .. "1"] = "/".. commands
	end
end

UIErrorMessage = function(self, msg, r, g, b)
	UIErrorsFrame:AddMessage(msg, r or 1, g or 0, b or 0, 1.0)
end

RaidWarning = function(self, msg, r, g, b)
	RaidNotice_AddMessage(RaidWarningFrame, msg, { r = r or 1, g = g or 0.49, b = b or 0.04 })
end

RaidNotice = function(self, msg, r, g, b)
	if not(r) then
		RaidNotice_AddMessage(RaidBossEmoteFrame, msg, ChatTypeInfo["RAID_BOSS_EMOTE"])
	else
		RaidNotice_AddMessage(RaidBossEmoteFrame, msg, { r = r or 1, g = g or 0.49, b = b or 0.04 })
	end
end

MODULE = {
	-- initialization
	OnInit = noop;
	OnEnable = noop;
	OnEnter = noop;
	OnDisable = noop;
	
	noop = noop;

	-- core api
	GetName = GetName;
	GetParent = GetParent;
	GetAttribute = GetAttribute;
	SetAttribute = SetAttribute;
	Kill = Kill;
	Init = Init;
	Enable = Enable;
	Disable = Disable;
	IsEnabled = IsEnabled;
	SetEnabled = SetEnabled;
	IsInitialized = IsInitialized;
	NewModule = NewModule;
	GetModule = GetModule;
	IsModule = IsModule;
	EnableModule = EnableModule;
	DisableModule = DisableModule;
	SetEnabledState = SetEnabledState;
	IterateModules = IterateModules;
	IterateEmbeds = IterateEmbeds;
	SetDefaultModuleState = SetDefaultModuleState;
	GetDefaultModuleState = GetDefaultModuleState;
	SetDefaultModuleLibraries = SetDefaultModuleLibraries;
	EmbedLibrary = EmbedLibrary;
	EmbedLibraries = EmbedLibraries;
	GetAncestor = GetAncestor;
	GetFamilyTree = GetFamilyTree;
	
	-- task api
	ScheduleTimer = ScheduleTimer;
	ScheduleRepeatingTimer = ScheduleRepeatingTimer;
	CancelTimer = CancelTimer;
	CancelAllTimers = CancelAllTimers;
	
	-- event api
	RegisterBucketEvent = RegisterBucketEvent;
	UnregisterBucketEvent = UnregisterBucketEvent;
	UnregisterAllBucketEvents = UnregisterAllBucketEvents;
	FireCallback = FireCallback;
	RegisterCallback = RegisterCallback;
	UnregisterCallback = UnregisterCallback;
	UnregisterAllCallbacks = UnregisterAllCallbacks;
	RegisterEvent = RegisterEvent;
	RegisterAllEvents = RegisterAllEvents;
	UnregisterEvent = UnregisterEvent;
	UnregisterAllEvents = UnregisterAllEvents;
	
	-- saved variables api
	RegisterGlobalForOptions = RegisterGlobalForOptions;
	RegisterDefaultsForOptions = RegisterDefaultsForOptions;
	GetGlobalForOptions = GetGlobalForOptions;
	GetDefaultsForOptions = GetDefaultsForOptions;
	GetOptionsSet = GetOptionsSet;
	GetCurrentOptionsSet = GetCurrentOptionsSet;
	SetCurrentOptionsSetToProfile = SetCurrentOptionsSetToProfile;
	ResetCurrentOptionsSetToDefaults = ResetCurrentOptionsSetToDefaults;
	ValidateDatabase = ValidateDatabase;
	ValidateCurrentOptionsSet = ValidateCurrentOptionsSet;
	InitializeCurrentOptionsSet = InitializeCurrentOptionsSet;
	GetOptionsProfiles = GetOptionsProfiles;
	CreateChatCommand = CreateChatCommand;

	-- table api
	AddToTable = AddToTable;
	CleanTable = CleanTable;
	CountTable = CountTable;
	DuplicateTable = DuplicateTable;
	ValidateTable = ValidateTable;
	
	-- string api
	Abbreviate = Abbreviate;
	RGB = RGB;
	RGBToHex = RGBToHex;
	Split = Split;
	Tag = Tag;
	RegisterTag = RegisterTag;
	UnregisterTag = UnregisterTag;
	
	-- some simple stuff
	RaidWarning = RaidWarning;
	RaidNotice = RaidNotice;
	UIErrorMessage = UIErrorMessage;
	
	argCheck = function(self, ...) return argCheck(...) end;
}

gCore:RegisterEvent("ADDON_LOADED")
gCore:RegisterEvent("PLAYER_LOGIN")
gCore:RegisterEvent("PLAYER_ENTERING_WORLD")
gCore:RegisterEvent("PLAYER_LOGOUT")
gCore:SetScript("OnEvent", OnEvent)

