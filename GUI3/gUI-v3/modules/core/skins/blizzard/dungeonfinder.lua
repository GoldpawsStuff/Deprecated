--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

-- local style = gUI:GetModule("Styling"):NewModule("DungeonFinder")

-- style.OnInit = function(self)
	-- local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	-- local gABT = LibStub("gActionButtons-3.0")

	-- self:SetAttribute("name", L["Dungeon Finder"])
	-- self:SetAttribute("description", L["Where you browse available dungeons, raids, scenarios and challenges"])
	
	-- local func = function()

	-- end
	-- self:GetParent():RegisterSkin(self:GetName(), func)
-- end