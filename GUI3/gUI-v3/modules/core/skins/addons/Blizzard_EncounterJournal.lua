--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

-- weird bugs in 5.3
if tonumber((select(2, GetBuildInfo()))) >= 16837 then return end

local style = gUI:GetModule("Styling"):NewModule("Blizzard_EncounterJournal")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")
	
	self:SetAttribute("name", L["Dungeon Journal"])
	self:SetAttribute("description", L["Instance descriptions, boss abilities and loot tables"])
	
	local func = function()
		local panelAlpha, r, g, b = 1/5, unpack(C["overlay"])
		
		gUI:DisableTextures(EncounterJournal)
		gUI:DisableTextures(EncounterJournalEncounterFrame)
		gUI:DisableTextures(EncounterJournalEncounterFrameInfo)
		gUI:DisableTextures(EncounterJournalInset)
		gUI:DisableTextures(EncounterJournalInstanceSelect)
		gUI:DisableTextures(EncounterJournalNavBar)
		gUI:DisableTextures(EncounterJournalNavBarOverlay)

		gUI:SetUITemplate(EncounterJournal, "backdrop")
		-- gUI:SetUITemplate(EncounterJournalEncounterFrameInfoLootScrollFrameClassFilterFrame, "backdrop")

		-- gUI:SetUITemplate(EncounterJournalEncounterFrameInfoLootScrollFrameFilter, "button", true)
		gUI:SetUITemplate(EncounterJournalEncounterFrameInfoLootScrollFrameFilterToggle, "button", true)
		gUI:SetUITemplate(EncounterJournalEncounterFrameInfoDifficulty, "button", true)
		gUI:SetUITemplate(EncounterJournalEncounterFrameInfoResetButton, "button")
		gUI:SetUITemplate(EncounterJournalNavBarHomeButton, "insetbutton")
		gUI:SetUITemplate(EncounterJournalCloseButton, "closebutton")
		gUI:SetUITemplate(EncounterJournalSearchBox, "editbox"):SetBackdropColor(r, g, b, panelAlpha)

		gUI:SetUITemplate(EncounterJournalInstanceSelectScrollDownButton, "arrow", "down")
		
		gUI:SetUITemplate(EncounterJournalInstanceSelectScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(EncounterJournalEncounterFrameInstanceFrameLoreScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(EncounterJournalEncounterFrameInfoDetailsScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(EncounterJournalEncounterFrameInfoLootScrollFrameScrollBar, "scrollbar")
		
		gUI:SetUITemplate(EncounterJournalInstanceSelectDungeonTab, "tab", true)
		gUI:SetUITemplate(EncounterJournalInstanceSelectRaidTab, "tab", true)
		
		gUI:SetUITemplate(EncounterJournalEncounterFrameInstanceFrame, "outerbackdrop", EncounterJournalEncounterFrameInstanceFrameBG)

		EncounterJournalEncounterFrameInstanceFrameBG:SetTexCoord(0.7617187/10, 0.7617187*9/10, 0.65625*1.5/10, 0.65625*8.5/10)
		EncounterJournalEncounterFrameInstanceFrameBG:SetSize(325, 280)
		EncounterJournalEncounterFrameInstanceFrameBG:SetPoint("TOP", 3, -22)
		
		EncounterJournalEncounterFrameInstanceFrameTitle:SetPoint("TOP", 0, -50)
		EncounterJournalEncounterFrameInstanceFrameTitleBG:SetPoint("TOP", 0, -21)
	
		EncounterJournalEncounterFrameInstanceFrameMapButton:SetPoint("BOTTOMLEFT", 40, 126)
		gUI:SetUITemplate(EncounterJournalEncounterFrameInstanceFrameMapButton, "button")
		
		EncounterJournalEncounterFrameInstanceFrameMapButtonTexture:SetTexCoord(0.125+0.875*1.5/10, 0.875*8.5/10, 0.0+0.5*1.5/10, 0.5*8.5/10)
		EncounterJournalEncounterFrameInstanceFrameMapButtonTexture:ClearAllPoints()
		EncounterJournalEncounterFrameInstanceFrameMapButtonTexture:SetPoint("TOPLEFT", 3, -3)
		EncounterJournalEncounterFrameInstanceFrameMapButtonTexture:SetPoint("BOTTOMRIGHT", -3, 3)
		
		EncounterJournalEncounterFrameInstanceFrameMapButton:SetScript("OnMouseDown", function(self)
			self.texture:SetTexCoord(0.125+0.875*1.7/10, 0.875*8.3/10, 0.5+0.5*1.7/10, 1.0*8.3/10)
		end)
		
		EncounterJournalEncounterFrameInstanceFrameMapButton:SetScript("OnMouseUp", function(self)
			self.texture:SetTexCoord(0.125+0.875*1.7/10, 0.875*8.3/10, 0.0+0.5*1.7/10, 0.5*8.3/10)
		end)

		gUI:KillObject(EncounterJournalEncounterFrameInstanceFrameMapButtonShadow)
		gUI:KillObject(EncounterJournalEncounterFrameInstanceFrameMapButtonHighlight)
		
		local fixTab = function(self)
			gUI:SetUITemplate(self, "outerbackdrop", nil, 11, 11, 11, 11)
			
			self:SetNormalTexture("")
			self:SetPushedTexture("")
			self:SetDisabledTexture("")
			
			self.SetNormalTexture = noop
			self.SetPushedTexture = noop
			self.SetDisabledTexture = noop

			gUI:CreateHighlight(self, -11, 11, 11, -11)
		end

		fixTab(EncounterJournalEncounterFrameInfoBossTab)
		fixTab(EncounterJournalEncounterFrameInfoLootTab)
		
		EncounterJournalEncounterFrameInfoBossTab:ClearAllPoints()
		EncounterJournalEncounterFrameInfoBossTab:SetPoint("TOPLEFT", EncounterJournal, "TOPRIGHT", -6, -35)

		EncounterJournalEncounterFrameInstanceFrameLoreScrollFrameScrollChildLore:SetTextColor(unpack(C["index"]))
		EncounterJournalEncounterFrameInfoDetailsScrollFrameScrollChildDescription:SetTextColor(unpack(C["index"]))
		
		gUI:DisableTextures(EncounterJournalEncounterFrameModelFrame)
		
		EncounterJournalEncounterFrameInfoDungeonBG:ClearAllPoints()
		EncounterJournalEncounterFrameInfoDungeonBG:SetAllPoints(EncounterJournalEncounterFrameModelFrame)
		EncounterJournalEncounterFrameInfoDungeonBG:SetParent(EncounterJournalEncounterFrameModelFrame)
		gUI:SetUITemplate(EncounterJournalEncounterFrameModelFrame, "outerbackdrop")
		EncounterJournalEncounterFrameInfoDungeonBG:SetTexCoord(0+0.76953125*1.7/10, 0.76953125*8.3/10, 0.0+0.830078125*1.7/10, 0.830078125*8.3/10)

		local updateBossList = function()
			local bossIndex = 1
			local name, description, bossID, _, link = EJ_GetEncounterInfoByIndex(bossIndex)
			local bossButton
			while bossID do
				bossButton = _G["EncounterJournalBossButton"..bossIndex]
				if not(bossButton) then
					return
				end
				
				gUI:SetUITemplate(bossButton, "button")
				
				if not(bossButton.overlayHolder) then
					bossButton.overlayHolder = CreateFrame("Frame", nil, bossButton)
					bossButton.overlayHolder:SetAllPoints()
				end
				
				bossButton.creature:ClearAllPoints()
				bossButton.creature:SetPoint("BOTTOMLEFT", bossButton.overlayHolder, "BOTTOMLEFT", 3, 3)
				bossButton.creature:SetParent(bossButton.overlayHolder)
				
				local w, h = bossButton.creature:GetSize()
				bossButton.creature:SetTexCoord(0, 1, 0, (h-2)/h)
				
				bossIndex = bossIndex + 1
				name, description, bossID, _, link = EJ_GetEncounterInfoByIndex(bossIndex)
			end
		end
		hooksecurefunc("EncounterJournal_DisplayInstance", updateBossList)
		updateBossList()
		
		local updateSpellList = function()
			local usedHeaders = EncounterJournal.encounter.usedHeaders
			
			for _,infoHeader in pairs(usedHeaders) do
				local texture = infoHeader.button.abilityIcon:GetTexture()
				
				if not(infoHeader.runOnce) then
					gUI:DisableTextures(infoHeader)
					
					gUI:SetUITemplate(infoHeader.button, "button", true)
					infoHeader.button.overlayFrame = CreateFrame("Frame", nil, infoHeader.button)
					
					infoHeader.button.expandedIcon:SetParent(infoHeader.button.overlayFrame)
					infoHeader.button.icon1:SetParent(infoHeader.button.overlayFrame)
					infoHeader.button.icon2:SetParent(infoHeader.button.overlayFrame)
					infoHeader.button.icon3:SetParent(infoHeader.button.overlayFrame)
					infoHeader.button.icon4:SetParent(infoHeader.button.overlayFrame)
					infoHeader.button.portrait:SetParent(infoHeader.button.overlayFrame)
					
					infoHeader.button.abilityIcon:SetParent(infoHeader.button.overlayFrame)
					infoHeader.button.abilityIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
					infoHeader.button.abilityIcon:SetDrawLayer("OVERLAY")
					infoHeader.button.abilityIcon:SetTexture(texture)
--					infoHeader.button.abilityIcon:SetWidth(infoHeader.button.abilityIcon:GetWidth() - 4)
--					infoHeader.button.abilityIcon:SetHeight(infoHeader.button.abilityIcon:GetHeight() - 4)
					
					infoHeader.description:SetTextColor(unpack(C["value"]))
					
					infoHeader.runOnce = true
				end
			end
		end
		hooksecurefunc("EncounterJournal_ToggleHeaders", updateSpellList) -- EncounterJournal_DisplayEncounter?

		-- for i = 1, MAX_CLASSES do
			-- local button = _G["EncounterJournalEncounterFrameInfoLootScrollFrameClassFilterFrameClass" .. i]
			
			-- local backdrop = gUI:SetUITemplate(button, "itembackdrop")
			
			-- local bevel = _G[button:GetName() .. "BevelEdge"]
			-- local shadow = _G[button:GetName() .. "Shadow"]
			-- local normal = _G[button:GetName() .. "NormalTexture"]
			-- local pushed = _G[button:GetName() .. "PushedTexture"]
			
			-- gUI:DisableTextures(bevel)
			-- gUI:DisableTextures(shadow)

			-- local e = 5/256
			-- local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = normal:GetTexCoord()
			-- normal:SetTexCoord(ULx + e, ULy + e, LLx + e, LLy - e, URx - e, URy + e, LRx - e, LRy - e)

			-- gUI:SetUITemplate(button, "gloss", normal)
			-- gUI:SetUITemplate(button, "shade", normal)
			
			-- gUI:CreateHighlight(button)
			-- gUI:CreatePushed(button)
		-- end
		
		local fixTexCoord = function(self)
			self:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
			self:GetNormalTexture().SetTexCoord = noop

			self:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
			self:GetPushedTexture().SetTexCoord = noop

			self:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
			self:GetHighlightTexture().SetTexCoord = noop

			self.SetNormalTexture = noop
			self.SetHighlightTexture = noop
			self.SetDisabledTexture = noop

		end
		
		gUI:SetUITemplate(EncounterJournalNavBarOverflowButton, "arrow", "left")
		fixTexCoord(EncounterJournalNavBarOverflowButton)
		
		local updateLootList = function()
			local self = EncounterJournal.encounter.info.lootScroll
			
			for i,item in pairs(self.buttons) do
				
				if not(item.GUISkinned) then
					for i = 1, item:GetNumRegions() do
						local region = select(i, item:GetRegions())
						
						if not(region:GetName()) and not(region == item.icon) then
							gUI:HideTexture(region)
						end
					end
					
					gUI:SetUITemplate(item, "insetbackdrop"):SetBackdropColor(r, g, b, 1/3)
					
					local itemBackdrop = gUI:SetUITemplate(CreateFrame("Frame", nil, item), "itembackdrop", item.icon)
					gUI:SetUITemplate(itemBackdrop, "gloss", item.icon)
					gUI:SetUITemplate(itemBackdrop, "shade", item.icon)
					
					item.icon:SetParent(itemBackdrop)
					item.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
					item.icon:SetDrawLayer("OVERLAY")
					
					local point, anchor, relpoint, x, y = item.icon:GetPoint()
					item.icon:SetPoint(point, anchor, relpoint, x+7, y-8)
					item.icon:SetSize(item.icon:GetWidth()-16, item.icon:GetHeight()-16)
					
					item.name:ClearAllPoints()
					item.name:SetPoint("TOPLEFT", item.icon, "TOPRIGHT", 8, -1)
					
					item.slot:ClearAllPoints()
					item.slot:SetPoint("BOTTOMLEFT", item.icon, "BOTTOMRIGHT", 8, 1)

					item.armorType:SetTextColor(unpack(C["index"]))
					
					local r, g, b = item.slot:GetTextColor()
					if not((r == 1) and (g == 0) and (b == 0)) then
						item.slot:SetTextColor(unpack(C["index"]))
					end
					item.GUISkinned = true
				end

				item.boss:SetTextColor(unpack(C["value"]))
			end

		end
		updateLootList()
	--	hooksecurefunc("EncounterJournal_LootCallback", updateLootList)
		hooksecurefunc("EncounterJournal_LootUpdate", updateLootList)
		
		local skinned = {}
		local updateInstanceList = function()
			local self = EncounterJournal.instanceSelect.scroll.child
			local index = 1
			local instanceButton = self["instance" .. index]
			
			while (instanceButton) do
				if not(skinned[index]) then
					local name = instanceButton:GetName()
					local icon = _G[name .. "bgImage"]
					local heroic = _G[name .. "HeroicIcon"]
					local text = _G[name .. "Name"]
					
					for i = 1, instanceButton:GetNumRegions() do
						local region = select(i, instanceButton:GetRegions())
						if (region:GetObjectType() == "Texture") then
							if not((region:GetName()) and ((region:GetName() == name .. "Range") 
							or (region:GetName() == name .. "bgImage") 
							or (region:GetName() == name .. "HeroicIcon") 
							or (region:GetName() == name .. "Name"))) then
								region:SetTexture("")
							end
						end
					end
					gUI:SetUITemplate(instanceButton, "border")
					gUI:SetUITemplate(instanceButton, "gloss")
					gUI:SetUITemplate(instanceButton, "shade")
					
					local e = 8/256
					local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = icon:GetTexCoord()
					icon:SetTexCoord(ULx + e, ULy + e, LLx + e, LLy - e, URx - e, URy + e, LRx - e, LRy - e)
					icon.SetTexCoord = noop
					
					_G[name .. "Highlight"] = gUI:CreateHighlight(instanceButton, 0, 0, 0, 0)
					_G[name .. "PushedTexture"] = gUI:CreatePushed(instanceButton, 0, 0, 0, 0)

					skinned[index] = true
				end
				
				index = index + 1
				instanceButton = self["instance"..index]
			end
		end
		updateInstanceList()
		
		hooksecurefunc("EncounterJournal_ListInstances", updateInstanceList)

		local updateNavButtons = function(self)
			if not(self == EncounterJournal.navBar) then
				return
			end
			
			local index = #self.navList
			local navButton = self.navList[index]
			
			if not(navButton.GUISskinned) then
				gUI:SetUITemplate(navButton, "insetbutton", true)
				navButton.arrowUp:SetTexture("")
				navButton.arrowDown:SetTexture("")
				navButton.selected:SetTexture("")
				
				navButton.GUISskinned = true
			end

			-- lock this sucker down
			local NumberTwo = _G[self:GetName() .."Button2"]
			if (NumberTwo) and not(NumberTwo.suckerLocked) then
				local parent = select(2, NumberTwo:GetPoint())
				NumberTwo:ClearAllPoints()
				NumberTwo:SetPoint("LEFT", parent, "RIGHT", 0, 0)
				NumberTwo.ClearAllPoints = noop
				NumberTwo.SetPoint = noop
			end
		end
		hooksecurefunc("NavBar_AddButton", updateNavButtons)
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end