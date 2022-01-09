--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_GuildUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Guild UI"])
	self:SetAttribute("description", L["The main guild interface"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		-- gUI:SetUITemplate(GuildFramePromoteButton, "arrow", "up")
		-- gUI:SetUITemplate(GuildFrameDemoteButton, "arrow", "down")
		gUI:DisableTextures(GuildInfoFrame)
		
		gUI:DisableTextures(GuildNewPerksFrame)
		gUI:DisableTextures(GuildFrameInset)
		gUI:DisableTextures(GuildFrameBottomInset)
		gUI:DisableTextures(GuildAllPerksFrame)
		gUI:DisableTextures(GuildMemberDetailFrame)
		gUI:DisableTextures(GuildMemberNoteBackground)
		gUI:DisableTextures(GuildLogContainer)
		gUI:DisableTextures(GuildLogFrame)
		gUI:DisableTextures(GuildRewardsFrame)
		gUI:DisableTextures(GuildMemberOfficerNoteBackground)
		gUI:DisableTextures(GuildTextEditContainer)
		gUI:DisableTextures(GuildTextEditFrame)
		gUI:DisableTextures(GuildRecruitmentRolesFrame)
		gUI:DisableTextures(GuildRecruitmentAvailabilityFrame)
		gUI:DisableTextures(GuildRecruitmentInterestFrame)
		gUI:DisableTextures(GuildRecruitmentLevelFrame)
		gUI:DisableTextures(GuildRecruitmentCommentFrame)
		gUI:DisableTextures(GuildRecruitmentCommentInputFrame) 
		gUI:DisableTextures(GuildInfoFrameApplicantsContainer)
		gUI:DisableTextures(GuildInfoFrameApplicants)
		gUI:DisableTextures(GuildNewsBossModel)
		gUI:DisableTextures(GuildNewsBossModelTextFrame)
		gUI:HideTexture(GuildXPBarLeft)
		gUI:HideTexture(GuildXPBarRight)
		gUI:HideTexture(GuildXPBarMiddle)
		gUI:HideTexture(GuildXPBarBG)
		gUI:HideTexture(GuildXPBarShadow)
		gUI:HideTexture(GuildXPBarDivider1)
		gUI:HideTexture(GuildXPBarDivider2)
		gUI:HideTexture(GuildXPBarDivider3)
		gUI:HideTexture(GuildXPBarDivider4)
		gUI:DisableTextures(GuildLevelFrame)
		gUI:HideTexture(GuildFactionBarLeft)
		gUI:HideTexture(GuildFactionBarRight)
		gUI:HideTexture(GuildFactionBarMiddle)
		gUI:HideTexture(GuildFactionBarBG)
		gUI:HideTexture(GuildFactionBarShadow)
		gUI:DisableTextures(GuildLatestPerkButton, GuildLatestPerkButton.icon)
		gUI:DisableTextures(GuildNextPerkButton, GuildNextPerkButton.icon)
		gUI:DisableTextures(GuildRosterColumnButton1)
		gUI:DisableTextures(GuildRosterColumnButton2)
		gUI:DisableTextures(GuildRosterColumnButton3)
		gUI:DisableTextures(GuildRosterColumnButton4)
		gUI:DisableTextures(GuildInfoFrameTab1)
		gUI:DisableTextures(GuildInfoFrameTab2) 
		gUI:DisableTextures(GuildInfoFrameTab3) 
		gUI:DisableTextures(GuildFrame)
		gUI:DisableTextures(GuildNewsFrame)
		gUI:DisableTextures(GuildNewsFiltersFrame)
		gUI:DisableTextures(GuildInfoFrameInfo)
		
		gUI:KillObject(GuildFrameTabardEmblem)
	
		gUI:SetUITemplate(GuildPerksToggleButton, "button", true)
		gUI:SetUITemplate(GuildMemberRemoveButton, "button", true)
		gUI:SetUITemplate(GuildMemberGroupInviteButton, "button", true)
		gUI:SetUITemplate(GuildAddMemberButton, "button", true)
		gUI:SetUITemplate(GuildViewLogButton, "button", true)
		gUI:SetUITemplate(GuildControlButton, "button", true)
		gUI:SetUITemplate(GuildTextEditFrameAcceptButton, "button", true)
		gUI:SetUITemplate(GuildRecruitmentListGuildButton, "button", true)
		gUI:SetUITemplate(GuildRecruitmentInviteButton, "button", true)
		gUI:SetUITemplate(GuildRecruitmentMessageButton, "button", true)
		gUI:SetUITemplate(GuildRecruitmentDeclineButton, "button", true)
		gUI:SetUITemplate(GuildRecruitmentQuestButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentDungeonButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentRaidButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentPvPButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentRPButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentWeekdaysButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentWeekendsButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentHealerButton.checkButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentTankButton.checkButton, "checkbutton")
		gUI:SetUITemplate(GuildRecruitmentDamagerButton.checkButton, "checkbutton")
		gUI:SetUITemplate(GuildRosterShowOfflineButton, "checkbutton")

		for i = 1,7 do gUI:SetUITemplate(_G["GuildNewsFilterButton" .. i], "checkbutton") end

		gUI:SetUITemplate(GuildRecruitmentLevelAnyButton, "radiobutton", true)
		gUI:SetUITemplate(GuildRecruitmentLevelMaxButton, "radiobutton", true)
	
		gUI:SetUITemplate(GuildMemberDetailCloseButton, "closebutton")
		gUI:SetUITemplate(GuildNewsFiltersFrameCloseButton, "closebutton")
		gUI:SetUITemplate(GuildFrameCloseButton, "closebutton")

		gUI:SetUITemplate(GuildMemberRankDropdown, "dropdown", true)
		gUI:SetUITemplate(GuildRosterViewDropdown, "dropdown", true)
		
		gUI:SetUITemplate(GuildFrame, "backdrop")
		gUI:SetUITemplate(GuildLogFrame, "backdrop")
		gUI:SetUITemplate(GuildNewsBossModel, "backdrop")
		gUI:SetUITemplate(GuildNewsFiltersFrame, "backdrop")
		gUI:SetUITemplate(GuildTextEditFrame, "backdrop")
		gUI:SetUITemplate(GuildMemberDetailFrame, "backdrop")
		gUI:SetUITemplate(GuildRecruitmentInterestFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildRecruitmentLevelFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildRecruitmentCommentFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildRecruitmentAvailabilityFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildRecruitmentRolesFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildMemberNoteBackground, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildMemberOfficerNoteBackground, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildTextEditContainer, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)

		gUI:SetUITemplate(GuildLogScrollFrame, "outerbackdrop", nil, -2, -3, -2, 0):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildInfoFrameInfoMOTDScrollFrame, "outerbackdrop", nil, -1, -3, -3, 0):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildInfoDetailsFrame, "outerbackdrop", nil, -1, -3, -3, 0):SetBackdropColor(r, g, b, panelAlpha)

		gUI:SetUITemplate(GuildInfoFrameInfoMOTDScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildPerksContainerScrollBar, "scrollbar")	
		gUI:SetUITemplate(GuildRosterContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildNewsContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildInfoDetailsFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildTextEditScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildLogScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildRewardsContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(GuildInfoFrameApplicantsContainerScrollBar, "scrollbar")
		
		gUI:SetUITemplate(GuildFrameTab1, "tab", true)
		gUI:SetUITemplate(GuildFrameTab2, "tab", true)
		gUI:SetUITemplate(GuildFrameTab3, "tab", true)
		gUI:SetUITemplate(GuildFrameTab4, "tab", true)
		gUI:SetUITemplate(GuildFrameTab5, "tab", true)
		
		--gUI:KillObject(GuildMemberRankDropdownText) -- why did I do this...?
		
		--------------------------------------------------------------------------------------------------
		--		Guild Level TODO: fix this stuff, make it update
		--------------------------------------------------------------------------------------------------		
		gUI:KillObject(GuildLevelFrame)
		
		--------------------------------------------------------------------------------------------------
		--		Guild XP Bar
		--------------------------------------------------------------------------------------------------		
		GuildXPFrame:ClearAllPoints()
		GuildXPFrame:SetPoint("TOP", GuildFrame, "TOP", 0, -40)
		
		GuildXPBar:SetPoint("TOP", 0, -50)
		GuildXPBar:SetHeight(14)

		GuildXPBar.progress:SetTexture(gUI:GetStatusBarTexture())
		GuildXPBar.progress:SetPoint("LEFT", GuildXPBar, "LEFT", 0, 0)
		GuildXPBar.progress:SetPoint("TOP", GuildXPBar, "TOP", 0, 0)
		GuildXPBar.progress:SetPoint("BOTTOM", GuildXPBar, "BOTTOM", 0, 0)

		GuildXPBar.cap:SetTexture(gUI:GetStatusBarTexture())
		GuildXPBar.cap:SetPoint("TOP", GuildXPBar, "TOP", 0, 0)
		GuildXPBar.cap:SetPoint("BOTTOM", GuildXPBar, "BOTTOM", 0, 0)

		GuildXPBarText:SetFontObject(gUI_DisplayFontSmallWhite)
		GuildXPBarText:ClearAllPoints()
		GuildXPBarText:SetPoint("CENTER")
		
		GuildXPFrameLevelText:SetPoint("BOTTOM", GuildXPBar, "TOP", 0, 4)
		GuildXPFrameLevelText:SetFontObject(gUI_TextFontTinyWhite)

		gUI:HideTexture(GuildXPBarCapMarker)
	
		GuildXPBar.backdrop = gUI:SetUITemplate(GuildXPBar, "border")
		GuildXPBar.eyeCandy = CreateFrame("Frame", nil, GuildXPBar.backdrop)
		GuildXPBar.eyeCandy:SetPoint("TOPLEFT", GuildXPBar.backdrop, "TOPLEFT", 3, -3)
		GuildXPBar.eyeCandy:SetPoint("BOTTOMRIGHT", GuildXPBar.backdrop, "BOTTOMRIGHT", -3, 3)
		gUI:SetUITemplate(GuildXPBar.eyeCandy, "gloss")
		
		--------------------------------------------------------------------------------------------------
		--		Guild Faction Bar
		--------------------------------------------------------------------------------------------------		
		GuildFactionBar:SetHeight(12)
		GuildFactionBar:SetPoint("TOPLEFT", -1, -5)
		GuildFactionBar.progress:SetTexture(gUI:GetStatusBarTexture())
		GuildFactionBar.progress:SetPoint("LEFT", GuildFactionBar, "LEFT", 0, 0)
		GuildFactionBar.progress:SetPoint("TOP", GuildFactionBar, "TOP", 0, 0)
		GuildFactionBar.progress:SetPoint("BOTTOM", GuildFactionBar, "BOTTOM", 0, 0)
		GuildFactionBar.cap:SetTexture(gUI:GetStatusBarTexture())
		GuildFactionBar.cap:SetPoint("TOP", GuildFactionBar, "TOP", 0, 0)
		GuildFactionBar.cap:SetPoint("BOTTOM", GuildFactionBar, "BOTTOM", 0, 0)

		gUI:HideTexture(GuildFactionBarCapMarker)

		-- they don't use the Text here, Label is used for the value instead
--		GuildFactionBarText:SetFontObject(gUI_DisplayFontSmallWhite)
--		GuildFactionBarText:ClearAllPoints()
--		GuildFactionBarText:SetPoint("CENTER")

		GuildFactionBarLabel:ClearAllPoints()
		GuildFactionBarLabel:SetPoint("CENTER")
		GuildFactionBarLabel:SetFontObject(gUI_DisplayFontExtraTinyWhite)

		GuildFactionBar.backdrop = gUI:SetUITemplate(GuildFactionBar, "border")
		GuildFactionBar.eyeCandy = CreateFrame("Frame", nil, GuildFactionBar.backdrop)
		GuildFactionBar.eyeCandy:SetPoint("TOPLEFT", GuildFactionBar.backdrop, "TOPLEFT", 3, -3)
		GuildFactionBar.eyeCandy:SetPoint("BOTTOMRIGHT", GuildFactionBar.backdrop, "BOTTOMRIGHT", -3, 3)
		gUI:SetUITemplate(GuildFactionBar.eyeCandy, "gloss")

		--------------------------------------------------------------------------------------------------
		--		Guild Perks
		--------------------------------------------------------------------------------------------------		
		GuildLatestPerkButtonIconTexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		GuildLatestPerkButtonIconTexture:ClearAllPoints()
		GuildLatestPerkButtonIconTexture:SetPoint("TOPLEFT", 3, -3)
		
		GuildLatestPerkButton.backdrop = gUI:SetUITemplate(GuildLatestPerkButton, "border")
		GuildLatestPerkButton.backdrop:ClearAllPoints()
		GuildLatestPerkButton.backdrop:SetPoint("TOPLEFT", GuildLatestPerkButtonIconTexture, "TOPLEFT", -3, 3)
		GuildLatestPerkButton.backdrop:SetPoint("BOTTOMRIGHT", GuildLatestPerkButtonIconTexture, "BOTTOMRIGHT", 3, -3)

		GuildNextPerkButtonIconTexture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		GuildNextPerkButtonIconTexture:ClearAllPoints()
		GuildNextPerkButtonIconTexture:SetPoint("TOPLEFT", 3, -3)
		
		GuildNextPerkButton.backdrop = gUI:SetUITemplate(GuildNextPerkButton, "border")
		GuildNextPerkButton.backdrop:ClearAllPoints()
		GuildNextPerkButton.backdrop:SetPoint("TOPLEFT", GuildNextPerkButtonIconTexture, "TOPLEFT", -3, 3)
		GuildNextPerkButton.backdrop:SetPoint("BOTTOMRIGHT", GuildNextPerkButtonIconTexture, "BOTTOMRIGHT", 3, -3)
		
		local makeHighlight = function(name, i, addSelectTexture)
			local button = _G[name .. i]
			
			button:SetBackdrop(nil)
			button.SetBackdrop = noop
			
			gUI:CreateHighlight(button)
			gUI:CreatePushed(button)

			-- can it get any worse?
			local selected = button:GetRegions()
			if (addSelectTexture) and  (selected) and (selected.GetObjectType) and (selected:GetObjectType() == "Texture") then
				selected:SetTexture(C["value"][1], C["value"][2], C["value"][3], 1/4)
			end
		end
		
--		for i = 1, 5 do
--			makeHighlight("LookingForGuildBrowseFrameContainerButton", i, true)
--			makeHighlight("LookingForGuildAppsFrameContainerButton", i)
--		end

		local SkinNewButtons = function()
			for _, button in next, GuildInfoFrameApplicantsContainer.buttons do
			end
		end

		for i = 1, 8 do
			local button = _G["GuildRewardsContainerButton" .. i]
			gUI:DisableTextures(button, button.icon)

			if (button.icon) then
				button.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
				button.icon:ClearAllPoints()
				button.icon:SetPoint("TOPLEFT", 6, -6)
				button.icon:SetSize(button:GetHeight() - 10, button:GetHeight() - 10)
				
				button.backdrop = gUI:SetUITemplate(button, "outerbackdrop")
				button.backdrop:SetPoint("TOPLEFT", button.icon, "TOPLEFT", -3, 3)
				button.backdrop:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 3, -3)

				button.icon:SetParent(button.backdrop)
			end
		end

		for i = 1, 8 do
			local button = _G["GuildPerksContainerButton" .. i]
			gUI:DisableTextures(button, button.icon)
		
			if (button.icon) then
				button.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
				button.icon:ClearAllPoints()
				button.icon:SetPoint("TOPLEFT", 8, -8)
				button.icon:SetSize(button:GetHeight() - 16, button:GetHeight() - 16)
				
				button.backdrop = gUI:SetUITemplate(button, "outerbackdrop")
				button.backdrop:SetPoint("TOPLEFT", button.icon, "TOPLEFT", -3, 3)
				button.backdrop:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 3, -3)

				button.icon:SetParent(button.backdrop)
			end
		end
		
		for i,button in pairs(GuildNewsContainer.buttons) do
			gUI:DisableTextures(button)
		end
		
		for i,button in pairs(GuildRosterContainer.buttons) do
			local header = _G[button:GetName() .. "HeaderButton"]
			local a, b, c = header:GetRegions()
			a:SetAlpha(0)
			b:SetAlpha(0)
			c:SetAlpha(0)
			
			gUI:SetUITemplate(header, "button"):SetBackdropColor(r, g, b, 1)
		end

		for i = 1, GuildTextEditFrame:GetNumChildren() do
			local child = select(i, GuildTextEditFrame:GetChildren())
			local point = select(1, child:GetPoint())
			if (child:GetName()) and (child:GetName():find("CloseButton")) then
				if (point == "TOPRIGHT") then
					gUI:SetUITemplate(child, "closebutton")
				else
					gUI:SetUITemplate(child, "button", true)
				end
			end
		end	
		
		for i = 1, GuildLogFrame:GetNumChildren() do
			local child = select(i, GuildLogFrame:GetChildren())
			local point = select(1, child:GetPoint())
			if (child:GetName()) and (child:GetName():find("CloseButton")) then
				if (point == "TOPRIGHT") then
					gUI:SetUITemplate(child, "closebutton")
				else
					gUI:SetUITemplate(child, "button", true)
				end
			end
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end