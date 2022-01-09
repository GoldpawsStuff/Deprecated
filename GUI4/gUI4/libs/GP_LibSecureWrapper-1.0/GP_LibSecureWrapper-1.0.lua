assert(GP_LibStub, "GP_LibSecureWrapper-1.0 requires GP_LibStub")
assert(GP_LibStub:GetLibrary("GP_CallbackHandler-1.0", true), "GP_LibSecureWrapper-1.0 requires GP_CallbackHandler-1.0")

local MAJOR, MINOR = "GP_LibSecureWrapper-1.0", 10
local lib = GP_LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end -- No upgrade needed

lib.frame = lib.frame or CreateFrame("Frame", "GP_LibSecureWrapper10Frame") -- our event frame
lib.frame:SetScript("OnEvent", function(self, event, ...) lib[event](lib, event, ...) end)
lib.embeds = lib.embeds or {} -- what objects embed this lib
lib.queuedCalls = lib.queuedCalls or {}

-- Lua API
local _G = _G
local pairs, unpack, select = pairs, unpack, select

-- WoW API
local InCombatLockdown = _G.InCombatLockdown
local UnitAffectingCombat = _G.UnitAffectingCombat

local INCOMBAT = UnitAffectingCombat("player")
local INLOCKDOWN = InCombatLockdown()

function lib:SafeCall(func, ...)
	if not INCOMBAT then
		func(...) -- perform the function right away when not in combat
		return
	end
	if not INLOCKDOWN then
		INLOCKDOWN = InCombatLockdown() 
		if not INLOCKDOWN then
			func(...)
			return
		end
	end
	local tbl = {} 
	for i = 1, select("#", ...) do
		tbl[i] = select(i, ...) -- give each argument its own entry
	end
	self.queuedCalls[func] = tbl -- put it in the queue, use 'func' as key, to avoid multiple calls
end

-- wrap a safecall handler around the given function
-- @usage MyFunc = MyAddon:SafeCallWrapper(MyFunc)
-- @usage MyTable.MyMethod = MyAddon:SafeCallWrapper(MyTable.MyMethod)
function lib:SafeCallWrapper(func)
	local lib = lib -- slight speed improvement?
	return function(...)
		return lib:SafeCall(func, ...)
	end
end

------------------------------------------------------------------------
--	Embedding
------------------------------------------------------------------------
local mixins = {
  "SafeCallWrapper"
 }

function lib:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

------------------------------------------------------------------------
--	Event Handling
------------------------------------------------------------------------
function lib:PLAYER_REGEN_DISABLED()
	INCOMBAT = true
end

function lib:PLAYER_REGEN_ENABLED()
	INCOMBAT = false
	INLOCKDOWN = false
	for func,args in pairs(self.queuedCalls) do
		func(unpack(args)) 
		self.queuedCalls[func] = nil -- clear queue entry
	end
end

lib.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
lib.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
