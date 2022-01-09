local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0", "GP_AceConsole-3.0")

-- bindings
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
BINDING_HEADER_GUI4_DEVTOOLS = L["Goldpaw's Developer Tools"]
BINDING_NAME_GUI4_DEVTOOLS_RELOADUI = L["Reload the user interface"]
BINDING_NAME_GUI4_DEVTOOLS_FULLSCREEN = L["Activate fullscreen mode"]
BINDING_NAME_GUI4_DEVTOOLS_WINDOWED = L["Activate windowed mode"]

-- Lua API
local print = print
local select = select
local strjoin = strjoin
local strsplit = strsplit

-- WoW API
local CombatLogClearEntries = CombatLogClearEntries
local GetCVar = GetCVar
local GetItemInfo = GetItemInfo
local ReloadUI = ReloadUI
local RestartGx = RestartGx
local SetActiveSpecGroup = SetActiveSpecGroup
local SetCVar = SetCVar

local defaults = {
}

-- credits to the Ace3 Development Team for this one
function module:PrintCmd(input)
	input = input:trim():match("^(.-);*$")
	local func, err = loadstring("GP_LibStub(\"GP_AceConsole-3.0\"):Print(" .. input .. ")")
	if not func then
		GP_LibStub("GP_AceConsole-3.0"):Print("Error: " .. err)
	else
		func()
	end
end

local go = function(...)
	local arg1, arg2 = ...
	local restart
	if arg1 ~= GetCVar("gxWindow") then
		SetCVar("gxWindow", arg1)
		restart = true
	end
	if arg2 and arg2 ~= GetCVar("gxMaximize") then
		SetCVar("gxMaximize", arg2) 
		restart = true
	end
	if restart then
		RestartGx()
	end
end

function module:Fullscreen()
	return ((GetCVar("gxWindow") == "0") and (GetCVar("gxMaximize") == "0")) or go("0", "0")
end

function module:Windowed()
	return ((GetCVar("gxWindow") == "1") and (GetCVar("gxMaximize") == "0")) or go("1", "0")
	-- return ((GetCVar("gxWindow") == "1") and (GetCVar("gxMaximize") == "1")) or go("1")
end

function module:GetItemID(msg)
	local itemLink, itemID
	if msg:sub(1, 7) == "|Hitem:" then
		itemLink = msg
	else
		itemLink = select(2, GetItemInfo(msg))
	end
	if itemLink then
		local itemString = itemLink:match("item[%-?%d:]+")
		local _, itemID = strsplit(":", itemString)
		print(itemLink, itemID)
	end
end

function module:GetItemString(msg)
	local _, itemLink = GetItemInfo(msg:gsub("  ", " "))
	if itemLink then
		print(itemLink, itemLink:match("item[%-?%d:]+"))
	end
end

function module:GetItemLinkByName(msg)
	local _, itemLink = GetItemInfo(msg:gsub("  ", " "))
	if itemLink then
		print(itemLink)
	end
end

function module:EnableAddOn(...)
	EnableAddOn(...)
	ReloadUI()
end

function module:DisableAddOn(...)
	DisableAddOn(...)
	ReloadUI()
end

function module:Debug(...)
	print(...)
end

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_DevTools_DB", defaults)

	-- add Ace3 commands
	if not gUI4:IsAddOnEnabled("GP_Ace3") then
		self:RegisterChatCommand("rl", ReloadUI)
		self:RegisterChatCommand("print", "PrintCmd")
	end

	-- toggle addons
	self:RegisterChatCommand("enableaddon", "EnableAddOn")
	self:RegisterChatCommand("disableaddon", "DisableAddOn")

	-- toggle fullscreen/windowed
	self:RegisterChatCommand("fullscreen", "Fullscreen")
	self:RegisterChatCommand("windowed", "Windowed")
	
	-- /itemid <ItemName or ItemLink>
	-- @return the itemID
	self:RegisterChatCommand("itemid", "GetItemID")
	
	-- /itemstring <ItemName or ItemLink>
	-- @return the itemstring for the item
	self:RegisterChatCommand("itemstring", "GetItemString")

	-- /itemlink <ItemName or ItemLink>
	-- @return clickable itemlink
	self:RegisterChatCommand("itemlink", "GetItemLinkByName")
	
	-- attempt to reset combatlog when it freezes
	self:RegisterChatCommand("fixlog", CombatLogClearEntries)
	
	-- private debugging
	-- self:RegisterMessage("GUI4_BOTTOM_PREOFFSET_CHANGED", "Debug")
	-- self:RegisterMessage("GUI4_BOTTOM_OFFSET_CHANGED", "Debug")
	
end
