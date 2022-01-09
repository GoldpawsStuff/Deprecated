--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("GameMenuFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")
	
	self:SetAttribute("name", L["GameMenu"])
	self:SetAttribute("description", L["The main game menu"])

	local origHeight = GameMenuFrame:GetHeight()
	local buttons = 0
	
	local func = function()
		local skinned = {}

		-- skin a menu button
		local Skin = function(button)
			if (skinned[button]) then
				return
			end

			button:SetHeight(button:GetHeight() + 4)
			gUI:SetUITemplate(button, "insetbutton", true)
			
			local text = button.text or button:GetName() and _G[button:GetName() .. "Text"]
			if (text) then
				text:SetFontObject(gUI_TextFontSmallWhite)
				button:SetNormalFontObject(gUI_TextFontSmallWhite)
			end
			
			buttons = buttons + 1
			skinned[button] = true
		end

		-- skin custom buttons
		local skinExtra = function()
			local extraButtons = F.GetGameMenuButtons()
			for i,v in ipairs(extraButtons) do
				if (v) and not(skinned[v]) then
					Skin(v)
				end
			end
		end

		local skinAll = function()
			-- let's do this the smart way
			for i = 1, GameMenuFrame:GetNumChildren() do
				local child = select(i, GameMenuFrame:GetChildren())
				if (child.GetObjectType) and (child:GetObjectType() == "Button") and not(skinned[child]) then
					Skin(child)
				end
			end
		end
		
		local resize = function(self)
			self:SetHeight(origHeight + buttons * 4 + 8)
		end
		GameMenuFrame:HookScript("OnShow", resize)
		
		local fireOnce = function()
			gUI:DisableTextures(GameMenuFrame)
			gUI:SetUITemplate(GameMenuFrame, "backdrop")

			-- resize the frame, it's kind of big without it's default backdrop
			-- GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() - 12) 
			
			-- move the header to where we want it, as the title is hooked to it
			GameMenuFrameHeader:SetPoint("TOP", GameMenuFrame, "TOP", 0, 8)
			
			-- find the title and style it
			for i = 1, GameMenuFrame:GetNumRegions() do
				r = select(i, GameMenuFrame:GetRegions())
				if (r:GetObjectType() == "FontString") and (r:GetText() == MAINMENU_BUTTON) then
					r:SetFontObject(gUI_TextFontNormalWhite)
					break
				end
			end
			skinAll() -- skin all existing buttons
			-- hooksecurefunc(F, "AddGameMenuButton", skinExtra) -- hook the creation of new custom menu buttons

			gUI:UnregisterEvent("PLAYER_ENTERING_WORLD", fireOnce)
		end
		gUI:RegisterEvent("PLAYER_ENTERING_WORLD", fireOnce)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end