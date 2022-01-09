--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gDropDown-1.0", 2
local gDropDown, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gDropDown) then return end 

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

------------------------------------------------------------------------------------------------------------
-- 	Widgets
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- 	Item Creation
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- 	Library API
------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------
-- 	Embedded API for addons/modules
------------------------------------------------------------------------------------------------------------

local mixins = {
} 

gDropDown.Embed = function(self, target) 
	for i, v in pairs(mixins) do
		target[i] = v
	end
	return target
end
