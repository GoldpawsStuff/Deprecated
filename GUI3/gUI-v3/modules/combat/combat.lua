--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Combat")

local L, C, F, M, db

local defaults = {
	scrollingText = true; -- use our own scrolling combat text module
	dps = true; -- show our simple dps/heal meter
	threat = true; -- show our threat bar
	
	-- dps/heal settings
	showSoloDPS = false; -- show the DPS meter when you are solo/ungrouped
	showPvPDPS = false; -- show the DPS meter in PvP situations
	showDPSVerboseReport = true; -- give a simple verbose report to the chat upon combat end
	minDPS = 1000; -- don't show reports unless you do at least this much DPS
	minTime = 60; -- don't show reports for fights shorter than this in seconds
	
	-- threat settings
	showWarnings = true; -- show warnings when you change threat group
	showSoloThreat = false; -- show the threat meter when you are solo/ungrouped
	showPvPThreat = false; -- show the threat meter in PvP situations (will show for pets, bosses, npcs, etc)
	showHealerThreat = false; -- shows the threat meter for healers as well as tanks/dps
	showFocusThreat = true; -- shows the threat for the focus target instead of target when availble

	-- yeah... my coding these days has gone straight to Hell! This is about as elegant as a dancing hippo.
	dps_pos = { "BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 8, 8 };
	threat_pos = { "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -8, 8 };

	-- the bar dock will be positioned with an 8px space under the minimap
	dockposition = { "TOPLEFT", "UIParent", "TOPLEFT", 8, -(8 + MINIMAP_SIZE + 6) };
	
	-- bars module
	showXPBar = true; 
	showXPBarAtMax = false; -- show xpbar at MAX_PLAYER_LEVEL (highest in your expansion, or if you have cancelled XP gains)
	showRepBar = true;
	showCaptureBar = true; -- capture bars in EotS
	
	-- score module
	showWorldScore = true;
	showDetailedScore = false; -- only show numbers and names, not text like "waves" or "reinforcements" except on mouseover
	
}

module.UpdateAll = function(self)
	local dps = self:GetModule("DPS")
	if (dps) then
		dps:PostUpdateSettings()
	end
	
	local dps = self:GetModule("Threat")
	if (threat) then
		threat:PostUpdateSettings()
	end

	local sct = self:GetModule("SCT")
	if (sct) then
		sct:PostUpdateSettings()
	end

	local bars = self:GetModule("Bars")
	if (bars) then
		bars:PostUpdateSettings()
	end
end

module.PostUpdateSettings = function(self)
	self:UpdateAll()
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	
	self:GetModule("DPS"):Init()
	self:GetModule("SCT"):Init()
	self:GetModule("Threat"):Init()
	self:GetModule("Bars"):Init()
	
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
						msg = L["Combat"];
					};
					
					{ -- dps/hps enable
						type = "widget";
						element = "CheckButton";
						name = "showDPS";
						order = 5;
						width = "full"; 
						msg = L["Enable simple DPS/HPS meter"];
						desc = nil;
						set = function(self) 
							db.dps = not(db.dps)
							self:onrefresh()
							module:UpdateAll()
						end;
						onrefresh = function(self) 
							if (self:get()) then
								if not(self.parent.child.dps:IsEnabled()) then
									self.parent.child.dps:Enable()
								end
							else
								if (self.parent.child.dps:IsEnabled()) then
									self.parent.child.dps:Disable()
								end
							end
						end;
						get = function() return db.dps end;
						init = function(self) self:onrefresh() end;

					};

					{ -- dps/hps choices
						type = "group";
						order = 15;
						name = "dps";
						virtual = true;
						children = {
							{ -- dps/hps title
								type = "widget";
								element = "Header";
								order = 1;
								msg = L["Simple DPS/HPS Meter"];
							};
							{ -- solo
								type = "widget";
								element = "CheckButton";
								name = "showSoloDPS";
								order = 10;
								msg = L["Show DPS/HPS when you are solo"];
								desc = nil;
								set = function(self) 
									db.showSoloDPS = not(db.showSoloDPS)
									module:UpdateAll()
								end;
								get = function() return db.showSoloDPS end;
							};
							{ -- pvp
								type = "widget";
								element = "CheckButton";
								name = "showPvPDPS";
								order = 15;
								msg = L["Show DPS/HPS when you are in a PvP instance"];
								desc = nil;
								set = function(self) 
									db.showPvPDPS = not(db.showPvPDPS)
									module:UpdateAll()
								end;
								get = function() return db.showPvPDPS end;
							};
							{ -- verbose report
								type = "widget";
								element = "CheckButton";
								name = "showDPSVerboseReport";
								order = 20;
								msg = L["Display a simple verbose report at the end of combat"];
								desc = nil;
								set = function(self) 
									db.showDPSVerboseReport = not(db.showDPSVerboseReport)
									self:onrefresh()
									module:UpdateAll()
								end;
								onrefresh = function(self) 
									if (self:get()) then
										self.parent.child.report:Enable()
									else
										self.parent.child.report:Disable()
									end
								end;
								get = function() return db.showDPSVerboseReport end;
								init = function(self) self:onrefresh() end;
							};
							{ -- verbose report choices
								type = "group";
								order = 21;
								name = "report";
								virtual = true;
								children = {
									{ -- minimum average DPS text
										type = "widget";
										element = "Header";
										name = "minDPSText";
										order = 10;
										width = "minimum";
										indented = true;
										msg = L["Minimum DPS to display: "];
									};
									
									{ -- minimum average DPS inputbox
										type = "widget";
										element = "EditBox";
										args = { numeric = true };
										name = "minDPS";
										order = 11;
										width = "last";
										msg = L["dps"];
										set = function(self, msg) 
											local value = tonumber(msg)
											
											if (value) then
												value = floor(value)
												if (value >= 0) then
													db.minDPS = value
													
													module:UpdateAll()
												end
											end
										end;
										get = function(self) return db.minDPS end;
									};
									
									
									{ -- minimum combat duration text
										type = "widget";
										element = "Header";
										name = "minTimeText";
										order = 20;
										width = "minimum";
										indented = true;
										msg = L["Minimum combat duration to display: "];
									};
									
									{ -- minimum combat duration inputbox
										type = "widget";
										element = "EditBox";
										args = { numeric = true };
										name = "minTime";
										order = 21;
										width = "last";
										msg = L["s"];
										set = function(self, msg) 
											local value = tonumber(msg)
											
											if (value) then
												value = floor(value)
												if (value >= 0) then
													db.minTime = value
													
													module:UpdateAll()
												end
											end
										end;
										get = function(self) return db.minTime end;
									};
								};
							};
						};
					};

					{ -- threat enable
						type = "widget";
						element = "CheckButton";
						name = "showThreat";
						order = 6;
						width = "full"; 
						msg = L["Enable simple Threat meter"];
						desc = nil;
						set = function(self) 
							db.threat = not(db.threat)
							self:onrefresh()
							module:UpdateAll()
						end;
						onrefresh = function(self) 
							if (self:get()) then
								if not(self.parent.child.threat:IsEnabled()) then
									self.parent.child.threat:Enable()
								end
							else
								if (self.parent.child.threat:IsEnabled()) then
									self.parent.child.threat:Disable()
								end
							end
						end;
						get = function() return db.threat end;
						init = function(self) self:onrefresh() end;
					};
					
					{ -- sct enable
						type = "widget";
						element = "CheckButton";
						name = "showSCT";
						order = 6;
						width = "full"; 
						msg = L["Enable simple scrolling combat text"] .. " " .. L["(In Development)"];
						desc = nil;
						set = function(self) 
							db.scrollingText = not(db.scrollingText)
							self:onrefresh()
							module:UpdateAll()
						end;
						onrefresh = function(self) 
							self:Disable()
		--					if (self:get()) then
		--						if not(self.parent.child.scrollingText:IsEnabled()) then
		--							self.parent.child.scrollingText:Enable()
		--						end
		--					else
		--						if (self.parent.child.scrollingText:IsEnabled()) then
		--							self.parent.child.scrollingText:Disable()
		--						end
		--					end
						end;
						get = function() return db.scrollingText end;
						init = function(self) self:onrefresh() end;
					};
					
					{ -- threat choices
						type = "group";
						order = 25;
						name = "threat";
						virtual = true;
						children = {
							{ -- threat title
								type = "widget";
								element = "Header";
								order = 1;
								msg = L["Simple Threat Meter"];
							};
							{ -- solo
								type = "widget";
								element = "CheckButton";
								name = "showSoloThreat";
								order = 10;
								msg = L["Show threat when you are solo"];
								desc = nil;
								set = function(self) 
									db.showSoloThreat = not(db.showSoloThreat)
									module:UpdateAll()
								end;
								get = function() return db.showSoloThreat end;
							};
							{ -- pvp
								type = "widget";
								element = "CheckButton";
								name = "showPvPThreat";
								order = 15;
								msg = L["Show threat when you are in a PvP instance"];
								desc = nil;
								set = function(self) 
									db.showPvPThreat = not(db.showPvPThreat)
									module:UpdateAll()
								end;
								get = function() return db.showPvPThreat end;
							};
							{ -- healer
								type = "widget";
								element = "CheckButton";
								name = "showHealerThreat";
								order = 20;
								msg = L["Show threat when you are a healer"];
								desc = nil;
								set = function(self) 
									db.showHealerThreat = not(db.showHealerThreat)
									module:UpdateAll()
								end;
								get = function() return db.showHealerThreat end;
							};
							{ -- focus
								type = "widget";
								element = "CheckButton";
								name = "showFocusThreat";
								order = 25;
								msg = L["Use the Focus target when it exists"];
								desc = nil;
								set = function(self) 
									db.showFocusThreat = not(db.showFocusThreat)
									module:UpdateAll()
								end;
								get = function() return db.showFocusThreat end;
							};
							{ -- warnings! achtung!
								type = "widget";
								element = "CheckButton";
								name = "showWarnings";
								order = 30;
								msg = L["Enable threat warnings"];
								desc = nil;
								set = function(self) 
									db.showWarnings = not(db.showWarnings)
									module:UpdateAll()
								end;
								get = function() return db.showWarnings end;
							};
						};
					};
					
					{ -- status bars
						type = "group";
						order = 30;
						name = "statusbars";
						virtual = true;
						children = {
							{
								type = "widget";
								element = "Title";
								order = 1;
								msg = L["StatusBars"];
							};
							{
								type = "widget";
								element = "Text";
								order = 2;
								msg = L["Here you can set the visibility and behaviour of various objects like the XP and Reputation Bars, the Battleground Capture Bars and more. If you wish to change their position, you can unlock them for movement with |cFF4488FF/glock|r."];
							};
							{ -- xpbar
								type = "widget";
								element = "CheckButton";
								name = "showXPBar";
								order = 10;
								width = "full"; 
								msg = L["Show the player experience bar."];
								desc = nil;
								set = function(self) 
									db.showXPBar = not(db.showXPBar)
									self:onrefresh()
									module:PostUpdateSettings()
								end;
								get = function() return db.showXPBar end;
								onrefresh = function(self) 
									if (db.showXPBar) then
										self.parent.child.showXPBarAtMax:Enable()
									else
										self.parent.child.showXPBarAtMax:Disable()
									end
								end;
								init = function(self) self:onrefresh() end;
							};					
							{ -- xpbar at max
								type = "widget";
								element = "CheckButton";
								name = "showXPBarAtMax";
								order = 11;
								indented = true;
								width = "full"; 
								msg = L["Show when you are at your maximum level or have turned off experience gains."];
								desc = nil;
								set = function(self) 
									db.showXPBarAtMax = not(db.showXPBarAtMax)
									module:PostUpdateSettings()
								end;
								get = function() return db.showXPBarAtMax end;
							};	
							{ -- repbar
								type = "widget";
								element = "CheckButton";
								name = "showRepBar";
								order = 15;
								width = "full"; 
								msg = L["Show the currently tracked reputation."];
								desc = nil;
								set = function(self) 
									db.showRepBar = not(db.showRepBar)
									module:PostUpdateSettings()
								end;
								get = function() return db.showRepBar end;
							};					
							{ -- capturebar
								type = "widget";
								element = "CheckButton";
								name = "showCaptureBar";
								order = 25;
								width = "full"; 
								msg = L["Show the capturebar for PvP objectives."];
								desc = nil;
								set = function(self) 
									db.showCaptureBar = not(db.showCaptureBar)
									module:PostUpdateSettings()
								end;
								get = function() return db.showCaptureBar end;
							};					
						};
					};
						
					{ -- sct choices
						type = "group";
						order = 35;
						name = "sct";
						virtual = true;
						children = {
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
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["Combat"], "default", restoreDefaults)
	end
end

module.OnEnable = function(self)
	self:GetModule("DPS"):Enable()
	self:GetModule("SCT"):Enable()
	self:GetModule("Threat"):Enable()
	self:GetModule("Bars"):Enable()
end
