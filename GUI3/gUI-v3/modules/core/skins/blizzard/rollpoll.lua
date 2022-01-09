--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("RolePollPopup")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Roll Poll"])
	self:SetAttribute("description", L["The roll poll popup when in a group"])
	
	local func = function()
		gUI:DisableTextures(RolePollPopup)
		gUI:SetUITemplate(RolePollPopupAcceptButton, "button", true)
		gUI:SetUITemplate(RolePollPopupRoleButtonTank.checkButton, "checkbutton")
		gUI:SetUITemplate(RolePollPopupRoleButtonHealer.checkButton, "checkbutton")
		gUI:SetUITemplate(RolePollPopupRoleButtonDPS.checkButton, "checkbutton")
		gUI:SetUITemplate(RolePollPopupCloseButton, "closebutton")
		gUI:SetUITemplate(RolePollPopup, "backdrop")
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end