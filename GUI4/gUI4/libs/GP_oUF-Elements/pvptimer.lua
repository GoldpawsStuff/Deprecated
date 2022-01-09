local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

-- WoW API
local ceil = math.ceil
local floor = math.floor

-- Lua API
local GetPVPTimer = GetPVPTimer
local IsInInstance = IsInInstance
local IsPVPTimerRunning = IsPVPTimerRunning
local UnitFactionGroup = UnitFactionGroup
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll

local frame
local timers = {}
local threshold = 5 * 60 * 1000 + 1

-- display seconds to min/hour/day
local function time(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return ("%dd"):format(floor(s / day))
	elseif s >= hour then
		local h = floor(s / hour)
		local m = floor((s - h*60) / minute)
		return ("%d:%02d"):format(h, m)
	elseif s >= minute then
		local m = floor(s / minute)
		return ("%d:%02d"):format(m, floor(s - m*60))
	elseif s >= minute / 12 then
		return ("%ss"):format(floor(s))
	end
	return ("%.1f"):format(s)
end

local function OnUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < .05 then return end
	self.elapsed = 0
	if not next(timers) then return end
	local pvp = UnitIsPVP("player")
	local hasTimer = IsPVPTimerRunning()
	local ms = GetPVPTimer()
	local msg, icon = "", ""
	if ms > 0 and ms < threshold and pvp and hasTimer then
		msg = time(ms /1000)
	end	
	local inInstance, instanceType = IsInInstance()
	if pvp and not(inInstance and (instanceType == "pvp" or instanceType == "arena")) then
		local factionGroup = UnitFactionGroup("player")
		if UnitIsPVPFreeForAll("player") then
			icon = [[|TInterface\TargetingFrame\UI-PVP-FFA:0:0:0:0:64:64:5:36:2:39|t]]
		elseif factionGroup == "Horde" then
			icon = [[|TInterface\TargetingFrame\UI-PVP-Horde:0:0:0:0:64:64:1:40:1:38|t]]
		elseif factionGroup == "Alliance" then
			icon = [[|TInterface\TargetingFrame\UI-PVP-Alliance:0:0:0:0:64:64:5:36:2:39|t]]
		end
	end
	for parent, timer in pairs(timers) do
		if pvp then
			if not timer:IsShown() then
				timer:Show()
			end
			timer.Icon:SetFormattedText("%s", icon)
			timer.Time:SetFormattedText("%s", msg)
			if ms and ms > 10000 then
				timer.Time:SetTextColor(.79, .79, .79)
			else
				timer.Time:SetTextColor(.99, .31, .31)
			end
		else
			if timer:IsShown() then
				timer:Hide()
			end
		end
	end
	if not pvp then
		self:SetScript("OnUpdate", nil)
		self:Hide()
	end
end

local Update = function(self, event, ...)
	local unit = ...
	if (event == "UNIT_FACTION" or event == "UNIT_REACTION") and unit ~= "player" then
		return
	end	
	if UnitIsPVP("player") and not frame:IsShown() then
		frame:SetScript("OnUpdate", OnUpdate)
		frame:Show()
	end	
end

local Path = function(self, ...)
	return (self.PvPTimer.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Disable = function(self)
	local PvPTimer = self.PvPTimer
	if PvPTimer then 
		timers[self] = nil
		if not next(timers) then
			frame:SetScript("OnUpdate", nil)
			frame:Hide()
		end
		self:UnregisterEvent("UNIT_FACTION", Path)
		self:UnregisterEvent("UNIT_REACTION", Path)		
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", Path)
	end
end

local Enable = function(self, unit)
	local PvPTimer = self.PvPTimer
	if PvPTimer then 
		if not frame then
			frame = CreateFrame("Frame", nil, UIParent)
			frame:Hide()
		end
		PvPTimer.__owner = self
		PvPTimer.ForceUpdate = ForceUpdate
		timers[self] = PvPTimer
		self:RegisterEvent("UNIT_FACTION", Path)
		self:RegisterEvent("UNIT_REACTION", Path)		
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", Path)
		Path(self, "PLAYER_ENTERING_WORLD")
	end
end

oUF:AddElement("PvPTimer", Path, Enable, Disable)
