local addon = ...
local GP_LibStub = GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Auras", true)
if not parent then return end

local module = parent:NewModule("Buffs", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T

-- Lua API
local _G = _G
local ipairs, pairs, unpack = ipairs, pairs, unpack
local tconcat, tinsert, wipe = table.concat, table.insert, table.wipe
local tostring = tostring 
local floor = math.floor

-- WoW API
local CreateFrame = _G.CreateFrame
local DebuffTypeColor = _G.DebuffTypeColor
local GameTooltip_Hide = _G.GameTooltip_Hide
local GetInventoryItemTexture = _G.GetInventoryItemTexture
local GetItemInfo = _G.GetItemInfo
local GetTime = _G.GetTime
local GetWeaponEnchantInfo = _G.GetWeaponEnchantInfo
local hooksecurefunc = _G.hooksecurefunc
local RegisterStateDriver = _G.RegisterStateDriver
local RegisterAttributeDriver = _G.RegisterAttributeDriver
local SecureHandlerSetFrameRef = _G.SecureHandlerSetFrameRef
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitAura = _G.UnitAura
local UnitRace = _G.UnitRace
local UnitSex = _G.UnitSex
local UnregisterStateDriver = _G.UnregisterStateDriver
local GameTooltip = _G.GameTooltip
local NumberFontNormalSmall = _G.NumberFontNormalSmall

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		--consolidate = true, -- must purge this from saved variables too, later
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
	T = parent:GetActiveTheme()
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
				elseif self.timeLeft >= 6 then
					self.scaffold:StartFlash(.75, .75, .5, 1, true)
					self.remaining:SetFormattedText("|cffff8800%1d|r", floor(self.timeLeft))
					
				-- between 3 and 5 seconds
				elseif self.timeLeft >= 3 then
					self.scaffold:StartFlash(.75, .75, .5, 1, true)
					self.remaining:SetFormattedText("|cffff0000%1d|r", floor(self.timeLeft))
					
				-- less than 3 seconds
				elseif self.timeLeft > 0 then
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
	--local consolidate = button.consolidate
	local name, _, icon, count, debuffType, duration, expirationTime, _, _, _, _, _, _, _, _, _ = UnitAura(unit, id, filter)
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
			local color = DebuffTypeColor[debuffType] 
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

local function updateEnchant(button, slot)
	button.icon:SetTexture(GetInventoryItemTexture("player", slot))

	local offset
	local weapon = button:GetName():sub(-1)
	
	-- 2017-04-24: 
	-- 
	-- Fixing a bug related to offhand weapon enchant returns. Seem to have gotten the return arguments 
	-- from GetWeaponEnchantInfo() wrong, or they might have changed without my noticing. 
	-- Either way, according to wowpedia, this is what the function currently returns:
	-- 
	-- local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, 
	-- 	     hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantId = GetWeaponEnchantInfo()
	-- 
	-- Source: http://wow.gamepedia.com/API_GetWeaponEnchantInfo

	if weapon:match("1") then
		offset = 2
	elseif weapon:match("2") then
		offset = 6 -- used to be? 5
	end
	
	local expiration = select(offset, GetWeaponEnchantInfo())
	if (expiration and expiration > 0) then
		button.remaining:Show()
	else
		button.remaining:Hide()
	end
	button.weapon = offset
	button.duration = HOUR
	button.timeLeft = expiration
	button:SetScript("OnUpdate", createTimer)

end

local function updateAttribute(self, attribute, value)
	--local consolidate = self:GetName():match("Consolidate")
	if attribute == "index" then
		--if consolidate and module.db.profile.consolidate then
		--	self.consolidate = true
		--end
		return updateAura(self, value)
	elseif attribute == "target-slot" then
		-- self.Bar:SetMinMaxValues(0, 3600)
		return updateEnchant(self, value)
	end
end

local function setAuraBorderColor(self, r, g, b, a)
	r, g, b = saturate(r, g, b)
	self:RawSetBackdropBorderColor(r, g, b, a)
end

local function styleAuraButton(button)
	button.icon:SetSize(T.buffs.icons.size, T.buffs.icons.size)
	button.icon:ClearAllPoints()
	button.icon:SetPoint(unpack(T.buffs.icons.place))
	button.icon:SetTexCoord(unpack(T.buffs.icons.texCoord))
	
	--if button.consolidateIcon then
	--	button.consolidateIcon:SetSize(T.buffs.icons.size, T.buffs.icons.size)
	--	button.consolidateIcon:ClearAllPoints()
	--	button.consolidateIcon:SetPoint(unpack(T.buffs.icons.place))
	--	button.consolidateIcon:SetTexCoord(unpack(T.buffs.icons.texCoord))
	--	if button.numConsolidatedBuffs and button.numConsolidatedBuffs > 0 then
	--		button.count:SetFormattedText("%d/%d", button.numConsolidatedBuffs, button.numTotalBuffs)
	--	end
	--end
	
	button.count:SetFontObject(T.buffs.fonts.count.fontObject)
	button.count:SetFontStyle(T.buffs.fonts.count.fontStyle)
	button.count:SetFontSize(T.buffs.fonts.count.fontSize)
	button.count:SetShadowOffset(unpack(T.buffs.fonts.count.shadowOffset))
	button.count:SetShadowColor(unpack(T.buffs.fonts.count.shadowColor))
	button.count:ClearAllPoints()
	button.count:SetPoint(unpack(T.buffs.fonts.count.place))
	
	button.remaining:SetFontObject(T.buffs.fonts.time.fontObject)
	button.remaining:SetFontStyle(T.buffs.fonts.time.fontStyle)
	button.remaining:SetFontSize(T.buffs.fonts.time.fontSize)
	button.remaining:SetShadowOffset(unpack(T.buffs.fonts.time.shadowOffset))
	button.remaining:SetShadowColor(unpack(T.buffs.fonts.time.shadowColor))
	button.remaining:ClearAllPoints()
	button.remaining:SetPoint(unpack(T.buffs.fonts.time.place))
end

local buttons = {}
function module:Scaffolding(button, isProxyButton)
	isProxyButton = false -- just to kill it off while testing
	button.isConsolidation = not not button:GetName():match("Consolidation")

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
		if self.isConsolidation then
			if self:GetParent():IsShown() then
				button.scaffold:SetAlpha(0)
				button.scaffold:Show()
				button.scaffold:StartFadeIn(.25, 1)
			else
				self.scaffold:Hide() 
			end
		else
			self.scaffold:Show() 
		end
	end)
	hooksecurefunc(button.icon, "SetTexture", function() 
		if button.isConsolidation then
			if button:GetParent():IsShown() then
				button.scaffold:Show() 
			else
				button.scaffold:Hide() 
			end
		else
			if button:IsShown() and not button.scaffold:IsShown() then
				button.scaffold:SetAlpha(0)
				button.scaffold:Show()
				button.scaffold:StartFadeIn(.25, 1)
			end
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
	if button.isConsolidation then
		if button:GetParent():IsShown() then
			button.scaffold:SetAlpha(0)
			button.scaffold:Show()
			button.scaffold:StartFadeIn(.25, 1)
		else
			button.scaffold:Hide()
		end
	else
		button.scaffold:SetAlpha(0)
		button.scaffold:Show()
		button.scaffold:StartFadeIn(.25, 1)
	end
	
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
	
	if isProxyButton then 
		local path = "Interface\\ICONS\\"
		local proxyIcons = {
			Dwarf = {
				Male = "Achievement_Character_Dwarf_Male",
				Female = "Achievement_Character_Dwarf_Female"
			},
			Draenei = {
				Male = "Achievement_Character_Draenei_Male",
				Female = "Achievement_Character_Draenei_Female"
			},
			Gnome = {
				Male = "Achievement_Character_Gnome_Male",
				Female = "Achievement_Character_Gnome_Female"
			},
			Human = {
				Male = "Achievement_Character_Human_Male",
				Female = "Achievement_Character_Human_Female"
			},
			NightElf = {
				Male = "Achievement_Character_Nightelf_Male",
				Female = "Achievement_Character_Nightelf_Female"
			},
			Worgen = {
				Male = "achievement_worganhead",
				Female = "achievement_worganhead"
			},
			BloodElf = {
				Male = "Achievement_Character_Bloodelf_Male",
				Female = "Achievement_Character_Bloodelf_Female"
			},
			Goblin = {
				Male = "achievement_Goblinhead",
				Female = "achievement_FemaleGoblinhead"
			},
			Orc = {
				Male = "Achievement_Character_Orc_Male",
				Female = "Achievement_Character_Orc_Female"
			},
			Tauren = {
				Male = "Achievement_Character_Tauren_Male",
				Female = "Achievement_Character_Tauren_Female"
			},
			Troll = {
				Male = "Achievement_Character_Troll_Male",
				Female = "Achievement_Character_Troll_Female"
			},
			Scourge = {
				Male = "Achievement_Character_Undead_Male",
				Female = "Achievement_Character_Undead_Female"
			},
			Pandaren = {
				Male = "Achievement_Guild_ClassyPanda",
				Female = "Achievement_Character_Pandaren_Female"
			}
		}
		local consolidateIcon = button.scaffold:CreateTexture(nil, "OVERLAY")
		consolidateIcon:SetAllPoints(button.icon)
		consolidateIcon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		consolidateIcon:SetTexture(path..proxyIcons[(select(2, UnitRace("player")))][UnitSex("player") == 3 and "Female" or "Male"]) 
		-- SetPortraitTexture(consolidateIcon, "player") -- doesn't work well with shapeshifts
		button.consolidateIcon = consolidateIcon
	else	
		button:SetScript("OnAttributeChanged", updateAttribute)
		button.filter = button:GetParent():GetAttribute("filter")
	end

	-- button.cd.noOCC = true
	-- button.cd.noCooldownCount = true 
	styleAuraButton(button)
	parent:GetFadeManager():RegisterHoverObject(button)
	buttons[button] = button
		
	return button
end

-- turns out spell- and itemnames are localized in macros. Thank you René Künzel for making me aware! :)
-- sometimes the item info isn't fully available at startup for some users, so we attempt to update these later on instead
local fishing_condition
local function updateFishingVariables()
	if not fishing_condition then
		fishing_condition = select(7, GetItemInfo(6256)) 
	end
	if fishing_condition then
		return true
	end
end

 -- force an early query to cache the items in the client so they're available on the second request later on
updateFishingVariables()

function module:UpdateFishingButton()
  if not updateFishingVariables() then return end
  wipe(self.frame.FishMonger.driver)
	tinsert(self.frame.FishMonger.driver, ("[equipped:%s]show"):format(fishing_condition))
	tinsert(self.frame.FishMonger.driver, "hide")
  if self.frame.FishMonger.hasDriver then
    UnregisterStateDriver(self.frame.FishMonger, "visibility")
  end
  RegisterStateDriver(self.frame.FishMonger, "visibility", tconcat(self.frame.FishMonger.driver, ";"))
  self.frame.FishMonger.hasDriver = true
end
module.UpdateFishingButton = gUI4:SafeCallWrapper(module.UpdateFishingButton)

function module:UpdateForcedDisplay(force)
  parent:GetFadeManager():SetUserForced(force)
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

function module:UpdateTheme(_, _, addonName)
	if addonName ~= tostring(parent) then return end
	updateConfig()
	
	-- buff container
	self.frame:SetSize(unpack(T.buffs.size))
	self.frame:SetAttribute("minHeight", T.buffs.attributes.minHeight)
	self.frame:SetAttribute("minWidth", T.buffs.attributes.minWidth)
	self.frame:SetAttribute("xOffset", T.buffs.attributes.xOffset)
	self.frame:SetAttribute("wrapAfter", T.buffs.attributes.wrapAfter)
	self.frame:SetAttribute("wrapYOffset", T.buffs.attributes.wrapYOffset)

	-- consolidation container
	--self.consolidation:SetSize(unpack(T.consolidation.size))
	--self.consolidation:SetAttribute("minWidth", T.consolidation.attributes.minWidth)
	--self.consolidation:SetAttribute("wrapAfter", T.consolidation.attributes.wrapAfter)
	--self.consolidation:SetAttribute("wrapYOffset", T.consolidation.attributes.wrapYOffset)
	
	for button in pairs(buttons) do
		styleAuraButton(button)
	end

	self:ApplySettings()
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings()
	if not self.frame then return end
	updateConfig() 
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not self.frame then return end
	updateConfig()
	if self.db.profile.locked then
		LMP:Place(self.frame, T.buffs.place)
		if not self.db.profile.position.x then
			self.frame:RegisterConfig(self.db.profile.position)
			self.frame:SavePosition()
		end
	else
		self.frame:RegisterConfig(self.db.profile.position)
		if self.db.profile.position.x then
			self.frame:LoadPosition()
		else
			LMP:Place(self.frame, T.buffs.place)
			self.frame:SavePosition()
			self.frame:LoadPosition()
		end
	end
	--LMP:Place(self.consolidation, T.consolidation.place)
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:UNIT_AURA(_, unit, ...)
  if not fishing_condition then self:UpdateFishingButton() end
	if not (unit == "player" or unit == "vehicle") then return end 
	-- local filter = self.frame:GetAttribute("filter")
	-- local numConsolidatedBuffs, numTotalBuffs = 0, 0
	-- for id = 1, 40 do
		-- local name, _, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unit, id, filter)
		-- if name then
			-- updateAura(button, button:GetID())
			-- numTotalBuffs = numTotalBuffs + 1
			-- if shouldConsolidate then 
				-- numConsolidatedBuffs = numConsolidatedBuffs + 1
			-- end
		-- else
			-- break
		-- end
	-- end
	-- self.proxy.numConsolidatedBuffs = numConsolidatedBuffs
	-- self.proxy.numTotalBuffs = numTotalBuffs
	-- if self.proxy.count then
		-- if numConsolidatedBuffs > 0 then
			-- self.proxy.count:SetFormattedText("%d/%d", numConsolidatedBuffs, numTotalBuffs)
		-- else
			-- self.proxy.count:SetText("")
		-- end
	-- end
	--for _, header in ipairs(self.frame, self.consolidation) do
	local header = self.frame
		local button = header:GetAttribute("child1")
		local i = 1
		while button do
			updateAura(button, button:GetID())
			i = i + 1
			button = header:GetAttribute("child"..i)
		end
	--end
end

function module:PLAYER_ENTERING_WORLD()
	self:UNIT_AURA("UNIT_AURA", "player")
  self:UpdateFishingButton() 
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Buffs", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	updateConfig()
	
	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4PlayerBuffs", parent:GetFadeManager(), "SecureAuraHeaderTemplate")) :SetClampedToScreen(true) :SetMovable(true) :SetSize(36, 36) :SetAttribute("template", "GUI4BuffButtonTemplate") :SetAttribute("weaponTemplate", "GUI4BuffButtonTemplate") 
		:Hide()
		:SetAttribute("filter", "HELPFUL") 
--		:SetAttribute("consolidateTo", self.db.profile.consolidate and 1) 
		:SetAttribute("includeWeapons", 1) 
--		:SetAttribute("consolidateDuration", -1) 
		-- :SetAttribute("consolidateThreshold", 10) 
		-- :SetAttribute("consolidateFraction", .10) 
		-- :SetAttribute("separateOwn", 1)
		-- :SetAttribute("groupBy", "NOT_CANCELABLE,CANCELABLE") 
		:SetAttribute("sortDirection", "+") 
	.__EndChain
	self.frame.overlay = gUI4:GlockThis(self.frame, L["Player Buffs"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "buffs")))
	self.frame.UpdatePosition = function(self) module:UpdatePosition() end

--	self.proxy = LMP:NewChain(CreateFrame("Frame", "$parentProxyButton", self.frame, "GUI4ConsolidationButtonTemplate")) :Hide() :SetSize(36, 36) .__EndChain 
--	self.consolidation = LMP:NewChain(CreateFrame("Frame", "GUI4PlayerBuffsConsolidation", self.proxy, "SecureFrameTemplate")) :Hide() :SetSize(36, 36) :ClearAllPoints() :SetPoint("CENTER", self.proxy, "CENTER", 0, -40) :SetAttribute("template", "GUI4BuffButtonTemplate") :SetAttribute("weaponTemplate", "GUI4BuffButtonTemplate") :SetAttribute("point", "RIGHT") :SetAttribute("minHeight", nil) :SetAttribute("minWidth", nil) .__EndChain
--	self.dropdown = LMP:NewChain(CreateFrame("Button", "$parentDropDown", self.proxy, "SecureHandlerClickTemplate"))
--		:SetAllPoints()
--		:RegisterForClicks("AnyUp")
--		:SetAttribute("_onclick", [[
--			local consolidation = self:GetFrameRef("consolidation")
--			local numChild = 0
--			local child
--			repeat
--				numChild = numChild + 1
--				child = consolidation:GetFrameRef("child" .. numChild)
--			until not(child and child:IsShown())
--			numChild = numChild - 1
--
--			local x, y = self:GetWidth(), self:GetHeight()
--			consolidation:SetWidth(x)
--			consolidation:SetHeight(y)
--			
--			if consolidation:IsShown() then
--				consolidation:Hide()
--			else
--				consolidation:Show()
--			end
--		]])
--	.__EndChain

--	SecureHandlerSetFrameRef(self.dropdown, "consolidation", self.consolidation)

--	self.dropdown:HookScript("OnEnter", function(self) 
--		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", -6, -6)
--		GameTooltip:AddLine(L["Consolidated Auras"], unpack(gUI4:GetColors("chat", "normal")))
--		GameTooltip:AddLine(L["Click to toggle display of consolidated auras."], unpack(gUI4:GetColors("chat", "highlight")))
--		GameTooltip:Show()
--	end)
--	self.dropdown:HookScript("OnLeave", GameTooltip_Hide)
	
	RegisterAttributeDriver(self.frame, "unit", "[vehicleui] vehicle; player")
--	RegisterAttributeDriver(self.consolidation, "unit", "[vehicleui] vehicle; player")

--	self.frame:SetAttribute("consolidateProxy", self.proxy) 
--	self.frame:SetAttribute("consolidateHeader", self.consolidation)
	
	-- because we're crazy
  self.frame.FishMonger = LMP:NewChain(CreateFrame("Frame", "GUI4PlayerBuffsFishMonger", self.frame, "SecureHandlerStateTemplate")) :Hide() .__EndChain
	self.frame.FishMonger.driver = {}
  self.frame.FishMonger:HookScript("OnShow", function() self:UpdateForcedDisplay(true) end)
  self.frame.FishMonger:HookScript("OnHide", function() self:UpdateForcedDisplay() end)
	if updateFishingVariables() then
		self:UpdateFishingButton()
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- self:RegisterEvent("UNIT_AURA")
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
