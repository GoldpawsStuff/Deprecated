--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("ReadyCheckFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Ready Check"])
	self:SetAttribute("description", L["The ready check popup when in a group"])
		
	local func = function()
		gUI:DisableTextures(ReadyCheckFrame)
		gUI:SetUITemplate(ReadyCheckFrameYesButton, "button", true)
		gUI:SetUITemplate(ReadyCheckFrameNoButton, "button", true)
		gUI:SetUITemplate(ReadyCheckFrame, "backdrop")

		ReadyCheckFrameYesButton:SetParent(ReadyCheckFrame)
		ReadyCheckFrameYesButton:ClearAllPoints()
		ReadyCheckFrameYesButton:SetPoint("RIGHT", ReadyCheckFrame, "CENTER", -2, -20)

		ReadyCheckFrameNoButton:SetParent(ReadyCheckFrame)
		ReadyCheckFrameNoButton:ClearAllPoints()
		ReadyCheckFrameNoButton:SetPoint("LEFT", ReadyCheckFrameYesButton, "RIGHT", 3, 0)

		ReadyCheckFrameText:SetParent(ReadyCheckFrame)	
		ReadyCheckFrameText:ClearAllPoints()
		ReadyCheckFrameText:SetPoint("TOP", 0, -12)

		ReadyCheckListenerFrame:SetAlpha(0)

		-- sometimes the lines get wrapped, and that looks bad. 
		-- ReadyCheckFrame:SetSize(350, 100) -- original size 323, 100
		-- ReadyCheckFrameText:SetSize(320, 36) -- original size 240, 36

		-- we'll get a big black box when performing ready checks, so we need to hide it!
		local fixDisplayBugs = function(self)
			if (self.initiator) and (UnitIsUnit("player", self.initiator)) then 
				self:Hide() 
			end
		end
		ReadyCheckFrame:HookScript("OnShow", fixDisplayBugs)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end