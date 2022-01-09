local addon = ...
local GP_LibStub = GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0", "GP_AceConsole-3.0")
module:SetDefaultModuleState(false)

-- Lua API
local ipairs, pairs = ipairs, pairs
local print = print
local select = select
local tonumber, tostring = tonumber, tostring

-- WoW API
local CreateFrame = CreateFrame
local GetBuildInfo = GetBuildInfo
local hooksecurefunc = hooksecurefunc
local RegisterStateDriver = RegisterStateDriver
local UIParent = UIParent
local UIPARENT_MANAGED_FRAME_POSITIONS = UIPARENT_MANAGED_FRAME_POSITIONS
local BOTTOMLEFT_ACTIONBAR_PAGE = BOTTOMLEFT_ACTIONBAR_PAGE
local BOTTOMRIGHT_ACTIONBAR_PAGE = BOTTOMRIGHT_ACTIONBAR_PAGE
local LEFT_ACTIONBAR_PAGE = LEFT_ACTIONBAR_PAGE
local NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS
local NUM_STANCE_SLOTS = NUM_STANCE_SLOTS
local RANGE_INDICATOR = RANGE_INDICATOR
local RIGHT_ACTIONBAR_PAGE = RIGHT_ACTIONBAR_PAGE

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local DEBUG = gUI4.version == "Development" -- for me
local build = tonumber((select(2, GetBuildInfo())))

local defaults = {
	profile = {
		clickOnDown = false, -- cast on downpress
		buttonLock = true, -- button drag lock
		locked = true, -- bar movement lock
		skin = "Warcraft", -- not really used by anything, yet. will be used by the config panel. 
		modules = {
			ActionBars = true,
			Backdrop = true,
			BagBar = false, 
			ExtraActionBar = true, 
			PetBar = true,
			StanceBar = true,
			XPBar = true,
			ArtifactBar = true,
			ReputationBar = true,
			VehicleExitBar = true,
			Custom = true,
			Salvage = true
		}
	}
}


------------------------------------------------------------------------
-- 	Hotkeys
------------------------------------------------------------------------
local bindingTable = {}
for _,t in ipairs({
	{ "1", "ACTIONBUTTON%d", NUM_ACTIONBAR_BUTTONS },
	{ tostring(BOTTOMLEFT_ACTIONBAR_PAGE), "MULTIACTIONBAR1BUTTON%d", NUM_ACTIONBAR_BUTTONS },
	{ tostring(BOTTOMRIGHT_ACTIONBAR_PAGE), "MULTIACTIONBAR2BUTTON%d", NUM_ACTIONBAR_BUTTONS },
	{ tostring(RIGHT_ACTIONBAR_PAGE), "MULTIACTIONBAR3BUTTON%d", NUM_ACTIONBAR_BUTTONS },
	{ tostring(LEFT_ACTIONBAR_PAGE), "MULTIACTIONBAR4BUTTON%d", NUM_ACTIONBAR_BUTTONS },
	{ "Pet", "BONUSACTIONBUTTON%d", NUM_PET_ACTION_SLOTS },
	{ "Stance", "SHAPESHIFTBUTTON%d", NUM_STANCE_SLOTS },
	{ "Extra", "EXTRAACTIONBUTTON%d", 1 }
}) do
	bindingTable[t[1]] = {}
	for i = 1, t[3] do
		bindingTable[t[1]][i] = t[2]:format(i)
	end
end
function module:GetBindingTable()
	return bindingTable
end

local function updateButtonVisuals(self)
	if not self.config then return end
	local name = self.actionName
	if name then 
		if self.config.hideElements.macro then
			name:Hide()
		else
			if self._state_type == "action" and not self:IsConsumableOrStackable() then
				name:SetText(self:GetActionText())
			else
				name:SetText("")
			end	
			name:Show()
		end
	end
	local border = self.border or self.Border
	if border then 
		if self:IsEquipped() and not self.config.hideElements.equipped then
			border:SetVertexColor(0, 1.0, 0, 0.35)
			border:Show()
		else
			border:Hide()
		end
	end
	local hotkey = self.hotkey or self.HotKey
	if hotkey then
		local key = self:GetHotkey()
		if not key or key == "" or self.config.hideElements.hotkey then
			hotkey:SetText(RANGE_INDICATOR)
			hotkey:Hide()
		else
			hotkey:SetText(key)
			hotkey:Show()
		end	
	end
end
local function showKey(self)
	if not self.config then return end
	self.config.hideElements.hotkey = false
end
local function hideKey(self)
	if not self.config then return end
	self.config.hideElements.hotkey = true
end
local function showName(self)
	if not self.config then return end
	self.config.hideElements.macro = false
end
local function hideName(self)
	if not self.config then return end
	self.config.hideElements.macro = true
end
local function showkeys() 
	for _, bar in pairs(module.bars) do
		bar:GetSettings().showHotkey = true
		for _, button in bar:GetAll() do
			showKey(button)
			updateButtonVisuals(button)
		end
	end
end
local function hidekeys() 
	for _, bar in pairs(module.bars) do
		bar:GetSettings().showHotkey = false
		for _, button in bar:GetAll() do
			hideKey(button)
			updateButtonVisuals(button)
		end
	end
end
local function showmacro() 
	for _, bar in pairs(module.bars) do
		bar:GetSettings().showMacrotext = true
		for _, button in bar:GetAll() do
			showName(button)
			updateButtonVisuals(button)
		end
	end
end
local function hidemacro() 
	for _, bar in pairs(module.bars) do
		bar:GetSettings().showMacrotext = false
		for _, button in bar:GetAll() do
			hideName(button)
			updateButtonVisuals(button)
		end
	end
end

function module:Lock()
	for _, mod in self:IterateModules() do
		if mod.Lock then
			mod:Lock()
		end
	end
end

function module:Unlock()
	for _, mod in self:IterateModules() do
		if mod.Unlock then
			mod:Unlock()
		end
	end
end

function module:ResetLock()
	for _, mod in self:IterateModules() do
		if mod.ResetLock then
			mod:ResetLock()
		end
	end
end

function module:ApplySettings(event, ...)
	-- kill off deprecated entries
	if self.db.profile.modules.Arrows ~= nil then
		self.db.profile.modules.Arrows = nil
	end

	-- update submodules
	for _, mod in self:IterateModules() do
		if mod.ApplySettings then
			mod:ApplySettings(event, ...)
		end
	end
end

local UIHider = CreateFrame("Frame", "GUI4_ActionBarsUIHider")
UIHider:Hide()

local function hide(...)
	local name, object
	for i = 1, select("#", ...) do
		name = select(i, ...)
		if name then
			object = _G[name]
			if object then
				object:Hide()
			else
				if DEBUG then
					print(("hide() failed: '%s' has been removed"):format(name)) 
				end
			end
		end
	end
end

local function parent(...)
	local name, object
	for i = 1, select("#", ...) do
		name = select(i, ...)
		if name then
			object = _G[name]
			if object then
				object:SetParent(UIHider)
			else
				if DEBUG then
					print(("parent() failed: '%s' has been removed"):format(name)) 
				end
			end
		end
	end
end

local function remove(...)
	local name 
	for i = 1, select("#", ...) do
		name = select(i, ...)
		if name then
			UIPARENT_MANAGED_FRAME_POSITIONS[name] = nil
		end
	end
end

local function unregister(...)
	local name, object
	for i = 1, select("#", ...) do
		name = select(i, ...)
		if name then
			object = _G[name]
			if object then
				object:UnregisterAllEvents()
			else
				if DEBUG then
					print(("unregister() failed: '%s' has been removed"):format(name)) 
				end
			end
		end
	end
end

function module:KillBlizzard()
	unregister("MainMenuBar", "OverrideActionBar", "StanceBarFrame", "PetActionBarFrame", "TalentMicroButtonAlert")
	unregister("CollectionsMicroButtonAlert", "LFDMicroButtonAlert", "TutorialFrameAlertButton", "EJMicroButtonAlert", GuildChallengeAlertFrame and "GuildChallengeAlertFrame")
	parent("MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight", "TalentMicroButtonAlert","EJMicroButtonAlert")
	parent("MainMenuBar", "OverrideActionBar", "MainMenuBarArtFrame", "MainMenuExpBar", "MainMenuBarMaxLevelBar", "ReputationWatchBar", "StanceBarFrame", "PossessBarFrame", "PetActionBarFrame")
	parent("CollectionsMicroButtonAlert", "LFDMicroButtonAlert")
	hide("MainMenuBar", "MainMenuBarArtFrame", "MainMenuBarMaxLevelBar", "StanceBarFrame", "PossessBarFrame", "PetActionBarFrame", GuildChallengeAlertFrame and "GuildChallengeAlertFrame", "TutorialFrameAlertButton", "EJMicroButtonAlert")
	remove("MultiBarRight", "MultiBarLeft", "MultiBarBottomLeft", "MultiBarBottomRight", "MainMenuBar", "StanceBarFrame", "PossessBarFrame", "PETACTIONBAR_YPOS")

	for i = 1,12 do
		LMP:NewChain(_G["ActionButton" .. i]) :Hide() :UnregisterAllEvents() :SetAttribute("statehidden", true) :EndChain()
		LMP:NewChain(_G["MultiBarBottomLeftButton" .. i]) :Hide() :UnregisterAllEvents() :SetAttribute("statehidden", true) :EndChain()
		LMP:NewChain(_G["MultiBarBottomRightButton" .. i]) :Hide() :UnregisterAllEvents() :SetAttribute("statehidden", true) :EndChain()
		LMP:NewChain(_G["MultiBarRightButton" .. i]) :Hide() :UnregisterAllEvents() :SetAttribute("statehidden", true) :EndChain()
		LMP:NewChain(_G["MultiBarLeftButton" .. i]) :Hide() :UnregisterAllEvents() :SetAttribute("statehidden", true) :EndChain()
	end

	for i = 1, 6 do
		LMP:NewChain(_G["OverrideActionBarButton"..i]) :UnregisterAllEvents() :SetAttribute("statehidden", true) :EndChain()
	end

	_G.MainMenuBar:EnableMouse(false)

	_G.MainMenuBar.slideOut:GetAnimations():SetOffset(0,0)
	_G.OverrideActionBar.slideOut:GetAnimations():SetOffset(0,0)
	
	if _G.PlayerTalentFrame then
		_G.PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	else
		hooksecurefunc("TalentFrame_LoadUI", function() _G.PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
	end

	if not self.petBattleController then
		self.petBattleController = CreateFrame("Frame", "GUI4_ActionBarsPetBattleController", UIParent, "SecureHandlerStateTemplate")
		self.petBattleController:SetAttribute("_onstate-petbattle", [[
			if newstate == "petbattle" then
				for i=1,6 do
					local button, vbutton = ("CLICK GUI4Button%d:LeftButton"):format(i), ("ACTIONBUTTON%d"):format(i)
					for k=1,select("#", GetBindingKey(button)) do
						local key = select(k, GetBindingKey(button))
						self:SetBinding(true, key, vbutton)
					end
					-- do the same for the default UIs bindings
					for k=1,select("#", GetBindingKey(vbutton)) do
						local key = select(k, GetBindingKey(vbutton))
						self:SetBinding(true, key, vbutton)
					end
				end
			else
				self:ClearBindings()
			end
		]])
	end
	RegisterStateDriver(self.petBattleController, "petbattle", "[petbattle]petbattle;nopetbattle")
end

function module:GetFadeManager()
	if not self.fademanager then
		self.fademanager = LMP:NewChain(gUI4:CreateFadeManager("ActionBars")) :Enable() .__EndChain
		self.fademanager:SetSize(8,8)
		self.fademanager:SetFrameStrata("LOW")
		-- self.fademanager:ApplySettings()
	end
	return self.fademanager
end

function module:GetBarByID(id)
	return _G["GUI4Bar"..id]
end

function module:IsBarVisible(id)
	local bar = self:GetBarByID(id)
	return bar and bar:IsShown()
end

function module:IsBarLocked(id)
	return self:IsBarVisible(id) and self:GetBarByID(id):GetSettings().locked
end

function module:IsXPBarVisible()
	local mod = self:GetModule("XPBar", true)
	return mod and mod:IsEnabled() and mod:IsXPBarVisible()
end

function module:IsReputationBarVisible()
	local mod = self:GetModule("ReputationBar", true)
	return mod and mod:IsEnabled() and mod:IsReputationBarVisible()
end

function module:IsArtifactBarVisible()
	local mod = self:GetModule("ArtifactBar", true)
	return mod and mod:IsEnabled() and mod:IsArtifactBarVisible()
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("FAQ", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["ActionBars"],
			args = gUI4:GenerateFAQOptionsTable(
				L["\n|cffffd200" .. "Where is the micro menu?" .. "|r"],
				L["There currently isn't one in Goldpaw's Actionbars, but you can middle click the minimap for a dropdown menu with all the relevant shortcuts if you have Goldpaw's Minimap installed."],
				L["\n|cffffd200" .. "How can I move the bars around?" .. "|r"],
				L["The command /glock toggles the movable frame anchors, though currently only the stance bar, the pet bar, the extra actionbutton, the vehicle exit button and the fishing button are movable."],
				L["\n|cffffd200" .. "How can I change number of visible actionbars?" .. "|r"],
				L["The command /setbars followed by a number from 1 to 3, and the command /setsidebars followed by a number from 0 to 2 toggles the number of visible bars. You can also change this setting from the /gui options menu under the 'Visibility' submenu and the 'ActionBars' tab."],
        		L["\n|cffffd200" .. "My spells are cast when I try to move them!" .. "|r"],
				L["This setting used to exist in Blizzard's interface menu under the 'Combat' settings, but was removed in patch 7.0.1 from the interface. You can change it now from the /gui options menu under the 'Miscellaneous' submenu and the 'ActionBars' tab!"]
        		--L["Goldpaw's Actionbars follow the default WoW setting for this. You can change it by opening the '%s', selecting the '%s' button, then the '%s' tab, and uncheck the option named '%s'."]:format(_G.MAINMENU_BUTTON, _G.UIOPTIONS_MENU, _G.COMBAT_LABEL, _G.ACTION_BUTTON_USE_KEY_DOWN)
			)
		}
	})
	

	gUI4:RegisterModuleOptions("Miscellaneous", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["ActionBars"],
			args = {
				description = {
					type = "description",
					name = L["The option to toggle whether spells are cast when you press the key down or when you release it still exists in-game, but was for reasons unknown removed from the normal user interface menu by Blizzard with the release of Legion.|n|n"],
					order = 2,
					width = "full"
				},
				castondown = {
					order = 10, 
					type = "toggle",
					name = L["Cast action keybinds on key down."],
					desc = L["Cast spells when you push a button down. Uncheck to cast spells when you release the button instead."],
					get = function() 
						return GetCVarBool("ActionButtonUseKeyDown")
					end,
					set = function(_, value) 
						SetCVar("ActionButtonUseKeyDown", GetCVarBool("ActionButtonUseKeyDown") and "0" or "1")
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:UpdateButtonSettings()
					end,
					width = "full"
				}
			}
		}
	})

	gUI4:RegisterModuleOptions("Sizing", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["ActionBars"],
			args = {
				description = {
					type = "description",
					name = L["Actionbuttons come in two main sizes. The big buttons which is the default size for the five standard actionbars, and the small buttons which is the default for the pet- and stance bars. Click the buttons below or type |cff4488ff/smallbars|r or |cff4488ff/bigbars|r to toggle the sizes.|n|n"],
					order = 2,
					width = "full"
				},
				smallbars = {
					order = 11, 
					type = "execute",
					name = L["Small Bars"],
					desc = L["Display all bars with small buttons. This is the same as typing |cff4488ff/smallbars|r in the chat."],
					func = function() 
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:SetSmallBars()
					end
				},
				bigbars = {
					order = 16, 
					type = "execute",
					name = L["Big Bars (default)"],
					desc = L["Display the five standard actionbars with large buttons, while keeping the pet- and stance bars small. This is the same as typing |cff4488ff/bigbars|r in the chat."],
					func = function() 
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:SetBigBars()
					end
				}
			}
		}
	})

	gUI4:RegisterModuleOptions("Visibility", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["ActionBars"],
			args = {
				header = {
					type = "header",
					name = L["ActionBar Visibility"],
					order = 1,
				},
				description = {
					type = "description",
					name = L["Here you can manually decide whether or not to show specific bars. Not all bars can be toggled, as some like the main actionbar is required for basic game functionality."],
					order = 2,
				},
				headerbottom = {
					order = 10,
					type = "description",
					name = L["|n|n|cffffd200" .. "Main ActionBars" .. "|r"]
				},
				descriptionbottom = {
					order = 11,
					type = "description",
					name = L["Choose the number of visible actionbars located at the bottom of the screen.|n|n"]
				},
				onebottombar = {
					order = 12, 
					type = "execute",
					name = L["One Bar"],
					desc = L["Only display the main actionbar."],
					func = function() 
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:SetBottomBars(1)
					end
				},
				twobottombars = {
					order = 13, 
					type = "execute",
					name = L["Two Bars"],
					desc = L["Display two bottom actionbars, with the main bar at the bottom, and the bar referred to as the \"bottom left\" bar in the default UI displayed at the top."],
					func = function() 
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:SetBottomBars(2)
					end
				},
				threebottombars = {
					order = 14, 
					type = "execute",
					name = L["Three Bars"],
					desc = L["Display all three bottom actionbars, with the main bar at the bottom, and the bar referred to as the \"bottom right\" bar in the default UI displayed at the top."],
					func = function() 
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:SetBottomBars(3)
					end
				},
				headerside = {
					order = 20,
					type = "description",
					name = L["|n|n|cffffd200" .. "Sidebars" .. "|r"]
				},
				descriptionside = {
					order = 21,
					type = "description",
					name = L["Choose the number of visible actionbars located at the right side of the screen.|n|n"]
				},
				nosidebars = {
					order = 22, 
					type = "execute",
					name = L["No Bars"],
					desc = L["Keep the sidebars hidden"],
					func = function() 
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:SetSideBars(0)
					end
				},
				onesidebar = {
					order = 23, 
					type = "execute",
					name = L["One Bar"],
					desc = L["Only display the right sidebar."],
					func = function() 
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:SetSideBars(1)
					end
				},
				twosidebars = {
					order = 24, 
					type = "execute",
					name = L["Two Bars"],
					desc = L["Display both sidebars."],
					func = function() 
						local ActionBars = self:GetModule("ActionBars")
						ActionBars:SetSideBars(2)
					end
				},
				headerfishing = {
					order = 100,
					type = "description",
					name = L["|n|n|cffffd200" .. "Custom Buttons" .. "|r"]
				},
				descriptionfishing = {
					order = 101,
					type = "description",
					name = L["Choose the visibility of special actionbars and buttons like the Fishing button that appears when you equip a Fishing Pole.|n|n"]
				},
				optionfishing = {
					order = 102, 
					type = "toggle",
					name = L["Display the fishing button."],
					desc = L["Toggles the display of the Fishing button that appears when you equip a Fishing Pole."],
					get = function() 
						local Custom = self:GetModule("Custom")
						return Custom.db.profile.enabled
					end,
					set = function(_, value) 
						local Custom = self:GetModule("Custom")
						Custom.db.profile.enabled = value
						Custom.bar:ApplyVisibilityDriver()
					end,
					width = "full"
				},
				optionsalvage = {
					order = 103, 
					type = "toggle",
					name = L["Display salvage crates and garrison mining tools."],
					desc = L["Toggles the display of clickable salvage crate buttons when you're in your Salvage Yard, as well as various mining tools when visiting your Garrison Mine."],
					get = function() 
						local Salvage = self:GetModule("Salvage")
						return Salvage.db.profile.enabled
					end,
					set = function(_, value) 
						local Salvage = self:GetModule("Salvage")
						Salvage.db.profile.enabled = value
						Salvage:UpdateBarDisplay()
					end,
					width = "full"
				},
			}
		}
	})
end

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_ActionBars_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	if self.db.profile.modules.Arrows ~= nil then
		self.db.profile.modules.Arrows = nil
	end
	
	self.bars = {} -- holder for all bars from all modules
	self:KillBlizzard()
	self:RegisterChatCommand("showkeys", showkeys)
	self:RegisterChatCommand("showbinds", showkeys)
	self:RegisterChatCommand("hidekeys", hidekeys)
	self:RegisterChatCommand("hidebinds", hidekeys)
	self:RegisterChatCommand("shownames", showmacro)
	self:RegisterChatCommand("showmacro", showmacro)
	self:RegisterChatCommand("hidenames", hidemacro)
	self:RegisterChatCommand("hidemacro", hidemacro)
end

function module:OnEnable()
	for name, mod in self:IterateModules() do
		if self.db.profile.modules[name] ~= nil then
			mod:Enable()
		end
	end
	self:SetActiveTheme(self.db.profile.skin)
end

