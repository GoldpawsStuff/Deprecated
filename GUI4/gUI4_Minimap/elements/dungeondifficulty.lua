local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Minimap", true)
if not parent then return end

local module = parent:NewModule("DungeonDifficulty", "GP_AceEvent-3.0")

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

local defaults = {
}

function module:OnInitialize()
	local minimap = parent:GetFrame()
end

function module:OnEnable()
	
end

function module:OnDisable()
end
