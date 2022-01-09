local addon = ...
local GP_LibStub = _G.GP_LibStub

local build = tonumber((select(2, GetBuildInfo())))
local LEGION = build >= 22124 

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local F = {}

-- Lua API
local floor = math.floor
local pairs, unpack = pairs, unpack
local setmetatable, getmetatable = setmetatable, getmetatable

-- WoW API
local CreateFrame = _G.CreateFrame
local DebuffTypeColor = _G.DebuffTypeColor
local GetTime = _G.GetTime
local hooksecurefunc = _G.hooksecurefunc
local UnitAlternatePowerInfo = _G.UnitAlternatePowerInfo
local UnitAura = _G.UnitAura
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitExists = _G.UnitExists
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDead = _G.UnitIsDead
local UnitIsFriend = _G.UnitIsFriend
local UnitIsGhost = _G.UnitIsGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsPVP = _G.UnitIsPVP
local UnitIsTapped = _G.UnitIsTapped
local UnitIsTapDenied = UnitIsTapDenied
local UnitIsTappedByAllThreatList = _G.UnitIsTappedByAllThreatList
local UnitIsTappedByPlayer = _G.UnitIsTappedByPlayer
local UnitIsUnit = _G.UnitIsUnit
local UnitIsVisible = _G.UnitIsVisible
local UnitLevel = _G.UnitLevel
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnitReaction = _G.UnitReaction
local ALTERNATE_POWER_INDEX= _G.ALTERNATE_POWER_INDEX
local NumberFontNormalSmall = _G.NumberFontNormalSmall


-- 		General Functions
------------------------------------------------------------------------------

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
local saturation = .5
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


-- 		UnitFrame Health & Power Updates
------------------------------------------------------------------------------

-- oUF healthbar override update
-- colors the bar, fixes value errors when dead
F.UpdateHealthBar = function(self, _, unit)
	if self.unit ~= unit then return end
	local health = self.Health

	if health.PreUpdate then health:PreUpdate(unit) end

	local min = UnitHealth(unit)
	local max = UnitHealthMax(unit)
	local dead = UnitIsDead(unit)
	local ghost = UnitIsGhost(unit)
	
	local r, g, b, m, s
	
	-- disconnected
	if not UnitIsConnected(unit)then
		min = max
		r, g, b = unpack(self.colors.disconnected)
		
	-- dead, released spirit
	elseif ghost then 
		min = 0
		r, g, b = unpack(self.colors.ghost)

	-- dead
	elseif dead then
		min = 0
		r, g, b = unpack(self.colors.dead)
		
	-- tapped 
	elseif health.colorTapping and (LEGION and UnitIsTapDenied(unit)) or (not LEGION and UnitIsTapped(unit) and not(UnitPlayerControlled(unit) or UnitIsTappedByPlayer(unit) or UnitIsTappedByAllThreatList(unit) or UnitIsFriend("player", unit))) then
		
		r, g, b = unpack(self.colors.tapped)
	
	-- rare spawn
	elseif health.colorRare and 
		(UnitClassification(unit) == "rare" or UnitClassification(unit) == "rareelite") then
		
		r, g, b = self.ColorGradient(min, max, unpack(self.colors.smoothrare))
	
	-- boss npc
	elseif health.colorBoss and 
		(UnitClassification(unit) == "worldboss" or 
		(UnitClassification(unit) == "elite" and (UnitLevel(unit) < 0 or not(UnitLevel(unit))) )) then

		r, g, b = self.ColorGradient(min, max, unpack(self.colors.smoothelite))
	
	-- class color
	elseif (health.colorClass and UnitIsPlayer(unit)) or -- player
		(health.colorClassPet and UnitPlayerControlled(unit) and not(UnitIsPlayer(unit))) or -- pet
		(health.colorClassNPC and not(UnitIsPlayer(unit))) then -- npc

		local _, class = UnitClass(unit)
		r, g, b = unpack(self.colors.class[class] or self.colors.class.UNKNOWN) -- class will not always be returned when joining crossrealm premades(?)
	
	-- player's pet or minion
	elseif (health.colorPetAsPlayer and UnitIsUnit("pet", unit)) then
		local _, class = UnitClass("player")
		r, g, b = unpack(self.colors.class[class])
		m = .7
		s = .75
	
	-- reaction
	elseif health.colorReaction and UnitReaction(unit, "player") then
		r, g, b = unpack(self.colors.reaction[UnitReaction(unit, "player")])
	
	-- smooth gradient
	elseif health.colorSmooth then
		r, g, b = self.ColorGradient(min, max, unpack(health.smoothGradient or self.colors.smooth))
	
	-- standard color
	else
		r, g, b = unpack(self.colors.health)
	end

	-- set the bar values
	health:SetMinMaxValues(0, max)
	health:SetValue(min)

	-- set the bar color
	if r then
		if m then
			if s then
				health:SetStatusBarColor(saturate(r*m, g*m, b*m, s))
			else
				health:SetStatusBarColor(r*m, g*m, b*m)
			end
		else
			if s then
				health:SetStatusBarColor(saturate(r, g, b, s))
			else
				health:SetStatusBarColor(r, g, b)
			end
		end
	end
	
	-- adjust low value pulse and bar spark
	if dead or ghost then 
		if self.SpiritHealer then
			if not self.SpiritHealer:IsShown() then
				self.SpiritHealer:Show()
			end
		end
		local spark = health.Spark
		if spark then
			spark:Hide()
		end
		local pulse = health.Pulse
		if pulse then
			pulse:Hide()
		end
	else
		local spark = health.Spark
		if spark then
			if min == max or min == 0 then
				spark:Hide()
			else
				if not spark:IsShown() then
					spark:Show()
				end
			end
		end
		local pulse = health.Pulse
		if pulse then
			if min == max or min == 0 or min/max > (pulse.threshold or .35) then -- todo: smarter percentages based on situation (pvp, raid, etc)
				pulse:Hide()
			else
				if not pulse:IsShown() then
					pulse:Show()
				end
			end
		end
		if self.SpiritHealer then
			self.SpiritHealer:Hide()
		end
	end	

	if health.PostUpdate then
		return health:PostUpdate(unit, min, max)
	end
end

local GetDisplayPower = function(unit)
	local _, min, _, _, _, _, showOnRaid = UnitAlternatePowerInfo(unit)
	if(showOnRaid) then
		return ALTERNATE_POWER_INDEX, min
	end
end

-- oUF powerbar override update
-- colors the bar, toggles spark, fixes value errors when dead/disconnected
F.UpdatePowerBar = function(self, _, unit)
	if self.unit ~= unit then return end
	local power = self.Power

	if power.PreUpdate then power:PreUpdate(unit) end

	local displayType, altPowerMin = power.displayAltPower and GetDisplayPower(unit)
	local min = UnitPower(unit, displayType)
	local max = UnitPowerMax(unit, displayType)
	local dead = UnitIsDead(unit) or (min == 0 and max == 0)
	local ghost = UnitIsGhost(unit) or (min == 0 and max == 0)

	local r, g, b, s, m 
	
	-- disconnected
	if not UnitIsConnected(unit)then
		min = max
		r, g, b = unpack(self.colors.disconnected)
		
	-- dead, released spirit
	elseif ghost then 
		min = 0
		r, g, b = unpack(self.colors.ghost)

	-- dead
	elseif dead then
		min = 0
		r, g, b = unpack(self.colors.dead)
		
	-- tapped 
	elseif power.colorTapping and (LEGION and UnitIsTapDenied(unit)) or (not LEGION and UnitIsTapped(unit) and not(UnitPlayerControlled(unit) or UnitIsTappedByPlayer(unit) or UnitIsTappedByAllThreatList(unit) or UnitIsFriend("player", unit))) then
		
		r, g, b = unpack(self.colors.tapped)
	
	-- power type color
	elseif power.colorPower then
	
		local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)
		if ptoken and self.colors.power[ptoken] then
			r, g, b = unpack(self.colors.power[ptoken])
		end
		if not r then
			if power.GetAlternativeColor then
				r, g, b = power:GetAlternativeColor(unit, ptype, ptoken, altR, altG, altB)
			elseif(altR) then
				r, g, b = altR, altG, altB
			else 
				r, g, b = unpack(self.colors.power[ptype])
			end
		end
		
	-- class coloring
	elseif (power.colorClass and UnitIsPlayer(unit)) or -- player
		(power.colorClassPet and UnitPlayerControlled(unit) and not(UnitIsPlayer(unit))) or -- pet
		(power.colorClassNPC and not(UnitIsPlayer(unit))) then -- npc

		local _, class = UnitClass(unit)
		r, g, b = unpack(self.colors.class[class] or self.colors.class.UNKNOWN) -- class will not always be returned when joining crossrealm premades(?)
	
	-- reaction
	elseif power.colorReaction and UnitReaction(unit, "player") then
		r, g, b = unpack(self.colors.reaction[UnitReaction(unit, "player")])
	
	-- smooth gradient
	elseif power.colorSmooth then
		r, g, b = self.ColorGradient(min, max, unpack(power.smoothGradient or self.colors.smooth))
	end
	
	-- set the bar values
	power:SetMinMaxValues(altPowerMin or 0, max)
	power:SetValue(min)

	-- set the bar color
	if r then
		if m then
			if s then
				power:SetStatusBarColor(saturate(r*m, g*m, b*m, s))
			else
				power:SetStatusBarColor(r*m, g*m, b*m)
			end
		else
			if s then
				power:SetStatusBarColor(saturate(r, g, b, s))
			else
				power:SetStatusBarColor(r, g, b)
			end
		end
	end
	
	-- adjust bar spark
	if dead or ghost then 
		local spark = power.Spark
		if spark then
			spark:Hide()
		end
	else
		local spark = power.Spark
		if spark then
			if min == max or min == 0 then
				spark:Hide()
			else
				if not spark:IsShown() then
					spark:Show()
				end
			end
		end
	end	
	
	if power.PostUpdate then
		return power:PostUpdate(unit, min, max)
	end
end


-- 		UnitFrame Portrait Updates
------------------------------------------------------------------------------

-- fix the worgen mail camera angle. 'self' is the portrait
F.PostUpdatePortrait = function(self) -- 2nd arg is unit
	if self.GetModel and self:GetModel() and self:GetModel().find and self:GetModel():lower():find("worgenmale") then
		self:SetCamera(1)
	end
end

-- update portrait alpha. 'self' is the portrait
F.PostUpdatePortraitAlpha = function(self, unit)
	self:SetAlpha(0)
	self:SetAlpha(self.alpha or 1)
	F.PostUpdatePortrait(self, unit)
end

-- hide the unitframe portrait. 'self' is the unitframe
F.HidePortrait = function(self, unit)
	local portrait = self.Portrait
	if not portrait then return end 
	if not UnitExists(self.unit) or not UnitIsConnected(self.unit) or not UnitIsVisible(self.unit) then
		self.Portrait:SetAlpha(0)
	else
		F.PostUpdatePortraitAlpha(portrait, unit)
	end
end


-- 		UnitFrame Aura Updates
------------------------------------------------------------------------------

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
local unitIsPlayer = { 
	player = true, 
	pet = true, 
	vehicle = true 
}
local DAY, HOUR, MINUTE = 86400, 3600, 60

local function createTimer(self, elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if not self.first then
				self.timeLeft = self.timeLeft - self.elapsed
			else
				self.timeLeft = self.timeLeft - GetTime()
				self.first = false
			end
			if self.timeLeft > 0 then
				-- more than a day
				if self.timeLeft > DAY then
					self:StopFlash()
					self.remaining:SetFormattedText("%1dd", floor(self.timeLeft / DAY))
					
				-- more than an hour
				elseif self.timeLeft > HOUR then
					self:StopFlash()
					self.remaining:SetFormattedText("%1dh", floor(self.timeLeft / HOUR))
				
				-- more than a minute
				elseif self.timeLeft > MINUTE then
					self:StopFlash()
					self.remaining:SetFormattedText("%1dm", floor(self.timeLeft / MINUTE))
				
				-- more than 10 seconds
				elseif self.timeLeft > 10 then 
					self:StopFlash()
					self.remaining:SetFormattedText("%1d", floor(self.timeLeft))
				
				-- between 5 and 10 seconds
				elseif self.timeLeft > 5 then
					self:StopFlash()
					self.remaining:SetFormattedText("|cffff8800%1d|r", floor(self.timeLeft))
					
				-- between 3 and 5 seconds
				elseif self.timeLeft > 3 then
					self:StartFlash(.75, .5, .5, 1, true)
					self.remaining:SetFormattedText("|cffff0000%1d|r", floor(self.timeLeft))
					
				-- less than 3 seconds
				elseif self.timeLeft > 0 then
					self:StartFlash(.75, .5, .5, 1, true)
					self.remaining:SetFormattedText("|cffff0000%.1f|r", self.timeLeft)
				else
					self:StopFlash()
					self.remaining:SetText("|cffff00000.0|r")
				end	
			else
				self:StopFlash()
				self.remaining:SetText("|cffff00000.0|r")
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end
local function setAuraBorderColor(self, r, g, b, a)
	r, g, b = saturate(r, g, b)
	self:RawSetBackdropBorderColor(r, g, b, a)
end
F.PostCreateAuraIcon = function(self, button)
	--local visibility = button:IsShown()
	button:SetAlpha(0)
	
	if not button.RawSetBackdropBorderColor then
		button.RawSetBackdropBorderColor = button.SetBackdropBorderColor
		button.SetBackdropBorderColor = setAuraBorderColor
	end

	LMP:NewChain(button) :SetBackdrop(auraBackdrop) :SetBackdropColor(0,0,0,1) :SetBackdropBorderColor(.15, .15, .15) :EndChain()
	LMP:NewChain(button.icon) :ClearAllPoints() :SetPoint("TOP", button, 0, -2) :SetPoint("RIGHT", button, -2, 0) :SetPoint("BOTTOM", button, 0, 2) :SetPoint("LEFT", button, 2, 0) :SetTexCoord(5/65, 59/64, 5/64, 59/64) :SetDrawLayer("ARTWORK", 0) :EndChain()
	LMP:NewChain(button.cd) :SetReverse() :SetAllPoints(button.icon) :SetFrameLevel(button:GetFrameLevel() + 1) :EndChain()
	-- :SetEdgeTexture("") :SetBlingTexture("") :SetSwipeTexture("") :SetSwipeColor(0, 0, 0, 0) :SetDrawEdge(false) :SetDrawBling(false)
	button.overlayFrame = LMP:NewChain(CreateFrame("frame", nil, button)) :SetFrameLevel(button.cd:GetFrameLevel() + 1) .__EndChain
	button.desaturate = LMP:NewChain(button:CreateTexture()) :SetDrawLayer("ARTWORK", 1) :SetVertexColor(1, 1, 1) :SetDesaturated(true) :SetAllPoints(button.icon) :SetSize(button.icon:GetSize()) :SetAlpha(1-saturation) .__EndChain
	button.shade = LMP:NewChain(button:CreateTexture()) :SetDrawLayer("ARTWORK", 2) :SetTexture(gUI4:GetMedia("Texture", "Shade", 64, 64, "Warcraft"):GetPath()) :SetAllPoints(button.icon) :SetVertexColor(0, 0, 0, 1) .__EndChain
	button.remaining = LMP:NewChain("FontString", nil, button.overlayFrame) :SetFontObject(NumberFontNormalSmall) :SetFontSize(10) :SetFontStyle("THINOUTLINE") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", 1) :SetPoint("TOPLEFT", button, 1, -1) .__EndChain

	LMP:NewChain(button.overlay) :SetParent(button.overlayFrame) :SetTexture("") :EndChain()
	LMP:NewChain(button.count) :SetParent(button.overlayFrame) :SetFontObject(NumberFontNormalSmall) :SetFont(NumberFontNormalSmall:GetFont(), 10, "THINOUTLINE") :SetTextColor(unpack(gUI4:GetColors("chat", "normal"))) :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", 2) :ClearAllPoints() :SetPoint("BOTTOMRIGHT", button, 0, 1) :EndChain()
	
	-- let's flash and fade these things
	gUI4:ApplyFadersToFrame(button)
	button:OverrideShowWithFadeIn(.25, 1)
	button:OverrideHideWithFadeOut(.1)
	
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
	
	button.cd.noOCC = true
	button.cd.noCooldownCount = true 
	
	button:Show()
	button:StartFadeIn()
	
	-- button:SetScript("OnUpdate", createTimer)	
end
F.PostUpdateAuraIcon = function(self, unit, button, index)
	local _, _, _, _, debuffType, duration, expirationTime, unitCaster, isStealable, _, _, _, isBossDebuff, _, _, _ = UnitAura(unit, index, button.filter)
	if unit == "player" then
		if unitIsPlayer[unitCaster] then
			button:SetBackdropBorderColor(.15,.15,.15)
			button.icon:SetDesaturated(false)
		elseif isBossDebuff then
			local color = DebuffTypeColor[debuffType] 
			if not(color and color.r and color.g and color.b) then
				color = { r = 0.7, g = 0, b = 0 }
			end
			button:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			if unitCaster == "vehicle" then
				button:SetBackdropBorderColor(0, 3/4, 0, 1)
			else
        local color = DebuffTypeColor[debuffType] 
				if color and color.r and color.g and color.b then
					button:SetBackdropBorderColor(color.r, color.g, color.b)
				else
					button:SetBackdropBorderColor(.15,.15,.15)
				end
			end
		end
	
	elseif unit == "target" then
		-- saturate boss debuffs, friendlies, non PvP enemy players, and auras cast by the player
		if unitIsPlayer[unitCaster] or isBossDebuff or UnitIsFriend("player", unit) or (UnitIsPlayer(unit) and not UnitIsPVP(unit)) then
			local color = DebuffTypeColor[debuffType] 
			if color and color.r and color.g and color.b then
				button:SetBackdropBorderColor(color.r, color.g, color.b)
			else
				button:SetBackdropBorderColor(.15,.15,.15)
			end
			button.icon:SetDesaturated(false)
		else
			if unitCaster == "vehicle" then
				button:SetBackdropBorderColor(0, 3/4, 0, 1)
			else
				button:SetBackdropBorderColor(.15,.15,.15)
			end
			button.icon:SetDesaturated(true)
		end
	else
		if unitCaster == "vehicle" then
			button:SetBackdropBorderColor(0, 3/4, 0, 1)
		else
			if isBossDebuff then
				local color = DebuffTypeColor[debuffType] or { r = 0.7, g = 0, b = 0 }
				button:SetBackdropBorderColor(color.r, color.g, color.b)
			else
				local color = DebuffTypeColor[debuffType] 
				if color and color.r and color.g and color.b then
					button:SetBackdropBorderColor(color.r, color.g, color.b)
				else
					button:SetBackdropBorderColor(.15,.15,.15)
				end
				
				-- button:SetBackdropBorderColor(.15,.15,.15)
			end
		end
	end
	
	if self.auraSaturation then
		button.desaturate:SetAlpha(1-self.auraSaturation) 
	else
		button.desaturate:SetAlpha(.25)
	end
	
	if duration and duration > 0 and expirationTime then
		button.remaining:Show()
	else
		button.remaining:Hide()
	end
	button.first = true
	button.duration = duration
	button.timeLeft = expirationTime -- why do we get actual seconds left here, while usually the ending time relative to GetTime() ...?
	button:SetScript("OnUpdate", createTimer)

	-- button:SetScript("OnUpdate", createTimer)
end


-- 		Finalize the API, protect it
------------------------------------------------------------------------------

local protected_meta = {
	__newindex = function(self)
		error(L["Attempt to modify read-only table"])
	end,
	__metatable = false
}
-- write protect a table from editing
local function protect(tbl)
	local old_meta = getmetatable(tbl)
	if old_meta then
		local new_meta = {}
		for i,v in pairs(old_meta) do
			new_meta[i] = v
		end
		for i,v in pairs(protected_meta) do
			new_meta[i] = v
		end
		return setmetatable(tbl, new_meta)
	else
		return setmetatable(tbl, protected_meta)
	end
end

-- lock our function registry from further editing
protect(F)


-- 		Public API
------------------------------------------------------------------------------

function gUI4:GetFunction(name)
	if name and F[name] then
		return F[name]
	else
		return F
	end
end