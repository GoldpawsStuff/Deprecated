--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_TrainerUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Trainers"])
	self:SetAttribute("description", L["The trainer interface where you learn new skills and abilities from"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(ClassTrainerFrame)
		gUI:DisableTextures(ClassTrainerScrollFrameScrollChild)
		gUI:DisableTextures(ClassTrainerFrameBottomInset)
		gUI:DisableTextures(ClassTrainerFrameInset)
		gUI:DisableTextures(ClassTrainerFrameSkillStepButton, ClassTrainerFrameSkillStepButton.icon, ClassTrainerFrameSkillStepButton.selectedTex, ClassTrainerFrameSkillStepButtonHighlight)
		
		gUI:KillObject(ClassTrainerFramePortrait)

		gUI:SetUITemplate(ClassTrainerTrainButton, "button", true)
		gUI:SetUITemplate(ClassTrainerFrameCloseButton, "closebutton", "TOPRIGHT", -4, -4)
		gUI:SetUITemplate(ClassTrainerFrameFilterDropDown, "dropdown", true, 128)
		gUI:SetUITemplate(ClassTrainerScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(ClassTrainerStatusBar, "statusbar", true)
		gUI:SetUITemplate(ClassTrainerFrame, "outerbackdrop", nil, -3, 0, 0, 0)
		gUI:SetUITemplate(ClassTrainerScrollFrame, "outerbackdrop", nil, 0, 2, -1, 0):SetBackdropColor(r, g, b, panelAlpha)

		ClassTrainerFrameFilterDropDown:ClearAllPoints()
		ClassTrainerFrameFilterDropDown:SetPoint("TOPRIGHT", -8, -30)
		ClassTrainerStatusBar:SetSize(180, 15)
		ClassTrainerStatusBar:SetPoint("TOPLEFT", 9, -36)
		ClassTrainerScrollFrame:SetHeight(ClassTrainerScrollFrame:GetHeight() - 8)
		ClassTrainerFrameSkillStepButtonHighlight:SetTexture(C["hover"].r, C["hover"].g, C["hover"].b, 1/3)
		ClassTrainerFrameSkillStepButton.selectedTex:SetTexture(C["hover"].r, C["hover"].g, C["hover"].b, 1/3)		

		local backdrop = gUI:SetUITemplate(ClassTrainerFrameSkillStepButton, "itembackdrop", ClassTrainerFrameSkillStepButton.icon)
		ClassTrainerFrameSkillStepButton.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		ClassTrainerFrameSkillStepButton.icon:SetParent(backdrop)
		gUI:SetUITemplate(backdrop, "gloss", ClassTrainerFrameSkillStepButton.icon)
		gUI:SetUITemplate(backdrop, "shade", ClassTrainerFrameSkillStepButton.icon)
		
		for i,button in pairs(ClassTrainerScrollFrame.buttons) do
			local icon = _G[button:GetName() .. "Icon"]
			gUI:DisableTextures(button, icon, button.selectedTex, button:GetName() .. "Highlight")
			
			local backdrop = gUI:SetUITemplate(button, "itembackdrop", icon)
			icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icon:SetParent(backdrop)
			gUI:SetUITemplate(backdrop, "gloss", icon)
			gUI:SetUITemplate(backdrop, "shade", icon)

			local highlight = gUI:CreateHighlight(button)
			highlight:ClearAllPoints()
			highlight:SetPoint("BOTTOM", icon, "BOTTOM", 0, -5)
			highlight:SetPoint("LEFT", icon, "LEFT", -5, 0)
			highlight:SetPoint("TOP", icon, "TOP", 0, 5)
			highlight:SetPoint("RIGHT", button, "RIGHT", 1, 0)
				
			local pushed = gUI:CreatePushed(button)
			pushed:ClearAllPoints()
			pushed:SetAllPoints(highlight)

			button.selectedTex:SetTexture(C["hover"].r, C["hover"].g, C["hover"].b, 1/3)
			button.selectedTex:SetAllPoints(highlight)

			_G[button:GetName() .. "Highlight"] = highlight
			_G[button:GetName() .. "Pushed"] = pushed
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end