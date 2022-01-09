local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("ReputationBar", "GP_AceEvent-3.0", "GP_AceConsole-3.0")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local path = [[Interface\AddOns\]]..addon..[[\media\]]
local C = gUI4:GetColors()

local Scaffold = parent.Scaffold
local ReputationBar = setmetatable({}, { __index = Scaffold })
parent.ReputationBar = ReputationBar

-- Lua API
local floor, min = math.floor, math.min
local tonumber, tostring = tonumber, tostring
local unpack = unpack

-- WoW API
local GameTooltip = GameTooltip
local UnitAffectingCombat = UnitAffectingCombat

local T, hasTheme, skinSize

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		position = {},
		alpha = 1,
		visibility = {},
		position = {}
	}
}

---------------------------------------------------------------------------------------------------------------------
-- Local Functions
---------------------------------------------------------------------------------------------------------------------
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
	T = parent:GetActiveTheme().rep[skinSize] -- figure out what backdrop to use based on main actionbar size
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

function ReputationBar:UpdateTheme()
	updateConfig()
	self:SetSize(unpack(T.size))
	LMP:NewChain(self.bar) :SetSize(unpack(T.statusbar.size)) :SetHitRectInsets(unpack(T.statusbar.hitrectinsets)) :ClearAllPoints() :SetPoint(unpack(T.statusbar.place)) :SetStatusBarTexture(T.statusbar.texture:GetPath()) :SetBackdropTexture(T.statusbar.texture:GetPath()) :EndChain()
	LMP:NewChain(self.bar.spark) :SetSize(unpack(T.statusbar.spark.size)) :ClearAllPoints() :SetPoint(T.statusbar.spark.texture:GetPoint(), self.bar:GetStatusBarTexture(), T.statusbar.spark.texture:GetPoint()) :SetTexture(T.statusbar.spark.texture:GetPath()) :EndChain()
	-- LMP:NewChain(self.glow) :SetVertexColor(unpack(T.textures.glow:GetColor())) :SetTexture(T.textures.glow:GetPath()) :SetSize(T.textures.glow:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.glow:GetPoint()) :EndChain()
	-- LMP:NewChain(self.backdrop) :SetVertexColor(unpack(T.textures.backdrop:GetColor())) :SetTexture(T.textures.backdrop:GetPath()) :SetSize(T.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.backdrop:GetPoint()) :EndChain()
	-- LMP:NewChain(self.notches) :SetVertexColor(unpack(T.textures.notches:GetColor())) :SetTexture(T.textures.notches:GetPath()) :SetSize(T.textures.notches:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.notches:GetPoint()) :EndChain()
	-- LMP:NewChain(self.normal) :SetVertexColor(unpack(T.textures.normal:GetColor())) :SetTexture(T.textures.normal:GetPath()) :SetSize(T.textures.normal:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.normal:GetPoint()) :EndChain()
	-- LMP:NewChain(self.highlight) :SetVertexColor(unpack(T.textures.highlight:GetColor())) :SetTexture(T.textures.highlight:GetPath()) :SetSize(T.textures.highlight:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.highlight:GetPoint()) :EndChain()
	-- LMP:NewChain(self.overlay) :SetVertexColor(unpack(T.textures.overlay:GetColor())) :SetTexture(T.textures.overlay:GetPath()) :SetSize(T.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(T.textures.overlay:GetPoint()) :EndChain()
end

local function wrap(str, limit, indent, indent1)
	if not str then return end
	indent = indent or ""
	indent1 = indent1 or indent
	limit = limit or 35
	local here = 1-#indent1
	return indent1..str:gsub("(%s+)()(%S+)()",
	function(sp, st, word, fi)
		if fi-here > limit then
			here = st - #indent
			return "\n"..indent..word
		end
	end)
end

function ReputationBar:UpdateData()
	local RPName, RPStanding, RPMin, RPMax, RPValue, factionID = GetWatchedFactionInfo()
	if RPName then
		local RPStandingName, isCapped, RPColor
		local gender = UnitSex("player")  
		-- check if this is a friendship faction 
		local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
    if RPStanding == 0 then 
      RPStanding = 8
    end
		if friendID ~= nil then
			local currentRank, maxRank = GetFriendshipReputationRanks(factionID)
			-- RPStanding = currentRank
			RPStandingName = friendTextLevel
			RPName = friendName
			if nextFriendThreshold then
				RPMin, RPMax, RPValue = friendThreshold, nextFriendThreshold, friendRep
			else
				-- max rank, make it look like a full bar
				RPMin, RPMax, RPValue = 0, 1, 1
				isCapped = true
			end
			RPColor = C.friendship[RPStanding]
		else
			friendID = nil
			isCapped = RPMax == 43000 and RPValue == 42999
			RPStandingName = GetText("FACTION_STANDING_LABEL"..RPStanding, gender)
			RPColor = C.reaction[RPStanding]
		end

		self.data.color = RPColor
		self.data.name = RPName
		self.data.isCapped = isCapped
		self.data.friendID = friendID
		self.data.friendText = friendText
		self.data.standingID = RPStanding
		self.data.standingName = RPStandingName
		self.data.repMin = RPMin
		self.data.repMax = RPMax
		self.data.repValue = RPValue
		self.data.barMax = isCapped and (RPValue - RPMin) or (RPMax - RPMin)
		self.data.barValue = RPValue - RPMin
	else
		wipe(self.data)
	end
	return self.data
end

local shortRepString = "%s%%"
local standingString = "%s - %s"
local longRepString = "%s / %s"
local fullRepString = "%s / %s - %s%%"

function ReputationBar:UpdateBar()
	local data = self:UpdateData()
	if not data.name then return end
	self.bar:SetStatusBarColor(unpack(data.color))
	self.bar:SetMinMaxValues(0, data.barMax)
	self.bar:SetValue(data.barValue)
	if self.mouseIsOver and not data.isCapped then
		self.text:SetFormattedText(fullRepString, colorize(short(data.barValue), "normal"), colorize(short(data.barMax), "normal"), colorize(short(floor(data.barValue/data.barMax*100)), "normal"))
	else
		self.text:SetFormattedText(shortRepString, colorize(short(floor(data.barValue/data.barMax*100)), "normal"))
	end
end

local enabled
function ReputationBar:UpdateVisibility()
	local data = self:UpdateData()
	module.db.profile.enabled = not not data.name
	if enabled ~= module.db.profile.enabled then
		if module.db.profile.enabled then
			module:SendMessage("GUI4_REPUTATIONBAR_ENABLED")
			if module.db.profile.locked then
				T.setOffset(self, "Reputation", skinSize)
			end
		else
			T.setOffset(self, "Reputation", nil)
			module:SendMessage("GUI4_REPUTATIONBAR_DISABLED")
		end
		enabled = module.db.profile.enabled
	end
	Scaffold.ApplySettings(self, module.db.profile)
end
ReputationBar.UpdateVisibility = gUI4:SafeCallWrapper(ReputationBar.UpdateVisibility) -- we level up in combat, so we need to queue these visibility events

function ReputationBar:UpdatePosition()
	if not hasTheme then return end
	if module.db.profile.enabled and module.db.profile.locked then
		T.setOffset(self, "Reputation", skinSize)
		self:ClearAllPoints()
		self:SetPoint(T.place("Reputation", skinSize))
		if not module.db.profile.position.x then
			self:RegisterConfig(module.db.profile.position)
			self:SavePosition()
		end
	else
		T.setOffset(self, "Reputation", nil)
		self:RegisterConfig(module.db.profile.position)
		if module.db.profile.position.x then
			self:LoadPosition()
		else
			self:ClearAllPoints()
			self:SetPoint(T.place("Reputation", skinSize))
			self:SavePosition()
			self:LoadPosition()
		end
	end	
end
ReputationBar.UpdatePosition = gUI4:SafeCallWrapper(ReputationBar.UpdatePosition) 

function ReputationBar:ApplySettings(event, arg)
	self:UpdateVisibility()
	self:UpdatePosition()
	Scaffold.ApplySettings(self, module.db.profile)
end
ReputationBar.ApplySettings = gUI4:SafeCallWrapper(ReputationBar.ApplySettings)

function ReputationBar:OnEvent(event, arg1)
	self:UpdateBar()
end

function ReputationBar:OnClick(button)
	if button == "LeftButton" then
		if ReputationFrame:IsShown() then 
			ToggleCharacter("ReputationFrame")
		else
			ToggleCharacter("ReputationFrame", true)
		end
		local RPName, RPStanding, RPMin, RPMax, RPValue = GetWatchedFactionInfo()
		if RPName then
			local faction
			local numFactions = GetNumFactions()
			if numFactions then
				ExpandAllFactionHeaders()
				for i = 1, numFactions do
					local name, description = GetFactionInfo(i)
					if RPName == name then
						faction = i
						break
					end
				end
				if faction then
					local found
					local offset, maxoffset = 0, (numFactions - NUM_FACTIONS_DISPLAYED)
					while offset and not(found) do
						ReputationListScrollFrameScrollBar:SetValue(offset * REPUTATIONFRAME_FACTIONHEIGHT) -- scroll the frame
						ReputationFrame_Update() -- update the rep frame with the new bars
						for i = offset + 1, math.min(offset + NUM_FACTIONS_DISPLAYED, numFactions) do
							if _G["ReputationBar"..(i - offset)].index == faction then
								found = true
								SetSelectedFaction(i - offset) -- select the correct row
								ReputationBar_OnClick(_G["ReputationBar"..i - offset]) -- fake a click on the row
								ReputationFrame_Update() -- update the frames 
								break -- break this loop, we found what we wanted
							end
						end
						if offset + NUM_FACTIONS_DISPLAYED >= numFactions then
							offset = nil -- we've seen all factions, so terminate this loop
						else 
							offset = offset + NUM_FACTIONS_DISPLAYED -- keep going 
						end
					end
				end
			end
		end
	end
end

function ReputationBar:OnEnter()
	local data = self.frame:UpdateData()
	if not data.barMax then return end

	if (not GameTooltip:IsForbidden()) then
		-- if GetCVar("UberTooltips") == "1" then
			-- GameTooltip_SetDefaultAnchor(GameTooltip, self)
		-- else
			LMP:PlaceTip(self.frame, "BOTTOMLEFT")
		-- end	

		local r, g, b = unpack(C.chat.highlight)
		GameTooltip:AddDoubleLine(data.name, data.standingName, r, g, b, unpack(data.color))
		if data.isCapped then
			GameTooltip:AddLine(L["Maximum Reputation"], unpack(C.chat.offwhite))
		else
			local r, g, b = unpack(C.chat.offwhite)
			GameTooltip:AddDoubleLine(L["Current Reputation: "], longRepString:format(colorize(short(data.barValue), "normal"), colorize(short(data.barMax), "normal")), r, g, b, r, g, b)
		end
		GameTooltip:AddLine(" ")

		local numFactions = GetNumFactions()
		if numFactions then
			ExpandAllFactionHeaders() -- this will crash the client if called before we're well into the world (e.g. when we are able to hover over it)
			local msg
			for i = 1, numFactions do
				local name, description = GetFactionInfo(i)
				if data.name == name then
					msg = description
					break
				end
			end
			if msg then
				GameTooltip:AddLine(wrap(msg))
				GameTooltip:AddLine(" ")
			end
		end
		if data.friendText then
			GameTooltip:AddLine(wrap(data.friendText))
			GameTooltip:AddLine(" ")
		end
		GameTooltip:AddLine(L["<Left-Click to toggle Reputation pane>"], unpack(C.chat.offgreen))
		GameTooltip:Show()
	end
	self.frame.mouseIsOver = true
	self.frame:UpdateBar()
end

function ReputationBar:OnLeave()
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

function module:IsReputationBarVisible()
	return self.db.profile.enabled
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("ReputationBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()

	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	
	self:RegisterChatCommand("enablerep", function()
		self.db.profile.enabled = true
		self:UpdateVisibility()
		-- self:Enable()
	end)
	self:RegisterChatCommand("disablerep", function()
		self.db.profile.enabled = false
		self:UpdateVisibility()
		-- self:Disable()
	end)

end

function module:OnEnable()
	self.frame = LMP:NewChain(setmetatable(Scaffold:New("Reputation", L["Reputation Bar"], function() return self.db.profile end), { __index = ReputationBar })) :SetFrameStrata("LOW") .__EndChain
	parent:GetFadeManager():RegisterObject(self.frame)
	self.frame.data = {} -- table to store info
	self.frame.border = LMP:NewChain(CreateFrame("Frame", "GUI4_ReputationBarBorder", self.frame)) :SetAllPoints() :SetFrameStrata("MEDIUM") :SetFrameLevel(self.frame:GetFrameLevel() + 3) .__EndChain
	self.frame.bar = LMP:NewChain("StatusBar", "GUI4_ReputationBarStatusBar", self.frame) :SetFrameLevel(self.frame:GetFrameLevel() + 2) :EnableMouse(true) :SetScript("OnMouseUp", ReputationBar.OnClick) :SetScript("OnEnter", ReputationBar.OnEnter) :SetScript("OnLeave", ReputationBar.OnLeave) .__EndChain
	self.frame.bar.spark = LMP:NewChain(self.frame.bar:CreateTexture(nil, "ARTWORK")) :SetBlendMode("ADD") .__EndChain
	self.frame.bar.frame = self.frame
	self.frame.text = LMP:NewChain("FontString", nil, self.frame.border) :SetFontObject(TextStatusBarText) :SetFontSize(12) :SetFontStyle("THINOUTLINE") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY") :SetTextColor(unpack(C.chat.offwhite)) :SetPoint("CENTER", 0, 0) .__EndChain
	self.frame.glow = LMP:NewChain(self.frame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetVertexColor(0, 0, 0, 1) .__EndChain 
	self.frame.backdrop = LMP:NewChain(self.frame:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) .__EndChain 
	self.frame.notches = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain 
	self.frame.normal = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 2) .__EndChain 
	self.frame.overlay = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 3) :Hide() .__EndChain 
	self.frame.highlight = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 4) :SetBlendMode("BLEND") :Hide() .__EndChain 
	
	self.frame:SetScript("OnEvent", ReputationBar.OnEvent)
	self.frame:RegisterEvent("PLAYER_ALIVE")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.frame:RegisterEvent("PLAYER_LOGIN")
	self.frame:RegisterEvent("UPDATE_FACTION")

	gUI4:ApplySmoothing(self.frame.bar)

    -- This function updates both XP, Rep, Artifact and honor bars
	hooksecurefunc("MainMenuBar_UpdateExperienceBars", function() self:ApplySettings() end)

	self:RegisterMessage("GUI4_XPBAR_ENABLED", "ApplySettings")
	self:RegisterMessage("GUI4_XPBAR_DISABLED", "ApplySettings")
	self:RegisterMessage("GUI4_ARTIFACTBAR_ENABLED", "ApplySettings")
	self:RegisterMessage("GUI4_ARTIFACTBAR_DISABLED", "ApplySettings")
	
	self:ApplySettings()
end

function module:OnDisable()
end
