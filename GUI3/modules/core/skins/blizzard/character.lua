--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local WoW51 = (select(4, GetBuildInfo())) >= 50100
local style = gUI:GetModule("Styling"):NewModule("Character")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Character"])
	self:SetAttribute("description", L["The window where you see your currently equipped gear, set your title and manage your equipment sets."])
	
	local gearSlots = {
		"BackSlot";
		"ChestSlot";
		"HandsSlot";
		"HeadSlot";
		"FeetSlot";
		"Finger0Slot";
		"Finger1Slot";
		"LegsSlot";
		"MainHandSlot";
		"NeckSlot";
		-- "RangedSlot";
		"SecondaryHandSlot";
		"ShirtSlot";
		"ShoulderSlot";
		"TabardSlot";
		"Trinket0Slot";
		"Trinket1Slot";
		"WaistSlot";
		"WristSlot";
	}
	local func = function()
		local EquipmentFlyoutFrameButtonName = "EquipmentFlyoutFrameButton"
		
		gUI:KillObject(CharacterFramePortrait)
		
		gUI:DisableTextures(CharacterFrame)
		gUI:DisableTextures(CharacterFrameInset)
		gUI:DisableTextures(CharacterFrameInsetRight)
		gUI:DisableTextures(CharacterModelFrame)
		gUI:DisableTextures(CharacterStatsPane)
		gUI:DisableTextures(CharacterStatsPaneCategory1)
		gUI:DisableTextures(CharacterStatsPaneCategory2)
		gUI:DisableTextures(CharacterStatsPaneCategory3)
		gUI:DisableTextures(CharacterStatsPaneCategory4)
		gUI:DisableTextures(CharacterStatsPaneCategory5)
		gUI:DisableTextures(CharacterStatsPaneCategory6)
		gUI:DisableTextures(CharacterStatsPaneCategory7)
		gUI:DisableTextures(GearManagerDialogPopup)
		gUI:DisableTextures(GearManagerDialogPopupScrollFrame)
		gUI:DisableTextures(ReputationListScrollFrame)
		gUI:DisableTextures(PaperDollEquipmentManagerPane) 
		gUI:DisableTextures(EquipmentFlyoutFrame)  
		gUI:DisableTextures(PaperDollSidebarTabs) 
		gUI:DisableTextures(ReputationDetailFrame)
		gUI:DisableTextures(ReputationFrame)
		gUI:DisableTextures(ReputationListScrollFrame)
		gUI:DisableTextures(TokenFramePopup)
		gUI:DisableTextures(GearManagerDialogPopupCancel)
		gUI:DisableTextures(GearManagerDialogPopupOkay)
		gUI:DisableTextures(PaperDollEquipmentManagerPaneEquipSet)
		gUI:DisableTextures(PaperDollEquipmentManagerPaneSaveSet)

		gUI:SetUITemplate(CharacterFrameExpandButton, "arrow")
		gUI:SetUITemplate(PetModelFrameRotateLeftButton, "arrow", "left")
		gUI:SetUITemplate(PetModelFrameRotateRightButton, "arrow", "right")
		gUI:SetUITemplate(GearManagerDialogPopupCancel, "button")
		gUI:SetUITemplate(GearManagerDialogPopupOkay, "button")
		gUI:SetUITemplate(PaperDollEquipmentManagerPaneEquipSet, "button") 
		gUI:SetUITemplate(PaperDollEquipmentManagerPaneSaveSet, "button") 
		gUI:SetUITemplate(ReputationDetailInactiveCheckBox, "checkbutton")
		gUI:SetUITemplate(ReputationDetailAtWarCheckBox, "checkbutton")
		gUI:SetUITemplate(ReputationDetailMainScreenCheckBox, "checkbutton")
		gUI:SetUITemplate(TokenFramePopupInactiveCheckBox, "checkbutton")
		gUI:SetUITemplate(TokenFramePopupBackpackCheckBox, "checkbutton")
		gUI:SetUITemplate(CharacterFrameCloseButton, "closebutton")
		gUI:SetUITemplate(ReputationDetailCloseButton, "closebutton")
		gUI:SetUITemplate(TokenFramePopupCloseButton, "closebutton")
		gUI:SetUITemplate(GearManagerDialogPopupEditBox, "editbox")
		-- gUI:SetUITemplate(CharacterFrame, "outerbackdrop", nil, -6, 0, 6, 0)
		gUI:SetUITemplate(CharacterFrame, "backdrop")
		gUI:SetUITemplate(CharacterModelFrame, "outerbackdrop", nil, -3, 3, 3, -3):SetBackdropColor(0, 0, 0, 1/5)
		gUI:SetUITemplate(TokenFramePopup, "backdrop")
		gUI:SetUITemplate(GearManagerDialogPopup, "backdrop")
		gUI:SetUITemplate(ReputationDetailFrame, "backdrop")
		gUI:SetUITemplate(TokenFramePopup, "backdrop")
		gUI:SetUITemplate(PetModelFrame, "backdrop")
		gUI:SetUITemplate(ChannelRosterScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(CharacterStatsPaneScrollBar, "scrollbar")
		gUI:SetUITemplate(GearManagerDialogPopupScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(PaperDollTitlesPaneScrollBar, "scrollbar") 
		gUI:SetUITemplate(PaperDollEquipmentManagerPaneScrollBar, "scrollbar") 
		gUI:SetUITemplate(ReputationListScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(TokenFrameContainerScrollBar, "scrollbar")
		gUI:SetUITemplate(CharacterFrameTab1, "tab")
		gUI:SetUITemplate(CharacterFrameTab2, "tab")
		gUI:SetUITemplate(CharacterFrameTab3, "tab")
		gUI:SetUITemplate(CharacterFrameTab4, "tab")

		if not(WoW51) then
			gUI:SetUITemplate(PetPaperDollFrameExpBar, "statusbar", true)
		end
		
		local FlyOutBackdrop = CreateFrame("Frame", nil, EquipmentFlyoutFrame)
		FlyOutBackdrop:SetPoint("TOPLEFT", EquipmentFlyoutFrameButtons, "TOPLEFT", 0, 0)
		FlyOutBackdrop:SetPoint("BOTTOMRIGHT", EquipmentFlyoutFrameButtons, "BOTTOMRIGHT", 2, 0)
		gUI:SetUITemplate(FlyOutBackdrop, "outerbackdrop"):SetBackdropBorderColor(unpack(C["value"]))

		for i = 1, NUM_GEARSET_ICONS_SHOWN do
			local button = _G["GearManagerDialogPopupButton" .. i]
			-- gUI:DisableTextures(button)
			local slot = select(2, button:GetRegions())
			gUI:KillObject(slot)
			gABT:GetStyleFunction()(button)
		end

		for i,v in pairs(gearSlots) do
			local button = _G["Character" .. v]
			
			-- a pain to skin, so I'll skip it for now
			-- the easiest thing would be to make a new texture that
			-- matches the texcoords of the original one, but without the borders
			-- check EquipmentFlyout.lua#484 in the function "EquipmentFlyoutPopoutButton_SetReversed"
			local arrow = _G["Character" .. v .. "PopoutButton"] 
			
			-- need to manually strip the textures, as the ignoreTexture hasn't got a name to whitelist
			for w = 1, button:GetNumRegions() do
				local region = select(w, button:GetRegions())
				if (region) and (region:GetObjectType() == "Texture") and not(region:GetName()) and not(region == button.ignoreTexture) then
					gUI:HideTexture(region)
				end
			end
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
			
			local Durability = button:CreateFontString(button:GetName() .. "Durability")
			Durability:SetJustifyH("CENTER")
			Durability:SetJustifyV("MIDDLE")
			Durability:SetPoint("CENTER", button, "CENTER", 2, 0)
			Durability:SetFontObject(gUI_DisplayFontTinyOutlineWhite)
			Durability:Hide()
			
			button.Durability = Durability
		end

		for i = 1, NUM_FACTIONS_DISPLAYED do
			gUI:DisableTextures(_G["ReputationBar" .. i])
			gUI:SetUITemplate(_G["ReputationBar" .. i .. "ExpandOrCollapseButton"], "arrow")
			gUI:SetUITemplate(_G["ReputationBar" .. i .. "ReputationBar"], "statusbar", true)
			-- gUI:SetUITemplate(_G["ReputationBar" .. i .. "ReputationBar"], "gloss")
			_G["ReputationBar" .. i .. "ReputationBar"]:SetWidth(90) -- default is 101 and 99
			_G["ReputationBar" .. i .. "ReputationBar"].SetWidth = noop
			-- _G["ReputationBar" .. i .. "FactionName"]:SetFontObject(gUI_TextFontSmallWhite) 
			-- _G["ReputationBar" .. i .. "FactionName"].SetFontObject = noop
			_G["ReputationBar" .. i .. "ReputationBarFactionStanding"]:SetFontObject(gUI_TextFontTinyBoldOutlineWhite)
		end
		
		local UpdateCurrency = function()
			for i = 1, GetCurrencyListSize() do
				local currency = _G["TokenFrameContainerButton" .. i]
				if (currency) then
					gUI:HideTexture(currency.highlight)
					gUI:HideTexture(currency.categoryMiddle)
					gUI:HideTexture(currency.categoryLeft)
					gUI:HideTexture(currency.categoryRight)
					if (currency.icon) then
						currency.icon:SetTexCoord(2/25, 23/25, 2/25, 23/25)
					end
				end
			end
		end

		local UpdateEQList = function(self)
			for i, v in pairs(PaperDollEquipmentManagerPane.buttons) do
				v.BgTop:SetTexture("")
				v.BgBottom:SetTexture("")
				v.BgMiddle:SetTexture("")
				v.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
				v.icon:ClearAllPoints()
				v.icon:SetSize(v:GetHeight()-16, v:GetHeight()-16)
				v.icon:SetPoint("TOPLEFT", v, "TOPLEFT", 8, -8)
				v.icon:SetPoint("BOTTOMRIGHT", v, "BOTTOMLEFT", 8 + (v:GetHeight()-16), 8)
				if not(v.IconBackdrop) then
					local IconBackdrop = CreateFrame("Frame", nil, v)
					IconBackdrop:SetAllPoints(v.icon)
					gUI:SetUITemplate(IconBackdrop, "border")
					v.IconBackdrop = IconBackdrop
				end
			end
		end
		
		local patch, build, released, toc = GetBuildInfo()
		build = tonumber(build)
		
		-- patch 5.3 fix
		local EQUIPMENTFLYOUT_MAXITEMS = EQUIPMENTFLYOUT_MAXITEMS
		if (build >= 16837) then
			EQUIPMENTFLYOUT_MAXITEMS = EQUIPMENTFLYOUT_ITEMS_PER_PAGE
		end

		local UpdateFlyoutSlot = function(self)
			gUI:DisableTextures(EquipmentFlyoutFrameButtons)
			for i = 1, EQUIPMENTFLYOUT_MAXITEMS do
				local button = _G[EquipmentFlyoutFrameButtonName .. i]
				if (button) then 
					if not(button.gUISkinned) then
						-- gUI:DisableTextures(button)
						gABT:GetStyleFunction()(button)
						button.gUISkinned = true
					end
				end
			end
		end

		local UpdateGearSlot = function()
			for i, v in pairs(gearSlots) do

				local item = _G["Character" .. v]
				local slot = GetInventorySlotInfo(v)
				local itemID = GetInventoryItemID("player", slot)
				
				if (itemID) then
					local quality = (select(3, GetItemInfo(itemID)))
					local current, maximum = GetInventoryItemDurability(slot)
					
					if (quality) then
						local r, g, b, hex = GetItemQualityColor(quality)
						item:SetBackdropBorderColor(r, g, b)
					end
					
					if (maximum) and (maximum > 0) and (current < maximum) then -- only show for damaged items
						local r, g, b = F.GetDurabilityColor(current, maximum)
						item.Durability:SetText(("|cFF%s%d%%|r"):format(gUI:RGBToHex(r, g, b), (current or 0)/maximum * 100))
						item.Durability:Show()
					else
						item.Durability:Hide()
					end
					item.Gloss:Show()
				else
					item:SetBackdropBorderColor(unpack(C["border"]))
					item.Durability:Hide()
					item.Gloss:Hide()
				end
			end
		end
		
		local UpdateSideBar = function ()
			for i = 1, #PAPERDOLL_SIDEBARS do
				local button = _G["PaperDollSidebarTab"..i]
				if (button) then
					button.Highlight:SetTexture(1, 1, 1, 0.3)
					button.Highlight:ClearAllPoints()
					button.Highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
					button.Highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
					
					button.Hider:SetTexture(0, 0, 0, 0.6)
					button.Hider:ClearAllPoints()
					button.Hider:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
					button.Hider:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)

					button.TabBg:Hide()
					button.TabBg.Show = noop

					local border = gUI:SetUITemplate(button, "border")
					border:ClearAllPoints()
					border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
					border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
				end
			end
		end
		
		local UpdateTitlesList = function(self)
			for _, button in pairs(PaperDollTitlesPane.buttons) do
				button.BgTop:SetTexture("")
				button.BgBottom:SetTexture("")
				button.BgMiddle:SetTexture("")
			end
		end
		CharacterFrame:HookScript("OnShow", UpdateGearSlot)

		if (EquipmentFlyoutFrame) then
			EquipmentFlyoutFrame:HookScript("OnShow", UpdateFlyoutSlot)
			hooksecurefunc(EquipmentFlyoutFrame, "SetPoint", UpdateFlyoutSlot)
		end

		if (PaperDollEquipmentManagerPane) then PaperDollEquipmentManagerPane:HookScript("OnShow", UpdateEQList) end
		if (PaperDollTitlesPane) then PaperDollTitlesPane:HookScript("OnShow", UpdateTitlesList) end
		TokenFrame:HookScript("OnShow", UpdateCurrency)

		gUI:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", UpdateGearSlot)
		gUI:RegisterEvent("UPDATE_INVENTORY_DURABILITY", UpdateGearSlot)

		if (PaperDollFrame_UpdateSidebarTabs) then hooksecurefunc("PaperDollFrame_UpdateSidebarTabs", UpdateSideBar) end
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end