--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("AuctionLite")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", self:GetName()) -- don't localize
	self:SetAttribute("description", L["Skins the '%s' addon"]:format(self:GetName()))
	
	local func = function()
		-- clonky, I wanted the skinner API to handle all this
		-- might have to build this functionality into it if more addons need this kind of stuff
		local once, needBlizzAH
		needBlizzAH = function(self, event, addon)
			if (once) or ((event == "ADDON_LOADED") and (addon ~= "Blizzard_AuctionUI")) then
				return
			else
				gUI:UnregisterEvent("ADDON_LOADED", needBlizzAH)
			end
			once = true
			
			gUI:SetUITemplate(BuyAdvancedButton, "arrow", "down")
			gUI:SetUITemplate(SellRememberButton, "arrow", "down")
			gUI:SetUITemplate(BuySummaryButton, "arrow", "left")

			gUI:SetUITemplate(BuyApproveButton, "button", true) 
			gUI:SetUITemplate(BuyCancelPurchaseButton, "button", true) 
			gUI:SetUITemplate(BuyBidButton, "button", true) 
			gUI:SetUITemplate(BuyBuyoutButton, "button", true)
			gUI:SetUITemplate(BuyCancelAuctionButton, "button", true)
			gUI:SetUITemplate(BuyCancelSearchButton, "button", true)
			gUI:SetUITemplate(BuyScanButton, "button", true)
			gUI:SetUITemplate(BuySearchButton, "button", true)
			gUI:SetUITemplate(SellCreateAuctionButton, "button", true)
			
			gUI:SetUITemplate(SellShortAuctionButton, "radiobutton", true)
			gUI:SetUITemplate(SellMediumAuctionButton, "radiobutton", true)
			gUI:SetUITemplate(SellLongAuctionButton, "radiobutton", true)
			gUI:SetUITemplate(SellPerItemButton, "radiobutton", true)
			gUI:SetUITemplate(SellPerStackButton, "radiobutton", true)

			gUI:SetUITemplate(BuyName, "editbox")
			gUI:SetUITemplate(BuyQuantity, "editbox")
			gUI:SetUITemplate(SellStacks, "editbox")
			gUI:SetUITemplate(SellSize, "editbox")
			gUI:SetUITemplate(SellBidPriceCopper, "editbox")
			gUI:SetUITemplate(SellBidPriceGold, "editbox")
			gUI:SetUITemplate(SellBidPriceSilver, "editbox")
			gUI:SetUITemplate(SellBuyoutPriceCopper, "editbox")
			gUI:SetUITemplate(SellBuyoutPriceGold, "editbox")
			gUI:SetUITemplate(SellBuyoutPriceSilver, "editbox")

			gUI:DisableTextures(BuyScrollFrame)
			gUI:DisableTextures(SellScrollFrame)
			
			gUI:SetUITemplate(BuyScrollFrame, "backdrop")
			gUI:SetUITemplate(SellScrollFrame, "backdrop")

			gUI:SetUITemplate(BuyScrollFrameScrollBar, "scrollbar")
			gUI:SetUITemplate(SellScrollFrameScrollBar, "scrollbar")
			
			SellScrollFrame:SetWidth(AuctionFrame:GetWidth() - 258)
			BuyScrollFrame:SetWidth(AuctionFrame:GetWidth() - 54)
			
			local i = 4
			while (_G["AuctionFrameTab" .. i]) do
				gUI:SetUITemplate(_G["AuctionFrameTab" .. i], "tab", true)
				i = i + 1
			end
			
			if not(SellItemButton.BlizzSetNormalTexture) then
				SellItemButton.BlizzSetNormalTexture = SellItemButton.SetNormalTexture
				SellItemButton.SetNormalTexture = function(self, ...)
					SellItemButton:BlizzSetNormalTexture(...)

					local icon = SellItemButton:GetNormalTexture()
					if (icon) then
						icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
						icon:ClearAllPoints()
						icon:SetPoint("TOPLEFT", SellItemButton, "TOPLEFT", 3, -3)
						icon:SetPoint("BOTTOMRIGHT", SellItemButton, "BOTTOMRIGHT", -3, 3)
					end
				end
			end
			SellItemButton:SetNormalTexture(SellItemButton:GetNormalTexture())
			SellItemButton:SetBackdrop(gUI:GetItemButtonBackdrop())
			SellItemButton:SetBackdropColor(C["backdrop"][1], C["backdrop"][2], C["backdrop"][3], 1)
			SellItemButton:SetBackdropBorderColor(C["border"][1], C["border"][2], C["border"][3], 1)
			gUI:CreateUIShadow(SellItemButton)			
		end
		
		if (AuctionFrame) then
			needBlizzAH()
		else
			gUI:RegisterEvent("ADDON_LOADED", needBlizzAH)
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end