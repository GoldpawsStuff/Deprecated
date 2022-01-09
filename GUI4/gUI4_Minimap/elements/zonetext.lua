local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Minimap", true)
if not parent then return end

local module = parent:NewModule("ZoneText", "GP_AceEvent-3.0")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- WoW API
local GetMinimapZoneText = GetMinimapZoneText
local GetSubZoneText = GetSubZoneText
local GetZonePVPInfo = GetZonePVPInfo
local GetZoneText = GetZoneText

local defaults = {
	profile = {
	}
}

local function onEnter(self) 
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	local zoneName = GetZoneText()
	local subzoneName = GetSubZoneText()
	local instance = IsInInstance()
	if subzoneName == zoneName then subzoneName = "" end
	
	if instance and pvptype then 
		return
	end
	-- if not(pvpType or instance) then
		-- pvpType = "contested" -- "fix" for pve realms? gotta come up with something better here.
	-- end
		
	if GameTooltip:IsForbidden() then
		return
	end

	LMP:PlaceTip(self)
	
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
		GameTooltip:AddLine(name, unpack(gUI4:GetColors("chat", "highlight")) )
		GameTooltip:AddLine(difficultyName, unpack(gUI4:GetColors("chat", "normal")))
	else
		local r, g, b = unpack(gUI4:GetColors("zone", pvpType or "unknown"))
		GameTooltip:AddLine(zoneName, unpack(gUI4:GetColors("chat", "highlight")) )
		GameTooltip:AddLine(subzoneName, r, g, b)
		
		if pvpType == "sanctuary" then
			GameTooltip:AddLine(SANCTUARY_TERRITORY, r, g, b)
		elseif pvpType == "arena" then
			GameTooltip:AddLine(FREE_FOR_ALL_TERRITORY, r, g, b)
		elseif pvpType == "friendly" then
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), r, g, b)	
		elseif pvpType == "hostile" then
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), r, g, b)
		elseif pvpType == "contested" then
			GameTooltip:AddLine(CONTESTED_TERRITORY, r, g, b)
		elseif pvpType == "combat" then
			GameTooltip:AddLine(COMBAT_ZONE, r, g, b)
		end
	end
	GameTooltip:Show()
end

local function onLeave(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end

function module:UpdateZoneText(event, ...)
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	local minimapZoneName = GetMinimapZoneText()
	local instance = IsInInstance()
	-- local zoneName = GetZoneText()
	-- local subzoneName = GetSubZoneText()
	if not(pvpType or instance) then
		-- pvpType = "contested" -- "fix" for pve realms? gotta come up with something better here.
	end
	local r, g, b = unpack(gUI4:GetColors("zone", pvpType or "unknown"))
	self.frame.text:SetText(minimapZoneName)
	self.frame.text:SetTextColor(unpack(gUI4:GetColors("zone", pvpType or "unknown")))
end	

function module:OnInitialize()
	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapZoneTextButton", parent:GetWidgetFrame())) :SetScript("OnUpdate", onUpdate) :SetScript("OnEnter", onEnter) :SetScript("OnLeave", onLeave) .__EndChain
	self.frame.text = LMP:NewChain("FontString", "GUI4_MinimapZoneText", self.frame) :SetFontObject(GameFontNormalSmall) :SetDrawLayer("ARTWORK") :SetFontSize(12) :SetFontStyle() :SetShadowOffset(.75, -.75) :SetShadowColor(0, 0, 0, 1) :SetPoint("TOP", parent:GetWidgetFrame(), "BOTTOM", 0, -16) :SetTextColor(unpack(gUI4:GetColors("chat", "gray"))) .__EndChain
	self.frame:SetAllPoints(self.frame.text)
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateZoneText")
	self:RegisterEvent("ZONE_CHANGED", "UpdateZoneText")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateZoneText")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateZoneText")
	self:UpdateZoneText()
end

function module:OnDisable()
end
