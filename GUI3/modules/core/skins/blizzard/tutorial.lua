--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Tutorials")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Tutorials"])
	self:SetAttribute("description", L["The game tutorials for new players"])
	
	local func = function()
		gUI:DisableTextures(TutorialFrame)
		gUI:SetUITemplate(TutorialFrame, "backdrop")
		gUI:SetUITemplate(TutorialFramePrevButton, "arrow", "left") 
		gUI:SetUITemplate(TutorialFrameNextButton, "arrow", "right") 
		gUI:SetUITemplate(TutorialFrameOkayButton, "button", true)
		gUI:SetUITemplate(TutorialFrameCloseButton, "closebutton", "TOPRIGHT", -4, -4)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end