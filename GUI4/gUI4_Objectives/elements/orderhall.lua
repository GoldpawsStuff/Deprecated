local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local module = parent:NewModule("OrderHall", "GP_AceEvent-3.0")

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local defaults = {
}

local function updateConfig()
	T = parent:GetActiveTheme().worldstate
end

function module:UpdateOrderHallUI()
	local frame = self.frame
	local bar = OrderHallCommandBar

	local index = 1
	C_Timer.After(0.1, function()
		local last
		for i, child in ipairs({bar:GetChildren()}) do
			if child.Icon and child.Count and child.TroopPortraitCover then
				child:ClearAllPoints()
				child:SetPoint("LEFT", bar.Currency, "RIGHT", 10 + (index-1)*70, 0)
				child:SetWidth(60)

				child.TroopPortraitCover:Hide()
				child.Icon:ClearAllPoints()
				child.Icon:SetPoint("LEFT", child, "LEFT", 0, 0)
				child.Icon:SetSize(32, 16)

				child.Count:ClearAllPoints()
				child.Count:SetPoint("LEFT", child.Icon, "RIGHT", 5, 0)
				child.Count:SetTextColor(.9, .9, .9)
				child.Count:SetShadowOffset(.75, -.75)
				
				last = child.Count

				index = index + 1
			end
		end

		local firstX = bar.CurrencyIcon:GetLeft()
		local lastX = last and last:GetRight() or bar.Currency:GetRight()  
		local width = lastX - firstX

		frame:SetWidth(width)
	end)
end

function module:SetUpOrderHallUI()
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateOrderHallUI")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateOrderHallUI")
	self:RegisterEvent("GARRISON_FOLLOWER_CATEGORIES_UPDATED", "UpdateOrderHallUI")
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED", "UpdateOrderHallUI")
	self:RegisterEvent("GARRISON_FOLLOWER_REMOVED", "UpdateOrderHallUI")

	self.styled = false

	OrderHallCommandBar:HookScript("OnShow", function()
		local frame = self.frame

		if (not self.styled) then
			local bar = OrderHallCommandBar

			bar:EnableMouse(false)
			bar.Background:SetAtlas(nil)

			bar.ClassIcon:Hide()
			bar.AreaName:Hide()

			bar.CurrencyIcon:ClearAllPoints()
			bar.CurrencyIcon:SetPoint("LEFT", frame, "LEFT", 0, 0)

			bar.Currency:ClearAllPoints()
			bar.Currency:SetPoint("LEFT", bar.CurrencyIcon, "RIGHT", 5, 0)
			bar.Currency:SetTextColor(.9, .9, .9)
			bar.Currency:SetShadowOffset(0.75, -.75)

			bar.WorldMapButton:UnregisterAllEvents()
			bar.WorldMapButton:Hide()

			self.styled = true
		end

		gUI4:SetOffset("TOP", frame, 32, "CENTER")
	end)

	OrderHallCommandBar:HookScript("OnHide", function()
		gUI4:SetOffset("TOP", self.frame, 32, "CENTER")
	end)
end

function module:Lock()
end

function module:Unlock()
end

function module:ResetLock()
end

function module:ApplySettings()
	if not self.frame then return end
	updateConfig()
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	local frame = parent:GetModule("WorldState").frame
	if frame then 
		self.frame:ClearAllPoints()
		self.frame:SetPoint("CENTER", frame, "CENTER", 0, 0)
	end
end

function module:ADDON_LOADED(_, addonName)
	if addonName == "Blizzard_OrderHallUI" then
		self:UnregisterEvent("ADDON_LOADED")
		self:SetUpOrderHallUI()
	end
end

function module:OnInitialize()
	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame:SetSize(20,20)

	if IsAddOnLoaded("Blizzard_OrderHallUI") then
		self:SetUpOrderHallUI()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

function module:OnEnable()
	self:ApplySettings()
end

function module:OnDisable()
end

