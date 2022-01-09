--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...
local oUF = ns.oUF or oUF

if not(oUF) then return end

-- developer stuff
local _TESTMODE = false

local _G = _G
local floor = math.floor
local strfind, format, strsub = string.find, string.format, string.sub
local setmetatable, unpack = setmetatable, unpack

local DebuffTypeColor = DebuffTypeColor

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
local L, C, F = gUI:GetEnvironment()
local Tag = function(...) return gUI:Tag(...) end -- cop out! coooop oooout!!

local TagEvents = oUF.Tags.Events
local TagMethods = oUF.Tags.Methods

-- cache up spellnames so we only need one actual function call per spellID
local spellcache = setmetatable({}, { __index = function(t, v) 
	local a = { _G.GetSpellInfo(v) } 
	if _G.GetSpellInfo(v) then 
		t[v] = a 
	end 
	return a 
end})
local GetSpellInfo = function(a) return unpack(spellcache[a]) end

-- keeping it safe until I can go through the MoP spells
local UnitAura = function(unit, spell) 
	if not(unit) or not(spell) then
		return
	else
		return _G.UnitAura(unit, spell)
	end
end

local utf8sub = function(str, i, dots)
	if not(str) then return end
	local bytes = str:len()
	if (bytes <= i) then
		return str
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = str:byte(pos)
			if (c > 0 and c <= 127) then
				pos = pos + 1
			elseif (c >= 192 and c <= 223) then
				pos = pos + 2
			elseif (c >= 224 and c <= 239) then
				pos = pos + 3
			elseif (c >= 240 and c <= 247) then
				pos = pos + 4
			end
			if (len == i) then break end
		end

		if (len == i and pos <= bytes) then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

------------------------------------------------------------------------
--	Health/Power
------------------------------------------------------------------------
if not(TagMethods["gUI™ health"]) then
	TagMethods["gUI™ health"] = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		local status = (not UnitIsConnected(unit)) and PLAYER_OFFLINE 
			or UnitIsGhost(unit) and L["Ghost"] 
			or UnitIsDead(unit) and DEAD
			or (UnitIsAFK(unit) and ((strfind(unit, "raid")) or (strfind(unit, "party")))) and CHAT_FLAG_AFK

		if (status) then 
			return status

		elseif (min ~= max) then
			if (unit == "player") then 
				return format("|cffffffff%d%%|r |cffD7BEA5-|r |cffffffff%s|r", floor(min / max * 100), Tag(("[shortvalue:%d]"):format(min)))
				
			elseif (unit == "target") then
				return format("|cffffffff%s|r |cffD7BEA5-|r |cffffffff%d%%|r", Tag(("[shortvalue:%d]"):format(min)), floor(min / max * 100))
				
			else
				return format("|cffffffff%d%%|r", floor(min / max * 100))
			end
		else
			return format("|cffffffff"..Tag(("[shortvalue:%d]"):format(max)).."|r")
		end
			
	end
end

if not(TagMethods["gUI™ healthshort"]) then
	TagMethods["gUI™ healthshort"] = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		local status = (not UnitIsConnected(unit)) and PLAYER_OFFLINE 
			or UnitIsGhost(unit) and L["Ghost"] 
			or UnitIsDead(unit) and DEAD
			or (UnitIsAFK(unit) and ((strfind(unit, "raid")) or (strfind(unit, "party")))) and CHAT_FLAG_AFK

		if (status) then 
			return status

		elseif (min ~= max) then
			return format("|cffffffff%d%%|r", floor(min / max * 100))
		else
			return format("|cffffffff"..Tag(("[shortvalue:%d]"):format(max)).."|r")
		end
			
	end
end

if not(TagMethods["gUI™ name"]) then
	TagEvents["gUI™ name"] = "UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION"
	TagMethods["gUI™ name"] = function(unit)
		local name = UnitName(unit)
		return name
	end
end

if not(TagMethods["gUI™ nameshort"]) then
	TagEvents["gUI™ nameshort"] = "UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION"
	TagMethods["gUI™ nameshort"] = function(unit)
		local name = UnitName(unit)
		return utf8sub(name, 7, false)
	end
end

if not(TagMethods["gUI™ namesmartsize"]) then
	TagEvents["gUI™ namesmartsize"] = "UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION GROUP_ROSTER_UPDATE GROUP_ROSTER_UPDATE"
	TagMethods["gUI™ namesmartsize"] = function(unit)
		local name = UnitName(unit)
		return (GetNumGroupMembers() > 15) and utf8sub(name, 7, false) or name
	end
end

if not(TagMethods["gUI™ power"]) then
	TagMethods["gUI™ power"] = function(unit)
		if (unit ~= "player") and (unit ~= "target") then return end

		local power = UnitPower(unit)
		local pType, pToken = UnitPowerType(unit)
		local min, max = UnitPower(unit), UnitPowerMax(unit)

		if (min == 0) then
			return 
			
		elseif (not UnitIsPlayer(unit)) and (not UnitPlayerControlled(unit)) or (not UnitIsConnected(unit)) then
			return
			
		elseif (UnitIsDead(unit)) or (UnitIsGhost(unit)) then
			return
			
		elseif (min == max) and (pType == 2 or pType == 3 and pToken ~= "POWER_TYPE_PYRITE") then
			return
			
		else
			if (min ~= max) then
				local shortHealth = Tag(("[shortvalue:%d]"):format((max - (max - min))))
				if (pType == 0) then
					if (unit == "player") then
						return format("%d%% |cffD7BEA5-|r %s", floor(min / max * 100), shortHealth)
						
					elseif (unit == "target") then
						return format("%s |cffD7BEA5-|r %d%%", shortHealth, floor(min / max * 100))
						
					elseif (unit == "player" and self:GetAttribute("normalUnit") == "pet") or (unit == "pet") then
						return format("%d%%", floor(min / max * 100))
						
					else
						return format("%d%% |cffD7BEA5-|r %s", floor(min / max * 100), shortHealth)
					end
				else
					return shortHealth
				end
			else
				if (unit == "pet") then
					return
					
				elseif (unit == "target") or (unit == "player") then
					return Tag(("[shortvalue:%d]"):format(min))
					
				else
					return Tag(("[shortvalue:%d]"):format(min))
				end
			end
		end
	end
end

if not(TagMethods["gUI™ demonicfury"]) then
	TagEvents["gUI™ demonicfury"] = "PLAYER_ENTERING_WORLD UNIT_POWER_BAR_HIDE UNIT_POWER_BAR_SHOW UNIT_POWER UNIT_MAXPOWER"
	TagMethods["gUI™ demonicfury"] = function(unit)
		local min = UnitPower(unit, SPELL_POWER_DEMONIC_FURY)
		local max = UnitPowerMax(unit, SPELL_POWER_DEMONIC_FURY)
		
		if (min == 0) then
			return 
			
		elseif (GetSpecialization() ~= SPEC_WARLOCK_DEMONOLOGY) then
			return
			
		elseif (not UnitIsPlayer(unit)) and (not UnitPlayerControlled(unit)) or (not UnitIsConnected(unit)) then
			return
			
		elseif (UnitIsDead(unit)) or (UnitIsGhost(unit)) then
			return
			
		elseif (min == max) then
			return
			
		else
			if (min ~= max) then
				local shortHealth = Tag(("[shortvalue:%d]"):format((max - (max - min))))
				if (pType == 0) then
					if (unit == "player") then
						return format("%d%% |cffD7BEA5-|r %s", floor(min / max * 100), shortHealth)
						
					elseif (unit == "target") then
						return format("%s |cffD7BEA5-|r %d%%", shortHealth, floor(min / max * 100))
						
					elseif (unit == "player" and self:GetAttribute("normalUnit") == "pet") or (unit == "pet") then
						return format("%d%%", floor(min / max * 100))
						
					else
						return format("%d%% |cffD7BEA5-|r %s", floor(min / max * 100), shortHealth)
					end
				else
					return shortHealth
				end
			else
				if (unit == "pet") then
					return
					
				elseif (unit == "target") or (unit == "player") then
					return Tag(("[shortvalue:%d]"):format(min))
					
				else
					return Tag(("[shortvalue:%d]"):format(min))
				end
			end
		end
	end
end

if not(TagMethods["gUI™ altpower"]) then
	TagEvents["gUI™ altpower"] = "PLAYER_ENTERING_WORLD UNIT_POWER_BAR_HIDE UNIT_POWER_BAR_SHOW UNIT_POWER UNIT_MAXPOWER"
	TagMethods["gUI™ altpower"] = function(unit)
		local barType, min = UnitAlternatePowerInfo(unit)
		local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
		local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
		
		if (cur < 0) or ( max < 100 ) then
			return
		else
			return ("%d%%"):format(cur / max * 100)
		end
	end
end

if not(TagMethods["gUI™ druid"]) then
	TagEvents["gUI™ druid"] = "UNIT_POWER UNIT_MAXPOWER UNIT_DISPLAYPOWER"
	TagMethods["gUI™ druid"] = function(unit)
		local min, max = UnitPower(unit, 0), UnitPowerMax(unit, 0)
		if (UnitPowerType(unit) ~= 0) and (min ~= max) then
			return ("%d%%"):format(min / max * 100)
		end
	end	
end

if not(TagMethods["gUI™ vengeance"]) then
	local _, currentVengeance, maxVengeance, stat, posBuff, maxHealth
	local apbase, apbuff, apdebuff = 0, 0, 0
	local spell = (GetSpellInfo(84839))

	TagEvents["gUI™ vengeance"] = "UNIT_ATTACK_POWER UNIT_MAXHEALTH ACTIVE_TALENT_GROUP_CHANGED PLAYER_TALENT_UPDATE UNIT_AURA"
	TagMethods["gUI™ vengeance"] = function(unit)
		-- check for unit and talent spec
		if (unit ~= "player") or not(F.IsPlayerTank()) then 
			return 
		end
		
		-- find the max health
		local currentMax = UnitHealthMax("player")
		if not(maxHealth) or (currentMax ~= maxHealth) then
			stat, _, posBuff, _ = UnitStat("player", 3)
			maxVengeance = (currentMax - (posBuff * UnitHPPerStamina("player")))/10 + stat
			maxHealth = currentMax
		end
		
		-- check for current value
		local v1, v2, v3 = select(14, UnitBuff(unit, spell, nil))
		-- patch 5.1 returns:
		-- v1 = true/nil depending on existance of Vengeance
		-- v2 = current AP increase
		-- v3 = current AP without the increase
		if not(v1) then
			return
		else
			return ("%d%%"):format(v2 / maxVengeance * 100)
		end
	end
end

------------------------------------------------------------------------
--	Player Status
------------------------------------------------------------------------
if not(TagMethods["gUI™ afk"]) then
	TagEvents["gUI™ afk"] = "PLAYER_FLAGS_CHANGED"
	TagMethods["gUI™ afk"] = function(unit)
		if (UnitIsAFK(unit)) then
			return CHAT_FLAG_AFK
		end
	end
end

------------------------------------------------------------------------
--	Group/Raid
------------------------------------------------------------------------
if not(TagMethods["gUI™ leader"]) then
	TagEvents["gUI™ leader"] = "PARTY_LEADER_CHANGED GROUP_ROSTER_UPDATE"
	TagMethods["gUI™ leader"] = function(unit)
		if (_TESTMODE) or ((UnitInParty(unit)) or (UnitInRaid(unit))) then
			if (UnitIsGroupLeader(unit)) then
				return [[|TInterface\GroupFrame\UI-Group-LeaderIcon:0:0:0:0:16:16:0:14:0:14|t]]
				
			elseif (UnitIsGroupAssistant(unit)) then
				return [[|TInterface\GroupFrame\UI-Group-AssistantIcon:0:0:0:0:16:16:0:14:0:14|t]]
				
			end
		end
	end
end

if not(TagMethods["gUI™ masterlooter"]) then
	TagEvents["gUI™ masterlooter"] = "PARTY_LOOT_METHOD_CHANGED GROUP_ROSTER_UPDATE"
	TagMethods["gUI™ masterlooter"] = function(unit)
		local mlunit
		local method, pid, rid = GetLootMethod()
		if (_TESTMODE) or (method == "master") then
			if (pid) then
				if (pid == 0) then
					mlunit = "player"
				else
					mlunit = "party" .. pid
				end
			elseif (rid) then
				mlunit = "raid" .. rid
			else
				return
			end
			
			if (_TESTMODE) or (UnitIsUnit(mlunit, unit)) then
				return [[|TInterface\GroupFrame\UI-Group-MasterLooter:0:0:0:0:16:16:0:15:0:16|t]]
			end
		end
	end
end

if not(TagMethods["gUI™ grouprole"]) then
	TagEvents["gUI™ grouprole"] = "PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE"
	TagMethods["gUI™ grouprole"] = function(unit)
		local role = UnitGroupRolesAssigned(unit)
		if (_TESTMODE) or (role == "TANK") then
			return [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:0:19:22:41|t]]
			
		elseif (role == "HEALER") then
			return [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:1:20|t]]
			
		elseif (role == "DAMAGER") then
			return [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:22:41|t]]
		end
	end
end
	
if not(TagMethods["gUI™ maintank"]) then
	TagEvents["gUI™ maintank"] = "GROUP_ROSTER_UPDATE GROUP_ROSTER_UPDATE"
	TagMethods["gUI™ maintank"] = function(unit)
		if (_TESTMODE) or ((UnitInRaid(unit)) and (GetPartyAssignment("MAINTANK", unit))) then
			return [[|TInterface\GroupFrame\UI-Group-MainTankIcon:0:0:0:0:16:16:0:14:0:15|t]]
		end
	end
end

if not(TagMethods["gUI™ mainassist"]) then
	TagEvents["gUI™ mainassist"] = "GROUP_ROSTER_UPDATE GROUP_ROSTER_UPDATE"
	TagMethods["gUI™ mainassist"] = function(unit)
		if (_TESTMODE) or ((UnitInRaid(unit)) and (GetPartyAssignment("MAINASSIST", unit))) then
			return [[|TInterface\GroupFrame\UI-Group-MainAssistIcon:0:0:0:0:16:16:0:15:0:16|t]]
		end
	end
end
	
------------------------------------------------------------------------
--	Combat
------------------------------------------------------------------------
if not(TagMethods["gUI™ threat"]) then
	TagEvents["gUI™ threat"] = "UNIT_THREAT_LIST_UPDATE UNIT_THREAT_SITUATION_UPDATE"
	TagMethods["gUI™ threat"] = function(unit)
		local isTanking, status, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", unit)
		--
		-- status:
		-- 3 = securely tanking (gray)
		-- 2 = insecurely tanking (yellow)
		-- 1 = not tanking but higher threat than tank (orange)
		-- 0 = not tanking and lower threat than tank (red)
		--
		if (scaledPercent and scaledPercent > 0) then
			return ("|cFF%s%d%%|r"):format(gUI:RGBToHex(GetThreatStatusColor(status)), scaledPercent)
		end
	end
end

------------------------------------------------------------------------
--	Questing
------------------------------------------------------------------------
if not(TagMethods["gUI™ quest"]) then
	TagEvents["gUI™ quest"] = "UNIT_CLASSIFICATION_CHANGED"
	TagMethods["gUI™ quest"] = function(unit)
		if (UnitIsQuestBoss(unit)) then
			return [[|TInterface\TargetingFrame\PortraitQuestBadge:0:0:0:0:32:32:0:27:0:31|t]]
		end
	end
end

if not(TagMethods["gUI™ phasing"]) then
	TagEvents["gUI™ phasing"] = "UNIT_PHASE"
	TagMethods["gUI™ phasing"] = function(unit)
		if (UnitInPhase(unit)) then
			return [[|TInterface\TargetingFrame\UI-PhasingIcon:0:0:0:0|t]]
		end
	end
end

if not(TagMethods["gUI™ resting"]) then
	TagEvents["gUI™ resting"] = "PLAYER_UPDATE_RESTING"
	TagMethods["gUI™ resting"] = function(unit)
		-- hotfix for the MoP account level bug in Cata July 25th 2012
		-- local accountLevel = GetAccountExpansionLevel()
		-- local MAX_PLAYER_LEVEL = accountLevel and MAX_PLAYER_LEVEL_TABLE[accountLevel] or UnitLevel("player") 

		-- if (unit == "player") and (IsResting()) and (UnitLevel("player") < MAX_PLAYER_LEVEL) then
			-- return [[|TInterface\CharacterFrame\UI-StateIcon:0:0:0:0:64:64:3:29:3:28|t]]
		-- end

		if (unit == "player") and (IsResting()) then
			return [[|TInterface\CharacterFrame\UI-StateIcon:0:0:0:0:64:64:3:29:3:28|t]]
		end
	end
end

------------------------------------------------------------------------
--	PvP
------------------------------------------------------------------------
if not(TagMethods["gUI™ pvp"]) then
	TagEvents["gUI™ pvp"] = "UNIT_FACTION UNIT_REACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA"
	TagMethods["gUI™ pvp"] = function(unit)
		-- don't show the PvP icon on group frames when in a battleground or arena. It's just spam there.
		if (F.IsInPvPInstance()) and (unit ~= "player") and (unit ~= "target") then
			return
		end
		local factionGroup = UnitFactionGroup(unit)
		if (UnitIsPVPFreeForAll(unit)) then
			return [[|TInterface\TargetingFrame\UI-PVP-FFA:0:0:0:0:64:64:5:36:2:39|t]]
			
		elseif (factionGroup and UnitIsPVP(unit)) then
			if (factionGroup == "Horde") then
				return ([[|TInterface\TargetingFrame\UI-PVP-%s:0:0:0:0:64:64:1:40:1:38|t]]):format(factionGroup)
				
			elseif factionGroup == "Alliance" then
				return ([[|TInterface\TargetingFrame\UI-PVP-%s:0:0:0:0:64:64:5:36:2:39|t]]):format(factionGroup)
			end
		end
	end
end

if not(TagMethods["gUI™ warsongflag"]) then
	TagEvents["gUI™ warsongflag"] = "UNIT_AURA"
	TagMethods["gUI™ warsongflag"] = function(unit)
		-- Horde Flag
		if (UnitAura(unit, GetSpellInfo(23333))) then
			return ([[|TInterface\WorldStateFrame\AllianceFlag.blp:0:0:0:0:32:32:0:32:0:32]])
			
		-- Alliance Flag
		elseif (UnitAura(unit, GetSpellInfo(23335))) then
			return ([[|TInterface\WorldStateFrame\HordeFlag.blp:0:0:0:0:32:32:0:32:0:32]])
		end
	end
end

------------------------------------------------------------------------
--	Grid Indicators 
------------------------------------------------------------------------
-- shows missing buffs, and running HoTs/Shields

-- @param r, g, b [INTEGER] values from 0-255
-- @return [STRING] texture string with a colorized gridlike HoT indicator
local indicator = function(r, g, b, count, max)
	local i = "|T" .. gUI:GetMedia("Icon", "gUI™ GridIndicator") .. ":0:0:0:0:16:16:0:16:0:16:" .. (r or 1) .. ":" .. (g or 1) .. ":" .. (b or 1) .. "|t"
	if (count) and (count > 0) then
		i = "|cFF" .. gUI:RGBToHex(unpack(C["value"])) .. count .. "|r" .. i
	end
	return i
end

-- @param debuffType [STRING] the type of debuff ("Magic", "Curse", "Poison", "Disease")
-- @return [STRING] texture string with a debuff colored grid indicator
local hasDebuffType = function(unit, debuffType)
	local DebuffTypeColor = DebuffTypeColor
	local name, dtype
	local index = 1
	while true do
		name, _, _, _, dtype = UnitAura(unit, index, "HARMFUL")
		if not(name) then break end

		if (dtype == debuffType) then
			return indicator(DebuffTypeColor[debuffType].r, DebuffTypeColor[debuffType].g, DebuffTypeColor[debuffType].b)
		end
		index = index + 1
	end
end

local numberize = function(val)
    if (val >= 1e6) then
        return ("%.1fm"):format(val / 1e6)
    elseif (val >= 1e3) then
        return ("%.1fk"):format(val / 1e3)
    else
        return ("%d"):format(val)
    end
end

local getTime = function(expirationTime)
    local expire = (expirationTime - GetTime())
    local timeleft = numberize(expire)
    if (expire > 0.5) then
        return ("|cFF" .. gUI:RGBToHex(unpack(C["value"])) .. timeleft .. "|r")
    end
end

-- reference for MoP buffs: http://www.wowhead.com/guide=1100/mists-of-pandaria-buffs-and-debuffs
-- classes and specs
-- 	*leaving out all the Hunter Pet buffs for now, they are spammy
--  *todo: check for level where the player can actually cast the given buffs to avoid spam in low level raids
local canBuff = { 
	stats = {
		DRUID = { [1] = true, [2] = true, [3] = true, [4] = true };
		-- HUNTER = { [1] = true };
		MONK = { [1] = true, [2] = true, [3] = true };
		PALADIN = { [1] = true, [2] = true, [3] = true };
	};
	stamina = {
		-- HUNTER = { [1] = true };
		PRIEST = { [1] = true, [2] = true, [3] = true };
		WARLOCK = { [1] = true, [2] = true, [3] = true };
		WARRIOR = { [1] = true, [2] = true, [3] = true };
	};
	attackpower = {
		DEATHKNIGHT = { [1] = true, [2] = true, [3] = true };
		HUNTER = { [1] = true, [2] = true, [3] = true };
		WARRIOR = { [1] = true, [2] = true, [3] = true };
	};
	spellpower = {
		-- HUNTER = { [1] = true };
		MAGE = { [1] = true, [2] = true, [3] = true };
		SHAMAN = { [1] = true, [2] = true, [3] = true };
		WARLOCK = { [1] = true, [2] = true, [3] = true };
	};
	haste = {
		DEATHKNIGHT = { [2] = true, [3] = true };
		-- HUNTER = { [1] = true, [2] = true, [3] = true };
		ROGUE = { [1] = true, [2] = true, [3] = true };
		SHAMAN = { [2] = true };
	};
	spellhaste = {
		DRUID = { [1] = true };
		-- HUNTER = { [1] = true, [2] = true, [3] = true };
		PRIEST = { [3] = true };
		SHAMAN = { [1] = true };
	};
	crit = {
		DRUID = { [2] = true, [3] = true };
		-- HUNTER = { [1] = true, [2] = true, [3] = true };
		MAGE = { [1] = true, [2] = true, [3] = true };
		MONK = { [3] = true };
	};
	mastery = {
		-- HUNTER = { [1] = true, [2] = true, [3] = true };
		PALADIN = { [1] = true, [2] = true, [3] = true };
		SHAMAN = { [1] = true, [2] = true, [3] = true };
	};
}
local _, class = UnitClass("player")
local playerCanBuff = function(type)
	return canBuff[type][class] and canBuff[type][class][GetSpecialization()]
end

-- spellIDs
local buffs = {
	stats = { -- +5% Strength, Agility, and Intellect
		[1126] = true; -- Druid, Mark of the Wild
		[90363] = true; -- Hunter, Beast Mastery, Shale Spider, Embrace of the Shale Spider
		[20217] = true; -- Paladin, Blessing of Kings
		[115921] = true; -- Monk, Legacy of the Emperor
	};
	stamina = { -- +10% Stamina
		[21562] = true; -- Priest, Power Word: Fortitude
		[103127] = true; -- Warlock, Imp: Blood Pact
		[469] = true; -- Warrior, Commanding Shout
		[90364] = true; -- Hunter, Beast Mastery, Silithid, Qiraji Fortitude
	};
	attackpower = { -- +10% melee and ranged attack power
		[57330] = true; -- Death Knight, Horn of Winter
		[19506] = true; -- Hunter, Trueshot Aura
		[6673] = true; -- Warrior, Battle Shout
	};
	spellpower = { -- 
		[1459] = true; -- Mage, Arcane Brilliance
		[61316] = true; -- Mage, Dalaran Brilliance
		[77747] = true; -- Shaman, Burning Wrath
		[109773] = true; -- Warlock, Dark Intent
		[126309] = true; -- Hunter, Beast Mastery, Waterstrider, Still Water
	};
	haste = { -- +10% melee and ranged haste
		[55610] = true; -- Death Knight, Unholy Aura 
		[113742] = true; -- Rogue, Swiftblade's Cunning
		[30809] = true; -- Shaman, Unleashed Rage
		[128432] = true; -- Hunter, Hyena, Cackling Howl
		[128433] = true; -- Hunter, Serpent, Serpent's Swiftness
	};
	spellhaste = { -- 
		[24907] = true; -- Druid, Moonkin Aura 
		[15473] = true; -- Priest, Shadowform 
		[51470] = true; -- Shaman, Elemental Oath
		[49868] = true; -- Hunter, Sporebat, Mind Quickening
	};
	crit = { -- 
		[17007] = true; -- Druid, Leader of the Pack 
		[1459] = true; -- Mage, Arcane Brilliance
		[61316] = true; -- Mage, Dalaran Brilliance
		[116781] = true; -- Monk, Windwalker, Legacy of the White Tiger
		[97229] = true; -- Hunter, Hydra, Bellowing Roar
		[24604] = true; -- Hunter, Wolf, Furious Howl
		[90309] = true; -- Hunter, Beast Mastery, Devilsaur, Terrifying Roar
		[126373] = true; -- Hunter, Beast Mastery, Quilen, Fearless Roar
		[126309] = true; -- Hunter, Beast Mastery, Waterstrider, Still Water
	};
	mastery = { -- 
		[19740] = true; -- Paladin, Blessing of Might
		[116956] = true; -- Shaman, Grace of Air
		[93435] = true; -- Hunter, Cat, Roar of Courage
		[128997] = true; -- Hunter, Beast Mastery, Spirit Beast, Spirit Beast Blessing
	};
}
local hasBuff = function(unit, groupOrSpell)
	if (type(groupOrSpell) == "string") then
		if not(buffs[groupOrSpell]) then return end
		for id,enable in pairs(buffs[groupOrSpell]) do
			if (UnitAura(unit, GetSpellInfo(id))) then
				return true
			end
		end
	elseif (type(groupOrSpell) == "number") then
		return UnitAura(unit, groupOrSpell)
	end
end

-- Stats
if not(TagMethods["gUI™ stats"]) then
	TagEvents["gUI™ stats"] = "UNIT_AURA"
	TagMethods["gUI™ stats"] = function(unit)
		if not(hasBuff(unit, "stats")) and (playerCanBuff("stats")) then 
			return indicator(128, 0, 255) 
		end
	end
end

-- Stamina
if not(TagMethods["gUI™ stamina"]) then
	TagEvents["gUI™ stamina"] = "UNIT_AURA"
	TagMethods["gUI™ stamina"] = function(unit)
		if not(hasBuff(unit, "stamina")) and (playerCanBuff("stamina")) then 
			return indicator(0, 0, 255) 
		end
	end
end

-- Attackpower
if not(TagMethods["gUI™ attackpower"]) then
	TagEvents["gUI™ attackpower"] = "UNIT_AURA"
	TagMethods["gUI™ attackpower"] = function(unit)
		if not(hasBuff(unit, "attackpower")) and (playerCanBuff("attackpower")) then 
			return indicator(255, 0, 0) 
		end
	end
end

-- Spellpower
if not(TagMethods["gUI™ spellpower"]) then
	TagEvents["gUI™ spellpower"] = "UNIT_AURA"
	TagMethods["gUI™ spellpower"] = function(unit)
		if not(hasBuff(unit, "spellpower")) and (playerCanBuff("spellpower")) then 
			return indicator(255, 0, 0) 
		end
	end
end

-- Haste
if not(TagMethods["gUI™ haste"]) then
	TagEvents["gUI™ haste"] = "UNIT_AURA"
	TagMethods["gUI™ haste"] = function(unit)
		if not(hasBuff(unit, "haste")) and (playerCanBuff("haste")) then 
			return indicator(255, 222, 0) 
		end
	end
end

-- Spellhaste
if not(TagMethods["gUI™ spellhaste"]) then
	TagEvents["gUI™ spellhaste"] = "UNIT_AURA"
	TagMethods["gUI™ spellhaste"] = function(unit)
		if not(hasBuff(unit, "spellhaste")) and (playerCanBuff("spellhaste")) then 
			return indicator(255, 222, 0) 
		end
	end
end

-- Crit
if not(TagMethods["gUI™ crit"]) then
	TagEvents["gUI™ crit"] = "UNIT_AURA"
	TagMethods["gUI™ crit"] = function(unit)
		if not(hasBuff(unit, "crit")) and (playerCanBuff("crit")) then 
			return indicator(255, 128, 0) 
		end
	end
end

-- Mastery
if not(TagMethods["gUI™ mastery"]) then
	TagEvents["gUI™ mastery"] = "UNIT_AURA"
	TagMethods["gUI™ mastery"] = function(unit)
		if not(hasBuff(unit, "mastery")) and (playerCanBuff("mastery")) then 
			return indicator(255, 128, 0) 
		end
	end
end


-- Soulstone Ressurection
if not(TagMethods["gUI™ soulstone"]) then
	TagEvents["gUI™ soulstone"] = "UNIT_AURA"
	TagMethods["gUI™ soulstone"] = function(unit)
		local name, _,_,_,_,_,_, caster = UnitAura(unit, GetSpellInfo(20707)) 
		if (caster == "player") then
			return indicator(102, 0, 255) 
		elseif (name) then
			return indicator(204, 0, 255) 
		end
	end
end

-- Focus Magic
if not(TagMethods["gUI™ focusmagic"]) then
	TagEvents["gUI™ focusmagic"] = "UNIT_AURA"
	TagMethods["gUI™ focusmagic"] = function(unit)
		if UnitAura(unit, GetSpellInfo(54648)) then 
			return indicator(204, 0, 255) 
		end
	end
end

-- Forbearance
if not(TagMethods["gUI™ forbearance"]) then
	TagEvents["gUI™ forbearance"] = "UNIT_AURA"
	TagMethods["gUI™ forbearance"] = function(unit)
		if UnitDebuff(unit, GetSpellInfo(25771)) then 
			return indicator(255, 153, 0) 
		end
	end
end

-- Weakened Soul
if not(TagMethods["gUI™ weakenedsoul"]) then
	TagEvents["gUI™ weakenedsoul"] = "UNIT_AURA"
	TagMethods["gUI™ weakenedsoul"] = function(unit)
		if UnitDebuff(unit, GetSpellInfo(6788)) then 
			return indicator(255, 153, 0) 
		end
	end
end

-- Fear Ward
if not(TagMethods["gUI™ fearward"]) then
	TagEvents["gUI™ fearward"] = "UNIT_AURA"
	TagMethods["gUI™ fearward"] = function(unit)
		if UnitAura(unit, GetSpellInfo(6346)) then 
			return indicator(139, 69, 19) 
		end
	end
end

-- Vigilance
if not(TagMethods["gUI™ vigilance"]) then
	TagEvents["gUI™ vigilance"] = "UNIT_AURA"
	TagMethods["gUI™ vigilance"] = function(unit)
		if UnitAura(unit, GetSpellInfo(50720)) then 
			return indicator(139, 69, 19) 
		end
	end
end

-- Power Word: Barrier
if not(TagMethods["gUI™ pwb"]) then
	TagEvents["gUI™ pwb"] = "UNIT_AURA"
	TagMethods["gUI™ pwb"] = function(unit)
		if UnitAura(unit, GetSpellInfo(81782)) then 
			return indicator(238, 238, 0) 
		end
	end
end

-- Power Word: Shield
if not(TagMethods["gUI™ pws"]) then
	TagEvents["gUI™ pws"] = "UNIT_AURA"
	TagMethods["gUI™ pws"] = function(unit)
		if UnitAura(unit, GetSpellInfo(17)) then 
			return indicator(51, 255, 51)
		end
	end
end

-- Renew
if not(TagMethods["gUI™ renew"]) then
	TagEvents["gUI™ renew"] = "UNIT_AURA"
	TagMethods["gUI™ renew"] = function(unit)
		local name, _,_,_,_,_, expirationTime, caster = UnitAura(unit, GetSpellInfo(139))
		if (caster == "player") then
			local spellTimer = GetTime() - expirationTime
			if (spellTimer > -2) then
				return indicator(255, 0, 0) 
			elseif (spellTimer > -4) then
				return indicator(255, 153, 0) 
			else
				return indicator(51, 255, 51)
			end
		end	
	end
end

if not(TagMethods["gUI™ renewTime"]) then
	TagMethods["gUI™ renewTime"] = function(unit)
		local name, _,_,_,_,_, expirationTime, caster = UnitAura(unit, GetSpellInfo(139))
		if (caster == "player") then 
			return getTime(expirationTime)
		end 
	end
end

-- Rejuvenation
if not(TagMethods["gUI™ rejuv"]) then
	TagEvents["gUI™ rejuv"] = "UNIT_AURA"
	TagMethods["gUI™ rejuv"] = function(unit)
		local name, _,_,_,_,_, expirationTime, caster = UnitAura(unit, GetSpellInfo(774))
		if (caster == "player") then
			local spellTimer = GetTime() - expirationTime
			if (spellTimer > -2) then
				return indicator(255, 0, 0) 
			elseif (spellTimer > -4) then
				return indicator(255, 153, 0) 
			else
				return indicator(51, 255, 51) 
			end
		end	
	end
end

if not(TagMethods["gUI™ rejuvTime"]) then
	TagMethods["gUI™ rejuvTime"] = function(unit)
		local name, _,_,_,_,_, expirationTime, caster = UnitAura(unit, GetSpellInfo(774))
		if (caster == "player") then 
			return getTime(expirationTime)
		end 
	end
end

-- Regrowth
if not(TagMethods["gUI™ regrowth"]) then
	TagEvents["gUI™ regrowth"] = "UNIT_AURA"
	TagMethods["gUI™ regrowth"] = function(unit)
		if UnitAura(unit, GetSpellInfo(8936)) then 
			return indicator(0, 255, 16)
		end
	end
end

-- Wild Growth
if not(TagMethods["gUI™ wildgrowth"]) then
	TagEvents["gUI™ wildgrowth"] = "UNIT_AURA"
	TagMethods["gUI™ wildgrowth"] = function(unit)
		if UnitAura(unit, GetSpellInfo(48438)) then 
			return indicator(51, 255, 51)
		end
	end
end

-- Cenarion Ward
if not(TagMethods["gUI™ cenarionward"]) then
	TagEvents["gUI™ cenarionward"] = "UNIT_AURA"
	TagMethods["gUI™ cenarionward"] = function(unit)
		if UnitAura(unit, GetSpellInfo(102352)) then 
			return indicator(240, 255, 51)
		end
	end
end

-- Riptide
if not(TagMethods["gUI™ riptide"]) then
	TagEvents["gUI™ riptide"] = "UNIT_AURA"
	TagMethods["gUI™ riptide"] = function(unit)
		local name, _,_,_,_,_,_, caster = UnitAura(unit, GetSpellInfo(61295))
		if (caster == 'player') then 
			return indicator(0, 254, 191)
		end
	end
end

if not(TagMethods["gUI™ riptideTime"]) then
	TagMethods["gUI™ riptideTime"] = function(unit)
		local name, _,_,_,_,_, expirationTime, caster = UnitAura(unit, GetSpellInfo(61295))
		if (caster == "player") then 
			return getTime(expirationTime)
		end 
	end
end

-- Beacon of Light 
if not(TagMethods["gUI™ beacon"]) then
	TagEvents["gUI™ beacon"] = "UNIT_AURA"
	TagMethods["gUI™ beacon"] = function(unit)
		local name, _,_,_,_,_, expirationTime, caster = UnitAura(unit, GetSpellInfo(53563))
		if not name then return end
		if (caster == "player") then
			local spellTimer = GetTime() - expirationTime
			if (spellTimer > -30) then
				return indicator(255, 0, 0)
			else
				return indicator(255, 204, 0) 
			end
		else
			return indicator(153, 102, 0)
		end
	end
end
	
-- Lifebloom
if not(TagMethods["gUI™ lifebloom"]) then
	TagEvents["gUI™ lifebloom"] = "UNIT_AURA"
	TagMethods["gUI™ lifebloom"] = function(unit)
		local name, _,_, count,_,_, expirationTime, caster = UnitAura(unit, GetSpellInfo(33763))
		if (caster == "player") then
			local spellTimer = GetTime() - expirationTime
			if (spellTimer > -2) then
				return indicator(255, 0, 0, count, 3)
			elseif (spellTimer > -4) then
				return indicator(255, 153, 0, count, 3)
			else
				return indicator(167, 253, 10, count, 3)
			end
		end	
	end
end

-- Prayer of Mending
if not(TagMethods["gUI™ mending"]) then
	TagEvents["gUI™ mending"] = "UNIT_AURA"
	TagMethods["gUI™ mending"] = function(unit)
    local name, _,_, count, _,_,_, caster = UnitAura(unit, GetSpellInfo(33076)) 
		if not(count) then return end
		if (caster == "player") then
			return indicator(102, 255, 255, count, 5)
		else
			return indicator(255, 207, 127, count, 5)
		end
	end
end

-- Earth Shield
if not(TagMethods["gUI™ earthshield"]) then
	TagEvents["gUI™ earthshield"] = "UNIT_AURA"
	TagMethods["gUI™ earthshield"] = function(unit)
		local count = select(4, UnitAura(unit, GetSpellInfo(974))) 
		if (count) then 
			return indicator(255, 207, 127, count, 9)
		end 
	end
end

-- Renewing Mist
if not(TagMethods["gUI™ renewingmist"]) then
	TagEvents["gUI™ renewingmist"] = "UNIT_AURA"
	TagMethods["gUI™ renewingmist"] = function(unit)
		if UnitAura(unit, GetSpellInfo(119611)) then 
			return indicator(0, 255, 16)
		end
	end
end

if not(TagMethods["gUI™ renewingmistTime"]) then
	TagMethods["gUI™ renewingmistTime"] = function(unit)
		local name, _,_,_,_,_, expirationTime, caster = UnitAura(unit, GetSpellInfo(119611))
		if (caster == "player") then 
			return getTime(expirationTime)
		end 
	end
end

-- Soothing Mist
if not(TagMethods["gUI™ soothingmist"]) then
	TagEvents["gUI™ soothingmist"] = "UNIT_AURA"
	TagMethods["gUI™ soothingmist"] = function(unit)
		if UnitAura(unit, GetSpellInfo(115175)) then 
			return indicator(51, 255, 51)
		end
	end
end

-- Enveloping Mist
if not(TagMethods["gUI™ envelopingmist"]) then
	TagEvents["gUI™ envelopingmist"] = "UNIT_AURA"
	TagMethods["gUI™ envelopingmist"] = function(unit)
		if UnitAura(unit, GetSpellInfo(124682)) then 
			return indicator(255, 240, 51)
		end
	end
end

-- Life Cocoon
if not(TagMethods["gUI™ lifecocoon"]) then
	TagEvents["gUI™ lifecocoon"] = "UNIT_AURA"
	TagMethods["gUI™ lifecocoon"] = function(unit)
		if UnitAura(unit, GetSpellInfo(116849)) then 
			return indicator(51, 255, 51)
		end
	end
end

-- Zen Sphere
if not(TagMethods["gUI™ zensphere"]) then
	TagEvents["gUI™ zensphere"] = "UNIT_AURA"
	TagMethods["gUI™ zensphere"] = function(unit)
		if UnitAura(unit, GetSpellInfo(124081)) then 
			return indicator(51, 240, 255)
		end
	end
end

-- Curse Debuff
if not(TagMethods["gUI™ curse"]) then
	TagEvents["gUI™ curse"] = "UNIT_AURA"
	TagMethods["gUI™ curse"] = function(unit)
		return hasDebuffType(unit, "Curse")
	end
end

-- Disease Debuff
if not(TagMethods["gUI™ disease"]) then
	TagEvents["gUI™ disease"] = "UNIT_AURA"
	TagMethods["gUI™ disease"] = function(unit)
		return hasDebuffType(unit, "Disease")
	end
end

-- Magic Debuff
if not(TagMethods["gUI™ magic"]) then
	TagEvents["gUI™ magic"] = "UNIT_AURA"
	TagMethods["gUI™ magic"] = function(unit)
		return hasDebuffType(unit, "Magic")
	end
end

-- Poison Debuff
if not(TagMethods["gUI™ poison"]) then
	TagEvents["gUI™ poison"] = "UNIT_AURA"
	TagMethods["gUI™ poison"] = function(unit)
		return hasDebuffType(unit, "Poison")
	end
end
