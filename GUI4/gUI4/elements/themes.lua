local _, gUI4 = ...

-- Lua API
local pairs = pairs
local rawget = rawget
local setmetatable = setmetatable
local tinsert, tsort = table.insert, table.sort
local tostring = tostring

local THEME = {}
local DEFAULT_THEME = "Warcraft" -- fallback theme when none is given. all modules using themes MUST have this.
local CURRENT_THEME = setmetatable({}, {
	__index = function(t,k)
		if rawget(THEME,k) then
			return rawget(t,k)
		else
			return DEFAULT_THEME
		end
	end
})
local prototype = gUI4:GetProtoType()

-------------------------------------------------------------------------------
--	Theme Registering & Selection
-------------------------------------------------------------------------------
-- addon messages:
-- 	GUI4_NEW_THEME_REGISTERED arg1 = theme name, arg2 = module name (tostring), arg3 = true (for new themes for the entire addon) or nil 
--	GUI4_THEME_UPDATED arg1 = theme name, arg2 = module name (tostring)
--	GUI4_ACTIVE_THEME_CHANGED arg1 = theme name, arg2 = module name (tostring)
--

-- Register a new theme for your module. 
-- Fires the addon message "GUI4_NEW_THEME_REGISTERED" with (name, addon, isNew) as args.
-- @name //addon//:RegisterTheme
-- @paramsig name, theme
-- @param name <string> name of the theme to register
-- @param theme <table> table containing the theme data
function gUI4:RegisterTheme(name, theme)
	local addon = tostring(self) -- using tostring rather than :GetName() to avoid duplicate names
	-- brand new theme
	if not(THEME[name]) then
		THEME[name] = {}
		THEME[name][addon] = theme
		gUI4:SendMessage("GUI4_THEME_REGISTERED", name, addon, true)
	-- new theme for the specific addon
	elseif not THEME[name][addon] then
		THEME[name][addon] = theme
		gUI4:SendMessage("GUI4_THEME_REGISTERED", name, addon)
	-- just an update
	else
		THEME[name][addon] = theme
		gUI4:SendMessage("GUI4_THEME_UPDATED", name, addon)
	end
end

-- Changes the currently active theme for your module
-- Fires the addon message "GUI4_ACTIVE_THEME_CHANGED" with (name, addon) as args
-- @name //addon//:SetActiveTheme
-- @paramsig name
-- @param name <string> name of the theme to activate
function gUI4:SetActiveTheme(name)
	local addon = tostring(self)
	-- local oldTheme = CURRENT_THEME[addon]
	-- if oldTheme ~= name then
		CURRENT_THEME[addon] = name
		gUI4:SendMessage("GUI4_ACTIVE_THEME_CHANGED", name, addon)
	-- end
end

-- Retrieve a specific theme for your module
-- @name //addon//:GetTheme
function gUI4:GetTheme(name)
	return name and THEME[name] and THEME[name][tostring(self)]
end

-- Retrieve the currently active theme for your module
-- @name //addon//:GetActiveTheme
-- @return <table> pointer to table containing the active theme data
function gUI4:GetActiveTheme()
	return self:GetTheme(CURRENT_THEME[tostring(self)])
end

local function theme_iterator(tbl, key)
	local tmp = {}
	for name,list in pairs(tbl) do
		for addon, theme in pairs(list) do
			if addon == key then
				tinsert(tmp, { name = name, theme = theme })
			end
		end
	end
	tsort(tmp, function(a, b) return a.name < b.name end)
	local pos = 0
	return function ()
		if tmp[pos] then
			local name, theme = tmp[pos].name, tmp[pos].theme
			pos = pos + 1
			return name, theme
		end
	end
end

-- Returns an iterator that returns the name and theme data of all themes registered to your addon, in alphabetical order.
-- *You should use this within a callback after theme updates, if your module contains theme selection
-- @name //addon//:GetThemes
-- @usage for name, theme = //addon//:GetThemes() do ... end
function gUI4:GetThemes()
	return theme_iterator(THEME, tostring(self))
end

-- @name //addon//:GetActiveThemeName
-- @return <string> name of the currently active theme for your module
function gUI4:GetActiveThemeName()
	return CURRENT_THEME[tostring(self)]
end

-- add theme functionality to modules
prototype.RegisterTheme = gUI4.RegisterTheme
prototype.SetActiveTheme = gUI4.SetActiveTheme
prototype.GetActiveTheme = gUI4.GetActiveTheme
prototype.GetActiveThemeName = gUI4.GetActiveThemeName
prototype.GetTheme = gUI4.GetTheme
prototype.GetThemes = gUI4.GetThemes

