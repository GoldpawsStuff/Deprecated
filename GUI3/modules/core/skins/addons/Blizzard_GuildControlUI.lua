--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_GuildControlUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Guild Control UI"])
	self:SetAttribute("description", L["The window where you create, modify and delete the guild ranks and their permissions"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(GuildControlUI)
		gUI:DisableTextures(GuildControlUIHbar)
		gUI:DisableTextures(GuildControlUIRankBankFrame)
		gUI:DisableTextures(GuildControlUIRankBankFrameInset)
		gUI:DisableTextures(GuildControlUIRankSettingsFrameGoldBox)
		gUI:DisableTextures(GuildControlUIRankBankFrameInsetScrollFrame)
		
		gUI:SetUITemplate(GuildControlUIRankOrderFrameNewButton, "button", true)
		gUI:SetUITemplate(GuildControlUICloseButton, "closebutton", "TOPRIGHT", GuildControlUI, "TOPRIGHT", -4, -4)
		gUI:SetUITemplate(GuildControlUINavigationDropDown, "dropdown", true)
		gUI:SetUITemplate(GuildControlUIRankSettingsFrameRankDropDown, "dropdown", true)
		gUI:SetUITemplate(GuildControlUIRankBankFrameRankDropDown, "dropdown", true)
		gUI:SetUITemplate(GuildControlUIRankSettingsFrameGoldBox, "editbox", -5, -2, 5, -2):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildControlUI, "outerbackdrop")
		gUI:SetUITemplate(CreateFrame("Frame", nil, GuildControlUIRankSettingsFrame), "outerbackdrop", GuildControlUIRankSettingsFrameChatBg):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CreateFrame("Frame", nil, GuildControlUIRankSettingsFrame), "outerbackdrop", GuildControlUIRankSettingsFrameRosterBg):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CreateFrame("Frame", nil, GuildControlUIRankSettingsFrame), "outerbackdrop", GuildControlUIRankSettingsFrameInfoBg):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CreateFrame("Frame", nil, GuildControlUIRankSettingsFrame), "outerbackdrop", GuildControlUIRankSettingsFrameBankBg):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildControlUIRankBankFrameInsetScrollFrameScrollBar, "scrollbar")
		
		for i = 1, NUM_RANK_FLAGS do
			local checkbutton = _G["GuildControlUIRankSettingsFrameCheckbox" .. i]
			if (checkbutton) then
				gUI:SetUITemplate(checkbutton, "checkbutton")
			end
		end
		
		local skinned = {}
		local updateBankPermissions = function()
			local tab
			for i = 1, MAX_GUILDBANK_TABS do
				tab = _G["GuildControlBankTab" .. i]
				if (tab) and not(skinned[tab]) then
					tab:SetHeight(tab:GetHeight() + 16)
					gUI:KillObject(_G[tab:GetName() .. "Bg"])
					gUI:RemoveClutter(_G[tab:GetName() .. "Owned"].editBox)
					gUI:SetUITemplate(_G[tab:GetName() .. "BuyPurchaseButton"], "button")
					gUI:SetUITemplate(_G[tab:GetName() .. "Owned"], "insetbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
					gUI:SetUITemplate(_G[tab:GetName() .. "Owned"].editBox, "insetbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
					gUI:SetUITemplate(_G[tab:GetName() .. "OwnedViewCheck"], "checkbutton")
					gUI:SetUITemplate(_G[tab:GetName() .. "OwnedDepositCheck"], "checkbutton")
					gUI:SetUITemplate(_G[tab:GetName() .. "OwnedUpdateInfoCheck"], "checkbutton")
					gUI:SetUIShadowColor(_G[tab:GetName() .. "Owned"], 0, 0, 0, 0)
					gUI:SetUIShadowColor(_G[tab:GetName() .. "OwnedViewCheck"], 0, 0, 0, 0)
					gUI:SetUIShadowColor(_G[tab:GetName() .. "OwnedDepositCheck"], 0, 0, 0, 0)
					gUI:SetUIShadowColor(_G[tab:GetName() .. "OwnedUpdateInfoCheck"], 0, 0, 0, 0)
					_G[tab:GetName() .. "Owned"].editBox:SetHeight(_G[tab:GetName() .. "Owned"].editBox:GetHeight() + 4)
					_G[tab:GetName() .. "Owned"].editBox:SetFontObject(GUIS_NumberFontSmall)
					_G[tab:GetName() .. "Owned"].editBox:SetTextInsets(2, 2, 2, 2)
					_G[tab:GetName() .. "Owned"].tabIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
					_G[tab:GetName() .. "Owned"].tabIcon:ClearAllPoints()
					_G[tab:GetName() .. "Owned"].tabIcon:SetPoint("TOPLEFT", tab, "TOPLEFT", 12, -12)
					_G[tab:GetName() .. "OwnedViewCheck"]:SetPoint("TOPRIGHT", -100, -12)
					skinned[tab] = true
				end
			end
		end
		
		local fixTexCoord = function(self)
			self:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
			self:GetNormalTexture().SetTexCoord = noop
			self:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
			self:GetPushedTexture().SetTexCoord = noop
			self:GetDisabledTexture():SetTexCoord(0, 1, 0, 1)
			self:GetDisabledTexture().SetTexCoord = noop
			self:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
			self:GetHighlightTexture().SetTexCoord = noop
			self.SetNormalTexture = noop
			self.SetPushedTexture = noop
			self.SetHighlightTexture = noop
			self.SetDisabledTexture = noop
		end

		local updateRanks = function()
			for i = 1, GuildControlGetNumRanks() do
				local rank = _G["GuildControlUIRankOrderFrameRank" .. i]
				if (rank) and not(skinned[rank]) then
					gUI:SetUITemplate(rank.downButton, "arrow")
					gUI:SetUITemplate(rank.upButton, "arrow")
					gUI:SetUITemplate(rank.deleteButton, "closebutton")
					gUI:SetUITemplate(rank.nameBox, "editbox", -4, -2, 4, -4):SetBackdropColor(r, g, b, panelAlpha)
					fixTexCoord(rank.upButton)
					fixTexCoord(rank.downButton)
					fixTexCoord(rank.deleteButton)
					skinned[rank] = true
				end
			end				
		end

		style:RegisterEvent("GUILD_RANKS_UPDATE", updateRanks)
		style:RegisterEvent("GUILD_ROSTER_UPDATE", updateRanks)
		
		hooksecurefunc("GuildControlUI_RankOrder_Update", updateRanks)
		hooksecurefunc("GuildControlUI_BankTabPermissions_Update", updateBankPermissions)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end