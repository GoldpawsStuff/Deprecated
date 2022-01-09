--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local patch, build, released, toc = GetBuildInfo()
build = tonumber(build)

-- disabling in 5.4
if (build >= 17205) then
	return
end
	
local style = gUI:GetModule("Styling"):NewModule("Blizzard_Calendar")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Calendar"])
	self:SetAttribute("description", L["The in-game calendar"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(CalendarFrame)
		gUI:DisableTextures(CalendarTodayFrame)
		gUI:DisableTextures(CalendarEventPickerCloseButton)
		gUI:DisableTextures(CalendarEventPickerTitleFrame)
		gUI:DisableTextures(CalendarEventPickerFrame)
		gUI:DisableTextures(CalendarViewEventInviteListSection)
		gUI:DisableTextures(CalendarViewEventInviteList)
		gUI:DisableTextures(CalendarViewEventDescriptionContainer)
		gUI:DisableTextures(CalendarViewEventFrame)
		gUI:DisableTextures(CalendarViewHolidayFrame)
		gUI:DisableTextures(CalendarViewHolidayTitleFrame)
		gUI:DisableTextures(CalendarViewRaidFrame)
		gUI:DisableTextures(CalendarViewRaidTitleFrame)
		gUI:DisableTextures(CalendarMassInviteFrame)
		gUI:DisableTextures(CalendarMassInviteTitleFrame)
		gUI:DisableTextures(CalendarTexturePickerFrame)
		gUI:DisableTextures(CalendarTexturePickerTitleFrame)
		gUI:DisableTextures(CalendarCreateEventInviteListSection)
		gUI:DisableTextures(CalendarCreateEventDescriptionContainer)
		gUI:DisableTextures(CalendarCreateEventInviteList)
		gUI:DisableTextures(CalendarCreateEventFrame)
		gUI:DisableTextures(CalendarCreateEventTitleFrame)
		gUI:DisableTextures(CalendarFilterFrame)
		gUI:DisableTextures(CalendarCreateEventCloseButton)
		gUI:DisableTextures(CalendarViewRaidCloseButton)
		gUI:DisableTextures(CalendarViewHolidayCloseButton)
		gUI:DisableTextures(CalendarMassInviteCloseButton)
		gUI:DisableTextures(CalendarCreateEventCloseButton)
		gUI:DisableTextures(CalendarCreateEventHourDropDown)
		gUI:DisableTextures(CalendarCreateEventMinuteDropDown)
		gUI:DisableTextures(CalendarCreateEventAMPMDropDown)
		gUI:DisableTextures(CalendarCreateEventRepeatOptionDropDown)
		gUI:DisableTextures(CalendarCreateEventTypeDropDown)
		gUI:DisableTextures(CalendarViewEventCloseButton)
		
		gUI:HideTexture(CalendarViewEventTitleFrameBackgroundLeft)
		gUI:HideTexture(CalendarViewEventTitleFrameBackgroundRight)
		gUI:HideTexture(CalendarViewEventTitleFrameBackgroundMiddle)

		gUI:SetUITemplate(CalendarNextMonthButton, "arrow", "right")
		gUI:SetUITemplate(CalendarPrevMonthButton, "arrow", "left")
		gUI:SetUITemplate(CalendarFilterButton, "arrow", "down")
		gUI:SetUITemplate(CalendarCreateEventCreateButton, "button", true)
		gUI:SetUITemplate(CalendarCreateEventMassInviteButton, "button", true)
		gUI:SetUITemplate(CalendarCreateEventInviteButton, "button", true)
		gUI:SetUITemplate(CalendarTexturePickerAcceptButton, "button", true)
		gUI:SetUITemplate(CalendarTexturePickerCancelButton, "button", true)
		gUI:SetUITemplate(CalendarCreateEventInviteButton, "button", true)
		gUI:SetUITemplate(CalendarCreateEventRaidInviteButton, "button", true)
		gUI:SetUITemplate(CalendarMassInviteGuildAcceptButton, "button", true)
		gUI:SetUITemplate(CalendarMassInviteArenaButton2, "button", true)
		gUI:SetUITemplate(CalendarMassInviteArenaButton3, "button", true)
		gUI:SetUITemplate(CalendarMassInviteArenaButton5, "button", true)
		gUI:SetUITemplate(CalendarViewEventAcceptButton, "button", true)
		gUI:SetUITemplate(CalendarViewEventTentativeButton, "button", true)
		gUI:SetUITemplate(CalendarViewEventRemoveButton, "button", true)
		gUI:SetUITemplate(CalendarViewEventDeclineButton, "button", true)
		gUI:SetUITemplate(CalendarEventPickerCloseButton, "closebutton")
		gUI:SetUITemplate(CalendarCreateEventLockEventCheck, "checkbutton")
		gUI:SetUITemplate(CalendarCloseButton, "closebutton", "TOPRIGHT", CalendarFrame, -8, -8)
		gUI:SetUITemplate(CalendarViewEventCloseButton, "closebutton")
		gUI:SetUITemplate(CalendarViewRaidCloseButton, "closebutton")
		gUI:SetUITemplate(CalendarViewHolidayCloseButton, "closebutton")
		gUI:SetUITemplate(CalendarMassInviteCloseButton, "closebutton")
		gUI:SetUITemplate(CalendarCreateEventCloseButton, "closebutton")
		gUI:SetUITemplate(CalendarCreateEventHourDropDown, "dropdown", true, 80)
		gUI:SetUITemplate(CalendarCreateEventMinuteDropDown, "dropdown", true, 80)
		gUI:SetUITemplate(CalendarCreateEventAMPMDropDown, "dropdown", true)
		gUI:SetUITemplate(CalendarCreateEventRepeatOptionDropDown, "dropdown", true)
		gUI:SetUITemplate(CalendarMassInviteGuildRankMenu, "dropdown", true)
		gUI:SetUITemplate(CalendarCreateEventTypeDropDown, "dropdown", true)
		gUI:SetUITemplate(CalendarCreateEventInviteEdit, "editbox", 0, 0, 0, -12):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CalendarCreateEventTitleEdit, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CalendarMassInviteGuildMinLevelEdit, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CalendarMassInviteGuildMaxLevelEdit, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CalendarFrame, "outerbackdrop")
		gUI:SetUITemplate(CalendarCreateEventFrame, "outerbackdrop")
		gUI:SetUITemplate(CalendarCreateEventInviteList, "outerbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CalendarCreateEventDescriptionContainer, "outerbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(CalendarTexturePickerFrame, "outerbackdrop")
		gUI:SetUITemplate(CalendarMassInviteFrame, "outerbackdrop", nil, 0, 0, 0, 30)
		gUI:SetUITemplate(CalendarViewRaidFrame, "outerbackdrop")
		gUI:SetUITemplate(CalendarViewHolidayFrame, "outerbackdrop")
		gUI:SetUITemplate(CalendarViewEventFrame, "outerbackdrop")
		gUI:SetUITemplate(CalendarViewEventDescriptionContainer, "outerbackdrop")
		gUI:SetUITemplate(CalendarViewEventInviteList, "outerbackdrop")
		gUI:SetUITemplate(CalendarEventPickerFrame, "outerbackdrop")
		gUI:SetUITemplate(CalendarTexturePickerScrollBar, "scrollbar")
		gUI:SetUITemplate(CalendarViewEventInviteListScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(CalendarEventPickerScrollBar, "scrollbar")
		gUI:SetUITemplate(CalendarTodayFrame, "targetborder")
		CalendarTodayFrame:SetSize(CalendarDayButton1:GetSize())

		gUI:SetUITemplate(CalendarContextMenu, "backdrop")
		gUI:SetUITemplate(CalendarInviteStatusContextMenu, "backdrop")
		
		-- CalendarContextMenu:SetBackdrop(M["Backdrop"]["PixelBorder-Satin"])
		-- CalendarContextMenu:SetBackdropColor(unpack(C["overlay"]))
		-- CalendarContextMenu:SetBackdropBorderColor(unpack(C["border"]))
	
		-- CalendarInviteStatusContextMenu:SetBackdrop(M["Backdrop"]["PixelBorder-Satin"])
		-- CalendarInviteStatusContextMenu:SetBackdropColor(unpack(C["overlay"]))
		-- CalendarInviteStatusContextMenu:SetBackdropBorderColor(unpack(C["border"]))
		
		CalendarCreateEventIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		CalendarCreateEventIcon.SetTexCoord = noop

		-- CALENDAR_MAX_DAYS_PER_MONTH
		for i = 1, 42 do
			local button = _G["CalendarDayButton" .. i]
			button:SetFrameLevel(button:GetFrameLevel() + 1)
			button:GetHighlightTexture():SetTexture(C["hover"].r, C["hover"].g, C["hover"].b, 1/3)

			local backdrop = gUI:SetUITemplate(button, "outerbackdrop")
			backdrop:SetBackdropColor(r, g, b, panelAlpha)

			button:GetHighlightTexture():ClearAllPoints()
			button:GetHighlightTexture():SetPoint("TOPLEFT", backdrop, "TOPLEFT", 3, -3)
			button:GetHighlightTexture():SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", -3, 3)
			
			button:GetNormalTexture():ClearAllPoints()
			button:GetNormalTexture():SetPoint("TOPLEFT", backdrop, "TOPLEFT", 3, -3)
			button:GetNormalTexture():SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", -3, 3)
			
			-- this kills the blizzard background, and makes our standard satin texture a bit more interesting
			button:GetNormalTexture():SetTexture(gUI:GetBlankTexture())
			button:GetNormalTexture():SetVertexColor(r, g, b, 1/3)
			-- button:GetNormalTexture():SetTexCoord(random(0, 35) * 1/100, random(65, 100) * 1/100, random(0, 35) * 1/100, random(65, 100) * 1/100)
			button:GetNormalTexture().SetTexCoord = noop
			button:GetNormalTexture().SetTexture = noop
			
			_G[button:GetName() .. "DarkFrame"]:SetAlpha(2/3)

			_G[button:GetName() .. "OverlayFrame"]:ClearAllPoints()
			_G[button:GetName() .. "OverlayFrame"]:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 3, -3)
			_G[button:GetName() .. "OverlayFrame"]:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", -3, 3)

			_G[button:GetName() .. "EventTexture"]:ClearAllPoints()
			_G[button:GetName() .. "EventTexture"]:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 3, -3)
			_G[button:GetName() .. "EventTexture"]:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", -3, 3)

			_G[button:GetName() .. "EventBackgroundTexture"]:ClearAllPoints()
			_G[button:GetName() .. "EventBackgroundTexture"]:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 3, -3)
			_G[button:GetName() .. "EventBackgroundTexture"]:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", -3, 3)
			
			_G[button:GetName() .. "PendingInviteTexture"]:ClearAllPoints()
			_G[button:GetName() .. "PendingInviteTexture"]:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 3, -3)
			_G[button:GetName() .. "PendingInviteTexture"]:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", -3, 3)

			button:SetWidth(button:GetWidth() - 8)
			button:SetHeight(button:GetHeight() - 8)
			button:ClearAllPoints()

			if ( i == 1 ) then
				button:SetPoint("TOPLEFT", CalendarWeekday1Background, "BOTTOMLEFT", 4, -4)
			elseif ( i % 7 == 1 ) then
				button:SetPoint("TOPLEFT", _G["CalendarDayButton" .. (i - 7)], "BOTTOMLEFT", 0, -8)
			else
				button:SetPoint("TOPLEFT", _G["CalendarDayButton" .. (i - 1)], "TOPRIGHT", 8, 0)
			end
			
			local font, size, style = _G[button:GetName() .. "DateFrameDate"]:GetFont()
			_G[button:GetName() .. "DateFrameDate"]:SetFont(font, size, "THINOUTLINE")

			-- CALENDAR_DAYBUTTON_MAX_VISIBLE_EVENTS
			for event = 1, 4 do
				eventButton = _G[button:GetName() .. "EventButton" .. event]
				
				if (eventButton) then
					eventButton:SetWidth(eventButton:GetWidth() - 8)
					
					font, size, style = _G[eventButton:GetName() .. "Text1"]:GetFont()
					_G[eventButton:GetName() .. "Text1"]:SetFont(font, size, "THINOUTLINE")
				
					font, size, style = _G[eventButton:GetName() .. "Text2"]:GetFont()
					_G[eventButton:GetName() .. "Text2"]:SetFont(font, size, "THINOUTLINE")

					eventButton:GetHighlightTexture():SetTexture(C["hover"].r, C["hover"].g, C["hover"].b, 1/3)
					_G[eventButton:GetName() .. "Black"]:SetTexture(C["pushed"].r, C["pushed"].g, C["pushed"].b, 1/3)
				end
			end
		end
		
		local once
		local updateClassButtons = function()
			if (once) then return end
			for i, class in ipairs(CLASS_SORT_ORDER) do
				local button = _G["CalendarClassButton" .. i]
				
				gUI:KillObject(button:GetRegions()) -- the old border is region 1
				gUI:SetUITemplate(button, "outerbackdrop")
				gUI:SetUITemplate(button, "gloss")
				gUI:SetUITemplate(button, "shade")

				local tcoords = CLASS_ICON_TCOORDS[class]
				button:GetNormalTexture():SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
				button:GetNormalTexture():SetTexCoord(tcoords[1] + 5/256, tcoords[2] - 5/256, tcoords[3] + 5/256, tcoords[4] - 5/256)
			end
			gUI:DisableTextures(CalendarClassTotalsButton)
			gUI:SetUITemplate(CalendarClassTotalsButton, "outerbackdrop", nil, -3, -6, -3, -6)
			once = true
		end
		CalendarClassButtonContainer:HookScript("OnShow", updateClassButtons)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end