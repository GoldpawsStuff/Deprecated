--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Map")

local L, C, F, M, db

local defaults = {
	pos = { "CENTER", "UIParent", "CENTER", 0, 0 }; -- the zonemap
}

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	local patch, build, released, toc = GetBuildInfo()
	build = tonumber(build)
	
	-- only skin the WorldMapFrame prior to patch 5.3
	if (build < 16837) then
		gUI:DisableTextures(WorldMapFrame)
		
		gUI:SetUITemplate(WorldMapQuestShowObjectives, "checkbutton")
		gUI:SetUITemplate(WorldMapShowDigSites, "checkbutton")
		gUI:SetUITemplate(WorldMapTrackQuest, "checkbutton")
		gUI:SetUITemplate(WorldMapFrameCloseButton, "closebutton")
		gUI:SetUITemplate(WorldMapDetailFrame, "outerbackdrop")
		gUI:SetUITemplate(WorldMapQuestDetailScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(WorldMapQuestRewardScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(WorldMapQuestScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(WorldMapShowDropDown, "dropdown", true, 120)
		gUI:SetUITemplate(WorldMapZoneMinimapDropDown, "dropdown", true, 120)

		gUI:SetUITemplate(WorldMapContinentDropDown, "dropdown", true, 160)
		WorldMapContinentDropDown:ClearAllPoints()
		WorldMapContinentDropDown:SetPoint("BOTTOMLEFT", WorldMapZoneMinimapDropDown, "BOTTOMRIGHT", 20, 0)
		
		gUI:SetUITemplate(WorldMapZoneDropDown, "dropdown", true, 180)
		WorldMapZoneDropDown:ClearAllPoints()
		WorldMapZoneDropDown:SetPoint("BOTTOMLEFT", WorldMapContinentDropDown, "BOTTOMRIGHT", 20, 0)

		WorldMapContinentDropDown:ClearAllPoints()
		WorldMapContinentDropDown:SetPoint("BOTTOMLEFT", WorldMapZoneMinimapDropDown, "BOTTOMRIGHT", 20, 0)

		WorldMapFrameAreaLabel:SetFontObject(gUI_DisplayFontEnormousBoldOutlineWhite)
		WorldMapFrameAreaDescription:SetFontObject(gUI_DisplayFontLargeBoldOutline)
		
		gUI:SetUITemplate(WorldMapZoomOutButton, "button", true)
		WorldMapZoomOutButton:ClearAllPoints()
		WorldMapZoomOutButton:SetPoint("LEFT", WorldMapZoneDropDown, "RIGHT", 40, 0)

		local r, g, b = gUI:GetBackdropColor()
		gUI:SetUITemplate(WorldMapLevelDropDown, "dropdown", true, 180)
		WorldMapLevelDropDown:ClearAllPoints()
		WorldMapLevelDropDown:SetPoint("LEFT", WorldMapZoomOutButton, "RIGHT", 40, 0)
		WorldMapLevelDropDown:SetBackdropColor(r, g, b, gUI:GetOverlayAlpha())
		
		gUI:SetUITemplate(WorldMapLevelDownButton, "arrow", "left")
		WorldMapLevelDownButton:SetSize(24, 24)
		WorldMapLevelDownButton:ClearAllPoints()
		WorldMapLevelDownButton:SetPoint("RIGHT", WorldMapLevelDropDown, "LEFT", 0, 0)
		
		gUI:SetUITemplate(WorldMapLevelUpButton, "arrow", "right")
		WorldMapLevelUpButton:SetSize(24, 24)
		WorldMapLevelUpButton:ClearAllPoints()
		WorldMapLevelUpButton:SetPoint("LEFT", WorldMapLevelDropDown, "RIGHT", 0, 0)
		
		WorldMapFrameSizeUpButton:SetSize(24, 24)
		gUI:SetUITemplate(WorldMapFrameSizeUpButton, "arrow", "up")

		WorldMapFrameSizeDownButton:SetSize(24, 24)
		gUI:SetUITemplate(WorldMapFrameSizeDownButton, "arrow", "down")
		
		local mapSkin = gUI:SetUITemplate(WorldMapFrame, "outerbackdrop", nil, 0, 8, 8, 0)
		gUI:CreateUIShadow(mapSkin)
		
		local setOpacity = function(opacity)
			mapSkin:SetAlpha(0.5 + (1.0 - opacity) * 0.5)
			WorldMapLevelDropDown:SetAlpha(0.75 + (1.0 - opacity) * 0.25)
		end
		setOpacity(1)
		hooksecurefunc("WorldMapFrame_SetOpacity", setOpacity)

		local setFontSize = function(fontString, size)
			local font, _, style = fontString:GetFont()
			return fontString:SetFont(font, size, style)
		end
		
		local MiniWorldMap = function()
			setOpacity(WORLDMAP_SETTINGS.opacity)
			mapSkin:ClearAllPoints()
			mapSkin:SetPoint("TOPLEFT", -3, 6)
			mapSkin:SetPoint("BOTTOMRIGHT", 3, -3)
			WorldMapLevelDropDown:ClearAllPoints()
			WorldMapLevelDropDown:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", 4, -4)
			WorldMapLevelDropDown:SetBackdropColor(r, g, b, gUI:GetPanelAlpha())
			WorldMapFrameSizeUpButton:SetAlpha(1)
			WorldMapFrameSizeDownButton:SetAlpha(0)
			setFontSize(WorldMapFrameAreaLabel, 32)
			setFontSize(WorldMapFrameAreaDescription, 28)
			setFontSize(WorldMapFrameAreaPetLevels, 28)
		end

		local LargeWorldMap = function()
			if not(InCombatLockdown()) then
				WorldMapFrame:SetParent(UIParent)
				WorldMapFrame:EnableMouse(false)
				WorldMapFrame:EnableKeyboard(false)
				SetUIPanelAttribute(WorldMapFrame, "area", "center")
				SetUIPanelAttribute(WorldMapFrame, "allowOtherPanels", true)
			end
			setOpacity(0)
			mapSkin:ClearAllPoints()
			mapSkin:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", -25, 78)
			mapSkin:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame, "BOTTOMRIGHT", 25, -30)
			WorldMapFrameSizeUpButton:SetAlpha(0)
			WorldMapFrameSizeDownButton:SetAlpha(1)
			WorldMapLevelDropDown:ClearAllPoints()
			WorldMapLevelDropDown:SetPoint("LEFT", WorldMapZoomOutButton, "RIGHT", 40, 0)
			WorldMapLevelDropDown:SetBackdropColor(r, g, b, gUI:GetOverlayAlpha())
			setFontSize(WorldMapFrameAreaLabel, 32)
			setFontSize(WorldMapFrameAreaDescription, 22)
			setFontSize(WorldMapFrameAreaPetLevels, 18)
		end

		local QuestWorldMap = function()
			if not(InCombatLockdown()) then
				WorldMapFrame:SetParent(UIParent)
				WorldMapFrame:EnableMouse(false)
				WorldMapFrame:EnableKeyboard(false)
				SetUIPanelAttribute(WorldMapFrame, "area", "center")
				SetUIPanelAttribute(WorldMapFrame, "allowOtherPanels", true)
			end
			setOpacity(0)
			mapSkin:ClearAllPoints()
			mapSkin:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", -25, 78)
			mapSkin:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame, "BOTTOMRIGHT", 334, -237) 
			setFontSize(WorldMapFrameAreaLabel, 32)
			setFontSize(WorldMapFrameAreaDescription, 28)
			setFontSize(WorldMapFrameAreaPetLevels, 28)
			WorldMapFrameSizeUpButton:SetAlpha(0)
			WorldMapFrameSizeDownButton:SetAlpha(1)
			WorldMapLevelDropDown:ClearAllPoints()
			WorldMapLevelDropDown:SetPoint("LEFT", WorldMapZoomOutButton, "RIGHT", 40, 0)
			WorldMapLevelDropDown:SetBackdropColor(r, g, b, gUI:GetOverlayAlpha())
			if not(WorldMapQuestDetailScrollFrame.backdrop) then
				WorldMapQuestDetailScrollFrame.backdrop = gUI:SetUITemplate(WorldMapQuestDetailScrollFrame, "border")
				WorldMapQuestDetailScrollFrame.backdrop:ClearAllPoints()
				WorldMapQuestDetailScrollFrame.backdrop:SetPoint("TOPLEFT", -22, 3)
				WorldMapQuestDetailScrollFrame.backdrop:SetPoint("BOTTOMRIGHT", 25, -5)
				WorldMapQuestDetailScrollFrame.backdrop:SetBackdropColor(unpack(C["overlay"]))
			end
			if not(WorldMapQuestRewardScrollFrame.backdrop) then
				WorldMapQuestRewardScrollFrame.backdrop = gUI:SetUITemplate(WorldMapQuestRewardScrollFrame, "border")
				WorldMapQuestRewardScrollFrame.backdrop:ClearAllPoints()
				WorldMapQuestRewardScrollFrame.backdrop:SetPoint("TOPLEFT", 0, 3)
				WorldMapQuestRewardScrollFrame.backdrop:SetPoint("BOTTOMRIGHT", 25, -5)				
			end
			if not(WorldMapQuestScrollFrame.backdrop) then
				WorldMapQuestScrollFrame.backdrop = gUI:SetUITemplate(WorldMapQuestScrollFrame, "border")
				WorldMapQuestScrollFrame.backdrop:ClearAllPoints()
				WorldMapQuestScrollFrame.backdrop:SetPoint("TOPLEFT", 0, 3)
				WorldMapQuestScrollFrame.backdrop:SetPoint("BOTTOMRIGHT", 28, -4)
			end
		end	

		local UpdateWorldMap = function()
			gUI:DisableTextures(WorldMapFrame) -- they keep re-adding the backdrop textures
			if (WORLDMAP_SETTINGS.size == WORLDMAP_FULLMAP_SIZE) then
				LargeWorldMap()
			elseif (WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE) then
				MiniWorldMap()
			elseif (WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE) then
				QuestWorldMap()
			end
			if not(InCombatLockdown()) then
				WorldMapFrame:SetScale(1)
				WorldMapFrameSizeDownButton:Show()
				WorldMapFrame:SetFrameLevel(40)
				WorldMapFrame:SetFrameStrata("HIGH")
			end
		end

		UpdateWorldMap() 
		
		-- WorldMapFrame:HookScript("OnShow", UpdateWorldMap)
		hooksecurefunc("WorldMapFrame_OnShow", UpdateWorldMap)
		hooksecurefunc("WorldMap_ToggleSizeUp", UpdateWorldMap)
		hooksecurefunc("WorldMap_ToggleSizeDown", UpdateWorldMap)
		hooksecurefunc("WorldMapFrame_SetFullMapView", LargeWorldMap)
		hooksecurefunc("WorldMapFrame_SetQuestMapView", QuestWorldMap)
	end

	-- WorldMap coordinates
	-- we're parenting it to the WorldMapFrame to easily solve the scale issue with the WorldMapButton
	local frame = CreateFrame("Frame", self:GetName() .. "CoordinatesFrame", WorldMapFrame)
	frame:SetAllPoints(WorldMapButton)
	frame:SetFrameLevel(WorldMapButton:GetFrameLevel() + 1)
	
	local xCoord = frame:CreateFontString()
	xCoord:SetDrawLayer("OVERLAY")
	xCoord:SetFontObject(gUI_DisplayFontSmallOutline)
	xCoord:SetPoint("BOTTOMRIGHT", WorldMapButton, "BOTTOM", -10, 4)
	xCoord:SetJustifyH("RIGHT")

	local yCoord = frame:CreateFontString()
	yCoord:SetDrawLayer("OVERLAY")
	yCoord:SetFontObject(gUI_DisplayFontSmallOutline)
	yCoord:SetPoint("BOTTOMLEFT", WorldMapButton, "BOTTOM", 10, 4)
	yCoord:SetJustifyH("LEFT")

	local update = function()
		if not(WorldMapButton:IsVisible()) then
			return
		end
		if (MouseIsOver(WorldMapButton)) then
			local x, y = GetCursorPosition()
			local scale = WorldMapButton:GetEffectiveScale()
			x = x / scale
			y = y / scale
			local centerX, centerY = WorldMapButton:GetCenter()
			local width = WorldMapButton:GetWidth()
			local height = WorldMapButton:GetHeight()
			local adjustedY = (centerY + (height/2) - y) / height
			local adjustedX = (x - (centerX - (width/2))) / width
			xCoord:SetFormattedText("%.2f", adjustedX*100)
			xCoord:SetTextColor(unpack(C["index"]))
			xCoord:SetAlpha(1)
			yCoord:SetFormattedText("%.2f", adjustedY*100)
			yCoord:SetTextColor(unpack(C["index"]))
			yCoord:SetAlpha(1)
		else
			local x, y = GetPlayerMapPosition("player")
			if ((x == 0) and (y == 0)) or not(x) or not(y) then
				xCoord:SetAlpha(0)
				yCoord:SetAlpha(0)
			else
				xCoord:SetFormattedText("%.2f", x*100)
				xCoord:SetTextColor(unpack(C["value"]))
				xCoord:SetAlpha(1)
				yCoord:SetFormattedText("%.2f", y*100)
				yCoord:SetTextColor(unpack(C["value"]))
				yCoord:SetAlpha(1)
			end
		end
	end
	self:ScheduleRepeatingTimer(0.1, update)

	-- zonemap
	local SkinFunc = function()
		local zoneMap = CreateFrame("Frame", gUI:GetName() .. "_" .. module:GetName() .. "_ZoneMapHolder", UIParent)
		zoneMap:Hide()
		zoneMap:SetSize(219, 147) -- 225, 150 
		zoneMap:SetFrameStrata("MEDIUM")
		zoneMap:SetFrameLevel(50)
		zoneMap:EnableMouse(true)
		zoneMap:SetMovable(true)
		zoneMap.alpha = 1
		
		zoneMap:SetPoint(unpack(db.pos)) 
		-- module:PlaceAndSave(zoneMap, L["ZoneMap"], db.pos, unpack(defaults.pos))
		-- module:AddObjectToFrameGroup(zoneMap, "uipanels")
		
		zoneMap.bg = CreateFrame("Frame", nil, zoneMap)
		zoneMap.bg:SetAllPoints()
		zoneMap.bg:SetFrameLevel(0)
		gUI:SetUITemplate(zoneMap.bg, "outerbackdrop")
		
		local once
		BattlefieldMinimap:SetScript("OnShow", function(self)
			zoneMap:Show()		
			
			if not(once) then
				gUI:HideTexture(BattlefieldMinimapCorner)
				gUI:HideTexture(BattlefieldMinimapBackground)
				gUI:HideTexture(BattlefieldMinimapTabLeft)
				gUI:HideTexture(BattlefieldMinimapTabMiddle)
				gUI:HideTexture(BattlefieldMinimapTabRight)
				gUI:KillObject(BattlefieldMinimapTab)
				gUI:SetUITemplate(BattlefieldMinimapCloseButton, "closebutton")
				once = true
			end
			
			self:SetParent(UIParent) -- zoneMap
			self:SetPoint("TOPLEFT", zoneMap, "TOPLEFT", 0, 0)
			self:SetFrameStrata(zoneMap:GetFrameStrata())
			self:SetFrameLevel(49)

			BattlefieldMinimapCloseButton:ClearAllPoints()
			BattlefieldMinimapCloseButton:SetPoint("TOPRIGHT", -4, 0)
			BattlefieldMinimapCloseButton:SetFrameLevel(51)

			zoneMap:SetScale(1)
			zoneMap:SetAlpha(zoneMap.alpha)
			
			BattlefieldMinimap_Update()
		end)

		BattlefieldMinimap:SetScript("OnHide", function(self)
			zoneMap:SetScale(0.00001)
			zoneMap:SetAlpha(0)
		end)

		zoneMap:SetScript("OnMouseUp", function(self, button)
			if (button == "LeftButton") then
				self:StopMovingOrSizing()
				
				db.pos = { module:GetObjectPosition(self) }
				
				if (OpacityFrame:IsShown()) then 
					OpacityFrame:Hide() 
				end 
			elseif (button == "RightButton") then
				ToggleDropDownMenu(1, nil, BattlefieldMinimapTabDropDown, self:GetName(), 0, -4)
				if (OpacityFrame:IsShown()) then 
					OpacityFrame:Hide() 
				end 
			end
		end)

		zoneMap:SetScript("OnMouseDown", function(self, button)
			if (button == "LeftButton") then
				if (BattlefieldMinimapOptions) and (BattlefieldMinimapOptions.locked) then
					return
				else
					self:StartMoving()
				end
			end
		end)
		
		-- taint or yay?
		BattlefieldMinimap_UpdateOpacity = function(opacity)
			BattlefieldMinimapOptions.opacity = opacity or OpacityFrameSlider:GetValue()
			
			local alpha = 1.0 - BattlefieldMinimapOptions.opacity
			BattlefieldMinimapBackground:SetAlpha(alpha)
			
			if ( alpha >= 0.15 ) then
				alpha = alpha - 0.15
			end
			
			local reverse
			if (GetNumberOfDetailTiles) then
				local numDetailTiles = GetNumberOfDetailTiles()
				local tile
				for i = 1, numDetailTiles do
					tile = _G["BattlefieldMinimap" .. i]
					if (tile) then
						tile:SetAlpha(alpha)
					end
				end
			else
				reverse = true
			end
			
			if (NUM_BATTLEFIELDMAP_OVERLAYS) then
				local overlay
				for i = 1, NUM_BATTLEFIELDMAP_OVERLAYS do
					overlay = _G["BattlefieldMinimapOverlay" .. i]
					if (overlay) then
						overlay:SetAlpha(alpha)
					end
				end
			end
			
			if (BattlefieldMinimapCorner) then
				BattlefieldMinimapCorner:SetAlpha(alpha)
			end

			local reverseAlpha = (reverse) and 1 - alpha or alpha
			BattlefieldMinimapCloseButton:SetAlpha(reverseAlpha)
			zoneMap:SetAlpha(reverseAlpha)
			zoneMap.alpha = reverseAlpha
		end
--		hooksecurefunc("BattlefieldMinimap_UpdateOpacity", opacityFunc)
		
		BattlefieldMinimap_UpdateOpacity(BattlefieldMinimapOptions and BattlefieldMinimapOptions.opacity or 1)
	end
	gUI:HookAddOn("Blizzard_BattlefieldMinimap", SkinFunc)
	
	-- WorldMapFrame_SetOpacity(WORLDMAP_SETTINGS.opacity)
	-- WorldMapFrame_ChangeOpacity
	-- WorldMapFrame_SetOpacity
	

	
end

module.OnEnter = function(self)
	-- if not(GetCVarBool("miniWorldMap")) then
		-- ToggleFrame(WorldMapFrame)
		-- ToggleFrame(WorldMapFrame)
	-- end
end
