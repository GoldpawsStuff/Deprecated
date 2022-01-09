--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_BarbershopUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Barber Shop"])
	self:SetAttribute("description", L["The Barber Shop Interface, where you change your hair, facial hair and markings."])
	
	local func = function()
		gUI:DisableTextures(BarberShopFrame)
		gUI:HideTexture(BarberShopFrameBackground)
		gUI:HideTexture(BarberShopAltFormFrameBackground)
		gUI:DisableTextures(BarberShopAltFormFrameBorder)
		gUI:DisableTextures(BarberShopFrameMoneyFrame)
		-- gUI:DisableTextures(BarberShopBannerFrame)
		-- gUI:DisableTextures(BarberShopBannerFrameBGTexture)
		gUI:DisableTextures(BarberShopFrameOkayButton)
		gUI:DisableTextures(BarberShopFrameCancelButton)
		gUI:DisableTextures(BarberShopFrameResetButton)

		gUI:SetUITemplate(BarberShopFrameOkayButton, "button", true)
		gUI:SetUITemplate(BarberShopFrameCancelButton, "button", true)
		gUI:SetUITemplate(BarberShopFrameResetButton, "button", true)
		
		gUI:SetUITemplate(BarberShopFrame, "outerbackdrop", nil, 32, 32, 32, 32)
		gUI:SetUITemplate(BarberShopAltFormFrame, "outerbackdrop", nil, -3, -2, -4, -3)
		
		for i = 1, 4 do
			local selector = _G["BarberShopFrameSelector" .. i]
			if (selector) then
				gUI:DisableTextures(selector)
				gUI:SetUITemplate(_G["BarberShopFrameSelector" .. i .. "Prev"], "arrow", "left")
				gUI:SetUITemplate(_G["BarberShopFrameSelector" .. i .. "Next"], "arrow", "right")
			end
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end