--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

-- pvp frame integrated into lfg in client patch 5.2
if tonumber((select(2, GetBuildInfo()))) >= 16650 then return end

-- weird bugs in 5.3
if tonumber((select(2, GetBuildInfo()))) >= 16837 then return end

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("PvP")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["PvP"])
	self:SetAttribute("description", L["The PvP window where you queue up for Battlegrounds and Arenas, and manage your teams"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:HideTexture(PVPHonorFrameBGTex)
		gUI:DisableTextures(PVPHonorFrameInfoScrollFrameScrollBar)
		gUI:HideTexture(PVPConquestFrameInfoButtonInfoBG)
		gUI:HideTexture(PVPConquestFrameInfoButtonInfoBGOff)
		gUI:HideTexture(PVPTeamManagementFrameFlag2GlowBG)
		gUI:HideTexture(PVPTeamManagementFrameFlag3GlowBG)
		gUI:HideTexture(PVPTeamManagementFrameFlag5GlowBG)
		gUI:HideTexture(PVPTeamManagementFrameFlag2HeaderSelected)
		gUI:HideTexture(PVPTeamManagementFrameFlag3HeaderSelected)
		gUI:HideTexture(PVPTeamManagementFrameFlag5HeaderSelected)
		gUI:HideTexture(PVPTeamManagementFrameFlag2Header)
		gUI:HideTexture(PVPTeamManagementFrameFlag3Header)
		gUI:HideTexture(PVPTeamManagementFrameFlag5Header)
		gUI:HideTexture(PVPTeamManagementFrameWeeklyDisplayLeft)
		gUI:HideTexture(PVPTeamManagementFrameWeeklyDisplayRight)
		gUI:HideTexture(PVPTeamManagementFrameWeeklyDisplayMiddle)
		gUI:HideTexture(PVPBannerFramePortrait)
		gUI:HideTexture(PVPBannerFramePortraitFrame)
		gUI:DisableTextures(PVPBannerFrameInset)
		gUI:HideTexture(PVPBannerFrameEditBoxLeft)
		gUI:HideTexture(PVPBannerFrameEditBoxRight)
		gUI:HideTexture(PVPBannerFrameEditBoxMiddle)
		gUI:HideTexture(PVPBannerFrameCancelButton_LeftSeparator)
		gUI:DisableTextures(PVPFrame)
		gUI:DisableTextures(PVPFrameInset)
		gUI:DisableTextures(PVPHonorFrame)
		gUI:DisableTextures(PVPConquestFrame)
		gUI:DisableTextures(PVPTeamManagementFrame)
		gUI:DisableTextures(PVPHonorFrameTypeScrollFrame)
		gUI:DisableTextures(PVPFrameTopInset)
		gUI:DisableTextures(PVPTeamManagementFrameInvalidTeamFrame)
		gUI:DisableTextures(PVPBannerFrame)
		gUI:DisableTextures(PVPBannerFrameCustomization1)
		gUI:DisableTextures(PVPBannerFrameCustomization2)
		gUI:DisableTextures(PVPBannerFrameCustomizationFrame)
		gUI:DisableTextures(PVPTeamManagementFrameHeader1)
		gUI:DisableTextures(PVPTeamManagementFrameHeader2)
		gUI:DisableTextures(PVPTeamManagementFrameHeader3)
		gUI:DisableTextures(PVPTeamManagementFrameHeader4)
		gUI:HideTexture(PVPFrameConquestBarShadow)
		gUI:HideTexture(PVPFrameConquestBarBG)
		gUI:HideTexture(PVPFrameConquestBarLeft)
		gUI:HideTexture(PVPFrameConquestBarMiddle)
		gUI:HideTexture(PVPFrameConquestBarRight)
		gUI:HideTexture(PVPFrameConquestBarDivider1)
		gUI:HideTexture(PVPFrameConquestBarDivider2) 
		gUI:HideTexture(PVPFrameConquestBarDivider3)
		gUI:HideTexture(PVPFrameConquestBarDivider4)  
		gUI:DisableTextures(WarGamesFrame)
		gUI:DisableTextures(WarGamesFrameInfoScrollFrameScrollBar)

		gUI:SetUITemplate(PVPBannerFrameCustomization1LeftButton, "arrow", "left")
		gUI:SetUITemplate(PVPBannerFrameCustomization1RightButton, "arrow", "right")
		gUI:SetUITemplate(PVPBannerFrameCustomization2LeftButton, "arrow", "left")
		gUI:SetUITemplate(PVPBannerFrameCustomization2RightButton, "arrow", "right")
		gUI:SetUITemplate(PVPTeamManagementFrameWeeklyToggleLeft, "arrow", "left")
		gUI:SetUITemplate(PVPTeamManagementFrameWeeklyToggleRight, "arrow", "right")

		gUI:SetUITemplate(WarGameStartButton, "button", true)
		gUI:SetUITemplate(PVPFrameLeftButton, "button", true)
		gUI:SetUITemplate(PVPFrameRightButton, "button", true)
		gUI:SetUITemplate(PVPColorPickerButton1, "button", true)
		gUI:SetUITemplate(PVPColorPickerButton2, "button", true)
		gUI:SetUITemplate(PVPColorPickerButton3, "button", true)
		gUI:SetUITemplate(PVPBannerFrameAcceptButton, "button", true)
		
		gUI:SetUITemplate(PVPFrameCloseButton, "closebutton")
		gUI:SetUITemplate(PVPBannerFrameCloseButton, "closebutton")
		
		gUI:SetUITemplate(PVPBannerFrameEditBox, "editbox")
		
		gUI:SetUITemplate(PVPTeamManagementFrameInvalidTeamFrame, "backdrop")
		gUI:SetUITemplate(PVPBannerFrame, "backdrop") -- :SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(PVPBannerFrameCustomization1, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(PVPBannerFrameCustomization2, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(PVPFrame, "backdrop")
		
		gUI:SetUITemplate(PVPConquestFrame, "outerbackdrop", nil, 0, 0, 3, -2):SetBackdropColor(r, g, b, panelAlpha)
		--gUI:SetUITemplate(PVPFrameConquestBar, "outerbackdrop", nil, 0, 0, 0, 0)
		
		gUI:SetUITemplate(PVPHonorFrameInfoScrollFrame, "outerbackdrop", nil, 0, 0, 3, 0):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(WarGamesFrameScrollFrame, "outerbackdrop", nil, 0, 2, -2, 3):SetBackdropColor(r, g, b, panelAlpha) 
		gUI:SetUITemplate(WarGamesFrameInfoScrollFrame, "outerbackdrop", nil, 3, 0, 3, 0):SetBackdropColor(r, g, b, panelAlpha) 
		gUI:SetUITemplate(WarGamesFrameScrollFrameScrollBar, "scrollbar") 
		gUI:SetUITemplate(WarGamesFrameInfoScrollFrameScrollBar, "scrollbar") 

		gUI:SetUITemplate(PVPHonorFrameInfoScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(PVPHonorFrameTypeScrollFrameScrollBar, "scrollbar")
			
		gUI:SetUITemplate(PVPFrameTab1, "tab")
		gUI:SetUITemplate(PVPFrameTab2, "tab")
		gUI:SetUITemplate(PVPFrameTab3, "tab")
		gUI:SetUITemplate(PVPFrameTab4, "tab")

		PVPFrameConquestBar:SetPoint("TOP", 0, -40)
		PVPFrameConquestBar:SetHeight(14)

		PVPFrameConquestBar.progress:SetTexture(gUI:GetStatusBarTexture())
		PVPFrameConquestBarCap1:SetTexture(gUI:GetStatusBarTexture())
		PVPFrameConquestBarCap2:SetTexture(gUI:GetStatusBarTexture())
		PVPFrameConquestBarLabel:SetPoint("BOTTOM", PVPFrameConquestBar, "TOP", 0, 4)
		PVPFrameConquestBarLabel:SetFontObject(gUI_TextFontSmallWhite)
		PVPFrameConquestBarText:SetFontObject(gUI_DisplayFontSmallOutlineWhite)
		PVPFrameConquestBarText:ClearAllPoints()
		PVPFrameConquestBarText:SetPoint("CENTER")
		gUI:DisableTextures(PVPFrameConquestBarCap1Marker)
		gUI:DisableTextures(PVPFrameConquestBarCap2Marker)
		
		PVPFrameConquestBar.backdrop = gUI:SetUITemplate(PVPFrameConquestBar, "outerbackdrop")
		PVPFrameConquestBar.eyeCandy = CreateFrame("Frame", nil, PVPFrameConquestBar.backdrop)
		PVPFrameConquestBar.eyeCandy:SetPoint("TOPLEFT", PVPFrameConquestBar.backdrop, 3, -3)
		PVPFrameConquestBar.eyeCandy:SetPoint("BOTTOMRIGHT", PVPFrameConquestBar.backdrop, -3, 3)
		gUI:SetUITemplate(PVPFrameConquestBar.eyeCandy, "gloss")
		-- gUI:SetUITemplate(PVPFrameConquestBar.eyeCandy, "shade")
		
		PVPHonorFrameInfoScrollFrameChildFrameDescription:SetTextColor(unpack(C["index"]))
		PVPHonorFrameInfoScrollFrameChildFrameRewardsInfo.description:SetTextColor(unpack(C["index"]))
		WarGamesFrameDescription:SetTextColor(unpack(C["index"])) 

		WarGameStartButton:ClearAllPoints()
		WarGameStartButton:SetPoint("LEFT", PVPFrameLeftButton, "RIGHT", 8, 0)

		local button
		for i = 1, #WarGamesFrame.scrollFrame.buttons do
			button = WarGamesFrame.scrollFrame.buttons[i]
			gUI:HideTexture(_G[button.warGame:GetName() .. "Border"])
			gUI:SetUITemplate(button.warGame, "border", _G[button.warGame:GetName() .. "Icon"])
			gUI:SetUITemplate(button.header, "arrow", "collapse")
			gUI:CreatePushed(button.warGame)
			gUI:CreateHighlight(button.warGame)
		end
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end