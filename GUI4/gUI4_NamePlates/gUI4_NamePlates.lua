local addon = ...

local wowBuild = tonumber((select(2, GetBuildInfo())))
local LEGION = wowBuild >= 22124 

local GP_LibStub = GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")

--local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T

-- Lua API
local setmetatable = setmetatable
local ipairs, pairs, select, unpack = ipairs, pairs, select, unpack
local tinsert = table.insert
local floor, ceil = math.floor, math.ceil

-- WoW API
local CreateFrame = CreateFrame
local GetLocale = GetLocale
local GetRaidTargetIndex = GetRaidTargetIndex
local GetTime = GetTime
local GetQuestGreenRange = GetQuestGreenRange
local SetCVar = SetCVar
local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapDenied = UnitIsTapDenied
local UnitIsTrivial = UnitIsTrivial
local UnitIsUnit = UnitIsUnit
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitReaction = UnitReaction
local UnitThreatSituation = UnitThreatSituation

-- WoW Frames & Tables
local GameFontNormal = GameFontNormal
local TextStatusBarText = TextStatusBarText
local UIParent = UIParent
local WorldFrame = WorldFrame
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local AllPlates, VisiblePlates, FadingPlates = {}, {}, {} -- nameplate registry
local CastData, CastBarPool = {}, {} -- castbar registry 
local colors = gUI4:GetColors() -- gUI4 color registry

-- NamePlate Smooth Fading 
local HZ = 1/120 -- we want it smooth, but still need to have a roof, no point wasting resources
local time_in = .75 -- slower looks better, but we need it fairly fast for readability and thus playability
local time_out = .1 -- anything slower will appear to be "stuck", since the blizz plate is gone and not moving

-- This will be updated later on by the addon,
-- we just need a value of some sort here as a fallback.
local SCALE = 768/1080 


local defaults = {
	profile = {
		skin = "Warcraft",
		showEnemyClassColor = true, -- class color enemy plates, will default to hated reaction color otherwise
		showTrivial = true, -- hides the nameplates of trivial NPCs when false
		useTrivialForRare = false,
		useTrivialForHostileBoss = false,
		useTrivialForHostileElite = false,
		useTrivialForHostileNPC = false, 
		useTrivialForHostilePlayer = false,
		useTrivialForFriendlyBoss = false,
		useTrivialForFriendlyElite = false,
		useTrivialForFriendlyNPC = false, 
		useTrivialForFriendlyPlayer = false, 
		useTrivialForTrivialNPC = true
	}
}



------------------------------------------------------------------------------
-- 	Utility Functions
------------------------------------------------------------------------------
local updateConfig = function()
	T = module:GetActiveTheme()
end

-- merges all methods from source into target
local merge = function(target, source)
	for key,value in pairs(source) do
		target[key] = value
	end
	return target
end

-- return a correct color value, since blizz keeps changing them by 0.01 and such
local getColor = function(r, g, b)
	return floor(r*100 + .5)/100, floor(g*100 + .5)/100, floor(b*100 + .5)/100
end

-- Returns the correct difficulty color compared to the player
local getlevelcolor = function(level)
	level = level - UnitLevel("player")
	if level > 4 then
		return colors.chat.dimred.colorCode
	elseif level > 2 then
		return colors.chat.orange.colorCode
	elseif level >= -2 then
		return colors.chat.yellow.colorCode
	elseif level >= -GetQuestGreenRange() then
		return colors.chat.offgreen.colorCode
	else
		return colors.chat.gray.colorCode
	end
end

local utf8sub = function(str, i, dots)
	if not str then return end
	local bytes = str:len()
	if bytes <= i then
		return str
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = str:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end
		if len == i and pos <= bytes then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

local DAY, HOUR, MINUTE = 86400, 3600, 60
local formatTime = function(time)
	if time > DAY then -- more than a day
		return ("%1d%s"):format(floor(time / DAY), L["d"])
	elseif time > HOUR then -- more than an hour
		return ("%1d%s"):format(floor(time / HOUR), L["h"])
	elseif time > MINUTE then -- more than a minute
		return ("%1d%s %d%s"):format(floor(time / MINUTE), L["m"], floor(time%MINUTE), L["s"])
	elseif time > 10 then -- more than 10 seconds
		return ("%d%s"):format(floor(time), L["s"])
	elseif time > 0 then
		return ("%.1f"):format(time)
	else
		return ""
	end	
end

local locale = GetLocale()
local goners = 
(locale == "enUS" or locale == "enGB") and {
	["Strand of the Ancients Emissary"] = "Emissary",
	["League of Arathor Emissary"] = "Emissary",
	["Isle of Conquest Emissary"] = "Emissary",
	["Eye of the Storm Emissary"] = "Emissary",
	["Gilnean Emissary"] = "Emissary",
	["Stormpike Emissary"] = "Emissary",
	["Tushui Emissary"] = "Emissary",
	["Silverwing Emissary"] = "Emissary",
	["Wildhammer Emissary"] = "Emissary",
	["Lunar Festival Emissary"] = "Emissary"
} or locale == "deDE" and {
	["Botschafter des Strands der Uralten"] = "Botschafter",
	["Abgesandter des Bunds von Arathor"] = "Abgesandter",
	["Abgesandter der Insel der Eroberung"] = "Abgesandter",
	["Abgesandter vom Auge des Sturms"] = "Abgesandter",
	["Botschafter aus Gilneas"] = "Botschafter",
	["Abgesandter der Sturmlanzen"] = "Abgesandter",
	["Abgesandter der Tushui"] = "Abgesandter",
	["Abgesandter der Silberschwingen"] = "Abgesandter",
	["Botschafter der Wildhämmer"] = "Botschafter",
	["Abgesandter des Mondfests"] = "Abgesandter"
} or (locale == "esES" or locale == "esMX") and {
	["Emisario de la Playa de los Ancestros"] = "Emisario",
	["Emisario de la Liga de Arathor"] = "Emisario",
	["Emisario de la Isla de la Conquista"] = "Emisario",
	["Emisario del Ojo de la Tormenta"] = "Emisario",
	["Emisario gilneano"] = "Emisario",
	["Emisario Pico Tormenta"] = "Emisario",
	["Emisario Tushui"] = "Emisario",
	["Emisaria Ala de Plata"] = "Emisario",
	["Emisario Martillo Salvaje"] = "Emisario",
	["Emisario del Festival Lunar"] = "Emisario"
} or (locale == "frFR") and {
	["Emissaire du rivage des Anciens"] = "Emissaire",
	["Emissaire de la Ligue d'Arathor"] = "Emissaire",
	["Emissaire de l'île des Conquérants"] = "Emissaire",
	["Emissaire de l'Oeil du cyclone"] = "Emissaire",
	["Emissaire gilnéen"] = "Emissaire",
	["Emissaire foudrepique"] = "Emissaire",
	["Emissaire tushui"] = "Emissaire",
	["Emissaire d'Aile-argent"] = "Emissaire",
	["Emissaire marteau-hardi"] = "Emissaire",
	["Emissaire de la fête lunaire"] = "Emissaire"
} or (locale == "itIT") and {
	["Emissario del Lido degli Antichi"] = "Emissario",
	["Emissario della Lega di Arathor"] = "Emissario",
	["Emissario dell'Isola della Conquista"] = "Emissario",
	["Emissario dell'Occhio del Ciclone"] = "Emissario",
	["Emissario di Gilneas"] = "Emissario",
	["Emissario dei Piccatonante"] = "Emissario",
	["Emissario Tushui"] = "Emissario",
	["Emissaria Alargentea"] = "Emissaria",
	["Emissario dei Granmartello"] = "Emissario",
	["Emissario dei Celebrazione della Luna"] = "Emissario"
} or (locale == "ptBR" or locale == "ptPT") and {
	["Emissário da Baía dos Ancestrais"] = "Emissário",
	["Emissário da Liga de Arathor"] = "Emissário",
	["Emissária da Ilha da Conquista"] = "Emissário",
	["Emissário do Olho da Tormenta"] = "Emissário",
	["Emissário de Guilnéas"] = "Emissário",
	["Emissário dos Lançatroz"] = "Emissário",
	["Emissário Tushui"] = "Emissário",
	["Emissário da Asa de Prata"] = "Emissário",
	["Emissário dos Martelo Feroz"] = "Emissário",
	["Emissário do Festival da Lua"] = "Emissário"
} or (locale == "ruRU") and {
	["Эмиссар Берега Древних"] = "Эмиссар",
	["Эмиссар Лиги Аратора"] = "Эмиссар",
	["Эмиссар Острова Завоеваний"] = "Эмиссар",
	["Эмиссар Ока Бури"] = "Эмиссар",
	["Посланник Гилнеаса"] = "Посланник",
	["Эмиссар из клана Грозовой Вершины"] = "Эмиссар",
	["Эмиссар Тушуй"] = "Эмиссар",
	["Посланница Среброкрылых"] = "Посланница",
	["Посланник клана Громового Молота"] = "Посланник",
	["Эмиссар Лунного фестиваля"] = "Эмиссар"
}

local shorten = function(str, max)
	if str:len() > max then
		if goners then
			for find, replace in pairs(goners) do
				str = str:gsub(find, replace)
			end
		end
	end
	if str:len() > max then
		if str:find(" ") then
			-- test if the second word has a lowercase first letter,
			-- since this usually indicate a title
			local j = str:find(" ")
			local letter = str:sub(j+1,j+1)
			if letter == letter:lower() then
				str = str:sub(1, j-1)
			else
				-- if not, start from the end
				str = str:reverse()
				local new
				local pos = 1
				while pos < str:len() do
					local j = str:find(" ", pos)
					if j then
						local word = str:sub(pos, j-1)
						if new then
							if word:len() + new:len() + 1 <= max then
								new = new .. " " .. word 
							else
								break
							end
						else
							if word:len() <= max then
								new = word
							else
								break
							end
						end
						pos = j+1
					else
						break
					end
				end
				str = (new or str):reverse()
			end
		end
	end
	return str
end


------------------------------------------------------------------------------
-- 	NamePlate Aura Button Template
------------------------------------------------------------------------------

local Aura = CreateFrame("Frame")
local Aura_MT = { __index = Aura }

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

Aura.OnEnter = function(self)
	local unit = self:GetParent().unit
	if not UnitExists(unit) then
		return
	end
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetUnitAura(unit, self:GetID(), self:GetParent().filter)
	end
end

Aura.OnLeave = function(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end

Aura.UpdateTheme = function(self)
	updateConfig()
	
	local config = T.widgets.auras
	local aura_config = config.button
	local rowsize = config.rowsize
	local gap = config.padding
	local width, height = unpack(aura_config.size)
	local index = self:GetID()

	self:SetSize(width, height)
	self:ClearAllPoints()
	self:SetPoint(aura_config.anchor, (index-1)%rowsize * (width + gap), floor((index-1)/rowsize) * (height + gap))
	
	self.Icon:SetSize(unpack(aura_config.icon.size))
	self.Icon:ClearAllPoints()
	self.Icon:SetPoint(unpack(aura_config.icon.place))
	self.Icon:SetTexCoord(unpack(aura_config.icon.texCoord))
	
	self.Count:SetFontObject(aura_config.count.fontObject)
	self.Count:SetFontStyle(aura_config.count.fontStyle)
	self.Count:SetFontSize(aura_config.count.fontSize)
	self.Count:SetShadowOffset(unpack(aura_config.count.shadowOffset))
	self.Count:SetShadowColor(unpack(aura_config.count.shadowColor))
	self.Count:ClearAllPoints()
	self.Count:SetPoint(unpack(aura_config.count.place))
	
	self.Time:SetFontObject(aura_config.time.fontObject)
	self.Time:SetFontStyle(aura_config.time.fontStyle)
	self.Time:SetFontSize(aura_config.time.fontSize)
	self.Time:SetShadowOffset(unpack(aura_config.time.shadowOffset))
	self.Time:SetShadowColor(unpack(aura_config.time.shadowColor))
	self.Time:ClearAllPoints()
	self.Time:SetPoint(unpack(aura_config.time.place))
	
end

local DAY, HOUR, MINUTE = 86400, 3600, 60
Aura.CreateTimer = function(self, elapsed)
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
					self.Scaffold:StopFlash()
					self.Time:SetFormattedText("%1dd", floor(self.timeLeft / DAY))
					
				-- more than an hour
				elseif self.timeLeft > HOUR then
					self.Scaffold:StopFlash()
					self.Time:SetFormattedText("%1dh", floor(self.timeLeft / HOUR))
				
				-- more than a minute
				elseif self.timeLeft > MINUTE then
					self.Scaffold:StopFlash()
					self.Time:SetFormattedText("%1dm", floor(self.timeLeft / MINUTE))
				
				-- more than 10 seconds
				elseif self.timeLeft > 10 then 
					self.Scaffold:StopFlash()
					self.Time:SetFormattedText("%1d", floor(self.timeLeft))
				
				-- between 6 and 10 seconds
				elseif self.timeLeft >= 6 then
					self.Scaffold:StartFlash(.75, .75, .5, 1, true)
					self.Time:SetFormattedText("|cffff8800%1d|r", floor(self.timeLeft))
					
				-- between 3 and 5 seconds
				elseif self.timeLeft >= 3 then
					self.Scaffold:StartFlash(.75, .75, .5, 1, true)
					self.Time:SetFormattedText("|cffff0000%1d|r", floor(self.timeLeft))
					
				-- less than 3 seconds
				elseif self.timeLeft > 0 then
					self.Scaffold:StartFlash(.75, .75, .5, 1, true)
					self.Time:SetFormattedText("|cffff0000%.1f|r", self.timeLeft)
				else
					self.Scaffold:StopFlash()
					self.Time:SetText("")
				end	
			else
				self.Scaffold:StopFlash()
				self.Time:SetText("")
				self.Time:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end



------------------------------------------------------------------------------
-- 	Legion NamePlate Template
------------------------------------------------------------------------------

local NamePlate = CreateFrame("Frame")
local NamePlate_MT = { __index = NamePlate }

NamePlate.UpdateHealth = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		return
	end
	
	local health = UnitHealth(unit) -- got a Script ran too long error on this. Weird...
	local healthmax = UnitHealthMax(unit)
	
	self.Health:SetMinMaxValues(0, healthmax)
	self.Health:SetValue(health)

	self.Trivial:SetMinMaxValues(0, healthmax)
	self.Trivial:SetValue(health)
end

NamePlate.UpdateName = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		return
	end

	local name = UnitName(unit)
	local level = UnitLevel(unit)
	local classificiation = UnitClassification(unit)
	local isplayer = UnitIsPlayer(unit)
	local istrivial = UnitIsTrivial(unit)

	if isplayer then
		self.Level:SetText("")
		self.Name:SetFormattedText("%s %s", getlevelcolor(level) .. level .. "|r", name)
	elseif istrivial then
		self.Level:SetText(level)
		self.Name:SetText("")
	else
		local levelstring
		if classificiation == "worldboss" or (level and level < 1) then
			levelstring = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:18:18:0:0|t"
		elseif level and level > 0 then
			levelstring = getlevelcolor(level) .. level .. "|r"
			if classificiation == "elite" or classificiation == "rareelite" then
				levelstring = levelstring .. colors.chat.dimred.colorCode .. "+|r"
			end
			if classificiation == "rareelite" or classificiation == "rare" then
				levelstring = levelstring .. colors.chat.dimred.colorCode .. " (rare)|r"
			end
			levelstring = levelstring .. " "
		else
			levelstring = ""
		end
		self.Level:SetText("")
		self.Name:SetFormattedText("%s%s", levelstring, utf8sub(shorten(name, 18), 18, false))
	end
end

NamePlate.UpdateColor = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		return
	end

	local classificiation = UnitClassification(unit)
	local isplayer = UnitIsPlayer(unit)
	local isfriend = UnitIsFriend("player", unit)
	local isenemy = UnitIsEnemy("player", unit)
	local isneutral = UnitReaction(unit, "player") == 4
	local istapped = UnitIsTapDenied(unit)
	local _, class = UnitClass(unit)

	if isplayer then
		if isfriend then
			r, g, b = unpack(colors.reaction.civilian)
		else
			if class and colors.class[class] and module.db.profile.showEnemyClassColor then
				r, g, b = unpack(colors.class[class])
			else
				r, g, b = unpack(colors.reaction[1])
			end
		end
	else
		if isfriend then
			r, g, b = unpack(colors.reaction[5])
		elseif istapped then
			r, g, b = unpack(colors.tapped)
		elseif isneutral then
			r, g, b = unpack(colors.reaction[4])
		else
			r, g, b = unpack(colors.reaction[2])
		end
	end

	self.Health:SetStatusBarColor(r, g, b)	
	self.Trivial:SetStatusBarColor(r, g, b)
		
end

NamePlate.UpdateThreat = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		return
	end
	
	local threat = UnitThreatSituation(unit)

	if threat and threat > 0 then
		r, g, b = unpack(colors.threat[threat])
		self.Health:SetThreatColor(r, g, b)
		self.Health:ShowThreatTexture()
		self.Health.Glow:SetVertexColor(r, g, b)
		self.Trivial:SetThreatColor(r, g, b)
		self.Trivial:ShowThreatTexture()
		self.Trivial.Glow:SetVertexColor(r, g, b)
	else
		self.Health:HideThreatTexture()
		self.Health.Glow:SetVertexColor(0, 0, 0)
		self.Trivial:HideThreatTexture()
		self.Trivial.Glow:SetVertexColor(0, 0, 0)
	end
end

-- This function updates the target alpha of the current NamePlate, 
-- but the actual alpha and the transition are still done by the 
-- global OnUpdate handler for all the NamePlates.
local framelevel_counter = 0
NamePlate.UpdateAlpha = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		return
	end
	
	if UnitExists("target") then
		if UnitIsUnit(unit, "target") then
			self.target_alpha = 1 -- current target, keep alpha at max
		elseif UnitIsTrivial(unit) then 
			if module.db.profile.showTrivial then
				self.target_alpha = 1 
			else
				self.target_alpha = 0 
			end
		else
			self.target_alpha = .5 -- non-targets while you have an actual target
		end
	elseif UnitIsTrivial(unit) then 
		if module.db.profile.showTrivial then
			self.target_alpha = .95
		else
			self.target_alpha = 0 
		end
	else
		self.target_alpha = .85 -- no target selected
	end
	
	if UnitIsUnit("target", unit) then
		if self:GetFrameLevel() ~= 125 then
			self:SetFrameLevel(125) 
		end
	else
		if self:GetFrameLevel() ~= self.frameLevel then
			self:SetFrameLevel(self.frameLevel)
		end
	end

end

-- Not happy about the module callback in here, 
-- should find some semi-intelligent way of including this in 
-- the NamePlate template without any performance loss. 
NamePlate.UpdateCast = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		return
	end
	module:OnSpellCast("UNIT_TARGET", self.unit)
end

NamePlate.AddAuraButton = function(self, id)
	local aura = setmetatable(CreateFrame("Frame", nil, self.Auras), Aura_MT)
	aura:SetID(id)
	
	aura.Scaffold = LMP:NewChain(CreateFrame("Frame", nil, aura)) :Hide() :SetAlpha(0) :SetPoint("TOPLEFT", aura, 1, -1) :SetPoint("BOTTOMRIGHT", aura, -1, 1) :SetBackdrop(auraBackdrop) :SetBackdropColor(0,0,0,1) :SetBackdropBorderColor(.15, .15, .15) .__EndChain

	aura.Overlay = LMP:NewChain(CreateFrame("Frame", nil, aura.Scaffold)) :SetAllPoints(aura) :SetFrameLevel(aura.Scaffold:GetFrameLevel() + 2)  .__EndChain 

	aura.Icon = LMP:NewChain(aura.Scaffold:CreateTexture()) :SetDrawLayer("ARTWORK", 0) :ClearAllPoints() :SetPoint("TOPLEFT", aura, 3, -3) :SetPoint("BOTTOMRIGHT", aura, -3, 3) :SetTexCoord(5/65, 59/64, 5/64, 59/64) .__EndChain
	
	aura.Shade = LMP:NewChain(aura.Scaffold:CreateTexture()) :SetDrawLayer("ARTWORK", 2) :SetTexture(gUI4:GetMedia("Texture", "Shade", 64, 64, "Warcraft"):GetPath()) :SetAllPoints(aura.Icon) :SetVertexColor(0, 0, 0, 1) .__EndChain

	aura.Time = LMP:NewChain("FontString", nil, aura.Overlay) :SetFontObject(NumberFontNormalSmall) :SetTextColor(unpack(gUI4:GetColors("chat", "offwhite"))) :SetFontSize(10) :SetFontStyle("") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", 1) :SetPoint("BOTTOM", aura, 0, -12) .__EndChain

	aura.Count = LMP:NewChain("FontString", nil, aura.Overlay) :SetFontObject(NumberFontNormalSmall) :SetTextColor(unpack(gUI4:GetColors("chat", "normal"))) :SetFontSize(12) :SetFontStyle("") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", 1) :SetPoint("TOPLEFT", aura, 1, -1) .__EndChain

	-- madness to make it fade in and out nicely
	gUI4:ApplyFadersToFrame(aura.Scaffold)
	aura.Scaffold:SetFadeOut(.1)
	hooksecurefunc(aura.Icon, "SetTexture", function() 
		if aura:IsShown() and not aura.Scaffold:IsShown() then
			aura.Scaffold:SetAlpha(0)
			aura.Scaffold:Show()
			aura.Scaffold:StartFadeIn(.25, 1)
		end
	end)
	aura:HookScript("OnShow", function(self) 
		self.Scaffold:SetAlpha(0)
		self.Scaffold:Show()
		self.Scaffold:StartFadeIn(.25, 1)
	end)
	aura:HookScript("OnHide", function(self) self.Scaffold:Hide() end)
	aura:GetParent():HookScript("OnHide", function() aura.Scaffold:Hide() end)

	aura:SetScript("OnEnter", Aura.OnEnter)
	aura:SetScript("OnLeave", Aura.OnLeave)
	aura:UpdateTheme()
	
	return aura
end


NamePlate.UpdateAuras = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		self.Auras:Hide()
		return
	end
	
	local classificiation = UnitClassification(unit)
	local istrivial = UnitIsTrivial(unit) or classificiation == "trivial" or classificiation == "minus"
	if istrivial then
		self.Auras:Hide()
		return
	end
	
	local filter
	local reaction = UnitReaction(unit, "player")
	if reaction then 
		if reaction <= 4 then
			-- Reaction 4 is neutral and less than 4 becomes increasingly more hostile
			filter = "HARMFUL|PLAYER" -- blizz use INCLUDE_NAME_PLATE_ONLY, but that sucks. So we don't.
		else
			filter = "HELPFUL|PLAYER" -- blizz don't show beneficial auras, but we do. 
		end
	else
		filter = "NONE" -- no reaction means no interaction, and no need for our aura display
	end
	self.filter = filter
	
	
	local visible = 0
	local auras = self.Auras
	for i = 1, BUFF_MAX_DISPLAY do
		if filter == "NONE" and auras[i] then
			auras[i]:Hide()
		end
		
		local name, rank, texture, count, debuffType, duration, expirationTime, caster, _, nameplateShowPersonal, spellId, _, _, _, nameplateShowAll = UnitAura(unit, i, filter)
		
		if name then
			if not auras[i] then
				auras[i] = self:AddAuraButton(i)
			end
		
			if duration and duration > 0 then
				auras[i].Time:Show()
			else
				auras[i].Time:Hide()
			end
			
			auras[i].first = true
			auras[i].duration = duration
			auras[i].timeLeft = expirationTime
			auras[i]:SetScript("OnUpdate", auras[i].CreateTimer)

			if count > 1 then
				auras[i].Count:SetText(count)
			else
				auras[i].Count:SetText("")
			end

			if filter:find("HARMFUL") then
				local color = DebuffTypeColor[debuffType] 
				if not(color and color.r and color.g and color.b) then
					color = { r = 0.7, g = 0, b = 0 }
				end
				auras[i].Scaffold:SetBackdropBorderColor(color.r, color.g, color.b)
			else
				auras[i].Scaffold:SetBackdropBorderColor(.15, .15, .15)
			end

			auras[i].Icon:SetTexture(texture)
			
			if not auras[i]:IsShown() then
				auras[i]:Show()
			end
			
			visible = visible + 1
		else
			if auras[i] then
				auras[i]:Hide()
			end
		end
	end
	
	if visible == 0 then
		if self.Auras:IsShown() then
			self.Auras:Hide()
		end
	else
		if not self.Auras:IsShown() then
			self.Auras:Show()
		end
	end
	
end

NamePlate.UpdateRaidTarget = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		self.RaidIcon:Hide()
		return
	end
	
	local classificiation = UnitClassification(unit)
	local istrivial = UnitIsTrivial(unit) or classificiation == "trivial" or classificiation == "minus"
	if istrivial then
		self.RaidIcon:Hide()
		return
	end
	
	local index = GetRaidTargetIndex(unit)
	if index then
		SetRaidTargetIconTexture(self.RaidIcon, index)
		self.RaidIcon:Show()
	else
		self.RaidIcon:Hide()
	end
	
end

NamePlate.UpdateFaction = function(self)
	self:UpdateName()
	self:UpdateColor()
	self:UpdateThreat()
end

NamePlate.UpdateAll = function(self)
	self:UpdateAlpha()
	self:UpdateHealth()
	self:UpdateName()
	self:UpdateColor()
	self:UpdateThreat()
	self:UpdateRaidTarget()
	self:UpdateCast()
	self:UpdateAuras()
end

NamePlate.IsTrivial = function(self)
	local classificiation = UnitClassification(unit)
	local istrivial = UnitIsTrivial(unit) or classificiation == "trivial" or classificiation == "minus"
	return istrivial
end

NamePlate.OnShow = function(self)
	local unit = self.unit
	if not UnitExists(unit) then
		return
	end

	-- setup player classbars
	-- setup auras
	-- setup raid targets

	-- figure out whether to show the trivial or normal frame
	local classificiation = UnitClassification(unit)
	local istrivial = UnitIsTrivial(unit) or classificiation == "trivial" or classificiation == "minus"
	if istrivial then
		self.Trivial:Show()
		self.Health:Hide()
		self.Cast:Hide()
		self.Auras:Hide()
	else
		self.Health:Show()
		self.Auras:Hide()
		self.Trivial:Hide()
		self.Cast:Hide()
	end

	self:SetAlpha(0) -- set the actual alpha to 0
	self.current_alpha = 0 -- update stored alpha value
	self:UpdateAll() -- update all elements while it's still transparent
	self:Show() -- make the fully transparent frame visible

	VisiblePlates[self] = self.baseframe -- this will trigger the fadein 
end

NamePlate.OnHide = function(self)
	VisiblePlates[self] = false -- this will trigger the fadeout and hiding
end

NamePlate.UpdateTheme = function(self)
	updateConfig()
	
	-- the plate itself
	LMP:NewChain(self) :SetSize(unpack(T.size)) :EndChain()	

	-- healthbar
	LMP:NewChain(self.Health) :SetSize(unpack(T.bars.health.size)) :ClearAllPoints() :SetPoint(unpack(T.bars.health.place)) :SetStatusBarTexture(T.bars.health.textures.bar:GetPath()) :SetBackdropTexture(T.bars.health.textures.backdrop:GetPath()) :SetOverlayTexture(T.bars.health.textures.overlay:GetPath()) :SetThreatTexture(T.bars.health.textures.threat:GetPath()) :SetBackdropAlpha(T.bars.health.textures.backdrop:GetAlpha()) :EndChain()
	LMP:NewChain(self.Health.Glow) :SetSize(T.bars.health.textures.glow:GetTexSize()) :ClearAllPoints() :SetPoint(T.bars.health.textures.glow:GetPoint()) :SetTexture(T.bars.health.textures.glow:GetPath()) :SetVertexColor(T.bars.health.textures.glow:GetColor()) :EndChain()

	-- absorbbar
	--LMP:NewChain(self.Absorb) :SetSize(unpack(T.bars.absorb.size)) :ClearAllPoints() :SetPoint(unpack(T.bars.absorb.place)) :SetStatusBarTexture(T.bars.absorb.textures.bar:GetPath()) :SetBackdropTexture(T.bars.absorb.textures.backdrop:GetPath()) :SetOverlayTexture(T.bars.absorb.textures.overlay:GetPath()) :SetBackdropAlpha(T.bars.absorb.textures.backdrop:GetAlpha()) :EndChain()
	--LMP:NewChain(self.Absorb.Glow) :SetSize(T.bars.absorb.textures.glow:GetTexSize()) :ClearAllPoints() :SetPoint(T.bars.absorb.textures.glow:GetPoint()) :SetTexture(T.bars.absorb.textures.glow:GetPath()) :SetVertexColor(T.bars.absorb.textures.glow:GetColor()) :EndChain()

	-- trivial health bar
	LMP:NewChain(self.Trivial) :SetSize(unpack(T.bars.trivial.size)) :ClearAllPoints() :SetPoint(unpack(T.bars.trivial.place)) :SetStatusBarTexture(T.bars.trivial.textures.bar:GetPath()) :SetBackdropTexture(T.bars.trivial.textures.backdrop:GetPath()) :SetOverlayTexture(T.bars.trivial.textures.overlay:GetPath()) :SetOverlayAlpha(T.bars.trivial.textures.overlay:GetAlpha()) :SetThreatTexture(T.bars.trivial.textures.threat:GetPath()) :SetThreatAlpha(T.bars.trivial.textures.threat:GetAlpha()) :SetBackdropAlpha(T.bars.trivial.textures.backdrop:GetAlpha()) :EndChain()
	LMP:NewChain(self.Trivial.Glow) :SetSize(T.bars.trivial.textures.glow:GetTexSize()) :ClearAllPoints() :SetPoint(T.bars.trivial.textures.glow:GetPoint()) :SetTexture(T.bars.trivial.textures.glow:GetPath()) :SetVertexColor(T.bars.trivial.textures.glow:GetColor()) :EndChain()
	
	-- castbar
	LMP:NewChain(self.Cast) :SetSize(unpack(T.bars.cast.size)) :ClearAllPoints() :SetPoint(unpack(T.bars.cast.place)) :SetStatusBarTexture(T.bars.cast.textures.bar:GetPath()) :SetBackdropTexture(T.bars.cast.textures.backdrop:GetPath()) :SetOverlayTexture(T.bars.cast.textures.overlay:GetPath()) :SetBackdropAlpha(T.bars.cast.textures.backdrop:GetAlpha()) :EndChain()
	LMP:NewChain(self.Cast.Glow) :SetSize(T.bars.cast.textures.glow:GetTexSize()) :ClearAllPoints() :SetPoint(T.bars.cast.textures.glow:GetPoint()) :SetTexture(T.bars.cast.textures.glow:GetPath()) :SetVertexColor(T.bars.cast.textures.glow:GetColor()) :EndChain()
	LMP:NewChain(self.Spell.Name) :SetFontObject(T.widgets.spellname.fontobject) :SetFontSize(T.widgets.spellname.size) :SetFontStyle(T.widgets.spellname.fontstyle) :SetShadowOffset(unpack(T.widgets.spellname.shadowoffset)) :SetShadowColor(unpack(T.widgets.spellname.shadowcolor)) :SetTextColor(unpack(T.widgets.spellname.color)) :ClearAllPoints() :SetPoint(unpack(T.widgets.spellname.place)) :EndChain()
	LMP:NewChain(self.Spell) :SetSize(unpack(T.widgets.spellicon.size)) :ClearAllPoints() :SetPoint(unpack(T.widgets.spellicon.place)) :EndChain()
	LMP:NewChain(self.Spell.Icon) :SetSize(unpack(T.widgets.spellicon.icon.size)) :ClearAllPoints() :SetPoint(unpack(T.widgets.spellicon.icon.place)) :SetTexCoord(unpack(T.widgets.spellicon.icon.texcoord)) :EndChain()
	LMP:NewChain(self.Spell.Icon.Border) :SetSize(T.widgets.spellicon.textures.border:GetTexSize()) :ClearAllPoints() :SetPoint(T.widgets.spellicon.textures.border:GetPoint()) :SetTexCoord(T.widgets.spellicon.textures.border:GetTexCoord()) :SetTexture(T.widgets.spellicon.textures.border:GetPath()) :SetVertexColor(unpack(T.widgets.spellicon.textures.border:GetColor())) :SetAlpha(T.widgets.spellicon.textures.border:GetAlpha()) :EndChain()
	LMP:NewChain(self.Spell.Icon.Shield) :SetSize(T.widgets.spellicon.textures.shield:GetTexSize()) :ClearAllPoints() :SetPoint(T.widgets.spellicon.textures.shield:GetPoint()) :SetTexCoord(T.widgets.spellicon.textures.shield:GetTexCoord()) :SetTexture(T.widgets.spellicon.textures.shield:GetPath()) :SetVertexColor(unpack(T.widgets.spellicon.textures.shield:GetColor())) :SetAlpha(T.widgets.spellicon.textures.shield:GetAlpha()) :EndChain()

	-- auras
	LMP:NewChain(self.Auras) :SetSize(T.widgets.auras.rowsize * (T.widgets.auras.button.size[1]) + ((T.widgets.auras.rowsize - 1) * T.widgets.auras.padding), T.widgets.auras.button.size[2]) :ClearAllPoints() :SetPoint(unpack(T.widgets.auras.place)) :EndChain()

	-- name
	LMP:NewChain(self.Name) :SetFontObject(T.widgets.name.fontobject) :SetFontSize(T.widgets.name.size) :SetFontStyle(T.widgets.name.fontstyle) :SetShadowOffset(unpack(T.widgets.name.shadowoffset)) :SetShadowColor(unpack(T.widgets.name.shadowcolor)) :SetTextColor(unpack(T.widgets.name.color)) :ClearAllPoints() :SetPoint(unpack(T.widgets.name.place)) :EndChain()
	
	-- level
	LMP:NewChain(self.Level) :SetFontObject(T.widgets.level.fontobject) :SetFontSize(T.widgets.level.size) :SetFontStyle(T.widgets.level.fontstyle) :SetShadowOffset(unpack(T.widgets.level.shadowoffset)) :SetShadowColor(unpack(T.widgets.level.shadowcolor)) :SetTextColor(unpack(T.widgets.level.color)) :ClearAllPoints() :SetPoint(unpack(T.widgets.level.place)) :EndChain()
	
	-- boss icon
	LMP:NewChain(self.BossIcon) :SetSize(unpack(T.widgets.skullicon.size)) :ClearAllPoints() :SetPoint(unpack(T.widgets.skullicon.place)) :SetTexture(T.widgets.skullicon.texture) :EndChain()
	
	-- elite/boss/rare textures
	-- self.eliteicon
	
	-- raid icon
	-- plate.raidicon
	LMP:NewChain(self.RaidIcon) :SetSize(unpack(T.widgets.raidicon.size)) :ClearAllPoints() :SetPoint(unpack(T.widgets.raidicon.place)) :SetTexture(T.widgets.raidicon.texture) :EndChain()
	
	self.Health:SetBackdropColor(0, 0, 0, 1)
	
	LMP:NewChain(self.Health) :SetFrameStrata("BACKGROUND") :SetFrameLevel(5) :EndChain()
	LMP:NewChain(self.Health.Glow) :SetDrawLayer("BACKGROUND", -1) :EndChain()
	--LMP:NewChain(self.Absorb) :SetFrameStrata("BACKGROUND") :SetFrameLevel(6) :EndChain()
	--LMP:NewChain(self.Absorb.Glow) :SetDrawLayer("BACKGROUND", -1) :EndChain()
	LMP:NewChain(self.Trivial) :SetFrameStrata("BACKGROUND") :SetFrameLevel(5) :EndChain()
	LMP:NewChain(self.Trivial.Glow) :SetDrawLayer("BACKGROUND", -1) :EndChain()
	LMP:NewChain(self.Cast) :SetFrameStrata("BACKGROUND") :SetFrameLevel(5) :EndChain()
	LMP:NewChain(self.Cast.Glow) :SetDrawLayer("BACKGROUND", -1) :EndChain()
	LMP:NewChain(self.Highlight) :SetDrawLayer("OVERLAY", -1) :SetBlendMode("ADD") :EndChain()
	LMP:NewChain(self.Name) :SetDrawLayer("ARTWORK") :EndChain()
	LMP:NewChain(self.Level) :SetDrawLayer("OVERLAY") :EndChain()
	LMP:NewChain(self.Spell.Name) :SetDrawLayer("OVERLAY") :EndChain()
	LMP:NewChain(self.Spell.Icon) :SetDrawLayer("BACKGROUND", 0) :EndChain()
	LMP:NewChain(self.Spell.Icon.Border) :SetDrawLayer("BORDER", 0) :EndChain()
	LMP:NewChain(self.Spell.Icon.Shield) :SetDrawLayer("BORDER", 1) :EndChain()
	LMP:NewChain(self.Spell.Icon.Shade) :SetDrawLayer("BACKGROUND", 2) :EndChain()
	LMP:NewChain(self.EliteIcon) :SetDrawLayer("OVERLAY") :EndChain()
	LMP:NewChain(self.RaidIcon) :SetDrawLayer("OVERLAY") :EndChain()
	LMP:NewChain(self.BossIcon) :SetDrawLayer("OVERLAY") :EndChain()
	
end


------------------------------------------------------------------------------
-- 	Nameplate Update Cycle
------------------------------------------------------------------------------

-- Proxy function to allow us to exit the update by returning,
-- but still continue looping through the remaining castbars, if any!
local UpdateCastBar = function(CastBar, unit, castdata, elapsed)
	if not UnitExists(unit) then 
		castdata.casting = nil
		castdata.castid = nil
		castdata.channeling = nil
		CastBar:SetValue(0)
		--CastBar:Clear()
		CastBar:Hide()
		return 
	end
	local r, g, b
	if castdata.casting or castdata.tradeskill then
		local duration = castdata.duration + elapsed
		if duration >= castdata.max then
			castdata.casting = nil
			castdata.tradeskill = nil
			castdata.total = nil
			--CastBar:Clear()
			CastBar:Hide()
		end
		if CastBar.SafeZone then
			if unit == "player" then
				local width = CastBar:GetWidth()
				local ms = GetLatency()
				if ms ~= 0 then
					local safeZonePercent = (width / castdata.max) * (ms / 1e5)
					if safeZonePercent > 1 then safeZonePercent = 1 end
					CastBar.SafeZone:SetWidth(width * safeZonePercent)
					if CastBar.SafeZone.Delay then
						CastBar.SafeZone.Delay:SetFormattedText("%s", ms .. MILLISECONDS_ABBR)
					end
					if not CastBar.SafeZone:IsShown() then
						CastBar.SafeZone:Show()
					end
				else
					CastBar.SafeZone:Hide()
					if CastBar.SafeZone.Delay then
						CastBar.SafeZone.Delay:SetText("")
					end
				end
			else
				CastBar.SafeZone:Hide()
			end
		end
		if CastBar.Value then
			if castdata.tradeskill then
				CastBar.Value:SetText(formatTime(castdata.max - duration))
			elseif self.delay and self.delay ~= 0 then
				CastBar.Value:SetFormattedText("%s|cffff0000 -%s|r", formatTime(floor(castdata.max - duration)), formatTime(castdata.delay))
			else
				CastBar.Value:SetText(formatTime(castdata.max - duration))
			end
		end
		castdata.duration = duration
		CastBar:SetValue(duration)

	elseif castdata.channeling then
		local duration = castdata.duration - elapsed
		if duration <= 0 then
			castdata.channeling = nil
			--CastBar:Clear()
			CastBar:Hide()
		end
		if CastBar.SafeZone then
			if unit == "player" then
				local width = CastBar:GetWidth()
				local ms = GetLatency()
				if ms ~= 0 then
					local safeZonePercent = (width / castdata.max) * (ms / 1e5)
					if safeZonePercent > 1 then safeZonePercent = 1 end
					CastBar.SafeZone:SetWidth(width * safeZonePercent)
					if CastBar.SafeZone.Delay then
						CastBar.SafeZone.Delay:SetFormattedText("%s", ms .. MILLISECONDS_ABBR)
					end
				else
					CastBar.SafeZone:Hide()
					if CastBar.SafeZone.Delay then 
						CastBar.SafeZone.Delay:SetText("")
					end
				end
			else
				CastBar.SafeZone:Hide()
			end
		end
		if CastBar.Value then
			if castdata.delay and castdata.delay ~= 0 then
				CastBar.Value:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, castdata.delay)
			else
				CastBar.Value:SetFormattedText("%.1f", duration)
			end
		end
		castdata.duration = duration
		CastBar:SetValue(duration)
	else
		castdata.casting = nil
		castdata.castid = nil
		castdata.channeling = nil
		CastBar:SetValue(0)
		--CastBar:Clear()
		CastBar:Hide()
	end
end

-- Update Cycle for Legion NamePlates
local OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < HZ then
		return
	end
	
	-- Update any running castbars
	for owner, CastBar in pairs(CastBarPool) do
		UpdateCastBar(CastBar, owner.unit, CastData[CastBar], elapsed)
	end

	-- Update alpha of all nameplates
	for plate, baseframe in pairs(VisiblePlates) do
		if baseframe then
			plate:UpdateHealth()
			plate:UpdateColor()
			plate:UpdateAlpha()
			--plate:UpdateAuras()
		else
			plate.target_alpha = 0
			--plate.Auras:Hide()
		end
		
		local step_in = elapsed/time_in
		local step_out = elapsed/time_out
		
		if plate.current_alpha ~= plate.target_alpha then
			FadingPlates[plate] = true
			if plate.target_alpha > plate.current_alpha + step_in then
				plate.current_alpha = plate.current_alpha + step_in -- fade in
			elseif plate.target_alpha < plate.current_alpha - step_out then
				plate.current_alpha = plate.current_alpha - step_out -- fade out
			else
				plate.current_alpha = plate.target_alpha -- fading done
				FadingPlates[plate] = false
			end
			plate:SetAlpha(plate.current_alpha)
		else
			FadingPlates[plate] = false
		end

		if plate.current_alpha == 0 and plate.target_alpha == 0 then
			VisiblePlates[plate] = nil
			plate:Hide()
		end
	end	
end


-- Called when a new Legion NamePlate is created
-- This is where we create our matching frame, and set it up.
function module:OnNamePlateCreated(baseframe)

	-- Shazam! A new plate is given life! 
	local plate = setmetatable(CreateFrame("Frame", "GUI4" .. baseframe:GetName(), WorldFrame), NamePlate_MT)
	plate:Hide()
	plate:SetAlpha(0)
	plate:SetFrameStrata("BACKGROUND")
	plate:SetFrameLevel(0)
	plate:SetScale(SCALE)
	plate:SetSize(1,1) 
	plate.baseframe = baseframe
	plate.target_alpha = 0
	plate.current_alpha = 0

	-- because it looks retarded when they glide into each other
	ramelevel_counter = framelevel_counter + 1
	if framelevel_counter > 120 then
		framelevel_counter = 1
	end
	plate.frameLevel = framelevel_counter


	-- trying out semlar's positioning tricks here,
	-- but added in tidyplates hide/show trick
	-------------------------------------------------------
	local sizer = CreateFrame("Frame", nil, plate)
	sizer:SetPoint("BOTTOMLEFT", WorldFrame)
	sizer:SetPoint("TOPRIGHT", baseframe, "CENTER")
	sizer:SetScript("OnSizeChanged", function(self, width, height)
		--self.plate:Hide() -- no idea why, but moving hidden frames is faster than moving visible ones
		self.plate:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", floor(width), floor(height)) 
		--self.plate:Show() -- show the frame again now that it's moved
	end)
	sizer.plate = plate


	-- Forcefully hide the Legion NamePlate's UnitFrame 
	-- Only the baseframe is secure, so this is safe
	-------------------------------------------------------
	local unitframe = baseframe.UnitFrame -- this always exists, but just in case...
	if unitframe then
		unitframe:Hide()
		unitframe:HookScript("OnShow", function(self) self:Hide() end)
	end


	-- debugging
	-------------------------------------------------------
	--local debugtex = plate:CreateTexture(nil, "BACKGROUND")
	--debugtex:SetAllPoints()
	--debugtex:SetColorTexture(0, 0, 0, .75)

	
	-- add bars
	-------------------------------------------------------
	plate.Health = LMP:NewChain("StatusBar", nil, plate) :Hide() :SetStatusBarColor(unpack(colors.chat.normal)) .__EndChain
	plate.Health.Glow = LMP:NewChain(plate.Health:CreateTexture()) .__EndChain
	plate.Absorb = LMP:NewChain("StatusBar", nil, plate) :Hide() :SetStatusBarColor(unpack(colors.chat.normal)) .__EndChain
	plate.Absorb.Glow = LMP:NewChain(plate.Absorb:CreateTexture()) .__EndChain
	plate.Trivial = LMP:NewChain("StatusBar", nil, plate) :Hide() :SetStatusBarColor(unpack(colors.chat.normal)) .__EndChain
	plate.Trivial.Glow = LMP:NewChain(plate.Trivial:CreateTexture()) .__EndChain
	plate.Cast = LMP:NewChain("StatusBar", nil, plate) :Hide() :SetFrameLevel(5) :SetStatusBarColor(unpack(colors.chat.normal)) .__EndChain
	plate.Cast.Glow = LMP:NewChain(plate.Cast:CreateTexture()) .__EndChain


	-- add other regions
	-------------------------------------------------------
	plate.Highlight = LMP:NewChain(plate.Health:CreateTexture()) :Hide() :SetAllPoints() :SetBlendMode("ADD") :SetColorTexture(1, 1, 1, 1/4) :SetDrawLayer("BACKGROUND", 1) .__EndChain
	plate.Name = LMP:NewChain("FontString", nil, plate.Health) :SetDrawLayer("OVERLAY") :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowOffset(.75, -.75) :SetShadowColor(0, 0, 0, 1) :SetTextColor(1, 1, 1)  .__EndChain
	plate.Level = LMP:NewChain("FontString", nil, plate.Trivial) :SetDrawLayer("OVERLAY") :SetFontObject(TextStatusBarText) :SetFontSize(15) :SetFontStyle() :SetShadowOffset(.75, -.75) :SetShadowColor(0, 0, 0, 1) :SetTextColor(1, 1, 1)  .__EndChain
	plate.Spell = LMP:NewChain(CreateFrame("Frame", nil, plate.Cast)) .__EndChain
	plate.Spell.Name = LMP:NewChain("FontString", nil, plate.Cast) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowOffset(.75, -.75) :SetShadowColor(0, 0, 0, 1) :SetTextColor(1, 1, 1)  .__EndChain
	plate.Spell.Icon = LMP:NewChain(plate.Spell:CreateTexture()) .__EndChain
	plate.Spell.Icon.Border = LMP:NewChain(plate.Spell:CreateTexture()) .__EndChain
	plate.Spell.Icon.Shield = LMP:NewChain(plate.Spell:CreateTexture()) .__EndChain
	plate.Spell.Icon.Shade = LMP:NewChain(plate.Spell:CreateTexture()) .__EndChain
	plate.EliteIcon = LMP:NewChain(plate.Health:CreateTexture()) :Hide() .__EndChain
	plate.RaidIcon = LMP:NewChain(plate.Health:CreateTexture()) :Hide() .__EndChain
	plate.BossIcon = LMP:NewChain(plate.Health:CreateTexture()) :Hide() .__EndChain

	
	-- Quality of life shortcuts so I don't have to rewrite my castbar code.
	-- I'm keeping the original parent keys too, though, 
	-- because I don't want to rewrite my styling code either. 
	-- (I'll do all that later, but for now... need to get there!)
	plate.Cast.Name = plate.Spell.Name
	plate.Cast.Icon = plate.Spell.Icon
	plate.Cast.Shield = plate.Spell.Icon.Shield
	
	
	-- auras!
	-------------------------------------------------------
	plate.Auras = LMP:NewChain(CreateFrame("Frame", nil, plate)) :Hide() :SetAllPoints() .__EndChain
	
	
	-- apply smoothing to our bars
	-------------------------------------------------------
	gUI4:ApplySmoothing(plate.Health)
	gUI4:ApplySmoothing(plate.Trivial)
	gUI4:ApplySmoothing(plate.Cast)
	

	-- put it into our registry
	-------------------------------------------------------
	AllPlates[baseframe] = plate


	-- fire off initial updates
	-------------------------------------------------------
	plate:UpdateTheme() 
	
end

-- Called when a Legion NamePlate is shown
function module:OnNamePlateAdded(unit)
	local plate = self:GetNamePlateForUnit(unit)
	if plate then
		plate.unit = unit
		plate:OnShow(unit)
	end
end

-- Called when a Legion NamePlate is hidden
function module:OnNamePlateRemoved(unit)
	local plate = self:GetNamePlateForUnit(unit)
	if plate then
		plate.unit = nil
		plate:OnHide()
	end
end

function module:OnRaidTargetUpdate()
	self:ForAllPlates("UpdateRaidTarget")
end

-- nameplate scale update, to keep it pixel perfect
function module:UpdateAllScales()
	local scale = UIParent:GetEffectiveScale() -- WorldFrame:GetHeight()/UIParent:GetHeight()
	if scale then
		SCALE = scale
	end
	self:ForAllPlates("SetScale", SCALE)
end

function module:UpdateAllPlates()
	self:ForAllPlates("UpdateAll")
end

-- Utility function to get our own NamePlate based on the unit
function module:GetNamePlateForUnit(unit)
	local baseframe = C_NamePlate.GetNamePlateForUnit(unit)
	if baseframe then
		return AllPlates[baseframe]
	end
end

function module:GetNamePlates()
	return pairs(AllPlates)
end

function module:ForAllPlates(method, ...)
	for baseframe, plate in self:GetNamePlates() do
		if type(method) == "string" then
			plate[method](plate, ...)
		else
			method(plate, ...)
		end 
	end
end
 
function module:OnSpellCast(event, ...)
	local unit = ...
	if not unit or not UnitExists(unit) then
		return
	end
	
	local plate = self:GetNamePlateForUnit(unit)
	if not plate then
		return
	end

	local CastBar = plate.Cast
	if not CastData[CastBar] then
		CastData[CastBar] = {}
	end

	local castdata = CastData[CastBar]
	if not CastBarPool[plate] then
		CastBarPool[plate] = CastBar
	end
	
	if event == "UNIT_SPELLCAST_START" then
		local unit, spell = ...
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
		if not name then
			--CastBar:Clear()
			CastBar:Hide()
			return
		end
		endTime = endTime / 1e3
		startTime = startTime / 1e3

		local now = GetTime()
		local max = endTime - startTime

		castdata.castid = castid
		castdata.duration = now - startTime
		castdata.max = max
		castdata.delay = 0
		castdata.casting = true
		castdata.interrupt = notInterruptable
		castdata.tradeskill = isTradeSkill
		castdata.total = nil
		castdata.starttime = nil
		
		CastBar:SetMinMaxValues(0, castdata.total or castdata.max)
		CastBar:SetValue(castdata.duration) 

		if CastBar.Name then CastBar.Name:SetText(utf8sub(text, 32, true)) end
		if CastBar.Icon then CastBar.Icon:SetTexture(texture) end
		if CastBar.Value then CastBar.Value:SetText("") end
		if CastBar.Shield then 
			if castdata.interrupt and not UnitIsUnit(unit ,"player") then
				CastBar.Shield:Show()
			else
				CastBar.Shield:Hide()
			end
		end
		
		if CastBar.SafeZone then
			if unit == "player" then
				--CastBar.SafeZone:SetWidth()
				--CastBar.SafeZone:Show()
			else
				CastBar.SafeZone:Hide()
			end
		end
		
		CastBar:Show()
		
		
	elseif event == "UNIT_SPELLCAST_FAILED" then
		local unit, spellname, _, castid = ...
		if castdata.castid ~= castid then
			return
		end
		castdata.tradeskill = nil
		castdata.total = nil
		castdata.casting = nil
		castdata.interrupt = nil
		CastBar:SetValue(0)
		--CastBar:Clear()
		CastBar:Hide()
		
	elseif event == "UNIT_SPELLCAST_STOP" then
		local unit, spellname, _, castid = ...
		if castdata.castid ~= castid then
			return
		end
		castdata.casting = nil
		castdata.interrupt = nil
		castdata.tradeskill = nil
		castdata.total = nil
		CastBar:SetValue(0)
		--CastBar:Clear()
		CastBar:Hide()
		
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		local unit, spellname, _, castid = ...
		if castdata.castid ~= castid then
			return
		end
		castdata.tradeskill = nil
		castdata.total = nil
		castdata.casting = nil
		castdata.interrupt = nil
		CastBar:SetValue(0)
		--CastBar:Clear()
		CastBar:Hide()
		
	elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then	
		local unit, spellname = ...
		if castdata.casting then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
			if name then
				castdata.interrupt = notInterruptable
			end
		elseif castdata.channeling then
			local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
			if name then
				castdata.interrupt = notInterruptable
			end
		end
		if CastBar.Shield then 
			if castdata.interrupt and not UnitIsUnit(unit ,"player") then
				CastBar.Shield:Show()
			else
				CastBar.Shield:Hide()
			end
		end
	
	
	elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then	
		local unit, spellname = ...
		if castdata.casting then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
			if name then
				castdata.interrupt = notInterruptable
			end
		elseif castdata.channeling then
			local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
			if name then
				castdata.interrupt = notInterruptable
			end
		end
		if CastBar.Shield and not UnitIsUnit(unit ,"player") then 
			if castdata.interrupt then
				CastBar.Shield:Show()
			else
				CastBar.Shield:Hide()
			end
		end
	
	
	elseif event == "UNIT_SPELLCAST_DELAYED" then
		local unit, spellname, _, castid = ...
		local name, _, text, texture, startTime, endTime = UnitCastingInfo(unit)
		if not startTime or not castdata.duration then return end
		local duration = GetTime() - (startTime / 1000)
		if duration < 0 then duration = 0 end
		castdata.delay = (castdata.delay or 0) + castdata.duration - duration
		castdata.duration = duration
		CastBar:SetValue(duration)
	
		
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then	
		local unit, spellname = ...
		local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
		if not name then
			--CastBar:Clear()
			CastBar:Hide()
			return
		end
		
		endTime = endTime / 1e3
		startTime = startTime / 1e3

		local max = endTime - startTime
		local duration = endTime - GetTime()

		castdata.duration = duration
		castdata.max = max
		castdata.delay = 0
		castdata.channeling = true
		castdata.interrupt = notInterruptable

		castdata.casting = nil
		castdata.castid = nil

		CastBar:SetMinMaxValues(0, max)
		CastBar:SetValue(duration)
		
		if CastBar.Name then CastBar.Name:SetText(utf8sub(name, 32, true)) end
		if CastBar.Icon then CastBar.Icon:SetTexture(texture) end
		if CastBar.Value then CastBar.Value:SetText("") end
		if CastBar.Shield then 
			if castdata.interrupt and not UnitIsUnit(unit ,"player") then
				CastBar.Shield:Show()
			else
				CastBar.Shield:Hide()
			end
		end
		if CastBar.SafeZone then
			if unit == "player" then
				--CastBar.SafeZone:SetWidth()
				--CastBar.SafeZone:Show()
			else
				CastBar.SafeZone:Hide()
			end
		end

		CastBar:Show()
		
		
	elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
		local unit, spellname = ...
		local name, _, text, texture, startTime, endTime, oldStart = UnitChannelInfo(unit)
		if not name or not castdata.duration then return end
		local duration = (endTime / 1000) - GetTime()
		castdata.delay = (castdata.delay or 0) + castdata.duration - duration
		castdata.duration = duration
		castdata.max = (endTime - startTime) / 1000
		CastBar:SetMinMaxValues(0, castdata.max)
		CastBar:SetValue(duration)
	
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		local unit, spellname = ...
		if CastBar:IsShown() then
			castdata.channeling = nil
			castdata.interrupt = nil
			CastBar:SetValue(castdata.max)
			--CastBar:Clear()
			CastBar:Hide()
		end
		
	elseif event == "UNIT_TARGET" 
	or event == "PLAYER_TARGET_CHANGED" 
	or event == "PLAYER_FOCUS_CHANGED" then 
		local unit = self.unit
		if not UnitExists(unit) then
			return
		end
		if UnitCastingInfo(unit) then
			self:OnSpellCast("UNIT_SPELLCAST_START", unit)
			return
		end
		if UnitChannelInfo(self.unit) then
			self:OnSpellCast("UNIT_SPELLCAST_CHANNEL_START", unit)
			return
		end
		castdata.casting = nil
		castdata.interrupt = nil
		castdata.tradeskill = nil
		castdata.total = nil
		CastBar:SetValue(0)
		--CastBar:Clear()
		CastBar:Hide()
	end
end

function module:OnEvent(event, ...)
	if (event == "NAME_PLATE_CREATED") then
		local baseframe = ...
		self:OnNamePlateCreated(baseframe)
	elseif (event == "NAME_PLATE_UNIT_ADDED") then
		local unit = ...
		self:OnNamePlateAdded(unit)
	elseif (event == "NAME_PLATE_UNIT_REMOVED") then
		local unit = ...
		self:OnNamePlateRemoved(unit)
	elseif event == "RAID_TARGET_UPDATE" then
		self:OnRaidTargetUpdate()
	elseif event == "UNIT_AURA" then
		local unit = ...
		local plate = self:GetNamePlateForUnit(unit)
		if plate then
			plate:UpdateAuras()
		end
	elseif event == "UNIT_FACTION" then
		local unit = ...
		local plate = self:GetNamePlateForUnit(unit)
		if plate then
			plate:UpdateFaction()
		end
	elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
		self:UpdateAllScales()
	else
		self:UpdateAllPlates()
	end
end

function module:StartListener()
	-- detection, showing & hiding
	self:RegisterEvent("NAME_PLATE_CREATED", "OnEvent")
	self:RegisterEvent("NAME_PLATE_UNIT_ADDED", "OnEvent")
	self:RegisterEvent("NAME_PLATE_UNIT_REMOVED", "OnEvent")

	-- We're not allowed to edit these at all -_-
	-- These are friendly nameplates in instances (which includes our WoD garrison)
	--self:RegisterEvent("FORBIDDEN_NAME_PLATE_CREATED", "OnEvent")
	--self:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_ADDED", "OnEvent")
	--self:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_REMOVED", "OnEvent")

	-- various updates
	self:RegisterEvent("PLAYER_CONTROL_GAINED", "OnEvent")
	self:RegisterEvent("PLAYER_CONTROL_LOST", "OnEvent")
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent") 
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("RAID_TARGET_UPDATE", "OnEvent")
	self:RegisterEvent("UNIT_AURA", "OnEvent")
	self:RegisterEvent("UNIT_FACTION", "OnEvent")
	self:RegisterEvent("UNIT_LEVEL", "OnEvent")
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")

	-- scale changes
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "OnEvent")
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")
	
	-- options changes
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	self:RegisterEvent("CVAR_UPDATE", "OnEvent")
	
	-- castbars
	self:RegisterEvent("UNIT_SPELLCAST_START", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "OnSpellCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnSpellCast")
	--self:RegisterEvent("UNIT_TARGET", "OnSpellCast")
	--self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnSpellCast")
	--self:RegisterEvent("PLAYER_FOCUS_CHANGED", "OnSpellCast")


	if not self.Updater then
		self.Updater = CreateFrame("Frame", "GUI4NamePlateWatcher", WorldFrame)
		self.Updater:SetFrameStrata("TOOLTIP")
	end

	self.Updater:SetScript("OnUpdate", OnUpdate)
end

-- Fire off theme updates for all active submodules.
-- ...not that we actually have any, but still...
function module:UpdateTheme(_, _, addonName)
	if addonName ~= tostring(self) then return end
	updateConfig()
	
	-- Setting the base size involves changing the size of secure unit buttons, 
	-- but since we're using our out of combat wrapper, we should be safe.
	NamePlateDriverMixin:SetBaseNamePlateSize(unpack(T.size))
	--local width, height = unpack(T.size)
	--C_NamePlate.SetNamePlateFriendlySize(width, height)
	--C_NamePlate.SetNamePlateEnemySize(width, height)

	-- Disable Blizzard rescale
	NamePlateDriverFrame.UpdateNamePlateOptions = function() end
	
	-- Make sure nameplates are always scaled at 1
	SetCVar("NamePlateVerticalScale", "1")
	SetCVar("NamePlateHorizontalScale", "1")	

	hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", function(self) print(self:GetName()) end)
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings()
	-- Insets at the top and bottom of the screen 
	-- which the target nameplate will be kept away from. 
	-- Used to avoid the target plate being overlapped 
	-- by the target frame or actionbars and keep it in view.
	SetCVar("nameplateLargeTopInset", .15) -- default .1
	SetCVar("nameplateOtherTopInset", .15) -- default .08
	SetCVar("nameplateLargeBottomInset", .15) -- default .15
	SetCVar("nameplateOtherBottomInset", .1) -- default .1


	SetCVar("nameplateClassResourceTopInset", 0)
	SetCVar("nameplateGlobalScale", 1)
	SetCVar("NamePlateHorizontalScale", 1)
	SetCVar("NamePlateVerticalScale", 1)

	-- Scale modifier for large plates, used for important monsters
	SetCVar("nameplateLargerScale", 1) -- default 1.2

	-- The maximum distance to show a nameplate at
	SetCVar("nameplateMaxDistance", 100)

	-- The minimum scale and alpha of nameplates
	SetCVar("nameplateMinScale", 1) -- .5 default .8
	SetCVar("nameplateMinAlpha", .3) -- default .5

	-- The minimum distance from the camera plates will reach their minimum scale and alpa
	SetCVar("nameplateMinScaleDistance", 30) -- default 10
	SetCVar("nameplateMinAlphaDistance", 30) -- default 10

	-- The maximum scale and alpha of nameplates
	SetCVar("nameplateMaxScale", 1) -- default 1
	SetCVar("nameplateMaxAlpha", 0.85) -- default 0.9
	
	-- The maximum distance from the camera where plates will still have max scale and alpa
	SetCVar("nameplateMaxScaleDistance", 10) -- default 10
	SetCVar("nameplateMaxAlphaDistance", 10) -- default 10

	-- Show nameplates above heads or at the base (0 or 2)
	SetCVar("nameplateOtherAtBase", 0)

	-- Scale and Alpha of the selected nameplate (current target)
	SetCVar("nameplateSelectedAlpha", 1) -- default 1
	SetCVar("nameplateSelectedScale", 1) -- default 1


end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_NamePlates_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end
	
	if IsAddOnLoaded("Blizzard_NamePlates") then
		self:ApplySettings()
	else
		self:RegisterEvent("ADDON_LOADED", function(_, _, addonName)
			if addonName ~= tostring(self) then return end
			self:ApplySettings()
			self:UnregisterEvent("ADDON_LOADED")
		end)
	end
		
	self:RegisterEvent("VARIABLES_LOADED", "ApplySettings")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "StartListener")
end

function module:OnEnable()
	self:SetActiveTheme(self.db.profile.skin)
end
