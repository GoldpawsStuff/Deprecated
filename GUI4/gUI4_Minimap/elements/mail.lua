local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Minimap", true)
if not parent then return end

local module = parent:NewModule("Mail", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme

-- Lua API
local unpack = unpack

-- WoW API
local GetLatestThreeSenders = GetLatestThreeSenders
local HasNewMail = HasNewMail
local UnitAffectingCombat = UnitAffectingCombat

local AUCTION_OUTBID = ERR_AUCTION_OUTBID_S:gsub("%%s", "%.+")
local AUCTION_WON = ERR_AUCTION_WON_S:gsub("%%s", "%.+")

local defaults = {
	profile = {
		locked = true,
		position = {}
	}
}

local function updateConfig()
	T = parent:GetActiveTheme().widgets.mail
end

-- this is a copy of the blizz function, might expand on it later
local function UpdateMailFrame() 
	local sender1,sender2,sender3 = GetLatestThreeSenders()
	local toolText
	
	if sender1 or sender2 or sender3 then
		toolText = HAVE_MAIL_FROM
	else
		toolText = HAVE_MAIL
	end
	
	if sender1 then
		toolText = toolText.."\n"..sender1
	end
	if sender2 then
		toolText = toolText.."\n"..sender2
	end
	if sender3 then
		toolText = toolText.."\n"..sender3
	end
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:SetText(toolText)
	end
end

local function OnEnter(self)
	LMP:PlaceTip(self)
	if (not GameTooltip:IsForbidden()) then
		if GameTooltip:IsOwned(self) then
			UpdateMailFrame()
		end
	end
	-- self.icon.highlight:Show()
end

local function OnLeave(self)
	if (not GameTooltip:IsForbidden()) then
		GameTooltip:Hide()
	end
	-- self.icon.highlight:Hide()
end

function module:UpdateMail(event, ...)
	if not self.frame then return end
	if event == "CHAT_MSG_SYSTEM" then
		local msg = ...
		if (not msg) or not(msg:match(AUCTION_OUTBID) or msg:match(AUCTION_WON) or (msg == ERR_AUCTION_REMOVED)) then
			return
		end
	end
	if HasNewMail() then
		self.frame:Show() 
		if (not GameTooltip:IsForbidden()) then
			if GameTooltip:IsOwned(self.frame) then
				UpdateMailFrame()
			end
		end
	else
		self.frame:Hide()
	end
end

function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	if not self.frame then return end 
	updateConfig()
	
	-- LMP:Place(self.frame, T.place)
	LMP:NewChain(self.frame) :SetSize(unpack(T.size)) :EndChain()
	LMP:NewChain(self.frame.icon) :SetTexture(T.icon.textures.newmail:GetPath()) :SetTexCoord(T.icon.textures.newmail:GetTexCoord()) :SetSize(T.icon.textures.newmail:GetTexSize()) :ClearAllPoints() :SetPoint(unpack(T.icon.place)) :EndChain()
	LMP:NewChain(self.frame.icon.highlight) :SetTexture(T.icon.textures.newmailhighlight:GetPath()) :SetTexCoord(T.icon.textures.newmailhighlight:GetTexCoord()) :SetSize(T.icon.textures.newmailhighlight:GetTexSize()) :ClearAllPoints() :SetPoint(unpack(T.icon.place)) :EndChain()
	-- LMP:NewChain(self.frame.message) :SetFontObject(T.message.fontobject) :SetFontSize(T.message.fontsize) :SetFontStyle(T.message.fontstyle) :SetTextColor(unpack(gUI4:GetColors("chat", "offwhite"))) :SetShadowOffset(unpack(T.message.shadowoffset)) :SetShadowColor(unpack(T.message.shadowcolor)) :ClearAllPoints() :SetPoint(unpack(T.message.place)) :EndChain()
	
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings()
	if not self.frame then return end 
	updateConfig()
	self:UpdatePosition()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.frame then return end
	updateConfig()
	local db = self.db.profile
	if db.locked then
		LMP:Place(self.frame, T.place)
		if not db.position.x then
			self.frame:RegisterConfig(db.position)
			self.frame:SavePosition()
		end
	else
		self.frame:RegisterConfig(db.position)
		if db.position.x then
			self.frame:LoadPosition()
		else
			LMP:Place(self.frame, T.place)
			self.frame:SavePosition()
			self.frame:LoadPosition()
		end
	end	
end

function module:Lock()
	self.frame.overlay:StartFadeOut()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	self.frame.overlay:SetAlpha(0)
	self.frame.overlay:Show()
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not hasTheme then return end
	if not self.frame then return end
	updateConfig()
	local db = self.db.profile
	db.position.point = nil
	db.position.y = nil
	db.position.x = nil
	db.locked = true
	wipe(db.position)
	self:ApplySettings()
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Mail", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	-- self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapMailFrame", parent:GetWidgetFrame())) :SetFrameLevel(parent:GetWidgetFrame():GetFrameLevel() + 10) :EnableMouse(true) :SetScript("OnEnter", OnEnter) :SetScript("OnLeave", OnLeave) .__EndChain
	self.frame = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapMailFrame", UIParent)) :EnableMouse(true) :SetScript("OnEnter", OnEnter) :SetScript("OnLeave", OnLeave) .__EndChain
	self.frame.highlight = LMP:NewChain(CreateFrame("Frame", "GUI4_MinimapMailFrameHighlight", self.frame)) :SetFrameLevel(self.frame:GetFrameLevel()) :SetAllPoints() .__EndChain
	self.frame.icon = LMP:NewChain(self.frame:CreateTexture()) :SetDrawLayer("OVERLAY", 0) .__EndChain
	self.frame.icon.highlight = LMP:NewChain(self.frame.highlight:CreateTexture()) :SetAlpha(.75) :SetDrawLayer("OVERLAY", 1) .__EndChain
	-- self.frame.message = LMP:NewChain("FontString", nil, self.frame) :SetDrawLayer("OVERLAY", 2) :SetFontObject(GameFontNormalSmall) :SetText(L["New Mail!"]) .__EndChain
	self.frame.overlay = gUI4:GlockThis(self.frame, MAIL_LABEL, function() return self.db.profile end, unpack(gUI4:GetColors("glock", "floaters")))
	self.frame.GetSettings = function() return self.db.profile end
	self.frame.UpdatePosition = function(self) module:UpdatePosition() end
	
	gUI4:ApplyFadersToFrame(self.frame.highlight)
	self.frame.highlight:StartFlash(1.75, 1, 0, 1, false)
	
	self:RegisterMessage("GUI4_THEME_UPDATED", "UpdateTheme")
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateTheme")
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateTheme")
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateMail")
	self:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMail")
	self:RegisterEvent("MAIL_INBOX_UPDATE", "UpdateMail")
	self:RegisterEvent("CHAT_MSG_SYSTEM", "UpdateMail")
	self:RegisterEvent("MAIL_CLOSED", "UpdateMail")
	self:UpdateMail()
end

function module:OnDisable()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", "UpdateMail")
	self:UnregisterEvent("UPDATE_PENDING_MAIL", "UpdateMail")
	self:UnregisterEvent("MAIL_INBOX_UPDATE", "UpdateMail")
	self:UnregisterEvent("CHAT_MSG_SYSTEM", "UpdateMail")
	self:UnregisterEvent("MAIL_CLOSED", "UpdateMail")
end
