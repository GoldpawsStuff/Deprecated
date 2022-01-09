--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("StackSplitFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Stack Split"])
	self:SetAttribute("description", L["The stack split frame when splitting stacks in your bank or bags"])
		
	local func = function()
		gUI:DisableTextures(StackSplitFrame)
		gUI:SetUITemplate(StackSplitFrame, "backdrop")
		gUI:SetUITemplate(StackSplitCancelButton, "button", true)
		gUI:SetUITemplate(StackSplitOkayButton, "button", true)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end