local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local module = gUI4:NewModule(addon, "GP_AceEvent-3.0")
module:SetDefaultModuleState(false)

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T, hasTheme

-- Lua API
local _G = _G
local tostring = tostring
local pairs = pairs

-- WoW API
local UnitAffectingCombat = UnitAffectingCombat

local defaults = {
	profile = {
		skin = "Warcraft"
	}
}

local function updateConfig()
	T = module:GetActiveTheme()
end

function module:UpdateTheme(event, name, addonName)
	if addonName ~= tostring(self) then return end
	if not self.frame then return end 
	updateConfig()
	-- if self.db.profile.locked then
		-- LMP:Place(frame, T.place)
	-- end
	
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
	updateConfig()
end
module.UpdatePosition = gUI4:SafeCallWrapper(module.UpdatePosition)

function module:Lock()
	for name, mod in self:IterateModules() do
		if mod:IsEnabled() and mod.Lock then
			mod:Lock()
		end
	end
end

function module:Unlock()
	if UnitAffectingCombat("player") then return end
	for name, mod in self:IterateModules() do
		if mod:IsEnabled() and mod.Unlock then
			mod:Unlock()
		end
	end
end

function module:ResetLock()
	if UnitAffectingCombat("player") then return end
	for name, mod in self:IterateModules() do
		if mod:IsEnabled() and mod.ResetLock then
			mod:ResetLock()
		end
	end
end

local hidden = LMP:NewChain(CreateFrame("Frame")) :Hide() .__EndChain

local handled = {}
local function handle(object)
	if not(object) or handled[object] then return end
	local parent = object:GetParent()
	object:SetScript("OnEvent", nil)
	object:SetScript("OnUpdate", nil)
	object:SetParent(hidden)
	object:UnregisterAllEvents()
	handled[object] = parent
end

function module:DisableCastingBarFrame()
	handle(CastingBarFrame)
	handle(PetCastingBarFrame)
end

function module:DisableMirrorTimers()
	for i = 1, MIRRORTIMER_NUMTIMERS or 1 do
		local timer = _G["MirrorTimer"..i]
		handle(timer)
	end
end

function module:DisableTimers()
	if TimerTracker then
		TimerTracker:SetScript("OnEvent", nil)
		TimerTracker:SetScript("OnUpdate", nil)
		TimerTracker:UnregisterAllEvents()
		if TimerTracker.timerList then
			for _, bar in pairs(TimerTracker.timerList) do
				handle(bar)
			end
		end
	end
end

function module:EnableAllBars()
	for object, parent in pairs(handled) do
		object:SetParent(parent)
	end
	wipe(handled)
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Visibility", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["CastBars & Timers"],
			args = {
				header1 = {
					type = "header",
					width = "full",
					order = 1,
					name = L["CastBars"]
				},
				description1 = {
					type = "description",
					width = "full",
					order = 2,
					name = L["Toggle the visibility of the on-screen floating castbars."]
				},
				player = {
					type = "toggle",
					width = "full",
					order = 10,
					name = L["Enable the Player castbar"],
					desc = L["Displays the your own castbar when you're casting a spell."],
					get = function() 
						local CastBars = self:GetModule("CastBars")
						return CastBars.db.profile.bars.player.enabled
					end,
					set = function(info, value)
						local CastBars = self:GetModule("CastBars")
						CastBars.db.profile.bars.player.enabled = value
						CastBars:ApplySettings()
					end
				},
				target = {
					type = "toggle",
					width = "full",
					order = 20,
					name = L["Enable the Target castbar"],
					desc = L["Displays the target's castbar when the target is casting a spell."],
					get = function() 
						local CastBars = self:GetModule("CastBars")
						return CastBars.db.profile.bars.target.enabled
					end,
					set = function(info, value)
						local CastBars = self:GetModule("CastBars")
						CastBars.db.profile.bars.target.enabled = value
						CastBars:ApplySettings()
					end
				},
				focus = {
					type = "toggle",
					width = "full",
					order = 30,
					name = L["Enable the Focus Target castbar"],
					desc = L["Displays the focus target's castbar when the focus target is casting a spell."],
					get = function() 
						local CastBars = self:GetModule("CastBars")
						return CastBars.db.profile.bars.focus.enabled
					end,
					set = function(info, value)
						local CastBars = self:GetModule("CastBars")
						CastBars.db.profile.bars.focus.enabled = value
						CastBars:ApplySettings()
					end
				},
			}
		}
	})

end

function module:OnInitialize()
	self.db = GP_LibStub("GP_AceDB-3.0"):New("gUI4_CastBars_DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	if gUI4.DEBUG then
		self.db:ResetDB("Default")
		self.db:ResetProfile()
	end	
	updateConfig()
	self:DisableCastingBarFrame()
	self:DisableMirrorTimers()
	self:DisableTimers()
	-- self:RegisterEvent("START_TIMER", "DisableTimers")
end

function module:OnEnable()
	for name, mod in self:IterateModules() do
		mod:Enable()
	end
	self:SetActiveTheme(self.db.profile.skin) 
end

function module:OnDisable()
	-- EnableAllBars()
end
