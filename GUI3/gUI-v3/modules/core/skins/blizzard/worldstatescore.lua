--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("WorldStateScore")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["World Score"])
	self:SetAttribute("description", L["The on-screen score (battlegrounds, dungeon waves, world PvP objectives etc)"])
	
	local func = function()
		local Horde, Alliance
		local PostUpdateWorldState
		local position
	
		Horde = {
			[ [[Interface\TargetingFrame\UI-PVP-Horde]] ] = true;
			[ [[Interface\WorldStateScore\HordeIcon]] ] = true;
		}

		Alliance = {
			[ [[Interface\TargetingFrame\UI-PVP-Alliance]] ] = true;
			[ [[Interface\WorldStateScore\AllianceIcon]] ] = true;
		}

		position = function(frame, default)
			local text = _G[frame:GetName() .. "Text"]
			local icon = _G[frame:GetName() .. "Icon"]
		--	do return end
			
			local indent = 3
			local w, h = 24, 24
			local origW, origH = 42, 42

			if (default) then
				icon:SetSize(origW, origH)
				icon:ClearAllPoints()
				icon:SetPoint("LEFT", frame, "LEFT", -6, 0)
				text:ClearAllPoints()
				text:SetPoint("LEFT", icon, "RIGHT", -12, 10)
			else
				-- the weird coordinates are there because I wish the process to calculate them to be visible
				-- so that I can easily re-align them or change them in the future
				icon:SetSize(w, h) 
				icon:ClearAllPoints()
				icon:SetPoint("LEFT", frame, "LEFT", -6 + (indent), ((origH-h)/2))
				text:ClearAllPoints()
				text:SetPoint("LEFT", icon, "RIGHT", -12 + ((origW-w)-indent), 10 - (origH-h)/2)
			end

			-- don't think this is strictly needed, but we'll do it anyway
			frame:SetSize(45, 24)
		end

		PostUpdateWorldState = function()
			for i = 1, NUM_ALWAYS_UP_UI_FRAMES do
				local frame = _G["AlwaysUpFrame" .. i]
				local text = _G["AlwaysUpFrame" .. i .. "Text"]
				local icon = _G["AlwaysUpFrame" .. i .. "Icon"] -- Horde/Alliance icons
				local dynamicIcon = _G["AlwaysUpFrame" .. i .. "DynamicIconButtonIcon"] -- flag icons

				local texture = icon:GetTexture()
				if (texture) then
					if (Alliance[texture]) then
						icon:SetTexture(M("Icon", "FactionAlliance"))
						position(frame)
						
					elseif (Horde[texture]) then
						icon:SetTexture(M("Icon", "FactionHorde"))
						position(frame)
						
					else
						position(frame, true)
					end
				else
					position(frame, true)
				end
				
				-- if (text:GetFontObject() ~= gUI_TextFontSmall) then
					-- text:SetFontObject(gUI_TextFontSmall)
				-- end
			end
		end
		
		hooksecurefunc("WorldStateAlwaysUpFrame_Update", PostUpdateWorldState)
		gUI:RegisterEvent("PLAYER_ENTERING_WORLD", PostUpdateWorldState)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end