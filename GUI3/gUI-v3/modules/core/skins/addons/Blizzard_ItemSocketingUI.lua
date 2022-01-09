--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_ItemSocketingUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Socketing UI"])
	self:SetAttribute("description", L["The item socketing UI where you add or remove gems from your gear"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(ItemSocketingFrame)
		gUI:DisableTextures(ItemSocketingFrameInset)
		gUI:DisableTextures(ItemSocketingScrollFrame)

		gUI:KillObject(ItemSocketingFramePortrait)
		
		gUI:SetUITemplate(ItemSocketingSocketButton, "button", true)
		gUI:SetUITemplate(ItemSocketingFrameCloseButton, "closebutton", "TOPRIGHT", -4, -4)
		gUI:SetUITemplate(ItemSocketingFrame, "backdrop")
		gUI:SetUITemplate(ItemSocketingScrollFrame, "outerbackdrop", nil, -2, 0, -3, 0):SetBackdropColor(r, g, b, panelAlpha)
		gUI:SetUITemplate(ItemSocketingScrollFrameScrollBar, "scrollbar")
		
		for i = 1, MAX_NUM_SOCKETS do
			local button = _G["ItemSocketingSocket"..i]
			local icon = _G["ItemSocketingSocket"..i.."IconTexture"]
			
			gUI:DisableTextures(_G["ItemSocketingSocket"..i.."BracketFrame"])
			gUI:HideTexture(_G["ItemSocketingSocket"..i.."Background"])
			gUI:HideTexture(_G["ItemSocketingSocket"..i.."Right"])
			gUI:HideTexture(_G["ItemSocketingSocket"..i.."Left"])
			gABT:GetStyleFunction()(button)

			local updateFunc = function(self)
				local color = GEM_TYPE_INFO[GetSocketTypes(i)]
				button:SetBackdropColor(color.r, color.g, color.b, 15/100)
				button:SetBackdropBorderColor(color.r, color.g, color.b)
			end
			hooksecurefunc("ItemSocketingFrame_Update", updateFunc)
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end