--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

-- local style = gUI:GetModule("Styling"):NewModule("DBM-Core")

-- style.OnInit = function(self)
	-- local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	-- local gABT = LibStub("gActionButtons-3.0")

	-- self:SetAttribute("name", self:GetName()) -- don't localize
	-- self:SetAttribute("description", L["Skins the '%s' addon"]:format(self:GetName()))
	
	-- local func = function()
	-- end
	-- self:GetParent():RegisterAddOnSkin(self:GetName(), func)
-- end