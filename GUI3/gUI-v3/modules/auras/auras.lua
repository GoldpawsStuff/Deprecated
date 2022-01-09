--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Auras")

local pairs, unpack, select = pairs, unpack, select
local tinsert = table.insert
local ceil, floor, max = math.ceil, math.floor, math.max
local strfind = string.find

local GetInventoryItemTexture = GetInventoryItemTexture
local GetInventorySlotInfo = GetInventorySlotInfo
local GetTime = GetTime 
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local UnitAura = UnitAura
local DebuffTypeColor = DebuffTypeColor

local L, C, F, M, db
local proxy, consolidate, buffs, debuffs
local createHeader, createStyle
local updateHeaders, updateHeader, updateButton, updateWeaponEnchant
local OnUpdate, OnAttributeChanged

local buttons = {}
local day, hour, minute = 86400, 3600, 60
local buffsize = 29
local columns = 20 -- there are 40 buffs, not 32. How did I miss this?
local lines = 2
local width = buffsize + 2
local height = buffsize + 2 + 14 + 4

local defaults = {
	showgloss = true;
	showshade = true;
	glossalpha = 1/3;
	shadealpha = 1/2;
	showTimeText = true;
	showDurationAsBar = true; 
	showCooldownSpiral = false;
	place = {
		buffs = { "TOPRIGHT", "UIParent", "TOPRIGHT", -8, -8 };
		debuffs = { "TOPRIGHT", "UIParent", "TOPRIGHT", -8, -(8 + (8 + lines * height)) };
	};
}

OnUpdate = function(self)
	if not(self) or not(self:IsVisible()) then return end
	
	local timeLeft = max((self.expirationTime or 0) - GetTime(), 0)
	if (timeLeft ~= self.timeLeft) then
		if (timeLeft <= 0) then
			if (self.Animation:IsPlaying()) then
				self.Animation:Stop()
			end
			self.duration = nil
			self.expirationTime = nil
			self:SetScript("OnUpdate", nil)	
		elseif (timeLeft < 11) then
			if not(self.Animation:IsPlaying()) then
				self.Animation:Play()
			end
		elseif (self.Animation:IsPlaying()) then
			self.Animation:Stop()
		end
		
		if (db.showDurationAsBar) then
			if (self.duration) and (self.duration > 0) then
				local r, g, b = F.ColorGradient(timeLeft, self.duration)
				self.DurationBar:SetValue(timeLeft)
				self.DurationBar:SetStatusBarColor(r, g, b)
			else
				self.DurationBar:Hide()
			end
		else
			-- more than a day
			if (timeLeft > day) then
				self.Duration:SetFormattedText("%1dd", ceil(timeLeft / day))
				
			-- more than an hour
			elseif (timeLeft > hour) then
				self.Duration:SetFormattedText("%1dh", ceil(timeLeft / hour))
			
			-- more than a minute
			elseif (timeLeft > minute) then
				self.Duration:SetFormattedText("%1dm", ceil(timeLeft / minute))
			
			-- more than 10 seconds
			elseif (timeLeft > 10) then 
				self.Duration:SetFormattedText("%1d", floor(timeLeft))
			
			-- between 6 and 10 seconds
			elseif (timeLeft <= 10) and (timeLeft >= 6) then
				self.Duration:SetFormattedText("|cffff8800%1d|r", floor(timeLeft))
				
			-- between 3 and 5 seconds
			elseif (timeLeft >= 3) and (timeLeft < 6)then
				self.Duration:SetFormattedText("|cffff0000%1d|r", floor(timeLeft))
				
			-- less than 3 seconds
			elseif (timeLeft > 0) and (timeLeft < 3) then
				self.Duration:SetFormattedText("|cffff0000%.1f|r", timeLeft)
			else
				self.Duration:SetText("")
			end
		end
	end
	self.timeLeft = timeLeft
end

OnAttributeChanged = function(self, attribute, value)
	if (attribute == "index") then
		updateHeader(self:GetParent())
		-- updateButton(self)
	end
	-- print(self:GetID(), attribute, value)
end

createStyle = function(self)
	if (buttons[self]) then return end
	
	gUI:SetUITemplate(self, "backdrop")
	gUI:CreateUIShadow(self)

	local Icon = self:CreateTexture()
	Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -3)
	Icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)
	Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	gUI:SetUITemplate(self, "shade", Icon):SetShown(db.showshade)
	gUI:SetUITemplate(self, "gloss", Icon):SetShown(db.showgloss)
	self.Icon = Icon

	local Count = self:CreateFontString(nil, "OVERLAY")
	Count:SetFontObject(gUI_TextFontExtraTinyBoldOutlineWhite)
	Count:SetJustifyH("RIGHT")
	Count:SetJustifyV("BOTTOM")
	Count:SetPoint("BOTTOMRIGHT", self.Icon, "BOTTOMRIGHT", -1, 1)
	self.Count = Count
	
	local Cooldown = CreateFrame("Cooldown", nil, self)
	Cooldown:SetAllPoints(self.Icon)
	Cooldown:SetReverse()
	Cooldown:SetShown(db.showCooldownSpiral)
	self.Cooldown = Cooldown
	
	local Duration = self:CreateFontString(nil, "OVERLAY")
	Duration:SetFontObject(gUI_DisplayFontExtraTinyOutline)
	Duration:SetJustifyH("CENTER")
	Duration:SetJustifyV("TOP")
	Duration:SetPoint("TOP", self, "BOTTOM", 0, -2)
	Duration:SetShown((db.showTimeText) and not(db.showDurationAsBar))
	self.Duration = Duration
	
	local DurationBar = CreateFrame("StatusBar", nil, self)
	DurationBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 3, -6)
	DurationBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -3, -6)
	DurationBar:SetHeight(6)
	DurationBar:SetStatusBarTexture(gUI:GetStatusBarTexture())
	DurationBar:SetShown((db.showTimeText) and (self.duration) and (db.showDurationAsBar))
	gUI:CreateUIShadow(gUI:SetUITemplate(DurationBar, "castbarwithborder"))
	self.DurationBar = DurationBar

	local Animation = self:CreateAnimationGroup()
	Animation:SetLooping("BOUNCE")
	
	local Alpha = Animation:CreateAnimation("Alpha")
	Alpha:SetChange(-0.5)
	Alpha:SetDuration(1.0)
	Alpha:SetSmoothing("IN_OUT")
	self.Animation = Animation

	self.filter = self:GetParent():GetAttribute("filter")

	self:SetScript("OnAttributeChanged", OnAttributeChanged)

	buttons[self] = true
end

updateWeaponEnchant = function(self, header, slot, active, time, charges)
	if not(self) then return end
	
	if not(buttons[self]) then
		createStyle(self)
	end
	
	if (active) then
		self.Icon:SetTexture(GetInventoryItemTexture("player", GetInventorySlotInfo(slot)))
		self.Count:SetText((charges > 1) and charges or "")
	end
	
	time = time and (time/1000 + GetTime())
	if (time ~= self.expirationTime) then
		self.expirationTime = time
	end
end

updateButton = function(self)
	if not(self) then return end 
	if not(buttons[self]) then createStyle(self) end

	local name, _, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(self:GetParent():GetAttribute("unit"), self:GetID(), self.filter)

	if (name) then
		self.Icon:SetTexture(icon)
		self:SetAlpha(1)

		if (duration) and (duration > 0) and (expirationTime) then
			if not(self.expirationTime) then
				self:SetScript("OnUpdate", OnUpdate)
			end
			self.duration = duration
			self.expirationTime = expirationTime
			self.Duration:SetShown((db.showTimeText) and not(db.showDurationAsBar))
			self.DurationBar:SetShown((db.showTimeText) and (db.showDurationAsBar))
			self.DurationBar:SetMinMaxValues(0, self.duration)

			if (db.showCooldownSpiral) then
				self.Cooldown:Show()
				self.Cooldown:SetCooldown(self.expirationTime - self.duration, self.duration)
			else
				self.Cooldown:Hide()
			end
		else
			self:SetScript("OnUpdate", nil)
			self.duration = nil
			self.expirationTime = nil
			self.Cooldown:Hide()
			self.Duration:SetText("")
			self.DurationBar:Hide()
			self.Animation:Stop()
		end
			
		self.Count:SetText((count > 1) and count or "")

		if (strfind(self:GetAttribute("filter"), "HARMFUL")) then
			local color = DebuffTypeColor[debuffType] or { r = 0.7, g = 0, b = 0 }
			self:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			if (unitCaster == "vehicle") then
				self:SetBackdropBorderColor(0, 3/4, 0, 1)
			else
				self:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
			end
		end
	else
		self:SetAlpha(0)
		-- self.Icon:SetTexture("")
		-- self:SetScript("OnUpdate", nil)
		-- self.duration = nil
		-- self.expirationTime = nil
		-- self.Duration:SetText("")
		-- self.DurationBar:Hide()
		-- self.Animation:Stop()
	end
end

updateHeader = function(self, event, unit)
	if (self == buffs) then
		local e1, e1time, e1charges, e2, e2time, e2charges, e3, e3time, e3charges = GetWeaponEnchantInfo()
		updateWeaponEnchant(self:GetAttribute("tempEnchant1"), self, "MainHandSlot", e1, e1time, e1charges)
		updateWeaponEnchant(self:GetAttribute("tempEnchant2"), self, "SecondaryHandSlot", e2, e2time, e2charges)
		updateWeaponEnchant(self:GetAttribute("tempEnchant3"), self, "RangedSlot", e3, e3time, e3charges)
	end

	local button
	for index = 1,40 do
		updateButton(self:GetAttribute("child" .. index))
	end
end

updateHeaders = function(self, event, unit)
	if (unit) and (unit ~= "player") and (unit ~= "vehicle") then return end
	-- updateHeader(consolidate)

	updateHeader(buffs)
	updateHeader(debuffs)
end

module.PostUpdateSettings = function(self)
	for button, _ in pairs(buttons) do
		button.Gloss:SetShown(db.showgloss)
		button.Shade:SetShown(db.showshade)
		
		if (button.Cooldown) then
			button.Cooldown:SetShown(db.showCooldownSpiral)
			if (db.showCooldownSpiral) and (button.expirationTime) and (button.duration) then
				button.Cooldown:SetCooldown(button.expirationTime - button.duration, button.duration)
			end
			button.Duration:SetShown((db.showTimeText) and not(db.showDurationAsBar))
			button.DurationBar:SetShown((db.showTimeText) and (button.duration) and (db.showDurationAsBar))
		end
	end
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	
	db.showshade = true
	db.showgloss = true

	buffs = CreateFrame("Frame", self:GetParent():GetName() .. "Buffs", gUI:GetAttribute("parent"), "SecureAuraHeaderTemplate")
	-- proxy = CreateFrame("Frame", self:GetParent():GetName() .. "ConsolidationButton", buffs, "GUIS_ConsolidatedAurasTemplate")
	-- consolidate = CreateFrame("Frame", self:GetParent():GetName() .. "ConsolidationFrame", proxy, "SecureAuraHeaderTemplate") -- SecureFrameTemplate
	debuffs = CreateFrame("Frame", self:GetParent():GetName() .. "Debuffs", gUI:GetAttribute("parent"), "SecureAuraHeaderTemplate")
	
	buffs:SetAttribute("unit", "player")
	buffs:SetAttribute("filter", "HELPFUL")
	buffs:SetAttribute("sortMethod", "TIME")
	buffs:SetAttribute("sortDirection", "-")
	buffs:SetAttribute("point", "TOPRIGHT")
	buffs:SetAttribute("template", "GUIS_AuraButtonTemplate")
	buffs:SetAttribute("wrapAfter", columns)
	buffs:SetAttribute("wrapXOffset", 0)
	buffs:SetAttribute("wrapYOffset", -height)
	buffs:SetAttribute("maxWraps", lines)
	buffs:SetAttribute("minWidth", width * columns)
	buffs:SetAttribute("minHeight", height * lines)
	buffs:SetAttribute("xOffset", -width)
	buffs:SetAttribute("yOffset", 0)
	buffs:SetAttribute("separateOwn", 0) -- 1 = own buffs before, -1 after, 0/nil no sorting
	-- buffs:SetAttribute("consolidateHeader", consolidate)
	-- buffs:SetAttribute("consolidateProxy", proxy) -- the aura button to click for the consolidation frame
	-- buffs:SetAttribute("consolidateHeader", consolidate) -- secure aura header for consolidated buffs
	-- buffs:SetAttribute("consolidateDuration", -1) -- minimum total duration to be considered for consolidation
	-- buffs:SetAttribute("consolidateThreshold", 30) -- buffs with less time left will not be consolidated
	-- buffs:SetAttribute("consolidateTo", 0) -- buff index, set to 0 to hide
	buffs:SetAttribute("includeWeapons", 1)
	buffs:SetAttribute("weaponTemplate", "GUIS_AuraButtonTemplate")
	buffs:SetSize(columns * width, lines * height)
	buffs:Show()
	RegisterAttributeDriver(buffs, "unit", "[vehicleui] vehicle; player")

	self:PlaceAndSave(buffs, L["Player Buffs"], db.place.buffs, unpack(defaults.place.buffs))
	self:AddObjectToFrameGroup(buffs, "buffs")
	
	debuffs:SetAttribute("unit", "player")
	debuffs:SetAttribute("filter", "HARMFUL")
	debuffs:SetAttribute("sortMethod", "TIME")
	debuffs:SetAttribute("sortDirection", "-")
	debuffs:SetAttribute("point", "TOPRIGHT")
	debuffs:SetAttribute("template", "GUIS_AuraButtonTemplate")
	debuffs:SetAttribute("wrapAfter", columns)
	debuffs:SetAttribute("wrapXOffset", 0)
	debuffs:SetAttribute("wrapYOffset", -height)
	debuffs:SetAttribute("maxWraps", lines)
	debuffs:SetAttribute("minWidth", width * columns)
	debuffs:SetAttribute("minHeight", height * lines)
	debuffs:SetAttribute("xOffset", -width)
	debuffs:SetAttribute("yOffset", 0)
	debuffs:SetSize(columns * width, lines * height)
	debuffs:Show()

	self:PlaceAndSave(debuffs, L["Player Debuffs"], db.place.debuffs, unpack(defaults.place.debuffs))
	self:AddObjectToFrameGroup(debuffs, "buffs")
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD", updateHeaders)
	self:RegisterEvent("UNIT_AURA", updateHeaders)
	-- self:RegisterEvent("PLAYER_ALIVE", updateHeaders)
	-- self:RegisterEvent("ZONE_CHANGED_NEW_AREA", updateHeaders) -- just a hunch
	-- self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", updateHeaders) -- totally needed
	-- self:RegisterEvent("UNIT_INVENTORY_CHANGED", updateHeaders)
	
	-- kill redundant blizzard options and frames
	do
		gUI:KillPanel(12, InterfaceOptionsBuffsPanel)
		gUI:KillObject(BuffFrame)
		gUI:KillObject(ConsolidatedBuffs)
		gUI:KillObject(TemporaryEnchantFrame)
	end
	
	-- create the options menu
	do
		local menuTable = {
			{
				type = "group";
				name = module:GetName();
				order = 1;
				virtual = true;
				children = {
					{
						type = "widget";
						element = "Title";
						order = 1;
						msg = L["Auras"];
					};
					{
						type = "widget";
						element = "Text";
						order = 2;
						msg = L["These options allow you to control how buffs and debuffs are displayed. If you wish to change the position of the buffs and debuffs, you can unlock them for movement with |cFF4488FF/glock|r."];
					};
					-- {
						-- type = "group";
						-- order = 5;
						-- virtual = true;
						-- children = {
							-- {
								-- type = "widget";
								-- element = "Header";
								-- order = 10;
								-- width = "half";
								-- msg = L["Aura Styling"];
							-- };
							-- {
								-- type = "widget";
								-- element = "CheckButton";
								-- name = "showGloss";
								-- order = 100;
								-- width = "full"; 
								-- msg = L["Show gloss layer on Auras"];
								-- desc = { L["Show Gloss"], L["This will display the gloss overlay on the Auras"] };
								-- set = function(self) 
									-- db.showgloss = not(db.showgloss)
									-- module:PostUpdateSettings()
								-- end;
								-- get = function() return db.showgloss end;
							-- };
							-- {
								-- type = "widget";
								-- element = "CheckButton";
								-- name = "showShade";
								-- order = 105;
								-- width = "full"; 
								-- msg = L["Show shade layer on Auras"];
								-- desc = { L["Show Shade"], L["This will display the shade overlay on the Auras"] };
								-- set = function(self) 
									-- db.showshade = not(db.showshade)
									-- module:PostUpdateSettings()
								-- end;
								-- get = function() return db.showshade end;
							-- };
						-- };
					-- };
					{
						type = "group";
						order = 10;
						virtual = true;
						children = {
							{
								type = "widget";
								element = "Header";
								order = 11;
								width = "full";
								msg = L["Time Display"];
							};
							-- { -- blizzard: consolidateBuffs
								-- type = "widget";
								-- element = "CheckButton";
								-- name = "consolidateBuffs";
								-- order = 100;
								-- width = "full"; 
								-- msg = L["Consolidate Buffs"];
								-- desc = nil;
								-- set = function(self) 
									-- SetCVar("consolidateBuffs", (tonumber(GetCVar("consolidateBuffs")) == 1) and 0 or 1)
								-- end;
								-- get = function() return tonumber(GetCVar("consolidateBuffs")) == 1 end;
							-- };							
							{
								type = "widget";
								element = "CheckButton";
								name = "showDuration";
								order = 101;
								width = "full"; 
								msg = L["Show remaining time on Auras"];
								desc = { L["Show Time"], L["This will display the currently remaining time on Auras where applicable"] };
								set = function(self) 
									db.showTimeText = not(db.showTimeText)
									self:init()
									module:PostUpdateSettings()
								end;
								get = function() return db.showTimeText end;
								init = function(self) 
									if (db.showTimeText) then
										self.parent.child.showDurationAsBar:Enable()
									else
										self.parent.child.showDurationAsBar:Disable()
									end
								end;
							};
							{
								type = "widget";
								element = "CheckButton";
								name = "showDurationAsBar";
								order = 102;
								width = "full"; 
								indented = true;
								msg = L["Display remaining time as a timer bar instead of text"];
								desc = nil;
								set = function(self) 
									db.showDurationAsBar = not(db.showDurationAsBar)
									module:PostUpdateSettings()
								end;
								get = function() return db.showDurationAsBar end;
							};
							{
								type = "widget";
								element = "CheckButton";
								name = "showCooldown";
								order = 106;
								width = "half"; 
								msg = L["Show cooldown spirals on Auras"];
								desc = { L["Show Cooldown Spirals"], L["This will display cooldown spirals on Auras to indicate remaining time"] };
								set = function(self) 
									db.showCooldownSpiral = not(db.showCooldownSpiral)
									module:PostUpdateSettings()
								end;
								get = function() return db.showCooldownSpiral end;
							};
						};
					};
				};
			};
		}
		local restoreDefaults = function()
			if (InCombatLockdown()) then 
				print(L["Can not apply default settings while engaged in combat."])
				return
			end
			self:ResetCurrentOptionsSetToDefaults()
		end
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["Auras"], "default", restoreDefaults)
	end
	
end

module.OnEnable = function(self)
end

module.OnEnter = function(self)
	-- updateHeaders()
end

module.OnDisable = function(self)
end
