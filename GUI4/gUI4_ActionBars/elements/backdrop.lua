local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("Backdrop", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

local T, hasTheme, skinSize, skinSizeSide

-- weird locals to simplify the process of changing everything. which I keep doing.
local NUM_BOTTOM_STATES = 9
local NUM_SIDE_STATES = 3
local NUM_BACKDROPS_PER_GROUP = 3
local NUM_BACKDROPS_BOTTOM = NUM_BOTTOM_STATES*NUM_BACKDROPS_PER_GROUP
local NUM_BACKDROPS_SIDE = NUM_SIDE_STATES*NUM_BACKDROPS_PER_GROUP
local NUM_BACKDROPS_TOTAL =  NUM_BACKDROPS_BOTTOM + NUM_BACKDROPS_SIDE
local BOTTOM_BACKDROP_OFFSET = 1
local SIDE_BACKDROP_OFFSET = 1 + NUM_BACKDROPS_BOTTOM
local NUM_EXTRABARS_MAX = 2
local BACKDROP_ID = 0
local BORDER_ID = 1
local HIGHLIGHT_ID = 2

local defaults = {
	profile = {
		enabled = true
	}
}

local function updateConfig()
	skinSize = parent.db:GetNamespace("ActionBars").profile.bars[1].skinSize
	skinSizeSide = parent.db:GetNamespace("ActionBars").profile.bars[3].skinSize
	T = parent:GetActiveTheme()
end

local positionCallbacks = {}
function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	updateConfig()
	for callback in pairs(positionCallbacks) do
		self:UnregisterMessage(callback, "UpdatePosition")
	end
	wipe(positionCallbacks)
	for callback in pairs(T.backdrop.positionCallbacks) do
		positionCallbacks[callback] = true
	end
	for callback in pairs(positionCallbacks) do
		self:RegisterMessage(callback, "UpdatePosition")
	end
	for i = 1, NUM_BACKDROPS_TOTAL do
		local db = T.backdrop[i < SIDE_BACKDROP_OFFSET and skinSize or skinSizeSide][i] 
		if db then 
			LMP:NewChain(self.texturePool[i]) :SetSize(db:GetTexSize()) :SetTexture(db:GetPath()) :ClearAllPoints() :SetPoint(db:GetPoint()) :SetTexCoord(db:GetTexCoord()) :SetVertexColor(unpack(db:GetColor())) :SetAlpha(db:GetAlpha()) :EndChain()
		else
			LMP:NewChain(self.texturePool[i]) :SetSize(.001, .001) :SetTexture("") :SetAlpha(0) :Hide() :EndChain() 
		end	
	end
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	if not self.texturePool then return end
	updateConfig()

	-- we could do this a lot simpler, but I wish to explain why things happen

	-- retrieve info about what bars are visible
	local main = parent:IsBarLocked(1)
	local bottomleft = parent:IsBarLocked(6)
	local bottomright = parent:IsBarLocked(5)
	local right = parent:IsBarLocked(3)
	local left = parent:IsBarLocked(4)
	local xp = parent:IsXPBarVisible() or parent:IsArtifactBarVisible() -- these 2 are displayed at the same place anyway
	local rep = parent:IsReputationBarVisible()
	local bars = (main and bottomleft and bottomright) and 3 or (main and bottomright) and 3 or (main and bottomleft) and 2 or main and 1 or 0
	local sidebars = (right and left) and 2 or left and 2 or (right or left) and 1 or 0
	local extrabars = (xp and rep) and 2 or (xp or rep) and 1 or 0
	
	-- bottom area
	local bottomID 
	if bars > 0 then
		bottomID = BOTTOM_BACKDROP_OFFSET + (extrabars*NUM_BACKDROPS_PER_GROUP) + (bars-1)*NUM_BACKDROPS_PER_GROUP*(NUM_EXTRABARS_MAX + 1)
	else 
		-- no bottom bars, no xp, no nothing. 
		-- todo: send message to the xp/rep modules to handle their own skins when this happens
	end
	-- side area
	local sideID
	if sidebars > 0 then
		sideID = SIDE_BACKDROP_OFFSET + (sidebars-1)*NUM_BACKDROPS_PER_GROUP
		-- if sidebars == 1 then
			-- sideID = 1 + 18
		-- elseif sidebars == 2 then
			-- sideID = 3 + 18
		-- end
	else -- no sidebars
		sideID = SIDE_BACKDROP_OFFSET + 2*NUM_BACKDROPS_PER_GROUP
	end
	for id, texture in pairs(self.texturePool) do
		if sideID and (id == sideID + BACKDROP_ID or id == sideID + BORDER_ID)
		or bottomID and (id == bottomID + BACKDROP_ID or id == bottomID + BORDER_ID) then
			texture:Show()
		else
			texture:Hide()
		end
	end

	-- LMP:NewChain(self.couch) :SetFrameStrata("MEDIUM") :SetFrameLevel(0) :EndChain()
	-- LMP:NewChain(self.cushion) :SetFrameStrata("LOW") :SetFrameLevel(0) :EndChain()
	-- LMP:NewChain(self.shelf) :SetFrameStrata("MEDIUM") :SetFrameLevel(0) :EndChain()
	-- LMP:NewChain(self.wall) :SetFrameStrata("LOW") :SetFrameLevel(0) :EndChain()

	if sideID and T.backdrop[skinSizeSide][sideID] then
		self.shelf:SetSize(T.backdrop[skinSizeSide][sideID + BORDER_ID]:GetSize())
	end
	if bottomID and T.backdrop[skinSize][bottomID] then
		self.couch:SetSize(T.backdrop[skinSize][bottomID + BORDER_ID]:GetSize())
	end

	self:UpdatePosition()
end
-- module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.texturePool then return end
	updateConfig()
	LMP:Place(self.couch, T.backdrop.place)
	LMP:Place(self.shelf, T.backdrop.sideplace)
end
-- module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Backdrop", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	updateConfig()
	if not self.texturePool then
		self.couch = LMP:NewChain(CreateFrame("Frame", "GUI4_ActionBarBottomBorder", parent:GetFadeManager())) :SetFrameStrata("MEDIUM") :SetFrameLevel(0) .__EndChain -- bottom bars border & highlight
		self.cushion = LMP:NewChain(CreateFrame("Frame", "GUI4_ActionBarBottomBackdrop", self.couch)) :SetFrameStrata("LOW") :SetFrameLevel(0) :SetAllPoints() .__EndChain -- bottom bars backdrop
		self.shelf = LMP:NewChain(CreateFrame("Frame", "GUI4_ActionBarSideBorder", parent:GetFadeManager())) :SetFrameStrata("MEDIUM") :SetFrameLevel(0) .__EndChain -- side bars border & highlight
		self.wall = LMP:NewChain(CreateFrame("Frame", "GUI4_ActionBarSideBackdrop", self.shelf)) :SetFrameStrata("LOW") :SetFrameLevel(0) :SetAllPoints() .__EndChain -- side bars backdrop
		self.texturePool = {}
		for i = 1, NUM_BACKDROPS_TOTAL do
			local parent, layer
			if i >= SIDE_BACKDROP_OFFSET then 
				if (i+2)%NUM_BACKDROPS_PER_GROUP == 0 then
					parent, layer, sublayer = "wall", "BACKGROUND", -8
				else
					parent, layer, sublayer = "shelf", "ARTWORK", 0
				end
			else
				if (i+2)%NUM_BACKDROPS_PER_GROUP == 0 then
					parent, layer, sublayer = "cushion", "BACKGROUND", -8
				else
					parent, layer, sublayer = "couch", "ARTWORK", 0
				end
			end
			self.texturePool[i] = LMP:NewChain(self[parent]:CreateTexture()) :SetDrawLayer(layer, sublayer) :Hide() .__EndChain
		end
	end
end

function module:OnEnable()
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIONBAR_CREATED", "ApplySettings")
	self:RegisterMessage("GUI4_NUM_ACTIONBARS_BOTTOM_CHANGED", "ApplySettings")
	self:RegisterMessage("GUI4_NUM_ACTIONBARS_SIDE_CHANGED", "ApplySettings")
	self:RegisterMessage("GUI4_XPBAR_ENABLED", "ApplySettings")
	self:RegisterMessage("GUI4_XPBAR_DISABLED", "ApplySettings")
	self:RegisterMessage("GUI4_ARTIFACTBAR_ENABLED", "ApplySettings")
	self:RegisterMessage("GUI4_ARTIFACTBAR_DISABLED", "ApplySettings")
	self:RegisterMessage("GUI4_REPUTATIONBAR_ENABLED", "ApplySettings")
	self:RegisterMessage("GUI4_REPUTATIONBAR_DISABLED", "ApplySettings")
	self:ApplySettings()
end

function module:OnDisable()
end
