--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("GuildRegistrar")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Guild Registrar"])
	self:SetAttribute("description", L["The guild registrar interface where you buy petitions and create new guilds"])
	
	local func = function()
		gUI:DisableTextures(GuildRegistrarFrame)
		gUI:DisableTextures(GuildRegistrarFrameInset)
		gUI:DisableTextures(GuildRegistrarGreetingFrame)

		gUI:KillObject(GuildRegistrarFramePortrait)
		
		gUI:SetUITemplate(GuildRegistrarFrame, "backdrop", nil, 18, 12, 64, 34)
		gUI:SetUITemplate(GuildRegistrarFrameCloseButton, "closebutton")
		gUI:SetUITemplate(GuildRegistrarFrameGoodbyeButton, "button", true)
		gUI:SetUITemplate(GuildRegistrarFrameCancelButton, "button", true)
		gUI:SetUITemplate(GuildRegistrarFramePurchaseButton, "button", true)
		gUI:SetUITemplate(GuildRegistrarFrameEditBox, "editbox", -4, 0, 4, 0)
		
		GuildRegistrarFrameEditBox:DisableDrawLayer("BACKGROUND") -- take THAT you damn border textures!!
		
		GuildRegistrarText:SetFontObject(gUI_TextFontSmall)
		GuildRegistrarButton1:SetNormalFontObject(gUI_TextFontSmall)
		GuildRegistrarButton2:SetNormalFontObject(gUI_TextFontSmall)
		
		GuildRegistrarText:SetTextColor(unpack(C["index"]))
		GuildRegistrarPurchaseText:SetTextColor(unpack(C["index"]))
		AvailableServicesText:SetTextColor(unpack(C["value"]))
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end