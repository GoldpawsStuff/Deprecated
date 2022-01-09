--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_InspectUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Inspect UI"])
	self:SetAttribute("description", L["The window where you inspect another player's gear, talents and PvP teams"])
	
	local func = function()
		local gearSlots = { "BackSlot", "ChestSlot", "HandsSlot", "HeadSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "LegsSlot", "MainHandSlot", "NeckSlot", "SecondaryHandSlot", "ShirtSlot", "ShoulderSlot", "TabardSlot", "Trinket0Slot", "Trinket1Slot", "WaistSlot", "WristSlot" }
		
		gUI:DisableTextures(InspectFrame)
		gUI:DisableTextures(InspectFrameInset)
		gUI:DisableTextures(InspectModelFrame)
		
		if (InspectPVPTeam1) then gUI:DisableTextures(InspectPVPTeam1) end
		if (InspectPVPTeam2) then gUI:DisableTextures(InspectPVPTeam2) end
		if (InspectPVPTeam3) then gUI:DisableTextures(InspectPVPTeam3) end
		if (InspectPVPFrameBottom) then gUI:HideTexture(InspectPVPFrameBottom) end
		gUI:HideTexture(InspectGuildFrameBG)
		
		gUI:KillObject(InspectFramePortrait)
		if (InspectPVPFrameBG) then gUI:KillObject(InspectPVPFrameBG) end

		gUI:SetUITemplate(InspectFrameCloseButton, "closebutton")
		gUI:SetUITemplate(InspectFrame, "backdrop")
		gUI:SetUITemplate(InspectModelFrame, "backdrop")
		gUI:SetUITemplate(InspectTalentFrame, "backdrop")
		gUI:SetUITemplate(InspectFrameTab1, "tab")
		gUI:SetUITemplate(InspectFrameTab2, "tab")
		gUI:SetUITemplate(InspectFrameTab3, "tab")
		gUI:SetUITemplate(InspectFrameTab4, "tab")

		for i,v in pairs(gearSlots) do
			gABT:GetStyleFunction()(_G["Inspect" .. v])
		end
		
		local ugly = select(7, InspectMainHandSlot:GetRegions())
		gUI:HideTexture(ugly)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end