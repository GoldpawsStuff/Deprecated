local _, ns = ...
local oUF = ns.oUF
if not oUF then return end

--[[
The specialization IDs are as follows:
*Note that a value of 0 is returned if the info 
 isn't available from the server yet. 

Source: http://wow.gamepedia.com/API_GetInspectSpecialization

Class			Specialization 1	Specialization 2	Specialization 3	Specialization 4
				 ID	Name			 ID	Name			 ID	Name			 ID	Name

Death Knight	250	Blood			251	Frost			252	Unholy	 	
Demon Hunter	577	Havoc			581	Vengeance	 	 	 	
Druid			102	Balance			103	Feral			104	Guardian		105	Restoration
Hunter			253	Beast Mastery	254	Marksmanship	255	Survival	 	
Mage			 62	Arcane			 63	Fire			 64	Frost	 	
Monk			268	Brewmaster		270	Mistweaver		269	Windwalker	 	
Paladin			 65	Holy			 66	Protection		 70	Retribution	 	
Priest			256	Discipline		257	Holy			258	Shadow	 	
Rogue			259	Assassination	260	Outlaw			261	Subtlety	 	
Shaman			262	Elemental		263	Enhancement		264	Restoration	 	
Warlock			265	Affliction		266	Demonology		267	Destruction	 	
Warrior			 71	Arms			 72	Fury			 73	Protection	 	

]]--

-- Lua API
local _G = _G
local select = select
local setmetatable = setmetatable
local unpack = unpack

-- WoW API
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local UnitAura = _G.UnitAura
local UnitClass = _G.UnitClass

-- WoW Objects
local DebuffTypeColor = _G.DebuffTypeColor

local PLAYER_CLASS = select(2, UnitClass("player"))
local PLAYER_SPEC_ID = 0

-- Priests need to check for helpful too, because of atonement
local specFilters = ({
	PRIEST 		= { HARMFUL = { Magic = true, Disease = true }, HELPFUL = { Custom = true } },
	SHAMAN 		= { HARMFUL = { Magic = false, Curse = true } },
	PALADIN 	= { HARMFUL = { Magic = false, Poison = true, Disease = true } },
	DRUID 		= { HARMFUL = { Magic = false, Curse = true, Poison = true } },
	MONK 		= { HARMFUL = { Magic = false, Poison = true, Disease = true } },
})[PLAYER_CLASS] or { HARMFUL = {} } -- just a dummy table for the rest to supply the filter

local specTracking = ({
	DRUID 		= { HARMFUL = { Magic = 105 } },
	MONK 		= { HARMFUL = { Magic = 270 } },
	PALADIN 	= { HARMFUL = { Magic = 65 } },
	PRIEST 		= { HELPFUL = { Custom = 256 } },
	SHAMAN 		= { HARMFUL = { Magic = 264 } }
})[PLAYER_CLASS]

-- Priority of varios auras
-- Higher means higher... ;) 
local bossDebuffPrio = 9999999
local invalidPrio = -1
local dispelPrio = {
	Boss 	= 9999999,
	Magic   = 4,
	Curse   = 3,
	Disease = 2,
	Poison  = 1,
	Custom 	= 0 
}

local spellTypeOverride = {
	[194384] 	= "Custom" -- Atonement
}

-- Use a metatable to dynamically create the colors
local spellTypeColor = setmetatable({
	["Custom"] = { 1, .9294, .7607 }, -- same color I used for "unknown" zone names (instances, bgs, contested zones on pve realms)
	["none"] = { 0, 0, 0 }
}, { __index = function(tbl,key)
		local v = DebuffTypeColor[key]
		if v then
			tbl[key] = { v.r, v.g, v.b }
			return tbl[key]
		end
	end
})

local UpdateAuraFrame = function(self)
	if self.PreUpdate then
		self:PreUpdate()
	end
	
	if (self.index and self.type and self.filter) then
		local name, rank, icon, count, spellType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(self.__owner.unit, self.index, self.filter)
		
		if self.icon then
			self.icon:SetTexture(icon)
			self.icon:Show()
		end
		
		if self.count then
			if (count and (count > 0)) then
				self.count:SetText(count)
				self.count:Show()
			else
				self.count:Hide()
			end
		end
		
		if self.cd then
			if (duration and (duration > 0)) then
				self.cd:SetCooldown(expirationTime - duration, duration)
				self.cd:Show()
			else
				self.cd:Hide()
			end
		end
		
		if self.SetDebuffTypeColor then
			local colors = self.DebuffTypeColor or spellTypeColor
			local c = colors[spellType] or colors.none or spellTypeColor.none
			self:SetDebuffTypeColor(unpack(c))
		end
		
		if (not self:IsShown()) then
			self:Show()
		end
	else
		if (self:IsShown()) then
			self:Hide()
		end
	end
	
	if self.PostUpdate then
		self:PostUpdate()
	end
end

local Update = function(self, event, unit)
	if not self then return end -- wth is this? 
	if (unit ~= self.unit) then 
		return 
	end

	local groupAuras = self.GroupAuras

	-- This shouldn't be happening either, but it is. 
	-- Must be some old unit frame code using outdated object names somewhere, 
	-- but for now we work around it by returning if the object doesn't exit.
	if (not groupAuras) then
		return
	end

	-- Reset the filter before iterating
	groupAuras.priority = invalidPrio
	
	-- Random order, but that doesn't matter
	-- since we do this by priority and not order. 
	for filter,schools in pairs(specFilters) do
		local i = 0
		while true do
			i = i + 1
			local name, rank, texture, count, spellType, duration, expirationTime, caster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod = UnitAura(unit, i, filter)

			-- no endless loops
			if (not name) then break end 

			-- only show harmful boss debuss, not helpful (if any)
			if isBossDebuff and (filter == "HARMFUL") then
				groupAuras.priority = dispelPrio.Boss
				groupAuras.index = i
				groupAuras.type = auraType
				groupAuras.filter = filter
			else
				local auraType = spellTypeOverride[spellId] or spellType
				local prio = schools[auraType] and dispelPrio[auraType]
				if (prio and (prio > groupAuras.priority)) then
					groupAuras.priority = prio
					groupAuras.index = i
					groupAuras.type = auraType
					groupAuras.filter = filter
				end
			end
		end
	end
	
	if (groupAuras.priority == invalidPrio) then
		groupAuras.index = nil
		groupAuras.filter = nil
		groupAuras.type = nil
	end
	
	return UpdateAuraFrame(groupAuras)
end

local SpecUpdate = function(self, event, ...)
	-- This returns 0 early in the startup process
	local spec = GetSpecialization()
	local id = spec and GetSpecializationInfo(spec)
	if (id and (id > 0)) and (PLAYER_SPEC_ID ~= id) then
		PLAYER_SPEC_ID = id
		for filter,schools in pairs(specTracking) do
			for school,specID in pairs(schools) do
				specFilters[filter][school] = specID == id
			end
		end
		Update(self, ...)
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, "ForceUpdate", element.__owner.unit)
end

local specTrackerFrame
local Enable = function(self)
	local groupAuras = self.GroupAuras
	if groupAuras then
		groupAuras.ForceUpdate = ForceUpdate
		groupAuras.__owner = self

		self:RegisterEvent("UNIT_AURA", Update)
		
		-- Don't do any of this for classes that don't need it.
		if specTracking then 
			specTrackerFrame = specTrackerFrame or CreateFrame("Frame")
			specTrackerFrame:SetScript("OnEvent", SpecUpdate)
			specTrackerFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
			specTrackerFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
			specTrackerFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")

			SpecUpdate()
		end
		
		return true
	end
end

local Disable = function(self)
	local groupAuras = self.GroupAuras
	if groupAuras then
		groupAuras:Hide()
		groupAuras.__owner = nil

		self:UnregisterEvent("UNIT_AURA", Update)

		if specTrackerFrame then
			specTrackerFrame:SetScript("OnEvent", nil)
			specTrackerFrame:UnregisterEvent("PLAYER_TALENT_UPDATE")
			specTrackerFrame:UnregisterEvent("CHARACTER_POINTS_CHANGED")
		end

	end
end

oUF:AddElement("GroupAuras", Update, Enable, Disable)
