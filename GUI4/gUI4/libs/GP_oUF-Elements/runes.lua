local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

-- Lua API
local floor = math.floor
local select = select

-- WoW API
local GetRuneCooldown = GetRuneCooldown
local GetRuneType = GetRuneType
local GetTime = GetTime

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996
local isDeathKnight = select(2, UnitClass("player")) == "DEATHKNIGHT"

local widget = "RuneWidget"
local runemap = { 1, 2, 5, 6, 3, 4 }

local OnUpdate = function(self, elapsed)
	local duration = self.duration + elapsed
	if duration >= self.max then
		return self:SetScript("OnUpdate", nil)
	else
		self.duration = duration
		return self:SetValue(duration)
	end
end

local UpdateType = function(self, event, rid, alt)
	local runes = self[widget]
	local rune = runes[runemap[rid]]
	local r, g, b
	
	if LEGION then
		r, g, b = 100/255, 155/255, 225/255
	else
		local colors = self.colors.power.RUNE_BAR[GetRuneType and GetRuneType(rid) or alt or 1]
		r, g, b = colors[1], colors[2], colors[3]
	end
	

	rune:SetStatusBarColor(r, g, b)

	if rune.bg then
		local mu = rune.bg.multiplier or 1
		rune.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	if runes.PostUpdateType then
		return runes:PostUpdateType(rune, rid, alt)
	end
end

local UpdateRune = function(self, event, rid)
	local runes = self[widget]
	local rune = runes[runemap[rid]]
	if not rune then return end
	
	local start, duration, runeReady = GetRuneCooldown(rid)
	if not start then return end -- will sometimes return a nil value when zoning through portals
	
	if runeReady then
		rune:SetMinMaxValues(0, 1)
		rune:SetValue(1)
		rune:SetScript("OnUpdate", nil)
		if rune.Shine then
			rune.Shine:Start()
		end
	else
		rune.duration = GetTime() - start
		rune.max = duration
		rune:SetMinMaxValues(1, duration)
		rune:SetScript("OnUpdate", OnUpdate)
	end

	if runes.PostUpdateRune then
		return runes:PostUpdateRune(rune, rid, start, duration, runeReady)
	end
end

local Update = function(self, event)
	for i = 1, 6 do
		UpdateRune(self, event, i)
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, 'ForceUpdate')
end

local UpdateVisibility = function(self, event, arg1)
	if arg1 ~= "player" then return end
	local runes = self[widget]
	if self.unit ~= "player" then
		runes:Hide()
	else
		runes:Show()
	end
end

local Disable = function(self)
	RuneFrame.Show = nil
	RuneFrame:Show()

	self:UnregisterEvent("RUNE_POWER_UPDATE", UpdateRune)
	self:UnregisterEvent("RUNE_TYPE_UPDATE", UpdateType)
end

local Enable = function(self, unit)
	local runes = self[widget]
	if runes then
		if not isDeathKnight then
			runes:Hide()
			return
		end
		runes.__owner = self
		runes.ForceUpdate = ForceUpdate

		if LEGION then
			for i = 1, 6 do
				local rune = runes[runemap[i]]
				-- From my minor testing this is an okey solution. A full login always remove
				-- the death runes, or at least the clients knowledge about them.
				UpdateType(self, nil, i)
			end
		
			self:RegisterEvent("RUNE_POWER_UPDATE", UpdateRune, true)
			self:RegisterEvent("RUNE_TYPE_UPDATE", UpdateType, true)
			self:RegisterEvent("UNIT_ENTERED_VEHICLE", UpdateVisibility)
			self:RegisterEvent("UNIT_EXITED_VEHICLE", UpdateVisibility)
		else
			for i = 1, 6 do
				local rune = runes[runemap[i]]
				-- From my minor testing this is an okey solution. A full login always remove
				-- the death runes, or at least the clients knowledge about them.
				UpdateType(self, nil, i, floor((i+1)/2))
			end

			self:RegisterEvent("RUNE_POWER_UPDATE", UpdateRune, true)
			self:RegisterEvent("RUNE_TYPE_UPDATE", UpdateType, true)
			self:RegisterEvent("UNIT_DISPLAYPOWER", UpdateVisibility)
			self:RegisterEvent("UNIT_ENTERED_VEHICLE", UpdateVisibility)
			self:RegisterEvent("UNIT_EXITED_VEHICLE", UpdateVisibility)
		end

		-- oUF leaves the vehicle events registered on the player frame, so
		-- buffs and such are correctly updated when entering/exiting vehicles.
		--
		-- This however makes the code also show/hide the RuneFrame.
		RuneFrame.Show = RuneFrame.Hide
		RuneFrame:Hide()

		return true
	end
end

oUF:AddElement(widget, Update, Enable, Disable)
