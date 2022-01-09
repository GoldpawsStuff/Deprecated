local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local module = parent:NewModule("Tracker", "GP_AceEvent-3.0", "GP_AceConsole-3.0")

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local HoverFrame = CreateFrame("Button")
local HoverFrame_MT = { __index = HoverFrame }
local T, hasTheme

-- Lua API
local pairs, select, unpack = pairs, select, unpack
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local tonumber, tostring = tonumber, tostring

-- WoW API
local GetCVarBool = GetCVarBool
local GetMoney = GetMoney
local GetNumQuestWatches = GetNumQuestWatches
local GetQuestWatchInfo = GetQuestWatchInfo
local MouseIsOver = MouseIsOver
local UnitAffectingCombat = UnitAffectingCombat

local colors = gUI4:GetColors()
local trackerHeight, smallTracker, largeTracker = 450, 204 + 20, 306 + 20 --450
local hadItem, hadQuestHere, hasItem, hasQuestHere, isResting

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		wide = GetCVar("watchFrameWidth") == "1",
		position = {}
	}
}

local function updateConfig() 
	T = parent:GetActiveTheme().tracker
end

local function getForcedState(previous)
	if previous then
		return not(isResting) and (hadItem or hadQuestHere)
	else
		return not(isResting) and (hasItem or hasQuestHere)
	end
end

local function updateForcedState()
	module.FadeManager:SetUserForced(getForcedState())
	hadItem = hasItem
	hadQuestHere = hasQuestHere
end

local function utf8sub(str, i, dots)
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

-- update the main header text's color when minimizing/maximizing the tracker
local function updateHeader()
	if ObjectiveTrackerFrame.collapsed or not ObjectiveTrackerFrame.HeaderMenu.MinimizeButton:IsEnabled() then 
		ObjectiveTrackerFrame.HeaderMenu.Title:SetTextColor(unpack(colors.chat.gray))
	else
		ObjectiveTrackerFrame.HeaderMenu.Title:SetTextColor(unpack(colors.chat.offwhite))
	end
end

function module:QUEST_ACCEPTED(event, questLogID)
	if GetNumQuestWatches() == 0 then 
		hasQuestHere = false
		return 
	end
	local found 
	for watchIndex = 1, GetNumQuestWatches() do
		local questID, title, questLogIndex, numObjectives, requiredMoney, isComplete, startEvent, isAutoComplete, failureTime, timeElapsed, questType, isTask, isStory, isOnMap, hasLocalPOI = GetQuestWatchInfo(watchIndex)
		if isOnMap and not isComplete then
			found = true
			break
		end
	end
	hasQuestHere = found
	updateForcedState()
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
	self.frame:SetHeight(trackerHeight)
	self.frame:SetWidth(self.db.profile.wide and largeTracker or smallTracker)
end
	
function module:CVAR_UPDATE(event, cvar, value)
	if cvar == "WATCH_FRAME_WIDTH_TEXT" then
		if not(ObjectiveTrackerFrame.collapsed) and value == "1" then
			self.db.profile.wide = true
		else
			self.db.profile.wide = false
		end
		self:UpdateSize()
	end
end

function module:PLAYER_UPDATE_RESTING()
	isResting = IsResting()
	updateForcedState()
end

function module:PLAYER_ENTERING_WORLD()
	self:QUEST_ACCEPTED()
	self:CVAR_UPDATE()
	self:PLAYER_UPDATE_RESTING()
	updateHeader()
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
	LMP:NewChain(ObjectiveTrackerFrame.HeaderMenu.MinimizeButton) :SetSize(T.textures.expandcollapse:GetSize()) :ClearAllPoints() :SetPoint(T.textures.expandcollapse:GetPoint()) :SetNormalTexture(T.textures.expandcollapse:GetPath()) :SetPushedTexture(T.textures.expandcollapse:GetPath()) :SetHighlightTexture(T.textures.highlight and T.textures.highlight:GetPath() or "") :SetDisabledTexture(T.textures.disabled:GetPath()) :EndChain()
	hasTheme = true
	self:ApplySettings()
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings(settings)
	if not self.frame then return end
	self.frame.settings = self.db.profile
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

function module:HookTracker()
	LMP:NewChain(ObjectiveTrackerFrame) :SetParent(self.frame) :SetFrameStrata("LOW") :SetFrameLevel(3) :SetClampedToScreen(false) :ClearAllPoints() :SetPoint("TOPLEFT", self.frame, 0, 0) :SetPoint("BOTTOMRIGHT", self.frame, 0, 0) :EndChain()
	ObjectiveTrackerFrame.ClearAllPoints = function() end
	ObjectiveTrackerFrame.SetPoint = function() end
	
	-- searching through the BlocksFrame for headers based on children keys, 
	-- since some of the headers (like 'Objectives') neither have keys nor names.
	for i = 1, ObjectiveTrackerFrame.BlocksFrame:GetNumChildren() do
		local v = select(i, ObjectiveTrackerFrame.BlocksFrame:GetChildren())
		if type(v) == "table" then
			if v.Background then
				v.Background:SetTexture("")
				v.LineGlow:Hide()
				v.SoftGlow:Hide()
				v.LineSheen:Hide()	
			end
			if v.BottomShadow then
				v.BottomShadow:Hide()
				v.TopShadow:Hide()
			end
		end
	end
	
	hooksecurefunc("ObjectiveTracker_Expand", updateHeader) 	
	hooksecurefunc("ObjectiveTracker_Collapse", updateHeader) 
	
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")

	self:ApplySettings(self.db.profile)
end

function module:CollapseTracker()
	if self.TrackerMonitor.isUserCollapsed or self.TrackerMonitor.isBossCollapsed or self.TrackerMonitor.isUserShown then
    return
  end
	ObjectiveTracker_Collapse()
	ObjectiveTracker_Update()
  self.TrackerMonitor.isBossCollapsed = true
end

function module:ADDON_LOADED(_, addonName)
  if addonName == "Blizzard_ObjectiveTracker" then
    self:UnregisterEvent("ADDON_LOADED")
  end
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Tracker", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4ObjectivesTracker", UIParent)) :SetHeight(trackerHeight)  .__EndChain
	self.frame.overlay = gUI4:GlockThis(self.frame, L["Objectives"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "floaters")))
	self.frame.UpdatePosition = function(self) module:UpdatePosition() end
	self.frame.GetSettings = function() return self.db.profile end
	self.FadeManager = LMP:NewChain(gUI4:CreateFadeManager("Tracker")) :RegisterObject(self.frame) :ApplySettings({ enablePerilFade = false }) :Enable() .__EndChain
	
	self:HookTracker()
  
	self:RegisterChatCommand("setwidetracker", function()
		self.db.profile.wide = true
		self:UpdateSize()
	end)
	self:RegisterChatCommand("setnarrowtracker", function()
		self.db.profile.wide = false
		self:UpdateSize()
	end)
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_UPDATE_RESTING")
	self:RegisterEvent("QUEST_ACCEPTED")
	self:RegisterEvent("CVAR_UPDATE")

	self:RegisterEvent("QUEST_LOG_UPDATE", "QUEST_ACCEPTED")
	self:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED", "QUEST_ACCEPTED")
	self:RegisterEvent("QUEST_WATCH_LIST_CHANGED", "QUEST_ACCEPTED")
	self:RegisterEvent("QUEST_AUTOCOMPLETE", "QUEST_ACCEPTED")
	self:RegisterEvent("QUEST_ACCEPTED", "QUEST_ACCEPTED")	
	self:RegisterEvent("SUPER_TRACKED_QUEST_CHANGED", "QUEST_ACCEPTED")
	self:RegisterEvent("SCENARIO_UPDATE", "QUEST_ACCEPTED")
	self:RegisterEvent("SCENARIO_CRITERIA_UPDATE", "QUEST_ACCEPTED")
	self:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE", "QUEST_ACCEPTED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "QUEST_ACCEPTED")
	self:RegisterEvent("ZONE_CHANGED", "QUEST_ACCEPTED")
	self:RegisterEvent("QUEST_POI_UPDATE", "QUEST_ACCEPTED")
	self:RegisterEvent("VARIABLES_LOADED", "QUEST_ACCEPTED")
	self:RegisterEvent("QUEST_TURNED_IN", "QUEST_ACCEPTED")
	-- self:RegisterEvent("PLAYER_MONEY", "QUEST_ACCEPTED")
end

function module:OnDisable()
end

