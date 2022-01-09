--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_GuildBankUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Guild Bank"])
	self:SetAttribute("description", L["The Guild Bank window with your guild's gold and items."])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(GuildBankFrame)
		gUI:DisableTextures(GuildBankEmblemFrame)
		gUI:DisableTextures(GuildBankInfoScrollFrame)
		gUI:DisableTextures(GuildBankTransactionsScrollFrame)
		gUI:DisableTextures(GuildBankPopupFrame)
		gUI:DisableTextures(GuildBankPopupScrollFrame)
		gUI:HideTexture(GuildBankPopupNameLeft)
		gUI:HideTexture(GuildBankPopupNameRight)
		gUI:HideTexture(GuildBankPopupNameMiddle)
		gUI:HideTexture(GuildBankMoneyFrameBackgroundLeft)
		gUI:HideTexture(GuildBankMoneyFrameBackgroundRight)
		gUI:HideTexture(GuildBankMoneyFrameBackgroundMiddle)
		
		GuildBankMoneyLimitLabel:SetFontObject(gUI_TextFontTiny)
		GuildBankMoneyLimitLabel:SetPoint("BOTTOMLEFT", 16, 6)
		
		GuildBankMoneyUnlimitedLabel:SetFontObject(gUI_TextFontTinyWhite)
	
		gUI:SetUITemplate(GuildBankFrameDepositButton, "button", true)
		gUI:SetUITemplate(GuildBankFrameWithdrawButton, "button", true)
		GuildBankFrameWithdrawButton:SetPoint("RIGHT", GuildBankFrameDepositButton, "LEFT", -8, 0)
		gUI:SetUITemplate(GuildBankInfoSaveButton, "button", true)
		gUI:SetUITemplate(GuildBankFramePurchaseButton, "button", true)
		gUI:SetUITemplate(GuildBankPopupOkayButton, "button", true)
		gUI:SetUITemplate(GuildBankPopupCancelButton, "button", true)
		gUI:SetUITemplate(GuildBankPopupEditBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildItemSearchBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		GuildItemSearchBox:SetPoint("TOPRIGHT", -20, -36)

		gUI:SetUITemplate(GuildBankFrame, "outerbackdrop", nil, 8, 8, 6, 0)
		gUI:SetUITemplate(GuildBankPopupFrame, "outerbackdrop", nil, 6, 8, 24, 24)
		
		gUI:SetUITemplate(GuildBankTransactionsScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildBankInfoScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildBankPopupScrollFrameScrollBar, "scrollbar")
		
		gUI:SetUITemplate(GuildBankFrameTab1, "tab")
		gUI:SetUITemplate(GuildBankFrameTab2, "tab")
		gUI:SetUITemplate(GuildBankFrameTab3, "tab")
		gUI:SetUITemplate(GuildBankFrameTab4, "tab")
		
		GuildBankFrame.inset = CreateFrame("Frame", nil, GuildBankFrame)
		gUI:SetUITemplate(GuildBankFrame.inset, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		GuildBankFrame.inset:SetPoint("TOPLEFT", 19, -58)
		GuildBankFrame.inset:SetPoint("BOTTOMRIGHT", -16, 62)	
		
		gUI:KillObject(GuildBankEmblemFrame)
		
		for i = 1, GuildBankFrame:GetNumChildren() do
			local child = select(i, GuildBankFrame:GetChildren())
			if (child.GetPushedTexture) and (child:GetPushedTexture()) and not(child:GetName()) then
				gUI:SetUITemplate(child, "closebutton", "TOPRIGHT", -12, -12) -- another one that can't be auto-detected
			end
		end
		
		local updateAllBorders = function()
			for i = 1, NUM_GUILDBANK_COLUMNS do
				gUI:DisableTextures(_G["GuildBankColumn" .. i])
				for j = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
					local button = _G["GuildBankColumn" .. i .. "Button" .. j]
					local tab = GetCurrentGuildBankTab()
					local slot = (NUM_SLOTS_PER_GUILDBANK_GROUP * (i-1)) + j
					local link = GetGuildBankItemLink(tab, slot)

					if (link) then
						local quality = (select(3, GetItemInfo(link)))
						if (quality) and (quality ~= 1) then
							local r, g, b, hex = GetItemQualityColor(quality)
							button:SetBackdropBorderColor(r, g, b)
						else
							button:SetBackdropBorderColor(unpack(C["border"]))
						end
						button.Gloss:Show()
					else
						button:SetBackdropBorderColor(unpack(C["border"]))
						button.Gloss:Hide()
					end
				end
			end
		end
		
		for i = 1, NUM_GUILDBANK_COLUMNS do
			gUI:DisableTextures(_G["GuildBankColumn" .. i])
			
			for j = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
				local button = _G["GuildBankColumn" .. i .. "Button" .. j]
				local icon = _G["GuildBankColumn" .. i .. "Button" .. j .. "IconTexture"]

				-- gUI:DisableTextures(button) -- removing all kills the search overlay. baaad. 
				gABT:GetStyleFunction()(button)
				
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
		end
		
		for i = 1, 8 do
			local button = _G["GuildBankTab" .. i .. "Button"]
			
			gUI:DisableTextures(_G["GuildBankTab" .. i])
			gABT:GetStyleFunction()(button)
		end
		
		for i = 1, 16 do
			local button = _G["GuildBankPopupButton" .. i]
			
			-- gUI:DisableTextures(button)
			local slot = select(2, button:GetRegions())
			gUI:KillObject(slot)
			gABT:GetStyleFunction()(button)
		end	

		updateAllBorders()
		hooksecurefunc("GuildBankFrame_Update", updateAllBorders)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end