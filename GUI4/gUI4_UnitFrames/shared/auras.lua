local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local UnitAffectingCombat = UnitAffectingCombat

local isPlayer = {
	player = true,
	pet = true,
	vehicle = true
}

ns.CustomAuraFilter = function(self, ...)
	local unit, icon, name, rank, texture, count, debuffType, duration, expirationTime, caster, canStealOrPurge, shouldConsolidate, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod = ...

	local db = self.GetSettings and self:GetSettings() -- check user settings for stuff to always show or hide
	if db then
		-- always show
		if (db.onlyInCombat and not UnitAffectingCombat("player")) -- and (unit:find("target") or unit:find("focus"))
		or (db.alwaysShowStealable and canStealOrPurge)
		or (db.alwaysShowBossDebuffs and isBossDebuff) then
			return true
		end
		-- always hide
		if (icon.isDebuff and (db.showDebuffs == false)) -- hide all buffs
		or (not(icon.isDebuff) and (db.showBuffs == false)) -- hide all benefitial buffs
		or (db.onlyPlayer and not(caster and isPlayer[caster])) -- aura not cast by the player, or a player controlled pet or vehicle
		or (db.onlyShortBuffs and (duration > 60)) -- hide auras with a duration above 60 seconds
		--or (duration > 0 and shouldConsolidate and (db.showConsolidated == false)) -- hide auras eligible for consolidation
		or (duration <= 0 and (db.showTimeless == false)) then -- hide auras that lack a duration
			return 
		end
	end
	return true -- display anything that doesn't fall into the former categories
end