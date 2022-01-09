local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_CastBars", true)
if not parent then return end

local module = parent:NewModule("Timers", "GP_AceEvent-3.0", "GP_AceBucket-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme

-- Lua API
local ipairs, pairs = ipairs, pairs
local select, unpack = select, unpack
local tostring = tostring

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat
-- local QueryWorldCountdownTimer = QueryWorldCountdownTimer

local TimerBar = parent.TimerBar
local TimerBar_MT = { __index = TimerBar }

local timers = {} -- table to hold our timer bar registry

local QUERIED

-- local timerTypes = { -- timerIDs for blizzard timers started with START_TIMER
	-- [TIMER_TYPE_PVP] = true,
	-- [TIMER_TYPE_CHALLENGE_MODE] = true
-- }

local validTimers = { -- timerIDs for blizzard timers started with MIRROR_TIMER_START
	EXHAUSTION = true, 
	BREATH = true, 
	FEIGNDEATH = true
}

local mirrorColors = {
	EXHAUSTION = { 1, .9, 0 },
	BREATH = { 0, .5, 1 },
	DEATH = { 1, .7, 0 },
	FEIGNDEATH = { 1, .7, 0 }
}

local defaults = {
	profile = {
		skin = "Warcraft",
		locked = true,
		enabled = true,
		growth = "DOWN",
		position = {}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().timers
end

local function GetTimerInfo(timerID)
	if TimerTracker and TimerTracker.timerList then
		for i, timer in ipairs(TimerTracker.timerList) do
			if timer.type and (timer.type == timerID) then
				local value
				if timer.endTime then
					value = timer.endTime - GetTime()
				else
					value = timer.time
				end
				local min, max = timer.bar:GetMinMaxValues()
				local started = timer.endTime - max
				return value, min, max, started, ending
			end
		end
	end
end

-- called by the timer bar template after :Hide(), but before its info is wiped
local function OnHide(self)
	local timerID = self.info.timerID
	if timerID and timers[timerID] then
		timers[timerID]:Hide() -- hide the scaffold
		timers[timerID] = nil -- clear the reference to release the bar
	end
end

function module:StartTimer(timerID, currentBarValue, maxBarValue, changePerSecond, paused, label)
	-- print(":StartTimer()", timerID, currentBarValue, maxBarValue, changePerSecond, paused, label)
	local timer = timers[timerID]
	timers[timerID] = timer or self:GetTimer()
	if not timer then -- spanking new timer
		timers[timerID].bar.OnHide = OnHide -- adding this to all timers for now
	end
	timers[timerID].bar:Start(timerID, currentBarValue, 0, maxBarValue, changePerSecond, paused, label) -- this resets the bar.info.started value to GetTime()
	if mirrorColors[timerID] then
		timers[timerID].bar:SetStatusBarColor(unpack(mirrorColors[timerID]))
	else
		timers[timerID].bar:SetStatusBarColor(unpack(timers[timerID].bar.fallbackColors))
	end
	if not timers[timerID]:IsShown() then
		timers[timerID]:Show()
	end
end
-- if gUI4.version == "Development" then
	-- _G.StartTimer = function(current, max, step) 
		-- module:StartTimer("Development", current, max, step)
	-- end
-- end

function module:StopTimer(timerID)
	if timers[timerID] then
		timers[timerID]:Hide() -- hide the scaffold to halt all update timers
		timers[timerID].bar:Stop() -- stop the bar now that its parent is hidden. no risk of double :Stop() calls now
		timers[timerID] = nil -- clear the local reference to free up the bar
	end
end

-- in MoP this applies to the countdown before a BG/arena starts
function module:START_TIMER(event, ...)
	local timerType, timeSeconds, totalTime  = ...
	-- only start pvp/instance countdown timers that have been started by our sync requests, as that is more reliable than the initial events
	if (timerType == TIMER_TYPE_PVP or timerType == TIMER_TYPE_CHALLENGE_MODE) and not QUERIED then
		return
	end
	self:StartTimer(timerType, timeSeconds, totalTime, -1, false, false)
	-- adding a callback for instance countdown timers to be slightly more synced later on, since they sometimes can be a bit off
	if QUERIED then
		if timeSeconds > 5 then
			-- C_Timer.After(duration, callback)
			-- ticker = C_Timer.NewTicker(duration, callback, iterations)
		end
		QUERIED = nil
	end
end

-- in MoP this applies to underwater breath
function module:MIRROR_TIMER_START(event, ...)
	local timerID, startTime, maxTime, change, paused, label = ... -- startTime & maxTime is in ms, change is the change per second in seconds
	if validTimers[timerID] then -- inactive timers returns "UNKNOWN", so make sure we only start actual timers
		self:StartTimer(timerID, startTime/1000, maxTime/1000, change, paused, label)
	end
end

function module:MIRROR_TIMER_STOP(event, timerID)
	self:StopTimer(timerID)
end

-- with no timerID, is this something we really need to watch out for? :/
function module:MIRROR_TIMER_PAUSE(event, ...)
end

function module:PLAYER_ENTERING_WORLD(event)
	-- BREATH timer not visible when logging in under water. blizzard bug. no way around. so the following is sort of pointless. :/
	for id = 1, MIRRORTIMER_NUMTIMERS do
		local timerID, startTime, maxTime, change, paused, label = GetMirrorTimerInfo(id) -- startTime & maxTime in ms. tested. 
		if timerID and validTimers[timerID] then
			self:MIRROR_TIMER_START(event, timerID, startTime, maxTime, change, paused, label)
		end
	end
	-- query the server for instance countdown timer if we're in one
	local inInstance, instanceType = IsInInstance()
	if inInstance then
		if instanceType == "pvp" or instanceType == "arena" then
			QUERIED = true -- tell our addon that we sent a query
			QueryWorldCountdownTimer(TIMER_TYPE_PVP)
		else
			local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()
			local _, groupType, isHeroic, isChallengeMode, toggleDifficultyID = GetDifficultyInfo(difficultyID)
			if isChallengeMode then
				QUERIED = true -- tell our addon that we sent a query
				QueryWorldCountdownTimer(TIMER_TYPE_CHALLENGE_MODE)
			end
		end
	end
end

function module:GetTimer()
	local id 
	for i, scaffold in ipairs(self.timers) do
		if not scaffold:IsShown() then
			id = i
			break
		end
	end
	if not id then
		id = #self.timers + 1
	end
	if not self.timers[id] then
		self.timers[id] = LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :SetFrameStrata("LOW") .__EndChain
		self.timers[id].GetSettings = function() return self.db.profile end
		self.timers[id].bar = LMP:NewChain(self:New(id, function() return self.db.profile end)) :SetParent(self.timers[id]) .__EndChain
		self.timers[id].backdropframe = LMP:NewChain(CreateFrame("Frame", nil, self.timers[id].bar)) :SetFrameLevel(self.timers[id]:GetFrameLevel() - 1) :SetAllPoints(self.timers[id]) .__EndChain
		self.timers[id].overlayframe = LMP:NewChain(CreateFrame("Frame", nil, self.timers[id].bar)) :SetFrameLevel(self.timers[id]:GetFrameLevel() + 1) :SetAllPoints(self.timers[id].backdropframe) .__EndChain
		self.timers[id].backdrop = LMP:NewChain(self.timers[id].backdropframe:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) .__EndChain
		self.timers[id].overlay = LMP:NewChain(self.timers[id].overlayframe:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
		self.timers[id].bar.fallbackColors = gUI4:GetColors("chat", "dimred")
		gUI4:ApplySmoothing(self.timers[id].bar)
		self:StyleTimer(self.timers[id])
		self:UpdatePosition()
	end
	return self.timers[id]
end

function module:StyleTimer(scaffold)
	if scaffold then
		updateConfig()
		LMP:NewChain(scaffold) :SetSize(unpack(T.size)) :EndChain()
		LMP:NewChain(scaffold.backdrop) :SetTexture(T.textures.backdrop:GetPath()) :SetSize(T.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.backdrop:GetPoint()) :EndChain()
		LMP:NewChain(scaffold.overlay) :SetTexture(T.textures.overlay:GetPath()) :SetSize(T.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.overlay:GetPoint()) :EndChain()
		
		LMP:NewChain(scaffold.bar) :ClearAllPoints() :SetPoint(unpack(T.bar.place)) :SetSize(unpack(T.bar.size)) :SetStatusBarTexture(T.bar.textures.normal:GetPath()) :SetStatusBarColor(unpack(T.bar.color)) :SetBackdropTexture(T.bar.textures.backdrop:GetPath()) :SetBackdropMultiplier(T.bar.backdropMultiplier) :SetBackdropColor(unpack(T.bar.backdropColor)) :SetBackdropAlpha(T.bar.backdropAlpha) :SetOverlayTexture(T.bar.textures.overlay:GetPath()) :SetOverlayColor(unpack(T.bar.overlayColor)) :SetOverlayAlpha(T.bar.overlayAlpha) :EndChain()
		LMP:NewChain(scaffold.bar.value) :SetFontObject(T.widgets.time.fontobject) :SetFontSize(T.widgets.time.size) :SetFontStyle(T.widgets.time.fontstyle) :SetShadowOffset(unpack(T.widgets.time.shadowoffset)) :SetShadowColor(unpack(T.widgets.time.shadowcolor)) :SetTextColor(unpack(T.widgets.time.color)) :ClearAllPoints() :SetPoint(unpack(T.widgets.time.place)) :EndChain()
		-- LMP:NewChain(scaffold.bar.safeZone.delay) :SetFontObject(T.widgets.delay.fontobject) :SetFontSize(T.widgets.delay.size) :SetFontStyle(T.widgets.delay.fontstyle) :SetShadowOffset(unpack(T.widgets.delay.shadowoffset)) :SetShadowColor(unpack(T.widgets.delay.shadowcolor)) :SetTextColor(unpack(T.widgets.delay.color)) :ClearAllPoints() :SetPoint(T.widgets.delay.place[1], scaffold.bar.safeZone, unpack(T.widgets.delay.place)) :EndChain()
		LMP:NewChain(scaffold.bar.name) :SetJustifyH(T.widgets.name.justify) :SetWidth(T.widgets.name.maxwidth) :SetHeight(T.widgets.name.size) :SetFontObject(T.widgets.name.fontobject) :SetFontSize(T.widgets.name.size) :SetFontStyle(T.widgets.name.fontstyle) :SetShadowOffset(unpack(T.widgets.name.shadowoffset)) :SetShadowColor(unpack(T.widgets.name.shadowcolor)) :SetTextColor(unpack(T.widgets.name.color)) :ClearAllPoints() :SetPoint(unpack(T.widgets.name.place)) :EndChain()
		-- LMP:NewChain(scaffold.bar.icon) :SetSize(unpack(T.widgets.icon.size)) :SetTexCoord(unpack(T.widgets.icon.texcoord)) :ClearAllPoints() :SetPoint(unpack(T.widgets.icon.place)) :EndChain()
		-- LMP:NewChain(scaffold.bar.icon.border)
			-- :SetSize(T.widgets.icon.border:GetSize())
			-- :SetTexCoord(T.widgets.icon.border:GetTexCoord())
			-- :ClearAllPoints()
			-- :SetPoint(T.widgets.icon.border:GetPoint())
		-- :EndChain()
		-- LMP:NewChain(scaffold.bar.border)
			-- :SetSize(T.bar.border:GetSize())
			-- :SetTexCoord(T.bar.border:GetTexCoord())
			-- :ClearAllPoints()
			-- :SetPoint(T.bar.border:GetPoint())
		-- :EndChain()
		
		LMP:NewChain(scaffold.bar.spark) :SetSize(T.spark.texture:GetTexSize(), scaffold.bar:GetHeight()) :SetTexture(T.spark.texture:GetPath()) :SetAlpha(T.spark.alpha) :ClearAllPoints() :SetPoint(T.spark.texture:GetPoint(), scaffold.bar:GetStatusBarTexture(), T.spark.texture:GetPoint()) :EndChain()
		
		scaffold.bar.fallbackColors = T.bar.color
	end
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
	for id, scaffold in ipairs(self.timers) do
		self:StyleTimer(scaffold)
	end
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	updateConfig()
	if self.timers then
		for id, scaffold in ipairs(self.timers) do
			scaffold.bar:ApplySettings()
			if self.db.profile.enabled then 
				scaffold.bar:Enable()
			else
				scaffold.bar:Disable()
			end
		end
	end
	self:UpdatePosition()
end
-- module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.timers then return end
	updateConfig()
	for id, scaffold in ipairs(self.timers) do
		if scaffold then
			if id == 1 then
				if self.db.profile.enabled then 
					if self.db.profile.locked then
						LMP:Place(scaffold, T.place)
						if not self.db.profile.position.x then
							scaffold:RegisterConfig(self.db.profile.position)
							scaffold:SavePosition()
						end
					else
						scaffold:RegisterConfig(self.db.profile.position)
						if self.db.profile.position.x then
							scaffold:LoadPosition()
						else
							LMP:Place(scaffold, T.place)
							scaffold:SavePosition()
							scaffold:LoadPosition()
						end
					end	
				end
			else
				scaffold:ClearAllPoints()
				scaffold:SetPoint("BOTTOMLEFT", self.timers[1], "BOTTOMLEFT", 0, (self.db.profile.growth == "DOWN" and -1 or self.db.profile.growth == "UP" and 1) * (id-1) * (T.size[2] + T.padding))
			end
		end
	end
end
-- module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:New(id, settingsFunc)
	return TimerBar:New(tostring(id), nil, settingsFunc)
end

local glocks = {}
function module:Lock()
	for bar, overlay in pairs(glocks) do
		overlay:StartFadeOut()
	end
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	for bar, overlay in pairs(glocks) do
		overlay:SetAlpha(0)
		overlay:Show()
	end
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not hasTheme then return end
	if not self.timers then return end
	updateConfig()
	for id, scaffold in ipairs(self.timers) do
		if scaffold then
			if id == 1 then
				self.db.profile.position.point = nil
				self.db.profile.position.y = nil
				self.db.profile.position.x = nil
				self.db.profile.locked = true
				wipe(self.db.profile.position)
			end
		end
	end
	self:ApplySettings()
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Timers", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()

	self:RegisterMessage("GUI4_TOP_OFFSET_CHANGED", "UpdatePosition") 
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
end

function module:OnEnable()
	if not self.timers then
		self.timers = {}
		local timer = self:GetTimer()
		timer:Hide()
		timer.UpdatePosition = function(self) module:UpdatePosition() end
		glocks[timer] = gUI4:GlockThis(timer, L["Timers"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "castbars"))) 
	end
	self:RegisterEvent("START_TIMER") 
	self:RegisterEvent("MIRROR_TIMER_START")
	self:RegisterEvent("MIRROR_TIMER_STOP")
	self:RegisterEvent("MIRROR_TIMER_PAUSE")
	self.bucketHandle = self:RegisterBucketEvent({ "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD" }, 1, "PLAYER_ENTERING_WORLD")
end

function module:OnDisable()
	self:UnregisterEvent("START_TIMER")
	self:UnregisterEvent("MIRROR_TIMER_START")
	self:UnregisterEvent("MIRROR_TIMER_STOP")
	self:UnregisterEvent("MIRROR_TIMER_PAUSE")
	self:UnregisterBucket(self.bucketHandle)
	if self.timers then
		for id, scaffold in ipairs(self.timers) do
			scaffold:Hide()
		end
	end
end
