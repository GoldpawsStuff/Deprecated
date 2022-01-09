--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_TradeSkillUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["TradeSkill"])
	self:SetAttribute("description", L["The tradeskill windows where you craft items."])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(TradeSkillFrame)
		gUI:DisableTextures(TradeSkillDetailScrollFrame)
		gUI:DisableTextures(TradeSkillDetailScrollChildFrame)
		gUI:DisableTextures(TradeSkillExpandButtonFrame)
		gUI:DisableTextures(TradeSkillFrameInset)
		gUI:DisableTextures(TradeSkillListScrollFrame)
		gUI:DisableTextures(TradeSkillGuildFrame)
		
		gUI:KillObject(TradeSkillFramePortrait)
		gUI:KillObject(TradeSkillFrameTabardEmblem)
		
		gUI:SetUITemplate(TradeSkillDecrementButton, "arrow")
		gUI:SetUITemplate(TradeSkillIncrementButton, "arrow")
		gUI:SetUITemplate(TradeSkillCollapseAllButton, "arrow")
		gUI:SetUITemplate(TradeSkillCancelButton, "button", true)
		gUI:SetUITemplate(TradeSkillCreateAllButton, "button", true)
		gUI:SetUITemplate(TradeSkillCreateButton, "button", true)
		gUI:SetUITemplate(TradeSkillFilterButton, "button", true)
		gUI:SetUITemplate(TradeSkillViewGuildCraftersButton, "button", true)
		gUI:SetUITemplate(TradeSkillFrameCloseButton, "closebutton")
		gUI:SetUITemplate(TradeSkillGuildFrameCloseButton, "closebutton")
		gUI:SetUITemplate(TradeSkillFrameSearchBox, "editbox")
		gUI:SetUITemplate(TradeSkillInputBox, "editbox")
		gUI:SetUITemplate(TradeSkillFrame, "outerbackdrop", nil, -6, -2, 0, 0)
		gUI:SetUITemplate(TradeSkillGuildFrame, "backdrop")
		gUI:SetUITemplate(TradeSkillGuildFrameContainer, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
--		gUI:SetUITemplate(TradeSkillSkillIcon, "outerbackdrop")
		
		local listBackdrop = CreateFrame("Frame", nil, TradeSkillFrame)
		listBackdrop:SetPoint("TOP", TradeSkillListScrollFrame, "TOP", 0, 0)
		listBackdrop:SetPoint("BOTTOM", TradeSkillListScrollFrame, "BOTTOM", 0, 0)
		listBackdrop:SetPoint("LEFT", TradeSkillListScrollFrame, "LEFT", 0, 0)
		listBackdrop:SetPoint("RIGHT", TradeSkillFrame, "RIGHT", -8, 0)
		
		local detailBackdrop = CreateFrame("Frame", nil, TradeSkillFrame)
		detailBackdrop:SetPoint("TOP", TradeSkillDetailScrollFrame, "TOP", 0, 0)
		detailBackdrop:SetPoint("BOTTOM", TradeSkillDetailScrollFrame, "BOTTOM", 0, 0)
		detailBackdrop:SetPoint("LEFT", TradeSkillDetailScrollFrame, "LEFT", 0, 0)
		detailBackdrop:SetPoint("RIGHT", TradeSkillFrame, "RIGHT", -8, 0)
		
		gUI:SetUITemplate(detailBackdrop, "outerbackdrop", nil, 0, 0, -2, 0):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(listBackdrop, "outerbackdrop", nil, 0, 0, 0, 0):SetBackdropColor(r, g, b, panelAlpha)
		
		local iconBackdrop = CreateFrame("Frame", nil, TradeSkillDetailScrollChildFrame)
		iconBackdrop:SetAllPoints(TradeSkillSkillIcon)
		gUI:SetUITemplate(iconBackdrop, "outerbackdrop")
		TradeSkillSkillIcon:SetParent(iconBackdrop)
		TradeSkillSkillIcon:SetSize(TradeSkillSkillIcon:GetWidth() - 6, TradeSkillSkillIcon:GetHeight() - 6)
		TradeSkillSkillIcon:ClearAllPoints()
		TradeSkillSkillIcon:SetPoint("TOPLEFT", TradeSkillDetailScrollChildFrame, "TOPLEFT", 11, -6)
		
		local iconCandy = CreateFrame("Frame", nil, TradeSkillSkillIcon)
		iconCandy:SetFrameLevel(TradeSkillSkillIcon:GetFrameLevel() + 1)
		iconCandy:SetAllPoints(TradeSkillSkillIcon)
		gUI:SetUITemplate(iconCandy, "gloss")
		gUI:SetUITemplate(iconCandy, "shade")
		TradeSkillSkillIcon.iconCandy = iconCandy
		
		gUI:SetUITemplate(TradeSkillListScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(TradeSkillDetailScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(TradeSkillRankFrame, "statusbar", true)
		gUI:SetUITemplate(TradeSkillRankFrame, "gloss")
		
		local point, anchor, relpoint, x, y = TradeSkillDetailScrollFrame:GetPoint()
		TradeSkillDetailScrollFrame:SetPoint(point, anchor, relpoint, x, -8)
		TradeSkillDetailScrollFrame:SetHeight(TradeSkillDetailScrollFrame:GetHeight() - 8)
		
		TradeSkillLinkButton:GetNormalTexture():SetTexCoord(0.25, 0.7, 0.37, 0.75)
		TradeSkillLinkButton:GetPushedTexture():SetTexCoord(0.25, 0.7, 0.45, 0.8)
		gUI:KillObject(TradeSkillLinkButton:GetHighlightTexture())
		TradeSkillLinkButton:SetSize(16, 16)
		TradeSkillLinkButton:SetPoint("LEFT", 12, 0)
		
		TradeSkillRankFrame:SetPoint("TOPLEFT", 45, -32)
		TradeSkillFrameSearchBox:SetPoint("TOPLEFT", TradeSkillRankFrame, "BOTTOMLEFT", 28, -8)

		for i = 1, TRADE_SKILLS_DISPLAYED do
			local button = _G["TradeSkillSkill" .. i]
			local bar = button.SubSkillRankBar 
			local rank = bar.Rank
			gUI:SetUITemplate(button, "arrow", "collapse")
			gUI:SetUITemplate(bar, "statusbar")
			rank:SetFontObject(gUI_DisplayFontExtraTinyWhite)
		end
		
		-- local updateTradeSkillList = function() 
		-- end
		-- hooksecurefunc("TradeSkillFrame_Update", updateTradeSkillList)

		-- fix the disappearing rank issue
		local fixRank = function(self)
			local _, max = self.SubSkillRankBar:GetMinMaxValues()
			if (max) then 
				self.SubSkillRankBar.Rank:SetText(self.SubSkillRankBar:GetValue() .. "/" .. max)
			end
		end
		hooksecurefunc("TradeSkillFrameButton_OnLeave", fixRank)
		
		local FixReagents = function()
			if (TradeSkillSkillIcon:GetNormalTexture()) then
				TradeSkillSkillIcon:GetNormalTexture():SetTexCoord(5/64, 59/64, 5/64, 59/64)
			end
			for i=1, MAX_TRADE_SKILL_REAGENTS do
				local button = _G["TradeSkillReagent" .. i]
				local icon = _G["TradeSkillReagent" .. i .. "IconTexture"]
				local count = _G["TradeSkillReagent" .. i .. "Count"]
				local name = _G["TradeSkillReagent" .. i .. "Name"]

				gUI:SetUITemplate(button, "insetbackdrop"):SetBackdropColor(r, g, b, 1/3)
				
				icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
				icon:SetDrawLayer("OVERLAY", -1)
				icon:ClearAllPoints()
				icon:SetPoint("TOPLEFT", button, "TOPLEFT", 8, -8)
				icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", 8 + (button:GetHeight() - 16), 8)
				if not(icon.backdrop) then
					local BackdropHolder = CreateFrame("Frame", nil, button)
					BackdropHolder:SetFrameLevel(button:GetFrameLevel() - 1)
					BackdropHolder:SetAllPoints(icon)

					local iconCandy = CreateFrame("Frame", nil, button)
					iconCandy:SetAllPoints(icon)
					gUI:SetUITemplate(iconCandy, "gloss")
					gUI:SetUITemplate(iconCandy, "shade")

					icon.backdrop = gUI:SetUITemplate(BackdropHolder, "border")
				end
				icon:SetParent(icon.backdrop)
				count:SetParent(icon.backdrop)
				count:SetDrawLayer("OVERLAY")
				name:SetParent(icon.backdrop)
				name:SetDrawLayer("OVERLAY")
				gUI:KillObject(_G["TradeSkillReagent" .. i .. "NameFrame"])
			end
		end
		hooksecurefunc("TradeSkillFrame_SetSelection", FixReagents)
		
		-- extra button for the enchantframe
		do
			local scroll, enchant = 38682, GetSpellInfo(7411)

			local enchantScrollButton = CreateFrame("Button", "GUIS_CreateScrollOfEnchant", TradeSkillFrame, "MagicButtonTemplate")
			enchantScrollButton:SetPoint("TOPRIGHT", TradeSkillCreateButton, "TOPLEFT")
			enchantScrollButton:SetScript("OnClick",function()
				DoTradeSkill(TradeSkillFrame.selectedSkill)
				UseItemByName(scroll)
			end)
			
			enchantScrollButton:SetScript("OnShow", function(self) 
				gUI:SetUITemplate(self, "button", true)
				self:SetScript("OnShow", nil)
			end)
			
			local enchantScrollButton = function(index)
				local skillName, skillType, numAvailable, isExpanded, serviceType, numSkillUps = GetTradeSkillInfo(index)
				if (((serviceType) and (CURRENT_TRADESKILL == enchant)) or ((serviceType) and GetLocale():find("zh"))) and not((IsTradeSkillGuild()) or (IsTradeSkillLinked())) then
					local scrolls = GetItemCount(scroll)
					enchantScrollButton:SetText(L["Scroll"] .. " (" .. scrolls .. ")")
					local failed, reagentName, reagentTexture, reagentCount, playerReagentCount
					for i = 1, GetTradeSkillNumReagents(index) do
						reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(index, i)
						if (playerReagentCount < reagentCount) then
							failed = true
						end
					end
					if ((skillName) and not(scrolls == 0) and not(failed)) then
						enchantScrollButton:Enable()
					else
						enchantScrollButton:Disable()
					end
					enchantScrollButton:Show()
				else
					enchantScrollButton:Hide()
				end
			end
			hooksecurefunc("TradeSkillFrame_SetSelection", enchantScrollButton)
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end