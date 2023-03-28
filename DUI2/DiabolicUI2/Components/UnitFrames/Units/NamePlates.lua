--[[

	The MIT License (MIT)

	Copyright (c) 2023 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
local Addon, ns = ...
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end

-- Lua API
local _G = _G

-- WoW API
local CreateFrame = CreateFrame

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

-- Callbacks
--------------------------------------------
-- Forceupdate health prediction on health updates,
-- to assure our smoothed elements are properly aligned.
local Health_PostUpdate = function(element, unit, cur, max)
	local predict = element.__owner.HealthPrediction
	if (predict) then
		predict:ForceUpdate()
	end
end

-- Update the health preview color on health color updates.
local Health_PostUpdateColor = function(element, unit, r, g, b)
	local preview = element.Preview
	if (preview) then
		preview:SetStatusBarColor(r * .7, g * .7, b * .7)
	end
end

-- Align our custom health prediction texture
-- based on the plugin's provided values.
local HealPredict_PostUpdate = function(element, unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb, curHealth, maxHealth)

	local allIncomingHeal = myIncomingHeal + otherIncomingHeal
	local allNegativeHeals = healAbsorb
	local showPrediction, change

	if ((allIncomingHeal > 0) or (allNegativeHeals > 0)) and (maxHealth > 0) then
		local startPoint = curHealth/maxHealth

		-- Dev switch to test absorbs with normal healing
		--allIncomingHeal, allNegativeHeals = allNegativeHeals, allIncomingHeal

		-- Hide predictions if the change is very small, or if the unit is at max health.
		change = (allIncomingHeal - allNegativeHeals)/maxHealth
		if ((curHealth < maxHealth) and (change > (element.health.predictThreshold or .05))) then
			local endPoint = startPoint + change

			-- Crop heal prediction overflows
			if (endPoint > 1) then
				endPoint = 1
				change = endPoint - startPoint
			end

			-- Crop heal absorb overflows
			if (endPoint < 0) then
				endPoint = 0
				change = -startPoint
			end

			-- This shouldn't happen, but let's do it anyway.
			if (startPoint ~= endPoint) then
				showPrediction = true
			end
		end
	end

	if (showPrediction) then

		local preview = element.preview
		local growth = preview:GetGrowth()
		local min,max = preview:GetMinMaxValues()
		local value = preview:GetValue() / max
		local previewTexture = preview:GetStatusBarTexture()
		local previewWidth, previewHeight = preview:GetSize()
		local left, right, top, bottom = preview:GetTexCoord()

		if (growth == "RIGHT") then

			local texValue, texChange = value, change
			local rangeH, rangeV

			rangeH = right - left
			rangeV = bottom - top
			texChange = change*value
			texValue = left + value*rangeH

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMRIGHT", 0, 0)
				element:SetSize((-change)*previewWidth, previewHeight)
				element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				element:SetVertexColor(.5, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end

		elseif (growth == "LEFT") then
			local texValue, texChange = value, change
			local rangeH, rangeV
			rangeH = right - left
			rangeV = bottom - top
			texChange = change*value
			texValue = left + value*rangeH

			if (change > 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMRIGHT", previewTexture, "BOTTOMLEFT", 0, 0)
				element:SetSize(change*previewWidth, previewHeight)
				element:SetTexCoord(texValue + texChange, texValue, top, bottom)
				element:SetVertexColor(0, .7, 0, .25)
				element:Show()

			elseif (change < 0) then
				element:ClearAllPoints()
				element:SetPoint("BOTTOMLEFT", previewTexture, "BOTTOMLEFT", 0, 0)
				element:SetSize((-change)*previewWidth, previewHeight)
				element:SetTexCoord(texValue, texValue + texChange, top, bottom)
				element:SetVertexColor(.5, 0, 0, .75)
				element:Show()

			else
				element:Hide()
			end
		end
	else
		element:Hide()
	end

end

-- Update cast bar color to indicate protected casts.
local Cast_UpdateInterruptible = function(element, unit)
	if (element.notInterruptible) then
		element:SetStatusBarColor(unpack(Colors.red))
	else
		element:SetStatusBarColor(unpack(Colors.cast))
	end
end

-- Update power bar visibility if a frame
-- is the perrsonal resource display.
local Power_PostUpdate = function(element, unit, cur, min, max)
	local self = element.__owner
	if (not unit) then
		unit = self.unit
	end
	if (not unit) then
		return
	end

	local shouldShow

	if (self.isPRD) then
		if (not cur) then
			cur, max = UnitPower(unit), UnitPowerMax(unit)
		end
		if (cur and cur == 0) and (max and max == 0) then
			shouldShow = nil
		else
			shouldShow = true
		end
	end

	local power = self.Power

	if (shouldShow) then
		if (power.isHidden) then
			local health = self.Health
			health:ClearAllPoints()
			health:SetPoint("CENTER", 0, 5)

			local cast = self.Castbar
			cast:ClearAllPoints()
			cast:SetPoint("CENTER", health, 0, -20)

			power:SetAlpha(1)
			power.isHidden = false
		end
	else
		if (not power.isHidden) then
			local health = self.Health
			health:ClearAllPoints()
			health:SetPoint("CENTER", 0, 0)

			power:SetAlpha(0)
			power.isHidden = true

			local cast = self.Castbar
			cast:ClearAllPoints()
			cast:SetPoint("CENTER", health, 0, -10)
		end
	end

end

-- Highlight current target and focus units.
local Plate_UpdateHighlight = function(self)
	local highlight = self.Highlight
	if (not highlight) then
		return
	end
	if (UnitIsUnit("target", self.unit)) then
		highlight:SetBackdropBorderColor(1, 1, 1)
		highlight:Show()
	elseif (UnitIsUnit("focus", self.unit)) then
		highlight:SetBackdropBorderColor(144/255, 195/255, 255/255)
		highlight:Show()
	else
		highlight:Hide()
	end
end

local UnitFrame_PostUpdate = function(self)
	Plate_UpdateHighlight(self)
	if (self.isPRD) then
		self:DisableElement("RaidTargetIndicator")
	else
		self:EnableElement("RaidTargetIndicator")
		self.RaidTargetIndicator:ForceUpdate()
	end
end

UnitStyles["NamePlate"] = function(self, unit, id)

	self:SetSize(75,45) -- 90,45
	self.colors = ns.Colors

	-- Health
	--------------------------------------------
	local health = self:CreateBar(self:GetName().."HealthBar")
	health:SetSize(75,5) -- 90,6
	health:SetPoint("CENTER")
	health:SetStatusBarTexture(GetMedia("bar-small"))
	health:SetSparkTexture(GetMedia("blank"))
	health.colorDisconnected = true
	health.colorTapping = true
	health.colorClass = true
	health.colorReaction = true
	health.colorThreat = true
	health.colorHealth = true

	local healthBorder = health:CreateTexture(nil, "BACKGROUND", nil, -2)
	healthBorder:SetPoint("TOPLEFT", -2, 2)
	healthBorder:SetPoint("BOTTOMRIGHT", 2, -2)
	healthBorder:SetColorTexture(0, 0, 0, .75)
	health.Border = healthBorder

	local healthBackdrop = health:CreateTexture(nil, "BACKGROUND", nil, -1)
	healthBackdrop:SetPoint("TOPLEFT", 0, 0)
	healthBackdrop:SetPoint("BOTTOMRIGHT", 0, 0)
	healthBackdrop:SetColorTexture(.6, .6, .6, .05)
	health.Backdrop = healthBackdrop

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth
	self.Health.PostUpdate = Health_PostUpdate
	self.Health.PostUpdateColor = Health_PostUpdateColor

	-- Health Preview
	--------------------------------------------
	local preview = self:CreateBar(health:GetName().."Preview", health)
	preview:SetFrameLevel(health:GetFrameLevel() - 1)
	preview:SetSize(75,5)
	preview:SetPoint("CENTER")
	preview:SetStatusBarTexture(GetMedia("bar-small"))
	preview:SetSparkTexture(GetMedia("blank"))
	preview:SetAlpha(.5)
	preview:DisableSmoothing(true)

	self.Health.Preview = preview

	-- Health Prediction
	--------------------------------------------
	local healPredictFrame = CreateFrame("Frame", nil, health)
	healPredictFrame:SetFrameLevel(health:GetFrameLevel() + 2)
	healPredictFrame:SetAllPoints()

	local healPredict = healPredictFrame:CreateTexture(health:GetName().."Prediction", "OVERLAY")
	healPredict:SetTexture(GetMedia("bar-small"))
	healPredict.health = health
	healPredict.preview = preview
	healPredict.maxOverflow = 1

	self.HealthPrediction = healPredict
	self.HealthPrediction.PostUpdate = HealPredict_PostUpdate

	-- Power
	--------------------------------------------
	local power = self:CreateBar()
	power:SetSize(75,5)
	power:SetPoint("CENTER", health, 0, -10)
	power:SetStatusBarTexture(GetMedia("bar-small"))
	power:SetSparkTexture(GetMedia("blank"))
	power:SetAlpha(0)
	power.isHidden = true
	power.colorPower = true
	power.PostUpdate = Power_PostUpdate

	local powerBorder = power:CreateTexture(nil, "BACKGROUND", nil, -2)
	powerBorder:SetPoint("TOPLEFT", -2, 2)
	powerBorder:SetPoint("BOTTOMRIGHT", 2, -2)
	powerBorder:SetColorTexture(0, 0, 0, .75)
	power.Border = powerBorder

	local powerBackdrop = power:CreateTexture(nil, "BACKGROUND", nil, -1)
	powerBackdrop:SetPoint("TOPLEFT", 0, 0)
	powerBackdrop:SetPoint("BOTTOMRIGHT", 0, 0)
	powerBackdrop:SetColorTexture(.6, .6, .6, .05)
	power.Backdrop = powerBackdrop

	self.Power = power
	self.Power.Override = ns.API.UpdatePower

	-- Highlight
	--------------------------------------------
	local highlight = CreateFrame("Frame", nil, health, ns.BackdropTemplate)
	highlight:SetPoint("TOPLEFT", -7, 7)
	highlight:SetPoint("BOTTOMRIGHT", 7, -7)
	highlight:SetBackdrop({ edgeFile = GetMedia("border-glow"), edgeSize = 8 })
	highlight:SetFrameLevel(0)
	highlight:Hide()

	self.Highlight = highlight

	self:RegisterEvent("PLAYER_TARGET_CHANGED", Plate_UpdateHighlight, true)
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", Plate_UpdateHighlight, true)

	-- Castbar
	--------------------------------------------
	local cast = self:CreateBar()
	cast:Hide()
	cast:SetSize(75,5)
	cast:SetPoint("CENTER", health, 0, -10)
	cast:SetStatusBarTexture(GetMedia("bar-small"))
	cast:SetSparkTexture(GetMedia("blank"))
	cast:SetStatusBarColor(64/255, 128/255, 255/255)
	cast:DisableSmoothing(true)
	cast.PostCastInterruptible = Cast_UpdateInterruptible
	cast.PostCastStart = Cast_UpdateInterruptible

	local castBorder = cast:CreateTexture(nil, "BACKGROUND", nil, -2)
	castBorder:SetPoint("TOPLEFT", -2, 2)
	castBorder:SetPoint("BOTTOMRIGHT", 2, -2)
	castBorder:SetColorTexture(0, 0, 0, .75)
	cast.Border = castBorder

	local castBackdrop = cast:CreateTexture(nil, "BACKGROUND", nil, -1)
	castBackdrop:SetPoint("TOPLEFT", 0, 0)
	castBackdrop:SetPoint("BOTTOMRIGHT", 0, 0)
	castBackdrop:SetColorTexture(.6, .6, .6, .05)
	cast.Backdrop = castBackdrop

	local castIcon = cast:CreateTexture(nil, "ARTWORK", nil, 0)
	castIcon:SetSize(16, 16)
	castIcon:SetPoint("TOPRIGHT", health, "TOPLEFT", -6, 0)
	castIcon:SetMask(GetMedia("actionbutton-mask-square"))
	castIcon:SetAlpha(.85)
	cast.Icon = castIcon

	local castIconFrame = CreateFrame("Frame", nil, cast, ns.BackdropTemplate)
	castIconFrame:SetPoint("TOPLEFT", castIcon, "TOPLEFT", -5, 5)
	castIconFrame:SetPoint("BOTTOMRIGHT", castIcon, "BOTTOMRIGHT", 5, -5)
	castIconFrame:SetBackdrop({ edgeFile = GetMedia("border-glow"), edgeSize = 8 })
	castIconFrame:SetBackdropBorderColor(0, 0, 0, 1)
	castIconFrame:SetFrameLevel(0)
	castIcon.Frame = castIconFrame

	local castIconBackdrop = castIconFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
	castIconBackdrop:SetPoint("TOPLEFT", 3, -3)
	castIconBackdrop:SetPoint("BOTTOMRIGHT", -3, 3)
	castIconBackdrop:SetColorTexture(0, 0, 0, .75)
	castIcon.Backdrop = castIconBackdrop

	self.Castbar = cast

	-- Raid Target Indicator
	--------------------------------------------
	local raidTarget = self:CreateTexture(nil, "OVERLAY", nil, 1)
	raidTarget:SetSize(64, 64)
	raidTarget:SetPoint("BOTTOM", 0, 54)
	raidTarget:SetTexture(GetMedia("raid_target_icons"))

	self.RaidTargetIndicator = raidTarget

	-- Auras
	--------------------------------------------
	local auras = CreateFrame("Frame", nil, self)
	auras:SetSize(30*3-4, 26)
	auras:SetPoint("BOTTOM", self.Health, "TOP", 0, 6)
	auras.size = 26
	auras.spacing = 4
	auras.numTotal = 6
	auras.disableMouse = true
	auras.disableCooldown = false
	auras.onlyShowPlayer = false
	auras.showStealableBuffs = false
	auras.initialAnchor = "BOTTOMLEFT"
	auras["spacing-x"] = 4
	auras["spacing-y"] = 4
	auras["growth-x"] = "RIGHT"
	auras["growth-y"] = "UP"
	auras.sortMethod = "TIME_REMAINING"
	auras.sortDirection = "DESCENDING"
	auras.reanchorIfVisibleChanged = true
	auras.CustomFilter = ns.AuraFilters.NameplateAuraFilter
	auras.CreateButton = ns.AuraStyles.CreateButton
	auras.PostUpdateButton = ns.AuraStyles.NameplatePostUpdateButton
	auras.PreSetPosition = ns.AuraSorts.Default -- only in classic
	auras.SortAuras = ns.AuraSorts.DefaultFunction -- only in retail

	self.Auras = auras

	self.PostUpdate = UnitFrame_PostUpdate

end