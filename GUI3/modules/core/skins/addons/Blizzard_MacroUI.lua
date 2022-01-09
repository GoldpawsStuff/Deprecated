--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_MacroUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Macro UI"])
	self:SetAttribute("description", L["The window where you manage your macros"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(MacroFrame)
		gUI:DisableTextures(MacroFrameInset)
		gUI:DisableTextures(MacroPopupFrame)
		-- gUI:DisableTextures(MacroFrameSelectedMacroButton)
		gUI:DisableTextures(MacroFrameTab1)
		gUI:DisableTextures(MacroFrameTab2)
		gUI:DisableTextures(MacroFrameTextBackground)
		gUI:HideTexture(MacroPopupNameLeft)
		gUI:HideTexture(MacroPopupNameMiddle)
		gUI:HideTexture(MacroPopupNameRight)
		gUI:DisableTextures(MacroButtonScrollFrame)
		gUI:DisableTextures(MacroPopupScrollFrame)
		
		gUI:KillObject(MacroFramePortrait)
		
		gUI:SetUITemplate(MacroFrame, "backdrop")
		gUI:SetUITemplate(MacroFrameScrollFrame, "outerbackdrop", nil, 0, 0, -3, 0):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(MacroButtonScrollFrame, "outerbackdrop", nil, 0, 1, 0, 3):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(MacroPopupFrame, "outerbackdrop", nil, 8, 12, 8, 8)
		gUI:SetUITemplate(MacroPopupScrollFrame, "outerbackdrop", nil, 16, 61, 6, 13):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(MacroSaveButton, "button", true)
		gUI:SetUITemplate(MacroCancelButton, "button", true)
		gUI:SetUITemplate(MacroDeleteButton, "button", true)
		gUI:SetUITemplate(MacroNewButton, "button", true)
		gUI:SetUITemplate(MacroExitButton, "button", true)
		gUI:SetUITemplate(MacroEditButton, "button", true)
		gUI:SetUITemplate(MacroPopupOkayButton, "button", true)
		gUI:SetUITemplate(MacroPopupCancelButton, "button", true)
		gUI:SetUITemplate(MacroPopupEditBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(MacroFrameCloseButton, "closebutton", "TOPRIGHT", -4, -4)
		gUI:SetUITemplate(MacroButtonScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(MacroFrameScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(MacroPopupScrollFrameScrollBar, "scrollbar")
		
		MacroNewButton:ClearAllPoints()
		MacroNewButton:SetPoint("BOTTOMRIGHT", -86, 4)
		
		MacroFrameScrollFrame:SetHeight(MacroFrameScrollFrame:GetHeight() - 6)
		
		-- local chooseIcon = select(2, MacroPopupFrame:GetRegions())
		-- chooseIcon:ClearAllPoints()
		-- chooseIcon:SetPoint("TOPLEFT", MacroPopupEditBox, "BOTTOMLEFT", 0, -2)
		
		MacroFrameSelectedMacroButtonIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		gUI:SetUITemplate(MacroFrameSelectedMacroButton, "itembackdrop", MacroFrameSelectedMacroButtonIcon)
		gUI:SetUITemplate(MacroFrameSelectedMacroButton, "gloss", MacroFrameSelectedMacroButtonIcon)
		gUI:SetUITemplate(MacroFrameSelectedMacroButton, "shade", MacroFrameSelectedMacroButtonIcon)
		gUI:CreatePushed(MacroFrameSelectedMacroButton)
		gUI:CreateHighlight(MacroFrameSelectedMacroButton)
		gUI:KillObject(select(2, MacroFrameSelectedMacroButton:GetRegions()))

		for i = 1, MAX_ACCOUNT_MACROS do
			local button = _G["MacroButton" .. i]
			local icon = _G["MacroButton" .. i .. "Icon"]
			local popup = _G["MacroPopupButton" .. i]
			local popicon = _G["MacroPopupButton" .. i .. "Icon"]
			
			if (button) then
				local slot = select(2, button:GetRegions())
				gUI:KillObject(slot)
				gABT:GetStyleFunction()(button)
				icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			end
			
			if (popup) then
				local slot = select(2, popup:GetRegions())
				gUI:KillObject(slot)
				gABT:GetStyleFunction()(popup)
				popicon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			end
		end
		
		MacroPopupFrame:HookScript("OnShow", function(self)
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", MacroFrame, "TOPRIGHT", 8, 5)
		end)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end