local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("ArtifactBar", "GP_AceEvent-3.0", "GP_AceConsole-3.0")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local path = [[Interface\AddOns\]]..addon..[[\media\]]
local C = gUI4:GetColors()

local Scaffold = parent.Scaffold
local ArtifactBar = setmetatable({}, { __index = Scaffold })
parent.ArtifactBar = ArtifactBar

-- Lua API
local floor, min = math.floor, math.min
local tonumber, tostring = tonumber, tostring
local unpack = unpack

-- WoW API
--  *changing some names here, since the new APIs are just stupid
local GameTooltip = GameTooltip
local GetArtifactArtInfo = C_ArtifactUI.GetArtifactArtInfo
local GetCostForPointAtRank = C_ArtifactUI.GetCostForPointAtRank
local GetEquippedArtifactInfo = C_ArtifactUI.GetEquippedArtifactInfo
local HasArtifactEquipped = HasArtifactEquipped
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

local function GetEquippedArtifactXP(pointsSpent, artifactXP, artifactTier)
	local numPoints = 0
	local xpForNextPoint = GetCostForPointAtRank(pointsSpent, artifactTier)
	while artifactXP >= xpForNextPoint and xpForNextPoint > 0 do
		artifactXP = artifactXP - xpForNextPoint;

		pointsSpent = pointsSpent + 1;
		numPoints = numPoints + 1;

		xpForNextPoint = GetCostForPointAtRank(pointsSpent, artifactTier)
	end
	return numPoints, artifactXP, xpForNextPoint
end

function ArtifactBar:UpdateTheme()
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

function ArtifactBar:UpdateData()

	local equipped = HasArtifactEquipped()
	if equipped then
		-- artifactTier argument added in 7.2.0. 
		local itemID, altItemID, name, icon, totalXP, usedPoints, quality, _, _, _, _, _, artifactTier = GetEquippedArtifactInfo()
		local unusedPoints, value, max = GetEquippedArtifactXP(usedPoints, totalXP, artifactTier)

		self.data.name = name
		self.data.rank = usedPoints
		self.data.equipped = HasArtifactEquipped()
		self.data.color = C.quality[quality-1]
		self.data.itemID = itemID
		self.data.totalXP = totalXP
		self.data.unusedPoints = unusedPoints
		self.data.barValue = value
		self.data.barMax = max
	else
		wipe(self.data)
	end

	return self.data
end

function ArtifactBar:UpdateBar()
	local data = self:UpdateData()
	if not data.name then return end
	self.bar:SetStatusBarColor(unpack(data.color))
	self.bar:SetMinMaxValues(0, data.barMax)
	self.bar:SetValue(data.barValue)
	if self.mouseIsOver then
		self.text:SetFormattedText(fullRepString, colorize(short(data.barValue), "normal"), colorize(short(data.barMax), "normal"), colorize(short(floor(data.barValue/data.barMax*100)), "normal"))
	else
		self.text:SetFormattedText(shortRepString, colorize(short(floor(data.barValue/data.barMax*100)), "normal"))
	end
end

local enabled
function ArtifactBar:UpdateVisibility()
	local data = self:UpdateData()
	local showXP = parent:IsXPBarVisible()
	module.db.profile.enabled = (not showXP) and data.equipped
	if enabled ~= module.db.profile.enabled then
		if module.db.profile.enabled then
            module:SendMessage("GUI4_ARTIFACTBAR_ENABLED")
            if module.db.profile.locked then
                T.setOffset(self, "Artifact", skinSize)
            end
		else
			T.setOffset(self, "Artifact", nil)
			module:SendMessage("GUI4_ARTIFACTBAR_DISABLED")
		end
		enabled = module.db.profile.enabled
	end
	Scaffold.ApplySettings(self, module.db.profile)
end
ArtifactBar.UpdateVisibility = gUI4:SafeCallWrapper(ArtifactBar.UpdateVisibility) -- we level up in combat, so we need to queue these visibility events

function ArtifactBar:UpdatePosition()
	if not hasTheme then return end
	if module.db.profile.enabled and module.db.profile.locked then
		T.setOffset(self, "Artifact", skinSize)
		self:ClearAllPoints()
		self:SetPoint(T.place("Artifact", skinSize))
		if not module.db.profile.position.x then
			self:RegisterConfig(module.db.profile.position)
			self:SavePosition()
		end
	else
		T.setOffset(self, "Artifact", nil)
		self:RegisterConfig(module.db.profile.position)
		if module.db.profile.position.x then
			self:LoadPosition()
		else
			self:ClearAllPoints()
			self:SetPoint(T.place("Artifact", skinSize))
			self:SavePosition()
			self:LoadPosition()
		end
	end	
end
ArtifactBar.UpdatePosition = gUI4:SafeCallWrapper(ArtifactBar.UpdatePosition) 

function ArtifactBar:ApplySettings(event, arg)
	self:UpdateVisibility()
	self:UpdatePosition()
	Scaffold.ApplySettings(self, module.db.profile)
end
ArtifactBar.ApplySettings = gUI4:SafeCallWrapper(ArtifactBar.ApplySettings)

function ArtifactBar:OnEvent(event, arg1)
	self:UpdateBar()
end

function ArtifactBar:OnClick(button)
	if button == "LeftButton" then
		if ArtifactFrame and ArtifactFrame:IsShown() then 
			HideUIPanel(ArtifactFrame)
		else
			SocketInventoryItem(16)
		end
	end
end

function ArtifactBar:OnEnter()
	local data = self.frame:UpdateData()
	if not data.barMax then return end

	if (not GameTooltip:IsForbidden()) then
		LMP:PlaceTip(self.frame, "BOTTOMLEFT")

		local textureKit, titleName, titleR, titleG, titleB, barConnectedR, barConnectedG, barConnectedB, barDisconnectedR, barDisconnectedG, barDisconnectedB = GetArtifactArtInfo()

		--GameTooltip:AddLine(ARTIFACTS_NUM_PURCHASED_RANKS:format(C_ArtifactUI.GetTotalPurchasedRanks()), HIGHLIGHT_FONT_COLOR:GetRGB());

		local r, g, b = unpack(C.chat.highlight)
		local nameR, nameG, nameB = unpack(data.color)
		GameTooltip:AddDoubleLine(data.name, data.rank, nameR, nameG, nameB, r, g, b)

		local r, g, b = unpack(C.chat.offwhite)
		GameTooltip:AddDoubleLine(L["Current Artifact Power: "], longRepString:format(colorize(short(data.barValue), "normal"), colorize(short(data.barMax), "normal")), r, g, b, r, g, b)

		local knowledgeLevel = C_ArtifactUI.GetArtifactKnowledgeLevel()
		if knowledgeLevel and knowledgeLevel > 0 then
			local knowledgeMultiplier = C_ArtifactUI.GetArtifactKnowledgeMultiplier()

			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(ARTIFACTS_KNOWLEDGE_TOOLTIP_LEVEL:format(knowledgeLevel), HIGHLIGHT_FONT_COLOR:GetRGB())
			GameTooltip:AddLine(ARTIFACTS_KNOWLEDGE_TOOLTIP_DESC:format(BreakUpLargeNumbers(knowledgeMultiplier * 100)), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
		end

		if data.unusedPoints > 0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(ARTIFACT_POWER_TOOLTIP_BODY:format(data.unusedPoints), nil, nil, nil, true)
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["<Left-Click to toggle Artifact Window>"], unpack(C.chat.offgreen))
		GameTooltip:Show()
	end

	self.frame.mouseIsOver = true
	self.frame:UpdateBar()
end

function ArtifactBar:OnLeave()
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

function module:IsArtifactBarVisible()
	local showXP = parent:IsXPBarVisible()
	local data = self.frame:UpdateData()
	module.db.profile.enabled = (not showXP) and data.equipped
	return HasArtifactEquipped() and self.db.profile.enabled
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("ArtifactBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()

	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")

end

function module:OnEnable()
	self.frame = LMP:NewChain(setmetatable(Scaffold:New("Artifact", L["Artifact Bar"], function() return self.db.profile end), { __index = ArtifactBar })) :SetFrameStrata("LOW") .__EndChain
	parent:GetFadeManager():RegisterObject(self.frame)
	self.frame.data = {} -- table to store info
	self.frame.border = LMP:NewChain(CreateFrame("Frame", "GUI4_ArtifactBarBorder", self.frame)) :SetAllPoints() :SetFrameStrata("MEDIUM") :SetFrameLevel(self.frame:GetFrameLevel() + 3) .__EndChain
	self.frame.bar = LMP:NewChain("StatusBar", "GUI4_ArtifactBarStatusBar", self.frame) :SetFrameLevel(self.frame:GetFrameLevel() + 2) :EnableMouse(true) :SetScript("OnMouseUp", ArtifactBar.OnClick) :SetScript("OnEnter", ArtifactBar.OnEnter) :SetScript("OnLeave", ArtifactBar.OnLeave) .__EndChain
	self.frame.bar.spark = LMP:NewChain(self.frame.bar:CreateTexture(nil, "ARTWORK")) :SetBlendMode("ADD") .__EndChain
	self.frame.bar.frame = self.frame
	self.frame.text = LMP:NewChain("FontString", nil, self.frame.border) :SetFontObject(TextStatusBarText) :SetFontSize(12) :SetFontStyle("THINOUTLINE") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY") :SetTextColor(unpack(C.chat.offwhite)) :SetPoint("CENTER", 0, 0) .__EndChain
	self.frame.glow = LMP:NewChain(self.frame:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetVertexColor(0, 0, 0, 1) .__EndChain 
	self.frame.backdrop = LMP:NewChain(self.frame:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) .__EndChain 
	self.frame.notches = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain 
	self.frame.normal = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 2) .__EndChain 
	self.frame.overlay = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 3) :Hide() .__EndChain 
	self.frame.highlight = LMP:NewChain(self.frame.border:CreateTexture()) :SetDrawLayer("ARTWORK", 4) :SetBlendMode("BLEND") :Hide() .__EndChain 
	
	self.frame:SetScript("OnEvent", ArtifactBar.OnEvent)
	self.frame:RegisterEvent("PLAYER_ALIVE")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.frame:RegisterEvent("PLAYER_LOGIN")
	self.frame:RegisterEvent("PLAYER_LEVEL_UP")
	self.frame:RegisterEvent("ENABLE_XP_GAIN")
	self.frame:RegisterEvent("DISABLE_XP_GAIN")
	self.frame:RegisterEvent("ARTIFACT_XP_UPDATE")
	self.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")

	gUI4:ApplySmoothing(self.frame.bar)

    -- This function updates both XP, Rep, Artifact and honor bars
	hooksecurefunc("MainMenuBar_UpdateExperienceBars", function() self:ApplySettings() end)

	self:RegisterMessage("GUI4_XPBAR_ENABLED", "ApplySettings")
	self:RegisterMessage("GUI4_XPBAR_DISABLED", "ApplySettings")

	self:ApplySettings()
end

function module:OnDisable()
end
