--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local parent = gUI:GetModule("Combat")
local module = parent:NewModule("SCT")

local L, C, F, M, db
local defaults

local updateAll

local settings = {
}

updateAll = function()
end
module.PostUpdateSettings = updateAll

module.OnInit = function(self)
	L, C, F, M = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	db = self:GetParent():GetCurrentOptionsSet() -- get module settings
	defaults = self:GetParent():GetDefaultsForOptions() -- get module defaults

end

