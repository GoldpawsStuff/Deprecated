local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Minimap", true)
if not parent then return end

local module = parent:NewModule("ButtonBag", "GP_AceEvent-3.0")

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local MBF, MBB

-- Lua API
local _G = _G
local floor = math.floor
local pairs, ipairs, select = pairs, ipairs, select

-- WoW API

local buttons, points, hidden = {}, {}, {}

local defaults = {
	profile = {
	}
}

-- elements we don't remove
local known = {
	BookOfTracksFrame = true,
	CartographerNotesPOI = true,
	DA_Minimap = true,
	FishingExtravaganzaMini = true,
	FWGMinimapPOI = true,
	GameTimeFrame = true,
	GatherArchNote = true,
	GatherMatePin = true,
	GatherNote = true,
	GuildInstanceDifficulty = true,
	HandyNotesPin = true,
	MBB_MinimapButtonFrame = true,
	MinimapButtonFrame = true,
	MiniMapBattlefieldFrame = true,
	MinimapBackdrop = true,
	MiniMapInstanceDifficulty = true,
	MiniMapMailFrame = true,
	MiniMapMeetingStoneFrame = true,
	MiniMapPing = true,
	MiniMapRecordingButton = true,
	MiniMapTracking = true,
	MiniMapTrackingFrame = true,
	MiniMapVoiceChatFrame = true,
	MiniMapWorldMapButton = true,
	MinimapZoneTextButton = true,
	MinimapZoomIn = true,
	MinimapZoomOut = true,
	MiniNotePOI = true,
	poiMinimap = true,
	QueueStatusMinimapButton = true,
	QuestPointerPOI = true,	
	RecipeRadarMinimapIcon = true,
	TDial_TrackButton = true,
	TDial_TrackingIcon = true,
	TimeManagerClockButton = true,
	ZGVMarker = true,
	-- LibDBIcon10_BugSack = true
}

-- elements that are removed, but kept "visible" in terms of :IsShown() for compability with binds and stuff
local invisible = {
	GarrisonLandingPageMinimapButton = true
}

local shown = {
	FishingExtravaganzaMini = true,
	QueueStatusMinimapButton = true,
	QuestPointerPOI = true,	
	RecipeRadarMinimapIcon = true,
	TDial_TrackButton = true,
	TDial_TrackingIcon = true,
	ZGVMarker = true, -- "ZGVMarker"..nummarkers.."Mini"
}

-- buttons to completely hide when listed addon is loaded
local addons = {
	-- gUI4_SmartBar = {
		-- LibDBIcon10_BugSack, -- BugSack
		-- TRP2_MinimapButton, -- totalRP2
		-- ZygorGuidesViewerMapIcon -- ZygorGuidesViewer
	-- }
}

local numButtons = 0
local cache = {}
local function add(button)
	numButtons = numButtons + 1
	cache[button] = { parent = button:GetParent(), point = { button:GetPoint() } }
	buttons[button] = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapButtonBagButtonFrame"..(numButtons), module.frame.bag)) :SetSize(24, 24) .__EndChain
	LMP:NewChain(button) :SetParent(buttons[button]) :ClearAllPoints() :SetPoint("TOPLEFT", 0, 0) :SetPoint("BOTTOMRIGHT", 0, 0) :EndChain()
end

local function remove(button)
	if not cache[button] then return end
	LMP:NewChain(button) :SetParent(cache[button].parent) :ClearAllPoints() :SetPoint(unpack(cache[button].point)) :EndChain()
	cache[button] = nil
end

local onUpdate = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= 3  then
		local children = self.owner:GetNumChildren()
		if self.children ~= children then
			local child
			for i = 1, children do
				child = select(i, self.owner:GetChildren())
				if child and not(buttons[child]) and child:HasScript("OnClick") and (child.GetName and child:GetName()) then 
					local ignore
					local childName = child:GetName()
					-- for name in pairs(invisible) do
						-- if childName:find(name) then
							-- ignore = true
							-- break
						-- end
					-- end
					for name in pairs(known) do
						if childName:find(name) then
							ignore = true
							break
						end
					end
					if not ignore then
						add(child)
					end
					local show
					for name in pairs(shown) do
						if childName:find(name) then
							show = true
							break
						end
					end
					if show then
						child:SetParent(parent:GetMinimapFrame())
						child:SetFrameLevel(parent:GetMinimapFrame():GetFrameLevel() + 10)
						-- if child.waypoint and child:GetName():find("Zygor") then
							-- points[child] = true
						-- end
					end
				end
			end
			self.children = children
		end
		
		self.elapsed = 0 
	end
end

function module:RestoreButtons()
	for button, scaffold in pairs(buttons) do
		restore(button)
	end
	wipe(buttons)
end

function module:MBB()
	local frame = MBB_MinimapButtonFrame
	if not frame then return end
	
	local m = gUI4:GetMedia("Texture", "WhitePlusRounded", 32, 32, "Warcraft")
	if not m then 
		print("|cffffffffGoldpaw's Minimap:|r |cffff0000Texture file missing for MBB functionality! Please download the most recent version of Goldpaw's UI(core)!|r")
		return 
	end
	
	local icon = MBB_MinimapButtonFrame_Texture

	frame:RegisterForDrag()
	frame:SetSize(m:GetSize()) 
	frame:SetParent(self.frame)
	frame:ClearAllPoints()
	frame.ClearAllPoints = function() end
	frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
	frame.SetPoint = function() end
	frame:SetHighlightTexture("") 
	frame:DisableDrawLayer("OVERLAY") 

	icon:ClearAllPoints()
	icon:SetPoint(m:GetPoint())
	icon:SetSize(m:GetTexSize())
	icon:SetTexture(m:GetPath())
	icon:SetTexCoord(m:GetTexCoord())
	icon:SetAlpha(.5)
	
	local down, over
	local function setalpha()
		if down and over then
			icon:SetAlpha(1)
		elseif down or over then
			icon:SetAlpha(.95)
		else
			icon:SetAlpha(.85)
		end
	end
	frame:SetScript("OnMouseDown", function(self) 
		down = true
		setalpha()
	end)
	frame:SetScript("OnMouseUp", function(self) 
		down = false
		setalpha()
	end)
	frame:SetScript("OnEnter", function(self) 
		over = true
		MBB_ShowTimeout = -1
		if (not GameTooltip:IsForbidden()) then
			LMP:PlaceTip(self)
			GameTooltip:AddLine("MinimapButtonBag v" .. MBB_Version)
			GameTooltip:AddLine(MBB_TOOLTIP1, 0, 1, 0)
			GameTooltip:Show()
		end
		setalpha()
	end)
	frame:SetScript("OnLeave", function(self) 
		over = false
		MBB_ShowTimeout = 0
		if (not GameTooltip:IsForbidden()) then
			GameTooltip:Hide()
		end
		setalpha()
	end)
	
end

function module:PLAYER_ENTERING_WORLD()
	self.frame:SetScript("OnUpdate", onUpdate)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

local checked, found = 0, 0
function module:ADDON_LOADED(event, addon)
	if addons[addon] then
		local more
		for _,button in ipairs(addons[addon]) do
			if not hidden[button] then
				hidden[button] = true
				more = true
			end
		end
		if more then
			found = found + 1
		end
		if found == checked then
			self:UnregisterEvent("ADDON_LOADED")
		end
	end
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("ButtonBag", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self.frame = CreateFrame("Frame", "GUI4_MinimapButtonBagParent", parent:GetWidgetFrame())
	self.frame.hider = CreateFrame("Frame", "GUI4_MinimapButtonBagHider", self.frame)
	self.frame.hider:Hide() -- use an extra hide layer, 
	self.frame.bag = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapButtonBagFrame", self.frame.hider)) :SetFrameStrata("HIGH") :SetPoint("TOPRIGHT", UIParent, -20, -20) .__EndChain
	-- self.frame.bag:Hide()
	self.frame.owner = _G.Minimap -- this is where the buttonbag will look for buttons
	self.frame.elapsed = 0
	self.frame.children = 0
	
	MBB = IsAddOnLoaded("MBB") 
	MBF = IsAddOnLoaded("MinimapButtonFrame")
	
	-- ugly hack to keep the keybind functioning
	if GarrisonLandingPageMinimapButton then
		GarrisonLandingPageMinimapButton:Show()
		GarrisonLandingPageMinimapButton.Hide = GarrisonLandingPageMinimapButton.Show
	end

	if not(MBF or MBB) then
		for name, t in pairs(addons) do
			checked = checked + 1
			if gUI4:IsAddOnEnabled(name) then
				for _,button in ipairs(t) do
					hidden[button] = true
				end
				found = found + 1
			end
		end
		if found < checked then 
			self:RegisterEvent("ADDON_LOADED")
		end
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
	else
		if not MBF then
			if MBB then
				self:MBB()
			end
		end
	end
	
end

function module:OnEnable()
end

function module:OnDisable()
end
