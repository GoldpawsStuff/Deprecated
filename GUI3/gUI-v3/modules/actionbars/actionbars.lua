--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Actionbars")
local LKB = LibStub("LibKeyBound-1.0")
local gAB = LibStub("gActionBars-3.0")
local gABT = LibStub("gActionButtons-3.0")

local format = string.format
local pairs, unpack, select = pairs, unpack, select

local CreateFrame = CreateFrame
local GetBindingAction = GetBindingAction
local GetBindingKey = GetBindingKey
local GetBindingText = GetBindingText
local SetBinding = SetBinding
local ActionButton_HideGrid = ActionButton_HideGrid
local ActionButton_ShowGrid = ActionButton_ShowGrid

local L, C, F, M, db
local layouts = {} -- will be defined later
local EDGE = 8
local MIN_BUTTON_SIZE, MAX_BUTTON_SIZE, GENERIC_BUTTON_SIZE = 29, 46, 56 + 6
local MIN_MICRO_SIZE, MAX_MICRO_SIZE = 18, 24 -- this keeps them at a max height of 29
-- local TEST_LAYOUT = 1 -- for development purposes only

local playerClass = select(2, UnitClass("player"))

-- ToDo:
-- optional number of bars and buttons, 
-- and update gCore-4.0 to accept variable size tables in saved settings
local defaults = {
	-- extra page switches
	-- we're keeping these as separate options, though it's not strictly needed
	-- this is because of our planned custom functionality later
	useProwlBar = false; 
	useShadowDanceBar = false;
	useMetaMorphBar = false;
	useWarriorStanceBars = false;
	
	-- our replaced blizzard option
	lockActionBars = true;
	
	showHotkeys = false; -- hotkeys on actionbuttons
	showMacros = false; -- macro names on actionbuttons
	
	-- bar visibility and layout
	showMicroMenu = true; -- our custom micromenu 
	showVehicleExitButtons = true; -- the vehicle exit buttons around the main bar
	vehicleExitButton = {
		place = { "CENTER", "UIParent", "CENTER", -270, -150 };
	};
	layout = 1;
	layouts = {
		[1] = {
			["1"] = {
				place = { "BOTTOM", "UIParent", "BOTTOM", 0, 12 + 29 + 2 };
				visible = true;
				hover = false;
				rotated = false; 
				width = NUM_ACTIONBAR_BUTTONS;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["2"] = {
				place = { "BOTTOM", "UIParent", "BOTTOM", 0, 12 };
				visible = true;
				rotated = false; 
				hover = false;
				width = NUM_ACTIONBAR_BUTTONS;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["3a"] = {
				-- place = { "BOTTOMRIGHT", "UIParent", "BOTTOM", -( (29 * NUM_ACTIONBAR_BUTTONS)/2 + (2*(NUM_ACTIONBAR_BUTTONS - 1))/2 + 11), 12 }; 
				place = { "BOTTOMRIGHT", "UIParent", "BOTTOM", -196, 12 }; 
				visible = true;
				rotated = false; 
				hover = false;
				width = 3;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["3b"] = {
				-- place = { "BOTTOMLEFT", "UIParent", "BOTTOM", ( (29 * NUM_ACTIONBAR_BUTTONS)/2 + (2*(NUM_ACTIONBAR_BUTTONS - 1))/2 + 11), 12 }; 
				place = { "BOTTOMLEFT", "UIParent", "BOTTOM", 196, 12 }; 
				visible = true;
				rotated = false; 
				hover = false;
				width = 3;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["3"] = {
				place = { "RIGHT", "UIParent", "RIGHT", -(12 + (29 + 2)*2), 0 };
				visible = true;
				rotated = false;
				hover = false;
				width = 1;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["4"] = {
				place = { "RIGHT", "UIParent", "RIGHT", -12, 0 };
				visible = true;
				rotated = false; 
				hover = false;
				width = 1;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["5"] = {
				place = { "RIGHT", "UIParent", "RIGHT", -(12 + 29 + 2), 0 };
				visible = true;
				rotated = false;
				hover = false;
				width = 1;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["shift"] = {
				place = { "TOPLEFT", "UIParent", "TOPLEFT", 180, -8 };
				visible = true;
				rotated = false;
				hover = false;
				width = NUM_STANCE_SLOTS;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["pet"] = {
				place = { "BOTTOM", "UIParent", "BOTTOM", 0, 260 };
				visible = true;
				rotated = false;
				hover = false;
				width = NUM_PET_ACTION_SLOTS;
				buttonsize = MIN_BUTTON_SIZE;
			};
			["micro"] = {
				place = { "TOP", "UIParent", "TOP", 0, -12 };
				visible = true;
				rotated = false;
				hover = false;
				width = 12;
				buttonsize = 18;
			};
			-- ["extra"] = {
				-- place = { "CENTER", "UIParent", "CENTER", 0, 0 };
				-- visible = true;
			-- };
		};
	};
}

--------------------------------------------------------------------------------------------------
--		Keybind functionality (integrated directly into this module in v3)
--------------------------------------------------------------------------------------------------
do
	local buttons = {}
	module.CreateBindingTable = function(self)
		for i = 1, NUM_ACTIONBAR_BUTTONS do
			buttons["ActionButton" .. i] = "ACTIONBUTTON" .. i
			buttons["MultiBarBottomLeftButton" .. i] = "MULTIACTIONBAR1BUTTON" .. i
			buttons["MultiBarBottomRightButton" .. i] = "MULTIACTIONBAR2BUTTON" .. i
			buttons["MultiBarRightButton" .. i] = "MULTIACTIONBAR3BUTTON" .. i
			buttons["MultiBarLeftButton" .. i] = "MULTIACTIONBAR4BUTTON" .. i
		end
		buttons["ExtraActionButton1"] = "EXTRAACTIONBUTTON1"
		
		for i = 1, NUM_PET_ACTION_SLOTS do
			buttons["PetActionButton" .. i] = "BONUSACTIONBUTTON" .. i
		end

		for i = 1, NUM_STANCE_SLOTS do 
			buttons["StanceButton" .. i] = "SHAPESHIFTBUTTON" .. i 
		end
	end
	module.buttons = buttons

	module.GetOverlayFrame = function(self)
		if not(self.overlayFrame) then
			local overlayFrame = CreateFrame("Frame", self:GetName() .. "_OverlayFrame", UIParent)
			overlayFrame:SetFrameStrata("DIALOG")
			overlayFrame:EnableMouse(false)
			overlayFrame:Hide()
			self.overlayFrame = overlayFrame
		end
		return self.overlayFrame
	end

	module.ToggleOverlayFrame = function(self)
		local overlayFrame = self:GetOverlayFrame()
		if (self.keyBoundMode) then
			overlayFrame:Show()
		else
			overlayFrame:Hide()
		end
	end

	module.LIBKEYBOUND_ENABLED = function(self)
		self.keyBoundMode = true
		self:ToggleOverlayFrame()
	end

	module.LIBKEYBOUND_DISABLED = function(self)
		self.keyBoundMode = nil
		self:ToggleOverlayFrame()
	end

	module.LIBKEYBOUND_MODE_COLOR_CHANGED = function(self)
		local overlayFrame = self:GetOverlayFrame()
		for i = 1, overlayFrame:GetNumRegions() do
			local region = select(i, overlayFrame:GetRegions())
			if (region:GetObjectType() == "Frame") and (region:GetBackdrop()) then
				region:SetBackdropColor(LKB:GetColorKeyBoundMode())
			end
		end
		self:ToggleOverlayFrame()
	end

	--
	-- setup a button to work with LibKeyBound
	-- 	*we've replaced most of LibKeyBound's own functions, 
	-- 		to make it compatible with the default blizzard keybinds!
	--
	--	:RegisterButtonForKeybind(button[, bindingID])
	-- 	@param button <frame> the button to handle
	-- 	@param bindingID <string> optional bindingID/action. will use (CLICK %s:LeftButton"):format(button:GetName()) if omitted
	-- 	@returns <boolean> 'true' if something went wrong, purely for debugging
	module.RegisterButtonForKeybind = function(self, button, bindingID)
		if not(button) then
			return true
		end
		
		if (bindingID) then
			buttons[button:GetName()] = bindingID
		end
		
		local parentOverlay = self:GetOverlayFrame()
		local thisOverlay = button.KeyBindOverlayFrame or CreateFrame("Frame", button:GetName() .. "_KeyBindOverlayFrame", parentOverlay)
		thisOverlay:SetAllPoints(button)
		thisOverlay:SetBackdrop(M("Backdrop", "Blank"))
		thisOverlay:SetBackdropColor(0, 0, 0, 0)
		thisOverlay:EnableMouse(false)
		
		local updateOverlay = function(self)
			local frame = LKB.frame
			if (button:IsVisible()) and (frame) then
				self:SetBackdropColor(LKB:GetColorKeyBoundMode())
				self:SetFrameStrata(frame:GetFrameStrata())
				self:SetFrameLevel(frame:GetFrameLevel())
			else
				self:SetBackdropColor(0, 0, 0, 0)
			end
		end
		thisOverlay:HookScript("OnShow", updateOverlay)
		thisOverlay:HookScript("OnHide", updateOverlay)

		-- returns the current action assigned to a button
		button.ToBinding = function(self)
			return buttons[self:GetName()] or format("CLICK %s:LeftButton", self:GetName())
		end

		-- returns the current hotkey assigned to the given button
		button.GetHotkey = function(self) 
			local key1, key2 = GetBindingKey(button:ToBinding())
			return F.ShortenHotKey(key1), F.ShortenHotKey(key2)
		end
		
		button.SetKey = function(self, key)
			SetBinding(key, button:ToBinding())
		end
		
		-- returns the current buttons/actions bound to a key, unless it is bound to the current button
		button.FreeKey = function(self, key)
			local action = GetBindingAction(key)
			if (action) and not((action == "") or (action == button:ToBinding())) then
				return action
			end
		end
		
		-- clear all binding keys from the current button
		button.ClearBindings = function(self)
			local bindingID = self:ToBinding()
			while (GetBindingKey(bindingID)) do
				SetBinding(GetBindingKey(bindingID), nil)
			end
		end
		
		-- lists all bindings on a button, separated by commas
		button.GetBindings = function(self)
			local keys
			local bindingID = self:ToBinding()
			for i = 1, select("#", GetBindingKey(bindingID)) do
				local hotKey = select(i, GetBindingKey(bindingID))
				if (keys) then
					keys = keys .. ", " .. GetBindingText(hotKey, "KEY_")
				else
					keys = GetBindingText(hotKey, "KEY_")
				end
			end
			return keys
		end
		
		button.GetActionName = function(self)
			return button:GetName()
		end
		
		button:HookScript("OnEnter", function(self) LKB:Set(self) end)
	end

	module.ActivateKeybindMode = function(self) LKB:Activate() end
	module.DeactivateKeybindMode = function(self) LKB:Deactivate() end
	module.ToggleKeybindMode = function(self) LKB:Toggle() end
end

--------------------------------------------------------------------------------------------------
--		Layout Handling
--------------------------------------------------------------------------------------------------
do
	-- for the beta release, we'll only include the age-old default layout
	-- 	*buttonsize will be moved to saved settings later
	module.CreateLayouts = function(self)
		local fonts = {
			-- ideal for 29-32
			{
				hotkeys = gUI_DisplayFontMicroOutline;
				names = gUI_DisplayFontMicro;
				count = gUI_DisplayFontMicroOutlineWhite;
			};
			
			-- ideal for 33-39
			{
				hotkeys = gUI_DisplayFontExtraTinyOutline;
				names = gUI_DisplayFontExtraTiny;
				count = gUI_DisplayFontExtraTinyOutlineWhite;
			};
			
			-- ideal 40-46
			{
				hotkeys = gUI_DisplayFontTinyOutline;
				names = gUI_DisplayFontTiny;
				count = gUI_DisplayFontTinyOutlineWhite;
			};
		}
	
		-- default v1 and v2
		layouts[1] = {
			attributes = {
				fonts = {
					hotkeys = gUI_DisplayFontMicroOutline;
					names = gUI_DisplayFontMicro;
					count = gUI_DisplayFontMicroOutlineWhite;
				};
			};
			bars = {
				["1"] = {
					name = L["ActionBar%s"]:format("1");
					type = "primary";
					attributes = {
						"buttonsize", MIN_BUTTON_SIZE, 
						"gap", 2,
						"width", NUM_ACTIONBAR_BUTTONS,
						"height", 1
					};
				};
				["2"] = {
					name = L["ActionBar%s"]:format("2");
					type = "bottomleft";
					attributes = {
						"buttonsize", MIN_BUTTON_SIZE,
						"gap", 2,
						"width", NUM_ACTIONBAR_BUTTONS,
						"height", 1
					};
				};
				["3a"] = {
					name = L["ActionBar%s"]:format("3a");
					type = "bottomright";
					attributes = {
						"buttonsize", MIN_BUTTON_SIZE,
						"width", 3,
						"height", 2,
						"gap", 2,
						"firstbutton", 1, 
						"lastbutton", 6
					};
				};
				["3b"] = {
					name = L["ActionBar%s"]:format("3b");
					type = "bottomright";
					attributes = {
						"buttonsize", MIN_BUTTON_SIZE,
						"width", 3,
						"height", 2,
						"gap", 2,
						"firstbutton", 7,
						"lastbutton", 12
					};
				};
				["4"] = {
					name = L["ActionBar%s"]:format("4");
					type = "right";
					attributes = {
						"buttonsize", MIN_BUTTON_SIZE,
						"width", 1,
						"height", NUM_ACTIONBAR_BUTTONS,
						"gap", 2
					};
				};
				["5"] = {
					name = L["ActionBar%s"]:format("5");
					type = "left";
					attributes = {
						"buttonsize", MIN_BUTTON_SIZE,
						"width", 1,
						"height", NUM_ACTIONBAR_BUTTONS,
						"gap", 2
					};
				};
				["shift"] = {
					name = L["StanceBar"];
					type = "shift";
					attributes = {
						"buttonsize", MIN_BUTTON_SIZE
					};
				};
				["pet"] = {
					name = L["PetBar"];
					type = "pet";
					attributes = {
						"buttonsize", MIN_BUTTON_SIZE
					};
				};
				["micro"] = {
					name = L["MicroMenu"];
					type = "micro";
					attributes = {
						"buttonsize", 18, 
						"gap", 6,
						"width", 12,
						"height", 1
					};
				};
				-- ["extra"] = {
					-- name = L["ExtraActionButton"];
					-- type = "extra";
					-- attributes = {
						-- "buttonsize", 64 -- too large? too small?
						
					-- };
				-- };
			};
		};
		
		-- alternative v3 big-button layout
		layouts[2] = {
			attributes = {
				fonts = fonts[3]
			};
			bars = {
				["1"] = {
					name = L["ActionBar%s"]:format("1");
					type = "primary";
					place = { "BOTTOM", "UIParent", "BOTTOM", 0, EDGE + 4 + MAX_BUTTON_SIZE + 2 };
					attributes = {
						"buttonsize", MAX_BUTTON_SIZE, 
						"gap", 2,
						"width", NUM_ACTIONBAR_BUTTONS,
						"height", 1
					};
				};
				["2"] = {
					name = L["ActionBar%s"]:format("2");
					type = "bottomleft";
					place = { "BOTTOM", "UIParent", "BOTTOM", 0, EDGE + 4 };
					attributes = {
						"buttonsize", MAX_BUTTON_SIZE,
						"gap", 2,
						"width", NUM_ACTIONBAR_BUTTONS,
						"height", 1
					};
				};
				["4"] = {
					name = L["ActionBar%s"]:format("4");
					type = "right";
					place = { "RIGHT", "UIParent", "RIGHT", -(EDGE + 4), 0 };
					attributes = {
						"buttonsize", 29,
						"width", 1,
						"height", NUM_ACTIONBAR_BUTTONS,
						"gap", 2
					};
				};
				["5"] = {
					name = L["ActionBar%s"]:format("5");
					type = "left";
					place = { "RIGHT", "UIParent", "RIGHT", -(EDGE + 4 + 29 + 2), 0 };
					attributes = {
						"buttonsize", 29,
						"width", 1,
						"height", NUM_ACTIONBAR_BUTTONS,
						"gap", 2
					};
				};
				["3"] = {
					name = L["ActionBar%s"]:format("3");
					type = "bottomright";
					place = { "RIGHT", "UIParent", "RIGHT", -(EDGE + 4 + (29 + 2)*2), 0 };
					attributes = {
						"buttonsize", 29,
						"width", 1,
						"height", NUM_ACTIONBAR_BUTTONS,
						"gap", 2
					};
				};
				["shift"] = {
					name = L["StanceBar"];
					type = "shift";
					place = { "TOPLEFT", "UIParent", "TOPLEFT", 180, -(EDGE) };
					attributes = {
						"buttonsize", 29
					};
				};
				["pet"] = {
					name = L["PetBar"];
					type = "pet";
					place = { "BOTTOM", "UIParent", "BOTTOM", 0, 260 };
					attributes = {
						"buttonsize", 29
					};
				};
				-- ["extra"] = {
					-- name = L["ExtraActionButton"];
					-- type = "extra";
					-- place = { "CENTER", "UIParent", "CENTER", 0, 0 };
					-- attributes = {
						-- "buttonsize", 64 -- too large? too small?
						
					-- };
				-- };
			};
		};
	end
end

module.SetLayout = function(self, layout)
end

module.GetLayout = function(self)
	local layout = TEST_LAYOUT or gUI:GetLayout() or db.layout
	return layout, layouts[layout]
end

module.UpdateActionBarLock = function(self)
	SetCVar("lockActionBars", db.lockActionBars)
	LOCK_ACTIONBAR = (db.lockActionBars) and "1" or nil
end

module.PostUpdateSettings = function(self)
	-- get the active base layout
	local layoutID, layout = self:GetLayout()

	-- update bar visibility
	local bar
	for id, info in pairs(layout.bars) do
		bar = gAB:GetBarByName(info.name)
		if (bar) then
			if (db.layouts[layoutID][id].visible ~= nil) then 
				bar:SetShown(db.layouts[layoutID][id].visible) 
			end
			if (db.layouts[layoutID][id].hover ~= nil) then 
				bar:SetAttribute("fade", db.layouts[layoutID][id].hover) 
			end
			local updateLayout
			if (db.layouts[layoutID][id].buttonsize ~= nil) then 
				bar:SetAttribute("buttonsize", db.layouts[layoutID][id].buttonsize) 
				updateLayout = true
			end
			if (db.layouts[layoutID][id].width ~= nil) and (db.layouts[layoutID][id].width ~= bar:GetAttribute("width")) then 
				bar:SetAttribute("width", db.layouts[layoutID][id].width)
				bar:SetAttribute("height", ceil((bar:GetAttribute("lastbutton") - bar:GetAttribute("firstbutton") + 1)/db.layouts[layoutID][id].width))
			end
			if (updateLayout) then
				F.SafeCall(bar.UpdateLayout, bar) -- safety first
			end
		end
	end
	
	-- update main bar drivers for classes with extra optional bars
	local useStanceMagic = ((db.useProwlBar) and (playerClass == "DRUID")) or	((db.useMetaMorphBar) and (playerClass == "WARLOCK")) or ((db.useWarriorStanceBars) and (playerClass == "WARRIOR")) or ((db.useShadowDanceBar) and (playerClass == "ROGUE"))
	bar = gAB:GetBarByName(layout.bars["1"].name)
	bar:SetAttribute("stancemagic", useStanceMagic) 
	F.SafeCall(bar.UpdateStates, bar) -- keep it safe

	-- update our button styles
	gUI:SetUpButtonStyling() -- this will be done in the core as well

	-- local for barmodule
	gABT:SetTextFunction(F.ShortenHotKey)
	gABT:SetEnableHotkeys(db.showHotkeys) 
	gABT:SetEnableMacros(db.showMacros) 

	-- layout specific
	gABT:SetHotkeyFontObject(layout.attributes.fonts.hotkeys)
	gABT:SetMacroFontObject(layout.attributes.fonts.names)
	gABT:SetCountFontObject(layout.attributes.fonts.count)
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	self:CreateBindingTable() -- populate the binding table for the keybind module
	self:CreateLayouts() -- populate the layout/preset table
	
	gAB:Start() -- kill off the blizzard bars
	
	-- we need to handle the actionbar lock manually, 
	-- since our hijacking of the menu option disabled blizzards own functionality
	self:UpdateActionBarLock()
	
	local layoutID, layout = self:GetLayout()

	-- set up actionbars
	do
		local bar
		for id, info in pairs(layout.bars) do
			bar = gAB:New(info.name, info.type, unpack(info.attributes))
			
			-- just an extra safe-check, since we might have bars listed 
			-- that aren't yet supported by gActionBars
			if (bar) then
				self:PlaceAndSave(bar:GetBar(), bar:GetName(), db.layouts[layoutID][id].place, unpack(defaults.layouts[layoutID][id].place))
				self:AddObjectToFrameGroup(bar:GetBar(), "actionbars")
				
				-- this setting indicates adjustable number of buttons in a row
				if (db.layouts[layoutID][id].width) then
					-- get all the defaults
					local bar, id = bar, id 
					local defaultWidth, defaultHeight = bar:GetAttribute("width"), bar:GetAttribute("height")
					local first, last = bar:GetAttribute("firstbutton"), bar:GetAttribute("lastbutton")
					local num = last - first + 1
					
					-- create width choices
					local choices = {}
					for i = 1, num do tinsert(choices, tostring(i)) end

					local func = function(object, newWidth) 
						local newHeight = ceil(num/newWidth)
						db.layouts[layoutID][id].width = newWidth
						bar:SetAttribute("width", newWidth)
						bar:SetAttribute("height", newHeight)
						bar:UpdateLayout()
					end
					local show = function(self) 
						bar:SetAttribute("old-width", bar:GetAttribute("width"))
						bar:SetAttribute("old-height", bar:GetAttribute("height"))
					end
					local reset = function(self) 
						db.layouts[layoutID][id].width = defaultWidth
						bar:SetAttribute("width", defaultWidth)
						bar:SetAttribute("height", defaultHeight)
						bar:UpdateLayout()
					end
					local cancel = function(self) 
						local oldWidth, oldHeight = bar:GetAttribute("old-width"), bar:GetAttribute("old-height")
						if (oldWidth) and (oldHeight) then
							db.layouts[layoutID][id].width = oldWidth
							bar:SetAttribute("width", oldWidth)
							bar:SetAttribute("height", oldHeight)
							bar:UpdateLayout()
						end
					end
					self:AddCustomFunctionToObjectAnchor(bar:GetBar(), L["Set number of buttons on each row"], func, choices, show, reset, cancel)
				end

				-- visibility
				if (db.layouts[layoutID][id].visible ~= nil) then
					local bar, id, layoutID = bar, id, layoutID

					-- show on mouseover
					if (db.layouts[layoutID][id].hover ~= nil) then
						do
							local func = function(self) 
								bar:Show()
								db.layouts[layoutID][id].visible = true
								db.layouts[layoutID][id].hover = true
								bar:SetAttribute("fade", true)
							end
							local show = function(self) 
								bar:SetAttribute("old-visible", bar:IsShown())
								bar:SetAttribute("old-fade", bar:GetAttribute("fade"))
							end
							local reset = function(self) 
								-- if (bar:IsShown() == defaults.bars[id].visible) then return end 
								-- db.layouts[layoutID][id].visible = defaults.bars[id].visible
								-- bar:SetShown(defaults.bars[id].visible)
							end
							local cancel = function(self) 
								db.layouts[layoutID][id].visible = bar:GetAttribute("old-visible")
								bar:SetShown(bar:GetAttribute("old-visible"))
								bar:SetAttribute("fade", bar:GetAttribute("old-fade"))
							end
							self:AddCustomFunctionToObjectAnchor(bar:GetBar(), L["Show on mouseover"], func, nil, show, reset, cancel)
						end
					end

					-- show always
					do
						local func = function(self) 
							bar:Show()
							db.layouts[layoutID][id].visible = true
							db.layouts[layoutID][id].hover = false
							bar:SetAttribute("fade", nil)
						end
						local show = function(self) 
							bar:SetAttribute("old-visible", bar:IsShown())
							bar:SetAttribute("old-fade", bar:GetAttribute("fade"))
						end
						local reset = function(self) 
							-- if (bar:IsShown() == defaults.bars[id].visible) then return end 
							-- db.layouts[layoutID][id].visible = defaults.bars[id].visible
							-- bar:SetShown(defaults.bars[id].visible)
						end
						local cancel = function(self) 
							db.layouts[layoutID][id].visible = bar:GetAttribute("old-visible")
							bar:SetShown(bar:GetAttribute("old-visible"))
							bar:SetAttribute("fade", bar:GetAttribute("old-fade"))
						end
						self:AddCustomFunctionToObjectAnchor(bar:GetBar(), L["Show always"], func, nil, show, reset, cancel)
					end

					-- hide not available for main
					if (id ~= "1") then
						-- hide
						do
							local func = function(self) 
								bar:Hide()
								db.layouts[layoutID][id].visible = false
								db.layouts[layoutID][id].hover = false
								bar:SetAttribute("fade", nil)
							end
							local show = function(self) 
								bar:SetAttribute("old-visible", bar:IsShown())
								bar:SetAttribute("old-fade", bar:GetAttribute("fade"))
							end
							local reset = function(self) 
								-- if (bar:IsShown() == defaults.bars[id].visible) then return end 
								-- db.layouts[layoutID][id].visible = defaults.bars[id].visible
								-- bar:SetShown(defaults.bars[id].visible)
							end
							local cancel = function(self) 
								db.layouts[layoutID][id].visible = bar:GetAttribute("old-visible")
								bar:SetShown(bar:GetAttribute("old-visible"))
								bar:SetAttribute("fade", bar:GetAttribute("old-fade"))
							end
							self:AddCustomFunctionToObjectAnchor(bar:GetBar(), L["Hide always"], func, nil, show, reset, cancel)
						end
					end
				end
			end
		end
	end
	
	-- our own fancy exitbuttons
	do
		local CreateExitButton = function(name, macro)
			local button = CreateFrame("Button", name, UIParent, "SecureHandlerClickTemplate")
			button:SetSize(37, 37)
			-- button:SetUITemplate("simplebackdrop")
			
			button.Background = button:CreateTexture()
			button.Background:SetDrawLayer("BACKGROUND", 1)
			button.Background:SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]])
			button.Background:SetTexCoord(17/64, 51/64, 17/64, 51/64)
			button.Background:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
			button.Background:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
			
			gUI:SetUITemplate(button, "backdrop")
			gUI:SetUITemplate(button, "gloss", button.Background)
			gUI:SetUITemplate(button, "shade", button.Background)
			gUI:CreateUIShadow(button)

			local hover = button:CreateTexture()
			hover:SetTexture(C["hover"].r, C["hover"].g, C["hover"].b, 1/3)
			hover:SetAllPoints(button.Background)
			button:SetHighlightTexture(hover)

			local pushed = button:CreateTexture()
			pushed:SetTexture(C["pushed"].r, C["pushed"].g, C["pushed"].b, 1/3)
			pushed:SetAllPoints(button.Background)
			pushed:SetAlpha(0)
			
			button:RegisterForClicks("AnyUp")
			button:SetScript("OnClick", function() 
				if (UnitInVehicle("player")) then
					VehicleExit()
				else
					PetDismiss() -- what if we dismiss the player's real pet...?
				end
			end)
			button:SetScript("OnMouseDown", function(self) pushed:SetAlpha(1) end)
			button:SetScript("OnMouseUp", function(self) pushed:SetAlpha(0) end)

			RegisterStateDriver(button, "visibility", macro or "[vehicleui][possessbar] show; hide")
			
			return button
		end
		CreateExitButton():SetPoint("TOPRIGHT", ActionButton1:GetParent(), "TOPLEFT", -12, 4)
		CreateExitButton():SetPoint("TOPLEFT", ActionButton1:GetParent(), "TOPRIGHT", 12, 4)
		
		-- movable exit button, will also appear for passenger seats and sandbox tigers. In theory.
		VehicleExitButton = CreateExitButton("VehicleExitButton", "[novehicleui, @vehicle,exists] show; hide")
		self:PlaceAndSave(VehicleExitButton, L["VehicleExitButton"], db.vehicleExitButton.place, unpack(defaults.vehicleExitButton.place))
		self:AddObjectToFrameGroup(VehicleExitButton, "actionbars")
		
		-- make it a global, it ought to be
		_G.VehicleExitButton = VehicleExitButton
		
	end
	
	-- set up button styling
	do
		-- fire up the button styler
		gABT:Start()
	
		-- add our shadows
		for i = 1, #gABT:GetActionButtons() do gUI:CreateUIShadow(gABT:GetActionButtons()[i]) end
		for i = 1, #gABT:GetPetButtons() do gUI:CreateUIShadow(gABT:GetPetButtons()[i]) end
		for i = 1, #gABT:GetStanceButtons() do gUI:CreateUIShadow(gABT:GetStanceButtons()[i]) end
		
		-- micromenu
		local bar = gAB:GetBarByName(L["MicroMenu"])
		local buttons = bar.buttons
		for i = 1, #buttons do
			gUI:SetUITemplate(buttons[i], "outerbackdrop")
			gUI:SetUITemplate(buttons[i], "gloss")
			gUI:SetUITemplate(buttons[i], "shade")
			self:RegisterButtonForKeybind(buttons[i], buttons[i].bindAction) 
		end
		bar.shadow = CreateFrame("Frame", nil, bar:GetBar())
		bar.shadow:SetPoint("TOPLEFT", bar:GetBar(), "TOPLEFT", -3, 3)
		bar.shadow:SetPoint("BOTTOMRIGHT", bar:GetBar(), "BOTTOMRIGHT", 3, -3)
		gUI:CreateUIShadow(bar.shadow)
	end
	
	-- create the special vehiclebackdrop
	-- *other backdrops are hidden while in vehicles
	local vehicle = CreateFrame("Frame", nil, gUI:GetAttribute("parent"), "SecureHandlerStateTemplate")
	vehicle:SetFrameStrata("BACKGROUND")
	vehicle:SetFrameLevel(10)
	vehicle:SetPoint("TOPLEFT", ActionButton1, "TOPLEFT", -4, 4)
	vehicle:SetPoint("BOTTOMRIGHT", ActionButton12, "BOTTOMRIGHT", 4, -4)
	vehicle.shine = F.Shine:New(vehicle)
	vehicle:HookScript("OnShow", function(self) self.shine:Start() end)
	gUI:SetUITemplate(vehicle, "backdrop")
	gUI:CreateUIShadow(vehicle)
	RegisterStateDriver(vehicle, "visibility", "[vehicleui][possessbar][overridebar] show; hide")
	
	-- update bars and buttons according to saved settings
	self:PostUpdateSettings()
	
	-- kill off blizzard menu options and stuff that no longer is relevant
	do
		-- might find a better way for these later
		gUI:KillPanel(6, InterfaceOptionsActionBarsPanel)
		gUI:KillOption(true, InterfaceOptionsActionBarsPanelBottomLeft)
		gUI:KillOption(true, InterfaceOptionsActionBarsPanelBottomRight)
		gUI:KillOption(true, InterfaceOptionsActionBarsPanelRight)
		gUI:KillOption(true, InterfaceOptionsActionBarsPanelRightTwo)
		gUI:KillOption(true, InterfaceOptionsActionBarsPanelAlwaysShowActionBars)
		gUI:KillObject(StreamingIcon)
		gUI:KillObject(TutorialFrameAlertButton)
		
		if (GuildChallengeAlertFrame) then
			gUI:KillObject(GuildChallengeAlertFrame)
		end
	end
	
	-- set up chat commands
	do
		self:CreateChatCommand({"showhotkeys", "enablehotkeys", "showkeybinds", "showbinds"}, function() 
			db.showHotkeys = true
			gABT:SetEnableHotkeys(true) 
		end)
		self:CreateChatCommand({"hidehotkeys", "disablehotkeys", "hidekeybinds", "hidebinds"}, function() 
			db.showHotkeys = false
			gABT:SetEnableHotkeys(false) 
		end)
		self:CreateChatCommand({"shownames", "showmacronames", "showmacros"}, function() 
			db.showMacros = true
			gABT:SetEnableMacros(true) 
		end)
		self:CreateChatCommand({"hidenames", "hidemacronames", "hidemacros"}, function() 
			db.showMacros = false
			gABT:SetEnableMacros(false) 
		end)
	end
	
	
	-- options menu
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
						order = 10;
						msg = L["ActionBars"];
					};
					{
						type = "widget";
						element = "Text";
						order = 20;
						msg = L["ActionBars are banks of hotkeys that allow you to quickly access abilities and inventory items. Here you can activate additional ActionBars and control their behaviors."];
					};
					{ -- blizzard: secure ability toggle
						type = "widget";
						element = "CheckButton";
						name = "secureAbilityToggle";
						order = 30;
						width = "full"; 
						msg = L["Secure Ability Toggle"];
						desc = L["When selected you will be protected from toggling your abilities off if accidently hitting the button more than once in a short period of time."];
						set = function(self) 
							SetCVar("secureAbilityToggle", (tonumber(GetCVar("secureAbilityToggle")) == 1) and 0 or 1)
						end;
						get = function() return tonumber(GetCVar("secureAbilityToggle")) == 1 end;
					};
					{ -- blizzard: lock actionbars
						type = "widget";
						element = "CheckButton";
						name = "lockActionBars";
						order = 40;
						width = "full"; 
						msg = L["Lock ActionBars"];
						desc = L["Prevents the user from picking up/dragging spells on the action bar. This function can be bound to a function key in the keybindings interface."];
						set = function(self) 
							db.lockActionBars = not(db.lockActionBars)
							self:onrefresh()
						end;
						get = function() return db.lockActionBars end;
						onrefresh = function(self) 
							module:UpdateActionBarLock()
							if db.lockActionBars then
								self.parent.child.pickupKey:Enable()
							else
								self.parent.child.pickupKey:Disable()
							end
						end;
						onshow = function(self) self:onrefresh() end;
						init = function(self) self:onrefresh() end;
					};
					{ -- blizzard: pick up key
						type = "widget";
						element = "Dropdown";
						name = "pickupKey";
						order = 50;
						width = "full";
						msg = nil; -- L["Pick Up Action Key"];
						desc = {
							"|cFFFFFFFF" .. L["ALT key"] .. "|r";
							"|cFFFFD100" .. L["Use the \"ALT\" key to pick up/drag spells from locked actionbars."] .. "|r";
							" ";
							"|cFFFFFFFF" .. L["CTRL key"] .. "|r";
							"|cFFFFD100" .. L["Use the \"CTRL\" key to pick up/drag spells from locked actionbars."] .. "|r";
							" ";
							"|cFFFFFFFF" .. L["SHIFT key"] .. "|r";
							"|cFFFFD100" .. L["Use the \"SHIFT\" key to pick up/drag spells from locked actionbars."] .. "|r";
							" ";
							"|cFFFFFFFF" .. L["None"] .. "|r";
							"|cFFFFD100" .. L["No key set."] .. "|r";
						};
						args = { L["ALT key"], L["CTRL key"], L["SHIFT key"], L["None"] };
						set = function(self, option)
							local value
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								value = "ALT"
							elseif (option == 2) then
								value = "CTRL"
							elseif (option == 3) then
								value = "SHIFT"
							else
								value = "NONE"
							end
							
							SetModifiedClick("PICKUPACTION", value)
							SaveBindings(GetCurrentBindingSet())
						end;
						get = function(self) 
							local value = GetModifiedClick("PICKUPACTION")
							return (value == "ALT") and 1 or (value == "CTRL") and 2 or (value == "SHIFT") and 3 or 4
						end;
						init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
					};	
					
					{
						type = "widget";
						element = "Title";
						order = 60;
						width = "full";
						msg = L["Main ActionBar [1]"];
					};
					{ -- size header
						type = "widget";
						element = "Header";
						order = 70;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 80;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 90;
						width = "half";
						min = MIN_BUTTON_SIZE;
						max = MAX_BUTTON_SIZE;
						msg = nil;
						desc = L["Set the size of the bar's buttons"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["1"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["1"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						order = 100;
						width = "half";
						msg = nil;
						min = 1;
						max = NUM_ACTIONBAR_BUTTONS;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["1"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["1"].width end;
					};

					-- {
						-- type = "widget";
						-- element = "Text";
						-- order = 110;
						-- width = "full";
						-- msg = L["Here you can enable extra pageswitching for the main ActionBar for some classes."];
					-- };
					{
						type = "widget";
						element = "CheckButton";
						name = "useProwlBar";
						order = 120;
						width = "full"; 
						msg = L["Use Druid Prowl Bar"];
						desc = L["Enabling this will switch to a separate bar when you use Prowl"];
						set = function(self) 
							db.useProwlBar = not(db.useProwlBar)
							module:PostUpdateSettings()
						end;
						get = function() return db.useProwlBar end;
						init = function(self) 
							if (playerClass ~= "DRUID") then
								self:Disable()
							end
						end;
					};
					{
						type = "widget";
						element = "CheckButton";
						name = "useShadowDanceBar";
						order = 130;
						width = "full"; 
						msg = L["Use Rogue Shadow Dance Bar"];
						desc = L["Enabling this will switch to a separate bar when Shadow Dance is active"];
						set = function(self) 
							db.useShadowDanceBar = not(db.useShadowDanceBar)
							module:PostUpdateSettings()
						end;
						get = function() return db.useShadowDanceBar end;
						init = function(self) 
							if (playerClass ~= "ROGUE") then
								self:Disable()
							end
						end;
					};
					{
						type = "widget";
						element = "CheckButton";
						name = "useMetaMorphBar";
						order = 140;
						width = "full"; 
						msg = L["Use Warlock Metamorphosis Bar"];
						desc = L["Enabling this will switch to a separate bar when Metamorphosis is active"];
						set = function(self) 
							db.useMetaMorphBar = not(db.useMetaMorphBar)
							module:PostUpdateSettings()
						end;
						get = function() return db.useMetaMorphBar end;
						init = function(self) 
							if (playerClass ~= "WARLOCK") then
								self:Disable()
							end
						end;
					};
					{
						type = "widget";
						element = "CheckButton";
						name = "useWarriorStanceBars";
						order = 150;
						width = "full"; 
						msg = L["Use Warrior Stance Bars"];
						desc = L["Enabling this will switch to a separate bar for each of your stances"];
						set = function(self) 
							db.useWarriorStanceBars = not(db.useWarriorStanceBars)
							module:PostUpdateSettings()
						end;
						get = function() return db.useWarriorStanceBars end;
						init = function(self) 
							if (playerClass ~= "WARRIOR") then
								self:Disable()
							end
						end;
					};

					{
						type = "widget";
						element = "Title";
						order = 160;
						width = "full";
						msg = L["Bottom ActionBar [2]"];
					};
					{
						type = "widget";
						element = "Dropdown";
						name = "showBar2";
						order = 170;
						width = "full"; 
						msg = nil; -- L["Show the bottom ActionBar [2]"];
						desc = nil;
						args = { F.green(L["Show always"]), F.yellow(L["Show on mouseover"]), F.red(L["Hide always"]) };
						set = function(self, option)
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								db.layouts[layoutID]["2"].visible = true
								db.layouts[layoutID]["2"].hover = false
							elseif (option == 2) then
								db.layouts[layoutID]["2"].visible = true
								db.layouts[layoutID]["2"].hover = true
							elseif (option == 3) then
								db.layouts[layoutID]["2"].visible = false
								db.layouts[layoutID]["2"].hover = false
							end
							module:PostUpdateSettings()
						end;
						get = function() 
							if (db.layouts[layoutID]["2"].visible) then
								if (db.layouts[layoutID]["2"].hover) then
									return 2
								else
									return 1
								end
							else
								return 3
							end
						end;
					};	
					{ -- size header
						type = "widget";
						element = "Header";
						order = 180;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 190;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 200;
						width = "half";
						min = MIN_BUTTON_SIZE;
						max = MAX_BUTTON_SIZE;
						msg = nil;
						desc = L["Set the size of the bar's buttons"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["2"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["2"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						order = 210;
						width = "half";
						msg = nil;
						min = 1;
						max = NUM_ACTIONBAR_BUTTONS;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["2"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["2"].width end;
					};

					{
						type = "widget";
						element = "Title";
						order = 220;
						width = "full";
						msg = L["Bottom Left ActionBar [3a]"];
					};
					{
						type = "widget";
						element = "Dropdown";
						name = "showBar3a";
						order = 230;
						width = "full"; 
						msg = nil; -- L["Show the bottom left ActionBar [3a]"];
						desc = nil;
						args = { F.green(L["Show always"]), F.yellow(L["Show on mouseover"]), F.red(L["Hide always"]) };
						set = function(self, option)
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								db.layouts[layoutID]["3a"].visible = true
								db.layouts[layoutID]["3a"].hover = false
							elseif (option == 2) then
								db.layouts[layoutID]["3a"].visible = true
								db.layouts[layoutID]["3a"].hover = true
							elseif (option == 3) then
								db.layouts[layoutID]["3a"].visible = false
								db.layouts[layoutID]["3a"].hover = false
							end
							module:PostUpdateSettings()
						end;
						get = function() 
							if (db.layouts[layoutID]["3a"].visible) then
								if (db.layouts[layoutID]["3a"].hover) then
									return 2
								else
									return 1
								end
							else
								return 3
							end
						end;
					};	
					{ -- size header
						type = "widget";
						element = "Header";
						order = 240;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 250;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 260;
						width = "half";
						msg = nil;
						desc = L["Set the size of the bar's buttons"];
						min = MIN_BUTTON_SIZE;
						max = MAX_BUTTON_SIZE;
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["3a"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["3a"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						min = 1;
						max = NUM_ACTIONBAR_BUTTONS/2;
						order = 270;
						width = "half";
						msg = nil;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["3a"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["3a"].width end;
					};

					{
						type = "widget";
						element = "Title";
						order = 280;
						width = "full";
						msg = L["Bottom Right ActionBar [3b]"];
					};
					{
						type = "widget";
						element = "Dropdown";
						name = "showBar3b";
						order = 290;
						width = "full"; 
						msg = nil; -- L["Show the bottom right ActionBar [3b]"];
						desc = nil;
						args = { F.green(L["Show always"]), F.yellow(L["Show on mouseover"]), F.red(L["Hide always"]) };
						set = function(self, option)
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								db.layouts[layoutID]["3b"].visible = true
								db.layouts[layoutID]["3b"].hover = false
							elseif (option == 2) then
								db.layouts[layoutID]["3b"].visible = true
								db.layouts[layoutID]["3b"].hover = true
							elseif (option == 3) then
								db.layouts[layoutID]["3b"].visible = false
								db.layouts[layoutID]["3b"].hover = false
							end
							module:PostUpdateSettings()
						end;
						get = function() 
							if (db.layouts[layoutID]["3b"].visible) then
								if (db.layouts[layoutID]["3b"].hover) then
									return 2
								else
									return 1
								end
							else
								return 3
							end
						end;
					};	
					{ -- size header
						type = "widget";
						element = "Header";
						order = 300;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 310;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 320;
						width = "half";
						msg = nil;
						min = MIN_BUTTON_SIZE;
						max = MAX_BUTTON_SIZE;
						desc = L["Set the size of the bar's buttons"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["3b"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["3b"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						order = 330;
						width = "half";
						min = 1;
						max = NUM_ACTIONBAR_BUTTONS/2;
						msg = nil;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["3b"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["3b"].width end;
					};

					{
						type = "widget";
						element = "Title";
						order = 340;
						width = "full";
						msg = L["Rightmost Side ActionBar [4]"];
					};
					{
						type = "widget";
						element = "Dropdown";
						name = "showBar4";
						order = 350;
						width = "full"; 
						msg = nil; -- L["Show the rightmost side ActionBar [4]"];
						desc = nil;
						args = { F.green(L["Show always"]), F.yellow(L["Show on mouseover"]), F.red(L["Hide always"]) };
						set = function(self, option)
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								db.layouts[layoutID]["4"].visible = true
								db.layouts[layoutID]["4"].hover = false
							elseif (option == 2) then
								db.layouts[layoutID]["4"].visible = true
								db.layouts[layoutID]["4"].hover = true
							elseif (option == 3) then
								db.layouts[layoutID]["4"].visible = false
								db.layouts[layoutID]["4"].hover = false
							end
							module:PostUpdateSettings()
						end;
						get = function() 
							if (db.layouts[layoutID]["4"].visible) then
								if (db.layouts[layoutID]["4"].hover) then
									return 2
								else
									return 1
								end
							else
								return 3
							end
						end;
					};	
					{ -- size header
						type = "widget";
						element = "Header";
						order = 360;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 370;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 380;
						width = "half";
						msg = nil;
						min = MIN_BUTTON_SIZE;
						max = MAX_BUTTON_SIZE;
						desc = L["Set the size of the bar's buttons"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["4"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["4"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						order = 390;
						width = "half";
						min = 1;
						max = NUM_ACTIONBAR_BUTTONS;
						msg = nil;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["4"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["4"].width end;
					};

					{
						type = "widget";
						element = "Title";
						order = 400;
						width = "full";
						msg = L["Leftmost Side ActionBar [5]"];
					};
					{
						type = "widget";
						element = "Dropdown";
						name = "showBar5";
						order = 410;
						width = "full"; 
						msg = nil; -- L["Show the leftmost side ActionBar [5]"];
						desc = nil;
						args = { F.green(L["Show always"]), F.yellow(L["Show on mouseover"]), F.red(L["Hide always"]) };
						set = function(self, option)
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								db.layouts[layoutID]["5"].visible = true
								db.layouts[layoutID]["5"].hover = false
							elseif (option == 2) then
								db.layouts[layoutID]["5"].visible = true
								db.layouts[layoutID]["5"].hover = true
							elseif (option == 3) then
								db.layouts[layoutID]["5"].visible = false
								db.layouts[layoutID]["5"].hover = false
							end
							module:PostUpdateSettings()
						end;
						get = function() 
							if (db.layouts[layoutID]["5"].visible) then
								if (db.layouts[layoutID]["5"].hover) then
									return 2
								else
									return 1
								end
							else
								return 3
							end
						end;
					};	
					{ -- size header
						type = "widget";
						element = "Header";
						order = 420;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 430;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 440;
						width = "half";
						min = MIN_BUTTON_SIZE;
						max = MAX_BUTTON_SIZE;
						msg = nil;
						desc = L["Set the size of the bar's buttons"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["5"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["5"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						order = 450;
						width = "half";
						min = 1;
						max = NUM_ACTIONBAR_BUTTONS;
						msg = nil;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["5"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["5"].width end;
					};

					{
						type = "widget";
						element = "Header";
						order = 460;
						width = "full";
						msg = L["Pet ActionBar"];
					};
					{
						type = "widget";
						element = "Dropdown";
						name = "showBarPet";
						order = 470;
						width = "full"; 
						msg = nil; -- L["Show the Pet ActionBar"];
						desc = nil;
						args = { F.green(L["Show always"]), F.yellow(L["Show on mouseover"]), F.red(L["Hide always"]) };
						set = function(self, option)
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								db.layouts[layoutID]["pet"].visible = true
								db.layouts[layoutID]["pet"].hover = false
							elseif (option == 2) then
								db.layouts[layoutID]["pet"].visible = true
								db.layouts[layoutID]["pet"].hover = true
							elseif (option == 3) then
								db.layouts[layoutID]["pet"].visible = false
								db.layouts[layoutID]["pet"].hover = false
							end
							module:PostUpdateSettings()
						end;
						get = function() 
							if (db.layouts[layoutID]["pet"].visible) then
								if (db.layouts[layoutID]["pet"].hover) then
									return 2
								else
									return 1
								end
							else
								return 3
							end
						end;
					};	
					{ -- size header
						type = "widget";
						element = "Header";
						order = 480;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 490;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 500;
						width = "half";
						min = MIN_BUTTON_SIZE;
						max = MAX_BUTTON_SIZE;
						msg = nil;
						desc = L["Set the size of the bar's buttons"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["pet"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["pet"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						order = 510;
						width = "half";
						msg = nil;
						min = 1;
						max = NUM_PET_ACTION_SLOTS;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["pet"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["pet"].width end;
					};

					{
						type = "widget";
						element = "Header";
						order = 520;
						width = "full";
						msg = L["Shapeshift/Aspect/Stance Bar"];
					};
					{
						type = "widget";
						element = "Dropdown";
						name = "showBarShift";
						order = 530;
						width = "full"; 
						msg = nil; -- L["Show the Shapeshift/Stance/Aspect Bar"];
						desc = nil;
						args = { F.green(L["Show always"]), F.yellow(L["Show on mouseover"]), F.red(L["Hide always"]) };
						set = function(self, option)
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								db.layouts[layoutID]["shift"].visible = true
								db.layouts[layoutID]["shift"].hover = false
							elseif (option == 2) then
								db.layouts[layoutID]["shift"].visible = true
								db.layouts[layoutID]["shift"].hover = true
							elseif (option == 3) then
								db.layouts[layoutID]["shift"].visible = false
								db.layouts[layoutID]["shift"].hover = false
							end
							module:PostUpdateSettings()
						end;
						get = function() 
							if (db.layouts[layoutID]["shift"].visible) then
								if (db.layouts[layoutID]["shift"].hover) then
									return 2
								else
									return 1
								end
							else
								return 3
							end
						end;
					};	
					{ -- size header
						type = "widget";
						element = "Header";
						order = 540;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 550;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 560;
						width = "half";
						msg = nil;
						min = MIN_BUTTON_SIZE;
						max = MAX_BUTTON_SIZE;
						desc = L["Set the size of the bar's buttons"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["shift"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["shift"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						order = 570;
						width = "half";
						msg = nil;
						min = 1;
						max = NUM_STANCE_SLOTS;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["shift"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["shift"].width end;
					};

					{
						type = "widget";
						element = "Header";
						order = 580;
						width = "full";
						msg = L["Micro Menu"];
					};
					{
						type = "widget";
						element = "Dropdown";
						name = "showMicroMenu";
						order = 590;
						width = "full"; 
						msg = nil; -- L["Show the Micro Menu"];
						desc = nil;
						args = { F.green(L["Show always"]), F.yellow(L["Show on mouseover"]), F.red(L["Hide always"]) };
						set = function(self, option)
							local option = option or UIDropDownMenu_GetSelectedID(self)
							if (option == 1) then
								db.layouts[layoutID]["micro"].visible = true
								db.layouts[layoutID]["micro"].hover = false
							elseif (option == 2) then
								db.layouts[layoutID]["micro"].visible = true
								db.layouts[layoutID]["micro"].hover = true
							elseif (option == 3) then
								db.layouts[layoutID]["micro"].visible = false
								db.layouts[layoutID]["micro"].hover = false
							end
							module:PostUpdateSettings()
						end;
						get = function() 
							if (db.layouts[layoutID]["micro"].visible) then
								if (db.layouts[layoutID]["micro"].hover) then
									return 2
								else
									return 1
								end
							else
								return 3
							end
						end;
					};	
					{ -- size header
						type = "widget";
						element = "Header";
						order = 600;
						width = "half";
						msg = L["Button Size"]; indented = true;
					};
					{ -- width header
						type = "widget";
						element = "Header";
						order = 610;
						width = "half";
						msg = L["Bar Width"]; indented = true; 
					};
					{ -- buttonsize
						type = "widget";
						element = "Slider";
						name = "buttonsize";
						order = 620;
						width = "half";
						msg = nil;
						min = MIN_MICRO_SIZE;
						max = MAX_MICRO_SIZE;
						desc = L["Set the size of the bar's buttons"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["micro"].buttonsize = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["micro"].buttonsize end;
					};
					{ -- bar width
						type = "widget";
						element = "Slider";
						name = "barwidth";
						order = 630;
						width = "half";
						msg = nil;
						min = 1;
						max = 12;
						desc = L["Set number of buttons on each row"];
						set = function(self, value) 
							if (value) then
								self.text:SetText(("%d"):format(value))
								db.layouts[layoutID]["micro"].width = tonumber(value)
								module:PostUpdateSettings()
							end
						end;
						get = function(self) return db.layouts[layoutID]["micro"].width end;
					};
					
					{ -- button setup
						type = "group";
						order = 640;
						name = "buttonSetup";
						virtual = true;
						children = {
							{
								type = "widget";
								element = "Title";
								order = 100;
								msg = L["ActionButtons"];
							};
							{
								type = "widget";
								element = "Text";
								order = 101;
								msg = L["ActionButtons are buttons allowing you to use items, cast spells or run a macro with a single keypress or mouseclick. Here you can decide upon the styling and visible elements of your ActionButtons."];
							};
							{
								type = "group";
								order = 150;
								virtual = true;
								children = {
									-- {
										-- type = "widget";
										-- element = "Header";
										-- order = 10;
										-- width = "half";
										-- msg = L["Button Styling"];
									-- };
									-- {
										-- type = "widget";
										-- element = "CheckButton";
										-- name = "showGloss";
										-- order = 100;
										-- width = "half"; 
										-- msg = L["Show gloss layer on ActionButtons"];
										-- desc = { L["Show Gloss"], L["This will display the gloss overlay on the ActionButtons"] };
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
										-- width = "half"; 
										-- msg = L["Show shade layer on ActionButtons"];
										-- desc = { L["Show Shade"], L["This will display the shade overlay on the ActionButtons"] };
										-- set = function(self) 
											-- db.showshade = not(db.showshade)
											-- module:PostUpdateSettings()
										-- end;
										-- get = function() return db.showshade end;
									-- };
									{
										type = "widget";
										element = "Header";
										order = 11;
										width = "full";
										msg = L["Button Text"];
									};
									{
										type = "widget";
										element = "CheckButton";
										name = "showHotkeys";
										order = 101;
										width = "full"; 
										msg = L["Show hotkeys on the ActionButtons"];
										desc = { L["Show Keybinds"], L["This will display your currently assigned hotkeys on the ActionButtons"] };
										set = function(self) 
											db.showHotkeys = not(db.showHotkeys)
											module:PostUpdateSettings()
										end;
										get = function() return db.showHotkeys end;
									};
									{
										type = "widget";
										element = "CheckButton";
										name = "showMacros";
										order = 106;
										width = "full"; 
										msg = L["Show macro names on the ActionButtons"];
										desc = { L["Show Names"], L["This will display the names of your macros on the ActionButtons"] };
										set = function(self) 
											db.showMacros = not(db.showMacros)
											module:PostUpdateSettings()
										end;
										get = function() return db.showMacros end;
									};
								};
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
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["ActionBars"], "default", restoreDefaults)
	end
end

module.OnEnable = function(self)
	-- set up keybind functionality
	do
		-- any button added to the self.buttons table prior to 'PLAYER_LOGIN'
		-- will be automatically set up to work with the hoverbind system
		-- this is to allow other modules to easily hook into the system 
		-- without having to mess with LibKeyBound themselves!
		do
			local button
			for buttonName, bindingID in pairs(self.buttons) do
				button = _G[buttonName]
				if (button) then
					self:RegisterButtonForKeybind(button, bindingID)
				end
			end
		end
		
		-- style the keybind frames
		do
			local styleKeyBindDialog, styleBindFrame
			do
				local once
				styleKeyBindDialog = function()
					if (once) then return end

					gUI:DisableTextures(KeyboundDialog)
					gUI:SetUITemplate(KeyboundDialog, "backdrop")
					gUI:SetUITemplate(KeyboundDialogCheck, "checkbutton")
					gUI:SetUITemplate(KeyboundDialogOkay, "button", true)
					gUI:SetUITemplate(KeyboundDialogCancel, "button", true)
					
					local point, anchor, relpoint, x, y, i, region
								
					for i = 1, KeyboundDialog:GetNumRegions() do
						region = select(i, KeyboundDialog:GetRegions())
						if (region:GetObjectType() == "FontString") then
							point, anchor, relpoint, x, y = region:GetPoint()
							
							if (point == "TOP") then
								region:SetFontObject(gUI_TextFontNormal)
								region:ClearAllPoints()
								region:SetPoint("TOP", KeyboundDialog, "TOP", 0, -8)
							else
								region:SetFontObject(gUI_TextFontSmallWhite)
							end
						end
					end
					
					once = true
				end
			end
			
			do
				local once
				styleBindFrame = function()
					if (once) then return end
					
					local frame = LKB.frame
					if (frame) then
						frame.text:SetFontObject(gUI_TextFontSmallWhite)
						frame.text:SetTextColor(unpack(C["value"]))
						frame.text:SetJustifyH("CENTER")
						frame.text:SetJustifyV("MIDDLE")
						frame.text:ClearAllPoints()
						frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
						
						frame.text.SetFontObject = noop
						frame.text.ClearAllPoints = noop
						frame.text.SetAllPoints = noop
						frame.text.SetPoint = noop
					
						once = true
					end
				end
			end
			
			if (KeyboundDialog) then
				styleKeyBindDialog()
			else
				hooksecurefunc(LKB, "Initialize", styleKeyBindDialog)
			end
				
			if (LKB.frame) then
				styleBindFrame()
			else
				hooksecurefunc(LKB, "Activate", styleBindFrame)
			end
		end
		
		LKB.RegisterCallback(self, "LIBKEYBOUND_ENABLED")
		LKB.RegisterCallback(self, "LIBKEYBOUND_DISABLED")
		LKB.RegisterCallback(self, "LIBKEYBOUND_MODE_COLOR_CHANGED")
		LKB:SetColorKeyBoundMode(1, 1, 1, 1/5)
		
		self:CreateChatCommand({ "keybind", "bindkey", "hoverbind", "bind" }, module.ToggleKeybindMode)
		_G.GUIS_ToggleKeybindMode = module.ToggleKeybindMode -- global for keybind functionality
	end
end

module.OnDisable = function(self)
	if db.lockActionBars and (tonumber(LOCK_ACTIONBAR) ~= 1) then
		db.lockActionBars = 0
		module:RefreshBlizzardOptionsMenu()
		module:UpdateActionBarLock()
	end

	if not(db.lockActionBars) and (tonumber(LOCK_ACTIONBAR) == 1) then
		db.lockActionBars = 1
		module:RefreshBlizzardOptionsMenu()
		module:UpdateActionBarLock()
	end
end
