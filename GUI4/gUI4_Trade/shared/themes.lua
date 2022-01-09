local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Trade", true)
if not parent then return end

local offset, border = 24, 12

parent:RegisterTheme("Warcraft", {
})