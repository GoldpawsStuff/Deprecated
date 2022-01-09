local addon, gUI4 = ...

-- Lua API
local _G = _G
local print = print
local tinsert = table.insert

-- WoW API
local GP_LibStub = _G.GP_LibStub
local UnitAffectingCombat = _G.UnitAffectingCombat

local AceConfig = GP_LibStub("GP_AceConfig-3.0")
local AceConfigDialog = GP_LibStub("GP_AceConfigDialog-3.0")
local AceDBOptions = GP_LibStub("GP_AceDBOptions-3.0")
local AceGUI = GP_LibStub("GP_AceGUI-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

function gUI4:OpenConfigPanel()
	if UnitAffectingCombat("player") then 
		print(L["Settings can't be modified while engaged in combat."])
		return 
	end
	if (not self.options_container) then
		self.options_container = AceGUI:Create("Frame")
		_G[self.options_container] = self.options_container -- ultimate solution to fix nameless frames, wohoo! 
		tinsert(_G.UIMenus, self.options_container) -- make it close on Esc
	end
	AceConfigDialog:Open("Goldpaw's UI", self.options_container)
end

function gUI4:CloseConfigPanel(event, ...)
	if not (self.options_container and self.options_container:IsShown()) then 
		return
	end
	if (event == "PLAYER_REGEN_DISABLED") then
		print(L["Closing options window because you entered combat."])
	end
	AceConfigDialog:Close("Goldpaw's UI")
	if self.options_container:IsShown() then
		self.options_container:Hide()
	end
end

function gUI4:ToggleConfigPanel()
	if (self.options_container and self.options_container:IsShown()) then
		self:CloseConfigPanel() 
	else
		self:OpenConfigPanel()
	end
end

function gUI4:RegisterModuleOptions(key, options)
	local optionstable = self:GetOptionsTable()
	local new
	if (not optionstable.args[key]) then
		new = true
		optionstable.args[key] = { 
			order = 0, 
			type = "group",
			name = L[key],
			childGroups = "tab",
			args = {}
		}
	-- if not optionstable.plugins[key] then
		-- optionstable.plugins[key] = { 
			-- [key] = {
				-- order = 0, 
				-- type = "group",
				-- name = L[key],
				-- childGroups = "tab",
				-- args = options
			-- }
		-- }
	-- else
	end
	for i,v in pairs(options) do
		-- optionstable.plugins[key][key].args[i] = v
		optionstable.args[key].args[i] = v
		if (type(v) == "table") and (v.type == "group") then
			if (v.name == L["General"]) then -- if new?
				v.order = 0 
			else
				v.order = 1
			end
		end
	end
	-- end
end

function gUI4:GenerateFAQOptionsTable(...)
	local options = {}
	for i = 1, select("#", ...) do
		options["line"..i] = {
			type = "description",
			name = select(i, ...),
			order = i
		}
	end
	return options
end

function gUI4:SetupOptions()
	if (not self.options) then
		self.options = {
			type = "group",
			name = L["Goldpaw's UI"],
			childGroups = "tree",
			plugins = {},
			args = {
				Positioning = {
					order = 0, 
					type = "group",
					name = L["Positioning"],
					childGroups = "tab",
					args = {
						general = {
							order = 0, 
							type = "group",
							name = L["General"],
							args = {
								description1 = {
									order = 1,
									type = "description",
									name = L["|nClick the button below or type |cff4488ff\"/glock\"|r in the chat (without the quotes) followed by the Enter key to toggle the visibility of the movable frame anchors, and choose between automatic and custom placement of the frames.|n"]
								},
								lock = {
									order = 11,
									type = "execute",
									name = L["Toggle Lock"],
									desc = L["Toggles the visibility of the movable frame anchors."],
									func = function() gUI4:ToggleLock() end
								},
								description2 = {
									order = 20,
									type = "description",
									name = L["|nClick the button below or type |cff4488ff\"/glock reset\"|r in the chat (without the quotes) followed by the Enter key to reset the positions of all movable frames, and return them all to automatic placement.|n"]
								},
								resetlock = {
									order = 21,
									type = "execute",
									name = L["Reset"],
									desc = L["Reset all movable frame anchors."],
									func = function() 
										_G.StaticPopup_Show("GUI4_GLOCK_RESET_ALL")
									end
								}
							}
						}
					}
				},
				-- Sizing = {
					-- order = 0, 
					-- type = "group",
					-- name = L["Sizing"],
					-- childGroups = "tab",
					-- args = {
					-- }
				-- },
				-- Fading = {
					-- order = 0, 
					-- type = "group",
					-- name = L["Fading"],
					-- childGroups = "tab",
					-- args = {
						
					-- }
				-- },
				-- L["Miscellaneous"] = {
					-- order = 0, 
					-- type = "group",
					-- name = L["Miscellaneous"],
					-- childGroups = "tab",
					-- args = {
						
					-- }
				-- },
				FAQ = {
					order = 10000, 
					type = "group",
					name = L["FAQ"],
					desc = L["Frequently Asked Questions"],
					childGroups = "tab",
					args = {
						general = {
							order = 0, 
							type = "group",
							name = L["General"],
							args = gUI4:GenerateFAQOptionsTable(
								L["\n|cffffd200" .. "How do I stop stuff from fading out?" .. "|r"],
								L["The commands /enablefade and /disablefade can toggle the automatic fading, or you can disable it directly in the options menu."],
								L["\n|cffffd200" .. "How do I move items around?" .. "|r"],
								L["The command /glock toggles the movable frame anchors."],
								L["\n|cffffd200" .. "How do I reset the position of something?" .. "|r"],
								L["You can reset the positions of saved frames and return to a fully locked mode by using the command /resetlock, or from the options menu. It should be noted that his will reset all frame anchors, as there is no way to reset just a single item."],
								L["\n|cffffd200" .. "Who wrote this masterpiece?" .. "|r"],
								L["Goldpaw's UI was written by Lars \"Goldpaw\" Norberg of EU-Karazhan. Visit www.facebook.com/cogwerkz for more info."]
							)
						}
					}
				}
			}
		}
		for _,mod in gUI4:IterateModules() do
			if mod.SetupOptions then
				mod:SetupOptions()
			end
		end	
		-- self.options.plugins.Profiles = { profiles = AceDBOptions:GetOptionsTable(self.db) }
		self.options.args.Profiles = AceDBOptions:GetOptionsTable(self.db)
		-- make our own profiling system, since our addon suite uses multiple databases squashed into a single menu
		-- self.options.args.Profiles = {
			
		-- }
		
		local SetProfile = self.db.SetProfile
		local CopyProfile = self.db.CopyProfile
		local DeleteProfile = self.db.DeleteProfile
		local ResetProfile = self.db.ResetProfile
		
		function self.db.SetProfile(optionsHandler, value)
			SetProfile(optionsHandler, value)
			for _,mod in gUI4:IterateModules() do
				if mod.db and mod.db.SetProfile and mod.db.profiles[value] then
					mod.db:SetProfile(value)
				end
			end
		end
		function self.db.CopyProfile(optionsHandler, value)
			CopyProfile(optionsHandler, value)
			for _,mod in gUI4:IterateModules() do
				if mod.db and mod.db.CopyProfile and mod.db.profiles[value] then
					mod.db:CopyProfile(value)
				end
			end
		end
		function self.db.DeleteProfile(optionsHandler, value)
			DeleteProfile(optionsHandler, value)
			for _,mod in gUI4:IterateModules() do
				if mod.db and mod.db.DeleteProfile and mod.db.profiles[value] then
					mod.db:DeleteProfile(value)
				end
			end
		end
		function self.db.ResetProfile(optionsHandler)
			ResetProfile(optionsHandler)
			for _,mod in gUI4:IterateModules() do
				if mod.db and mod.db.ResetProfile then
					mod.db:ResetProfile()
				end
			end
		end
	end	
end

function gUI4:GetOptionsTable()
	if not self.options then
		self:SetupOptions()
	end
	return self.options
end

function gUI4:InitializeOptionsTable()
	AceConfig:RegisterOptionsTable("Goldpaw's UI", self:GetOptionsTable())
	AceConfigDialog:SetDefaultSize("Goldpaw's UI", 800, 600)
	-- AceConfigDialog:AddToBlizOptions("Goldpaw's UI", "Goldpaw's UI")
end

function gUI4:ChatCommandParser(cmd)
	if not cmd or cmd == "" then
		self:ToggleConfigPanel()
	end
end

gUI4:AddEvent("PLAYER_REGEN_DISABLED", "CloseConfigPanel")
gUI4:AddChatCommand("gui", "ChatCommandParser")
gUI4:AddChatCommand("gui4", "ChatCommandParser")
gUI4:AddStartupMessage("/gui to toggle the options menu.", true)
gUI4:AddStartupScript("InitializeOptionsTable", true)
