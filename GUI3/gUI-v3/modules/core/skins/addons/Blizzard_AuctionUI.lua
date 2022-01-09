--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_AuctionUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Auction House"])
	self:SetAttribute("description", L["The Auction House Interface"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(AuctionFrame)
		gUI:DisableTextures(AuctionProgressFrame)
		gUI:DisableTextures(AuctionsScrollFrame)
		gUI:DisableTextures(AuctionsItemButton)
		gUI:DisableTextures(BidScrollFrame)
		gUI:DisableTextures(BrowseFilterScrollFrame)
		gUI:DisableTextures(BrowseScrollFrame)
		
		gUI:KillObject(AuctionPortraitTexture)

		gUI:RemoveClutter(AuctionsBidSort)
		gUI:RemoveClutter(AuctionsDurationSort)
		gUI:RemoveClutter(AuctionsHighBidderSort)
		gUI:RemoveClutter(AuctionsQualitySort)
		gUI:RemoveClutter(BidBidSort)
		gUI:RemoveClutter(BidBuyoutSort)
		gUI:RemoveClutter(BidDurationSort)
		gUI:RemoveClutter(BidLevelSort)
		gUI:RemoveClutter(BidQualitySort)
		gUI:RemoveClutter(BidStatusSort)
		gUI:RemoveClutter(BrowseCurrentBidSort)
		gUI:RemoveClutter(BrowseDurationSort)
		gUI:RemoveClutter(BrowseHighBidderSort)
		gUI:RemoveClutter(BrowseLevelSort)
		gUI:RemoveClutter(BrowseQualitySort)

		gUI:SetUITemplate(BrowseNextPageButton, "arrow")
		gUI:SetUITemplate(BrowsePrevPageButton, "arrow")
		gUI:SetUITemplate(AuctionsCancelAuctionButton, "button", true)
		gUI:SetUITemplate(AuctionsCloseButton, "button", true)
		gUI:SetUITemplate(AuctionsCreateAuctionButton, "button", true)
		gUI:SetUITemplate(AuctionsNumStacksMaxButton, "button", true)
		gUI:SetUITemplate(AuctionsStackSizeMaxButton, "button", true)
		gUI:SetUITemplate(BidBidButton, "button", true)
		gUI:SetUITemplate(BidBuyoutButton, "button", true)
		gUI:SetUITemplate(BidCloseButton, "button", true)
		gUI:SetUITemplate(BrowseBidButton, "button", true)
		gUI:SetUITemplate(BrowseBuyoutButton, "button", true)
		gUI:SetUITemplate(BrowseCloseButton, "button", true)
		gUI:SetUITemplate(BrowseSearchButton, "button", true)
		gUI:SetUITemplate(BrowseResetButton, "button", true)
		gUI:SetUITemplate(IsUsableCheckButton, "checkbutton")
		gUI:SetUITemplate(ShowOnPlayerCheckButton, "checkbutton")
		gUI:SetUITemplate(AuctionFrameCloseButton, "closebutton", "TOPRIGHT", -4, -10)
		gUI:SetUITemplate(BrowseDropDown, "dropdown", true, 120)
		gUI:SetUITemplate(DurationDropDown, "dropdown", true)
		gUI:SetUITemplate(PriceDropDown, "dropdown", true)
		gUI:SetUITemplate(BrowseName, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BrowseMinLevel, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BrowseMaxLevel, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BrowseBidPriceGold, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BrowseBidPriceSilver, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BrowseBidPriceCopper, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BidBidPriceGold, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BidBidPriceSilver, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BidBidPriceCopper, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(AuctionsStackSizeEntry, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(AuctionsNumStacksEntry, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(StartPriceGold, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(StartPriceSilver, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(StartPriceCopper, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BuyoutPriceGold, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BuyoutPriceSilver, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(BuyoutPriceCopper, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(AuctionFrame, "outerbackdrop", nil, 6, -6, 9, 0)
		gUI:SetUITemplate(AuctionProgressFrame, "outerbackdrop", nil, 8, 8, 8, 8)
		gUI:SetUITemplate(AuctionsScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(BidScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(BrowseFilterScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(BrowseScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(AuctionProgressBar, "statusbar", true)
		
		-- these are just too tiny, we need to expand them a bit,
		-- as well as reposition and clean it up
		BrowseMinLevel:SetWidth(BrowseMinLevel:GetWidth() + 8)
		BrowseMaxLevel:SetWidth(BrowseMaxLevel:GetWidth() + 8)
		BrowseMaxLevel:ClearAllPoints()
		BrowseMaxLevel:SetPoint("LEFT", BrowseMinLevel, "RIGHT", 8, 0)
		BrowseLevelHyphen:Hide()

		BrowseNameText:ClearAllPoints()
		BrowseNameText:SetPoint("TOPLEFT", 30, -36)
		BrowseName:ClearAllPoints()
		BrowseName:SetPoint("TOPLEFT", BrowseNameText, "BOTTOMLEFT", 0, -2)
		
		BrowseLevelText:ClearAllPoints()
		BrowseLevelText:SetPoint("TOPLEFT", 200, -36)
		
		BrowseMinLevel:ClearAllPoints()
		BrowseMinLevel:SetPoint("TOPLEFT", BrowseLevelText, "BOTTOMLEFT", 0, -2)

		BrowseDropDownName:ClearAllPoints()
		BrowseDropDownName:SetPoint("TOPLEFT", AuctionFrameBrowse, "TOPLEFT", 310, -36)
		
		BrowseDropDown:ClearAllPoints()
		BrowseDropDown:SetPoint("TOPLEFT", BrowseDropDownName, "BOTTOMLEFT", -6, 2)
		
		IsUsableCheckButton:ClearAllPoints()
		IsUsableCheckButton:SetPoint("LEFT", BrowseDropDownButton, "RIGHT", 10, 16)
			
		-- Auctioneer moves these buttons around
		if not(IsAddOnLoaded("Auc-Advanced")) then
			BrowseSearchButton:ClearAllPoints()
			BrowseSearchButton:SetPoint("TOPRIGHT", 25, -25)
			BrowsePrevPageButton:ClearAllPoints()
			BrowsePrevPageButton:SetPoint("TOPLEFT", 658, -45)
			BrowseNextPageButton:ClearAllPoints()
			BrowseNextPageButton:SetPoint("TOPRIGHT", 70, -45)
		end
		
		-- make sure all tabs by all addons eventually are skinned
		local skinnedTabs = {}
		local updateTabs = function()
			local i = 1
			local tab = _G["AuctionFrameTab" .. i]
			while (tab) do
				if not(skinnedTabs[tab]) then
					gUI:SetUITemplate(tab, "tab", true)
				end
				i = i + 1
				tab = _G["AuctionFrameTab" .. i]
			end
		end
		AuctionFrame:HookScript("OnShow", updateTabs)
		updateTabs()

		gUI:SetUITemplate(AuctionProgressFrameCancelButton, "closebutton", "LEFT", AuctionProgressBar, "RIGHT", 12, 0) -- have to force this
		AuctionProgressFrameCancelButton:SetHitRectInsets(0, 0, 0, 0)
--		gUI:SetUITemplate(AuctionProgressFrameCancelButton, "outerbackdrop", AuctionProgressBarIcon)
		AuctionProgressBarIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		
		local styleAHButton = function(name, i)
			local button = _G[name .. i]
			local icon = _G[name .. i .. "Item"]
			
			gUI:DisableTextures(button)
			gABT:GetStyleFunction()(icon)

			gUI:CreateHighlight(button, 3, -3, 3, 3)
			gUI:CreatePushed(button, 3, -3, 3, 3)

		end
		
		for i = 1, NUM_FILTERS_TO_DISPLAY do
			local tab = _G["AuctionFilterButton" .. i]
			gUI:DisableTextures(tab)
			gUI:CreateHighlight(tab)
			gUI:CreatePushed(tab)
		end

		for i = 1, NUM_AUCTIONS_TO_DISPLAY do
			styleAHButton("AuctionsButton", i)
		end
		
		for i = 1, NUM_BROWSE_TO_DISPLAY do
			styleAHButton("BrowseButton", i)
		end
		
		for i = 1, NUM_BIDS_TO_DISPLAY do
			styleAHButton("BidButton", i)
		end

		AuctionsItemButton:SetPoint("TOPLEFT", 33, -97)
		AuctionsItemButton:SetSize(31, 31)
		gUI:SetUITemplate(AuctionsItemButton, "border")
		local updateAuctionItem = function(self, ...)
			local button = AuctionsItemButton:GetNormalTexture()
			if (button) then
				button:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			end
		end
		hooksecurefunc(AuctionsItemButton, "SetNormalTexture", updateAuctionItem)

		AuctionsScrollFrame:SetHeight(336)	
		BidScrollFrame:SetHeight(332)
		BrowseFilterScrollFrame:SetHeight(300) 
		BrowseScrollFrame:SetHeight(300)

		AuctionsCreateAuctionButton:SetPoint("BOTTOMLEFT", 18, 44)
		
		local makeAHBackdrop = function(parent, toprightAnchor, x, y, bottomleftanchor, x2, y2)
			local backdrop = CreateFrame("Frame", nil, parent)
			gUI:SetUITemplate(backdrop, "outerbackdrop"):SetBackdropColor(r, g, b, panelAlpha)

			if (toprightAnchor) then
				backdrop:SetPoint("TOPLEFT", toprightAnchor, "TOPRIGHT", x, y)
			else
				backdrop:SetPoint("TOPLEFT", x, y)
			end

			if (bottomleftanchor) then
				backdrop:SetPoint("BOTTOMRIGHT", bottomleftanchor, "BOTTOMRIGHT", x2, y2)
			else
				backdrop:SetPoint("BOTTOMRIGHT", x2, y2)
			end
			
			backdrop:SetFrameLevel(backdrop:GetFrameLevel() - 2)
			
			return backdrop
		end

		AuctionFrameBrowse.leftBackdrop = makeAHBackdrop(AuctionFrameBrowse, nil, 20, -103, nil, -575, 42)
		AuctionFrameBrowse.rightBackdrop = makeAHBackdrop(AuctionFrameBrowse, AuctionFrameBrowse.leftBackdrop, 8, 0, AuctionFrame, -12, 42)
		AuctionFrameBid.backdrop = makeAHBackdrop(AuctionFrameBid, nil, 20, -72, nil, 63, 42)
		AuctionFrameAuctions.leftBackdrop = makeAHBackdrop(AuctionFrameAuctions, nil, 19, -70, nil, -550, 42)
		AuctionFrameAuctions.rightBackdrop = makeAHBackdrop(AuctionFrameAuctions, AuctionFrameAuctions.leftBackdrop, 8, 0, AuctionFrame, -11, 42)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end