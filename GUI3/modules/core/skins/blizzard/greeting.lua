--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("QuestFrameGreeting")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Quest Greeting"])
	self:SetAttribute("description", L["The greeting window when talking to quest givers"])
	
	local func = function()
		-- QuestFrameNpcNameText:SetFontObject(gUI_DisplayFontSmallWhite)
		-- QuestFrameNpcNameText:SetJustifyH("CENTER")
		
		gUI:KillObject(QuestFrameInset)
		gUI:DisableTextures(QuestFrameGreetingPanel)
		gUI:DisableTextures(QuestProgressScrollFrame)
		gUI:DisableTextures(QuestGreetingScrollFrame)
		gUI:HideTexture(QuestGreetingFrameHorizontalBreak)
		gUI:SetUITemplate(QuestFrameGreetingGoodbyeButton, "button", true)
		gUI:SetUITemplate(QuestGreetingScrollFrameScrollBar, "scrollbar")

		-- AvailableQuestsText:SetFontObject(gUI_DisplayFontNormalWhite)
		-- CurrentQuestsText:SetFontObject(gUI_DisplayFontNormalWhite)
		-- GreetingText:SetFontObject(gUI_TextFontSmallWhite)

		hooksecurefunc("QuestFrame_SetTextColor", function(fontstring, color)
			fontstring:SetTextColor(unpack(C["value"]))
		end)
		
		hooksecurefunc("QuestFrame_SetTitleTextColor", function(fontstring, color)
			fontstring:SetTextColor(unpack(C["index"]))
		end)
		
		for i = 1, MAX_NUM_QUESTS do
			-- _G["QuestTitleButton" .. i]:SetNormalFontObject(gUI_TextFontSmallWhite)
			_G["QuestTitleButton" .. i]:GetNormalFontObject():SetTextColor(unpack(C["index"]))
		end
		
		local fixColor = function()
			local numActiveQuests = GetNumActiveQuests() -- number of "current" quests in the frame
			local numAvailableQuests = GetNumAvailableQuests() -- number of total quests in the frame
			if (numActiveQuests > 0) then
				for i = 1, numActiveQuests do
					local button = _G["QuestTitleButton" .. i]
					local title, isComplete = GetActiveTitle(i)
					if (title) then
						if ( IsActiveQuestTrivial(i) ) then
							button:SetText(title)
							button:GetNormalFontObject():SetTextColor(0.6, 0.6, 0.6)
						else
							button:SetText(title)
							button:GetNormalFontObject():SetTextColor(unpack(C["index"]))
						end
					end
				end
			end
			for i=(numActiveQuests + 1), (numActiveQuests + numAvailableQuests), 1 do
				local questTitleButton = _G["QuestTitleButton" .. i]
				local isTrivial, isDaily, isRepeatable, isLegendary = GetAvailableQuestInfo(i - numActiveQuests)
				if ( isTrivial ) then
					questTitleButton:SetText(GetAvailableTitle(i - numActiveQuests))
					questTitleButton:GetNormalFontObject():SetTextColor(0.6, 0.6, 0.6)
				else
					questTitleButton:SetText(GetAvailableTitle(i - numActiveQuests))
					questTitleButton:GetNormalFontObject():SetTextColor(unpack(C["index"]))
				end
			end
		end
		fixColor() -- not strictly needed, but it's in my nature
		QuestFrameGreetingPanel:HookScript("OnShow", fixColor) -- this handles the initial showing of the window
		hooksecurefunc("QuestFrameGreetingPanel_OnShow", fixColor) -- this handles updates while the window is open
		-- QuestFrameProgressPanel:HookScript("OnShow", fixColor) -- no idea why I included this
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end