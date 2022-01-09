--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gDB-2.0", 3
local gDB, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gDB) then return end 

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

local GetName = function(self) 
	return self.GetName and self:GetName() or GetAddOnMetadata(addon, "Title") or addon or MAJOR
end

------------------------------------------------------------------------------------------------------------
-- 	Generic Database Handling
------------------------------------------------------------------------------------------------------------

-- :NewDataBase(name)
-- 	@param name <string> - name of your database
-- 	@return <table> - the new table object
gDB.NewDataBase = function(self, name)
	if (type(name) ~= "string") then 
		error((GetName(self) .. ": NewDataBase(name) 'name' - string expected, got %s"):format(type(name)), 2)
	end
	
	if not(self.__DBRegistry) then
		self.__DBRegistry = {}
	end
	
	if (self.__DBRegistry[name]) then
		error((GetName(self) .. ": NewDataBase(name): 'name' - a database named '%s' already exists"):format(name), 2)
	end

	self.__DBRegistry[name] = {}
	
	return self.__DBRegistry[name]
end

-- :GetDataBase(name[, silent])
-- 	@param name <string> - name of your database
-- 	@param silent <boolean> - 'true' to silently fail when database isn't found
-- 	@return <boolean,table> - the table object, or nil
gDB.GetDataBase = function(self, name, silent)
	if (type(name) ~= "string") then 
		error((GetName(self) .. ": GetDataBase(name) 'name' - string expected, got %s"):format(type(name)), 2)
	end
	
	if not(self.__DBRegistry) or not(self.__DBRegistry[name]) then
		if not(silent) then
			error((GetName(self) .. ": GetDataBase(name): 'name' - cannot find a database named '%s'"):format(name), 2)
		else
			return
		end
	end
	
	return self.__DBRegistry[name]
end

-- :DeleteDataBase(name)
-- 	@param name <string> - name of your database
-- 	@return <boolean> - 'true' if successfull, 'nil' if not
gDB.DeleteDataBase = function(self, name)
	if (type(name) ~= "string") then 
		error((GetName(self) .. ": DeleteDataBase(name) 'name' - string expected, got %s"):format(type(name)), 2)
	end
	
	if not(self.__DBRegistry) or not(self.__DBRegistry[name]) then
		error((GetName(self) .. ": DeleteDataBase(name): 'name' - cannot find a database named '%s'"):format(name), 2)
	end
	
	self.__DBRegistry[name] = nil
	
	return true
end

-- :ClearDataBase(name)
-- 	@param name <string> - name of your database
-- 	@return <boolean> - 'true' if successfull, 'nil' if not
gDB.ClearDataBase = function(self, name)
	if (type(name) ~= "string") then 
		error((GetName(self) .. ": ClearDataBase(name) 'name' - string expected, got %s"):format(type(name)), 2)
	end
	
	if not self.__DBRegistry[name] then
		error((GetName(self) .. ": ClearDataBase(name): 'name' - cannot find a database named '%s'"):format(name), 2)
	end
	
	wipe(self.__DBRegistry[name])
	
	return true
end

local mixins = {
	"NewDataBase", "DeleteDataBase", "GetDataBase", "ClearDataBase"
} 

gDB.Embed = function(self, target) 
	for _, v in pairs(mixins) do
		target[v] = self[v]
	end
	return target
end
