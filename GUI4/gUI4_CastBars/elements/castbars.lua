local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_CastBars", true)
if not parent then return end

local module = parent:NewModule("CastBars", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme

-- Lua API
local pairs, ipairs, unpack = pairs, ipairs, unpack
local tostring = tostring

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat

local CastBar = parent.CastBar
local CastBar_MT = { __index = CastBar }

local _,playerClass = UnitClass("player")

local defaults = {
	profile = {
		bars = {
			player = {
				skin = "Warcraft",
				classColor = true,
				locked = true,
				enabled = true,
				showText = false,
				position = {}
			},
			target = {
				skin = "Warcraft",
				classColor = true,
				locked = true,
				enabled = true,
				showText = true,
				position = {}
			},
			focus = {
				skin = "Warcraft",
				classColor = true,
				locked = true,
				enabled = true,
				showText = true,
				position = {}
			}
		}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().castbars
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
	for id, scaffold in pairs(self.bars) do
		LMP:NewChain(scaffold) :SetSize(unpack(T.bars[id].size)) :EndChain()
		LMP:NewChain(scaffold.backdrop) :SetTexture(T.bars[id].textures.backdrop:GetPath()) :SetSize(T.bars[id].textures.backdrop:GetTexSize()) :ClearAllPoints() :SetPoint(T.bars[id].textures.backdrop:GetPoint()) :EndChain()
		LMP:NewChain(scaffold.overlay) :SetTexture(T.bars[id].textures.overlay:GetPath()) :SetSize(T.bars[id].textures.overlay:GetTexSize()) :ClearAllPoints() :SetPoint(T.bars[id].textures.overlay:GetPoint()) :EndChain()
		
		LMP:NewChain(scaffold.bar) :ClearAllPoints() :SetPoint(unpack(T.bars[id].bar.place)) :SetSize(unpack(T.bars[id].bar.size)) :SetStatusBarTexture(T.bars[id].bar.textures.normal:GetPath()) :SetStatusBarColor(unpack(T.bars[id].bar.color)) :SetBackdropTexture(T.bars[id].bar.textures.backdrop:GetPath()) :SetBackdropMultiplier(T.bars[id].bar.backdropMultiplier) :SetBackdropColor(unpack(T.bars[id].bar.backdropColor)) :SetBackdropAlpha(T.bars[id].bar.backdropAlpha) :SetOverlayTexture(T.bars[id].bar.textures.overlay:GetPath()) :SetOverlayColor(unpack(T.bars[id].bar.overlayColor)) :SetOverlayAlpha(T.bars[id].bar.overlayAlpha) :EndChain()
		LMP:NewChain(scaffold.bar.value) :SetFontObject(T.bars[id].widgets.time.fontobject) :SetFontSize(T.bars[id].widgets.time.size) :SetFontStyle(T.bars[id].widgets.time.fontstyle) :SetShadowOffset(unpack(T.bars[id].widgets.time.shadowoffset)) :SetShadowColor(unpack(T.bars[id].widgets.time.shadowcolor)) :SetTextColor(unpack(T.bars[id].widgets.time.color)) :ClearAllPoints() :SetPoint(unpack(T.bars[id].widgets.time.place)) :EndChain()
		LMP:NewChain(scaffold.bar.safeZone.delay) :SetFontObject(T.bars[id].widgets.delay.fontobject) :SetFontSize(T.bars[id].widgets.delay.size) :SetFontStyle(T.bars[id].widgets.delay.fontstyle) :SetShadowOffset(unpack(T.bars[id].widgets.delay.shadowoffset)) :SetShadowColor(unpack(T.bars[id].widgets.delay.shadowcolor)) :SetTextColor(unpack(T.bars[id].widgets.delay.color)) :ClearAllPoints() :SetPoint(unpack(T.bars[id].widgets.delay.place)) :EndChain()
		LMP:NewChain(scaffold.bar.name) :SetJustifyH(T.bars[id].widgets.name.justify) :SetWidth(T.bars[id].widgets.name.maxwidth) :SetHeight(T.bars[id].widgets.name.size) :SetFontObject(T.bars[id].widgets.name.fontobject) :SetFontSize(T.bars[id].widgets.name.size) :SetFontStyle(T.bars[id].widgets.name.fontstyle) :SetShadowOffset(unpack(T.bars[id].widgets.name.shadowoffset)) :SetShadowColor(unpack(T.bars[id].widgets.name.shadowcolor)) :SetTextColor(unpack(T.bars[id].widgets.name.color)) :ClearAllPoints() :SetPoint(unpack(T.bars[id].widgets.name.place)) :EndChain()
		
		LMP:NewChain(scaffold.bar.shield) :SetSize(unpack(T.bars[id].widgets.shield.size)) :ClearAllPoints() :SetPoint(unpack(T.bars[id].widgets.shield.place)) :EndChain()
		LMP:NewChain(scaffold.bar.shield.texture) :SetSize(T.bars[id].widgets.shield.textures.shield:GetTexSize()) :ClearAllPoints() :SetPoint(T.bars[id].widgets.shield.textures.shield:GetPoint()) :SetTexture(T.bars[id].widgets.shield.textures.shield:GetPath()) :EndChain()
		
		if T.bars[id].widgets.title then
			LMP:NewChain(scaffold.bar.title) :Show() :SetJustifyH(T.bars[id].widgets.title.justify) :SetWidth(T.bars[id].widgets.title.maxwidth) :SetHeight(T.bars[id].widgets.title.size) :SetFontObject(T.bars[id].widgets.title.fontobject) :SetFontSize(T.bars[id].widgets.title.size) :SetFontStyle(T.bars[id].widgets.title.fontstyle) :SetShadowOffset(unpack(T.bars[id].widgets.title.shadowoffset)) :SetShadowColor(unpack(T.bars[id].widgets.title.shadowcolor)) :SetTextColor(unpack(T.bars[id].widgets.title.color)) :ClearAllPoints() :SetPoint(unpack(T.bars[id].widgets.title.place)) :EndChain()
		else
			LMP:NewChain(scaffold.bar.title) :Hide() :EndChain()
		end
		-- LMP:NewChain(scaffold.bar.icon) :SetSize(unpack(T.bars[id].widgets.icon.size)) :SetTexCoord(unpack(T.bars[id].widgets.icon.texcoord)) :ClearAllPoints() :SetPoint(unpack(T.bars[id].widgets.icon.place)) :EndChain()
		-- LMP:NewChain(scaffold.bar.icon.border)
			-- :SetSize(T.bars[id].widgets.icon.border:GetSize())
			-- :SetTexCoord(T.bars[id].widgets.icon.border:GetTexCoord())
			-- :ClearAllPoints()
			-- :SetPoint(T.bars[id].widgets.icon.border:GetPoint())
		-- :EndChain()
		-- LMP:NewChain(scaffold.bar.border)
			-- :SetSize(T.bars[id].bar.border:GetSize())
			-- :SetTexCoord(T.bars[id].bar.border:GetTexCoord())
			-- :ClearAllPoints()
			-- :SetPoint(T.bars[id].bar.border:GetPoint())
		-- :EndChain()
		LMP:NewChain(scaffold.bar.spark) :SetSize(T.bars[id].spark.texture:GetTexSize(), scaffold.bar:GetHeight()) :SetTexture(T.bars[id].spark.texture:GetPath()) :SetAlpha(T.bars[id].spark.alpha) :ClearAllPoints() :SetPoint(T.bars[id].spark.texture:GetPoint(), scaffold.bar:GetStatusBarTexture(), T.bars[id].spark.texture:GetPoint()) :EndChain()
		
	end
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	updateConfig()
	if self.bars then
		for id, scaffold in pairs(self.bars) do 
			scaffold.bar:ApplySettings()
			local db = self.db.profile.bars[id]
			if db.enabled then 
				scaffold.bar:Enable()
			else
				scaffold.bar:Disable()
			end
		end
	end
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.bars then return end
	updateConfig()
	for id, scaffold in pairs(self.bars) do 
		if scaffold then
			local db = self.db.profile.bars[id]
			if db.enabled then 
				if db.locked then
					LMP:Place(scaffold, T.bars[id].place)
					if not db.position.x then
						scaffold:RegisterConfig(db.position)
						scaffold:SavePosition()
					end
				else
					scaffold:RegisterConfig(db.position)
					if db.position.x then
						scaffold:LoadPosition()
					else
						LMP:Place(scaffold, T.bars[id].place)
						scaffold:SavePosition()
						scaffold:LoadPosition()
					end
				end	
			end
		end
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:New(id, settingsFunc)
	return CastBar:New(tostring(id), nil, settingsFunc)
end

local glocks = {}
function module:Lock()
	for bar, overlay in pairs(glocks) do
		if bar:GetSettings().enabled then
			overlay:StartFadeOut()
		end
	end
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	for bar, overlay in pairs(glocks) do
		if bar:GetSettings().enabled then
			overlay:SetAlpha(0)
			overlay:Show()
		end
	end
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not hasTheme then return end
	if not self.bars then return end
	updateConfig()
	for id, scaffold in pairs(self.bars) do 
		if scaffold then
			local db = self.db.profile.bars[id]
			db.position.point = nil
			db.position.y = nil
			db.position.x = nil
			db.locked = true
			wipe(db.position)
		end
	end
	self:ApplySettings()
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("CastBars", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	updateConfig()

	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
	self:RegisterMessage("GUI4_BOTTOM_OFFSET_CHANGED", "UpdatePosition") 
end

function module:OnEnable()
	if not self.bars then
		self.bars = {}
		for unit in pairs({ player = true, focus = true, target = true }) do
			self.bars[unit] = LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :SetFrameStrata("LOW") .__EndChain
			self.bars[unit].GetSettings = function() return self.db.profile.bars[unit] end
			self.bars[unit].bar = LMP:NewChain(self:New(unit, function() return self.db.profile.bars[unit] end)) :SetUnit(unit) :SetParent(self.bars[unit]) .__EndChain
			self.bars[unit].backdropframe = LMP:NewChain(CreateFrame("Frame", nil, self.bars[unit].bar)) :SetFrameLevel(self.bars[unit]:GetFrameLevel() - 1) :SetAllPoints(self.bars[unit]) .__EndChain
			self.bars[unit].overlayframe = LMP:NewChain(CreateFrame("Frame", nil, self.bars[unit].bar)) :SetFrameLevel(self.bars[unit]:GetFrameLevel() + 1) :SetAllPoints(self.bars[unit]) .__EndChain
			self.bars[unit].backdrop = LMP:NewChain(self.bars[unit].backdropframe:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) .__EndChain
			self.bars[unit].overlay = LMP:NewChain(self.bars[unit].overlayframe:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
			self.bars[unit].UpdatePosition = function(self) module:UpdatePosition() end
			if unit ~= "player" then
				local shine = gUI4:ApplyShine(self.bars[unit], .5, .75, 2)
				self.bars[unit].bar:HookScript("OnShow", function(self) 
					shine:Start()
				end)
			end
			gUI4:ApplySmoothing(self.bars[unit].bar)
		end
		glocks[self.bars.player] = gUI4:GlockThis(self.bars.player, L["Player CastBar"], function() return self.db.profile.bars.player end, unpack(gUI4:GetColors("glock", "castbars"))) 
		glocks[self.bars.focus] = gUI4:GlockThis(self.bars.focus, L["Focus CastBar"], function() return self.db.profile.bars.focus end, unpack(gUI4:GetColors("glock", "castbars"))) 
		glocks[self.bars.target] = gUI4:GlockThis(self.bars.target, L["Target CastBar"], function() return self.db.profile.bars.target end, unpack(gUI4:GetColors("glock", "castbars"))) 
	end
end

function module:OnDisable()
end
