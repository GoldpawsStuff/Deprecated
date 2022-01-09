--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...
local oUF = ns.oUF or oUF 

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local unitframes = gUI:GetModule("Unitframes")
local R = unitframes:GetDataBase("auras")
local RaidGroups = unitframes:GetDataBase("raidgroups")
local UnitFrames = unitframes:GetDataBase("unitframes")

R.AuraList = {}
R.PetAuraList = {}

local localizedClass, class = UnitClass("player")
local race = select(2, UnitRace("player"))
local spellIDToName = function(spellID)
	-- add the aura to our custom filter for the unitframes
	R.addAura(spellID, 3, true) -- by anyone on friendly
	local sname = _G.GetSpellInfo(spellID) -- use the global func
	if (sname) then
		return sname
	else
		local name, realm = UnitName("player")
		if not(realm) or ((name == "Goldpaw") and (realm == "Draenor")) then
			print(spellID, "doesn't exist (ORD)")
		end
	end
end
local unitIsPlayer = { player = true, pet = true, vehicle = true }
local auraFilter = {
	[1] = function(self, unit, caster) return true end;
	[2] = function(self, unit, caster) return unitIsPlayer[caster] end;
	[3] = function(self, unit, caster) return UnitIsFriend(unit, "player") and UnitPlayerControlled(unit) end;
	[4] = function(self, unit, caster) return (unit == "player") and not(self.__owner.isGroupFrame) end;
}
local addAura = function(spellID, v, silent)
	local spellName = GetSpellInfo(spellID)
	
	-- storing all relevant auras by name instead of ID
	if (spellName) then
		if not(R.AuraList[spellName]) then
			R.AuraList[spellName] = v
		end
	else
		if not(silent) then
			-- in case of an invalid/deprecated spellID, we print it out for easier debugging
			local name, realm = UnitName("player")
			if not(realm) or ((name == "Goldpaw") and (realm == "Draenor")) then
				print(spellID, "doesn't exist (aurafilter)")
			end
		end
	end
end
local addAuras = function(auras) 
	for spellID, v in pairs(auras) do 
		addAura(spellID, v)
	end 
end
local addPetAuras = function(auras)
	for spellID, v in pairs(auras) do 
		local spellName = GetSpellInfo(spellID)
		
		-- storing all relevant auras by name instead of ID
		if (spellName) then
			if not(R.PetAuraList[spellName]) then
				R.PetAuraList[spellName] = v
			end
		else
			if not(silent) then
				-- in case of an invalid/deprecated spellID, we print it out for easier debugging
				local name, realm = UnitName("player")
				if not(realm) or ((name == "Goldpaw") and (realm == "Draenor")) then
					print(spellID, "doesn't exist (aurafilter)")
				end
			end
		end
	end 
end

-- give other modules access to adding debuffs
R.addAura = addAura
R.addAuras = addAuras
R.addPetAuras = addPetAuras

-- full credits to Phanx for most of this list (http://www.wowinterface.com/downloads/info13993-oUFPhanx.html)
-- 1 = by anyone on anyone
-- 2 = by player on anyone
-- 3 = by anyone on friendly
-- 4 = by anyone on player
------------------------------------------------------------------------
--	General PvP
------------------------------------------------------------------------
addAuras({
	[50541] = 1; -- Clench (hunter scorpid)
	[676] = 1; -- Disarm (warrior)
	[51722] = 1; -- Dismantle (rogue)
	[117368] = 1; -- Grapple Weapon (monk)
	[91644] = 1; -- Snatch (hunter bird of prey)
	
	[25046] = 1; -- Arcane Torrent (blood elf - rogue)
	[28730] = 1; -- Arcane Torrent (blood elf - mage, paladin, priest, warlock)
	[50613] = 1; -- Arcane Torrent (blood elf - death knight)
	[69179] = 1; -- Arcane Torrent (blood elf - warrior)
	[80483] = 1; -- Arcane Torrent (blood elf - hunter)
	[129597] = 1; -- Arcane Torrent (blood elf - monk)
	[31935] = 1; -- Avenger's Shield (paladin)
	[102051] = 1; -- Frostjaw (mage)
	[1330] = 1; -- Garrote - Silence (rogue)
	[50479] = 1; -- Nether Shock (hunter nether ray)
	[15487] = 1; -- Silence (priest)
	[18498] = 1; -- Silenced - Gag Order (warrior)
	[34490] = 1; -- Silencing Shot (hunter)
	[78675] = 1; -- Solar Beam (druid)
	[97547] = 1; -- Solar Beam (druid)
	[113286] = 1; -- Solar Beam (symbiosis)
	[113287] = 1; -- Solar Beam (symbiosis)
	[113288] = 1; -- Solar Beam (symbiosis)
	[116709] = 1; -- Spear Hand Strike (monk)
	[24259] = 1; -- Spell Lock (warlock felhunter)
	[47476] = 1; -- Strangulate (death knight)
})

------------------------------------------------------------------------
--	Racials
------------------------------------------------------------------------
if (race == "BloodElf") then
	addAuras({
		[50613] = 4; -- Arcane Torrent (death knight)
		[80483] = 4; -- Arcane Torrent (hunter)
		[28730] = 4; -- Arcane Torrent (mage, paladin, priest, warlock)
		[129597] = 4; -- Arcane Torrent (monk)
		[25046] = 4; -- Arcane Torrent (rogue)
		[69179] = 4; -- Arcane Torrent (warrior)
	})
elseif (race == "Draenei") then
	addAuras({
		[59545] = 4; -- Gift of the Naaru (death knight)
		[59543] = 4; -- Gift of the Naaru (hunter)
		[59548] = 4; -- Gift of the Naaru (mage)
		[121093] = 4; -- Gift of the Naaru (monk)
		[59542] = 4; -- Gift of the Naaru (paladin)
		[59544] = 4; -- Gift of the Naaru (priest)
		[59547] = 4; -- Gift of the Naaru (shaman)
		[28880] = 4; -- Gift of the Naaru (warrior)
	})
elseif (race == "Dwarf") then
	addAuras({
		[20594] = 4; -- Stoneform
	})
elseif (race == "NightElf") then
	addAuras({
		[58984] = 4; -- Shadowmeld
	})
elseif (race == "Orc") then
	addAuras({
		[20572] = 4; -- Blood Fury (attack power)
		[33702] = 4; -- Blood Fury (spell power)
		[33697] = 4; -- Blood Fury (attack power and spell damage)
	})
elseif (race == "Pandaren") then
	addAuras({
		[107079] = 4; -- Quaking Palm
	})
elseif (race == "Scourge") then
	addAuras({
		[7744] = 4; -- Will of the Forsaken
	})
elseif (race == "Tauren") then
	addAuras({
		[20549] = 1; -- War Stomp
	})
elseif (race == "Troll") then
	addAuras({
		[26297] = 4; -- Berserking
	})
elseif (race == "Worgen") then
	addAuras({
		[68992] = 4; -- Darkflight
	})
end

------------------------------------------------------------------------
--	Classes
------------------------------------------------------------------------
if (class == "DEATHKNIGHT") then addAuras({
	[48707] = 4; -- Anti-Magic Shell
	[49222] = 4; -- Bone Shield
	[53386] = 4; -- Cinderglacier
	[119975] = 4; -- Conversion
	[101568] = 4; -- Dark Succor <= glyph
	[96268] = 4; -- Death's Advance
	[59052] = 4; -- Freezing Fog <= Rime
	[48792] = 4; -- Icebound Fortitude
	[51124] = 4; -- Killing Machine
	[49039] = 4; -- Lichborne
	[51271] = 4; -- Pillar of Frost
	[46584] = 4; -- Raise Dead
	[108200] = 4; -- Remorseless Winter
	[51460] = 4; -- Runic Corruption
	[50421] = 4; -- Scent of Blood
	[116888] = 4; -- Shroud of Purgatory
	[81340] = 4; -- Sudden Doom
	[115989] = 4; -- Unholy Blight
--	[53365] = 4; -- Unholy Strength <= Rune of the Fallen Crusader
	[55233] = 4; -- Vampiric Blood
	[81162] = 4; -- Will of the Necropolis (damage reduction)
	[96171] = 4; -- Will of the Necropolis (free Rune Tap)

	[108194] = 1; -- Asphyxiate
	[55078] = 2; -- Blood Plague
	[45524] = 1; -- Chains of Ice
--	[50435] = 1; -- Chilblains
	[111673] = 2; -- Control Undead; -- needs check
	[77606] = 2; -- Dark Simulacrum
	[55095] = 2; -- Frost Fever
	[51714] = 2; -- Frost Vulernability <= Rune of Razorice
	[73975] = 1; -- Necrotic Strike
	[115000] = 2; -- Remorseless Winter (slow)
	[115001] = 2; -- Remorseless Winter (stun)
	[114866] = 2; -- Soul Reaper (blood)
	[130735] = 2; -- Soul Reaper (frost)
	[130736] = 2; -- Soul Reaper (unholy)
	[47476] = 1; -- Strangulate
	[115798] = 1; -- Weakened Blows

	[49016] = 3; -- Unholy Frenzy

	[63560] = 2; -- Dark Transformation
}) end 
if (class == "DRUID") then addAuras({
	[88212] = 4; -- Barkskin
	[106952] = 4; -- Berserk
	[112071] = 4; -- Celestial Alignment
	[16870] = 4; -- Clearcasting <= Omen of Clarity
	[1850] = 4; -- Dash
	-- [108381] = 4; -- Dream of Cenarius (+damage) -- removed in 5.4
	-- [108382] = 4; -- Dream of Cenarius (+healing) -- removed in 5.4
	[48518] = 4; -- Eclipse (Lunar)
	[48517] = 4; -- Eclipse (Solar)
	[5229] = 4; -- Enrage
	[124769] = 4; -- Frenzied Regeneration <= glpyh
	[102560] = 4; -- Incarnation: Chosen of Elune
	[102543] = 4; -- Incarnation: King of the Jungle
	[102558] = 4; -- Incarnation: Son of Ursoc
	[33891] = 4; -- Incarnation: Tree of Life
	[81192] = 4; -- Lunar Shower
	[106922] = 4; -- Might of Ursoc
	[16689] = 4; -- Nature's Grasp
	[132158] = 4; -- Nature's Swiftness
	[124974] = 4; -- Nature's Vigil
	[48391] = 4; -- Owlkin Frenzy
	[69369] = 4; -- Predator's Swiftness
	[62606] = 4; -- Savage Defense
	[52610] = 4; -- Savage Roar
	[93400] = 4; -- Shooting Stars
	[114108] = 2; -- Soul of the Forest (resto)
	[61336] = 4; -- Survival Instincts
	[5217] = 4; -- Tiger's Fury
	[102416] = 4; -- Wild Charge (aquatic)

	[33786] = 1; -- Cyclone
	[99] = 1; -- Disorienting Roar
	[339] = 1; -- Entangling Roots
	[114238] = 1; -- Fae Silence <= glpyh
	[770] = 1; -- Faerie Fire
	[102355] = 1; -- Faerie Swarm
	[81281] = 1; -- Fungal Growth <= Wild Mushroom: Detonate
	[2637] = 1; -- Hibernate
	[33745] = 2; -- Lacerate
	[22570] = 1; -- Maim
	[5211] = 1; -- Mighty Bash
	[8921] = 2; -- Moonfire
	[9005] = 2; -- Pounce
	[102546] = 2; -- Pounce
	[9007] = 2; -- Pounce Bleed
	[1822] = 2; -- Rake
	[1079] = 2; -- Rip
	[106839] = 1; -- Skull Bash
	[78675] = 1; -- Solar Beam (silence)
	[97547] = 1; -- Solar Beam (interrupt)
	[93402] = 2; -- Sunfire
	[77758] = 2; -- Thrash (bear)
	[106830] = 2; -- Thrash (cat)
	[61391] = 3; -- Typhoon
	[102793] = 1; -- Ursol's Vortex
	[16979] = 1; -- Wild Charge (bear)
	[45334] = 1; -- Immobilize <= Wild Charge (bear)
	[49376] = 1; -- Wild Charge (cat)
	[50259] = 1; -- Immobilize <= Wild Charge (cat)

	[102352] = 2; -- Cenarion Ward
	[29166] = 3; -- Innervate
	[102342] = 3; -- Ironbark
	[33763] = 2; -- Lifebloom
	[94447] = 2; -- Lifebloom (tree)
	[8936] = 2; -- Regrowth
	[744] = 2; -- Rejuvenation
	[77761] = 3; -- Stampeding Roar (bear)
	[77764] = 3; -- Stampeding Roar (cat)
	[106898] = 3; -- Stampeding Roar
	[48438] = 2; -- Wild Growth
}) end 
if (class == "HUNTER") then addAuras({
	[83559] = 4; -- Black Ice
--	[82921] = 4; -- Bombardment
--	[53257] = 4; -- Cobra Strikes
	[51755] = 4; -- Camouflage
	[19263] = 4; -- Deterrence
	[15571] = 4; -- Dazed <== Aspect of the Cheetah
	[6197] = 4; -- Eagle Eye
	[5384] = 4; -- Feign Death
	[82726] = 4; -- Fervor
	[82926] = 4; -- Fire! <= Master Marksman
	[82692] = 4; -- Focus Fire
	[56453] = 4; -- Lock and Load
	[62305] = 4; -- Master's Call
	[64216] = 4; -- Master's Call
	[34477] = 4; -- Misdirection
	[118922] = 4; -- Posthaste
	[3045] = 4; -- Rapid Fire
--	[82925] = 4; -- Ready, Set, Aim... <= Master Marksman
	[53220] = 4; -- Steady Focus
	[34471] = 4; -- The Beast Within
	[34720] = 4; -- Thrill of the Hunt

	[131894] = 2; -- A Murder of Crows
	[117526] = 2; -- Binding Shot (stun)
	[117405] = 2; -- Binding Shot (tether)
	[3674] = 2; -- Black Arrow
	[35101] = 2; -- Concussive Barrage
	[5116] = 2; -- Concussive Shot
	[20736] = 2; -- Distracting Shot
	[64803] = 2; -- Entrapment
	[53301] = 2; -- Explosive Shot
	[13812] = 2; -- Explosive Trap
	[43446] = 2; -- Explosive Trap Effect
	[128961] = 2; -- Explosive Trap Effect
	[3355] = 2; -- Freezing Trap
	[43448] = 2; -- Freezing Trap
	[61394] = 2; -- Frozen Wake <= Glyph of Freezing Trap
	[120761] = 2; -- Glaive Toss
	[121414] = 2; -- Glaive Toss
	[1130] = 1; -- Hunter's Mark
	-- [67035] = 2; -- Ice Trap
	-- [110610] = 2; -- Ice Trap
	[13809] = 2; -- Ice Trap
	[34394] = 2; -- Intimidation
	[115928] = 2; -- Narrow Escape
	[128405] = 2; -- Narrow Escape
--	[63468] = 2; -- Piercing Shots
	[1513] = 2; -- Scare Beast
	[19503] = 2; -- Scatter Shot
	[1978] = 2; -- Serpent Sting
	[34490] = 2; -- Silencing Shot
	[82654] = 2; -- Widow Venom
	[19386] = 2; -- Wyvern Sting

	[19615] = 3; -- Frenzy
--	[118455] = 3; -- Beast Cleave
	[19574] = 3; -- Bestial Wrath
	[136] = 3; -- Mend end Pet
	[35079] = 3; -- Misdirection
	[110588] = 3; -- Misdirection
	[110591] = 3; -- Misdirection
}) end
if (class == "MAGE") then 
addAuras({
	[110909] = 4; -- Alter Time
	[36032] = 4; -- Arcane Charge
	[12042] = 4; -- Arcane Power
	[108843] = 4; -- Blazing Speed
	[57761] = 4; -- Brain Freeze
	[87023] = 4; -- Cauterize
	[44544] = 4; -- Fingers of Frost
	[110960] = 4; -- Greater Invisibility
	[48107] = 4; -- Heating Up
	[11426] = 4; -- Ice Barrier
	[45438] = 4; -- Ice Block
	[108839] = 4; -- Ice Floes
	[12472] = 4; -- Icy Veins
	[1463] = 4; -- Incanter's Ward
	[66] = 4; -- Invisibility
	[12043] = 4; -- Presence of Mind
	[116014] = 4; -- Rune of Power
	[115610] = 4; -- Temporal Shield (shield)
	[115611] = 4; -- Temporal Shield (heal)

	[34356] = 2; -- Blizzard (slow)
	[83853] = 2; -- Combustion
	[120] = 2; -- Cone of Cold
	[44572] = 2; -- Deep Freeze
	[31661] = 2; -- Dragon's Breath
	[112948] = 2; -- Frost Bomb
	[113092] = 2; -- Frost Bomb (slow)
	[122] = 2; -- Frost Nova
	[116] = 2; -- Frostbolt
	[44614] = 2; -- Frostfire Bolt
	[102051] = 2; -- Frostjaw
	[84721] = 2; -- Frozen Orb
	[12846] = 2; -- Mastery: Ignite
	[12654] = 2; -- Ignite
	[44457] = 2; -- Living Bomb
	[114923] = 2; -- Nether Tempest
	[118] = 2; -- Polymorph
	[61305] = 2; -- Polymorph (Black Cat)
	[28272] = 2; -- Polymorph (Pig)
	[61721] = 2; -- Polymorph (Rabbit)
	[61780] = 2; -- Polymorph (Turkey)
	[28271] = 2; -- Polymorph (Turtle)
	[11366] = 2; -- Pyroblast
	[132210] = 2; -- Pyromaniac
	[82691] = 2; -- Ring of Frost
	[55021] = 2; -- Silenced - Improved Counterspell
	[31589] = 2; -- Slow
}) end 
if (class == "MONK") then addAuras({
	[126050] = 4; -- Adaptation
	[122278] = 4; -- Dampen Harm
	[122465] = 4; -- Dematerialize
	[122783] = 4; -- Diffuse Magic
	[128939] = 4; -- Elusive Brew (stack)
	[115308] = 4; -- Elusive Brew (consume)
	[115288] = 4; -- Energizing Brew
	[115203] = 4; -- Fortifying Brew
	[115295] = 4; -- Guard
	[124458] = 4; -- Healing Sphere (count)
	[115867] = 4; -- Mana Tea (stack)
	[119085] = 4; -- Momentum
	[124968] = 4; -- Retreat
	[127722] = 4; -- Serpent's Zeal
	[115307] = 4; -- Shuffle
	[124275] = 4; -- Light Stagger
	[124274] = 4; -- Moderate Stagger
	[124273] = 4; -- Heavy Stagger
	[125359] = 4; -- Tiger Power
	[120273] = 4; -- Tiger Strikes
	[116841] = 4; -- Tiger's Lust
	[125195] = 4; -- Tigereye Brew (stack)
	[116740] = 4; -- Tigereye Brew (consume)
	[122470] = 4; -- Touch of Karma
	[118674] = 4; -- Vital Mists

	[128531] = 2; -- Blackout Kick
	[123393] = 2; -- Breath of Fire (disorient)
	[123725] = 2; -- Breath of Fire (dot)
	[119392] = 2; -- Charging Ox Wave
	[122242] = 2; -- Clash (stun)
	[126451] = 2; -- Clash (stun)
	[128846] = 2; -- Clash (stun)
	[125647] = 2; -- Crackling Jade Lightning (+damage)
	[116095] = 2; -- Disable
	[116330] = 2; -- Dizzying Haze
	[123727] = 2; -- Dizzying Haze
	[123586] = 4; -- Flying Serpent Kick
	[117368] = 2; -- Grapple Weapon
	[118585] = 2; -- Leer of the Ox
	[119381] = 2; -- Leg Sweep
	[115078] = 2; -- Paralysis
	[118635] = 2; -- Provoke
	[116189] = 2; -- Provoke
	[130320] = 2; -- Rising Sun Kick
	[116847] = 2; -- Rushing Jade Wind
	[116709] = 2; -- Spear Hand Strike
	[123407] = 2; -- Spinning Fire Blossom

	[124682] = 2; -- Enveloping Mist
	[116849] = 3; -- Life Cocoon
	[119611] = 2; -- Renewing Mist
	[115175] = 2; -- Soothing Mist
	[124081] = 2; -- Zen Sphere
}) end 
if (class == "PALADIN") then addAuras({
	[121467] = 4; -- Alabaster Shield
	[31850] = 4; -- Ardent Def}) ender
	[31884] = 4; -- Avenging Wrath
	[114637] = 4; -- Bastion of Glory
	[88819] = 4; -- Daybreak
	[31842] = 4; -- Divine Favor
	[54428] = 4; -- Divine Plea
	[498] = 4; -- Divine Protection
	[90174] = 4; -- Divine Purpose
	[642] = 4; -- Divine Shield
	[54957] = 4; -- Glyph of Flash of Light
	[85416] = 4; -- Grand Crusader
	[86659] = 4; -- Guardian of Ancient Kings (protection)
	[86669] = 4; -- Guardian of Ancient Kings (holy)
	[86698] = 4; -- Guardian of Ancient Kings (retribution)
	[105809] = 4; -- Holy Avenger
	[54149] = 4; -- Infusion of Light
	[84963] = 4; -- Inquisition
	[114250] = 4; -- Selfless Healer
--	[132403] = 4; -- Shield of the Righteous
	[85499] = 4; -- Speed of Light
	[94686] = 4; -- Supplication

	[31935] = 2; -- Avenger's Shield
--	[110300] = 2; -- Burden of Guilt
	[105421] = 2; -- Blinding Light
	[31803] = 2; -- Censure
	[63529] = 2; -- Dazed - Avenger's Shield
	[2812] = 2; -- Denounce
	[114916] = 2; -- Execution Sentence
	[105593] = 2; -- Fist of Justice
	[853] = 2; -- Hammer of Justice
	[119072] = 2; -- Holy Wrath
	[20066] = 2; -- Repentance
	[10326] = 2; -- Turn Evil

	[31821] = 3; -- Devotion Aura
	[114163] = 3; -- Eternal Flame
	[1044] = 3; -- Hand of Freedom
	[1022] = 3; -- Hand of Protection
	[114039] = 3; -- Hand of Purity
	[6940] = 3; -- Hand of Sacrifice
	[1038] = 3; -- Hand of Salvation
	[86273] = 3; -- Illuminated Healing
	[20925] = 3; -- Sacred Shield
	[20170] = 3; -- Seal of Justice
	[114917] = 3; -- Stay of Execution
}) end 
if (class == "PRIEST") then addAuras({
	[108945] = 4; -- Angelic Bulwark
	[81700] = 4; -- Archangel
	[52798] = 4; -- Borrowed Time
	[47585] = 4; -- Dispersion
	[123266] = 4; -- Divine Insight (discipline)
	[123267] = 4; -- Divine Insight (holy)
	[124430] = 4; -- Divine Insight (shadow)
	[81661] = 4; -- Evangelism
	[586] = 4; -- Fade
	[2096] = 4; -- Mind Vision
	[114239] = 4; -- Phantasm
	[10060] = 4; -- Power Infusion
	[63735] = 4; -- Ser}) endipity
	[112833] = 4; -- Spectral Guise
	[109964] = 4; -- Spirit Shell
	[87160] = 4; -- Surge of Darkness
	[126083] = 4; -- Surge of Darkness
	[128654] = 4; -- Surge of Light
	[114255] = 4; -- Surge of Light
	[123254] = 4; -- Twist of Fate
	[15286] = 4; -- Vampiric Embrace
	[108920] = 4; -- Void T}) endrils

	[124467] = 2; -- Devouring Plague
	[14914] = 2; -- Holy Fire
	[88625] = 2; -- Holy Word: Chastise
	[89485] = 2; -- Inner Focus
	[64044] = 2; -- Psychic Horror (horror)
	[64058] = 2; -- Psychic Horror (disarm)
	[8122] = 2; -- Psychic Scream
	[113792] = 2; -- Psychic Terror
	[9484] = 2; -- Shackle Undead
	[589] = 2; -- Shadow Word: Pain
	[124464] = 2; -- Shadow Word: Pain
	[15487] = 2; -- Silence
	[34914] = 2; -- Vampiric Touch
	[124465] = 2; -- Vampiric Touch

	[77613] = 3; -- Grace
	[47788] = 3; -- Guardian Spirit
	[88684] = 3; -- Holy Word: Serenity
	[33206] = 3; -- Pain Suppression
	[62618] = 3; -- Power Word: Barrier
	[17] = 3; -- Power Word: Shield
	[139] = 3; -- Renew
}) end 
if (class == "ROGUE") then addAuras({
	[113746] = 1; -- Weakened Armor

	[13750] = 4; -- Adrenaline Rush
	[115189] = 4; -- Anticipation
	[18377] = 4; -- Blade Flurry
	[121153] = 4; -- Blindside
	[108212] = 4; -- Burst of Speed
	[31224] = 4; -- Cloak of Shadows
	[74002] = 4; -- Combat Insight
	[74001] = 4; -- Combat Readiness
	[84747] = 4; -- Deep Insight
	[56814] = 4; -- Detection
	[32645] = 4; -- Envenom
	[5277] = 4; -- Evasion
	[1966] = 4; -- Feint
	[51690] = 4; -- Killing Spree
	[84746] = 4; -- Moderate Insight
	[73651] = 4; -- Recuperate
	[121471] = 4; -- Shadow Blades
	[51713] = 4; -- Shadow Dance
	[114842] = 4; -- Shadow Walk
	[36554] = 4; -- Shadowstep
	[84745] = 4; -- Shallow Insight
	[114018] = 4; -- Shroud of Concealment
	[5171] = 4; -- Slice and Dice
	[76577] = 4; -- Smoke Bomb
	[2983] = 4; -- Sprint
	[57934] = 4; -- Tricks of the Trade
	[1856] = 4; -- Vanish

	[2094] = 2; -- Blind
	[1833] = 2; -- Cheap Shot
	[121411] = 2; -- Crimson Tempest
	[26679] = 2; -- Deadly Throw
	[51722] = 2; -- Dismantle
	[91021] = 2; -- Find Weakness
	[703] = 2; -- Garrote
	[1330] = 2; -- Garrote - Silence
	[1776] = 2; -- Gouge
	[16511] = 2; -- Hemorrhage
	[408] = 2; -- Kidney Shot
	[112947] = 2; -- Nerve Strike
	[84617] = 2; -- Revealing Strike
	[1943] = 2; -- Rupture
	[6770] = 2; -- Sap
	[57933] = 2; -- Tricks of the Trade
	[79140] = 2; -- Vendetta

	[3409] = 2; -- Crippling Poison
	[2818] = 2; -- Deadly Poison
	[5760] = 2; -- Mind-numbing Poison
	[8680] = 2; -- Wound Poison
	[112961] = 2; -- Leeching Poison
	[113952] = 2; -- Paralytic Poison
}) end 
if (class == "SHAMAN") then addAuras({
	[108281] = 4; -- Ancestral Guidance
	[16188] = 4; -- Ancestral Swiftness
	[114050] = 4; -- Ascendance (elemental)
	[114051] = 4; -- Ascendance (enhancement)
	[114052] = 4; -- Ascendance (restoration)
	[108271] = 4; -- Astral Shift
	[118522] = 4; -- Elemental Blast
	[16166] = 4; -- Elemental Mastery
	[6196] = 4; -- Far Sight
	[77762] = 4; -- Lava Surge
	[31616] = 4; -- Nature's Guardian
	[77661] = 4; -- Searing Flames
	[30823] = 4; -- Shamanistic Rage
	[58876] = 4; -- Spirit Walk
	[79206] = 4; -- Spiritwalker's Grace
	[53390] = 4; -- Tidal Waves
	[73683] = 4; -- Unleash Flame
	[73681] = 4; -- Unleash Wind
	[118474] = 4; -- Unleashed Fury (frostbrand)
	[118475] = 4; -- Unleashed Fury (rockbiter)
	[118472] = 4; -- Unleashed Fury (windfury)

	[76780] = 1; -- Bind Elemental
	[3600] = 1; -- Earthbind <= Earthbind Totem
	[64695] = 1; -- Earthgrab <= Earthgrab Totem
	[61882] = 2; -- Earthquake
	[8050] = 2; -- Flame Shock
	[8056] = 1; -- Frost Shock
	[8034] = 2; -- Frostbrand Attack <= Frostbrand Weapon
	[63685] = 1; -- Freeze <= Frozen Power
	[51514] = 1; -- Hex
	[8178] = 1; -- Grounding Totem Effect
	[89523] = 1; -- Grounding Totem (reflect)
	[118905] = 1; -- Static Charge <= Capacitor Totem
	[115356] = 2; -- Stormblast
	[120676] = 1; -- Stormlash Totem
	[17364] = 2; -- Stormstrike
	[51490] = 1; -- Thunderstorm
	[73684] = 2; -- Unleash Earth
	[73682] = 2; -- Unleash Frost
	[117012] = 2; -- Unleashed Fury (flametongue)

	[2825] = 3; -- Bloodlust (shaman)
	[32182] = 3; -- Heroism (shaman)
	[974] = 2; -- Earth Shield
	[119523] = 3; -- Healing Stream Totem (resistance)
	[16191] = 3; -- Mana Tide
	[61295] = 2; -- Riptide
	[98007] = 3; -- Spirit Link Totem
	[114893] = 3; -- Stone Bulwark
	[73685] = 4; -- Unleash Life
	[118473] = 2; -- Unleashed Fury (earthliving)
	[114896] = 3; -- Windwalk Totem
}) end 
if (class == "WARLOCK") then addAuras({
	[116198] = 2; -- Aura of Enfeeblement
	[119652] = 2; -- Aura of Enfeeblement
	[116202] = 2; -- Aura of the Elements
	[117828] = 4; -- Backdraft
	[111400] = 4; -- Burning Rush
	[114168] = 4; -- Dark Apotheosis
	[110913] = 4; -- Dark Bargain (absorb)
	[110914] = 4; -- Dark Bargain (dot)
	[108359] = 4; -- Dark Regeneration
	[113858] = 4; -- Dark Soul: Instability
	[113861] = 4; -- Dark Soul: Knowledge
	[113860] = 4; -- Dark Soul: Misery
	[88448] = 4; -- Demonic Rebirth
	[126] = 4; -- Eye of Kilrogg
	[108683] = 4; -- Fire and Brimstone
	[80240] = 4; -- Havoc
	[137587] = 4; -- Kil'jaeden's Cunning
	[126090] = 4; -- Molten Core
	[122355] = 4; -- Molten Core
	[86211] = 4; -- Soul Swap

	[131737] = 2; -- Agony
	[108505] = 2; -- Archimonde's Vengeance
	[710] = 2; -- Banish
	[111397] = 2; -- Blood Fear
	[124915] = 2; -- Chaos Wave
	[129347] = 2; -- Chaos Wave
	[17962] = 2; -- Conflagrate (slow)
	[172] = 2; -- Corruption
	[131740] = 2; -- Corruption
	[109466] = 2; -- Curse of Enfeeblement
	[18223] = 2; -- Curse of Exhaustion
	[1490] = 1; -- Curse of the Elements
	[603] = 2; -- Doom
	[5782] = 2; -- Fear
	[48181] = 2; -- Haunt
	[5484] = 2; -- Howl of Terror
	[348] = 2; -- Immolate
	[103103] = 2; -- Malefic Grasp
	[6789] = 2; -- Mortal Coil
	[60947] = 2; -- Nightmare
	[108416] = 2; -- Sacrificial Pact
	[123566] = 2; -- Seed of Corruption
	[47960] = 2; -- Shadowflame
	[30283] = 2; -- Shadowfury
	[104773] = 2; -- Un}) ending Resolve
	[131736] = 2; -- Unstable Affliction
}) end 
if (class == "WARRIOR") then addAuras({
	[107574] = 4; -- Avatar
	[18499] = 4; -- Berserker Rage
	[46924] = 4; -- Bladestorm
	[12292] = 4; -- Bloodbath
	[46916] = 4; -- Bloodsurge
	[85730] = 4; -- Deadly Calm
	[125565] = 4; -- Demoralizing Shout
	[118038] = 4; -- Die by the Sword
	[12880] = 4; -- Enrage
	[55964] = 4; -- Enraged Regeneration
	[115945] = 4; -- Glyph of Hamstring
	[12975] = 4; -- Last Stand
	[114028] = 4; -- Mass Spell Reflection
	[114192] = 4; -- Mocking Banner
	[97463] = 4; -- Rallying Cry
	[1719] = 4; -- Recklessness
	[112048] = 4; -- Shield Barrier
	[2565] = 4; -- Shield Block
	[871] = 4; -- Shield Wall
	[114206] = 4; -- Skull Banner
	[23920] = 4; -- Spell Banner
	[52437] = 4; -- Sudden Death
	[12328] = 4; -- Sweeping Strikes
	[50227] = 4; -- Sword and Board
	[125831] = 4; -- Taste for Blood
	[122510] = 4; -- Ultimatum

	[86346] = 2; -- Colossus Smash
	[114205] = 2; -- Demoralizing Banner
	[1160] = 2; -- Demoralizing Shout
	[676] = 2; -- Disarm
	[118895] = 2; -- Dragon Roar
	[1715] = 2; -- Hamstring
	[5246] = 2; -- Intimidating Shout
	[20511] = 2; -- Intimidating Shout
	[12323] = 2; -- Piercing Howl
	[64382] = 2; -- Shattering Throw
	[46968] = 2; -- Shockwave
	[18498] = 2; -- Silenced - Gag Order
	[107566] = 2; -- Staggering Shout
	[107570] = 2; -- Storm Bolt
	[355] = 2; -- Taunt
	[105771] = 2; -- Warbringer

	[46947] = 3; -- Safeguard (damage reduction)
	[114029] = 3; -- Safeguard (intercept)
	[114030] = 3; -- Vigilance
}) end

------------------------------------------------------------------------
--	Pets
------------------------------------------------------------------------
addPetAuras({
	-- Warlock Demons
	-- [6307] = true; -- Blood Pact
	[115236] = true; -- Void Shield
	[17767] = true; -- Shadow Bulwark
	[115831] = true; -- Wrathstorm

	-- Death Knight Ghouls
	[63560] = true; -- Dark Transformation
	[49572] = true; -- Shadow Infusion 
	
	-- Hunter Pets
	[6991] = true; -- Feed Pet
	[19623] = true; -- Frenzy Effect
	[136] = true; -- Mend Pet
})

------------------------------------------------------------------------
--	Raid Debuffs
------------------------------------------------------------------------
R.RaidDebuffs = {
	--------------------------------------------------------------------------------------------------
	--		Misc
	--------------------------------------------------------------------------------------------------
	-- for testing purposes only
	[11196] = 5; 	-- Recently Bandaged

	-----------------------------------------------------------------
	-- Mogu'shan Vaults
	-----------------------------------------------------------------
	-- The Stone Guard
	[116281] = 5;	-- Cobalt Mine Blast
	
	-- Feng the Accursed
	[116784] = 5;	-- Wildfire Spark
	[116417] = 5;	-- Arcane Resonance
	[116942] = 5;	-- Flaming Spear
	
	-- Gara'jal the Spiritbinder
	[116161] = 5;	-- Crossed Over
	[122151] = 5;	-- Voodoo Dolls
	
	-- The Spirit Kings
	[117708] = 5;	-- Maddening Shout
	[118303] = 5;	-- Fixate
	[118048] = 5;	-- Pillaged
	[118135] = 5;	-- Pinned Down
	
	-- Elegon
	[117878] = 5;	-- Overcharged
	[117949] = 5;	-- Closed Circuit
	
	-- Will of the Emperor
	[116835] = 5;	-- Devastating Arc
	[116778] = 5;	-- Focused Defense
	[116525] = 5;	-- Focused Assault
	
	-----------------------------------------------------------------
	-- Heart of Fear
	-----------------------------------------------------------------
	-- Imperial Vizier Zor'lok
	[122761] = 5;	-- Exhale
	[122760] = 5; 	-- Exhale
	[122740] = 5;	-- Convert
	[123812] = 5;	-- Pheromones of Zeal
	
	-- Blade Lord Ta'yak
	[123180] = 5;	-- Wind Step
	[123474] = 5;	-- Overwhelming Assault
	
	-- Garalon
	[122835] = 5;	-- Pheromones
	[123081] = 5;	-- Pungency
	
	-- Wind Lord Mel'jarak
	[122125] = 5;	-- Corrosive Resin Pool
	[121885] = 5; 	-- Amber Prison
	
	-- Amber-Shaper Un'sok
	[121949] = 5;	-- Parasitic Growth
	-- Grand Empress Shek'zeer
	
	-----------------------------------------------------------------
	-- Terrace of Endless Spring
	-----------------------------------------------------------------
	-- Protectors of the Endless
	[117436] = 5;	-- Lightning Prison
	[118091] = 5;	-- Defiled Ground
	[117519] = 5;	-- Touch of Sha

	-- Tsulong
	[122752] = 5;	-- Shadow Breath
	[123011] = 5;	-- Terrorize
	[116161] = 5;	-- Crossed Over
	
	-- Lei Shi
	[123121] = 5;	-- Spray
	
	-- Sha of Fear
	[119985] = 5;	-- Dread Spray
	[119086] = 5;	-- Penetrating Bolt
	[119775] = 5;	-- Reaching Attack
}

F.CustomAuraFilter = function(self, ...)
	local unit, icon, name, rank, texture, count, debuffType, duration, expirationTime, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = ...
	
	-- always show boss debuffs
	-- show selected player debuffs only
	if (unit == "player") then
		local db = unitframes:GetCurrentOptionsSet()
		if (db.usePlayerAuraFilter) and (InCombatLockdown()) then
			local show = R.AuraList[name]
			if ((show) and (auraFilter[show])) or (isBossDebuff) then
				return (isBossDebuff) or auraFilter[show](self, unit, caster)
			end
		else
			return true
		end 
		
	-- always show all out of combat
	-- always show boss debuffs
	-- if filter is active, show filtered results in combat
	elseif (unit == "target") then
		local db = unitframes:GetCurrentOptionsSet()
		if (db.useTargetAuraFilter) and (InCombatLockdown()) then
			local show = R.AuraList[name]
			if ((show) and (auraFilter[show])) or (isBossDebuff) then
				return (isBossDebuff) or auraFilter[show](self, unit, caster)
			end
		else
			return true
		end
	
	-- always show boss debuffs
	-- only show selected buffs
	elseif (unit:find("pet")) then
		if ((name) and (R.PetAuraList[name])) or (isBossDebuff) then
			return true
		end
	else
		return true
	end
end
