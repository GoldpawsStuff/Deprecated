--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...
local cargBags = cargBags or ns.cargBags

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:GetModule("Bags")
local Sorting = module:GetDataBase("Sorting")

Sorting[22743] = "armor" -- Bloodsail Sash

-- Sorting[30688] = "keys" -- Deathforge Key
-- Sorting[18250] = "keys" -- Gordok Shackle Key
-- Sorting[45798] = "keys" -- Heroic Celestial Planetarium Key

-- keys (from 5.4.2 and beyond)
-- Sorting[94222] = "keys" -- Key to the Palace of Lei Shen

-- tradeskill tools
Sorting[6219] = "misc" -- Arclight Spanner
Sorting[5956] = "misc" -- Blacksmith Hammer
Sorting[71634] = "misc" -- Darkmoon Adventurer's Guide
Sorting[20815] = "misc" -- Jeweler's Kit
Sorting[2901] = "misc" -- Mining Pick
Sorting[22462] = "misc" -- Runed Adamantite Rod
Sorting[16207] = "misc" -- Runed Arcanite Rod
Sorting[52723] = "misc" -- Runed Elementium Rod
Sorting[22463] = "misc" -- Runed Eternium Rod
Sorting[22461] = "misc" -- Runed Fel Iron Rod
Sorting[11130] = "misc" -- Runed Golden Rod
Sorting[6339] = "misc" -- Runed Silver Rod
Sorting[44452] = "misc" -- Runed Titanium Rod
Sorting[11145] = "misc" -- Runed Truesilver Rod
Sorting[20824] = "misc" -- Simple Grinder
Sorting[7005] = "misc" -- Skinning Knife
Sorting[39505] = "misc" -- Virtuoso Inking Set
	
-- teleports
Sorting[32757] = "misc" -- Blessed Medallion of Karabor
Sorting[65360] = "misc" -- Cloak of Coordination (Alliance)
Sorting[65274] = "misc" -- Cloak of Coordination (Horde)
Sorting[30542] = "misc" -- Dimensional Ripper - Area 52
Sorting[18984] = "misc" -- Dimensional Ripper - Everlook
Sorting[37863] = "misc" -- Direbrew's Remote
Sorting[48955] = "misc" -- Etched Loop of the Kirin Tor
Sorting[17690] = "misc" -- Frostwolf Insignia Rank 1
Sorting[17905] = "misc" -- Frostwolf Insignia Rank 2
Sorting[17906] = "misc" -- Frostwolf Insignia Rank 3
Sorting[17907] = "misc" -- Frostwolf Insignia Rank 4
Sorting[17908] = "misc" -- Frostwolf Insignia Rank 5
Sorting[17909] = "misc" -- Frostwolf Insignia Rank 6
Sorting[6948] = "misc" -- Hearthstone
Sorting[45689] = "misc" -- Inscribed Loop of the Kirin Tor
Sorting[52251] = "misc" -- Jaina's Locket
Sorting[44934] = "misc" -- Loop of the Kirin Tor
Sorting[51558] = "misc" -- Runed Loop of the Kirin Tor
Sorting[63352] = "misc" -- Shroud of Cooperation (Alliance)
Sorting[63353] = "misc" -- Shroud of Cooperation (Horde)
Sorting[17691] = "misc" -- Stormpike Insignia Rank 1
Sorting[17900] = "misc" -- Stormpike Insignia Rank 2
Sorting[17901] = "misc" -- Stormpike Insignia Rank 3
Sorting[17902] = "misc" -- Stormpike Insignia Rank 4
Sorting[17903] = "misc" -- Stormpike Insignia Rank 5
Sorting[17904] = "misc" -- Stormpike Insignia Rank 6
Sorting[64488] = "misc" -- The Innkeeper's Daughter
Sorting[64457] = "misc" -- The Last Relic of Argus
Sorting[18986] = "misc" -- Ultrasafe Transporter: Gadgetzan
Sorting[30544] = "misc" -- Ultrasafe Transporter: Toshley's Station
Sorting[48933] = "misc" -- Wormhole Generator: Northrend
Sorting[87215] = "misc" -- Wormhole Generator: Pandaria
Sorting[63206] = "misc" -- Wrap of Unity (Alliance)
Sorting[63207] = "misc" -- Wrap of Unity (Horde)

-- trade goods
Sorting[32897] = "trade" -- Mark of the Illidari

-- quests
Sorting[71716] = "quest" -- Soothsayer's Runes
Sorting[28607] = "quest" -- Sunfury Disguise
Sorting[104267] = "quest" -- Thick Tiger Haunch


-- 'Gizmos' are items with a /use effect that differs from the standard
-- "increase damage" or "increase dodge" of normal trinkets.
-- 		* If you think you know of an item that belongs here, 
--			feel free to email the english name and/or itemID to goldpaw@friendlydruid.com
--			You can retrieve the itemID by typing "/itemid" in-game, followed by either
--			the item name or the item link retrieved by shift-clicking the item with the chat input open
-- 		* as a general rule I only put items that are re-usable here, 
-- 			not items that have charges and are consumed 
Sorting[69776] = "gizmos" -- Ancient Amber
Sorting[85500] = "gizmos" -- Anglers Fishing Raft
Sorting[31666] = "gizmos" -- Battered Steam Tonk Controller
Sorting[86565] = "gizmos" -- Battle Horn
Sorting[90067] = "gizmos" -- B. F. F. Necklace
Sorting[54343] = "gizmos" -- Blue Crashin' Thrashin' Racer Controller
Sorting[49917] = "gizmos" -- Brazie's Gnomish Pleasure Device
Sorting[34686] = "gizmos" -- Brazier of Dancing Flames
Sorting[33927] = "gizmos" -- Brewfest Pony Keg
Sorting[71137] = "gizmos" -- Brewfest Keg Pony
Sorting[88384] = "gizmos" -- Burlap Ritual Bag
Sorting[49704] = "gizmos" -- Carved Ogre Idol
Sorting[64373] = "gizmos" -- Chalice of the Mountain Kings
Sorting[86425] = "gizmos" -- Cooking School Bell
Sorting[37710] = "gizmos" -- Crashin' Thrashin' Racer Controller
Sorting[23767] = "gizmos" -- Crashin' Thrashin' Robot
Sorting[104038] = "gizmos" -- Curse Swabby Helmet
Sorting[38301] = "gizmos" -- D.I.S.C.O.
Sorting[77158] = "gizmos" -- Darkmoon "Tiger"
Sorting[36863] = "gizmos" -- Decahedral Dwarven Dice
Sorting[89880] = "gizmos" -- Dented Shovel
Sorting[21745] = "gizmos" -- Elder's Moonstone
Sorting[21540] = "gizmos" -- Elune's Lantern
Sorting[13508] = "gizmos" -- Eye of Arachnida
Sorting[75040] = "gizmos" -- Flimsy Darkmoon Balloon
Sorting[18232] = "gizmos" -- Field Repair Bot 74A
Sorting[34113] = "gizmos" -- Field Repair Bot 110G
Sorting[33223] = "gizmos" -- Fishing Chair
Sorting[54651] = "gizmos" -- Gnomeregan Pride
Sorting[40772] = "gizmos" -- Gnomish Army Knife
Sorting[18645] = "gizmos" -- Gnomish Alarm-o-Bot
Sorting[18587] = "gizmos" -- Goblin Jumper Cables XL
Sorting[18258] = "gizmos" -- Gordok Ogre Suit
Sorting[44481] = "gizmos" -- Grindgear Toy Gorilla
Sorting[70725] = "gizmos" -- Hallowed Hunter Wand - Squashling
Sorting[86584] = "gizmos" -- Hardened Shell
Sorting[40110] = "gizmos" -- Haunted Memento
Sorting[69777] = "gizmos" -- Haunted War Drum
Sorting[44601] = "gizmos" -- Heavy Copper Racer
Sorting[45631] = "gizmos" -- High-powered Flashlight
Sorting[88385] = "gizmos" -- Hozen Idol
Sorting[49040] = "gizmos" -- Jeeves
Sorting[88579] = "gizmos" -- Jin Warmkeg's Brew
Sorting[88531] = "gizmos" -- Lao Chin's Last Mug 
Sorting[70722] = "gizmos" -- Little Wickerman
Sorting[60854] = "gizmos" -- Loot-A-Rang
Sorting[88580] = "gizmos" -- Ken-Ken's Mask
Sorting[89815] = "gizmos" -- Master Plow
Sorting[46709] = "gizmos" -- MiniZep Controller
Sorting[40768] = "gizmos" -- MOLL-E
Sorting[52201] = "gizmos" -- Muradin's Favor
Sorting[70161] = "gizmos" -- Mushroom Chair
Sorting[70159] = "gizmos" -- Mylune's Call
Sorting[89869] = "gizmos" -- Pandaren Scarecrow
Sorting[34499] = "gizmos" -- Paper Flying Machine Kit
Sorting[49703] = "gizmos" -- Perpetual Purple Firework
Sorting[32566] = "gizmos" -- Picnic Basket
Sorting[88370] = "gizmos" -- Puntable Marmot
Sorting[46725] = "gizmos" -- Red Rider Air Rifle
Sorting[34480] = "gizmos" -- Romantic Picnic Basket
Sorting[79104] = "gizmos" -- Rusty Watering Can
Sorting[82467] = "gizmos" -- Ruther's Harness
Sorting[45047] = "gizmos" -- Sandbox Tiger
Sorting[40769] = "gizmos" -- Scrapbot Construction Kit
Sorting[88387] = "gizmos" -- Shushen's Spittoon
Sorting[88381] = "gizmos" -- Silversage Incense
Sorting[52253] = "gizmos" -- Sylvanas' Music Box
Sorting[38578] = "gizmos" -- The Flag of Ownership
Sorting[80822] = "gizmos" -- The Golden Banana
Sorting[44817] = "gizmos" -- The Mischief Maker
Sorting[43824] = "gizmos" -- The Schools of Arcane Magic - Mastery
Sorting[54438] = "gizmos" -- Tiny Blue Ragdoll
Sorting[44849] = "gizmos" -- Tiny Green Ragdoll (old, but still existing duplicate version)
Sorting[54439] = "gizmos" -- Tiny Green Ragdoll (Winter Veil drop, purchasable vendor item)
Sorting[54437] = "gizmos" -- Tiny Green Ragdoll (seriously... what the Hell? How many are there?)
Sorting[44430] = "gizmos" -- Titanium Seal of Dalaran
Sorting[63141] = "gizmos" -- Tol Barad Searchlight (Alliance)
Sorting[64997] = "gizmos" -- Tol Barad Searchlight (Horde)
Sorting[88584] = "gizmos" -- Totem of Harmony
Sorting[44606] = "gizmos" -- Toy Train Set
Sorting[44482] = "gizmos" -- Trusty Copper Racer
Sorting[88377] = "gizmos" -- Turnip Paint 'Gun'
Sorting[88375] = "gizmos" -- Turnip Punching Bag
Sorting[45984] = "gizmos" -- Unusual Compass
Sorting[80513] = "gizmos" -- Vintage Bug Sprayer
Sorting[34068] = "gizmos" -- Weighted Jack-o'-Lantern
Sorting[45057] = "gizmos" -- Wind-Up Train Wrecker
Sorting[17712] = "gizmos" -- Winter Veil Disguise Kit
Sorting[18660] = "gizmos" -- World Enlarger
Sorting[36862] = "gizmos" -- Worn Troll Dice
Sorting[23821] = "gizmos" -- Zapthrottle Mote Extractor
Sorting[44599] = "gizmos" -- Zippy Copper Racer

-- banners & standards
Sorting[18606] = "gizmos" -- Alliance Battle Standard
Sorting[63359] = "gizmos" -- Banner of Cooperation (Alliance)
Sorting[64400] = "gizmos" -- Banner of Cooperation (Horde)
Sorting[64399] = "gizmos" -- Battle Standard of Coordination (Alliance)
Sorting[64402] = "gizmos" -- Battle Standard of Coordination (Horde)
Sorting[63377] = "gizmos" -- Baradin's Wardens Battle Standard
Sorting[18607] = "gizmos" -- Horde Battle Standard
Sorting[64398] = "gizmos" -- Standard of Unity (Alliance)
Sorting[64401] = "gizmos" -- Standard of Unity (Horde)
Sorting[19045] = "gizmos" -- Stormpike Battle Standard

-- player transforms
Sorting[44719] = "gizmos" -- Frenzyheart Brew
Sorting[20410] = "gizmos" -- Hallowed Wand - Bat
Sorting[20409] = "gizmos" -- Hallowed Wand - Ghost
Sorting[20399] = "gizmos" -- Hallowed Wand - Leper Gnome
Sorting[20398] = "gizmos" -- Hallowed Wand - Ninja
Sorting[20397] = "gizmos" -- Hallowed Wand - Pirate
Sorting[20413] = "gizmos" -- Hallowed Wand - Random
Sorting[20411] = "gizmos" -- Hallowed Wand - Skeleton
Sorting[20414] = "gizmos" -- Hallowed Wand - Wisp
Sorting[43499] = "gizmos" -- Iron Boot Flask
Sorting[1973] = "gizmos" -- Orb of Deception
Sorting[35275] = "gizmos" -- Orb of the Sin'dorei
