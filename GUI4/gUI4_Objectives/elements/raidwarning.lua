local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local module = parent:NewModule("RaidWarning")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

local defaults = {
}

function module:Lock()
end

function module:Unlock()
end

function module:ResetLock()
end

function module:OnInitialize()
	-- Initialize the AceDB-3.0 database
	-- self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_Objectives_DB", defaults)

	
end

function module:OnEnable()

end

function module:OnDisable()
end

