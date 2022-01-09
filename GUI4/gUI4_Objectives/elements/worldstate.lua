local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local module = parent:NewModule("WorldState", "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local LibWin = GP_LibStub("GP_LibWindow-1.1")
local T, hasTheme

-- Lua API
local tonumber, tostring = tonumber, tostring
local unpack, pairs = unpack, pairs
local floor = math.floor

-- WoW API
local GetNumWorldStateUI = GetNumWorldStateUI
local GetWorldStateUIInfo = GetWorldStateUIInfo
local UnitAffectingCombat = UnitAffectingCombat

local uiInfo, timerInfo = {}, {}
local activeUIs, activeTimers = {}, {}
local icons = { -- todo: add the objectives icon used in Ashran!
	[ [[Interface\TargetingFrame\UI-PVP-Horde]] ] = "horde",
	[ [[Interface\WorldStateScore\HordeIcon]] ] = "horde",
	[ [[Interface\WorldStateFrame\HordeTower]] ] = "hordetower",
	[ [[Interface\WorldStateFrame\HordeFlag]] ] = "hordeflag",
	[ [[Interface\WorldStateScore\ColumnIcon-FlagCapture1]] ] = "hordeflag",
	[ [[Interface\WorldStateScore\ColumnIcon-FlagReturn0]] ] = "hordeflag",
	[ [[Interface\TargetingFrame\UI-PVP-Alliance]] ] = "alliance", 
	[ [[Interface\WorldStateScore\AllianceIcon]] ] = "alliance",
	[ [[Interface\WorldStateFrame\AllianceTower]] ] = "alliancetower",
	[ [[Interface\WorldStateFrame\AllianceFlag]] ] = "allianceflag",
	[ [[Interface\WorldStateScore\ColumnIcon-FlagCapture0]] ] = "allianceflag",
	[ [[Interface\WorldStateScore\ColumnIcon-FlagReturn1]] ] = "allianceflag",
	[ [[Interface\WorldStateFrame\NeutralTower]] ] = "neutraltower"
}

local defaults = {
	profile = {
		locked = true,
		position = {}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().worldstate
end

local DAY, HOUR, MINUTE = 86400, 3600, 60
local function formatTime(value)
	if value < 0 then 
		value = 0
	end
	return ("%02d:%02d"):format(floor(value / MINUTE), value%MINUTE)
end

local function getIconData(path)
	local tex = T.textures[icons[path]]
	local w, h = tex:GetTexSize()
	local y = (h-(T.height or h))/2
	-- if T.height then
		-- h = T.height
	-- end
	return tex, w, h, y
end

local function place(object, ...)
	object:ClearAllPoints()
	object:SetPoint(...)
end

------------------------------------------------------------------------
-- UI Template
------------------------------------------------------------------------
local WorldStateUI = CreateFrame("Frame", nil, WorldFrame)
local WorldStateUI_MT = { __index = WorldStateUI }

-- using the template frame to handle all timers, as its always visible
WorldStateUI.elapsed = 0
WorldStateUI:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed > 0.1 then
		local reposition
		for timerIndex = #timerInfo, 1, -1 do
			-- update time left
			local timer = timerInfo[timerIndex]
			timer.timeLeft = timer.timeEnding - GetTime()

			-- cancel timers that have ran out
			if timer.timeLeft < 0 then
				tremove(timerInfo, timerIndex) -- pull the timer out of the info table
				timer.timeLeft = 0
				activeTimers[timer.msg].enabled = false
				if timer.ui then
					timer.ui:Clear()
				end
				reposition = true
			end
			
			-- update the text of active timers
			if activeTimers[timer.msg].enabled then
				if timer.ui then
					timer.ui.text:SetText(timer.msg .. formatTime(floor(timer.timeLeft)))
				end
			end

		end
		if reposition then
			module:UpdateUIPositions()
		end
		self.elapsed = 0
	end
end)

function WorldStateUI:OnEnter()
	if self.tooltip then
		if (not GameTooltip:IsForbidden()) then
			LMP:PlaceTip(self)
			GameTooltip:AddLine(self.tooltip, 0, 1, 0)
			GameTooltip:Show()
		end
	end
end

function WorldStateUI:OnLeave()
	if (not GameTooltip:IsForbidden()) then	
		GameTooltip:Hide()
	end
end

function WorldStateUI:EnableMouseScripts()
	self:EnableMouse(true)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
end

function WorldStateUI:DisableMouseScripts()
	self:EnableMouse(false)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
end

function WorldStateUI:SetType(uiType)
	self.uiType = uiType
end

function WorldStateUI:GetType()
	return self.uiType
end

function WorldStateUI:SetIcon(iconType, path, reset)
	if reset or path == "" or not path then
		self[iconType]:SetSize(32, 32)
		self[iconType]:SetTexture(path)
		self[iconType]:SetTexCoord(0, 1, 0, 1)
	else
		local tex, w, h, y = getIconData(path)
		self[iconType]:SetSize(w, h)
		self[iconType]:SetTexture(tex:GetPath())
		self[iconType]:SetTexCoord(tex:GetTexCoord())
	end
end

function WorldStateUI:Clear()
	updateConfig()
	self:Hide()
	self:SetSize(32, T.height or 32)
	self:SetHitRectInsets(0, 0, 0, 0)
	self:SetIcon("icon", "")
	self:SetIcon("dynamicIcon", "")
	self.holder:StopFlash()
	self.dynamicIcon:Hide()
	self.uiType = nil
	self.infoTable = nil
	self.tooltip = nil
	self.enabled = nil
	place(self.icon, "TOPLEFT", 0, 0)
	place(self.text, "LEFT", 32, 0)
end

function module:GetUI(uiIndex)
	if uiIndex > self:GetNumUIs() then
		local new = LMP:NewChain(setmetatable(CreateFrame("Frame", nil, self.frame), WorldStateUI_MT)) :EnableMouseScripts() .__EndChain
		-- local new = LMP:NewChain(CreateFrame("Frame", nil, self.frame)) :SetSize(32, 32) :EnableMouse(true) :SetScript("OnEnter", onEnter) :SetScript("OnLeave", onLeave) .__EndChain
		new.icon = LMP:NewChain(new:CreateTexture()) :SetSize(32, 32) :SetPoint("TOPLEFT") .__EndChain
		new.text = LMP:NewChain("FontString", nil, new) :SetPoint("LEFT", 32, 0) :SetFontObject(GameFontNormalSmall) :SetTextColor(.8, .8, .8) :SetFontStyle(nil) :SetShadowColor(0, 0, 0, 1) :SetShadowOffset(.75, -.75) .__EndChain
		new.holder = LMP:NewChain(CreateFrame("Frame", nil, self.frame)) :SetAllPoints() .__EndChain
		new.dynamicIcon = LMP:NewChain(new.holder:CreateTexture()) :SetSize(32, 32) :SetPoint("TOPLEFT", new.text, "TOPRIGHT", 10, 0) .__EndChain
		gUI4:ApplyFadersToFrame(new.holder)
		if not self.uis then
			self.uis = {}
		end
		tinsert(self.uis, new)
		self.numTotalUIs = #self.uis
		return new
	else
		return self.uis[uiIndex]
	end
end

function module:GetNumUIs()
	return self.numTotalUIs or 0
end

function module:GetNumActiveUIs()
	return self.numActiveUIs or -1
end

function module:UpdateUIPositions()
	if not self.numTotalUIs then return end
	updateConfig()
	local height = 0
	
	-- hide all redundant uis, if any
	for i = 1, self:GetNumUIs() do
		local ui = self:GetUI(i)
		if not ui.enabled then
			ui:Clear()
		end
	end
	
	-- sort and display the info UIs
	local currentPosition = 0
	for i = 1, self.numInfoUIs do 
		if uiInfo[i] then
			currentPosition = currentPosition + 1
			local ui = uiInfo[i].ui
			ui:ClearAllPoints()
			if i == 1 then
				ui:SetPoint("TOPLEFT")
			else
				ui:SetPoint("TOPLEFT", uiInfo[i-1].ui, "BOTTOMLEFT", 0, -4)
			end
			height = height + (ui.height or 32)
			ui:Show()
		end
	end
	
	-- sort and display the timer UIs
	for i = 1, self.numTimerUIs do 
		if timerInfo[i] then
			currentPosition = currentPosition + 1
			local ui = timerInfo[i].ui
			ui:ClearAllPoints()
			if currentPosition == 1 then -- this is the first ui
				ui:SetPoint("TOPLEFT") 
			elseif i == 1 then -- this is the first timer ui, but there are info uis prior to it
				ui:SetPoint("TOPLEFT", uiInfo[self.numInfoUIs].ui, "BOTTOMLEFT", 0, -4) 
			else -- not the first timer ui
				ui:SetPoint("TOPLEFT", timerInfo[i-1].ui, "BOTTOMLEFT", 0, -4)
			end
			height = height + (ui.height or 32)
			ui:Show()
		end
	end
	
	-- update master visibility
	if currentPosition == 0 then
		if self.frame:IsShown() then
			self.frame:Hide()
		end
		self.height = 10
	else
		if not self.frame:IsShown() then
			self.frame:Show()
		end
		self.height = height + 10
	end
	
	if self.db.profile.locked then
		for message, justify in pairs(T.positionMessagesToFire) do
			gUI4:SetOffset(message, self.frame, self.height + 20, justify)
		end
	end	
end

function module:UpdateStates()
	updateConfig()

	local numBlizzardUI = GetNumWorldStateUI() or 0
	local uiIndex, infoIndex, timerIndex = 0, 0, 0
	local height = 0
	
	-- halt all timers until new data has been processed
	for msg, info in pairs(activeTimers) do
		info.ui = nil
		info.enabled = false
	end
	
	-- disable all uis until new data has been processed
	for i = 1, self:GetNumUIs() do
		self:GetUI(i).enabled = false
	end
	
	wipe(timerInfo)
	wipe(uiInfo)
	
	for blizzardID = 1, numBlizzardUI do
		-- retrieve info about this specific blizzardUI
		local uiType, state, hidden, text, icon, dynamicIcon, tooltip, dynamicTooltip, extendedUI, extendedUIState1, extendedUIState2, extendedUIState3 = GetWorldStateUIInfo(blizzardID)
		if state > 0 and extendedUI == "" and text ~= nil and not hidden then
			uiIndex = uiIndex + 1 -- increase the ui counter

			local ui = self:GetUI(uiIndex) -- get or create a custom ui
			ui.blizzardID = blizzardID -- store blizzards id here
			ui.height = T.height or 32
			
			-- figure out what kind of UI this is
			local mins, secs = text:match("(%d+):(%d+)") -- we assume only 1 time value will be listed in any single ui
			if mins and secs then
				ui.uiType = "timer"
				timerIndex = timerIndex + 1 -- increase the timer ui counter

				ui:SetSize(32, T.height or 32)
				ui:SetHitRectInsets(0, 0, 0, 0)
				height = height + (T.height or 32)
				-- ui:SetIcon("icon", icon, true)
				ui:SetIcon("icon", "", true) -- only show icons we have customs for
				place(ui.icon, "TOPLEFT", 0, 0)
				place(ui.text, "LEFT", 32, 0)
				ui.tooltip = tooltip

				-- calculate actual seconds remaining and grab blizzards msg here
				local seconds = floor((mins and tonumber(mins)*60 or 0) + tonumber(secs))
				local msg = text:gsub("(%d+):(%d+)", "") 

				-- feed the timer into our timer table
				if not timerInfo[timerIndex] then
					timerInfo[timerIndex] = {}
				end
				timerInfo[timerIndex].ui = ui
				timerInfo[timerIndex].msg = msg
				timerInfo[timerIndex].timeLeft = seconds
				timerInfo[timerIndex].timeEnding = GetTime() + seconds
				
				-- feed the timer into our active timers listing
				if not activeTimers[msg] then
					activeTimers[msg] = {}
				end
				activeTimers[msg].ui = ui
				activeTimers[msg].enabled = true 
				
				-- give the ui references to its tables
				ui.infoTable = timerInfo[timerIndex]
			else
				ui.uiType = "info"
				infoIndex = infoIndex + 1 -- increase the info ui counter
				
				-- feed the timer into our info table
				if not uiInfo[infoIndex] then
					uiInfo[infoIndex] = {}
				end
				uiInfo[infoIndex].ui = ui
				uiInfo[infoIndex].msg = text
				
				ui.text:SetText(text)
				
				if icon and icons[icon] then
					local tex, w, h, y = getIconData(icon)
					ui:SetSize(w, T.height or h)
					height = height + T.height
					if T.hitrects then
						ui:SetHitRectInsets(unpack(T.hitrects))
					else
						ui:SetHitRectInsets(0, 0, 0, 0)
					end
					ui:SetIcon("icon", icon)
					place(ui.icon, "TOPLEFT", 0, y)
					place(ui.text, "LEFT", w, 0)
					ui.tooltip = tooltip
				else
					ui:SetSize(32, T.height or 32)
					ui:SetHitRectInsets(0, 0, 0, 0)
					height = height + (T.height or 32)
					-- ui:SetIcon("icon", icon, true)
					ui:SetIcon("icon", "", true) -- only show icons we have customs for
					place(ui.icon, "TOPLEFT", 0, 0)
					place(ui.text, "LEFT", 32, 0)
					ui.tooltip = nil
				end
				if dynamicIcon then
					if icons[dynamicIcon] then
						ui:SetIcon("dynamicIcon", dynamicIcon)
						ui.dynamicIcon:ClearAllPoints()
						ui.dynamicIcon:SetPoint("TOP", ui.icon, "TOP", 0, 0)
						ui.dynamicIcon:SetPoint("LEFT", ui.text, "RIGHT", 0, 0)
					else
						ui:SetIcon("dynamicIcon", dynamicIcon, true)
						place(ui.dynamicIcon, "TOPLEFT", ui.text, "TOPRIGHT", 0, 0)
					end
					if state == 2 then
						ui.holder:StartFlash(.5, .5, .5, 1, true)
						ui.dynamicIcon:Show()
					elseif state == 3 then
						ui.holder:StopFlash()
						ui.dynamicIcon:Show()
					else
						ui.holder:StopFlash()
						ui.dynamicIcon:Hide()
					end
				else
					ui:SetIcon("dynamicIcon", "")
					ui.holder:StopFlash()
					ui.dynamicIcon:Hide()
				end	
				
				-- give the ui references to its tables
				ui.infoTable = uiInfo[infoIndex]
				
			end	
			ui.enabled = true
		end	
	end

	self.height = height
	self.numActiveUIs = uiIndex
	self.numInfoUIs = infoIndex
	self.numTimerUIs = timerIndex

	self:UpdateUIPositions()
end

function module:Clear()
	self.frame:Hide()
	for i = 1, self:GetNumUIs() do
		self:GetUI(i):Clear()
	end
	if self.db.profile.locked then
		for message, justify in pairs(T.positionMessagesToFire) do
			gUI4:SetOffset(message, self.frame, 20, justify)
		end
	end
end

local first
function module:OnEvent(event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		self:Clear() 
	end
	self:UpdateStates()
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
	self.frame:SetSize(unpack(T.size))
	self:UpdateStates()
	hasTheme = true
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
	if not hasTheme then return end
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
-- module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:DisableBlizzard()
	LMP:NewChain(WorldStateAlwaysUpFrame) :SetParent(LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :Hide() .__EndChain) :Hide() :SetScript("OnEvent", nil) :SetScript("OnUpdate", nil) :UnregisterAllEvents() :EndChain()
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("WorldState", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self:DisableBlizzard()
	
	self.frame = LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :Hide() :SetMovable(true) :SetSize(32, 32) .__EndChain
	self.frame.overlay = gUI4:GlockThis(self.frame, L["World Score"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "floaters")))
	self.frame.UpdatePosition = function() self:UpdatePosition() end
	self.frame.GetSettings = function() return self.db.profile end
	
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")

	self:ApplySettings()
end

function module:OnEnable()
	self:RegisterEvent("UPDATE_WORLD_STATES", "OnEvent")
	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "OnEvent")
	self:RegisterEvent("BATTLEGROUND_POINTS_UPDATE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")

	self:UpdateStates() -- needed?
end

function module:OnDisable()
	self:UnregisterEvent("UPDATE_WORLD_STATES", "OnEvent")
	self:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE", "OnEvent")
	self:UnregisterEvent("BATTLEGROUND_POINTS_UPDATE", "OnEvent")
	self:UnregisterEvent("PLAYER_ENTERING_BATTLEGROUND", "OnEvent")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:UnregisterEvent("ZONE_CHANGED", "OnEvent")
	self:UnregisterEvent("ZONE_CHANGED_INDOORS", "OnEvent")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
end

