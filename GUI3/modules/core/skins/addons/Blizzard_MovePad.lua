--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_MovePad")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["MovePad"])
	self:SetAttribute("description", L["The movepad which allows you to move and jump with your mouse"])
	
	local func = function()
		gUI:SetUITemplate(MovePadFrame, "backdrop")
		
		local buttons = {
			"MovePadStrafeLeft";
			"MovePadStrafeRight";
			"MovePadForward";
			"MovePadBackward";
			"MovePadJump";
		}
		local t, bName, b, i, _
		for _,bName in pairs(buttons) do
			b = _G[bName]
			i = _G[bName .. "Icon"]
			t = i:GetTexture()
			
			gUI:SetUITemplate(b, "button")
			gUI:CreateHighlight(b)
			gUI:CreatePushed(b)
			
			if (b.SetCheckedTexture) then
				gUI:CreateChecked(b)
			end

			i:SetTexture(t)
			i:SetParent(b)
			i:SetDrawLayer("OVERLAY")
		end
		
		local first = MovePadLock:GetRegions()
		gUI:HideTexture(first)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end