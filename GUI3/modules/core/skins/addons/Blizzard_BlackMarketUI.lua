--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_BlackMarketUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Black Market UI"])
	self:SetAttribute("description", L["The black market interface"])
	
	local func = function()
		gUI:DisableTextures(BlackMarketFrame)
		gUI:DisableTextures(BlackMarketFrame.Inset)
		gUI:DisableTextures(BlackMarketFrame.MoneyFrameBorder)
		gUI:DisableTextures(BlackMarketFrame.HotDeal)
		gUI:DisableTextures(BlackMarketFrame.ColumnName)
		gUI:DisableTextures(BlackMarketFrame.ColumnLevel)
		gUI:DisableTextures(BlackMarketFrame.ColumnType)
		gUI:DisableTextures(BlackMarketFrame.ColumnDuration)
		gUI:DisableTextures(BlackMarketFrame.ColumnHighBidder)
		gUI:DisableTextures(BlackMarketFrame.ColumnCurrentBid)
		
		gUI:SetUITemplate(BlackMarketFrame, "outerbackdrop", nil, -3, -3, -3, -3)
		gUI:SetUITemplate(BlackMarketScrollFrame, "outerbackdrop", nil, -2, -3, -2, -3)
		gUI:SetUITemplate(BlackMarketFrame.BidButton, "button", true)
		gUI:SetUITemplate(BlackMarketBidPriceGold, "editbox")
		gUI:SetUITemplate(BlackMarketScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(BlackMarketFrame.HotDeal.Item, "border", true)
		
		BlackMarketFrame.HotDeal.Item.IconTexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		
		BlackMarketMoneyFrameGoldButtonText:SetFontObject(gUI_DisplayFontSmallWhite)
		BlackMarketMoneyFrameSilverButtonText:SetFontObject(gUI_DisplayFontSmallWhite)
		BlackMarketMoneyFrameCopperButtonText:SetFontObject(gUI_DisplayFontSmallWhite)
		
		if (HotItemCurrentBidMoneyFrame) then
			HotItemCurrentBidMoneyFrameGoldButtonText:SetFontObject(gUI_DisplayFontSmallWhite)
			HotItemCurrentBidMoneyFrameSilverButtonText:SetFontObject(gUI_DisplayFontSmallWhite)
			HotItemCurrentBidMoneyFrameCopperButtonText:SetFontObject(gUI_DisplayFontSmallWhite)
		end
		
		if (BlackMarketFrame.HotDeal.BidButton) then
			gUI:SetUITemplate(BlackMarketFrame.HotDeal.BidButton, "button", true)
		end

		local done = {}
		local update = function()
			local button
			for i = 1, #BlackMarketScrollFrame.buttons do
				button = BlackMarketScrollFrame.buttons[i]
				if not(done[button]) then
					gUI:DisableTextures(button)
					gUI:DisableTextures(button.Item, button.Item.IconTexture)
					gUI:CreatePushed(button)
					gUI:CreateHighlight(button)
					gUI:SetUITemplate(button.Item, "border", button.Item.IconTexture)
					gUI:SetUITemplate(button.Item, "gloss", button.Item.IconTexture)
					gUI:SetUITemplate(button.Item, "shade", button.Item.IconTexture)
					button.Item.IconTexture:SetWidth(button:GetHeight() - 10)
					button.Item.IconTexture:SetHeight(button:GetHeight() - 10)
					done[button] = true
				end
				button.Item.IconTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
				button.Item.IconTexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			end
		end
		hooksecurefunc("BlackMarketScrollFrame_Update", update)
	end 
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end