local _, gUI4 = ...

-- Lua API
local _G = _G
local type = type

-- WoW API
local Arena_LoadUI = _G.Arena_LoadUI
local GetCVarBool = _G.GetCVarBool
local SetCVar = _G.SetCVar
local UnitClass = _G.UnitClass

local LMP = _G.GP_LibStub("GP_LibMediaPlus-1.0")

------------------------------------------------------------------------
--	Unit Frames
------------------------------------------------------------------------
local function getFrame(baseName)
	if (type(baseName) == "string") then
		return _G[baseName]
	else
		return baseName
	end
end

local function killUnitFrame(baseName)
	local frame = getFrame(baseName)
	if(frame) then
		LMP:Kill(frame, false, true)
		frame:Hide()
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMLEFT", _G.UIParent, "TOPLEFT", -400, 500)

		local health = frame.healthbar
		if(health) then
			health:UnregisterAllEvents()
		end

		local power = frame.manabar
		if(power) then
			power:UnregisterAllEvents()
		end

		local spell = frame.spellbar
		if(spell) then
			spell:UnregisterAllEvents()
		end

		local altpowerbar = frame.powerBarAlt
		if(altpowerbar) then
			altpowerbar:UnregisterAllEvents()
		end
	end
end

local function reviveUnitFrame(baseName, unit)
	local frame = getFrame(baseName)
	if(frame) then
		LMP:Revive(frame, true)
		
		local health = frame.healthbar
		if(health) then
			if ( health.frequentUpdates ) then
				health:RegisterEvent("VARIABLES_LOADED")
			end	
			if not( GetCVarBool("predictedHealth") and health.frequentUpdates ) then
				health:RegisterUnitEvent("UNIT_HEALTH", unit)
			end
			health:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
		end

		local power = frame.manabar
		if(power) then
			if ( power.frequentUpdates ) then
				power:RegisterEvent("VARIABLES_LOADED")
			end	
			if not( GetCVarBool("predictedPower") and power.frequentUpdates ) then
				power:RegisterUnitEvent("UNIT_POWER", unit)
			end
			power:RegisterUnitEvent("UNIT_MAXPOWER", unit)
		end

		local spell = frame.spellbar
		if(spell) then
			spell:RegisterEvent("CVAR_UPDATE")
			spell:RegisterEvent("VARIABLES_LOADED")
			if (spell.updateEvent) then
				spell:RegisterEvent(spell.updateEvent)
			end
		end

		local altpowerbar = frame.powerBarAlt
		if(altpowerbar) then
			altpowerbar:RegisterEvent("UNIT_POWER_BAR_SHOW")
			altpowerbar:RegisterEvent("UNIT_POWER_BAR_HIDE")
			altpowerbar:RegisterEvent("PLAYER_ENTERING_WORLD")
			altpowerbar:RegisterEvent("PLAYER_TARGET_CHANGED")
			if (altpowerbar.updateAllEvent) then
				altpowerbar:RegisterEvent(altpowerbar.updateAllEvent)
			end
		end

		-- for units that call UnitFrame_Initialize()
		if (unit == "player" 
		or unit == "target" 
		or unit == "pet" 
		or unit == "targettarget" 
		or unit == "focus" 
		or unit == "focustarget") then

			frame:RegisterEvent("UNIT_NAME_UPDATE")
			frame:RegisterEvent("UNIT_DISPLAYPOWER")
			frame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
			frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
			if ( frame.healAbsorbBar ) then
				frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
			end
			if ( frame.myHealPredictionBar ) then
				frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
				frame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", unit)
			end
			if ( frame.totalAbsorbBar ) then
				frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
			end
		end
	end
end

-- @usage gUI4:DisableUnitFrame(unit)
-- @description disables a unitframe based on "unit"
-- @param unit <string> the unitID of the unit whose blizzard frame to disable (http://wowpedia.org/UnitId)
function gUI4:DisableUnitFrame(unit)
	if unit == "focus-target" then unit = "focustarget" end
	if unit == "playerpet" then unit = "pet" end
	if unit == "tot" then unit = "targettarget" end
	
	if(unit == "player") then
    local PlayerFrame = _G.PlayerFrame
		killUnitFrame(PlayerFrame)
		-- For the oUF's vehicle support:
		PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		PlayerFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
		-- User placed frames don't animate
		PlayerFrame:SetUserPlaced(true)
		PlayerFrame:SetDontSavePosition(true)
	elseif(unit == "pet") then
		killUnitFrame(_G.PetFrame)
	elseif(unit == "target") then
		killUnitFrame(_G.TargetFrame)
		killUnitFrame(_G.ComboFrame)
	elseif(unit == "focus") then
		killUnitFrame(_G.FocusFrame)
		killUnitFrame(_G.TargetofFocusFrame)
	elseif(unit == "targettarget") then
    local TargetFrameToT = _G.TargetFrameToT
		-- originalValue["showTargetOfTarget"] = GetCVar("showTargetOfTarget")
		SetCVar("showTargetOfTarget", "0", "SHOW_TARGET_OF_TARGET_TEXT")
		_G.SHOW_TARGET_OF_TARGET = "0"
		_G.TargetofTarget_Update(TargetFrameToT)
		killUnitFrame(TargetFrameToT)
	elseif(unit:match"(boss)%d?$" == "boss") then
		local id = unit:match"boss(%d)"
		if(id) then
			killUnitFrame("Boss" .. id .. "TargetFrame")
		else
			for i=1, 4 do
				killUnitFrame(("Boss%dTargetFrame"):format(i))
			end
		end
	elseif(unit:match"(party)%d?$" == "party") then
		local id = unit:match"party(%d)"
		if(id) then
			killUnitFrame("PartyMemberFrame" .. id)
		else
			for i=1, 4 do
				killUnitFrame(("PartyMemberFrame%d"):format(i))
			end
		end
	elseif(unit:match"(arena)%d?$" == "arena") then
		local id = unit:match"arena(%d)"
		if(id) then
			killUnitFrame("ArenaEnemyFrame" .. id)
		else
			for i=1, 4 do
				killUnitFrame(("ArenaEnemyFrame%d"):format(i))
			end
		end

		-- Blizzard_ArenaUI should not be loaded
		_G.Arena_LoadUI = function() end
		SetCVar("showArenaEnemyFrames", "0", "SHOW_ARENA_ENEMY_FRAMES_TEXT")
	end
end

-- @usage gUI4:EnableUnitFrame(unit)
-- @description enables a unitframe based on "unit"
-- @param unit <string> the unitID of the unit whose blizzard frame to enable (http://wowpedia.org/UnitId)
function gUI4:EnableUnitFrame(unit)
	if unit == "focus-target" then unit = "focustarget" end
	if unit == "playerpet" then unit = "pet" end
	if unit == "tot" then unit = "targettarget" end
	
	-- TODO: party and pet events
	
	if(unit == "player") then
    local PlayerFrame = _G.PlayerFrame
    local PlayerFrame_Update = _G.PlayerFrame_Update
    
		reviveUnitFrame(PlayerFrame, unit)

		PlayerFrame:RegisterEvent("UNIT_LEVEL")
		PlayerFrame:RegisterEvent("UNIT_FACTION")
		PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		PlayerFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
		PlayerFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
		PlayerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		PlayerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		PlayerFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
		PlayerFrame:RegisterEvent("PARTY_LEADER_CHANGED")
		PlayerFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
		PlayerFrame:RegisterEvent("VOICE_START")
		PlayerFrame:RegisterEvent("VOICE_STOP")
		PlayerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
		PlayerFrame:RegisterEvent("READY_CHECK")
		PlayerFrame:RegisterEvent("READY_CHECK_CONFIRM")
		PlayerFrame:RegisterEvent("READY_CHECK_FINISHED")
		PlayerFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
		PlayerFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
		PlayerFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
		PlayerFrame:RegisterEvent("VARIABLES_LOADED")
		PlayerFrame:RegisterUnitEvent("UNIT_COMBAT", "player", "vehicle")
		PlayerFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player", "vehicle")

		-- Chinese playtime stuff
		PlayerFrame:RegisterEvent("PLAYTIME_CHANGED")
		
		PlayerFrame:SetUserPlaced(false)
		PlayerFrame:SetDontSavePosition(false)
		
		PlayerFrame:Show()
		PlayerFrame:ClearAllPoints()
		PlayerFrame:SetPoint("TOPLEFT", -19, -4)
		
		PlayerFrame_Update()
	elseif(unit == "pet" or unit == "playerpet") then
    local PetFrame = _G.PetFrame
    local PetFrame_Update = _G.PetFrame_Update
    local PlayerFrame = _G.PlayerFrame
		reviveUnitFrame(PetFrame, "pet")
		PetFrame:ClearAllPoints()
		local _, class = UnitClass("player")
		if ( class == "DEATHKNIGHT") then	--Death Knights need the Pet frame moved down for their Runes and Druids need it moved down for the secondary power bar.
			PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 60, -75)
		elseif ( class == "SHAMAN" or class == "DRUID" ) then
			PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 60, -100)
		elseif ( class == "WARLOCK" ) then
			PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 60, -90)
		elseif ( class == "PALADIN" ) then
			PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 60, -90)
		elseif ( class == "PRIEST" ) then
			PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 60, -90)
		elseif ( class == "MONK" ) then
			PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 90, -100)
		else
			PetFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 80, -60)
		end
		PetFrame:RegisterEvent("UNIT_PET")
		PetFrame:RegisterEvent("PET_ATTACK_START")
		PetFrame:RegisterEvent("PET_ATTACK_STOP")
		PetFrame:RegisterEvent("PET_UI_UPDATE")
		PetFrame:RegisterEvent("PET_RENAMEABLE")
		PetFrame:RegisterUnitEvent("UNIT_COMBAT", "pet", "player")
		PetFrame:RegisterUnitEvent("UNIT_AURA", "pet", "player")
		PetFrame_Update(PetFrame)
	elseif(unit == "target") then
    local ComboFrame = _G.ComboFrame
    local TargetFrame = _G.TargetFrame
    local TargetFrame_Update = _G.TargetFrame_Update
		reviveUnitFrame(TargetFrame, unit)
		reviveUnitFrame(ComboFrame, unit)
		TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
		TargetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		TargetFrame:RegisterEvent("UNIT_HEALTH")
		TargetFrame:RegisterEvent("UNIT_FACTION")
		TargetFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
		TargetFrame:RegisterEvent("RAID_TARGET_UPDATE")
		TargetFrame:RegisterEvent("UNIT_AURA")
		if (TargetFrame.showLevel) then
			TargetFrame:RegisterEvent("UNIT_LEVEL")
		end
		if (TargetFrame.showClassification) then
			TargetFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
		end
		if (TargetFrame.showLeader) then
			TargetFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
		end
		TargetFrame:RegisterUnitEvent("UNIT_AURA", "target")
		TargetFrame:ClearAllPoints()
		TargetFrame:SetPoint("TOPLEFT", 250, -4)
		TargetFrame_Update(TargetFrame)
	elseif(unit == "focus") then
    local FocusFrame = _G.FocusFrame
    local FocusFrameToT = _G.FocusFrameToT
    local TargetFrame_Update = _G.TargetFrame_Update
		reviveUnitFrame(FocusFrame, unit)
		reviveUnitFrame(FocusFrameToT, "focustarget")
		FocusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
		if (FocusFrame.showClassification) then
			FocusFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
		end
		if (FocusFrame.smallSize) then
			FocusFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
		end
		FocusFrame:RegisterUnitEvent("UNIT_AURA", "focus")
		FocusFrame:ClearAllPoints()
		FocusFrame:SetPoint("TOPLEFT", 250, -240)
		FocusFrameToT:ClearAllPoints()
		FocusFrameToT:SetPoint("BOTTOMRIGHT", -35, -10)
		TargetFrame_Update(FocusFrame)
		-- TargetFrame_Update(FocusFrameToT)
	elseif(unit == "targettarget" or unit == "tot") then
    local TargetFrame = _G.TargetFrame
    local TargetFrameToT = _G.TargetFrameToT
    local TargetofTarget_Update = _G.TargetofTarget_Update
		reviveUnitFrame(TargetFrameToT, "targettarget")
		SetCVar("showTargetOfTarget", "1", "SHOW_TARGET_OF_TARGET_TEXT")
		_G.SHOW_TARGET_OF_TARGET = "1"
		TargetFrameToT:SetParent(TargetFrame) -- doesn't happen automatically, for some reason
		TargetFrameToT:ClearAllPoints()
		TargetFrameToT:SetPoint("BOTTOMRIGHT", TargetFrame, "BOTTOMRIGHT", -35, -10)
		TargetofTarget_Update(TargetFrameToT)
		-- if TargetFrame:IsShown() then
			-- TargetFrame_Update(TargetFrameToT)
			-- TargetFrame_Update(TargetFrame)
			-- if not(UnitIsUnit(PlayerFrame.unit, TargetFrameToT.unit)) then
				-- TargetFrameToT:Show()
			-- end
		-- end
	elseif(unit:match"(boss)%d?$" == "boss") then
		local id = unit:match"boss(%d)"
		if(id) then
      local TargetFrame_Update = _G.TargetFrame_Update
			local frame = getFrame("Boss" .. id .. "TargetFrame")
			reviveUnitFrame(frame, "boss" .. id)
			frame:RegisterEvent("UNIT_TARGETABLE_CHANGED")
			frame:ClearAllPoints()
			if (id == 1) then
				frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
				frame:SetPoint("TOPRIGHT", 55, -236)
			else
				frame:SetPoint("TOPLEFT", _G["Boss" .. (id-1) .. "TargetFrame"], "BOTTOMLEFT", 0, -30)
			end
			TargetFrame_Update(frame)
		else
			local frame
			for i=1, 5 do
        local TargetFrame_Update = _G.TargetFrame_Update
				frame = getFrame("Boss" .. i .. "TargetFrame")
				reviveUnitFrame(frame, "boss" .. i)
				frame:ClearAllPoints()
				if (id == 1) then
					frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
					frame:SetPoint("TOPRIGHT", 55, -236)
				else
					frame:SetPoint("TOPLEFT", _G["Boss" .. (id-1) .. "TargetFrame"], "BOTTOMLEFT", 0, -30)
				end
				TargetFrame_Update(frame)
			end
		end
		
	elseif(unit:match"(party)%d?$" == "party") then
		local id = unit:match"party(%d)"
		if(id) then
			reviveUnitFrame("PartyMemberFrame" .. id, "party" .. id)
		else
			for i=1, 4 do
				reviveUnitFrame(("PartyMemberFrame%d"):format(i), "party" .. id)
			end
		end
	elseif(unit:match"(arena)%d?$" == "arena") then
		local id = unit:match"arena(%d)"
		if(id) then
			reviveUnitFrame("ArenaEnemyFrame" .. id, unit)
		else
			for i=1, 4 do
				reviveUnitFrame(("ArenaEnemyFrame%d"):format(i), "arena" .. id)
			end
		end

		_G.Arena_LoadUI = Arena_LoadUI
		SetCVar("showArenaEnemyFrames", "1", "SHOW_ARENA_ENEMY_FRAMES_TEXT")
	end
end
