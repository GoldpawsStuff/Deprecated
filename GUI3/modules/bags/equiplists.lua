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
local EquipList = module:GetDataBase("EquipList")
local Types = cargBags:GetLocalizedTypes()

EquipList["EXCEPTIONS"] = {
	HUNTER = { [Types["Mail"]] = 40; };
	PALADIN = { [Types["Plate"]] = 40; };
	SHAMAN = { [Types["Mail"]] = 40; };
	WARRIOR = { [Types["Plate"]] = 40; };
}
EquipList["MONK"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = true; 
		[Types["Mail"]] = false;
		[Types["Plate"]] = false;
		[Types["Shields"]] = false;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = true;
		[Types["Two-Handed Axes"]] = false;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = true;
		[Types["Two-Handed Maces"]] = false;
		[Types["Polearms"]] = true;
		[Types["One-Handed Swords"]] = true;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = true;
		[Types["Fist Weapons"]] = true;
		[Types["Miscellaneous"]] = false;
		[Types["Daggers"]] = false;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = false;
		[Types["Fishing Poles"]] = false;
	};
};
EquipList["DEATHKNIGHT"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = true; 
		[Types["Mail"]] = true;
		[Types["Plate"]] = true;
		[Types["Shields"]] = false;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = true;
		[Types["Two-Handed Axes"]] = true;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = true;
		[Types["Two-Handed Maces"]] = true;
		[Types["Polearms"]] = true;
		[Types["One-Handed Swords"]] = true;
		[Types["Two-Handed Swords"]] = true;
		[Types["Staves"]] = false;
		[Types["Fist Weapons"]] = false;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = false;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = false;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["DRUID"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = true; 
		[Types["Mail"]] = false;
		[Types["Plate"]] = false;
		[Types["Shields"]] = false;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = false;
		[Types["Two-Handed Axes"]] = false;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = true;
		[Types["Two-Handed Maces"]] = true;
		[Types["Polearms"]] = true;
		[Types["One-Handed Swords"]] = false;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = true;
		[Types["Fist Weapons"]] = true;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = true;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = false;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["HUNTER"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = true; 
		[Types["Mail"]] = true;
		[Types["Plate"]] = false;
		[Types["Shields"]] = false;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = false;
		[Types["Two-Handed Axes"]] = false;
		[Types["Bows"]] = true;
		[Types["Guns"]] = true;
		[Types["One-Handed Maces"]] = false;
		[Types["Two-Handed Maces"]] = false;
		[Types["Polearms"]] = false;
		[Types["One-Handed Swords"]] = false;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = false;
		[Types["Fist Weapons"]] = false;
		[Types["Miscellaneous"]] = false;
		[Types["Daggers"]] = false;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = true;
		[Types["Wands"]] = false;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["MAGE"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = false; 
		[Types["Mail"]] = false;
		[Types["Plate"]] = false;
		[Types["Shields"]] = false;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = false;
		[Types["Two-Handed Axes"]] = false;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = false;
		[Types["Two-Handed Maces"]] = false;
		[Types["Polearms"]] = false;
		[Types["One-Handed Swords"]] = true;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = true;
		[Types["Fist Weapons"]] = false;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = true;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = true;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["PALADIN"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = true; 
		[Types["Mail"]] = true;
		[Types["Plate"]] = true;
		[Types["Shields"]] = true;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = true;
		[Types["Two-Handed Axes"]] = true;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = true;
		[Types["Two-Handed Maces"]] = true;
		[Types["Polearms"]] = true;
		[Types["One-Handed Swords"]] = true;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = false;
		[Types["Fist Weapons"]] = false;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = false;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = false;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["PRIEST"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = false; 
		[Types["Mail"]] = false;
		[Types["Plate"]] = false;
		[Types["Shields"]] = false;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = false;
		[Types["Two-Handed Axes"]] = false;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = true;
		[Types["Two-Handed Maces"]] = false;
		[Types["Polearms"]] = false;
		[Types["One-Handed Swords"]] = false;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = true;
		[Types["Fist Weapons"]] = false;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = true;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = true;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["ROGUE"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = true; 
		[Types["Mail"]] = false;
		[Types["Plate"]] = false;
		[Types["Shields"]] = false;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = true;
		[Types["Two-Handed Axes"]] = false;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = true;
		[Types["Two-Handed Maces"]] = false;
		[Types["Polearms"]] = true;
		[Types["One-Handed Swords"]] = true;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = false;
		[Types["Fist Weapons"]] = true;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = true;
		[Types["Thrown"]] = true;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = false;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["SHAMAN"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = true; 
		[Types["Mail"]] = true;
		[Types["Plate"]] = false;
		[Types["Shields"]] = true;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = true;
		[Types["Two-Handed Axes"]] = true;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = true;
		[Types["Two-Handed Maces"]] = true;
		[Types["Polearms"]] = true;
		[Types["One-Handed Swords"]] = false;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = true;
		[Types["Fist Weapons"]] = true;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = true;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = false;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["WARLOCK"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = false; 
		[Types["Mail"]] = false;
		[Types["Plate"]] = false;
		[Types["Shields"]] = false;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = false;
		[Types["Two-Handed Axes"]] = false;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = false;
		[Types["Two-Handed Maces"]] = false;
		[Types["Polearms"]] = false;
		[Types["One-Handed Swords"]] = true;
		[Types["Two-Handed Swords"]] = false;
		[Types["Staves"]] = true;
		[Types["Fist Weapons"]] = false;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = true;
		[Types["Thrown"]] = false;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = true;
		[Types["Fishing Poles"]] = true;
	};
};
EquipList["WARRIOR"] =  {
	[Types["Armor"]] = {
		[Types["Miscellaneous"]] = true;
		[Types["Cloth"]] = true;
		[Types["Leather"]] = true; 
		[Types["Mail"]] = true;
		[Types["Plate"]] = true;
		[Types["Shields"]] = true;
	};
	[Types["Weapon"]] = {
		[Types["One-Handed Axes"]] = true;
		[Types["Two-Handed Axes"]] = true;
		[Types["Bows"]] = false;
		[Types["Guns"]] = false;
		[Types["One-Handed Maces"]] = true;
		[Types["Two-Handed Maces"]] = true;
		[Types["Polearms"]] = true;
		[Types["One-Handed Swords"]] = true;
		[Types["Two-Handed Swords"]] = true;
		[Types["Staves"]] = true;
		[Types["Fist Weapons"]] = true;
		[Types["Miscellaneous"]] = true;
		[Types["Daggers"]] = true;
		[Types["Thrown"]] = true;
		[Types["Crossbows"]] = false;
		[Types["Wands"]] = false;
		[Types["Fishing Poles"]] = true;
	};
};
