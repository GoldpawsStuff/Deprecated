--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

-- Healium frame structure is changed in v2.1.11, so we bail out
if (IsAddOnLoaded("Healium")) then
	local v = GetAddOnMetadata("Healium", "X-Curse-Packaged-Version")
	v = v:gsub(" ", "")
	if (v >= "v2.1.11") then
		return
	end
end

local style = gUI:GetModule("Styling"):NewModule("Healium")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", self:GetName()) -- don't localize
	self:SetAttribute("description", L["Skins the '%s' addon"]:format(self:GetName()))
	
	local func = function()
		local skinHeader, skinUnitFrame, skinHeal, skinBuff
		local skinAllHeals, skinAllBuffs
		local skinAll
		local updateButtonIcon
	
		local r, g, b = gUI:GetBackdropColor()
		local a = 0.66
	
		local skinned = {}
		local captionFrames = {
			"HealiumPartyFrame";
			"HealiumPetFrame";
			"HealiumMeFrame";
			"HealiumFriendsFrame";
			"HealiumDanagersFrame";
			"HealiumHealersFrame";
			"HealiumTanksFrame";
			"HealiumTargetFrame";
			"HealiumFocusFrame";
			"HealiumGroup1Frame";
			"HealiumGroup2Frame";
			"HealiumGroup3Frame";
			"HealiumGroup4Frame";
			"HealiumGroup5Frame";
			"HealiumGroup6Frame";
			"HealiumGroup7Frame";
			"HealiumGroup8Frame";
		}
		
		skinHeader = function(self)
			if not(self) or (skinned[self]) then
				return
			end
			
			local captionbar = self.CaptionBar -- frame w/backdrop
			local captiontext = self.CaptionBar.Caption -- font
			local closebutton = self.CaptionBar.CloseButton -- normal closebutton
			
			gUI:SetUITemplate(closebutton, "closebutton", "RIGHT", -8, 0)
			gUI:SetUITemplate(captionbar, "insetbackdrop"):SetBackdropColor(r, g, b, a)

			local shadow = CreateFrame("Frame", nil, captionbar)
			shadow:SetPoint("TOPLEFT", 2, -2)
			shadow:SetPoint("BOTTOMRIGHT", -2, 2)

			gUI:CreateUIShadow(shadow)

			captiontext:SetFontObject(gUI_UnitFrameFont12)
			captiontext:SetPoint("LEFT", 8, 0)
			
			skinned[self] = true
		end
		
		skinHeal = function(self)
			if not(self) or (skinned[self]) then
				return
			end

			gABT:GetStyleFunction()(self)
			gUI:CreateUIShadow(self)
			
			local Gloss = gUI:SetUITemplate(self, "gloss", self.icon)
			Gloss:Show()
			self.Gloss = Gloss
			
			local Shade = gUI:SetUITemplate(self, "shade", self.icon)
			Shade:Show()
			self.Shade = Shade

			updateButtonIcon(self, self.icon:GetTexture())
			
			skinned[self] = true
		end
		
		skinBuff = function(self)
			if not(self) or (skinned[self]) then
				return
			end
			
			local icon = self.icon
			local cooldown = self.cooldown
			local count = self.count 
			local border = self.border 
			
			icon:SetDrawLayer("OVERLAY")
			icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			icon:ClearAllPoints()
			icon:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -3)
			icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)

			gUI:SetUITemplate(self, "gloss", icon)
			gUI:SetUITemplate(self, "shade", icon)

			count:SetFontObject(gUI_UnitFrameFont10)
			count:SetDrawLayer("OVERLAY", 1)
			count:SetJustifyH("RIGHT")
			count:SetJustifyV("BOTTOM")
			count:ClearAllPoints()
			count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
		
			cooldown:ClearAllPoints()
			cooldown:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -3)
			cooldown:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)
			cooldown:SetWidth(self:GetWidth() - 6)
			cooldown:SetHeight(self:GetHeight() - 6)
			
			gUI:SetUITemplate(self, "backdrop")
			gUI:CreateUIShadow(self)
			
			skinned[self] = true
		end
		
		skinAllHeals = function(frame)
			for i = 1, #frame.buttons do
				skinHeal(frame.buttons[i])
			end
		end
		
		skinAllBuffs = function(unit, frame)
			for i = 1, #frame.buffs do
				skinBuff(frame.buffs[i])
			end
		end
		
		updateButtonIcon = function(button, texture)
			button.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			button.icon:ClearAllPoints()
			button.icon:SetPoint("TOPLEFT", 3, -3)
			button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
			if (button.icon:GetTexture() == "Interface/Icons/INV_Misc_QuestionMark") then
				button.icon:SetTexture("") -- empty slot for no spell
				button.Gloss:Hide()
			else
				button.Gloss:Show()
			end
		end
		
		skinUnitFrame = function(self)
			if not(self) or (skinned[self]) then
				return
			end
			
			local frameName = self:GetName() -- 120, 28
			local name = self.name -- font
			local hptext = self.HPText -- font
			local raidtarget = self.raidTargetIcon
			local cursebar = self.CurseBar -- frame w/backdrop
			local aggrobar = self.AggroBar -- frame w/backdrop
			local predictbar = self.PredictBar -- statusbar 111, 23
			local healthbar = self.HealthBar -- statusbar, 111, 23 TOPLEFT, 7, -2
			local manabar = self.ManaBar -- statusbar, 5,23 TOPLEFT, 2, -2
			
			gUI:DisableTextures(self)
			gUI:DisableTextures(aggrobar)
			gUI:DisableTextures(cursebar)
			
			gUI:DisableTextures(predictbar)
			gUI:DisableTextures(healthbar)
			gUI:DisableTextures(manabar)
			
			gUI:SetUITemplate(predictbar, "statusbar")
			gUI:SetUITemplate(healthbar, "statusbar")
			gUI:SetUITemplate(manabar, "statusbar")
			
			aggrobar.backdrop = gUI:SetUITemplate(aggrobar, "border")
			aggrobar.SetBackdropBorderColor = aggrobar.backdrop.SetBackdropBorderColor

			cursebar.backdrop = gUI:SetUITemplate(aggrobar, "border")
			cursebar.SetBackdropBorderColor = aggrobar.backdrop.SetBackdropBorderColor
			
			name:SetFontObject(gUI_UnitFrameFont12)
			hptext:SetFontObject(gUI_UnitFrameFont14)
			
			predictbar:SetHeight(21)
			healthbar:SetHeight(21)
			manabar:SetHeight(21)
			
			predictbar:SetPoint("TOPLEFT", 7, -3)
			healthbar:SetPoint("TOPLEFT", 7, -3)
			manabar:SetPoint("TOPLEFT", 2, -3)
			
			local bgTexture = healthbar:CreateTexture()
			bgTexture:SetDrawLayer("BACKGROUND", -1)
			bgTexture:SetPoint("LEFT", self, "LEFT", 1, 0)
			bgTexture:SetPoint("TOP", healthbar, "TOP", 0, 1)
			bgTexture:SetPoint("BOTTOM", healthbar, "BOTTOM", 0, -1)
			bgTexture:SetPoint("RIGHT", healthbar, "RIGHT", 1, 0)
			bgTexture:SetTexture(gUI:GetStatusBarTexture())
			bgTexture:SetVertexColor(unpack(C["background"]))
			bgTexture:SetAlpha(3/4)
			
			local backdrop = gUI:SetUITemplate(healthbar, "border")
			backdrop:ClearAllPoints()
			backdrop:SetPoint("LEFT", bgTexture, "LEFT", -2, 0)
			backdrop:SetPoint("TOP", bgTexture, "TOP", 0, 2)
			backdrop:SetPoint("BOTTOM", bgTexture, "BOTTOM", 0, -2)
			backdrop:SetPoint("RIGHT", bgTexture, "RIGHT", 2, 0)
			
			gUI:CreateUIShadow(backdrop)
			
			self.SetBackdropBorderColor = backdrop.SetBackdropBorderColor

			skinAllHeals(self)
			skinAllBuffs(nil, self)

			skinned[self] = true
		end
		
		skinAll = function()
			if not(Healium_Frames) then
				return
			end
			for i,frameName in pairs(captionFrames) do
				if (_G[frameName]) then
					skinHeader(_G[frameName])
				end
			end
			for i,frame in pairs(Healium_Frames) do
				skinUnitFrame(frame)
			end
		end
		skinAll()
		
		hooksecurefunc("Healium_UpdateButtonIcon", updateButtonIcon)
		hooksecurefunc("Healium_HealButton_OnLoad", skinHeal)
		hooksecurefunc("HealiumUnitFrames_Button_OnLoad", skinUnitFrame)
		hooksecurefunc("Healium_UpdateUnitBuffs", skinAllBuffs)
		hooksecurefunc("Healium_CreateUnitFrames", skinAll) 
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end