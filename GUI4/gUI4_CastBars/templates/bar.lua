local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_CastBars = gUI4:GetModule("gUI4_CastBars", true)
if not gUI4_CastBars then return end

local Scaffold = gUI4_CastBars.Scaffold 
local Bar = setmetatable({}, { __index = Scaffold })
local Bar_MT = { __index = Bar }
gUI4_CastBars.Bar = Bar

function Bar:ApplySettings()
	Scaffold.ApplySettings(self)
end

function Bar:New(id, name, settingsFunc, template)
	local bar = setmetatable(Scaffold:New(id, name, settingsFunc, template), Bar_MT)
	return bar
end

function Bar:Update()
end

