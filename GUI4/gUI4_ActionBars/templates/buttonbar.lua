local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_ActionBars = gUI4:GetModule("gUI4_ActionBars", true)
if not gUI4_ActionBars then return end

local Scaffold = gUI4_ActionBars.Scaffold
local ButtonBar = setmetatable({}, { __index = Scaffold })
local ButtonBar_MT = { __index = ButtonBar }
gUI4_ActionBars.ButtonBar = ButtonBar

local blockMasque = true -- until I can fix the compability issues
local Masque = not(blockMasque) and GP_LibStub("Masque", true)

-- Lua API
local ceil, min = math.ceil, math.min
local pairs, tostring = pairs, tostring

local function getConfig(theme)
	return gUI4_ActionBars:GetTheme(theme)
end

function ButtonBar:ApplySettings()
	Scaffold.ApplySettings(self)
end

function ButtonBar:New(id, name, settingsFunc)
	local bar = setmetatable(Scaffold:New(id, name, settingsFunc), ButtonBar_MT)
	if Masque then
		bar.MasqueGroup = Masque:Group("gUI4", tostring(id))
	end
	return bar
end

function ButtonBar:UpdateSkin()
	local settings = self:GetSettings()
	local buttons = self.buttons
	local numbuttons = self.numbuttons or #buttons
	if numbuttons == 0 then return end
	for i = 1, numbuttons do
		local button = buttons[i]
		button:UpdateSkin(getConfig(settings.skin)[settings.skinSize], true) -- force the update
	end
end

function ButtonBar:UpdateLayout()
	local settings = self:GetSettings()
	local buttons = self.buttons
	local numbuttons = self.numbuttons or #buttons
	if numbuttons == 0 then return end
	
	-- set the bar size
	local db = getConfig(settings.skin)[settings.skinSize]
	local size = db.size
	local padding = db.padding
	local w = min(numbuttons, settings.barWidth)
	local h = ceil(numbuttons/settings.barWidth)
	self:SetSize(w * size + (w-1)*padding, h * size + (h-1)*padding)
	
	-- decide layout parameters
	local anchor, anchor_newrow, anchor_samerow, padX, padY
	if settings.growthX == "RIGHT" then
		if settings.growthY == "DOWN" then
			anchor = "TOPLEFT"
			anchor_newrow = "BOTTOMLEFT"
			anchor_samerow = "TOPRIGHT"
			padX = padding
			padY = -padding
		elseif settings.growthY == "UP" then
			anchor = "BOTTOMLEFT"
			anchor_newrow = "TOPLEFT"
			anchor_samerow = "BOTTOMRIGHT"
			padX = padding
			padY = padding
		end
	elseif settings.growthX == "LEFT" then
		if settings.growthY == "DOWN" then
			anchor = "TOPRIGHT"
			anchor_newrow = "BOTTOMRIGHT"
			anchor_samerow = "TOPLEFT"
			padX = -padding
			padY = -padding
		elseif settings.growthY == "UP" then
			anchor = "BOTTOMRIGHT"
			anchor_newrow = "TOPRIGHT"
			anchor_samerow = "BOTTOMLEFT"
			padX = -padding
			padY = padding
		end
	end
	
	-- align buttons
	buttons[1]:ClearAllPoints()
	buttons[1]:SetPoint(anchor, self, anchor, 0, 0)
	for i = 2, numbuttons do
		local button = buttons[i]
		if ((i-1) % settings.barWidth) == 0 then
			button:ClearAllPoints()
			button:SetPoint(anchor, buttons[i-settings.barWidth], anchor_newrow, 0, padY)
		else
			button:ClearAllPoints()
			button:SetPoint(anchor, buttons[i-1], anchor_samerow, padX, 0)
		end
	end
	
	-- size the buttons
	for i = 1, numbuttons do
		local button = buttons[i]
		button:SetSize(size, size)
	end
	
	-- update skin
	if not Masque then
		self:UpdateSkin()
	end
end

-- get an iterator for all buttons
function ButtonBar:GetAll()
	return pairs(self.buttons)
end

-- apply a mehtod to all buttons
function ButtonBar:ForAll(method, ...)
	if not self.buttons then return end
	for _, button in self:GetAll() do
		local func = button[method]
		if func then
			func(button, ...)
		end
	end
end
