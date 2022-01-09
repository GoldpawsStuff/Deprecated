local addon, gUI4 = ...

-- Lua API
local _G = _G
local type, ipairs, pairs = type, ipairs, pairs
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local wipe = table.wipe 

-- WoW API
local DoReadyCheck = _G.DoReadyCheck
local EnableAddOn = _G.EnableAddOn
local GetAddOnInfo = _G.GetAddOnInfo
local GetNumAddOns = _G.GetNumAddOns
local IsAddOnLoaded = _G.IsAddOnLoaded
local LoadAddOn = _G.LoadAddOn
local LeaveParty = _G.LeaveParty
local RepopMe = _G.RepopMe
local ToggleHelpFrame = _G.ToggleHelpFrame

local required_patch, required_build, required_tocversion = "7.1.0", 22578, 70100
local version, build, _, tocversion = _G.GetBuildInfo()
build = tonumber(build)

local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
if tocversion < required_tocversion or build < required_build then
	print(L["%s requires WoW patch %s(%d) or higher, and you only have %s(%d), bailing out!"]:format(L["Goldpaw's UI"], required_patch, required_build, version, build))
	return
end

local prototype = {} -- we'll be adding methods to this later on
_G.GP_LibStub("GP_AceAddon-3.0"):NewAddon(gUI4, addon, "GP_AceConsole-3.0", "GP_AceEvent-3.0", "GP_AceBucket-3.0", "GP_AceHook-3.0", "GP_AceSerializer-3.0", "GP_AceTimer-3.0", "GP_LibSecureWrapper-1.0", "GP_LibFlash-1.0") -- , "LibFade-1.0")
gUI4:SetDefaultModuleState(false) -- there are certain things we wish to do before enabling other modules
gUI4:SetDefaultModulePrototype(prototype)

gUI4.version = "4.0.@project-version@"
gUI4.name = L["Goldpaw's UI"]
if gUI4.version:match("@") then
	gUI4.version = "Development"
	-- gUI4.DEBUG = true -- this will reset everything for me. 
end

_G.BINDING_HEADER_GUI4_CORE = L["Goldpaw's UI"] 
_G.BINDING_NAME_GUI4_CORE_TOGGLECALENDAR = L["Toggle Calendar"]
_G.BINDING_NAME_GUI4_CORE_TOGGLECUSTOMERSUPPORT = L["Toggle Help Window"]
_G.BINDING_NAME_GUI4_CORE_TOGGLEBLIZZARDSTORE = L["Toggle Blizzard Store"]

local startupQueue = {}
local eventQueue, messageQueue, cmdQueue = {}, {}, {}
local scriptQueue = { first = {}, last = {} }

local defaults = {
	profile = {
		skin = "Warcraft"
	}
}

-- Matching the pre-MoP return arguments of the Blizzard API call
gUI4.GetAddOnInfo = function(self, index)
	local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(index)
	local enabled = not(GetAddOnEnableState(UnitName("player"), index) == 0) -- not a boolean, messed that one up! o.O
	return name, title, notes, enabled, loadable, reason, security
end

-- Check if an addon is enabled	in the addon listing
gUI4.IsAddOnEnabled = function(self, target)
	local target = strlower(target)
	for i = 1,GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = self:GetAddOnInfo(i)
		if strlower(name) == target then
			if enabled then
				return true
			end
		end
	end
end	

-------------------------------------------------------------------------------
-- 	Utility functions for easier cross file handling
-------------------------------------------------------------------------------
-- @return <table> the prototype table used for sub modules
function gUI4:GetProtoType()
	return prototype
end

-- simple handler to allow multiple registrations of the same events and messages,
-- but point towards different methods and functions
function gUI4:EventQueueHandler(event, ...)
	if eventQueue[event] then
		for method in pairs(eventQueue[event]) do
			if type(method) == "string" then
				self[method](self, event, ...)
			elseif type(method) == "function" then
				method(self, event, ...)
			end
		end
	end
	if messageQueue[event] then
		for method in pairs(messageQueue[event]) do
			if type(method) == "string" then
				self[method](self, event, ...)
			elseif type(method) == "function" then
				method(self, event, ...)
			end
		end
	end
end

function gUI4:AddEvent(event, method)
	if self:IsReady() then
		self:RegisterEvent(event)
	else
		if not eventQueue[event] then
			eventQueue[event] = {}
		end
		if method then
			eventQueue[event][method] = true
		end
	end
end

function gUI4:AddMessage(message, method)
	if self:IsReady() then
		self:RegisterMessage(message)
	else
		if not messageQueue[message] then
			messageQueue[message] = {}
		end
		if method then
			messageQueue[message][method] = true
		end
	end
end

function gUI4:AddChatCommand(cmd, method)
	if self:IsReady() then
		self:RegisterChatCommand(cmd, method)
	else
		cmdQueue[cmd] = method
	end
end

function gUI4:AddStartupScript(scriptOrMethod, loadlast)
	if (self:IsReady() and not loadlast) or (self:IsFullyLoaded() and loadlast) then
		if type(scriptOrMethod) == "string" then
			self[scriptOrMethod](self)
		elseif type(scriptOrMethod) == "function" then
			scriptOrMethod(self)
		end
	else
		if loadlast then
			tinsert(scriptQueue.last, scriptOrMethod)
		else
			tinsert(scriptQueue.first, scriptOrMethod)
		end
	end
end

function gUI4:ParseStartupScripts(includelast)
	for i = #scriptQueue.first, 1, -1 do
		local scriptOrMethod = tremove(scriptQueue.first, i)
		if type(scriptOrMethod) == "string" then
			self[scriptOrMethod](self)
		elseif type(scriptOrMethod) == "function" then
			scriptOrMethod(self)
		end
	end
	if includelast then
		for i = #scriptQueue.last, 1, -1 do
			local scriptOrMethod = tremove(scriptQueue.last, i)
			if type(scriptOrMethod) == "string" then
				self[scriptOrMethod](self)
			elseif type(scriptOrMethod) == "function" then
				scriptOrMethod(self)
			end
		end
	end
end

function gUI4:AddStartupMessage(msg, fromStart)
	if fromStart then
		tinsert(startupQueue, 1, msg)
	else
		tinsert(startupQueue, msg)
	end
end

local new = {}
local function formatChatCommand(msg)
	-- search for chat commands
	local min, max = msg:find("^/(%a+)%s*")
	if min and max then
		wipe(new)
		
		-- capture the command
		local cmd = msg:sub(min, max-1)
		tinsert(new, gUI4:GetColors("chat", "normal").colorCode..cmd.."|r")
		
		local position = max + 1
		
		-- capture any numerical parameters
		min, max = msg:find("([0-9]%-[0-9])%s*", position)
		if min and max then
			local param = msg:sub(min, max-1)
			tinsert(new, gUI4:GetColors("chat", "offwhite").colorCode..param.."|r")
			position = max + 1
		end
		
		-- grab the rest of the string
		tinsert(new, gUI4:GetColors("chat", "gray").colorCode..msg:sub(position).."|r")
		
		return tconcat(new, " ")
	else
		return msg
	end
end

function gUI4:FireChatQueue()
	for _,msg in ipairs(startupQueue) do
		print(formatChatCommand(msg))
	end
end

-- fire a method for all modules that has it
function gUI4:ForAll(method, ...)
	for _, mod in self:IterateModules() do
		if mod:IsEnabled() then
			local func = mod[method]
			if func and type(func) == "function" then
				mod[method](mod, ...)
			end
		end
	end
end

function gUI4:ApplySettings()
end

local ready
function gUI4:OnInitialize()
	-- Previous RothUI users don't always get they need to manually enable these
	-- we love you Zork, but disabling Blizz addons just mess it up for the average user ;)
	-- Adding the ObjectiveTracker to this because a moron named Goldpaw (lol) disabled it in DiabolicUI once... ;)
	for _,v in ipairs({ "Blizzard_CUFProfiles", "Blizzard_CompactRaidFrames", "Blizzard_ObjectiveTracker" }) do
		EnableAddOn(v)
		LoadAddOn(v)
	end
	
	self.db = _G.GP_LibStub("GP_AceDB-3.0"):New("gUI4_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end
	
	self:RegisterChatCommand("leaveparty", LeaveParty) -- leave a group
	self:RegisterChatCommand("rc", DoReadyCheck) -- perform a readycheck
	self:RegisterChatCommand("gm", ToggleHelpFrame) -- toggle help frame
	self:RegisterChatCommand("repop", RepopMe) -- release spirit
	
	self:RegisterMessage("GUI4_CHAT_READY", "FireChatQueue")

	-- register events, messages and chat commands queued from other files
	for event, calls in pairs(eventQueue) do
		for _ in pairs(calls) do
			self:RegisterEvent(event, "EventQueueHandler")
		end
	end
	for message, calls in pairs(messageQueue) do
		for _ in pairs(calls) do
			self:RegisterMessage(message, "EventQueueHandler")
		end
	end
	for cmd, method in pairs(cmdQueue) do
		self:RegisterChatCommand(cmd, method)
	end
	ready = true 
	self.locked = true -- start with all frames locked
end

function gUI4:IsReady()
	return ready
end

local modulesloaded
function gUI4:IsFullyLoaded()
	return modulesloaded
end

function gUI4:OnEnable()
	if not ready then return end 
	self:ParseStartupScripts()
	for _, mod in self:IterateModules() do
		mod:Enable()
	end
	modulesloaded = true
	self:ParseStartupScripts(true) 
	if not self:IsAddOnEnabled("gUI4_Chat") then
		self:FireChatQueue() 
	end
end

