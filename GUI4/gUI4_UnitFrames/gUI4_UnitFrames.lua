local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local prototype = {} -- module template
local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)
module:SetDefaultModulePrototype(prototype)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LibWin = GP_LibStub("GP_LibWindow-1.1")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme, db
local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

-- Lua API
local pairs, select, tostring = pairs, select, tostring
local tconcat, tinsert = table.concat, table.insert

-- WoW API
local InCombatLockdown = InCombatLockdown
local UnitAffectingCombat = UnitAffectingCombat

local FadeManager
local units = {} -- unitframe registry
local unitsPerModule = {} -- units per module
local mirror = {
	BOTTOM = "TOP",
	BOTTOMLEFT = "TOPRIGHT",
	BOTTOMRIGHT = "TOPLEFT",
	CENTER = "CENTER",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	TOP = "BOTTOM",
	TOPLEFT = "BOTTOMRIGHT",
	TOPRIGHT = "BOTTOMLEFT"
}

local defaults = {
	profile = {
		skin = "Warcraft", -- default theme
		modules = { 
			Player = true, 
			AltPowerBar = true,
			ClassBar = true, 
			Pet = true,
			PetTarget = true,
			Target = true,
			ToT = true,
			ToTTarget = true,
			Focus = true,
			FocusTarget = true,
			Boss = true
		}
	}
}

local function updateConfig()
	T = module:GetActiveTheme()
end

-- we're using custom handling of frames, and need to bypass oUF's disabling
oUF.DisableBlizzard = function() end

-------------------------------------------------------------------------------
--	UnitFrame Prototype
-------------------------------------------------------------------------------
local function showHighlight(self)
	local highlight = self.Highlight
	local border = self.Border
	if highlight then
		highlight:Show()
		if border then
			border:Hide()
		end
	end
end
local function hideHighlight(self)
	local highlight = self.Highlight
	local border = self.Border
	if highlight then
		if border then
			border:Show()
		end
		highlight:Hide()
	end
end
local function onEnter(self)
	showHighlight(self)
	if self.GetStatusBarRegistry then
		for _,bar in self:GetStatusBarRegistry() do
			showHighlight(bar)
		end
	end
	local healer = self.SpiritHealer
	if healer then
		if not(healer.alpha) then
			healer.alpha = healer:GetAlpha()
		end
		healer:SetAlpha(1)
	end
	if (GameTooltip:IsForbidden()) then 
		return 
	end 
	GameTooltip:Hide()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(self.unit) 
	local r, g, b = GameTooltip_UnitColor(self.unit)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
end

local function onLeave(self)
	hideHighlight(self)
	if self.GetStatusBarRegistry then
		for _,bar in self:GetStatusBarRegistry() do
			hideHighlight(bar)
		end
	end
	local healer = self.SpiritHealer
	if healer then
		if (healer.alpha) then
			healer:SetAlpha(healer.alpha)
			healer.alpha = nil
		end
	end
	if (GameTooltip:IsForbidden()) then
		return 
	end 
	if SHOW_NEWBIE_TIPS == "1" then
		GameTooltip:Hide()
	else
		GameTooltip:FadeOut()
	end
end

-- adds common frames, layers and scripts
-- called for all unitframes upon creation
local function scaffold(self, unit)
	self.colors = gUI4:GetColors()

	self:SetScript("OnEnter", onEnter)
	self:SetScript("OnLeave", onLeave)
	self:RegisterForClicks("AnyUp")

	self.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetFrameLevel(self:GetFrameLevel() + 10) :SetAllPoints() .__EndChain
	self.InfoFrame = LMP:NewChain(CreateFrame("Frame", nil, self.OverlayFrame)) :SetAllPoints() .__EndChain
	self.IconFrame = LMP:NewChain(CreateFrame("Frame", nil, self.InfoFrame)) :SetAllPoints() .__EndChain

	self.Glow = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("BACKGROUND", -7) :SetAllPoints() :SetVertexColor(0, 0, 0, 1) .__EndChain
	self.Backdrop = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("BACKGROUND", -1) :SetAllPoints() .__EndChain
	self.Shade = LMP:NewChain(self.OverlayFrame:CreateTexture()) :SetDrawLayer("BACKGROUND", 1) :SetAllPoints() .__EndChain
	self.Border = LMP:NewChain(self.OverlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 0) :SetAllPoints() .__EndChain
	self.Highlight = LMP:NewChain(self.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 1) :SetBlendMode("BLEND") :SetAllPoints() .__EndChain
	self.Overlay = LMP:NewChain(self.OverlayFrame:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 2) :SetAllPoints() .__EndChain
	self.SpiritHealer = LMP:NewChain(self.IconFrame:CreateTexture()) :Hide() :SetDrawLayer("OVERLAY", 7) :SetAlpha(.5) :SetAllPoints() .__EndChain
	
	return self, unit
end


-------------------------------------------------------------------------------
--	Module Prototype
-------------------------------------------------------------------------------
local styles = {} -- just to keep track of registered styles, to avoid oUF bugs
local glocks = {} -- draggable frame overlays

-- create a new frame and add it to our registry
-- @usage local frame = //addon//:AddUnit(unit[, id], func, settings)
-- @param unit <string> unitID of the unitframe
-- @param id <string, number> a unique id to add to the name (e.g. 1 for "Boss1", or "1Target" for "Boss1Target")
-- @param func <function> style function called by oUF when creating the frame
-- @param settings <table> the stored settings for the module or frame (not actually used here...?)
-- @return <frame> the newly created unitframe
function prototype:AddUnit(unit, ...)
	local name = self:GetName()
	local id, func, settings
	local frameID
	local styleName = "gUI4_UnitFrame_" .. name
	if select("#", ...) == 2 then
		func, settings = ...
		frameID = name
	elseif select("#", ...) == 3 then
		id, func, settings = ...
		frameID = name .. id
	end
	if not styles[styleName] then
		oUF:RegisterStyle(styleName, function(self, unit)
			scaffold(self, unit)
			func(self, unit)
			-- return self
		end)
		styles[styleName] = true
	end
	oUF:SetActiveStyle(styleName)
	local frame = oUF:Spawn(unit, "gUI4_Unit" .. frameID)
	frame.frameID = frameID
	frame.isNumbered = id
	frame.blizzardUnit = unit
	frame.module = self
	if not FadeManager then
		-- note: the fademanager and all the unitframes should stay at a LOW strata, to be below the WoW UI panels which usually are MEDIUM
		FadeManager = LMP:NewChain(gUI4:CreateFadeManager("UnitFrames")) :SetFrameStrata("LOW") :SetFrameLevel(100) :Enable() .__EndChain
	end
	if not frame.module.db.profile.alwaysVisible then
		FadeManager:RegisterObject(frame)
	end
	
	glocks[frame] = gUI4:GlockThis(frame, L[self:GetName()] .. (id or ""), function() 
		if frame.isNumbered then
			return frame.module.db.profile[frame.isNumbered]
		else
			return frame.module.db.profile 
		end
	end, unpack(gUI4:GetColors("glock", "unitframes"))) 
  
	-- todo: let numbered units be forcefully positioned relative to a movable anchorframe!
	function frame:UpdatePosition()
		if not hasTheme then return end
		updateConfig()
		local db 
		if self.isNumbered then
			db = self.module.db.profile[self.isNumbered]
		else
			db = self.module.db.profile
		end
		if db.locked then
			LMP:Place(self, T[self.frameID].place)
			if not db.position.x then
				self:RegisterConfig(db.position)
				self:SavePosition()
			end
		else
			self:RegisterConfig(db.position)
			if db.position.x then
				self:LoadPosition()
			else
				LMP:Place(self, T[self.frameID].place)
				self:SavePosition()
				self:LoadPosition()
			end
		end	
	end
  
	function frame:ResetLock()
		if UnitAffectingCombat("player") then return end
		local db 
		if self.isNumbered then
			db = self.module.db.profile[self.isNumbered]
		else
			db = self.module.db.profile
		end
		db.position.point = nil
		db.position.y = nil
		db.position.x = nil
		db.locked = true
		wipe(db.position)
		-- self:ApplySettings()
	end

	units[frameID] = frame -- add it to our registry
	if not unitsPerModule[self] then
		unitsPerModule[self] = {} 
	end
	if id then
		self.hasNumberedUnits = true
		unitsPerModule[self][id] = frameID
	end
	unitsPerModule[self][frameID] = frame -- add it to the module's registry
	return frame
end
prototype.AddUnit = gUI4:SafeCallWrapper(prototype.AddUnit)

-- function prototype:Place(...)
	-- LMP:Place(...)
-- end
-- prototype.Place = gUI4:SafeCallWrapper(prototype.Place)

-- update the position of all frames registered to the module
function prototype:UpdatePosition()
	if not hasTheme then return end
	updateConfig()
	self:ForAll("UpdatePosition")
end
prototype.UpdatePosition = gUI4:SafeCallWrapper(prototype.UpdatePosition)

function prototype:ResetLock()
	if not hasTheme then return end
	updateConfig()
	self:ForAll("ResetLock")
end
prototype.ResetLock = gUI4:SafeCallWrapper(prototype.ResetLock)

-- apply the method with the args(frame, ...) to all unitframes registered to the module
function prototype:ForAll(method, ...)
	if self.hasNumberedUnits then
		for id, frameID in ipairs(unitsPerModule[self]) do
			local frame = unitsPerModule[self][frameID]
			if frame and frame[method] then
				frame[method](frame, ...)
			elseif type(method) == "function" then
				method(self, frame, ...) -- don't do this unless you're me, it'll mess with my zen
			end
		end
	else
		for frameID, frame in self:GetAllUnits() do
			if frame and frame[method] then
				frame[method](frame, ...)
			elseif type(method) == "function" then
				method(self, frame, ...) 
			end
		end
	end
end

local function enableBlizzard(self, frame, ...)
	if not frame.module.db.profile.ignoreBlizzard then
		gUI4:EnableUnitFrame(frame.blizzardUnit)
	end
end

local function disableBlizzard(self, frame, ...)
	if not frame.module.db.profile.ignoreBlizzard then
		gUI4:DisableUnitFrame(frame.blizzardUnit)
	end
end

function prototype:EnableUnitFrames()
	self:ForAll(disableBlizzard)
	self:ForAll("Enable")
end

function prototype:DisableUnitFrames()
	self:ForAll("Disable")
	self:ForAll(enableBlizzard)
end

function prototype:GetAllUnits()
	if not unitsPerModule[self] then
		unitsPerModule[self] = {}
	end
	return pairs(unitsPerModule[self])
end

local function updateTexture(tex, db)
	if db then
		tex:SetTexture(db:GetPath())
		tex:SetSize(db:GetTexSize())
		tex:SetVertexColor(unpack(db:GetColor()))
		tex:SetAlpha(db:GetAlpha())
		tex:SetTexCoord(db:GetTexCoord())
		tex:ClearAllPoints()
		tex:SetPoint(db:GetPoint())
	else
		tex:SetSize(.001, .001)
		tex:SetAlpha(0)
		tex:SetTexture("")
		tex:Hide()
	end
end

local texList = { "Backdrop", "Border", "Highlight" } 
local function updateTextures(frame, db)
	for _,t in ipairs(texList) do
		if frame[t] then
			updateTexture(frame[t], db.textures and db.textures[t:lower()])
		end
	end
end

local function updateBar(bar, db)
	if db.alpha then
		bar:SetAlpha(db.alpha)
	else
		bar:SetAlpha(1)
	end
	if db.sparkle then
		if bar.Sparkle then
			bar.Sparkle:Show()
			bar.Sparkle:SetAlpha(tonumber(db.sparkle) or .1)
		end
	else
		if bar.Sparkle then
			bar.Sparkle:Hide()
		end
	end
	if db.size then
		bar:SetSize(unpack(db.size))
	else
		bar:SetSize(bar:GetParent():GetSize())
	end
	if db.growth then
		bar:SetGrowth(db.growth)
	else
		bar:SetGrowth("RIGHT")
	end
	if db.place then
		bar:ClearAllPoints()
		bar:SetPoint(unpack(db.place))
	else
		bar:ClearAllPoints()
		bar:SetAllPoints(bar:GetParent())
	end
	if db.bar.textures.backdrop then
		bar:SetBackdropTexture(db.bar.textures.backdrop:GetPath())
		if db.bar.backdropmultiplier then
			bar:SetBackdropMultiplier(db.bar.backdropmultiplier)
		else
			bar:SetBackdropMultiplier(nil)
		end
	else
		bar:SetBackdropTexture("")
	end
	if db.bar.textures.normal then
		bar:SetStatusBarTexture(db.bar.textures.normal:GetPath())
	else
		bar:SetStatusBarTexture("") -- weird. but might have a bar with only overlay and spark? :/
	end
	if db.bar.textures.overlay then
		bar:SetOverlayTexture(db.bar.textures.overlay:GetPath())
	else
		bar:SetOverlayTexture("")
	end
	if db.bar.textures.glow then
		bar:SetThreatTexture(db.bar.textures.glow:GetPath())
	else
		bar:SetThreatTexture("")
	end	
	if bar.Threat then
		if db.textures.threat then 
			updateTexture(bar.Threat, db.textures.threat)
			bar.Threat.enabled = true
		else
			bar.Threat.enabled = false
			bar.Threat:Hide()
		end
	end
	if bar.Spark then
		if db.spark then
			bar.Spark:SetSize(db.spark.texture:GetTexSize(), bar:GetHeight())
			bar.Spark:SetTexture(db.spark.texture:GetPath())
			bar.Spark:SetAlpha(db.spark.alpha)
			bar.Spark:ClearAllPoints()
			bar.Spark:SetPoint(db.spark.texture:GetPoint(), bar:GetStatusBarTexture(), db.spark.texture:GetPoint())
		else
			bar.Spark:SetTexture("")
		end
	end
end

local barList = { "Health", "Power", "AltPowerBar", "Castbar" }
local function updateBars(frame, db)
	for _,t in ipairs(barList) do
		if frame[t] then
			local db = db and db.bars and db.bars[t:lower()]
			if db then 
				updateBar(frame[t], db)
				updateTextures(frame[t], db)
				if frame[t].OverlayFrame then
					if db and db.texframe then
						frame[t].OverlayFrame:SetSize(unpack(db.texframe.size))
						frame[t].OverlayFrame:ClearAllPoints()
						frame[t].OverlayFrame:SetPoint(db.texframe.place[1], frame[t], unpack(db.texframe.place)) -- bad hack, must add proper treatment later
					else
						frame[t].OverlayFrame:SetAllPoints(frame[t])
					end
				end
				frame:EnableElement(t)
			else
				frame:DisableElement(t)
			end
		end
	end
end

local function updateFontString(fontString, db, anchor)
	if db then
		fontString:ClearAllPoints()
		if anchor then
			local point, x, y = unpack(db.place)
			fontString:SetPoint(point, anchor, point, x, y)
		else
			fontString:SetPoint(unpack(db.place))
		end
		fontString:SetHeight(db.size)
		fontString:SetFontObject(db.fontobject)
		fontString:SetFontSize(db.fontsize or db.size)
		fontString:SetFontStyle(db.fontstyle)
		fontString:SetShadowOffset(unpack(db.shadowoffset))
		fontString:SetShadowColor(unpack(db.shadowcolor))
		fontString:SetTextColor(unpack(db.color))
		if fontString.frame and fontString.frame.Tag then
			fontString.frame:Tag(fontString, db.tag or "")
		end
	else
		if fontString.frame and fontString.frame.Tag then
			fontString.frame:Tag(fontString, "")
		end
		fontString:SetText("")
	end
end

local stringList = { "CombatFeedbackText", "HealthText", "NameText", "PowerText", "LeaderText", "LootText", "DruidManaText" }
local function updateFontStrings(frame, db)
	for _,t in ipairs(stringList) do
		if frame[t] then
			local db = db and db.fontstrings and db.fontstrings[t:lower()]
			updateFontString(frame[t], db)
		end
	end
end

-- postupdate the style of a specific frame
-- will check for all known bars, widgets, fonstrings and style according to theme
-- NOTE: db here is NOT the module user database, it's the static theme data!
function prototype:PostUpdate(frame)
	updateConfig() -- update theme reference
	local db = T[self:GetName()] -- get theme data for this frame type

	frame:SetSize(unpack(db.size)) -- size the frame

	if db.strata then
		frame:SetFrameStrata(db.strata)
	end
	if db.level then
		frame:SetFrameLevel(db.level)
	end

	updateTextures(frame, db) -- main frame textures
	updateBars(frame, db) -- bars and their textures * will disable/enable elements
	updateFontStrings(frame, db) -- common fontstrings and their tags
	
	
	-- alternate power
	if frame.AltPowerBarWidget then
		if db.widgets and db.widgets.altpower then
			LMP:NewChain(frame.AltPowerBarWidget) :SetSize(unpack(db.widgets.altpower.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.altpower.place)) :EndChain()
			LMP:NewChain(frame.AltPowerBarWidget.bar) :SetStatusBarColor(unpack(db.widgets.altpower.bar.color)) :SetStatusBarTexture(db.widgets.altpower.bar.textures.normal:GetPath()) :SetSize(unpack(db.widgets.altpower.bar.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.altpower.bar.place)) :EndChain()
			LMP:NewChain(frame.AltPowerBarWidget.bar.overlay) :SetTexture(db.widgets.altpower.bar.textures.overlay:GetPath()) :EndChain()
			LMP:NewChain(frame.AltPowerBarWidget.backdrop) :SetTexture(db.widgets.altpower.textures.backdrop:GetPath()) :SetSize(db.widgets.altpower.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.altpower.textures.backdrop:GetPoint()) :EndChain()
			LMP:NewChain(frame.AltPowerBarWidget.overlay) :SetTexture(db.widgets.altpower.textures.overlay:GetPath()) :SetSize(db.widgets.altpower.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.altpower.textures.overlay:GetPoint()) :EndChain()
			updateFontString(frame.AltPowerBarWidget.bar.value, db.widgets.altpower.bar.value)
			frame:EnableElement("AltPowerBarWidget")
		else
			frame:DisableElement("AltPowerBarWidget")
		end
	end

	-- auras
	if frame.Auras then
		if db.widgets and db.widgets.auras then
			frame.Auras.size = db.widgets.auras.auraSize - 2
			frame.Auras.spacing = db.widgets.auras.padding + 2
			frame.Auras.initialAnchor = db.widgets.auras.initialAnchor
			frame.Auras["growth-y"] = db.widgets.auras.growthy
			frame.Auras["growth-x"] = db.widgets.auras.growthx
			frame.Auras.onlyShowPlayer = db.widgets.auras.onlyShowPlayer
			frame.Auras.onlyShort = db.widgets.auras.onlyShort
			frame.Auras.num = db.widgets.auras.columns * db.widgets.auras.rows
			frame.Auras:SetSize(db.widgets.auras.auraSize*db.widgets.auras.columns + db.widgets.auras.padding*(db.widgets.auras.columns-1), db.widgets.auras.auraSize*db.widgets.auras.rows + db.widgets.auras.padding*(db.widgets.auras.rows-1))
			frame.Auras:ClearAllPoints()
			frame.Auras:SetPoint(unpack(db.widgets.auras.place))
			frame.Auras.disableCooldown = true
			frame:EnableElement("Auras")
			frame.Auras:ForceUpdate()
			if not frame._forceUpdateAuras then
				frame._forceUpdateAuras = function() frame.Auras:ForceUpdate() end
			end
			frame:RegisterEvent("PLAYER_REGEN_DISABLED", frame._forceUpdateAuras)
			frame:RegisterEvent("PLAYER_REGEN_ENABLED", frame._forceUpdateAuras)
			if frame.module.db.profile.auras.showAuras then
				frame.Auras:Show()
			else
				frame.Auras:Hide()
			end
		else
			frame.Auras:Hide()
			if frame._forceUpdateAuras then
				frame:UnregisterEvent("PLAYER_REGEN_DISABLED", frame._forceUpdateAuras)
				frame:UnregisterEvent("PLAYER_REGEN_ENABLED", frame._forceUpdateAuras)
			end
			frame:DisableElement("Auras")
		end
	end
	if frame.Buffs then
		if db.widgets and db.widgets.buffs then
			frame.Buffs.size = db.widgets.buffs.auraSize - 2
			frame.Buffs.spacing = db.widgets.buffs.padding + 2
			frame.Buffs.initialAnchor = db.widgets.buffs.initialAnchor
			frame.Buffs["growth-y"] = db.widgets.buffs.growthy
			frame.Buffs["growth-x"] = db.widgets.buffs.growthx
			frame.Buffs.onlyShowPlayer = db.widgets.buffs.onlyShowPlayer
			frame.Buffs.num = db.widgets.buffs.columns * db.widgets.buffs.rows
			frame.Buffs:SetSize(db.widgets.buffs.auraSize*db.widgets.buffs.columns + db.widgets.buffs.padding*(db.widgets.buffs.columns-1), db.widgets.buffs.auraSize*db.widgets.buffs.rows + db.widgets.buffs.padding*(db.widgets.buffs.rows-1))
			frame.Buffs:ClearAllPoints()
			frame.Buffs:SetPoint(unpack(db.widgets.buffs.place))
			frame.Buffs.disableCooldown = true
			frame:EnableElement("Buffs")
			frame.Buffs:ForceUpdate()
			if not frame._forceUpdateBuffs then
				frame._forceUpdateBuffs = function() frame.Buffs:ForceUpdate() end
			end
			frame:RegisterEvent("PLAYER_REGEN_DISABLED", frame._forceUpdateBuffs)
			frame:RegisterEvent("PLAYER_REGEN_ENABLED", frame._forceUpdateBuffs)
			if frame.module.db.profile.auras.showBuffs then
				frame.Buffs:Show()
			else
				frame.Buffs:Hide()
			end
		else
			frame.Buffs:Hide()
			if frame._forceUpdateBuffs then
				frame:UnregisterEvent("PLAYER_REGEN_DISABLED", frame._forceUpdateBuffs)
				frame:UnregisterEvent("PLAYER_REGEN_ENABLED", frame._forceUpdateBuffs)
			end
			frame:DisableElement("Buffs")
		end
	end
	if frame.Debuffs then
		if db.widgets and db.widgets.debuffs then
			frame.Debuffs.size = db.widgets.debuffs.auraSize - 2
			frame.Debuffs.spacing = db.widgets.debuffs.padding + 2
			frame.Debuffs.initialAnchor = db.widgets.debuffs.initialAnchor
			frame.Debuffs["growth-y"] = db.widgets.debuffs.growthy
			frame.Debuffs["growth-x"] = db.widgets.debuffs.growthx
			frame.Debuffs.onlyShowPlayer = db.widgets.debuffs.onlyShowPlayer
			frame.Debuffs.num = db.widgets.debuffs.columns * db.widgets.debuffs.rows
			frame.Debuffs:SetSize(db.widgets.debuffs.auraSize*db.widgets.debuffs.columns + db.widgets.debuffs.padding*(db.widgets.debuffs.columns-1), db.widgets.debuffs.auraSize*db.widgets.debuffs.rows + db.widgets.debuffs.padding*(db.widgets.debuffs.rows-1))
			frame.Debuffs:ClearAllPoints()
			frame.Debuffs:SetPoint(unpack(db.widgets.debuffs.place))
			frame.Debuffs.disableCooldown = true
			frame:EnableElement("Debuffs")
			frame.Debuffs:ForceUpdate()
			if not frame._forceUpdateDebuffs then
				frame._forceUpdateDebuffs = function() frame.Debuffs:ForceUpdate() end
			end
			frame:RegisterEvent("PLAYER_REGEN_DISABLED", frame._forceUpdateDebuffs)
			frame:RegisterEvent("PLAYER_REGEN_ENABLED", frame._forceUpdateDebuffs)

		else
			if frame._forceUpdateDebuffs then
				frame:UnregisterEvent("PLAYER_REGEN_DISABLED", frame._forceUpdateDebuffs)
				frame:UnregisterEvent("PLAYER_REGEN_ENABLED", frame._forceUpdateDebuffs)
			end
			frame:DisableElement("Debuffs")
		end
	end

	-- combat status
	if frame.Combat then
		if db.widgets and db.widgets.combat then
			frame.Combat:SetSize(unpack(db.widgets.combat.size))
			frame.Combat:ClearAllPoints()
			frame.Combat:SetPoint(unpack(db.widgets.combat.place))
			frame.Combat:SetTexture(db.widgets.combat.texture)
			frame.Combat:SetTexCoord(unpack(db.widgets.combat.texcoord))
			frame:EnableElement("Combat")
		else
			frame:DisableElement("Combat")
		end
	end
	
	-- rest icon
	if frame.Resting then
		if db.widgets and db.widgets.resting then
			frame.Resting:SetSize(unpack(db.widgets.resting.size))
			frame.Resting:ClearAllPoints()
			if db.widgets.resting.attachToChild then
				local point, x, y = unpack(db.widgets.resting.place)
				frame.Resting:SetPoint(point, frame[db.widgets.resting.attachToChild], db.widgets.resting.attachPoint, x, y )
			else
				frame.Resting:SetPoint(unpack(db.widgets.resting.place))
			end
			frame.Resting:SetTexture(db.widgets.resting.texture)
			frame.Resting:SetTexCoord(unpack(db.widgets.resting.texcoord))
			frame:EnableElement("Resting")
		else
			frame.Resting:SetTexCoord(0, .5, 0, .5)
			frame:DisableElement("Resting")
		end
	end
	
	-- raid icons
	if frame.RaidIcon then
		if db.widgets and db.widgets.raidicon then
			frame.RaidIcon:SetSize(unpack(db.widgets.raidicon.size))
			frame.RaidIcon:ClearAllPoints()
			frame.RaidIcon:SetPoint(unpack(db.widgets.raidicon.place))
			frame.RaidIcon:SetTexture(db.widgets.raidicon.texture)
			frame:EnableElement("RaidIcon")
		else
			frame:DisableElement("RaidIcon")
		end
	end
	
	-- master looter icon
	if frame.MasterLooter then
		if db.widgets and db.widgets.looticon then
			frame.MasterLooter:SetSize(unpack(db.widgets.looticon.size))
			frame.MasterLooter:ClearAllPoints()
			frame.MasterLooter:SetPoint(unpack(db.widgets.looticon.place))
			frame.MasterLooter:SetTexture(db.widgets.looticon.texture)
			frame:EnableElement("MasterLooter")
		else
			frame:DisableElement("MasterLooter")
		end
	end

	-- group leader icon
	if frame.Leader then
		if db.widgets and db.widgets.leadericon then
			frame.Leader:SetSize(unpack(db.widgets.leadericon.size))
			frame.Leader:ClearAllPoints()
			frame.Leader:SetPoint(unpack(db.widgets.leadericon.place))
			frame.Leader:SetTexture(db.widgets.leadericon.texture)
			frame:EnableElement("Leader")
		else
			frame:DisableElement("Leader")
		end
	end

	-- group assistant icon
	if frame.Assistant then
		if db.widgets and db.widgets.assisticon then
			frame.Assistant:SetSize(unpack(db.widgets.assisticon.size))
			frame.Assistant:ClearAllPoints()
			frame.Assistant:SetPoint(unpack(db.widgets.assisticon.place))
			frame.Assistant:SetTexture(db.widgets.assisticon.texture)
			frame:EnableElement("Assistant")
		else
			frame:DisableElement("Assistant")
		end
	end

	-- group role icon
	if frame.LFDRole then
		if db.widgets and db.widgets.roleicon then
			frame.LFDRole:SetSize(unpack(db.widgets.roleicon.size))
			frame.LFDRole:ClearAllPoints()
			frame.LFDRole:SetPoint(unpack(db.widgets.roleicon.place))
			frame.LFDRole:SetTexture(db.widgets.roleicon.texture)
			frame:EnableElement("LFDRole")
		else
			frame:DisableElement("LFDRole")
		end
	end

	-- threat
	if frame.Threat then
		-- if db.widgets and db.widgets.threat then
			-- frame.Threat:SetSize(unpack(db.widgets.threat.size))
			-- frame.Threat:ClearAllPoints()
			-- frame.Threat:SetPoint(unpack(db.widgets.threat.place))
			-- frame.Threat.alpha = db.widgets.threat.alpha
			-- frame:EnableElement("Threat")
		-- else
			-- frame:DisableElement("Threat")
		-- end
	end
	
	-- portraits
	if frame.Portrait then
		if db.widgets and db.widgets.portrait then
			frame.Portrait:SetSize(unpack(db.widgets.portrait.size))
			frame.Portrait:ClearAllPoints()
			frame.Portrait:SetPoint(unpack(db.widgets.portrait.place))
			frame.Portrait.alpha = db.widgets.portrait.alpha
			
			updateTextures(frame.Portrait, db.widgets.portrait)
			
			local backdrop = frame:CreateTexture(nil, "BACKGROUND")
			backdrop:SetAllPoints(frame.Portrait)
			backdrop:SetTexture(0,0,0,.75)
			frame.Portrait.OverlayFrame:SetBackdrop({
				bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
				edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
				edgeSize = 1, tile = false
			})
			frame.Portrait.OverlayFrame:SetBackdropColor(0,0,0,.75)
			frame.Portrait.OverlayFrame:SetBackdropBorderColor(0,0,0,1)
			frame:EnableElement("Portrait")
		else
			frame:DisableElement("Portrait")
		end
	end
	
	-- heal prediction
	if frame.HealPrediction then
		local predict = frame.HealPrediction
		local width = frame.Health:GetWidth()
		local growth = frame.Health:GetGrowth()
		if predict.myBar then
			LMP:NewChain(predict.myBar) :SetWidth(width) :SetGrowth(growth) :ClearAllPoints() :SetPoint("TOP", frame.Health:GetStatusBarTexture(), "TOP") :SetPoint("BOTTOM", frame.Health:GetStatusBarTexture(), "BOTTOM") :SetPoint(mirror[growth], frame.Health:GetStatusBarTexture(), growth) :EndChain()
		end
		if predict.otherBar then
			LMP:NewChain(predict.otherBar) :SetWidth(width) :SetGrowth(growth) :ClearAllPoints() :SetPoint("TOP", frame.Health:GetStatusBarTexture(), "TOP") :SetPoint("BOTTOM", frame.Health:GetStatusBarTexture(), "BOTTOM") :SetPoint(mirror[growth], frame.Health:GetStatusBarTexture(), growth) :EndChain()
		end
		if predict.absorbBar then
			LMP:NewChain(predict.absorbBar) :SetWidth(width) :SetGrowth(growth) :ClearAllPoints() :SetPoint("TOP", frame.Health:GetStatusBarTexture(), "TOP") :SetPoint("BOTTOM", frame.Health:GetStatusBarTexture(), "BOTTOM") :SetPoint(mirror[growth], frame.Health:GetStatusBarTexture(), growth) :EndChain()
		end
		if predict.healAbsorbBar then
			LMP:NewChain(predict.healAbsorbBar) :SetWidth(width) :SetGrowth(growth) :ClearAllPoints() :SetPoint("TOP", frame.Health:GetStatusBarTexture(), "TOP") :SetPoint("BOTTOM", frame.Health:GetStatusBarTexture(), "BOTTOM") :SetPoint(mirror[growth], frame.Health:GetStatusBarTexture(), growth) :EndChain()
		end
	end
	
		-- classbar
	if frame.PlayerClassBar then
		if frame.ComboPointsWidget then
			if db.widgets and db.widgets.combopoints then
				LMP:NewChain(frame.ComboPointsWidget) :SetSize(unpack(db.widgets.combopoints.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.combopoints.place)) :EndChain()
				LMP:NewChain(frame.ComboPointsWidget.backdrop) :SetTexture(db.widgets.combopoints.textures.backdrop:GetPath()) :SetSize(db.widgets.combopoints.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.combopoints.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.ComboPointsWidget.overlay) :SetTexture(db.widgets.combopoints.textures.overlay:GetPath()) :SetSize(db.widgets.combopoints.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.combopoints.textures.overlay:GetPoint()) :EndChain()
				for i = 1, 5 do
					LMP:NewChain(frame.ComboPointsWidget[i]) :SetTexture(db.widgets.combopoints.points[i].texture:GetPath()) :SetSize(db.widgets.combopoints.points[i].texture:GetTexSize()) :ClearAllPoints() :SetPoint(unpack(db.widgets.combopoints.points[i].place)) :EndChain()
					LMP:NewChain(frame.ComboPointsWidget[i].gloss) :SetTexture(db.widgets.combopoints.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.combopoints.textures.pillgloss:GetAlpha()) :EndChain()
				end
				frame:EnableElement("ComboPointsWidget")
			else
				frame:DisableElement("ComboPointsWidget")
			end
			if frame.ComboPointsWidget.Anticipation then
				for i = 6, 10 do
					LMP:NewChain(frame.ComboPointsWidget[i]) :SetTexture(db.widgets.combopoints.points[i].texture:GetPath()) :SetSize(db.widgets.combopoints.points[i].texture:GetTexSize()) :ClearAllPoints() :SetPoint(unpack(db.widgets.combopoints.points[i].place)) :EndChain()
				end
			end
		end
		if frame.RuneWidget then
			if db.widgets and db.widgets.runes then
				LMP:NewChain(frame.RuneWidget) :SetSize(unpack(db.widgets.runes.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.runes.place)) :EndChain()
				LMP:NewChain(frame.RuneWidget.backdrop) :SetTexture(db.widgets.runes.textures.backdrop:GetPath()) :SetSize(db.widgets.runes.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.runes.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.RuneWidget.overlay) :SetTexture(db.widgets.runes.textures.overlay:GetPath()) :SetSize(db.widgets.runes.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.runes.textures.overlay:GetPoint()) :EndChain()
				for i = 1, 6 do
					LMP:NewChain(frame.RuneWidget[i]) :SetStatusBarTexture(db.widgets.runes.textures.pill:GetPath()) :SetSize(db.widgets.runes.size[1]/6, db.widgets.runes.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.runes.size[1]/6)*(i-1), 0) :EndChain()
					LMP:NewChain(frame.RuneWidget[i].bg) :SetTexture(db.widgets.runes.textures.pill:GetPath()) :EndChain()
					LMP:NewChain(frame.RuneWidget[i].gloss) :SetTexture(db.widgets.runes.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.runes.textures.pillgloss:GetAlpha()) :EndChain()
					updateFontString(frame.RuneWidget[i].value, db.widgets.runes.values)
				end	
				frame:EnableElement("RuneWidget")
			else
				frame:DisableElement("RuneWidget")
			end
		end
		if frame.TotemWidget then
			if db.widgets and db.widgets.totems then
				LMP:NewChain(frame.TotemWidget) :SetSize(unpack(db.widgets.totems.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.totems.place)) :EndChain()
				LMP:NewChain(frame.TotemWidget.backdrop) :SetTexture(db.widgets.totems.textures.backdrop:GetPath()) :SetSize(db.widgets.totems.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.totems.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.TotemWidget.overlay) :SetTexture(db.widgets.totems.textures.overlay:GetPath()) :SetSize(db.widgets.totems.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.totems.textures.overlay:GetPoint()) :EndChain()
				for i = 1, MAX_TOTEMS do
					LMP:NewChain(frame.TotemWidget[i]) :SetStatusBarTexture(db.widgets.totems.textures.pill:GetPath()) :SetSize(db.widgets.totems.size[1]/MAX_TOTEMS, db.widgets.totems.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.totems.size[1]/MAX_TOTEMS)*(i-1), 0) :EndChain()
					LMP:NewChain(frame.TotemWidget[i].bg) :SetTexture(db.widgets.totems.textures.pill:GetPath()) :EndChain()
					LMP:NewChain(frame.TotemWidget[i].gloss) :SetTexture(db.widgets.totems.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.totems.textures.pillgloss:GetAlpha()) :EndChain()
					updateFontString(frame.TotemWidget[i].value, db.widgets.totems.values, frame.TotemWidget[i])
					if db.widgets.totems.spark then
						frame.TotemWidget[i].spark:SetSize(db.widgets.totems.spark.texture:GetTexSize(), frame.TotemWidget[i]:GetHeight())
						frame.TotemWidget[i].spark:SetTexture(db.widgets.totems.spark.texture:GetPath())
						frame.TotemWidget[i].spark:SetAlpha(db.widgets.totems.spark.alpha)
						frame.TotemWidget[i].spark:ClearAllPoints()
						frame.TotemWidget[i].spark:SetPoint(db.widgets.totems.spark.texture:GetPoint(), frame.TotemWidget[i]:GetStatusBarTexture(), db.widgets.totems.spark.texture:GetPoint())
					else
						frame.TotemWidget[i].spark:SetTexture("")
					end
				end	
				frame:EnableElement("TotemWidget")
			else
				frame:DisableElement("TotemWidget")
			end
		end
		if frame.EclipseWidget then
			if db.widgets and db.widgets.eclipsebar then
				LMP:NewChain(frame.EclipseWidget) :SetSize(unpack(db.widgets.eclipsebar.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.eclipsebar.place)) :EndChain()

				LMP:NewChain(frame.EclipseWidget.LunarBar) :SetStatusBarColor(unpack(db.widgets.eclipsebar.bar.colors.lunar)) :SetStatusBarTexture(db.widgets.eclipsebar.bar.textures.normal:GetPath()) :SetSize(unpack(db.widgets.eclipsebar.bar.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.eclipsebar.bar.place)) :EndChain()
				LMP:NewChain(frame.EclipseWidget.SolarBar) :SetStatusBarColor(unpack(db.widgets.eclipsebar.bar.colors.solar)) :SetStatusBarTexture(db.widgets.eclipsebar.bar.textures.normal:GetPath()) :SetSize(unpack(db.widgets.eclipsebar.bar.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.eclipsebar.bar.place)) :EndChain()
				LMP:NewChain(frame.EclipseWidget.SolarBar.overlay) :SetTexture(db.widgets.eclipsebar.bar.textures.overlay:GetPath()) :EndChain()

				LMP:NewChain(frame.EclipseWidget.backdrop) :SetTexture(db.widgets.eclipsebar.textures.backdrop:GetPath()) :SetSize(db.widgets.eclipsebar.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.eclipsebar.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.EclipseWidget.overlay) :SetTexture(db.widgets.eclipsebar.textures.overlay:GetPath()) :SetSize(db.widgets.eclipsebar.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.eclipsebar.textures.overlay:GetPoint()) :EndChain()

				if db.widgets.eclipsebar.bar.spark then
					frame.EclipseWidget.SolarBar.Spark:SetSize(db.widgets.eclipsebar.bar.spark.texture:GetTexSize(), frame.EclipseWidget.SolarBar:GetHeight())
					frame.EclipseWidget.SolarBar.Spark:SetTexture(db.widgets.eclipsebar.bar.spark.texture:GetPath())
					frame.EclipseWidget.SolarBar.Spark:SetAlpha(db.widgets.eclipsebar.bar.spark.alpha)
					frame.EclipseWidget.SolarBar.Spark:ClearAllPoints()
					frame.EclipseWidget.SolarBar.Spark:SetPoint(db.widgets.eclipsebar.bar.spark.texture:GetPoint(), frame.EclipseWidget.SolarBar:GetStatusBarTexture(), db.widgets.eclipsebar.bar.spark.texture:GetPoint())
				else
					frame.EclipseWidget.SolarBar.Spark:SetTexture("")
				end
				
				updateFontString(frame.EclipseWidget.Value, db.widgets.eclipsebar.bar.value)
				updateFontString(frame.EclipseWidget.Guide, db.widgets.eclipsebar.bar.guide)

				frame:EnableElement("EclipseWidget")
				frame.EclipseWidget:ForceUpdate()
			else
				frame:DisableElement("EclipseWidget")
			end
		end
		if frame.ArcaneChargesWidget then
			if db.widgets and db.widgets.arcanecharges then
				LMP:NewChain(frame.ArcaneChargesWidget) :SetSize(unpack(db.widgets.arcanecharges.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.arcanecharges.place)) :EndChain()
				LMP:NewChain(frame.ArcaneChargesWidget.backdrop) :SetTexture(db.widgets.arcanecharges.textures.backdrop:GetPath()) :SetSize(db.widgets.arcanecharges.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.arcanecharges.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.ArcaneChargesWidget.overlay) :SetTexture(db.widgets.arcanecharges.textures.overlay:GetPath()) :SetSize(db.widgets.arcanecharges.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.arcanecharges.textures.overlay:GetPoint()) :EndChain()
				LMP:NewChain(frame.ArcaneChargesWidget.timer) :SetBackdropMultiplier(db.widgets.arcanecharges.bar.multiplier or 1/3) :SetStatusBarColor(unpack(db.widgets.arcanecharges.bar.color)) :SetBackdropTexture(db.widgets.arcanecharges.bar.textures.backdrop:GetPath()) :SetStatusBarTexture(db.widgets.arcanecharges.bar.textures.normal:GetPath()) :SetSize(unpack(db.widgets.arcanecharges.bar.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.arcanecharges.bar.place)) :EndChain()
				updateFontString(frame.ArcaneChargesWidget.value, db.widgets.arcanecharges.bar.value)
				for i = 1, 4 do
					LMP:NewChain(frame.ArcaneChargesWidget[i]) :SetTexture(db.widgets.arcanecharges.textures.pill:GetPath()) :SetSize(db.widgets.arcanecharges.size[1]/4, db.widgets.arcanecharges.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.arcanecharges.size[1]/4)*(i-1), 0) :EndChain()
					LMP:NewChain(frame.ArcaneChargesWidget[i].gloss) :SetTexture(db.widgets.arcanecharges.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.arcanecharges.textures.pillgloss:GetAlpha()) :EndChain()
				end
				frame:EnableElement("ArcaneChargesWidget")
			else
				frame:DisableElement("ArcaneChargesWidget")
			end
		end
		if frame.ChiWidget then
			if db.widgets and db.widgets.chi then
				LMP:NewChain(frame.ChiWidget) :SetSize(unpack(db.widgets.chi.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.chi.place)) :EndChain()
				LMP:NewChain(frame.ChiWidget.backdrop) :SetTexture(db.widgets.chi.textures.backdrop:GetPath()) :SetSize(db.widgets.chi.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.chi.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.ChiWidget.overlay) :SetTexture(db.widgets.chi.textures.overlay:GetPath()) :SetSize(db.widgets.chi.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.chi.textures.overlay:GetPoint()) :EndChain()
				local numChi = 4 
				if IsPlayerSpell(115396) then -- ascension 
					numChi = numChi + 1
				end
				if IsPlayerSpell(157411) then -- empowered chi perk
					numChi = numChi + 1
				end
				for i = 1, 6 do
					LMP:NewChain(frame.ChiWidget[i]) :SetTexture(db.widgets.chi.textures.pill:GetPath()) :SetSize(db.widgets.chi.size[1]/numChi, db.widgets.chi.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.chi.size[1]/numChi)*(i-1), 0) :EndChain()
					LMP:NewChain(frame.ChiWidget[i].gloss) :SetTexture(db.widgets.chi.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.chi.textures.pillgloss:GetAlpha()) :EndChain()
				end	
				frame.ChiWidget.numChi = numChi
				function frame.ChiWidget:PostUpdate()
					local numChi = 4 
					if IsPlayerSpell(115396) then -- ascension 
						numChi = numChi + 1
					end
					if IsPlayerSpell(157411) then -- empowered chi perk
						numChi = numChi + 1
					end
					if self.numChi ~= numChi then
						for i = 1, numChi do
							LMP:NewChain(self[i]) :SetTexture(db.widgets.chi.textures.pill:GetPath()) :SetSize(db.widgets.chi.size[1]/numChi, db.widgets.chi.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.chi.size[1]/numChi)*(i-1), 0) :EndChain()
						end	
						self.numChi = numChi
					end
				end
				frame:EnableElement("ChiWidget")
			else
				frame:DisableElement("ChiWidget")
			end
		end
		if frame.HolyPowerWidget then
			if db.widgets and db.widgets.holypower then
				LMP:NewChain(frame.HolyPowerWidget) :SetSize(unpack(db.widgets.holypower.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.holypower.place)) :EndChain()
				LMP:NewChain(frame.HolyPowerWidget.backdrop) :SetTexture(db.widgets.holypower.textures.backdrop:GetPath()) :SetSize(db.widgets.holypower.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.holypower.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.HolyPowerWidget.overlay) :SetTexture(db.widgets.holypower.textures.overlay:GetPath()) :SetSize(db.widgets.holypower.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.holypower.textures.overlay:GetPoint()) :EndChain()
				local numPower = LEGION and 5 or UnitLevel("player") >= 85 and 5 or 3
				for i = 1, 5 do
					LMP:NewChain(frame.HolyPowerWidget[i]) :SetTexture(db.widgets.holypower.textures.pill:GetPath()) :SetSize(db.widgets.holypower.size[1]/numPower, db.widgets.holypower.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.holypower.size[1]/numPower)*(i-1), 0) :EndChain()
					LMP:NewChain(frame.HolyPowerWidget[i].gloss) :SetTexture(db.widgets.holypower.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.holypower.textures.pillgloss:GetAlpha()) :EndChain()
					-- updateFontString(frame.HolyPowerWidget[i].value, db.widgets.holypower.values)
				end	
				frame.HolyPowerWidget.numPower = numPower
				function frame.HolyPowerWidget:PostUpdate()
					local numPower = LEGION and 5 or UnitLevel("player") >= 85 and 5 or 3
					if self.numPower ~= numPower then
						for i = 1, numPower do
							LMP:NewChain(self[i]) :SetTexture(db.widgets.chi.textures.pill:GetPath()) :SetSize(db.widgets.chi.size[1]/numPower, db.widgets.chi.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.chi.size[1]/numPower)*(i-1), 0) :EndChain()
						end
						self.numPower = numPower
					end
				end
				frame:EnableElement("HolyPowerWidget")
			else
				frame:DisableElement("HolyPowerWidget")
			end
		end
		if frame.ShadowOrbsWidget then
			if db.widgets and db.widgets.shadoworbs then
				LMP:NewChain(frame.ShadowOrbsWidget) :SetSize(unpack(db.widgets.shadoworbs.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.shadoworbs.place)) :EndChain()
				LMP:NewChain(frame.ShadowOrbsWidget.backdrop) :SetTexture(db.widgets.shadoworbs.textures.backdrop:GetPath()) :SetSize(db.widgets.shadoworbs.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.shadoworbs.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.ShadowOrbsWidget.overlay) :SetTexture(db.widgets.shadoworbs.textures.overlay:GetPath()) :SetSize(db.widgets.shadoworbs.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.shadoworbs.textures.overlay:GetPoint()) :EndChain()
				local numOrbs = IsPlayerSpell(157217) and 5 or 3
				for i = 1, 5 do
					LMP:NewChain(frame.ShadowOrbsWidget[i]) :SetTexture(db.widgets.shadoworbs.textures.pill:GetPath()) :SetSize(db.widgets.shadoworbs.size[1]/numOrbs, db.widgets.shadoworbs.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.shadoworbs.size[1]/numOrbs)*(i-1), 0) :EndChain()
					LMP:NewChain(frame.ShadowOrbsWidget[i].gloss) :SetTexture(db.widgets.shadoworbs.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.shadoworbs.textures.pillgloss:GetAlpha()) :EndChain()
				end
				frame.ShadowOrbsWidget.numOrbs = numOrbs
				function frame.ShadowOrbsWidget:PostUpdate()
					local numOrbs = IsPlayerSpell(157217) and 5 or 3
					if self.numOrbs ~= numOrbs then
						for i = 1, numOrbs do
							LMP:NewChain(self[i]) :SetTexture(db.widgets.shadoworbs.textures.pill:GetPath()) :SetSize(db.widgets.shadoworbs.size[1]/numOrbs, db.widgets.shadoworbs.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.shadoworbs.size[1]/numOrbs)*(i-1), 0) :EndChain()
						end	
						self.numOrbs = numOrbs
					end
				end
				frame:EnableElement("ShadowOrbsWidget")
			else
				frame:DisableElement("ShadowOrbsWidget")
			end
		end
		if frame.BurningEmbersWidget then
			if db.widgets and db.widgets.burningembers then
				LMP:NewChain(frame.BurningEmbersWidget) :SetSize(unpack(db.widgets.burningembers.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.burningembers.place)) :EndChain()
				LMP:NewChain(frame.BurningEmbersWidget.backdrop) :SetTexture(db.widgets.burningembers.textures.backdrop:GetPath()) :SetSize(db.widgets.burningembers.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.burningembers.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.BurningEmbersWidget.overlay) :SetTexture(db.widgets.burningembers.textures.overlay:GetPath()) :SetSize(db.widgets.burningembers.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.burningembers.textures.overlay:GetPoint()) :EndChain()
				for i = 1, 4 do
					LMP:NewChain(frame.BurningEmbersWidget[i]) :SetStatusBarTexture(db.widgets.burningembers.textures.pill:GetPath()) :SetSize(db.widgets.burningembers.size[1]/4, db.widgets.burningembers.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.burningembers.size[1]/4)*(i-1), 0) :EndChain()
					LMP:NewChain(frame.BurningEmbersWidget[i].gloss) :SetTexture(db.widgets.burningembers.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.burningembers.textures.pillgloss:GetAlpha()) :EndChain()
					updateFontString(frame.BurningEmbersWidget[i].value, db.widgets.burningembers.values)
				end
				frame:EnableElement("BurningEmbersWidget")
			else
				frame:DisableElement("BurningEmbersWidget")
			end
		end
		if frame.SoulShardsWidget then
			if db.widgets and db.widgets.soulshards then
				LMP:NewChain(frame.SoulShardsWidget) :SetSize(unpack(db.widgets.soulshards.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.soulshards.place)) :EndChain()
				LMP:NewChain(frame.SoulShardsWidget.backdrop) :SetTexture(db.widgets.soulshards.textures.backdrop:GetPath()) :SetSize(db.widgets.soulshards.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.soulshards.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.SoulShardsWidget.overlay) :SetTexture(db.widgets.soulshards.textures.overlay:GetPath()) :SetSize(db.widgets.soulshards.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.soulshards.textures.overlay:GetPoint()) :EndChain()
				local num_shards = LEGION and 5 or 4
				for i = 1, num_shards do
					LMP:NewChain(frame.SoulShardsWidget[i]) :SetTexture(db.widgets.soulshards.textures.pill:GetPath()) :SetSize(db.widgets.soulshards.size[1]/num_shards, db.widgets.soulshards.size[2]) :ClearAllPoints() :SetPoint("BOTTOMLEFT", (db.widgets.soulshards.size[1]/num_shards)*(i-1), 0) :EndChain()
					LMP:NewChain(frame.SoulShardsWidget[i].gloss) :SetTexture(db.widgets.soulshards.textures.pillgloss:GetPath()) :SetAlpha(db.widgets.soulshards.textures.pillgloss:GetAlpha()) :EndChain()
				end
				frame:EnableElement("SoulShardsWidget")
			else
				frame:DisableElement("SoulShardsWidget")
			end
		end
		if frame.DemonicFuryWidget then
			if db.widgets and db.widgets.demonicfury then
				LMP:NewChain(frame.DemonicFuryWidget) :SetSize(unpack(db.widgets.demonicfury.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.demonicfury.place)) :EndChain()
				LMP:NewChain(frame.DemonicFuryWidget.bar) :SetStatusBarColor(unpack(db.widgets.demonicfury.bar.color)) :SetStatusBarTexture(db.widgets.demonicfury.bar.textures.normal:GetPath()) :SetSize(unpack(db.widgets.demonicfury.bar.size)) :ClearAllPoints() :SetPoint(unpack(db.widgets.demonicfury.bar.place)) :EndChain()
				LMP:NewChain(frame.DemonicFuryWidget.bar.overlay) :SetTexture(db.widgets.demonicfury.bar.textures.overlay:GetPath()) :EndChain()
				LMP:NewChain(frame.DemonicFuryWidget.backdrop) :SetTexture(db.widgets.demonicfury.textures.backdrop:GetPath()) :SetSize(db.widgets.demonicfury.textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.demonicfury.textures.backdrop:GetPoint()) :EndChain()
				LMP:NewChain(frame.DemonicFuryWidget.overlay) :SetTexture(db.widgets.demonicfury.textures.overlay:GetPath()) :SetSize(db.widgets.demonicfury.textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(db.widgets.demonicfury.textures.overlay:GetPoint()) :EndChain()
				if db.widgets.demonicfury.bar.spark then
					frame.DemonicFuryWidget.bar.spark:SetSize(db.widgets.demonicfury.bar.spark.texture:GetTexSize(), frame.DemonicFuryWidget.bar:GetHeight())
					frame.DemonicFuryWidget.bar.spark:SetTexture(db.widgets.demonicfury.bar.spark.texture:GetPath())
					frame.DemonicFuryWidget.bar.spark:SetAlpha(db.widgets.demonicfury.bar.spark.alpha)
					frame.DemonicFuryWidget.bar.spark:ClearAllPoints()
					frame.DemonicFuryWidget.bar.spark:SetPoint(db.widgets.demonicfury.bar.spark.texture:GetPoint(), frame.DemonicFuryWidget.bar:GetStatusBarTexture(), db.widgets.demonicfury.bar.spark.texture:GetPoint())
				else
					frame.DemonicFuryWidget.bar.spark:SetTexture("")
				end
				updateFontString(frame.DemonicFuryWidget.bar.value, db.widgets.demonicfury.bar.value)
				frame:EnableElement("DemonicFuryWidget")
			else
				frame:DisableElement("DemonicFuryWidget")
			end
		end
	end

	-- allow frames to have custom postupdates, 
	-- and pass the theme db to them
	if frame.PostUpdateTheme then
		frame:PostUpdateTheme(db)
	end
	
	-- placeholder graphic for development
	if db.development then
		if not frame.placeHolder then
			if LEGION then
				frame.placeHolder = LMP:NewChain(UIParent:CreateTexture(nil, "ARTWORK")) :SetColorTexture(.1,.6,.1,.5) :SetAllPoints(frame) .__EndChain
			else
				frame.placeHolder = LMP:NewChain(UIParent:CreateTexture(nil, "ARTWORK")) :SetTexture(.1,.6,.1,.5) :SetAllPoints(frame) .__EndChain
			end
			frame.placeHolder.text = LMP:NewChain("FontString", nil, UIParent) :SetDrawLayer("OVERLAY") :SetFontObject(GameFontNormal) :SetText(L[self:GetName()]) :SetPoint("CENTER", frame) .__EndChain
		end
	end
end
prototype.PostUpdate = gUI4:SafeCallWrapper(prototype.PostUpdate)

-- theme update
function prototype:UpdateTheme()
	local name = self:GetName()
	self:ForAll(self.PostUpdate)
end

function prototype:OnEnable()
	self:ForAll("Enable")
end
prototype.OnEnable = gUI4:SafeCallWrapper(prototype.OnEnable)

function prototype:OnDisable()
	self:ForAll("Disable")
end
prototype.OnDisable = gUI4:SafeCallWrapper(prototype.OnDisable)


-------------------------------------------------------------------------------
--	Public API
-------------------------------------------------------------------------------
-- control the load order to allow frames to position relative to their logical parents
local moduleLoadOrder = { 
	"Player", 
	"AltPowerBar", 
	"ClassBar",
	"Pet", 
	"PetTarget",
	"Target", 
	"ToT", 
	"ToTTarget",
	"Focus", 
	"FocusTarget",
	"Boss"
}

-- retrieve a specific unitframe from our registry
function module:GetUnit(name)
	return units[name]
end

-- returns an iterator for all the unitframes from all the modules
function module:GetAllUnits()
	return pairs(units)
end

function module:Lock(mod)
	for frameID, frame in self:GetAllUnits() do
		if mod then
			if frame.module == mod then
				glocks[frame]:StartFadeOut()
			end
		else
			if self.db.profile.modules[frame.module:GetName()] then
				glocks[frame]:StartFadeOut()
			end
		end
	end
end

function module:Unlock(mod)
	if UnitAffectingCombat("player") then return end
	for frameID, frame in self:GetAllUnits() do
		if mod then
			if frame.module == mod then
				glocks[frame]:SetAlpha(0)
				glocks[frame]:Show()
			end
		else
			if self.db.profile.modules[frame.module:GetName()] then
				glocks[frame]:SetAlpha(0)
				glocks[frame]:Show()
			end
		end
	end
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not hasTheme then return end
	for i, name in ipairs(moduleLoadOrder) do
		local mod = self:GetModule(name, true)
		if mod then 
			if mod.ResetLock then
				mod:ResetLock()
			end
		end
	end
	self:ApplySettings()
end

function module:Place(...)
	LMP:Place(...)
end
module.Place = gUI4:SafeCallWrapper(module.Place)

-- fire off theme updates for all submodules
function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(self) then return end
	for name, mod in self:IterateModules() do
		mod:UpdateTheme()
	end
	hasTheme = true
	self:ApplySettings()
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings()
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

-- update position of all frames
function module:UpdatePosition()
	if not hasTheme then return end
	for i, name in ipairs(moduleLoadOrder) do
		if self.db.profile.modules[name] == true then
			local mod = self:GetModule(name, true)
			if mod then
				mod:UpdatePosition()
			end
		end
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:GetModuleData(name)
	local mod = self:GetModule(name)
	return mod, mod.db.profile.auras
end

function module:SetModuleOption(name, option, value)
	local mod, db = self:GetModuleData(name)
	db[option] = value
end

function module:GetModuleOption(name, option)
	local mod, db = self:GetModuleData(name)
	return db[option]
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Auras", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["UnitFrames"],
			args = {
				playerheader = {
					type = "header",
					name = L["Player"],
					order = 101,
				},
				playervisibilityheader = {
					type = "description",
					name = L["\n|cffffd200" .. "Player Aura Visibility" .. "|r"],
					order = 102,
				},
				playervisibilitydescription = {
					type = "description",
					name = L["Select whether or not to show the player aura widgets. Deselecting a widget will override all other settings."],
					order = 103,
				},
				playerbuffs = {
					order = 105,
					type = "toggle",
					name = L["Display Player Buffs"],
					desc = L["Display benefitial auras"],
					get = function() return self:GetModuleOption("Player", "showBuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "showBuffs", value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Buffs then
								if value then
									frame:EnableElement("Buffs")
									frame.Buffs:Show()
									frame.Buffs:ForceUpdate()
								else
									frame.Buffs:Hide()
									frame:DisableElement("Buffs")
								end
							end
						end
					end,
					width = "full"
				},
				playerdebuffs = {
					order = 106, 
					type = "toggle",
					name = L["Display Player Debuffs"],
					desc = L["Display harmful auras"],
					get = function() return self:GetModuleOption("Player", "showDebuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "showDebuffs", value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Debuffs then
								if value then
									frame:EnableElement("Debuffs")
									frame.Debuffs:Show()
									frame.Debuffs:ForceUpdate()
								else
									frame.Debuffs:Hide()
									frame:DisableElement("Debuffs")
								end
							end
						end
					end,
					width = "full"
				},
				playerfilters = {
					type = "description",
					name = L["\n|cffffd200" .. "Player Aura Filters" .. "|r"],
					order = 120,
				},
				playerfiltersdescription = {
					type = "description",
					name = L["Toggle filters related to what auras are shown at what times."],
					order = 121,
				},
				playercombatfilter = {
					order = 122, 
					type = "toggle",
					name = L["Only apply filters while engaged in combat."],
					desc = L["Only apply the aura filters while you are engaged in combat, and show every aura unfiltered otherwise."],
					get = function() return self:GetModuleOption("Player", "onlyInCombat") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "onlyInCombat", value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				playerplayercastfilter = {
					order = 123, 
					type = "toggle",
					name = L["Hide auras not cast by the player"],
					desc = "",
					get = function() return self:GetModuleOption("Player", "onlyPlayer") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "onlyPlayer", value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				--[[
				playerconsolidatefilter = {
					order = 124, 
					type = "toggle",
					name = L["Hide auras eligible for consolidation."],
					desc = L["Hide auras with a very long duration like Mark of the Wild or similar."],
					get = function() return not self:GetModuleOption("Player", "showConsolidated") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "showConsolidated", not value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},]]--
				playershortfilter = {
					order = 125, 
					type = "toggle",
					name = L["Hide long duration auras."],
					desc = L["Hide auras with a duration above 60 seconds. This includes food buffs."],
					get = function() return self:GetModuleOption("Player", "onlyShortBuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "onlyShortBuffs", value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				playertimelessfilter = {
					order = 126, 
					type = "toggle",
					name = L["Hide static auras."],
					desc = L["Hide static auras that lack a duration, like mounts, feral forms, auras from group members and so on."],
					get = function() return not self:GetModuleOption("Player", "showTimeless") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "showTimeless", not value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				playerstealable = {
					order = 127, 
					type = "toggle",
					name = L["Always Show Stealable Buffs"],
					desc = L["Always display buffs that can be stolen. Overrides other choices."],
					get = function() return self:GetModuleOption("Player", "alwaysShowStealable") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "alwaysShowStealable", value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				playerbossdebuffs = {
					order = 128, 
					type = "toggle",
					name = L["Always Show Boss Debuffs"],
					desc = L["Always display debuffs cast by a boss. Overrides other choices."],
					get = function() return self:GetModuleOption("Player", "alwaysShowBossDebuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Player", "alwaysShowBossDebuffs", value)
						for frameID, frame in self:GetModuleData("Player"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				petheader = {
					type = "header",
					name = L["Pet"],
					order = 201,
				},
				petvisibilityheader = {
					type = "description",
					name = L["\n|cffffd200" .. "Pet Aura Visibility" .. "|r"],
					order = 202,
				},
				petvisibilitydescription = {
					type = "description",
					name = L["Select whether or not to show the pet aura widget. Deselecting a widget will override all other settings."],
					order = 203,
				},
				petauras = {
					order = 204,
					type = "toggle",
					name = L["Display Pet Auras"],
					desc = L["Display auras on the pet frame"],
					get = function() return self:GetModuleOption("Pet", "showAuras") end,
					set = function(info, value) 
						self:SetModuleOption("Pet", "showAuras", value)
						for frameID, frame in self:GetModuleData("Pet"):GetAllUnits() do
							if frame.Auras then
								if value then
									frame:EnableElement("Auras")
									frame.Auras:Show()
									frame.Auras:ForceUpdate()
								else
									frame.Auras:Hide()
									frame:DisableElement("Auras")
								end
							end
						end
					end,
					width = "full"
				},
				petfilters = {
					type = "description",
					name = L["\n|cffffd200" .. "Pet Aura Filters" .. "|r"],
					order = 220,
				},
				petfiltersdescription = {
					type = "description",
					name = L["Toggle filters related to what auras are shown at what times."],
					order = 221,
				},
				petcombatfilter = {
					order = 222, 
					type = "toggle",
					name = L["Only apply filters while engaged in combat."],
					desc = L["Only apply the aura filters while you are engaged in combat, and show every aura unfiltered otherwise."],
					get = function() return self:GetModuleOption("Pet", "onlyInCombat") end,
					set = function(info, value) 
						self:SetModuleOption("Pet", "onlyInCombat", value)
						for frameID, frame in self:GetModuleData("Pet"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				pettargetcastfilter = {
					order = 223, 
					type = "toggle",
					name = L["Hide auras not cast by the player"],
					desc = "",
					get = function() return self:GetModuleOption("Pet", "onlyPlayer") end,
					set = function(info, value) 
						self:SetModuleOption("Pet", "onlyPlayer", value)
						for frameID, frame in self:GetModuleData("Pet"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				--[[
				petconsolidatefilter = {
					order = 224, 
					type = "toggle",
					name = L["Hide auras eligible for consolidation."],
					desc = L["Hide auras with a very long duration like Mark of the Wild or similar."],
					get = function() return not self:GetModuleOption("Pet", "showConsolidated") end,
					set = function(info, value) 
						self:SetModuleOption("Pet", "showConsolidated", not value)
						for frameID, frame in self:GetModuleData("Pet"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},]]--
				petshortfilter = {
					order = 225, 
					type = "toggle",
					name = L["Hide long duration auras."],
					desc = L["Hide auras with a duration above 60 seconds. This includes food buffs."],
					get = function() return self:GetModuleOption("Pet", "onlyShortBuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Pet", "onlyShortBuffs", value)
						for frameID, frame in self:GetModuleData("Pet"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				pettimelessfilter = {
					order = 226, 
					type = "toggle",
					name = L["Hide static auras."],
					desc = L["Hide static auras that lack a duration, like mounts, feral forms, auras from group members and so on."],
					get = function() return not self:GetModuleOption("Pet", "showTimeless") end,
					set = function(info, value) 
						self:SetModuleOption("Pet", "showTimeless", not value)
						for frameID, frame in self:GetModuleData("Pet"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				-- petstealable = {
					-- order = 227, 
					-- type = "toggle",
					-- name = L["Always Show Stealable Buffs"],
					-- desc = L["Always display buffs that can be stolen. Overrides other choices."],
					-- get = function() return self:GetModuleOption("Pet", "alwaysShowStealable") end,
					-- set = function(info, value) 
						-- self:SetModuleOption("Pet", "alwaysShowStealable", value)
						-- for frameID, frame in self:GetModuleData("Pet"):GetAllUnits() do
							-- if frame.Auras then
								-- frame.Auras:ForceUpdate()
							-- end
						-- end
					-- end,
					-- width = "full"
				-- },
				petbossdebuffs = {
					order = 228, 
					type = "toggle",
					name = L["Always Show Boss Debuffs"],
					desc = L["Always display debuffs cast by a boss. Overrides other choices."],
					get = function() return self:GetModuleOption("Pet", "alwaysShowBossDebuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Pet", "alwaysShowBossDebuffs", value)
						for frameID, frame in self:GetModuleData("Pet"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				
				targetheader = {
					type = "header",
					name = L["Target"],
					order = 301,
				},
				targetvisibilityheader = {
					type = "description",
					name = L["\n|cffffd200" .. "Target Aura Visibility" .. "|r"],
					order = 310,
				},
				targetvisibilitydescription = {
					type = "description",
					name = L["Select whether or not to show the target aura widgets. Deselecting a widget will override all other settings."],
					order = 311,
				},
				targetbuffs = {
					order = 312,
					type = "toggle",
					name = L["Display Target Buffs"],
					desc = L["Display benefitial auras"],
					get = function() return self:GetModuleOption("Target", "showBuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "showBuffs", value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Buffs then
								if value then
									frame:EnableElement("Buffs")
									frame.Buffs:Show()
									frame.Buffs:ForceUpdate()
								else
									frame.Buffs:Hide()
									frame:DisableElement("Buffs")
								end
							end
						end
					end,
					width = "full"
				},
				targetdebuffs = {
					order = 313, 
					type = "toggle",
					name = L["Display Target Debuffs"],
					desc = L["Display harmful auras"],
					get = function() return self:GetModuleOption("Target", "showDebuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "showDebuffs", value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Debuffs then
								if value then
									frame:EnableElement("Debuffs")
									frame.Debuffs:Show()
									frame.Debuffs:ForceUpdate()
								else
									frame.Debuffs:Hide()
									frame:DisableElement("Debuffs")
								end
							end
						end
					end,
					width = "full"
				},
				targetfilters = {
					type = "description",
					name = L["\n|cffffd200" .. "Target Aura Filters" .. "|r"],
					order = 320,
				},
				targetfiltersdescription = {
					type = "description",
					name = L["Toggle filters related to what auras are shown at what times."],
					order = 321,
				},
				targetcombatfilter = {
					order = 322, 
					type = "toggle",
					name = L["Only apply filters while engaged in combat."],
					desc = L["Only apply the aura filters while you are engaged in combat, and show every aura unfiltered otherwise."],
					get = function() return self:GetModuleOption("Target", "onlyInCombat") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "onlyInCombat", value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				targettargetcastfilter = {
					order = 323, 
					type = "toggle",
					name = L["Hide auras not cast by the player"],
					desc = "",
					get = function() return self:GetModuleOption("Target", "onlyPlayer") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "onlyPlayer", value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				--[[
				targetconsolidatefilter = {
					order = 324, 
					type = "toggle",
					name = L["Hide auras eligible for consolidation."],
					desc = L["Hide auras with a very long duration like Mark of the Wild or similar."],
					get = function() return not self:GetModuleOption("Target", "showConsolidated") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "showConsolidated", not value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},]]--
				targetshortfilter = {
					order = 325, 
					type = "toggle",
					name = L["Hide long duration auras."],
					desc = L["Hide auras with a duration above 60 seconds. This includes food buffs."],
					get = function() return self:GetModuleOption("Target", "onlyShortBuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "onlyShortBuffs", value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				targettimelessfilter = {
					order = 326, 
					type = "toggle",
					name = L["Hide static auras."],
					desc = L["Hide static auras that lack a duration, like mounts, feral forms, auras from group members and so on."],
					get = function() return not self:GetModuleOption("Target", "showTimeless") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "showTimeless", not value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				targetstealable = {
					order = 327, 
					type = "toggle",
					name = L["Always Show Stealable Buffs"],
					desc = L["Always display buffs that can be stolen. Overrides other choices."],
					get = function() return self:GetModuleOption("Target", "alwaysShowStealable") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "alwaysShowStealable", value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				targetbossdebuffs = {
					order = 328, 
					type = "toggle",
					name = L["Always Show Boss Debuffs"],
					desc = L["Always display debuffs cast by a boss. Overrides other choices."],
					get = function() return self:GetModuleOption("Target", "alwaysShowBossDebuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Target", "alwaysShowBossDebuffs", value)
						for frameID, frame in self:GetModuleData("Target"):GetAllUnits() do
							if frame.Buffs then
								frame.Buffs:ForceUpdate()
							end
							if frame.Debuffs then
								frame.Debuffs:ForceUpdate()
							end
						end
					end,
					width = "full"
				},

				totheader = {
					type = "header",
					name = L["ToT"],
					order = 401,
				},
				totvisibilityheader = {
					type = "description",
					name = L["\n|cffffd200" .. "Target of Target Aura Visibility" .. "|r"],
					order = 402,
				},
				totvisibilitydescription = {
					type = "description",
					name = L["Select whether or not to show the target's target aura widget. Deselecting a widget will override all other settings."],
					order = 403,
				},
				totbuffs = {
					order = 404,
					type = "toggle",
					name = L["Display Target of Target Auras"],
					desc = L["Display auras on the target's target's frame"],
					get = function() return self:GetModuleOption("ToT", "showAuras") end,
					set = function(info, value) 
						self:SetModuleOption("ToT", "showAuras", value)
						for frameID, frame in self:GetModuleData("ToT"):GetAllUnits() do
							if frame.Auras then
								if value then
									frame:EnableElement("Auras")
									frame.Auras:Show()
									frame.Auras:ForceUpdate()
								else
									frame.Auras:Hide()
									frame:DisableElement("Auras")
								end
							end
						end
					end,
					width = "full"
				},
				totfilters = {
					type = "description",
					name = L["\n|cffffd200" .. "Target of Target Aura Filters" .. "|r"],
					order = 420,
				},
				totfiltersdescription = {
					type = "description",
					name = L["Toggle filters related to what auras are shown at what times."],
					order = 421,
				},
				totcombatfilter = {
					order = 422, 
					type = "toggle",
					name = L["Only apply filters while engaged in combat."],
					desc = L["Only apply the aura filters while you are engaged in combat, and show every aura unfiltered otherwise."],
					get = function() return self:GetModuleOption("ToT", "onlyInCombat") end,
					set = function(info, value) 
						self:SetModuleOption("ToT", "onlyInCombat", value)
						for frameID, frame in self:GetModuleData("ToT"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				tottargetcastfilter = {
					order = 423, 
					type = "toggle",
					name = L["Hide auras not cast by the player"],
					desc = "",
					get = function() return self:GetModuleOption("ToT", "onlyPlayer") end,
					set = function(info, value) 
						self:SetModuleOption("ToT", "onlyPlayer", value)
						for frameID, frame in self:GetModuleData("ToT"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				--[[
				totconsolidatefilter = {
					order = 424, 
					type = "toggle",
					name = L["Hide auras eligible for consolidation."],
					desc = L["Hide auras with a very long duration like Mark of the Wild or similar."],
					get = function() return not self:GetModuleOption("ToT", "showConsolidated") end,
					set = function(info, value) 
						self:SetModuleOption("ToT", "showConsolidated", not value)
						for frameID, frame in self:GetModuleData("ToT"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},]]--
				totshortfilter = {
					order = 425, 
					type = "toggle",
					name = L["Hide long duration auras."],
					desc = L["Hide auras with a duration above 60 seconds. This includes food buffs."],
					get = function() return self:GetModuleOption("ToT", "onlyShortBuffs") end,
					set = function(info, value) 
						self:SetModuleOption("ToT", "onlyShortBuffs", value)
						for frameID, frame in self:GetModuleData("ToT"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				tottimelessfilter = {
					order = 426, 
					type = "toggle",
					name = L["Hide static auras."],
					desc = L["Hide static auras that lack a duration, like mounts, feral forms, auras from group members and so on."],
					get = function() return not self:GetModuleOption("ToT", "showTimeless") end,
					set = function(info, value) 
						self:SetModuleOption("ToT", "showTimeless", not value)
						for frameID, frame in self:GetModuleData("ToT"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				-- totstealable = {
					-- order = 427, 
					-- type = "toggle",
					-- name = L["Always Show Stealable Buffs"],
					-- desc = L["Always display buffs that can be stolen. Overrides other choices."],
					-- get = function() return self:GetModuleOption("ToT", "alwaysShowStealable") end,
					-- set = function(info, value) 
						-- self:SetModuleOption("ToT", "alwaysShowStealable", value)
						-- for frameID, frame in self:GetModuleData("ToT"):GetAllUnits() do
							-- if frame.Auras then
								-- frame.Auras:ForceUpdate()
							-- end
						-- end
					-- end,
					-- width = "full"
				-- },
				totbossdebuffs = {
					order = 428, 
					type = "toggle",
					name = L["Always Show Boss Debuffs"],
					desc = L["Always display debuffs cast by a boss. Overrides other choices."],
					get = function() return self:GetModuleOption("ToT", "alwaysShowBossDebuffs") end,
					set = function(info, value) 
						self:SetModuleOption("ToT", "alwaysShowBossDebuffs", value)
						for frameID, frame in self:GetModuleData("ToT"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				
				focusheader = {
					type = "header",
					name = L["Focus"],
					order = 501,
				},
				focusvisibilityheader = {
					type = "description",
					name = L["\n|cffffd200" .. "Focus Target Aura Visibility" .. "|r"],
					order = 502,
				},
				focusvisibilitydescription = {
					type = "description",
					name = L["Select whether or not to show the focus target aura widget. Deselecting a widget will override all other settings."],
					order = 503,
				},
				focusbuffs = {
					order = 502,
					type = "toggle",
					name = L["Display Focus Target Auras"],
					desc = L["Display auras on the focus target's frame"],
					get = function() return self:GetModuleOption("Focus", "showAuras") end,
					set = function(info, value) 
						self:SetModuleOption("Focus", "showAuras", value)
						for frameID, frame in self:GetModuleData("Focus"):GetAllUnits() do
							if frame.Auras then
								if value then
									frame:EnableElement("Auras")
									frame.Auras:Show()
									frame.Auras:ForceUpdate()
								else
									frame.Auras:Hide()
									frame:DisableElement("Auras")
								end
							end
						end
					end,
					width = "full"
				},
				focusfilters = {
					type = "description",
					name = L["\n|cffffd200" .. "Focus Target Aura Filters" .. "|r"],
					order = 520,
				},
				focusfiltersdescription = {
					type = "description",
					name = L["Toggle filters related to what auras are shown at what times."],
					order = 521,
				},
				focuscombatfilter = {
					order = 522, 
					type = "toggle",
					name = L["Only apply filters while engaged in combat."],
					desc = L["Only apply the aura filters while you are engaged in combat, and show every aura unfiltered otherwise."],
					get = function() return self:GetModuleOption("Focus", "onlyInCombat") end,
					set = function(info, value) 
						self:SetModuleOption("Focus", "onlyInCombat", value)
						for frameID, frame in self:GetModuleData("Focus"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				focustargetcastfilter = {
					order = 523, 
					type = "toggle",
					name = L["Hide auras not cast by the player"],
					desc = "",
					get = function() return self:GetModuleOption("Focus", "onlyPlayer") end,
					set = function(info, value) 
						self:SetModuleOption("Focus", "onlyPlayer", value)
						for frameID, frame in self:GetModuleData("Focus"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				--[[
				focusconsolidatefilter = {
					order = 524, 
					type = "toggle",
					name = L["Hide auras eligible for consolidation."],
					desc = L["Hide auras with a very long duration like Mark of the Wild or similar."],
					get = function() return not self:GetModuleOption("Focus", "showConsolidated") end,
					set = function(info, value) 
						self:SetModuleOption("Focus", "showConsolidated", not value)
						for frameID, frame in self:GetModuleData("Focus"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},]]--
				focusshortfilter = {
					order = 525, 
					type = "toggle",
					name = L["Hide long duration auras."],
					desc = L["Hide auras with a duration above 60 seconds. This includes food buffs."],
					get = function() return self:GetModuleOption("Focus", "onlyShortBuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Focus", "onlyShortBuffs", value)
						for frameID, frame in self:GetModuleData("Focus"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				focustimelessfilter = {
					order = 526, 
					type = "toggle",
					name = L["Hide static auras."],
					desc = L["Hide static auras that lack a duration, like mounts, feral forms, auras from group members and so on."],
					get = function() return not self:GetModuleOption("Focus", "showTimeless") end,
					set = function(info, value) 
						self:SetModuleOption("Focus", "showTimeless", not value)
						for frameID, frame in self:GetModuleData("Focus"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},
				-- focusstealable = {
					-- order = 527, 
					-- type = "toggle",
					-- name = L["Always Show Stealable Buffs"],
					-- desc = L["Always display buffs that can be stolen. Overrides other choices."],
					-- get = function() return self:GetModuleOption("Focus", "alwaysShowStealable") end,
					-- set = function(info, value) 
						-- self:SetModuleOption("Focus", "alwaysShowStealable", value)
						-- for frameID, frame in self:GetModuleData("Focus"):GetAllUnits() do
							-- if frame.Auras then
								-- frame.Auras:ForceUpdate()
							-- end
						-- end
					-- end,
					-- width = "full"
				-- },
				focusbossdebuffs = {
					order = 528, 
					type = "toggle",
					name = L["Always Show Boss Debuffs"],
					desc = L["Always display debuffs cast by a boss. Overrides other choices."],
					get = function() return self:GetModuleOption("Focus", "alwaysShowBossDebuffs") end,
					set = function(info, value) 
						self:SetModuleOption("Focus", "alwaysShowBossDebuffs", value)
						for frameID, frame in self:GetModuleData("Focus"):GetAllUnits() do
							if frame.Auras then
								frame.Auras:ForceUpdate()
							end
						end
					end,
					width = "full"
				},				
			}
		}
	})	
	
	gUI4:RegisterModuleOptions("Visibility", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["UnitFrames"],
			args = {
				header = {
					type = "header",
					name = L["Unit Visibility"],
					order = 1,
				},
				description = {
					type = "description",
					name = L["Here you can manually decide whether or not to show specific units. But be aware that disabling an object such as the player or the target, may lead to connected unitframes changing positions."],
					order = 2,
				},
				playerenable = {
					type = "toggle",
					name = L["Enable Player Frame"],
					desc = L["Toggle the display of the player's unit frame."],
					order = 101,
					width = "full",
					get = function() return self.db.profile.modules.Player end,
					set = function(info, value) 
						local Player = self:GetModule("Player")
						if value then
							-- gUI4:DisableUnitFrame("player")
							self.db.profile.modules.Player = true
							-- Player:ForAll("Enable")
							Player:EnableUnitFrames()
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(Player)
							end
						else
							self.db.profile.modules.Player = false
							-- Player:ForAll("Disable")
							Player:DisableUnitFrames()
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(Player)
							end
						end
					end
				},
				playerclassbarenable = {
					type = "toggle",
					name = L["Enable Player Resource Bars"],
					desc = L["Toggle the display of the player's resource bars."],
					order = 102,
					width = "full",
					get = function() return self.db.profile.modules.ClassBar end,
					set = function(info, value) 
						local ClassBar = self:GetModule("ClassBar")
						if value then
							-- gUI4:DisableUnitFrame("player")
							self.db.profile.modules.ClassBar = true
							-- ClassBar:ForAll("Enable")
							ClassBar:EnableUnitFrames()
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(ClassBar)
							end
						else
							self.db.profile.modules.ClassBar = false
							-- ClassBar:ForAll("Disable")
							ClassBar:DisableUnitFrames()
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(ClassBar)
							end
						end
					end
				},
				petenable = {
					type = "toggle",
					name = L["Enable Pet Frame"],
					desc = L["Toggle the display of your pet's unit frame."],
					order = 103,
					width = "full",
					get = function() return self.db.profile.modules.Pet end,
					set = function(info, value) 
						local Pet = self:GetModule("Pet")
						if value then
							self.db.profile.modules.Pet = true
							-- Pet:ForAll("Enable")
							Pet:EnableUnitFrames()
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(Pet)
							end
						else
							self.db.profile.modules.Pet = false
							-- Pet:ForAll("Disable")
							Pet:DisableUnitFrames()
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(Pet)
							end
						end
					end
				},
				pettargetenable = {
					type = "toggle",
					name = L["Enable Pet Target Frame"],
					desc = L["Toggle the display of your pet's target's unit frame."],
					order = 104,
					width = "full",
					get = function() return self.db.profile.modules.PetTarget end,
					set = function(info, value) 
						local PetTarget = self:GetModule("PetTarget")
						if value then
							self.db.profile.modules.PetTarget = true
							PetTarget:ForAll("Enable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(PetTarget)
							end
						else
							self.db.profile.modules.PetTarget = false
							PetTarget:ForAll("Disable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(PetTarget)
							end
						end
					end
				},
				targetenable = {
					type = "toggle",
					name = L["Enable Target Frame"],
					desc = L["Toggle the display of the target's unit frame."],
					order = 201,
					width = "full",
					get = function() return self.db.profile.modules.Target end,
					set = function(info, value) 
						local Target = self:GetModule("Target")
						if value then
							self.db.profile.modules.Target = true
							Target:EnableUnitFrames()
							-- Target:ForAll("Enable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(Target)
							end
						else
							self.db.profile.modules.Target = false
							Target:DisableUnitFrames()
							-- Target:ForAll("Disable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(Target)
							end
						end
					end
				},
				targettargetenable = {
					type = "toggle",
					name = L["Enable Target's Target Frame"],
					desc = L["Toggle the display of the target's target's unit frame."],
					order = 202,
					width = "full",
					get = function() return self.db.profile.modules.ToT end,
					set = function(info, value) 
						local ToT = self:GetModule("ToT")
						if value then
							self.db.profile.modules.ToT = true
							ToT:EnableUnitFrames()
							-- ToT:ForAll("Enable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(ToT)
							end
						else
							self.db.profile.modules.ToT = false
							ToT:DisableUnitFrames()
							-- ToT:ForAll("Disable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(ToT)
							end
						end
					end
				},
				tottargetenable = {
					type = "toggle",
					name = L["Enable Target's Target's Target Frame"],
					desc = L["Toggle the display of the target's target's target unit frame."],
					order = 203,
					width = "full",
					get = function() return self.db.profile.modules.ToTTarget end,
					set = function(info, value) 
						local ToTTarget = self:GetModule("ToTTarget")
						if value then
							self.db.profile.modules.ToTTarget = true
							ToTTarget:ForAll("Enable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(ToTTarget)
							end
						else
							self.db.profile.modules.ToTTarget = false
							ToTTarget:ForAll("Disable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(ToTTarget)
							end
						end
					end
				},
				focusenable = {
					type = "toggle",
					name = L["Enable Focus Target Frame"],
					desc = L["Toggle the display of the focus target's unit frame."],
					order = 204,
					width = "full",
					get = function() return self.db.profile.modules.Focus end,
					set = function(info, value) 
						local Focus = self:GetModule("Focus")
						if value then
							self.db.profile.modules.Focus = true
							Focus:EnableUnitFrames()
							-- Focus:ForAll("Enable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(Focus)
							end
						else
							self.db.profile.modules.Focus = false
							Focus:DisableUnitFrames()
							-- Focus:ForAll("Disable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(Focus)
							end
						end
					end
				},
				focustargetenable = {
					type = "toggle",
					name = L["Enable Focus Target's Target Frame"],
					desc = L["Toggle the display of the focus target's target's unit frame."],
					order = 205,
					width = "full",
					get = function() return self.db.profile.modules.FocusTarget end,
					set = function(info, value) 
						local FocusTarget = self:GetModule("FocusTarget")
						if value then
							self.db.profile.modules.FocusTarget = true
							FocusTarget:EnableUnitFrames()
							-- FocusTarget:ForAll("Enable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(FocusTarget)
							end
						else
							self.db.profile.modules.FocusTarget = false
							FocusTarget:DisableUnitFrames()
							-- FocusTarget:ForAll("Disable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(FocusTarget)
							end
						end
					end
				},
				bossenable = {
					type = "toggle",
					name = L["Enable Boss Frames"],
					desc = L["Toggle the display of the boss frames."],
					order = 206,
					width = "full",
					get = function() return self.db.profile.modules.Boss end,
					set = function(info, value) 
						local Boss = self:GetModule("Boss")
						if value then
							self.db.profile.modules.Boss = true
							Boss:EnableUnitFrames()
							-- Boss:ForAll("Enable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Unlock(Boss)
							end
						else
							self.db.profile.modules.Boss = false
							Boss:DisableUnitFrames()
							-- Boss:ForAll("Disable")
							self:SetActiveTheme(self.db.profile.skin)
							if not gUI4:IsLocked() then
								self:Lock(Boss)
							end
						end
					end
				}
			}
		}
	})	

end

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_UnitFrames_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end

	updateConfig()

	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
	self:RegisterMessage("GUI4_BOTTOM_OFFSET_CHANGED", "UpdatePosition") -- hold position updates until we're certain we have a theme
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

-- forcefully enables all available units
function module:LoadUnits()
	for i, name in ipairs(moduleLoadOrder) do
		-- if defaults.profile.modules[name] == true then -- comment out when done testing
		-- if self.db.profile.modules[name] == true then 
			local mod = self:GetModule(name, true)
			if mod then
				mod:Enable() 
			end
		-- end
	end
end

-- disable or enable units based on user settings
function module:UpdateUnits()
	for i, name in ipairs(moduleLoadOrder) do
		-- if defaults.profile.modules[name] == true then -- comment out when done testing
		if self.db.profile.modules[name] == true then 
			local mod = self:GetModule(name, true)
			if mod then
				mod:EnableUnitFrames()
				-- mod:ForAll("Enable") 
			end
		else
			local mod = self:GetModule(name, true)
			if mod then
				mod:DisableUnitFrames()
				-- mod:ForAll("Disable") 
			end
		end
	end
	-- self:SetActiveTheme(self.db.profile.skin)
end

-- some blizzard frames needs to be forcefully enabled, 
-- since we've robbed them of their own initial display functions
function module:PLAYER_ENTERING_WORLD()
	if not self.db.profile.modules.Player then 
		gUI4:EnableUnitFrame("player")
	end
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function module:OnEnable()
	self:LoadUnits()
	self:UpdateUnits()
	self:SetActiveTheme(self.db.profile.skin)
end
