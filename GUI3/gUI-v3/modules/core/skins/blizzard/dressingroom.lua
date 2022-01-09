--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("DressUpFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Dressing Room"])
	self:SetAttribute("description", L["The dressing room where your character can try on other gear and weapons."])
	
	local func = function()
		gUI:DisableTextures(DressUpFrame)
		gUI:SetUITemplate(DressUpFrame, "outerbackdrop", nil, 0, 6, 70, 32)
		gUI:SetUITemplate(DressUpModel, "outerbackdrop"):SetBackdropColor(0, 0, 0, 1/3)
		gUI:SetUITemplate(DressUpFrameCancelButton, "button", true)
		gUI:SetUITemplate(DressUpFrameResetButton, "button", true)
		gUI:SetUITemplate(DressUpFrameCloseButton, "closebutton", "TOPRIGHT", DressUpFrame, "TOPRIGHT", -36, -4)
		
		gUI:DisableTextures(SideDressUpFrame)
		gUI:DisableTextures(SideDressUpModelCloseButton)
		gUI:SetUITemplate(SideDressUpModelResetButton, "button", true)
		gUI:SetUITemplate(SideDressUpFrame, "outerbackdrop", nil,  8, -2, 8, 8)
		gUI:SetUITemplate(SideDressUpModelCloseButton, "closebutton")
		SideDressUpFrame:SetPoint("TOPLEFT", AuctionFrame, "TOPRIGHT", 8, -28)
		SideDressUpModelResetButton:SetPoint("BOTTOM", SideDressUpFrame, "BOTTOM", 0, 16)
		
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end