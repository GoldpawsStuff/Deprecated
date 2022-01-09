local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("XPBar", "GP_AceEvent-3.0", "GP_AceConsole-3.0")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local path = [[Interface\AddOns\]]..addon..[[\media\]]
local C = gUI4:GetColors()

local Scaffold = parent.Scaffold
local XPBar = setmetatable({}, { __index = Scaffold })
parent.XPBar = XPBar

-- Lua API
local floor, min = math.floor, math.min
local tonumber, tostring = tonumber, tostring
local unpack = unpack

-- WoW API
local GetAccountExpansionLevel = GetAccountExpansionLevel
local GetArtifactArtInfo = C_ArtifactUI.GetArtifactArtInfo
local GetEquippedArtifactInfo = C_ArtifactUI.GetEquippedArtifactInfo
local GetEquippedArtifactXP = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP
local GetScreenWidth = GetScreenWidth
local GetTimeToWellRested = GetTimeToWellRested
local GetXPExhaustion = GetXPExhaustion
local HasArtifactEquipped = HasArtifactEquipped
local IsXPUserDisabled = IsXPUserDisabled
local UnitAffectingCombat = UnitAffectingCombat
local UnitLevel = UnitLevel
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax

local GameTooltip = GameTooltip
local MAX_PLAYER_LEVEL_TABLE = MAX_PLAYER_LEVEL_TABLE

-- pandaren can get 300% rested bonus
local maxRested = select(2, UnitRace("player")) == "Pandaren" and 3 or 1.5
local T, hasTheme, skinSize

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		showMaxLevel = false, 
		alpha = 1,
		visibility = {},
		position = {}
	}
}

---------------------------------------------------------------------------------------------------------------------
-- Local Functions
---------------------------------------------------------------------------------------------------------------------
local shortRepString = "%s%%"
local standingString = "%s - %s"
local longRepString = "%s / %s"
local fullRepString = "%s / %s - %s%%"

local function colorize(str, colorName)
	return C.chat[colorName].colorCode .. str .. "|r"
end

-- turn a large value into a more readable one
local function short(value)
	value = tonumber(value)
	if not value then return "" end
	if value >= 1e6 then
		return ("%.1f"):format(value / 1e6):gsub("%.?0+([km])$", "%1") .. colorize("m", "offwhite")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1f"):format(value / 1e3):gsub("%.?0+([km])$", "%1") .. colorize("k", "offwhite")
	else
		return tostring(value)
	end	
end

local function hex(r, g, b)
	if type(r) == "table" then
		if r.r then 
			r, g, b = r.r, r.g, r.b 
		else 
			r, g, b = unpack(r) 
		end
	end
	return ("|cff%02x%02x%02x"):format(r*255, g*255, b*255)
end

local function clean(str)
	str = str:gsub("|r", "")
	while str:find("|c") do
		local where = str:find("|c")
		local new = ""
		if where >= 1 then
			new = new .. str:sub(1, where-1)
		end
		if str:len() > where + 10 then
			new = new .. str:sub(where + 10)
		end
		str = new
	end
	return str
end

-- updates the local theme reference to the current theme
local function updateConfig()
	skinSize = parent.db:GetNamespace("ActionBars").profile.bars[1].skinSize
	T = parent:GetActiveTheme().xp[skinSize] -- figure out what backdrop to use based on main actionbar size
end

-- hides the bonus indicator spark when >= max
local function updateSpark(self)
	local value = self:GetValue()
	local min, max = self:GetMinMaxValues()
	if value == 0 or max == 0 or value == max then
		self.spark:Hide()
	else
		self.spark:Show()
	end
end

local shortXPString = "%s%%"
local longXPString = "%s / %s"
local fullXPString = "%s / %s - %s%%"
local restedString = " (%s%% %s)"
local shortLevelString = "%s %d"

local function getZeroDifferenceValue(playerLevel)
	if playerLevel <= 7 then
		return 5
	elseif playerLevel <= 9 then
		return 6
	elseif playerLevel <= 11 then
		return 7
	elseif playerLevel <= 15 then
		return 8
	elseif playerLevel <= 19 then
		return 9
	elseif playerLevel <= 29 then
		return 11
	elseif playerLevel <= 39 then
		return 12
	elseif playerLevel <= 44 then
		return 13
	elseif playerLevel <= 49 then
		return 14
	elseif playerLevel <= 54 then
		return 15
	elseif playerLevel <= 59 then
		return 16
	elseif playerLevel <= 84 then
		return 17
	else
		return 0
	end
end

local function getGrayLevel(playerLevel)
	if playerLevel <= 5 then
		return 0
	elseif playerLevel <= 39 then
		return floor(playerLevel/10) - 5
	elseif playerLevel <= 59 then
		return floor(playerLevel/5) - 1
	elseif playerLevel <= 70 then
		return playerLevel - 9
	else
		return playerLevel - 9
	end
end

-- Map Continent IDs:
-- #1: Kalimdor
-- #2: Eastern Kingdoms
-- #3: Outland (The Burning Crusade)
-- #4: Northrend (Wrath of the Lich King)
-- #5: The Maelstrom (Cataclysm)
-- #6: Pandaria (Mists of Pandaria)
local zoneOverrides = {
	["Mount Hyjal"] = 5,
	["Uldum"] = 5,
	["Vashj'ir"] =  5,
	["Twilight Highlands"] = 5,
	["Kezan"] = 1,
	["The Lost Isles"] = 1,
	["Ruins of Gilneas"] = 1
}
local continents
local continentZones
local function getZoneID()
	local currentZone = GetRealZoneText()
	if not continents then
		continents = { GetMapContinents() }
	end
	for continentID, continentName in ipairs(continents) do
		if not continentZones then
			continentZones = {}
		end
		if not continentZones[continentID] then
			continentZones[continentID] = { GetMapZones(continentID) }
		end
		for id,zone in ipairs(continentZones[continentID]) do
			if zone == currentZone then
				return continentID
			end
		end	
	end
	return 1
end

local function getBaseKillXP(playerLevel, expansionID)
	if expansionID == 1 or expansionID == 2 then
		return (playerLevel * 5) + 45 -- Azeroth
	elseif expansionID == 3 then
		return (playerLevel * 5) + 235 -- Outland
	elseif expansionID == 4 then
		return (playerLevel * 5) + 580 -- WotLK
	elseif expansionID == 5 then
		return (playerLevel * 5) + 1878 -- Cata
	elseif expansionID == 6 then
		return (playerLevel * 5) + 20785 -- MoP (based on a 22292 xp from a level 90 kill at level 89. could be very wrong, need more calculations!)
	else 
		return (playerLevel * 5) + 20785 -- WoD (todo: figure out a good value for WoD, must check the first days of the expansion)
	end
end

local function getFullKillXp(playerLevel, mobLevel, expansionID)
	local grayLevel = getGrayLevel(playerLevel)
	if grayLevel >= mobLevel then
		return 0 -- gray mobs produce zero experience
	end
	local baseXP = getBaseKillXP(playerLevel, expansionID)
	if playerLevel > mobLevel then
		local zeroDifference = getZeroDifferenceValue(playerLevel)
		return baseXP * (1 - (playerLevel - mobLevel)/zeroDifference )
	elseif mobLevel > playerLevel then
		if mobLevel > playerLevel + 4 then
			mobLevel = playerLevel + 4 -- this is the cap, so let's cap
		end
		return baseXP * (1 + 0.05 * (mobLevel - playerLevel))
	else
		return baseXP
	end
end

local function calculateKillXP()
	local playerLevel = UnitLevel("player")
	local xp = getFullKillXp(playerLevel, playerLevel, getZoneID())
	return xp
end

local function calculateQuestXP()
	local playerLevel = UnitLevel("player")
	
	-- playerLevel <= Quest_Level +  5 : Quest_XP = (100 %) or Full_Quest_XP
	-- playerLevel  = Quest_Level +  6 : Quest_XP = ( 80 %) or ROUND(Full_Quest_XP * 0.8 / 5) * 5
	-- playerLevel  = Quest_Level +  7 : Quest_XP = ( 60 %) or ROUND(Full_Quest_XP * 0.6 / 5) * 5
	-- playerLevel  = Quest_Level +  8 : Quest_XP = ( 40 %) or ROUND(Full_Quest_XP * 0.4 / 5) * 5
	-- playerLevel  = Quest_Level +  9 : Quest_XP = ( 20 %) or ROUND(Full_Quest_XP * 0.2 / 5) * 5
	-- playerLevel >= Quest_Level + 10 : Quest_XP = ( 10 %) or ROUND(Full_Quest_XP * 0.1 / 5) * 5
end

function XPBar:UpdateTheme()
	updateConfig()
	self:SetSize(unpack(T.size))
	LMP:NewChain(self.bar) :SetSize(unpack(T.statusbar.size)) :SetHitRectInsets(unpack(T.statusbar.hitrectinsets)) :ClearAllPoints() :SetPoint(unpack(T.statusbar.place)) :SetStatusBarTexture(T.statusbar.texture:GetPath()) :SetStatusBarColor(unpack(T.statusbar.color.xp)) :EndChain()
	LMP:NewChain(self.bar.spark) :SetSize(unpack(T.statusbar.spark.size)) :ClearAllPoints() :SetPoint(T.statusbar.spark.texture:GetPoint(), self.bar:GetStatusBarTexture(), T.statusbar.spark.texture:GetPoint()) :SetTexture(T.statusbar.spark.texture:GetPath()) :EndChain()
	LMP:NewChain(self.rested) :SetSize(unpack(T.statusbar.size)) :ClearAllPoints() :SetPoint(unpack(T.statusbar.place)) :SetStatusBarTexture(T.statusbar.texture:GetPath()) :SetStatusBarColor(unpack(T.statusbar.color.restedbonus)) :EndChain()
	LMP:NewChain(self.rested.spark) :SetSize(unpack(T.statusbar.spark.size)) :ClearAllPoints() :SetPoint(T.statusbar.spark.texture:GetPoint(), self.rested:GetStatusBarTexture(), T.statusbar.spark.texture:GetPoint()) :SetTexture(T.statusbar.spark.texture:GetPath()) :EndChain()
	-- LMP:NewChain(self.glow) :SetVertexColor(unpack(T.textures.glow:GetColor())) :SetTexture(T.textures.glow:GetPath()) :SetSize(T.textures.glow:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.glow:GetPoint()) :EndChain()
	LMP:NewChain(self.backdrop) :SetTexture(T.statusbar.texture:GetPath()) :SetVertexColor(.15, .15, .15, 1) :EndChain()
	-- LMP:NewChain(self.notches) :SetVertexColor(unpack(T.textures.notches:GetColor())) :SetTexture(T.textures.notches:GetPath()) :SetSize(T.textures.notches:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.notches:GetPoint()) :EndChain()
	-- LMP:NewChain(self.normal) :SetVertexColor(unpack(T.textures.normal:GetColor())) :SetTexture(T.textures.normal:GetPath()) :SetSize(T.textures.normal:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.normal:GetPoint()) :EndChain()
	-- LMP:NewChain(self.highlight) :SetVertexColor(unpack(T.textures.highlight:GetColor())) :SetTexture(T.textures.highlight:GetPath()) :SetSize(T.textures.highlight:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.highlight:GetPoint()) :EndChain()
	-- LMP:NewChain(self.overlay) :SetVertexColor(unpack(T.textures.overlay:GetColor())) :SetTexture(T.textures.overlay:GetPath()) :SetSize(T.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.overlay:GetPoint()) :EndChain()
end

function XPBar:UpdateData()
	self.data.resting = IsResting()
	self.data.restState, self.data.restedName, self.data.mult = GetRestState()
	self.data.restedLeft, self.data.restedTimeLeft = GetXPExhaustion(), GetTimeToWellRested()
	self.data.xp, self.data.xpMax = UnitXP("player"), UnitXPMax("player")
	self.data.color = self.data.restedLeft and "restedxp" or "xp"
	self.data.mult = (self.data.mult or 1) * 100
	if self.data.xpMax == 0 then
		self.data.xpMax = nil
	end
	if self.data.xpMax then
		local fullKillXP = calculateKillXP()
		local xpNeeded = self.data.xpMax - self.data.xp
		local killsToLevel
		if self.data.restedLeft then -- rested
			if self.data.restedLeft >= xpNeeded then -- fully rested
				killsToLevel = ceil(xpNeeded/(fullKillXP*2))
			else -- partly rested
				local xpUnrested = xpNeeded - self.data.restedLeft
				killsToLevel = ceil(self.data.restedLeft/(fullKillXP*2)) + ceil(xpNeeded/fullKillXP)
			end
		else -- fully unrested
			killsToLevel = ceil(xpNeeded/fullKillXP)
		end
		self.data.killsToLevel = killsToLevel
		self.data.questsToLevel = nil
	else
		self.data.killsToLevel = nil
		self.data.questsToLevel = nil
	end
	return self.data
end

function XPBar:UpdateBar()
	local data = self:UpdateData()
	if not data.xpMax then return end
	local r, g, b = unpack(T.statusbar.color[data.color])
	self.bar:SetStatusBarColor(r, g, b)
	self.bar:SetMinMaxValues(0, data.xpMax)
	self.bar:SetValue(data.xp)
	self.rested:SetMinMaxValues(0, data.xpMax)
	self.rested:SetValue(min(data.xpMax, data.xp + (data.restedLeft or 0)))
	if data.restedLeft then
		local r, g, b = unpack(T.statusbar.color.restedbonus)
		self.backdrop:SetVertexColor(r *.25, g *.25, b *.25, 1)
	else
		self.backdrop:SetVertexColor(r *.25, g *.25, b *.25, 1)
	end
	if self.mouseIsOver then
		if data.restedLeft then
			self.text:SetFormattedText(fullXPString..colorize(restedString, "offgreen"), colorize(short(data.xp), "normal"), colorize(short(data.xpMax), "normal"), colorize(short(floor(data.xp/data.xpMax*100)), "normal"), short(floor(data.restedLeft/data.xpMax*100)), L["Rested"])
		else
			self.text:SetFormattedText(fullXPString, colorize(short(data.xp), "normal"), colorize(short(data.xpMax), "normal"), colorize(short(floor(data.xp/data.xpMax*100)), "normal"))
		end
	else
		self.text:SetFormattedText(shortXPString, colorize(short(floor(data.xp/data.xpMax*100)), "normal"))
	end
end

local enabled
function XPBar:UpdateVisibility()
	local maxLevel = MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE] or MAX_PLAYER_LEVEL_TABLE[#MAX_PLAYER_LEVEL_TABLE]
	local isMaxLevel = IsXPUserDisabled() or UnitLevel("player") == maxLevel
	if isMaxLevel then
		module.db.profile.enabled = module.db.profile.showMaxLevel
	else
		module.db.profile.enabled = true
	end
	if enabled ~= module.db.profile.enabled then
		if module.db.profile.enabled then
			if module.db.profile.locked then
				T.setOffset(self, "XP", skinSize)
			end
			module:SendMessage("GUI4_XPBAR_ENABLED")
		else
			T.setOffset(self, "XP", nil)
			module:SendMessage("GUI4_XPBAR_DISABLED")
		end
		enabled = module.db.profile.enabled
	end
end
XPBar.UpdateVisibility = gUI4:SafeCallWrapper(XPBar.UpdateVisibility) -- we level up in combat, so we need to queue these visibility events

function XPBar:UpdatePosition()
	if not hasTheme then return end
	if module.db.profile.enabled and module.db.profile.locked then
		T.setOffset(self, "XP", skinSize)
		self:ClearAllPoints()
		self:SetPoint(T.place("XP", skinSize))
		if not module.db.profile.position.x then
			self:RegisterConfig(module.db.profile.position)
			self:SavePosition()
		end
	else
		T.setOffset(self, "XP", nil)
		self:RegisterConfig(module.db.profile.position)
		if module.db.profile.position.x then
			self:LoadPosition()
		else
			self:ClearAllPoints()
			self:SetPoint(T.place("XP", skinSize))
			self:SavePosition()
			self:LoadPosition()
		end
	end
end
XPBar.UpdatePosition = gUI4:SafeCallWrapper(XPBar.UpdatePosition) 

function XPBar:ApplySettings(event, arg)
	self:UpdateVisibility()
	self:UpdatePosition()
	Scaffold.ApplySettings(self)
end
XPBar.ApplySettings = gUI4:SafeCallWrapper(XPBar.ApplySettings)

function XPBar:OnEvent(event, arg1)
	self:UpdateBar()
	if event == "PLAYER_LEVEL_UP"
	or event == "ENABLE_XP_GAIN"
	or event == "DISABLE_XP_GAIN"
	or event == "PLAYER_ALIVE"
	-- or event == "PLAYER_LOGIN" 
	or event == "PLAYER_ENTERING_WORLD" then
		self:ApplySettings()
	end
end

local day, hour, minute = 86400, 3600, 60
function XPBar:OnEnter()
	local data = self.frame:UpdateData()
	if not data.xpMax then return end

	if (not GameTooltip:IsForbidden()) then
		-- if GetCVar("UberTooltips") == "1" then
			-- GameTooltip_SetDefaultAnchor(GameTooltip, self)
		-- else
			LMP:PlaceTip(self.frame, "BOTTOMLEFT")
		-- end	

		local r, g, b = unpack(C.chat.highlight)
		local r2, g2, b2 = unpack(C.chat.offwhite)
		GameTooltip:AddLine(shortLevelString:format(LEVEL, UnitLevel("player")))
		GameTooltip:AddLine(" ")

		-- use XP as the title
		GameTooltip:AddDoubleLine(L["Current XP: "], longXPString:format(colorize(short(data.xp), "normal"), colorize(short(data.xpMax), "normal")), r2, g2, b2, r2, g2, b2)
		
		-- add rested bonus if it exists
		if data.restedLeft and data.restedLeft > 0 then
			GameTooltip:AddDoubleLine(L["Rested Bonus: "], longXPString:format(colorize(short(data.restedLeft), "normal"), colorize(short(data.xpMax * maxRested), "normal")), r2, g2, b2, r2, g2, b2)
		end
		
		if data.restState == 1 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["Rested"], unpack(C.chat.highlight))
			GameTooltip:AddLine(L["%s of normal experience\ngained from monsters."]:format(shortXPString:format(data.mult)), unpack(C.chat.green))
			if data.resting and data.restedTimeLeft and data.restedTimeLeft > 0 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(L["Resting"], unpack(C.chat.highlight))
				if data.restedTimeLeft > hour*2 then
					GameTooltip:AddLine(L["You must rest for %s additional\nhours to become fully rested."]:format(colorize(floor(data.restedTimeLeft/hour), "offwhite")), unpack(C.chat.normal))
				else
					GameTooltip:AddLine(L["You must rest for %s additional\nminutes to become fully rested."]:format(colorize(floor(data.restedTimeLeft/minute), "offwhite")), unpack(C.chat.normal))
				end
			end
		elseif data.restState >= 2 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["Normal"], unpack(C.chat.highlight))
			GameTooltip:AddLine(L["%s of normal experience\ngained from monsters."]:format(shortXPString:format(data.mult)), unpack(C.chat.green))

			if not(data.restedTimeLeft and data.restedTimeLeft > 0) then 
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(L["You should rest at an Inn."], unpack(C.chat.dimred))
			end
		end
		
		if data.killsToLevel or data.questsToLevel then
			local r, g, b = unpack(C.chat.normal)
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["Time to level"], unpack(C.chat.highlight))
			if data.killsToLevel then
				GameTooltip:AddDoubleLine(L["Kills: "], data.killsToLevel, r, g, b, r2, g2, b2)
			end
			if data.questsToLevel then
				GameTooltip:AddDoubleLine(L["Quests: "], data.questsToLevel, r, g, b, r2, g2, b2)
			end
		end

		local equipped = HasArtifactEquipped()
		if equipped then 
			-- 7.2.0 update: artifactTier added
			local itemID, altItemID, name, icon, totalXP, usedPoints, quality, _, _, _, _, _, artifactTier = GetEquippedArtifactInfo()
			local unusedPoints, value, max = GetEquippedArtifactXP(usedPoints, totalXP, artifactTier)
			local textureKit, titleName, titleR, titleG, titleB, barConnectedR, barConnectedG, barConnectedB, barDisconnectedR, barDisconnectedG, barDisconnectedB = GetArtifactArtInfo()

			local r, g, b = unpack(C.chat.highlight)
			local nameR, nameG, nameB = unpack(C.quality[quality-1])
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(name, usedPoints, nameR, nameG, nameB, r, g, b)

			local r, g, b = unpack(C.chat.offwhite)
			GameTooltip:AddDoubleLine(L["Current Artifact Power: "], longRepString:format(colorize(short(value), "normal"), colorize(short(max), "normal")), r, g, b, r, g, b)

			local knowledgeLevel = C_ArtifactUI.GetArtifactKnowledgeLevel()
			if knowledgeLevel and knowledgeLevel > 0 then
				local knowledgeMultiplier = C_ArtifactUI.GetArtifactKnowledgeMultiplier()

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(ARTIFACTS_KNOWLEDGE_TOOLTIP_LEVEL:format(knowledgeLevel), HIGHLIGHT_FONT_COLOR:GetRGB())
				GameTooltip:AddLine(ARTIFACTS_KNOWLEDGE_TOOLTIP_DESC:format(BreakUpLargeNumbers(knowledgeMultiplier * 100)), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
			end

			if unusedPoints > 0 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(ARTIFACT_POWER_TOOLTIP_BODY:format(unusedPoints), nil, nil, nil, true)
			end

		end
		
		GameTooltip:Show()
	end
	self.frame.mouseIsOver = true
	self.frame:UpdateBar()
end

function XPBar:OnLeave()
	-- self.frame.highlight:Hide()
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
	self.frame.mouseIsOver = false
	self.frame:UpdateBar()
end

local positionCallbacks = {}
function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	updateConfig()
	for callback in pairs(positionCallbacks) do
		self:UnregisterMessage(callback, "UpdatePosition")
	end
	wipe(positionCallbacks)
	for id, callbacks in pairs(T.positionCallbacks) do
		for _, callback in ipairs(callbacks) do
			positionCallbacks[callback] = true
		end
	end
	for callback in pairs(positionCallbacks) do
		self:RegisterMessage(callback, "UpdatePosition")
	end
	if self.frame then
		self.frame:UpdateTheme()
	end
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings(event, ...)
	if not self.frame then return end
	self.frame:ApplySettings(event, ...)
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.frame then return end
	self.frame:UpdatePosition()
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:Lock()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
end

function module:IsXPBarVisible()
	local maxLevel = MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE] or MAX_PLAYER_LEVEL_TABLE[#MAX_PLAYER_LEVEL_TABLE]
	local isMaxLevel = IsXPUserDisabled() or UnitLevel("player") == maxLevel
	local showXP
	if isMaxLevel then
		showXP = module.db.profile.showMaxLevel
	else
		showXP = true
	end
	return showXP and self.frame:GetSettings().enabled
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("XPBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()

	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	
	self:RegisterChatCommand("enablexp", function()
		self.db.profile.enabled = true
		self:ApplySettings()
	end)
	self:RegisterChatCommand("disablexp", function()
		self.db.profile.enabled = false
		self:ApplySettings()
	end)
end

function module:OnEnable()
	self.frame = LMP:NewChain(setmetatable(Scaffold:New("XP", L["XP Bar"], function() return self.db.profile end), { __index = XPBar })) :SetFrameStrata("LOW") .__EndChain
	parent:GetFadeManager():RegisterObject(self.frame)
	self.frame.data = {} -- table to store info
	self.frame.border = LMP:NewChain(CreateFrame("Frame", "GUI4_XPBarBorder", self.frame)) :SetFrameStrata("MEDIUM") :SetAllPoints() :SetFrameLevel(self.frame:GetFrameLevel() + 3) .__EndChain
	self.frame.bar = LMP:NewChain("StatusBar", "GUI4_XPBarStatusBar", self.frame) :SetFrameLevel(self.frame:GetFrameLevel() + 2) :EnableMouse(true) :SetScript("OnEnter", XPBar.OnEnter) :SetScript("OnLeave", XPBar.OnLeave) .__EndChain
	self.frame.bar.spark = LMP:NewChain(self.frame.bar:CreateTexture(nil, "ARTWORK")) :SetBlendMode("ADD") .__EndChain
	self.frame.bar.frame = self.frame
	self.frame.rested = LMP:NewChain("StatusBar", "GUI4_XPBarRestedStatusBar", self.frame) :SetAlpha(.5) :SetFrameLevel(self.frame:GetFrameLevel() + 1) .__EndChain
	self.frame.rested.spark = LMP:NewChain(self.frame.bar:CreateTexture(nil, "ARTWORK")) :SetAlpha(.5) :SetBlendMode("ADD") .__EndChain
	self.frame.text = LMP:NewChain("FontString", nil, self.frame.border) :SetFontObject(TextStatusBarText) :SetFontSize(12) :SetFontStyle("THINOUTLINE") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY") :SetTextColor(unpack(C.chat.offwhite)) :SetPoint("CENTER", 0, 0) .__EndChain
	-- self.frame.glow = LMP:NewChain(self.frame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetVertexColor(0, 0, 0, 1) .__EndChain 
	self.frame.backdrop = LMP:NewChain(self.frame:CreateTexture()) :SetAllPoints(self.frame.bar) :SetDrawLayer("BACKGROUND", 0) .__EndChain 
	-- self.frame.notches = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain 
	-- self.frame.normal = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 2) .__EndChain 
	-- self.frame.overlay = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 3) :Hide() .__EndChain 
	-- self.frame.highlight = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 4) :SetBlendMode("BLEND") :Hide() .__EndChain 

	self.frame:SetScript("OnEvent", XPBar.OnEvent)
	self.frame:RegisterEvent("PLAYER_ALIVE")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.frame:RegisterEvent("PLAYER_LEVEL_UP")
	self.frame:RegisterEvent("PLAYER_XP_UPDATE")
	self.frame:RegisterEvent("PLAYER_LOGIN")
	self.frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
	self.frame:RegisterEvent("DISABLE_XP_GAIN")
	self.frame:RegisterEvent("ENABLE_XP_GAIN")
	self.frame:RegisterEvent("UPDATE_FACTION")
	self.frame:RegisterEvent("PLAYER_REGEN_ENABLED") 
	self.frame:RegisterEvent("PLAYER_UPDATE_RESTING")

	hooksecurefunc(self.frame.rested, "SetValue", updateSpark)
	hooksecurefunc(self.frame.rested, "SetMinMaxValues", updateSpark)
	
	gUI4:ApplySmoothing(self.frame.bar)
	gUI4:ApplySmoothing(self.frame.rested)

	self:ApplySettings()
end

function module:OnDisable()
end
