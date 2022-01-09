local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

-- Lua API
local select, unpack = select, unpack
local ceil, floor = math.ceil, math.floor

-- WoW API
local GetTime = GetTime
local GetTotemInfo = GetTotemInfo
local GetTotemTimeLeft = GetTotemTimeLeft

local widget = "TotemWidget"
local totemmap = { 1, 2, 5, 6, 3, 4 }
local isShaman = select(2, UnitClass("player")) == "SHAMAN"

-- Order the list based upon the default UIs priorities.
local priorities = STANDARD_TOTEM_PRIORITIES
if isShaman then
	priorities = SHAMAN_TOTEM_PRIORITIES
end

local UpdateVisibility = function(self, event, arg1)
	local totems = self[widget]
	if self.unit ~= "player" then
		totems:Hide()
	else
		self.activeTotems = 0
		for i = 1, MAX_TOTEMS do
			local haveTotem, name, start, duration, icon = GetTotemInfo(priorities[i])
			if duration > 0 then 
				self.activeTotems = self.activeTotems + 1/3
				break
			end
		end
		if self.activeTotems > 0 then
			totems:Show()
		else
			totems:Hide()
		end
	end
end

local DAY, HOUR, MINUTE = 86400, 3600, 60
local function formatTime(s)
	-- return ("|cff999999%dm|r"):format(ceil(s / MINUTE))
	if s > 0 and s < 6 then
		return ("|cffff0000%.1f|r"):format(s)
	elseif s < 10 then
		return ("|cffff8800%1d|r"):format(floor(s))
	elseif s < 60 then
		return ("|cffcccccc%1d|r"):format(floor(s))
	else
		return ""
	end
end

local OnUpdate = function(self, elapsed)
	local duration = self.duration + elapsed
	local spark = self.spark
	if spark then
		if duration >= self.max or duration == 0 or self.max > 60 then
			spark:Hide()
		else
			if not spark:IsShown() then
				spark:Show()
			end
		end
	end
	if duration >= self.max then
		UpdateVisibility(self.__owner)
		if self.value then
			self.value:SetText("")
		end
		return self:SetScript("OnUpdate", nil)
	else
		self.duration = duration
		if self.value then
			self.value:SetText(formatTime(self.max - duration))
		end
		return self:SetValue(self.max - duration)
	end
end

local UpdateTooltip = function(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:SetTotem(self:GetID())
	end
end

local OnEnter = function(self)
	if not self:IsVisible() then return end
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		self:UpdateTooltip()
	end
end

local OnLeave = function()
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end

local UpdateTotem = function(self, event, slot)
	if slot > MAX_TOTEMS then return end
	local totems = self[widget]
	if totems.PreUpdate then 
		totems:PreUpdate(priorities[slot]) 
	end
	local totem = totems[priorities[slot]]
	local haveTotem, name, start, duration, icon = GetTotemInfo(slot)
	local min = GetTotemTimeLeft(slot)
	local colors = self.colors.power.TOTEM[slot]
	local r, g, b = colors[1], colors[2], colors[3]
	totem:SetStatusBarColor(r, g, b)
	if totem.bg then
		local mu = totem.bg.multiplier or 1/3
		totem.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
	if duration > 0 then
		totem:SetMinMaxValues(0, duration)
		totem:SetValue(duration - min)
		totem.max = duration
		totem.duration = GetTime() - start
		totem:SetScript("OnUpdate", OnUpdate)
		totem:Show() -- to fire off the shine script
	else
		totem:SetScript("OnUpdate", nil)
		totem:SetValue(0)
		local spark = totem.spark
		if spark then
			spark:Hide()
		end
	-- totem:Hide()
	end
	UpdateVisibility(self)
	if totems.PostUpdate then
		return totems:PostUpdate(priorities[slot], haveTotem, name, start, duration, icon)
	end
end

local Path = function(self, ...)
	return (self[widget].Override or UpdateTotem) (self, ...)
end

local Update = function(self, event)
	for i = 1, MAX_TOTEMS do
		Path(self, event, i)
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, "ForceUpdate")
end

local Disable = function(self)
	local totems = self[widget]
	if totems then
		for i = 1, MAX_TOTEMS do
			totems[i]:Hide()
		end
		totems:Hide()
		TotemFrame.Show = nil
		TotemFrame:Show()
		TotemFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")
		TotemFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		TotemFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
		TotemFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:UnregisterEvent("PLAYER_TOTEM_UPDATE", Path)
	end
end

local Enable = function(self, unit)
	local totems = self[widget]
	if totems then
		if not isShaman then
			totems:Hide()
			return
		end
		totems.__owner = self
		totems.__map = { unpack(priorities) }
		totems.ForceUpdate = ForceUpdate
		for i = 1, MAX_TOTEMS do
			local totem = totems[i]
			totem:SetID(priorities[i])
			totem.__owner = self
			if totem:IsMouseEnabled() then
				totem:SetScript("OnEnter", OnEnter)
				totem:SetScript("OnLeave", OnLeave)
				if not totem.UpdateTooltip then
					totem.UpdateTooltip = UpdateTooltip
				end
			end
		end
		self:RegisterEvent("PLAYER_TOTEM_UPDATE", Path, true)
		TotemFrame.Show = TotemFrame.Hide
		TotemFrame:Hide()
		TotemFrame:UnregisterEvent("PLAYER_TOTEM_UPDATE")
		TotemFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		TotemFrame:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
		TotemFrame:UnregisterEvent("PLAYER_TALENT_UPDATE")
		return true
	end
end

oUF:AddElement(widget, Update, Enable, Disable)
