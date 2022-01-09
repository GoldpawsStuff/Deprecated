local addon = ...

local GP_LibStub = _G.GP_LibStub

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule(addon, true)
if not parent then return end

local module = parent:NewModule("Clicks", "GP_AceEvent-3.0")
local Zygor = gUI4:IsAddOnEnabled("ZygorGuidesViewer")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- Lua API
local _G = _G
local print = print
local select, unpack = select, unpack
local tsort, tinsert = table.sort, table.insert
local tonumber = tonumber
local type, pairs, ipairs = type, pairs, ipairs
local min, max, sqrt = math.min, math.max, math.sqrt

-- WoW API
local Minimap = _G.Minimap
local CreateFrame = _G.CreateFrame
local GetBuildInfo = _G.GetBuildInfo
local GetCursorPosition =  _G.GetCursorPosition
local GuildFrame_LoadUI = _G.GuildFrame_LoadUI
local IsAddOnLoaded = _G.IsAddOnLoaded
local IsInGuild = _G.IsInGuild
local IsTrialAccount = _G.IsTrialAccount
local LoadAddOn = _G.LoadAddOn
local PVEFrame_ToggleFrame = _G.PVEFrame_ToggleFrame
local ShowUIPanel = _G.ShowUIPanel
local ToggleAchievementFrame = _G.ToggleAchievementFrame
-- local ToggleBackpack = _G.ToggleBackpack -- don't upvalue this, other addons prehook it!
local ToggleCharacter = _G.ToggleCharacter
local ToggleCollectionsJournal = _G.ToggleCollectionsJournal
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local ToggleFrame = _G.ToggleFrame
local ToggleFriendsFrame = _G.ToggleFriendsFrame
local ToggleHelpFrame = _G.ToggleHelpFrame
local TogglePetJournal = _G.TogglePetJournal
local TogglePVPUI = _G.TogglePVPUI
local ToggleQuestLog = _G.ToggleQuestLog
local UnitClass = _G.UnitClass
local UnitFactionGroup = _G.UnitFactionGroup
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName
local SpellBookFrame = _G.SpellBookFrame
local WorldMapFrame = _G.WorldMapFrame

local list = {}
local restrictions = {}
local build = tonumber((select(2, GetBuildInfo())))

local defaults = {
	profile = {
		autoZoom = 30, -- seconds before minimap fully zooms out
		useMiddleClickMenu = true, -- our good old middle-click dropdown menu
	}
}

-- starter editions on a 10-day MoP trial will return 'nil' at startup, 
-- but true once logged into the game. 
local function restricted()
	return IsTrialAccount and IsTrialAccount()
end

local function preUpdateList()
	local level = UnitLevel("player")
	for text, req in pairs(restrictions) do
		for _, entry in ipairs(list) do
			if text == entry.text then
				if type(req) == "number" then
					entry.disabled = level < req
				elseif type(req) == "function" then
					entry.disabled = req()
				else
					entry.disabled = req
				end
			end
		end
	end
end

local function addItem(msg, func)
	tinsert(list, {
		text = msg, 
		notCheckable = true,
		func = func
	})
end

local function addItemRestriction(msg, func)
	if not msg or not func then return end
	restrictions[msg] = func
end

local function OnClick(self)
	local x, y = GetCursorPosition()
	x = x / self:GetEffectiveScale()
	y = y / self:GetEffectiveScale()
	local cx, cy = self:GetCenter()
	x = x - cx
	y = y - cy
	if sqrt(x * x + y * y) < (self:GetWidth() / 2) then
		Minimap:PingLocation(x, y)
	end
end

local function OnMouseUp(self, button)
	if button == "RightButton" then
		ToggleDropDownMenu(1, nil,  _G.MiniMapTrackingDropDown, self)
		
	elseif button == "MiddleButton" then
		if module.db.profile.useMiddleClickMenu then
			if  _G.DropDownList1:IsShown() then
				 _G.DropDownList1:Hide()
			else
				preUpdateList()
				 _G.EasyMenu(list, parent:GetWidget("middleclickmenu"), "cursor", 0, 0, "MENU", 2)
			end
		end
	else
		OnClick(self)
	end
end

local function OnMouseWheel(self, delta)
	if delta > 0 then
		self:SetZoom(min(self:GetZoomLevels(), self:GetZoom() + 1))
	elseif delta < 0 then
		self:SetZoom(max(0, self:GetZoom() - 1))
	end
	if module.db.profile.autoZoom and (module.db.profile.autoZoom > 0) and not(Zygor) then -- don't interfere with Zygor's own zoom handling
		-- self:GetWidget("zoom"):Stop()
		-- self:GetWidget("zoomAnim"):SetDuration(module.db.profile.autoZoom)
		-- self:GetWidget("zoom"):Play()
	end
end

local function OnFinished() 
	for _ = 1, 5 do 
		parent:GetMinimapFrame():SetZoom(max(0, parent:GetMinimapFrame():GetZoom() - 1)) 
	end 
end

function module:AssignClicks()
	LMP:NewChain(parent:GetMinimap()) :EnableMouseWheel(true) :SetScript("OnMouseWheel", OnMouseWheel) :SetScript("OnMouseUp", OnMouseUp) :EndChain()
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("MiddleClickMenu", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self.frame = parent:RegisterWidget("middleclickmenu", LMP:NewChain(CreateFrame("Frame", "GUI4MinimapMiddleClickMenu", parent:GetWidgetFrame(), "UIDropDownMenuTemplate")) .__EndChain)
	self.frame.zoom = parent:RegisterWidget("zoom", LMP:NewChain(parent:GetMinimapFrame():CreateAnimationGroup()) :SetScript("OnFinished", OnFinished) .__EndChain)
	self.frame.zoomAnim = parent:RegisterWidget("zoomAnim", LMP:NewChain(parent:GetWidget("zoom"):CreateAnimation()) :SetOrder(1) :SetDuration(1) .__EndChain)
	
	self:AssignClicks()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "AssignClicks")
	self:RegisterEvent("PET_BATTLE_CLOSE", "AssignClicks") 
  
  self.ping = CreateFrame("ScrollingMessageFrame", nil, parent:GetMinimapFrame())
  self.ping:SetHeight(10)
  self.ping:SetWidth(100)
  self.ping:SetPoint("BOTTOM", 0, 24)

  self.ping:SetFontObject(_G.GameFontNormalSmall)
  self.ping:SetJustifyH("CENTER")
  self.ping:SetJustifyV("CENTER")
  self.ping:SetMaxLines(1)
  self.ping:SetFading(true)
  self.ping:SetFadeDuration(3)
  self.ping:SetTimeVisible(5)
  self.ping.playerName = UnitName("player")
  self.ping.colors = gUI4:GetColors()

  self.ping:RegisterEvent("MINIMAP_PING")
  self.ping:SetScript("OnEvent", function(self, _, unit)
    local color = self.colors.class[select(2, UnitClass(unit))]
    local name = UnitName(unit)
    if name ~= self.playerName then
      self:AddMessage(name, unpack(color))
    end
  end)

	addItem(_G.ACHIEVEMENT_BUTTON, function() ToggleAchievementFrame() end)
	addItem(_G.ADVENTURE_JOURNAL, function() if not IsAddOnLoaded("Blizzard_EncounterJournal") then _G.EncounterJournal_LoadUI() end _G.ToggleEncounterJournal() end)
	addItem(_G.BACKPACK_TOOLTIP, _G.ToggleBackpack)
	addItem(_G.BLIZZARD_STORE, function() _G.StoreMicroButton:Click() end)
	addItem(L["Calendar"], function() if not _G.CalendarFrame then LoadAddOn("Blizzard_Calendar") end _G.Calendar_Toggle() end) 
	addItem(_G.CHARACTER_BUTTON, function() ToggleCharacter("PaperDollFrame") end)
	-- addItem(DUNGEONS_BUTTON, function() PVEFrame_ToggleFrame("GroupFinderFrame", LFDParentFrame) end)
	-- addItem(FLEX_RAID, function() PVEFrame_ToggleFrame("GroupFinderFrame", FlexRaidFrame) end)
	addItem(_G.GUILD, function() 
    if IsInGuild() then 
      if not _G.GuildFrame then 
        GuildFrame_LoadUI() 
      end 
      _G.GuildFrame_Toggle() 
    else 
      if not _G.LookingForGuildFrame then 
        _G.LookingForGuildFrame_LoadUI() 
      end 
      _G.ToggleGuildFinder() 
    end 
  end)
	addItem(_G.HELP_BUTTON, function() ToggleHelpFrame() end)
	if build < 19678 then
		addItem(_G.MOUNTS_AND_PETS, function() TogglePetJournal() end)
	else -- 6.1
		addItem(_G.MOUNTS, function() ToggleCollectionsJournal(1) end)
		addItem(_G.PETS, function() ToggleCollectionsJournal(2) end)
		addItem(_G.TOY_BOX, function() ToggleCollectionsJournal(3) end)
		addItem(_G.HEIRLOOMS, function() ToggleCollectionsJournal(4) end)
	end
	-- addItem(_G.RAID_FINDER, function() PVEFrame_ToggleFrame("GroupFinderFrame", _G.RaidFinderFrame) end)
	-- addItem(_G.SCENARIOS_PVEFRAME, function() PVEFrame_ToggleFrame("GroupFinderFrame", _G.ScenarioFinderFrame) end)
	addItem(_G.COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATEPVE, function() PVEFrame_ToggleFrame() end)
	addItem(_G.GARRISON_LANDING_PAGE_TITLE, function() 
		if _G.GarrisonLandingPageMinimapButton then
			_G.GarrisonLandingPageMinimapButton:GetScript("OnClick")(_G.GarrisonLandingPageMinimapButton, "LeftButton")
		end
	end)
	addItem(_G.SOCIAL_BUTTON, function() ToggleFriendsFrame() end) -- 1
	addItem(_G.SPELLBOOK_ABILITIES_BUTTON, function() ToggleFrame(SpellBookFrame) end)
	addItem(_G.TALENTS_BUTTON, function() if not _G.PlayerTalentFrame then _G.TalentFrame_LoadUI() end ShowUIPanel(_G.PlayerTalentFrame) end)
	addItem(_G.COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATEPVP, function() TogglePVPUI() end)
	if build < 19678 then
		addItem(_G.QUESTLOG_BUTTON, function() ToggleQuestLog() end)
	else -- 6.1
		addItem(_G.WORLD_MAP.." / ".._G.QUESTLOG_BUTTON, function() ShowUIPanel(WorldMapFrame) end)
	end

	if build >= 19678 then  -- 6.1
		addItem(_G.SOCIAL_TWITTER_COMPOSE_NEW_TWEET, function()
			if not _G.SocialPostFrame then
				LoadAddOn("Blizzard_SocialUI")
			end
			local IsTwitterEnabled = _G.C_Social.IsSocialEnabled()
			if IsTwitterEnabled then
				_G.Social_SetShown(true)
			else
				print(_G.SOCIAL_TWITTER_TWEET_NOT_LINKED)
			end
		end)
	end

	addItemRestriction(_G.ENCOUNTER_JOURNAL, _G.SHOW_LFD_LEVEL)
	addItemRestriction(_G.GARRISON_LANDING_PAGE_TITLE, function() return not _G.GarrisonLandingPageMinimapButton end)
	addItemRestriction(_G.MOUNTS_AND_PETS, _G.SHOW_SPEC_LEVEL)
	addItemRestriction(_G.COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATEPVE, _G.SHOW_LFD_LEVEL)
	addItemRestriction(_G.TALENTS_BUTTON, _G.SHOW_SPEC_LEVEL)
	addItemRestriction(_G.GUILD, function() 
		if restricted() then return true end
		local factionGroup = UnitFactionGroup("player") 
		if factionGroup and factionGroup == "Neutral" then
			return true
		end
	end)
	addItemRestriction(_G.SOCIAL_BUTTON, function() return restricted() end)

	addItemRestriction(_G.COMPACT_UNIT_FRAME_PROFILE_AUTOACTIVATEPVP, function()
		if UnitLevel("player") < _G.SHOW_PVP_LEVEL then return true end
		local factionGroup = UnitFactionGroup("player")
		if factionGroup and factionGroup == "Neutral" then
			return true
		end
	end)

	tsort(list, function(a,b) return a.text < b.text end)

end

function module:OnEnable()
end

function module:OnDisable()
end
