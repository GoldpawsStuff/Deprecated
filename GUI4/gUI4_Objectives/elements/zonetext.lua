local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local module = parent:NewModule("ZoneText", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T

-- Lua API
local pairs, unpack = pairs, unpack
local tostring = tostring

-- WoW API
local GetDifficultyInfo = GetDifficultyInfo
local GetInstanceInfo = GetInstanceInfo
local GetSubZoneText = GetSubZoneText
local GetTime = GetTime
local GetZonePVPInfo = GetZonePVPInfo
local GetZoneText = GetZoneText
local IsInInstance = IsInInstance
local UnitAffectingCombat = UnitAffectingCombat

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		position = {}
	}
}

local function updateConfig() 
	T = parent:GetActiveTheme().zonetext
end

local function Show(self)
	self.startTime = GetTime()
	self:Show()
end

local function OnUpdate(self)
	local elapsed = GetTime() - self.startTime
	local fadeInTime = self.fadeInTime
	if elapsed < fadeInTime then
		local alpha = elapsed / fadeInTime
		self:SetAlpha(alpha)
		return
	end
	local holdTime = self.holdTime
	if elapsed < (fadeInTime + holdTime) then
		self:SetAlpha(1.0)
		return
	end
	local fadeOutTime = self.fadeOutTime
	if elapsed < (fadeInTime + holdTime + fadeOutTime) then
		local alpha = 1.0 - ((elapsed - holdTime - fadeInTime) / fadeOutTime)
		self:SetAlpha(alpha)
		return
	end
	self:Hide()
end

function module:KillBlizzard()
	ZoneTextFrame:UnregisterAllEvents()
	ZoneTextFrame:SetScript("OnUpdate", nil)
	ZoneTextFrame:Hide()
	SubZoneTextFrame:UnregisterAllEvents()
	SubZoneTextFrame:SetScript("OnUpdate", nil)
	SubZoneTextFrame:Hide()
	AutoFollowStatus:UnregisterAllEvents()
	AutoFollowStatus:SetScript("OnUpdate", nil)
	AutoFollowStatus:Hide()
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

function module:UpdateSize()
	if not self.frame then return end
	updateConfig()
	self.frame:SetSize(unpack(T.size))
end
	
local positionCallbacks = {}
function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	if not self.frame then return end
	updateConfig()
	for callback in pairs(positionCallbacks) do
		self:UnregisterMessage(callback, "UpdatePosition")
	end
	wipe(positionCallbacks)
	for callback in pairs(T.positionCallbacks) do
		positionCallbacks[callback] = true
	end
	for callback in pairs(positionCallbacks) do
		self:RegisterMessage(callback, "UpdatePosition")
	end
	LMP:NewChain(self.frame) :SetAlpha(T.alpha) :EndChain()
	LMP:NewChain(self.frame.zonetext) :SetFontObject(T.zonetext.fontobject) :SetFontSize(T.zonetext.fontsize) :SetFontStyle(T.zonetext.fontstyle) :SetShadowOffset(unpack(T.zonetext.shadowoffset)) :SetShadowColor(unpack(T.zonetext.shadowcolor)) :SetTextColor(unpack(T.zonetext.color)) :EndChain()
	LMP:NewChain(self.frame.zonepvptext) :SetFontObject(T.zonepvptext.fontobject) :SetFontSize(T.zonepvptext.fontsize) :SetFontStyle(T.zonepvptext.fontstyle) :SetShadowOffset(unpack(T.zonepvptext.shadowoffset)) :SetShadowColor(unpack(T.zonepvptext.shadowcolor)) :SetTextColor(unpack(T.zonepvptext.color)) :EndChain()
	LMP:NewChain(self.frame.subzonetext) :SetFontObject(T.subzonetext.fontobject) :SetFontSize(T.subzonetext.fontsize) :SetFontStyle(T.subzonetext.fontstyle) :SetShadowOffset(unpack(T.subzonetext.shadowoffset)) :SetShadowColor(unpack(T.subzonetext.shadowcolor)) :SetTextColor(unpack(T.subzonetext.color)) :EndChain()
	LMP:NewChain(self.frame.subzonepvptext) :SetFontObject(T.subzonepvptext.fontobject) :SetFontSize(T.subzonepvptext.fontsize) :SetFontStyle(T.subzonepvptext.fontstyle) :SetShadowOffset(unpack(T.subzonepvptext.shadowoffset)) :SetShadowColor(unpack(T.subzonepvptext.shadowcolor)) :SetTextColor(unpack(T.subzonepvptext.color)) :EndChain()
	LMP:NewChain(self.frame.autofollowtext) :SetFontObject(T.autofollowtext.fontobject) :SetFontSize(T.autofollowtext.fontsize) :SetFontStyle(T.autofollowtext.fontstyle) :SetShadowOffset(unpack(T.autofollowtext.shadowoffset)) :SetShadowColor(unpack(T.autofollowtext.shadowcolor)) :SetTextColor(unpack(T.autofollowtext.color)) :EndChain()
	hasTheme = true
	self:ApplySettings()
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings(settings)
	if not self.frame then return end
	self:UpdateSize()
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition(event, offset, justify)
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

function module:UpdateZone(event, ...)
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	local zoneName = GetZoneText()
	local subzoneName = GetSubZoneText()
	local instance = IsInInstance()
	local zoneNameText = self.frame.zonetext
	local zonePvPText = (isSubZonePvP or pvpType == "combat") and self.frame.subzonepvptext or self.frame.zonepvptext
	local subZoneText = self.frame.subzonetext
	local subZonePvPText = (isSubZonePvP or pvpType == "combat") and self.frame.zonepvptext or self.frame.subzonepvptext
	
	local r, g, b, zonePvPName, showZoneText
	
	-- figure out what to write, and the colors
	if instance then
		local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()
		local _, groupType, isHeroic, isChallengeMode, toggleDifficultyID = GetDifficultyInfo(difficultyID)
		if maxPlayers == 5 and instanceType == "party" then
			if isHeroic then
				difficultyName = DUNGEON_DIFFICULTY2
			else
				difficultyName = DUNGEON_DIFFICULTY1
			end
		end
		r, g, b = unpack(gUI4:GetColors("chat", "normal"))
		zoneName = name
		zonePvPName = difficultyName
	else
		-- r, g, b = unpack(gUI4:GetColors("zone", pvpType or "contested"))
		r, g, b = unpack(gUI4:GetColors("zone", pvpType or "unknown"))
		if pvpType == "sanctuary" then
			zonePvPName = SANCTUARY_TERRITORY
		elseif pvpType == "arena" then
			zonePvPName = FREE_FOR_ALL_TERRITORY
		elseif pvpType == "friendly" then
			zonePvPName = FACTION_CONTROLLED_TERRITORY:format(factionName)
		elseif pvpType == "hostile" then
			zonePvPName = FACTION_CONTROLLED_TERRITORY:format(factionName)
		elseif pvpType == "combat" then
			zonePvPText = self.frame.subzonepvptext
			zonePvPName = COMBAT_ZONE
		elseif pvpType == "contested" then
			zonePvPName = CONTESTED_TERRITORY
		-- else
			-- zonePvPName = CONTESTED_TERRITORY
		end
	end
	
	-- colors!
	self.frame.zonetext:SetTextColor(r, g, b)
	self.frame.zonepvptext:SetTextColor(r, g, b)
	self.frame.subzonetext:SetTextColor(r, g, b)
	self.frame.subzonepvptext:SetTextColor(r, g, b)
	
	subZonePvPText:SetText("")
	zonePvPText:SetText(zonePvPName)

	-- when the zone is brand new, or we're entering a new main area
	if zoneName ~= self.currentZone or event == "ZONE_CHANGED_NEW_AREA" then
		self.currentZone = zoneName
		zoneNameText:SetText(zoneName)
		showZoneText = true
		if zoneName == subzoneName then
			subzoneName = "" -- hide the subzone if it's identical to the main zone
		end
		subZoneText:SetText(subzoneName)
		if not LevelUpDisplay:IsShown() then
			Show(self.frame.zoneframe)
			if subzoneName ~= "" then
				if not LevelUpDisplay:IsShown() then
					Show(self.frame.subzoneframe)
				end
			end
		end
	else
		if subzoneName == "" then
			subzoneName = zoneName
		end
		-- if the main zone name is still visible
		if self.frame.zoneframe:IsShown() then
			if zoneName == subzoneName then
				subzoneName = "" -- if the subzone equals the main zone, while the main zone is visible, then hide the subzone
				subZoneText:SetText(subzoneName)
			else
				subZoneText:SetText(subzoneName)
				if not LevelUpDisplay:IsShown() then
					Show(self.frame.subzoneframe)
				end
			end
		else
			subZoneText:SetText(subzoneName)
			if not LevelUpDisplay:IsShown() then
				Show(self.frame.subzoneframe)
			end
		end
	end
	
	
	-- positioning
	if self.frame.zonepvptext:GetText() == "" then
		self.frame.subzonetext:SetPoint("TOP", self.frame.zonetext, "BOTTOM", 0, 0)
	else
		self.frame.subzonetext:SetPoint("TOP", self.frame.zonepvptext, "BOTTOM", 0, 0)
	end	

	
end

function module:UpdateFollow(event, ...)
end

function module:ClearFollow(event, ...)
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("ZoneText", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4ZoneText", UIParent)) :SetSize(512, 128) :SetFrameStrata("LOW") :SetFrameLevel(128)  .__EndChain 
	self.frame.zoneframe = LMP:NewChain(CreateFrame("Frame", "GUI4ZoneTextFrame", self.frame)) :SetAllPoints() :SetAlpha(0) :Hide() :SetScript("OnUpdate", OnUpdate) .__EndChain 
	self.frame.zoneframe.fadeInTime = .75
	self.frame.zoneframe.holdTime = 1
	self.frame.zoneframe.fadeOutTime = 1.5
	self.frame.zonetext = LMP:NewChain("FontString", nil, self.frame.zoneframe) :SetDrawLayer("ARTWORK") :SetFontObject(ZoneTextFont) :SetPoint("TOP") .__EndChain
	self.frame.zonepvptext = LMP:NewChain("FontString", nil, self.frame.zoneframe) :SetDrawLayer("ARTWORK") :SetFontObject(PVPInfoTextFont) :SetPoint("TOP", self.frame.zonetext, "BOTTOM") .__EndChain
	self.frame.subzoneframe = LMP:NewChain(CreateFrame("Frame", "GUI4SubZoneTextFrame", self.frame)) :SetAllPoints() :SetAlpha(0) :Hide() :SetScript("OnUpdate", OnUpdate) .__EndChain 
	self.frame.subzoneframe.fadeInTime = .75
	self.frame.subzoneframe.holdTime = 1
	self.frame.subzoneframe.fadeOutTime = 1.5
	self.frame.subzonetext = LMP:NewChain("FontString", nil, self.frame.subzoneframe) :SetDrawLayer("ARTWORK") :SetFontObject(SubZoneTextFont) :SetPoint("TOP", self.frame.zonetext, "BOTTOM") .__EndChain
	self.frame.subzonepvptext = LMP:NewChain("FontString", nil, self.frame.subzoneframe) :SetDrawLayer("ARTWORK") :SetFontObject(PVPInfoTextFont) :SetPoint("TOP", self.frame.subzonepvptext, "BOTTOM") .__EndChain
	self.frame.autofollowtext = LMP:NewChain("FontString", nil, self.frame) :SetDrawLayer("ARTWORK") :SetFontObject(GameFontNormal) :SetPoint("CENTER", WorldFrame) .__EndChain
	self.frame.overlay = gUI4:GlockThis(self.frame, L["ZoneText"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "floaters")))
	self.frame.UpdatePosition = function(self) module:UpdatePosition() end
	self.frame.GetSettings = function() return self.db.profile end
	
	self.currentZone = ""

	self:KillBlizzard()

	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")

	self:ApplySettings()
end

function module:OnEnable()
	self:RegisterEvent("ZONE_CHANGED", "UpdateZone")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateZone")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateZone")
	self:RegisterEvent("AUTOFOLLOW_BEGIN", "UpdateFollow")
	self:RegisterEvent("AUTOFOLLOW_END", "UpdateFollow")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ClearFollow")
end

function module:OnDisable()
	self:UnregisterEvent("ZONE_CHANGED")
	self:UnregisterEvent("ZONE_CHANGED_INDOORS")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	self:UnregisterEvent("AUTOFOLLOW_BEGIN")
	self:UnregisterEvent("AUTOFOLLOW_END")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end
