--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Mailbox")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Mailbox"])
	self:SetAttribute("description", L["Your Mail Inbox and Send Mail windows."])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(MailFrame)
		gUI:DisableTextures(InboxFrame)
		gUI:DisableTextures(OpenMailFrame)
		gUI:DisableTextures(SendMailFrame)
		gUI:DisableTextures(OpenMailInvoiceFrame)
		gUI:DisableTextures(OpenMailScrollFrame)
		gUI:DisableTextures(SendMailScrollFrame)
		-- gUI:DisableTextures(OpenMailLetterButton)
		-- gUI:DisableTextures(OpenMailMoneyButton)
		-- gUI:DisableTextures(OpenMailDeleteButton)
		-- gUI:DisableTextures(OpenMailCancelButton)
		-- gUI:DisableTextures(OpenMailReplyButton)
		-- gUI:DisableTextures(OpenMailReportSpamButton)
		-- gUI:DisableTextures(SendMailMailButton)
		-- gUI:DisableTextures(SendMailCancelButton)

		gUI:KillObject(OpenMailArithmeticLine)
		gUI:KillObject(OpenStationeryBackgroundLeft)
		gUI:KillObject(OpenStationeryBackgroundRight)
		gUI:KillObject(SendStationeryBackgroundLeft)
		gUI:KillObject(SendStationeryBackgroundRight)
		gUI:KillObject((select(2, InboxNextPageButton:GetRegions())))
		gUI:KillObject((select(2, InboxPrevPageButton:GetRegions())))
		gUI:KillObject(OpenMailFrameInset)
		gUI:KillObject(MailFrameInset)
		gUI:KillObject(SendMailMoneyBg)
		gUI:KillObject(SendMailMoneyInset)
		gUI:KillObject(OpenMailFrameIcon)
		
		gUI:SetUITemplate(InboxNextPageButton, "arrow", "right", "BOTTOMRIGHT", InboxFrame, "BOTTOMRIGHT", -40, 85)
		gUI:SetUITemplate(InboxPrevPageButton, "arrow", "left", "BOTTOMLEFT", InboxFrame, "BOTTOMLEFT", 10, 85)
		gUI:SetUITemplate(SendMailMailButton, "button", true)
		gUI:SetUITemplate(SendMailCancelButton, "button", true)
		gUI:SetUITemplate(OpenMailReportSpamButton, "button", true)
		gUI:SetUITemplate(OpenMailReplyButton, "button", true)
		gUI:SetUITemplate(OpenMailDeleteButton, "button", true)
		gUI:SetUITemplate(OpenMailCancelButton, "button", true)
		gUI:SetUITemplate(SendMailSendMoneyButton, "radiobutton", true)
		gUI:SetUITemplate(SendMailCODButton, "radiobutton", true)
		gUI:SetUITemplate(MailFrameCloseButton, "closebutton")
		gUI:SetUITemplate(OpenMailFrameCloseButton, "closebutton")
		gUI:SetUITemplate(SendMailNameEditBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(SendMailSubjectEditBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(SendMailMoneyGold, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(SendMailMoneySilver, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(SendMailMoneyCopper, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		
		SendMailMoneyGold:SetFontObject(gUI_DisplayFontTinyWhite)
		SendMailMoneySilver:SetFontObject(gUI_DisplayFontTinyWhite)
		SendMailMoneyCopper:SetFontObject(gUI_DisplayFontTinyWhite)
		
		SendMailMoneyFrameGoldButton:SetNormalFontObject(gUI_DisplayFontTinyWhite)
		SendMailMoneyFrameSilverButton:SetNormalFontObject(gUI_DisplayFontTinyWhite)
		SendMailMoneyFrameCopperButton:SetNormalFontObject(gUI_DisplayFontTinyWhite)
		
		-- gUI:SetUITemplate(MailFrame, "outerbackdrop", nil, 0, 4, 74, 30)
		-- gUI:SetUITemplate(OpenMailFrame, "outerbackdrop", nil, 0, 4, 74, 30)
		gUI:SetUITemplate(MailFrame, "backdrop")
		gUI:SetUITemplate(OpenMailFrame, "backdrop")
		gUI:SetUITemplate(OpenMailScrollFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(SendMailScrollFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		
		gABT:GetStyleFunction()(OpenMailLetterButton)
		gABT:GetStyleFunction()(OpenMailMoneyButton)
		OpenMailMoneyButton:SetBackdropBorderColor(1, 0.82, 0)
		
		gUI:SetUITemplate(OpenMailScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(SendMailScrollFrameScrollBar, "scrollbar")
		
		gUI:SetUITemplate(MailFrameTab1, "tab")
		gUI:SetUITemplate(MailFrameTab2, "tab")

		SendMailBodyEditBox:SetTextColor(unpack(C["index"]))
		OpenMailBodyText:SetTextColor(unpack(C["index"]))
		InvoiceTextFontNormal:SetTextColor(unpack(C["index"]))

		InboxTitleText:SetPoint("TOP", 0, -8)
		OpenMailTitleText:SetPoint("TOP", 0, -8)
		SendMailTitleText:SetPoint("TOP", 0, -8)

		local updateItem = function(item, itemID)
			local quality
			if (itemID) then
				quality = (itemID) and (select(3, GetItemInfo(itemID)))
			end
			
			if (quality) and (quality > 1) then
				local r, g, b, hex = GetItemQualityColor(quality)
				item:SetBackdropBorderColor(r, g, b)
			else
				item:SetBackdropBorderColor(unpack(C["border"]))
			end
		end

		for i = 1, INBOXITEMS_TO_DISPLAY do
			local bg = _G["MailItem" .. i]
			local b = _G["MailItem" .. i .. "Button"]
			local slot = _G["MailItem" .. i .. "ButtonSlot"]
			local w,h = bg:GetSize()
			local w2,h2 = b:GetSize()

			gUI:DisableTextures(bg)
			gUI:KillObject(slot)
			gUI:SetUITemplate(bg, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)

			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", bg, "TOPLEFT", 4, -4)
			b:SetHitRectInsets(-4, -(w-(w2+4)), -4, -(h-(h2+4)))
			-- gUI:DisableTextures(b)
			gABT:GetStyleFunction()(b)
		end
		
		for i = 1, ATTACHMENTS_MAX_SEND do				
			local b = _G["OpenMailAttachmentButton" .. i]
			-- gUI:DisableTextures(b)
			gABT:GetStyleFunction()(b)
		end
		
		local skin = {}
		local UpdateSendMail = function()
			for i = 1, ATTACHMENTS_MAX_SEND do				
				local itemName, itemTexture, stackCount, quality = GetSendMailItem(i)
				local b = _G["SendMailAttachment" .. i]
				
				if not(skin[b]) then
					-- gUI:DisableTextures(b)
					local slot = select(1, b:GetRegions())
					gUI:KillObject(slot)
					gABT:GetStyleFunction()(b)
					skin[b] = true
				end
				
				local t = b:GetNormalTexture()
				if (t) then
					t:SetTexCoord(5/64, 59/64, 5/64, 59/64)
					t:ClearAllPoints()
					t:SetPoint("TOPLEFT", 3, -3)
					t:SetPoint("BOTTOMRIGHT", -3, 3)
				end
				
				if (itemName) then
					updateItem(b, itemName)
				else
					updateItem(b)
				end
			end
		end
		hooksecurefunc("SendMailFrame_Update", UpdateSendMail)
		
		local UpdateInbox = function()
			local numItems, totalItems = GetInboxNumItems()
			local index = ((InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY) + 1
			local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, x, y, z, isGM, firstItemQuantity
			local button, buttonIcon
			
			for i = 1, INBOXITEMS_TO_DISPLAY do
				button = _G["MailItem" .. i .. "Button"]
				buttonIcon = _G["MailItem" .. i .. "ButtonIcon"]
				if (index <= numItems) then
					packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, x, y, z, isGM, firstItemQuantity = GetInboxHeaderInfo(index)
					
					if (wasRead) then
						updateItem(button)
					else
						if (itemCount) and (buttonIcon:GetTexture() == packageIcon) then
							updateItem(button, GetInboxItemLink(index, 1))
						elseif (money) and (money > 0) then
							button:SetBackdropBorderColor(1, 0.82, 0)
						else
							updateItem(button)
						end
					end
				else
					updateItem(button)
				end
				index = index + 1
			end
		end
		hooksecurefunc("InboxFrame_Update", UpdateInbox)
		
		local UpdateOpenMail = function()
			if not(InboxFrame.openMailID) then
				return
			end
			local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, wasReturned, textCreated, canReply = GetInboxHeaderInfo(InboxFrame.openMailID)
			local bodyText, texture, isTakeable, isInvoice = GetInboxText(InboxFrame.openMailID)
			local itemButtonCount, itemRowCount = OpenMail_GetItemCounts(isTakeable, textCreated, money)
			
			if (itemRowCount > 0) and (OpenMailFrame.activeAttachmentButtons) then
				local rowIndex = 1;
				for i, attachmentButton in pairs(OpenMailFrame.activeAttachmentButtons) do
					if (attachmentButton ~= OpenMailLetterButton) and (attachmentButton ~= OpenMailMoneyButton) then
						updateItem(attachmentButton, GetInboxItemLink(InboxFrame.openMailID, attachmentButton:GetID()))
					end
				end
			end
		end
		hooksecurefunc("OpenMail_Update", UpdateOpenMail)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end