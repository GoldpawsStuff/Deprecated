--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_ItemAlterationUI")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Transmogrification UI"])
	self:SetAttribute("description", L["The item transmogrification window where you style your items to look like other items"])
	
	local slots = { "Head", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet", "MainHand", "SecondaryHand" }
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(TransmogrifyFrame) 
		gUI:DisableTextures(TransmogrifyArtFrame) 
		gUI:DisableTextures(TransmogrifyModelFrame)
		gUI:DisableTextures(TransmogrifyFrameButtonFrame)
		gUI:DisableTextures(TransmogrifyMoneyFrame)
	
		gUI:SetUITemplate(TransmogrifyApplyButton, "button", true)
		gUI:SetUITemplate(TransmogrifyArtFrameCloseButton, "closebutton", "TOPRIGHT", -4, -4)
		gUI:SetUITemplate(TransmogrifyFrame, "backdrop")
		gUI:SetUITemplate(TransmogrifyModelFrame, "outerbackdrop"):SetBackdropColor(r, g, b, panelAlpha)
		
		for i,v in pairs(slots) do
			local button = _G["TransmogrifyFrame" .. v .. "Slot"]
			gUI:HideTexture(_G[button:GetName() .. "Grabber"])
			gABT:GetStyleFunction()(button)
			local overlay = CreateFrame("Frame", nil, button)
			overlay:SetAllPoints()
			
			local gloss = gUI:SetUITemplate(overlay, "gloss")
			gloss:ClearAllPoints()
			gloss:SetPoint("TOPLEFT", 3, -3)
			gloss:SetPoint("BOTTOMRIGHT", -3, 3)
			gloss:Hide()
			
			button.Gloss = gloss
			
			local shade = gUI:SetUITemplate(overlay, "shade")
			shade:ClearAllPoints()
			shade:SetPoint("TOPLEFT", 3, -3)
			shade:SetPoint("BOTTOMRIGHT", -3, 3)
		end
		
		local UpdateSlotButton = function(button)
			local isTransmogrified, canTransmogrify, cannotTransmogrifyReason, hasPending, hasUndo, visibleItemID, textureName = GetTransmogrifySlotInfo(button.id)
			local hasChange = hasPending or hasUndo
			
			-- *we keep the icons of equipped items saturated at all times
			-- *transmogrified items are indicated by their border
			-- *empty slots (no equipped items) have no gloss
			if (isTransmogrified) or (canTransmogrify) then
				button.Gloss:Show()
				button.icon:SetDesaturated(false)
			else
				button.Gloss:Hide()
				button.icon:SetDesaturated(true)
			end
		end
		hooksecurefunc("TransmogrifyFrame_UpdateSlotButton", UpdateSlotButton)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end