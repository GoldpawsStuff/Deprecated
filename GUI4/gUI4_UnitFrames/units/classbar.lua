local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local oUF = gUI4.oUF
if not oUF then return end

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

local parent = gUI4:GetModule("gUI4_UnitFrames")
if not parent then return end

local module = parent:NewModule("ClassBar", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

-- Lua API
local select = select

-- WoW API
local GetEclipseDirection = GetEclipseDirection
local GetSpellInfo = GetSpellInfo
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local ECLIPSE_MARKER_COORDS = ECLIPSE_MARKER_COORDS

local playerClass = select(2, UnitClass("player"))

local defaults = {
	profile = {
		locked = true,
		ignoreBlizzard = true,
		position = {}
	}
}

local function create(parent, name)
	local pill = CreateFrame("Frame", name, parent)
	-- standard texture layer
	pill.texture = pill:CreateTexture(name and "$parentTexture" or nil)
	pill.texture:SetAllPoints()

	-- texture layer proxy methods
	pill.SetTexture = function(self, ...) return self.texture:SetTexture(...) end
	pill.SetTexCoord = function(self, ...) return self.texture:SetTexCoord(...) end
	pill.SetVertexColor = function(self, ...) return self.texture:SetVertexColor(...) end
	pill.SetDrawLayer = function(self, ...) return self.texture:SetDrawLayer(...) end

	-- spell overlay
	pill.model = CreateFrame("Model", name and "$parentSpellModel" or nil, pill)
	pill.model:SetAllPoints()
	
	-- spell overlay proxy methods
	pill.ShowModel = function(self, ...) return self.model:Show() end
	pill.HideModel = function(self, ...) return self.model:Hide() end
	pill.SetLight = function(self, ...) return self.model:SetLight(...) end
	pill.SetModel = function(self, ...) return self.model:SetModel(...) end
	pill.SetModelAlpha = function(self, ...) return self.model:SetAlpha(...) end
	pill.SetModelSize = function(self, ...) return self.model:SetSize(...) end
	pill.SetModelScale = function(self, ...) return self.model:SetModelScale(...) end
	pill.SetPosition = function(self, ...) return self.model:SetPosition(...) end
	pill.SetModelPoint = function(self, ...) 
		self.model:ClearAllPoints() 
		return self.model:SetPoint(...) 
	end
	
	return pill
end

local function scaffolding(self, unit)
	self:EnableMouse(false) -- this module is for display purposes only. don't want mouse functionality to mess with hovering and such.
	
	self.PlayerClassBar = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetAllPoints() .__EndChain
	
	-- druid and rogue combo points 
	self.ComboPointsWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
	self.ComboPointsWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.ComboPointsWidget)) :SetFrameLevel(self.ComboPointsWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
	self.ComboPointsWidget.backdrop = LMP:NewChain(self.ComboPointsWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
	self.ComboPointsWidget.overlay = LMP:NewChain(self.ComboPointsWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
	for i = 1, 5 do
		self.ComboPointsWidget[i] = LMP:NewChain(create(self.ComboPointsWidget)) :SetDrawLayer("BORDER", 0) :SetVertexColor(unpack(gUI4:GetColors("power", "COMBO_POINTS")[i])) .__EndChain
		self.ComboPointsWidget[i].gloss = LMP:NewChain(self.ComboPointsWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
		local shine = gUI4:ApplyShine(self.ComboPointsWidget[i])
		-- hooksecurefunc(self.ComboPointsWidget[i], "Show", function(self)
		self.ComboPointsWidget[i]:HookScript("OnShow", function(self) 
			shine:Start()
		end)
	end
	local shine = gUI4:ApplyShine(self.ComboPointsWidget)
	self.ComboPointsWidget:HookScript("OnShow", function(self) 
		shine:Start()
	end)
		
	-- runes
	if playerClass == "DEATHKNIGHT" then
		self.RuneWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
		self.RuneWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.RuneWidget)) :SetFrameLevel(self.RuneWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
		self.RuneWidget.backdrop = LMP:NewChain(self.RuneWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
		self.RuneWidget.overlay = LMP:NewChain(self.RuneWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
		for i = 1, 6 do
			self.RuneWidget[i] = LMP:NewChain("StatusBar", nil, self.RuneWidget) .__EndChain
			self.RuneWidget[i].value = LMP:NewChain("FontString", nil, self.RuneWidget[i]) :SetFontObject(GameFontNormal) .__EndChain
			self.RuneWidget[i].gloss = LMP:NewChain(self.RuneWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
			self.RuneWidget[i].bg = LMP:NewChain(self.RuneWidget[i]:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) :SetAllPoints() .__EndChain
			self.RuneWidget[i].bg.multiplier = 1/3
			local shine = gUI4:ApplyShine(self.RuneWidget[i])
			self.RuneWidget[i].Shine = shine
			-- self.RuneWidget[i]:HookScript("OnShow", function(self) 
				-- shine:Start()
			-- end)
			gUI4:ApplySmoothing(self.RuneWidget[i])
		end
	end
	
	-- totem timers
	if playerClass == "SHAMAN" then
		self.TotemWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
		self.TotemWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.TotemWidget)) :SetFrameLevel(self.TotemWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
		self.TotemWidget.backdrop = LMP:NewChain(self.TotemWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
		self.TotemWidget.overlay = LMP:NewChain(self.TotemWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
		for i = 1, MAX_TOTEMS do
			self.TotemWidget[i] = LMP:NewChain("StatusBar", nil, self.TotemWidget) .__EndChain
			self.TotemWidget[i].value = LMP:NewChain("FontString", nil, self.TotemWidget.overlayFrame) :SetFontObject(GameFontNormal) .__EndChain
			self.TotemWidget[i].gloss = LMP:NewChain(self.TotemWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
			self.TotemWidget[i].bg = LMP:NewChain(self.TotemWidget[i]:CreateTexture()) :SetDrawLayer("BACKGROUND", 0) :SetAllPoints() .__EndChain
			self.TotemWidget[i].bg.multiplier = 1/3
			self.TotemWidget[i].spark = LMP:NewChain(self.TotemWidget[i]:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
			-- self.TotemWidget[i]:EnableMouse(true) -- will enable tooltips, but give less clickable screen space
			local shine = gUI4:ApplyShine(self.TotemWidget[i])
			hooksecurefunc(self.TotemWidget[i], "Show", function(self)
			-- self.TotemWidget[i]:HookScript("OnShow", function(self) 
				shine:Start()
			end)
			gUI4:ApplySmoothing(self.TotemWidget[i])
		end
		local shine = gUI4:ApplyShine(self.TotemWidget)
		self.TotemWidget:HookScript("OnShow", function(self) 
			shine:Start()
		end)
	end
	
	-- eclipse bar
	if playerClass == "DRUID" then
		if not LEGION then -- bugs out in Legion
			self.EclipseWidget = LMP:NewChain(CreateFrame("Frame", nil, self.PlayerClassBar)) :SetSize(1,1) .__EndChain
			self.EclipseWidget.LunarBar = LMP:NewChain("StatusBar", nil, self.EclipseWidget) :SetSize(1,1) :SetPoint("LEFT") .__EndChain
			self.EclipseWidget.SolarBar = LMP:NewChain("StatusBar", nil, self.EclipseWidget) :SetGrowth("LEFT") :SetSize(1,1) :SetPoint("RIGHT") .__EndChain
			self.EclipseWidget.OverlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.EclipseWidget.SolarBar)) :SetAllPoints(self.EclipseWidget.LunarBar) .__EndChain
			
			self.EclipseWidget.SolarBar.overlay = LMP:NewChain(self.EclipseWidget.OverlayFrame:CreateTexture()) :SetDrawLayer("ARTWORK", -2) :SetAllPoints() .__EndChain
			self.EclipseWidget.SolarBar.Spark = LMP:NewChain(self.EclipseWidget.SolarBar:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain

			self.EclipseWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.EclipseWidget)) :SetFrameLevel(self.EclipseWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
			self.EclipseWidget.backdrop = LMP:NewChain(self.EclipseWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
			self.EclipseWidget.overlay = LMP:NewChain(self.EclipseWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain

			gUI4:ApplySmoothing(self.EclipseWidget.LunarBar)
			gUI4:ApplySmoothing(self.EclipseWidget.SolarBar)

			-- local wrath = GetSpellInfo(5176)
			-- local starfire = GetSpellInfo(2912)
			
			self.EclipseWidget.Value = LMP:NewChain("FontString", nil, self.EclipseWidget.overlayFrame) :SetFontObject(GameFontNormal) .__EndChain
			self.EclipseWidget.Guide = LMP:NewChain("FontString", nil, self.EclipseWidget.overlayFrame) :SetFontObject(GameFontNormal) .__EndChain
			-- self.EclipseWidget.PostUpdatePower = function(self, unit, power, maxpower)
				-- self.Value:SetFormattedText("%d%%", abs(power))
				-- self.Value:SetFormattedText("%d - %d", power, maxpower)
				-- if self.directionIsLunar then
					-- self.Value:SetText(wrath)
				-- elseif self.direction == "sun" then
					-- self.Value:SetText(starfire)
				-- else
					-- self.Value:SetText("")
				-- end
			-- end	
		end
	end
	
	-- arcane charges
	if playerClass == "MAGE" then
		self.ArcaneChargesWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
		self.ArcaneChargesWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.ArcaneChargesWidget)) :SetFrameLevel(self.ArcaneChargesWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
		self.ArcaneChargesWidget.backdrop = LMP:NewChain(self.ArcaneChargesWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
		self.ArcaneChargesWidget.overlay = LMP:NewChain(self.ArcaneChargesWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
		self.ArcaneChargesWidget.timer = LMP:NewChain("StatusBar", nil, self.ArcaneChargesWidget.overlayFrame) :SetStatusBarColor(unpack(gUI4:GetColors("power", "ARCANE_CHARGE"))) .__EndChain
		self.ArcaneChargesWidget.value = LMP:NewChain("FontString", nil, self.ArcaneChargesWidget.timer) :SetFontObject(GameFontNormal) .__EndChain
		self.ArcaneChargesWidget.timer.value = self.ArcaneChargesWidget.value
		for i = 1, 4 do
			self.ArcaneChargesWidget[i] = LMP:NewChain(create(self.ArcaneChargesWidget)) :SetDrawLayer("BORDER", 0) :SetVertexColor(unpack(gUI4:GetColors("power", "ARCANE_CHARGE"))) .__EndChain
			self.ArcaneChargesWidget[i].gloss = LMP:NewChain(self.ArcaneChargesWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
			local shine = gUI4:ApplyShine(self.ArcaneChargesWidget[i])
			-- hooksecurefunc(self.ArcaneChargesWidget[i], "Show", function(self)
			self.ArcaneChargesWidget[i]:HookScript("OnShow", function(self) 
				shine:Start()
			end)
		end	
		local shine = gUI4:ApplyShine(self.ArcaneChargesWidget)
		self.ArcaneChargesWidget:HookScript("OnShow", function(self) 
			shine:Start()
		end)
	end
	
	-- chi
	if playerClass == "MONK" then
		self.ChiWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
		self.ChiWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.ChiWidget)) :SetFrameLevel(self.ChiWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
		self.ChiWidget.backdrop = LMP:NewChain(self.ChiWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
		self.ChiWidget.overlay = LMP:NewChain(self.ChiWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
		for i = 1, 6 do -- they can have 6 now
			self.ChiWidget[i] = LMP:NewChain(create(self.ChiWidget)) :SetDrawLayer("BORDER", 0) :SetVertexColor(unpack(gUI4:GetColors("power", "CHI_BAR")[min(i, 5)])) .__EndChain
			self.ChiWidget[i].gloss = LMP:NewChain(self.ChiWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
			local shine = gUI4:ApplyShine(self.ChiWidget[i])
			-- hooksecurefunc(self.ChiWidget[i], "Show", function(self)
			self.ChiWidget[i]:HookScript("OnShow", function(self) 
				shine:Start()
			end)
		end	
		local shine = gUI4:ApplyShine(self.ChiWidget)
		self.ChiWidget:HookScript("OnShow", function(self) 
			shine:Start()
		end)
	end
	
	-- holy power
	if playerClass == "PALADIN" then
		self.HolyPowerWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
		self.HolyPowerWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.HolyPowerWidget)) :SetFrameLevel(self.HolyPowerWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
		self.HolyPowerWidget.backdrop = LMP:NewChain(self.HolyPowerWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
		self.HolyPowerWidget.overlay = LMP:NewChain(self.HolyPowerWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
		for i = 1, 5 do
			self.HolyPowerWidget[i] = LMP:NewChain(create(self.HolyPowerWidget)) :SetDrawLayer("BORDER", 0) :SetVertexColor(unpack(gUI4:GetColors("power", "HOLY_POWER"))) .__EndChain
			self.HolyPowerWidget[i].gloss = LMP:NewChain(self.HolyPowerWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
			local shine = gUI4:ApplyShine(self.HolyPowerWidget[i])
			-- hooksecurefunc(self.HolyPowerWidget[i], "Show", function(self)
			self.HolyPowerWidget[i]:HookScript("OnShow", function(self) 
				shine:Start()
			end)
		end	
		local shine = gUI4:ApplyShine(self.HolyPowerWidget)
		self.HolyPowerWidget:HookScript("OnShow", function(self) 
			shine:Start()
		end)
	end
	
	-- shadow orbs
	if playerClass == "PRIEST" then
		if not LEGION then
			self.ShadowOrbsWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
			self.ShadowOrbsWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.ShadowOrbsWidget)) :SetFrameLevel(self.ShadowOrbsWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
			self.ShadowOrbsWidget.backdrop = LMP:NewChain(self.ShadowOrbsWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
			self.ShadowOrbsWidget.overlay = LMP:NewChain(self.ShadowOrbsWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
			for i = 1, 5 do 
				self.ShadowOrbsWidget[i] = LMP:NewChain(create(self.ShadowOrbsWidget)) :SetDrawLayer("BORDER", 0) :SetVertexColor(unpack(gUI4:GetColors("power", "SOUL_SHARDS"))) .__EndChain
				self.ShadowOrbsWidget[i].gloss = LMP:NewChain(self.ShadowOrbsWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
				local shine = gUI4:ApplyShine(self.ShadowOrbsWidget[i])
				-- hooksecurefunc(self.ShadowOrbsWidget[i], "Show", function(self)
				self.ShadowOrbsWidget[i]:HookScript("OnShow", function(self) 
					shine:Start()
				end)
			end
			local shine = gUI4:ApplyShine(self.ShadowOrbsWidget)
			self.ShadowOrbsWidget:HookScript("OnShow", function(self) 
				shine:Start()
			end)
		end
	end
	
	-- anticipation
	if playerClass == "ROGUE" then
		self.ComboPointsWidget.Anticipation = {}
		for i = 6, 10 do
			self.ComboPointsWidget[i] = LMP:NewChain(self.ComboPointsWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 2) :SetVertexColor(unpack(gUI4:GetColors("power", "COMBO_POINTS")[i])) .__EndChain
		end
	end
	
	-- burning embers, soul shards, demonic fury
	if playerClass == "WARLOCK" then
		if not LEGION then
			self.BurningEmbersWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
			self.BurningEmbersWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.BurningEmbersWidget)) :SetFrameLevel(self.BurningEmbersWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
			self.BurningEmbersWidget.backdrop = LMP:NewChain(self.BurningEmbersWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
			self.BurningEmbersWidget.overlay = LMP:NewChain(self.BurningEmbersWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
			for i = 1, 4 do
				self.BurningEmbersWidget[i] = LMP:NewChain("StatusBar", nil, self.BurningEmbersWidget) :SetStatusBarColor(unpack(gUI4:GetColors("power", "BURNING_EMBERS"))) .__EndChain
				self.BurningEmbersWidget[i].gloss = LMP:NewChain(self.BurningEmbersWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
				self.BurningEmbersWidget[i].value = LMP:NewChain("FontString", nil, self.BurningEmbersWidget[i]) :SetFontObject(GameFontNormal) .__EndChain
				local shine = gUI4:ApplyShine(self.BurningEmbersWidget[i])
				self.BurningEmbersWidget[i].Shine = shine
				-- self.BurningEmbersWidget[i]:HookScript("OnShow", function(self) 
					-- shine:Start()
				-- end)
				gUI4:ApplySmoothing(self.BurningEmbersWidget[i])
			end

			self.DemonicFuryWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
			self.DemonicFuryWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.DemonicFuryWidget)) :SetFrameLevel(self.DemonicFuryWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
			self.DemonicFuryWidget.bar = LMP:NewChain("StatusBar", nil, self.DemonicFuryWidget) .__EndChain
			self.DemonicFuryWidget.bar.value = LMP:NewChain("FontString", nil, self.DemonicFuryWidget.bar) :SetFontObject(GameFontNormal) .__EndChain
			self.DemonicFuryWidget.bar.overlay = LMP:NewChain(self.DemonicFuryWidget.bar:CreateTexture()) :SetDrawLayer("ARTWORK", -2) :SetAllPoints() .__EndChain
			self.DemonicFuryWidget.bar.spark = LMP:NewChain(self.DemonicFuryWidget.bar:CreateTexture()) :SetDrawLayer("BORDER", 2) .__EndChain
			self.DemonicFuryWidget.backdrop = LMP:NewChain(self.DemonicFuryWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
			self.DemonicFuryWidget.overlay = LMP:NewChain(self.DemonicFuryWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
			gUI4:ApplySmoothing(self.DemonicFuryWidget.bar)
		end
	
		self.SoulShardsWidget = CreateFrame("Frame", nil, self.PlayerClassBar)
		self.SoulShardsWidget.overlayFrame = LMP:NewChain(CreateFrame("Frame", nil, self.SoulShardsWidget)) :SetFrameLevel(self.SoulShardsWidget:GetFrameLevel() + 3) :SetAllPoints() .__EndChain
		self.SoulShardsWidget.backdrop = LMP:NewChain(self.SoulShardsWidget:CreateTexture()) :SetDrawLayer("BORDER", -1) .__EndChain
		self.SoulShardsWidget.overlay = LMP:NewChain(self.SoulShardsWidget.overlayFrame:CreateTexture()) :SetDrawLayer("BORDER", 1) .__EndChain
		for i = 1, LEGION and 5 or 4 do
			self.SoulShardsWidget[i] = LMP:NewChain(create(self.SoulShardsWidget)) :SetDrawLayer("BORDER", 0) :SetVertexColor(unpack(gUI4:GetColors("power", "SOUL_SHARDS"))) .__EndChain
			self.SoulShardsWidget[i].gloss = LMP:NewChain(self.SoulShardsWidget[i]:CreateTexture()) :SetDrawLayer("OVERLAY", -1) :SetAllPoints() .__EndChain
			local shine = gUI4:ApplyShine(self.SoulShardsWidget[i])
			-- hooksecurefunc(self.SoulShardsWidget[i], "Show", function(self)
			self.SoulShardsWidget[i]:HookScript("OnShow", function(self) 
				shine:Start()
			end)
		end
		local shine = gUI4:ApplyShine(self.SoulShardsWidget)
		self.SoulShardsWidget:HookScript("OnShow", function(self) 
			shine:Start()
		end)
	end

end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("ClassBar", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
end

function module:OnEnable()
	self:AddUnit("player", scaffolding, self.db.profile)
end
