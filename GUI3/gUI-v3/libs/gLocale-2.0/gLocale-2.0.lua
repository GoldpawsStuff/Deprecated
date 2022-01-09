--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gLocale-2.0", 2
local gLocale, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gLocale) then return end 

-- Lua APIs
local assert = assert
local setmetatable = setmetatable
local tostring, type = tostring, type
local rawget, rawset = rawget, rawset

local assertfalse
local readmeta, writemeta, writedefaultmeta
local defaultLocale, currentLocale, clientLocale

-- for development purposes
local clientLocale = GAME_LOCALE or GetLocale()

-- too similar for us to separate
if (clientLocale == "enGB") then
	clientLocale = "enUS"
end

local GetName = function(self) 
	return self and self.GetName and self:GetName() or GetAddOnMetadata(addon, "Title") or addon or MAJOR
end

assertfalse = function() assert(false, GetName() .. ": Can't retrieve existing keys with locales retrieved with :NewLocale(), use :GetLocale() instead") end

readmeta = setmetatable({}, {
	-- accept new entries with this?
	-- they won't be inserted into the correct locale, just the current one,
	-- so addons need to make sure what they insert is in the current GetLocale() themselves!!
	__newindex = function(self, key, value)
		rawset(self, key, value == true and key or value) 
	end;
	
	-- fire a non-breaking error if an unknown index is requested,
	-- and fill in the missing index for us
	__index = function(self, key)
		rawset(self, key, key)
		geterrorhandler()(GetName() .. ": No entry exists for '" .. tostring(key) .. "'")
		return key
	end;
})

writemeta = setmetatable({}, {
	__newindex = function(self, key, value)
		rawset(currentLocale, key, value == true and key or value) 
	end;
	__index = assertfalse;
})

--
-- write proxy for locales created with :NewLocale
-- does not allow the user to overwrite existing entries
-- if you specify the same string twice, the second value will be ignored
writedefaultmeta = setmetatable({}, {
	__newindex = function(self, key, value)
		if not(rawget(currentLocale, key)) then
			rawset(currentLocale, key, value == true and key or value)
		end
	end;
	__index = assertfalse;
})

--
-- @param addon <string> can be anything, as long as its name is unique with this handler
-- @param locale <string> is the name of the locale, typically "enUS", "esMX", etc
-- @return <table> pointer to the new locale
gLocale.NewLocale = function(self, addon, locale, default)
	if (type(addon) ~= "string") then
		geterrorhandler()((MAJOR .. ": NewLocale(addon, locale) 'addon' - string expected, got %s"):format(type(addon)), 2)
		return 
	end
	
	if (type(locale) ~= "string") then
		geterrorhandler()((GetName() .. ": NewLocale(addon, locale) 'locale' - string expected, got %s"):format(type(locale)), 2)
		return 
	end

	self.__localeRegistry = self.__localeRegistry or {} 
	self.__localeRegistry[addon] = self.__localeRegistry[addon] or {} 

	if (self.__localeRegistry[addon][locale]) then
		geterrorhandler()((GetName() .. ": NewLocale(addon, locale) 'locale' - data for locale '%s' already exists"):format(type(locale)), 2)
		return 
	end

	-- return a nil value if the locale is neither the current client language nor the default locale
	if not(locale == clientLocale) and not(default) then
		return
	end
	
	self.__localeRegistry[addon][locale] = readmeta
	
	-- set the value of the current locale we're registering. Don't register more than one at once, or it'll bug out
	currentLocale = self.__localeRegistry[addon][locale]
	
	if (default) then
		defaultLocale = locale
		
		return writedefaultmeta
	end

	return writemeta
end

--
-- retrieve the current locale for the game client
gLocale.GetLocale = function(self, addon, silent)
	if not(self.__localeRegistry) or not(self.__localeRegistry[addon]) then
		if not(silent) then
			geterrorhandler()(GetName() .. ": GetLocale(addon) - couldn't find any registered locales for addon '%s'", 2)
		end
		return 
	end

	return self.__localeRegistry[addon][clientLocale] or self.__localeRegistry[addon][defaultLocale]
end

local mixins = {
	"NewLocale", "GetLocale"
} 

gLocale.Embed = function(self, target) 
	for _, v in pairs(mixins) do
		target[v] = self[v]
	end
	
	return target
end

