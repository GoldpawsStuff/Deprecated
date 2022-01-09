local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_CastBars = gUI4:GetModule("gUI4_CastBars", true)
if not gUI4_CastBars then return end

local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local C = gUI4:GetColors()

-- Lua API
local ceil, floor = math.ceil, math.floor
local setmetatable = setmetatable
local tonumber = tonumber
local unpack = unpack

-- WoW API
local GetNetStats = GetNetStats
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitPlayerControlled = UnitPlayerControlled
local UnitReaction = UnitReaction

local StatusBar = gUI4_CastBars.StatusBar
local CastBar = setmetatable({}, { __index = StatusBar })
local CastBar_MT = { __index = CastBar }
gUI4_CastBars.CastBar = CastBar

local _,playerClass = UnitClass("player")

local DAY, HOUR, MINUTE = 86400, 3600, 60
local function formatTime(time)
	if time > DAY then -- more than a day
		return ("%1d%s"):format(floor(time / DAY), L["d"])
	elseif time > HOUR then -- more than an hour
		return ("%1d%s"):format(floor(time / HOUR), L["h"])
	elseif time > MINUTE then -- more than a minute
		return ("%1d%s %d%s"):format(floor(time / MINUTE), L["m"], floor(time%MINUTE), L["s"])
	elseif time > 10 then -- more than 10 seconds
		return ("%d%s"):format(floor(time), L["s"])
	elseif time > 0 then
		return ("%.1f"):format(time)
	else
		return ""
	end	
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

function CastBar:ApplySettings()
	StatusBar.ApplySettings(self)
	if self.unit and self.unit ~= "" then
		if UnitCastingInfo(self.unit) then
			self:UNIT_SPELLCAST_START(self.unit)
		elseif UnitChannelInfo(self.unit) then
			self:UNIT_SPELLCAST_CHANNEL_START(self.unit)
		end
	end
end

function CastBar:UNIT_SPELLCAST_START(unit, spell)
	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
	if not name then
		self:Hide()
		return
	end
	
	endTime = endTime / 1e3
	startTime = startTime / 1e3

	local now = GetTime()
	local max = endTime - startTime

	self.castid = castid
	self.duration = now - startTime
	self.max = max
	self.delay = 0
	self.casting = true
	self.interrupt = notInterruptable
	self.tradeskill = isTradeSkill
	self.total = nil
	self.starttime = nil
	self.name:SetText(utf8sub(text, 32, true))
	
	self:SetMinMaxValues(0, self.total or self.max)
	self:SetValue(self.duration) 
	
	self.icon:SetTexture(texture)
	self.value:SetText("")

	if self.shield then 
		if self.interrupt and not UnitIsUnit(unit ,"player") then
			self.shield:Show()
		else
			self.shield:Hide()
		end
	end

	if self.unit == "player" then
		self.safeZone:ClearAllPoints()
		self.safeZone:SetPoint("TOP")
		self.safeZone:SetPoint("BOTTOM")
		self.safeZone:SetPoint("RIGHT")
	end
	self:Show()
end

function CastBar:UNIT_SPELLCAST_FAILED(unit, spellname, _, castid)
	if self.castid ~= castid then
		return
	end
	self.tradeskill = nil
	self.total = nil
	self.casting = nil
	self.interrupt = nil
	self:SetValue(0)
	self:Hide()
end

function CastBar:UNIT_SPELLCAST_INTERRUPTED(unit, spellname, _, castid)
	if self.castid ~= castid then
		return
	end
	self.tradeskill = nil
	self.total = nil
	self.casting = nil
	self.interrupt = nil
	self:SetValue(0)
	self:Hide()
end

function CastBar:UNIT_SPELLCAST_INTERRUPTIBLE(unit, spellname)
	if self.casting then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
		if name then
			self.interrupt = notInterruptable
		end
	elseif self.channeling then
		local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
		if name then
			self.interrupt = notInterruptable
		end
	end
	if self.shield then 
		if self.interrupt and not UnitIsUnit(unit ,"player") then
			self.shield:Show()
		else
			self.shield:Hide()
		end
	end
end

function CastBar:UNIT_SPELLCAST_NOT_INTERRUPTIBLE(unit, spellname)
	if self.casting then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
		if name then
			self.interrupt = notInterruptable
		end
	elseif self.channeling then
		local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
		if name then
			self.interrupt = notInterruptable
		end
	end
	if self.shield and not UnitIsUnit(unit ,"player") then 
		if self.interrupt then
			self.shield:Show()
		else
			self.shield:Hide()
		end
	end
end

function CastBar:UNIT_SPELLCAST_DELAYED(unit, spellname, _, castid)
	local name, _, text, texture, startTime, endTime = UnitCastingInfo(unit)
	if not startTime or not self.duration then return end
	local duration = GetTime() - (startTime / 1000)
	if duration < 0 then duration = 0 end
	self.delay = (self.delay or 0) + self.duration - duration
	self.duration = duration
	self:SetValue(duration)
end

function CastBar:UNIT_SPELLCAST_STOP(unit, spellname, _, castid)
	if self.castid ~= castid then
		return
	end
	self.casting = nil
	self.interrupt = nil
	self.tradeskill = nil
	self.total = nil
	self:SetValue(0)
	self:Hide()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(unit, spellname)
	local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
	if not name then
		self:Hide()
		return
	end
	
	endTime = endTime / 1e3
	startTime = startTime / 1e3

	local max = endTime - startTime
	local duration = endTime - GetTime()

	self.duration = duration
	self.max = max
	self.delay = 0
	self.channeling = true
	self.interrupt = notInterruptable

	self.casting = nil
	self.castid = nil

	self:SetMinMaxValues(0, max)
	self:SetValue(duration)
	
	if self.name then self.name:SetText(utf8sub(name, 32, true)) end
	if self.icon then self.icon:SetTexture(texture) end
	if self.value then self.value:SetText("") end
	if self.shield then 
		if self.interrupt and not UnitIsUnit(unit ,"player") then
			self.shield:Show()
		else
			self.shield:Hide()
		end
	end

	if self.unit == "player" then
		self.safeZone:ClearAllPoints()
		self.safeZone:SetPoint("TOP")
		self.safeZone:SetPoint("BOTTOM")
		self.safeZone:SetPoint("LEFT")
	end
	self:Show()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(unit, spellname)
	local name, _, text, texture, startTime, endTime, oldStart = UnitChannelInfo(unit)
	if not name or not self.duration then return end
	local duration = (endTime / 1000) - GetTime()
	self.delay = (self.delay or 0) + self.duration - duration
	self.duration = duration
	self.max = (endTime - startTime) / 1000
	self:SetMinMaxValues(0, self.max)
	self:SetValue(duration)
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(unit, spellname)
	if self:IsShown() then
		self.channeling = nil
		self.interrupt = nil
		self:SetValue(self.max)
		self:Hide()
	end
end

function CastBar:UNIT_TARGET(unit)
	if not UnitExists(self.unit) then
		return
	end
	if UnitCastingInfo(self.unit) then
		self:UNIT_SPELLCAST_START(self.unit)
		return
	end
	if UnitChannelInfo(self.unit) then
		self:UNIT_SPELLCAST_CHANNEL_START(self.unit)
		return
	end
	self.casting = nil
	self.interrupt = nil
	self.tradeskill = nil
	self.total = nil
	self:SetValue(0)
	self:Hide()
end

function CastBar:PLAYER_TARGET_CHANGED(unit)
	if not UnitExists(self.unit) then
		return
	end
	if UnitCastingInfo(self.unit) then
		self:UNIT_SPELLCAST_START(self.unit)
		return
	end
	if UnitChannelInfo(self.unit) then
		self:UNIT_SPELLCAST_CHANNEL_START(self.unit)
		return
	end
	self.casting = nil
	self.interrupt = nil
	self.tradeskill = nil
	self.total = nil
	self:SetValue(0)
	self:Hide()
end

local lastTradeCast
function CastBar:OnUpdate(elapsed)
	local unit = self.unit
	if not UnitExists(unit) then 
		self.casting = nil
		self.castid = nil
		self.channeling = nil
		self:SetValue(0)
		self:Hide()
		return 
	end
	local r, g, b
	local settings = self:GetSettings()
	if settings.classColor then
		if unit == "player" or unit == "pet" then
			r, g, b = unpack(C.class[playerClass])
		elseif UnitIsPlayer(unit) or UnitPlayerControlled(unit) then
			local _, class = UnitClass(unit)
			r, g, b = unpack(C.class[class])
		elseif UnitReaction(unit, "player") then
			r, g, b = unpack(C.reaction[UnitReaction(unit, "player")])
		else
			r, g, b = unpack(C.chat.normal)
		end
		self:SetStatusBarColor(r, g, b)
	end
	if self.casting or self.tradeskill then
		local duration = self.duration + elapsed
		if duration >= self.max then
			self.casting = nil
			self.tradeskill = nil
			self.total = nil
			self:Hide()
		end
		if self.unit == "player" then
			local width = self:GetWidth()
			local _, _, _, ms = GetNetStats()
			if ms ~= 0 then
				local safeZonePercent = (width / self.max) * (ms / 1e5)
				if safeZonePercent > 1 then safeZonePercent = 1 end
				self.safeZone:SetWidth(width * safeZonePercent)
				self.safeZone.delay:SetFormattedText("%s", ms .. MILLISECONDS_ABBR)
				if not self.safeZone:IsShown() then
					self.safeZone:Show()
				end
			else
				self.safeZone:Hide()
				self.safeZone.delay:SetText("")
			end
		end
		if self.tradeskill then
			self.value:SetText(formatTime(self.max - duration))
		elseif self.delay and self.delay ~= 0 then
			self.value:SetFormattedText("%s|cffff0000 -%s|r", formatTime(floor(self.max - duration)), formatTime(self.delay))
		else
			self.value:SetText(formatTime(self.max - duration))
		end
		self.duration = duration
		self:SetValue(duration)

	elseif self.channeling then
		local duration = self.duration - elapsed
		if duration <= 0 then
			self.channeling = nil
			self:Hide()
		end
		if self.unit == "player" then
			local width = self:GetWidth()
			local _, _, _, ms = GetNetStats()
			if ms ~= 0 then
				local safeZonePercent = (width / self.max) * (ms / 1e5)
				if safeZonePercent > 1 then safeZonePercent = 1 end
				self.safeZone:SetWidth(width * safeZonePercent)
				self.safeZone.delay:SetFormattedText("%s", ms .. MILLISECONDS_ABBR)
			else
				self.safeZone:Hide()
				self.safeZone.delay:SetText("")
			end
		end
		if self.delay and self.delay ~= 0 then
			self.value:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, self.delay)
		else
			self.value:SetFormattedText("%.1f", duration)
		end
		self.duration = duration
		self:SetValue(duration)
	else
		self.casting = nil
		self.castid = nil
		self.channeling = nil
		self:SetValue(0)
		self:Hide()
	end
end

function CastBar:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function CastBar:RegisterEvents()
	if self.unit then
		if self.hasEvents then
			self:UnregisterEvents()
		end
		self:RegisterUnitEvent("UNIT_SPELLCAST_START", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", self.unit)
		self:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", self.unit)
		if self.unit ~= "player" then
			self:RegisterEvent("UNIT_TARGET")
			self:RegisterEvent("PLAYER_TARGET_CHANGED")
		end
		self.hasEvents = true
	end
end

function CastBar:UnregisterEvents()
	if self.hasEvents then
		self:UnregisterEvent("UNIT_SPELLCAST_START")
		self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
		self:UnregisterEvent("UNIT_SPELLCAST_STOP")
		self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		self:UnregisterEvent("UNIT_TARGET")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
		self:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		self.hasEvents = false
	end
end

function CastBar:Enable()
	self:RegisterEvents()
	self:SetScript("OnUpdate", self.OnUpdate)
	self:SetScript("OnEvent", self.OnEvent)
	StatusBar.Enable(self)
end

function CastBar:Disable()
	self:UnregisterEvents()
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEvent", nil)
	StatusBar.Disable(self)
end

function CastBar:SetUnit(unit)
	self.unit = unit
	if unit == "player" then
		self.safeZone:Show()
		self.safeZone.delay:Show()
		if self.hasEvents then
			self:UnregisterEvent("UNIT_TARGET")
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		end
	else
		self.safeZone:Hide()
		self.safeZone.delay:Hide()
		if self.hasEvents then
			self:RegisterEvent("UNIT_TARGET")
			self:RegisterEvent("PLAYER_TARGET_CHANGED")
		end
	end
	if unit == "player" then
		self.title:SetText(L["Player"])
	elseif unit == "target" then
		self.title:SetText(L["Target"])
	elseif unit == "focus" then
		self.title:SetText(L["Focus"])
	elseif unit == "vehicle" then
		self.title:SetText(L["Vehicle"])
	else
		self.title:SetText("")
	end
end

function CastBar:New(id, name, settingsFunc)
	local bar = setmetatable(StatusBar:New(id, name, settingsFunc), CastBar_MT)
	bar.name = LMP:NewChain("FontString", nil, bar) :SetDrawLayer("OVERLAY", 0) :SetFontObject(GameFontNormalSmall) :SetPoint("LEFT", 10, 0) .__EndChain
	bar.title = LMP:NewChain("FontString", nil, bar) :SetDrawLayer("OVERLAY", 0) :SetFontObject(GameFontNormalSmall) :SetPoint("TOP", 0, 0) .__EndChain
	bar.safeZone = LMP:NewChain(bar:CreateTexture()) :Hide() :SetDrawLayer("BORDER", 1) :SetAllPoints(bar) :SetTexture(.8, .1, .1) :SetAlpha(2/4) .__EndChain
	bar.safeZone.delay = LMP:NewChain("FontString", nil, bar) :Hide() :SetDrawLayer("OVERLAY", 0) :SetFontObject(GameFontNormalSmall) :SetPoint("BOTTOM", bar.safeZone, "BOTTOM", 0, 4) .__EndChain
	bar.icon = LMP:NewChain(bar:CreateTexture()) :SetDrawLayer("BORDER", 0) .__EndChain
	bar.icon.border = LMP:NewChain(bar:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
	bar.shield = LMP:NewChain(CreateFrame("Frame", nil, bar)) :Hide() .__EndChain
	bar.shield.texture = LMP:NewChain(bar.shield:CreateTexture()) :SetDrawLayer("OVERLAY", 1) .__EndChain
	return bar
end

function CastBar:Update()
end

