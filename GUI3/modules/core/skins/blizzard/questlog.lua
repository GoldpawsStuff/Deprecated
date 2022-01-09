--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("QuestFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Quest Log"])
	self:SetAttribute("description", L["Main quest log"])
	
	local func = function()
		local a = gUI:GetOverlayAlpha() 
		local r, g, b = unpack(C["overlay"])
			
		gUI:DisableTextures(EmptyQuestLogFrame)
		gUI:DisableTextures(QuestDetailScrollFrame)
		gUI:DisableTextures(QuestDetailScrollChildFrame)
		gUI:DisableTextures(QuestFrame)
		gUI:DisableTextures(QuestLogFrameInset)
		gUI:DisableTextures(QuestLogScrollFrame)
		gUI:DisableTextures(QuestFrameDetailPanel)
		gUI:DisableTextures(QuestFrameRewardPanel)
		gUI:DisableTextures(QuestFrameProgressPanel)
		-- gUI:DisableTextures(QuestInfoSkillPointFrame)
		
		gUI:HideTexture(QuestInfoSkillPointFrameSkillPointBg)
		gUI:HideTexture(QuestInfoSkillPointFrameSkillPointBgGlow)
		gUI:HideObject(QuestInfoSkillPointFrameNameFrame)
		
		gUI:DisableTextures(QuestInfoItemHighlight)
		gUI:DisableTextures(QuestLogCount)
		gUI:DisableTextures(QuestLogFrame)
		gUI:DisableTextures(QuestLogDetailFrame)
		gUI:DisableTextures(QuestLogDetailFrameInset)
		gUI:DisableTextures(QuestLogDetailScrollFrame)
		gUI:DisableTextures(QuestLogFrameShowMapButton)
		gUI:DisableTextures(QuestNPCModel)
		gUI:DisableTextures(QuestNPCModelTextFrame)
		gUI:DisableTextures(QuestRewardScrollFrame)
		gUI:DisableTextures(QuestRewardScrollChildFrame)
		gUI:DisableTextures(QuestInfoSpecialObjectivesFrame)
		gUI:DisableTextures(QuestInfoSpellObjectiveFrame)

		gUI:HideTexture(QuestFrameRewardPanelMaterialTopLeft)
		gUI:HideTexture(QuestFrameRewardPanelMaterialTopRight)
		gUI:HideTexture(QuestFrameRewardPanelMaterialBotLeft)
		gUI:HideTexture(QuestFrameRewardPanelMaterialBotRight)
		gUI:HideTexture(QuestFrameDetailPanelMaterialTopLeft)
		gUI:HideTexture(QuestFrameDetailPanelMaterialTopRight)
		gUI:HideTexture(QuestFrameDetailPanelMaterialBotLeft)
		gUI:HideTexture(QuestFrameDetailPanelMaterialBotRight)

		gUI:KillObject(QuestFramePortrait)
			
		gUI:SetUITemplate(QuestFrameAcceptButton, "button", true)
		gUI:SetUITemplate(QuestFrameDeclineButton, "button", true)
		gUI:SetUITemplate(QuestFrameCompleteButton, "button", true)
		gUI:SetUITemplate(QuestFrameGoodbyeButton, "button", true)
		gUI:SetUITemplate(QuestFrameCompleteQuestButton, "button", true)
		gUI:SetUITemplate(QuestLogFrameAbandonButton, "button", true)
		gUI:SetUITemplate(QuestLogFrameCancelButton, "button", true)
		gUI:SetUITemplate(QuestLogFrameCompleteButton, "button", true)
		gUI:SetUITemplate(QuestLogFramePushQuestButton, "button", true)
		gUI:SetUITemplate(QuestLogFrameTrackButton, "button", true)
		gUI:SetUITemplate(QuestLogFrameShowMapButton, "button", true)

		gUI:SetUITemplate(QuestFrameCloseButton, "closebutton", "TOPRIGHT", -8, -8)
		gUI:SetUITemplate(QuestLogDetailFrameCloseButton, "closebutton")
		gUI:SetUITemplate(QuestLogFrameCloseButton, "closebutton", "TOPRIGHT", -8, -8)

		gUI:SetUITemplate(QuestFrame, "backdrop")
		gUI:SetUITemplate(QuestLogFrame, "outerbackdrop", nil, 0, 0, 4, 0)
		gUI:SetUITemplate(QuestLogDetailFrame, "backdrop")
		gUI:SetUITemplate(QuestNPCModel, "outerbackdrop", nil, -3, -3, -3, -3)
		gUI:SetUITemplate(QuestNPCModelTextFrame, "outerbackdrop", nil, -3, -3, -3, -3) -- :SetBackdropColor(r, g, b, a)
		--	QuestInfoItemHighlight"outerbackdrop")

		gUI:SetUITemplate(QuestLogScrollFrame, "outerbackdrop", nil, 0, 0, 4, 0):SetBackdropColor(r, g, b, a)
		gUI:SetUITemplate(QuestLogDetailScrollFrame, "outerbackdrop", nil, 0, 0, 4, 0):SetBackdropColor(r, g, b, a)
		gUI:SetUITemplate(QuestDetailScrollFrameScrollBar, "scrollbar", true)
		gUI:SetUITemplate(QuestLogDetailScrollFrameScrollBar, "scrollbar", true)
		gUI:SetUITemplate(QuestLogScrollFrameScrollBar, "scrollbar", true)
		gUI:SetUITemplate(QuestNPCModelTextScrollFrameScrollBar, "scrollbar", true)
		gUI:SetUITemplate(QuestProgressScrollFrameScrollBar, "scrollbar", true)
		gUI:SetUITemplate(QuestRewardScrollFrameScrollBar, "scrollbar", true)
			
		QuestLogFrameShowMapButton.text:ClearAllPoints()
		QuestLogFrameShowMapButton.text:SetPoint("CENTER")
		QuestLogFrameShowMapButton:SetSize(QuestLogFrameShowMapButton:GetWidth() - 30, QuestLogFrameShowMapButton:GetHeight(), - 40)

		--	QuestInfoSkillPointFrame:SetWidth(QuestInfoSkillPointFrame:GetWidth() - 4)
		QuestInfoSkillPointFrame:SetFrameLevel(QuestInfoSkillPointFrame:GetFrameLevel() + 2)
		local skillBackdrop = gUI:SetUITemplate(QuestInfoSkillPointFrame, "itembackdrop", QuestInfoSkillPointFrameIconTexture)
		gUI:SetUITemplate(skillBackdrop, "gloss", QuestInfoSkillPointFrameIconTexture)
		gUI:SetUITemplate(skillBackdrop, "shade", QuestInfoSkillPointFrameIconTexture)
			
		QuestInfoSkillPointFrameIconTexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		QuestInfoSkillPointFrameIconTexture:SetDrawLayer("OVERLAY")
		QuestInfoSkillPointFrameIconTexture:SetPoint("TOPLEFT", 0, 0)
		-- QuestInfoSkillPointFrameIconTexture:SetPoint("BOTTOMRIGHT", 0, 0)
		QuestInfoSkillPointFrameIconTexture:SetSize(QuestInfoSkillPointFrameIconTexture:GetWidth() - 3, QuestInfoSkillPointFrameIconTexture:GetHeight() - 3)
		QuestInfoSkillPointFrameCount:SetDrawLayer("OVERLAY")
		-- QuestInfoSkillPointFrameCount:SetFontObject(gUI_DisplayFontSmall)
		QuestInfoSkillPointFramePoints:ClearAllPoints()
		QuestInfoSkillPointFramePoints:SetPoint("BOTTOMRIGHT", QuestInfoSkillPointFrameIconTexture, "BOTTOMRIGHT")
		-- QuestInfoSkillPointFramePoints:SetFontObject(gUI_DisplayFontSmall)

		QuestInfoSkillPointFrameCount:SetParent(skillBackdrop)
		QuestInfoSkillPointFramePoints:SetParent(skillBackdrop)
		QuestInfoSkillPointFrameIconTexture:SetParent(skillBackdrop)
		
		QuestInfoSkillPointFrameName:SetParent(QuestInfoSkillPointFrame)
		QuestInfoSkillPointFrameName:ClearAllPoints()
		QuestInfoSkillPointFrameName:SetPoint("LEFT", QuestInfoSkillPointFrameIconTexture, "RIGHT", 12, 0)
		
		gUI:SetUITemplate(QuestInfoItemHighlight, "targetborder")
		QuestInfoItemHighlight:SetBackdropBorderColor(unpack(C["value"]))
		QuestInfoItemHighlight:SetBackdropColor(0, 0, 0, 0)
		QuestInfoItemHighlight:SetSize(142, 40)

		QuestInfoSpellObjectiveFrame.backdrop = gUI:SetUITemplate(QuestInfoSpellObjectiveFrame, "itembackdrop", QuestInfoSpellObjectiveFrame.Icon)
		QuestInfoSpellObjectiveFrame.Icon:SetParent(QuestInfoSpellObjectiveFrame.backdrop)
		QuestInfoSpellObjectiveFrame.Icon:SetDrawLayer("OVERLAY")
		QuestInfoSpellObjectiveFrame.Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		gUI:SetUITemplate(QuestInfoSpellObjectiveFrame.backdrop, "gloss", QuestInfoSpellObjectiveFrame.Icon)
		gUI:SetUITemplate(QuestInfoSpellObjectiveFrame.backdrop, "shade", QuestInfoSpellObjectiveFrame.Icon)
			
		local updateQuestLog = function()
			local numEntries, numQuests = GetNumQuestLogEntries()
			local scrollOffset = HybridScrollFrame_GetOffset(QuestLogScrollFrame)
			
			local questLogTitle, questIndex, isCollapsed, isHeader, _
		
			local buttons = QuestLogScrollFrame.buttons
			for i = 1, #buttons do
				questLogTitle = buttons[i]
				questIndex = i + scrollOffset
				
				if ( questIndex <= numEntries ) then
					_, _, _, _, isHeader, isCollapsed, _, _, _, _, _ = GetQuestLogTitle(questIndex)
					if (isHeader) then
						if (isCollapsed) then
							gUI:SetUITemplate(questLogTitle, "arrow", "down")
						else
							gUI:SetUITemplate(questLogTitle, "arrow", "up")
						end
					end
				end
			end
		end
		updateQuestLog()
			
		for i = 1, 6 do
			local button = _G["QuestProgressItem" .. i]
			local icon = _G["QuestProgressItem" .. i .. "IconTexture"]
			local count = _G["QuestProgressItem" .. i .. "Count"]

			gUI:KillObject(_G["QuestProgressItem" .. i .. "NameFrame"])
			local name = _G["QuestProgressItem" .. i .. "Name"]
			name:SetParent(button)
			name:ClearAllPoints()
			name:SetPoint("LEFT", icon, "RIGHT", 12, 0)

			-- gUI:DisableTextures(button)

			local backdrop = gUI:SetUITemplate(button, "border", icon)
			gUI:SetUITemplate(backdrop, "gloss", icon)
			gUI:SetUITemplate(backdrop, "shade", icon)

			button:SetWidth(button:GetWidth() - 4)
			button:SetFrameLevel(button:GetFrameLevel() + 2)

			icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icon:SetDrawLayer("OVERLAY")
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT", 3, -3)
			icon:SetSize(icon:GetWidth() - 3, icon:GetHeight() - 3)
			icon:SetParent(backdrop)

			count:SetDrawLayer("OVERLAY")
			count:SetParent(backdrop)
				
			button.backdrop = backdrop
		end
			
		do
			local button = QuestInfoRewardSpell
			local icon = QuestInfoRewardSpellIconTexture

			gUI:KillObject(QuestInfoRewardSpellSpellBorder)
			gUI:KillObject(QuestInfoRewardSpellNameFrame)
			QuestInfoRewardSpellName:SetParent(button)
			
			-- gUI:DisableTextures(button)

			local backdrop = gUI:SetUITemplate(button, "border", icon)
			gUI:SetUITemplate(backdrop, "gloss", icon)
			gUI:SetUITemplate(backdrop, "shade", icon)

			button:SetWidth(button:GetWidth() - 4)
			button:SetFrameLevel(button:GetFrameLevel() + 2)
			
			icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icon:SetDrawLayer("OVERLAY")
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT", 3, -3)
			icon:SetSize(icon:GetWidth() - 3, icon:GetHeight() - 3)
			icon:SetParent(backdrop)

			button.backdrop = backdrop
		end
			
		for i = 1, MAX_NUM_ITEMS do
			local item = _G["QuestInfoItem" .. i]
			local icon = _G["QuestInfoItem" .. i .. "IconTexture"]
			local count = _G["QuestInfoItem" .. i .. "Count"]
			local pawn = item.PawnQuestAdvisor
			
			gUI:KillObject(_G["QuestInfoItem" .. i .. "NameFrame"])
			local name = _G["QuestInfoItem" .. i .. "Name"]
			name:SetParent(item)
			name:ClearAllPoints()
			name:SetPoint("LEFT", icon, "RIGHT", 12, 0)

			-- gUI:DisableTextures(item)
				
			local backdrop = gUI:SetUITemplate(item, "border", icon)
			gUI:SetUITemplate(backdrop, "gloss", icon)
			gUI:SetUITemplate(backdrop, "shade", icon)

			item:SetWidth(item:GetWidth() - 4)
			item:SetFrameLevel(item:GetFrameLevel() + 2)

			icon:SetDrawLayer("OVERLAY")
			icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT", 3, -3)
			icon:SetSize(icon:GetWidth() - 3, icon:GetHeight() - 3)
			icon:SetParent(backdrop)
				
			count:SetDrawLayer("OVERLAY")
			count:SetParent(backdrop)
			-- count:SetFontObject(gUI_DisplayFontSmall)
				
			if (pawn) then
				pawn:SetDrawLayer("OVERLAY")
				pawn:SetParent(backdrop)
			end
				
			item.backdrop = backdrop
		end
			
		-- compability fix, not any actual skinning
		if (PawnUI_OnQuestInfo_ShowRewards) then
			local fixPawn = function()
				for i = 1, MAX_NUM_ITEMS do
					local item = _G["QuestInfoItem" .. i]
					local pawn = item.PawnQuestAdvisor
					if (pawn) then
						pawn:SetDrawLayer("OVERLAY")
						pawn:SetParent(item.backdrop)
					end	
				end
			end
			hooksecurefunc("PawnUI_OnQuestInfo_ShowRewards", fixPawn)
		end
			
		-- postupdate item coloring
		local updateQuestInfoItems = function()
			local name, texture, numItems, quality, isUsable
			local texture, name, isTradeskillSpell, isSpellLearned
			local questItem
			local numQuestRewards = 0
			local numQuestChoices = 0
			local numQuestCurrencies = 0
			local numQuestSpellRewards = 0
			
			if (QuestInfoFrame.questLog) then
				numQuestRewards = GetNumQuestLogRewards()
				numQuestChoices = GetNumQuestLogChoices()
				numQuestCurrencies = GetNumQuestLogRewardCurrencies()
				if (GetQuestLogRewardSpell()) then
					numQuestSpellRewards = 1
				end
			else
				numQuestRewards = GetNumQuestRewards()
				numQuestChoices = GetNumQuestChoices()
				numQuestCurrencies = GetNumRewardCurrencies()
				if (GetRewardSpell()) then
					numQuestSpellRewards = 1
				end
			end
				
			-- just return if there are no rewards to worry about
			local totalRewards = numQuestRewards + numQuestChoices + numQuestCurrencies
			if ((totalRewards == 0) and (numQuestSpellRewards == 0)) then
				return
			end
			
			local rewardsCount = 0
			
			-- choosable rewards
			if (numQuestChoices > 0) then
				local index
				local baseIndex = rewardsCount
				for i = 1, numQuestChoices, 1 do
					index = i + baseIndex
					questItem = _G["QuestInfoItem" .. index]

					if ( QuestInfoFrame.questLog ) then
						name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo(i)
					else
						name, texture, numItems, quality, isUsable = GetQuestItemInfo("choice", i)
					end
					
					if (texture) and (quality) and (quality > 1) then
						local r, g, b, hex = GetItemQualityColor(quality)
						questItem.backdrop:SetBackdropBorderColor(r, g, b)
					else
						questItem.backdrop:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
					end

					rewardsCount = rewardsCount + 1
				end
			end
				
			-- spell rewards
			if (numQuestSpellRewards > 0) then
				questItem = QuestInfoRewardSpell
				
				if (QuestInfoFrame.questLog) then
					texture, name, isTradeskillSpell, isSpellLearned = GetQuestLogRewardSpell()
				else
					texture, name, isTradeskillSpell, isSpellLearned = GetRewardSpell()
				end

				if (texture) and (quality) and (quality > 1) then
					local r, g, b, hex = GetItemQualityColor(quality)
					questItem.backdrop:SetBackdropBorderColor(r, g, b)
				else
					questItem.backdrop:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				end
			end
			
			-- mandatory rewards
			if ((numQuestRewards > 0) or (numQuestCurrencies > 0)) then
				-- items
				local index
				local baseIndex = rewardsCount
				for i = 1, numQuestRewards, 1 do
					index = i + baseIndex
					questItem = _G["QuestInfoItem" .. index]

					if (QuestInfoFrame.questLog) then
						name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(i)
					else
						name, texture, numItems, quality, isUsable = GetQuestItemInfo("reward", i)
					end
					
					if (texture) and (quality) and (quality > 1) then
						local r, g, b, hex = GetItemQualityColor(quality)
						questItem.backdrop:SetBackdropBorderColor(r, g, b)
					else
						questItem.backdrop:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
					end

					rewardsCount = rewardsCount + 1
				end
				
				-- currency
				baseIndex = rewardsCount
				for i = 1, numQuestCurrencies, 1 do
					index = i + baseIndex
					questItem = _G["QuestInfoItem"..index]
					
					if (QuestInfoFrame.questLog) then
						name, texture, numItems = GetQuestLogRewardCurrencyInfo(i)
					else
						name, texture, numItems = GetQuestCurrencyInfo("reward", i)
					end

					if (texture) and (quality) and (quality > 1) then
						local r, g, b, hex = GetItemQualityColor(quality)
						questItem.backdrop:SetBackdropBorderColor(r, g, b)
					else
						questItem.backdrop:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
					end
					
					rewardsCount = rewardsCount + 1
				end
			end
				
			--[[
				for i = 1, MAX_NUM_ITEMS do
					local item = _G["QuestInfoItem" .. i]
					local name, texture, numItems, quality, isUsable
					
					if (QuestInfoFrame.questLog) then
					
						if (item.type == "reward") then
							if (item.objectType == "item") then
								name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(i)
							elseif (item.objectType == "currency") then
								name, texture, numItems = GetQuestLogRewardCurrencyInfo(i)
							end
						elseif (item.type == "choice") then
							if (item.objectType == "item") then
								name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo(i)
							end
						end
					else
						
						-- we need this check to avoid nil/"invalid quest item" errors
						if (item.type == "reward") then
							if (item.objectType == "item") then
								name, texture, numItems, quality, isUsable = GetQuestItemInfo(item.type, i)
								
							elseif (item.objectType == "currency") then
								name, texture, numItems = GetQuestCurrencyInfo(item.type, i)
							end
						elseif (item.type == "choice") then
							if (item.objectType == "item") then
								name, texture, numItems, quality, isUsable = GetQuestItemInfo(item.type, i)
								
							elseif (item.objectType == "currency") then
								name, texture, numItems = GetQuestCurrencyInfo(item.type, i)
							end
						end
					end
					
			]]--
					

		--		end
		end
		
		QuestInfoRewardsFrame:HookScript("OnShow", updateQuestInfoItems)
		hooksecurefunc("QuestInfo_Display", updateQuestInfoItems)
		hooksecurefunc("QuestInfo_ShowRewards", updateQuestInfoItems)
		
		local updateDisplay = function(template, parentFrame, acceptButton, material)
			QuestInfoTitleHeader:SetTextColor(unpack(C["value"]))
			QuestInfoDescriptionHeader:SetTextColor(unpack(C["value"]))
			QuestInfoDescriptionText:SetTextColor(unpack(C["index"]))
			QuestInfoGroupSize:SetTextColor(unpack(C["index"]))
			QuestInfoItemChooseText:SetTextColor(unpack(C["index"]))
			QuestInfoItemReceiveText:SetTextColor(unpack(C["index"]))
			QuestInfoObjectivesHeader:SetTextColor(unpack(C["value"]))
			QuestInfoObjectivesText:SetTextColor(unpack(C["index"]))
			QuestInfoRewardsHeader:SetTextColor(unpack(C["value"]))
			QuestInfoRewardText:SetTextColor(unpack(C["index"]))
			QuestInfoSpellLearnText:SetTextColor(unpack(C["index"]))
			QuestInfoXPFrameReceiveText:SetTextColor(unpack(C["index"]))
			QuestInfoSpellObjectiveLearnLabel:SetTextColor(unpack(C["value"]))
			
			local objectives = 0
			for i = 1, GetNumQuestLeaderBoards() do
				local _, type, done = GetQuestLogLeaderBoard(i)
				if (type ~= "spell") then
					objectives = objectives + 1

					local objective = _G["QuestInfoObjective" .. objectives]
					if (done) then
						objective:SetTextColor(unpack(C["value"]))
					else
						objective:SetTextColor(0.6, 0.6, 0.6)
					end
				end
			end			
		end

		local updateQuestProgress = function()
			QuestProgressTitleText:SetTextColor(unpack(C["value"]))
			QuestProgressText:SetTextColor(unpack(C["index"]))
			QuestProgressRequiredItemsText:SetTextColor(unpack(C["value"]))
			QuestProgressRequiredMoneyText:SetTextColor(unpack(C["value"]))
		end
		
		local updatePortrait = function(parent, portrait, text, name, x, y)
			QuestNPCModel:ClearAllPoints()
			QuestNPCModel:SetPoint("TOPLEFT", parent, "TOPRIGHT", x + 18, y)
			QuestNPCModelTextFrame:ClearAllPoints()
			QuestNPCModelTextFrame:SetPoint("TOPLEFT", QuestNPCModel, "BOTTOMLEFT", 0, -8)
			QuestNPCModelNameText:ClearAllPoints()
			QuestNPCModelNameText:SetPoint("TOP", QuestNPCModel, "TOP", 0, -8)
		end
		
		-- QuestTitleButton1
		
		local updateHighlight = function(self)
			QuestInfoItemHighlight:ClearAllPoints()
			QuestInfoItemHighlight:SetAllPoints(self)
		end

		local updateMoney = function()
			local requiredMoney = GetQuestLogRequiredMoney()
			if (requiredMoney > 0) then
				if (requiredMoney > GetMoney()) then
					QuestInfoRequiredMoneyText:SetTextColor(0.6, 0.6, 0.6)
				else
					QuestInfoRequiredMoneyText:SetTextColor(unpack(C["value"]))
				end
			end			
		end
		
		local questlevel = function()
			local buttons = QuestLogScrollFrame.buttons
			local numButtons = #buttons
			local scrollOffset = HybridScrollFrame_GetOffset(QuestLogScrollFrame)
			local numEntries, numQuests = GetNumQuestLogEntries()
			for i = 1, numButtons do
				local questIndex = i + scrollOffset
				local questLogTitle = buttons[i]
				if (questIndex <= numEntries) then
					local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(questIndex)
					if (not isHeader) then
						questLogTitle:SetText("[" .. level .. "] " .. title)
						QuestLogTitleButton_Resize(questLogTitle)
					end
				end
			end
		end
		questlevel()
		QuestLogScrollFrameScrollBar:HookScript("OnValueChanged", questlevel)

		hooksecurefunc("QuestLog_Update", questlevel)
		hooksecurefunc("QuestInfo_Display", updateDisplay)
		hooksecurefunc("QuestInfo_ShowRequiredMoney", updateMoney)
		hooksecurefunc("QuestInfoItem_OnClick", updateHighlight)
		hooksecurefunc("QuestFrame_ShowQuestPortrait", updatePortrait)
		hooksecurefunc("QuestFrameProgressItems_Update", updateQuestProgress)
		hooksecurefunc("QuestLog_Update", updateQuestLog)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end