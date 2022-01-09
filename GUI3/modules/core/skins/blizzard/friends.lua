--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Friends")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Friends"])
	self:SetAttribute("description", L["The friends frame"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(AddFriendNoteFrame)
		gUI:DisableTextures(ChannelFrameDaughterFrame)
		gUI:DisableTextures(ChannelListScrollFrame)
		gUI:DisableTextures(ChannelRoster)
		gUI:DisableTextures(FriendsFrame)
		gUI:DisableTextures(FriendsFrameFriendsScrollFrame)
		gUI:DisableTextures(FriendsFriendsFrame)
		gUI:DisableTextures(FriendsFriendsList)
		gUI:DisableTextures(FriendsFriendsNoteFrame)
		gUI:DisableTextures(FriendsFramePendingButton1)
		gUI:DisableTextures(FriendsFramePendingButton2)
		gUI:DisableTextures(FriendsFramePendingButton3)
		gUI:DisableTextures(FriendsFramePendingButton4)
		gUI:DisableTextures(FriendsListFrame)
		gUI:DisableTextures(FriendsTabHeader)
		gUI:DisableTextures(WhoFrameColumnHeader1)
		gUI:DisableTextures(WhoFrameColumnHeader2)
		gUI:DisableTextures(WhoFrameColumnHeader3)
		gUI:DisableTextures(WhoFrameColumnHeader4)
		gUI:HideTexture(FriendsFrameBroadcastInputMiddle)
		gUI:HideTexture(FriendsFrameBroadcastInputLeft)
		gUI:HideTexture(FriendsFrameBroadcastInputRight)
		gUI:DisableTextures(FriendsTabHeaderTab1)
		gUI:DisableTextures(FriendsTabHeaderTab2)
		gUI:DisableTextures(FriendsTabHeaderTab3)
		gUI:HideTexture(ChannelFrameDaughterFrameChannelNameMiddle)
		gUI:HideTexture(ChannelFrameDaughterFrameChannelNameLeft)
		gUI:HideTexture(ChannelFrameDaughterFrameChannelNameRight)
		gUI:HideTexture(ChannelFrameDaughterFrameChannelPasswordMiddle)
		gUI:HideTexture(ChannelFrameDaughterFrameChannelPasswordLeft)
		gUI:HideTexture(ChannelFrameDaughterFrameChannelPasswordRight)
		gUI:DisableTextures(PendingListFrame)
		gUI:DisableTextures(IgnoreListFrame)
		gUI:DisableTextures(FriendsFrameBattlenetFrame)
		
		gUI:KillObject(FriendsFramePortrait)
		gUI:KillObject(FriendsFrameIcon)
		
		-- gUI:HideTexture(FriendsFrameBottomLeft)
		-- gUI:HideTexture(FriendsFrameBottomRight)
		-- gUI:HideTexture(FriendsFrameTopLeft)
		-- gUI:HideTexture(FriendsFrameTopRight)
		gUI:DisableTextures(FriendsFrameInset)
		gUI:DisableTextures(WhoFrameListInset)
		-- gUI:DisableTextures(ChannelFrameVerticalBar)

		gUI:SetUITemplate(AddFriendFrame, "outerbackdrop")
		gUI:SetUITemplate(ChannelFrameDaughterFrame, "outerbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(ChannelFrameDaughterFrameChannelName, "outerbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(ChannelFrameDaughterFrameChannelPassword, "outerbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
		
		gUI:SetUITemplate(WhoListScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(FriendsFrameFriendsScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(FriendsFrameIgnoreScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(FriendsFramePendingScrollFrameScrollBar, "scrollbar")
		
		gUI:DisableTextures(WhoFrameEditBoxInset)
		gUI:DisableTextures(ChannelFrameLeftInset)
		gUI:DisableTextures(ChannelFrameRightInset)
		
		gUI:SetUITemplate(WhoFrameListInset, "outerbackdrop", nil, 4, 3, 6, 3):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(FriendsFrame, "outerbackdrop", nil, -8, -6, 0, -6)
		
		WhoListScrollFrameScrollBar:ClearAllPoints()
		WhoListScrollFrameScrollBar:SetPoint("TOPRIGHT", WhoFrameListInset, -4, -19)
		WhoListScrollFrameScrollBar:SetPoint("BOTTOMRIGHT", WhoFrameListInset, -4, 19)

		FriendsFrameIgnoreScrollFrameScrollBar:ClearAllPoints()
		FriendsFrameIgnoreScrollFrameScrollBar:SetPoint("TOPRIGHT", FriendsFrameInset, -4, -19)
		FriendsFrameIgnoreScrollFrameScrollBar:SetPoint("BOTTOMRIGHT", FriendsFrameInset, -4, 19)

		FriendsFramePendingScrollFrameScrollBar:ClearAllPoints()
		FriendsFramePendingScrollFrameScrollBar:SetPoint("TOPRIGHT", FriendsFrameInset, -4, -19)
		FriendsFramePendingScrollFrameScrollBar:SetPoint("BOTTOMRIGHT", FriendsFrameInset, -4, 19)

		
		-- ress icon
		FriendsTabHeaderSoRButtonIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		FriendsTabHeaderSoRButtonIcon:ClearAllPoints()
		FriendsTabHeaderSoRButtonIcon:SetPoint("TOPLEFT", 3, -3)
		FriendsTabHeaderSoRButtonIcon:SetPoint("BOTTOMRIGHT", -3, 3)
		gUI:SetUITemplate(FriendsTabHeaderSoRButton, "simpleborder")
		FriendsTabHeaderSoRButton:GetHighlightTexture():SetTexCoord(5/64, 59/64, 5/64, 59/64)
		FriendsTabHeaderSoRButton:GetHighlightTexture():SetTexture(1, 1, 1, 1/2)
		FriendsTabHeaderSoRButton:GetHighlightTexture():SetAllPoints(FriendsTabHeaderSoRButtonIcon)
		FriendsTabHeaderSoRButton:GetPushedTexture():SetTexCoord(5/64, 59/64, 5/64, 59/64)
		FriendsTabHeaderSoRButton:GetPushedTexture():SetTexture(1, 0.82, 0, 1/2)
		FriendsTabHeaderSoRButton:GetPushedTexture():SetAllPoints(FriendsTabHeaderSoRButtonIcon)
	
		gUI:SetUITemplate(FriendsTabHeaderSoRButton, "gloss", FriendsTabHeaderSoRButtonIcon)
		gUI:SetUITemplate(FriendsTabHeaderSoRButton, "shade", FriendsTabHeaderSoRButtonIcon)
	
		-- ress selection frame
		gUI:DisableTextures(ScrollOfResurrectionSelectionFrame)
		gUI:SetUITemplate(ScrollOfResurrectionSelectionFrame, "backdrop")
		gUI:SetUITemplate(ScrollOfResurrectionSelectionFrameList, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(ScrollOfResurrectionSelectionFrameListScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(ScrollOfResurrectionSelectionFrameAcceptButton, "button", true)
		gUI:SetUITemplate(ScrollOfResurrectionSelectionFrameCancelButton, "button", true)
		gUI:SetUITemplate(ScrollOfResurrectionSelectionFrameTargetEditBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)

		-- ress frame
		gUI:DisableTextures(ScrollOfResurrectionFrame)
		gUI:SetUITemplate(ScrollOfResurrectionFrame, "backdrop")
		gUI:SetUITemplate(ScrollOfResurrectionFrameNoteFrame, "backdrop")
		gUI:SetUITemplate(ScrollOfResurrectionFrameAcceptButton, "button", true)
		gUI:SetUITemplate(ScrollOfResurrectionFrameCancelButton, "button", true)


		gUI:SetUITemplate(FriendsFriendsFrame, "outerbackdrop")
		gUI:SetUITemplate(FriendsFrameFriendsScrollFrame, "outerbackdrop", nil, -1, 0, 0, 3):SetBackdropColor(r, g, b, panelAlpha)

		gUI:SetUITemplate(WhoFrameDropDown, "dropdown", true, 120)
		WhoFrameDropDown:SetPoint("TOPLEFT", -15, 4)
		
		gUI:DisableTextures(FriendsFrameStatusDropDown, FriendsFrameStatusDropDownStatus, FriendsFrameStatusDropDownIcon)
		gUI:SetUITemplate(FriendsFrameStatusDropDown, "dropdown", 72)

		FriendsFrameBattlenetFrame.BroadcastButton:SetSize(26, 26)
		
		gUI:DisableTextures(FriendsFrameBattlenetFrame.BroadcastFrame.ScrollFrame)
		gUI:SetUITemplate(FriendsFrameBattlenetFrame.BroadcastFrame, "backdrop")
		gUI:SetUITemplate(FriendsFrameBattlenetFrame.BroadcastFrame.ScrollFrame, "outerbackdrop", -1, 0, -3, 0)
		gUI:SetUITemplate(FriendsFrameBattlenetFrame.BroadcastFrame.ScrollFrame.CancelButton, "button", true)
		gUI:SetUITemplate(FriendsFrameBattlenetFrame.BroadcastFrame.ScrollFrame.UpdateButton, "button", true)
		
		gUI:SetUITemplate(AddFriendNameEditBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(FriendsFrameBroadcastInput, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(WhoFrameEditBox, "editbox", -8, -3, 8, 23):SetBackdropColor(r, g, b, panelAlpha)
		
		for i,v in pairs(FriendsFrameFriendsScrollFrame.buttons) do
			-- gUI:DisableTextures(v) -- not needed, and it hides the game icon
			gUI:CreateHighlight(v)
			gUI:CreatePushed(v)
			
			if (v.gameIcon) then
				v.gameIcon:SetDrawLayer("OVERLAY")
			end
			
			if (v.name) then
				v.name:SetDrawLayer("OVERLAY")
			end

			if (v.compactInfo) then
				v.compactInfo:SetDrawLayer("OVERLAY")
			end

			if (v.info) then
				v.info:SetDrawLayer("OVERLAY")
			end

			if (v.broadcastMessage) then
				v.broadcastMessage:SetDrawLayer("OVERLAY")
			end
			
			if (v.travelPassButton) then
			end

			if (v.summonButton) then
	--			F.StyleActionButton(v.summonButton)
			end

			if (v.soRButton) then
			end
		end

		gUI:SetUITemplate(AddFriendEntryFrameAcceptButton, "button", true)
		gUI:SetUITemplate(AddFriendEntryFrameCancelButton, "button", true)
		gUI:SetUITemplate(AddFriendInfoFrameContinueButton, "button", true)
		gUI:SetUITemplate(ChannelFrameDaughterFrameCancelButton, "button", true)
		gUI:SetUITemplate(ChannelFrameDaughterFrameOkayButton, "button", true)
		gUI:SetUITemplate(ChannelFrameNewButton, "button", true)
		gUI:SetUITemplate(FriendsFrameAddFriendButton, "button", true)
		gUI:SetUITemplate(FriendsFrameSendMessageButton, "button", true)
		gUI:SetUITemplate(FriendsFrameIgnorePlayerButton, "button", true)
		gUI:SetUITemplate(FriendsFramePendingButton1AcceptButton, "button", true)
		gUI:SetUITemplate(FriendsFramePendingButton1DeclineButton, "button", true)
		gUI:SetUITemplate(FriendsFramePendingButton2AcceptButton, "button", true)
		gUI:SetUITemplate(FriendsFramePendingButton2DeclineButton, "button", true)
		gUI:SetUITemplate(FriendsFramePendingButton3AcceptButton, "button", true)
		gUI:SetUITemplate(FriendsFramePendingButton3DeclineButton, "button", true)
		gUI:SetUITemplate(FriendsFramePendingButton4AcceptButton, "button", true)
		gUI:SetUITemplate(FriendsFramePendingButton4DeclineButton, "button", true)
		gUI:SetUITemplate(FriendsFrameUnsquelchButton, "button", true)
		gUI:SetUITemplate(FriendsFriendsSendRequestButton, "button", true)
		gUI:SetUITemplate(WhoFrameAddFriendButton, "button", true)
		gUI:SetUITemplate(WhoFrameGroupInviteButton, "button", true)
		gUI:SetUITemplate(WhoFrameWhoButton, "button", true)
		
		gUI:SetUITemplate(FriendsFriendsCloseButton, "button", true) -- changed this from 'closebutton'

		gUI:SetUITemplate(ChannelFrameDaughterFrameDetailCloseButton, "closebutton")
		gUI:SetUITemplate(FriendsFrameCloseButton, "closebutton")

		gUI:SetUITemplate(FriendsFrameTab1, "tab")
		gUI:SetUITemplate(FriendsFrameTab2, "tab")
		gUI:SetUITemplate(FriendsFrameTab3, "tab")
		gUI:SetUITemplate(FriendsFrameTab4, "tab")
		
		gUI:SetUITemplate(FriendsFriendsFrameDropDown, "dropdown", true)
		gUI:SetUITemplate(FriendsFriendsScrollFrameScrollBar, "scrollbar")

		local StripChannelList = function()
			for i=1, MAX_DISPLAY_CHANNEL_BUTTONS do
				local button = _G["ChannelButton"..i]
				if (button) then
					gUI:DisableTextures(button)
					button:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
				end
			end
		end
		
		local StripChannelRoster = function()
			gUI:DisableTextures(ChannelRosterScrollFrame) 
		end

		local StripWhoList = function()
			gUI:DisableTextures(WhoListScrollFrame) 
		end

		ChannelFrame:HookScript("OnShow", function(self) gUI:DisableTextures(self) end)
		WhoFrame:HookScript("OnShow", function(self) gUI:DisableTextures(self) end)

		hooksecurefunc("ChannelList_Update", StripChannelList)
		hooksecurefunc("FriendsFrame_OnEvent", StripChannelRoster)
		hooksecurefunc("FriendsFrame_OnEvent", StripWhoList)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end