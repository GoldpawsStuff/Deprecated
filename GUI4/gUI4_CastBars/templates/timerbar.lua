local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_CastBars = gUI4:GetModule("gUI4_CastBars", true)
if not gUI4_CastBars then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 22124 
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

-- Lua API
local abs, floor, max = math.abs, math.floor, math.max

-- WoW API
local GetTime = GetTime

local StatusBar = gUI4_CastBars.StatusBar
local TimerBar = setmetatable({}, { __index = StatusBar })
local TimerBar_MT = { __index = TimerBar }
gUI4_CastBars.TimerBar = TimerBar

function TimerBar:ApplySettings(settings)
	StatusBar.ApplySettings(self, settings)
end

local extraTime = 1.5 -- seconds to keep the timer visible after it ends
function TimerBar:Start(timerID, currentBarValue, minBarValue, maxBarValue, changePerSecond, paused, label)
	self.info.HZ = .1 
	
	if changePerSecond < 0 then
		self.info.ending = GetTime() + abs(currentBarValue / changePerSecond) -- all normal timers
		self.info.started = self.info.ending - abs((maxBarValue - currentBarValue) / changePerSecond)
	else 
		self.info.ending = GetTime() + abs((maxBarValue - currentBarValue) / changePerSecond) -- breathtimer when exiting water
		self.info.started = self.info.ending - abs(currentBarValue/changePerSecond)
	end
	
	self.info.minValue = minBarValue
	self.info.maxValue = maxBarValue
	self.info.value = currentBarValue
	self.info.change = changePerSecond
	
	self.info.timerID = timerID
	self.info.paused = paused
	self.info.label = label

	self.name:SetText(label)
	self:SetMinMaxValues(minBarValue, maxBarValue) 
	self:SetValue(currentBarValue)
	self:SetStatusBarDisplayValue(currentBarValue)
	self:Show()
end

function TimerBar:Stop()
	self:Hide()
	if self.OnHide then
		self:OnHide() -- let the module perform tasks before wiping this bar's info
	end
	wipe(self.info)
end

local DAY, HOUR, MINUTE = 86400, 3600, 60
function TimerBar:SetStatusBarDisplayValue(value)
	if value > DAY then
		self.value:SetFormattedText("%1dd", floor(value / DAY))
	elseif value > HOUR then
		self.value:SetFormattedText("%1dh", floor(value / HOUR))
	elseif value > MINUTE*3 then
		self.value:SetFormattedText("%1dm", floor(value / MINUTE))
	elseif value > MINUTE then
		self.value:SetFormattedText("%1d:%02d", floor(value / MINUTE), value%MINUTE)
	elseif value > 10 then 
		self.value:SetFormattedText("%1d", floor(value))
	elseif value > 5 then
		self.value:SetFormattedText("|cffff8800%1d|r", floor(value))
	elseif value > 0 then
		self.value:SetFormattedText("|cffff0000%.1f|r", value)
	else
		self.value:SetText(READY)
		-- self.value:SetText("|cffff00000.0|r")
	end	
end

function TimerBar:SetStatusBarValue(value)
	local min, max = self:GetMinMaxValues()
	-- if value < max and value > min then
		-- local pixelperfect = floor((value/max)*self:GetWidth())/self:GetWidth()*max
		-- value = pixelperfect -- pixelperfection looks really bad on slow moving bars. no movement, just steps. :/
	-- end
	self:SetValue(value)
	local spark = self.spark
	if spark then
		if value == max or value == 0 then
			spark:Hide()
		else
			if not spark:IsShown() then
				spark:Show()
			end
		end
	end
	local pulse = self.pulse
	if pulse then
		-- if value == max or value == 0 or value/max > (pulse.threshold or .35) then -- todo: smarter percentages based on situation (pvp, raid, etc)
		if value == max or value == 0 or value > 10 then 
			pulse:Hide()
		else
			if not pulse:IsShown() then
				pulse:Show()
			end
		end
	end
end

function TimerBar:OnUpdate(elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if not(self.info.paused) or self.info.paused == 0 then
		self.info.value = self.info.value + elapsed * self.info.change
	end
	local value = (self.info.value < self.info.minValue) and self.info.minValue or (self.info.value > self.info.maxValue) and self.info.maxValue or self.info.value
	self:SetStatusBarValue(value)
	if self.info.value < 5 then
		self.info.HZ = .1
	else
		self.info.HZ = 1
	end
	-- if self.elapsed > self.info.HZ then
		self:SetStatusBarDisplayValue(value)
		self.elapsed = 0
	-- end
	if self.info.value <= (self.info.minValue - extraTime) then
		self:Stop()
	end
end

function TimerBar:Enable()
	self:SetScript("OnUpdate", self.OnUpdate)
	StatusBar.Enable(self)
end

function TimerBar:Disable()
	self:SetScript("OnUpdate", nil)
	StatusBar.Disable(self)
end

function TimerBar:New(id, name, settingsFunc)
	local bar = setmetatable(StatusBar:New(id, name, settingsFunc), TimerBar_MT)
	bar.name = LMP:NewChain("FontString", nil, bar) :SetDrawLayer("OVERLAY", 0) :SetFontObject(GameFontNormalSmall) :SetPoint("LEFT", 10, 0) .__EndChain
	bar.icon = LMP:NewChain(bar:CreateTexture()) :SetDrawLayer("BORDER", 0) .__EndChain
	bar.icon.border = LMP:NewChain(bar:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
	
	if LEGION then -- Legion
		bar.pulse = LMP:NewChain(bar:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 1) :SetAllPoints(bar:GetStatusBarTexture()) :SetBlendMode("BLEND") :SetTexture(1,0,0,.5) .__EndChain
		bar.pulse.Anim = LMP:NewChain(bar.pulse:CreateAnimationGroup()) :SetLooping("REPEAT") .__EndChain
		bar.pulse.Anim.start = LMP:NewChain(bar.pulse.Anim:CreateAnimation("Alpha")) :SetToAlpha(0) :SetDuration(0) :SetSmoothing("IN") :SetOrder(0) .__EndChain
		bar.pulse.Anim.fadeIn = LMP:NewChain(bar.pulse.Anim:CreateAnimation("Alpha")) :SetToAlpha(.5) :SetDuration(.5) :SetOrder(1) .__EndChain
		bar.pulse.Anim.fadeOut = LMP:NewChain(bar.pulse.Anim:CreateAnimation("Alpha")) :SetToAlpha(0) :SetDuration(.5) :SetOrder(2) .__EndChain
		bar.pulse.Anim:Play()
	else
		bar.pulse = LMP:NewChain(bar:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 1) :SetAllPoints(bar:GetStatusBarTexture()) :SetBlendMode("BLEND") :SetTexture(1,0,0,.5) .__EndChain
		bar.pulse.Anim = LMP:NewChain(bar.pulse:CreateAnimationGroup()) :SetLooping("REPEAT") .__EndChain
		bar.pulse.Anim.start = LMP:NewChain(bar.pulse.Anim:CreateAnimation("Alpha")) :SetChange(-1) :SetDuration(0) :SetSmoothing("IN") :SetOrder(0) .__EndChain
		bar.pulse.Anim.fadeIn = LMP:NewChain(bar.pulse.Anim:CreateAnimation("Alpha")) :SetChange(.5) :SetDuration(.5) :SetOrder(1) .__EndChain
		bar.pulse.Anim.fadeOut = LMP:NewChain(bar.pulse.Anim:CreateAnimation("Alpha")) :SetChange(-.5) :SetDuration(.5) :SetOrder(2) .__EndChain
		bar.pulse.Anim:Play()
	end	
	
	bar.info = {}
	return bar
end


function TimerBar:Update()
end

