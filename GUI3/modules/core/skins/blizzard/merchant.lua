--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("MerchantFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Merchant"])
	self:SetAttribute("description", L["The buy/sell window when talking to merchants"])
	
	local func = function()
		local a = gUI:GetOverlayAlpha() 
		local r, g, b = unpack(C["overlay"])
		
		gUI:DisableTextures(MerchantFrame)
		gUI:DisableTextures(MerchantFrameInset)
		gUI:DisableTextures(MerchantBuyBackItem)
		-- gUI:DisableTextures(MerchantRepairItemButton)
		gUI:KillObject(MerchantMoneyBg)
		gUI:KillObject(MerchantMoneyInset)
		gUI:KillObject(MerchantExtraCurrencyBg)
		gUI:KillObject(MerchantExtraCurrencyInset)
		gUI:KillObject(MerchantFramePortrait)

		gUI:SetUITemplate(MerchantNextPageButton, "arrow", "right")
		gUI:SetUITemplate(MerchantPrevPageButton, "arrow", "left")
		gUI:SetUITemplate(MerchantFrame, "backdrop")
		gUI:SetUITemplate(MerchantBuyBackItem, "outerbackdrop", nil, -3, -3, -3, -3):SetBackdropColor(r, g, b, 1/3)
		gUI:SetUITemplate(MerchantRepairItemButton, "backdrop")
		gUI:SetUITemplate(MerchantGuildBankRepairButton, "backdrop")
		gUI:SetUITemplate(MerchantRepairAllButton, "backdrop")
		gUI:SetUITemplate(MerchantFrameTab1, "tab")
		gUI:SetUITemplate(MerchantFrameTab2, "tab")
		gUI:SetUITemplate(MerchantFrameCloseButton, "closebutton")
		gUI:SetUITemplate(MerchantFrameLootFilter, "dropdown", true)
		
		gABT:GetStyleFunction()(MerchantBuyBackItemItemButton)
		
		MerchantRepairItemButton:GetRegions():SetTexCoord(0.04, 0.24, 0.06, 0.52)
		MerchantRepairItemButton:GetRegions():ClearAllPoints()
		MerchantRepairItemButton:GetRegions():SetPoint("TOPLEFT", 3, -3)
		MerchantRepairItemButton:GetRegions():SetPoint("BOTTOMRIGHT", -3, 3)
		gUI:CreatePushed(MerchantRepairItemButton)
		gUI:CreateHighlight(MerchantRepairItemButton)
		
		MerchantGuildBankRepairButtonIcon:SetTexCoord(0.61, 0.82, 0.1, 0.52)
		MerchantGuildBankRepairButtonIcon:ClearAllPoints()
		MerchantGuildBankRepairButtonIcon:SetPoint("TOPLEFT", 3, -3)
		MerchantGuildBankRepairButtonIcon:SetPoint("BOTTOMRIGHT", -3, 3)

		MerchantRepairAllIcon:SetTexCoord(0.34, 0.1, 0.34, 0.535, 0.535, 0.1, 0.535, 0.535)
		MerchantRepairAllIcon:ClearAllPoints()
		MerchantRepairAllIcon:SetPoint("TOPLEFT", 3, -3)
		MerchantRepairAllIcon:SetPoint("BOTTOMRIGHT", -3, 3)
		
		for i = 1, max(MERCHANT_ITEMS_PER_PAGE, BUYBACK_ITEMS_PER_PAGE) do
			local bar = _G["MerchantItem" .. i]
			local button = _G["MerchantItem" .. i .. "ItemButton"]
			local money = _G["MerchantItem" .. i .. "MoneyFrame"]
			local currency = _G["MerchantItem" .. i .. "AltCurrencyFrame"]

			gABT:GetStyleFunction()(button)
			
			gUI:DisableTextures(bar)
			gUI:SetUITemplate(bar, "outerbackdrop", nil, -1, -1, 1, -1):SetBackdropColor(r, g, b, 1/3)

			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", 4, -4)

	--		money:ClearAllPoints()
	--		money:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 6, 0)
			
	--		currency:ClearAllPoints()
	--		currency:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 6, 0)
			
	--		currency.OldSetPoint = currency.SetPoint
	--		currency.SetPoint = function(self) 
	--			self:ClearAllPoints()
	--			self:OldSetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", 6, 0)
	--		end
		end
		
		local updateItem = function(item, itemID)
			local quality
			if (itemID) then
				quality = (itemID) and (select(3, GetItemInfo(itemID)))
			end
			
			if (quality) and (quality > 1) then
				local r, g, b, hex = GetItemQualityColor(quality)
				item:SetBackdropBorderColor(r, g, b)
			else
				item:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
			end
		end

		local updateMerchantItems = function()
			local numMerchantItems = GetMerchantNumItems()
			local index, itemButton

			for i = 1, MERCHANT_ITEMS_PER_PAGE, 1 do
				local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i)
				local itemButton = _G["MerchantItem" .. i .. "ItemButton"]

				if ( index <= numMerchantItems ) then
					updateItem(itemButton, itemButton.link) 
				else
					updateItem(itemButton)
				end
			end
			
			local buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable = GetBuybackItemInfo(GetNumBuybackItems())
			if (buybackName) then
				updateItem(MerchantBuyBackItemItemButton, buybackName)
			else
				updateItem(MerchantBuyBackItemItemButton)
			end
		end
		hooksecurefunc("MerchantFrame_UpdateMerchantInfo", updateMerchantItems)

		local updateMerchantBuyBackItems = function()
			local numBuybackItems = GetNumBuybackItems()
			local itemButton

			for i = 1, BUYBACK_ITEMS_PER_PAGE, 1 do
				itemButton = _G["MerchantItem" .. i .. "ItemButton"]
				if ( i <= numBuybackItems ) then
					updateItem(itemButton, GetBuybackItemLink(i)) 
				else
					updateItem(itemButton)
				end
			end
		end
		hooksecurefunc("MerchantFrame_UpdateBuybackInfo", updateMerchantBuyBackItems)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end