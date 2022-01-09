local addon, gUI4 = ...

local oUF = gUI4.oUF
if not oUF then return end

local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local C = gUI4:GetColors()
local T

-- local _DEBUG = true 

-- Lua API
local tonumber, tostring = tonumber, tostring
local floor = math.floor
local unpack = unpack

-- WoW API
local GetAccountExpansionLevel = GetAccountExpansionLevel
local GetLootMethod = GetLootMethod
local GetPartyAssignment = GetPartyAssignment
local GetPVPTimer = GetPVPTimer
local GetQuestDifficultyColor = GetQuestDifficultyColor
local IsInInstance = IsInInstance
local IsPVPTimerRunning = IsPVPTimerRunning
local UnitBattlePetLevel = UnitBattlePetLevel
local _UnitAura = UnitAura
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitFactionGroup = UnitFactionGroup
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid 
local UnitIsAFK = UnitIsAFK
local UnitIsBattlePetCompanion = UnitIsBattlePetCompanion
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsUnit = UnitIsUnit
local UnitIsWildBattlePet = UnitIsWildBattlePet
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitReaction = UnitReaction
local MAX_PLAYER_LEVEL_TABLE = MAX_PLAYER_LEVEL_TABLE

-- oUF shortcuts
local _EVENTS = oUF.Tags.Events
local _TAGS = oUF.Tags.Methods

-- cache up spellnames so we only need one actual function call per spellID
local spellcache = setmetatable({}, { __index = function(t, v) 
	local a = { _G.GetSpellInfo(v) } 
	if _G.GetSpellInfo(v) then 
		t[v] = a 
	end 
	return a 
end})
local GetSpellInfo = function(a) return unpack(spellcache[a]) end

-- keeping it safe
local UnitAura = function(unit, spell) 
	if not(unit and spell) then
		return
	else
		return _UnitAura(unit, spell)
	end
end

local function short(value)
	value = tonumber(value)
	if not value then return "" end
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return tostring(value)
	end	
end

local function tiny(value)
	value = tonumber(value)
	if not value then return "" end
	if value >= 1e6 then
		return ("%dm"):format(value / 1e6)
	elseif value >= 1e3 or value <= -1e3 then
		return ("%dk"):format(value / 1e3)
	else
		return tostring(value)
	end	
end

local function hex(r, g, b)
	if type(r) == "table" then
		if r.r then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
	end
	return ("|cff%02x%02x%02x"):format(r*255, g*255, b*255)
end

-- Returns the correct difficulty color compared to the player
local function getlevelcolor(level)
	level = level - UnitLevel("player")
	if level > 4 then
		return C.chat.dimred.colorCode
	elseif level > 2 then
		return C.chat.orange.colorCode
	elseif level >= -2 then
		return C.chat.yellow.colorCode
	elseif level >= -GetQuestGreenRange() then
		return C.chat.offgreen.colorCode
	else
		return C.chat.gray.colorCode
	end
end
local GetQuestDifficultyColor = getlevelcolor -- because. better. 

local function time(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return ("%dd"):format(floor(s / day))
	elseif s >= hour then
		local h = floor(s / hour)
		local m = floor((s - h*60) / minute)
		return ("%d:%02d"):format(h, m)
	elseif s >= minute then
		local m = floor(s / minute)
		return ("%d:%02d"):format(m, floor(s - m*60))
	elseif s >= minute / 12 then
		return ("%ss"):format(floor(s))
	end
	return ("%.1f"):format(s)
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

local locale = GetLocale()
local goners = 
(locale == "enUS" or locale == "enGB") and {
	["Strand of the Ancients Emissary"] = "Emissary",
	["League of Arathor Emissary"] = "Emissary",
	["Isle of Conquest Emissary"] = "Emissary",
	["Eye of the Storm Emissary"] = "Emissary",
	["Gilnean Emissary"] = "Emissary",
	["Stormpike Emissary"] = "Emissary",
	["Tushui Emissary"] = "Emissary",
	["Silverwing Emissary"] = "Emissary",
	["Wildhammer Emissary"] = "Emissary",
	["Lunar Festival Emissary"] = "Emissary"
} or locale == "deDE" and {
	["Botschafter des Strands der Uralten"] = "Botschafter",
	["Abgesandter des Bunds von Arathor"] = "Abgesandter",
	["Abgesandter der Insel der Eroberung"] = "Abgesandter",
	["Abgesandter vom Auge des Sturms"] = "Abgesandter",
	["Botschafter aus Gilneas"] = "Botschafter",
	["Abgesandter der Sturmlanzen"] = "Abgesandter",
	["Abgesandter der Tushui"] = "Abgesandter",
	["Abgesandter der Silberschwingen"] = "Abgesandter",
	["Botschafter der Wildhämmer"] = "Botschafter",
	["Abgesandter des Mondfests"] = "Abgesandter"
} or (locale == "esES" or locale == "esMX") and {
	["Emisario de la Playa de los Ancestros"] = "Emisario",
	["Emisario de la Liga de Arathor"] = "Emisario",
	["Emisario de la Isla de la Conquista"] = "Emisario",
	["Emisario del Ojo de la Tormenta"] = "Emisario",
	["Emisario gilneano"] = "Emisario",
	["Emisario Pico Tormenta"] = "Emisario",
	["Emisario Tushui"] = "Emisario",
	["Emisaria Ala de Plata"] = "Emisario",
	["Emisario Martillo Salvaje"] = "Emisario",
	["Emisario del Festival Lunar"] = "Emisario"
} or (locale == "frFR") and {
	["Emissaire du rivage des Anciens"] = "Emissaire",
	["Emissaire de la Ligue d'Arathor"] = "Emissaire",
	["Emissaire de l'île des Conquérants"] = "Emissaire",
	["Emissaire de l'Oeil du cyclone"] = "Emissaire",
	["Emissaire gilnéen"] = "Emissaire",
	["Emissaire foudrepique"] = "Emissaire",
	["Emissaire tushui"] = "Emissaire",
	["Emissaire d'Aile-argent"] = "Emissaire",
	["Emissaire marteau-hardi"] = "Emissaire",
	["Emissaire de la fête lunaire"] = "Emissaire"
} or (locale == "itIT") and {
	["Emissario del Lido degli Antichi"] = "Emissario",
	["Emissario della Lega di Arathor"] = "Emissario",
	["Emissario dell'Isola della Conquista"] = "Emissario",
	["Emissario dell'Occhio del Ciclone"] = "Emissario",
	["Emissario di Gilneas"] = "Emissario",
	["Emissario dei Piccatonante"] = "Emissario",
	["Emissario Tushui"] = "Emissario",
	["Emissaria Alargentea"] = "Emissaria",
	["Emissario dei Granmartello"] = "Emissario",
	["Emissario dei Celebrazione della Luna"] = "Emissario"
} or (locale == "ptBR" or locale == "ptPT") and {
	["Emissário da Baía dos Ancestrais"] = "Emissário",
	["Emissário da Liga de Arathor"] = "Emissário",
	["Emissária da Ilha da Conquista"] = "Emissário",
	["Emissário do Olho da Tormenta"] = "Emissário",
	["Emissário de Guilnéas"] = "Emissário",
	["Emissário dos Lançatroz"] = "Emissário",
	["Emissário Tushui"] = "Emissário",
	["Emissário da Asa de Prata"] = "Emissário",
	["Emissário dos Martelo Feroz"] = "Emissário",
	["Emissário do Festival da Lua"] = "Emissário"
} or (locale == "ruRU") and {
	["Эмиссар Берега Древних"] = "Эмиссар",
	["Эмиссар Лиги Аратора"] = "Эмиссар",
	["Эмиссар Острова Завоеваний"] = "Эмиссар",
	["Эмиссар Ока Бури"] = "Эмиссар",
	["Посланник Гилнеаса"] = "Посланник",
	["Эмиссар из клана Грозовой Вершины"] = "Эмиссар",
	["Эмиссар Тушуй"] = "Эмиссар",
	["Посланница Среброкрылых"] = "Посланница",
	["Посланник клана Громового Молота"] = "Посланник",
	["Эмиссар Лунного фестиваля"] = "Эмиссар"
}

local function shorten(str, max)
	if not str then return "" end
	if str:len() > max then
		if goners then -- to avoid nil bugs with locales missing from the table
			for find, replace in pairs(goners) do
				str = str:gsub(find, replace)
			end
		end
	end
	if str:len() > max then
		if str:find(" ") then
			-- test if the second word has a lowercase first letter,
			-- since this usually indicate a title
			local j = str:find(" ")
			local letter = str:sub(j+1,j+1)
			if letter == letter:lower() then
				str = str:sub(1, j-1)
			else
				-- if not, start from the end
				str = str:reverse()
				local new
				local pos = 1
				while pos < str:len() do
					local j = str:find(" ", pos)
					if j then
						local word = str:sub(pos, j-1)
						if new then
							if word:len() + new:len() + 1 <= max then
								new = new .. " " .. word 
							else
								break
							end
						else
							if word:len() <= max then
								new = word
							else
								break
							end
						end
						pos = j+1
					else
						break
					end
				end
				str = (new or str):reverse()
			end
		end
	end
	return str
end

local function adjustLength(unit, baseLength, shortenOnHealth, shortenOnPvP)
	if shortenOnHealth then 
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		if min ~= max then
			baseLength = baseLength - 4
		end
	end
	-- if shortenOnPvP then
		-- local inInstance, instanceType = IsInInstance() 
		-- local pvp = (UnitIsPVPFreeForAll(unit) or UnitIsPVP(unit)) and not(inInstance and (instanceType == "pvp" or instanceType == "arena"))
		-- if pvp then 
			-- baseLength = baseLength - 3
		-- end
	-- end
	return baseLength
end

local function getSpace(unit)
	local inInstance, instanceType = IsInInstance() 
	local pvp = (UnitIsPVPFreeForAll(unit) or UnitIsPVP(unit)) and not(inInstance and (instanceType == "pvp" or instanceType == "arena"))
	return pvp  and " " or ""
end

------------------------------------------------------------------------
--	Name
------------------------------------------------------------------------

if not(_TAGS["gUI4: Name:Long"]) then
	_EVENTS["gUI4: Name:Long"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Name:Long"] = function(unit)
		local baseLength = adjustLength(unit, 18, true, true)
		return utf8sub(shorten(UnitName(unit), baseLength), baseLength, false)
	end
end

if not(_TAGS["gUI4: Name:Long:Colored"]) then
	_EVENTS["gUI4: Name:Long:Colored"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Name:Long:Colored"] = function(unit)
		local _, unitClass = UnitClass(unit)
		local unitReaction = not UnitIsPlayer(unit) and UnitReaction(unit, "player")
		local name = _TAGS["gUI4: Name:Long"](unit)
		if unitReaction then
			name = C.reaction[unitReaction].colorCode .. name .. "|r"
		elseif unitClass then
			name = C.class[unitClass].colorCode .. name .. "|r"
		end
		return name
	end
end

if not(_TAGS["gUI4: Name:Short"]) then
	_EVENTS["gUI4: Name:Short"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Name:Short"] = function(unit)
		local baseLength = adjustLength(unit, 7, false, true)
		return utf8sub(shorten(UnitName(unit), baseLength), baseLength, true)
	end
end

if not(_TAGS["gUI4: Name:Short:Colored"]) then
	_EVENTS["gUI4: Name:Short:Colored"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Name:Short:Colored"] = function(unit)
		local _, unitClass = UnitClass(unit)
		local unitReaction = not UnitIsPlayer(unit) and UnitReaction(unit, "player")
		local name = _TAGS["gUI4: Name:Short"](unit)
		if unitReaction then
			name = C.reaction[unitReaction].colorCode .. name .. "|r"
		elseif unitClass then
			name = C.class[unitClass].colorCode .. name .. "|r"
		end
		return name
	end
end

if not(_TAGS["gUI4: Name:Medium"]) then
	_EVENTS["gUI4: Name:Medium"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Name:Medium"] = function(unit)
		local baseLength = adjustLength(unit, 12, false, true)
		return utf8sub(shorten(UnitName(unit), baseLength), baseLength, false)
	end
end

if not(_TAGS["gUI4: Name:Medium:Colored"]) then
	_EVENTS["gUI4: Name:Medium:Colored"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Name:Medium:Colored"] = function(unit)
		local _, unitClass = UnitClass(unit)
		local unitReaction = not UnitIsPlayer(unit) and UnitReaction(unit, "player")
		local name = _TAGS["gUI4: Name:Medium"](unit)
		if unitReaction then
			name = C.reaction[unitReaction].colorCode .. name .. "|r"
		elseif unitClass then
			name = C.class[unitClass].colorCode .. name .. "|r"
		end
		return name
	end
end

if not(_TAGS["gUI4: SmartName:Short"]) then
	_EVENTS["gUI4: SmartName:Short"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: SmartName:Short"] = function(unit)
		local name = _TAGS["gUI4: Name:Short"](unit)
		local level = (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) and UnitBattlePetLevel(unit) or UnitLevel(unit)
		local mylevel = UnitLevel("player") 
		local accountLevel = GetAccountExpansionLevel()
		local MAX_PLAYER_LEVEL = accountLevel and MAX_PLAYER_LEVEL_TABLE[accountLevel] or mylevel
		local c = UnitClassification(unit)
		local space = getSpace(unit)
		if c == "worldboss" or not level or level < 0 then
			return "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16|t " .. name
		elseif level >= MAX_PLAYER_LEVEL and mylevel >= MAX_PLAYER_LEVEL then
			if c == "elite" or c == "rareelite" then
				return space .. "|cffff0000+|r" .. name 
			else
				return space .. name
			end
		else
			if c == "elite" or c == "rareelite" then
				return space .. getlevelcolor((level > 0) and level or 999) .. level .."|r|cffff0000+|r:" .. name
			else
				return space .. getlevelcolor((level > 0) and level or 999) .. level .."|r:" .. name
			end
		end
	end
end

if not(_TAGS["gUI4: SmartName:Short:Reverse"]) then
	_EVENTS["gUI4: SmartName:Short:Reverse"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: SmartName:Short:Reverse"] = function(unit)
		local name = _TAGS["gUI4: Name:Short"](unit)
		local level = (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) and UnitBattlePetLevel(unit) or UnitLevel(unit)
		local mylevel = UnitLevel("player") 
		local accountLevel = GetAccountExpansionLevel()
		local MAX_PLAYER_LEVEL = accountLevel and MAX_PLAYER_LEVEL_TABLE[accountLevel] or mylevel
		local c = UnitClassification(unit)
		local space = getSpace(unit)
		if c == "worldboss" or not level or level < 0 then
			return name .. " |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16|t"
		elseif level >= MAX_PLAYER_LEVEL and mylevel >= MAX_PLAYER_LEVEL then
			if c == "elite" or c == "rareelite" then
				return name .. "|cffff0000+|r" .. space
			else
				return name .. space
			end
		else
			if c == "elite" or c == "rareelite" then
				return name .. ":" .. getlevelcolor((level > 0) and level or 999) .. level .."|r|cffff0000+|r" .. space
			else
				return name .. ":" .. getlevelcolor((level > 0) and level or 999) .. level .."|r" .. space
			end
		end
	end
end

if not(_TAGS["gUI4: SmartName:Medium"]) then
	_EVENTS["gUI4: SmartName:Medium"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: SmartName:Medium"] = function(unit)
		local name = _TAGS["gUI4: Name:Medium"](unit)
		local level = (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) and UnitBattlePetLevel(unit) or UnitLevel(unit)
		local mylevel = UnitLevel("player") 
		local accountLevel = GetAccountExpansionLevel()
		local MAX_PLAYER_LEVEL = accountLevel and MAX_PLAYER_LEVEL_TABLE[accountLevel] or mylevel
		local c = UnitClassification(unit)
		local space = getSpace(unit)
		if c == "worldboss" or not level or level < 0 then
			return "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16|t " .. name
		elseif level >= MAX_PLAYER_LEVEL and mylevel >= MAX_PLAYER_LEVEL then
			if c == "elite" or c == "rareelite" then
				return space .. "|cffff0000+|r" .. name 
			else
				return space .. name
			end
		else
			if c == "elite" or c == "rareelite" then
				return space .. getlevelcolor((level > 0) and level or 999) .. level .."|r|cffff0000+|r:" .. name
			else
				return space .. getlevelcolor((level > 0) and level or 999) .. level .."|r:" .. name
			end
		end
	end
end

if not(_TAGS["gUI4: SmartName:Medium:Reverse"]) then
	_EVENTS["gUI4: SmartName:Medium:Reverse"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: SmartName:Medium:Reverse"] = function(unit)
		local name = _TAGS["gUI4: Name:Medium"](unit)
		local level = (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) and UnitBattlePetLevel(unit) or UnitLevel(unit)
		local mylevel = UnitLevel("player") 
		local accountLevel = GetAccountExpansionLevel()
		local MAX_PLAYER_LEVEL = accountLevel and MAX_PLAYER_LEVEL_TABLE[accountLevel] or mylevel
		local c = UnitClassification(unit)
		local space = getSpace(unit)
		if c == "worldboss" or not level or level < 0 then
			return name .. " |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16|t"
		elseif level >= MAX_PLAYER_LEVEL and mylevel >= MAX_PLAYER_LEVEL then
			if c == "elite" or c == "rareelite" then
				return name .. "|cffff0000+|r" .. space
			else
				return name .. space
			end
		else
			if c == "elite" or c == "rareelite" then
				return name .. ":" .. getlevelcolor((level > 0) and level or 999) .. level .."|r|cffff0000+|r" .. space
			else
				return name .. ":" .. getlevelcolor((level > 0) and level or 999) .. level .."|r" .. space
			end
		end
	end
end

if not(_TAGS["gUI4: SmartName:Long"]) then
	_EVENTS["gUI4: SmartName:Long"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: SmartName:Long"] = function(unit)
		local name = _TAGS["gUI4: Name:Long"](unit)
		local level = (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) and UnitBattlePetLevel(unit) or UnitLevel(unit)
		local mylevel = UnitLevel("player") 
		local accountLevel = GetAccountExpansionLevel()
		local MAX_PLAYER_LEVEL = accountLevel and MAX_PLAYER_LEVEL_TABLE[accountLevel] or mylevel
		local c = UnitClassification(unit)
		local space = getSpace(unit)
		if c == "worldboss" or not level or level < 0 then
			return "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16|t " .. name
		elseif level >= MAX_PLAYER_LEVEL and mylevel >= MAX_PLAYER_LEVEL then
			if c == "elite" or c == "rareelite" then
				return space .. "|cffff0000+|r" .. name 
			else
				return space .. name
			end
		else
			if c == "elite" or c == "rareelite" then
				return space .. getlevelcolor((level > 0) and level or 999) .. level .."|r|cffff0000+|r:" .. name
			else
				return space .. getlevelcolor((level > 0) and level or 999) .. level .."|r:" .. name
			end
		end
	end
end

if not(_TAGS["gUI4: SmartName:Long:Reverse"]) then
	_EVENTS["gUI4: SmartName:Long:Reverse"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA PLAYER_ALIVE PLAYER_DEAD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: SmartName:Long:Reverse"] = function(unit)
		local name = _TAGS["gUI4: Name:Long"](unit)
		local level = (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) and UnitBattlePetLevel(unit) or UnitLevel(unit)
		local mylevel = UnitLevel("player") 
		local accountLevel = GetAccountExpansionLevel()
		local MAX_PLAYER_LEVEL = accountLevel and MAX_PLAYER_LEVEL_TABLE[accountLevel] or mylevel
		local c = UnitClassification(unit)
		local inInstance, instanceType = IsInInstance() 
		local displayPvP = not(inInstance and (instanceType == "pvp" or instanceType == "arena"))
		local ffa = UnitIsPVPFreeForAll(unit) and displayPvP
		local pvp = UnitIsPVP(unit) and displayPvP
		local space = getSpace(unit)
		if c == "worldboss" or not level or level < 0 then
			return name .. " |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16|t"
		elseif level >= MAX_PLAYER_LEVEL and mylevel >= MAX_PLAYER_LEVEL then
			if c == "elite" or c == "rareelite" then
				return name .. "|cffff0000+|r" .. space
			else
				return name .. space
			end
		else
			if c == "elite" or c == "rareelite" then
				return name .. ":" .. getlevelcolor((level > 0) and level or 999) .. level .."|r|cffff0000+|r" .. space
			else
				return name .. ":" .. getlevelcolor((level > 0) and level or 999) .. level .."|r" .. space
			end
		end
	end
end

if not(_TAGS["gUI4: Name:Tiny"]) then
	_EVENTS["gUI4: Name:Tiny"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA"
	_TAGS["gUI4: Name:Tiny"] = function(unit)
		return utf8sub(UnitName(unit), 4, false)
	end
end

if not(_TAGS["gUI4: Name:Tiny:Colored"]) then
	_EVENTS["gUI4: Name:Tiny:Colored"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE UNIT_REACTION UNIT_FACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA"
	_TAGS["gUI4: Name:Tiny:Colored"] = function(unit)
		local _, unitClass = UnitClass(unit)
		local unitReaction = not UnitIsPlayer(unit) and UnitReaction(unit, "player")
		local name = _TAGS["gUI4: Name:Tiny"](unit)
		if unitReaction then
			name = C.reaction[unitReaction].colorCode .. name .. "|r"
		elseif unitClass then
			name = C.class[unitClass].colorCode .. name .. "|r"
		end
		return name
	end
end



------------------------------------------------------------------------
--	Health/Power
------------------------------------------------------------------------

if not(_TAGS["gUI4: MissingHealth"]) then
	_EVENTS["gUI4: MissingHealth"] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ALIVE PLAYER_DEAD PLAYER_ENTERING_WORLD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: MissingHealth"] = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		local status = (not UnitIsConnected(unit)) and PLAYER_OFFLINE 
			or UnitIsGhost(unit) and DEAD
			or UnitIsDead(unit) and DEAD
			or (UnitIsAFK(unit) and (unit:find("raid") or unit:find("party"))) and CHAT_FLAG_AFK
		if status then 
			return status
		elseif min ~= max then
			return ("%s"):format(short(min-max)) 
		end
	end
end

if not(_TAGS["gUI4: Health"]) then
	_EVENTS["gUI4: Health"] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ALIVE PLAYER_DEAD PLAYER_ENTERING_WORLD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Health"] = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		local status = (not UnitIsConnected(unit)) and PLAYER_OFFLINE 
			or UnitIsGhost(unit) and DEAD
			or UnitIsDead(unit) and DEAD
			or (UnitIsAFK(unit) and (unit:find("raid") or unit:find("party"))) and CHAT_FLAG_AFK
		if status then 
			return status
		elseif min ~= max then
			return ("|cffcc5555%s|r |cff666666-|r %d%%"):format(short(min), floor(min / max * 100))
		else
			return short(min) 
		end
	end
end

if not(_TAGS["gUI4: Health:Reverse"]) then
	_EVENTS["gUI4: Health:Reverse"] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ALIVE PLAYER_DEAD PLAYER_ENTERING_WORLD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Health:Reverse"] = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit) -- script ran too long?...?
		local status = (not UnitIsConnected(unit)) and PLAYER_OFFLINE 
			or UnitIsGhost(unit) and DEAD
			or UnitIsDead(unit) and DEAD
			or (UnitIsAFK(unit) and (unit:find("raid") or unit:find("party"))) and CHAT_FLAG_AFK
		if status then 
			return status
		elseif min ~= max then
			return ("%d%% |cff666666-|r |cffcc5555%s|r"):format(floor(min / max * 100), short(min))
		else
			return short(min) 
		end
	end
end

if not(_TAGS["gUI4: Health:Simple"]) then
	_EVENTS["gUI4: Health:Simple"] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ALIVE PLAYER_DEAD PLAYER_ENTERING_WORLD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Health:Simple"] = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		local status = (not UnitIsConnected(unit)) and PLAYER_OFFLINE 
			or UnitIsGhost(unit) and DEAD
			or UnitIsDead(unit) and DEAD
			or (UnitIsAFK(unit) and (unit:find("raid") or unit:find("party"))) and CHAT_FLAG_AFK
		if status then 
			return status
		elseif min ~= max then
			return ("%d%%"):format(floor(min / max * 100))
		else
			return short(min) 
		end
	end
end

if not(_TAGS["gUI4: Health:Percentage"]) then
	_EVENTS["gUI4: Health:Percentage"] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ALIVE PLAYER_DEAD PLAYER_ENTERING_WORLD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Health:Percentage"] = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		local status = (not UnitIsConnected(unit)) and PLAYER_OFFLINE 
			or UnitIsGhost(unit) and DEAD
			or UnitIsDead(unit) and DEAD
			or (UnitIsAFK(unit) and (unit:find("raid") or unit:find("party"))) and CHAT_FLAG_AFK
		if status then 
			return status
		else
			return ("%d%%"):format(floor(min / max * 100))
		end
	end
end

if not(_TAGS["gUI4: Health:Tiny"]) then
	_EVENTS["gUI4: Health:Tiny"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE PLAYER_ALIVE PLAYER_DEAD PLAYER_ENTERING_WORLD PLAYER_LEAVING_WORLD PLAYER_FLAGS_CHANGED PLAYER_LOGOUT PLAYER_LOGIN GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Health:Tiny"] = function(unit)
		local min, max = UnitHealth(unit), UnitHealthMax(unit)
		local status = (not UnitIsConnected(unit)) and PLAYER_OFFLINE 
		or UnitIsGhost(unit) and DEAD
		or UnitIsDead(unit) and DEAD
		or (UnitIsAFK(unit) and (unit:find("raid") or unit:find("party"))) and CHAT_FLAG_AFK
		if status then 
			return status
		elseif min ~= max then
			return ("%d%%"):format(floor(min / max * 100))
		else
			return tiny(min) 
		end
	end
end

if not(_TAGS["gUI4: Power"]) then
	_EVENTS["gUI4: Power"] = "UNIT_MAXPOWER UNIT_POWER UNIT_DISPLAYPOWER"
	_TAGS["gUI4: Power"] = function(unit)
		if (unit ~= "player") and (unit ~= "target") then return end
		local power = UnitPower(unit)
		local pType, pToken = UnitPowerType(unit)
		local min, max = UnitPower(unit), UnitPowerMax(unit)
		if min == 0 then
			return 
		elseif (not UnitIsPlayer(unit)) and (not UnitPlayerControlled(unit)) or (not UnitIsConnected(unit)) then
			return
		elseif (UnitIsDead(unit)) or (UnitIsGhost(unit)) then
			return
		else
			if min ~= max and pType == 0 then
				return ("%d%%"):format(floor(min / max * 100))
			elseif unit == "pet" then
				return
			else
				return short(min) 
			end
		end
	end
end

if not(_TAGS["gUI4: DruidMana"]) then
	_EVENTS["gUI4: DruidMana"] = "UNIT_MAXPOWER UNIT_POWER UNIT_DISPLAYPOWER"
	_TAGS["gUI4: DruidMana"] = function(unit)
		if unit ~= "player" then return end
		if UnitPowerType("player") == SPELL_POWER_MANA then
			return
		end
		local min, max = UnitPower("player", SPELL_POWER_MANA), UnitPowerMax("player", SPELL_POWER_MANA)
		if min == max then
			return 
		else
			return ("%d%%"):format(floor(min / max * 100))
		end
	end
end

------------------------------------------------------------------------
--	Player Status
------------------------------------------------------------------------

if not(_TAGS["gUI4: Resting"]) then
	_EVENTS["gUI4: Resting"] = "PLAYER_UPDATE_RESTING"
	_TAGS["gUI4: Resting"] = function(unit)
		if unit ~= "player" or not IsResting() then return end
		local resting = gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft")
		local left, right, top, bottom = gUI4:GetMedia("Texture", "StateIconGrid", 64, 64, "Warcraft"):GetGridTexCoord(1)
		local width, height = resting:GetTexSize()
		local path = resting:GetPath()
		return ("|T%s:%d:%d:0:0:%d:%d:%d:%d:%d:%d|t"):format(path, 32, 32, width, height, left*width, right*width, top*height, bottom*height)
	end
end

------------------------------------------------------------------------
--	PvP
------------------------------------------------------------------------

if not(_TAGS["gUI4: PvP"]) then
	_EVENTS["gUI4: PvP"] = "UNIT_FACTION UNIT_REACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA"
	_TAGS["gUI4: PvP"] = function(unit)
		-- don't show the PvP icon in battlegrounds or arena. It's just spam there.
		local inInstance, instanceType = IsInInstance()
		if not _DEBUG and inInstance and (instanceType == "pvp" or instanceType == "arena") then
			return
		end
		local factionGroup = UnitFactionGroup(unit)
		if UnitIsPVPFreeForAll(unit) then
			return [[|TInterface\TargetingFrame\UI-PVP-FFA:20:20:0:0:64:64:5:36:2:39|t]]
		elseif _DEBUG or (factionGroup and UnitIsPVP(unit)) then
			if factionGroup == "Horde" then
				-- return "|TInterface\\TargetingFrame\\UI-PVP-Horde:16:16:-4:0:64:64:0:40:0:40|t"
				-- return [[|T]]..gUI4:GetMedia("Texture", "FactionHorde", 32, 32, "Warcraft"):GetPath()..[[:20:20:0:0:32:32:0:32:0:32|t]]
				return ([[|TInterface\TargetingFrame\UI-PVP-%s:20:20:0:0:64:64:1:40:1:38|t]]):format(factionGroup)
			elseif _DEBUG or factionGroup == "Alliance" then
				-- return [[|T]]..gUI4:GetMedia("Texture", "FactionAlliance", 32, 32, "Warcraft"):GetPath()..[[:20:20:0:0:32:32:0:32:0:32|t]]
				return ([[|TInterface\TargetingFrame\UI-PVP-%s:20:20:0:0:64:64:5:36:2:39|t]]):format(factionGroup)
			end
		end
	end
end

if not(_TAGS["gUI4: PvP:Player"]) then
	_EVENTS["gUI4: PvP:Player"] = "UNIT_FACTION UNIT_REACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA"
	_TAGS["gUI4: PvP:Player"] = function(unit)
		-- don't show the PvP icon in battlegrounds or arena. It's just spam there.
		local inInstance, instanceType = IsInInstance()
		if not _DEBUG and inInstance and (instanceType == "pvp" or instanceType == "arena") then
			return
		end
		local isPlayer = UnitIsPlayer(unit)
		if not isPlayer then
			return
		end
		local factionGroup = UnitFactionGroup(unit)
		if UnitIsPVPFreeForAll(unit) then
			return [[|TInterface\TargetingFrame\UI-PVP-FFA:20:20:0:0:64:64:5:36:2:39|t]]
		elseif _DEBUG or (factionGroup and UnitIsPVP(unit)) then
			if factionGroup == "Horde" then
				-- return [[|T]]..gUI4:GetMedia("Texture", "FactionHorde", 32, 32, "Warcraft"):GetPath()..[[:20:20:0:0:32:32:0:32:0:32|t]]
				return ([[|TInterface\TargetingFrame\UI-PVP-%s:20:20:0:0:64:64:1:40:1:38|t]]):format(factionGroup)
			elseif _DEBUG or factionGroup == "Alliance" then
				-- return [[|T]]..gUI4:GetMedia("Texture", "FactionAlliance", 32, 32, "Warcraft"):GetPath()..[[:20:20:0:0:32:32:0:32:0:32|t]]
				return ([[|TInterface\TargetingFrame\UI-PVP-%s:20:20:0:0:64:64:5:36:2:39|t]]):format(factionGroup)
			end
		end
	end
end

if not(_TAGS["gUI4: PvP:Small"]) then
	_EVENTS["gUI4: PvP:Small"] = "UNIT_FACTION UNIT_REACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA"
	_TAGS["gUI4: PvP:Small"] = function(unit)
		-- don't show the PvP icon in battlegrounds or arena. It's just spam there.
		local inInstance, instanceType = IsInInstance()
		if not _DEBUG and inInstance and (instanceType == "pvp" or instanceType == "arena") then
			return
		end
		local factionGroup = UnitFactionGroup(unit)
		if UnitIsPVPFreeForAll(unit) then
			return [[|TInterface\TargetingFrame\UI-PVP-FFA:18:18:0:0:64:64:5:36:2:39|t]]
		elseif _DEBUG or (factionGroup and UnitIsPVP(unit)) then
			if factionGroup == "Horde" then
				return ([[|TInterface\TargetingFrame\UI-PVP-%s:18:18:0:0:64:64:1:40:1:38|t]]):format(factionGroup)
			elseif _DEBUG or factionGroup == "Alliance" then
				return ([[|TInterface\TargetingFrame\UI-PVP-%s:18:18:0:0:64:64:5:36:2:39|t]]):format(factionGroup)
			end
		end
	end
end

if not(_TAGS["gUI4: WarsongFlag"]) then
	_EVENTS["gUI4: WarsongFlag"] = "UNIT_AURA"
	_TAGS["gUI4: WarsongFlag"] = function(unit)
		-- Horde Flag
		if _DEBUG or UnitAura(unit, GetSpellInfo(23333)) then
			return ([[|TInterface\WorldStateFrame\AllianceFlag.blp:0:0:0:0:32:32:0:32:0:32]])
		-- Alliance Flag
		elseif UnitAura(unit, GetSpellInfo(23335)) then
			return ([[|TInterface\WorldStateFrame\HordeFlag.blp:0:0:0:0:32:32:0:32:0:32]])
		end
	end
end

if not(_TAGS["gUI4: PvP:Timer"]) then
	_EVENTS["gUI4: PvP:Timer"] = "UNIT_FACTION UNIT_REACTION PLAYER_ENTERING_WORLD ZONE_CHANGED_NEW_AREA"
	_TAGS["gUI4: PvP:Timer"] = function(unit)
		if unit ~= "player" then return end
		local inInstance, instanceType = IsInInstance() 
		local pvp = (UnitIsPVPFreeForAll(unit) or UnitIsPVP(unit)) and not(inInstance and (instanceType == "pvp" or instanceType == "arena"))
		local hasTimer = pvp and IsPVPTimerRunning()
		if not hasTimer then return end
		local ms = GetPVPTimer()
		if ms > 0 and ms < 301000 then
			if ms and ms > 10000 then
				return time(ms /1000)
			else
				return hex(.99, .31, .31) .. time(ms /1000) .. "|r"
			end
		end	
	end
end

------------------------------------------------------------------------
--	Groups
------------------------------------------------------------------------

if not(_TAGS["gUI4: Leader"]) then
	_EVENTS["gUI4: Leader"] = "PARTY_LEADER_CHANGED GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: Leader"] = function(unit)
		if _DEBUG or UnitInParty(unit) or UnitInRaid(unit) then
			if _DEBUG or UnitIsGroupLeader(unit) then
				return [[|TInterface\GroupFrame\UI-Group-LeaderIcon:0:0:0:0:16:16:0:14:0:14|t]]
			elseif UnitIsGroupAssistant(unit) then
				return [[|TInterface\GroupFrame\UI-Group-AssistantIcon:0:0:0:0:16:16:0:14:0:14|t]]
			end
		end
	end
end

if not(_TAGS["gUI4: MasterLooter"]) then
	_EVENTS["gUI4: MasterLooter"] = "PARTY_LOOT_METHOD_CHANGED GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: MasterLooter"] = function(unit)
		local mlunit
		local method, pid, rid = GetLootMethod()
		if _DEBUG or method == "master" then
			if _DEBUG or pid == 0 then
				mlunit = "player"
			elseif pid then 
				mlunit = "party" .. pid
			elseif rid then
				mlunit = "raid" .. rid
			else
				return
			end
			if _DEBUG or UnitIsUnit(mlunit, unit) then
				return [[|TInterface\GroupFrame\UI-Group-MasterLooter:0:0:0:0:16:16:0:15:0:16|t]]
			end
		end
	end
end

-- ToDo: Add in my own icons
if not(_TAGS["gUI4: GroupRole"]) then
	_EVENTS["gUI4: GroupRole"] = "PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: GroupRole"] = function(unit)
		local role = UnitGroupRolesAssigned(unit)
		if _DEBUG or role == "TANK" then
			return [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:0:19:22:41|t]]
		elseif role == "HEALER" then
			return [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:1:20|t]]
		elseif role == "DAMAGER" then
			return [[|TInterface\LFGFrame\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:22:41|t]]
		end
	end
end
	
if not(_TAGS["gUI4: MainTank"]) then
	_EVENTS["gUI4: MainTank"] = "GROUP_ROSTER_UPDATE GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: MainTank"] = function(unit)
		if _DEBUG or (UnitInRaid(unit) and GetPartyAssignment("MAINTANK", unit)) then
			return [[|TInterface\GroupFrame\UI-Group-MainTankIcon:0:0:0:0:16:16:0:14:0:15|t]]
		end
	end
end

if not(_TAGS["gUI4: MainAssist"]) then
	_EVENTS["gUI4: MainAssist"] = "GROUP_ROSTER_UPDATE GROUP_ROSTER_UPDATE"
	_TAGS["gUI4: MainAssist"] = function(unit)
		if _DEBUG or (UnitInRaid(unit) and GetPartyAssignment("MAINASSIST", unit)) then
			return [[|TInterface\GroupFrame\UI-Group-MainAssistIcon:0:0:0:0:16:16:0:15:0:16|t]]
		end
	end
end


------------------------------------------------------------------------
--	Combat
------------------------------------------------------------------------


------------------------------------------------------------------------
--	Questing
------------------------------------------------------------------------



------------------------------------------------------------------------
--	Grid Indicators
------------------------------------------------------------------------


