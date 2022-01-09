local ADDON = ...
local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule(ADDON, true)
if not parent then return end

-- Lua API
local _G = _G
local tostring = tostring 

-- WoW API
local CreateFrame = _G.CreateFrame
local GameTooltip = _G.GameTooltip
local GarrisonLandingPageMinimapButton = _G.GarrisonLandingPageMinimapButton

local module = parent:NewModule("Garrison", "GP_AceEvent-3.0")

local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local GARRISON_ALERT_CONTEXT_BUILDING = _G.GARRISON_ALERT_CONTEXT_BUILDING
local GARRISON_ALERT_CONTEXT_INVASION = _G.GARRISON_ALERT_CONTEXT_INVASION
local GARRISON_ALERT_CONTEXT_MISSION = _G.GARRISON_ALERT_CONTEXT_MISSION
local GARRISON_LANDING_PAGE_TITLE = _G.GARRISON_LANDING_PAGE_TITLE
local MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP = _G.MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP
local T, hasTheme


local defaults = {
	profile = {
    showGarrisonButton = true
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().widgets.garrison
end

local function OnEnter(self)
	if not self.highlight:IsShown() then
		self.highlight:SetAlpha(0)
		self.highlight:Show()
	end
	self.highlight:StartFadeIn(self.highlight.fadeInDuration)
	if (not GameTooltip:IsForbidden()) then
		LMP:PlaceTip(self)
		GameTooltip:SetText(GARRISON_LANDING_PAGE_TITLE, 1, 1, 1)
		GameTooltip:AddLine(MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP, nil, nil, nil, true)
		GameTooltip:Show()
	end
end

local function OnLeave(self)
	if self.highlight:IsShown() then
		self.highlight:StartFadeOut()
	end
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end

local function OnClick(self, ...)
  if GarrisonLandingPageMinimapButton then
    GarrisonLandingPageMinimapButton:GetScript("OnClick")(GarrisonLandingPageMinimapButton, "LeftButton")
  end
end

local function ShowPulse(self, redAlert)
  if redAlert then
    if self.frame.icon.glow:IsShown() then
      self.frame.icon.glow:Hide()
    end
    if not self.frame.icon.redglow:IsShown() then
      self.frame.icon.redglow:Show()
    end
  else
    if self.frame.icon.redglow:IsShown() then
      self.frame.icon.redglow:Hide()
    end
    if not self.frame.icon.glow:IsShown() then
      self.frame.icon.glow:Show()
    end
  end
  if not self.frame.glow:IsShown() then
    self.frame.glow:SetAlpha(0)
    self.frame.glow:Show()
  end
--  self.frame.glow:StartFadeIn(.5)
	self.frame.glow:StartFlash(2.5, 1.5, 0, 1, false)
end

local function HidePulse(self, ...)
  if self.frame.glow:IsShown() then
    self.frame.glow:StopFlash()
    self.frame.glow:StartFadeOut()
  end
end

function module:UpdateGarrisonButton(event, ...)
	if event == "GARRISON_HIDE_LANDING_PAGE" then
    if self.frame:IsShown() then
      self.frame:Hide()
    end
	elseif event == "GARRISON_SHOW_LANDING_PAGE" then
    if self.db.profile.showGarrisonButton and not self.frame:IsShown() then
      self.frame:Show()
    end
    -- kill the pulsing when we open the report, we don't really need to be reminded any longer
    if _G.GarrisonLandingPage and _G.GarrisonLandingPage:IsShown() then
      HidePulse(self) 
    end
	elseif event == "GARRISON_BUILDING_ACTIVATABLE" then
		ShowPulse(self)
	elseif event == "GARRISON_BUILDING_ACTIVATED" or event == "GARRISON_ARCHITECT_OPENED" then
		HidePulse(self, GARRISON_ALERT_CONTEXT_BUILDING)
	elseif event == "GARRISON_MISSION_FINISHED" then
		ShowPulse(self)
	elseif  event == "GARRISON_MISSION_NPC_OPENED" then
		HidePulse(self, GARRISON_ALERT_CONTEXT_MISSION)
	elseif event == "GARRISON_INVASION_AVAILABLE" then
		ShowPulse(self, true)
	elseif event == "GARRISON_INVASION_UNAVAILABLE" then
		HidePulse(self, GARRISON_ALERT_CONTEXT_INVASION)
	elseif event == "SHIPMENT_UPDATE" then
		local shipmentStarted = ...
		if shipmentStarted then
			-- ShowPulse(self) -- we don't need to pulse when a work order starts, because WE just started it!!!
		end
	end
end

function module:UpdateTheme(_, _, addonName)
	if addonName ~= tostring(parent) then return end
	if not self.frame then return end 
	updateConfig()
	
	LMP:Place(self.frame, T.place)
	LMP:NewChain(self.frame) :SetSize(unpack(T.size)) :EndChain()
	LMP:NewChain(self.frame.icon) :SetTexture(T.icon.textures.normal:GetPath()) :SetTexCoord(T.icon.textures.normal:GetTexCoord()) :SetSize(T.icon.textures.normal:GetTexSize()) :ClearAllPoints() :SetPoint(unpack(T.icon.place)) :EndChain()
	LMP:NewChain(self.frame.icon.highlight) :SetTexture(T.icon.textures.highlight:GetPath()) :SetTexCoord(T.icon.textures.highlight:GetTexCoord()) :SetSize(T.icon.textures.highlight:GetTexSize()) :ClearAllPoints() :SetPoint(unpack(T.icon.place)) :EndChain()
	LMP:NewChain(self.frame.icon.glow) :SetTexture(T.icon.textures.glow:GetPath()) :SetTexCoord(T.icon.textures.glow:GetTexCoord()) :SetSize(T.icon.textures.glow:GetTexSize()) :ClearAllPoints() :SetPoint(unpack(T.icon.place)) :EndChain()
	LMP:NewChain(self.frame.icon.redglow) :SetTexture(T.icon.textures.redglow:GetPath()) :SetTexCoord(T.icon.textures.redglow:GetTexCoord()) :SetSize(T.icon.textures.redglow:GetTexSize()) :ClearAllPoints() :SetPoint(unpack(T.icon.place)) :EndChain()
  LMP:NewChain(self.frame.highlight) :SetFadeOut(T.fadeOutDuration) :EndChain()
  self.frame.highlight.fadeInDuration = T.fadeInDuration
  
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	if not self.frame then return end 
	updateConfig()
  if self.db.profile.showGarrisonButton then
    self.frame:Show()
  else
    self.frame:Hide()
  end
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Garrison", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapGarrisonReportFrame", parent:GetWidgetFrame())) :EnableMouse(true) :SetScript("OnEnter", OnEnter) :SetScript("OnLeave", OnLeave) :SetScript("OnMouseDown", OnClick) .__EndChain
	self.frame.highlight = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapGarrisonReportFrameHighlight", self.frame)) :SetAlpha(0) :SetFrameLevel(self.frame:GetFrameLevel()) :SetAllPoints() .__EndChain
  self.frame.glow = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapGarrisonReportFramePulse", self.frame)) :SetAlpha(0) :SetFrameLevel(self.frame:GetFrameLevel()) :SetAllPoints() .__EndChain
	self.frame.icon = LMP:NewChain(self.frame:CreateTexture()) :SetDrawLayer("OVERLAY", 0) .__EndChain
	self.frame.icon.highlight = LMP:NewChain(self.frame.highlight:CreateTexture()) :SetAlpha(1) :SetDrawLayer("OVERLAY", 1) .__EndChain
	self.frame.icon.glow = LMP:NewChain(self.frame.glow:CreateTexture()) :Hide() :SetAlpha(1) :SetDrawLayer("OVERLAY", 2) .__EndChain
	self.frame.icon.redglow = LMP:NewChain(self.frame.glow:CreateTexture()) :Hide() :SetAlpha(1) :SetDrawLayer("OVERLAY", 3) .__EndChain
	
	gUI4:ApplyFadersToFrame(self.frame.highlight)
	gUI4:ApplyFadersToFrame(self.frame.glow)
  self.frame.highlight:SetFadeOut(1.5)
  self.frame.glow:SetFadeOut(0.75)
  
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
end

function module:OnEnable()
 	self:RegisterEvent("GARRISON_SHOW_LANDING_PAGE", "UpdateGarrisonButton")
	self:RegisterEvent("GARRISON_HIDE_LANDING_PAGE", "UpdateGarrisonButton")
	self:RegisterEvent("GARRISON_BUILDING_ACTIVATABLE", "UpdateGarrisonButton")
	self:RegisterEvent("GARRISON_BUILDING_ACTIVATED", "UpdateGarrisonButton")
	self:RegisterEvent("GARRISON_ARCHITECT_OPENED", "UpdateGarrisonButton")
	self:RegisterEvent("GARRISON_MISSION_FINISHED", "UpdateGarrisonButton")
	self:RegisterEvent("GARRISON_MISSION_NPC_OPENED", "UpdateGarrisonButton")
	self:RegisterEvent("GARRISON_INVASION_AVAILABLE", "UpdateGarrisonButton")
	self:RegisterEvent("GARRISON_INVASION_UNAVAILABLE", "UpdateGarrisonButton")
	self:RegisterEvent("SHIPMENT_UPDATE", "UpdateGarrisonButton")
end

function module:OnDisable()
 	self:UnregisterEvent("GARRISON_SHOW_LANDING_PAGE")
	self:UnregisterEvent("GARRISON_HIDE_LANDING_PAGE")
	self:UnregisterEvent("GARRISON_BUILDING_ACTIVATABLE")
	self:UnregisterEvent("GARRISON_BUILDING_ACTIVATED")
	self:UnregisterEvent("GARRISON_ARCHITECT_OPENED")
	self:UnregisterEvent("GARRISON_MISSION_FINISHED")
	self:UnregisterEvent("GARRISON_MISSION_NPC_OPENED")
	self:UnregisterEvent("GARRISON_INVASION_AVAILABLE")
	self:UnregisterEvent("GARRISON_INVASION_UNAVAILABLE")
	self:UnregisterEvent("SHIPMENT_UPDATE")
end

