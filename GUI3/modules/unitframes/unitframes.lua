--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...
local oUF = ns.oUF or oUF 

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Unitframes", "gDB-2.0")
module:SetDefaultModuleLibraries("gDB-2.0", "gFrameHandler-2.0")
module:SetDefaultModuleState(false)

local R = module:NewDataBase("auras")
local RaidGroups = module:NewDataBase("raidgroups")
local UnitFrames = module:NewDataBase("unitframes")

local L, C, F, M, db

local defaults = {
	-- module selection
	loadarenaframes = true; 
	loadbossframes = true;
	loadclassbar = true;
	loadpartyframes = true;
	loadpartypetframes = false;
	loadmaintankframes = true;
	loadraidframes = true;
	loadraidpetframes = false;

	-- common stuff
	showHealth = true; -- show health text
	showPower = true; -- show power text 
	-- showDruid = true; -- show druid mana in forms (player only)
	showGridIndicators = true; -- show grid indicators for selected classes

	-- set focus
	shiftToFocus = true; -- shift+click a unit frame to make it your focus target
	focusKey = 1; -- 1 = shift, 2 = ctrl, 3 = alt, 4 = none
	focusButton = 1; -- mouse button

	-- party frames
	showPlayer = true; -- show player frame as part of the party frames while in a party
	
	-- raid frames
	autoSpec = true; -- automatically decide what frames to show based on spec
	useGridFrames = true; -- use grid frames instead of the dps/tank layout for 16-40p frames
	showRaidFramesInParty = false; -- show your chosen raid frames when you're in a party, instead of the party frames
	showGridFramesAlways = true; -- use the 16-40 layout for all raids, including party if the above option is 'true' 
	show10pAuras = true; -- show auras in the large 10-15p frames
	
	-- player settings
	usePlayerAuraFilter = true; -- use the smart aura filter on the player frame
	showEmbeddedClassBar = false; -- integrated class resource bar
	showFloatingClassBar = true; -- external movable class bar
	showFloatingClassBarAlways = true; -- false; only in combat, true; always
	showPlayerPortrait = true;
	showPlayerAuras = true;
	
	-- target settings
	showTargetPortrait = true;
	showTargetAuras = true;
	desaturateNonPlayerAuras = true; -- desaturate auras on the target frame not cast by the player
	useTargetAuraFilter = true; -- use the smart aura filter on the target frame
}

module.ForAllElements = function(self, func, ...)
	if not(self.frames) then return end
	for i = 1, #self.frames do
		if (self.frames[i]) and (self.frames[i][func]) then
			self.frames[i][func](self.frames[i], ...)
		end
	end
end

module.PostUpdateSettings = function(self)
	F.ApplyToAllUnits(F.PostUpdateOptions)
	self:ForAllElements("PostUpdateSettings")
	F.updateAllVisibility()
end

local fadeRaidFrameManager = function()
	-- prevent the frames themselves from fading out
	local crfc = _G["CompactRaidFrameContainer"]
	crfc:SetParent(UIParent)

	--fade the raid frame manager
	local crfm = _G["CompactRaidFrameManager"]
	local crfb = _G["CompactRaidFrameManagerToggleButton"]

	local ag1, ag2, a1, a2

	--fade in anim
	ag1 = crfm:CreateAnimationGroup()
	a1 = ag1:CreateAnimation("Alpha")
	a1:SetDuration(0.4)
	a1:SetSmoothing("OUT")
	a1:SetChange(1)
	ag1.a1 = a1
	crfm.ag1 = ag1

	--fade out anim
	ag2 = crfm:CreateAnimationGroup()
	a2 = ag2:CreateAnimation("Alpha")
	a2:SetDuration(0.3)
	a2:SetSmoothing("IN")
	a2:SetChange(-1)
	ag2.a2 = a2
	crfm.ag2 = ag2

	crfm.ag1:SetScript("OnFinished", function(ag1)
		local self = ag1:GetParent()
		if not self.ag2:IsPlaying() then
			self:SetAlpha(1)
		end
	end)

	crfm.ag2:SetScript("OnFinished", function(ag2)
		local self = ag2:GetParent()
		if not self.ag1:IsPlaying() then
			self:SetAlpha(0)
		end
	end)

	crfm:SetAlpha(0)

	crfm:SetScript("OnEnter", function(m)
		if m.collapsed and m:GetAlpha() < 0.8 then
			m.ag2:Stop()
			m:SetAlpha(0)
			m.ag1:Play()
		end
	end)
	crfm:SetScript("OnMouseUp", function(self)
		if self.collapsed and not InCombatLockdown() then
			CompactRaidFrameManager_Toggle(self)
		end
	end)
	crfb:SetScript("OnMouseUp", function(self)
		local m = self:GetParent()
		if not m.collapsed then
			m.ag2:Play()
		end
	end)
	crfm:SetScript("OnLeave", function(m)
		if m.collapsed and GetMouseFocus():GetName() ~= "CompactRaidFrameManagerToggleButton" and GetMouseFocus():GetName() ~= "CompactRaidFrameManager" then
			m.ag1:Stop()
			m:SetAlpha(1)
			m.ag2:Play()
		end
	end)
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment
	
	-- disable blizzard stuff
	do
		-- fadeRaidFrameManager()
		-- we disable all frames here, regardless of whether our elements will be loaded or not
		-- if people want other frames, it can NOT be Blizzard frames. Too much risk and taint.

		-- manually disabled raid addons will cause the UI to bug out, so let's force them back on
		if not(IsAddOnLoaded("Blizzard_CUFProfiles") and IsAddOnLoaded("Blizzard_CompactRaidFrames")) then
			for _, v in ipairs({"Blizzard_CUFProfiles", "Blizzard_CompactRaidFrames", "Blizzard_RaidUI"}) do 
				-- print("~~enable~~~~") 
				-- print(v) 
				EnableAddOn(v)
				LoadAddOn(v)
				-- print() 
				-- print(IsAddOnLoaded(v)) 
			end
			-- F.ScheduleRestart()
		end
		CompactUnitFrameProfiles:UnregisterAllEvents()
		gUI:HideObject(CompactRaidFrameManager)
		gUI:KillPanel(11, CompactUnitFrameProfiles)
		gUI:KillObject(PartyMemberBackground)
		
		for i=1, MAX_PARTY_MEMBERS do
			local name = "PartyMemberFrame" .. i
			local pet = name .. "PetFrame"
			gUI:HideObject(_G[name])
			gUI:HideObject(_G[pet])
			_G[name .. "HealthBar"]:UnregisterAllEvents()
			_G[name .. "ManaBar"]:UnregisterAllEvents()
			_G[pet .. "HealthBar"]:UnregisterAllEvents()
		end
		HidePartyFrame()
		HidePartyFrame = noop
		ShowPartyFrame = noop
		
		-- gUI:SetCVar("showArenaEnemyFrames", 0)
		-- oUF:DisableBlizzard("arena1")
		-- oUF:DisableBlizzard("arena2")
		-- oUF:DisableBlizzard("arena3")
		-- oUF:DisableBlizzard("arena4")
		-- oUF:DisableBlizzard("arena5")
		-- Arena_LoadUI = noop
		
		gUI:KillPanel(10, InterfaceOptionsUnitFramePanel)
		-- gUI:KillOption(true, InterfaceOptionsCombatPanelTargetOfTarget)
		-- gUI:KillOption(true, InterfaceOptionsStatusTextPanelPlayer)
		-- gUI:KillOption(true, InterfaceOptionsStatusTextPanelTarget)
		-- gUI:KillOption(true, InterfaceOptionsStatusTextPanelPet)
		-- gUI:KillOption(true, InterfaceOptionsStatusTextPanelParty)
		-- gUI:KillOption(true, InterfaceOptionsStatusTextPanelPercentages)
		-- gUI:KillOption(true, InterfaceOptionsUnitFramePanelArenaEnemyFrames)
		-- gUI:KillOption(true, InterfaceOptionsUnitFramePanelArenaEnemyCastBar)
		-- gUI:KillOption(true, InterfaceOptionsUnitFramePanelArenaEnemyPets)
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
					{ -- title
						type = "widget";
						element = "Title";
						order = 1;
						msg = L["UnitFrames"];
					};
					{ -- description
						type = "widget";
						element = "Text";
						order = 2;
						msg = L["These options can be used to change the display and behavior of unit frames within the UI. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."];
					};
					{ -- show health text
						type = "widget";
						element = "CheckButton";
						name = "showHealth";
						order = 5;
						width = "half"; 
						msg = L["Show values on the health bars"];
						desc = nil;
						set = function(self) 
							db.showHealth = not(db.showHealth)
							module:PostUpdateSettings()
						end;
						get = function() return db.showHealth end;
					};
					{ -- show power text
						type = "widget";
						element = "CheckButton";
						name = "showPower";
						order = 6;
						width = "half"; 
						msg = L["Show values on the power bars"];
						desc = nil;
						set = function(self) 
							db.showPower = not(db.showPower)
							module:PostUpdateSettings()
						end;
						get = function() return db.showPower end;
					};
					{ -- general
						type = "group";
						order = 10;
						name = "general";
						virtual = true;
						children = { 
							{ -- selected modules header
								type = "widget";
								element = "Title";
								order = 1;
								msg = L["Choose what unit frames to load"];
							};
							{ -- selected modules warning
								type = "widget";
								element = "Text";
								order = 2;
								msg = F.warning(L["Changing these settings requires the UI to be reloaded in order to complete."]);
							};
							{ -- party
								type = "widget";
								element = "CheckButton";
								name = "loadpartyframes";
								order = 10;
								width = "half"; 
								msg = L["Enable Party Frames"];
								desc = nil;
								set = function(self) 
									db.loadpartyframes = not(db.loadpartyframes)
									F.ScheduleRestart()
								end;
								get = function() return db.loadpartyframes end;
							};
							{ -- raid
								type = "widget";
								element = "CheckButton";
								name = "loadraidframes";
								order = 15;
								width = "half"; 
								msg = L["Enable Raid Frames"];
								desc = nil;
								set = function(self) 
									db.loadraidframes = not(db.loadraidframes)
									F.ScheduleRestart()
								end;
								get = function() return db.loadraidframes end;
							};
							{ -- boss
								type = "widget";
								element = "CheckButton";
								name = "loadbossframes";
								order = 20;
								width = "half"; 
								msg = L["Enable Boss Frames"];
								desc = nil;
								set = function(self) 
									db.loadbossframes = not(db.loadbossframes)
									F.ScheduleRestart()
								end;
								get = function() return db.loadbossframes end;
							};
							{ -- arena
								type = "widget";
								element = "CheckButton";
								name = "loadarenaframes";
								order = 25;
								width = "half"; 
								msg = L["Enable Arena Frames"];
								desc = nil;
								set = function(self) 
									db.loadarenaframes = not(db.loadarenaframes)
									F.ScheduleRestart()
								end;
								get = function() return db.loadarenaframes end;
							};
							{ -- focus key title
								type = "widget";
								element = "Title";
								order = 30;
								msg = L["Set Focus"];
							};
							{ -- focus key description
								type = "widget";
								element = "Text";
								order = 31;
								msg = L["Here you can enable and define a mousebutton and optional modifier key to directly set a focus target from clicking on a frame."];
							};
							{ -- enable set focus
								type = "widget";
								element = "CheckButton";
								name = "shiftToFocus";
								order = 32;
								width = "full"; 
								msg = L["Enable Set Focus"];
								desc = L["Enabling this will allow you to quickly set your focus target by clicking the key combination below while holding the mouse pointer over the selected frame."];
								set = function(self) 
									if not(InCombatLockdown()) then
										F.ApplyToAllUnits(F.PostUpdateFocusMacro)
										db.shiftToFocus = not(db.shiftToFocus)
									else
										self:SetChecked(db.shiftToFocus)
										print(L["Can't change the Set Focus key while engaged in combat!"])
									end
								end;
								get = function() return db.shiftToFocus end;
							};
							{ -- set focus modifier key
								type = "widget";
								element = "Dropdown";
								order = 33;
								width = "half";
								msg = L["Modifier Key"];
								desc = nil;
								args = { L["Shift"], L["Ctrl"], L["Alt"], NONE };
								set = function(self, option)
									if not(InCombatLockdown()) then
										db.focusKey = UIDropDownMenu_GetSelectedID(self)
										F.ApplyToAllUnits(F.PostUpdateFocusMacro)
									else
										self:init()
										print(L["Can't change the Set Focus key while engaged in combat!"])
									end
								end;
								get = function(self) return db.focusKey end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							{ -- set focus modifier mouse button
								type = "widget";
								element = "Dropdown";
								order = 34;
								width = "half";
								msg = L["Mouse Button"];
								desc = nil;
								args = { 1, 2, 3, 4, 5, 6, 7 }; -- 8 or more entries causes taint
								set = function(self, option)
									if not(InCombatLockdown()) then
										db.focusButton = UIDropDownMenu_GetSelectedID(self)
										F.ApplyToAllUnits(F.PostUpdateFocusMacro)
									else
										self:init()
										print(L["Can't change the Set Focus key while engaged in combat!"])
									end
								end;
								get = function(self) return db.focusButton end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							
						};
					};
					{ -- auras
						type = "group";
						order = 25;
						name = "auras";
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
								msg = L["Here you can change the settings for the auras displayed on the player- and target frames."];
							};
							{ -- aura desaturation
								type = "widget";
								element = "CheckButton";
								name = "desaturateNonPlayerAuras";
								order = 10;
								width = "full"; 
								msg = L["Desature target auras not cast by the player"];
								desc = L["This will desaturate auras on the target frame not cast by you, to make it easier to track your own debuffs."];
								set = function(self) 
									db.desaturateNonPlayerAuras = not(db.desaturateNonPlayerAuras)
									module:PostUpdateSettings()
								end;
								get = function() return db.desaturateNonPlayerAuras end;
							};			
							{ -- hot/dot indicators
								type = "widget";
								element = "CheckButton";
								name = "showGridIndicators";
								order = 20;
								width = "full"; 
								msg = L["Enable indicators for HoTs, DoTs and missing buffs."];
								desc = L["This will display small squares on the party- and raidframes to indicate your active HoTs and missing buffs."];
								set = function(self) 
									db.showGridIndicators = not(db.showGridIndicators)
									module:PostUpdateSettings()
								end;
								get = function() return db.showGridIndicators end;
							};			
						};
					};
					{ -- groups
						type = "group";
						order = 20;
						name = "groups";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Title";
								order = 1;
								msg = L["Groups"];
							};
							{ -- description
								type = "widget";
								element = "Text";
								order = 2;
								msg = L["Here you can change what kind of group frames are used for groups of different sizes."];
							};
							{ -- 5p party
								type = "widget";
								element = "Header";
								order = 100;
								msg = L["5 Player Party"];
							};
							{ -- always raid frames
								type = "widget";
								element = "CheckButton";
								name = "showRaidFramesInParty";
								order = 110;
								width = "full"; 
								msg = L["Use the same frames for parties as for raid groups."];
								desc = L["Enabling this will show the same types of unitframes for 5 player parties as you currently have chosen for 10 player raids."];
								set = function(self) 
									db.showRaidFramesInParty = not(db.showRaidFramesInParty)
									module:PostUpdateSettings()
								end;
								get = function() return db.showRaidFramesInParty end;
							};	
							{ -- 10p raid
								type = "widget";
								element = "Header";
								order = 200;
								msg = L["10 Player Raid"];
							};
							{ -- always max size group frames
								type = "widget";
								element = "CheckButton";
								name = "showGridFramesAlways";
								order = 210;
								width = "full"; 
								msg = L["Use same raid frames as for 25 player raids."];
								desc = L["Enabling this will show the same types of unitframes for 10 player raids as you currently have chosen for 25 player raids."];
								set = function(self) 
									db.showGridFramesAlways = not(db.showGridFramesAlways)
									module:PostUpdateSettings()
								end;
								get = function() return db.showGridFramesAlways end;
							};	
							{ -- 25p raid
								type = "widget";
								element = "Header";
								order = 300;
								msg = L["25 Player Raid"];
							};
							{ -- decide what frames to use based on spec
								type = "widget";
								element = "CheckButton";
								name = "autoSpec";
								order = 310;
								width = "full"; 
								msg = L["Automatically decide what frames to show based on your current specialization."];
								desc = L["Enabling this will display the Grid layout when you are a Healer, and the smaller DPS layout when you are a Tank or DPSer."];
								set = function(self) 
									db.autoSpec = not(db.autoSpec)
									self:onrefresh()
									module:PostUpdateSettings()
								end;
								get = function() return db.autoSpec end;
								onrefresh = function(self) 
									if (db.autoSpec) then
										self.parent.child.useGridFrames:Disable()
									else
										self.parent.child.useGridFrames:Enable()
									end
								end;
								init = function(self) self:onrefresh() end;
							};	
							{ -- use grid frames (manual)
								type = "widget";
								element = "CheckButton";
								name = "useGridFrames";
								order = 320;
								width = "full"; 
								msg = L["Use Healer/Grid layout."];
								desc = L["Enabling this will use the Grid layout instead of the smaller DPS layout for raid groups."];
								set = function(self) 
									db.useGridFrames = not(db.useGridFrames)
									module:PostUpdateSettings()
								end;
								get = function() return db.useGridFrames end;
							};	
							
						};			
					};			
					
					{ -- player
						type = "group";
						order = 30;
						name = "groups";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Title";
								order = 1;
								msg = L["Player"];
							};
							{ -- description
								type = "widget";
								element = "Text";
								order = 510;
								msg = { L["The ClassBar is a larger display of class related information like Holy Power, Runes, Eclipse and Combo Points. It is displayed close to the on-screen CastBar and is designed to more easily track your most important resources."] };
							};
							{ -- integrated class bar
								type = "widget";
								element = "CheckButton";
								name = "showEmbeddedClassBar";
								order = 550;
								width = "full"; 
								indented = true;
								msg = L["Disable integrated classbar"];
								desc = L["This will disable the integrated classbar in the player unitframe"];
								set = function(self) 
									db.showEmbeddedClassBar = not(db.showEmbeddedClassBar)
									module:PostUpdateSettings()
								end;
								get = function() return not(db.showEmbeddedClassBar) end;
							};
							{ -- external class bar
								type = "widget";
								element = "CheckButton";
								name = "showFloatingClassBar";
								order = 545;
								width = "half"; 
								msg = L["Enable large movable classbar"];
								desc = L["This will enable the large on-screen classbar"];
								set = function(self) 
									db.showFloatingClassBar = not(db.showFloatingClassBar)
									module:PostUpdateSettings()
									self:onrefresh()
								end;
								get = function() return db.showFloatingClassBar end;
								onrefresh = function(self)
									if (db.showFloatingClassBar) then
										self.parent.child.showEmbeddedClassBar:Enable()
										self.parent.child.showFloatingClassBarAlways:Enable()
									else
										self.parent.child.showEmbeddedClassBar:Disable()
										self.parent.child.showFloatingClassBarAlways:Disable()
									end
								end;
								init = function(self) 
									self:onrefresh()
								end;
							}; 
							
							{ -- external class bar only in combat or always
								type = "widget";
								element = "Dropdown";
								name = "showFloatingClassBarAlways";
								order = 546;
								width = "half";
								msg = nil;
								desc = nil;
								args = { L["Always"], L["Only in Combat"] };
								set = function(self, option)
									db.showFloatingClassBarAlways = (UIDropDownMenu_GetSelectedID(self) == 1)
									module:PostUpdateSettings()
								end;
								get = function(self) return (db.showFloatingClassBarAlways) and 1 or 2 end;
								init = function(self) UIDropDownMenu_SetSelectedID(self, self:get()) end;
							};
							
							{ -- auras
								type = "widget";
								element = "CheckButton";
								name = "showPlayerAuras";
								order = 20;
								width = "full"; 
								msg = L["Show player auras"];
								desc = L["This decides whether or not to show the auras next to the player frame"];
								set = function(self) 
									db.showPlayerAuras = not(db.showPlayerAuras)
									module:PostUpdateSettings()
								end;
								get = function() return db.showPlayerAuras end;
							};
							{ -- player aura filter
								type = "widget";
								element = "CheckButton";
								name = "usePlayerAuraFilter";
								order = 25;
								width = "full"; 
								msg = L["Filter the player auras in combat"];
								desc = L["This will filter out auras not relevant to your role from the player frame while engaged in combat, to make it easier to track your own auras."];
								set = function(self) 
									db.usePlayerAuraFilter = not(db.usePlayerAuraFilter)
									module:PostUpdateSettings()
								end;
								get = function() return db.usePlayerAuraFilter end;
							};	
						};
					}; 
		

		
					{ -- target
						type = "group";
						order = 40;
						name = "groups";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Title";
								order = 1;
								msg = L["Target"];
							};
							{ -- auras
								type = "widget";
								element = "CheckButton";
								name = "showTargetAuras";
								order = 20;
								width = "full"; 
								msg = L["Show target auras"];
								desc = L["This decides whether or not to show the auras next to the target frame"];
								set = function(self) 
									db.showTargetAuras = not(db.showTargetAuras)
									module:PostUpdateSettings()
								end;
								get = function() return db.showTargetAuras end;
							};
							{ -- target aura filter
								type = "widget";
								element = "CheckButton";
								name = "useTargetAuraFilter";
								order = 25;
								width = "full"; 
								msg = L["Filter the target auras in combat"];
								desc = L["This will filter out auras not relevant to your role from the target frame while engaged in combat, to make it easier to track your own debuffs."];
								set = function(self) 
									db.useTargetAuraFilter = not(db.useTargetAuraFilter)
									module:PostUpdateSettings()
								end;
								get = function() return db.useTargetAuraFilter end;
							};	
						};
					}; 
					
					{ -- pet
					}; 
					
					{ -- focus
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
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["UnitFrames"], "default", restoreDefaults)
	end
	
	-- init sub-modules (order is important, so don't change it)
	self.frames = {}
	tinsert(self.frames, self:GetModule("GroupTools", true))
	tinsert(self.frames, self:GetModule("Player", true))
	tinsert(self.frames, self:GetModule("Target", true))
	tinsert(self.frames, self:GetModule("Pet", true))
	tinsert(self.frames, self:GetModule("ToT", true))
	tinsert(self.frames, self:GetModule("Focus", true))
	tinsert(self.frames, self:GetModule("ClassBar", true))
	if (db.loadpartyframes) then tinsert(self.frames, self:GetModule("Party", true)) end
	if (db.loadbossframes) then tinsert(self.frames, self:GetModule("Boss", true)) end
	if (db.loadarenaframes) then tinsert(self.frames, self:GetModule("Arena", true)) end
	if (db.loadraidframes) then tinsert(self.frames, self:GetModule("Raid", true)) end
	
	self:ForAllElements("Init") -- init sub-modules

	-- visibility callbacks for groups, 
	-- to automatically select the "right" group based on your spec and settings
	self:RegisterEvent("PLAYER_ALIVE", self.PostUpdateSettings)
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", self.PostUpdateSettings)
	self:RegisterEvent("PLAYER_TALENT_UPDATE", self.PostUpdateSettings)
	self:RegisterEvent("TALENTS_INVOLUNTARILY_RESET", self.PostUpdateSettings)

	-- simple fix for the problems with raidframes disappearing on /reload?
	self:RegisterEvent("PLAYER_ENTERING_WORLD", self.PostUpdateSettings)
	
end

module.OnEnable = function(self)
	self:ForAllElements("Enable") -- enable sub-modules
end

