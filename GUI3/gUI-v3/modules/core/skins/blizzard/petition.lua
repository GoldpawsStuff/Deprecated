--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Petitions")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Petitions"])
	self:SetAttribute("description", L["Petition request such as Guild- and Arena charters"])
	
	local func = function()
		gUI:DisableTextures(PetitionFrame)
		gUI:DisableTextures(PetitionFrameInset)
		
		gUI:SetUITemplate(PetitionFrameCancelButton, "button", true)
		gUI:SetUITemplate(PetitionFrameRenameButton, "button", true)
		gUI:SetUITemplate(PetitionFrameRequestButton, "button", true)
		gUI:SetUITemplate(PetitionFrameSignButton, "button", true)
		gUI:SetUITemplate(PetitionFrameCloseButton, "closebutton", "TOPRIGHT", -4, -4)
		gUI:SetUITemplate(PetitionFrame, "backdrop")
		
		PetitionFrameCharterName:SetTextColor(unpack(C["index"]))
		PetitionFrameCharterTitle:SetTextColor(unpack(C["value"]))
		PetitionFrameInstructions:SetTextColor(unpack(C["index"]))
		PetitionFrameMasterName:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName1:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName2:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName3:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName4:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName5:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName6:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName7:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName8:SetTextColor(unpack(C["index"]))
		PetitionFrameMemberName9:SetTextColor(unpack(C["index"]))
		PetitionFrameMasterTitle:SetTextColor(unpack(C["value"]))
		PetitionFrameMemberTitle:SetTextColor(unpack(C["value"]))
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end