--- AceConfig-3.0 wrapper library.
-- Provides an API to register an options table with the config registry,
-- as well as associate it with a slash command.
-- @class file
-- @name AceConfig-3.0
-- @release $Id: AceConfig-3.0.lua 969 2010-10-07 02:11:48Z shefki $

--[[
AceConfig-3.0

Very light wrapper library that combines all the AceConfig subcomponents into one more easily used whole.

]]

local MAJOR, MINOR = "GP_AceConfig-3.0", 2
local AceConfig = GP_LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfig then return end

local cfgreg = GP_LibStub("GP_AceConfigRegistry-3.0")
local cfgcmd = GP_LibStub("GP_AceConfigCmd-3.0")
--TODO: local cfgdlg = GP_LibStub("GP_AceConfigDialog-3.0", true)
--TODO: local cfgdrp = GP_LibStub("GP_AceConfigDropdown-3.0", true)

-- Lua APIs
local pcall, error, type, pairs = pcall, error, type, pairs

-- -------------------------------------------------------------------
-- :RegisterOptionsTable(appName, options, slashcmd, persist)
--
-- - appName - (string) application name
-- - options - table or function ref, see AceConfigRegistry
-- - slashcmd - slash command (string) or table with commands, or nil to NOT create a slash command

--- Register a option table with the AceConfig registry.
-- You can supply a slash command (or a table of slash commands) to register with AceConfigCmd directly.
-- @paramsig appName, options [, slashcmd]
-- @param appName The application name for the config table.
-- @param options The option table (or a function to generate one on demand).  http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
-- @param slashcmd A slash command to register for the option table, or a table of slash commands.
-- @usage
-- local AceConfig = GP_LibStub("GP_AceConfig-3.0")
-- AceConfig:RegisterOptionsTable("MyAddon", myOptions, {"/myslash", "/my"})
function AceConfig:RegisterOptionsTable(appName, options, slashcmd)
	local ok,msg = pcall(cfgreg.RegisterOptionsTable, self, appName, options)
	if not ok then error(msg, 2) end
	
	if slashcmd then
		if type(slashcmd) == "table" then
			for _,cmd in pairs(slashcmd) do
				cfgcmd:CreateChatCommand(cmd, appName)
			end
		else
			cfgcmd:CreateChatCommand(slashcmd, appName)
		end
	end
end
