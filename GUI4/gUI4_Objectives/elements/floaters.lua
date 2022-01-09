local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Objectives", true)
if not parent then return end

local module = parent:NewModule("Floaters", "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme

-- Lua API
local _G = _G
local floor, min, max = math.floor, math.min, math.max
local ipairs, pairs, unpack = ipairs, pairs, unpack
local tostring = tostring

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat

local IsMappyEnabled = gUI4:IsAddOnEnabled("Mappy")

local utilFrame = CreateFrame("Frame")
local SetPoint = getmetatable(utilFrame).__index.SetPoint
local ClearAllPoints = getmetatable(utilFrame).__index.ClearAllPoints


local glocks = {}
local itemSlots = { "HeadSlot", "ShoulderSlot", "ChestSlot", "WaistSlot", "WristSlot", "HandsSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot" }
local backdrop = {
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],  
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
	edgeSize = 16,
	insets = {
		left = 2.5,
		right = 2.5,
		top = 2.5,
		bottom = 2.5
	}
}

local defaults = {
	profile = {
		-- alerts = {
			-- locked = true,
			-- position = {
			-- }
		-- },
		durability = {
			locked = true,
			alpha = .5,
			position = {}
		},
		graveyard = {
			locked = true,
			position = {}
		},
		talkinghead = {
			locked = true,
			alpha = .75,
			position = {}
		},
		vehicleseat = {
			locked = true,
			alpha = .5,
			position = {}
		}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().floaters
end

local function getDurability()
	local current, total, lowest = 0, 0, 100
	local itemCurrent, itemTotal
	for _, slot in ipairs(itemSlots) do
		itemCurrent, itemTotal = GetInventoryItemDurability(_G["Character" .. slot]:GetID())
		if itemCurrent and itemTotal then
			current = current + itemCurrent
			total = total + itemTotal
			lowest = min(lowest, itemCurrent/itemTotal * 100)
		end
	end
	if total > 0 then
		return max(0, floor(current / total * 100)), floor(lowest)
	else
		return 100, floor(lowest)
	end
end

function module:CreateHolder(name, content, width, height, displayName, ...)
	local frame = LMP:NewChain(CreateFrame("Frame", nil, self:GetFrame())) :SetSize(width, height)  .__EndChain

	-- If Mappy is enabled, we need to reset objects it's already taken control of.
	if IsMappyEnabled then
		frame.Mappy_DidHook = true -- set the flag indicating its already been set up for Mappy
		frame.Mappy_SetPoint = function() end -- kill the IsVisible reference Mappy makes
		frame.Mappy_HookedSetPoint = function() end -- kill this too
		frame.SetPoint = nil -- return the SetPoint method to its original metamethod
		frame.ClearAllPoints = nil -- return the SetPoint method to its original metamethod
	end

	frame.name = name
	frame.content = content
	frame.UpdatePosition = function() self:UpdatePosition() end
	frame.GetSettings = function() return self.db.profile[frame.name] end
	glocks[frame] = gUI4:GlockThis(frame, displayName, function() return self.db.profile[frame.name] end, unpack(gUI4:GetColors("glock", "floaters")))
	return frame, glocks[frame]
end


-- Vehicle Seat Indicator
-------------------------------------------------------------------
function module:InitializeVehicleSeat()
	local frame = self:GetFrame()
	frame.vehicleseat = self:CreateHolder("vehicleseat", VehicleSeatIndicator, 128, 128, L["Vehicle Seat"])
	VehicleSeatIndicator:SetSize(128, 128)
	hooksecurefunc(VehicleSeatIndicator, "SetPoint", function(vehicle, _, anchor) 
		if (anchor ~= self:GetFrame().vehicleseat) then
			ClearAllPoints(vehicle)
			SetPoint(vehicle, "BOTTOM", self:GetFrame().vehicleseat, "BOTTOM", 0, 0)
		end
	end)
end


-- Durability Frame
-------------------------------------------------------------------
function module:InitializeDurability()
	local frame = self:GetFrame()
	frame.durability = self:CreateHolder("durability", DurabilityFrame, 60, 64, DURABILITY)
	frame.durability.scaffold = LMP:NewChain(CreateFrame("Frame", nil, frame.durability.content)) :SetAllPoints() .__EndChain
	frame.durability.message = LMP:NewChain("FontString", nil, frame.durability.scaffold) :SetDrawLayer("OVERLAY", 2) :SetFontObject(GameFontNormal) .__EndChain
	hooksecurefunc(DurabilityFrame, "SetPoint", function(durability, _, anchor)
		if (anchor ~= self:GetFrame().durability) then
			ClearAllPoints(durability)
			SetPoint(durability, "BOTTOM", self:GetFrame().durability, "BOTTOM", 0, 0)
		end
	end)
end


-- Ghostframe (return to graveyard button)
-------------------------------------------------------------------
function module:InitializeGhostFrame()
	local frame = self:GetFrame()

	LMP:NewChain(GhostFrame) :SetScript("OnShow", nil) :SetScript("OnHide", nil) :SetScript("OnMouseUp", nil) :SetScript("OnMouseDown", nil)  :EndChain()

	LMP:Kill(GhostFrameLeft)
	LMP:Kill(GhostFrameMiddle) 
	LMP:Kill(GhostFrameRight)

	for i = 1, GhostFrame:GetNumRegions() do
		local region = select(i, GhostFrame:GetRegions())
		if region:GetObjectType() == "Texture" then
			region:SetTexture(nil)
			region.SetTexture = function() end
		elseif region:GetObjectType() == "FontString" then
			region:SetText("")
		end
		region:Hide()
		region.Show = region.Hide
	end

	frame.graveyard = self:CreateHolder("graveyard", GhostFrame, 154, 32, L["Graveyard Teleport"])
	frame.graveyard.scaffold = LMP:NewChain(CreateFrame("Frame", nil, frame.graveyard.content)) :SetAllPoints() .__EndChain
	frame.graveyard.texture = LMP:NewChain(frame.graveyard.scaffold:CreateTexture()) :SetDrawLayer("ARTWORK", 0) .__EndChain
	frame.graveyard.message = LMP:NewChain("FontString", nil, frame.graveyard.scaffold) :SetDrawLayer("OVERLAY", 2) :SetFontObject(GameFontNormalSmall) .__EndChain

	LMP:NewChain(frame.graveyard.content) :SetSize(154, 32) :ClearAllPoints() :SetPoint("TOPLEFT", frame.graveyard) :EndChain()
	LMP:NewChain(GhostFrameContentsFrameText) :SetFontObject(GameFontNormalSmall) :SetTextColor(unpack(gUI4:GetColors("chat", "offwhite"))) :ClearAllPoints() :SetPoint("CENTER") :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :EndChain()

	local width, height = math.ceil(GhostFrameContentsFrameText:GetStringWidth()), math.ceil(GhostFrameContentsFrameText:GetStringHeight())
	local frameHeight = height + 20 + 4 + 48 + 2
	local highlight = LMP:NewChain(GhostFrame:CreateTexture()) :SetTexture(.5, .7, 1, 1/10) :SetDrawLayer("OVERLAY", -1) .__EndChain

	GhostFrame:SetHighlightTexture(highlight)
	GhostFrame:GetHighlightTexture():ClearAllPoints()
	GhostFrame:GetHighlightTexture():SetPoint("TOPLEFT", GhostFrameContentsFrame, 3, -3)
	GhostFrame:GetHighlightTexture():SetPoint("BOTTOMRIGHT", GhostFrameContentsFrame, -3, 3)
	
	LMP:NewChain(GhostFrameContentsFrame) :SetBackdrop(backdrop) :SetBackdropColor(0, 0, 0, .25) :SetBackdropBorderColor(.15, .15, .15, .25) :ClearAllPoints() :SetPoint("BOTTOM") :SetSize(width + 20, height + 20) :EndChain()

	GhostFrameContentsFrame.SetPoint = function() end
	GhostFrameContentsFrameIcon:Hide()
	GhostFrameContentsFrameIcon.Show = GhostFrameContentsFrameIcon.Hide

end


-- Talking Head Frame
-------------------------------------------------------------------
function module:InitializeTalkingHead()
	local frame = self:GetFrame()

	-- We're doing this before the talking head addon is loaded
	-- in order to have the movable anchor available in /glock.
	if (not frame.talkinghead) then
		frame.talkinghead = self:CreateHolder("talkinghead", TalkingHeadFrame, 570, 155, L["Talking Head Frame"])
	end

	-- This means the addon hasn't been loaded, 
	-- so we register a listener and return.
	if (not TalkingHeadFrame) then
		return self:RegisterEvent("ADDON_LOADED", "WaitForTalkingHead")
	end

	-- Put the actual talking head into our /glock holder
	frame.talkinghead.content = TalkingHeadFrame
	TalkingHeadFrame:ClearAllPoints()
	SetPoint(TalkingHeadFrame, "BOTTOM", frame.talkinghead, "BOTTOM", 0, 0)
	TalkingHeadFrame.ignoreFramePositionManager = true

	-- Kill off Blizzard's repositioning
	UIParent:UnregisterEvent("TALKINGHEAD_REQUESTED")
	UIPARENT_MANAGED_FRAME_POSITIONS["TalkingHeadFrame"] = nil

	-- Iterate through all alert subsystems in order to find the one created for TalkingHeadFrame, and then remove it.
	-- We do this to prevent alerts from anchoring to this frame when it is shown.
	for index, alertFrameSubSystem in ipairs(AlertFrame.alertFrameSubSystems) do
		if alertFrameSubSystem.anchorFrame and alertFrameSubSystem.anchorFrame == TalkingHeadFrame then
			table.remove(AlertFrame.alertFrameSubSystems, index)
		end
	end

	-- Debugging
	--TalkingHeadFrame:HookScript("OnShow", function() print("showing talking head") end)
	--TalkingHeadFrame:HookScript("OnHide", function() print("hiding talking head") end)
end

function module:WaitForTalkingHead(event, addon)
	if (addon ~= "Blizzard_TalkingHeadUI") then
		return
	end
	self:InitializeTalkingHead()
	self:UnregisterEvent("ADDON_LOADED")
end


function module:Lock()
	for frame, overlay in pairs(glocks) do
		overlay:StartFadeOut()
	end
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	for frame, overlay in pairs(glocks) do
		overlay:SetAlpha(0)
		overlay:Show()
	end
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not hasTheme then return end
	updateConfig()
	for frame in pairs(glocks) do
		local db = self.db.profile[frame.name]
		db.position.point = nil
		db.position.y = nil
		db.position.x = nil
		db.locked = true
		wipe(db.position)
	end
	self:ApplySettings()
end

function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	if not frame then return end 
	updateConfig()
	self:ApplySettings()
end
module.UpdateTheme = gUI4:SafeCallWrapper(module.UpdateTheme)

function module:ApplySettings()
	if (not hasTheme) then return end 
	for frame, overlay in pairs(glocks) do
		local settings = self.db.profile[frame.name]
		if frame.content then
			if settings.alpha then
				frame.content:SetAlpha(settings.alpha)
			else
				frame.content:SetAlpha(1)
			end
		end
	end
	updateConfig()
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	updateConfig()
	for frame in pairs(glocks) do
		local settings = self.db.profile[frame.name]
		if settings.locked then
			LMP:Place(frame, T[frame.name].place)
			if (not settings.position.x) then
				frame:RegisterConfig(settings.position)
				frame:SavePosition()
			end
		else
			frame:RegisterConfig(settings.position)
			if settings.position.x then
				frame:LoadPosition()
			else
				frame:ClearAllPoints()
				LMP:Place(frame, T[frame.name].place)
				frame:SavePosition()
				frame:LoadPosition()
			end
		end	
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Floaters", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")

	if IsMappyEnabled then
		if Mappy then
			self:InitializeMappy()
		else
			self:RegisterEvent("ADDON_LOADED", "CheckForMappy")
		end
	end
end

function module:CheckForMappy(event, ...)
	local addon = ...
	if (addon == "Mappy") then
		self:UnregisterEvent("ADDON_LOADED", "CheckForMappy")
		self:InitializeMappy()
	end
end

function module:InitializeMappy()
	for i=#Mappy.MinimapAttachedFrames,1,-1 do
		local v = Mappy.MinimapAttachedFrames[i]
		if (v == "VehicleSeatIndicator") or (v == "DurabilityFrame") then
			table.remove(Mappy.MinimapAttachedFrames, i)
		end
	end
	self:UpdatePosition()
end


function module:GetFrame()
	if (not self.frame) then
		local frame = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
		frame:SetAllPoints()
		RegisterStateDriver(frame, "visibility", "[petbattle] hide; show")

		self.frame = frame
	end
	return self.frame
end

function module:OnEnable()
	self:InitializeVehicleSeat()
	self:InitializeDurability()
	self:InitializeGhostFrame()
	self:InitializeTalkingHead()

	hasTheme = true

	self:ApplySettings()
end
