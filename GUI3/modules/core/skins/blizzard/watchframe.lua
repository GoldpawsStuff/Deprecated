--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("WatchFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Objectives Tracker"])
	self:SetAttribute("description", L["The quest- and achievement tracker"])
	
	local func = function()
		gUI:SetUITemplate(WatchFrameCollapseExpandButton, "arrow", "down")
		
		local normal = WatchFrameCollapseExpandButton:GetNormalTexture()
		local pushed = WatchFrameCollapseExpandButton:GetPushedTexture()
			
		normal:SetTexCoord(0, 1, 0, 1)
		pushed:SetTexCoord(0, 1, 0, 1)
			
		normal.SetTexCoord = noop
		pushed.SetTexCoord = noop
		
		local numItems = 0
		local styleWatchFrameItems = function(lineFrame, nextAnchor, maxHeight, frameWidth)
			for i = 1, WATCHFRAME_NUM_ITEMS do
				local item = _G["WatchFrameItem" .. i]
				if (item) then
					gABT:GetStyleFunction()(item)
				end
			end
			numItems = WATCHFRAME_NUM_ITEMS
		end
		styleWatchFrameItems()

		hooksecurefunc("WatchFrame_DisplayTrackedQuests", styleWatchFrameItems)
		hooksecurefunc("WatchFrameItem_OnShow", styleWatchFrameItems)

		gUI:RegisterEvent("QUEST_LOG_UPDATE", styleWatchFrameItems)
		
		-- WatchFrameTitle:SetFontObject(gUI_TextFontNormal)
		local styleWatchFrameLine = function(self, anchor, verticalOffset, isHeader, text, dash, hasItem, isComplete, eligible)
			self.dash:SetSize(1/1e4, 1/1e4)
			-- self.text:SetFontObject(gUI_TextFontSmall)
		end
		hooksecurefunc("WatchFrame_SetLine", styleWatchFrameLine)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end