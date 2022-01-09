--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Omen")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", self:GetName()) -- don't localize
	self:SetAttribute("description", L["Skins the '%s' addon"]:format(self:GetName()))
	
	local func = function()
		local r, g, b = gUI:GetBackdropColor()
		local r2, g2, b2 = gUI:GetBackdropBorderColor()
		
		Omen.db.profile.Alpha = 1
		
		Omen.db.profile.Background.EdgeSize = 8
		Omen.db.profile.Background.BarInset = 2
		Omen.db.profile.Background.Texture = "Solid"
		Omen.db.profile.Background.Color = { r = r, g = g, b = b, a = 2/3 }
		Omen.db.profile.Background.Tile = nil
		Omen.db.profile.Background.TileSize = nil
		Omen.db.profile.Background.BorderTexture = "gUI™ PixelBorder"
		Omen.db.profile.Background.BorderColor = { r = r2, g = g2, b = b2, a = 1 }

		Omen.db.profile.TitleBar.Height = 20
		Omen.db.profile.TitleBar.Font = "PT Sans Narrow"
		Omen.db.profile.TitleBar.FontColor = { a = 1, r = 1, g = 1, b = 1 }
		Omen.db.profile.TitleBar.FontSize = 12
		Omen.db.profile.TitleBar.FontOutline = nil
		Omen.db.profile.TitleBar.EdgeSize = 8
		Omen.db.profile.TitleBar.Tile = nil
		Omen.db.profile.TitleBar.TileSize = nil
		Omen.db.profile.TitleBar.Texture = "Solid"
		Omen.db.profile.TitleBar.Color = { r = r, g = g, b = b, a = 2/3 }
		Omen.db.profile.TitleBar.UseSameBG = false
		Omen.db.profile.TitleBar.BorderTexture = "gUI™ PixelBorder"
		Omen.db.profile.TitleBar.BorderColor = { r = r2, g = g2, b = b2, a = 1 }
	
		Omen.db.profile.Bar.Texture = "gUI™ StatusBar"
		Omen.db.profile.Bar.Height = 14
		Omen.db.profile.Bar.Font = "PT Sans Narrow"
		Omen.db.profile.Bar.FontColor = { a = 1, r = 1, g = 1, b = 1 }
		Omen.db.profile.Bar.FontSize = 12
		Omen.db.profile.Bar.FontOutline = nil
		Omen.db.profile.Bar.Spacing = 1
		Omen.db.profile.Bar.InvertColors = nil

		Omen:UpdateBarTextureSettings()
		Omen:UpdateBarLabelSettings()
		Omen:UpdateTitleBar()
		Omen:UpdateBackdrop()
		
		gUI:CreateUIShadow(Omen.Anchor)
		
		local embed = gUI:IsMe()
		if (embed) then
			Omen.db.profile.Locked = true
		
			local anchor = ChatFrame4

			local holder = CreateFrame("Frame", nil, UIParent)
			holder:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
			holder:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)

			local target = Omen.Anchor
			target:ClearAllPoints()
			target:SetPoint("TOPLEFT", holder, "TOPLEFT", -3, 3)
			target:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 3, -6) -- 1px spacing over panel
			target.SetPoint = noop
			target.SetAllPoints = noop
			target.ClearAllPoints = noop
			
			local resize = Omen.Anchor:GetScript("OnSizeChanged")
			if (resize) then
				resize()
			end
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end