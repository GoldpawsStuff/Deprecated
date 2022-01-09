--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("AutoCompleteBox")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Autocomplete"])
	self:SetAttribute("description", L["The autocomplete box that pops up when you send mail, invite people to a group etc."])
	
	local func = function()
		gUI:SetUITemplate(AutoCompleteBox, "backdrop")
		
		-- sometimes text will appear above it, 
		-- so we're increasing its strata above other frames, 
		-- but still below tooltips and dialogs
		AutoCompleteBox:SetFrameStrata("HIGH")
		AutoCompleteBox:HookScript("OnShow", function(self) self:SetFrameStrata("HIGH") end)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end