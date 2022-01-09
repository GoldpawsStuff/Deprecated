--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("WorldStateScoreFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Battleground Score"])
	self:SetAttribute("description", L["The Battleground score frame"])
	
	local func = function()
		local a = gUI:GetOverlayAlpha() 
		local r, g, b = unpack(C["overlay"])
		
		gUI:DisableTextures(WorldStateScoreFrame)
		gUI:DisableTextures(WorldStateScoreFrameInset)
		gUI:DisableTextures(WorldStateScoreScrollFrame)
		
		gUI:SetUITemplate(WorldStateScoreFrame, "backdrop")
		gUI:SetUITemplate(WorldStateScoreFrameInset, "backdrop"):SetBackdropColor(r, g, b, a)
		gUI:SetUITemplate(WorldStateScoreFrameLeaveButton, "button", true)
		gUI:SetUITemplate(WorldStateScoreFrameCloseButton, "closebutton")
		gUI:SetUITemplate(WorldStateScoreScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(WorldStateScoreFrameTab1, "tab", true)
		gUI:SetUITemplate(WorldStateScoreFrameTab2, "tab", true)
		gUI:SetUITemplate(WorldStateScoreFrameTab3, "tab", true)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end