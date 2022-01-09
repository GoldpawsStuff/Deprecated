--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_LookingForGuildUI")
-- /run LoadAddOn("Blizzard_LookingForGuildUI")
style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Guild Finder UI"])
	self:SetAttribute("description", L["The window where you browser for guilds"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(LookingForGuildFrame)
		gUI:DisableTextures(LookingForGuildFrameInset)
		gUI:HideTexture(LookingForGuildBrowseButton_LeftSeparator)
		gUI:HideTexture(LookingForGuildRequestButton_RightSeparator)
		gUI:DisableTextures(GuildFinderRequestMembershipFrameInputFrame)
		gUI:DisableTextures(GuildFinderRequestMembershipFrame)
		gUI:DisableTextures(LookingForGuildFrameTab1)
		gUI:DisableTextures(LookingForGuildFrameTab2)
		gUI:DisableTextures(LookingForGuildFrameTab3)
		
		gUI:SetUITemplate(LookingForGuildBrowseButton, "button", true)
		gUI:SetUITemplate(LookingForGuildRequestButton, "button", true)
		gUI:SetUITemplate(GuildFinderRequestMembershipFrameAcceptButton, "button", true)
		gUI:SetUITemplate(GuildFinderRequestMembershipFrameCancelButton, "button", true)
		gUI:SetUITemplate(LookingForGuildQuestButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildDungeonButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildRaidButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildRPButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildPvPButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildWeekdaysButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildWeekendsButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildTankButton.checkButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildHealerButton.checkButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildDamagerButton.checkButton, "checkbutton")
		gUI:SetUITemplate(LookingForGuildFrameCloseButton, "closebutton")
		gUI:SetUITemplate(LookingForGuildFrame, "outerbackdrop", nil, -3, 0, 0, 0)
		gUI:SetUITemplate(LookingForGuildAvailabilityFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(LookingForGuildInterestFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(LookingForGuildRolesFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(LookingForGuildCommentFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(LookingForGuildAppsFrame, "outerbackdrop", nil, 4, 4, 2, 23):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(LookingForGuildBrowseFrame, "outerbackdrop", nil, 4, 4, 2, 23):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(LookingForGuildCommentInputFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildFinderRequestMembershipFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(GuildFinderRequestMembershipFrameInputFrame, "backdrop"):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(LookingForGuildAppsFrameContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(LookingForGuildBrowseFrameContainerScrollBar, "scrollbar")
		
		local makeHighlight = function(name, i, addSelectTexture)
			local button = _G[name .. i]
			button:SetBackdrop(nil)
			button.SetBackdrop = noop
			gUI:CreateHighlight(button)
			gUI:CreatePushed(button)
			local selected = button:GetRegions()
			if (addSelectTexture) and (selected) and (selected.GetObjectType) and (selected:GetObjectType() == "Texture") then
				selected:SetTexture(C.value[1], C.value[2], C.value[3], 1/4)
			end
		end
		for i = 1, 5 do
			makeHighlight("LookingForGuildBrowseFrameContainerButton", i, true)
			makeHighlight("LookingForGuildAppsFrameContainerButton", i)
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end