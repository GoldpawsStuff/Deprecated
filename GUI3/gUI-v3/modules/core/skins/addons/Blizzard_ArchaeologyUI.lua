--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_ArchaeologyUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Archeology"])
	self:SetAttribute("description", L["The Archeology UI"])

	local func = function()
		gUI:DisableTextures(ArchaeologyFrame)
		gUI:DisableTextures(ArchaeologyFrameSummaryPage)
		gUI:DisableTextures(ArchaeologyFrameCompletedPage)
		gUI:DisableTextures(ArchaeologyFrameInset)
		gUI:HideTexture(ArchaeologyFrameBgLeft)
		gUI:HideTexture(ArchaeologyFrameBgRight)

		gUI:KillObject(ArchaeologyFramePortrait)

		gUI:SetUITemplate(ArchaeologyFrameCompletedPagePrevPageButton, "arrow", "left")
		gUI:SetUITemplate(ArchaeologyFrameCompletedPageNextPageButton, "arrow", "right")
		gUI:SetUITemplate(ArchaeologyFrameArtifactPageSolveFrameSolveButton, "button", true)
		gUI:SetUITemplate(ArchaeologyFrameCloseButton, "closebutton")
		gUI:SetUITemplate(ArchaeologyFrameRaceFilter, "dropdown", true)
		gUI:SetUITemplate(ArchaeologyFrame, "backdrop")
		gUI:SetUITemplate(ArchaeologyFrameRankBar, "statusbar", true)
		gUI:SetUITemplate(ArchaeologyFrameArtifactPageSolveFrameStatusBar, "statusbar", true)
		
		ArchaeologyFrameInfoButton:ClearAllPoints()
		ArchaeologyFrameInfoButton:SetPoint("TOPLEFT", ArchaeologyFrame, "TOPLEFT", 8, -8)
		
		ArchaeologyFrameCompletedPage.infoText:SetTextColor(unpack(C["index"]))
		ArchaeologyFrameArtifactPageHistoryTitle:SetTextColor(unpack(C["value"]))
		ArchaeologyFrameArtifactPageHistoryScrollChildText:SetTextColor(unpack(C["index"]))
		ArchaeologyFrameHelpPageDigTitle:SetTextColor(unpack(C["value"]))
		ArchaeologyFrameHelpPageHelpScrollHelpText:SetTextColor(unpack(C["index"]))
		ArchaeologyFrameHelpPageTitle:SetTextColor(unpack(C["value"]))
				
		for i = 1, ARCHAEOLOGY_MAX_RACES do
			local frame = _G["ArchaeologyFrameSummaryPageRace" .. i]
			if (frame) then
				frame.raceName:SetTextColor(unpack(C["index"]))
			end
		end
		
		for i = 1, ArchaeologyFrameCompletedPage:GetNumRegions() do
			local region = select(i, ArchaeologyFrameCompletedPage:GetRegions())
			if (region:GetObjectType() == "FontString") then
				region:SetTextColor(unpack(C["value"]))
			end
		end
		
		for i = 1, ArchaeologyFrameSummaryPage:GetNumRegions() do
			local region = select(i, ArchaeologyFrameSummaryPage:GetRegions())
			if (region:GetObjectType() == "FontString") then
				region:SetTextColor(unpack(C["value"]))
			end
		end

		local backdrop = gUI:SetUITemplate(CreateFrame("Frame", nil, ArchaeologyFrameArtifactPage), "itembackdrop", ArchaeologyFrameArtifactPageIcon)
		ArchaeologyFrameArtifactPageIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		ArchaeologyFrameArtifactPageIcon:SetParent(backdrop)
		ArchaeologyFrameArtifactPageIcon:SetDrawLayer("OVERLAY")
			
		for i=1, ARCHAEOLOGY_MAX_COMPLETED_SHOWN do
			local artifact = _G["ArchaeologyFrameCompletedPageArtifact" .. i]
			
			if (artifact) then
				local icon = _G[artifact:GetName() .. "Icon"]
				local bg = _G[artifact:GetName() .. "Bg"]
				local border = _G[artifact:GetName() .. "Border"]
				local name = _G[artifact:GetName() .. "ArtifactName"]
				local subtext = _G[artifact:GetName() .. "ArtifactSubText"]
				
				-- gUI:DisableTextures(artifact)
				gUI:KillObject(bg)
				gUI:KillObject(border)

				local BackdropHolder = CreateFrame("Frame", nil, artifact)
				BackdropHolder:SetFrameLevel(artifact:GetFrameLevel() - 1)
				BackdropHolder:SetAllPoints(icon)

				icon.backdrop = gUI:SetUITemplate(BackdropHolder, "border")
				icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
				icon:SetDrawLayer("OVERLAY")
				icon:SetParent(icon.backdrop)
				gUI:SetUITemplate(icon.backdrop, "gloss", icon)
				gUI:SetUITemplate(icon.backdrop, "shade", icon)
				
				name:SetTextColor(unpack(C["value"]))
				subtext:SetTextColor(0.6, 0.6, 0.6)
			end
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end