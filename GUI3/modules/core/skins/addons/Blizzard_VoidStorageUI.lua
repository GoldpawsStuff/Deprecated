--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_VoidStorageUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Void Storage UI"])
	self:SetAttribute("description", L["The Void Storage interface"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		local VOID_DEPOSIT_MAX = 9
		local VOID_WITHDRAW_MAX = 9
		local VOID_STORAGE_MAX = 80

		gUI:DisableTextures(VoidStorageFrame)
		gUI:DisableTextures(VoidStorageBorderFrame)
		gUI:DisableTextures(VoidStorageContentFrame)
		gUI:DisableTextures(VoidStorageCostFrame)
		gUI:DisableTextures(VoidStorageDepositFrame)
		gUI:DisableTextures(VoidStorageMoneyFrame)
		gUI:DisableTextures(VoidStorageStorageFrame)
		gUI:DisableTextures(VoidStorageWithdrawFrame)
		
		gUI:SetUITemplate(VoidStorageTransferButton, "button", true)
		gUI:SetUITemplate(VoidStoragePurchaseButton, "button", true)
		gUI:SetUITemplate(VoidStorageHelpBoxButton, "button", true)
		
		gUI:SetUITemplate(VoidStorageBorderFrame.CloseButton, "closebutton", "TOPRIGHT", -8, -8)
		
		gUI:SetUITemplate(VoidItemSearchBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)

		gUI:SetUITemplate(VoidStorageFrame, "backdrop")
		gUI:SetUITemplate(VoidStorageHelpBox, "backdrop")
		gUI:SetUITemplate(VoidStoragePurchaseFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(VoidStorageCostFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(VoidStorageDepositFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(VoidStorageWithdrawFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(VoidStorageStorageFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		
		local styleButton = function(button)
			local bg = _G[button:GetName() .. "Bg"]
			local icon = _G[button:GetName() .. "IconTexture"]

			gUI:HideTexture(bg)
			gABT:GetStyleFunction()(button)

			local backdrop = button:GetBackdrop()
			backdrop.bgFile = M("Background", "gUI™ VoidStorage")
			button:SetBackdrop(backdrop)
			button:SetBackdropBorderColor(unpack(C["border"]))
			
			local overlay = CreateFrame("Frame", nil, button)
			overlay:SetAllPoints()

			local gloss = gUI:SetUITemplate(overlay, "gloss")
			gloss:ClearAllPoints()
			gloss:SetPoint("TOPLEFT", 3, -3)
			gloss:SetPoint("BOTTOMRIGHT", -3, 3)
			gloss:Hide()
			
			button.Gloss = gloss
			
			local shade = gUI:SetUITemplate(overlay, "shade")
			shade:ClearAllPoints()
			shade:SetPoint("TOPLEFT", 3, -3)
			shade:SetPoint("BOTTOMRIGHT", -3, 3)
		end
		
		for i = 1,VOID_DEPOSIT_MAX do
			styleButton(_G["VoidStorageDepositButton" .. i])
		end

		for i = 1,VOID_WITHDRAW_MAX do
			styleButton(_G["VoidStorageWithdrawButton" .. i])
		end

		for i = 1,VOID_STORAGE_MAX do
			styleButton(_G["VoidStorageStorageButton" .. i])
		end

		local postUpdateItem = function(item, itemID)
			local quality
			if (itemID) then
				quality = (itemID) and (select(3, GetItemInfo(itemID)))
				item.Gloss:Show()
			else
				item.Gloss:Hide()
			end
			if (quality) and (quality > 1) then
				local r, g, b, hex = GetItemQualityColor(quality)
				item:SetBackdropBorderColor(r, g, b)
			else
				item:SetBackdropBorderColor(unpack(C["border"]))
			end
		end
		
		local postUpdateStorage = function()
			for i = 1, VOID_DEPOSIT_MAX do
				postUpdateItem(_G["VoidStorageDepositButton" .. i], (GetVoidTransferDepositInfo(i)))
			end
			for i = 1, VOID_WITHDRAW_MAX do
				postUpdateItem(_G["VoidStorageWithdrawButton" .. i], (GetVoidTransferWithdrawalInfo(i)))
			end
			for i = 1, VOID_STORAGE_MAX do
				postUpdateItem(_G["VoidStorageStorageButton" .. i], (GetVoidItemInfo(i)))
			end
		end
		
		style:RegisterEvent("VOID_STORAGE_DEPOSIT_UPDATE", postUpdateStorage)
		style:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE", postUpdateStorage)
		hooksecurefunc("VoidStorage_ItemsUpdate", postUpdateStorage)

		-- Adding a minor delay here, to make up for server latency.
		-- Otherwise we'll have randomly colored itembuttons, 
		-- 	as not all the buttons and items seem to appear at once.
		VoidStorageFrame:HookScript("OnShow", function(self)
			style:ScheduleTimer(1, postUpdateStorage)
		end)
		
		postUpdateStorage()
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end