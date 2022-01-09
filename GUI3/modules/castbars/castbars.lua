--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Castbars")

local select, unpack = select, unpack

local CopyTable = CopyTable
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitName = UnitName
local UIParent = UIParent

local L, C, F, M, db
local skinBar
local styleTimer, stylebar
local styleAllBars, styleAllTimers
local New, OnUpdate, OnEvent, Enable, Disable
local AddElement
local UNIT_SPELLCAST_START
local UNIT_SPELLCAST_FAILED
local UNIT_SPELLCAST_INTERRUPTED
local UNIT_SPELLCAST_INTERRUPTIBLE
local UNIT_SPELLCAST_NOT_INTERRUPTIBLE
local UNIT_SPELLCAST_DELAYED
local UNIT_SPELLCAST_STOP
local UNIT_SPELLCAST_CHANNEL_START
local UNIT_SPELLCAST_CHANNEL_UPDATE
local UNIT_SPELLCAST_CHANNEL_STOP

local player, pet, target, focus

local _, playerClass = UnitClass("player")
local castBars = {}

local bigNumbers = function() return {	
	texture = M("Texture", "gUI™ BigNumbers"); 
	w = 256; 
	h = 170; 
	texW = 1024; 
	texH = 512;
	numberHalfWidths = {
		--0,   1,   2,   3,   4,   5,   6,   7,   8,   9,
		35/128, 14/128, 33/128, 32/128, 36/128, 32/128, 33/128, 29/128, 31/128, 31/128,
	};
} end

local MAX_WIDTH, MIN_WIDTH = 220, 120
local MAX_HEIGHT, MIN_HEIGHT = 28, 16

local defaults = {
	showPlayerBar = true; -- show player castbar
	showTargetBar = true; -- show target castbar
	showFocusBar = false; -- show focus castbar
	showPetBar = true; -- show pet castbar
	showTradeSkill = true; -- use our castbars for tradeskills 

	player = { 
		size = { 220, 28 }; -- 
		pos = { "BOTTOM", "UIParent", "BOTTOM", 19, 250 }; -- (19)px (28+4+6)/2 (iconW+padding+2xBorder)
	};
	
	pet = { 
		size = { 120, 16 };
		pos = { "TOPLEFT", "UIParent", "BOTTOM", -(58 + 19), 242 }; -- -(58 + 19)px
	};
	
	target = { 
		size = { 180, 22 };
		pos = { "BOTTOMLEFT", "UIParent", "CENTER", 60, 48 }; -- 80, 8
	};
	
	focus = { 
		size = { 120, 16 };
		pos = { "TOPLEFT", "UIParent", "CENTER", 110, 40 }; -- 130, 0
	};
}

--------------------------------------------------------------------------------------------------
--		Restyle Blizzard Stuff (MirrorTimers and TimerTrackers)
--------------------------------------------------------------------------------------------------
skinBar = function(bar)
	local statusBar = _G[bar:GetName().."StatusBar"]
	if not(statusBar) then return end
	
	-- hide everything except the big numbers
	for i = 1, bar:GetNumRegions() do
		local region = select(i, bar:GetRegions())
		if (region:GetObjectType() == "Texture") and not(region == statusBar:GetStatusBarTexture()) then
			if not(region == bar.digit1) 
			and not(region == bar.digit2) 
			and not(region == bar.glow1) 
			and not(region == bar.glow2) 
			and not(region == bar.faction) 
			and not(region == bar.factionGlow) then
				region:SetTexture("")
			end
		end
	end
	
	for i = 1, statusBar:GetNumRegions() do
		local region = select(i, statusBar:GetRegions())
		if (region:GetObjectType() == "Texture") and not(region == statusBar:GetStatusBarTexture()) then
			region:SetTexture("")
		end
	end

	local border = _G[bar:GetName().."StatusBarBorder"]
	if border then
		border:SetTexture("")
	end

	local text = _G[bar:GetName().."Text"]
	if text then
		text:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
		text:ClearAllPoints()
		text:SetPoint("RIGHT", statusBar, "LEFT", -12, 0)
		text:SetJustifyH("RIGHT")
		text:SetJustifyV("MIDDLE")
	end

	local timeText = _G[bar:GetName().."StatusBarTimeText"]
	if timeText then
		timeText:SetFontObject(gUI_DisplayFontTinyOutlineWhite)
		timeText:ClearAllPoints()
		timeText:SetPoint("LEFT", statusBar, "RIGHT", 12, 0)
		timeText:SetJustifyH("LEFT")
		timeText:SetJustifyV("MIDDLE")
	end
	
	statusBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	statusBar:SetSize(160, 12) -- 195, 13
	statusBar:SetBackdrop({ bgFile = gUI:GetStatusBarTexture() })
	statusBar:SetBackdropColor(0, 0, 0, 0.5)
	statusBar.eyeCandy = CreateFrame("Frame", nil, statusBar)
	statusBar.eyeCandy:SetPoint("TOPLEFT", statusBar:GetStatusBarTexture(), "TOPLEFT", 0, 0)
	statusBar.eyeCandy:SetSize(statusBar:GetSize())
	
	gUI:CreateUIShadow(gUI:SetUITemplate(statusBar.eyeCandy, "border"))
	gUI:SetUITemplate(statusBar.eyeCandy, "gloss")
	-- gUI:SetUITemplate(statusBar.eyeCandy, "shade")
end

styleTimer = function(bar)
	if (bar.styled) then return end
	bar.styled = true
	
	skinBar(bar)
	bar.bar:SetStatusBarColor(0.75, 0, 0)

	bar:SetFrameStrata("LOW")
	bar.SetFrameStrata = noop
end

stylebar = function(bar)
	if (bar.styled) then return end
	bar.styled = true
	
	bar:SetSize(200, 26)

	_G[bar:GetName().."StatusBar"]:ClearAllPoints()
	_G[bar:GetName().."StatusBar"]:SetPoint("BOTTOM", bar, "BOTTOM", 0, 6)
	_G[bar:GetName().."StatusBarTimeText"] = _G[bar:GetName().."StatusBar"]:CreateFontString()
	local updateTime = function()
		_G[bar:GetName().."StatusBarTimeText"]:SetText( module:Tag(("[smarttime:%.1f]"):format(_G[bar:GetName().."StatusBar"]:GetValue())) )
	end
	module:ScheduleRepeatingTimer(0.1, updateTime)
	
	skinBar(bar)
end

styleAllBars = function()
	if (MirrorTimer1) then
		MirrorTimer1:ClearAllPoints()
		MirrorTimer1:SetPoint("TOP", "UIParent", "TOP", 0, -140)
	end 

	if (MIRRORTIMER_NUMTIMERS) then
		for i = 1, MIRRORTIMER_NUMTIMERS do
			stylebar(_G[("MirrorTimer%d"):format(i)])
		end
	end
end

styleAllTimers = function()
	if (TimerTracker) and (TimerTracker.timerList) then
		for _, bar in pairs(TimerTracker.timerList) do
			styleTimer(bar)
		end
	end
end

--------------------------------------------------------------------------------------------------
--		Custom Cast Bars
--------------------------------------------------------------------------------------------------
local CastBar = CreateFrame("Frame", nil, UIParent)
local CastBarMeta = { __index = CastBar }

local RegisterEvent = CastBar.RegisterEvent
CastBar.RegisterEvent = function(self, event, callback)
	RegisterEvent(self, event)
	self.events[event] = callback
end

local UnregisterEvent = CastBar.UnregisterEvent
CastBar.UnregisterEvent = function(self, event)
	UnregisterEvent(self, event)
	self.events[event] = nil
end

CastBar.SetUnit = function(self, unit)
	self.unit = unit
end

local SetSize = CastBar.SetSize
CastBar.SetSize = function(self, w, h)
	SetSize(self, w + 6, h + 6)
	if (self.cast) then self.cast:SetSize(w, h) end
	if (self.icon) then self.icon:SetSize(h + 6, h + 6) end
end

local GetSize = CastBar.GetSize
CastBar.GetSize = function(self)
	local w, h = GetSize(self)
	return (w) and (w - 6), (h) and (h - 6)
end

local SetWidth = CastBar.SetWidth
CastBar.SetWidth = function(self, w)
	SetWidth(self, w + 6)
	if (self.cast) then self.cast:SetWidth(w) end
end

local GetWidth = CastBar.GetWidth
CastBar.GetWidth = function(self)
	local w = GetWidth(self)
	return (w) and (w - 6)
end

local SetHeight = CastBar.SetHeight
CastBar.SetHeight = function(self, h)
	SetHeight(self, h + 6)
	if (self.cast) then self.cast:SetHeight(h) end
	if (self.icon) then self.icon:SetWidth(w + 6, h + 6) end
end

local GetHeight = CastBar.GetHeight
CastBar.GetHeight = function(self)
	local h = GetHeight(self)
	return (h) and (h - 6)
end

CastBar.UNIT_SPELLCAST_START = function(self, event, unit, spell)
	if (self.unit ~= unit) then 
		return 
	end
	
	local cast = self.cast
	if not(cast) then
		return
	end
	
	local name, _, text, texture, startTime, endTime, isTradeSkill, castid, interrupt = UnitCastingInfo(unit)
	if not(name) or (not(db.showTradeSkill) and (isTradeSkill)) then
		self:Hide()
		return
	end
	
	endTime = endTime / 1e3
	startTime = startTime / 1e3
	local max = endTime - startTime

	cast.castid = castid
	cast.duration = GetTime() - startTime
	cast.max = max
	cast.delay = 0
	cast.casting = true
	cast.interrupt = interrupt

	cast:SetMinMaxValues(0, max)
	cast:SetValue(0)
	
	if (cast.name) then cast.name:SetText(text) end
	if (cast.icon) then cast.icon:SetTexture(texture) end
	if (cast.time) then cast.time:SetText() end
	if (cast.ms) then cast.ms:SetText() end

	if (cast.latency) then
		cast.latency:ClearAllPoints()
		cast.latency:SetPoint("RIGHT")
		cast.latency:SetPoint("TOP")
		cast.latency:SetPoint("BOTTOM")
		cast.latency:Show()
	end

	self:Show()
end

CastBar.UNIT_SPELLCAST_FAILED = function(self, event, unit, spellname, _, castid)
	if (self.unit ~= unit) then 
		return 
	end

	local cast = self.cast
	if not(cast) then
		return
	end
	
	if(cast.castid ~= castid) then
		return
	end

	cast.casting = nil
	cast.interrupt = nil
	cast:SetValue(0)
	
	self:Hide()
end

CastBar.UNIT_SPELLCAST_INTERRUPTED = function(self, event, unit, spellname, _, castid)
	if (self.unit ~= unit) then 
		return 
	end

	local cast = self.cast
	if not(cast) then
		return
	end
	
	if(cast.castid ~= castid) then
		return
	end

	cast.casting = nil
	cast.channeling = nil
	cast:SetValue(0)
	
	self:Hide()
end

CastBar.UNIT_SPELLCAST_INTERRUPTIBLE = function(self, event, unit)
	if (self.unit ~= unit) then 
		return 
	end
end

CastBar.UNIT_SPELLCAST_NOT_INTERRUPTIBLE = function(self, event, unit)
	if (self.unit ~= unit) then 
		return 
	end
end

CastBar.UNIT_SPELLCAST_DELAYED = function(self, event, unit, spellname, _, castid)
	if (self.unit ~= unit) then 
		return 
	end

	local name, _, text, texture, startTime, endTime = UnitCastingInfo(unit)
	if not(startTime) then return end

	local cast = self.cast
	if not(cast) or not(cast.duration) then
		return
	end
	
	local duration = GetTime() - (startTime / 1000)
	if (duration < 0) then duration = 0 end

	cast.delay = (cast.delay or 0) + cast.duration - duration
	cast.duration = duration

	cast:SetValue(duration)
end

CastBar.UNIT_SPELLCAST_STOP = function(self, event, unit, spellname, _, castid)
	if (self.unit ~= unit) then 
		return 
	end

	local cast = self.cast
	if not(cast) then
		return
	end
	
	if(cast.castid ~= castid) then
		return
	end

	cast.casting = nil
	cast.interrupt = nil
	cast:SetValue(0)
	
	self:Hide()
end

CastBar.UNIT_SPELLCAST_CHANNEL_START = function(self, event, unit, spellname)
	if (self.unit ~= unit) then 
		return 
	end

	local cast = self.cast
	if not(cast) then
		return
	end
	
	local name, _, text, texture, startTime, endTime, isTradeSkill, interrupt = UnitChannelInfo(unit)
	if not(name) or (not(db.showTradeSkill) and (isTradeSkill)) then
		return
	end

	endTime = endTime / 1e3
	startTime = startTime / 1e3
	local max = (endTime - startTime)
	local duration = endTime - GetTime()

	cast.duration = duration
	cast.max = max
	cast.delay = 0
	cast.channeling = true
	cast.interrupt = interrupt

	cast.casting = nil
	cast.castid = nil

	cast:SetMinMaxValues(0, max)
	cast:SetValue(duration)

	if (cast.name) then cast.name:SetText(name) end
	if (cast.icon) then cast.icon:SetTexture(texture) end
	if (cast.time) then cast.time:SetText() end
	if (cast.ms) then cast.ms:SetText() end

	if (cast.latency) then
		cast.latency:ClearAllPoints()
		cast.latency:SetPoint("LEFT")
		cast.latency:SetPoint("TOP")
		cast.latency:SetPoint("BOTTOM")
		cast.latency:Show()
	end

	self:Show()

end

CastBar.UNIT_SPELLCAST_CHANNEL_UPDATE = function(self, event, unit, spellname)
	if (self.unit ~= unit) then 
		return 
	end
	
	local name, _, text, texture, startTime, endTime, oldStart = UnitChannelInfo(unit)
	if not(name) then
		return
	end

	local cast = self.cast
	if not(cast) or not(cast.duration) then
		return
	end
	
	local duration = (endTime / 1000) - GetTime()

	cast.delay = (cast.delay or 0) + cast.duration - duration
	cast.duration = duration
	cast.max = (endTime - startTime) / 1000

	cast:SetMinMaxValues(0, cast.max)
	cast:SetValue(duration)

end

CastBar.UNIT_SPELLCAST_CHANNEL_STOP = function(self, event, unit, spellname)
	if (self.unit ~= unit) then 
		return 
	end

	local cast = self.cast
	if not(cast) then
		return
	end
	
	if (self:IsShown()) then
		cast.channeling = nil
		cast.interrupt = nil

		cast:SetValue(cast.max)
		self:Hide()
	end
end

CastBar.UNIT_TARGET = function(self, event, unit)
	if (self.unit ~= unit) then 
		return 
	end

	if (UnitCastingInfo(unit)) then
		self:UNIT_SPELLCAST_START("UNIT_SPELLCAST_START", unit)
		return
	end
	
	if (UnitChannelInfo(unit)) then
		self:UNIT_SPELLCAST_CHANNEL_START("UNIT_SPELLCAST_CHANNEL_START", unit)
		return
	end
	
end

OnUpdate = function(self, elapsed)
	local cast = self.cast
	if not(cast) then
		return
	end
	
	local unit = self.unit

	if not(UnitExists(unit)) then 
		cast.casting = nil
		cast.castid = nil
		cast.channeling = nil

		cast:SetValue(1)
		self:Hide()
		return 
	end

	-- fix the color of the cast bar to something smart
	do
		local r, g, b, t
		-- give your pet the same color as you
		if (unit == "player") or (unit == "pet") then
			t = C.RAID_CLASS_COLORS[playerClass]
		
		elseif (UnitIsPlayer(unit)) or (UnitPlayerControlled(unit) and not(UnitIsPlayer(unit))) then
			local _, class = UnitClass(unit)
			t = C.RAID_CLASS_COLORS[class]
			
		elseif (UnitReaction(unit, "player")) then
			t = C.FACTION_BAR_COLORS[UnitReaction(unit, "player")]
			
		elseif (cast.colorHealth) then
			r, g, b = unpack(C["health"])
			
		end

		if (t) then
			r, g, b = t.r, t.g, t.b
		end
		
		cast:SetStatusBarColor(r, g, b)
	end

	if (cast.casting) then
		local duration = cast.duration + elapsed
		if (duration >= cast.max) then
			cast.casting = nil
			self:Hide()
		end

		if (cast.latency) then
			local width = cast:GetWidth()
			local _, _, _, ms = GetNetStats()
			if(ms ~= 0) then
				local safeZonePercent = (width / cast.max) * (ms / 1e5)
				if (safeZonePercent > 1) then safeZonePercent = 1 end
				cast.latency:SetWidth(width * safeZonePercent)
				
				if (cast.ms) then
					cast.ms:SetFormattedText("%s", ms .. MILLISECONDS_ABBR)
				end
			else
				cast.latency:Hide()

				if (cast.ms) then
					cast.ms:SetText()
				end
			end
		end

		if (cast.time) then
			if (cast.delay) and (cast.delay ~= 0) then
				cast.time:SetFormattedText("%.1f|cffff0000-%.1f|r", cast.max - duration, cast.delay)
			else
				cast.time:SetFormattedText("%.1f", cast.max - duration)
			end
		end

		cast.duration = duration
		cast:SetValue(duration)

	elseif (cast.channeling) then
		local duration = cast.duration - elapsed

		if (duration <= 0) then
			cast.channeling = nil
			self:Hide()
		end

		if (cast.latency) then
			local width = cast:GetWidth()
			local _, _, _, ms = GetNetStats()
			if(ms ~= 0) then
				local safeZonePercent = (width / cast.max) * (ms / 1e5)
				if(safeZonePercent > 1) then safeZonePercent = 1 end
				cast.latency:SetWidth(width * safeZonePercent)

				if (cast.ms) then
					cast.ms:SetFormattedText("%s", ms .. MILLISECONDS_ABBR)
				end
			else
				cast.latency:Hide()

				if (cast.ms) then
					cast.ms:SetText()
				end
			end
		end

		if (cast.time) then
			if (cast.delay) and (cast.delay ~= 0) then
				cast.time:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, cast.delay)
			else
				cast.time:SetFormattedText("%.1f", duration)
			end
		end

		cast.duration = duration
		cast:SetValue(duration)
		
	else
		cast.casting = nil
		cast.castid = nil
		cast.channeling = nil

		cast:SetValue(1)
		self:Hide()
	end
end

OnEvent = function(self, event, ...) 
	if (self[event]) then
		self[event](self, event, ...)
		
	elseif (self.events[event]) then
		self.events[event](self, event, ...)
	end
end

CastBar.Enable = function(self)
	if (self.enabled) or not(self.unit) then
		return
	end
	
	self.enabled = true

	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_TARGET")

	if (self.unit ~= "player") then
		self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
		self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	end
	
	self:SetScript("OnUpdate", OnUpdate)
	self:SetScript("OnEvent", OnEvent)
	
	castBars[self] = true
end

CastBar.Disable = function(self)
	if not(self.enabled) then
		return
	end

	self.enabled = nil

	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	self:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_TARGET")
	
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEvent", nil)

	self:Hide()

	castBars[self] = nil
end

CastBar.AddElement = function(self, ...)
	for i = 1, select("#", ...) do
		local element = select(i, ...)
		
		if (element == "cast") then
			-- castbar
			local cast = CreateFrame("StatusBar", nil, self)
			cast:SetPoint("TOPLEFT", 3, -3)
			cast:SetStatusBarTexture(gUI:GetStatusBarTexture())
			cast:SetSize(self:GetSize())
			gUI:SetUITemplate(cast, "gloss")
			-- gUI:SetUITemplate(cast, "shade")
			self.cast = cast
		end
		
		if (element == "icon") then
			-- casticon
			local icon = CreateFrame("Frame", nil, self)
			icon:SetSize(self:GetHeight() + 6, self:GetHeight() + 6)
			icon:SetPoint("RIGHT", self.cast, "LEFT", -4, 0)
			gUI:SetUITemplate(icon, "backdrop")
			gUI:CreateUIShadow(icon)
			
			local texture = icon:CreateTexture()
			texture:SetDrawLayer("OVERLAY", 0)
			texture:SetPoint("TOPLEFT", 3, -3)
			texture:SetPoint("BOTTOMRIGHT", -3, 3)
			texture:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			gUI:SetUITemplate(icon, "gloss", texture)
			gUI:SetUITemplate(icon, "shade", texture)

			icon.texture = texture
			icon.SetTexture = function(self, ...) texture:SetTexture(...) end
			icon.SetVertexColor = function(self, ...) texture:SetVertexColor(...) end

			self.cast.icon = icon
		end
		
		if (element == "time") then
			-- spell timer
			local time = self.cast:CreateFontString()
			time:SetFontObject(gUI_DisplayFontTinyOutlineWhite)
			time:SetDrawLayer("OVERLAY", 5)
			time:SetPoint("RIGHT", self.cast, "RIGHT", -8, 0)
			self.cast.time = time
		end

		if (element == "name") then
			-- spell name
			local name = self.cast:CreateFontString()
			name:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
			name:SetDrawLayer("OVERLAY", 4)
			name:SetPoint("LEFT", self.cast, "LEFT", 8, 0)
			name:SetPoint("RIGHT", self.cast, "RIGHT", -30, 0)
			self.cast.name = name
		end

		if (element == "latency") then
			-- latency bar/safezone
			local latency = self.cast:CreateTexture()
			latency:Hide()
			latency:SetDrawLayer("OVERLAY", 1)
			latency:SetTexture(1, 0, 0)
			latency:SetAlpha(1/4)
			self.cast.latency = latency
		end

		if (element == "delay") then
			-- latency text
			local ms = self.cast:CreateFontString()
			ms:SetFontObject(gUI_DisplayFontExtraTinyWhite)
			ms:SetDrawLayer("OVERLAY", 2)
			ms:SetTextColor(0.5, 0.5, 0.5, 1)
			if (self.cast.time) then
				ms:SetPoint("TOPRIGHT", self.cast.time, "BOTTOMRIGHT", 8, -4)
			else
				ms:SetPoint("CENTER", self.cast.latency or self.cast, "BOTTOM", 0, 0)
			end
			self.cast.ms = ms
		end
		
	end
end

-- create a new castbar
New = function(self, w, h, globalName, ...)
	local frame = setmetatable(CreateFrame("Frame", globalName, UIParent), CastBarMeta)
--	local frame = CreateFrame("Frame", globalName, UIParent)
	frame:Hide()
	frame:SetFrameStrata("MEDIUM")
	frame:SetFrameLevel(15) -- above the actionbars, below wow's ui panels and stuff
	frame:SetSize(w, h)
	frame:AddElement("cast")
	gUI:SetUITemplate(frame, "castbarbackdropwithborder")
	gUI:CreateUIShadow(frame)

	frame.events = {}
	
	if (...) then
		frame:AddElement(...)
	end

	return frame
end
module.New = New

module.UpdateAll = function(self)
	if (player) then
		if (db.showPlayerBar) then
			player:Enable()
		else
			player:Disable()
		end
		
		local w, h = player:GetSize()
		if (db.player.size[1] ~= w) or (db.player.size[2] ~= h) then
			player:SetSize(unpack(db.player.size))
		end
	end

	if (target) then
		if (db.showTargetBar) then
			target:Enable()
		else
			target:Disable()
		end
		
		local w, h = target:GetSize()
		if (db.target.size[1] ~= w) or (db.target.size[2] ~= h) then
			target:SetSize(unpack(db.target.size))
		end
	end

	if (focus) then
		if (db.showFocusBar) then
			focus:Enable()
		else
			focus:Disable()
		end
		
		local w, h = focus:GetSize()
		if (db.focus.size[1] ~= w) or (db.focus.size[2] ~= h) then
			focus:SetSize(unpack(db.focus.size))
		end
	end

	if (pet) then
		if (db.showPetBar) then
			pet:Enable()
		else
			pet:Disable()
		end
		
		local w, h = pet:GetSize()
		if (db.pet.size[1] ~= w) or (db.pet.size[2] ~= h) then
			pet:SetSize(unpack(db.pet.size))
		end
	end
end

module.PostUpdateSettings = function(self)
	if (player) then
		self:PlaceAndSave(player, L["Player Castbar"], db.player.pos, unpack(defaults.player.pos))
	end

	if (target) then
		self:PlaceAndSave(target, L["Target Castbar"], db.target.pos, unpack(defaults.target.pos))
	end

	if (focus) then
		self:PlaceAndSave(focus, L["Focus Castbar"], db.focus.pos, unpack(defaults.focus.pos))
	end

	if (pet) then
		self:PlaceAndSave(pet, L["Pet Castbar"], db.pet.pos, unpack(defaults.pet.pos))
	end
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 

	-- skin default elements
	-- disable default player castbar
	gUI:KillObject(CastingBarFrame)

	styleAllBars() -- style mirror bars (fatigue, etc)
	styleAllTimers() -- bg countdown
	
	self:RegisterEvent("START_TIMER", styleAllTimers)

	-- replace WoWs default numbers with ours
	-- glow effect texture is retrieved by adding "Glow" to the file name
	-- so keep the filenames in order!
	if (TIMER_NUMBERS_SETS) then
		TIMER_NUMBERS_SETS["BigGold"] = bigNumbers() 
	end
	
	-- initialize our custom castbars
	-- player cast bar
	player = self:New(
		db.player.size[1], db.player.size[2], 
		"GUIS_PlayerCastBar", 
		"icon", "time", "name", "latency", "delay"
		)
	player:SetUnit("player")
	player.cast.name:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
	player.cast.time:SetFontObject(gUI_DisplayFontTinyOutlineWhite)
	self:PlaceAndSave(player, L["Player Castbar"], db.player.pos, unpack(defaults.player.pos))
	self:AddObjectToFrameGroup(player, "castbars")

	-- target cast bar
	target = self:New(
		db.target.size[1], 
		db.target.size[2], 
		"GUIS_TargetCastBar",
		"icon", "time", "name"
		)
	target:SetUnit("target")
	target.cast.name:SetFontObject(gUI_TextFontTinyBoldOutlineWhite)
	target.cast.time:SetFontObject(gUI_DisplayFontTinyOutlineWhite)
	target.cast.icon:ClearAllPoints()
	target.cast.icon:SetPoint("LEFT", target.cast, "RIGHT", 4, 0)
	self:PlaceAndSave(target, L["Target Castbar"], db.target.pos, unpack(defaults.target.pos))
	self:AddObjectToFrameGroup(target, "castbars")

	-- focus cast bar
	focus = self:New(
		db.focus.size[1], 
		db.focus.size[2], 
		"GUIS_FocusCastBar",
		"icon", "time", "name"
	)
	focus:SetUnit("focus")
	focus.cast.name:SetFontObject(gUI_TextFontExtraTinyBoldOutlineWhite)
	focus.cast.time:SetFontObject(gUI_DisplayFontExtraTinyOutlineWhite)
	focus.cast.icon:ClearAllPoints()
	focus.cast.icon:SetPoint("LEFT", focus.cast, "RIGHT", 4, 0)
	self:PlaceAndSave(focus, L["Focus Castbar"], db.focus.pos, unpack(defaults.focus.pos))
	self:AddObjectToFrameGroup(focus, "castbars")

	-- pet cast bar
	pet = self:New(
		db.pet.size[1], 
		db.pet.size[2], 
		"GUIS_PetCastBar",
		"icon", "time", "name", "latency"
	)
	pet:SetUnit("pet")
	pet.cast.name:SetFontObject(gUI_TextFontExtraTinyBoldOutlineWhite)
	pet.cast.time:SetFontObject(gUI_DisplayFontExtraTinyOutlineWhite)
	self:PlaceAndSave(pet, L["Pet Castbar"], db.pet.pos, unpack(defaults.pet.pos))
	self:AddObjectToFrameGroup(pet, "castbars")
	
	self:UpdateAll()
	
	-- set up options menu
	do
		local menuTable = {
			{
				type = "group";
				name = module:GetName();
				order = 1;
				virtual = true;
				children = {
					{ -- menu title
						type = "widget";
						element = "Title";
						order = 1;
						msg = L["Castbars"];
					};
					{ -- subtext
						type = "widget";
						element = "Text";
						order = 2;
						msg = L["Here you can change the size and visibility of the on-screen castbars. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."];
					};
					{ -- enable player
						type = "widget";
						element = "CheckButton";
						name = "enablePlayer";
						order = 10;
						msg = L["Show the player castbar"];
						desc = nil;
						set = function(self) 
							db.showPlayerBar = not(db.showPlayerBar)
							self:onrefresh()
							module:UpdateAll()
						end;
						onrefresh = function(self) 
							if (self:get()) then
								self.parent.child.playerCastbar:Enable()
							else
								self.parent.child.playerCastbar:Disable()
							end
						end;
						get = function() return db.showPlayerBar end;
						init = function(self) 
							if not(self:get()) then
								self.parent.child.playerCastbar:Disable()
							end
						end;
					};
					{ -- enable target
						type = "widget";
						element = "CheckButton";
						name = "enableTarget";
						order = 15;
						msg = L["Show the target castbar"];
						desc = nil;
						set = function(self) 
							db.showTargetBar = not(db.showTargetBar)
							self:onrefresh()
							module:UpdateAll()
						end;
						onrefresh = function(self) 
							if (self:get()) then
								self.parent.child.targetCastbar:Enable()
							else
								self.parent.child.targetCastbar:Disable()
							end
						end;
						get = function() return db.showTargetBar end;
						init = function(self) 
							if not(self:get()) then
								self.parent.child.targetCastbar:Disable()
							end
						end;
					};
					{ -- enable pet
						type = "widget";
						element = "CheckButton";
						name = "enablePet";
						order = 20;
						msg = L["Show the pet castbar"];
						desc = nil;
						set = function(self) 
							db.showPetBar = not(db.showPetBar)
							self:onrefresh()
							module:UpdateAll()
						end;
						onrefresh = function(self) 
							if (self:get()) then
								self.parent.child.petCastbar:Enable()
							else
								self.parent.child.petCastbar:Disable()
							end
						end;
						get = function() return db.showPetBar end;
						init = function(self) 
							if not(self:get()) then
								self.parent.child.petCastbar:Disable()
							end
						end;
					};
					{ -- enable focus
						type = "widget";
						element = "CheckButton";
						name = "enable";
						order = 25;
						msg = L["Show the focus target castbar"];
						desc = nil;
						set = function(self) 
							db.showFocusBar = not(db.showFocusBar)
							self:onrefresh()
							module:UpdateAll()
						end;
						onrefresh = function(self) 
							if (self:get()) then
								self.parent.child.focusCastbar:Enable()
							else
								self.parent.child.focusCastbar:Disable()
							end
						end;
						get = function() return db.showFocusBar end;
						init = function(self) 
							if not(self:get()) then
								self.parent.child.focusCastbar:Disable()
							end
						end;
					};

					{ -- player castbar
						type = "group";
						order = 100;
						name = "playerCastbar";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Title";
								order = 1;
								msg = PLAYER; -- PLAYER PET TARGET FOCUS 
							};
							{ -- tradeskill
								type = "widget";
								element = "CheckButton";
								name = "tradeskill";
								order = 11;
								msg = L["Show for tradeskills"];
								desc = nil;
								set = function(self) 
									db.showTradeSkill = not(db.showTradeSkill)
									module:UpdateAll()
								end;
								get = function() return db.showTradeSkill end;
								init = function(self) end;
							};
							{ -- width text
								type = "widget";
								element = "Header";
								order = 15;
								name = "widthText";
								width = "half";
								msg = L["Set Width"]; 
							};
							{ -- height text
								type = "widget";
								element = "Header";
								order = 16;
								name = "heightText";
								width = "half";
								msg = L["Set Height"]; 
							};
							{ -- width
								type = "widget";
								element = "Slider";
								name = "width";
								order = 20;
								width = "half";
								msg = nil;
								desc = L["Set the width of the bar"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.player.size[1] = value
										
										module:UpdateAll()
									end
								end;
								get = function(self) return db.player.size[1] end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_WIDTH, MAX_WIDTH, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
							{ -- height
								type = "widget";
								element = "Slider";
								name = "height";
								order = 21;
								width = "half";
								msg = nil;
								desc = L["Set the height of the bar"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.player.size[2] = value
										
										module:UpdateAll()
									end
								end;
								get = function(self) return db.player.size[2] end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_HEIGHT, MAX_HEIGHT, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
						};
					};

					{ -- pet castbar
						type = "group";
						order = 120;
						name = "petCastbar";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Title";
								order = 1;
								msg = PET; 
							};
							{ -- width text
								type = "widget";
								element = "Header";
								order = 15;
								name = "widthText";
								width = "half";
								msg = L["Set Width"]; 
							};
							{ -- height text
								type = "widget";
								element = "Header";
								order = 16;
								name = "heightText";
								width = "half";
								msg = L["Set Height"]; 
							};
							{ -- width
								type = "widget";
								element = "Slider";
								name = "width";
								order = 20;
								width = "half";
								msg = nil;
								desc = L["Set the width of the bar"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.pet.size[1] = value
										
										module:UpdateAll()
									end
								end;
								get = function(self) return db.pet.size[1] end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_WIDTH, MAX_WIDTH, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
							{ -- height
								type = "widget";
								element = "Slider";
								name = "height";
								order = 21;
								width = "half";
								msg = nil;
								desc = L["Set the height of the bar"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.pet.size[2] = value
										
										module:UpdateAll()
									end
								end;
								get = function(self) return db.pet.size[2] end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_HEIGHT, MAX_HEIGHT, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
						};
					};

					{ -- target castbar
						type = "group";
						order = 110;
						name = "targetCastbar";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Title";
								order = 1;
								msg = TARGET; 
							};
							{ -- width text
								type = "widget";
								element = "Header";
								order = 15;
								name = "widthText";
								width = "half";
								msg = L["Set Width"]; 
							};
							{ -- height text
								type = "widget";
								element = "Header";
								order = 16;
								name = "heightText";
								width = "half";
								msg = L["Set Height"]; 
							};
							{ -- width
								type = "widget";
								element = "Slider";
								name = "width";
								order = 20;
								width = "half";
								msg = nil;
								desc = L["Set the width of the bar"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.target.size[1] = value
										
										module:UpdateAll()
									end
								end;
								get = function(self) return db.target.size[1] end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_WIDTH, MAX_WIDTH, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
							{ -- height
								type = "widget";
								element = "Slider";
								name = "height";
								order = 21;
								width = "half";
								msg = nil;
								desc = L["Set the height of the bar"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.target.size[2] = value
										
										module:UpdateAll()
									end
								end;
								get = function(self) return db.target.size[2] end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_HEIGHT, MAX_HEIGHT, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
						};
					};

					{ -- focus target castbar
						type = "group";
						order = 130;
						name = "focusCastbar";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Title";
								order = 1;
								msg = FOCUS; 
							};
							{ -- width text
								type = "widget";
								element = "Header";
								order = 15;
								name = "widthText";
								width = "half";
								msg = L["Set Width"]; 
							};
							{ -- height text
								type = "widget";
								element = "Header";
								order = 16;
								name = "heightText";
								width = "half";
								msg = L["Set Height"]; 
							};
							{ -- width
								type = "widget";
								element = "Slider";
								name = "width";
								order = 20;
								width = "half";
								msg = nil;
								desc = L["Set the width of the bar"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.focus.size[1] = value
										
										module:UpdateAll()
									end
								end;
								get = function(self) return db.focus.size[1] end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_WIDTH, MAX_WIDTH, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
							{ -- height
								type = "widget";
								element = "Slider";
								name = "height";
								order = 21;
								width = "half";
								msg = nil;
								desc = L["Set the height of the bar"];
								set = function(self, value) 
									if (value) then
										self.text:SetText(("%d"):format(value))
										db.focus.size[2] = value
										
										module:UpdateAll()
									end
								end;
								get = function(self) return db.focus.size[2] end;
								ondisable = function(self)
									self:SetAlpha(3/4)
									self.low:SetTextColor(unpack(C["disabled"]))
									self.high:SetTextColor(unpack(C["disabled"]))
									self.text:SetTextColor(unpack(C["disabled"]))
									
									self:EnableMouse(false)
								end;
								onenable = function(self)
									self:SetAlpha(1)
									self.low:SetTextColor(unpack(C["value"]))
									self.high:SetTextColor(unpack(C["value"]))
									self.text:SetTextColor(unpack(C["index"]))
									
									self:EnableMouse(true)
								end;
								init = function(self)
									local min, max, value = MIN_HEIGHT, MAX_HEIGHT, self:get()
									self:SetMinMaxValues(min, max)
									self.low:SetText(min)
									self.high:SetText(max)

									self:SetValue(value)
									self:SetValueStep(1)
									self.text:SetText(("%d"):format(value))
									
									if (self:IsEnabled()) then
										self:onenable()
									else
										self:ondisable()
									end
								end;
							};
						};
					};
					
				};
			};
		}
		local restoreDefaults = function()
			if (InCombatLockdown()) then 
				print(L["Can not apply default settings while engaged in combat."])
				return
			end
			self:ResetCurrentOptionsSetToDefaults()
		end
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["Castbars"], "default", restoreDefaults)
	end
end

