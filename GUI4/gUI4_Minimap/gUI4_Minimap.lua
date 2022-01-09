local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme

-- Lua API
local tonumber, select = tonumber, select
local tinsert, tsort = table.insert, table.sort
local min, max, sqrt = math.min, math.max, math.sqrt

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat

local defaults = {
	profile = {
		skin = "Warcraft",
		-- rotateCog = false,
		locked = true,
		showspikes = true, 
		position = {}
	}
}

local function updateConfig()
	T = module:GetActiveTheme()
end

-- local hz = 1/60
-- local function OnUpdate(self, elapsed)
	-- self.elapsed = (self.elapsed or 0) + elapsed
	-- if self.elapsed > hz then 
		-- if self.db.profile.rotateCog then
			-- local currentSpeed, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player")
			-- if currentSpeed ~= 0 then 
				-- local step = 1 + (currentSpeed-runSpeed)/(runSpeed)
				-- local cog = self.custom.cogwheel
				-- local inc = step * self.elapsed/hz -- skip frames if needed
				-- self.counter = (self.counter or 0) + inc
				-- local counter = floor(self.counter)
				-- if counter >= cog.numItems then
					-- counter = counter%cog.numItems
				-- end
				-- cog:SetTexCoord(cog.T:GetGridTexCoord(counter + 1))
			-- end
		-- end
		-- self.elapsed = 0
	-- end
-- end

function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(self) then return end
	if not self.frame then return end 
	updateConfig()
	LMP:NewChain(self.frame) :SetSize(unpack(T.size)) :EndChain()
	LMP:NewChain(self.frame.custom.map) :SetSize(unpack(T.mapSize)) :ClearAllPoints() :SetPoint(unpack(T.mapPlace)) :EndChain()
	LMP:NewChain(self.frame.custom.map.content) :SetSize(unpack(T.mapSize)) :ClearAllPoints() :SetPoint(unpack(T.mapPlace)) :SetMaskTexture(T.mask:GetPath()) :EndChain()
	LMP:NewChain(self.frame.scaffold.model) :ClearAllPoints() :SetPoint(unpack(T.model.place)) :SetShown(T.model.enable) :SetSize(unpack(T.model.size)) :SetCamDistanceScale(T.model.distanceScale) :SetPosition(unpack(T.model.position)) :SetRotation(T.model.rotation) :SetPortraitZoom(T.model.zoom) :ClearModel() :SetDisplayInfo(T.model.id) :SetAlpha(T.model.alpha) :EndChain()
	-- LMP:NewChain(self.frame.custom.glow) :ClearAllPoints() :SetPoint(T.textures.glow:GetPoint()) :SetSize(T.textures.glow:GetTexSize()) :SetTexture(T.textures.glow:GetPath()) :SetVertexColor(unpack(T.textures.glow:GetColor())) :SetTexCoord(T.textures.glow:GetTexCoord()) :EndChain()
	LMP:NewChain(self.frame.custom.backdrop) :ClearAllPoints() :SetPoint(T.textures.backdrop:GetPoint()) :SetSize(T.textures.backdrop:GetTexSize()) :SetTexture(T.textures.backdrop:GetPath()) :SetVertexColor(unpack(T.textures.backdrop:GetColor())) :SetTexCoord(T.textures.backdrop:GetTexCoord()) :EndChain()
	-- LMP:NewChain(self.frame.custom.gloss) :ClearAllPoints() :SetPoint(T.textures.gloss:GetPoint()) :SetSize(T.textures.gloss:GetTexSize()) :SetTexture(T.textures.gloss:GetPath()) :SetAlpha(T.textures.gloss:GetAlpha()) :SetVertexColor(unpack(T.textures.gloss:GetColor())) :SetTexCoord(T.textures.gloss:GetTexCoord()) :EndChain()
	-- LMP:NewChain(self.frame.custom.shade) :ClearAllPoints() :SetPoint(T.textures.shade:GetPoint()) :SetSize(T.textures.shade:GetTexSize()) :SetTexture(T.textures.shade:GetPath()) :SetAlpha(T.textures.shade:GetAlpha()) :SetVertexColor(unpack(T.textures.shade:GetColor())) :SetTexCoord(T.textures.shade:GetTexCoord()) :EndChain()
	LMP:NewChain(self.frame.custom.border) :ClearAllPoints() :SetPoint(T.textures.border:GetPoint()) :SetSize(T.textures.border:GetTexSize()) :SetTexture(T.textures.border:GetPath()) :SetVertexColor(unpack(T.textures.border:GetColor())) :SetTexCoord(T.textures.border:GetTexCoord()) :EndChain()
	LMP:NewChain(self.frame.custom.ring) :ClearAllPoints() :SetPoint(T.textures.ring:GetPoint()) :SetSize(T.textures.ring:GetTexSize()) :SetTexture(T.textures.ring:GetPath()) :SetVertexColor(unpack(T.textures.ring:GetColor())) :SetTexCoord(T.textures.ring:GetTexCoord()) :EndChain()
	LMP:NewChain(self.frame.custom.cogwheel) :ClearAllPoints() :SetPoint(T.textures.cogwheel:GetPoint()) :SetSize(T.textures.cogwheel:GetGridSlotSize()) :SetTexture(T.textures.cogwheel:GetPath()) :SetVertexColor(unpack(T.textures.cogwheel:GetColor())) :SetTexCoord(T.textures.cogwheel:GetTexCoord()) :EndChain()

	-- position and size the original Minimap to the same as our custom, for better compability with other addons
	-- LMP:NewChain(Minimap) :SetAllPoints(self.frame.custom.map) :SetSize(self.frame.custom.map:GetSize()) :EndChain()
	LMP:NewChain(self.frame.custom.map.content) :SetAllPoints(self.frame.custom.map) :SetSize(self.frame.custom.map:GetSize()) :EndChain()
	
	-- wow shrinks a rotating texture to fit inside a circle, 
	-- so we need to figure out the proper sizes and coords
	local w, h = T.textures.compass:GetTexSize() -- original texture dimensions
	local region, x, y = T.textures.compass:GetPoint() -- original texture position
	local size = math.ceil(math.sqrt(w^2 + h^2)) -- the new square sides are the diameter of the cirle (which is the hypothenuse of the 2 triangles making up the original square)
	local mult = 2^.5 -- this is a short version of sqrt(2 * size^2), which works for square textures. we're not using it, "just in case"
	local newX, newY = math.floor(x - (size-w)/2), math.floor(y + (size-h)/2) -- adding the difference in size to the old coordinates to align it properly

	LMP:NewChain(self.frame.widgets.compass) :ClearAllPoints() :SetPoint(region, newX, newY) :SetSize(size, size) :SetTexture(T.textures.compass:GetPath()) :SetVertexColor(unpack(T.textures.compass:GetColor())) :SetTexCoord(T.textures.compass:GetTexCoord()) :EndChain()

	self.frame.custom.cogwheel.T = T.textures.cogwheel
	self.frame.custom.cogwheel.numItems = T.textures.cogwheel:GetNumGridItems()
	self.frame.custom.cogwheel:SetTexCoord(T.textures.cogwheel:GetGridTexCoord(T.textures.cogwheel:GetNumGridItems()))
	
  QueueStatusMinimapButton:ClearAllPoints() QueueStatusMinimapButton:SetPoint(unpack(T.widgets.eye.place))
  
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	if not self.frame then return end 
	updateConfig()
	if self.db.profile.showspikes then 
		self.frame.custom.cogwheel:Hide()
		self.frame.custom.ring:Hide()
		self.frame.custom.border:Show()
	else
		self.frame.custom.cogwheel:Hide()
		self.frame.custom.ring:Show()
		self.frame.custom.border:Hide()
	end
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:SetupOptions()
	for name, mod in self:IterateModules() do
		if mod.SetupOptions then
			mod:SetupOptions()
		end
	end	

	gUI4:RegisterModuleOptions("Maps", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["Minimap"],
			args = {
				use24hrClock = {
					order = 10,
					type = "toggle",
					name = L["Use 24-hour clock."],
					desc = L["Toggles the use of the normal 24-hour clock."],
					width = "full",
					get = function() 
						local time = self:GetModule("Time")
						return time.db.profile.use24hrClock 
					end,
					set = function(info, value)
						local time = self:GetModule("Time")
						time.db.profile.use24hrClock = value
					end
				},
				useGameTime = {
					order = 10,
					type = "toggle",
					name = L["Use realm time."],
					desc = L["Toggles the use of the time as reported by your current realm."],
					width = "full",
					get = function() 
						local time = self:GetModule("Time")
						return time.db.profile.useGameTime 
					end,
					set = function(info, value)
						local time = self:GetModule("Time")
						time.db.profile.useGameTime = value
					end
				},
				showGarrisonButton = self:GetModule("Garrison", true) and {
					order = 10,
					type = "toggle",
					name = L["Show Garrison Report button."],
					desc = L["Toggles the display of the Garrison Report button."],
					width = "full",
					get = function() 
						local garrison = self:GetModule("Garrison")
						return garrison.db.profile.showGarrisonButton 
					end,
					set = function(info, value)
						local garrison = self:GetModule("Garrison")
						garrison.db.profile.showGarrisonButton = value
						garrison:ApplySettings()
					end
				} or nil,
				showspikes = {
					order = 10,
					type = "toggle",
					name = L["Show spikes around the Minimap."],
					desc = L["Toggles the display of spikes on the Minimap border."],
					width = "full",
					get = function() 
						return self.db.profile.showspikes 
					end,
					set = function(info, value)
						self.db.profile.showspikes = value
						self:ApplySettings()
					end
				}
			}
		}
	})

end

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
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:GetFrame()
	return self.frame
end

function module:GetMinimap() -- returns the actual minimap, whatever frame that might be
	return self.frame.custom.map.content
end

function module:GetMinimapFrame()
	return self.frame.custom.map
end

function module:GetWidgetFrame() -- intended as a parent frame for widgets and 3rd party addons to hook into
	return self.frame.scaffold.border
end

function module:Lock()
	self.frame.overlay:StartFadeOut()
	for name, mod in self:IterateModules() do
		if mod.Lock then
			mod:Lock()
		end
	end
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	self.frame.overlay:SetAlpha(0)
	self.frame.overlay:Show()
	for name, mod in self:IterateModules() do
		if mod.Unlock then
			mod:Unlock()
		end
	end
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
	for name, mod in self:IterateModules() do
		if mod.ResetLock then
			mod:ResetLock()
		end
	end
	self:ApplySettings()
end

local queued = {}
function module:ADDON_LOADED(event, ...)
	if event == "ADDON_LOADED" then 
		local arg1 = ... 
		if arg1 == "Blizzard_TimeManager" then
			LMP:Kill("TimeManagerClockButton")
			queued[arg1] = nil
		end
		if not next(queued) then
			queued = nil
			self:UnregisterEvent("ADDON_LOADED")
		end
	end
end

function module:RegisterWidget(id, widget)
	if self.frame.widgets[id] then return end -- silently fail with existing widget names
	self.frame.widgets[id] = widget
	return widget
end

function module:GetWidget(id)
	return self.frame.widgets[id]
end

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_Minimap_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end
	updateConfig()
	
	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapHolder", UIParent, "SecureHandlerStateTemplate")) :SetFrameStrata("LOW") :SetFrameLevel(0) .__EndChain
	self.frame.overlay = gUI4:GlockThis(self.frame, MINIMAP_LABEL, function() return self.db.profile end, unpack(gUI4:GetColors("glock", "panels")))
	self.frame.GetSettings = function() return self.db.profile end
	self.frame.UpdatePosition = function(self) module:UpdatePosition() end
	RegisterStateDriver(self.frame, "visibility", "[petbattle] hide; show")
	
	self.frame.visibility = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapToggler", self.frame)) :SetAllPoints() :SetFrameStrata("LOW") :SetFrameLevel(0) .__EndChain

	-- kill the original map, it messes with its parent's size
	-- update: keep the map visible, to properly trigger Zygor waypoints, arrows and anttrails
	-- update2: set the dummy's points to UIParent
	-- update3: lock the dummy position and visibility
	local dummy = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapHider", UIParent)) :SetAllPoints()  .__EndChain --:Hide()
	dummy.SetAllPoints = function() end
	dummy.ClearAllPoints = function() end
	dummy.SetPoint = function() end
	dummy.Hide = dummy.Show

	Minimap:SetParent(dummy)
	Minimap.SetParent = function() end
	Minimap:Show() -- make sure the map is shown
	
	-- re-route the minimap show/hide functionality to affect our visibility layer instead
	Minimap.Hide = function() self.frame.visibility:Hide() end
	Minimap.Show = function() self.frame.visibility:Show() end
	Minimap.IsShown = function() return self.frame.visibility:IsShown() end
	Minimap.SetShown = function(_, show) self.frame.visibility:SetShown(show) end
	
	dummy:SetParent(self.frame.visibility) -- parent the minimap dummy layer (resize protection) to our visibility layer
	
	self.frame.scaffold = {}
	self.frame.scaffold.backdrop = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapHolderBackdrop", self.frame.visibility)) :SetAllPoints() :SetFrameLevel(1) .__EndChain
	self.frame.scaffold.model = LMP:NewChain(CreateFrame("PlayerModel", "GUI4_MinimapHolderModel", self.frame.visibility)) :SetAllPoints() :SetFrameLevel(6) .__EndChain
	self.frame.scaffold.border = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapHolderBorder", self.frame.visibility)) :SetAllPoints() :SetFrameLevel(10) .__EndChain

	self.frame.custom = {}
	
	-- self.frame.dummy = LMP:NewChain(CreateFrame("Frame", nil, self.frame)) :SetAllPoints() :SetFrameStrata("LOW") :SetFrameLevel(0) .__EndChain
	self.frame.dummy = dummy
	self.frame.custom.map = LMP:NewChain(CreateFrame("Frame", "GUI4_CustomMinimap", self.frame.visibility)) :ClearAllPoints() :SetPoint("TOPLEFT", 0, 0) :SetFrameStrata("LOW") :SetFrameLevel(5) .__EndChain
	self.frame.custom.map.content = LMP:NewChain(Minimap) :ClearAllPoints() :SetPoint("TOPLEFT", 0, 0) :SetFrameStrata("LOW") :SetFrameLevel(5) .__EndChain
	-- self.frame.custom.map = LMP:NewChain(CreateFrame("Minimap", "GUI4_CustomMinimap", self.frame)) :ClearAllPoints() :SetPoint("TOPLEFT", 0, 0) :SetFrameStrata("LOW") :SetFrameLevel(5) .__EndChain
	self.frame.custom.glow = LMP:NewChain(self.frame.scaffold.backdrop:CreateTexture()) :SetDrawLayer("BACKGROUND", -1) :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.frame.custom.backdrop = LMP:NewChain(self.frame.scaffold.backdrop:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) .__EndChain
	self.frame.custom.gloss = LMP:NewChain(self.frame.scaffold.border:CreateTexture()) :SetDrawLayer("OVERLAY", -2) .__EndChain
	-- self.frame.custom.shade = LMP:NewChain(self.frame.scaffold.border:CreateTexture()) :SetDrawLayer("OVERLAY", -1) .__EndChain
	self.frame.custom.border = LMP:NewChain(self.frame.scaffold.border:CreateTexture()) :SetDrawLayer("OVERLAY", 0) .__EndChain
	self.frame.custom.ring = LMP:NewChain(self.frame.scaffold.border:CreateTexture()) :SetDrawLayer("OVERLAY", 1) .__EndChain
	self.frame.custom.cogwheel = LMP:NewChain(self.frame.scaffold.backdrop:CreateTexture()) :SetDrawLayer("BACKGROUND", 1) .__EndChain
	self.frame.custom.guide = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapHolderGuide", self.frame.scaffold.border)) :SetAllPoints(self.frame.custom.map) :SetFrameLevel(15) .__EndChain
	
	self.frame.old = {}
	self.frame.old.map = LMP:NewChain(Minimap) .__EndChain
	self.frame.old.backdrop = LMP:NewChain(MinimapBackdrop) :SetParent(self.frame.custom.map) :ClearAllPoints() :SetPoint("CENTER", -8, -23) .__EndChain
	self.frame.old.cluster = LMP:NewChain(MinimapCluster) :SetAllPoints(self.frame.custom.map) :EnableMouse(false) .__EndChain

	self.frame.widgets = {}
	self.frame.widgets.compass = LMP:NewChain(MinimapCompassTexture) :SetParent(self.frame.scaffold.border) :SetTexture("") :SetDrawLayer("OVERLAY", 2) .__EndChain
	self.frame.widgets.queue = LMP:NewChain(QueueStatusMinimapButton) :SetParent(self.frame.scaffold.border) .__EndChain

	LMP:Kill("GameTimeFrame") 
	LMP:Kill("MinimapBorder") 
	LMP:Kill("MinimapBorderTop") 
	LMP:Kill("MinimapCluster")
	LMP:Kill("MiniMapMailBorder") 
	LMP:Kill("MiniMapMailFrame") 
	LMP:Kill("MinimapBackdrop") -- MinimapCompassTexture
	LMP:Kill("MinimapNorthTag") 
	LMP:Kill("MiniMapTracking") 
	LMP:Kill("MiniMapTrackingButton") 
	LMP:Kill("MiniMapVoiceChatFrame") 
	LMP:Kill("MiniMapWorldMapButton") 
	LMP:Kill("MinimapZoomIn") 
	LMP:Kill("MinimapZoomOut") 
	LMP:Kill("MinimapZoneTextButton") 
	LMP:Kill("MiniMapInstanceDifficulty") -- 3.3
	LMP:Kill("GuildInstanceDifficulty") -- 4.0.6
	LMP:Kill("QueueStatusMinimapButtonBorder") -- 5.0.4
	LMP:Kill("GarrisonLandingPageMinimapButton") -- 6.0.1
	
	-- fix the queueframe - todo: move this stuff to the theme
	QueueStatusMinimapButton:SetParent(self.frame.scaffold.border)
	QueueStatusMinimapButton:SetFrameLevel(20)
	QueueStatusMinimapButton:ClearAllPoints() QueueStatusMinimapButton:SetPoint("CENTER", -64, -64)
	QueueStatusMinimapButton:SetHighlightTexture("")
	QueueStatusMinimapButton:SetSize(48, 48)
	QueueStatusMinimapButton.Eye:SetSize(48, 48)
	QueueStatusMinimapButton.Highlight:SetTexture("")
	QueueStatusMinimapButton.Highlight:SetAlpha(0)
	LFG_EYE_TEXTURES["unknown"] = LFG_EYE_TEXTURES["default"]
	for i = 1, QueueStatusFrame:GetNumRegions() do
		local region = select(i, QueueStatusFrame:GetRegions())
		if region.IsObjectType and region:IsObjectType("Texture") then
			region:SetTexture("")
			region:SetAlpha(0)
		end
	end
	QueueStatusFrame:SetBackdrop({
		bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		edgeSize = 1,
		insets = { 
			left = -1, 
			right = -1, 
			top = -1, 
			bottom = -1
		}
	})
	QueueStatusFrame:SetBackdropColor(0, 0, 0, .75) 
	QueueStatusFrame:SetBackdropBorderColor(.15, .15, .15)

	if not LMP:Kill("TimeManagerClockButton", nil, true) then 
		self:RegisterEvent("ADDON_LOADED")
		queued.Blizzard_TimeManager = true
	end
	
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
end

function module:OnEnable()
	for name, mod in self:IterateModules() do
		mod:Enable()
	end
	self:SetActiveTheme(self.db.profile.skin)
	-- self.frame:SetScript("OnUpdate", OnUpdate) -- ignoring cogs for now
end

function module:OnDisable()
end
