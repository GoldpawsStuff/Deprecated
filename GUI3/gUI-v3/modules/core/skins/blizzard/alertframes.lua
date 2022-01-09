--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("AlertFrames")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Alert Frames"])
	self:SetAttribute("description", L["General alerts such as new achievements, dungeons completed, etc"])
	
	local func = function()
		local makeMySkin = function(self, icon)
			if (self.styled) then return end
			
			local texture
			if (icon) then
				icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
				icon:ClearAllPoints()
				icon:SetPoint("LEFT", self, 8, 0)
				texture = icon:GetTexture()
			end	
			gUI:DisableTextures(self)
	
			self:SetAlpha(1)
			self.SetAlpha = noop

			if not(self.backdrop) then
				self.backdrop = gUI:SetUITemplate(self, "outerbackdrop")
				self.backdrop:SetPoint("TOPLEFT", -3, -6)
				self.backdrop:SetPoint("BOTTOMRIGHT", 3, 6)
			end
			
			if (self.glow) then gUI:HideObject(self.glow) end
			if (self.shine) then gUI:HideObject(self.shine) end
			if (self.glowFrame) then gUI:HideObject(self.glowFrame) end

			if (icon) then
				if not(icon.backdrop) then
					icon.backdrop = CreateFrame("Frame", nil, self)
					gUI:SetUITemplate(icon.backdrop, "backdrop")
					icon.backdrop:ClearAllPoints()
					icon.backdrop:SetPoint("TOPLEFT", icon, "TOPLEFT", -3, 3)
					icon.backdrop:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 3, -3)
				end
				
				icon:SetParent(icon.backdrop)
				
				if (texture) then
					icon:SetTexture(texture)
				end
			end
			
			self.styled = true
		end
		
		local updateAchievementEarned = function()
			for i = 1, MAX_ACHIEVEMENT_ALERTS do
				local frame = _G["AchievementAlertFrame" .. i]
				
				if (frame) then
					makeMySkin(frame, _G["AchievementAlertFrame" .. i .. "IconTexture"])
					
					if _G[frame:GetName() .. "Background"] then gUI:HideTexture(_G[frame:GetName() .. "Background"]) end
					if _G[frame:GetName() .. "IconOverlay"] then gUI:HideTexture(_G[frame:GetName() .. "IconOverlay"]) end

					_G[frame:GetName() .. "Unlocked"]:SetTextColor(unpack(C["value"]))
					_G[frame:GetName() .. "Name"]:SetTextColor(unpack(C["index"]))
				end
			end
		end
		hooksecurefunc("AlertFrame_FixAnchors", updateAchievementEarned)

		local updateDungeonCompleted = function()
			for i = 1, DUNGEON_COMPLETION_MAX_REWARDS do
				local frame = _G["DungeonCompletionAlertFrame" .. i]

				if (frame) then
					makeMySkin(frame, frame.dungeonTexture)
					
					for i = 1, frame:GetNumRegions() do
						local region = select(i, frame:GetRegions())
						if (region:GetObjectType() == "Texture") then
							if (region:GetTexture() == "Interface\\LFGFrame\\UI-LFG-DUNGEONTOAST") then
								gUI:KillObject(region)
							end
						end
					end
				end
			end				
		end
		hooksecurefunc("AlertFrame_FixAnchors", updateDungeonCompleted)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end