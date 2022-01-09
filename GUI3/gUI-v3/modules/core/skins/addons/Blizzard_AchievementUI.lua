--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_AchievementUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Achievements"])
	self:SetAttribute("description", L["The achievement- and statistic frames"])

	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		local SkinStatusBar = function(self, makeBorder)
			gUI:SetUITemplate(self, "statusbar", makeBorder)
				
			local name = self:GetName()
			local text = self.text or name and _G[name .. "Text"]
			if (text) then
				text:ClearAllPoints()
				text:SetPoint("RIGHT", -8, 0)
			end

			local title = self.title or name and _G[name .. "Title"]
			if (title) then
				title:ClearAllPoints()
				title:SetPoint("LEFT", 8, 0)
			end

			local label = self.label or name and _G[name .. "Label"]
			if (label) then
				label:ClearAllPoints()
				label:SetPoint("LEFT", 8, 0)
			end
		end	
		
		local StripBackdrop = function(self)
			for i = 1, self:GetNumChildren() do
				local child = select(i, self:GetChildren())
				if (child) and not(child:GetName()) then
					child:SetBackdrop(nil)
					child.SetBackdrop = noop
				end
			end
		end
		
		StripBackdrop(AchievementFrameAchievements)
		StripBackdrop(AchievementFrameComparison)
		StripBackdrop(AchievementFrameStats)
		StripBackdrop(AchievementFrameSummary)

		gUI:DisableTextures(AchievementFrame)
		gUI:DisableTextures(AchievementFrameAchievements)
		gUI:DisableTextures(AchievementFrameCategories)
		gUI:DisableTextures(AchievementFrameCategoriesContainer)
		gUI:DisableTextures(AchievementFrameComparison)
		gUI:DisableTextures(AchievementFrameComparisonHeader)
		gUI:DisableTextures(AchievementFrameComparisonSummaryPlayer)
		gUI:DisableTextures(AchievementFrameComparisonSummaryFriend)
		gUI:DisableTextures(AchievementFrameHeader)
		gUI:DisableTextures(AchievementFrameStats)
		gUI:DisableTextures(AchievementFrameStatsBG)
		gUI:DisableTextures(AchievementFrameSummary)
		gUI:DisableTextures(AchievementFrameSummaryAchievementsHeader)
		gUI:DisableTextures(AchievementFrameSummaryCategoriesHeader)

		gUI:HideTexture(AchievementFrameAchievementsBackground)
		gUI:HideTexture(AchievementFrameCategoriesBG)
		gUI:HideTexture(AchievementFrameComparisonBackground)
		gUI:HideTexture(AchievementFrameComparisonDark)
		gUI:HideTexture(AchievementFrameComparisonWatermark)

		gUI:RemoveClutter(AchievementFrameCategories)
		gUI:RemoveClutter(AchievementFrameAchievements)
		gUI:RemoveClutter(AchievementFrameComparison)

		gUI:KillObject(AchievementFrameGuildEmblemLeft)
		gUI:KillObject(AchievementFrameGuildEmblemRight)
		gUI:KillObject(AchievementFrameWaterMark)
		
		for i = 1, 8 do
			gUI:DisableTextures(_G["AchievementFrameSummaryCategoriesCategory" .. i .. "Button"])
			gUI:DisableTextures(_G["AchievementFrameSummaryCategoriesCategory" .. i .. "ButtonHighlight"])
		end
		
		for i = 1, 20 do
			gUI:DisableTextures(_G["AchievementFrameComparisonStatsContainerButton" .. i])
			gUI:HideTexture(_G["AchievementFrameComparisonStatsContainerButton" .. i .. "HeaderMiddle"])
			gUI:HideTexture(_G["AchievementFrameComparisonStatsContainerButton" .. i .. "HeaderLeft"])
			gUI:HideTexture(_G["AchievementFrameComparisonStatsContainerButton" .. i .. "HeaderRight"])
			gUI:DisableTextures(_G["AchievementFrameStatsContainerButton" .. i])
			gUI:HideTexture(_G["AchievementFrameStatsContainerButton" .. i .. "HeaderMiddle"])
			gUI:HideTexture(_G["AchievementFrameStatsContainerButton" .. i .. "HeaderLeft"])
			gUI:HideTexture(_G["AchievementFrameStatsContainerButton" .. i .. "HeaderRight"])
			_G["AchievementFrameStatsContainerButton" .. i]:GetHighlightTexture():SetTexture(1, 1, 1, 1/3)
			
			if (i%2 == 1) then
				_G["AchievementFrameStatsContainerButton" .. i]:SetBackdrop({ bgFile = gUI:GetBlankTexture() })
				_G["AchievementFrameStatsContainerButton" .. i]:SetBackdropColor(1, 1, 1, 1/10)

				_G["AchievementFrameComparisonStatsContainerButton" .. i]:SetBackdrop({ bgFile = gUI:GetBlankTexture() })
				_G["AchievementFrameComparisonStatsContainerButton" .. i]:SetBackdropColor(1, 1, 1, 1/10)
			end
		end
		
		gUI:SetUITemplate(AchievementFrameCloseButton, "closebutton", "TOPRIGHT", -4, 4)
		gUI:SetUITemplate(AchievementFrameFilterDropDown, "dropdown", true, 160)
		gUI:SetUITemplate(AchievementFrame, "outerbackdrop", nil, -8, 0, 0, 0)
		gUI:SetUITemplate(AchievementFrameCategoriesContainer, "outerbackdrop", nil, -3, 2, -4, 2):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(AchievementFrameAchievementsContainer, "outerbackdrop", nil, -1, 0, -2, 5):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(AchievementFrameComparisonStatsContainer, "outerbackdrop", nil, -4, -1, -4, 6):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(AchievementFrameStatsContainer, "outerbackdrop", nil, -4, -3, -4, 0):SetBackdropColor(r, g, b, panelAlpha)

		AchievementFrameStatsContainer:SetPoint("TOPLEFT", 6, -6)
		AchievementFrameStatsContainer:SetWidth(AchievementFrameStatsContainer:GetWidth() - 6)
		AchievementFrameStatsContainer:SetHeight(AchievementFrameStatsContainer:GetHeight() - 6)
		
		gUI:SetUITemplate(AchievementFrameAchievementsContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(AchievementFrameCategoriesContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(AchievementFrameComparisonContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(AchievementFrameComparisonStatsContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(AchievementFrameStatsContainerScrollBar, "scrollbar")
		
		SkinStatusBar(AchievementFrameComparisonSummaryPlayerStatusBar, true)
		SkinStatusBar(AchievementFrameComparisonSummaryFriendStatusBar, true)
		SkinStatusBar(AchievementFrameSummaryCategoriesStatusBar, true)
		
		for i = 1, 10 do
			SkinStatusBar(_G["AchievementFrameSummaryCategoriesCategory" .. i], true)
			gUI:CreateHighlight(_G["AchievementFrameSummaryCategoriesCategory" .. i .. "Button"])
		end
		
		local skinnedTabs = {}
		local skinTabs = function()
			local i = 1
			while (_G["AchievementFrameTab" .. i]) do
				if not(skinnedTabs[_G["AchievementFrameTab" .. i]]) then
					gUI:SetUITemplate(_G["AchievementFrameTab" .. i], "tab", true)
					skinnedTabs[_G["AchievementFrameTab" .. i]] = true
				end
				i = i + 1
			end
		end
--		skinTabs()

		AchievementFrameHeaderTitle:ClearAllPoints()
		AchievementFrameHeaderTitle:SetPoint("TOPLEFT", AchievementFrame, "TOPLEFT", -8, -4)

		AchievementFrameHeaderPoints:ClearAllPoints()
		AchievementFrameHeaderPoints:SetPoint("LEFT", AchievementFrameHeaderTitle, "RIGHT", 8, 0)

		AchievementFrameFilterDropDown:ClearAllPoints()
		AchievementFrameFilterDropDown:SetPoint("TOPRIGHT", AchievementFrame, "TOPRIGHT", -40, 5)
	
		AchievementFrameComparisonHeaderName:ClearAllPoints()
		AchievementFrameComparisonHeaderName:SetPoint("TOPRIGHT", AchievementFrame, "TOPRIGHT", -56, -4)
		AchievementFrameComparisonHeaderName:SetJustifyH("RIGHT")

		AchievementFrameComparisonHeaderPoints:ClearAllPoints()
		AchievementFrameComparisonHeaderPoints:SetPoint("RIGHT", AchievementFrameComparisonHeaderName, "LEFT", -8, 0)		

		AchievementFrameComparisonHeaderPortrait:Hide()
		AchievementFrameComparisonHeaderPortrait.Show = noop
		
		AchievementFrameComparisonStatsContainer:SetPoint("TOPLEFT", 4, -6)

		for i = 1, 7 do
			local frame = _G["AchievementFrameAchievementsContainerButton" .. i]

			local background = _G[frame:GetName() .. "Background"]
			local description = _G[frame:GetName() .. "Description"]
			local glow = _G[frame:GetName() .. "Glow"]
			local hiddendescription = _G[frame:GetName() .. "HiddenDescription"]
			local highlight = _G[frame:GetName() .. "Highlight"]
			local icon = _G[frame:GetName() .. "Icon"]
			local iconbling = _G[icon:GetName() .. "Bling"]
			local iconoverlay = _G[icon:GetName() .. "Overlay"]
			local icontexture = _G[icon:GetName() .. "Texture"]
			local tracked = _G[frame:GetName() .. "Tracked"]
			local tsunami1 = _G[frame:GetName() .. "BottomLeftTsunami"]
			local tsunami2 = _G[frame:GetName() .. "BottomRightTsunami"]
			local tsunami3 = _G[frame:GetName() .. "BottomTsunami1"]
			local tsunami4 = _G[frame:GetName() .. "TopLeftTsunami"]
			local tsunami5 = _G[frame:GetName() .. "TopRightTsunami"]
			local tsunami6 = _G[frame:GetName() .. "TopTsunami1"]
			local titlebackground = _G[frame:GetName() .. "TitleBackground"]
			local plusminus = _G[frame:GetName() .. "PlusMinus"]
			local rewardbackground = _G[frame:GetName() .. "RewardBackground"]
			
			if (background) then gUI:KillObject(background) end
			if (titlebackground) then gUI:KillObject(titlebackground) end
			if (glow) then gUI:KillObject(glow) end
			if (highlight) then gUI:DisableTextures(highlight) end
			if (iconbling) then gUI:KillObject(iconbling) end
			if (iconoverlay) then gUI:KillObject(iconoverlay) end
			if (tsunami1) then gUI:KillObject(tsunami1) end
			if (tsunami2) then gUI:KillObject(tsunami2) end
			if (tsunami3) then gUI:KillObject(tsunami3) end
			if (tsunami4) then gUI:KillObject(tsunami4) end
			if (tsunami5) then gUI:KillObject(tsunami5) end
			if (tsunami6) then gUI:KillObject(tsunami6) end
			if (plusminus) then gUI:KillObject(plusminus) end
			if (rewardbackground) then gUI:KillObject(rewardbackground) end
	
			if (tracked) then 
				tracked:Hide()
				tracked.Show = noop
			end

			gUI:SetUITemplate(frame, "insetbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
			frame.SetBackdropBorderColor = noop
			
			local highlightBorder = gUI:SetUITemplate(highlight, "targetborder")
			highlightBorder:ClearAllPoints()
			highlightBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
			highlightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
			
			highlight.overlay = highlight:CreateTexture(nil, "OVERLAY")
			highlight.overlay:SetPoint("TOPLEFT", highlightBorder, "TOPLEFT", 0, 0)
			highlight.overlay:SetPoint("BOTTOMRIGHT", highlightBorder, "BOTTOMRIGHT", 0, 0)
			highlight.overlay:SetTexture(1, 1, 1, 1/10)

			description:SetTextColor(0.6, 0.6, 0.6)
			description.SetTextColor = noop
			
			hiddendescription:SetTextColor(unpack(C["index"]))
			hiddendescription.SetTextColor = noop
			
			local backdrop = gUI:SetUITemplate(icon, "itembackdrop")
			icon:SetHeight(icon:GetHeight() - 4)
			icon:SetWidth(icon:GetWidth() - 4)
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT", 12, -12)
			
			icontexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icontexture:ClearAllPoints()
			icontexture:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
			icontexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
			
			icontexture:SetParent(backdrop)
			icontexture:SetDrawLayer("OVERLAY")
		end
		
		local fixComparisonFrame = function(self)
			local background = _G[self:GetName() .. "Background"]
			local description = _G[self:GetName() .. "Description"]
			local glow = _G[self:GetName() .. "Glow"]
			local hiddendescription = _G[self:GetName() .. "HiddenDescription"]
			local highlight = _G[self:GetName() .. "Highlight"]
			local icon = _G[self:GetName() .. "Icon"]
			local iconbling = _G[icon:GetName() .. "Bling"]
			local iconoverlay = _G[icon:GetName() .. "Overlay"]
			local icontexture = _G[icon:GetName() .. "Texture"]
			local shield = _G[self:GetName() .. "Shield"]
			local tracked = _G[self:GetName() .. "Tracked"]
			local tsunami1 = _G[self:GetName() .. "BottomLeftTsunami"]
			local tsunami2 = _G[self:GetName() .. "BottomRightTsunami"]
			local tsunami3 = _G[self:GetName() .. "BottomTsunami1"]
			local tsunami4 = _G[self:GetName() .. "TopLeftTsunami"]
			local tsunami5 = _G[self:GetName() .. "TopRightTsunami"]
			local tsunami6 = _G[self:GetName() .. "TopTsunami1"]
			local titlebackground = _G[self:GetName() .. "TitleBackground"]
			local plusminus = _G[self:GetName() .. "PlusMinus"]
			local rewardbackground = _G[self:GetName() .. "RewardBackground"]

			if (background) then gUI:KillObject(background) end
			if (titlebackground) then gUI:KillObject(titlebackground) end
			if (glow) then gUI:KillObject(glow) end
			if (highlight) then gUI:DisableTextures(highlight) end
			if (iconbling) then gUI:KillObject(iconbling) end
			if (iconoverlay) then gUI:KillObject(iconoverlay) end
			if (tsunami1) then gUI:KillObject(tsunami1) end
			if (tsunami2) then gUI:KillObject(tsunami2) end
			if (tsunami3) then gUI:KillObject(tsunami3) end
			if (tsunami4) then gUI:KillObject(tsunami4) end
			if (tsunami5) then gUI:KillObject(tsunami5) end
			if (tsunami6) then gUI:KillObject(tsunami6) end
			if (plusminus) then gUI:KillObject(plusminus) end
			if (rewardbackground) then gUI:KillObject(rewardbackground) end

			if (tracked) then 
				tracked:Hide()
				tracked.Show = noop
			end
			
			gUI:SetUITemplate(self, "insetbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
			self.SetBackdropBorderColor = noop
			
			if (description) then
				description:SetTextColor(0.6, 0.6, 0.6)
				description.SetTextColor = noop
			end
			
			local backdrop = gUI:SetUITemplate(icon, "itembackdrop")
			icon:SetHeight(icon:GetHeight() - 16)
			icon:SetWidth(icon:GetWidth() - 16)
			icon:ClearAllPoints()
			icon:SetPoint("LEFT", 8, 0)
			
			icontexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icontexture:ClearAllPoints()
			icontexture:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
			icontexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
			
			icontexture:SetParent(backdrop)
			icontexture:SetDrawLayer("OVERLAY")	

		end
		
		for i = 1, 9 do
			fixComparisonFrame(_G["AchievementFrameComparisonContainerButton" .. i .. "Player"])
			fixComparisonFrame(_G["AchievementFrameComparisonContainerButton" .. i .. "Friend"])
		end
		
		local updateCategoryList
		do
			local once
			updateCategoryList = function()
				-- always check for new tabs
				-- this provides a "first glance" compability with OverAchiever
				skinTabs()
			
				for i = 1, 20 do 
					local button = _G["AchievementFrameCategoriesContainerButton" .. i]
					local background = _G["AchievementFrameCategoriesContainerButton" .. i .. "Background"]
					local label = _G["AchievementFrameCategoriesContainerButton" .. i .. "Label"]
					
					if not(once) then
						gUI:KillObject(background)
					end
					
					gUI:SetUITemplate(button, "button"):SetBackdropColor(r, g, b, panelAlpha)

--					if (label) then
--						label:SetPoint("BOTTOMLEFT", 20, 8)
--						label:SetPoint("TOPRIGHT", -12, -8)
--					end
				end

				once = true
			end
		end
		
		local updateProgressBar = function(index)
			local frame = _G["AchievementFrameProgressBar" .. index]
			if (frame) then
				if not(frame.GUIskinned) then
					gUI:SetUITemplate(frame, "statusbar", true)
					
					local a, b = frame:GetStatusBarTexture():GetDrawLayer()
					frame.background = frame:CreateTexture()
					frame.background:SetDrawLayer(a, b-1)
					frame.background:SetTexture(frame:GetStatusBarTexture():GetTexture())
					frame.background:SetVertexColor(0.1, 0.1, 0.1, 1)
					frame.background:SetAllPoints(frame)
					
					frame.text:ClearAllPoints()
					frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
					frame.text:SetJustifyH("CENTER")
					
					if (index > 1) then
						frame:ClearAllPoints()
						frame:SetPoint("TOP", _G["AchievementFrameProgressBar" .. (index - 1)], "BOTTOM", 0, -6)
						frame.SetPoint = noop
						frame.ClearAllPoints = noop
					end
					
					frame.GUIskinned = true
				end
			end
		end
		
		local updateAchievementCriteria = function(objectivesFrame, id)
			local numCriteria = GetAchievementNumCriteria(id)
			local textStrings, metas = 0, 0
			for i = 1, numCriteria do	
				local criteriaString, criteriaType, completed, quantity, reqQuantity, charName, flags, assetID, quantityString = GetAchievementCriteriaInfo(id, i)
				
				if (criteriaType == CRITERIA_TYPE_ACHIEVEMENT) and (assetID) then
					metas = metas + 1
					local metaCriteria = AchievementButton_GetMeta(metas)			
					if (objectivesFrame.completed) and (completed) then
						metaCriteria.label:SetTextColor(1, 1, 1, 1)
						
					elseif ( completed ) then
						metaCriteria.label:SetTextColor(0, 1, 0, 1)
						
					else
						metaCriteria.label:SetTextColor(.6, .6, .6, 1)
						
					end				
				elseif (criteriaType ~= 1) then
					textStrings = textStrings + 1
					local criteria = AchievementButton_GetCriteria(textStrings)			
					if (objectivesFrame.completed) and (completed) then
						criteria.name:SetTextColor(1, 1, 1, 1)

					elseif ( completed ) then
						criteria.name:SetTextColor(0, 1, 0, 1)

					else
						criteria.name:SetTextColor(.6, .6, .6, 1)
					end		
				end
			end
		end

		local updateAchievementSummary = function()
			for i = 1, ACHIEVEMENTUI_MAX_SUMMARY_ACHIEVEMENTS do
				local frame = _G["AchievementFrameSummaryAchievement" ..i]

				local background = _G[frame:GetName() .. "Background"]
				local description = _G[frame:GetName() .. "Description"]
				local glow = _G[frame:GetName() .. "Glow"]
				local highlight = _G[frame:GetName() .. "Highlight"]
				local icon = _G[frame:GetName() .. "Icon"]
				local titlebackground = _G[frame:GetName() .. "TitleBackground"]
				
				if (background) then gUI:KillObject(background) end
				if (glow) then gUI:KillObject(glow) end
				if (titlebackground) then gUI:KillObject(titlebackground) end
				if (highlight) then gUI:RemoveClutter(highlight) end
				
				if (highlight) then
					local highlightBorder = gUI:SetUITemplate(highlight, "targetborder")
					highlightBorder:ClearAllPoints()
					highlightBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
					highlightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 2)
					
					if not(highlight.overlay) then
						highlight.overlay = highlight:CreateTexture(nil, "OVERLAY")
						highlight.overlay:SetPoint("TOPLEFT", highlightBorder, "TOPLEFT", 0, 0)
						highlight.overlay:SetPoint("BOTTOMRIGHT", highlightBorder, "BOTTOMRIGHT", 0, 0)
						highlight.overlay:SetTexture(1, 1, 1, 1/5)
					end
				end
				
				if (description) then
					description:SetTextColor(0.6, 0.6, 0.6)
				end

				if not(frame.GUISkinned) then
					gUI:DisableTextures(frame)
				
					frame:SetBackdrop(nil)
					frame.SetBackdrop = nil
					
					frame.backdrop = gUI:SetUITemplate(frame, "outerbackdrop")
					frame.backdrop:SetBackdropColor(r, g, b, panelAlpha)
					frame.backdrop:SetPoint("TOPLEFT", 0, -2)
					frame.backdrop:SetPoint("BOTTOMRIGHT", 0, 2)
					
					if (icon) then
						gUI:SetUITemplate(icon, "itembackdrop")
						local bling = _G[icon:GetName() .. "Bling"]
						local overlay = _G[icon:GetName() .. "Overlay"]
						
						if (bling) then gUI:KillObject(bling) end
						if (overlay) then gUI:KillObject(overlay) end
					
						icon:SetHeight(icon:GetHeight() - 16)
						icon:SetWidth(icon:GetWidth() - 16)
						icon:ClearAllPoints()
						icon:SetPoint("LEFT", 6, 0)

						_G[icon:GetName() .. "Texture"]:SetTexCoord(5/64, 59/64, 5/64, 59/64)
						_G[icon:GetName() .. "Texture"]:ClearAllPoints()
						_G[icon:GetName() .. "Texture"]:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
						_G[icon:GetName() .. "Texture"]:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
					end
					
					frame.GUISkinned = true
				end
			end
		end
		
		-- this is compatible with OverAchiever
		hooksecurefunc("AchievementFrame_OnShow", updateCategoryList) 
		AchievementFrame:HookScript("OnShow", updateCategoryList) 
		
		hooksecurefunc("AchievementObjectives_DisplayCriteria", updateAchievementCriteria)
		hooksecurefunc("AchievementFrameSummary_UpdateAchievements", updateAchievementSummary)
		hooksecurefunc("AchievementButton_GetProgressBar", updateProgressBar)
		
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end