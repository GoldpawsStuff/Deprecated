--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("TradeFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Trade"])
	self:SetAttribute("description", L["The trade window when trading with another player."])
	
	local func = function()
		local MAX_TRADE_ITEMS = MAX_TRADE_ITEMS or 7
		local MAX_TRADABLE_ITEMS = MAX_TRADABLE_ITEMS or 6
		local TRADE_ENCHANT_SLOT = MAX_TRADE_ITEMS
		
		-- TradeFrame:ClearAllPoints()
		-- TradeFrame:SetPoint("CENTER", UIParent)
		-- TradeFrame:Show()
		
		gUI:DisableTextures(TradeFrame)
		gUI:DisableTextures(TradeFrameInset)
		gUI:DisableTextures(TradeHighlightPlayer)
		gUI:DisableTextures(TradeHighlightRecipient)
		gUI:DisableTextures(TradeHighlightPlayerEnchant)
		gUI:DisableTextures(TradeHighlightRecipientEnchant)
		gUI:DisableTextures(TradePlayerItemsInset)
		gUI:DisableTextures(TradePlayerEnchantInset)
		gUI:DisableTextures(TradeRecipientItemsInset)
		gUI:DisableTextures(TradeRecipientEnchantInset)

		gUI:KillObject(TradeFramePlayerPortrait)
		gUI:KillObject(TradeFrameRecipientPortrait)
		gUI:KillObject(TradePlayerInputMoneyInset)
		gUI:KillObject(TradeRecipientMoneyInset)
		gUI:KillObject(TradeRecipientMoneyBg)
		
		TradeHighlightPlayer:SetAllPoints(TradePlayerItemsInset)
		TradeHighlightRecipient:SetAllPoints(TradeRecipientItemsInset)
		TradeHighlightPlayerEnchant:SetAllPoints(TradePlayerEnchantInset)
		TradeHighlightRecipientEnchant:SetAllPoints(TradeRecipientEnchantInset)

		gUI:SetUITemplate(TradeHighlightPlayer, "simplehighlightborder")
		gUI:SetUITemplate(TradeHighlightRecipient, "simplehighlightborder")
		gUI:SetUITemplate(TradeHighlightPlayerEnchant, "simplehighlightborder")
		gUI:SetUITemplate(TradeHighlightRecipientEnchant, "simplehighlightborder")

		-- gUI:SetUITemplate(TradeFrame, "outerbackdrop", nil, 8, 10, 44, 22)
		gUI:SetUITemplate(TradeFrame, "backdrop")
		gUI:SetUITemplate(TradeFrameTradeButton, "button", true)
		gUI:SetUITemplate(TradeFrameCancelButton, "button", true)
		gUI:SetUITemplate(TradeFrameCloseButton, "closebutton")
		
		-- player
		TradeFramePlayerNameText:ClearAllPoints()
		TradeFramePlayerNameText:SetPoint("TOPLEFT", 75 - 58, -20)
		
		gUI:SetUITemplate(TradePlayerInputMoneyFrame.gold, "editbox")
		gUI:SetUITemplate(TradePlayerInputMoneyFrame.silver, "editbox")
		gUI:SetUITemplate(TradePlayerInputMoneyFrame.copper, "editbox")
		
		TradePlayerInputMoneyFrame.gold:SetFontObject(gUI_DisplayFontTinyWhite)
		TradePlayerInputMoneyFrame.silver:SetFontObject(gUI_DisplayFontTinyWhite)
		TradePlayerInputMoneyFrame.copper:SetFontObject(gUI_DisplayFontTinyWhite)
		
		local trade, item
		for i = 1, MAX_TRADE_ITEMS do
			trade = _G["TradePlayerItem" .. i]
			item = _G["TradePlayerItem" .. i .. "ItemButton"]
			gUI:DisableTextures(trade)
			if (i%2 == 1) then
				trade:SetBackdrop({
					bgFile = gUI:GetBlankTexture(); 
					edgeFile = nil; 
					edgeSize = 0;
					insets = { 
						bottom = 0; 
						left = 0; 
						right = 0; 
						top = 0; 
					};
				})
				trade:SetBackdropColor(1, 1, 1, 1/10)
			end
			gABT:GetStyleFunction()(item)
		end
		
		-- recipient
		TradeFrameRecipientNameText:ClearAllPoints()
		TradeFrameRecipientNameText:SetPoint("TOPLEFT", 245 - 58, -20)

		for i = 1, MAX_TRADE_ITEMS do
			trade = _G["TradeRecipientItem" .. i]
			item = _G["TradeRecipientItem" .. i .. "ItemButton"]
			gUI:DisableTextures(trade)
			if (i%2 == 1) then
				trade:SetBackdrop({
					bgFile = gUI:GetBlankTexture(); 
					edgeFile = nil; 
					edgeSize = 0;
					insets = { 
						bottom = 0; 
						left = 0; 
						right = 0; 
						top = 0; 
					};
				})
				trade:SetBackdropColor(1, 1, 1, 1/10)
			end
			gABT:GetStyleFunction()(item)
		end
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end