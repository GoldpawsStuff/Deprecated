local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local module = parent:NewModule("CaptureBar", "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local LibWin = GP_LibStub("GP_LibWindow-1.1")
local T, hasTheme

-- Lua API
local tostring = tostring
local tinsert = table.insert
local unpack, ipairs, pairs = unpack, ipairs, pairs

-- WoW API
local GetNumWorldStateUI = GetNumWorldStateUI
local GetWorldStateUIInfo = GetWorldStateUIInfo
local UnitAffectingCombat = UnitAffectingCombat

local CaptureBar = parent.CaptureBar
local CaptureBar_MT = { __index = CaptureBar }

local captureBars, visibleCaptureBars = {}, {}

local defaults = {
	profile = {
		locked = true,
		position = {}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().capturebar
end

local function getID(id)
	if type(id) == "number" then
		return "BlizzardCaptureBar"..id -- let's avoid pure numbers as id, and go with unique strings for future compability
	else
		return id
	end
end

-- this is a theme styling function for a single bar, called when the bar is made, and on theme updates
function module:UpdateBarTheme(barOrID)
	updateConfig()
	local bar
	if type(barOrID) == "string" or type(barOrID) == "number" then
		bar = self:GetCaptureBar(barOrID)
	else
		bar = barOrID
	end

	LMP:NewChain(bar) :SetSize(unpack(T.size)) :EndChain()
	
	LMP:NewChain(bar.backdrop) :SetTexture(T.textures.backdrop:GetPath()) :SetSize(T.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.backdrop:GetPoint()) :EndChain()
	LMP:NewChain(bar.border) :SetTexture(T.textures.overlay:GetPath()) :SetSize(T.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.overlay:GetPoint()) :EndChain()
	
	LMP:NewChain(bar.bar) :SetSize(unpack(T.bar.size)) :ClearAllPoints() :SetPoint(unpack(T.bar.place)) :SetStatusBarTexture(0,0,0,0) :EndChain()
	LMP:NewChain(bar.left) :SetTexture(T.bar.textures.normal:GetPath()) :SetVertexColor(unpack(gUI4:GetColors("faction", "Alliance"))) :EndChain()
	LMP:NewChain(bar.middle) :SetTexture(T.bar.textures.normal:GetPath()) :SetVertexColor(1,1,.7) :EndChain()
	LMP:NewChain(bar.right) :SetTexture(T.bar.textures.normal:GetPath()) :SetVertexColor(unpack(gUI4:GetColors("faction", "Horde"))) :EndChain()
	LMP:NewChain(bar.overlay) :SetTexture(T.bar.textures.overlay:GetPath()) :EndChain()

	LMP:NewChain(bar.spark) :SetSize(T.spark.texture:GetTexSize(), bar.bar:GetHeight()) :SetTexture(T.spark.texture:GetPath()) :SetAlpha(T.spark.alpha) :ClearAllPoints() :SetPoint(T.spark.texture:GetPoint(), bar.bar:GetStatusBarTexture(), T.spark.texture:GetPoint()) :EndChain()

	LMP:NewChain(bar.left.indicator) :SetSize(8, 15) :SetTexture([[Interface\WorldStateFrame\WorldState-CaptureBar]]) :SetTexCoord(186/256, 193/256, 9/64, 23/64) :ClearAllPoints() :SetPoint("RIGHT", bar.spark, "LEFT", 1, 0) :EndChain()
	LMP:NewChain(bar.right.indicator) :SetSize(8, 15) :SetTexture([[Interface\WorldStateFrame\WorldState-CaptureBar]]) :SetTexCoord(193/256, 186/256, 9/64, 23/64) :ClearAllPoints() :SetPoint("LEFT", bar.spark, "RIGHT", -1, 0) :EndChain()

	LMP:NewChain(bar.left.icon) :SetTexture() :EndChain()
	LMP:NewChain(bar.right.icon) :SetTexture() :EndChain()
end

function module:New(id, settingsFunc)
	local bar = CaptureBar:New(tostring(id), nil, settingsFunc)
	bar.shine = gUI4:ApplyShine(bar, .5, .75, 2)
	bar:HookScript("OnShow", function(self) self.shine:Start() end)
	tinsert(captureBars, bar)
	self:UpdateBarTheme(bar)
	return bar
end

function module:GetCaptureBar(id)
	local bar
	for i,v in ipairs(captureBars) do
		if v.id == id then
			bar = v
			break
		end
	end
	if not bar then
		bar = self:New(id)
	end
	return bar
end

function module:UpdateCaptureBar(id, value, neutralpercent, min, max)
	local bar = self:GetCaptureBar(id) -- retrieve or create a bar
	bar:SetNeutralPercent(neutralpercent)
	bar:SetMinMaxValues(min, max)
	bar:SetValue(value)
	if not bar:IsShown() then
		bar:Show()
	end
	-- print(bar:IsShown(), value, min, max, bar:GetPoint())
end

function module:Clear()
	-- self.frame:Hide()
	for i,bar in ipairs(captureBars) do
		bar:Hide()
	end
end

function module:UpdateStates()
	updateConfig()
	local numBlizzardUI = GetNumWorldStateUI() or 0
	local extendedUIShown = 0 
	
	-- temporarily set all bar visibility statuses to hidden
	for id in pairs(visibleCaptureBars) do
		visibleCaptureBars[id] = false
	end
	
	for i = 1, numBlizzardUI do
		local uiType, state, hidden, text, icon, dynamicIcon, tooltip, dynamicTooltip, extendedUI, extendedUIState1, extendedUIState2, extendedUIState3 = GetWorldStateUIInfo(i)
		if state > 0 and extendedUI == "CAPTUREPOINT" and not hidden then
			extendedUIShown = extendedUIShown + 1
			visibleCaptureBars[getID(extendedUIState3)] = true -- set the bar's status to visible
			self:UpdateCaptureBar(getID(extendedUIState3), 100 - extendedUIState1, extendedUIState2, 0, 100) 
			-- print(extendedUIState3, extendedUIState1, extendedUIState2, i) -- bar id (always 0?), current pos (100 = left), neutral percent
		end
	end

	-- position bars
	-- we only have a single bar currently in WoW, but our system supports multiple, and thus we need to realign them on worldstate updates
	local previous
	for i,bar in ipairs(captureBars) do
		if visibleCaptureBars[bar.id] then
			bar:ClearAllPoints()
			if previous then 
				bar:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
			else
				bar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
			end
			previous = bar
		end
	end

	-- hide unused bars
	for i,bar in ipairs(captureBars) do
		if not visibleCaptureBars[bar.id] then
			bar:Hide()
		end
	end

end

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
	if not hasTheme then return end
	if not self.frame then return end
	updateConfig()
	local db = self.db.profile
	db.position.point = nil
	db.position.y = nil
	db.position.x = nil
	db.locked = true
	wipe(db.position)
	self:ApplySettings()
end

local positionCallbacks = {}
function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	if not self.frame then return end
	updateConfig()
	-- for callback in pairs(positionCallbacks) do
		-- self:UnregisterMessage(callback, "UpdatePosition")
	-- end
	wipe(positionCallbacks)
	-- for callback in pairs(T.positionCallbacks) do
		-- positionCallbacks[callback] = true
	-- end
	-- for callback in pairs(positionCallbacks) do
		-- self:RegisterMessage(callback, "UpdatePosition")
	-- end
	self.frame:SetSize(unpack(T.size))
	for i,bar in ipairs(captureBars) do
		self:UpdateBarTheme(bar)
	end
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
	local db = self.db.profile
	if db.locked then
		LMP:Place(self.frame, T.place)
		if not db.position.x then
			self.frame:RegisterConfig(db.position)
			self.frame:SavePosition()
		end
	else
		self.frame:RegisterConfig(db.position)
		if db.position.x then
			self.frame:LoadPosition()
		else
			LMP:Place(self.frame, T.place)
			self.frame:SavePosition()
			self.frame:LoadPosition()
		end
	end
end
-- module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("CaptureBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self.frame = LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :Hide() :SetMovable(true) :SetSize(32, 32) .__EndChain
	-- self.frame:SetScript("OnUpdate", RequestBattlefieldScoreData)
	self.frame.GetSettings = function() return self.db.profile end
	self.frame.overlay = gUI4:GlockThis(self.frame, L["Capture Bar"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "floaters")))
	self.frame.UpdatePosition = function() self:UpdatePosition() end
	
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

