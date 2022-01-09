local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_CastBars = gUI4:GetModule("gUI4_CastBars", true)
if not gUI4_CastBars then return end

local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local tonumber, tostring = tonumber, tostring

local Bar = gUI4_CastBars.Bar 
local StatusBar = setmetatable({}, { __index = Bar })
local StatusBar_MT = { __index = StatusBar }
gUI4_CastBars.StatusBar = StatusBar

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

function StatusBar:ApplySettings()
	Bar.ApplySettings(self)
end

function StatusBar:SetStatusBarValue(value)
	self:SetValue(value)
	self.value:SetText(short(value))
	local min, max = self:GetMinMaxValues()
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
end

local numbars = 0
function StatusBar:New(id, name, settingsFunc)
	numbars = numbars + 1
	local bar = setmetatable(Bar:New(id, name, settingsFunc, LMP:NewChain("StatusBar", "GUI4StatusBar"..numbars, UIParent) :SetStatusBarTexture(1, 1, 1) .__EndChain), StatusBar_MT)
	bar.value = LMP:NewChain("FontString", nil, bar) :SetFontObject(TextStatusBarText) :SetPoint("TOPRIGHT", -4, -4) .__EndChain
	bar.border = LMP:NewChain(bar:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
	bar.spark = LMP:NewChain(bar:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
	return bar
end

function StatusBar:Update()
end

