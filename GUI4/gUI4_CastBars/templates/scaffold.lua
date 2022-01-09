local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_CastBars = gUI4:GetModule("gUI4_CastBars", true)
if not gUI4_CastBars then return end

-- local LibWin = GP_LibStub("GP_LibWindow-1.1")
-- local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local Scaffold = CreateFrame("Frame")
local Scaffold_MT = { __index = Scaffold }
gUI4_CastBars.Scaffold = Scaffold

function Scaffold:ApplySettings()
end

function Scaffold:Enable()
	if self.enabled then return end
	local settings = self:GetSettings()
	settings.enabled = true
	self.enabled = true
end

function Scaffold:Disable()
	if not self.enabled then return end
	local settings = self:GetSettings()
	settings.enabled = false
	self.enabled = false
	self:Hide()
end

function Scaffold:IsEnabled()
	return self.enabled
end

local numbars = 0
function Scaffold:New(id, name, settingsFunc, template)
	if not template then
		numbars = numbars + 1
	end
	local bar = setmetatable(template or CreateFrame("Frame", "GUI4GeneralBar"..numbars, UIParent), Scaffold_MT)
	bar.name = name or id
	bar.id = id
	bar.GetSettings = settingsFunc
	bar:SetSize(1,1)
	bar:SetFrameStrata("LOW")
	bar:Hide() -- everything in this addon should be hidden by default
	local settings = bar:GetSettings()
	if settings and settings.position and settings.position.x then
		bar:SetPoint(settings.position.point, settings.position.x, settings.position.y)
	end
	return bar
end