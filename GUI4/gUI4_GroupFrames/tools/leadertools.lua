local addon,ns = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local parent = gUI4:GetModule(addon, true)
if not parent then return end

local module = parent:NewModule("LeaderTools", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme

-- Lua API
local pairs = pairs
local select, type, unpack = select, type, unpack
local tonumber = tonumber
local rawget, setmetatable = rawget, setmetatable
local tinsert, wipe = table.insert, table.wipe

-- WoW API
local CanBeRaidTarget = _G.CanBeRaidTarget
local ConvertToParty = _G.ConvertToParty
local ConvertToRaid = _G.ConvertToRaid
local CreateFrame = _G.CreateFrame
local DoReadyCheck = _G.DoReadyCheck
local GetNumGroupMembers = _G.GetNumGroupMembers
local GetNumSubgroupMembers = _G.GetNumSubgroupMembers
local GetRaidRosterInfo = _G.GetRaidRosterInfo
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local InCombatLockdown = _G.InCombatLockdown
local InitiateRolePoll = _G.InitiateRolePoll
local IsAddOnLoaded = _G.IsAddOnLoaded
local IsInGroup = _G.IsInGroup
local IsInInstance = _G.IsInInstance
local IsInRaid = _G.IsInRaid
local LeaveParty = _G.LeaveParty
local PlaySoundKitID = (tonumber((select(2, GetBuildInfo()))) >= 24500) and _G.PlaySound or _G.PlaySoundKitID 
local SetRaidTarget = _G.SetRaidTarget
local StaticPopup_Show = _G.StaticPopup_Show
local ToggleFriendsFrame = _G.ToggleFriendsFrame
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitExists = _G.UnitExists
local UnitInRaid = _G.UnitInRaid
local UnitName = _G.UnitName
local UninviteUnit = _G.UninviteUnit
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsGroupAssistant = _G.UnitIsGroupAssistant
local UnitIsGroupLeader = _G.UnitIsGroupLeader
local GameFontNormal = _G.GameFontNormal
local GameFontNormalSmall = _G.GameFontNormalSmall
local GameFontNormalGraySmall = _G.GameFontNormalGraySmall
local StaticPopupDialogs = _G.StaticPopupDialogs
local HEALER = _G.HEALER
local MAX_PARTY_MEMBERS = _G.MAX_PARTY_MEMBERS
local CONVERT_TO_PARTY = _G.CONVERT_TO_PARTY
local CONVERT_TO_RAID = _G.CONVERT_TO_RAID
local DAMAGER = _G.DAMAGER
local RAID_CONTROL = _G.RAID_CONTROL
local READY_CHECK = _G.READY_CHECK
local ROLE_POLL = _G.ROLE_POLL
local TANK = _G.TANK

local _, playerName = UnitName("player")

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		skin = "Warcraft",
		togglebutton = {
			position = {},
			enabled = true,
			locked = true
			},
		position = {}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().LeaderTools
end

StaticPopupDialogs["GUI4_GROUPFRAMES_DISBAND_GROUP"] = {
	text = L["This will disband your group. Are you sure?"],
	button1 = _G.YES,
	button2 = _G.NO,
	OnAccept = function() 
		if InCombatLockdown() then return end 
		if UnitInRaid("player") then
			for i = 1, GetNumGroupMembers() do
				local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
				if online and name ~= playerName then
					UninviteUnit(name)
				end
			end
		else
			for i = MAX_PARTY_MEMBERS, 1, -1 do
				if UnitExists("party"..i) then
					UninviteUnit(UnitName("party"..i))
				end
			end
		end
		LeaveParty()
	end,
	OnCancel = function() end,
	exclusive = 1,
	hideOnEscape = 0,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
	preferredIndex = _G.STATICPOPUP_NUMDIALOGS
}

local function strip(object)
	object.BottomLeft:SetAlpha(0)
	object.BottomRight:SetAlpha(0)
	object.BottomMiddle:SetAlpha(0)
	object.TopMiddle:SetAlpha(0)
	object.TopLeft:SetAlpha(0)
	object.TopRight:SetAlpha(0)
	object.MiddleLeft:SetAlpha(0)
	object.MiddleRight:SetAlpha(0)
	object.MiddleMiddle:SetAlpha(0)
	object:SetHighlightTexture("")
	object:SetDisabledTexture("")
	return object
end

local function hideTexture(texture)
	texture:SetTexture("")
	texture:SetAlpha(0)
end

local function stripTextures(object)
	local region
	for i = 1, object:GetNumRegions() do
		region = select(i, object:GetRegions())
		if region:GetObjectType() == "Texture" then
			hideTexture(region)
		end
	end
	return object
end

local function hasLeaderTools()
	local inInstance, instanceType = IsInInstance()
	if ((IsInGroup() and not IsInRaid()) or UnitIsGroupLeader('player') or UnitIsGroupAssistant("player")) and not (inInstance and (instanceType == "pvp" or instanceType == "arena")) then
		return true
	else
		return false
	end
end

local backdropObjects = {}
local function setBackdrop(object)
	backdropObjects[object] = true
	--[[
	object:SetBackdrop({
		bgFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		edgeFile = gUI4:GetMedia("Texture", "Blank"):GetPath(),
		edgeSize = 1,
		insets = { 
			left = -1, 
			right = -1, 
			top = -1, 
			bottom = -1
		}
	})
	object:SetBackdropBorderColor(.15, .15, .15, 1)
	object:SetBackdropColor(0, 0, 0, .75)
	]]
end

local function OnButtonEnter(self)
	self:SetBackdropColor(unpack(self.backdrophighlightcolor))
	self:SetBackdropBorderColor(unpack(self.backdropborderhighlightcolor))
end

local function OnButtonLeave(self)
	self:SetBackdropColor(unpack(self.backdropcolor))
	self:SetBackdropBorderColor(unpack(self.backdropbordercolor))
end

local buttonObjects = {}
local function makeButton(parent, msg, w, h, script, template)
	local button = stripTextures(CreateFrame("Button", nil, parent, "UIPanelButtonTemplate"..(template and ","..template or "")))
	button:SetSize(w, h)
	button:SetText(msg)
	buttonObjects[button] = true

	--[[if button:GetName() then
		local l = _G[button:GetName() .. "Left"]
		local m = _G[button:GetName() .. "Middle"]
		local r = _G[button:GetName() .. "Right"]
		if l then l:SetAlpha(0) end
		if m then m:SetAlpha(0) end
		if r then r:SetAlpha(0) end
	end]]
	
	if button.SetNormalTexture then button:SetNormalTexture("") end
	if button.SetHighlightTexture then button:SetHighlightTexture("") end
	if button.SetPushedTexture then button:SetPushedTexture("") end
	if button.SetDisabledTexture then button:SetDisabledTexture("") end
	
	button:HookScript("OnEnter", OnButtonEnter)
	button:HookScript("OnLeave", OnButtonLeave)
	
	if script then
		button:SetScript("OnClick", function(self) 
			PlaySoundKitID(856, "SFX")
			script() 
		end)
	end
	return button
end

function module:ToggleLeaderTools()
	if not self.loaded then
		self.queueThemeUpdate = true
		return
	end
	if hasLeaderTools() then
		self.showbutton:Show()
	else
		self.frame:Hide()
		self.showbutton:Hide()
	end
end
module.ToggleLeaderTools = gUI4:SafeCallWrapper(module.ToggleLeaderTools)

function module:ResetCounts()
	for role in pairs(self.roleCounts) do
		for status in pairs(self.roleCounts[role]) do
			self.roleCounts[role][status] = 0
		end
	end
end

function module:AddCount(role, alive)
	self.roleCounts[role][alive and "alive" or "dead"] = self.roleCounts[role][alive and "alive" or "dead"] + 1
end

function module:GetCount(role, alive)
	return self.roleCounts[role][alive and "alive" or "dead"]
end

function module:UpdateCounts()
	self:ResetCounts() -- reset existing counts
	-- count current roles
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i)
			if rank then
				self:AddCount(combatRole, not isDead)
			end
		end
	else
		-- add the player first since players aren't technically group members in normal parties
		self:AddCount(UnitGroupRolesAssigned("player"), not UnitIsDeadOrGhost("player"))
		for i = 1, GetNumSubgroupMembers() do
			local unit = "party" .. i
			self:AddCount(UnitGroupRolesAssigned(unit), not UnitIsDeadOrGhost(unit))
		end
	end	
	-- update visual display
	local totalLiving, totalDead = 0, 0
	local living, dead = self:GetCount("TANK", true), self:GetCount("TANK", false)
	totalLiving = totalLiving + living
	totalDead = totalDead + dead
	if dead > 0 then
		self.tankCount:SetFormattedText("%d/%d", living, living + dead)
	else
		self.tankCount:SetFormattedText("%d", living)
	end
	living, dead = self:GetCount("HEALER", true), self:GetCount("HEALER", false)
	totalLiving = totalLiving + living
	totalDead = totalDead + dead
	if dead > 0 then
		self.healerCount:SetFormattedText("%d/%d", living, living + dead)
	else
		self.healerCount:SetFormattedText("%d", living)
	end
	living, dead = self:GetCount("DAMAGER", true), self:GetCount("DAMAGER", false)
	totalLiving = totalLiving + living
	totalDead = totalDead + dead
	if dead > 0 then
		self.damagerCount:SetFormattedText("%d/%d", living, living + dead)
	else
		self.damagerCount:SetFormattedText("%d", living)
	end
	if totalDead > 0 then
		self.raidMembers:SetFormattedText(L["Group Members: |cffffffff%s|r/|cffffffff%s|r"], totalLiving, totalLiving + totalDead)
	else
		self.raidMembers:SetFormattedText(L["Group Members: |cffffffff%s|r"], totalLiving)
	end

end

function module:UpdateRaidTargets()
	local unit = "target"
	local disable = not CanBeRaidTarget(unit)
	local button, target, id
	for i = 1,8 do
		button = self.raidMarkers[i]
		target = GetRaidTargetIndex(unit)
		id = button:GetID()
		if not(disabled) and target and target == id then
			button.disabled:Hide()
			button.enabled:SetVertexColor(1, 1, 1)
		else
			button.disabled:Show()
			button.disabled:SetVertexColor(.75, .75, .75)
			button.enabled:SetVertexColor(.75, .75, .75)
		end
	end
end

function module:UpdateTheme()
	if not self.loaded then
		self.queueThemeUpdate = true
		return
	end
	updateConfig()
	
	LMP:NewChain(self.showbutton) :SetSize(unpack(T.button.size)) :EndChain()
	LMP:NewChain(self.closebutton) :SetSize(unpack(T.button.size)) :EndChain()
	LMP:NewChain(self.dragFrame) :SetSize(unpack(T.frame.size)) :EndChain()
	LMP:NewChain(self.frame) :SetSize(self.frame:IsShown() and T.frame.size[1] or 0.0001, T.frame.size[2]) :SetAttribute("realWidth", T.frame.size[1]) :EndChain()

	LMP:NewChain(self.raidMarkers) :SetSize(unpack(T.raidmarkers.size)) :ClearAllPoints() :SetPoint(unpack(T.raidmarkers.place)) :EndChain()
	LMP:NewChain(self.rolecheck) :SetSize(unpack(T.rolecheck.size)) :ClearAllPoints() :SetPoint(unpack(T.rolecheck.place)) :EndChain()
	LMP:NewChain(self.readycheck) :SetSize(unpack(T.readycheck.size)) :ClearAllPoints() :SetPoint(unpack(T.readycheck.place)) :EndChain()
	LMP:NewChain(self.worldmarkers) :SetSize(unpack(T.worldmarkers.size)) :ClearAllPoints() :SetPoint(unpack(T.worldmarkers.place)) :EndChain()
	LMP:NewChain(self.disbandgroup) :SetSize(unpack(T.disbandgroup.size)) :ClearAllPoints() :SetPoint(unpack(T.disbandgroup.place)) :EndChain()
	LMP:NewChain(self.raidcontrol) :SetSize(unpack(T.raidcontrol.size)) :ClearAllPoints() :SetPoint(unpack(T.raidcontrol.place)) :EndChain()
	LMP:NewChain(self.convert) :SetSize(unpack(T.convert.size)) :ClearAllPoints() :SetPoint(unpack(T.convert.place)) :EndChain()

	for i = 1,8 do
		local db = T.raidmarkers[i]
		LMP:NewChain(self.raidMarkers[i]) :SetSize(unpack(db.size)) :ClearAllPoints() :SetPoint(unpack(db.place)) :EndChain()
		--LMP:NewChain(self.raidMarkers[i].enabled) :SetTexture(db.textures.enabled:GetPath()) :SetSize(db.textures.enabled:GetTexSize()) :SetVertexColor(unpack(db.textures.enabled:GetColor())) :SetAlpha(db.textures.enabled:GetAlpha()) :SetTexCoord(db.textures.enabled:GetTexCoord()) :ClearAllPoints() :SetPoint(db.textures.enabled:GetPoint()) :EndChain()
		--LMP:NewChain(self.raidMarkers[i].disabled) :SetTexture(db.textures.disabled:GetPath()) :SetSize(db.textures.disabled:GetTexSize()) :SetVertexColor(unpack(db.textures.disabled:GetColor())) :SetAlpha(db.disabledSaturation and (1 - tonumber(db.disabledSaturation)) or db.textures.disabled:GetAlpha()) :SetTexCoord(db.textures.disabled:GetTexCoord()) :ClearAllPoints() :SetPoint(db.textures.disabled:GetPoint()) :SetDesaturated(db.disabledSaturation) :EndChain()
		--LMP:NewChain(self.raidMarkers[i].highlight) :SetTexture(db.textures.highlight:GetPath()) :SetSize(db.textures.highlight:GetTexSize()) :SetVertexColor(unpack(db.textures.highlight:GetColor())) :SetAlpha(db.textures.highlight:GetAlpha()) :SetTexCoord(db.textures.highlight:GetTexCoord()) :ClearAllPoints() :SetPoint(db.textures.highlight:GetPoint()) :EndChain()
		LMP:NewChain(self.raidMarkers[i].enabled) :SetTexture(db.textures.enabled:GetPath()) :SetSize(unpack(db.size)) :SetVertexColor(unpack(db.textures.enabled:GetColor())) :SetAlpha(db.textures.enabled:GetAlpha()) :SetTexCoord(db.textures.enabled:GetTexCoord()) :ClearAllPoints() :SetPoint(db.textures.enabled:GetPoint()) :EndChain()
		LMP:NewChain(self.raidMarkers[i].disabled) :SetTexture(db.textures.disabled:GetPath()) :SetSize(unpack(db.size)) :SetVertexColor(unpack(db.textures.disabled:GetColor())) :SetAlpha(db.disabledSaturation and (1 - tonumber(db.disabledSaturation)) or db.textures.disabled:GetAlpha()) :SetTexCoord(db.textures.disabled:GetTexCoord()) :ClearAllPoints() :SetPoint(db.textures.disabled:GetPoint()) :SetDesaturated(db.disabledSaturation) :EndChain()
		LMP:NewChain(self.raidMarkers[i].highlight) :SetTexture(db.textures.highlight:GetPath()) :SetSize(unpack(db.size)) :SetVertexColor(unpack(db.textures.highlight:GetColor())) :SetAlpha(db.textures.highlight:GetAlpha()) :SetTexCoord(db.textures.highlight:GetTexCoord()) :ClearAllPoints() :SetPoint(db.textures.highlight:GetPoint()) :EndChain()
	end
	self:UpdateRaidTargets()

	LMP:NewChain(self.roleCount) :SetSize(unpack(T.rolecounts.size)) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.place)) :EndChain()
	LMP:NewChain(self.roleTank) :SetSize(unpack(T.rolecounts.roles.tank.size)) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.tank.place)) :EndChain()
	LMP:NewChain(self.tankIcon) :SetTexture(T.rolecounts.roles.tank.icon.texture:GetPath()) :SetVertexColor(unpack(T.rolecounts.roles.tank.icon.texture:GetColor())) :SetAlpha(T.rolecounts.roles.tank.icon.texture:GetAlpha()) :SetTexCoord(T.rolecounts.roles.tank.icon.texture:GetTexCoord()) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.tank.icon.place)) :SetSize(unpack(T.rolecounts.roles.tank.icon.size)) :EndChain()
	LMP:NewChain(self.tankLabel) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.tank.label.place)) :SetHeight(T.rolecounts.roles.tank.label.size) :SetFontObject(T.rolecounts.roles.tank.label.fontobject) :SetFontSize(T.rolecounts.roles.tank.label.fontsize or T.rolecounts.roles.tank.label.size) :SetFontStyle(T.rolecounts.roles.tank.label.fontstyle) :SetShadowOffset(unpack(T.rolecounts.roles.tank.label.shadowoffset)) :SetShadowColor(unpack(T.rolecounts.roles.tank.label.shadowcolor)) :SetTextColor(unpack(T.rolecounts.roles.tank.label.color)) :EndChain()
	LMP:NewChain(self.tankCount) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.tank.count.place)) :SetHeight(T.rolecounts.roles.tank.count.size) :SetFontObject(T.rolecounts.roles.tank.count.fontobject) :SetFontSize(T.rolecounts.roles.tank.count.fontsize or T.rolecounts.roles.tank.count.size) :SetFontStyle(T.rolecounts.roles.tank.count.fontstyle) :SetShadowOffset(unpack(T.rolecounts.roles.tank.count.shadowoffset)) :SetShadowColor(unpack(T.rolecounts.roles.tank.count.shadowcolor)) :SetTextColor(unpack(T.rolecounts.roles.tank.count.color)) :EndChain()
	LMP:NewChain(self.roleHealer) :SetSize(unpack(T.rolecounts.roles.healer.size)) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.healer.place)) :EndChain()
	LMP:NewChain(self.healerIcon) :SetTexture(T.rolecounts.roles.healer.icon.texture:GetPath()) :SetVertexColor(unpack(T.rolecounts.roles.healer.icon.texture:GetColor())) :SetAlpha(T.rolecounts.roles.healer.icon.texture:GetAlpha()) :SetTexCoord(T.rolecounts.roles.healer.icon.texture:GetTexCoord()) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.healer.icon.place)) :SetSize(unpack(T.rolecounts.roles.healer.icon.size)) :EndChain()
	LMP:NewChain(self.healerLabel) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.healer.label.place)) :SetHeight(T.rolecounts.roles.healer.label.size) :SetFontObject(T.rolecounts.roles.healer.label.fontobject) :SetFontSize(T.rolecounts.roles.healer.label.fontsize or T.rolecounts.roles.healer.label.size) :SetFontStyle(T.rolecounts.roles.healer.label.fontstyle) :SetShadowOffset(unpack(T.rolecounts.roles.healer.label.shadowoffset)) :SetShadowColor(unpack(T.rolecounts.roles.healer.label.shadowcolor)) :SetTextColor(unpack(T.rolecounts.roles.healer.label.color)) :EndChain()
	LMP:NewChain(self.healerCount) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.healer.count.place)) :SetHeight(T.rolecounts.roles.healer.count.size) :SetFontObject(T.rolecounts.roles.healer.count.fontobject) :SetFontSize(T.rolecounts.roles.healer.count.fontsize or T.rolecounts.roles.healer.count.size) :SetFontStyle(T.rolecounts.roles.healer.count.fontstyle) :SetShadowOffset(unpack(T.rolecounts.roles.healer.count.shadowoffset)) :SetShadowColor(unpack(T.rolecounts.roles.healer.count.shadowcolor)) :SetTextColor(unpack(T.rolecounts.roles.healer.count.color)) :EndChain()
	LMP:NewChain(self.roleDamager) :SetSize(unpack(T.rolecounts.roles.damager.size)) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.damager.place)) :EndChain()
	LMP:NewChain(self.damagerIcon) :SetTexture(T.rolecounts.roles.damager.icon.texture:GetPath()) :SetVertexColor(unpack(T.rolecounts.roles.damager.icon.texture:GetColor())) :SetAlpha(T.rolecounts.roles.damager.icon.texture:GetAlpha()) :SetTexCoord(T.rolecounts.roles.damager.icon.texture:GetTexCoord()) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.damager.icon.place)) :SetSize(unpack(T.rolecounts.roles.damager.icon.size)) :EndChain()
	LMP:NewChain(self.damagerLabel) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.damager.label.place)) :SetHeight(T.rolecounts.roles.damager.label.size) :SetFontObject(T.rolecounts.roles.damager.label.fontobject) :SetFontSize(T.rolecounts.roles.damager.label.fontsize or T.rolecounts.roles.damager.label.size) :SetFontStyle(T.rolecounts.roles.damager.label.fontstyle) :SetShadowOffset(unpack(T.rolecounts.roles.damager.label.shadowoffset)) :SetShadowColor(unpack(T.rolecounts.roles.damager.label.shadowcolor)) :SetTextColor(unpack(T.rolecounts.roles.damager.label.color)) :EndChain()
	LMP:NewChain(self.damagerCount) :ClearAllPoints() :SetPoint(unpack(T.rolecounts.roles.damager.count.place)) :SetHeight(T.rolecounts.roles.damager.count.size) :SetFontObject(T.rolecounts.roles.damager.count.fontobject) :SetFontSize(T.rolecounts.roles.damager.count.fontsize or T.rolecounts.roles.damager.count.size) :SetFontStyle(T.rolecounts.roles.damager.count.fontstyle) :SetShadowOffset(unpack(T.rolecounts.roles.damager.count.shadowoffset)) :SetShadowColor(unpack(T.rolecounts.roles.damager.count.shadowcolor)) :SetTextColor(unpack(T.rolecounts.roles.damager.count.color)) :EndChain()
	LMP:NewChain(self.raidMembers) :ClearAllPoints() :SetPoint(unpack(T.raidmembers.place)) :SetHeight(T.raidmembers.size) :SetFontObject(T.raidmembers.fontobject) :SetFontSize(T.raidmembers.fontsize or T.raidmembers.size) :SetFontStyle(T.raidmembers.fontstyle) :SetShadowOffset(unpack(T.raidmembers.shadowoffset)) :SetShadowColor(unpack(T.raidmembers.shadowcolor)) :SetTextColor(unpack(T.raidmembers.color)) :EndChain()

	LMP:NewChain(self.showbutton.texture) :SetTexture(T.button.textures.open:GetPath()) :SetVertexColor(unpack(T.button.textures.open:GetColor())) :SetAlpha(T.button.textures.open:GetAlpha()) :SetTexCoord(T.button.textures.open:GetTexCoord()) :ClearAllPoints() :SetPoint(T.button.textures.open:GetPoint()) :SetSize(T.button.textures.open:GetSize()) :EndChain()
	LMP:NewChain(self.closebutton.texture) :SetTexture(T.button.textures.close:GetPath()) :SetVertexColor(unpack(T.button.textures.close:GetColor())) :SetAlpha(T.button.textures.close:GetAlpha()) :SetTexCoord(T.button.textures.close:GetTexCoord()) :ClearAllPoints() :SetPoint(T.button.textures.close:GetPoint()) :SetSize(T.button.textures.close:GetSize()) :EndChain()

	for object in pairs(backdropObjects) do
		object:SetBackdrop(T.backdrop)
		object:SetBackdropColor(unpack(T.backdropcolor))
		object:SetBackdropBorderColor(unpack(T.backdropbordercolor))
		object.backdropcolor = T.backdropcolor
		object.backdropbordercolor = T.backdropbordercolor
		object.backdrophighlightcolor = T.backdrophighlightcolor
		object.backdropborderhighlightcolor = T.backdropborderhighlightcolor
	end

	for button in pairs(buttonObjects) do
		button:SetNormalFontObject(GameFontNormalSmall)
		button:SetHighlightFontObject(GameFontNormalSmall)
		button:SetDisabledFontObject(GameFontNormalGraySmall)
	end

	hasTheme = true
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	updateConfig()
	local db = self.db.profile
	if db.locked then
		LMP:Place(self.dragFrame, T.frame.place)
		if not db.position.x then
			self.dragFrame:RegisterConfig(db.position)
			self.dragFrame:SavePosition()
		end
	else
		self.dragFrame:RegisterConfig(db.position)
		if db.position.x then
			self.dragFrame:LoadPosition()
		else
			LMP:Place(self.dragFrame, T.frame.place)
			self.dragFrame:SavePosition()
			self.dragFrame:LoadPosition()
		end
	end
	LMP:Place(self.showbutton, T.button.place)
	--[[
	if db.togglebutton.locked then
		LMP:Place(self.showbutton, T.button.place)
		if not db.togglebutton.position.x then
			self.frame:RegisterConfig(db.togglebutton.position)
			self.frame:SavePosition()
		end
	else
		self.frame:RegisterConfig(db.togglebutton.position)
		if db.togglebutton.position.x then
			self.frame:LoadPosition()
		else
			LMP:Place(self.showbutton, T.button.place)
			self.frame:SavePosition()
			self.frame:LoadPosition()
		end
	end
	]]
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:Lock()
	self.dragFrame.overlay:StartFadeOut()
--	self.showbutton.overlay:StartFadeOut()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	self.dragFrame.overlay:SetAlpha(0)
	self.dragFrame.overlay:Show()
--	self.showbutton.overlay:SetAlpha(0)
--	self.showbutton.overlay:Show()
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	local db = self.db.profile
	db.position.point = nil
	db.position.y = nil
	db.position.x = nil
	db.locked = true
	wipe(db.position)
--	db.togglebutton.position.point = nil
--	db.togglebutton.position.y = nil
--	db.togglebutton.position.x = nil
--	db.togglebutton.locked = true
--	wipe(db.togglebutton.position)
	self:ApplySettings()
end

function module:SetUp()
	self.dragFrame = CreateFrame("Frame", nil, _G.UIParent)
	self.dragFrame.overlay = gUI4:GlockThis(self.dragFrame, L["Group Leader Tools"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "floaters")))
	self.dragFrame.UpdatePosition = function(self) module:UpdatePosition() end
	self.dragFrame.GetSettings = function() return self.db.profile end

	self.frame = CreateFrame("Frame", "gUI4_GroupFramesRaidLeaderToolsFrame", self.dragFrame, "SecureHandlerClickTemplate") 
	self.frame:SetFrameStrata("LOW") -- keep it the same as the group frames 
	self.frame:SetPoint("TOPLEFT", self.dragFrame, "TOPLEFT", 0, 0)
	self.frame:Hide()

	self.frame:HookScript("OnShow", function() self:SendMessage("GUI4_LEADERTOOLS_SHOWN") end)
	self.frame:HookScript("OnHide", function() self:SendMessage("GUI4_LEADERTOOLS_HIDDEN") end)

	self.showbutton = strip(CreateFrame("Button", "gUI4_GroupFramesRaidLeaderToolsShowButton", _G.UIParent, "UIMenuButtonStretchTemplate, SecureHandlerClickTemplate"))
	--self.showbutton.overlay = gUI4:GlockThis(self.showbutton, L["Group Leader Tools Toggle"], function() return self.db.profile.togglebutton end, unpack(gUI4:GetColors("glock", "floaters")))
	--self.showbutton.overlay.UpdatePosition = function(self) module:UpdatePosition() end
	--self.showbutton.overlay.GetSettings = function() return self.db.profile.togglebutton end
	self.showbutton:SetFrameRef("frame", self.frame)
	self.showbutton:SetAttribute("_onclick", [[ 
		self:Hide(); 
		local frame = self:GetFrameRef("frame");
		frame:SetWidth(frame:GetAttribute("realWidth")); 
		frame:Show(); 
		]])
	self.showbutton.texture = LMP:NewChain(self.showbutton:CreateTexture()) :SetDrawLayer("ARTWORK", 0) .__EndChain

	self.closebutton = strip(CreateFrame("Button", "gUI4_GroupFramesRaidLeaderToolsHideButton", self.frame, "UIMenuButtonStretchTemplate, SecureHandlerClickTemplate"))
	self.closebutton:SetAllPoints(self.showbutton)
	self.closebutton:SetFrameRef("frame", self.frame)
	self.closebutton:SetFrameRef("showbutton", self.showbutton)
	self.closebutton:SetAttribute("_onclick", [[ 
		self:GetFrameRef("frame"):Hide(); 
		self:GetFrameRef("frame"):SetWidth(0.0001);
		self:GetFrameRef("showbutton"):Show(); 
	]])
	self.closebutton.texture = LMP:NewChain(self.closebutton:CreateTexture()) :SetDrawLayer("ARTWORK", 0) .__EndChain
	
--	self.showbutton:SetFrameRef("groupframe5", gUI4_GroupFrames_Group5_Scaffold)
	--self.frame:SetFrameRef("showbutton", self.showbutton)
	--self.frame:SetFrameRef("closebutton", self.closebutton)

	self.raidMembers = LMP:NewChain("FontString", nil, self.frame) :SetFontObject(GameFontNormalSmall) :SetText(RAID_MEMBERS) .__EndChain

	-- role listings
	-- 	*we're treating no role (the "NONE" return value) as a damager
	self.roleCounts = setmetatable({ 
		DAMAGER = { alive = 0, dead = 0 }, 
		TANK = { alive = 0, dead = 0 }, 
		HEALER = { alive = 0, dead = 0 } 
	}, { 
		__index = function(t,k) 
			if rawget(t,k) then
				return rawget(t,k)
			else
				return rawget(t, "DAMAGER")
			end
		end 
	})

	self.roleCount = CreateFrame("Frame", nil, self.frame)

	self.roleTank = CreateFrame("Frame", nil, self.roleCount)
	self.tankIcon = LMP:NewChain(self.roleTank:CreateTexture()) :SetDrawLayer("ARTWORK", 0) .__EndChain
	self.tankLabel = LMP:NewChain("FontString", nil, self.roleTank) :SetFontObject(GameFontNormalSmall) :SetText(TANK) .__EndChain
	self.tankCount = LMP:NewChain("FontString", nil, self.roleTank) :SetFontObject(NumberFontNormal) :SetText("0") .__EndChain

	self.roleHealer = CreateFrame("Frame", nil, self.roleCount)
	self.healerIcon = LMP:NewChain(self.roleHealer:CreateTexture()) :SetDrawLayer("ARTWORK", 0) .__EndChain
	self.healerLabel = LMP:NewChain("FontString", nil, self.roleHealer) :SetFontObject(GameFontNormalSmall) :SetText(HEALER) .__EndChain
	self.healerCount = LMP:NewChain("FontString", nil, self.roleHealer) :SetFontObject(NumberFontNormal) :SetText("0") .__EndChain

	self.roleDamager = CreateFrame("Frame", nil, self.roleCount)
	self.damagerIcon = LMP:NewChain(self.roleDamager:CreateTexture()) :SetDrawLayer("ARTWORK", 0) .__EndChain
	self.damagerLabel = LMP:NewChain("FontString", nil, self.roleDamager) :SetFontObject(GameFontNormalSmall) :SetText(DAMAGER) .__EndChain
	self.damagerCount = LMP:NewChain("FontString", nil, self.roleDamager) :SetFontObject(NumberFontNormal) :SetText("0") .__EndChain

	-- raid markers
	self.raidMarkers = CreateFrame("Frame", nil, self.frame)
	local onMarkerClick = function(self)
		local unit = "target" 
		local canBeTarget = CanBeRaidTarget(unit)
		local raidTarget = GetRaidTargetIndex(unit)
		local id = self:GetID()
		if canBeTarget then
			PlaySoundKitID(856, "SFX")
			if raidTarget == id then
				SetRaidTarget(unit, 0)
			else
				SetRaidTarget(unit, id)
			end
		end
		self.module:UpdateRaidTargets()
	end
	local onMarkerEnter = function(self) self.highlight:Show() end
	local onMarkerLeave = function(self) self.highlight:Hide() end
	for i = 1,8 do
		self.raidMarkers[i] = LMP:NewChain(CreateFrame("Button", nil, self.raidMarkers)) :SetID(i) :SetScript("OnClick", onMarkerClick) :SetScript("OnEnter", onMarkerEnter) :SetScript("OnLeave", onMarkerLeave) .__EndChain
		self.raidMarkers[i].enabled = LMP:NewChain(self.raidMarkers[i]:CreateTexture()) :SetDrawLayer("ARTWORK", 0) .__EndChain
		self.raidMarkers[i].disabled = LMP:NewChain(self.raidMarkers[i]:CreateTexture()) :SetDrawLayer("ARTWORK", 1) .__EndChain
		self.raidMarkers[i].highlight = LMP:NewChain(self.raidMarkers[i]:CreateTexture()) :SetDrawLayer("ARTWORK", 2) :Hide() .__EndChain
		self.raidMarkers[i].module = self
	end

	self.worldmarkers = LMP:NewChain(_G.CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton) :SetParent(self.frame) :HookScript("OnEnter", OnButtonEnter) :HookScript("OnLeave", OnButtonLeave) .__EndChain
	self.rolecheck = makeButton(self.frame, ROLE_POLL, 32, 32, function(self) if hasLeaderTools() then InitiateRolePoll() end end)
	self.readycheck = makeButton(self.frame, READY_CHECK, 32, 32, function(self) if hasLeaderTools() then DoReadyCheck() end end)
	self.disbandgroup = makeButton(self.frame, L["Disband Group"], 32, 32, function() 
		if InCombatLockdown() then return end
		StaticPopup_Show("GUI4_GROUPFRAMES_DISBAND_GROUP") 
	end)
	self.raidcontrol = makeButton(self.frame, RAID_CONTROL, 32, 32, function() 
		if InCombatLockdown() then return end
		ToggleRaidFrame()
	end)

	self.convert = LMP:NewChain(makeButton(self.frame, IsInRaid() and CONVERT_TO_PARTY or CONVERT_TO_RAID, 32, 32, 
		function() 
			if InCombatLockdown() then return end
			if IsInRaid() then
				if GetNumGroupMembers() < 6 then
					ConvertToParty()
				end
			else
				ConvertToRaid()
			end
		end))
		:RegisterEvent("GROUP_ROSTER_UPDATE")
		:SetScript("OnEvent", function(self, event, ...) 
			if IsInRaid() and not self.inRaid then
				self.inRaid = true
				self:SetText(CONVERT_TO_PARTY)
			elseif not IsInRaid() and self.inRaid then
				self.inRaid = nil
				self:SetText(CONVERT_TO_RAID)
			end
		end)
	.__EndChain
	
	strip(self.worldmarkers)
	setBackdrop(self.worldmarkers)
	setBackdrop(self.frame)
	setBackdrop(self.showbutton)
	setBackdrop(self.closebutton)
	setBackdrop(self.rolecheck)
	setBackdrop(self.readycheck)
	setBackdrop(self.disbandgroup)
	setBackdrop(self.raidcontrol)
	setBackdrop(self.convert)
	
	self.FadeManager = LMP:NewChain(gUI4:CreateFadeManager("GroupLeaderTools")) :ApplySettings({ enablePerilFade = false }) :Enable() .__EndChain
	
	self.loaded = true
	
	if self.queueThemeUpdate then
		self:UpdateTheme()
		self:UpdatePosition()
	end
end
module.SetUp = gUI4:SafeCallWrapper(module.SetUp)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("LeaderTools", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	if IsAddOnLoaded("Blizzard_CompactRaidFrames") then
		self:SetUp()
	else
		self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end
	
end

function module:UpdateAvailableButtons(lockdown)
	if lockdown then
		self.raidcontrol:Disable()
		self.disbandgroup:Disable()
		self.convert:Disable()
	else
		if UnitIsGroupLeader("player") then
			self.raidcontrol:Enable()
			self.disbandgroup:Enable()
			self.convert:Enable()
		else
			self.raidcontrol:Enable()
			self.disbandgroup:Disable()
			self.convert:Disable()
		end
	end
end

function module:OnEvent(event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		self:ToggleLeaderTools()
		self:UpdateAvailableButtons(UnitAffectingCombat("player"))
		self:UpdateRaidTargets()
		self:UpdateCounts()
	elseif event == "GROUP_ROSTER_UPDATE" then
		self:ToggleLeaderTools()
		self:UpdateAvailableButtons(UnitAffectingCombat("player"))
		self:UpdateCounts()
	elseif event == "UNIT_FLAGS" or event == "PLAYER_FLAGS_CHANGED" then
		self:UpdateCounts()
	elseif event == "RAID_TARGET_UPDATE" then
		self:UpdateRaidTargets()
	elseif event == "PLAYER_TARGET_CHANGED" then
		self:UpdateRaidTargets()
	elseif event == "ADDON_LOADED" then
		local arg1 = ...
		if arg1 == "Blizzard_CompactRaidFrames" then
			self:SetUp()
			self:UnregisterEvent("ADDON_LOADED")
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		self:UpdateAvailableButtons(true)
	elseif event == "PLAYER_REGEN_ENABLED" then
		self:UpdateAvailableButtons(false)
	end
end

function module:OnEnable()
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:RegisterEvent("RAID_TARGET_UPDATE", "OnEvent")
	self:RegisterEvent("UNIT_FLAGS", "OnEvent")
end

function module:OnDisable()
	self:UnregisterEvent("GROUP_ROSTER_UPDATE")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("PLAYER_FLAGS_CHANGED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("RAID_TARGET_UPDATE")
	self:UnregisterEvent("UNIT_FLAGS")
end