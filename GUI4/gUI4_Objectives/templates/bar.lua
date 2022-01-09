local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_Objectives = gUI4:GetModule("gUI4_Objectives", true)
if not gUI4_Objectives then return end

local Scaffold = gUI4_Objectives.Scaffold 
local Bar = setmetatable({}, { __index = Scaffold })
local Bar_MT = { __index = Bar }
gUI4_Objectives.Bar = Bar

function Bar:ApplySettings()
	Scaffold.ApplySettings(self)
end

function Bar:New(id, name, settingsFunc, template)
	local scaffold = setmetatable(Scaffold:New(id, name, settingsFunc, template), Bar_MT)
	scaffold.bar = CreateFrame("StatusBar", scaffold:GetName().."ContentBar", scaffold)
	scaffold.bar:SetAllPoints(scaffold)
	return scaffold
end

function Bar:Update()
end

