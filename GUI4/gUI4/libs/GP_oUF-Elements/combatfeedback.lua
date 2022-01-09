local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local damage_format = "-%s"
local heal_format = "+%s"
local maxAlpha = 0.6
local updateFrame
local feedback = {}
local originalHeight = {}
local color 
local colors = {
	DAMAGE = { .69, .31, .31 },
	CRUSHING = { .69, .31, .31 },
	CRITICAL = { .69, .31, .31 },
	GLANCING = { .69, .31, .31 },
	STANDARD = { .84, .75, .65 },
	IMMUNE = { .84, .75, .65 },
	ABSORB = { .84, .75, .65 },
	BLOCK = { .84, .75, .65 },
	RESIST = { .84, .75, .65 },
	MISS = { .84, .75, .65 },
	HEAL = { .33, .59, .33 },
	CRITHEAL = { .33, .59, .33 },
	ENERGIZE = { .31, .45, .63 },
	CRITENERGIZE = { .31, .45, .63 }
}
local CombatFeedbackText = CombatFeedbackText

local function short(value)
	value = tonumber(value)
	if not(value) then return "0.0" end
	if (value >= 1e6) then
		return ("%.1f MEGA"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif (value >= 1e4) or (value <= -1e3) then
		return ("%.1fK"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return tostring(value)
	end	
end

local function createUpdateFrame()
	if updateFrame then return end
	updateFrame = CreateFrame("Frame")
	updateFrame:Hide()
	updateFrame:SetScript("OnUpdate", function()
		if next(feedback) == nil then
			updateFrame:Hide()
			return
		end
		for object, startTime in pairs(feedback) do
			local maxalpha = object.CombatFeedbackText.maxAlpha
			local elapsedTime = GetTime() - startTime
			if ( elapsedTime < COMBATFEEDBACK_FADEINTIME ) then
				local alpha = maxalpha*(elapsedTime / COMBATFEEDBACK_FADEINTIME)
				object.CombatFeedbackText:SetAlpha(alpha)
			elseif ( elapsedTime < (COMBATFEEDBACK_FADEINTIME + COMBATFEEDBACK_HOLDTIME) ) then
				object.CombatFeedbackText:SetAlpha(maxalpha)
			elseif ( elapsedTime < (COMBATFEEDBACK_FADEINTIME + COMBATFEEDBACK_HOLDTIME + COMBATFEEDBACK_FADEOUTTIME) ) then
				local alpha = maxalpha - maxalpha*((elapsedTime - COMBATFEEDBACK_HOLDTIME - COMBATFEEDBACK_FADEINTIME) / COMBATFEEDBACK_FADEOUTTIME)
				object.CombatFeedbackText:SetAlpha(alpha)
			else
				object.CombatFeedbackText:Hide()
				feedback[object] = nil
			end
		end		
	end)
end

local function combat(self, event, unit, eventType, flags, amount, dtype)
	if unit ~= self.unit then return end
	local FeedbackText = self.CombatFeedbackText
	local fColors = FeedbackText.colors
	local font, fontHeight, fontFlags = FeedbackText:GetFont()
	fontHeight = FeedbackText.origHeight -- always start at original height
	local text, arg
	color = fColors and fColors.STANDARD or colors.STANDARD
	if eventType == "IMMUNE" and not FeedbackText.ignoreImmune then
		color = fColors and fColors.IMMUNE or colors.IMMUNE
		fontHeight = fontHeight * 0.75
		text = CombatFeedbackText[eventType]
	elseif eventType == "WOUND" and not FeedbackText.ignoreDamage then
		if amount ~= 0 then
			if flags == "CRITICAL" then
				color = fColors and fColors.CRITICAL or colors.CRITICAL
				fontHeight = fontHeight * 1.5
			elseif  flags == "CRUSHING" then
				color = fColors and fColors.CRUSING or colors.CRUSHING
				fontHeight = fontHeight * 1.5
			elseif flags == "GLANCING" then
				color = fColors and fColors.GLANCING or colors.GLANCING
				fontHeight = fontHeight * 0.75
			else
				color = fColors and fColors.DAMAGE or colors.DAMAGE
			end
			text = damage_format
			arg = short(amount)
		elseif flags == "ABSORB" then
			color = fColors and fColors.ABSORB or colors.ABSORB
			fontHeight = fontHeight * 0.75
			text = CombatFeedbackText["ABSORB"]
		elseif flags == "BLOCK" then
			color = fColors and fColors.BLOCK or colors.BLOCK
			fontHeight = fontHeight * 0.75
			text = CombatFeedbackText["BLOCK"]
		elseif flags == "RESIST" then
			color = fColors and fColors.RESIST or colors.RESIST
			fontHeight = fontHeight * 0.75
			text = CombatFeedbackText["RESIST"]
		else
			color = fColors and fColors.MISS or colors.MISS
			text = CombatFeedbackText["MISS"]
		end
	elseif eventType == "BLOCK" and not FeedbackText.ignoreDamage then
		color = fColors and fColors.BLOCK or colors.BLOCK
		fontHeight = fontHeight * 0.75
		text = CombatFeedbackText[eventType]
	elseif eventType == "HEAL" and not FeedbackText.ignoreHeal then
		text = heal_format
		arg = short(amount)
		if flags == "CRITICAL" then
			color = fColors and fColors.CRITHEAL or colors.CRITHEAL
			fontHeight = fontHeight * 1.3
		else
			color = fColors and fColors.HEAL or colors.HEAL
		end
	elseif event == "ENERGIZE" and not FeedbackText.ignoreEnergize then
		text = amount
		if flags == "CRITICAL" then
			color = fColors and fColors.ENERGIZE or colors.ENERGIZE
			fontHeight = fontHeight * 1.3
		else
			color = fColors and fColors.CRITENERGIZE or colors.CRITENERGIZE
		end
	elseif not FeedbackText.ignoreOther then
		text = CombatFeedbackText[eventType]
	end

	if text then
		FeedbackText:SetFont(font,fontHeight,fontFlags)
		FeedbackText:SetFormattedText(text, arg)
		FeedbackText:SetTextColor(unpack(color))
		FeedbackText:SetAlpha(0)
		FeedbackText:Show()
		feedback[self] = GetTime()
		updateFrame:Show() -- start our onupdate
	end
end

local function addCombat(object)
	if not object.CombatFeedbackText then return end
	-- store the original starting height
	local font, fontHeight, fontFlags = object.CombatFeedbackText:GetFont()
	object.CombatFeedbackText.origHeight = fontHeight
	object.CombatFeedbackText.maxAlpha = object.CombatFeedbackText.maxAlpha or maxAlpha
	-- make it LibMediaPlus-1.0 compatible
	if object.CombatFeedbackText.SetFontSize then
		hooksecurefunc(object.CombatFeedbackText, "SetFontSize", function(self, size) 
			object.CombatFeedbackText.origHeight = size
		end)
	end
	createUpdateFrame()
	object:RegisterEvent("UNIT_COMBAT", combat)
end

for k, object in ipairs(oUF.objects) do addCombat(object) end
oUF:RegisterInitCallback(addCombat)
