--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("TaxiFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Taxi"])
	self:SetAttribute("description", L["The flight map when talking to flight masters"])
	
	local func = function()
		gUI:DisableTextures(TaxiFrame, TaxiFrame.InsetBg)
		gUI:SetUITemplate(TaxiFrame, "outerbackdrop", nil, 0, 0, 0, 2)
		gUI:SetUITemplate(TaxiFrame.CloseButton, "closebutton")

		local border = CreateFrame("Frame", nil, TaxiFrame)
		gUI:SetUITemplate(border, "border")
		border:SetAllPoints(TaxiRouteMap)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end