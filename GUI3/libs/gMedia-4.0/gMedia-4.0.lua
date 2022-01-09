--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gMedia-4.0", 2
local M, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(M) then return end 

-- Lua API
local assert, error = assert, error
local pairs, select = pairs, select
local strmatch = string.match
local type = type

local meta
local locale = GetLocale()

local argCheck
local metaTable
local getMediaPool, getPath 
local setValue, setRootValue

do
	--
	-- argCheck(value, num[, nobreak], ...)
	-- 	@param value <any> the argument to check
	-- 	@param num <number> the number of the argument in your function 
	-- 	@param nobreak <boolean> optional. if true, then a non-breaking error will fired instead
	-- 	@param ... <string> list of argument types
	argCheck = function(value, num, ...)
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
end

-- 
-- disable direct modifications of the stored media
metaTable = function() return setmetatable({}, {
	__newindex = function(self, key, value)
		geterrorhandler()(M:GetName() .. ": Illegal action. Use :NewMedia(mediaType, key, path) to register new media!", 2)
		return
	end;
	__index = function(self, key)
		if not(key) then
			geterrorhandler()(M:GetName() .. ": No entry exists for '" .. tostring(key) .. "'", 2)
		else
			return rawget(self, key)
		end
	end;
}) end

--
-- use this function to retrieve a pointer to your mediatable
getMediaPool = function(self, mediaType)
	argCheck(self, 1, "table")
	argCheck(mediaType, 2, "string", "nil")
	if not(self.__mediaRegistry) then
		self.__mediaRegistry = metaTable()
		-- copy gMedia default media to all new libraries
		if (self ~= M) then
			for cat, content in pairs(M.__mediaRegistry) do
				for key, value in pairs(content) do
					self:NewMedia(cat, key, value, true)
				end
			end
		end
	end
	if (mediaType) and not(self.__mediaRegistry[mediaType]) then
		rawset(self.__mediaRegistry, mediaType, metaTable())
		-- self.__mediaRegistry[mediaType] = metaTable()
	end
	return (mediaType) and self.__mediaRegistry[mediaType] or self.__mediaRegistry
end

setRootValue = function(self, key, value)
	argCheck(key, 1, "string")
	rawset(getMediaPool(self), key, value)
end

setValue = function(self, mediaType, key, value)
	argCheck(mediaType, 1, "string")
	argCheck(key, 2, "string")
	rawset(getMediaPool(self)[mediaType], key, value)
end

getPath = function(self)
	return self and self.__defaultMediaPath or ""
end

------------------------------------------------------------------------------------------------------------
-- 	API
------------------------------------------------------------------------------------------------------------
-- :NewMedia(mediaType, key, path)
-- 	@param mediaType <string> - refers to an internal category like "Background", "Button", "Font" or "Border"
-- 	@param key <string> - is the name of your media, which can be anything you like as long as it's unique for its mediaType.
-- 	@param path <string,table> - is the full path and filename of the media OR a table containing additional info (like with backdrops) 
-- 	@return <boolean> - 'true' if media is succesfully registered, nil otherwise
M.NewMedia = function(self, mediaType, key, path, overrideDefaultPath)
	argCheck(mediaType, 1, "string")
	argCheck(key, 2, "string")
	argCheck(path, 3, "string", "table")
	
	if (getMediaPool(self, mediaType)[key]) and (self:IsMediaWriteProtected()) then
		geterrorhandler()((self:GetName() .. ": NewMedia(mediaType, key, path) 'key' - '%s' already exists, use :SetMediaWriteProtected(false) to disable write protection"):format(type(key)), 2)
		return 
	end

	setValue(self, mediaType, key, (type(path) == "string") and self:GetMediaPath(path, overrideDefaultPath) or path)
	
	return true
end

-- :GetMedia(mediaType, key)
-- 	@mediaType <string> - refers to an internal category like "Background", "Button", "Font" or "Border"
-- 	@key <string> - is the name of your media
-- 	@return <string> - path to the media
M.GetMedia = function(self, mediaType, key)
	argCheck(mediaType, 1, "string")
	argCheck(key, 2, "string")
	
	return getMediaPool(self, mediaType)[key]
end

--
-- Sets the default path when creating new media
M.SetDefaultMediaPath = function(self, path)
	argCheck(path, 1, "string")
	self.__defaultMediaPath = path
end

--
-- Returns the current default media path or ""
M.GetDefaultMediaPath = function(self)
	return getPath(self)
end

M.GetMediaPath = function(self, path, overrideDefaultPath)
	argCheck(path, 1, "string")
	return (overrideDefaultPath) and path or self:GetDefaultMediaPath() .. path
end

-- 
-- Toggle write protection of existing media
M.SetMediaWriteProtected = function(self, state)
	if (state) then
		setRootValue(self, "__isWriteProtected", true)
	else
		setRootValue(self, "__isWriteProtected", nil)
	end
end

M.IsMediaWriteProtected = function(self)
	return getMediaPool(self).__isWriteProtected
end

M.GetName = function(self)
	return MAJOR
end

local mixins = {
	"NewMedia", "GetMedia", 
	"SetMediaWriteProtected", "IsMediaWriteProtected", 
	"SetDefaultMediaPath", "GetDefaultMediaPath", "GetMediaPath"
} 

M.Embed = function(self, target) 
	for _, v in pairs(mixins) do
		target[v] = self[v]
	end
	return target
end

------------------------------------------------------------------------------------------------------------
-- 	Default Media (All Blizzard)
------------------------------------------------------------------------------------------------------------
M:NewMedia("Background", "Blank", [[Interface\ChatFrame\ChatFrameBackground]])
M:NewMedia("Background", "Blizzard Tooltip", [[Interface\Tooltips\UI-Tooltip-Background]])
M:NewMedia("Background", "Blizzard Dialog", [[Interface\DialogFrame\UI-DialogBox-Background]])
M:NewMedia("Background", "Blizzard Event Notification", [[Interface\Calendar\EventNotification]])

M:NewMedia("Border", "Blizzard Dialog", [[Interface\DialogFrame\UI-DialogBox-Border]])
M:NewMedia("Border", "Blizzard Dialog Gold", [[Interface\DialogFrame\UI-DialogBox-Gold-Border]])
M:NewMedia("Border", "Blizzard Tooltip", [[Interface\Tooltips\UI-Tooltip-Border]])

M:NewMedia("Button", "Glow", [[Interface\Buttons\UI-ActionButton-Border]])
M:NewMedia("Button", "Pass", [[Interface\Buttons\UI-GroupLoot-Pass-Up]])
M:NewMedia("Button", "PassDown", [[Interface\Buttons\UI-GroupLoot-Pass-Down]])
M:NewMedia("Button", "PassHighlight", [[Interface\Buttons\UI-GroupLoot-Pass-Highlight]])

M:NewMedia("Statusbar", "Blizzard", [[Interface\TargetingFrame\UI-Statusbar]])
M:NewMedia("Statusbar", "Spark", [[Interface\CastingBar\UI-CastingBar-Spark]])

M:NewMedia("Icon", "WorldState Alliance", [["Interface\WorldStateScore\AllianceIcon"]])
M:NewMedia("Icon", "WorldState Horde", [["Interface\WorldStateScore\HordeIcon"]])

M:NewMedia("Iconstring", "HeroicSkull", [[|TInterface\LFGFrame\UI-LFG-ICON-HEROIC:0:0:0:0|t]])
M:NewMedia("Iconstring", "Role-DPS", [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:0:64:64:20:39:22:41|t]])
M:NewMedia("Iconstring", "Role-Heal", [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:0:64:64:20:39:22:41|t]])
M:NewMedia("Iconstring", "Role-Tank", [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:0:64:64:0:19:22:41|t]])

-- 2002.ttf 2002 (Korean) - ChatFontNormal, GameFontNormal
-- 2002B.ttf 2002B (Korean)
-- ARHei.ttf AR CrystalzcuheiGBK Demibold (Chinese) - ChatFontNormal
-- ARIALN.TTF Arial Narrow
-- ARKai_C.ttf AR ZhongkaiGBK Medium (Chinese)
-- ARKai_T.ttf AR ZhongkaiGBK Medium (Chinese) - GameFontNormal
-- bHEI00M.ttf AR Heiti2 Medium B5 (Chinese)
-- bHEI01B.ttf AR Heiti2 Bold B5 (Chinese)
-- bKAI00M.ttf AR Kaiti Medium B5 (Chinese)
-- bLEI00D.ttf AR Leisu Demi B5 (Chinese)
-- FRIZQT__.TTF Friz Quadrata TT (Latin)
-- FRIZQT___CYR.TTF FrizQuadrataCTT (Cyrilic) - GameFontNormal
-- K_Damage.TTF YDIWingsM (Korean)
-- K_Pagetext.TTF YDIMokM (Korean)
-- MORPHEUS.TTF Morpheus (Latin)
-- MORPHEUS_CYR.TTF Morpheus Cyr (Cyrilic)
-- NIM_____.ttf Nimrod MT (Latin, Cyrilic)
-- SKURRI.TTF Skurri (Latin)
-- SKURRI_CYR.TTF Skurri Cyr (Cyrilic) 

M:NewMedia("Font", "Arial Narrow", [[Fonts\ARIALN.TTF]])
M:NewMedia("Font", "Friz Quadrata", [[Fonts\FRIZQT__.TTF]])
M:NewMedia("Font", "Morpheus", [[Fonts\MORPHEUS.TTF]])
M:NewMedia("Font", "Skurri", [[Fonts\SKURRI.TTF]])

M:NewMedia("Backdrop", "Blank", {
	bgFile = M:GetMedia("Background", "Blank");
	insets = { 
		bottom = 0; 
		left = 0; 
		right = 0; 
		top = 0; 
	};
})

M:NewMedia("Backdrop", "Blank-Inset", {
	bgFile = M:GetMedia("Background", "Blank");
	edgeFile = M:GetMedia("Background", "Blank");
	edgeSize = 1;
	insets = { 
		bottom = -1; 
		left = -1; 
		right = -1; 
		top = -1; 
	};
})

M:NewMedia("Backdrop", "Border", {
	edgeFile = M:GetMedia("Background", "Blank");
	edgeSize = 1;
	insets = {
		left = 1;
		right = 1;
		top = 1;
		bottom = 1;
	};
})

M:NewMedia("Backdrop", "Blank-Border", {
	bgFile = M:GetMedia("Background", "Blank");
	edgeFile = M:GetMedia("Background", "Blank");
	edgeSize = 1;
	insets = {
		left = 1;
		right = 1;
		top = 1;
		bottom = 1;
	};
})

