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

local unitframes = gUI:GetModule("Unitframes")
local module = unitframes:NewModule("GroupTools")

local L, C, F, M
local update, updateCombat
local CreateHeader, CreateButton, CreateCheckButton, CreateIcon

CreateHeader = function(parent, msg)
	local text = parent:CreateFontString(nil, "ARTWORK")
	text:SetFontObject(gUI_DisplayFontSmallWhite)
	text:SetText(msg)
	text:SetWidth(parent:GetWidth() - 32)
	text:SetJustifyH("LEFT")
	return text
end

CreateButton = function(parent, w, h, msg, click)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(w, h)
	button:SetText(msg)
	gUI:SetUITemplate(button, "button", true)
	if (click) then
		button:SetScript("OnClick", function(self) 
			PlaySound("igMainMenuOptionCheckBoxOn")
			click() 
		end)
	end
	return button
end

CreateCheckButton = function(parent, msg, click)
	local button = CreateFrame("CheckButton", nil, parent, "OptionsBaseCheckButtonTemplate")  -- OptionsBaseCheckButtonTemplate?
	local text = button:CreateFontString(nil, "ARTWORK")
	text:SetFontObject(gUI_TextFontSmallWhite)
	text:SetPoint("LEFT", button, "RIGHT", 8, 0)
	text:SetTextColor(unpack(C["index"]))
	text:SetWordWrap(true)
	text:SetNonSpaceWrap(true)
	text:SetText(msg)
	button.text = text	
	gUI:SetUITemplate(button, "checkbutton"):SetBackdropColor(nil, nil, nil, gUI:GetOverlayAlpha())
	button:SetScript("OnEnable", function(self) self.text:SetTextColor(unpack(C["index"])) end)
	button:SetScript("OnDisable", function(self) self.text:SetTextColor(unpack(C["disabled"])) end)
	if (click) then
		button:SetScript("OnClick", function(self) 
			if (self:GetChecked()) then
				PlaySound("igMainMenuOptionCheckBoxOn")
			else
				PlaySound("igMainMenuOptionCheckBoxOff")
			end
			click(self) 
		end)
	end
	return button
end

CreateIcon = function(iconValues)
	return "|T" .. M("Icon", "RaidTarget") .. iconValues .. "|t"
end


update = function(self, event, ...)
	local frame = self:GetAttribute("frame")
	if (InCombatLockdown())	then 
		self:RegisterEvent("PLAYER_REGEN_ENABLED", update)
		return 
	elseif (event == "PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", update)
	end
	if (F.IsLeader()) then
		if not(frame:IsShown()) and not(frame.show:IsShown()) then 
			frame.show:Show() 
		end
	else
		if (frame.show:IsShown()) then 
			frame.show:Hide() 
		end
	end
end

updateCombat = function(self, event, ...)
	local frame = self:GetAttribute("frame")
	if (event == "PLAYER_REGEN_DISABLED") then
		if (frame.allAssist:IsEnabled()) then frame.allAssist:Disable() end
		if (frame.convertGroup:IsEnabled()) then frame.convertGroup:Disable() end
		if (frame.role:IsEnabled()) then frame.role:Disable() end
		if (frame.ready:IsEnabled()) then frame.ready:Disable() end
		if (frame.mainTank:IsEnabled()) then frame.mainTank:Disable() end
		if (frame.mainAssist:IsEnabled()) then frame.mainAssist:Disable() end
		if (frame.heal:IsEnabled()) then frame.heal:Disable() end
		if (frame.damager:IsEnabled()) then frame.damager:Disable() end
		if (frame.tank:IsEnabled()) then frame.tank:Disable() end
	else
		if not(frame:IsShown()) then
			if (F.IsLeader()) then
				if not(frame.show:IsShown()) then frame.show:Show() end
			end
		end
		if not(frame.allAssist:IsEnabled()) then frame.allAssist:Enable() end
		if not(frame.convertGroup:IsEnabled()) then frame.convertGroup:Enable() end
		if not(frame.role:IsEnabled()) then frame.role:Enable() end
		if not(frame.ready:IsEnabled()) then frame.ready:Enable() end
		if not(frame.mainTank:IsEnabled()) then frame.mainTank:Enable() end
		if not(frame.mainAssist:IsEnabled()) then frame.mainAssist:Enable() end
		if not(frame.heal:IsEnabled()) then frame.heal:Enable() end
		if not(frame.damager:IsEnabled()) then frame.damager:Enable() end
		if not(frame.tank:IsEnabled()) then frame.tank:Enable() end
	end
end

module.OnInit = function(self)
	L, C, F, M = gUI:GetEnvironment() 
	
	local offset = 16
	local frame = CreateFrame("Frame", nil, gUI:GetAttribute("parent"))
	frame:EnableMouse(true)
	frame:SetFrameStrata("HIGH")
	frame:SetSize(300, 444)
	frame:SetPoint("TOPLEFT", Minimap, "TOPRIGHT", 11, -3)
	frame:SetClampedToScreen(true)
	frame:Hide()
	-- tinsert(UISpecialFrames, frame:GetName())
	
	local show = CreateFrame("Button", nil, Minimap, "SecureHandlerClickTemplate")
	show:SetSize(24, 32)
	show:SetPoint("RIGHT", Minimap, "RIGHT")
	show:SetFrameRef("frame", frame)
	show:SetAttribute("_onclick", [[
		self:Hide(); 
		self:GetFrameRef("frame"):Show();
	]])
	
	frame.show = show
	gUI:SetUITemplate(show, "arrow", "right")
	
	local close = CreateFrame("Button", nil, frame, "SecureHandlerClickTemplate")
	close:SetSize(24, 32)
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	close:SetFrameRef("frame", show)
	close:SetAttribute("_onclick", [[
		self:GetParent():Hide(); 
		self:GetFrameRef("frame"):Show();
	]])
	gUI:SetUITemplate(close, "closebutton")
	
	gUI:SetUITemplate(frame, "backdrop")
	gUI:CreateUIShadow(frame)
	
	local groupHeader = CreateHeader(frame, L["Group Structure"])
	groupHeader:SetPoint("TOP", frame, "TOP", 0, -offset)
	offset = offset + groupHeader:GetHeight() + 8
	
	-- taint!!! this needs to be called securely, and I can't be arsed to do that tonight
	local allAssist = CreateCheckButton(frame, ALL_ASSIST_LABEL_LONG, function(self) 
		if (InCombatLockdown()) then 
			self:SetChecked(IsEveryoneAssistant()) 
			return 
		end
		SetEveryoneIsAssistant(self:GetChecked()) 
	end)
	allAssist:RegisterEvent("GROUP_ROSTER_UPDATE")
	allAssist:RegisterEvent("PARTY_LEADER_CHANGED")
	allAssist:SetScript("OnEvent", function(self, event, ...)
		self:SetChecked(IsEveryoneAssistant())
		if ( UnitIsGroupLeader("player") ) then
			self:Enable()
		else
			self:Disable()
		end
	end)
	allAssist:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -offset)
	offset = offset + allAssist:GetHeight() + 8
	frame.allAssist = allAssist
	
	local convertGroup = CreateButton(frame, 132, 26, CONVERT_TO_RAID, function() 
		if (InCombatLockdown()) then
			return
		end
		if (IsInRaid()) then
			if (GetNumGroupMembers() < 6) then
				ConvertToParty()
			end
		else
			ConvertToRaid()
		end
	end)
	convertGroup:RegisterEvent("GROUP_ROSTER_UPDATE")
	convertGroup:SetScript("OnEvent", function(self, event, ...) 
		if (IsInRaid()) and not(self.inRaid) then
			self.inRaid = true
			self:SetText(CONVERT_TO_PARTY)
		elseif not(IsInRaid()) and (self.inRaid) then
			self.inRaid = nil
			self:SetText(CONVERT_TO_RAID)
		end
	end)
	convertGroup:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -offset)
	offset = offset + convertGroup:GetHeight() + 16
	frame.convertGroup = convertGroup

	local roleHeader = CreateHeader(frame, L["Group Roles"])
	roleHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -offset)
	offset = offset + roleHeader:GetHeight() + 8

	local mainTank = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
	mainTank:SetText([[|TInterface\GroupFrame\UI-Group-MainTankIcon:0:0:0:0:16:16:0:14:0:15|t]] .. " " .. MAINTANK)
	-- mainTank:SetText(MAINTANK)
	mainTank:SetAttribute("type", "maintank")
	mainTank:SetAttribute("unit", "target")
	mainTank:SetAttribute("action", "toggle")
	mainTank:SetSize(132, 26)
	mainTank:ClearAllPoints()
	mainTank:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -offset)
	offset = offset + mainTank:GetHeight() + 8
	gUI:SetUITemplate(mainTank, "button", true)
	frame.mainTank = mainTank
	
	local mainAssist = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
	mainAssist:SetText([[|TInterface\GroupFrame\UI-Group-MainAssistIcon:0:0:0:0:16:16:0:15:0:16|t]] .. " " .. MAINASSIST)
	-- mainAssist:SetText(MAINASSIST)
	mainAssist:SetAttribute("type", "mainassist")
	mainAssist:SetAttribute("unit", "target")
	mainAssist:SetAttribute("action", "toggle") -- toggle, clear, set
	mainAssist:SetSize(132, 26)
	mainAssist:ClearAllPoints()
	mainAssist:SetPoint("TOPLEFT", mainTank, "TOPRIGHT", 4, 0)
	gUI:SetUITemplate(mainAssist, "button", true)
	frame.mainAssist = mainAssist
	
	local tank = CreateButton(frame, 86, 26, INLINE_TANK_ICON .. " " .. TANK, function() UnitSetRole("target", "TANK") end)
	tank:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -offset)
	offset = offset + tank:GetHeight() + 16
	frame.tank = tank

	local heal = CreateButton(frame, 86, 26, INLINE_HEALER_ICON .. " " .. HEALER, function() UnitSetRole("target", "HEALER") end)
	heal:SetPoint("TOPLEFT", tank, "TOPRIGHT", 5, 0)
	frame.heal = heal

	local damager = CreateButton(frame, 86, 26, INLINE_DAMAGER_ICON .. " " .. DAMAGER, function() UnitSetRole("target", "DAMAGER") end)
	damager:SetPoint("TOPLEFT", heal, "TOPRIGHT", 5, 0)
	frame.damager = damager
	
	local marksHeader = CreateHeader(frame, L["World Markers"])
	marksHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -offset)
	offset = offset + marksHeader:GetHeight() + 8

	-- steal and style Blizzards world raid marker flag
	local marker = _G["CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton"]
	_G[marker:GetName() .. "Left"]:SetAlpha(0)
	_G[marker:GetName() .. "Right"]:SetAlpha(0)
	_G[marker:GetName() .. "Middle"]:SetAlpha(0)
	gUI:SetUITemplate(marker, "button")
	marker:SetNormalTexture([[Interface\RaidFrame\Raid-WorldPing]]) -- restore the original flag texture, it looks good
	marker:SetParent(frame)
	marker:SetSize(64,26)
	marker:ClearAllPoints()
	marker:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -offset)
	offset = offset + marker:GetHeight() + 16
	
	local raidiconHeader = CreateHeader(frame, L["Raid Target Icon"])
	raidiconHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -offset)
	offset = offset + raidiconHeader:GetHeight() + 8
	
	local raidicons = {}
	raidicons[0] = CreateButton(frame, 104, 26, RAID_TARGET_NONE, function() SetRaidTarget("target", 0) end)
	raidicons[1] = CreateButton(frame, 64, 26, CreateIcon(":0:0:0:0:256:256:0:64:0:64"), function() SetRaidTarget("target", 1) end)
	raidicons[2] = CreateButton(frame, 64, 26, CreateIcon(":0:0:0:0:256:256:64:128:0:64"), function() SetRaidTarget("target", 2) end)
	raidicons[3] = CreateButton(frame, 64, 26, CreateIcon(":0:0:0:0:256:256:128:196:0:64"), function() SetRaidTarget("target", 3) end)
	raidicons[4] = CreateButton(frame, 64, 26, CreateIcon(":0:0:0:0:256:256:196:256:0:64"), function() SetRaidTarget("target", 4) end)
	raidicons[5] = CreateButton(frame, 64, 26, CreateIcon(":0:0:0:0:256:256:0:64:64:128"), function() SetRaidTarget("target", 5) end)
	raidicons[6] = CreateButton(frame, 64, 26, CreateIcon(":0:0:0:0:256:256:64:128:64:128"), function() SetRaidTarget("target", 6) end)
	raidicons[7] = CreateButton(frame, 64, 26, CreateIcon(":0:0:0:0:256:256:128:196:64:128"), function() SetRaidTarget("target", 7) end)
	raidicons[8] = CreateButton(frame, 64, 26, CreateIcon(":0:0:0:0:256:256:196:256:64:128"), function() SetRaidTarget("target", 8) end)

	raidicons[1]:SetPoint("TOPLEFT", raidiconHeader, "BOTTOMLEFT", 0, -8) 
	raidicons[2]:SetPoint("LEFT", raidicons[1], "RIGHT", 4, 0) 
	raidicons[3]:SetPoint("LEFT", raidicons[2], "RIGHT", 4, 0) 
	raidicons[4]:SetPoint("LEFT", raidicons[3], "RIGHT", 4, 0) 
	raidicons[5]:SetPoint("TOPLEFT", raidicons[1], "BOTTOMLEFT", 0, -4) 
	raidicons[6]:SetPoint("LEFT", raidicons[5], "RIGHT", 4, 0) 
	raidicons[7]:SetPoint("LEFT", raidicons[6], "RIGHT", 4, 0) 
	raidicons[8]:SetPoint("LEFT", raidicons[7], "RIGHT", 4, 0) 
	raidicons[0]:SetPoint("TOPLEFT", raidicons[5], "BOTTOMLEFT", 0, -4)
	
	local role = CreateButton(frame, 104, 26, ROLE_POLL, function() 
		if (InCombatLockdown()) then
			return
		end
		InitiateRolePoll()
	end)
	role:SetPoint("BOTTOMLEFT", 16, 16)
	frame.role = role
	
	-- this one needs to be ...more... secure
	local ready = CreateButton(frame, 104, 26, READY_CHECK, function()
		if (InCombatLockdown()) then
			return
		end
		DoReadyCheck() 
	end)
	ready:SetPoint("BOTTOMRIGHT", -16, 16) 
	frame.ready = ready
	
	-- LOOT_METHOD
	-- LOOT_MASTER_LOOTER
	-- LOOT_NEED_BEFORE_GREED
	
	
	self:SetAttribute("frame", frame)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", update)
	self:RegisterEvent("GROUP_ROSTER_UPDATE", update)
	self:RegisterEvent("PARTY_LEADER_CHANGED", update)
	self:RegisterEvent("PLAYER_REGEN_ENABLED", updateCombat)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", updateCombat)
end
