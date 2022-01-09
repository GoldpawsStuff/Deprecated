local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_ActionBars", true)
if not parent then return end

local module = parent:NewModule("ExtraActionBar", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat

local ButtonBar = parent.ButtonBar
local ExtraButton = parent.ExtraButton
local ExtraActionBar = setmetatable({}, { __index = ButtonBar })
parent.ExtraActionBar = ExtraActionBar

local defaults = {
	profile = {
		enabled = true,
		locked = true,
		barWidth = 1,
		buttons = 1,
		skin = "Warcraft",
		skinSize = "large",
		growthX = "RIGHT",
		growthY = "DOWN",
		showMacrotext = false,
		showHotkey = true,
		showEquipped = true,
		showGrid = false,
		flyoutDir = "UP",
		position = {},
		alpha = 1,
		fadeIn = true,
		fadeInDuration = .25,
		fadeOut = false,
		fadeOutDelay = 1,
		fadeOutDuration = 1.5,
		fadeOutAlpha = 0, -- 0.1
		visibility = {
		}
	}
}

local T, hasTheme
local function updateConfig()
	T = parent:GetActiveTheme()
end

function ExtraActionBar:UpdateLayout()
	local bar = self.child
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", 0, 0)
	ButtonBar.UpdateLayout(self)
end

function ExtraActionBar:OnEvent(event, arg1)

end

function module:Lock()
	self.bar.overlay:StartFadeOut()
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	self.bar.overlay:SetAlpha(0)
	self.bar.overlay:Show()
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	if not self.bar then return end
	updateConfig() 
	self.db.profile.position.point = nil
	self.db.profile.position.y = nil
	self.db.profile.position.x = nil
	self.db.profile.locked = true
	wipe(self.db.profile.position)
	self:ApplySettings()
end

function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(parent) then return end
	updateConfig()
	hasTheme = true
	self:ApplySettings()
end

function module:ApplySettings(settings)
	if not self.bar then return end
	updateConfig() 
	self.bar:ApplySettings(self.db.profile)
	self.bar:UpdateLayout()
	-- self.bar:UpdateButtonSettings()
	self.bar:ForAll("Update")
	self:UpdatePosition() 
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:UpdatePosition()
	if not hasTheme then return end
	if not self.bar or InCombatLockdown() then return end
	updateConfig() 
	if self.db.profile.locked then
		self.bar:ClearAllPoints()
		self.bar:SetPoint(T.place("Extra", self.db.profile.skinSize))
		if not self.db.profile.position.x then
			self.bar:RegisterConfig(self.db.profile.position)
			self.bar:SavePosition()
		end
	else
		self.bar:RegisterConfig(self.db.profile.position)
		if self.db.profile.position.x then
			self.bar:LoadPosition()
		else
			self.bar:ClearAllPoints()
			self.bar:SetPoint(T.place("Extra", self.db.profile.skinSize))
			self.bar:SavePosition()
			self.bar:LoadPosition()
		end
	end
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:GrabBinds()
	if InCombatLockdown() or not self.actionbars then return end
	ClearOverrideBindings(self.bar)
	for i,button in self.bar:GetAll() do
		local action = self.bar.bindingTable[self.bar.id][i]
		for k = 1, select("#", GetBindingKey(action)) do
		local key = select(k, GetBindingKey(action))
			if key and key ~= "" then
				SetOverrideBindingClick(self.bar, false, key, button:GetName())
			end				
		end
	end
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("ExtraActionBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	
	self.fadeManager = parent:GetFadeManager()
end

function module:OnEnable()
	if not self.bar then

		self.bar = setmetatable(ButtonBar:New("Extra", L["ExtraActionButton"], function() return self.db.profile end), { __index = ExtraActionBar })
		-- self.fadeManager:RegisterObject(self.bar)
		self.bar.overlay = gUI4:GlockThis(self.bar, L["ExtraActionButton"], function() return self.db.profile end, unpack(gUI4:GetColors("glock", "actionbars")))
		self.bar.UpdatePosition = function(self) module:UpdatePosition() end
		self.bar.GetSettings = function() return self.db.profile end
		
		tinsert(parent.bars, self.bar)
		
		self.bar.child = ExtraActionBarFrame
		self.bar.child.ignoreFramePositionManager = true -- stop blizzard from moving it around
		self.bar.child:SetParent(self.bar)

		local buttons = { setmetatable( ExtraActionButton1, { __index = ExtraButton } ) }

		self.bar.buttons = buttons
		self.bar:SetScript("OnEvent", ExtraActionBar.OnEvent)
	end

	self.bar:Enable()
	
	self:RegisterMessage("GUI4_ACTIVE_THEME_CHANGED", "UpdateTheme")
	self:RegisterEvent("UPDATE_BINDINGS", "GrabBinds")
	self:ApplySettings() 
	self:GrabBinds()
	self:UpdateTheme()

end

