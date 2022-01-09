local addon, gUI4 = ...

-- Lua API
local _G = _G

-- WoW API
local CreateFrame = _G.CreateFrame
local GameFontNormal = _G.GameFontNormal
local GameFontNormalLarge = _G.GameFontNormalLarge
local GameTooltip = _G.GameTooltip
local RegisterStateDriver = _G.RegisterStateDriver
local UnitAffectingCombat = _G.UnitAffectingCombat
local UIParent = _G.UIParent

local LMP = _G.GP_LibStub("GP_LibMediaPlus-1.0")
local LibWin = _G.GP_LibStub("GP_LibWindow-1.1")
local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

_G.BINDING_NAME_GUI4_CORE_TOGGLELOCK = L["Toggle movable frames"]

local lockTexture = [[Interface\Glues\CharacterSelect\Glues-AddOn-Icons]]
local lockedCoords = { 0/64, 15/64, 0/16, 16/16 }
local unlockedChords = { 16/64, 31/64, 0/16, 16/16 }
local lockedString = "|TInterface\\Glues\\CharacterSelect\\Glues-AddOn-Icons:16:16:0:2:64:16:0:15:0:16|t"
local unlockedString = "|TInterface\\Glues\\CharacterSelect\\Glues-AddOn-Icons:16:16:0:2:64:16:16:31:0:16|t"
local middleButtonString = "|TInterface\\TutorialFrame\\UI-TUTORIAL-FRAME:25:19:0:0:512:512:1:76:118:218|t"
local leftButtonString = "|TInterface\\TutorialFrame\\UI-TUTORIAL-FRAME:25:19:0:0:512:512:1:76:218:318|t"
local rightButtonString = "|TInterface\\TutorialFrame\\UI-TUTORIAL-FRAME:25:19:0:0:512:512:1:76:321:421|t"
local dragArrowString = "|TInterface\\TutorialFrame\\UI-TUTORIAL-FRAME:20:16:0:0:512:512:157:222:265:185|t"

local glockBackdrop = {
	edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeSize = 1, tile = true, tileSize = 16
}

local glockAlpha, numGlocks = .85, 0
local glocks = {} -- overlay registry

-- some frames are smaller than their display names, 
-- so we'll align the name according to screen section
local function updateNamePlacement(self)
	local width, stringwidth = self:GetWidth(), self.text:GetStringWidth()
	if width - 8 < stringwidth then
		local pwidth = UIParent:GetSize()
		local left = self:GetLeft() 
		if left < pwidth * 1/3 then
			self.text:ClearAllPoints()
			self.text:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 4, 4)
			self.text:SetJustifyH("LEFT")
		else
			self.text:ClearAllPoints()
			self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4)
			self.text:SetJustifyH("RIGHT")
		end
	end
end

local function onDragStart(overlay)
	if overlay:GetSettings() and overlay:GetSettings().locked then return end
	if UnitAffectingCombat("player") then return end
	overlay.frame:StartMoving()
	updateNamePlacement(overlay)
end
local function onDragStop(overlay)
	if overlay:GetSettings() and overlay:GetSettings().locked then return end
	overlay.frame:StopMovingOrSizing()
	overlay.frame:SavePosition()
	updateNamePlacement(overlay)
end
local function onEnter(button)
	if  GameTooltip:IsForbidden() then
		return
	end
	LMP:PlaceTip(button)
	if button:GetParent():GetSettings().locked then
		GameTooltip:AddLine(lockedString .. button.title, 1, 1, 1)
		GameTooltip:AddLine(L["The frame is currently set to automatic positioning, |nwhich means its placement will be handled by the UI."], 1, .82, 0)
		GameTooltip:AddLine(L["<Left-Click to enable free movement>"], 1, 0, 0)
	else
		GameTooltip:AddLine(unlockedString .. button.title, 1, 1, 1)
		GameTooltip:AddLine(L["Frame is currently set to free movement, |nwhich means you are free to place it wherever you wish."], 1, .82, 0)
		GameTooltip:AddLine(L["<Left-Click to enable automatic placement>"], 0, 1, 0)
	end
	GameTooltip:Show()
end
local function onClick(button)
	button:GetParent():GetSettings().locked = not button:GetParent():GetSettings().locked
	button:SetChecked(button:GetParent():GetSettings().locked)
	if button.frame.UpdatePosition then
		button.frame:UpdatePosition()
	end
	if (not GameTooltip:IsForbidden()) then
		if GameTooltip:IsShown() and GameTooltip:GetOwner() == button then
			onEnter(button)
		end
	end
end
local function onLeave()
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
end
local function onShow(overlay)
	if not overlay:GetSettings() then 
		overlay.Button:Hide()
		return 
	else 
		overlay.Button:SetChecked(overlay:GetSettings().locked)
		overlay.Button:Show()
	end
	overlay:SetFrameLevel(overlay.frameLevel)
	overlay.Button:SetFrameLevel(overlay.frameLevel + 1)
	updateNamePlacement(overlay)
end
local function onClickOverlay(overlay, button)
	for _, glock in pairs(glocks) do
		local r, g, b = glock:GetBackdropColor()
		if glock == overlay then
			if button == "LeftButton" then
				glock:SetBackdropColor(r, g, b, 1)
				glock:SetFrameLevel(126)
				glock.Button:SetFrameLevel(127)
			elseif button == "RightButton" then
				glock:SetBackdropColor(r, g, b, glockAlpha)
				glock:SetFrameLevel(0)
				glock.Button:SetFrameLevel(1)
      elseif button == "MiddleButton" then
        glock:Hide()
			end
		else
			glock:SetBackdropColor(r, g, b, glockAlpha)
			glock:SetFrameLevel(glock.frameLevel)
			glock.Button:SetFrameLevel(glock.frameLevel + 1)
		end
	end
end

function gUI4:GlockThis(object, title, settingsFunc, r, g, b)
	object:SetMovable(true)
	if not r or not g or not b then
		r, g, b = .35, .75, .15
	end
	local name
	if object:GetName() and object:GetName() ~= "" then
		name = object:GetName() .. "Overlay"
	end 
	local overlay = LMP:NewChain(CreateFrame("Button", nil, self:GetSafeFrame())) :Hide() :SetAlpha(0) :SetMovable(true) :EnableMouse(true) :SetAllPoints(object) :RegisterForDrag("LeftButton") :RegisterForClicks("LeftButtonUp") :SetBackdrop(glockBackdrop) :SetBackdropBorderColor(r*.3, g*.3, b*.3, 1) :SetBackdropColor(r, g, b, glockAlpha) :SetScript("OnClick", onClickOverlay) :RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp") :SetScript("OnDragStart", onDragStart) :SetScript("OnDragStop", onDragStop) :SetScript("OnShow", onShow) .__EndChain
	local normalTexture = LMP:NewChain(overlay:CreateTexture(nil, "ARTWORK")) :SetSize(16, 16) :SetPoint("TOPLEFT", 2, -2) :SetTexture(lockTexture) :SetTexCoord(unpack(unlockedChords)) .__EndChain
	local checkedTexture = LMP:NewChain(overlay:CreateTexture(nil, "ARTWORK")) :SetSize(16, 16) :SetPoint("TOPLEFT", 2, -2) :SetTexture(lockTexture) :SetTexCoord(unpack(lockedCoords)) .__EndChain
	local button = LMP:NewChain(CreateFrame("CheckButton", nil, overlay)) :SetHitRectInsets(-4, -4, -4, -4) :SetPoint("TOPLEFT", 2, -2) :SetSize(16, 16) :EnableMouse(true) :SetNormalTexture(normalTexture) :SetCheckedTexture(checkedTexture) :SetScript("OnEnter", onEnter) :SetScript("OnLeave", onLeave) :SetScript("OnClick", onClick) :RegisterForClicks("LeftButtonUp") .__EndChain
	local text = LMP:NewChain("FontString", nil, overlay) :SetDrawLayer("OVERLAY") :SetFontObject(GameFontNormal) :SetFontStyle(nil) :SetFontSize(10) :SetTextColor(unpack(gUI4:GetColors("chat", "highlight"))) :SetShadowColor(0, 0, 0, 1) :SetShadowOffset(1.25, -1.25) :SetText(title) :SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -4, 4) .__EndChain

	numGlocks = numGlocks + 1

	local nextGlock = numGlocks*2
	if nextGlock + 1 >= 126 then
		numGlocks = 0
	end
	
	overlay.GetSettings = settingsFunc or function() end
	overlay.frameLevel = nextGlock
	overlay.title = title
	overlay.frame = object
	overlay.text = text
	overlay.Button = button
	overlay.Button.frame = object
	overlay.Button.title = title
	
	gUI4:ApplyFadersToFrame(overlay)
	overlay:SetFadeOut(.10)
	overlay:HookScript("OnShow", function(self) 
		local w = self:GetSize()
		if w < 60 then
			self:SetHitRectInsets(-16, -16, -8, -8)
		else
			self:SetHitRectInsets(0, 0, 0, 0)
		end
		self:StartFadeIn(.25, 1) 
	end)
	
	overlay:HookScript("OnEnter", function(self)
		if GameTooltip:IsForbidden() then
			return
		end
		LMP:PlaceTip(self)
		if self:GetSettings().locked then
			GameTooltip:AddLine(lockedString .. self.Button.title, 1, 1, 1)
			GameTooltip:AddLine(L["The frame is currently set to automatic positioning, |nwhich means its placement will be handled by the UI."], 1, .82, 0)
			GameTooltip:AddLine(L["<Left-Click to move it to the front.>"], 0, .7, 0)
			GameTooltip:AddLine(L["<Right-Click to move it to the back.>"], 0, .7, 0)
			GameTooltip:AddLine(L["<Middle-Click to hide the anchor.>"], 0, .7, 0)
			GameTooltip:AddLine(L["<Left-Click %s to enable free movement>"]:format(lockedString), 1, 0, 0)
		else
			GameTooltip:AddLine(unlockedString .. self.Button.title, 1, 1, 1)
			GameTooltip:AddLine(L["Frame is currently set to free movement, |nwhich means you are free to place it wherever you wish."], 1, .82, 0)
			GameTooltip:AddLine(L["<Left-Click to move it to the front.>"], 0, .7, 0)
			GameTooltip:AddLine(L["<Right-Click to move it to the back.>"], 0, .7, 0)
			GameTooltip:AddLine(L["<Middle-Click to hide the anchor.>"], 0, .7, 0)
			GameTooltip:AddLine(L["<Left-Click %s to enable automatic placement>"]:format(unlockedString), 0, 1, 0)
		end
		GameTooltip:Show()
	end)

	overlay:HookScript("OnLeave", function(self)
		if (not GameTooltip:IsForbidden()) then
			if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
				GameTooltip:Hide()
			end
		end
	end)
	
	if not object.RegisterConfig then
		function object:RegisterConfig(settings)
			LibWin.RegisterConfig(self, settings)
		end
	end
	if not object.LoadPosition then
		function object:LoadPosition()
			LibWin.RestorePosition(self)
		end
	end
	if not object.SavePosition then
		function object:SavePosition()
			LibWin.SavePosition(self)
		end
	end

	glocks[object] = overlay

	return overlay
end

function gUI4:UpdateLockOverlays()
	for _, overlay in pairs(glocks) do
		onShow(overlay)
	end
end

function gUI4:Unlock()
	if UnitAffectingCombat("player") then return end
	if self.locked then
		-- self:FullScreenFadeOut()
		self:GetFrameLockDescriptionOverlay():SetAlpha(0)
		self:GetFrameLockDescriptionOverlay():Show()
		self:GetFrameLockDescriptionOverlay():StartFadeIn(.35, 1)
		self.locked = false
		self:ForAll("Unlock")
	end
end

function gUI4:Lock()
	if not self.locked then
		-- self:FullScreenFadeIn()
		self:GetFrameLockDescriptionOverlay():StartFadeOut()
		self.locked = true
		self:ForAll("Lock")
	end
end

function gUI4:IsLocked()
	return self.locked
end

function gUI4:ResetLock()
	if UnitAffectingCombat("player") then return end
	-- self:Lock() -- lock all frames before attempting this
	self:ForAll("ResetLock")
	self:UpdateLockOverlays()
end

function gUI4:LockAndResetLock()
	if UnitAffectingCombat("player") then return end
	self:Lock() -- lock all frames before attempting this
	-- self:ForAll("ResetLock")
	self:ResetLock()
end

function gUI4:ToggleLock(arg)
	if arg == "reset" then
		return self:LockAndResetLock()
	else
		if self:IsLocked() then
			self:Unlock()
		else
			self:Lock()
		end
	end
end

do
	local frame
	function gUI4:GetSafeFrame()
		if not frame then
			frame = LMP:NewChain(CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")) :SetFrameStrata("HIGH") :SetFrameLevel(0) .__EndChain
			RegisterStateDriver(frame, "visibility", "[petbattle]hide;[combat]hide;show")
			frame:SetScript("OnHide", function(self) -- prevent overlays from popping back in on combat end
				for _, overlay in pairs(glocks) do
					overlay:Hide()
					overlay:SetAlpha(0)
				end
			end)
		end
		return frame
	end
end

do
	local frame
	function gUI4:GetFrameLockDescriptionOverlay()
		if not frame then -- :SetBackdrop(glockBackdrop) :SetBackdropColor(0, 0, 0, .5) :SetBackdropBorderColor(0, 0, 0, 1)
			frame = LMP:NewChain(CreateFrame("Frame", nil, UIParent)) :SetFrameStrata("HIGH") :SetFrameLevel(128) :SetAlpha(0) :Hide() :SetPoint("TOP", 0, -40) .__EndChain
			frame.backdrop = LMP:NewChain(CreateFrame("Frame", nil, frame)) :SetFrameStrata("HIGH") :SetFrameLevel(0) :SetAllPoints(UIParent) .__EndChain
			frame.backdrop.texture = LMP:NewChain(frame.backdrop:CreateTexture()) :SetAllPoints() :SetTexture(0, 0, 0, .5) .__EndChain
			frame.lines = {
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormalLarge) :SetFontSize(18) :SetFontStyle() :SetShadowColor(0, 0, 0, 1) :SetShadowOffset(1.25, -1.25) :SetTextColor(unpack(gUI4:GetColors("chat", "highlight"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 1) :SetShadowOffset(1.25, -1.25) :SetTextColor(unpack(gUI4:GetColors("chat", "green"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 1) :SetShadowOffset(1.25, -1.25) :SetTextColor(unpack(gUI4:GetColors("chat", "green"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 1) :SetShadowOffset(1.25, -1.25) :SetTextColor(unpack(gUI4:GetColors("chat", "green"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 1) :SetShadowOffset(1.25, -1.25) :SetTextColor(unpack(gUI4:GetColors("chat", "green"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 1) :SetShadowOffset(1.25, -1.25) :SetTextColor(unpack(gUI4:GetColors("chat", "green"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 0) :SetShadowOffset(0, 0) :SetTextColor(unpack(gUI4:GetColors("chat", "highlight"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 0) :SetShadowOffset(0, 0) :SetTextColor(unpack(gUI4:GetColors("chat", "highlight"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 0) :SetShadowOffset(0, 0) :SetTextColor(unpack(gUI4:GetColors("chat", "highlight"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 0) :SetShadowOffset(0, 0) :SetTextColor(unpack(gUI4:GetColors("chat", "highlight"))) .__EndChain,
				LMP:NewChain("FontString", nil, frame) :SetIndentedWordWrap(false) :SetFontObject(GameFontNormal) :SetFontSize(12) :SetFontStyle() :SetShadowColor(0, 0, 0, 0) :SetShadowOffset(0, 0) :SetTextColor(unpack(gUI4:GetColors("chat", "highlight"))) .__EndChain,
			}
			LMP:NewChain(frame.lines[1]) :SetAlpha(1) :SetPoint("TOPLEFT", 0, 0) :EndChain()
			LMP:NewChain(frame.lines[2]) :SetAlpha(1) :SetPoint("TOPLEFT", frame.lines[1], "BOTTOMLEFT", 0, -16) :SetJustifyH("LEFT") :EndChain()
			LMP:NewChain(frame.lines[3]) :SetAlpha(1) :SetPoint("TOPLEFT", frame.lines[2], "BOTTOMLEFT", 0, -16) :SetJustifyH("LEFT") :EndChain()
			LMP:NewChain(frame.lines[4]) :SetAlpha(1) :SetPoint("TOPLEFT", frame.lines[3], "BOTTOMLEFT", 0, -16) :SetJustifyH("LEFT") :EndChain()
			LMP:NewChain(frame.lines[5]) :SetAlpha(1) :SetPoint("TOPLEFT", frame.lines[4], "BOTTOMLEFT", 0, -16) :SetJustifyH("LEFT") :EndChain()
			LMP:NewChain(frame.lines[6]) :SetAlpha(1) :SetPoint("TOPLEFT", frame.lines[5], "BOTTOMLEFT", 0, -16) :SetJustifyH("LEFT") :EndChain()
			LMP:NewChain(frame.lines[7]) :SetAlpha(1) :SetPoint("RIGHT", frame.lines[2], "LEFT", -10, 0) :SetJustifyH("RIGHT") :EndChain()
			LMP:NewChain(frame.lines[8]) :SetAlpha(1) :SetPoint("RIGHT", frame.lines[3], "LEFT", -10, 0) :SetJustifyH("RIGHT") :EndChain()
			LMP:NewChain(frame.lines[9]) :SetAlpha(1) :SetPoint("RIGHT", frame.lines[4], "LEFT", -10, 0) :SetJustifyH("RIGHT") :EndChain()
			LMP:NewChain(frame.lines[10]) :SetAlpha(1) :SetPoint("RIGHT", frame.lines[5], "LEFT", -10, 0) :SetJustifyH("RIGHT") :EndChain()
			LMP:NewChain(frame.lines[11]) :SetAlpha(1) :SetPoint("RIGHT", frame.lines[6], "LEFT", -10, 0) :SetJustifyH("RIGHT") :EndChain()
			
			frame.lines[1]:SetText(L["/glock"])
			frame.lines[2]:SetText(L["Toggle between automatic placement and free movement by clicking|nthe padlock icons in the upper right corners of the frame overlays."])
			frame.lines[3]:SetText(L["Hold down the left mouse button and drag the overlay|nto your preferred position when in free movement mode."])
			frame.lines[4]:SetText(L["Left-Click an overlay to move it to the front of the other overlays."])
			frame.lines[5]:SetText(L["Right-Click an overlay to move it to the back of the other frames."])
			frame.lines[6]:SetText(L["Middle-Click an overlay to completely hide it."])
			frame.lines[7]:SetFormattedText("%s / %s", lockedString, unlockedString)
			frame.lines[8]:SetFormattedText("%s + %s", leftButtonString, dragArrowString)
			frame.lines[9]:SetFormattedText("%s", leftButtonString)
			frame.lines[10]:SetFormattedText("%s", rightButtonString)
			frame.lines[11]:SetFormattedText("%s", middleButtonString)
			
			local width, height = 0, 0
			for i = 1, 5 do
				width = math.max(width, frame.lines[i]:GetStringWidth() + 20)
				height = height + frame.lines[i]:GetStringHeight() + 20
			end
			local width2 = 0
			for i = 6, 9 do
				width2 = math.max(width2, frame.lines[i]:GetStringWidth() + 20)
			end

			frame:SetSize(width + 10 + width2 + 40, height + 40)
			frame.lines[1]:ClearAllPoints()
			frame.lines[1]:SetPoint("TOPLEFT", width2 + 10 + 20, -20) 

			gUI4:ApplyFadersToFrame(frame)
			frame:SetFadeOut(.10)
		end
		return frame
	end
end

gUI4:AddEvent("PLAYER_REGEN_DISABLED", "Lock")
gUI4:AddChatCommand("glock", "ToggleLock")
gUI4:AddChatCommand("glockreset", "LockAndResetLock")
gUI4:AddChatCommand("resetlock", "LockAndResetLock")
if gUI4.AddStartupMessage then 
	gUI4:AddStartupMessage(L["/glock to toggle movable frames."])
	-- gUI4:AddStartupMessage(L["/glockreset to reset movable frames."])
end


