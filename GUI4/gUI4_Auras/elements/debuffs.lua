local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Auras", true)
if not parent then return end

local module = parent:NewModule("Debuffs", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T

-- Lua API
local ipairs, pairs, unpack = ipairs, pairs, unpack
local tostring = tostring 

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat
local UnitAura = UnitAura

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		colorborder = true,
		skin = "Warcraft", 
		position = {}
	}
}

local auraBackdrop = {
	bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
	edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
	edgeSize = 1,
	insets = { 
		left = -1, 
		right = -1, 
		top = -1, 
		bottom = -1
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().debuffs
end

-- normalize a number to 0 <= num <= 1
local function normalize(num)
	if num > 1 then
		return 1
	elseif num < 0 then
		return 0
	else
		return num
	end
end

-- set the level of saturation on a given rgb value
-- values from 0-1 decreases saturation, while values > 1 increase it
local saturation = .75
local function saturate(r, g, b, override)
	local saturation = override or saturation
	if saturation > 1 then
		if r > g and r > b then -- red
			local s = r*(saturation-1)
			r = r + s
			g = g - s/2
			b = b - s/2
		elseif g > r and g > b then -- green
			local s = g*(saturation-1)
			r = r - s/2
			g = g + s 
			b = b - s/2
		elseif b > r and b > g then -- blue
			local s = b*(saturation-1)
			r = r - s/2
			g = g - s/2
			b = b + s
		elseif r < g and r < b then -- turquoise
			local s = g*(saturation-1)
			r = r - s
			g = g + s/2
			b = b + s/2
		elseif g < r and g < b then -- purple
			local s = r*(saturation-1)
			r = r + s/2
			g = g - s
			b = b + s/2
		elseif b < r and b < g then -- yellow
			local s = r*(saturation-1)
			r = r + s/2
			g = g + s/2
			b = b - s
		else -- gray, do nothing
		end
	else
		-- local graytone = (r*.21 + g*.72 + b*.07) * (1-saturation) -- average
		local graytone = (r + g + b)/3 * (1-saturation) -- average
		r = graytone + r*saturation
		g = graytone + g*saturation
		b = graytone + b*saturation
	end
	return normalize(r), normalize(g), normalize(b)
end

local DAY, HOUR, MINUTE = 86400, 3600, 60
local function createTimer(self, elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if self.weapon then
				local expiration = select(self.weapon, GetWeaponEnchantInfo())
				if expiration then
					self.timeLeft = expiration / 1e3
				else
					self.timeLeft = nil
				end
			else
				if not self.first then
					self.timeLeft = self.timeLeft - self.elapsed
				else
					self.timeLeft = self.timeLeft - GetTime()
					self.first = false
				end
			end
			if self.timeLeft > 0 then
				-- more than a day
				if self.timeLeft > DAY then
					self.scaffold:StopFlash()
					self.remaining:SetFormattedText("%1dd", floor(self.timeLeft / DAY))
					
				-- more than an hour
				elseif self.timeLeft > HOUR then
					self.scaffold:StopFlash()
					self.remaining:SetFormattedText("%1dh", floor(self.timeLeft / HOUR))
				
				-- more than a minute
				elseif self.timeLeft > MINUTE then
					self.scaffold:StopFlash()
					self.remaining:SetFormattedText("%1dm", floor(self.timeLeft / MINUTE))
				
				-- more than 10 seconds
				elseif self.timeLeft > 10 then 
					self.scaffold:StopFlash()
					self.remaining:SetFormattedText("%1d", floor(self.timeLeft))
				
				-- between 6 and 10 seconds
				elseif self.timeLeft <= 10 and self.timeLeft >= 6 then
					self.scaffold:StartFlash(.75, .75, .5, 1, true)
					self.remaining:SetFormattedText("|cffff8800%1d|r", floor(self.timeLeft))
					
				-- between 3 and 5 seconds
				elseif self.timeLeft >= 3 and self.timeLeft < 6 then
					self.scaffold:StartFlash(.75, .75, .5, 1, true)
					self.remaining:SetFormattedText("|cffff0000%1d|r", floor(self.timeLeft))
					
				-- less than 3 seconds
				elseif self.timeLeft > 0 and self.timeLeft < 3 then
					self.scaffold:StartFlash(.75, .75, .5, 1, true)
					self.remaining:SetFormattedText("|cffff0000%.1f|r", self.timeLeft)
				else
					self.scaffold:StopFlash()
					self.remaining:SetText("")
				end	
			else
				self.scaffold:StopFlash()
				self.remaining:SetText("")
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end

local function updateAura(button, id)
	local unit = button:GetParent():GetAttribute("unit")
	local filter = button.filter
	local name, _, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unit, id, filter)
	if name then
		if duration and duration > 0 then
			button.remaining:Show()
		else
			button.remaining:Hide()
		end
		button.first = true
		button.duration = duration
		button.timeLeft = expirationTime
		button:SetScript("OnUpdate", createTimer)

		if count > 1 then
			button.count:SetText(count)
		else
			button.count:SetText("")
		end

		if button.filter == "HARMFUL" then
			local color
			if module.db.profile.colorborder then
				color = DebuffTypeColor[debuffType] 
			end
			if not(color and color.r and color.g and color.b) then
				color = { r = 0.7, g = 0, b = 0 }
			end
			button.scaffold:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			button.scaffold:SetBackdropBorderColor(.15, .15, .15)
		end

		button.icon:SetTexture(icon)
	end

end

local function updateAttribute(self, attribute, value)
	return updateAura(self, value)
end

local function setAuraBorderColor(self, r, g, b, a)
	r, g, b = saturate(r, g, b)
	self:RawSetBackdropBorderColor(r, g, b, a)
end

local function styleAuraButton(button)
	button.icon:SetSize(T.icons.size, T.icons.size)
	button.icon:ClearAllPoints()
	button.icon:SetPoint(unpack(T.icons.place))
	button.icon:SetTexCoord(unpack(T.icons.texCoord))
	
	button.count:SetFontObject(T.fonts.count.fontObject)
	button.count:SetFontStyle(T.fonts.count.fontStyle)
	button.count:SetFontSize(T.fonts.count.fontSize)
	button.count:SetShadowOffset(unpack(T.fonts.count.shadowOffset))
	button.count:SetShadowColor(unpack(T.fonts.count.shadowColor))
	button.count:ClearAllPoints()
	button.count:SetPoint(unpack(T.fonts.count.place))
	
	button.remaining:SetFontObject(T.fonts.time.fontObject)
	button.remaining:SetFontStyle(T.fonts.time.fontStyle)
	button.remaining:SetFontSize(T.fonts.time.fontSize)
	button.remaining:SetShadowOffset(unpack(T.fonts.time.shadowOffset))
	button.remaining:SetShadowColor(unpack(T.fonts.time.shadowColor))
	button.remaining:ClearAllPoints()
	button.remaining:SetPoint(unpack(T.fonts.time.place))
end

local buttons = {}
function module:Scaffolding(button, isProxyButton)
	button.scaffold = LMP:NewChain(CreateFrame("Frame", nil, parent:GetFadeManager())) :Hide() :SetAlpha(0) :SetPoint("TOPLEFT", button, 1, -1) :SetPoint("BOTTOMRIGHT", button, -1, 1) :SetBackdrop(auraBackdrop) :SetBackdropColor(0,0,0,1) :SetBackdropBorderColor(.15, .15, .15) .__EndChain
	button.icon = LMP:NewChain(button.scaffold:CreateTexture()) :SetDrawLayer("ARTWORK", 0) :ClearAllPoints() :SetPoint("TOPLEFT", button, 3, -3) :SetPoint("BOTTOMRIGHT", button, -3, 3) :SetTexCoord(5/65, 59/64, 5/64, 59/64) .__EndChain
	-- LMP:NewChain(button.cd) :SetReverse() :SetAllPoints(button.icon) :SetFrameLevel(button:GetFrameLevel() + 1) :EndChain()
	
	button.overlayFrame = LMP:NewChain(CreateFrame("frame", nil, button.scaffold)) :SetAllPoints(button) :SetFrameLevel(button.scaffold:GetFrameLevel() + 2)  .__EndChain -- :SetFrameLevel(button.cd:GetFrameLevel() + 1) 
	button.desaturate = LMP:NewChain(button.scaffold:CreateTexture()) :SetDrawLayer("ARTWORK", 1) :SetVertexColor(1, 1, 1) :SetDesaturated(true) :SetAllPoints(button.icon) :SetSize(button.icon:GetSize()) :SetAlpha(1-saturation) .__EndChain
	button.shade = LMP:NewChain(button.scaffold:CreateTexture()) :SetDrawLayer("ARTWORK", 2) :SetTexture(gUI4:GetMedia("Texture", "Shade", 64, 64, "Warcraft"):GetPath()) :SetAllPoints(button.icon) :SetVertexColor(0, 0, 0, 1) .__EndChain
	button.remaining = LMP:NewChain("FontString", nil, button.overlayFrame) :SetFontObject(NumberFontNormalSmall) :SetTextColor(unpack(gUI4:GetColors("chat", "offwhite"))) :SetFontSize(10) :SetFontStyle("") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", 1) :SetPoint("BOTTOM", button, 0, -12) .__EndChain
	button.count = LMP:NewChain("FontString", nil, button.overlayFrame) :SetFontObject(NumberFontNormalSmall) :SetTextColor(unpack(gUI4:GetColors("chat", "normal"))) :SetFontSize(12) :SetFontStyle("") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", 1) :SetPoint("TOPLEFT", button, 1, -1) .__EndChain
	
	if not button.scaffold.RawSetBackdropBorderColor then
		button.scaffold.RawSetBackdropBorderColor = button.scaffold.SetBackdropBorderColor
		button.scaffold.SetBackdropBorderColor = setAuraBorderColor
	end

	-- madness to make it fade in and out nicely
	gUI4:ApplyFadersToFrame(button.scaffold)
	button.scaffold:SetFadeOut(.1)
	button:HookScript("OnShow", function(self)
		self.scaffold:Show() 
	end)
	hooksecurefunc(button.icon, "SetTexture", function() 
		if button:IsShown() and not button.scaffold:IsShown() then
			button.scaffold:SetAlpha(0)
			button.scaffold:Show()
			button.scaffold:StartFadeIn(.25, 1)
		end
	end)
	button:HookScript("OnShow", function(self) 
		self.scaffold:SetAlpha(0)
		self.scaffold:Show()
		self.scaffold:StartFadeIn(.25, 1)
	end)
	button:HookScript("OnHide", function(self) self.scaffold:Hide() end)
	button:GetParent():HookScript("OnHide", function() button.scaffold:Hide() end)

	-- initial visibility check
	button.scaffold:SetAlpha(0)
	button.scaffold:Show()
	button.scaffold:StartFadeIn(.25, 1)
	
	-- experimental madness to control level of saturation
	local function updateTexture()
		button.desaturate:SetTexCoord(button.icon:GetTexCoord())
		button.desaturate:SetTexture(button.icon:GetTexture())
		button.desaturate:SetDesaturated(true)
	end
	local function updateColor()
		local r, g, b = button.icon:GetVertexColor() -- make sure we avoid alpha changes
		if r and g and b then
			button.desaturate:SetVertexColor(r, g, b)
		else
			button.desaturate:SetVertexColor(1, 1, 1)
		end
	end
	hooksecurefunc(button.icon, "SetTexture", updateTexture)
	hooksecurefunc(button.icon, "SetVertexColor", updateColor)

	button:SetScript("OnAttributeChanged", updateAttribute)
	button.filter = button:GetParent():GetAttribute("filter")
	
	styleAuraButton(button)
	parent:GetFadeManager():RegisterHoverObject(button)
	buttons[button] = button
		
	return button
end

function module:UpdateAllButtons()
	for button in pairs(buttons) do
		updateAura(button, button:GetID())
	end
end

function module:Lock()
	self.frame.overlay:StartFadeOut()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	self.frame.overlay:SetAlpha(0)
	self.frame.overlay:Show()
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not self.frame then return end
	updateConfig()
	self.db.profile.position.point = nil
	self.db.profile.position.y = nil
	self.db.profile.position.x = nil
	self.db.profile.locked = true
	wipe(self.db.profile.position)
	self:ApplySettings()
end

function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	updateConfig()
	
	self.frame:SetSize(unpack(T.size))
	self.frame:SetAttribute("minHeight", T.attributes.minHeight)
	self.frame:SetAttribute("minWidth", T.attributes.minWidth)
	self.frame:SetAttribute("xOffset", T.attributes.xOffset)
	self.frame:SetAttribute("wrapAfter", T.attributes.wrapAfter)
	self.frame:SetAttribute("wrapYOffset", T.attributes.wrapYOffset)

	for button in pairs(buttons) do
		styleAuraButton(button)
	end

	self:ApplySettings()
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings(settings)
	if not self.frame then return end
	updateConfig() 
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not self.frame then return end
	updateConfig()
	if self.db.profile.locked then
		LMP:Place(self.frame, T.place)
		if not self.db.profile.position.x then
			self.frame:RegisterConfig(self.db.profile.position)
			self.frame:SavePosition()
		end
	else
		self.frame:RegisterConfig(self.db.profile.position)
		if self.db.profile.position.x then
			self.frame:LoadPosition()
		else
			LMP:Place(self.frame, T.place)
			self.frame:SavePosition()
			self.frame:LoadPosition()
		end
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Debuffs", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()
	
	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4PlayerDebuffs", parent:GetFadeManager(), "SecureAuraHeaderTemplate")) 
		:Hide()
		:SetClampedToScreen(true) 
		:SetMovable(true) 
		:SetSize(28, 28) 
		:SetAttribute("template", "GUI4DebuffButtonTemplate")
		:SetAttribute("filter", "HARMFUL") 
		:SetAttribute("sortDirection", "+") 
	.__EndChain

	self.frame.overlay = gUI4:GlockThis(self.frame, L["Player Debuffs"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "buffs")))
	self.frame.UpdatePosition = function(self) module:UpdatePosition() end

	RegisterAttributeDriver(self.frame, "unit", "[vehicleui] vehicle; player")

	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
	
	self:ApplySettings(self.db.profile)
end

function module:OnEnable()
	if self.db.profile.enabled then -- to prevent it from being automatically shown
		self.frame:Show()
		if not gUI4:IsLocked() then
			self:Unlock()
		end
	end
end

function module:OnDisable()
	self.frame:Hide()
	self:Lock()
end
