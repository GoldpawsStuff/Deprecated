--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_DebugTools")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")
	
	self:SetAttribute("name", L["Debug Tools"])
	self:SetAttribute("description", L["Debug tools such as the /framestack or /eventtrace frames"])

	local func = function()
		gUI:DisableTextures(EventTraceFrame)
		gUI:DisableTextures(ScriptErrorsFrame)
		
		gUI:SetUITemplate(EventTraceFrame, "backdrop")
		gUI:SetUITemplate(ScriptErrorsFrame, "backdrop")
		gUI:SetUITemplate(ScriptErrorsFrameClose, "closebutton")
		gUI:SetUITemplate(EventTraceFrameCloseButton, "closebutton")
		gUI:SetUITemplate(ScriptErrorsFrameScrollFrameScrollBar, "scrollbar")
		
		for i = 1, ScriptErrorsFrame:GetNumChildren() do
			local button = select(i, ScriptErrorsFrame:GetChildren())
			if (button:GetObjectType() == "Button") and not(button.GetName and button:GetName()) then
				gUI:SetUITemplate(button, "button", true)
			end
		end	
		
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end