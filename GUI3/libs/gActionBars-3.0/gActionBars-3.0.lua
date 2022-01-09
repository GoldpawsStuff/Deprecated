--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local MAJOR, MINOR = "gActionBars-3.0", 37
local gAB, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gAB) then return end 

assert(LibStub("gCore-4.0"), MAJOR .. ": Cannot find an instance of gCore-4.0")

local strfind, strsplit, format = string.find, string.split, string.format
local pairs, select, unpack = pairs, select, unpack
local type = type
local tconcat, tinsert = table.concat, table.insert
local setmetatable = setmetatable
local rawget = rawget
local wipe = wipe

local ActionButton_ShowGrid = ActionButton_ShowGrid
local AutoCastShine_AutoCastStart = AutoCastShine_AutoCastStart
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local CreateFrame = CreateFrame
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetPetActionInfo = GetPetActionInfo
local GetShapeshiftFormCooldown = GetShapeshiftFormCooldown
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local GetPetActionSlotUsable = GetPetActionSlotUsable
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsLoggedIn = IsLoggedIn
local IsPetAttackAction = IsPetAttackAction
local PetActionBar_UpdateCooldowns = PetActionBar_UpdateCooldowns
local PetActionButton_StartFlash = PetActionButton_StartFlash
local PetActionButton_StopFlash = PetActionButton_StopFlash
local PetHasActionBar = PetHasActionBar
local SetCVar = SetCVar
local SetDesaturation = SetDesaturation

gAB.scheduler = gAB.scheduler or LibStub("gCore-4.0"):NewAddon(MAJOR)
gAB.bars = gAB.bars or {} -- table of virtual bars
gAB.buttonPool = gAB.buttonPool or {} -- pool of buttons and their parent virtual bars
gAB.queue = gAB.queue or {} -- queued functions to be executed on combat end (e.g updated shapeshift forms)

local noop = noop or function() return end
local playerClass = (select(2, UnitClass("player")))

local NUM_MICRO_BUTTONS = 12

--
-- argCheck(value, num[, nobreak], ...)
-- 	@param value <any> the argument to check
-- 	@param num <number> the number of the argument in your function 
-- 	@param nobreak <boolean> optional. if true, then a non-breaking error will fired instead
-- 	@param ... <string,nil> list of argument types. a 'nil' value will be treated as the text 'nil'
local argCheck = function(value, num, ...)
	assert(type(num) == "number", "Bad argument #2 to 'argCheck' (number expected, got " .. type(num) .. ")")
	
	local nobreak, t
	for i = 1, select("#", ...) do
		if (i == 1) and (select(i, ...) == true) then
			nobreak = true
		else
			t = select(i, ...) 
			if (type(value) == t) then return end
		end
	end

	local types = strjoin(", ", ...)
	local name = strmatch(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	
	if (nobreak) then
		geterrorhandler()(("Bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
	else
		error(("Bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
	end
end

-- table of buttons belonging to bars, their names and max number
local buttons = {
	primary = { name = "ActionButton", num = NUM_ACTIONBAR_BUTTONS };
	bottomleft = { name = "MultiBarBottomLeftButton", num = NUM_ACTIONBAR_BUTTONS };
	bottomright = { name = "MultiBarBottomRightButton", num = NUM_ACTIONBAR_BUTTONS };
	right = { name = "MultiBarRightButton", num = NUM_ACTIONBAR_BUTTONS };
	left = { name = "MultiBarLeftButton", num = NUM_ACTIONBAR_BUTTONS };
	pet = { name = "PetActionButton", num = NUM_PET_ACTION_SLOTS };
	shift = { name = "StanceButton", num = NUM_STANCE_SLOTS };
	micro = { name = "GAB_MicroButton", num = NUM_MICRO_BUTTONS };
	-- extra = { name = "ExtraActionButton", num = 1 };
}

-- table to identify what buttons the user can edit
local editable = {}
for i = 1, NUM_ACTIONBAR_BUTTONS do
	editable[ _G["ActionButton" .. i] ] = true
	editable[ _G["MultiBarBottomLeftButton" .. i] ] = true
	editable[ _G["MultiBarBottomRightButton" .. i] ] = true
	editable[ _G["MultiBarRightButton" .. i] ] = true
	editable[ _G["MultiBarLeftButton" .. i] ] = true
end

local nameToPage, getStateDriver
do 
	local common = "[vehicleui] 12; [possessbar] 12; [overridebar] 14; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6"
	-- local common = "[vehicleui:12] 12; [possessbar] 12; [overridebar] 14; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6"
	local driverByClass = {
		["DRUID"] = "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10";
		["MONK"] = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9";
		["PRIEST"] = "[bonusbar:1] 7";
		["ROGUE"] = "[form:1] 7; [form:3] 7";
		-- ["WARLOCK"] = "";
		-- ["WARRIOR"] = "";
	}

	-- these are included in the library only because they are so common that I expect very frequent usage of them
	local extraStanceMagic = {
		["DRUID"] = "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10"; -- prowl
		["ROGUE"] = "[form:1] 7; [form:3] 8"; -- shadow dance
		["WARLOCK"] = "[form:1] 7"; -- metamorphosis
		["WARRIOR"] = "[form:1] 7; [form:2] 8; [form:3] 9"; -- stance switching
	}
	
	-- which bars can have states
	-- ToDo: add functionality to customize this for all bars, like in bartender
	local hasStateBar = {
		primary = true
	}

	-- this table returns the page pageID of a bar
	nameToPage = setmetatable({
		primary = 1;
		secondary = 2; -- we don't use this
		bottomleft = BOTTOMLEFT_ACTIONBAR_PAGE; -- 6
		bottomright = BOTTOMRIGHT_ACTIONBAR_PAGE; -- 5
		right = RIGHT_ACTIONBAR_PAGE; -- 3
		left = LEFT_ACTIONBAR_PAGE; -- 4
	}, { __index = function(t, i) return rawget(t,i) or 0 end })

	-- returns state driver
	getStateDriver = function(parent, useStanceMagic)
		if (hasStateBar[parent]) then 
			local extra = (useStanceMagic) and extraStanceMagic[playerClass] or driverByClass[playerClass]
			if (extra) then
				return common .. "; " .. extra .. "; 1"
			else
				return common .. "; 1"
			end
			-- return common .. (useStanceMagic and extraStanceMagic[playerClass] or byClass) .. "1" 
		else
			return nameToPage[parent]
		end
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Custom Buttons
------------------------------------------------------------------------------------------------------------
-- micro menu
do
	local createButton = function(name, ...)
		local button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate") 
		button:SetAttribute("type", "click")
		button:SetSize(30, 36) -- 20,24
		
		local icon = button:CreateTexture(name .. "Icon", "BACKGROUND")
		icon:SetTexCoord(6/32, 26/32, 32/64, 56/64)
		icon:SetAllPoints()
		button.Icon = icon
		
		local pushed = button:CreateTexture(name .. "PushedTex", "OVERLAY")
		pushed:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		pushed:SetAllPoints()
		pushed:SetBlendMode("ADD")
		pushed:SetAlpha(0.5)
		button.PushedTex = pushed
		button:SetPushedTexture(pushed)
		
		local hover = button:CreateTexture(name .. "HoverTex", "OVERLAY")
		hover:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		hover:SetAllPoints()
		hover:SetBlendMode("ADD")
		hover:SetAlpha(0.5)
		button.HoverTex = hover
		button:SetHighlightTexture(hover)

		-- local checked = button:CreateTexture(name .. "CheckedTex", "OVERLAY")
		-- checked:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
		-- checked:SetAllPoints()
		-- checked:SetBlendMode("ADD")
		-- checked:SetAlpha(0.5)
		-- button.CheckedTex = checked
		-- button:SetCheckedTexture(checked)
		
		button:SetScript("OnEnter", function(self)
			if (self:IsEnabled() or self.minLevel or self.disabledTooltip or self.factionGroup) then
				GameTooltip:SetOwner(self, "ANCHOR_PRESERVE")
				GameTooltip:ClearAllPoints()
				if ((GetScreenWidth() - self:GetRight()) > self:GetLeft()) then 			-- object on left side
					if ((GetScreenHeight() - self:GetTop()) > self:GetBottom()) then
						GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 8, 8) 			-- bottom left side
					else 
						GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMRIGHT", 8, -8) 		-- top left side
					end
				else 																		-- object on right side
					if ((GetScreenHeight() - self:GetTop()) > self:GetBottom()) then 
						GameTooltip:SetPoint("BOTTOMRIGHT", self, "TOPLEFT", -8, 8) 		-- bottom right side
					else 
						GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMLEFT", -8, -8) 		-- top right side
					end
				end
				if ( SHOW_NEWBIE_TIPS == "1" ) then
					if (self.tooltipText) then
						GameTooltip:SetText(self.tooltipText, 1.0, 1.0, 1.0)
						GameTooltip:AddLine(self.newbieText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
					else
						GameTooltip:SetText(self.newbieText, 1.0, 1.0, 1.0, 1, 1)
					end
				else
					GameTooltip:SetText(self.tooltipText, 1.0, 1.0, 1.0)
				end
				if not(self:IsEnabled()) or (self.disabled) then
					if (self.factionGroup == "Neutral") then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(FEATURE_NOT_AVAILBLE_PANDAREN, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
					elseif (self.minLevel) then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, self.minLevel), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
					elseif (self.disabledTooltip) then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(self.disabledTooltip, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
					end
				end
				GameTooltip:Show()
			end
		end)

		button:SetScript("OnLeave", function(self) 
			GameTooltip:Hide()
		end)

		-- set additional attributes
		for i = 1, select("#", ...), 2 do
			local attribute, value = select(i, ...)
			if not(attribute) then break end
			button:SetAttribute(attribute, value)
		end
	
		_G[name] = button
		
		return button
	end

	-- character
	do
		local button = createButton("GAB_MicroButton1", "type", "macro", "macrotext", "/run ToggleCharacter('PaperDollFrame')")
		button.Portrait = button:CreateTexture(button:GetName() .. "Portrait", "BORDER")
		button.Portrait:SetSize(button:GetSize())
		button.Portrait:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
		button.Portrait:SetAllPoints()
		button.tooltipText = MicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0")
		button.newbieText = NEWBIE_TOOLTIP_CHARACTER
		button.bindAction = "TOGGLECHARACTER0"
		button:RegisterEvent("UNIT_PORTRAIT_UPDATE")
		button:RegisterEvent("UPDATE_BINDINGS")
		button:RegisterEvent("PLAYER_ENTERING_WORLD")
		-- button:SetScript("OnMouseDown", function(self) 
			-- if ( self.down ) then
				-- self.down = nil
				-- ToggleCharacter("PaperDollFrame")
				-- return
			-- end
			-- self.down = 1
		-- end)
		-- button:SetScript("OnMouseUp", function(self) 
			-- if ( self.down ) then
				-- self.down = nil
				-- if ( self:IsMouseOver() ) then
					-- ToggleCharacter("PaperDollFrame")
				-- end
				-- return
			-- end
			-- if ( self:GetButtonState() == "NORMAL" ) then
				-- self.down = 1
			-- else
				-- self.down = 1
			-- end
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if ( event == "UNIT_PORTRAIT_UPDATE" ) then
				local unit = ...
				if ( not unit or unit == "player" ) then
					SetPortraitTexture(self.Portrait, "player")
				end
				return
			elseif ( event == "PLAYER_ENTERING_WORLD" ) then
				SetPortraitTexture(self.Portrait, "player")
				
			elseif ( event == "UPDATE_BINDINGS" ) then
				self.tooltipText = MicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0")
			end
		end)
	end
	
	-- spellbook
	do
		local button = createButton("GAB_MicroButton2", "clickbutton", SpellbookMicroButton)
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-Spellbook-Up")
		button.bindAction = "TOGGLESPELLBOOK"
		button.newbieText = NEWBIE_TOOLTIP_SPELLBOOK
		button.tooltipText = MicroButtonTooltipText(SPELLBOOK_ABILITIES_BUTTON, "TOGGLESPELLBOOK")
		-- button:SetScript("OnClick", function(self) 
			-- ToggleSpellBook(BOOKTYPE_SPELL)
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			self.tooltipText =  MicroButtonTooltipText(SPELLBOOK_ABILITIES_BUTTON, "TOGGLESPELLBOOK")
		end)
	end
	
	-- talents
	do
		local button = createButton("GAB_MicroButton3", "clickbutton", TalentMicroButton)
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		-- button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button:RegisterEvent("PLAYER_LEVEL_UP")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-Talents-Up")
		button.tooltipText = MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS")
		button.newbieText = NEWBIE_TOOLTIP_TALENTS
		button.bindAction = "TOGGLETALENTS" 
		button.minLevel = SHOW_SPEC_LEVEL
		if (button.minLevel > UnitLevel("player")) then
			button.disabled = true
			-- button:SetAttribute("_softdisabled", true)
			button.Icon:SetAlpha(0.5)
			SetDesaturation(button.Icon, true)
		end
		-- button:SetScript("OnClick", function(self) 
			-- if not(self:IsEnabled()) or (self.disabled) then return end
			-- ToggleTalentFrame()
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if (event == "PLAYER_LEVEL_UP") and (UnitLevel("player") >= self.minLevel) then
				self.disabled = nil
				self.Icon:SetAlpha(1)
				SetDesaturation(self.Icon, false)
			end
			self.tooltipText =  MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS")
		end)
	end
	
	-- achievements
	do
		local button = createButton("GAB_MicroButton4", "clickbutton", AchievementMicroButton)
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		--button:RegisterEvent("RECEIVED_ACHIEVEMENT_LIST")
		--button:RegisterEvent("ACHIEVEMENT_EARNED")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-Achievement-Up")
		button.tooltipText = MicroButtonTooltipText(ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT")
		button.newbieText = NEWBIE_TOOLTIP_ACHIEVEMENT
		button.bindAction = "TOGGLEACHIEVEMENT" 
		-- button:SetScript("OnClick", function(self) 
			-- ToggleAchievementFrame()
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if ( event == "UPDATE_BINDINGS" ) then
				self.tooltipText = MicroButtonTooltipText(ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT")
			end
		end)
	end

	-- questlog
	do
		local button = createButton("GAB_MicroButton5", "clickbutton", QuestLogMicroButton)
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		--button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-Quest-Up")
		button.tooltipText = MicroButtonTooltipText(QUESTLOG_BUTTON, "TOGGLEQUESTLOG")
		button.newbieText = NEWBIE_TOOLTIP_QUESTLOG
		button.bindAction = "TOGGLEQUESTLOG" 
		-- button:SetScript("OnClick", function(self) 
			-- ToggleFrame(QuestLogFrame)
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if ( event == "UPDATE_BINDINGS" ) then
				self.tooltipText = MicroButtonTooltipText(QUESTLOG_BUTTON, "TOGGLEQUESTLOG")
			end
		end)
	end

	-- guild
	do
		local button = createButton("GAB_MicroButton6", "clickbutton", GuildMicroButton)
		button.background = button:CreateTexture(button:GetName() .. "Background", "ARTWORK")
		button.background:SetTexture("Interface\\Buttons\\UI-MicroButton-Guild-Banner")
		button.background:SetPoint("CENTER")
		button.emblem = button:CreateTexture(button:GetName() .. "Emblem")
		button.emblem:SetDrawLayer("OVERLAY", 1)
		button.emblem:SetTexture("Interface\\GuildFrame\\GuildEmblems_01")
		button.emblem:SetPoint("CENTER")
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button.OnSizeChanged = function(self, width, height) 
			if not(width) or not(height) then
				width, height = self:GetSize()
			end
			self.background:SetSize(width * 1.5, height * 2.2)
			self.background:SetPoint("CENTER", 0, height/3)
			self.emblem:SetSize(width * 2/3, width * 2/3)
		end
		button:HookScript("OnSizeChanged", button.OnSizeChanged)
		button:OnSizeChanged() -- initial size adjustment
		button:RegisterEvent("UPDATE_BINDINGS")
		button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button:RegisterEvent("PLAYER_GUILD_UPDATE")
		button:RegisterEvent("GUILDTABARD_UPDATE")
		button:RegisterEvent("PLAYER_ENTERING_WORLD")
		button.tooltipText = MicroButtonTooltipText(LOOKINGFORGUILD, "TOGGLEGUILDTAB")
		button.newbieText = NEWBIE_TOOLTIP_LOOKINGFORGUILDTAB
		button.bindAction = "TOGGLEGUILDTAB" 
		button.factionGroup = UnitFactionGroup("player")
		if (IsTrialAccount()) then
			button.disabled = true
			button.Icon:SetAlpha(0.5)
			SetDesaturation(button.Icon, true)
			button.disabledTooltip = ERR_RESTRICTED_ACCOUNT
		elseif (button.factionGroup) and (button.factionGroup == "Neutral") then
			button.disabled = true
			button.Icon:SetAlpha(0.5)
			SetDesaturation(button.Icon, true)
		end
		-- button:SetScript("OnClick", function(self) 
			-- if not(self:IsEnabled()) or (self.disabled) then return end
			-- ToggleGuildFrame()
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if (event == "NEUTRAL_FACTION_SELECT_RESULT") then
				self.disabled = nil
				self.Icon:SetAlpha(1)
				SetDesaturation(self.Icon, false)
			end
			local bkgR, bkgG, bkgB, borderR, borderG, borderB, emblemR, emblemG, emblemB, emblemFilename = GetGuildLogoInfo("player")
			if (emblemFilename) and (IsInGuild()) then
				self.Icon:SetTexture("") 
				self.emblem:Show()
				self.background:Show()
				SetSmallGuildTabardTextures("player", self.emblem, self.background)
			else
				self.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-Socials-Up")
				self.emblem:Hide()
				self.background:Hide()
			end
			if IsInGuild() then 
				self.tooltipText = MicroButtonTooltipText(GUILD, "TOGGLEGUILDTAB")
			else
				self.tooltipText = MicroButtonTooltipText(LOOKINGFORGUILD, "TOGGLEGUILDTAB")
			end
		end)
	end

	-- pvp
	do
		local is520 = tonumber((select(2, GetBuildInfo()))) >= 16650
		local TogglePVPFrame = is520 and "TogglePVPUI" or "TogglePVPFrame"
		local button = createButton("GAB_MicroButton7", "type", "macro", "macrotext", "/run "..TogglePVPFrame.."()")
		button:RegisterEvent("UPDATE_BINDINGS")
		button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button:RegisterEvent("PLAYER_ENTERING_WORLD")
		button:RegisterEvent("PLAYER_LEVEL_UP")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-Character-Up")
		button.factionGroup = UnitFactionGroup("player")
		button.tooltipText = MicroButtonTooltipText(PLAYER_V_PLAYER, "TOGGLECHARACTER4")
		button.newbieText = NEWBIE_TOOLTIP_PVP
		button.minLevel = SHOW_PVP_LEVEL
		button.bindAction = "TOGGLECHARACTER4" 
		if ((button.factionGroup) and (button.factionGroup == "Neutral")) or (button.minLevel > UnitLevel("player")) then
			button.disabled = true
			button.Icon:SetAlpha(0.5)
			SetDesaturation(button.Icon, true)
		end
		-- button:SetScript("OnMouseDown", function(self) 
			-- if not(self:IsEnabled()) or (self.disabled) then return end
			-- if ( self.down ) then
				-- self.down = nil
				-- TogglePVPFrame()
				-- return
			-- end
			-- self.down = 1
		-- end)
		-- button:SetScript("OnMouseUp", function(self) 
			-- if not(self:IsEnabled()) or (self.disabled) then return end
			-- if ( self.down ) then
				-- self.down = nil
				-- if ( self:IsMouseOver() ) then
					-- TogglePVPFrame()
				-- end
				-- return
			-- end
			-- if ( self:GetButtonState() == "NORMAL" ) then
				-- self.down = 1
			-- else
				-- self.down = 1
			-- end
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			self.factionGroup = nil
			self.factionGroup = UnitFactionGroup("player")
			if (event == "NEUTRAL_FACTION_SELECT_RESULT") or (event == "PLAYER_LEVEL_UP") and (UnitLevel("player") >= self.minLevel) then
				self.disabled = nil
				self.Icon:SetAlpha(1)
				SetDesaturation(self.Icon, false)
			end
			if (self.factionGroup) and (self.factionGroup == "Horde" or self.factionGroup == "Alliance") then
				self.Icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. self.factionGroup)
			else
				self.Icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
			end
			if (self.factionGroup) and (self.factionGroup == "Horde") then
				self.Icon:SetTexCoord(1/64, 40/64, 1/64, 38/64)
			elseif (self.factionGroup) and (self.factionGroup == "Alliance") then
				self.Icon:SetTexCoord(5/64, 36/64, 2/64, 39/64)
			else
				self.Icon:SetTexCoord(5/64, 36/64, 2/64, 39/64)
			end
			if (self.disabled) then
				SetDesaturation(self.Icon, true)
			end	
			self.tooltipText = MicroButtonTooltipText(PLAYER_V_PLAYER, "TOGGLECHARACTER4")
		end)
	end

	-- LFD
	do
		local button = createButton("GAB_MicroButton8", "clickbutton", LFDMicroButton)
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button:RegisterEvent("PLAYER_LEVEL_UP")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-LFG-Up")
		button.tooltipText = MicroButtonTooltipText(DUNGEONS_BUTTON, "TOGGLELFGPARENT")
		button.newbieText = NEWBIE_TOOLTIP_LFGPARENT
		button.minLevel = SHOW_LFD_LEVEL
		button.bindAction = "TOGGLELFGPARENT" 
		if (button.minLevel > UnitLevel("player")) then
			button.disabled = true
			button.Icon:SetAlpha(0.5)
			SetDesaturation(button.Icon, true)
		end
		-- button:SetScript("OnClick", function(self) 
			-- if not(self:IsEnabled()) or (self.disabled) then return end
			-- PVEFrame_ToggleFrame()
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if (event == "PLAYER_LEVEL_UP") and (UnitLevel("player") >= self.minLevel) then
				self.disabled = nil
				self.Icon:SetAlpha(1)
				SetDesaturation(self.Icon, false)
			elseif ( event == "UPDATE_BINDINGS" ) then
				self.tooltipText = MicroButtonTooltipText(DUNGEONS_BUTTON, "TOGGLELFGPARENT")
			end
		end)
	end

	-- companions and mounts
	do
		local button = createButton("GAB_MicroButton9", "clickbutton", CompanionsMicroButton)
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-Mounts-Up")
		button.tooltipText = MicroButtonTooltipText(MOUNTS_AND_PETS, "TOGGLEPETJOURNAL")
		button.newbieText = NEWBIE_TOOLTIP_MOUNTS_AND_PETS
		button.bindAction = "TOGGLEPETJOURNAL" 
		-- button:SetScript("OnClick", function(self) 
			-- TogglePetJournal()
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if ( event == "UPDATE_BINDINGS" ) then
				self.tooltipText = MicroButtonTooltipText(MOUNTS_AND_PETS, "TOGGLEPETJOURNAL")
			end
		end)
	end

	-- encounter journal
	do
		local button = createButton("GAB_MicroButton10", "clickbutton", EJMicroButton)
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button:RegisterEvent("PLAYER_LEVEL_UP")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-EJ-Up")
		button.tooltipText = MicroButtonTooltipText(ENCOUNTER_JOURNAL, "TOGGLEENCOUNTERJOURNAL")
		button.newbieText = NEWBIE_TOOLTIP_ENCOUNTER_JOURNAL
		button.minLevel = SHOW_LFD_LEVEL
		button.bindAction = "TOGGLEENCOUNTERJOURNAL" 
		if (button.minLevel > UnitLevel("player")) then
			button.disabled = true
			button.Icon:SetAlpha(0.5)
			SetDesaturation(button.Icon, true)
		end
		-- button:SetScript("OnClick", function(self) 
			-- if not(self:IsEnabled()) or (self.disabled) then return end
			-- ToggleEncounterJournal()
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if (event == "PLAYER_LEVEL_UP") and (UnitLevel("player") >= self.minLevel) then
				self.disabled = nil
				self.Icon:SetAlpha(1)
				SetDesaturation(self.Icon, false)
			elseif ( event == "UPDATE_BINDINGS" ) then
				self.tooltipText = MicroButtonTooltipText(ENCOUNTER_JOURNAL, "TOGGLEENCOUNTERJOURNAL")
			end
		end)
	end

	-- game menu
	do
		local button = createButton("GAB_MicroButton11")
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-MainMenu-Up")
		button.tooltipText = MicroButtonTooltipText(MAINMENU_BUTTON, "TOGGLEGAMEMENU")
		button.newbieText = NEWBIE_TOOLTIP_MAINMENU
		button.bindAction = "TOGGLEGAMEMENU" 
		button.hover = nil
		button:RegisterForClicks("LeftButtonDown", "RightButtonDown", "LeftButtonUp", "RightButtonUp")
		button:SetScript("OnMouseDown", function(self) 
			if ( self.down ) then
				self.down = nil -- I'm pretty sure none of this should ever get run.
				if ( not GameMenuFrame:IsShown() ) then
					if ( VideoOptionsFrame:IsShown() ) then
						VideoOptionsFrameCancel:Click()
					elseif ( AudioOptionsFrame:IsShown() ) then
						AudioOptionsFrameCancel:Click()
					elseif ( InterfaceOptionsFrame:IsShown() ) then
						InterfaceOptionsFrameCancel:Click()
					end		
					CloseMenus()
					CloseAllWindows()
					PlaySound("igMainMenuOpen")
					ShowUIPanel(GameMenuFrame)
				else
					PlaySound("igMainMenuQuit")
					HideUIPanel(GameMenuFrame)
				end
				return
			end
			self.down = 1
		end)
		button:SetScript("OnMouseUp", function(self) 
			if ( self.down ) then
				self.down = nil
				if ( self:IsMouseOver() ) then
					if ( not GameMenuFrame:IsShown() ) then
						if ( VideoOptionsFrame:IsShown() ) then
							VideoOptionsFrameCancel:Click()
						elseif ( AudioOptionsFrame:IsShown() ) then
							AudioOptionsFrameCancel:Click()
						elseif ( InterfaceOptionsFrame:IsShown() ) then
							InterfaceOptionsFrameCancel:Click()
						end						
						CloseMenus()
						CloseAllWindows()
						PlaySound("igMainMenuOpen")
						ShowUIPanel(GameMenuFrame)
					else
						PlaySound("igMainMenuQuit")
						HideUIPanel(GameMenuFrame)
					end
				end
				return
			end
			if ( self:GetButtonState() == "NORMAL" ) then
				self.down = 1
			else
				self.down = 1
			end
		end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if ( event == "UPDATE_BINDINGS" ) then
				self.tooltipText = MicroButtonTooltipText(MAINMENU_BUTTON, "TOGGLEGAMEMENU")
			end
		end)
	end

	-- help
	do
		local button = createButton("GAB_MicroButton12", "clickbutton", HelpMicroButton)
		-- button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterEvent("UPDATE_BINDINGS")
		button:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
		button.Icon:SetTexture("Interface\\Buttons\\UI-MicroButton-Help-Up")
		button.tooltipText = MicroButtonTooltipText(HELP_BUTTON, "GUISTOGGLECUSTOMERSUPPORT")
		button.newbieText = NEWBIE_TOOLTIP_HELP
		button.bindAction = "GUISTOGGLECUSTOMERSUPPORT" -- no blizzard action for this yet
		-- button:SetScript("OnClick", function(self) 
			-- ToggleHelpFrame()
		-- end)
		button:SetScript("OnEvent", function(self, event, ...) 
			if ( event == "UPDATE_BINDINGS" ) then
				self.tooltipText = MicroButtonTooltipText(HELP_BUTTON, "GUISTOGGLECUSTOMERSUPPORT")
			end
		end)
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Shared Functions
------------------------------------------------------------------------------------------------------------
--
-- create a new virtual bar with a parent and a granny for visibility handling
-- somehow this all seems crazy to me. I couldn't find any better way? I'm mental. Totally.
local New = function(name)
	-- the grannybar handles manual show/hides. this is the master bar, and remains usercontrolled at all times
	local granny = CreateFrame("Frame", MAJOR .. "_BarPool_" .. name .. "_GrandParent", UIParent, "SecureHandlerStateTemplate")
	granny:SetFrameStrata("LOW")
	granny:SetFrameLevel(50) -- give us some air

	-- the parent bar handles vehicle/posses/petbattle hiding
	-- this bar is NOT usercontrolled, and subject to whatever it's "type" attribute is
	local parent = CreateFrame("Frame", MAJOR .. "_BarPool_" .. name .. "_Parent", granny, "SecureHandlerStateTemplate")

	-- the actual bar is the one we'll do hover stuff with, this is also the one that changes state based on ...states...
	local bar = CreateFrame("Frame", MAJOR .. "_BarPool_" .. name, parent, "SecureHandlerStateTemplate")
	
	return bar
end

-- execute a function if not in combat, abort otherwise
local safeCall = function(func, ...)
	if not(InCombatLockdown()) then
		return func(...)
	end
end

-- execute a function if not in combat, queue it up for combat end otherwise
local safeQueueCall = function(func, ...)
	if (InCombatLockdown()) then
		tinsert(gAB.queue, { func = func, arg = { ... } })
	else
		func(...)
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Bar
------------------------------------------------------------------------------------------------------------
local Show, Hide, SetShown, IsShown, SetPoint, ClearAllPoints, SetAllPoints
local SetVisibility, RegisterStateDriver, UnregisterStateDriver, GetStateDriver
local SetAttribute, GetAttribute, SetID, GetID, GetName, GetBar
local SetWidth, SetHeight, SetSize, GetWidth, GetHeight, GetSize
local Update, UpdateButtons, UpdateLayout, UpdateStates
local AssignButton, ReleaseButton

-- bunch of proxy functions for the real bar
do
	-- secure calls
	ClearAllPoints = function(self) safeCall(self.bar.ClearAllPoints, self.bar) end

	local setPoint = function(self, ...)
		self:GetBar():SetPoint(...)
		gAB.scheduler:FireCallback("GAB_ACTIONBAR_POSITION_UPDATE", self:GetName())
	end
	SetPoint = function(self, ...) safeCall(setPoint, self, ...) end

	local setAllPoints = function(self, ...)
		self:GetBar():SetAllPoints(...)
		gAB.scheduler:FireCallback("GAB_ACTIONBAR_POSITION_UPDATE", self:GetName())
	end
	SetAllPoints = function(self, ...) safeCall(setAllPoints, self, ...) end
	
	SetID = function(self, ...) safeCall(self.bar.SetID, self.bar, ...) end

	local setWidth = function(self, ...)
		self:GetBar():SetWidth(...)
		gAB.scheduler:FireCallback("GAB_ACTIONBAR_LAYOUT_UPDATE", self:GetName())
	end
	SetWidth = function(self, ...) safeCall(setWidth, self, ...) end

	local setHeight = function(self, ...)
		self:GetBar():SetHeight(...)
		gAB.scheduler:FireCallback("GAB_ACTIONBAR_LAYOUT_UPDATE", self:GetName())
	end
	SetHeight = function(self, ...) safeCall(setHeight, self, ...) end

	local setSize = function(self, ...)
		self:GetBar():SetSize(...)
		gAB.scheduler:FireCallback("GAB_ACTIONBAR_LAYOUT_UPDATE", self:GetName())
	end
	SetSize = function(self, ...) safeCall(setSize, self, ...) end

	-- safe by definition
	GetID = function(self) return self.bar:GetID() end
	GetWidth = function(self) return self.bar:GetWidth() end
	GetHeight = function(self) return self.bar:GetHeight() end
	GetSize = function(self) return self.bar:GetSize() end
end

-- the following all affect the parent whose main role is visibility handling
do
	-- granny to the rescue!
	Show = function(self) safeCall(self.bar:GetParent():GetParent().Show, self.bar:GetParent():GetParent()) end
	Hide = function(self) safeCall(self.bar:GetParent():GetParent().Hide, self.bar:GetParent():GetParent()) end
	SetShown = function(self, ...) safeCall(self.bar:GetParent():GetParent().SetShown, self.bar:GetParent():GetParent(), ...) end
	IsShown = function(self) return self.bar:GetParent():GetParent():IsShown() end

	local getBarFromState = function(self, state)
		return state == "page" and self.bar or self.bar:GetParent()
	end
	
	-- daddy doing his thing
	RegisterStateDriver = function(self, state, driver)
		if (InCombatLockdown()) then
			return
		end
		local oldDriver = self:GetStateDriver(state)
		if (oldDriver) then
			-- abort if an identical state driver already exists
			if (oldDriver == driver) then
				return
			end
			-- unregister any previous driver
			self:UnregisterStateDriver(state)
		end
		_G.RegisterStateDriver(getBarFromState(self, state), state, driver)
		self.drivers[state] = driver
	end

	UnregisterStateDriver = function(self, state)
		if (InCombatLockdown()) then
			return
		end
		if not(self:GetStateDriver(state)) then
			return
		end
		_G.UnregisterStateDriver(getBarFromState(self, state), state)
		self.drivers[state] = nil
	end

	GetStateDriver = function(self, state)
		return self.drivers[state]
	end

	-- visibility handler
	-- only affects each bar's parent bar, and does not interfere with internal state handling 
	--
	-- bar:SetVisibility(visible[, hideOnVehicle, hideOnPetbattle, hideOnOverride])
	--		@param visible <boolean> 'true' to show the frame, 'false' or 'nil' to always hide
	-- 	@param hideOnVehicle <boolean> 'true' to hide the bar when entering a vehicle
	-- 	@param hideOnPetbattle <boolean> 'true' to hide the bar when entering pet battle
	-- 	@param hideOnOverride <boolean> 'true' to hide the bar when overridebar (possess etc) is visible
	SetVisibility = function(self, visible, hideOnVehicle, hideOnPetbattle, hideOnOverride, hideOnPossess)
		argCheck(visible, 1, "boolean", "nil")
		argCheck(hideOnVehicle, 2, "boolean", "nil")
		argCheck(hideOnPetbattle, 3, "boolean", "nil")
		argCheck(hideOnOverride, 4, "boolean", "nil")
		argCheck(hideOnPossess, 5, "boolean", "nil")
		local macro
		if (visible) then
			if (hideOnVehicle) then macro = (macro or "") .. "[vehicleui]" end
			if (hideOnPetbattle) then macro = (macro or "") .. "[petbattle]" end
			if (hideOnOverride) then macro = (macro or "") .. "[overridebar]" end
			if (hideOnPossess) then macro = (macro or "") .. "[possessbar]" end
			if (macro) then
				macro = macro .. " hide; show"
			else
				macro = "show"
			end
		else
			macro = "hide"
		end
		self:RegisterStateDriver("visibility", macro)
	end
	
	GetName = function(self)
		return self:GetAttribute("name")
	end
end

-- layout and hover functionality for the real bar
do
	local IsMouseOver = function(self)
		if (MouseIsOver(self)) or ((SpellFlyout:IsShown()) and (SpellFlyout:GetParent()) and (SpellFlyout:GetParent():GetParent() == self) and (MouseIsOver(SpellFlyout))) then
			return true
		end
		return false
	end
	
	local Fade = function(self, elapsed)
		if (IsMouseOver(self)) then
			if (self.fading) or (self.faded) then
				self.faded = nil
				self.fading = 0
				self:SetAlpha(1)
			end
		else
			if not(self.faded) then
				self.fading = self.fading + elapsed
				if (self.fading >= self.fadeDelay) then
					if ((self.fading - self.fadeDelay) >= self.fadeDuration) then
						self.fading = nil
					else
						self:SetAlpha(1 - (self.fading - self.fadeDelay)/self.fadeDuration)
					end
				end
			end
			
			if not(self.fading) and not(self.faded) then
				self:SetAlpha(0)
				self.faded = true
			end
			
		end
	end

	local OnUpdate = function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if (self.elapsed > 0.01) then
			Fade(self, self.elapsed)
			self.elapsed = 0
		end
	end

	-- attributes that can't be manipulated directly
	local restrictedAttributes = { 
		type = true;
		name = true;
	}
	
	-- virtual bar attribute handling
	SetAttribute = function(self, attribute, value) 
		argCheck(attribute, 1, "string")
		if (self.created) and (restrictedAttributes[attribute]) then
			error(("Restricted attribute! You can not change the attribute '%s' in bar '%s' after creation"):format(attribute, self:GetName() or "undefined"), 2)
		end
		self.attributes[attribute] = value 
		if (attribute == "fade") then
			local bar = self:GetBar()
			if (value) then 
				bar.fadeDuration = tonumber(value) or 0.5
				bar.fadeDelay = 0.5
				bar.fading = 0
				bar:SetScript("OnUpdate", OnUpdate)
			else
				bar:SetScript("OnUpdate", nil)
				bar.faded = nil
				bar.fadeDuration = nil
				bar.fadeDelay = nil
				bar.fading = nil
				bar:SetAlpha(1)
			end
		elseif (attribute == "buttonsize") then
			-- if (self.created) then
				-- self:UpdateLayout()
			-- end
		end
	end
	
	GetAttribute = function(self, attribute) 
		argCheck(attribute, 1, "string")
		return self.attributes[attribute] 
	end

	-- a button is simply inserted at the end of the local button pool, regardless of index
	-- so make sure you assign buttons in the proper order, or the layout will be all wonky.
	-- This is INTENDED!
	AssignButton = function(self, index)
		argCheck(index, 1, "number")
		local parent = self:GetAttribute("type")

		-- failsafe for bars with unregistered buttons
		if not(buttons[parent]) then return end

		local name = buttons[parent].name
		local first, last = self:GetAttribute("firstbutton"), self:GetAttribute("lastbutton")
		if (index < first or index > last) then
			error(("Button index out of range. Must be between %d and %d, got %d"):format(first, last, index), 2)
		end
		
		local button = _G[name .. index]
		if not(button) then
			error(("Button not found: '%s'"):format(name .. index), 2)
		end
		
		if not(gAB.buttonPool[button]) then
			error(("Can't assign the button '%s' to the bar '%s'[%d]: Button already in use, release first!"):format(button:GetName(), self:GetName(), index), 2)
		end
		
		local bar = self:GetBar()
		button:SetParent(bar) -- parent the button to the real bar
		bar:SetAttribute("addchild", button)
		
		tinsert(self.buttons, button) -- assign it to local button pool
		gAB.buttonPool[button] = nil -- remove from global button pool
		
		return button
	end
	
	-- release a button based on its index in the button pool
	-- completely unrelated to the actual index of the button itself
	ReleaseButton = function(self, index)
		argCheck(index, 1, "number")
		local button = self.buttons[index]
		if (button) then
			self.buttons[index] = nil -- remove from local button pool
			gAB:ReleaseButton(button) -- return to the global pool
		end
		return button
	end
	
	-- assign/free buttons to a bar
	UpdateButtons = function(self) 
		local parent = self:GetAttribute("type")

		-- failsafe for bars with unregistered buttons
		if not(buttons[parent]) then return end
		
		local name = buttons[parent].name
		local first, last = self:GetAttribute("firstbutton"), self:GetAttribute("lastbutton")
		if (first > last) then 
			error(("Firstbutton must have an index between 1 and %d, got #d"):format(last,first), 2)
		end
		
		local width = self:GetAttribute("width")
		local height = self:GetAttribute("height")
		local last = min(last, first + width*height - 1) -- in case our layout has room for more buttons than exist
		
		for i = 1, #self.buttons do self:ReleaseButton(i) end -- release all existing buttons
		for i = first, last do self:AssignButton(i) end -- assign new buttons
		
		gAB.scheduler:FireCallback("GAB_ACTIONBAR_BUTTON_UPDATE", self:GetName())
	end

	-- update the bar and its buttons
	UpdateLayout = function(self) 
		if not self then return end -- shouldn't happen, but it does
		-- if we're somehow in combat (which shouldn't happen), we queue this very function and leave
		if (InCombatLockdown()) then
			safeQueueCall(UpdateLayout, self)
			return
		end
	
		local width = self:GetAttribute("width")
		local height = self:GetAttribute("height")
		local x, y
		if (self:GetAttribute("type") == "micro") then -- these aren't square
			x, y = self:GetAttribute("buttonsize") * 5/6, self:GetAttribute("buttonsize")
		else
			x, y = self:GetAttribute("buttonsize"), self:GetAttribute("buttonsize")
		end
		local gap = self:GetAttribute("gap")
		local down = self:GetAttribute("growth-y") == "down"
		local right = self:GetAttribute("growth-x") == "right"
		
		local oldButtonSizeX, oldButtonSizeY = self.buttons[1]:GetSize()
		local oldWidth, oldHeight = self:GetSize()
		local newWidth, newHeight = width * (x + gap) - gap, height * (y + gap) - gap
	
		if (newWidth ~= oldWidth) or (newHeight ~= oldHeight) then
			self:SetSize(newWidth, newHeight) 
		end
	
		local button
		local current = 1
		while (current <= #self.buttons) do
			button = self.buttons[current]
			button:SetSize(x, y)
			button:ClearAllPoints()
			if (current == 1) then
				-- if (self:GetAttribute("type") == "shift") and (not self.fixShift) then
					-- local down, right = down, right
					-- self.fixShift = function() 
						-- ShapeshiftButton1:ClearAllPoints()
						-- ShapeshiftButton1:SetPoint((down and "TOP" or "BOTTOM") .. (right and "LEFT" or "RIGHT"), self, 0, 0)
					-- end
					-- hooksecurefunc("ShapeshiftBar_Update", self.fixShift)
				-- end
				button:ClearAllPoints()
				button:SetPoint((down and "TOP" or "BOTTOM") .. (right and "LEFT" or "RIGHT"), self:GetBar(), 0, 0)
				
			elseif ((current-1) % width == 0) then
				button:ClearAllPoints()
				button:SetPoint(down and "TOP" or "BOTTOM", self.buttons[current-width], down and "BOTTOM" or "TOP", 0, down and -gap or gap)	
			else
				button:ClearAllPoints()
				button:SetPoint(right and "LEFT" or "RIGHT", self.buttons[current-1], right and "RIGHT" or "LEFT", right and gap or -gap, 0)
			end
			current = current + 1
		end
		
		if (newWidth ~= oldWidth) or (newHeight ~= oldHeight) or (oldButtonSizeX ~= x) or (oldButtonSizeY ~= y) then
			gAB.scheduler:FireCallback("GAB_ACTIONBAR_BUTTON_UPDATE", self:GetName())
		end
	end

	UpdateStates = function(self)
		if not(self.IsStateBar) then return end

		local bar = self:GetBar()
		local button
		for i = 1, #self.buttons do
			button = self.buttons[i]
			-- except for this, the script is identical to the original blizzard script in FrameXML\ActionBarFrame.xml
			button:SetScript("OnDragStart", function(self) 
				if (InCombatLockdown()) or not(editable[self]) then return end
				if ((LOCK_ACTIONBAR ~= "1") or (IsModifiedClick("PICKUPACTION"))) then
					SpellFlyout:Hide()
					PickupAction(self.action)
					ActionButton_UpdateState(self)
					ActionButton_UpdateFlash(self)
				end
			end)
			bar:SetFrameRef(button:GetName(), button)
		end

		local execute = [[ buttons = table.new(); ]]
		for i = 1, #self.buttons do
			execute = execute .. ([[ table.insert(buttons, self:GetFrameRef("%s")); ]]):format(self.buttons[i]:GetName())
		end
		
		bar:Execute(execute)
		bar:SetAttribute("_onstate-page", [[ 
			for i, button in ipairs(buttons) do 
				button:SetAttribute("actionpage", tonumber(newstate))
			end
		]])
		
		self:RegisterStateDriver("page", getStateDriver(self:GetAttribute("type"), self:GetAttribute("stancemagic")))
	end
	
end

-- use this one with caution, preferably only with gFrameHandler-2.0
GetBar = function(self)
	return self.bar
end

------------------------------------------------------------------------------------------------------------
-- 	Library API
------------------------------------------------------------------------------------------------------------
local dummy = CreateFrame("Frame"); dummy:Hide() -- dummy bar for taintfree hiding
-- this function MUST be called prior to PLAYER_LOGIN, or chaos will ensue!
gAB.Start = function(self)
	for i, f in pairs({
			IconIntroTracker,
			StanceBarLeft; 
			StanceBarMiddle; 
			StanceBarRight;
			StanceBarFrame;
			MainMenuBar; 
			MainMenuBarArtFrame; 
			PetActionBarFrame; 
			PossessBarFrame; 
			OverrideActionBar; 
			
			-- these two alerts makes no sense with our actionbars
			CompanionsMicroButtonAlert;
			TalentMicroButtonAlert;

			-- leave this in until we've rewritten the ExtraActionBar controller
			-- ActionBarController; 
			
		}) do
		if (f.RegisterEvent) then
			f:UnregisterAllEvents()
		end
		f:SetParent(dummy)
		f.ignoreFramePositionManager = true
	end
	
	-- we don't need all these events, as they are all handled by our main bar page switcher
	-- we only need (currently) the ExtraActionBarFrame-related events
	--
	-- ActionBarController:UnregisterAllEvents()
	-- ActionBarController:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
	
	-- prevent override and vehicle from being activated
	-- 	*the chain ActionBarController_UpdateAll - OverrideActionBar_Setup must be prevented
	ActionBarController:UnregisterEvent("PLAYER_ENTERING_WORLD")
	ActionBarController:UnregisterEvent("ACTIONBAR_PAGE_CHANGED")
	ActionBarController:UnregisterEvent("UPDATE_BONUS_ACTIONBAR")
	ActionBarController:UnregisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	ActionBarController:UnregisterEvent("UPDATE_OVERRIDE_ACTIONBAR")

	-- don't need vehicle power updated 
	ActionBarController:UnregisterEvent("UNIT_DISPLAYPOWER")

	-- prevent stance- and posses from being activated
	ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_FORMS")
	ActionBarController:UnregisterEvent("UPDATE_SHAPESHIFT_USABLE")
	ActionBarController:UnregisterEvent("UPDATE_POSSESS_BAR")
	ActionBarController:UnregisterEvent("UPDATE_INVENTORY_ALERTS")

	MainMenuBar.slideOut.IsPlaying = noop -- kill off animations
	SetCVar("alwaysShowActionBars", 1) -- avoid buttons getting hidden

	for i = 1, NUM_OVERRIDE_BUTTONS do 
		local b = _G["OverrideActionBarButton" .. i]
		b:UnregisterAllEvents()
		b:SetAttribute("statehidden", 1)
		b:Hide()
	end

	-- sometimes the main bar keybinds will break after a talent change, 
	-- this is an attempt to remedy that situation
	local fixKeybinds = function() 
		if (PlayerTalentFrame) then
			PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		end
	end
	fixKeybinds()
	hooksecurefunc("TalentFrame_LoadUI", fixKeybinds)

	-- assign all the buttons in the universe to our pool
	-- warning: this deactives the blizzard actionbars completely! 
	local button
	for bar, v in pairs(buttons) do
		for i = 1, v.num do
			self:ReleaseButton(_G[v.name .. i]) 
		end
	end
	
	self.scheduler:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.scheduler:FireCallback("GAB_LOADED")
end

-- parent a button to our invisible dummy, and return it to the pool
gAB.ReleaseButton = function(self, button)
	button:SetParent(dummy)
	gAB.buttonPool[button] = true
end

--
-- create a new virtual bar
--		*many virtual bars can share the 'parent'
-- 	*no virtual bar can have several 'parent's
-- 	*all buttons are decided by index and 'parent',
-- 		so changing 'parent' will free up ALL the buttons
--
-- local bar = gAB:New(name, parent, ...)
-- 	@param name <string> name of your virtual bar. can't have the same name as other bars
-- 	@param parent <string> name of the parent bar, can be any of the list above
-- 	@param ... pairs of values fed to :SetAttribute(attribute, value)
-- 	@return <table> pointer to the new actionbar
gAB.New = function(self, name, parent, ...)
	argCheck(name, 1, "string")
	argCheck(parent, 2, "string")
	
	if (self.bars[name]) then
		error(("A bar named '%s' already exists"):format(name), 2)
	end

	if not(buttons[parent]) then
		error(("Unknown parent bar '%s'"):format(parent), 2)
	end
	
	if (InCombatLockdown()) then
		error("You can't define actionbars when engaged in combat. Do it after 'ADDON_LOADED' but before 'PLAYER_LOGIN'!", 2)
	end
	
	-- the virtual bar object is neither secure nor insecure, as it is not a frame at all. 
	-- both the visible bar itself and its show/hide object are secure, though.
	local bar = {
		bar = New(name); -- the 'real' bar that responds to page switching, and is parent to the buttons
		drivers = {}; -- currently assigned state drivers (parent visibility bar)
		attributes = {}; -- currently assigned attributes
		buttons = {}; -- will hold indexes of currently assigned buttons
		Hide = Hide; -- manually hide the parent visibility bar (won't work when a visibility driver is present)
		Show = Show; -- manually show the parent visibility bar (won't work when a visibility driver is present)
		SetShown = SetShown;
		IsShown = IsShown;
		RegisterStateDriver = RegisterStateDriver; -- register a state driver for the parent visibility bar
		UnregisterStateDriver = UnregisterStateDriver; -- unregister a state driver from the parent visibility bar
		GetStateDriver = GetStateDriver; -- retrieve the current macro registered for a state
		SetVisibility = SetVisibility; -- set the visibility of the parent to the real bar, this registers a state driver
		SetAttribute = SetAttribute; -- set a private attribute for the virtual bar
		GetAttribute = GetAttribute; -- returns a private attribute from the virtual bar
		GetBar = GetBar; -- returns the frame object for the real bar. only use this with gFrameHandler-2.0
		SetPoint = SetPoint; -- sets a point of the real bar
		ClearAllPoints = ClearAllPoints; -- clear all points of the real bar
		SetAllPoints = SetAllPoints; -- sets all points of the real bar
		SetID = SetID; -- sets the ID of the real bar, mainly used when requesting a state driver for a "normal" bar 
		GetID = GetID; -- returns the ID of the real bar
		GetName = GetName;
		SetWidth = SetWidth;
		SetHeight = SetHeight;
		SetSize = SetSize;
		GetWidth = GetWidth;
		GetHeight = GetHeight;
		GetSize = GetSize;
		-- Update = Update; -- don't add this, let various bars do it themselves
		UpdateButtons = UpdateButtons; -- updates the bar's buttons, frees and assigns as needed
		UpdateLayout = UpdateLayout; -- updatates the bar's size, and re-arrange all its buttons
		AssignButton = AssignButton; -- assigns a button to the bar if available
		ReleaseButton = ReleaseButton; -- release a button to the pool
		UpdateStates = UpdateStates;
	}

	bar:SetAttribute("name", name)
	bar:SetAttribute("type", parent)
	bar:SetAttribute("hover", false) -- used for hoverbars only
	bar:SetAttribute("buttonsize", 29) 
	bar:SetAttribute("growth-x", "right")
	bar:SetAttribute("growth-y", "down")
	bar:SetAttribute("gap", 2)
	bar:SetAttribute("firstbutton", 1)
	bar:SetAttribute("lastbutton", buttons[parent].num)
	bar:SetAttribute("width", buttons[parent].num)
	bar:SetAttribute("height", 1)
	bar:SetAttribute("stancemagic", false)
	bar:SetID(nameToPage[parent]) -- 0 for all 'non-state' bars
	
	-- set additional attributes
	for i = 1, select("#", ...), 2 do
		local attribute, value = select(i, ...)
		if not(attribute) then break end
		bar:SetAttribute(attribute, value)
	end
	
	self.created = true -- indicates that initial attribute setup is DONE!
	
	if (parent == "shift") then -- parent is the stancebar
		bar:SetVisibility(true, true, true, true) -- hide on vehicle, petbattle and override
		
		local UpdateButtons = function()
			for i = 1, NUM_STANCE_SLOTS do
				local button = _G["StanceButton" .. i]
				local name = select(2, GetShapeshiftFormInfo(i))
				if (name) then
					button:Show()
				else
					button:Hide()
				end
			end
		end

		local StanceBarUpdate = function()
			local numForms = GetNumShapeshiftForms()
			local texture, name, isActive, isCastable
			local button, icon, cooldown
			local start, duration, enable
			for i = 1, NUM_STANCE_SLOTS do
				buttonName = "StanceButton" .. i
				button = _G[buttonName]
				icon = _G[buttonName.."Icon"]
				if i <= numForms then
					texture, name, isActive, isCastable = GetShapeshiftFormInfo(i)
					
					if not icon then return end
					
					icon:SetTexture(texture)
					
					cooldown = _G[buttonName.."Cooldown"]
					if texture then
						cooldown:SetAlpha(1)
					else
						cooldown:SetAlpha(0)
					end
					
					start, duration, enable = GetShapeshiftFormCooldown(i)
					CooldownFrame_SetTimer(cooldown, start, duration, enable)
					
					if isActive then
						StanceBarFrame.lastSelected = button:GetID()
						button:SetChecked(1)
					else
						button:SetChecked(0)
					end

					if isCastable then
						icon:SetVertexColor(1.0, 1.0, 1.0)
					else
						icon:SetVertexColor(0.4, 0.4, 0.4)
					end
				end
			end
		end
		
		StanceBarFrame.ignoreFramePositionManager = true
		StanceBarFrame:SetParent(bar:GetBar())
		StanceBarFrame:EnableMouse(false)

		local OnEvent = function(self, event, ...)
			if (event == "PLAYER_LOGIN") then
				safeQueueCall(UpdateButtons)
			elseif (event == "UPDATE_SHAPESHIFT_FORMS") then
				safeQueueCall(UpdateButtons)
			-- elseif (event == "PLAYER_ENTERING_WORLD") then
				-- StanceBarUpdate()
			else
				StanceBarUpdate()
			end
		end
		
		bar:GetBar():RegisterEvent("PLAYER_LOGIN")
		bar:GetBar():RegisterEvent("PLAYER_ENTERING_WORLD")
		bar:GetBar():RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
		bar:GetBar():RegisterEvent("UPDATE_SHAPESHIFT_USABLE")
		bar:GetBar():RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
		bar:GetBar():RegisterEvent("UPDATE_SHAPESHIFT_FORM")
		bar:GetBar():RegisterEvent("ACTIONBAR_PAGE_CHANGED")
		bar:GetBar():RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		bar:GetBar():RegisterEvent("PLAYER_LEVEL_UP") 
		bar:GetBar():SetScript("OnEvent", OnEvent)
		
	elseif (parent == "pet") then -- parent is the pet bar
		bar:SetVisibility(true, true, true, true, true) -- hide on vehicle, petbattle, override and possess
		
		-- leave these 3 in, or buttons will bug out when abilities are manually removed from the Pet Bar
		PetActionBarFrame:UnregisterEvent("PET_BAR_SHOWGRID")
		PetActionBarFrame:UnregisterEvent("PET_BAR_HIDEGRID")
		PetActionBarFrame.showgrid = 1

		local PetBarUpdate = function()
			local petActionButton, petActionIcon, petAutoCastableTexture, petAutoCastShine
			for i = 1, NUM_PET_ACTION_SLOTS, 1 do
				local buttonName = "PetActionButton" .. i
				petActionButton = _G[buttonName]
				petActionIcon = _G[buttonName.."Icon"]
				petActionTex2 = _G[buttonName.."NormalTexture2"]
				petAutoCastableTexture = _G[buttonName.."AutoCastable"]
				petAutoCastShine = _G[buttonName.."Shine"]
				local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i)
				
				if (not isToken) then
					petActionIcon:SetTexture(texture)
					petActionButton.tooltipName = name
				else
					petActionIcon:SetTexture(_G[texture])
					petActionButton.tooltipName = _G[name]
				end
				
				petActionButton.isToken = isToken
				petActionButton.tooltipSubtext = subtext

				if (isActive) and (name ~= "PET_ACTION_FOLLOW") then
					petActionButton:SetChecked(1)
					if (IsPetAttackAction(i)) then
						PetActionButton_StartFlash(petActionButton)
					end
				else
					petActionButton:SetChecked(0)
					if (IsPetAttackAction(i)) then
						PetActionButton_StopFlash(petActionButton)
					end			
				end
				
				if (autoCastAllowed) then
					petAutoCastableTexture:Show()
				else
					petAutoCastableTexture:Hide()
				end
				
				if (autoCastEnabled) then
					AutoCastShine_AutoCastStart(petAutoCastShine)
				else
					AutoCastShine_AutoCastStop(petAutoCastShine)
				end
				
				if (name) then
					petActionButton:SetAlpha(1)
				else
					petActionButton:SetAlpha(0)
				end

				if (texture) then
					if GetPetActionSlotUsable(i) then
						SetDesaturation(petActionIcon, nil)
					else
						SetDesaturation(petActionIcon, 1)
					end
					petActionIcon:Show()
				else
					petActionIcon:Hide()
				end
				
				if (not PetHasActionBar()) and (texture) and (name ~= "PET_ACTION_FOLLOW") then
					PetActionButton_StopFlash(petActionButton)
					SetDesaturation(petActionIcon, 1)
					petActionButton:SetChecked(0)
				end
				
				-- hotfix for the strata issue on login
				-- no idea as to the cause, and gActionButtons-3.0 fixes it as well.
				if (petActionIcon) and (petActionIcon:IsShown()) and (petActionTex2) and (petActionTex2:IsShown()) then
					local strata, layer = petActionIcon:GetDrawLayer()
					petActionTex2:SetDrawLayer(strata, layer - 1)
				end
			end
		end
		
		local UpdateButtons = function(self)
			local button
			for i = 1, #self.buttons do
				button = self.buttons[i]
				button:Show()
				self:GetBar():SetAttribute("addchild", button)
			end
		end
		
		local OnEvent = function(self, event, ...)
			local arg1 = ...
			if (event == "PLAYER_ENTERING_WORLD") then
				safeQueueCall(UpdateButtons, bar)
			elseif (event == "PET_BAR_UPDATE") 
			or ((event == "UNIT_PET") and (arg1 == "player")) 
			or (event == "PET_UI_UPDATE")
			or (event == "UPDATE_VEHICLE_ACTIONBAR") 
			or (event == "PLAYER_CONTROL_LOST")
			or (event == "PLAYER_CONTROL_GAINED")
			or (event == "PLAYER_FARSIGHT_FOCUS_CHANGED")
			or (event == "PET_BAR_UPDATE_USABLE") 
			or (event == "PLAYER_TARGET_CHANGED") then
				PetBarUpdate()
			elseif ( (event == "UNIT_FLAGS") or (event == "UNIT_AURA") ) then
				if ( arg1 == "pet" ) then
					PetBarUpdate()
				end
			elseif ( event =="PET_BAR_UPDATE_COOLDOWN" ) then
				PetActionBar_UpdateCooldowns()
			-- elseif ( event =="PET_BAR_HIDE" ) then
			end
		end

		bar:GetBar():RegisterEvent("PLAYER_CONTROL_LOST")
		bar:GetBar():RegisterEvent("PLAYER_CONTROL_GAINED")
		bar:GetBar():RegisterEvent("PLAYER_ENTERING_WORLD")
		bar:GetBar():RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
		bar:GetBar():RegisterEvent("PET_BAR_UPDATE")
		bar:GetBar():RegisterEvent("PET_BAR_UPDATE_USABLE")
		bar:GetBar():RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
		-- bar:GetBar():RegisterEvent("PET_BAR_HIDE") 
		bar:GetBar():RegisterEvent("PET_UI_UPDATE")
		bar:GetBar():RegisterEvent("UNIT_PET")
		bar:GetBar():RegisterEvent("UNIT_FLAGS")
		bar:GetBar():RegisterEvent("UNIT_AURA")
		-- bar:GetBar():RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		-- bar:GetBar():RegisterEvent("PLAYER_LEVEL_UP") 
		bar:GetBar():SetScript("OnEvent", OnEvent)
		
		bar:RegisterStateDriver("visibility", "[pet,novehicleui,nobonusbar:5] show; hide")
		hooksecurefunc("PetActionBar_Update", PetBarUpdate)
	
	elseif (parent == "extra") then
		
		-- our totally terrible ghettohack
		-- local granny = bar:GetBar():GetParent():GetParent()
		-- granny:SetParent(ExtraActionBarFrame)
	
		bar:SetVisibility(true, false, true, false) -- don't really know what to do with this thing...
	
	elseif (parent == "micro") then
		bar:SetVisibility(true, false, true, false) -- follows the main bar rules, only hidden in petbattles
		
	elseif (parent == "primary") then -- primary actionbar
		bar:SetVisibility(true, false, true, false) -- always show the primary bar (hide in petbattles)
		bar.IsStateBar = true
	elseif (parent == "bottomleft") -- secondary /bottomleft bar
	or (parent == "bottomright") -- third /bottomright bar
	or (parent == "right") -- right sidebar
	or (parent == "left") then -- left sidebar
		bar:SetVisibility(true, true, true, true, true) -- hide on vehicle, petbattle, override and possess
		bar.IsStateBar = true
	end
	
	self.bars[name] = bar
	
	-- simpler to simply hook these calls to the script handlers, 
	-- since this will prevent multiple calls at once
	bar:GetBar():HookScript("OnShow", function(self) gAB.scheduler:FireCallback("GAB_ACTIONBAR_VISIBILITY_UPDATE", bar:GetName(), self:IsVisible()) end)
	bar:GetBar():HookScript("OnHide", function(self) gAB.scheduler:FireCallback("GAB_ACTIONBAR_VISIBILITY_UPDATE", bar:GetName(), self:IsVisible()) end)

	-- initial setup
	bar:UpdateButtons()
	bar:UpdateLayout() 

	return bar
end

gAB.GetBarByName = function(self, name)
	argCheck(name, 1, "string")
	return self.bars[name]
end

------------------------------------------------------------------------------------------------------------
-- 	Event Handling
------------------------------------------------------------------------------------------------------------
local updateBars = function()
	for name, bar in pairs(gAB.bars) do
		safeQueueCall(bar.UpdateButtons, bar)
		safeQueueCall(bar.UpdateLayout, bar)
		safeQueueCall(bar.UpdateStates, bar)
	end
end

gAB.scheduler.OnInit = function(self)
end

gAB.scheduler.PLAYER_ENTERING_WORLD = function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	_G.ActionButton_HideGrid = noop
	_G.ActionButton_ShowGrid = noop
	local button, i, name, _
	for i = 1, NUM_ACTIONBAR_BUTTONS do
		for _,name in pairs({
		"ActionButton", 
		"MultiBarRightButton", 
		"MultiBarBottomRightButton", 
		"MultiBarLeftButton", 
		"MultiBarBottomLeftButton"}) do
			button = _G[name .. i]
			button:SetAttribute("showgrid", 1)
			ActionButton_ShowGrid(button)
		end
	end
end

gAB.scheduler.OnEnable = function(self)
	updateBars()
end

gAB.scheduler.ACTIVE_TALENT_GROUP_CHANGED = function(self)
	updateBars()
end

gAB.scheduler.PLAYER_REGEN_ENABLED = function(self, event, ...)
	local next
	while (#gAB.queue > 0) do 
		next = tremove(gAB.queue, 1)
		safeQueueCall(next.func, unpack(next.arg)) -- no, we can never be safe enough
	end
end
gAB.scheduler:RegisterEvent("PLAYER_REGEN_ENABLED")
gAB.scheduler:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
