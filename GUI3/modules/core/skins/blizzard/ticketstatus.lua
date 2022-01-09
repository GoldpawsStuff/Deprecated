--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("TicketStatusFrameButton")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Ticket Status"])
	self:SetAttribute("description", L["The ticket status button for active support tickets"])
	
	local func = function()
		gUI:DisableTextures(TicketStatusFrameButton)
		gUI:SetUITemplate(TicketStatusFrameButton, "button", true)
		-- TicketStatusTitleText:SetFontObject(gUI_TextFontSmall)	
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end