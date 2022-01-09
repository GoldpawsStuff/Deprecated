--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_ReforgingUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Reforging UI"])
	self:SetAttribute("description", L["The reforging UI where you redistribute secondary stats on your gear"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(ReforgingFrame)
		gUI:DisableTextures(ReforgingFrame.ButtonFrame)

		gUI:HideTexture(ReforgingFrame.ItemButton.Frame)
		gUI:HideTexture(ReforgingFrame.ItemButton.Grabber)
		gUI:HideTexture(ReforgingFrame.ItemButton.TextFrame)
		gUI:HideTexture(ReforgingFrame.ItemButton.TextGrabber)

		gUI:HideTexture(ReforgingFrame.ButtonFrame.ButtonBorder)
		gUI:HideTexture(ReforgingFrame.ButtonFrame.ButtonBottomBorder)
		gUI:HideTexture(ReforgingFrame.ButtonFrame.MoneyLeft)
		gUI:HideTexture(ReforgingFrame.ButtonFrame.MoneyRight)
		gUI:HideTexture(ReforgingFrame.ButtonFrame.MoneyMiddle)
		
		gUI:SetUITemplate(ReforgingFrameRestoreButton, "button", true)
		gUI:SetUITemplate(ReforgingFrameReforgeButton, "button", true)
		gUI:SetUITemplate(ReforgingFrameCloseButton, "closebutton")
		gUI:SetUITemplate(ReforgingFrame, "backdrop")

		gUI:SetUITemplate(ReforgingFrame.ItemButton, "backdrop")
		gUI:CreateHighlight(ReforgingFrame.ItemButton)
		gUI:CreatePushed(ReforgingFrame.ItemButton)
		
		ReforgingFrame.ItemButton:GetHighlightTexture():ClearAllPoints()
		ReforgingFrame.ItemButton:GetHighlightTexture():SetPoint("TOPLEFT", ReforgingFrame.ItemButton, "TOPLEFT", 3, -3)
		ReforgingFrame.ItemButton:GetHighlightTexture():SetPoint("BOTTOMRIGHT", ReforgingFrame.ItemButton, "BOTTOMRIGHT", -3, 3)

		ReforgingFrame.ItemButton:GetPushedTexture():ClearAllPoints()
		ReforgingFrame.ItemButton:GetPushedTexture():SetPoint("TOPLEFT", ReforgingFrame.ItemButton, "TOPLEFT", 3, -3)
		ReforgingFrame.ItemButton:GetPushedTexture():SetPoint("BOTTOMRIGHT", ReforgingFrame.ItemButton, "BOTTOMRIGHT", -3, 3)

		ReforgingFrame.ItemButton.IconTexture:ClearAllPoints()
		ReforgingFrame.ItemButton.IconTexture:SetPoint("TOPLEFT", ReforgingFrame.ItemButton, "TOPLEFT", 3, -3)
		ReforgingFrame.ItemButton.IconTexture:SetPoint("BOTTOMRIGHT", ReforgingFrame.ItemButton, "BOTTOMRIGHT", -3, 3)
		
		ReforgingFrameReforgeButton:ClearAllPoints()
		ReforgingFrameReforgeButton:SetPoint("BOTTOMRIGHT", ReforgingFrame, "BOTTOMRIGHT", -8, 8)

		ReforgingFrameRestoreButton:ClearAllPoints()
		ReforgingFrameRestoreButton:SetPoint("BOTTOMRIGHT", ReforgingFrameReforgeButton, "BOTTOMLEFT", -8, 0)
		
		ReforgingFrameMoneyFrame:ClearAllPoints()
		ReforgingFrameMoneyFrame:SetPoint("BOTTOMLEFT", ReforgingFrame, 16, 12)
		
		ReforgingFrame.RestoreMessage:SetTextColor(unpack(C["index"]))
		ReforgingFrame.MissingDescription:SetTextColor(unpack(C["index"]))

		local updateButton = function(self)
			if (select(2, GetReforgeItemInfo())) then
				ReforgingFrame.ItemButton.IconTexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			else
				ReforgingFrame.ItemButton.IconTexture:SetTexture("")
			end
		end
		hooksecurefunc("ReforgingFrame_Update", updateButton)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end