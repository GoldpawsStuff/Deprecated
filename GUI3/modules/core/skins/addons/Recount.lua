--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Recount")

local defaults = {
	once = false;
}

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", self:GetName()) -- don't localize
	self:SetAttribute("description", L["Skins the '%s' addon"]:format(self:GetName()))
	
	local func = function()
		local Recount = _G.Recount
		local skinFrame, addWindow
		local frames = { 
			Recount["ConfigWindow"], 
			Recount["DetailWindow"], 
			Recount["GraphWindow"], 
			Recount["MainWindow"], 
			Recount["ResetFrame"], 
			_G["Recount_Realtime_!RAID_DAMAGE"] and _G["Recount_Realtime_!RAID_DAMAGE"].Window,
			_G["Recount_Realtime_!RAID_DAMAGETAKEN"] and _G["Recount_Realtime_!RAID_DAMAGETAKEN"].Window,
			_G["Recount_Realtime_!RAID_HEALING"] and _G["Recount_Realtime_!RAID_HEALING"].Window,
			_G["Recount_Realtime_!RAID_HEALINGTAKEN"] and _G["Recount_Realtime_!RAID_HEALINGTAKEN"].Window,
			_G["Recount_Realtime_Bandwidth Available_AVAILABLE_BANDWIDTH"] and _G["Recount_Realtime_Bandwidth Available_AVAILABLE_BANDWIDTH"].Window,
			_G["Recount_Realtime_Downstream Traffic_DOWN_TRAFFIC"] and _G["Recount_Realtime_Downstream Traffic_DOWN_TRAFFIC"].Window,
			_G["Recount_Realtime_FPS_FPS"] and _G["Recount_Realtime_FPS_FPS"].Window,
			_G["Recount_Realtime_Latency_LAG"] and _G["Recount_Realtime_Latency_LAG"].Window,
			_G["Recount_Realtime_Upstream Traffic_UP_TRAFFIC"] and _G["Recount_Realtime_Upstream Traffic_UP_TRAFFIC"].Window
		}

		skinFrame = function(self)
			if not(self) then
				return
			end
			gUI:DisableTextures(self)
			gUI:CreateUIShadow(gUI:SetUITemplate(self, "outerbackdrop", nil, 10, 1, 1, 1))
			gUI:SetUITemplate(self.CloseButton, "closebutton", "TOPRIGHT", -2, -11)
		end
		
		addWindow = function(self, frame)
			if (frame == Recount["ConfigWindow"]) then
				for i = 11, 13 do
					local hide = select(i, frame:GetRegions())
					gUI:KillObject(hide)
				end
				gUI:SetUITemplate(Recount_ConfigWindow_RowHeight_Slider, "slider")
				gUI:SetUITemplate(Recount_ConfigWindow_RowSpacing_Slider, "slider")
				gUI:SetUITemplate(Recount_ConfigWindow_Scaling_Slider, "slider")
			end
			if (frame["NoButton"]) then
				gUI:DisableTextures(frame)
				gUI:SetUITemplate(frame, "backdrop")
				gUI:SetUITemplate(frame["NoButton"], "button", true)
				gUI:SetUITemplate(frame["YesButton"], "button", true)
			end
			if (frame["ReportButton"]) then
				gUI:RemoveClutter(frame)
				gUI:SetUITemplate(frame["ReportButton"], "button", true)
				gUI:SetUITemplate(frame["Whisper"], "editbox")
				gUI:SetUITemplate(frame["slider"], "slider")
			end
		end
		
		Recount.db.profile.Font = "PT Sans Narrow" 
		Recount.db.profile.BarTexture = "gUI™ StatusBar" 
		Recount:SetBarTextures(Recount.db.profile.BarTexture)
		Recount:UpdateBarTextures()

		gUI:SetUITemplate(Recount.MainWindow.RightButton, "arrow", "right")
		gUI:SetUITemplate(Recount.MainWindow.LeftButton, "arrow", "left")

		for i, v in pairs(frames) do
			skinFrame(v)
		end

		local once, doOnce
		doOnce = function()
			if not(once) and (LibDropdownFrame0) then 
				once = true
				gUI:SetUITemplate(LibDropdownFrame0, "backdrop")
			end 
		end
		doOnce()

		Recount.MainWindow.FileButton:HookScript("OnClick", doOnce)
		hooksecurefunc(Recount, "OpenBarDropDown", doOnce)
		hooksecurefunc(Recount, "OpenFightDropDown", doOnce)
		hooksecurefunc(Recount, "OpenModeDropDown", doOnce)
		hooksecurefunc(Recount, "AddWindow", addWindow)
		hooksecurefunc(Recount, "CreateFrame", function(self, name, ...) skinFrame(_G[name]) end)
		
		local embed = gUI:IsMe()
		if (embed) then
			local lock = function()
				Recount:LockWindows(false)
				-- Recount.db.profile.Locked = false
			
				local anchor = ChatFrame4

				local holder = CreateFrame("Frame", nil, UIParent)
				holder:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
				holder:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)

				
				local target = Recount_MainWindow
				target:ClearAllPoints()
				target:SetPoint("TOPLEFT", holder, "TOPLEFT", -1, 9)
				target:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 1, -3) -- 1px spacing over panel
				target.SetPoint = noop
				target.SetAllPoints = noop
				target.ClearAllPoints = noop

				Recount:ResizeMainWindow()
				Recount:LockWindows(true)

				-- Recount.db.profile.Locked = true
				self:UnregisterEvent("PLAYER_ENTERING_WORLD", lock)
			end
			self:RegisterEvent("PLAYER_ENTERING_WORLD", lock)
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end