--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("GossipFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Quest Gossip"])
	self:SetAttribute("description", L["General gossip when talking to quest givers"])
	
	local func = function()
		gUI:DisableTextures(GossipFrameGreetingPanel)
		gUI:DisableTextures(GossipGreetingScrollFrame)
		gUI:DisableTextures(GossipFrame)
		gUI:DisableTextures(GossipFrameInset)
		
		gUI:KillObject(GossipFramePortrait)

		gUI:SetUITemplate(GossipFrameGreetingGoodbyeButton, "button", true)
		gUI:SetUITemplate(GossipGreetingScrollFrameScrollBar, "scrollbar")
		gUI:SetUITemplate(GossipFrameCloseButton, "closebutton")
		gUI:SetUITemplate(GossipFrame, "backdrop")
		gUI:SetUITemplate(NPCFriendshipStatusBar, "statusbar", true)
		
		NPCFriendshipStatusBar:ClearAllPoints()
		NPCFriendshipStatusBar:SetPoint("TOP", 0, -40)
		NPCFriendshipStatusBar:SetStatusBarColor(0, 0.6, 0)
		
		GossipGreetingText:SetTextColor(unpack(C["index"]))
		for i = 1, NUMGOSSIPBUTTONS do
			local text = select(3, _G["GossipTitleButton" .. i]:GetRegions())
			text:SetTextColor(unpack(C["index"]))
		end	
		
		local SkinFunc = function()
			for i = 1, NUMGOSSIPBUTTONS do
				local button = _G["GossipTitleButton" .. i]
				if (button:GetFontString()) then
					if (button:GetFontString():GetText()) and (button:GetFontString():GetText():find("|cff000000")) then
						button:GetFontString():SetText(gsub(button:GetFontString():GetText(), "|cff000000", "|cff" .. gUI:RGBToHex(unpack(C["value"]))))
					end
				end
			end
		end
		hooksecurefunc("GossipFrameUpdate", SkinFunc)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end