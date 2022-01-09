--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("OpacityFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Opacity"])
	self:SetAttribute("description", L["The opacity selector"])
	
	local func = function()
		gUI:DisableTextures(OpacityFrame)
		gUI:SetUITemplate(OpacityFrame, "backdrop")
		gUI:SetUITemplate(OpacityFrameSlider, "slider")
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end