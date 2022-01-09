--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("StaticPopup")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Popups"])
	self:SetAttribute("description", L["The popup windows with yes/no or other queries"])
	
	local func = function()
		local a = gUI:GetOverlayAlpha() 
		local r, g, b = unpack(C["overlay"])
		for i = 1,4 do
			gUI:SetUITemplate(_G["StaticPopup" .. i], "backdrop")
			gUI:SetUITemplate(_G["StaticPopup" .. i .. "CloseButton"], "closebutton")
			gUI:SetUITemplate(_G["StaticPopup" .. i .. "EditBox"], "editbox", -3, 0, 3, 0):SetBackdropColor(r, g, b, a)
			gUI:SetUITemplate(_G["StaticPopup" .. i .. "MoneyInputFrameGold"], "editbox"):SetBackdropColor(r, g, b, a)
			gUI:SetUITemplate(_G["StaticPopup" .. i .. "MoneyInputFrameSilver"], "editbox"):SetBackdropColor(r, g, b, a)
			gUI:SetUITemplate(_G["StaticPopup" .. i .. "MoneyInputFrameCopper"], "editbox"):SetBackdropColor(r, g, b, a)
			
			gUI:KillObject(_G["StaticPopup" .. i .. "MoneyInputFrameCopperRight"])
			gUI:KillObject(_G["StaticPopup" .. i .. "MoneyInputFrameCopperLeft"])
			gUI:KillObject(_G["StaticPopup" .. i .. "MoneyInputFrameCopperMiddle"])
			
			
			gABT:GetStyleFunction()(_G["StaticPopup" .. i .. "ItemFrame"])
			_G["StaticPopup" .. i .. "ItemFrameNameFrame"]:SetSize(1/1e4, 1/1e4)

			for j = 1,3 do
				gUI:SetUITemplate(_G["StaticPopup" .. i .. "Button" .. j], "button", true)
			end
		end
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end