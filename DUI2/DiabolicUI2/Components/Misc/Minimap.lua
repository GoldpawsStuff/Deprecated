--[[

	The MIT License (MIT)

	Copyright (c) 2023 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
local Addon, ns = ...
local MinimapMod = ns:NewModule("Minimap", "LibMoreEvents-1.0", "AceTimer-3.0", "AceHook-3.0", "AceConsole-3.0")

-- Lua API
local ipairs = ipairs
local math_cos = math.cos
local math_floor = math.floor
local math_pi = math.pi
local half_pi = math_pi/2
local math_sin = math.sin
local pairs = pairs
local select = select
local string_format = string.format
local string_lower = string.lower
local string_match = string.match
local unpack = unpack

-- WoW API
local C_Timer = C_Timer
local CreateFrame = CreateFrame
local GetBuildInfo = GetBuildInfo
local GetCVar = GetCVar
local GetLatestThreeSenders = GetLatestThreeSenders
local GetMinimapZoneText = GetMinimapZoneText
local GetNetStats = GetNetStats
local GetPlayerFacing = GetPlayerFacing
local GetRealZoneText = GetRealZoneText
local GetZonePVPInfo = GetZonePVPInfo
local HasNewMail = HasNewMail
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsResting = IsResting
local PlaySound = PlaySound
local ToggleDropDownMenu = ToggleDropDownMenu

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local SetObjectScale = ns.API.SetObjectScale
local GetTime = ns.API.GetTime
local GetLocalTime = ns.API.GetLocalTime
local GetServerTime = ns.API.GetServerTime
local IsAddOnEnabled = ns.API.IsAddOnEnabled

-- WoW Strings
local L_FPS = FPS_ABBR -- "fps"
local L_MS = MILLISECONDS_ABBR -- "ms"
local L_RESTING = TUTORIAL_TITLE30 -- "Resting"
local L_NEW = NEW -- "New"
local L_MAIL = MAIL_LABEL -- "Mail"
local L_HAVE_MAIL = HAVE_MAIL -- "You have unread mail"
local L_HAVE_MAIL_FROM = HAVE_MAIL_FROM -- "Unread mail from:"

-- Constants
local TORGHAST_ZONE_ID = 2162
local IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))

local PetHider = ns.PetHider
local UIHider = ns.Hider
local noop = ns.Noop

local getTimeStrings = function(h, m, suffix, useHalfClock, abbreviateSuffix)
	if (useHalfClock) then
		return "%.0f:%02.0f |cff888888%s|r", h, m, abbreviateSuffix and string_match(suffix, "^.") or suffix
	else
		return "%02.0f:%02.0f", h, m
	end
end

local Minimap_OnMouseWheel = function(self, delta)
	if (delta > 0) then
		Minimap.ZoomIn:Click()
	elseif (delta < 0) then
		Minimap.ZoomOut:Click()
	end
end

local Minimap_OnMouseUp = function(self, button)
	if (button == "RightButton") then
		if (ns.IsWrath) then
			ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "MiniMapTracking", 8, 5)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
		else
			MinimapCluster.Tracking.Button:OnMouseDown()
		end
	elseif (button == "MiddleButton" and ns.IsRetail) then
		local GLP = GarrisonLandingPageMinimapButton or ExpansionLandingPageMinimapButton
		if (GLP and GLP:IsShown()) and (not InCombatLockdown()) then
			if (GLP.ToggleLandingPage) then
				GLP:ToggleLandingPage()
			else
				GarrisonLandingPage_Toggle()
			end
		end
	else
		local func = Minimap.OnClick or Minimap_OnClick
		if (func) then
			func(self)
		end
	end
end

local Mail_OnEnter = function(self)
	if (GameTooltip:IsForbidden()) then return end

	GameTooltip:SetOwner(self:GetParent(), "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -40, 0)

	local sender1, sender2, sender3 = GetLatestThreeSenders()
	if (sender1 or sender2 or sender3) then
		GameTooltip:AddLine(L_HAVE_MAIL_FROM, unpack(Colors.highlight))
		if (sender1) then
			GameTooltip:AddLine(sender1, unpack(Colors.green))
		end
		if (sender2) then
			GameTooltip:AddLine(sender2, unpack(Colors.green))
		end
		if (sender3) then
			GameTooltip:AddLine(sender3, unpack(Colors.green))
		end
	else
		GameTooltip:AddLine(L_HAVE_MAIL, unpack(Colors.highlight))
	end
	GameTooltip:Show()
end

local Mail_OnLeave = function(self)
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local Time_UpdateTooltip = function(self)
	if (GameTooltip:IsForbidden()) then return end

	local useHalfClock = ns.db.global.minimap.useHalfClock -- the outlandish 12 hour clock the colonials seem to favor so much
	local lh, lm, lsuffix = GetLocalTime(useHalfClock) -- local computer time
	local sh, sm, ssuffix = GetServerTime(useHalfClock) -- realm time
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)

	GameTooltip:SetOwner(self:GetParent(), "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -40, 0)
	GameTooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, unpack(Colors.title))
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, string_format(getTimeStrings(lh, lm, lsuffix, useHalfClock)), rh, gh, bh, r, g, b)
	GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, string_format(getTimeStrings(sh, sm, ssuffix, useHalfClock)), rh, gh, bh, r, g, b)
	GameTooltip:AddLine("<"..GAMETIME_TOOLTIP_TOGGLE_CALENDAR..">", unpack(Colors.quest.green))
	GameTooltip:Show()
end

local Time_OnEnter = function(self)
	self.UpdateTooltip = Time_UpdateTooltip
	self:UpdateTooltip()
end

local Time_OnLeave = function(self)
	self.UpdateTooltip = nil
	if (GameTooltip:IsForbidden()) then return end
	GameTooltip:Hide()
end

local Time_OnClick = function(self, mouseButton)
	if (ToggleCalendar) and (not InCombatLockdown()) then
		ToggleCalendar()
	end
end

MinimapMod.UpdateCompass = function(self)
	local compassFrame = self.compassFrame
	if (not compassFrame) then
		return
	end
	if (self.rotateMinimap) then
		local radius = self.compassRadius
		if (not radius) then
			local width = compassFrame:GetWidth()
			if (not width) then
				return
			end
			radius = width/2
		end

		local playerFacing = GetPlayerFacing()
		if (not playerFacing) or (self.supressCompass) or (IN_TORGHAST) then
			compassFrame:SetAlpha(0)
		else
			compassFrame:SetAlpha(1)
		end

		-- In Torghast, map is always locked. Weird.
		local angle = (IN_TORGHAST) and 0 or (self.rotateMinimap and playerFacing) and -playerFacing or 0
		compassFrame.north:SetPoint("CENTER", radius*math_cos(angle + half_pi), radius*math_sin(angle + half_pi))

		--if (not compassFrame:IsShown()) then
		--	compassFrame:Show()
		--end
	else
		compassFrame:SetAlpha(0)

		--if (compassFrame:IsShown()) then
		--	compassFrame:Hide()
		--end
	end
end

MinimapMod.UpdatePerformance = function(self)
	local performance = self.performance
	if (not performance) then
		return
	end

	local now = GetTime()
	local fps = GetFramerate()
	local world
	if (not performance.nextUpdate) or (now >= performance.nextUpdate) then
		-- latencyHome: chat, auction house, some addon data
		-- latencyWorld: combat, data from people around you(specs, gear, enchants, etc.), NPCs, mobs, casting, professions
		_, _, _, world = GetNetStats()
		performance.nextUpdate = now + 30
		performance.latencyWorld = world
	else
		world = performance.latencyWorld
	end

	local hasFps = fps and fps > 0
	local hasLatency = world and world > 0

	if (hasLatency and hasFps) then
		performance:SetFormattedText("|cffaaaaaa%.0f|r|cff888888%s|r |cffaaaaaa%.0f|r|cff888888%s|r", world, L_MS, fps, L_FPS)
	elseif (hasLatency) then
		performance:SetFormattedText("|cffaaaaaa%.0f|r|cff888888%s|r", world, L_MS)
	elseif (hasFps) then
		performance:SetFormattedText("|cffaaaaaa%.0f|r|cff888888%s|r", fps, L_FPS)
	else
		performance:SetText("")
	end

end

MinimapMod.UpdateClock = function(self)
	local time = self.time
	if (not time) then
		return
	end
	if (ns.db.global.minimap.useServerTime) then
		if (ns.db.global.minimap.useHalfClock) then
			local h, m, suffix = GetServerTime(true)
			time:SetFormattedText("%.0f:%02d", h, m)
			time.suffix:SetFormattedText(" %s", suffix)
		else
			time:SetFormattedText("%02d:%02d", GetServerTime(false))
			time.suffix:SetText(nil)
		end
	else
		if (ns.db.global.minimap.useHalfClock) then
			local h, m, suffix = GetLocalTime(true)
			time:SetFormattedText("%.0f:%02d", h, m)
			time.suffix:SetFormattedText(" %s", suffix)
		else
			time:SetFormattedText("%02d:%02d", GetLocalTime(false))
			time.suffix:SetText(nil)
		end
	end
end

MinimapMod.UpdateMail = function(self)
	local mail = self.mail
	if (not mail) then
		return
	end
	local hasMail = HasNewMail()
	if (hasMail) then
		mail:GetParent():Show()
	else
		mail:GetParent():Hide()
	end
end

MinimapMod.UpdateTimers = function(self)
	-- In Torghast, map is always locked. Weird.
	-- *Note that this is only in the tower, not the antechamber.
	-- *We're resting in the antechamber, and it's a sanctuary. Good indicators.
	-- *Also, we know there is an API call for it. We like ours better.
	IN_TORGHAST = (not IsResting()) and (GetRealZoneText() == GetRealZoneText(TORGHAST_ZONE_ID))

	self.rotateMinimap = GetCVar("rotateMinimap") == "1"
	if (self.rotateMinimap) then
		if (not self.compassTimer) then
			self.compassTimer = self:ScheduleRepeatingTimer("UpdateCompass", 1/60)
			self:UpdateCompass()
		end
	elseif (self.compassTimer) then
		self:CancelTimer(self.compassTimer)
		self:UpdateCompass()
	end
	if (not self.performanceTimer) then
		self.performanceTimer = self:ScheduleRepeatingTimer("UpdatePerformance", 1)
		self:UpdatePerformance()
	end
	if (not self.clockTimer) then
		self.clockTimer = self:ScheduleRepeatingTimer("UpdateClock", 1)
		self:UpdateClock()
	end
end

MinimapMod.UpdateZone = function(self)
	local zoneName = self.zoneName
	if (not zoneName) then
		return
	end
	local a = zoneName:GetAlpha() -- needed to preserve alpha after text color changes
	local minimapZoneName = GetMinimapZoneText()
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	if (pvpType) then
		local color = Colors.zone[pvpType]
		if (color) then
			zoneName:SetTextColor(color[1], color[2], color[3], a)
		else
			zoneName:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], a)
		end
	else
		zoneName:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], a)
	end
	zoneName:SetText(minimapZoneName)
end

MinimapMod.UpdatePosition = function(self)
	Minimap:SetParent(PetHider)
	Minimap:ClearAllPoints()
	Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -60, -60)
	Minimap:SetMovable(true)
end

MinimapMod.UpdateSize = function(self)
	Minimap:SetSize(280,280)
end

MinimapMod.DisableBlizzard = function(self)
	MinimapCluster:UnregisterAllEvents()
	MinimapCluster:EnableMouse(false)
	MinimapBackdrop:SetParent(UIHider)
	GameTimeFrame:SetParent(UIHider)
	GameTimeFrame:UnregisterAllEvents()

	if (ns.IsRetail) then
		MinimapCluster.BorderTop:SetParent(UIHider)
		MinimapCluster.InstanceDifficulty:SetParent(UIHider)
		MinimapCluster.MailFrame:SetParent(UIHider)
		MinimapCluster.Tracking:SetParent(UIHider)
		MinimapCluster.ZoneTextButton:SetParent(UIHider)
		Minimap.ZoomIn:SetParent(UIHider)
		Minimap.ZoomIn:UnregisterAllEvents()
		Minimap.ZoomOut:SetParent(UIHider)
		Minimap.ZoomOut:UnregisterAllEvents()
		Minimap:SetArchBlobRingAlpha(0)
		Minimap:SetArchBlobRingScalar(0)
		Minimap:SetQuestBlobRingAlpha(0)
		Minimap:SetQuestBlobRingScalar(0)
		ExpansionLandingPageMinimapButton:SetParent(UIHider)
		ExpansionLandingPageMinimapButton:ClearAllPoints()
		ExpansionLandingPageMinimapButton:SetPoint("CENTER")
	else
		MinimapBorderTop:SetParent(UIHider)
		MiniMapInstanceDifficulty:SetParent(UIHider)
		MiniMapInstanceDifficulty:UnregisterAllEvents()
		MiniMapMailFrame:SetParent(UIHider)
		MiniMapTracking:SetParent(UIHider)
		MinimapZoneTextButton:SetParent(UIHider)
		MinimapZoomIn:SetParent(UIHider)
		MinimapZoomOut:SetParent(UIHider)
	end
end

MinimapMod.StyleMinimap = function(self)

	SetObjectScale(MinimapCluster)
	SetObjectScale(Minimap)

	Minimap:SetFrameStrata("MEDIUM")
	Minimap:SetSize(280,280)
	Minimap:SetMaskTexture(GetMedia("minimap-mask-transparent"))
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", Minimap_OnMouseWheel)
	Minimap:SetScript("OnMouseUp", Minimap_OnMouseUp)

	-- Minimap Backdrop
	local backdrop = Minimap:CreateTexture(nil, "BACKGROUND")
	backdrop:SetPoint("TOPLEFT", -2, 2)
	backdrop:SetPoint("BOTTOMRIGHT", 2, -2)
	backdrop:SetTexture(GetMedia("minimap-mask-opaque"))
	backdrop:SetVertexColor(0, 0, 0, .75)

	-- Minimap Border
	local border = Minimap:CreateTexture(nil, "OVERLAY", nil, 0)
	border:SetPoint("CENTER")
	border:SetSize(340,340)
	border:SetTexture(GetMedia("minimap-border"))

	-- Custom Widgets
	--------------------------------------------------------
	-- Zone
	local zoneName = Minimap:CreateFontString()
	zoneName:SetDrawLayer("OVERLAY", 1)
	zoneName:SetFontObject(GetFont(15,true))
	zoneName:SetAlpha(.85)
	zoneName:SetPoint("TOP", Minimap, "BOTTOM", 0, -26)
	self.zoneName = zoneName

	-- Performance
	local performance = Minimap:CreateFontString()
	performance:SetDrawLayer("OVERLAY", 1)
	performance:SetFontObject(GetFont(13,true))
	performance:SetTextColor(.53,.53,.53, .85)
	performance:SetPoint("TOP", zoneName, "BOTTOM", 0, -4)
	self.performance = performance

	-- Time
	local timeFrame = CreateFrame("Button", nil, Minimap)
	timeFrame:SetScript("OnEnter", Time_OnEnter)
	timeFrame:SetScript("OnLeave", Time_OnLeave)
	timeFrame:SetScript("OnClick", Time_OnClick)
	timeFrame:RegisterForClicks("AnyUp")

	local time = timeFrame:CreateFontString()
	time:SetDrawLayer("OVERLAY", 1)
	time:SetJustifyH("CENTER")
	time:SetJustifyV("TOP")
	time:SetFontObject(GetFont(18,true))
	time:SetTextColor(unpack(Colors.offwhite))
	time:SetAlpha(.85)
	time:SetPoint("TOP", Minimap, "TOP", 0, -30)
	timeFrame:SetAllPoints(time)
	self.time = time

	local timeSuffix = timeFrame:CreateFontString()
	timeSuffix:SetDrawLayer("OVERLAY", 1)
	timeSuffix:SetJustifyH("CENTER")
	timeSuffix:SetJustifyV("TOP")
	timeSuffix:SetFontObject(GetFont(11,true))
	timeSuffix:SetTextColor(unpack(Colors.darkgray))
	timeSuffix:SetAlpha(.75)
	timeSuffix:SetPoint("TOPLEFT", time, "TOPRIGHT", 0, -2)
	time.suffix = timeSuffix

	-- Coordinates
	local coordinates = Minimap:CreateFontString()
	coordinates:SetDrawLayer("OVERLAY", 1)
	coordinates:SetJustifyH("CENTER")
	coordinates:SetJustifyV("BOTTOM")
	coordinates:SetFontObject(GetFont(12,true))
	self.coordinates = coordinates

	-- Mail
	local mailFrame = CreateFrame("Button", nil, Minimap)
	mailFrame:SetFrameLevel(mailFrame:GetFrameLevel() + 5)
	mailFrame:SetScript("OnEnter", Mail_OnEnter)
	mailFrame:SetScript("OnLeave", Mail_OnLeave)
	mailFrame:Hide()

	local mail = mailFrame:CreateFontString()
	mail:SetDrawLayer("OVERLAY", 1)
	mail:SetJustifyH("CENTER")
	mail:SetJustifyV("BOTTOM")
	mail:SetFontObject(GetFont(16,true))
	mail:SetTextColor(unpack(Colors.offwhite))
	mail:SetAlpha(.85)
	mail:SetFormattedText("%s %s", L_NEW, L_MAIL)
	mail:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 30)
	mailFrame:SetAllPoints(mail)
	self.mail = mail

	-- Minimap Highlight
	local highlight = Minimap:CreateTexture(nil, "OVERLAY", nil, -1)
	highlight:SetPoint("CENTER")
	highlight:SetSize(340,340)
	highlight:SetTexture(GetMedia("minimap-highlight"))
	highlight:SetAlpha(0)
	highlight:Hide()
	highlight.Animation = highlight:CreateAnimationGroup()
	highlight.Animation:SetLooping("BOUNCE")
	highlight.Animation.Bounce = highlight.Animation:CreateAnimation("Alpha")
	highlight.Animation.Bounce:SetFromAlpha(0)
	highlight.Animation.Bounce:SetToAlpha(1)
	highlight.Animation.Bounce:SetDuration(1.5)
	highlight.Animation.Bounce:SetSmoothing("IN_OUT")
	self.highlight = highlight

	self.StartHighlight = function()
		if (not highlight.Animation:IsPlaying()) then
			highlight:Show()
			highlight.Animation:Play()
		end
	end

	self.StopHighlight = function()
		if (highlight.Animation:IsPlaying()) then
			highlight.Animation:Stop()
			highlight:Hide()
		end
	end

	if (not ns.IsRetail) then
		local GLP = GarrisonLandingPageMinimapButton or ExpansionLandingPageMinimapButton
		if (GLP) then
			self:SecureHook(GLP.MinimapLoopPulseAnim, "Play", self.StartHighlight)
			self:SecureHook(GLP.MinimapLoopPulseAnim, "Stop", self.StopHighlight)
			self:SecureHook(GLP.MinimapPulseAnim, "Play", self.StartHighlight)
			self:SecureHook(GLP.MinimapPulseAnim, "Stop", self.StopHighlight)
			self:SecureHook(GLP.MinimapAlertAnim, "Play", self.StartHighlight)
			self:SecureHook(GLP.MinimapAlertAnim, "Stop", self.StopHighlight)
		end
	end

	-- Compass
	local compassFrame = CreateFrame("Frame", nil, Minimap)
	compassFrame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	compassFrame:SetPoint("TOPLEFT", 14, -14)
	compassFrame:SetPoint("BOTTOMRIGHT", -14, 14)
	--compassFrame:Hide()

	local north = compassFrame:CreateFontString()
	north:SetDrawLayer("ARTWORK", 1)
	north:SetFontObject(GetFont(16,true))
	north:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], .75)
	north:SetText("N")
	compassFrame.north = north
	self.compassFrame = compassFrame


	-- Blizzard Widgets
	--------------------------------------------------------
	-- Order Hall / Garrison / Covenant Sanctum
	local GLP = GarrisonLandingPageMinimapButton or ExpansionLandingPageMinimapButton
	if (GLP) then
		GLP:ClearAllPoints()
		GLP:SetPoint("TOP", UIParent, "TOP", 0, 200) -- off-screen

		---- They change the position of the button through a local function named "ApplyGarrisonTypeAnchor".
		---- Only way we can override it without messing with method nooping, is to hook into the global function calling it.
		if (GarrisonLandingPageMinimapButton_UpdateIcon) then
			hooksecurefunc("GarrisonLandingPageMinimapButton_UpdateIcon", function()
				GLP:ClearAllPoints()
				GLP:SetPoint("TOP", UIParent, "TOP", 0, 200)
			end)
		elseif (ExpansionLandingPageMinimapButton and ExpansionLandingPageMinimapButton.UpdateIcon) then
			hooksecurefunc(ExpansionLandingPageMinimapButton, "UpdateIcon", function()
				GLP:ClearAllPoints()
				GLP:SetPoint("TOP", UIParent, "TOP", 0, 200)
			end)
		end
	end

	-- Dungeon Eye
	local eyeFrame = CreateFrame("Frame", nil, Minimap)
	eyeFrame:SetFrameLevel(Minimap:GetFrameLevel() + 10)
	eyeFrame:SetPoint("CENTER", math_cos(225*(math_pi/180)) * (280/2 + 10), math_sin(225*(math_pi/180)) * (280/2 + 10))
	eyeFrame:SetSize(64,64)
	self.eyeFrame = eyeFrame

	if (ns.IsWrath) then
		if (MiniMapBattlefieldFrame) then

			local eyeTexture = MiniMapBattlefieldFrame:CreateTexture()
			eyeTexture:SetDrawLayer("ARTWORK", 1)
			eyeTexture:SetPoint("CENTER", 0, 0)
			eyeTexture:SetSize(64,64)
			eyeTexture:SetTexture(GetMedia("group-finder-eye-orange"))
			eyeTexture:SetVertexColor(.8, .76, .72)
			eyeTexture:SetShown(MiniMapBattlefieldFrame:IsShown())
			self.eyeTexture = eyeTexture

			MiniMapBattlefieldFrame:SetParent(eyeFrame)
			MiniMapBattlefieldFrame:ClearAllPoints()
			MiniMapBattlefieldFrame:SetPoint("CENTER", 0, 0)

			MiniMapBattlefieldFrame:SetFrameLevel(MiniMapBattlefieldFrame:GetFrameLevel() + 10)
			MiniMapBattlefieldFrame:ClearAllPoints()
			MiniMapBattlefieldFrame:SetHitRectInsets(-8, -8, -8, -8)

			MiniMapBattlefieldBorder:Hide()
			MiniMapBattlefieldIcon:SetAlpha(0)
		end

	else

		if (not ns.IsRetail) then

			local eyeTexture = QueueStatusMinimapButton.Eye:CreateTexture()
			eyeTexture:SetDrawLayer("ARTWORK", 1)
			eyeTexture:SetPoint("CENTER", 0, 0)
			eyeTexture:SetSize(64,64)
			eyeTexture:SetTexture(GetMedia("group-finder-eye-orange"))
			eyeTexture:SetVertexColor(.8, .76, .72)
			self.eyeTexture = eyeTexture

			QueueStatusMinimapButton:SetHighlightTexture("")

			QueueStatusMinimapButtonBorder:SetAlpha(0)
			QueueStatusMinimapButtonBorder:SetTexture(nil)
			QueueStatusMinimapButtonGroupSize:SetFontObject(GetFont(15,true))
			QueueStatusMinimapButtonGroupSize:ClearAllPoints()
			QueueStatusMinimapButtonGroupSize:SetPoint("BOTTOMRIGHT", 0, 0)

			QueueStatusMinimapButton:SetParent(eyeFrame)
			QueueStatusMinimapButton:ClearAllPoints()
			QueueStatusMinimapButton:SetPoint("CENTER", 0, 0)

			QueueStatusMinimapButton.Eye:SetSize(64,64)
			QueueStatusMinimapButton.Eye.texture:SetParent(UIHider)
			QueueStatusMinimapButton.Eye.texture:SetAlpha(0)

			QueueStatusMinimapButton.Highlight:SetAlpha(0)
			QueueStatusMinimapButton.Highlight:SetTexture(nil)

			QueueStatusFrame:ClearAllPoints()
			QueueStatusFrame:SetPoint("TOPRIGHT", QueueStatusMinimapButton, "BOTTOMLEFT", 0, 0)
		end

	end
end

MinimapMod.InitializeMBB = function(self)
end

MinimapMod.InitializeNarcissus = function(self)
	local Narci_MinimapButton = SetObjectScale(Narci_MinimapButton)
	if (not Narci_MinimapButton) then
		return
	end

	Narci_MinimapButton:SetScript("OnDragStart", nil)
	Narci_MinimapButton:SetScript("OnDragStop", nil)
	Narci_MinimapButton:SetSize(56,56) -- 36,36
	Narci_MinimapButton.Color:SetVertexColor(.85, .85, .85, 1)
	Narci_MinimapButton.Background:SetScale(1)
	Narci_MinimapButton.Background:SetSize(46,46) -- 42,42
	Narci_MinimapButton.Background:SetVertexColor(.75, .75, .75, 1)
	Narci_MinimapButton.InitPosition = function(self)
		local p, a, rp, x, y = self:GetPoint()
		if (rp ~= "BOTTOM") then
			Narci_MinimapButton:ClearAllPoints()
			Narci_MinimapButton:SetPoint("CENTER", Minimap, "BOTTOM", 0, 0)
		end
	end
	Narci_MinimapButton.OnDragStart = noop
	Narci_MinimapButton.OnDragStop = noop
	Narci_MinimapButton.SetIconScale = noop
	Narci_MinimapButton:InitPosition()

	hooksecurefunc(Narci_MinimapButton, "SetPoint", Narci_MinimapButton.InitPosition)

	--Narci_SetActiveBorderTexture

end

MinimapMod.InitializeAddon = function(self, addon, ...)
	if (addon == "ADDON_LOADED") then
		addon = ...
	end
	if (not self.Addons[addon]) then
		return
	end
	local method = self["Initialize"..addon]
	if (method) then
		method(self)
	end
	self.Addons[addon] = nil
end

MinimapMod.SetClock = function(self, input)
	local args = { self:GetArgs(string_lower(input)) }
	for _,arg in ipairs(args) do
		if (arg == "24") then
			ns.db.global.minimap.useHalfClock = false
		elseif (arg == "12") then
			ns.db.global.minimap.useHalfClock = true
		elseif (arg == "realm") then
			ns.db.global.minimap.useServerTime = true
		elseif (arg == "local") then
			ns.db.global.minimap.useServerTime = false
		end
	end
end

MinimapMod.OnEvent = function(self, event)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:UpdateZone()
		self:UpdateMail()
		self:UpdateTimers()

	elseif (event == "VARIABLES_LOADED") then
		self:UpdateTimers()
		self:UpdateSize()
		self:UpdatePosition()

	elseif (event == "PLAYER_REGEN_ENABLED") then
		if (not InCombatLockdown()) then
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
			self:UpdateTimers()
		end
	end
end

MinimapMod.OnInitialize = function(self)

	self:DisableBlizzard()
	self:StyleMinimap()
	self:UpdatePosition()
	self:UpdateSize()

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	self:RegisterEvent("CVAR_UPDATE", "UpdateTimers")
	self:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMail")
	self:RegisterEvent("ZONE_CHANGED", "UpdateZone")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateZone")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateZone")

	if (ns.IsRetail) then
		self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "UpdatePosition")
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "UpdatePosition")
	end

	self:RegisterChatCommand("setclock", "SetClock")

	if (not SlashCmdList["CALENDAR"]) then
		self:RegisterChatCommand("calendar", function()
			if (ToggleCalendar) then
				ToggleCalendar()
			end
		end)
	end

	self.Addons = {}

	local addons, queued = { "MBB", "Narcissus" }
	for _,addon in ipairs(addons) do
		if (IsAddOnEnabled(addon)) then
			self.Addons[addon] = true
			if (IsAddOnLoaded(addon)) then
				self:InitializeAddon(addon)
			else
				-- Forcefully load addons
				-- *This helps work around an issue where
				--  Narcissus can bug out when started in combat.
				LoadAddOn(addon)
				self:InitializeAddon(addon)
			end
		end
	end

end