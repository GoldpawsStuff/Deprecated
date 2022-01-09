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
local module = parent:NewModule("Threat")

local print = print

local GetNumPartyMembers = GetNumGroupMembers or GetNumPartyMembers
local GetNumRaidMembers = GetNumGroupMembers or GetNumRaidMembers
local InCombatLockdown = InCombatLockdown
local PlaySound = PlaySound
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local RaidNotice_AddMessage = RaidNotice_AddMessage

local L, C, F, M, db
local defaults

local frame, show, combat, warning, inPvP, inGroup, oldStatus
local update, updateRole, updateVisibility, updateSizeAndPos, updatePvP, updateGroup, updateAll

local _,playerClass = UnitClass("player")

warning = function(status)
	if not(db.threat)
	or not(db.showWarnings)
	or (not(db.showSoloThreat) and not(inGroup))
	or (not(db.showPvPThreat) and (inPvP)) 
	or (oldStatus == status) then 
		return 
	end
	
	local msg

	-- role based
	if (role == "TANK") then
		if (status == 3) then
			-- msg = L["You are tanking!"] -- the tank doesn't need to be told it's tanking, does it?
		elseif (status == 2) then
			msg = L["You are losing threat!"]
		elseif (status == 1) then 
			msg = L["You've lost the threat!"]
		elseif (status == 0) then
		end
	else 
		if (status == 3) then
			msg = L["You have aggro, stop attacking!"]
		elseif (status == 2) then
			msg = L["You have aggro, stop attacking!"]
		elseif (status == 1) then 
			msg = L["You are overnuking!"]
		elseif (status == 0) then
		end
	end

	if (msg) then
		RaidNotice_AddMessage(RaidBossEmoteFrame, "|cFFFF0000" .. msg .. "|r", ChatTypeInfo["RAID_BOSS_EMOTE"] )
		PlaySound("PVPTHROUGHQUEUE", "Master") -- "RaidWarning" could also work, but the queue sound stands more out
	end
	
	oldStatus = status
end

updateGroup = function()
	inGroup = (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0)
end

updatePvP = function()
	inPvP = F.IsInPvPEvent()
end

updateRole = function()
	if (F.IsPlayerHealer()) then
		show = db.showHealerThreat
		role = "HEAL"
	elseif (F.IsPlayerTank()) then
		show = true
		role = "TANK"
		-- pre-MoP stuff
		if (playerClass == "DRUID") and (GetShapeshiftForm() ~= 1) then
			role = "DPS"
		end
	else
		show = true
		role = "DPS"
	end
end

updateVisibility = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then
		combat = true
	end
		
	if (event == "PLAYER_REGEN_ENABLED") then
		combat = nil
		oldStatus = nil
		frame:Hide()
	end
end

update = function()
	local visible
	local toShow = (db.threat) and (combat) and (show)
	local blockPvP = not(db.showPvPThreat) and (inPvP)
	local blockSolo = not(db.showSoloThreat) and not(inGroup)
	
	if (toShow) and not(blockPvP or blockSolo) then
		local focus = (db.showFocusThreat) and (UnitExists("focus"))
		if (focus) or (UnitExists("target")) then
			local isTanking, status, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", focus and "focus" or "target")
			
			if (scaledPercent and scaledPercent > 0) then
				local r, g, b = unpack(C["THREAT_STATUS_COLORS"][status]) -- GetThreatStatusColor(status)
				frame.bar:SetStatusBarColor(r, g, b)
				frame.bar.bg:SetVertexColor(r * 1/3, g * 1/3, b * 1/3)
				frame.bar:SetValue(scaledPercent)
				frame.bar.value:SetFormattedText("%d%%", scaledPercent)
				
				-- check if we've lost/gained threat and warn accordingly
				warning(status)
				
				visible = true
			else
				frame.bar:SetValue(0)
				frame.bar.value:SetText("")
			end
		end
	end

	frame:SetShown(visible)
end

updateSizeAndPos = function()
	local w, h = F.fixPanelWidth(), F.fixPanelHeight()
	frame:SetSize(w, h)
	frame:ClearAllPoints()
	frame:SetPoint(unpack(db.threat_pos))

	frame.bar:SetSize(w - 6, h - 6)
	frame.bar:SetMinMaxValues(0, 100)
	frame.bar:SetValue(0)
end

updateAll = function()
	updateSizeAndPos()
	updatePvP()
	updateGroup()
	updateRole()
	updateVisibility()
	update()
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
	gUI:PlaceAndSave(frame, L["Simple Threat Meter"], db.threat_pos, unpack(defaults.threat_pos))
	gUI:AddObjectToFrameGroup(frame, "floaters")

	-- create and setup the bar itself
	local bar = F.ReverseBar(frame) 
	bar:SetSize(frame:GetWidth() - 6, frame:GetHeight() - 6)
	bar:SetPoint("BOTTOMRIGHT", -3, 3)
	bar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	gUI:SetUITemplate(bar, "gloss")
	gUI:SetUITemplate(bar, "shade")
	frame.bar = bar
	
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(bar)
	bg:SetTexture(gUI:GetStatusBarTexture())
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
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", updateGroup)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", updateGroup)

	-- update threat
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", update)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", update)
	self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", update)
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", update)
	
	-- update combat visibility
	self:RegisterEvent("PLAYER_REGEN_DISABLED", updateVisibility)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", updateVisibility)
	
	-- update player role
	self:RegisterEvent("PLAYER_ALIVE", updateRole)
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", updateRole) 
	self:RegisterEvent("PLAYER_TALENT_UPDATE", updateRole) 
	self:RegisterEvent("TALENTS_INVOLUNTARILY_RESET", updateRole) 
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", updateRole)
	
	-- update the size and position of the panels
	self:RegisterEvent("PLAYER_ENTERING_WORLD", updateSizeAndPos)
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", updateSizeAndPos)
	self:RegisterEvent("UI_SCALE_CHANGED", updateSizeAndPos)
end

