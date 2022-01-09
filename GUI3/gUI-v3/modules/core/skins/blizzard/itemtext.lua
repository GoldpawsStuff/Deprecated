--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("ItemText")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["ItemText"])
	self:SetAttribute("description", L["The itemtext frame for books, signs, etc."])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(ItemTextFrame)
		gUI:DisableTextures(ItemTextFrameInset)
		gUI:DisableTextures(ItemTextScrollFrame)
		
		gUI:SetUITemplate(ItemTextNextPageButton, "arrow")
		gUI:SetUITemplate(ItemTextPrevPageButton, "arrow")
		gUI:SetUITemplate(ItemTextFrameCloseButton, "closebutton", "TOPRIGHT", -4, -4)
		gUI:SetUITemplate(ItemTextFrame, "backdrop")
		gUI:SetUITemplate(ItemTextScrollFrame, "outerbackdrop", nil, 0, -4, 0, -4):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(ItemTextScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(ItemTextStatusBar, "statusbar", true)
		
		ItemTextScrollFrame:SetHeight(ItemTextScrollFrame:GetHeight() - 10)
		
		ItemTextScrollFrameScrollBar:ClearAllPoints()
		ItemTextScrollFrameScrollBar:SetPoint("TOPLEFT", ItemTextScrollFrame, "TOPRIGHT", 10, -16)
		ItemTextScrollFrameScrollBar:SetPoint("BOTTOMLEFT", ItemTextScrollFrame, "BOTTOMRIGHT", 10, 16)
		
		gUI:HideTexture(ItemTextMaterialTopLeft)
		gUI:HideTexture(ItemTextMaterialTopRight)
		gUI:HideTexture(ItemTextMaterialBotLeft)
		gUI:HideTexture(ItemTextMaterialBotRight)

		ItemTextPageText:SetTextColor(unpack(C["index"]))
		ItemTextPageText.SetTextColor = noop

		ItemTextPrevPageButton:ClearAllPoints()
		ItemTextPrevPageButton:SetPoint("TOPLEFT", 8, -30)
		
		ItemTextNextPageButton:ClearAllPoints()
		ItemTextNextPageButton:SetPoint("TOPRIGHT", -8, -30)
		
		ItemTextTitleText:ClearAllPoints()
		ItemTextTitleText:SetPoint("TOP", 0, -8)
		
		ItemTextCurrentPage:ClearAllPoints()
		ItemTextCurrentPage:SetPoint("TOP", 0, -40)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end