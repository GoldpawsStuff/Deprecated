--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_ItemUpgradeUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Item Upgrade UI"])
	self:SetAttribute("description", L["The window where you upgrade the item level of your gear"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(ItemUpgradeFrame)
		gUI:DisableTextures(ItemUpgradeFrame.ButtonFrame)

		gUI:HideTexture(ItemUpgradeFrame.ItemButton.Frame)
		gUI:HideTexture(ItemUpgradeFrame.ItemButton.Grabber)
		gUI:HideTexture(ItemUpgradeFrame.ItemButton.TextFrame)
		gUI:HideTexture(ItemUpgradeFrame.ItemButton.TextGrabber)

		gUI:HideTexture(ItemUpgradeFrame.ButtonFrame.ButtonBorder)
		gUI:HideTexture(ItemUpgradeFrame.ButtonFrame.ButtonBottomBorder)
		gUI:HideTexture(ItemUpgradeFrameMoneyFrameLeft)
		gUI:HideTexture(ItemUpgradeFrameMoneyFrameRight)
		gUI:HideTexture(ItemUpgradeFrameMoneyFrameMiddle)
		
		gUI:SetUITemplate(ItemUpgradeFrameUpgradeButton, "button", true)
		gUI:SetUITemplate(ItemUpgradeFrameCloseButton, "closebutton")
		gUI:SetUITemplate(ItemUpgradeFrame, "backdrop")

		gUI:SetUITemplate(ItemUpgradeFrame.ItemButton, "backdrop")
		gUI:CreateHighlight(ItemUpgradeFrame.ItemButton)
		gUI:CreatePushed(ItemUpgradeFrame.ItemButton)
		
		ItemUpgradeFrame.ItemButton:GetHighlightTexture():ClearAllPoints()
		ItemUpgradeFrame.ItemButton:GetHighlightTexture():SetPoint("TOPLEFT", ItemUpgradeFrame.ItemButton, "TOPLEFT", 3, -3)
		ItemUpgradeFrame.ItemButton:GetHighlightTexture():SetPoint("BOTTOMRIGHT", ItemUpgradeFrame.ItemButton, "BOTTOMRIGHT", -3, 3)

		ItemUpgradeFrame.ItemButton:GetPushedTexture():ClearAllPoints()
		ItemUpgradeFrame.ItemButton:GetPushedTexture():SetPoint("TOPLEFT", ItemUpgradeFrame.ItemButton, "TOPLEFT", 3, -3)
		ItemUpgradeFrame.ItemButton:GetPushedTexture():SetPoint("BOTTOMRIGHT", ItemUpgradeFrame.ItemButton, "BOTTOMRIGHT", -3, 3)

		ItemUpgradeFrame.ItemButton.IconTexture:ClearAllPoints()
		ItemUpgradeFrame.ItemButton.IconTexture:SetPoint("TOPLEFT", ItemUpgradeFrame.ItemButton, "TOPLEFT", 3, -3)
		ItemUpgradeFrame.ItemButton.IconTexture:SetPoint("BOTTOMRIGHT", ItemUpgradeFrame.ItemButton, "BOTTOMRIGHT", -3, 3)
		
		ItemUpgradeFrame.MissingDescription:SetTextColor(unpack(C["index"]))

		local updateButton = function(self)
			local icon, name, quality, bound, numCurrUpgrades, numMaxUpgrades, cost, currencyType = GetItemUpgradeItemInfo()
			if (name) then
				ItemUpgradeFrame.ItemButton.IconTexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			else
				ItemUpgradeFrame.ItemButton.IconTexture:SetTexture("")
			end
		end
		hooksecurefunc("ItemUpgradeFrame_Update", updateButton)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end