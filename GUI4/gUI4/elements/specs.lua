local addon, gUI4 = ...

-- Lua API
local _G = _G

-- WoW API
local GetActiveSpecGroup = _G.GetActiveSpecGroup
local GetNumSpecGroups = _G.GetNumSpecGroups
local RaidNotice_AddMessage = _G.RaidNotice_AddMessage
local RaidWarningFrame = _G.RaidWarningFrame
local SetActiveSpecGroup = _G.SetActiveSpecGroup

local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- The old dual spec system got removed in Legion
-- I might add similar chat commands for multiple specs later on
local LEGION = tonumber((select(2, GetBuildInfo()))) >= 22410
if LEGION then
	return
end

-------------------------------------------------------------------------------
--	Character Specialization
-------------------------------------------------------------------------------
local colorInfo = {} -- just use the same table every time this is called with a custom color
local colorInfoDefault = { r = 1, g = .49, b = .04 } -- keep defaults separated, so we don't have to set them
local function warning(msg, r, g, b)
	if r and g and b then
		colorInfo.r = r
		colorInfo.g = g
		colorInfo.b = b
		RaidNotice_AddMessage(RaidWarningFrame, msg, colorInfo)
	else
		RaidNotice_AddMessage(RaidWarningFrame, msg, colorInfoDefault)
	end
end
function gUI4:ToggleSpec()
	if GetNumSpecGroups() == 1 then return end
	if GetActiveSpecGroup() == 1 then
		warning(L["Activating Secondary Specialization"])
		SetActiveSpecGroup(2)
	else
		warning(L["Activating Primary Specialization"])
		SetActiveSpecGroup(1)
	end
end

function gUI4:MainSpec()
	if GetNumSpecGroups() == 1 then return end
	if GetActiveSpecGroup() ~= 1 then 
		warning(L["Activating Primary Specialization"])
		SetActiveSpecGroup(1) 
	end
end

function gUI4:OffSpec()
	if GetNumSpecGroups() == 1 then return end
	if GetActiveSpecGroup() ~= 2 then 
		warning(L["Activating Secondary Specialization"])
		SetActiveSpecGroup(2) 
	end
end

gUI4:AddChatCommand("spec1", "MainSpec") -- switch to main specialization
gUI4:AddChatCommand("mainspec", "MainSpec") -- switch to main specialization
gUI4:AddChatCommand("spec2", "OffSpec") -- switch to secondary specialization
gUI4:AddChatCommand("offspec", "OffSpec") -- switch to secondary specialization
gUI4:AddChatCommand("togglespec", "ToggleSpec") -- toggle between specializations
