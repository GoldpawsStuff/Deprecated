--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Colors")

module.OnInit = function(self)
	local C = gUI:GetDataBase("colors")

	-- multipliers to darken colors
	local class = 1
	local power = 1
	
	--------------------------------------------------------------------------------------------------
	--		color library
	--------------------------------------------------------------------------------------------------
	-- ToDo:
	-- 	- remove deprecated entries
	-- 	- remove all r = 1, g = 1 etc
	-- 	- add functions to easier set and retrieve main UI colors

	C.index = { 1.00, 1.00, 1.00 }
	C.value = { 1.00, 0.82, 0.00 }
	C.dead = { 0.50, 0.50, 0.50 }
	C.disabled = { 0.40, 0.40, 0.40 }
	C.background = { 0.00, 0.00, 0.00 } -- 0
	C.backdrop = { 0.55, 0.55, 0.55 } -- 0.55
	C.border = { 0.15, 0.15, 0.15 } -- 0.15
	C.overlay = { 0.05, 0.05, 0.05 } -- 0.25
	C.hovercolor = { 0.35, 0.35, 0.35 } 
	C.shadow = { 0.00, 0.00, 0.00, 1 } 
	-- C.normal = { r = 0.15, g = 0.15, b = 0.15 } -- C.border
	C.equipped = { r = 0.10, g = 0.65, b = 0.10 } -- equipped items
	C.range = { r = 0.85, g = 0.10, b = 0.10 } -- target is out of range
	C.mana = { r = 0.10, g = 0.10, b = 0.85 } -- you haven't enough mana
	C.usable = { r = 1.00, g = 1.00, b = 1.00 } -- an item or ability is usable 
	C.unusable = { r = 0.35, g = 0.35, b = 0.35 } -- an item or ability is not usable
	C.checked = { r = 1, g = 1, b = 0.9 }
	C.flash = { r = 1, g = 0, b = 0, a = 0.3 }
	C.hover = { r = 1, g = 1, b = 1, a = 0.3 } 
	C.pushed = { r = 1, g = 0.82, b = 0, a = 0.3 } 

	-- various
	C.realm = { 1.00, 1.00, 1.00, }
	C.guild = { 1.00, 1.00, 0.70, }
	C.error = { 1.00, 0.00, 0.00, }

	-- chat
	C.GeneralChat = { 0.6, 0.6, 1.0 }
	C.TradeChat = { 0.4, 0.4, 0.8 }
	C.RaidChat = { 1.0, 0.28, 0.04 } -- same as the original RaidLeader
	C.RaidLeader = { 1.0, 0.82, 0.0 }

	-- bag module
	C.bank = { 0.35, 0.35, 0.75, 1.00 }

	-- nameplate and tooltip stuff
	C.shield = { 1, 1, 0.75, 0.75 } -- uninterruptible enemy spellcasts
	C.rare = { 0.00, 0.44, 0.87, 0.75 }; -- rare mobs, but same as rare quality loot
	C.boss = { r = 1.00, g = 0.00, b = 0.00 }

	-- threat coloring for unitframe (or other) borders
	C.target = { 0.95, 0.95, 0.65, 0.85 }
	C.threat = { 0.95, 0.05, 0.05, 0.75 }
	C.lessthreat = { 0.95, 0.65, 0.05, 0.75 }

	-- LFD role coloring. Experimental.
	C.role = {
		tank = { 0.00, 0.25, 0.45 };
		dps = { 0.45, 0.00, 0.00 };
		heal = { 0.00, 0.45, 0.00 };
	}

	-- damage feedback for unitframes
	C.feedbackcolors = {
		DAMAGE = { 0.69; 0.31; 0.31 };
		CRUSHING = { 0.69; 0.31; 0.31 };
		CRITICAL = { 0.69; 0.31; 0.31 };
		GLANCING = { 0.69; 0.31; 0.31 };
		STANDARD = { 0.84; 0.75; 0.65 };
		IMMUNE = { 0.84; 0.75; 0.65 };
		ABSORB = { 0.84; 0.75; 0.65 };
		BLOCK = { 0.84; 0.75; 0.65 };
		RESIST = { 0.84; 0.75; 0.65 };
		MISS = { 0.84; 0.75; 0.65 };
		HEAL = { 0.33; 0.59; 0.33 };
		CRITHEAL = { 0.33; 0.59; 0.33 };
		ENERGIZE = { 0.31; 0.45; 0.63 };
		CRITENERGIZE = { 0.31; 0.45; 0.63 };
	}

	-- our own class colors
	C.RAID_CLASS_COLORS = setmetatable({
		-- HUNTER = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
		-- WARLOCK = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
		-- PRIEST = { r = 1.0, g = 1.0, b = 1.0, colorStr = "ffffffff" },
		-- PALADIN = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
		-- MAGE = { r = 0.41, g = 0.8, b = 0.94, colorStr = "ff69ccf0" },
		-- ROGUE = { r = 1.0, g = 0.96, b = 0.41, colorStr = "fffff569" },
		-- DRUID = { r = 1.0, g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
		-- SHAMAN = { r = 0.0, g = 0.44, b = 0.87, colorStr = "ff0070de" },
		-- WARRIOR = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
		-- DEATHKNIGHT = { r = 0.77, g = 0.12 , b = 0.23, colorStr = "ffc41f3b" },
		-- MONK = { r = 0.0, g = 1.00 , b = 0.59, colorStr = "ff00ff96" },
		UNKNOWN = { r = 0.80; g = 0.80; b = 0.80, colorStr = "ff999999" }
	}, { __index = RAID_CLASS_COLORS })
	
	for i, v in pairs(RAID_CLASS_COLORS) do
		v.r = v.r * class
		v.g = v.g * class
		v.b = v.b * class
		v.colorStr = "ff" .. self:RGBToHex(v.r, v.g, v.b)
	end

	-- reputation coloring
	C.FACTION_BAR_COLORS = setmetatable({
		[1] = { r = 0.75, g = 0.00, b = 0.00 };
		[2] = { r = 0.75, g = 0.00, b = 0.00 };
		[3] = { r = 0.85, g = 0.40, b = 0.00 };
		[4] = { r = 0.90, g = 0.70, b = 0.00 };
		[5] = { r = 0.00, g = 0.60, b = 0.00 };
		[6] = { r = 0.00, g = 0.60, b = 0.00 };
		[7] = { r = 0.00, g = 0.60, b = 0.00 };
		[8] = { r = 0.00, g = 0.60, b = 0.00 };
	}, { __index = FACTION_BAR_COLORS })

	C.friendship = {
		[1] = { 1.00, 0.00, 0.00 }; -- Stranger
		[2] = { 1.00, 0.35, 0.00 }; -- Acquaintance
		[3] = { 1.00, 0.75, 0.00 }; -- Buddy
		[4] = { 0.00, 0.60, 0.00 }; -- Friend
		[5] = { 0.00, 0.60, 0.00 }; -- Good Friend
		[6] = { 0.00, 0.60, 0.00 }; -- Best Friend
	}
	-- threat colors for statusbars and text
	C.THREAT_STATUS_COLORS = {
		[0] = { 1/10, 1/10, 1/10 }; -- this is where anybody not being the tank should be
		[1] = { 1, 1, 0.47 }; -- this is a dps dimwit with no comprehension of anything but dps meters
		[2] = { 1, 0.6, 0 }; -- this is when the tank is losing aggro due to overnuking dps dimwits
		[3] = { 1 * 1/3, 0, 0 }; -- this is where only the tank should be
	}

	-- health and power bars
	C.health = { C.FACTION_BAR_COLORS[5].r * 2/3, C.FACTION_BAR_COLORS[5].g * 2/3, C.FACTION_BAR_COLORS[5].b * 2/3, 1.00 }

	-- combatlog GUIS filter coloring
	C.combatlog = {
		defaults = {
			spell = { a = 1.00, r = C.index[1], g = C.index[2], b = C.index[3] };
			damage = { a = 1.00, r = C.value[1], g = C.value[2], b = C.value[3] };
		};
		schoolColoring = {
			[SCHOOL_MASK_NONE] = { a = 1.00, r = 1.00, g = 1.00, b = 1.00 };
			[SCHOOL_MASK_PHYSICAL] = { a = 1.00, r = 1.00, g = 1.00, b = 0.00 };
			[SCHOOL_MASK_HOLY] = { a = 1.00, r = 1.00, g = 0.90, b = 0.50 };
			[SCHOOL_MASK_FIRE] = { a = 1.00, r = 1.00, g = 0.50, b = 0.00 };
			[SCHOOL_MASK_NATURE] = { a = 1.00, r = 0.30, g = 1.00, b = 0.30 };
			[SCHOOL_MASK_FROST] = { a = 1.00, r = 0.50, g = 1.00, b = 1.00 };
			[SCHOOL_MASK_SHADOW] = { a = 1.00, r = 0.50, g = 0.50, b = 1.00 };
			[SCHOOL_MASK_ARCANE] = { a = 1.00, r = 1.00, g = 0.50, b = 1.00 };
		};
		unitColoring = {
			[COMBATLOG_FILTER_MINE] = { a = 1, r = 0.40, g = 0.50, b = 1.00 };
			[COMBATLOG_FILTER_MY_PET] = { a = 1, r = 0.35, g = 0.75, b = 0.25 };
			[COMBATLOG_FILTER_FRIENDLY_UNITS] = { a = 1, r = 0.40, g = 0.50, b = 1.00 };
			[COMBATLOG_FILTER_HOSTILE_UNITS] = { a = 1, r = C.FACTION_BAR_COLORS[2].r, g = C.FACTION_BAR_COLORS[2].g, b = C.FACTION_BAR_COLORS[2].b };
			[COMBATLOG_FILTER_HOSTILE_PLAYERS] = { a = 1, r = C.FACTION_BAR_COLORS[2].r, g = C.FACTION_BAR_COLORS[2].g, b = C.FACTION_BAR_COLORS[2].b };
			[COMBATLOG_FILTER_NEUTRAL_UNITS] = { a = 1, r = C.FACTION_BAR_COLORS[4].r, g = C.FACTION_BAR_COLORS[4].g, b = C.FACTION_BAR_COLORS[4].b };
			[COMBATLOG_FILTER_UNKNOWN_UNITS] = { a = 1, r = 0.75, g = 0.75, b = 0.75 };
		};	
	}

	C.PowerBarColor = setmetatable({
		AMMOSLOT = { r = 0.80, g = 0.60, b = 0.00 };
		ECLIPSE = { negative = { r = 0.0, g = 0.6, b = 1.0 },  positive = { r = 1.0, g = 0.8, b = 0.0 }}; -- just looks better
		ENERGY = { r = 1.00, g = 1.00, b = 0.00 };
		FOCUS = { r = 1.00, g = 0.50, b = 0.25 };
		FUEL = { r = 0.00, g = 0.55, b = 0.50 };
		HOLY_POWER = { r = 255/255, g = 225/255, b = 75/255 };
		MANA = { r = 0.00, g = 0.00, b = 1.00 };
		RAGE = { r = 1.00, g = 0.00, b = 0.00 };
		RUNES = { r = 0.50, g = 0.50, b = 0.50 };
		RUNIC_POWER = { r = 0.00, g = 0.82, b = 1.00 };
		SOUL_SHARDS = { r = 0.50, g = 0, b = 1 };
	}, { __index = PowerBarColor })
	
	for i, v in pairs(PowerBarColor) do
		if (v.r) then v.r = v.r * power end
		if (v.g) then v.g = v.g * power end
		if (v.b) then v.b = v.b * power end
		if (v.negative) then
			if (v.negative.r) then v.negative.r = v.negative.r * power end
			if (v.negative.g) then v.negative.g = v.negative.g * power end
			if (v.negative.b) then v.negative.b = v.negative.b * power end
		end
		if (v.positive) then
			if (v.positive.r) then v.positive.r = v.positive.r * power end
			if (v.positive.g) then v.positive.g = v.positive.g * power end
			if (v.positive.b) then v.positive.b = v.positive.b * power end
		end
	end
	
	-- my own colors
	C.PowerBarColor.SHADOW_ORBS = { r = 0.5, g = 0.5, b = 0.75 };
	C.PowerBarColor.ARCANE_CHARGE = { r = 225/255, g = 255/255, b = 255/255 };
	C.PowerBarColor.BURNING_EMBERS = { r = 1, g = 0.2, b = 0 };
	C.PowerBarColor.DEMONIC_FURY = { r = 222/255, g = 95/255, b = 95/255 };
	C.PowerBarColor.UNUSED = { r = 0.00; g = 1.00; b = 1.00 }

	-- combopoints for rogues/ferals etc
	C.combopointcolors = {
		[1] = { 0.89, 0.00, 0.00 };
		[2] = { 0.89, 0.35, 0.00 };
		[3] = { 0.89, 0.65, 0.00 };
		[4] = { 0.89, 0.89, 0.00 };
		[5] = { 0.00, 0.89, 0.00 };
	}
	
	-- monk chi
	C.Chi = {
		[1] = { 0.69, 0.31, 0.31, 1 };
		[2] = { 0.65, 0.42, 0.31, 1 };
		[3] = { 0.65, 0.63, 0.35, 1 };
		[4] = { 0.46, 0.63, 0.35, 1 };
		[5] = { 0.33, 0.63, 0.33, 1 };
	};

	-- shaman totem colors
	C.totem = {
		[EARTH_TOTEM_SLOT] = { r = 0.29, g = 0.56, b = 0.16 }; 
		[FIRE_TOTEM_SLOT] = { r = 0.81, g = 0.39, b = 0.13 }; 
		[WATER_TOTEM_SLOT] = { r = 0.22, g = 0.47, b = 0.75 };
		[AIR_TOTEM_SLOT] = { r = 0.52, g = 0.22, b = 0.90 }; 
	}

	--------------------------------------------------------------------------------------------------
	--		oUF
	--------------------------------------------------------------------------------------------------
	local oUF = oUF or ns.oUF
	assert(oUF, "Couldn't find an instance of oUF")

	C.oUF = setmetatable({
		class = setmetatable({
			HUNTER = { C.RAID_CLASS_COLORS.HUNTER.r, C.RAID_CLASS_COLORS.HUNTER.g, C.RAID_CLASS_COLORS.HUNTER.b };
			WARLOCK = { C.RAID_CLASS_COLORS.WARLOCK.r, C.RAID_CLASS_COLORS.WARLOCK.g, C.RAID_CLASS_COLORS.WARLOCK.b };
			PRIEST = { C.RAID_CLASS_COLORS.PRIEST.r, C.RAID_CLASS_COLORS.PRIEST.g, C.RAID_CLASS_COLORS.PRIEST.b };
			PALADIN = { C.RAID_CLASS_COLORS.PALADIN.r, C.RAID_CLASS_COLORS.PALADIN.g, C.RAID_CLASS_COLORS.PALADIN.b };
			MAGE = { C.RAID_CLASS_COLORS.MAGE.r, C.RAID_CLASS_COLORS.MAGE.g, C.RAID_CLASS_COLORS.MAGE.b };
			MONK = { C.RAID_CLASS_COLORS.MONK.r, C.RAID_CLASS_COLORS.MONK.g, C.RAID_CLASS_COLORS.MONK.b };
			ROGUE = { C.RAID_CLASS_COLORS.ROGUE.r, C.RAID_CLASS_COLORS.ROGUE.g, C.RAID_CLASS_COLORS.ROGUE.b };
			DRUID = { C.RAID_CLASS_COLORS.DRUID.r, C.RAID_CLASS_COLORS.DRUID.g, C.RAID_CLASS_COLORS.DRUID.b };
			SHAMAN = { C.RAID_CLASS_COLORS.SHAMAN.r, C.RAID_CLASS_COLORS.SHAMAN.g, C.RAID_CLASS_COLORS.SHAMAN.b };
			WARRIOR = { C.RAID_CLASS_COLORS.WARRIOR.r, C.RAID_CLASS_COLORS.WARRIOR.g, C.RAID_CLASS_COLORS.WARRIOR.b };
			DEATHKNIGHT = { C.RAID_CLASS_COLORS.DEATHKNIGHT.r, C.RAID_CLASS_COLORS.DEATHKNIGHT.g, C.RAID_CLASS_COLORS.DEATHKNIGHT.b };
		}, { __index = oUF.colors.class }),
		reaction = setmetatable({
			[1] = { C.FACTION_BAR_COLORS[1].r, C.FACTION_BAR_COLORS[1].g, C.FACTION_BAR_COLORS[1].b };
			[2] = { C.FACTION_BAR_COLORS[2].r, C.FACTION_BAR_COLORS[2].g, C.FACTION_BAR_COLORS[2].b };
			[3] = { C.FACTION_BAR_COLORS[3].r, C.FACTION_BAR_COLORS[3].g, C.FACTION_BAR_COLORS[3].b };
			[4] = { C.FACTION_BAR_COLORS[4].r, C.FACTION_BAR_COLORS[4].g, C.FACTION_BAR_COLORS[4].b };
			[5] = { C.FACTION_BAR_COLORS[5].r, C.FACTION_BAR_COLORS[5].g, C.FACTION_BAR_COLORS[5].b };
			[6] = { C.FACTION_BAR_COLORS[6].r, C.FACTION_BAR_COLORS[6].g, C.FACTION_BAR_COLORS[6].b };
			[7] = { C.FACTION_BAR_COLORS[7].r, C.FACTION_BAR_COLORS[7].g, C.FACTION_BAR_COLORS[7].b };
			[8] = { C.FACTION_BAR_COLORS[8].r, C.FACTION_BAR_COLORS[8].g, C.FACTION_BAR_COLORS[8].b };
		}, { __index = oUF.colors.reaction }),
		health = setmetatable({ 
			0.33, 0.59, 0.33
		}, { __index = oUF.colors.health }),
		power = setmetatable({
			AMMOSLOT = { C.PowerBarColor.AMMOSLOT.r, C.PowerBarColor.AMMOSLOT.g, C.PowerBarColor.AMMOSLOT.b };
			-- is this even used at all?
			ECLIPSE = { 
				negative = { C.PowerBarColor.ECLIPSE.negative.r, C.PowerBarColor.ECLIPSE.negative.g, C.PowerBarColor.ECLIPSE.negative.b };
				positive = { C.PowerBarColor.ECLIPSE.positive.r, C.PowerBarColor.ECLIPSE.positive.g, C.PowerBarColor.ECLIPSE.positive.b };
			};
			ENERGY = { C.PowerBarColor.ENERGY.r, C.PowerBarColor.ENERGY.g, C.PowerBarColor.ENERGY.b };
			FOCUS = { C.PowerBarColor.FOCUS.r, C.PowerBarColor.FOCUS.g, C.PowerBarColor.FOCUS.b };
			FUEL = { C.PowerBarColor.FUEL.r, C.PowerBarColor.FUEL.g, C.PowerBarColor.FUEL.b };
			HOLY_POWER = { C.PowerBarColor.HOLY_POWER.r, C.PowerBarColor.HOLY_POWER.g, C.PowerBarColor.HOLY_POWER.b };
			MANA = { C.PowerBarColor.MANA.r, C.PowerBarColor.MANA.g, C.PowerBarColor.MANA.b };
			RAGE = { C.PowerBarColor.RAGE.r, C.PowerBarColor.RAGE.g, C.PowerBarColor.RAGE.b };
			RUNES = { C.PowerBarColor.RUNES.r, C.PowerBarColor.RUNES.g, C.PowerBarColor.RUNES.b };
			RUNIC_POWER = { C.PowerBarColor.RUNIC_POWER.r, C.PowerBarColor.RUNIC_POWER.g, C.PowerBarColor.RUNIC_POWER.b };
			SOUL_SHARDS = { C.PowerBarColor.SOUL_SHARDS.r, C.PowerBarColor.SOUL_SHARDS.g, C.PowerBarColor.SOUL_SHARDS.b };
			UNUSED = { C.PowerBarColor.UNUSED.r, C.PowerBarColor.UNUSED.g, C.PowerBarColor.UNUSED.b };
		}, { __index = oUF.colors.power }),
		-- this is the fancy black-to-scarlet-red transition on npc frames
		smooth = setmetatable({ 
			0.79, 0.15, 0.15, 
			0.49, 0.15, 0.15, 
			0.15, 0.15, 0.15, 
		}, { __index = oUF.colors.smooth }),
		totems = setmetatable({
			[1] = { C.totem[1].r, C.totem[1].g, C.totem[1].b };
			[2] = { C.totem[2].r, C.totem[2].g, C.totem[2].b };		
			[3] = { C.totem[3].r, C.totem[3].g, C.totem[3].b };
			[4] = { C.totem[4].r, C.totem[4].g, C.totem[4].b };
		}, { __index = oUF.colors.totems }),
		runes = setmetatable({
			[1] = { 0.7, 0.2, 0.2 };
			[2] = { 0.2, 0.5, 0.2 };
			[3] = { 0.2, 0.6, 0.6 };
			[4] = { 0.4, 0.2, 0.6 };
		}, {__index = oUF.colors.runes}),
		disconnected = setmetatable({ 
			0.6, 0.6, 0.6,
			}, { __index = oUF.colors.tapped }),
		tapped = setmetatable({ 
			0.6, 0.6, 0.6, 
		}, { __index = oUF.colors.tapped }),
	}, { __index = oUF.colors })

end
