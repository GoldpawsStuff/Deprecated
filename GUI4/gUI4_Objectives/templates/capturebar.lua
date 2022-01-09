local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_Objectives = gUI4:GetModule("gUI4_Objectives", true)
if not gUI4_Objectives then return end

local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local floor, min, max = math.floor, math.min, math.max
local tonumber, tostring = tonumber, tostring

local Bar = gUI4_Objectives.Bar 
local CaptureBar = setmetatable({}, { __index = Bar })
local CaptureBar_MT = { __index = CaptureBar }
gUI4_Objectives.CaptureBar = CaptureBar

local function short(value)
	value = tonumber(value)
	if not value then return "" end
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return tostring(value)
	end	
end

function CaptureBar:ApplySettings(settings)
	Bar.ApplySettings(self, settings)
end

function CaptureBar:Update()
	local min, max = self:GetMinMaxValues()
	local value = self:GetValue()
	local percentage = value/max*100
	-- local neutralpercent = self:GetNeutralPercent(true)
	-- local spark = self.spark
	-- local x = (value-min)/(max-min)*(self:GetWidth() or 0)
	-- spark:SetPoint("LEFT", self.bar, "LEFT", x, 0) -- don't round off x, we want a fluid statusbar-like motion
	self.bar:SetMinMaxValues(min, max)
	self.bar:SetValue(value)

	if percentage < .5 or percentage > 99.5 then -- hide directional indicators close to the edges
		self.left.indicator:Hide()
		self.right.indicator:Hide()
	elseif value < self._value then -- moving left
		self.left.indicator:Show()
		self.right.indicator:Hide()
	elseif value > self._value then -- moving right
		self.left.indicator:Hide()
		self.right.indicator:Show()
	else -- no current movement
		self.left.indicator:Hide()
		self.right.indicator:Hide()
	end	
end

function CaptureBar:SetValue(value)
	-- if value == self._value then return end
	-- direction indicator visibility
	self._value = value
	self._oldvalue = self._value
	self:Update()
end

function CaptureBar:SetMinMaxValues(min, max)
	self._min = min
	self._max = max
	self:Update()
end

function CaptureBar:GetMinMaxValues()
	return self._min, self._max
end

function CaptureBar:GetValue()
	return self._value
end

function CaptureBar:SetCaptureBarValue(value)
	self:SetValue(value)
	self.value:SetText(short(value))
	self:Update()
end

function CaptureBar:SetNeutralPercent(neutralpercent)
	if neutralpercent == self._neutral then return end
	self._oldneutral = self._neutral
	self._neutral = min(max(neutralpercent, 0.0001), 100) -- it needs a minimum size, or it'll disappear and bug out the bar
	
	local x = neutralpercent/100
	
	self.middle:SetWidth(self:GetWidth() * x)
	
	self.left:SetTexCoord(0, x, 0, 1)
	self.middle:SetTexCoord(x, 1-x, 0, 1)
	self.right:SetTexCoord(1-x, 1, 0, 1)
	
	self:Update()
end

function CaptureBar:GetNeutralPercent(round)
	return round and floor(self._neutral) or self._neutral
end

local numbars = 0
function CaptureBar:New(id, name, settingsFunc)
	numbars = numbars + 1
	local bar = setmetatable(Bar:New(id, name, settingsFunc, CreateFrame("Frame", "GUI4CaptureBar"..numbars, UIParent)), CaptureBar_MT)
	bar._value = 1/2
	bar._min = 0
	bar._max = 1
	bar._neutral = 0.0001

	-- backdrop and border aligned to the main scaffold frame
	bar.backdrop = LMP:NewChain(bar.bar:CreateTexture()) :SetDrawLayer("BACKGROUND", 1) :SetAllPoints() .__EndChain
	bar.border = LMP:NewChain(bar.bar:CreateTexture()) :SetDrawLayer("BORDER", 4) :SetAllPoints() .__EndChain
	-- bar.value = LMP:NewChain("FontString", nil, bar) :SetFontObject(TextCaptureBarText) :SetPoint("TOPRIGHT", -4, -4) .__EndChain

	-- textures, overlay, spark and indicators aligned to the 'bar' frame, which isn't shown but act as a positioning guide
	bar.spark = LMP:NewChain(bar.bar:CreateTexture()) :SetPoint("TOP", bar.bar, 0, 0) :SetPoint("BOTTOM", bar.bar, 0, 0) :SetPoint("RIGHT", bar.bar:GetStatusBarTexture(), 0, 0) :SetWidth(2) :SetDrawLayer("BORDER", 3) .__EndChain
	bar.overlay = LMP:NewChain(bar.bar:CreateTexture()) :SetAllPoints(bar.bar) :SetDrawLayer("BORDER", 2) .__EndChain
	bar.middle = LMP:NewChain(bar.bar:CreateTexture()) :SetPoint("TOP", bar.bar, 0, 0) :SetPoint("BOTTOM", bar.bar, 0, 0) :SetWidth(0.0001) :SetDrawLayer("BORDER", 1) .__EndChain
	bar.left = LMP:NewChain(bar.bar:CreateTexture()) :SetPoint("TOP", bar.bar, 0, 0) :SetPoint("BOTTOM", bar.bar, 0, 0) :SetPoint("LEFT", bar.bar, 0, 0) :SetPoint("RIGHT", bar.middle, "LEFT", 0, 0) :SetDrawLayer("BORDER", 1) .__EndChain
	bar.right = LMP:NewChain(bar.bar:CreateTexture()) :SetPoint("TOP", bar.bar, 0, 0) :SetPoint("BOTTOM", bar.bar, 0, 0) :SetPoint("RIGHT", bar.bar, 0, 0) :SetPoint("LEFT", bar.middle, "RIGHT", 0, 0) :SetDrawLayer("BORDER", 1) .__EndChain
	bar.left.indicator = LMP:NewChain(bar.bar:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
	bar.right.indicator = LMP:NewChain(bar.bar:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
	
	-- faction icons positioned relative to the main scaffold frame
	bar.left.icon = LMP:NewChain(bar:CreateTexture()) .__EndChain
	bar.right.icon = LMP:NewChain(bar:CreateTexture()) .__EndChain

	return bar
end

