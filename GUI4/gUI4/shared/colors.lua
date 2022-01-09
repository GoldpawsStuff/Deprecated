local ADDON = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon(ADDON, true)
if not gUI4 then return end

-- Lua API
local _G = _G
local error = error
local rawset = rawset
local type = type
local setmetatable = setmetatable
local select, unpack = select, unpack

-- WoW API
local GetItemQualityColor = _G.GetItemQualityColor
local GetThreatStatusColor = _G.GetThreatStatusColor

local EARTH_TOTEM_SLOT = _G.EARTH_TOTEM_SLOT
local FIRE_TOTEM_SLOT = _G.FIRE_TOTEM_SLOT
local WATER_TOTEM_SLOT = _G.WATER_TOTEM_SLOT
local AIR_TOTEM_SLOT = _G.AIR_TOTEM_SLOT
local NUM_ITEM_QUALITIES = _G.NUM_ITEM_QUALITIES

local BATTLENET_FONT_COLOR = _G.BATTLENET_FONT_COLOR
local DIM_RED_FONT_COLOR = _G.DIM_RED_FONT_COLOR
local GRAY_FONT_COLOR = _G.GRAY_FONT_COLOR
local GREEN_FONT_COLOR = _G.GREEN_FONT_COLOR
local LIGHTYELLOW_FONT_COLOR = _G.LIGHTYELLOW_FONT_COLOR
local NORMAL_FONT_COLOR = _G.NORMAL_FONT_COLOR
local ORANGE_FONT_COLOR = _G.ORANGE_FONT_COLOR
local RED_FONT_COLOR = _G.RED_FONT_COLOR
local YELLOW_FONT_COLOR = _G.YELLOW_FONT_COLOR

--local FACTION_BAR_COLORS = _G.FACTION_BAR_COLORS
local PLAYER_FACTION_COLORS = _G.PLAYER_FACTION_COLORS
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS


local function hex(r, g, b)
	return ("|cff%02x%02x%02x"):format(r*255, g*255, b*255)
end

local function prepare(...)
	local tbl
	if select("#", ...) == 1 then
		local old = ...
		if old.r then 
			tbl = {}
			tbl[1] = old.r or 1
			tbl[2] = old.g or 1
			tbl[3] = old.b or 1
		else
			tbl = { unpack(old) }
		end
	else
		tbl = { ... }
	end
	if #tbl == 3 then
		tbl.colorCode = hex(unpack(tbl))
	end
	return setmetatable(tbl, {
		__index = function(self) 
			return rawget(self, "unknown") or rawget(self, "UNKNOWN") or rawget(self, "UNUSED")
		end,
		__newindex = function(self)
			error("Attempt to modify read-only table")
		end,
		__metatable = false
	})
end

-- allow the addition of new indexes to the color table, 
-- but disallow any modification of them once added
local C = setmetatable({}, { 
	__metatable = false, 
	__newindex = function(tbl, key, value)
		if type(value) == "table" then
			if type(value[1]) == "number" then
				rawset(tbl, key, prepare(value))
			else
				rawset(tbl, key, setmetatable(value, {
					__newindex = function(self)
						error("Attempt to modify read-only table")
					end,
					__metatable = false
				}))
			end
		else
			error("You can't write singular values directly into gUI4's color library, use sub-libraries instead!")
		end
	end
})

function gUI4:GetColors(type, element)
	local colors = C
	if type and colors[type] then
		if element and colors[type][element] then
			return colors[type][element]
		else 
			return colors[type]
		end
	else
		return colors
	end
end

function gUI4:GetColorCode(type, element)
	local colors = C
	if type and colors[type] then
		if element and colors[type][element] and colors[type][element].colorCode then
			return colors[type][element].colorCode
		elseif colors[type].colorCode then
			return colors[type].colorCode
		end
	end
end

function gUI4:SetColor(lib, ...)
	local colors = C
	if not lib or type(lib) ~= "string" or colors[type] then return end
	local num = select("#", ...)
	if num == 1 then
		colors[lib] = ...
	elseif num == 2 or num == 3 then
		colors[lib] = prepare(...)
	else
		local tbl = {}
		for i = 1, select("#", ...), 2 do
			if type((select(i + 1, ...))) == "table" then
				tbl[(select(i, ...))] = prepare((select(i + 1, ...)))
			else
				tbl[(select(i, ...))] = prepare((select(i + 1, ...)), (select(i + 2, ...)), (select(i + 3, ...)))
			end
		end
		colors[lib] = tbl
	end
end

-- chat windows and channels
-- *I'll be using these for tons of general coloring
gUI4:SetColor("chat", {
	normal = prepare(.9, .7, .15), -- orange/yellow -- NORMAL_FONT_COLOR
	highlight = prepare(250/255, 250/255, 250/255), -- white --HIGHLIGHT_FONT_COLOR
	red = prepare(RED_FONT_COLOR),
	dimred = prepare(DIM_RED_FONT_COLOR),
	green = prepare(GREEN_FONT_COLOR),
	gray = prepare(GRAY_FONT_COLOR),
	yellow = prepare(YELLOW_FONT_COLOR),
	lightyellow = prepare(LIGHTYELLOW_FONT_COLOR),
	orange = prepare(ORANGE_FONT_COLOR),
	battlenet = prepare(BATTLENET_FONT_COLOR),
	offwhite = prepare(.79, .79, .79),
	offgreen = prepare(.35, .79, .35), -- it's a slight chance I'm making up these names
	general = prepare(.6, .6, 1),
	trade = prepare(.4, .4, .8),
	raid = prepare(1, .28, .04), -- same as the original RaidLeader
	leader = prepare(NORMAL_FONT_COLOR)
})

-- character classes
-- *index as returned by (select(2, UnitClass(unit)))
gUI4:SetColor("class", {
	DEATHKNIGHT = prepare(196/255, 31/255, 59/255),
	DEMONHUNTER = prepare(163/255, 48/255, 201/255),
	DRUID = prepare(255/255, 125/255, 10/255),
	HUNTER = prepare(171/255, 212/255, 115/255),
	MAGE = prepare(105/255, 204/255, 240/255),
	MONK = prepare(0/255, 255/255, 150/255),
	PALADIN = prepare(245/255, 140/255, 186/255),
	PRIEST = prepare(220/255, 235/255, 250/255), 
	--ROGUE = prepare(255/255, 245/255, 105/255),
	ROGUE = prepare(255/255, 225/255, 85/255),
	SHAMAN = prepare(0/255, 112/255, 222/255),
	WARLOCK = prepare(148/255, 130/255, 201/255),
	WARRIOR = prepare(199/255, 156/255, 110/255),
	UNKNOWN = prepare(195/255, 202/255, 217/255)
})

gUI4:SetColor("healpredict", {
	predict = prepare(75/255, 190/255, 75/255),
	predictOther = prepare(55/255, 170/255, 55/255),
	absorb = prepare(190/255, 220/255, 240/255),
	absorbOther = prepare(170/255, 190/255, 220/255)
})

gUI4:SetColor("glock", {
	unitframes = prepare(255/255,125/255,10/255),
	actionbars = prepare(64/255, 131/255, 38/255),
	panels = prepare(48/255, 113/255, 191/255),
	floaters = prepare(229/255, 178/255, 0/255),
	buffs = prepare(175/255, 76/255, 229/255),
	castbars = prepare(175/255, 76/255, 56/255)
})

-- factions (Horde, Alliance) 
-- *index as returned by (UnitFactionGroup("unit"))
gUI4:SetColor("faction", {
	Alliance = prepare(PLAYER_FACTION_COLORS[1]), -- Alliance
	Horde =  prepare(PLAYER_FACTION_COLORS[0]), -- Horde
	Neutral = prepare(.9, .7, 0) -- Neutral (Pandaren on Wandering Isle)
})

-- reactions
-- *index as returned by UnitReaction()
gUI4:SetColor("reaction", {
		[1] = prepare( 175/255, 76/255, 56/255 ), -- hated
		[2] = prepare( 175/255, 76/255, 56/255 ), -- hostile
		[3] = prepare( 192/255, 68/255, 0/255 ), -- unfriendly
		--[4] = prepare( 229/255, 210/255, 60/255 ), -- neutral 
		[4] = prepare( 249/255, 178/255, 35/255 ), -- neutral 
		[5] = prepare( 64/255, 131/255, 38/255 ), -- friendly
		[6] = prepare( 64/255, 131/255, 38/255 ), -- honored
		[7] = prepare( 64/255, 131/255, 38/255 ), -- revered
		[8] = prepare( 64/255, 131/255, 38/255 ), -- exalted
		civilian = prepare( 64/255, 131/255, 38/255 ) 
}) 

gUI4:SetColor("friendship", {
	prepare(192/255, 68/255, 0/255), -- #1 Stranger
	prepare(249/255, 178/255, 35/255), -- #2 Acquaintance
	prepare(64/255, 131/255, 38/255), -- #3 Buddy
	prepare(64/255, 131/255, 38/255), -- #4 Friend 
	prepare(64/255, 131/255, 38/255), -- #5 Good Friend
	prepare(64/255, 131/255, 38/255), -- #6 Best Friend
	prepare(64/255, 131/255, 38/255), -- #7 Best Friend (brawler's stuff)
	prepare(64/255, 131/255, 38/255) -- #8 Best Friend (brawler's stuff)
}) 

gUI4:SetColor("classification", {
	rare = prepare(.82 *.65, .92 *.65, 1 *.65), -- rares (silver dragon texture)
	elite = prepare(1 *.85, .82 *.85, .45 *.85) -- worldbosses, elites (winged golden dragon texture)
})

local quality = {}
for i = 0, #ITEM_QUALITY_COLORS do
--	local r, g, b = GetItemQualityColor(i)
	local r, g, b = ITEM_QUALITY_COLORS[i].r, ITEM_QUALITY_COLORS[i].g, ITEM_QUALITY_COLORS[i].b
	quality[i-1] = prepare(r, g, b)
end
gUI4:SetColor("quality", quality)

local threat = {}
for i = 0, 3 do
	local r, g, b = GetThreatStatusColor(i)
	threat[i] = prepare(r, g, b)
end
gUI4:SetColor("threat", threat)

-- role coloring
-- *index as returned by GetSpecializationRoleByID(specID) or (select(6, GetSpecializationInfoByID(specID))) where specID = GetInspectSpecialization("unit")
gUI4:SetColor("role", {
	TANK = prepare(0, .25, .45),
	DAMAGER = prepare(.45, 0, 0),
	HEALER = prepare(0, .45, 0), 
	UNKNOWN = prepare(.77, .77, .77)
})

gUI4:SetColor("guild", 1, 1, 178/255)

-- unit status colors
-- gUI4:SetColor("dead", 215/255 *.6, 190/255 *.6, 165/255 *.6) 
-- gUI4:SetColor("disconnected", 215/255 *.6, 190/255 *.6, 165/255 *.6)
-- gUI4:SetColor("ghost", 215/255 *.6, 190/255 *.6, 165/255 *.6) 
-- gUI4:SetColor("tapped", 215/255 *.6, 190/255 *.6, 165/255 *.6) -- 195/255 *.6, 202/255 *.6, 217/255 *.6 
gUI4:SetColor("dead", .5, .5, .5) 
gUI4:SetColor("disconnected", .5, .5, .5) 
gUI4:SetColor("ghost", .5, .5, .5) 
gUI4:SetColor("tapped", 161/255, 141/255, 120/255) -- .4, .4, .4
gUI4:SetColor("afk", .5, .5, .5)
gUI4:SetColor("dnd", 217/255, 52/255, 52/255)

gUI4:SetColor("xp", 18/255, 179/255, 21/255)
gUI4:SetColor("restedxp", 23/255, 93/255, 180/255)
gUI4:SetColor("restedbonus", 192/255, 111/255, 255/255)

-- health 
gUI4:SetColor("health", .25, .7, .15)
gUI4:SetColor("smooth", prepare(
	192/255, 38/255, 38/255, 
	98/255, 38/255, 38/255,
	64/255, 64/255, 64/255
))
-- gUI4:SetColor("smooth", prepare(
	-- 192/255, 38/255, 38/255, 
	-- 98/255, 38/255, 38/255,
	-- 38/255, 38/255, 38/255
-- ))
gUI4:SetColor("smoothrare", prepare(
	192/255, 38/255, 38/255, 
	98/255, 38/255, 38/255,
	.9 *.65, .95 *.65, 1 *.65
))
gUI4:SetColor("smoothelite", prepare(
	192/255, 38/255, 38/255, 
	98/255, 38/255, 38/255,
	1 *.85, .82 *.85, .45 *.85
))

-- power types
gUI4:SetColor("power", {
	ENERGY = prepare(1, 1, 0),
	FOCUS = prepare(1, .5, .25),
	MANA = prepare(18/255, 68/255, 255/255), -- 0, 0, 1
	RAGE = prepare(1, 0, 0),
	RUNES = prepare(.5, .5, .5),

	ARCANE_CHARGE = prepare(161/255 * .75, 203/255 * .75, 255/255 * .75),
	BURNING_EMBERS = prepare(151/255, 45/255, 24/255), -- 228/255, 47/255, 10/255
	CHI = prepare(.71, 1, .92),
	DEMONIC_FURY = prepare(105/255, 53/255, 142/255),-- prepare(188/255, 176/255, 227/255), -- 222/255, 95/255, 95/255 -- 206/255, 190/255, 255/255
	HOLY_POWER = prepare(245/255, 254/255, 145/255), -- 239/255, 252/255, 106/255, -- 255/255, 225/255, 75/255
	INSANITY = prepare(.5, .5, .75), -- added in Legion
	LUNAR_POWER = prepare(161/255 * .75, 203/255 * .75, 255/255 * .75), -- added in Legion
	MAELSTROM = prepare(.71, 1, .92), -- added in Legion
	FURY = prepare(.75, .35, .85), -- added in Legion
	PAIN = prepare(.85, .41, 0), -- added in Legion
	RUNIC_POWER = prepare(0, .82, 1),
	SHADOW_ORBS = prepare(.5, .5, .75), 
	SOUL_SHARDS = prepare(RAID_CLASS_COLORS.WARLOCK), -- prepare(.5, .32, .55), -- .5, 0, 1
	CHI_BAR = { 
		prepare(0/255, 102/255, 60/255),
		prepare(0/255, 153/255, 89/255),
		prepare(0/255, 204/255, 119/255),
		prepare(0/255, 255/255, 150/255), -- monk class color?
		prepare(81/255, 255/255, 180/255),
		prepare(81/255, 255/255, 180/255)
		-- prepare(.69, .31, .31),
		-- prepare(.65, .42, .31),
		-- prepare(.65, .63, .35),
		-- prepare(.46, .63, .35),
		-- prepare(.33, .63, .33)
	},
	COMBO_POINTS = {
		-- prepare(88/255, 34/255, 30/255),
		-- prepare(116/255, 34/255, 30/255),
		-- prepare(141/255, 34/255, 30/255),
		prepare(126/255, 34/255, 30/255),
		prepare(136/255, 34/255, 30/255),
		prepare(166/255, 34/255, 30/255),
		prepare(176/255, 34/255, 30/255),
		prepare(226/255, 34/255, 30/255),
		
		-- anticipation
		prepare(137/255, 34/255, 30/255),
		prepare(137/255, 34/255, 30/255),
		prepare(137/255, 34/255, 30/255),
		prepare(137/255, 34/255, 30/255),
		prepare(137/255, 34/255, 30/255),

		-- prepare(180/255, 0/255, 0/255),
		-- prepare(210/255, 90/255, 0/255),
		-- prepare(220/255, 180/255, 0/255),
		-- prepare(140/255, 160/255, 0/255),
		-- prepare(54/255, 161/255, 0/255),
		-- prepare(.89, 0, 0),
		-- prepare(.89, .35, 0),
		-- prepare(.89, .65, 0),
		-- prepare(.89, .89, 0),
		-- prepare(0, .89, 0)
	},
	ECLIPSE = { 
		negative = prepare(90/255, 110/255, 172/255),
		positive = prepare(255/255, 211/255, 117/255) 
	},
	RUNE_BAR = {
		prepare(196/255, 31/255, 60/255), -- blood
		prepare(73/255, 180/255, 28/255), -- unholy
		prepare(63/255, 103/255, 154/255), -- frost
		prepare(173/255, 62/255, 145/255) -- death -154/255, 24/255, 122/255
	}, 
	TOTEM = { 
		[EARTH_TOTEM_SLOT] = prepare(.23, .45, .13),
		[FIRE_TOTEM_SLOT] = prepare(.58, .23, .10),
		[WATER_TOTEM_SLOT] = prepare(.19, .48, .60),
		[AIR_TOTEM_SLOT] = prepare(.42, .18, .74)
	},
	
	-- vehicles
	AMMOSLOT = prepare(.8, .6, 0),
	FUEL = prepare(0, .55, .5),
	STAGGER = {
		prepare(.52, 1, .52), 
		prepare(1, .98, .72), 
		prepare(1, .42, .42)
	},

	-- the actual colors here are borrowed from PitBull4.
	POWER_TYPE_FEL_ENERGY = prepare(0.87843143939972, 0.98039221763611, 0),
	POWER_TYPE_PYRITE = prepare(0, 0.79215693473816, 1),
	POWER_TYPE_STEAM = prepare(0.94901967048645, 0.94901967048645, 0.94901967048645),
	POWER_TYPE_HEAT = prepare(1, 0.490019610742107, 0),
	POWER_TYPE_BLOOD_POWER = prepare(0.73725494556129, 0, 1),
	POWER_TYPE_OOZE = prepare(0.75686281919479, 1, 0 ),
	
	UNUSED = prepare(195/255, 202/255, 217/255)
})

-- zones
-- *index as returned by GetZonePVPInfo()
gUI4:SetColor("zone", { 
	sanctuary = prepare(.41, .8, .94), --.41, .8, .94
	arena = prepare(175/255, 76/255, 56/255), -- 1, .1, .1
	friendly = prepare(64/255, 175/255, 38/255), -- .1, 1, .1
	hostile = prepare(175/255, 76/255, 56/255), --1, .1, .1
	contested = prepare(229/255, 159/255, 28/255), --1, .7, 0
	combat = prepare(175/255, 76/255, 56/255), --1, .1, .1
	unknown = prepare(1, .9294, .7607) -- instances, bgs, contested zones on pve realms 
})

--[[
-- combat log
-- C.CombatLog = {
	-- defaults = {
		-- spell = { a = 1, r = NORMAL_FONT_COLOR.r, g = NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b },
		-- damage = { a = 1, r = HIGHLIGHT_FONT_COLOR.r, g = HIGHLIGHT_FONT_COLOR.g, b = HIGHLIGHT_FONT_COLOR.b }
	-- },
	-- schoolColoring = {
		-- [SCHOOL_MASK_NONE] = { a = 1, r = 1, g = 1, b = 1 },
		-- [SCHOOL_MASK_PHYSICAL] = { a = 1, r = 1, g = 1, b = 0 },
		-- [SCHOOL_MASK_HOLY] = { a = 1, r = 1, g = .9, b = .5 },
		-- [SCHOOL_MASK_FIRE] = { a = 1, r = 1, g = .5, b = 0 },
		-- [SCHOOL_MASK_NATURE] = { a = 1, r = .3, g = 1, b = .3 },
		-- [SCHOOL_MASK_FROST] = { a = 1, r = .5, g = 1, b = 1 },
		-- [SCHOOL_MASK_SHADOW] = { a = 1, r = .5, g = .5, b = 1 },
		-- [SCHOOL_MASK_ARCANE] = { a = 1, r = 1, g = .5, b = 1 }
	-- },
	-- unitColoring = {
		-- [COMBATLOG_FILTER_MINE] = { a = 1, r = .4, g = .5, b = 1 },
		-- [COMBATLOG_FILTER_MY_PET] = { a = 1, r = .35, g = .75, b = .25 },
		-- [COMBATLOG_FILTER_FRIENDLY_UNITS] = { a = 1, r = .4, g = .5, b = 1 },
		-- [COMBATLOG_FILTER_HOSTILE_UNITS] = { a = 1, r = .75, g = 0, b = 0 },
		-- [COMBATLOG_FILTER_HOSTILE_PLAYERS] = { a = 1, r = .75, g = 0, b = 0 },
		-- [COMBATLOG_FILTER_NEUTRAL_UNITS] = { a = 1, r = .9, g = .7, b = 0 },
		-- [COMBATLOG_FILTER_UNKNOWN_UNITS] = { a = 1, r = .75, g = .75, b = .75 }
	-- }
-- }

-- local C = {
	-- general frame colors for the entire UI
	-- frame = {
		-- overlay = { -- spell overlay
			-- threat = { .95, .05, .05, .75 }, 
			-- lessthreat = { .95, .65, .05, .75 }
		-- },
		-- border = { .7, .7, .7, 1 }, -- normal/highlight border 
		-- shade = { 0, 0, 0, 1 }, -- inner shade 
		-- gloss = { 1, 1, 1, 1 }, -- gloss overlay
		-- slot = { 1, 1, 1, 1 }, -- empty slot
		-- shadow = { 0, 0, 0, .5 }, -- drop shadow
		-- glow = { 0, 0, 0, .7 }, -- outer glow
		-- highlight = { .77, .77, .77, 1 }, -- highlight
		-- target = { .95, .95, .65, .85 } -- outer target border
	-- },
]]--

