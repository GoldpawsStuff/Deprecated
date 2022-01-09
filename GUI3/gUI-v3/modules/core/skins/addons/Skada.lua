--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Skada")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", self:GetName()) -- don't localize
	self:SetAttribute("description", L["Skins the '%s' addon"]:format(self:GetName()))
	
	local func = function()
		local r, g, b = gUI:GetBackdropColor()
		local getWindow, getMainWindow
		local skinWindow

		getWindow = function(window)
			return _G["SkadaBarWindow" .. (window.db.name or "Skada")]
		end
	
		getMainWindow = function()
			local windows = Skada:GetWindows()
			if (#windows == 1) then
				return getWindow(windows[1])
			else
				local main
				for i,v in pairs(windows) do
					if not(v.name) or (v.name == "Skada") then
						return getWindow(v)
					end
				end
			end
		end

		skinWindow = function(self)
			local db = self.db
			db.scale = 1
		
			db.barslocked = true
			db.classcolorbars = true
			db.classicons = false
		
			db.barbgcolor = { r = r, g = g, b = b, a = 2/3 }
			db.barfont = "PT Sans Narrow"
			db.barfontflags = ""
			db.barfontsize = 12
			db.barheight = 14
			db.barspacing = 1
			db.bartexture = "gUI™ StatusBar"

			db.title.bordertexture = "None"
			db.title.borderthickness = 8
			db.title.color = { r = r, g = g, b = b, a = 0 }
			db.title.font = "PT Sans Narrow"
			db.title.fontflags = ""
			db.title.fontsize = 12
			db.title.height = 20
			db.title.margin = 0
			db.title.texture = "gUI™ StatusBar"
			
			db.background.bordertexture = "None"
			db.background.borderthickness = 8
			db.background.margin = 0
			db.background.color = { r = r, g = g, b = b, a = 0 }
			
			local frame = getWindow(self)
			if (frame) then
				local backdrop = gUI:SetUITemplate(frame, "outerbackdrop")
				backdrop:SetBackdropColor(r, g, b, 2/3)
				backdrop:ClearAllPoints()
				backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, (3 + db.title.height))
				backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3)
				gUI:CreateUIShadow(backdrop)
			end
		end
	
		-- for i,v in pairs(Skada.db.profile.windows) do
		-- end
		local skinAllWindows = function()
			for i,v in pairs(Skada:GetWindows()) do
				skinWindow(v)
			end
			Skada:ApplySettings()
		end
		skinAllWindows()
		hooksecurefunc(Skada, "CreateWindow", skinAllWindows)
		
		local embed = gUI:IsMe()
		if (embed) then
			-- Skada.db.profile.Locked = true
		
			local anchor = ChatFrame4
			local holder = { CreateFrame("Frame", nil, UIParent), CreateFrame("Frame", nil, UIParent) }
			local lock = function()
				local windows = Skada:GetWindows()
				if (#windows == 1) then
					holder[1]:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
					holder[1]:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
					holder[1]:Show()

					holder[2]:Hide()

					local win1 = windows[1].bargroup
					win1:ClearAllPoints()
					win1:SetPoint("TOPLEFT", holder[1], "TOPLEFT", 0, -windows[1].db.title.height)
					win1:SetPoint("BOTTOMRIGHT", holder[1], "BOTTOMRIGHT", 0, -2) -- 1px spacing over panel
					win1.SetPoint = noop
					win1.SetAllPoints = noop
					win1.ClearAllPoints = noop
					
					windows[1].db.barwidth = holder[1]:GetWidth()
					windows[1]:UpdateDisplay()
					
					gUI:GetUIShadow(gUI:GetUITemplate(win1)):ClearAllPoints()
					gUI:GetUIShadow(gUI:GetUITemplate(win1)):SetPoint("TOPLEFT", gUI:GetUITemplate(win1), "TOPLEFT", -3, 3)
					gUI:GetUIShadow(gUI:GetUITemplate(win1)):SetPoint("BOTTOMRIGHT", gUI:GetUITemplate(win1), "BOTTOMRIGHT", 3, -3)
					
				elseif (#windows == 2) then
					holder[1]:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
					holder[1]:SetPoint("BOTTOMRIGHT", anchor, "BOTTOM", -3, 0)
					holder[1]:Show()
					
					holder[2]:SetPoint("TOPLEFT", anchor, "TOP", 3, 0)
					holder[2]:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
					holder[2]:Show()

					local win1 = windows[1].bargroup
					win1:ClearAllPoints()
					win1:SetPoint("TOPLEFT", holder[1], "TOPLEFT", 0, -windows[1].db.title.height)
					win1:SetPoint("BOTTOMRIGHT", holder[1], "BOTTOMRIGHT", 0, -2) -- 1px spacing over panel
					win1.SetPoint = noop
					win1.SetAllPoints = noop
					win1.ClearAllPoints = noop

					windows[1].db.barwidth = holder[1]:GetWidth()
					windows[1]:UpdateDisplay(true)

					local win2 = windows[2].bargroup
					win2:ClearAllPoints()
					win2:SetPoint("TOPLEFT", holder[2], "TOPLEFT", 0, -windows[2].db.title.height)
					win2:SetPoint("BOTTOMRIGHT", holder[2], "BOTTOMRIGHT", 0, -2) -- 1px spacing over panel
					win2.SetPoint = noop
					win2.SetAllPoints = noop
					win2.ClearAllPoints = noop

					windows[2].db.barwidth = holder[2]:GetWidth()
					windows[2]:UpdateDisplay(true)
					
					gUI:GetUIShadow(gUI:GetUITemplate(win1)):ClearAllPoints()
					gUI:GetUIShadow(gUI:GetUITemplate(win1)):SetPoint("TOPLEFT", gUI:GetUITemplate(win1), "TOPLEFT", -3, 3)
					gUI:GetUIShadow(gUI:GetUITemplate(win1)):SetPoint("BOTTOMRIGHT", gUI:GetUITemplate(win2), "BOTTOMRIGHT", 3, -3)
					gUI:GetUIShadow(gUI:GetUITemplate(win2)):Hide()
					
				else
					-- holder[1]:Hide()
					-- holder[2]:Hide()
				end
				Skada:ApplySettings()
				Skada:UpdateDisplay(true)
				self:UnregisterEvent("PLAYER_ENTERING_WORLD", lock)
			end
			hooksecurefunc(Skada, "CreateWindow", lock)
			hooksecurefunc(Skada, "DeleteWindow", lock)
			self:RegisterEvent("PLAYER_ENTERING_WORLD", lock)
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end