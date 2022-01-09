--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Tabard")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Tabard UI"])
	self:SetAttribute("description", L["The tabard designer interface"])
	
	local func = function()
		
		gUI:DisableTextures(TabardFrame, TabardFrameEmblemTopRight, TabardFrameEmblemTopLeft, TabardFrameEmblemBottomRight, TabardFrameEmblemBottomLeft) 
		gUI:DisableTextures(TabardFrameInset) 
		gUI:DisableTextures(TabardFrameCostFrame) 
		gUI:DisableTextures(TabardFrameCustomizationFrame)
		gUI:DisableTextures(TabardFrameCustomization1)
		gUI:DisableTextures(TabardFrameCustomization2)
		gUI:DisableTextures(TabardFrameCustomization3)
		gUI:DisableTextures(TabardFrameCustomization4)
		gUI:DisableTextures(TabardFrameCustomization5)
		gUI:DisableTextures(TabardFrameMoneyBg)
		gUI:DisableTextures(TabardFrameMoneyInset)
		
		gUI:KillObject(TabardFramePortrait)
		
		gUI:SetUITemplate(TabardFrame, "backdrop")
		gUI:SetUITemplate(TabardFrameCancelButton, "button", true)
		gUI:SetUITemplate(TabardFrameAcceptButton, "button", true)
		gUI:SetUITemplate(TabardFrameCloseButton, "closebutton", "TOPRIGHT", -4, -4)
		gUI:SetUITemplate(TabardCharacterModelRotateLeftButton, "arrow", "left")
		gUI:SetUITemplate(TabardCharacterModelRotateRightButton, "arrow", "right")
		gUI:SetUITemplate(TabardFrameCustomization1LeftButton, "arrow", "left")
		gUI:SetUITemplate(TabardFrameCustomization1RightButton, "arrow", "right")
		gUI:SetUITemplate(TabardFrameCustomization2LeftButton, "arrow", "left")
		gUI:SetUITemplate(TabardFrameCustomization2RightButton, "arrow", "right")
		gUI:SetUITemplate(TabardFrameCustomization3LeftButton, "arrow", "left")
		gUI:SetUITemplate(TabardFrameCustomization3RightButton, "arrow", "right")
		gUI:SetUITemplate(TabardFrameCustomization4LeftButton, "arrow", "left")
		gUI:SetUITemplate(TabardFrameCustomization4RightButton, "arrow", "right")
		gUI:SetUITemplate(TabardFrameCustomization5LeftButton, "arrow", "left")
		gUI:SetUITemplate(TabardFrameCustomization5RightButton, "arrow", "right")
		
		TabardFrameNameText:ClearAllPoints()
		TabardFrameNameText:SetPoint("TOP", 0, -8)
		TabardFrameGreetingText:SetPoint("TOP", 0, -30)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end