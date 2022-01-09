--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("GhostFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Ghost"])
	self:SetAttribute("description", L["The button returning you to a graveyard as a ghost"])
		
	local func = function()
		gUI:DisableTextures(GhostFrame)
		gUI:KillObject(GhostFrameLeft)
		gUI:KillObject(GhostFrameMiddle)
		gUI:KillObject(GhostFrameRight)
		gUI:SetUITemplate(GhostFrame, "backdrop")

		local iconBackdrop = CreateFrame("Frame", nil, GhostFrameContentsFrame)
		iconBackdrop:SetAllPoints(GhostFrameContentsFrameIcon)
		gUI:SetUITemplate(iconBackdrop, "outerbackdrop", GhostFrameContentsFrameIcon)
		-- iconBackdrop:SetUITemplate("thinborder")

		local highlight = GhostFrame:CreateTexture()
		highlight:SetTexture(1, 1, 1, 2/10)
		highlight:SetPoint("TOPLEFT", 3, -3)
		highlight:SetPoint("BOTTOMRIGHT", -3, 3)
		highlight:SetDrawLayer("OVERLAY", -1)
		GhostFrame:SetHighlightTexture(highlight)

		GhostFrameContentsFrame:SetPoint("TOPLEFT", 0, 0)
		GhostFrameContentsFrame.SetPoint = noop
		-- GhostFrameContentsFrameText:SetFontObject(gUI_TextFontSmallWhiteOutline)
		GhostFrameContentsFrameText:SetTextColor(1, 1, 1)
		GhostFrameContentsFrameIcon:SetParent(iconBackdrop)
		GhostFrameContentsFrameIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		GhostFrameContentsFrameIcon:SetDrawLayer("OVERLAY", 1)
		GhostFrameContentsFrameIcon:ClearAllPoints()
		GhostFrameContentsFrameIcon:SetPoint("TOPLEFT", GhostFrame, "TOPLEFT", 9, -9)
		GhostFrameContentsFrameIcon:SetSize(GhostFrameContentsFrameIcon:GetWidth() - 9, GhostFrameContentsFrameIcon:GetHeight() - 9)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end