--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local parent = gUI:GetModule("Combat")
local module = parent:NewModule("DPS")

local print = print

local GetNumPartyMembers = GetNumGroupMembers or GetNumPartyMembers
local GetNumRaidMembers = GetNumGroupMembers or GetNumRaidMembers
local GetShapeshiftForm = GetShapeshiftForm
local UnitExists = UnitExists
local UnitThreatSituation = UnitThreatSituation

local L, C, F, M, db
local defaults

local printOut
local frame, combat, role, inPvP, inGroup
local updateRole, updateColor, updateGroup, updatePvP, updateAll
local updateDPS, updateDamage, updateVisibility, updateSizeAndPos
local dps, hps, totalDamage, totalHealing, damage, petDamage, otherDamage, startTime, totalTime = 0, 0, 0, 0, 0, 0, 0, 0, 0

local MINUTE = 60
local HOUR = MINUTE * 60
local DAY = HOUR * 24 -- like fights are gonna last days, lol
local stat = "|cFFFFD200%d|r|cFFFFFFFF%s|r"

local _,playerClass = UnitClass("player")

-- print last fights dps to the main chat frame
printOut = function()
	if not(db.showDPSVerboseReport) then return end
	
	-- gotta set some limits to avoid spam
	if (totalTime < db.minTime) or (dps < db.minDPS) then
		return
	end

	local time = ""
	local gotValue
	if (totalTime > DAY) then
		time = time .. stat:format(floor(totalTime/DAY), L["h"])
		gotValue = true
	end

	if (totalTime > HOUR) then
		if (gotValue) then 
			time = time .. " "
		end
		time = time .. stat:format(floor((totalTime%DAY)/HOUR), L["h"])
		gotValue = true
	end
	
	if (totalTime > MINUTE) then
		if (gotValue) then 
			time = time .. " "
		end
		time = time .. stat:format(floor((totalTime%HOUR)/MINUTE), L["m"])
		gotValue = true
	end
	
	if (gotValue) then
		time = time .. " "
	end
	
	time = time .. stat:format(totalTime%MINUTE, L["s"])
	
	if (role == "TANK") or (role == "DPS") and (floor(dps) > 0) then
		print(L["Last fight lasted %s"]:format(time))
		print(L["You did an average of %s%s"]:format(module:Tag(("[shortvaluecolored:%.1f]"):format(dps)), " " .. L["dps"]))
	end
	
	if (role == "HEAL")  and (floor(hps) > 0) then
		print(L["Last fight lasted %s"]:format(time))
		print(L["You did an average of %s%s"]:format(module:Tag(("[shortvaluecolored:%.1f]"):format(hps)), " " .. L["hps"]))
	end
end

-- change the color based on threat, to match the threatpanel on the other side
updateColor = function()
	local r, g, b, status
	local focus = (db.showFocusThreat) and (UnitExists("focus"))
	
	if (focus) or (UnitExists("target")) then
		status = UnitThreatSituation("player", focus and "focus" or "target")
		if (status) then
			r, g, b = unpack(C["THREAT_STATUS_COLORS"][status])
		else
			r, g, b = 1/10, 1/10, 1/10
		end
	else
		r, g, b = 1/10, 1/10, 1/10
	end
	
	frame.bar:SetStatusBarColor(r, g, b)
	frame.bar.bg:SetVertexColor(r * 1/3, g * 1/3, b * 1/3)
end

updateGroup = function()
	inGroup = (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0)
end

updatePvP = function()
	inPvP = F.IsInPvPEvent()
end

updateRole = function()
	if (F.IsPlayerHealer()) then
		role = "HEAL"
	elseif (F.IsPlayerTank()) then
		role = "TANK"
		
		-- pre-MoP stuff, should replace it
		if (playerClass == "DRUID") and (GetShapeshiftForm() ~= 1) then
			role = "DPS"
		end
	else
		role = "DPS"
	end
end

updateVisibility = function(self, event, ...)
	local blockPvP = (inPvP) and not(db.showPvPDPS)
	local blockSolo = not(inGroup) and not(db.showSoloDPS)
	local toUpdate = db.dps
	local toShow = (toUpdate) and not(blockPvP) and not(blockSolo)

	if (toUpdate) then
		-- reset on combat start
		if (event == "PLAYER_REGEN_DISABLED") then
			dps, damage, petDamage, otherDamage, totalDamage = 0, 0, 0, 0, 0
			hps, totalHealing = 0, 0
			startTime, totalTime = GetTime(), 0
			combat = true
			
			updateColor()
		end
		
		if (event == "PLAYER_REGEN_ENABLED") then
			combat = nil
			
			if (toShow) then
				printOut()
			end
		end
	end
	
	
	-- keep hidden until you're doing actual damage
	frame:SetShown((toShow) and (combat) and (totalDamage > 0))
end

updateDPS = function()
	if not(combat) then
		return
	end
	
	totalTime = GetTime() - startTime

	if (role == "TANK") or (role == "DPS") then
		if (totalTime > 0) then
			dps = (totalDamage > 0) and totalDamage/totalTime or 0

			frame.bar.value:SetText(module:Tag(("[shortvalue:%.1f]"):format(dps)))
		end
	end
	
	if (role == "HEAL") then
		if (totalTime > 0) then
			hps = (totalHealing > 0) and totalHealing/totalTime or 0
			
			frame.bar.value:SetText(module:Tag(("[shortvalue:%.1f]"):format(hps)))
		end
	end
	
--	frame.bar:SetValue(dps)
end

local gflags = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_GUARDIAN)

-- this function should update both damage and healing
updateDamage = function(self, event, ...)
	local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags
	if (F.IsBuild(4,2)) then
		timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
	else
		timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
	end
	
	local amount, healed, critical, spellId, spellSchool, missType 
	if (sourceGUID == UnitGUID("player")) then
		amount, healed, critical, spellId, spellSchool, missType = F.simpleParseLog(eventType, select(9, ...))
		damage = damage + amount
		totalHealing = totalHealing + healed
		
	elseif (sourceGUID == UnitGUID("pet")) then
		amount, healed, critical, spellId, spellSchool, missType = F.simpleParseLog(eventType, select(9, ...))
		petDamage = petDamage + amount
		totalHealing = totalHealing + healed
		
	elseif (sourceFlags == gflags) then
		amount, healed, critical, spellId, spellSchool, missType = F.simpleParseLog(eventType, select(9, ...))
		otherDamage = otherDamage + amount
		totalHealing = totalHealing + healed
	end

	totalDamage = damage + petDamage + otherDamage

	-- make it visible when we start doing damage
	if (totalDamage > 0) and not(frame:IsShown()) then
		updateVisibility()
	end
end

updateSizeAndPos = function()
	local w, h = F.fixPanelWidth(), F.fixPanelHeight()
	frame:SetSize(w, h)
	frame:ClearAllPoints()
	frame:SetPoint(unpack(db.dps_pos))
	
	frame.bar:SetSize(w - 6, h - 6)
	frame.bar:SetMinMaxValues(0, 100)
	frame.bar:SetValue(100)
end

updateAll = function()
	updateSizeAndPos()
	updatePvP()
	updateGroup()
	updateRole()
	updateVisibility()
	updateDPS()
end
module.PostUpdateSettings = updateAll

module.OnInit = function(self)
	L, C, F, M = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	db = self:GetParent():GetCurrentOptionsSet() -- get module settings
	defaults = self:GetParent():GetDefaultsForOptions() -- get module defaults

	-- create a holder
	frame = CreateFrame("Frame", self:GetName() .. "Bar", UIParent)
	frame:SetSize(F.fixPanelWidth(), F.fixPanelHeight())
	frame:EnableMouse(true)
	frame:Hide()

	gUI:SetUITemplate(frame, "backdrop")
	gUI:CreateUIShadow(frame)
	gUI:PlaceAndSave(frame, L["Simple DPS/HPS Meter"], db.dps_pos, unpack(defaults.dps_pos))
	gUI:AddObjectToFrameGroup(frame, "floaters")
	
	-- create and setup the bar itself
	local bar = CreateFrame("StatusBar", nil, frame)
	bar:SetSize(frame:GetWidth() - 6, frame:GetHeight() - 6)
	bar:SetPoint("BOTTOMRIGHT", -3, 3)
	bar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	bar:SetStatusBarColor(1/3, 0, 0)
	gUI:SetUITemplate(bar, "gloss")
	gUI:SetUITemplate(bar, "shade")
	frame.bar = bar
	
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(bar)
	bg:SetTexture(gUI:GetStatusBarTexture())
	bg:SetVertexColor(1/9, 0, 0)
	bar.bg = bg

	local value = bar:CreateFontString()
	value:SetDrawLayer("OVERLAY", 5)
	value:SetFontObject(gUI_DisplayFontTinyWhite)
	value:SetPoint("CENTER")
	bar.value = value

	-- initial updates
	updateAll()

	-- update pvp status
	self:RegisterEvent("PLAYER_ENTERING_WORLD", updatePvP)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", updatePvP)	
	
	-- update group status
	self:RegisterEvent("GROUP_ROSTER_UPDATE", updateGroup)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", updateGroup)

	-- update visibility
	self:RegisterEvent("PLAYER_REGEN_DISABLED", updateVisibility)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", updateVisibility)
	
	-- update role
	self:RegisterEvent("PLAYER_ALIVE", updateRole)
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", updateRole) 
	self:RegisterEvent("PLAYER_TALENT_UPDATE", updateRole) 
	self:RegisterEvent("TALENTS_INVOLUNTARILY_RESET", updateRole) 
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", updateRole)

	-- update background color to match the threat panel. vanity rocks.
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", updateColor)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", updateColor)
	self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", updateColor)
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", updateColor)
	
	-- update damage
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", updateDamage)

	-- update the displayed DPS
	self:ScheduleRepeatingTimer(1/10, updateDPS)
	
	-- make sure the bar stays in place and is correctly sized
	self:RegisterEvent("PLAYER_ENTERING_WORLD", updateSizeAndPos)
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", updateSizeAndPos)
	self:RegisterEvent("UI_SCALE_CHANGED", updateSizeAndPos)
end
