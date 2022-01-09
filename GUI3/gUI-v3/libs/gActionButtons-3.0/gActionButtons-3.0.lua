--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local MAJOR, MINOR = "gActionButtons-3.0", 8
local gABT, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not(gABT) then return end 

assert(LibStub("gCore-4.0"), MAJOR .. ": Cannot find an instance of gCore-4.0")

local pairs, select = pairs, select
local strfind = string.find
local type = type
local min, max = math.min, math.max

local ActionHasRange = ActionHasRange
local GetActionCooldown = GetActionCooldown
local GetActionInfo = GetActionInfo
local GetItemInfo = GetItemInfo
local IsActionInRange = IsActionInRange
local IsEquippedAction = IsEquippedAction
local IsUsableAction = IsUsableAction

gABT.scheduler = gABT.scheduler or LibStub("gCore-4.0"):NewAddon(MAJOR)

-- gABT.gloss = gABT.gloss -- texture path for gloss texture
-- gABT.shade = gABT.shade -- texture path for shade texture
-- gABT.hideHotkeys = gABT.hideHotkeys -- true to hide hotkeys, nil to show
-- gABT.hideMacros = gABT.hideMacros -- true to hide macro names, nil to show
-- gABT.hotkeyFont = gABT.hotkeyFont -- fontobject for hotkey display
-- gABT.macroFont = gABT.macroFont -- fontobject for macro names
-- gABT.countFont = gABT.countFont -- font object for charges/stack size
gABT.glossAlpha = gABT.glossAlpha or 1/3 -- alpha of gloss layer
gABT.shadeAlpha = gABT.shadeAlpha or 1/2 -- alpha of shade layer
gABT.borderSize = gABT.borderSize or 0 -- thickness of the button borders/amount to indent content
gABT.overlay = gABT.overlay or [[Interface\ChatFrame\ChatFrameBackground]] -- overlay texture for hover, range, mana, etc
gABT.backdrop = gABT.backdrop or {  -- backdrop for button styling
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground";
	edgeFile = "Interface\\ChatFrame\\ChatFrameBackground";
	edgeSize = 1;
}

local noop = noop or function() end

-- default colors
local C = {
	-- colors the border
	background = { 0.55, 0.55, 0.55 }; -- the background of the backdrop
	normal = { 0.15, 0.15, 0.15 }; -- normal state, when nothing else applies
	equipped = { 0.10, 0.85, 0.10 }; -- equipped items
	borderchecked = { 1, 1, 0.9 }; 
	
	-- colors the overlay
	oom = { 0.05, 0.05, 1.0, 1 }; -- you haven't enough mana/or other resource. seems to vary
	oor = { 1.00, 0.05, 0.05, 1 }; -- target is out of range
	usable = { 1.00, 1.00, 1.00, 1 }; -- an item or ability is usable 
	unusable = { 0.65, 0.65, 0.65, 1 }; -- an item or ability is not usable. this might also apply to missing resource (shadowburn)
	
	-- overlay coloring, but not with options. yet.
	gloss = { 1, 1, 1 }; -- gloss layer
	shade = { 0, 0, 0 }; -- shade layer
	checked = { 1, 1, 0.9 }; -- when checked (active stance, etc)
	flash = { 1, 0, 0, 0.3 }; -- flashing
	hover = { 1, 1, 1, 0.3 }; -- when hovering over a button
	pushed = { 1, 0.82, 0, 0.3 }; -- when pushing a button
}

local buttons, petbuttons, stancebuttons = {}, {}, {}
local custombuttons = {}

-- populate default button tables
for i = 1, NUM_PET_ACTION_SLOTS do tinsert(petbuttons, _G["PetActionButton" .. i]) end
for i = 1, NUM_STANCE_SLOTS do tinsert(stancebuttons, _G["StanceButton" .. i]) end
for i = 1, NUM_ACTIONBAR_BUTTONS do
	tinsert(buttons, _G["ActionButton" .. i])
	tinsert(buttons, _G["MultiBarBottomLeftButton" .. i])
	tinsert(buttons, _G["MultiBarBottomRightButton" .. i])
	tinsert(buttons, _G["MultiBarRightButton" .. i])
	tinsert(buttons, _G["MultiBarLeftButton" .. i])
end
tinsert(buttons, _G["ExtraActionButton1"])

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

-- limit a number to <0, 1>
local limit = function(n)
	argCheck(n, 1, "number")
	return max(min(n, 1), 0)
end

------------------------------------------------------------------------------------------------------------
-- 	Element Styling
------------------------------------------------------------------------------------------------------------
local UpdateOverlayColor, UpdateFlyout
local UpdateShade, UpdateGloss
local UpdateCooldown
local UpdateHotkey, UpdateMacro
local StyleHotkey, SetText
local UpdateBorderColor, ShowOverlayGlow, HideOverlayGlow
local OnUpdate, OnEvent
local StyleButton, StylePetButton, StyleStanceButton
local UpdateCooldowns, StyleStanceButtons, StylePetButtons
local UpdateHotkeys, UpdateMacros

UpdateBorderColor = function(self)
	if not(self) then return end
	if (self.action) and (IsEquippedAction(self.action)) and (self.ItemRarity) and (self.ItemRarity > 1) then  
		local r, g, b = GetItemQualityColor(self.ItemRarity)
		-- self:SetBackdropBorderColor(r * 4/5, g * 4/5, b * 4/5, 1)
		self:SetBackdropBorderColor(r, g, b, 1)
	else
		local checked = _G[self:GetName() .. "CheckedTex"]
		if (checked) and (checked:IsShown()) then
			self:SetBackdropBorderColor(unpack(C.borderchecked))
		else
			self:SetBackdropBorderColor(unpack(C.normal))
		end
	end
end

UpdateOverlayColor = function(self)
	if not(self) or not(self.action) then return end
	
	UpdateBorderColor(self)
		
	local isUsable, notEnoughMana = IsUsableAction(self.action)
	if (self.Icon) then
		if (ActionHasRange(self.action)) and (IsActionInRange(self.action) == 0) then
			self.Icon:SetVertexColor(unpack(C.oor))
			self.Icon:SetDesaturated(true)
		elseif (notEnoughMana) then
			self.Icon:SetVertexColor(unpack(C.oom))
			self.Icon:SetDesaturated(true)
		elseif (isUsable) then
			self.Icon:SetVertexColor(unpack(C.usable)) -- normal color
			self.Icon:SetDesaturated(false)
		else
			self.Icon:SetVertexColor(unpack(C.unusable))
			self.Icon:SetDesaturated(true)
		end
	end
end

OnUpdate = function(self, elapsed)
	local t = self.rangetimer
	
	if not(t) then
		self.rangetimer = 0
		return
	end
	
	t = t + elapsed
	
	if (t < (rangetimer or 0.1)) then
		self.rangetimer = t
		return
	else
		-- just zero it out
		-- less accurate, but our goal is not timing, it is updating
		self.rangetimer = 0 
	end
	
	UpdateOverlayColor(self)
end

UpdateFlyout = function(self)
end

-- ToDo: 
-- 	Custom cooldown counter and shine effects
UpdateCooldown = function(self)
	local start, duration, enable = 0, 0, 0
	if (self.action) then
		start, duration, enable = GetActionCooldown(self.action)
	end
end

SetText = function(msg)
	return (gABT.setText) and gABT.setText(msg) or msg
end

StyleHotkey = function(text, hotkey, button, actionButtonType)
	if (text == _G["RANGE_INDICATOR"]) then
		hotkey:SetText("")
	else
		hotkey:SetText(SetText(text))
	end
end

UpdateHotkey = function(self, actionButtonType)
	if not(self) or not(self:GetName()) then return end
	local hotkey = _G[self:GetName() .. "HotKey"]
	if not(hotkey) then return end
	
	local text = hotkey:GetText()
	if (text) then
		StyleHotkey(text, hotkey, self, actionButtonType)
	end
	
	if (gABT:ShowHotkeys()) then
		hotkey:Show()
	else
		hotkey:Hide()
	end
end 

UpdateMacro = function(self)
	if not(self.Macro) then return end
	if (gABT:ShowMacros()) then
		self.Macro:Show()
	else
		self.Macro:Hide()
	end
end

UpdateShade = function(self)
	local shadeTex = gABT:GetShadeTexture()
	if not(self.Shade) and (shadeTex) then
		self.Shade = self:CreateTexture()
		self.Shade:SetTexture(shadeTex)
		self.Shade:SetVertexColor(C.shade[1], C.shade[2], C.shade[3], gABT:GetShadeAlpha())
		self.Shade:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Shade:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
	end
end

UpdateGloss = function(self)
	local glossTex = gABT:GetGlossTexture()
	if not(self.Gloss) and (glossTex) then
		self.Gloss = self:CreateTexture()
		self.Gloss:SetTexture(glossTex)
		self.Gloss:SetVertexColor(C.gloss[1], C.gloss[2], C.gloss[3], gABT:GetGlossAlpha())
		self.Gloss:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Gloss:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
	end
	if not(self.Icon) or not(self.Icon:GetTexture()) or (self.Icon:GetTexture() == "") then
		self.Gloss:Hide()
	else
		self.Gloss:Show()
	end
end

ShowOverlayGlow = function(self)
end

HideOverlayGlow = function(self)
end

UpdateCooldowns = function()
end

UpdateHotkeys = function(self)
	if not(gABT.started) then return end
	for i = 1, #buttons do UpdateHotkey(buttons[i]) end
	for i = 1, #petbuttons do UpdateHotkey(petbuttons[i]) end
	for i = 1, #stancebuttons do UpdateHotkey(stancebuttons[i]) end
end

UpdateMacros = function(self)
	if not(gABT.started) then return end
	for i = 1, #buttons do UpdateMacro(buttons[i]) end
end


------------------------------------------------------------------------------------------------------------
-- 	Main styling functions
------------------------------------------------------------------------------------------------------------
StyleButton = function(self)
	if not(self) then return end

	local name = self:GetName()
	local actionType, ID, subType
	if (self.action) then
		actionType, ID, subType = GetActionInfo(self.action)
	end

	self.Button = self
	self.ActionType = actionType
	self.ItemID = actionType == "item" and ID
	self.ItemRarity = actionType == "item" and (select(3,GetItemInfo(ID)))
	self.Name = name

	self.Autocast = self.Autocast or _G[name .. "AutoCastable"]
	self.Background = self.Background or _G[name].background
	self.Border = self.Border or _G[name .. "Border"]
	self.Cooldown = self.Cooldown or _G[name .. "Cooldown"]
	self.Count = self.Count or _G[name .. "Count"]
	self.Flash = self.Flash or _G[name .. "Flash"]
	self.FloatingBG = self.FloatingBG or _G[name .. "FloatingBG"]
	self.FlyoutBorder = self.FlyoutBorder or _G[name .. "FlyoutBorder"]
	self.FlyoutBorderShadow = self.FlyoutBorderShadow or _G[name .. "FlyoutBorderShadow"]
	self.Frame = self.Frame or _G[name .. "Frame"]
	self.Gloss = self.Gloss or _G[name .. "Gloss"]
	self.Highlight = self.Highlight or _G[name .. "Highlight"] or _G[name .. "_Highlight"] -- Healium
	self.Hotkey = self.Hotkey or _G[name .. "HotKey"]
	self.Hover = self.Hover or _G[name .. "HoverTex"]
	self.Icon = self.Icon or _G[name .. "Icon"] or _G[name .. "IconTexture"] or _G[name .. "_Icon"] -- Healium
	self.Macro = self.Macro or _G[name .. "Name"]
	self.NormalTexture = self.NormalTexture or _G[name .. "NormalTexture"] or _G[name .. "NormalTexture2"]
	self.Overlay = self.Overlay or _G[name].overlay
	self.Panel = self.Panel or _G[name .. "Panel"]
	self.Pushed = self.Pushed or _G[name .. "PushedTex"]
	self.Shade = self.Shade or _G[name .. "Shade"]
	self.Shine = self.Shine or _G[name .. "Shine"]

	self:SetBackdrop(gABT:GetBackdrop())
	self:SetBackdropColor(gABT:GetBackgroundColor())
	UpdateBorderColor(self)
	-- self:SetBackdropBorderColor(gABT:GetNormalColor())
	
	-- what we always hide
	self.Button:SetNormalTexture("")
	if (self.Border) then self.Border:SetAlpha(0) end
	if (self.Frame) and (self.Frame.SetTexture) then self.Frame:SetTexture("") end
	if (self.FloatingBG) then self.FloatingBG:SetAlpha(0) end
	if (self.FlyoutBorder) then self.FlyoutBorder:SetAlpha(0) end
	if (self.FlyoutBorderShadow) then self.FlyoutBorderShadow:SetAlpha(0) end
	if (self.Highlight) then self.Highlight:SetAlpha(0) end

	if (self.Overlay) then end -- don't reposition this, it's animated and you'll crash WoW!
	
	if (self.NormalTexture) then
		self.NormalTexture:ClearAllPoints()
		self.NormalTexture:SetPoint("TOPLEFT", self.Button, "TOPLEFT", -gABT.borderSize, gABT.borderSize)
		self.NormalTexture:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", gABT.borderSize, -gABT.borderSize)
		self.NormalTexture:SetVertexColor(unpack(C.normal))
	end
	
	if (self.Icon) then
		self.Icon:ClearAllPoints()
		self.Icon:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Icon:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
		self.Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		self.Icon:SetDrawLayer("ARTWORK", 0)
	end

	-- add or adjust new search overlay
	--[[
	if (self.Search) then
		self.Search:SetDrawLayer("OVERLAY", 7)
		self.Search:ClearAllPoints()
		self.Search:SetPoint("TOPLEFT", self, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Search:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
		
	else 
		self.Search = self:CreateTexture()
		self.Search:SetDrawLayer("OVERLAY", 1)
		self.Search:SetTexture(M["Background"]["Blank"])
		self.Search:SetVertexColor(0, 0, 0)
		self.Search:SetAlpha(4/5)
		self.Search:ClearAllPoints()
		self.Search:SetPoint("TOPLEFT", self, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Search:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
		
		if (self:GetName()) then
			_G[self:GetName() .. "Search"] = self.Search
		end
	end
	]]--
		
	if (self.Background) then
		self.Background:ClearAllPoints()
		self.Background:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Background:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
	end

	-- autocast ant trails and corner indicators
	if (self.Autocast) then
		self.Autocast:ClearAllPoints()
		self.Autocast:SetPoint("TOPLEFT", self.Button, "TOPLEFT", -12, 12)
		self.Autocast:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", 12, -12)
	end

	if (self.Shine) then
		self.Shine:ClearAllPoints()
		self.Shine:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Shine:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
	end

	if (self.Cooldown) then
		self.Cooldown:ClearAllPoints()
		self.Cooldown:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Cooldown:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
	end
	
	if (self.Count) then
		self.Count:ClearAllPoints()
		self.Count:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -1, 3)
		if (gABT.countFont) then
			self.Count:SetFontObject(gABT.countFont)
		end
		self.Count:SetJustifyH("RIGHT")
		self.Count:SetJustifyV("BOTTOM")
		self.Count:SetDrawLayer("OVERLAY", 4)
	end

	if (self.Hotkey) then
		-- self.Hotkey:ClearAllPoints()
		-- self.Hotkey:SetPoint("TOPRIGHT", self.Button, "TOPRIGHT", -1, -5)
		-- self.Hotkey.SetPoint = noop
		-- self.Hotkey.SetAllPoints = noop
		-- self.Hotkey.ClearAllPoints = noop
		self.Hotkey:SetWidth(self.Button:GetWidth())
		if (gABT.hotkeyFont) then
			self.Hotkey:SetFontObject(gABT.hotkeyFont)
		end
		self.Hotkey:SetJustifyH("RIGHT")
		self.Hotkey:SetJustifyV("TOP")
		self.Hotkey:SetDrawLayer("OVERLAY", 4)

		UpdateHotkey(self)
	end

	if (self.Macro) then
		self.Macro:ClearAllPoints()
		self.Macro:SetPoint("BOTTOMLEFT", self.Button, "BOTTOMLEFT", 2, 2)
		self.Macro:SetWidth(self.Button:GetWidth())
		if (gABT.macroFont) then
			self.Macro:SetFontObject(gABT.macroFont)
		end
		self.Macro:SetJustifyH("LEFT")
		self.Macro:SetJustifyV("BOTTOM")
		self.Macro:SetDrawLayer("OVERLAY", 3)

		UpdateMacro(self)
	end

	if (self.Flash) then
		self.Flash:SetTexture(unpack(C.flash))
		self.Flash:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		self.Flash:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
	end
	
	if (self.Button.SetHighlightTexture) and (not _G[self.Name .. "HoverTex"]) then
		local hover = self.Button:CreateTexture(self.Name .. "HoverTex", nil, self)
		hover:SetTexture(gABT:GetTexture())
		hover:SetVertexColor(unpack(C.hover))
		hover:ClearAllPoints()
		hover:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
		hover:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
--		hover:SetDrawLayer("OVERLAY", 1)
		self.Button:SetHighlightTexture(hover)
	end
 
	if (self.Button.SetPushedTexture) then
		if (_G[self.Name .. "PushedTex"]) then
			self.Button:GetPushedTexture():SetDrawLayer("OVERLAY")
		else
			local pushed = self.Button:CreateTexture(self.Name .. "PushedTex", nil, self)
			pushed:SetTexture(gABT:GetTexture())
			pushed:SetVertexColor(unpack(C.pushed))
			pushed:ClearAllPoints()
			pushed:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
			pushed:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
			pushed:SetDrawLayer("OVERLAY")
			self.Button:SetPushedTexture(pushed)
			self.Button:GetPushedTexture():SetDrawLayer("OVERLAY")
			
			_G[self.Name .. "PushedTex"] = pushed
		end
	end
 
	if (self.Button.SetCheckedTexture) then 
		if (_G[self.Name .. "CheckedTex"]) then
			self.Button:GetCheckedTexture():SetDrawLayer("OVERLAY")
		else
			local checked = self.Button:CreateTexture(self.Name .. "CheckedTex", nil, self)
			checked:SetTexture(gABT:GetTexture())
			checked:SetVertexColor(C.checked[1], C.checked[2], C.checked[3], 0.3)
			checked:ClearAllPoints()
			checked:SetPoint("TOPLEFT", self.Button, "TOPLEFT", gABT.borderSize, -gABT.borderSize)
			checked:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -gABT.borderSize, gABT.borderSize)
			checked:SetDrawLayer("OVERLAY")
			self.Button:SetCheckedTexture(checked)
			self.Button:GetCheckedTexture():SetDrawLayer("OVERLAY")
			
			_G[self.Name .. "CheckedTex"] = checked
		end
	end
	
	if (gABT:GetGlossTexture()) then
		UpdateGloss(self)
		self.Gloss:SetDrawLayer("OVERLAY", 2)
		self.Gloss:SetAlpha(gABT:GetGlossAlpha())
	end
	
	if (gABT:GetShadeTexture()) then
		UpdateShade(self)
		self.Shade:SetDrawLayer("OVERLAY", 1)
		self.Shade:SetAlpha(gABT:GetShadeAlpha())
	end

	-- UpdateCooldown(self)
end

StylePetButton = function(self)
	StyleButton(self)
end

StyleStanceButton = function(self)
	StyleButton(self)
end

StyleButtons = function()
	for i = 1, #buttons do
		StyleButton(buttons[i])
	end
end

StylePetButtons = function()
	for i = 1, #petbuttons do
		StylePetButton(petbuttons[i])
	end
end

StyleStanceButtons = function()
	for i = 1, #stancebuttons do 
		StyleStanceButton(stancebuttons[i])
	end
end

------------------------------------------------------------------------------------------------------------
-- 	Library API
------------------------------------------------------------------------------------------------------------
-- nothing happens before we call this, 
-- but when we do, there is no way back
gABT.Start = function(self)
	if (gABT.started) then
		return
	end

	self.scheduler:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self.scheduler:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self.scheduler:RegisterEvent("UPDATE_SHAPESHIFT_USABLE", self.scheduler.UPDATE_SHAPESHIFT_FORMS)
	self.scheduler:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", self.scheduler.UPDATE_SHAPESHIFT_FORMS)
	self.scheduler:RegisterEvent("UPDATE_SHAPESHIFT_FORM", self.scheduler.UPDATE_SHAPESHIFT_FORMS)
	self.scheduler:RegisterEvent("ACTIONBAR_PAGE_CHANGED", self.scheduler.UPDATE_SHAPESHIFT_FORMS)
	self.scheduler:RegisterEvent("PET_BAR_UPDATE")
	self.scheduler:RegisterEvent("PLAYER_CONTROL_GAINED", self.scheduler.PET_BAR_UPDATE)
	self.scheduler:RegisterEvent("PLAYER_CONTROL_LOST", self.scheduler.PET_BAR_UPDATE)
	self.scheduler:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED", self.scheduler.PET_BAR_UPDATE)
	self.scheduler:RegisterEvent("PET_BAR_HIDE", self.scheduler.PET_BAR_UPDATE)
	self.scheduler:RegisterEvent("PET_UI_UPDATE", self.scheduler.PET_BAR_UPDATE)
	self.scheduler:RegisterEvent("PET_BAR_UPDATE_USABLE", self.scheduler.PET_BAR_UPDATE)
	self.scheduler:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", self.scheduler.PET_BAR_UPDATE)
	self.scheduler:RegisterEvent("SPELL_ACTIVATION_OVERLAY_SHOW")
	self.scheduler:RegisterEvent("SPELL_ACTIVATION_OVERLAY_HIDE")
	self.scheduler:RegisterEvent("UNIT_FLAGS", self.scheduler.PET_BAR_UPDATE)
	self.scheduler:RegisterEvent("UNIT_PET", function(self, event, ...)
		local arg1 = ...
		if (arg1 == "player") then
			self:PET_BAR_UPDATE(event, ...)
		end
	end)
	self.scheduler:RegisterEvent("UNIT_AURA", function(self, event, ...)
		local arg1 = ...
		if (arg1 == "pet") then
			self:PET_BAR_UPDATE(event, ...)
		end
	end)

	hooksecurefunc("ActionButton_Update", StyleButton)
	hooksecurefunc("ActionButton_UpdateUsable", UpdateOverlayColor)
	hooksecurefunc("ActionButton_OnUpdate", OnUpdate)
	hooksecurefunc("ActionButton_ShowGrid", UpdateBorderColor)
	hooksecurefunc("ActionButton_UpdateHotkeys", UpdateHotkey)
	hooksecurefunc("ActionButton_ShowOverlayGlow", ShowOverlayGlow)
	hooksecurefunc("ActionButton_HideOverlayGlow", HideOverlayGlow)
	hooksecurefunc("ActionButton_UpdateFlyout", UpdateFlyout)
	
	gABT.started = true
	
	self.scheduler:FireCallback("GABT_LOADED")
end

gABT.RegisterCustomButton = function(self, button)
	custombuttons[button] = true
end

gABT.GetCustomButtons = function(self)
	return custombuttons
end

gABT.GetActionButtons = function(self)
	return buttons
end

gABT.GetPetButtons = function(self)
	return petbuttons
end

gABT.GetStanceButtons = function(self)
	return stancebuttons
end

gABT.SetBackdrop = function(self, backdrop)
	argCheck(backdrop, 1, "table")
	self.backdrop = backdrop
end

gABT.GetBackdrop = function(self)
	return self.backdrop
end

gABT.SetTexture = function(self, texture)
	argCheck(texture, 1, "string")
	self.overlay = texture
end

gABT.GetTexture = function(self)
	return self.overlay
end

gABT.SetTextFunction = function(self, func)
	argCheck(func, 1, "function")
	self.setText = func
end

gABT.SetHotkeyFontObject = function(self, fontObject)
	self.hotkeyFont = fontObject
	UpdateHotkeys()
end

gABT.GetHotkeyFontObject = function(self, fontObject)
	return self.hotkeyFont
end

gABT.SetMacroFontObject = function(self, fontObject)
	self.macroFont = fontObject
	UpdateMacros()
end

gABT.GetMacroFontObject = function(self, fontObject)
	return self.macroFont
end

gABT.SetCountFontObject = function(self, fontObject)
	self.countFont = fontObject
end

gABT.GetCountFontObject = function(self, fontObject)
	return self.countFont
end

gABT.ShowHotkeys = function(self)
	return not(self.hideHotkeys)
end

gABT.ShowMacros = function(self)
	return not(self.hideMacros)
end

gABT.SetEnableHotkeys = function(self, enable)
	self.hideHotkeys = not(enable)
	UpdateHotkeys()
end

gABT.SetEnableMacros = function(self, enable)
	self.hideMacros = not(enable)
	UpdateMacros()
end

gABT.SetGlossTexture = function(self, texture)
	argCheck(texture, 1, "string")
	self.gloss = texture
end

gABT.GetGlossTexture = function(self)
	return self.gloss
end

gABT.SetShadeTexture = function(self, texture)
	argCheck(texture, 1, "string")
	self.shade = texture
end

gABT.GetShadeTexture = function(self)
	return self.shade
end

gABT.SetGlossAlpha = function(self, a)
	argCheck(a, 1, "number")
	self.glossAlpha = limit(a)
end

gABT.GetGlossAlpha = function(self, a)
	return self.glossAlpha
end

gABT.SetShadeAlpha = function(self, a)
	argCheck(a, 1, "number")
	self.shadeAlpha = limit(a)
end

gABT.GetShadeAlpha = function(self, a)
	return self.shadeAlpha
end

gABT.SetBackgroundColor = function(self, r, g, b)
	argCheck(r, 1, "number")
	argCheck(g, 1, "number")
	argCheck(b, 1, "number")
	C.background[1] = limit(r)
	C.background[2] = limit(g)
	C.background[3] = limit(b)
end

gABT.SetNormalColor = function(self, r, g, b)
	argCheck(r, 1, "number")
	argCheck(g, 1, "number")
	argCheck(b, 1, "number")
	C.normal[1] = limit(r)
	C.normal[2] = limit(g)
	C.normal[3] = limit(b)
end

gABT.SetEquippedColor = function(self, r, g, b)
	argCheck(r, 1, "number")
	argCheck(g, 1, "number")
	argCheck(b, 1, "number")
	C.equipped[1] = limit(r)
	C.equipped[2] = limit(g)
	C.equipped[3] = limit(b)
end

gABT.SetOutOfManaColor = function(self, r, g, b)
	argCheck(r, 1, "number")
	argCheck(g, 1, "number")
	argCheck(b, 1, "number")
	C.oom[1] = limit(r)
	C.oom[2] = limit(g)
	C.oom[3] = limit(b)
end

gABT.SetOutOfRangeColor = function(self, r, g, b)
	argCheck(r, 1, "number")
	argCheck(g, 1, "number")
	argCheck(b, 1, "number")
	C.oor[1] = limit(r)
	C.oor[2] = limit(g)
	C.oor[3] = limit(b)
end

gABT.SetUsableColor = function(self, r, g, b)
	argCheck(r, 1, "number")
	argCheck(g, 1, "number")
	argCheck(b, 1, "number")
	C.usable[1] = limit(r)
	C.usable[2] = limit(g)
	C.usable[3] = limit(b)
end

gABT.SetUnusableColor = function(self, r, g, b)
	argCheck(r, 1, "number")
	argCheck(g, 1, "number")
	argCheck(b, 1, "number")
	C.unusable[1] = limit(r)
	C.unusable[2] = limit(g)
	C.unusable[3] = limit(b)
end

gABT.GetBackgroundColor = function(self, r, g, b)
	return unpack(C.background)
end

gABT.GetNormalColor = function(self, r, g, b)
	return unpack(C.normal)
end

gABT.GetEquippedColor = function(self, r, g, b)
	return unpack(C.equipped)
end

gABT.GetOutOfManaColor = function(self, r, g, b)
	return unpack(C.oom)
end

gABT.GetOutOfRangeColor = function(self, r, g, b)
	return unpack(C.oor)
end

gABT.GetUsableColor = function(self, r, g, b)
	return unpack(C.usable)
end

gABT.GetUnusableColor = function(self, r, g, b)
	return unpack(C.unusable)
end

gABT.GetStyleFunction = function(self)
	return StyleButton
end

gABT.SetBorderSize = function(self, size)
	argCheck(size, 1, "number")
	self.borderSize = size
end

gABT.GetBorderSize = function(self)
	return self.borderSize
end

------------------------------------------------------------------------------------------------------------
-- 	Event Handling
------------------------------------------------------------------------------------------------------------
gABT.scheduler.OnInit = function(self)
end

gABT.scheduler.OnEnable = function(self)
end

gABT.scheduler.OnEnter = function(self)
	if not(gABT.started) then return end

	-- initial forced button styling
	StyleButtons()
	StylePetButtons()
	StyleStanceButtons()
	UpdateHotkeys()
	UpdateMacros()
end

gABT.scheduler.ACTIONBAR_UPDATE_COOLDOWN = function(self)
	UpdateCooldowns()
end

gABT.scheduler.UPDATE_SHAPESHIFT_FORMS = function(self)
	StyleStanceButtons()
end

gABT.scheduler.PET_BAR_UPDATE = function(self)
	StylePetButtons()
end

gABT.scheduler.SPELL_ACTIVATION_OVERLAY_SHOW = function(self)
	--[[
	local actionType, id, subType = GetActionInfo(self.action);
	if ( actionType == "spell" and id == arg1 ) then
		ActionButton_ShowOverlayGlow(self);
	elseif ( actionType == "macro" ) then
		local _, _, spellId = GetMacroSpell(id);
		if ( spellId and spellId == arg1 ) then
			ActionButton_ShowOverlayGlow(self);
		end
	end
	]]--
end

gABT.scheduler.SPELL_ACTIVATION_OVERLAY_HIDE = function(self)
	--[[
	local actionType, id, subType = GetActionInfo(self.action)
	if ( actionType == "spell" and id == arg1 ) then
		ActionButton_HideOverlayGlow(self);
	elseif ( actionType == "macro" ) then
		local _, _, spellId = GetMacroSpell(id);
		if (spellId and spellId == arg1 ) then
			ActionButton_HideOverlayGlow(self);
		end
	end
	]]--
end

