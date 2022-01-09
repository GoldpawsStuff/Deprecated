--[[
Copyright (c) 2010-2013, Hendrik "nevcairiel" Leppkes <h.leppkes@gmail.com>

All rights reserved.

***********************************************************************************
** 	All custom modifications for the gUI4 addon suite by Lars "Norberg" Goldpaw.
***********************************************************************************

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.
    * Neither the name of the developer nor the names of its contributors 
      may be used to endorse or promote products derived from this software without 
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]
local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local MAJOR_VERSION = "LibButtonGUI4-1.0"
local MINOR_VERSION = 57

if not GP_LibStub then error(MAJOR_VERSION .. " requires GP_LibStub.") end
local lib, oldversion = GP_LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

-- Lua API
local _G = _G
local type, error, tostring, tonumber, assert, select = type, error, tostring, tonumber, assert, select
local setmetatable, wipe, unpack, pairs, next = setmetatable, wipe, unpack, pairs, next
local str_match, format, tinsert, tremove = string.match, format, tinsert, tremove
local floor = math.floor

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- Note: No WoW API function get upvalued to allow proper interaction with any addons that try to hook them.
-- GLOBALS: GP_LibStub, CreateFrame, InCombatLockdown, ClearCursor, GetCursorInfo, GameTooltip, GameTooltip_SetDefaultAnchor
-- GLOBALS: GetBindingKey, GetBindingText, SetBinding, SetBindingClick, GetCVar, GetMacroInfo
-- GLOBALS: PickupAction, PickupItem, PickupMacro, PickupPetAction, PickupSpell, PickupCompanion, PickupEquipmentSet
-- GLOBALS: CooldownFrame_SetTimer, UIParent, IsSpellOverlayed, SpellFlyout, GetMouseFocus, SetClampedTextureRotation
-- GLOBALS: GetActionInfo, GetActionTexture, HasAction, GetActionText, GetActionCount, GetActionCooldown, IsAttackAction
-- GLOBALS: IsAutoRepeatAction, IsEquippedAction, IsCurrentAction, IsConsumableAction, IsUsableAction, IsStackableAction, IsActionInRange
-- GLOBALS: GetSpellLink, GetMacroSpell, GetSpellTexture, GetSpellCount, GetSpellCooldown, IsAttackSpell, IsCurrentSpell
-- GLOBALS: FindSpellBookSlotBySpellID, IsUsableSpell, IsConsumableSpell, IsSpellInRange, IsAutoRepeatSpell
-- GLOBALS: GetItemIcon, GetItemCount, GetItemCooldown, IsEquippedItem, IsCurrentItem, IsUsableItem, IsConsumableItem, IsItemInRange
-- GLOBALS: GetActionCharges, IsItemAction, GetSpellCharges
-- GLOBALS: RANGE_INDICATOR, ATTACK_BUTTON_FLASH_TIME, TOOLTIP_UPDATE_TIME
-- GLOBALS: GetShapeshiftFormInfo, GetShapeshiftFormCooldown

local CBH = GP_LibStub("GP_CallbackHandler-1.0")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

lib.eventFrame = lib.eventFrame or CreateFrame("Frame")
lib.eventFrame:UnregisterAllEvents()

lib.buttonRegistry = lib.buttonRegistry or {}
lib.activeButtons = lib.activeButtons or {}
lib.actionButtons = lib.actionButtons or {}
lib.nonActionButtons = lib.nonActionButtons or {}

lib.unusedOverlayGlows = lib.unusedOverlayGlows or {}
lib.numOverlays = lib.numOverlays or 0

lib.callbacks = lib.callbacks or CBH:New(lib)

local Generic = CreateFrame("CheckButton")
local Generic_MT = { __index = Generic }

local Action = setmetatable({}, { __index = Generic })
local Action_MT = { __index = Action }

local PetAction = setmetatable({}, { __index = Generic })
local PetAction_MT = { __index = PetAction }

local Spell = setmetatable({}, { __index = Generic })
local Spell_MT = { __index = Spell }

local Item = setmetatable({}, { __index = Generic })
local Item_MT = { __index = Item }

local Macro = setmetatable({}, { __index = Generic })
local Macro_MT = { __index = Macro }

local Custom = setmetatable({}, { __index = Generic })
local Custom_MT = { __index = Custom }

local Extra = setmetatable({}, { __index = Generic })
local Extra_MT = { __index = Extra }

local Stance = setmetatable({}, { __index = Generic })
local Stance_MT = { __index = Stance }

local type_meta_map = {
	empty = Generic_MT,
	action = Action_MT,
	pet = PetAction_MT,
	spell = Spell_MT,
	item = Item_MT,
	macro = Macro_MT,
	custom = Custom_MT,
	extra = Extra_MT,
	stance = Stance_MT
}

local ButtonRegistry, ActiveButtons, ActionButtons, NonActionButtons = lib.buttonRegistry, lib.activeButtons, lib.actionButtons, lib.nonActionButtons

local Update, UpdateButtonState, UpdateUsable, UpdateCount, UpdateCooldown, UpdateTooltip
local StartFlash, StopFlash, UpdateFlash, UpdateHotkeys, UpdateRangeTimer, UpdateOverlayGlow
local UpdateFlyout, ShowGrid, HideGrid, UpdateGrid, SetupSecureSnippets, WrapOnClick
local ShowOverlayGlow, HideOverlayGlow, GetOverlayGlow, OverlayGlowAnimOutFinished

local InitializeEventHandler, OnEvent, ForAllButtons, OnUpdate

local GetColor, StyleElement
local HidePetButton, ShowPetButton, HidePetGrid, ShowPetGrid

local Hidden = CreateFrame("Frame", "LibButtonGUI4UIHider", UIParent)
Hidden:Hide()

local DefaultConfig = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	tooltipAnchor = false,
	showGrid = false,
	saturation = 1,
	desaturateUnusable = true,
	colors = {
		range = { .8, .1, .1 },
		mana = { .5, .5, 1 },
		unusable = { .5, .5, .5 }, 
	},
	hideElements = {
		macro = false,
		hotkey = false,
		equipped = false,
	},
	keyBoundTarget = false,
	clickOnDown = false,
	flyoutDirection = "UP",
}

-- set up the custom styling layers 
Generic.InitSkin = function(button)
	local hidden = Hidden 
	local name = button:GetName() 
	local buttonType = button.buttonActionType
	
	button.data = {}

	button.scaffold = LMP:NewChain(CreateFrame("Frame", name .. "Scaffold", button)) :SetFrameLevel(button:GetFrameLevel() + 2) :SetAllPoints() .__EndChain

	button.icon = LMP:NewChain(_G[name .. "Icon"]) :SetDrawLayer("BORDER", 0) :SetAllPoints() :SetTexCoord(5/64, 59/64, 5/64, 59/64) .__EndChain

	button.pushed = LMP:NewChain(button:CreateTexture(name .. "PushedTexture")) :SetDrawLayer("BORDER", 2) :SetColorTexture(1, .97, 0, .25) :SetAllPoints(button.icon) .__EndChain
	button.normal = LMP:NewChain(button:CreateTexture(name .. "NormalBorder")) :SetAlpha(.85) :SetDrawLayer("ARTWORK", 0) :SetAllPoints() .__EndChain
	button.normal.highlight = LMP:NewChain(button:CreateTexture(name .. "NormalBorderHighlight")) :SetColorTexture(1, 1, 1, .35) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	button.checked = LMP:NewChain(button:CreateTexture(name .. "CheckedBorder")) :SetDrawLayer("ARTWORK", 0) :SetColorTexture(1, .97, 0, .25) :Hide() :SetAllPoints() .__EndChain
	button.checked.highlight = LMP:NewChain(button:CreateTexture(name .. "CheckedBorderHighlight")) :SetColorTexture(1, .97, 0, .25) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	button.flash = LMP:NewChain(_G[name .. "Flash"]) :SetAllPoints(button.icon) :SetColorTexture(.7, 0, 0, .30) .__EndChain
	button.empty = LMP:NewChain(button:CreateTexture(name .. "EmptyTexture")) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	button.empty.highlight = LMP:NewChain(button:CreateTexture(name .. "EmptyTextureHighlight")) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	
	button.hotkey = LMP:NewChain(_G[name .. "HotKey"]) :SetParent(button.scaffold) :SetFontObject(GameFontNormal) :SetFont(GameFontNormal:GetFont(), 10, "") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", -1) :SetPoint("TOPRIGHT", -2, -2) :SetTextColor(1, 1, 1) .__EndChain
	button.count = LMP:NewChain(_G[name .. "Count"]) :SetParent(button.scaffold) :SetFontObject(GameFontNormal) :SetFont(GameFontNormal:GetFont(), 10, "") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", -2) :SetPoint("BOTTOMRIGHT", -2, 2) :SetTextColor(1, 1, 1) .__EndChain

	if (buttonType ~= "extra") then
		button.actionName = LMP:NewChain(_G[name .. "Name"]) :SetParent(button.scaffold) :SetFontObject(GameFontNormal) :SetFont(GameFontNormal:GetFont(), 10, "") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", -1) :ClearAllPoints() :SetPoint("BOTTOM") :SetPoint("LEFT") :SetPoint("RIGHT") :SetTextColor(1, 1, 1) .__EndChain
		button.border = LMP:NewChain(_G[name .. "Border"]) :SetAlpha(0) :SetParent(hidden) .__EndChain
	end

	button.normalTexture = LMP:NewChain(_G[name .. "NormalTexture"] or _G[name .. "NormalTexture2"]) :SetParent(hidden) .__EndChain

	if button.buttonActionType == "action" or button.buttonActionType == "stance" or button.buttonActionType == "pet" then
		button.cooldown = LMP:NewChain(_G[name .. "Cooldown"]) :SetFrameLevel(button:GetFrameLevel() + 1) :SetAllPoints(button.icon) .__EndChain
		button.flyoutArrow = LMP:NewChain(_G[name .. "FlyoutArrow"]) .__EndChain -- keep the arrow high enough
		button.flyoutBorder = LMP:NewChain(_G[name .. "FlyoutBorder"]) :SetAlpha(0) :SetParent(hidden) .__EndChain
		button.flyoutBorderShadow = LMP:NewChain(_G[name .. "FlyoutBorderShadow"]) :SetAlpha(0) :SetParent(hidden) .__EndChain

		local blingTexture = "Interface\\Cooldown\\star4" -- what wow uses as default
		button.cooldown:SetSwipeColor(0, 0, 0, .75)
		button.cooldown:SetBlingTexture(blingTexture, .3, .6, 1, .75) -- again what wow uses, only with slightly lower alpha

		-- button.cooldown.noCooldownCount = true
		
		-- we need to fire off this during fading to make sure the annoying alpha-immune cooldown spirals are updated properly
		local _fader = button:GetParent():GetParent()
		if gUI4:IsFadeManager(_fader) then
			if not _fader.alphaHooked then
				hooksecurefunc(_fader, "SetAlpha", function() 
					_fader._currentAlpha = _fader:GetAlpha()
					if _fader._oldAlpha ~= _fader._currentAlpha then
						OnEvent(lib.eventFrame, "ACTIONBAR_UPDATE_COOLDOWN")
						OnEvent(lib.eventFrame, "SPELL_UPDATE_COOLDOWN")
						_fader._oldAlpha = _fader._currentAlpha
					end
				end)
			end
		end
	end

	if button.buttonActionType == "pet" then
		button.autocastable = LMP:NewChain(_G[name .. "AutoCastable"]) .__EndChain
		button.autocast = LMP:NewChain(_G[name .. "Shine"]) .__EndChain
	end

	if button.buttonActionType == "extra" then
		button.style = LMP:NewChain(_G[name].style) :SetParent(hidden) .__EndChain
	end
	
	if button.SetCheckedTexture then
		button:SetCheckedTexture("")
	end
	if button.SetHighlightTexture then
		button:SetHighlightTexture("")
	end
	if button.SetPushedTexture then -- let blizz handle this one
		button:SetPushedTexture(button.pushed)
		button:GetPushedTexture():SetBlendMode("BLEND")
		button:GetPushedTexture():SetDrawLayer("BORDER", 2)
	end
end

local NUM_MOUSE_BUTTONS = 31

function lib:ToShortKey(key)
	if key then
		key = key:upper()
		key = key:gsub(' ', '')
		key = key:gsub('ALT%-', L['Alt'])
		key = key:gsub('CTRL%-', L['Ctrl'])
		key = key:gsub('SHIFT%-', L['Shift'])
		key = key:gsub('NUMPAD', L['NumPad'])

		key = key:gsub('PLUS', '%+')
		key = key:gsub('MINUS', '%-')
		key = key:gsub('MULTIPLY', '%*')
		key = key:gsub('DIVIDE', '%/')

		key = key:gsub('BACKSPACE', L['Backspace'])

		for i = 1, NUM_MOUSE_BUTTONS do
			key = key:gsub('BUTTON' .. i, L['Button' .. i])
		end

		key = key:gsub('CAPSLOCK', L['Capslock'])
		key = key:gsub('CLEAR', L['Clear'])
		key = key:gsub('DELETE', L['Delete'])
		key = key:gsub('END', L['End'])
		key = key:gsub('HOME', L['Home'])
		key = key:gsub('INSERT', L['Insert'])
		key = key:gsub('MOUSEWHEELDOWN', L['Mouse Wheel Down'])
		key = key:gsub('MOUSEWHEELUP', L['Mouse Wheel Up'])
		key = key:gsub('NUMLOCK', L['Num Lock'])
		key = key:gsub('PAGEDOWN', L['Page Down'])
		key = key:gsub('PAGEUP', L['Page Up'])
		key = key:gsub('SCROLLLOCK', L['Scroll Lock'])
		key = key:gsub('SPACEBAR', L['Spacebar'])
		key = key:gsub('SPACE', L['Spacebar'])
		key = key:gsub('TAB', L['Tab'])

		key = key:gsub('DOWNARROW', L['Down Arrow'])
		key = key:gsub('LEFTARROW', L['Left Arrow'])
		key = key:gsub('RIGHTARROW', L['Right Arrow'])
		key = key:gsub('UPARROW', L['Up Arrow'])

		return key
	end
end


--- Create a new action button.
-- @param buttonType Type of button to be created ()
-- @param id Internal id of the button (not used by LibActionButton-1.0, only for tracking inside the calling addon)
-- @param name Name of the button frame to be created (not used by LibActionButton-1.0 aside from naming the frame)
-- @param header Header that drives these action buttons (if any)
function lib:CreateButton(buttonType, id, name, header, config)
	-- if type(name) ~= "string" then
		-- error("Usage: CreateButton(buttonType, id, name. header): Buttons must have a valid name!", 2)
	-- end
	if not header then
		error("Usage: CreateButton(buttonType, id, name, header): Buttons without a secure header are not yet supported!", 2)
	end
	if not buttonType then
		buttonType = "action"
	end

	local button
	if buttonType == "pet" then
		button = setmetatable(CreateFrame("CheckButton", name or ("GUI4PetButton" .. id), header, "PetActionButtonTemplate"), Generic_MT)
		button.showgrid = 0
		button.id = id
		button.parent = header
		button:SetFrameStrata("MEDIUM")
		button:SetID(id)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		button:SetScript("OnUpdate", nil)
	elseif buttonType == "stance" then
		button = setmetatable(CreateFrame("CheckButton", name or ("GUI4StanceButton" .. id), header, "StanceButtonTemplate"), Generic_MT) 
		button.showgrid = 0
		button.id = id
		button.parent = header
		button:SetFrameStrata("MEDIUM")
		button:SetID(id)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
	elseif buttonType == "extra" then 
		button = setmetatable(CreateFrame("CheckButton", name or ("GUI4ExtraButton" .. id), header, "ExtraActionButtonTemplate"), Generic_MT)
		button.showgrid = 0
		button.id = id
		button.parent = header
		button:SetFrameStrata("MEDIUM")
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)

	elseif buttonType == "action" then
		button = setmetatable(CreateFrame("CheckButton", name or ("GUI4Button" .. id), header, "SecureActionButtonTemplate, ActionButtonTemplate"), Generic_MT)
		button:RegisterForDrag("LeftButton", "RightButton")
		button:RegisterForClicks("AnyUp")
	end
	button.buttonActionType = buttonType

	-- Frame Scripts
	button:SetScript("OnEnter", Generic.OnEnter)
	button:SetScript("OnLeave", Generic.OnLeave)
	button:SetScript("OnMouseDown", Generic.OnMouseDown)
	button:SetScript("OnMouseUp", Generic.OnMouseUp)
	button:SetScript("PreClick", Generic.PreClick)
	button:SetScript("PostClick", Generic.PostClick)

	button.id = id
	button.header = header
	-- Mapping of state -> action
	button.state_types = {}
	button.state_actions = {}

	-- Store the library version that created this button for debugging
	button.__GAB_Version = MINOR_VERSION

	button:SetAttribute("state", 0)

	SetupSecureSnippets(button)
	WrapOnClick(button)


	button:InitSkin()
	
	hooksecurefunc(button, "SetChecked", function(self) self:UpdateLayers() end) -- this solves the checking for our custom textures
	
	if not next(ButtonRegistry) then -- Store the button in the registry, needed for event and OnUpdate handling
		InitializeEventHandler()
	end
	ButtonRegistry[button] = true

	button:UpdateConfig(config)
	button:UpdateAction() -- run an initial update
	button:UpdateLayers()

	UpdateHotkeys(button)
	
	button.action = 0 -- somewhat of a hack for the Flyout buttons to not error.

	lib.callbacks:Fire("OnButtonCreated", button)

	return button
end

function SetupSecureSnippets(button)
	button:SetAttribute("_custom", Custom.RunCustom)
	-- secure UpdateState(self, state)
	-- update the type and action of the button based on the state
	button:SetAttribute("UpdateState", [[
		local state = ...
		self:SetAttribute("state", state)
		local type, action = (self:GetAttribute(format("labtype-%s", state)) or "empty"), self:GetAttribute(format("labaction-%s", state))

		self:SetAttribute("type", type)
		if type ~= "empty" and type ~= "custom" then
			local action_field = (type == "pet") and "action" or type
			self:SetAttribute(action_field, action)
			self:SetAttribute("action_field", action_field)
		end
		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			self:Run(onStateChanged, state, type, action)
		end
	]])

	-- this function is invoked by the header when the state changes
	button:SetAttribute("_childupdate-state", [[
		self:RunAttribute("UpdateState", message)
		self:CallMethod("UpdateAction")
	]])

	-- secure PickupButton(self, kind, value, ...)
	-- utility function to place a object on the cursor
	button:SetAttribute("PickupButton", [[
		local kind, value = ...
		if kind == "empty" then
			return "clear"
		elseif kind == "action" or kind == "pet" then
			local actionType = (kind == "pet") and "petaction" or kind
			return actionType, value
		elseif kind == "spell" or kind == "item" or kind == "macro" then
			return "clear", kind, value
		else
			print("LibActionButton-1.0: Unknown type: " .. tostring(kind))
			return false
		end
	]])

	button:SetAttribute("OnDragStart", [[
		if (self:GetAttribute("buttonlock") and not IsModifiedClick("PICKUPACTION")) or self:GetAttribute("LABdisableDragNDrop") then return false end
		local state = self:GetAttribute("state")
		local type = self:GetAttribute("type")
		-- if the button is empty, we can't drag anything off it
		if type == "empty" or type == "custom" then
			return false
		end
		-- Get the value for the action attribute
		local action_field = self:GetAttribute("action_field")
		local action = self:GetAttribute(action_field)

		-- non-action fields need to change their type to empty
		if type ~= "action" and type ~= "pet" then
			self:SetAttribute(format("labtype-%s", state), "empty")
			self:SetAttribute(format("labaction-%s", state), nil)
			-- update internal state
			self:RunAttribute("UpdateState", state)
			-- send a notification to the insecure code
			self:CallMethod("ButtonContentsChanged", state, "empty", nil)
		end
		-- return the button contents for pickup
		return self:RunAttribute("PickupButton", type, action)
	]])

	button:SetAttribute("OnReceiveDrag", [[
		if self:GetAttribute("LABdisableDragNDrop") then return false end
		local kind, value, subtype, extra = ...
		if not kind or not value then return false end
		local state = self:GetAttribute("state")
		local buttonType, buttonAction = self:GetAttribute("type"), nil
		if buttonType == "custom" then return false end
		-- action buttons can do their magic themself
		-- for all other buttons, we'll need to update the content now
		if buttonType ~= "action" and buttonType ~= "pet" then
			-- with "spell" types, the 4th value contains the actual spell id
			if kind == "spell" then
				if extra then
					value = extra
				else
					print("no spell id?", ...)
				end
			elseif kind == "item" and value then
				value = format("item:%d", value)
			end

			-- Get the action that was on the button before
			if buttonType ~= "empty" then
				buttonAction = self:GetAttribute(self:GetAttribute("action_field"))
			end

			-- TODO: validate what kind of action is being fed in here
			-- We can only use a handful of the possible things on the cursor
			-- return false for all those we can't put on buttons

			self:SetAttribute(format("labtype-%s", state), kind)
			self:SetAttribute(format("labaction-%s", state), value)
			-- update internal state
			self:RunAttribute("UpdateState", state)
			-- send a notification to the insecure code
			self:CallMethod("ButtonContentsChanged", state, kind, value)
		else
			-- get the action for (pet-)action buttons
			buttonAction = self:GetAttribute("action")
		end
		return self:RunAttribute("PickupButton", buttonType, buttonAction)
	]])

	button:SetScript("OnDragStart", nil)
	-- Wrapped OnDragStart(self, button, kind, value, ...)
	button.header:WrapScript(button, "OnDragStart", [[
		return self:RunAttribute("OnDragStart")
	]])
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	button.header:WrapScript(button, "OnDragStart", [[
		return "message", "update"
	]], [[
		self:RunAttribute("UpdateState", self:GetAttribute("state"))
	]])

	button:SetScript("OnReceiveDrag", nil)
	-- Wrapped OnReceiveDrag(self, button, kind, value, ...)
	button.header:WrapScript(button, "OnReceiveDrag", [[
		return self:RunAttribute("OnReceiveDrag", kind, value, ...)
	]])
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	button.header:WrapScript(button, "OnReceiveDrag", [[
		return "message", "update"
	]], [[
		self:RunAttribute("UpdateState", self:GetAttribute("state"))
	]])
end

function WrapOnClick(button)
	-- Wrap OnClick, to catch changes to actions that are applied with a click on the button.
	button.header:WrapScript(button, "OnClick", [[
		if self:GetAttribute("type") == "action" then
			local type, action = GetActionInfo(self:GetAttribute("action"))
			return nil, format("%s|%s", tostring(type), tostring(action))
		end
	]], [[
		local type, action = GetActionInfo(self:GetAttribute("action"))
		if message ~= format("%s|%s", tostring(type), tostring(action)) then
			self:RunAttribute("UpdateState", self:GetAttribute("state"))
		end
	]])
end


-----------------------------------------------------------
--- gUI4 custom modifications
function GetColor(r, g, b)
	return floor(r*100 + .5)/100, floor(g*100 + .5)/100, floor(b*100 + .5)/100
end

function StyleElement(element, db, ...)
	if not element then return end
	if db then
		element:SetTexture(db:GetPath())
		element:SetTexCoord(db:GetTexCoord())
		element:SetVertexColor(unpack(db:GetColor()))
		element:SetAlpha(db:GetAlpha())
		element:SetSize(db:GetTexSize())
		element:ClearAllPoints()
		element:SetPoint(db:GetPoint())
	else
		element:SetTexture("")
		element:Hide()
		element:SetTexCoord(0, 1, 0, 1)
		element:SetVertexColor(1, 1, 1)
		element:SetAlpha(1)
		element:SetSize(.001, .001)
		element:ClearAllPoints()
		element:SetAllPoints()
	end
	return element
end

function Generic:UpdateSkin(db, forced)
	if forced or not self.db then
		self.db = db 
	end
	db = self.db 
	
	if db.icon then
		self.icon:SetSize(unpack(db.icon.size))
		self.icon:SetTexCoord(unpack(db.icon.texCoord))
		self.icon:ClearAllPoints()
		self.icon:SetPoint(unpack(db.icon.place))
	else
		self.icon:SetSize(self:GetSize())
		self.icon:SetTexCoord(5/65, 59/64, 5/64, 59/64)
		self.icon:SetAllPoints()
	end
	
	StyleElement(self.normal, db.normal)
	StyleElement(self.normal.highlight, db.highlight)
	StyleElement(self.checked, db.checked)
	StyleElement(self.checked.highlight, db.checkedhighlight)
	StyleElement(self.empty, db.empty)
	StyleElement(self.empty.highlight, db.emptyhighlight)

	self.pushed:SetSize(self.icon:GetSize())
	self.pushed:ClearAllPoints()
	self.pushed:SetPoint(self.icon:GetPoint())

	Update(self)
end

function Generic:UpdateLayers()
	local checked
	if self._state_type == "pet" then
		checked = self:IsCurrentlyActive() or self:IsAutoRepeat() 
	else
		checked = self:GetChecked() == true
	end
	local empty = self.data.empty
	-- local pushed = self:GetButtonState() == "PUSHED"-- self.data.pushed
	local highlight = self.data.highlight
	if empty then
		self.empty:SetShown(not highlight)
		self.empty.highlight:SetShown(highlight)
		self.normal:Hide()
		self.normal.highlight:Hide()
		self.checked:Hide()
		self.checked.highlight:Hide()
		checked = nil
		pushed = nil
	else
		self.empty:Hide()
		self.empty.highlight:Hide()
		if checked then
			self.checked:SetShown(not(highlight))
			self.checked.highlight:SetShown(highlight)
			self.normal:Hide()
			self.normal.highlight:Hide()
		else
			self.checked:Hide()
			self.checked.highlight:Hide()
			self.normal:SetShown(not highlight)
			self.normal.highlight:SetShown(highlight)
		end
	end
	-- self.pushed:SetShown(pushed)
	self.data.checked = checked
	self.data.pushed = pushed
end


-----------------------------------------------------------
--- utility

function lib:GetAllButtons()
	local buttons = {}
	for button in next, ButtonRegistry do
		buttons[button] = true
	end
	return buttons
end

function Generic:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end

function Generic:NewHeader(header)
	self.header = header
	self:SetParent(header)
	SetupSecureSnippets(self)
	WrapOnClick(self)
end


-----------------------------------------------------------
--- state management

function Generic:ClearStates()
	for state in pairs(self.state_types) do
		self:SetAttribute(format("labtype-%s", state), nil)
		self:SetAttribute(format("labaction-%s", state), nil)
	end
	wipe(self.state_types)
	wipe(self.state_actions)
end

function Generic:SetState(state, kind, action)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	-- we allow a nil kind for setting a empty state
	if not kind then kind = "empty" end
	if not type_meta_map[kind] then
		error("SetStateAction: unknown action type: " .. tostring(kind), 2)
	end
	if kind ~= "empty" and action == nil then
		error("SetStateAction: an action is required for non-empty states", 2)
	end
	if kind ~= "custom" and action ~= nil and type(action) ~= "number" and type(action) ~= "string" or (kind == "custom" and type(action) ~= "table") then
		error("SetStateAction: invalid action data type, only strings and numbers allowed", 2)
	end

	if kind == "item" then
		if tonumber(action) then
			action = format("item:%s", action)
		else
			local itemString = str_match(action, "^|c%x+|H(item[%d:]+)|h%[")
			if itemString then
				action = itemString
			end
		end
	end

	self.state_types[state] = kind
	self.state_actions[state] = action
	self:UpdateState(state)
end

function Generic:UpdateState(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	self:SetAttribute(format("labtype-%s", state), self.state_types[state])
	self:SetAttribute(format("labaction-%s", state), self.state_actions[state])
	if state ~= tostring(self:GetAttribute("state")) then return end
	if self.header then
		self.header:SetFrameRef("updateButton", self)
		self.header:Execute([[
			local frame = self:GetFrameRef("updateButton")
			control:RunFor(frame, frame:GetAttribute("UpdateState"), frame:GetAttribute("state"))
		]])
	else
	-- TODO
	end
	self:UpdateAction()
end

function Generic:GetAction(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	return self.state_types[state] or "empty", self.state_actions[state]
end

function Generic:UpdateAllStates()
	for state in pairs(self.state_types) do
		self:UpdateState(state)
	end
end

function Generic:ButtonContentsChanged(state, kind, value)
	state = tostring(state)
	self.state_types[state] = kind or "empty"
	self.state_actions[state] = value
	lib.callbacks:Fire("OnButtonContentsChanged", self, state, self.state_types[state], self.state_actions[state])
	self:UpdateAction(self)
end

function Generic:DisableDragNDrop(flag)
	if InCombatLockdown() then
		error("LibActionButton-1.0: You can only toggle DragNDrop out of combat!", 2)
	end
	if flag then
		self:SetAttribute("LABdisableDragNDrop", true)
	else
		self:SetAttribute("LABdisableDragNDrop", nil)
	end
end


-----------------------------------------------------------
--- frame scripts

-- copied (and adjusted) from SecureHandlers.lua
local function PickupAny(kind, target, detail, ...)
	if kind == "clear" then
		ClearCursor()
		kind, target, detail = target, detail, ...
	end

	if kind == 'action' then
		PickupAction(target)
	elseif kind == 'item' then
		PickupItem(target)
	elseif kind == 'macro' then
		PickupMacro(target)
	elseif kind == 'petaction' then
		PickupPetAction(target)
	elseif kind == 'spell' then
		PickupSpell(target)
	elseif kind == 'companion' then
		PickupCompanion(target, detail)
	elseif kind == 'equipmentset' then
		PickupEquipmentSet(target)
	end
end

function Generic:OnEnter()
	if self.config.tooltip ~= "disabled" and (self.config.tooltip ~= "nocombat" or not InCombatLockdown()) then
		if (not GameTooltip:IsForbidden()) then
			UpdateTooltip(self)
		end
	end
	self.data.highlight = true
	self:UpdateLayers()
end

function Generic:OnLeave()
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
	self.data.highlight = false
	self:UpdateLayers()
end

function Generic:OnMouseDown(button) 
	-- self.data.pushed = true
	self:UpdateLayers()
end

function Generic:OnMouseUp(button)  
	-- self.data.pushed = false
	self:UpdateLayers()
end

-- Insecure drag handler to allow clicking on the button with an action on the cursor
-- to place it on the button. Like action buttons work.
function Generic:PreClick()
	if self._state_type == "action" or self._state_type == "pet" or InCombatLockdown() or self:GetAttribute("LABdisableDragNDrop") then
		return
	end
	-- check if there is actually something on the cursor
	local kind, value, subtype = GetCursorInfo()
	if not (kind and value) then return end
	self._old_type = self._state_type
	if self._state_type and self._state_type ~= "empty" then
		self._old_type = self._state_type
		self:SetAttribute("type", "empty")
		--self:SetState(nil, "empty", nil)
	end
	self._receiving_drag = true
end

local function formatHelper(input)
	if type(input) == "string" then
		return format("%q", input)
	else
		return tostring(input)
	end
end

function Generic:PostClick()
	UpdateButtonState(self)
	if self._receiving_drag and not InCombatLockdown() then
		if self._old_type then
			self:SetAttribute("type", self._old_type)
			self._old_type = nil
		end
		local oldType, oldAction = self._state_type, self._state_action
		local kind, data, subtype, extra = GetCursorInfo()
		self.header:SetFrameRef("updateButton", self)
		self.header:Execute(format([[
			local frame = self:GetFrameRef("updateButton")
			control:RunFor(frame, frame:GetAttribute("OnReceiveDrag"), %s, %s, %s, %s)
			control:RunFor(frame, frame:GetAttribute("UpdateState"), %s)
		]], formatHelper(kind), formatHelper(data), formatHelper(subtype), formatHelper(extra), formatHelper(self:GetAttribute("state"))))
		PickupAny("clear", oldType, oldAction)
	end
	self._receiving_drag = nil
end


-----------------------------------------------------------
--- configuration

local function merge(target, source, default)
	for k,v in pairs(default) do
		if type(v) ~= "table" then
			if source and source[k] ~= nil then
				target[k] = source[k]
			else
				target[k] = v
			end
		else
			if type(target[k]) ~= "table" then target[k] = {} else wipe(target[k]) end
			merge(target[k], type(source) == "table" and source[k], v)
		end
	end
	return target
end

function Generic:UpdateConfig(config)
	if config and type(config) ~= "table" then
		error("LibActionButton-1.0: UpdateConfig requires a valid configuration!", 2)
	end
	local oldconfig = self.config
	if not self.config then self.config = {} end
	-- merge the two configs
	merge(self.config, config, DefaultConfig)

	if self.config.outOfRangeColoring == "button" or (oldconfig and oldconfig.outOfRangeColoring == "button") then
		UpdateUsable(self)
	end
	if self.config.outOfRangeColoring == "hotkey" then
		self.outOfRange = nil
	elseif oldconfig and oldconfig.outOfRangeColoring == "hotkey" then
		self.hotkey:SetVertexColor(0.75, 0.75, 0.75)
	end

	if self.actionName then
		if self.config.hideElements.macro then
			self.actionName:Hide()
		else
			self.actionName:Show()
		end
	end

	self:SetAttribute("flyoutDirection", self.config.flyoutDirection)

	UpdateHotkeys(self)
	UpdateGrid(self)
	Update(self)
	self:RegisterForClicks(self.config.clickOnDown and "AnyDown" or "AnyUp")
end


-----------------------------------------------------------
--- event handler

function ForAllButtons(method, onlyWithAction)
	assert(type(method) == "function")
	for button in next, (onlyWithAction and ActiveButtons or ButtonRegistry) do
		method(button)
	end
end

function InitializeEventHandler()
	lib.eventFrame:SetScript("OnEvent", OnEvent)
	lib.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.eventFrame:RegisterEvent("ACTIONBAR_SHOWGRID")
	lib.eventFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
	--lib.eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	--lib.eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	lib.eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	lib.eventFrame:RegisterEvent("UPDATE_BINDINGS")
	lib.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	lib.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
	lib.eventFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")

	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	lib.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	lib.eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
	lib.eventFrame:RegisterEvent("TRADE_SKILL_CLOSE")
	lib.eventFrame:RegisterEvent("ARCHAEOLOGY_CLOSED")
	lib.eventFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
	lib.eventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
	lib.eventFrame:RegisterEvent("START_AUTOREPEAT_SPELL")
	lib.eventFrame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	lib.eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
	lib.eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
	lib.eventFrame:RegisterEvent("COMPANION_UPDATE")
	lib.eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	lib.eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
	lib.eventFrame:RegisterEvent("PET_STABLE_UPDATE")
	lib.eventFrame:RegisterEvent("PET_STABLE_SHOW")
	lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
	lib.eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
	lib.eventFrame:RegisterEvent("UPDATE_SUMMONPETS_ACTION")

	-- With those two, do we still need the ACTIONBAR equivalents of them?
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
	lib.eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

	lib.eventFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
	lib.eventFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
	
	lib.eventFrame:RegisterEvent("PET_BAR_UPDATE")
	lib.eventFrame:RegisterEvent("PET_BAR_SHOWGRID")
	lib.eventFrame:RegisterEvent("PET_BAR_HIDEGRID")

  -- for items, as we want the count and similar updated!
	lib.eventFrame:RegisterEvent("BAG_UPDATE")

	lib.eventFrame:Show()
	lib.eventFrame:SetScript("OnUpdate", OnUpdate)
end

function OnEvent(frame, event, arg1, ...)
	if (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") or event == "LEARNED_SPELL_IN_TAB" then
		if (not GameTooltip:IsForbidden()) then
			local tooltipOwner = GameTooltip:GetOwner()
			if ButtonRegistry[tooltipOwner] then
				tooltipOwner:SetTooltip()
			end
		end
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		for button in next, ButtonRegistry do
			if button._state_type == "action" and (arg1 == 0 or arg1 == tonumber(button._state_action)) then
				Update(button)
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_VEHICLE_ACTIONBAR" then
		ForAllButtons(Update)
	elseif event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" then
		-- TODO: Are these even needed?
	elseif event == "ACTIONBAR_SHOWGRID" then
		ShowGrid()
	elseif event == "ACTIONBAR_HIDEGRID" then
		HideGrid()
	elseif event == "UPDATE_BINDINGS" then
		ForAllButtons(UpdateHotkeys)
	elseif event == "PLAYER_TARGET_CHANGED" then
		UpdateRangeTimer()
	elseif (event == "ACTIONBAR_UPDATE_STATE") or
		((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and (arg1 == "player")) or
		((event == "COMPANION_UPDATE") and (arg1 == "MOUNT")) then
		ForAllButtons(UpdateButtonState, true)
	elseif event == "ACTIONBAR_UPDATE_USABLE" then
		for button in next, ActionButtons do
			UpdateUsable(button)
		end
	elseif event == "SPELL_UPDATE_USABLE" then
		for button in next, NonActionButtons do
			UpdateUsable(button)
		end
	elseif event == "UPDATE_SHAPESHIFT_COOLDOWN" then
		for button in next, ActionButtons do
			UpdateCooldown(button)
			if (not GameTooltip:IsForbidden()) then
				if GameTooltip:GetOwner() == button then
					UpdateTooltip(button)
				end
			end
		end
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
		for button in next, ActionButtons do
			UpdateCooldown(button)
			if (not GameTooltip:IsForbidden()) then
				if GameTooltip:GetOwner() == button then
					UpdateTooltip(button)
				end
			end
		end
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		for button in next, NonActionButtons do
			UpdateCooldown(button)
			if (not GameTooltip:IsForbidden()) then
				if GameTooltip:GetOwner() == button then
					UpdateTooltip(button)
				end
			end
		end
	elseif event == "LOSS_OF_CONTROL_ADDED" then
		for button in next, ActiveButtons do
			UpdateCooldown(button)
			if (not GameTooltip:IsForbidden()) then
				if GameTooltip:GetOwner() == button then
					UpdateTooltip(button)
				end
			end
		end
	elseif event == "LOSS_OF_CONTROL_UPDATE" then
		for button in next, ActiveButtons do
			UpdateCooldown(button)
		end
	elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE"  or event == "ARCHAEOLOGY_CLOSED" then
		ForAllButtons(UpdateButtonState, true)
	elseif event == "PLAYER_ENTER_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				StartFlash(button)
			end
		end
	elseif event == "PLAYER_LEAVE_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				StopFlash(button)
			end
		end
	elseif event == "START_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button:IsAutoRepeat() then
				StartFlash(button)
			end
		end
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button.flashing == 1 and not button:IsAttack() then
				StopFlash(button)
			end
		end
	elseif event == "PET_STABLE_UPDATE" or event == "PET_STABLE_SHOW" then
		ForAllButtons(Update)
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
		for button in next, ActiveButtons do
			local spellId = button:GetSpellId()
			if spellId and spellId == arg1 then
				ShowOverlayGlow(button)
			else
				if button._state_type == "action" then
					local actionType, id = GetActionInfo(button._state_action)
					if actionType == "flyout" and FlyoutHasSpell(id, arg1) then
						ShowOverlayGlow(button)
					end
				end
			end
		end
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
		for button in next, ActiveButtons do
			local spellId = button:GetSpellId()
			if spellId and spellId == arg1 then
				HideOverlayGlow(button)
			else
				if button._state_type == "action" then
					local actionType, id = GetActionInfo(button._state_action)
					if actionType == "flyout" and FlyoutHasSpell(id, arg1) then
						HideOverlayGlow(button)
					end
				end
			end
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		for button in next, ActiveButtons do
			if button._state_type == "item" then
				Update(button)
			end
		end
	elseif event == "SPELL_UPDATE_CHARGES" then
		ForAllButtons(UpdateCount, true)
	elseif event == "UPDATE_SUMMONPETS_ACTION" then
		for button in next, ActiveButtons do
			if button._state_type == "action" then
				local actionType, id = GetActionInfo(button._state_action)
				if actionType == "summonpet" then
					local texture = GetActionTexture(button._state_action)
					if texture then
						button.icon:SetTexture(texture)
					end
				end
			end
		end
	elseif event == "PET_BAR_SHOWGRID" then
		for button in next, ButtonRegistry do
			if button:IsShown() and button.buttonActionType == "pet" then
				ShowPetGrid(button)
			end
		end
	elseif event == "PET_BAR_HIDEGRID" then
		for button in next, ButtonRegistry do
			if button.buttonActionType == "pet" then
				HidePetGrid(button)
			end
		end
	elseif event == "PET_BAR_UPDATE" then
		for button in next, ButtonRegistry do
			if button:IsShown() and button.buttonActionType == "pet" then
				Update(button)
			end
		end
  elseif event == "BAG_UPDATE" then
		for button in next, ActiveButtons do
			if button._state_type == "item" then
        Update(button)
      end
    end
	end
end

local flashTime = 0
local rangeTimer = -1
function OnUpdate(_, elapsed)
	flashTime = flashTime - elapsed
	rangeTimer = rangeTimer - elapsed
	-- Run the loop only when there is something to update
	if rangeTimer <= 0 or flashTime <= 0 then
		for button in next, ActiveButtons do
			-- Flashing
			if button.flashing == 1 and flashTime <= 0 then
				if button.flash:IsShown() then
					button.flash:Hide()
				else
					button.flash:Show()
				end
			end

			-- Range
			if rangeTimer <= 0 then
				local inRange = button:IsInRange()
				local oldRange = button.outOfRange
				button.outOfRange = (inRange == false)
				if oldRange ~= button.outOfRange then
					if button.config.outOfRangeColoring == "button" then
						UpdateUsable(button)
					elseif button.config.outOfRangeColoring == "hotkey" then
						local hotkey = button.HotKey
						if hotkey:GetText() == RANGE_INDICATOR then
							if inRange ~= nil then
								hotkey:Show()
							else
								hotkey:Hide()
							end
						end
						if inRange == false then
							hotkey:SetVertexColor(unpack(button.config.colors.range))
						else
							hotkey:SetVertexColor(0.75, 0.75, 0.75)
						end
					end
				end
			end
		end

		-- Update values
		if flashTime <= 0 then
			flashTime = flashTime + ATTACK_BUTTON_FLASH_TIME
		end
		if rangeTimer <= 0 then
			rangeTimer = TOOLTIP_UPDATE_TIME
		end
	end
end

-- actionbutton grid
local gridCounter = 0
function ShowGrid()
	gridCounter = gridCounter + 1
	if gridCounter >= 1 then
		for button in next, ButtonRegistry do
			if button:IsShown() and button.buttonActionType == "action" then
				button:SetAlpha(1.0)
			end
		end
	end
end
function HideGrid()
	if gridCounter > 0 then
		gridCounter = gridCounter - 1
	end
	if gridCounter == 0 then
		for button in next, ButtonRegistry do
			if button:IsShown() and button.buttonActionType == "action" and not button:HasAction() and not button.config.showGrid then
				button:SetAlpha(0.0)
			end
		end
	end
end
function UpdateGrid(self)
	if self.config.showGrid then
		self:SetAlpha(1.0)
	elseif gridCounter == 0 and self:IsShown() and not self:HasAction() then
		self:SetAlpha(0)
	end
end

-- petbutton grid
function ShowPetGrid(self)
	self.showgrid = self.showgrid + 1
	if self:GetTexture() or self:HasAction() then -- filled
		self.data.empty = false
	else -- empty / grid display
		self.data.empty = true
	end
	self:UpdateLayers()
	self:SetAlpha(1.0)
end
function HidePetGrid(self)
	if self.showgrid > 0 then self.showgrid = self.showgrid - 1 end
	-- print(self:GetName(), self.showgrid, (self.icon:GetTexture()), (GetPetActionInfo(self.id)))
	if self.showgrid == 0 then
		if self:GetTexture() or self:HasAction() then -- filled
			self.data.empty = false
			self:SetAlpha(1)
		else -- empty 
			self.data.empty = true
			if not self.parent:GetSettings().showgrid then
				self:SetAlpha(0)
			else
				self:SetAlpha(1)
			end
		end
	end
	self:UpdateLayers()
end
function ShowPetButton(self)
	local backdrop, gloss
	if backdrop then
		backdrop:Show()
	end
	if gloss then
		gloss:Show()
	end
	self:UpdateLayers()
	self:SetAlpha(1.0)
end
function HidePetButton(self)
	local backdrop, gloss
	if backdrop then
		backdrop:Hide()
	end
	if gloss then
		gloss:Hide()
	end
	if self.showgrid == 0 and not self.parent:GetSettings().showgrid then  
		-- self:UpdateLayers() -- save it for when we show it
		self:SetAlpha(0)
	end
end


-----------------------------------------------------------
--- KeyBound integration

function Generic:GetBindingAction()
	return self.config.keyBoundTarget or "CLICK "..self:GetName()..":LeftButton"
end

function Generic:GetHotkey()
	local name = "CLICK "..self:GetName()..":LeftButton"
	local key = GetBindingKey(self.config.keyBoundTarget or name)
	if not key and self.config.keyBoundTarget then
		key = GetBindingKey(name)
	end
	if key then
		return lib:ToShortKey(key) or key
	end
end

local function getKeys(binding, keys)
	keys = keys or ""
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ", "
		end
		keys = keys .. GetBindingText(hotKey, "KEY_")
	end
	return keys
end

function Generic:GetBindings()
	local keys, binding

	if self.config.keyBoundTarget then
		keys = getKeys(self.config.keyBoundTarget)
	end

	keys = getKeys("CLICK "..self:GetName()..":LeftButton")

	return keys
end

function Generic:SetKey(key)
	if self.config.keyBoundTarget then
		SetBinding(key, self.config.keyBoundTarget)
	else
		SetBindingClick(key, self:GetName(), "LeftButton")
	end
	lib.callbacks:Fire("OnKeybindingChanged", self, key)
end

local function clearBindings(binding)
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

function Generic:ClearBindings()
	if self.config.keyBoundTarget then
		clearBindings(self.config.keyBoundTarget)
	end
	clearBindings("CLICK "..self:GetName()..":LeftButton")
	lib.callbacks:Fire("OnKeybindingChanged", self, nil)
end


-----------------------------------------------------------
--- button management

function Generic:UpdateAction(force)
	local type, action = self:GetAction()
	if force or type ~= self._state_type or action ~= self._state_action then
		-- type changed, update the metatable
		if force or self._state_type ~= type then
			local meta = type_meta_map[type] or type_meta_map.empty
			setmetatable(self, meta)
			self._state_type = type
		end
		self._state_action = action
		Update(self)
	end
end

function Update(self)
	-- do -- debugging
		-- local name = self:GetName()
		-- if name:find("Stance") then
			-- print(name, self:HasAction(), self._state_action, self._state_type)
		-- end
	-- end
	if self:HasAction() then
		ActiveButtons[self] = true
		if self._state_type == "action" then
			ActionButtons[self] = true
			NonActionButtons[self] = nil
		elseif self._state_type == "pet" then
			ActionButtons[self] = nil
			NonActionButtons[self] = nil
			self:SetNormalTexture("")
			ShowPetButton(self)
			local _, _, _, _, _, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self.id)
			if autoCastAllowed and not autoCastEnabled then
				self.autocastable:Show()
				AutoCastShine_AutoCastStop(self.autocast)
			elseif autoCastAllowed then
				self.autocastable:Hide()
				AutoCastShine_AutoCastStart(self.autocast)
			else
				self.autocastable:Hide()
				AutoCastShine_AutoCastStop(self.autocast)
			end
		elseif self._state_type == "stance" then
			ActionButtons[self] = true -- good idea? bad?
			NonActionButtons[self] = nil
		else
			ActionButtons[self] = nil
			NonActionButtons[self] = true
		end
		self.data.empty = false
		self.icon:Show()
		self:SetAlpha(1.0)
		UpdateButtonState(self)
		UpdateUsable(self)
		UpdateCooldown(self)
		UpdateFlash(self)
	else
		ActiveButtons[self] = nil
		ActionButtons[self] = nil
		NonActionButtons[self] = nil
		if self._state_type == "pet" then
			ActionButtons[self] = nil
			NonActionButtons[self] = nil
			self.autocastable:Hide()
			AutoCastShine_AutoCastStop(self.autocast)
			self:SetNormalTexture("")
			HidePetButton(self)
		else
			if gridCounter == 0 and not self.config.showGrid then
				self:SetAlpha(0)
			end
		end
		self.data.empty = false
		self.icon:Hide()
		self.cooldown:Hide()
		self:SetChecked(false)
	end

	-- Add a green border if button is an equipped item
	if self.border then
		if self:IsEquipped() and not self.config.hideElements.equipped then
			self.border:SetVertexColor(0, 1.0, 0, 0.35)
			self.border:Show()
		else
			self.border:Hide()
		end
	end

	-- Update Action Text
	if self.actionName then
		if self._state_type == "action" and not self:IsConsumableOrStackable() then
			self.actionName:SetText(self:GetActionText())
		else
			self.actionName:SetText("")
		end
	end

	-- Update icon and hotkey
	local normal = self:GetNormalTexture()
	if normal then 
		normal:SetTexture("")
		normal:Hide()
	end

	local texture = self:GetTexture()
	if texture then
		self.data.empty = false
		self.icon:SetTexture(texture)
		self.icon:Show()
		self.rangeTimer = - 1
		self.normalTexture:SetTexCoord(0, 0, 0, 0)
	else
		self.data.empty = true
		self.icon:Hide()
		self.cooldown:Hide()
		self.rangeTimer = nil
		if self.hotkey:GetText() == RANGE_INDICATOR then
			self.hotkey:Hide()
		else
			self.hotkey:SetVertexColor(0.75, 0.75, 0.75)
		end
		self.normalTexture:SetTexCoord(-0.15, 1.15, -0.15, 1.17)
	end

	self:UpdateLocal()
	self:UpdateLayers()
	
	UpdateCount(self)
	UpdateFlyout(self)
	UpdateOverlayGlow(self)

	if (not GameTooltip:IsForbidden()) then
		if GameTooltip:GetOwner() == self then
			UpdateTooltip(self)
		end
	end

	-- this could've been a spec change, need to call OnStateChanged for action buttons, if present
	if not InCombatLockdown() and self._state_type == "action" then
		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			self.header:SetFrameRef("updateButton", self)
			self.header:Execute(([[
				local frame = self:GetFrameRef("updateButton")
				control:RunFor(frame, frame:GetAttribute("OnStateChanged"), %s, %s, %s)
			]]):format(formatHelper(self:GetAttribute("state")), formatHelper(self._state_type), formatHelper(self._state_action)))
		end
	end
	lib.callbacks:Fire("OnButtonUpdate", self)
end

function Generic:UpdateLocal()
-- dummy function the other button types can override for special updating
end

function UpdateButtonState(self)
	if self:IsCurrentlyActive() or self:IsAutoRepeat() then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end
	lib.callbacks:Fire("OnButtonState", self)
end

function UpdateUsable(self)
	if self.config.outOfRangeColoring == "button" then
		local isUsable, notEnoughMana = self:IsUsable()
		if self.outOfRange then
			if UnitOnTaxi("player") then
				SetDesaturation(self.icon, self.config.desaturateUnusable)
				self.icon:SetVertexColor(unpack(self.config.colors.unusable))
			else
				SetDesaturation(self.icon, false)
				self.icon:SetVertexColor(unpack(self.config.colors.range))
			end
		elseif notEnoughMana then
			SetDesaturation(self.icon, false)
			self.icon:SetVertexColor(unpack(self.config.colors.mana))
		elseif isUsable then
			SetDesaturation(self.icon, false)
			self.icon:SetVertexColor(1, 1, 1)
		else
			SetDesaturation(self.icon, self.config.desaturateUnusable)
			self.icon:SetVertexColor(unpack(self.config.colors.unusable))
		end
	end
	lib.callbacks:Fire("OnButtonUsable", self)
end

function UpdateCount(self)
	if not self:HasAction() then
		self.count:SetText("")
		return
	end
	if self:IsConsumableOrStackable() then
		local count = self:GetCount()
		if count > (self.maxDisplayCount or 9999) then
			self.count:SetText("*")
		else
			self.count:SetText(count)
		end
	else
		local charges, maxCharges, chargeStart, chargeDuration = self:GetCharges()
		if charges and maxCharges and maxCharges > 0 then
			self.count:SetText(charges)
		else
			self.count:SetText("")
		end
	end
end

-- omnicc fixed the alpha in v6.0.7
if OmniCC then
	local function getVersion()
    local version
    if OmniCC.GetVersion then
      version = OmniCC:GetVersion()
    else
      version = GetAddOnMetadata("OmniCC", "Version")
    end
		if version then
			local expansion, patch, release = version:match("(%d+)\.(%d+)\.(%d+)")
      if not expansion or not patch then 
        expansion, patch = version:match("(%d+)\.(%d+)") -- recent versions only have 2 numbers
      end
			return (tonumber(expansion) or 0) * 10000 + (tonumber(patch) or 0) * 100 + (tonumber(release) or 0)
		end
		return 0
	end
  local omnicc_version = getVersion()
	if omnicc_version > 0 and omnicc_version < 60007 then
		function UpdateCooldownAlpha(self)
			local locStart, locDuration = self:GetLossOfControlCooldown()
			local start, duration, enable, charges, maxCharges = self:GetCooldown()
			local effectiveAlpha = self:GetEffectiveAlpha()
			self.cooldown:SetDrawBling(effectiveAlpha > .5)
			-- self.cooldown:SetDrawEdge(effectiveAlpha > .5)
			self.cooldown:SetDrawEdge(false) -- this stuff looks bad, just remove it
			if (locStart + locDuration) > (start + duration) then
				self.cooldown:SetSwipeColor(.17, 0, 0, effectiveAlpha * .8)
			else
				self.cooldown:SetSwipeColor(0, 0, 0, effectiveAlpha * .8)
				-- if effectiveAlpha < 0.5 then
					self.cooldown:SetDrawEdge(false)
				-- end
			end
		end
		hooksecurefunc(OmniCC.Cooldown, "UpdateAlpha", function(self)
			local parent = self:GetParent()
			if ButtonRegistry[parent] then
				UpdateCooldownAlpha(parent)
			end
		end)
	end
end

-- Our own little stable proxy function to initiate button cooldowns, 
-- since the wow function for it keeps changing. 
Generic.SetCooldownTimer = function(self, start, duration, enable, charges, maxCharges, isLocCooldown)
	if enable then
		-- Cooldown frames ignore alpha changes, 
		-- so we need to manually check whether or not we should
		-- draw the edge and bling textures.
		local effectiveAlpha = self:GetEffectiveAlpha()
		local draw = effectiveAlpha > .5
		local has_bling = self.cooldown.SetSwipeColor and true or false
		
		-- color loss of control cooldowns red
		if has_bling then 
			if isLocCooldown then
				self.cooldown:SetSwipeColor(.17, 0, 0, effectiveAlpha * .75)
			else
				self.cooldown:SetSwipeColor(0, 0, 0, effectiveAlpha * .75)
			end
		end

		-- When this is 0, it means a cooldown will initiate later, but cannot yet.
		-- An example is the cooldown of stealth when you're currently in stealth. 
		if enable == 0 then
			self.cooldown:SetCooldown(0, 0)
		else
			if has_bling then
				-- If charges still remain on the spell, 
				-- don't draw the swipe texture, just the edge,
				-- as the swipe should always indicate that a spell is unusable!
				local drawEdge = false
				if duration > 2 and charges and maxCharges and charges ~= 0 then
					drawEdge = true
				end
				self.cooldown:SetDrawEdge(draw and drawEdge)
				self.cooldown:SetDrawBling(false)
				self.cooldown:SetDrawSwipe(not drawEdge)
			end
			self.cooldown:SetCooldown(start, duration)
		end
	end
end

-- Updates the cooldown of a button
UpdateCooldown = function(self)
	local locStart, locDuration = self:GetLossOfControlCooldown()
	local start, duration, enable, charges, maxCharges = self:GetCooldown()

	if (locStart + locDuration) > (start + duration) then
		if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_LOSS_OF_CONTROL then
			self.cooldown:SetHideCountdownNumbers(true)
			self.cooldown.currentCooldownType = COOLDOWN_TYPE_LOSS_OF_CONTROL
		end
		self.cooldown.locQueued = nil
		
		-- Hide the duration from the shine script, 
		-- to avoid shines being run after loss of control cooldowns.
		self.cooldown.duration = nil 
		self:SetCooldownTimer(locStart, locDuration, 1, nil, nil, true) 
	else
		if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL then
			self.cooldown:SetHideCountdownNumbers(false)
			self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
		end
		self.cooldown.locQueued = locStart > 0
		self.cooldown.duration = duration
		self:SetCooldownTimer(start, duration, enable, charges, maxCharges, false)
	end
end

function StartFlash(self)
	self.flashing = 1
	flashTime = 0
	UpdateButtonState(self)
end

function StopFlash(self)
	self.flashing = 0
	self.flash:Hide()
	UpdateButtonState(self)
end

function UpdateFlash(self)
	if (self:IsAttack() and self:IsCurrentlyActive()) or self:IsAutoRepeat() then
		StartFlash(self)
	else
		StopFlash(self)
	end
end

function UpdateTooltip(self)
	if (not GameTooltip:IsForbidden()) and (self.config.tooltip ~= "disabled" and (self.config.tooltip ~= "nocombat" or not InCombatLockdown())) then
		if self.config.tooltipAnchor then
			LMP:PlaceTip(self)
		elseif (GetCVar("UberTooltips") == "1") then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end
		if self:SetTooltip() then
			self.UpdateTooltip = UpdateTooltip
		else
			self.UpdateTooltip = nil
		end
	else
		self.UpdateTooltip = nil
	end
end

function UpdateHotkeys(self)
	local key = self:GetHotkey()
	if not key or key == "" or self.config.hideElements.hotkey then
		self.hotkey:SetText(RANGE_INDICATOR)
		self.hotkey:SetPoint("TOPLEFT", self, "TOPLEFT", 1, - 2)
		self.hotkey:Hide()
	else
		self.hotkey:SetText(key)
		self.hotkey:SetPoint("TOPLEFT", self, "TOPLEFT", - 2, - 2)
		self.hotkey:Show()
	end
end

local function OverlayGlow_OnHide(self)
	if self.animOut:IsPlaying() then
		self.animOut:Stop()
		OverlayGlowAnimOutFinished(self.animOut)
	end
end

function GetOverlayGlow()
	local overlay = tremove(lib.unusedOverlayGlows);
	if not overlay then
		lib.numOverlays = lib.numOverlays + 1
		overlay = CreateFrame("Frame", "LibButtonGUI4ActionButtonOverlay"..lib.numOverlays, UIParent, "ActionBarButtonSpellActivationAlert")
		overlay.animOut:SetScript("OnFinished", OverlayGlowAnimOutFinished)
		overlay:SetScript("OnHide", OverlayGlow_OnHide)
	end
	return overlay
end

function ShowOverlayGlow(self)
	if self.overlay then
		if self.overlay.animOut:IsPlaying() then
			self.overlay.animOut:Stop()
			self.overlay.animIn:Play()
		end
	else
		self.overlay = GetOverlayGlow()
		local frameWidth, frameHeight = self:GetSize()
		self.overlay:SetParent(self)
		self.overlay:ClearAllPoints()
		--Make the height/width available before the next frame:
		self.overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
		self.overlay:SetPoint("TOPLEFT", self, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
		self.overlay:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
		self.overlay.animIn:Play()
	end
end

function HideOverlayGlow(self)
	if self.overlay then
		if self.overlay.animIn:IsPlaying() then
			self.overlay.animIn:Stop()
		end
		if self:IsVisible() then
			self.overlay.animOut:Play()
		else
			OverlayGlowAnimOutFinished(self.overlay.animOut)
		end
	end
end

function OverlayGlowAnimOutFinished(animGroup)
	local overlay = animGroup:GetParent()
	local actionButton = overlay:GetParent()
	overlay:Hide()
	tinsert(lib.unusedOverlayGlows, overlay)
	actionButton.overlay = nil
end

function UpdateOverlayGlow(self)
	local spellId = self:GetSpellId()
	if spellId and IsSpellOverlayed(spellId) then
		ShowOverlayGlow(self)
	else
		HideOverlayGlow(self)
	end
end

function UpdateFlyout(self)
	if not self.FlyoutBorder then 
		return
	end
	self.FlyoutBorder:Hide()
	self.FlyoutBorderShadow:Hide()
	if self._state_type == "action" then
		-- based on ActionButton_UpdateFlyout in ActionButton.lua
		local actionType = GetActionInfo(self._state_action)
		if actionType == "flyout" then
			-- Update border and determine arrow position
			local arrowDistance
			if (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self) or GetMouseFocus() == self then
				arrowDistance = 5
			else
				arrowDistance = 2
			end

			-- Update arrow
			self.FlyoutArrow:Show()
			self.FlyoutArrow:ClearAllPoints()
			local direction = self:GetAttribute("flyoutDirection")
			if direction == "LEFT" then
				self.FlyoutArrow:SetPoint("LEFT", self, "LEFT", -arrowDistance, 0)
				SetClampedTextureRotation(self.FlyoutArrow, 270)
			elseif direction == "RIGHT" then
				self.FlyoutArrow:SetPoint("RIGHT", self, "RIGHT", arrowDistance, 0)
				SetClampedTextureRotation(self.FlyoutArrow, 90)
			elseif direction == "DOWN" then
				self.FlyoutArrow:SetPoint("BOTTOM", self, "BOTTOM", 0, -arrowDistance)
				SetClampedTextureRotation(self.FlyoutArrow, 180)
			else
				self.FlyoutArrow:SetPoint("TOP", self, "TOP", 0, arrowDistance)
				SetClampedTextureRotation(self.FlyoutArrow, 0)
			end

			-- return here, otherwise flyout is hidden
			return
		end
	end 
	self.FlyoutArrow:Hide()
end
hooksecurefunc("ActionButton_UpdateFlyout", function(self, ...)
	if ButtonRegistry[self] then
		UpdateFlyout(self)
	end
end)
LMP:NewChain(CreateFrame("Frame")) 
	:RegisterEvent("PLAYER_LOGIN")
	:SetScript("OnEvent", function(self, event, ...)
		local GetFlyoutInfo = GetFlyoutInfo
		local GetNumFlyouts = GetNumFlyouts
		local GetFlyoutID = GetFlyoutID
		local SpellFlyout = SpellFlyout
		local SpellFlyoutBackgroundEnd = SpellFlyoutBackgroundEnd
		local SpellFlyoutHorizontalBackground = SpellFlyoutHorizontalBackground
		local SpellFlyoutVerticalBackground = SpellFlyoutVerticalBackground
		local numFlyoutButtons = 0
		local flyoutButtons = {}
		local buttonBackdrop = {
			bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
			edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
			edgeSize = 1,
			insets = { 
				left = -1, 
				right = -1, 
				top = -1, 
				bottom = -1
			}
		}
		local function UpdateFlyout(self)
			if not self.FlyoutArrow then return end
			SpellFlyoutHorizontalBackground:SetAlpha(0)
			SpellFlyoutVerticalBackground:SetAlpha(0)
			SpellFlyoutBackgroundEnd:SetAlpha(0)
			-- self.FlyoutBorder:SetAlpha(0)
			-- self.FlyoutBorderShadow:SetAlpha(0)
			for i = 1, GetNumFlyouts() do
				local _, _, numSlots, isKnown = GetFlyoutInfo(GetFlyoutID(i))
				if isKnown then
					numFlyoutButtons = numSlots
					break
				end
			end
		end
		local function updateFlyoutButton(self)
			self.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
			self.icon:ClearAllPoints()
			self.icon:SetPoint("TOPLEFT", 2, -2)
			self.icon:SetPoint("BOTTOMRIGHT", -2, 2)
			self.icon:SetDrawLayer("BORDER", 0) -- tends to disappear into BACKGROUND, 0
			self:SetBackdrop(buttonBackdrop)
			self:SetBackdropColor(0, 0, 0, 1)
			self:SetBackdropBorderColor(.15, .15, .15, 1)
		end
		local function SetupFlyoutButton()
			local button
			for i = 1, numFlyoutButtons do
				button = _G["SpellFlyoutButton"..i]
				if button then
					if not flyoutButtons[button] then
						updateFlyoutButton(button)
						flyoutButtons[button] = true
					end
					if button:GetChecked() == true then
						button:SetChecked(false) -- do we need to see this?
					end
				else
					return
				end
			end
		end
		SpellFlyout:HookScript("OnShow", SetupFlyoutButton)
		hooksecurefunc("ActionButton_UpdateFlyout", UpdateFlyout)
	end)
:EndChain()

function UpdateRangeTimer()
	rangeTimer = -1
end

local function GetSpellIdByName(spellName)
	if not spellName then return end
	local spellLink = GetSpellLink(spellName)
	if spellLink then
		return tonumber(spellLink:match("spell:(%d+)"))
	end
	return nil
end


-----------------------------------------------------------
--- WoW API mapping
--- Generic Button
Generic.HasAction               = function(self) return nil end
Generic.GetActionText           = function(self) return "" end
Generic.GetTexture              = function(self) return nil end
Generic.GetCharges              = function(self) return nil end
Generic.GetCount                = function(self) return 0 end
Generic.GetCooldown             = function(self) return 0, 0, 0 end
Generic.IsAttack                = function(self) return nil end
Generic.IsEquipped              = function(self) return nil end
Generic.IsCurrentlyActive       = function(self) return nil end
Generic.IsAutoRepeat            = function(self) return nil end
Generic.IsUsable                = function(self) return nil end
Generic.IsConsumableOrStackable = function(self) return nil end
Generic.IsUnitInRange           = function(self, unit) return nil end
Generic.IsInRange               = function(self)
	local unit = self:GetAttribute("unit")
	if unit == "player" then
		unit = nil
	end
	local val = self:IsUnitInRange(unit)
	-- map 1/0 to true false, since the return values are inconsistent between actions and spells
	if val == 1 then val = true elseif val == 0 then val = false end
	return val
end
Generic.SetTooltip              = function(self) return nil end
Generic.GetSpellId              = function(self) return nil end
Generic.GetLossOfControlCooldown = function(self) return 0, 0 end


-----------------------------------------------------------
--- Action Button
Action.HasAction               = function(self) return HasAction(self._state_action) end
Action.GetActionText           = function(self) return GetActionText(self._state_action) end
Action.GetTexture              = function(self) return GetActionTexture(self._state_action) end
Action.GetCharges              = function(self) return GetActionCharges(self._state_action) end
Action.GetCount                = function(self) return GetActionCount(self._state_action) end
Action.GetCooldown             = function(self) return GetActionCooldown(self._state_action) end
Action.IsAttack                = function(self) return IsAttackAction(self._state_action) end
Action.IsEquipped              = function(self) return IsEquippedAction(self._state_action) end
Action.IsCurrentlyActive       = function(self) return IsCurrentAction(self._state_action) end
Action.IsAutoRepeat            = function(self) return IsAutoRepeatAction(self._state_action) end
Action.IsUsable                = function(self) return IsUsableAction(self._state_action) end
Action.IsConsumableOrStackable = function(self) return IsConsumableAction(self._state_action) or IsStackableAction(self._state_action) or (not IsItemAction(self._state_action) and GetActionCount(self._state_action) > 0) end
Action.IsUnitInRange           = function(self, unit) return IsActionInRange(self._state_action, unit) end
Action.SetTooltip              = function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetAction(self._state_action) end
Action.GetSpellId              = function(self)
	local actionType, id, subType = GetActionInfo(self._state_action)
	if actionType == "spell" then
		return id
	elseif actionType == "macro" then
		local _, _, spellId = GetMacroSpell(id)
		return spellId
	end
end
Action.GetLossOfControlCooldown = function(self) return GetActionLossOfControlCooldown(self._state_action) end

		
-----------------------------------------------------------
--- Spell Button
Spell.HasAction               = function(self) return true end
Spell.GetActionText           = function(self) return "" end
Spell.GetTexture              = function(self) return GetSpellTexture(self._state_action) end
Spell.GetCharges              = function(self) return GetSpellCharges(self._state_action) end
Spell.GetCount                = function(self) return GetSpellCount(self._state_action) end
Spell.GetCooldown             = function(self) return GetSpellCooldown(self._state_action) end
Spell.IsAttack                = function(self) return IsAttackSpell(FindSpellBookSlotBySpellID(self._state_action), "spell") end -- needs spell book id as of 4.0.1.13066
Spell.IsEquipped              = function(self) return nil end
Spell.IsCurrentlyActive       = function(self) return IsCurrentSpell(self._state_action) end
Spell.IsAutoRepeat            = function(self) return IsAutoRepeatSpell(FindSpellBookSlotBySpellID(self._state_action), "spell") end -- needs spell book id as of 4.0.1.13066
Spell.IsUsable                = function(self) return IsUsableSpell(self._state_action) end
Spell.IsConsumableOrStackable = function(self) return IsConsumableSpell(self._state_action) end
Spell.IsUnitInRange           = function(self, unit) return IsSpellInRange(FindSpellBookSlotBySpellID(self._state_action), "spell", unit) end -- needs spell book id as of 4.0.1.13066
Spell.SetTooltip              = function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetSpellByID(self._state_action) end
Spell.GetSpellId              = function(self) return self._state_action end


-----------------------------------------------------------
--- Item Button
local function getItemId(input)
	return input:match("^item:(%d+)")
end

Item.HasAction               = function(self) return true end
Item.GetActionText           = function(self) return "" end
Item.GetTexture              = function(self) return GetItemIcon(self._state_action) end
Item.GetCharges              = function(self) return nil end
Item.GetCount                = function(self) return GetItemCount(self._state_action, nil, true) end
Item.GetCooldown             = function(self) return GetItemCooldown(getItemId(self._state_action)) end
Item.IsAttack                = function(self) return nil end
Item.IsEquipped              = function(self) return IsEquippedItem(self._state_action) end
Item.IsCurrentlyActive       = function(self) return IsCurrentItem(self._state_action) end
Item.IsAutoRepeat            = function(self) return nil end
Item.IsUsable                = function(self) return IsUsableItem(self._state_action) end
Item.IsConsumableOrStackable = function(self) 
  local stackSize = select(8, GetItemInfo(self._state_action)) -- salvage crates and similar don't register as consumables
  return IsConsumableItem(self._state_action) or stackSize and stackSize > 1
end
Item.IsUnitInRange           = function(self, unit) return IsItemInRange(self._state_action, unit) end
Item.SetTooltip              = function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetHyperlink(self._state_action) end
Item.GetSpellId              = function(self) return nil end


-----------------------------------------------------------
--- Macro Button
-- TODO: map results of GetMacroSpell/GetMacroItem to proper results
Macro.HasAction               = function(self) return true end
Macro.GetActionText           = function(self) return (GetMacroInfo(self._state_action)) end
Macro.GetTexture              = function(self) return (select(2, GetMacroInfo(self._state_action))) end
Macro.GetCharges              = function(self) return nil end
Macro.GetCount                = function(self) return 0 end
Macro.GetCooldown             = function(self) return 0, 0, 0 end
Macro.IsAttack                = function(self) return nil end
Macro.IsEquipped              = function(self) return nil end
Macro.IsCurrentlyActive       = function(self) return nil end
Macro.IsAutoRepeat            = function(self) return nil end
Macro.IsUsable                = function(self) return nil end
Macro.IsConsumableOrStackable = function(self) return nil end
Macro.IsUnitInRange           = function(self, unit) return nil end
Macro.SetTooltip              = function(self) return nil end
Macro.GetSpellId              = function(self) return nil end


-----------------------------------------------------------
--- Custom Button
Custom.HasAction               = function(self) return true end
Custom.GetActionText           = function(self) return "" end
Custom.GetTexture              = function(self) return self._state_action.texture end
Custom.GetCharges              = function(self) return nil end
Custom.GetCount                = function(self) return 0 end
Custom.GetCooldown             = function(self) return 0, 0, 0 end
Custom.IsAttack                = function(self) return nil end
Custom.IsEquipped              = function(self) return nil end
Custom.IsCurrentlyActive       = function(self) return nil end
Custom.IsAutoRepeat            = function(self) return nil end
Custom.IsUsable                = function(self) return true end
Custom.IsConsumableOrStackable = function(self) return nil end
Custom.IsUnitInRange           = function(self, unit) return nil end
Custom.SetTooltip              = function(self) 
	if self._state_action.tooltip then
		return (not GameTooltip:IsForbidden()) and GameTooltip:SetText(self._state_action.tooltip) 
	end
end
Custom.GetSpellId              = function(self) return nil end
Custom.RunCustom               = function(self, unit, button) return self._state_action.func(self, unit, button) end


-----------------------------------------------------------
--- Pet Button
PetAction.HasAction 			= function(self) return GetPetActionInfo(self.id) end
PetAction.GetCooldown 			= function(self) return GetPetActionCooldown(self.id) end
PetAction.IsCurrentlyActive 	= function(self) return select(5, GetPetActionInfo(self.id)) end
PetAction.IsAutoRepeat 			= function(self) return nil end -- select(7, GetPetActionInfo(self.id))
PetAction.SetTooltip 			= function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetPetAction(self:GetID()) end
PetAction.IsAttack 				= function(self) return nil end
PetAction.IsUsable 				= function(self) return GetPetActionsUsable() end
PetAction.GetActionText = function(self)
	local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self.id)
	return isToken and _G[name] or name
end
PetAction.GetTexture = function(self)
	local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self.id)
	return isToken and _G[texture] or texture
end


-----------------------------------------------------------
--- Stance Button
Stance.HasAction = function(self) return GetShapeshiftFormInfo(self.id) end
Stance.GetCooldown = function(self) return GetShapeshiftFormCooldown(self.id) end
Stance.GetActionText = function(self) return select(2,GetShapeshiftFormInfo(self.id)) end
Stance.GetTexture = function(self) return GetShapeshiftFormInfo(self.id) end
Stance.IsCurrentlyActive = function(self) return select(3,GetShapeshiftFormInfo(self.id)) end
Stance.IsUsable = function(self) 
	return IsUsableAction(self._state_action)
	--return (select(4,GetShapeshiftFormInfo(self.id)))
end
Stance.SetTooltip = function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetShapeshift(self.id) end


