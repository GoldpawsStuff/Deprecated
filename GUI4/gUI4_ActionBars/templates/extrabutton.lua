local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_ActionBars = gUI4:GetModule("gUI4_ActionBars", true)
if not gUI4_ActionBars then return end

local Button = CreateFrame("CheckButton")
gUI4_ActionBars.ExtraButton = Button

local LMP = GP_LibStub("GP_LibMediaPlus-1.0")

-- Lua API
local _G = _G
local pairs, unpack = pairs, unpack

-- WoW API
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop
local GetPetActionInfo = GetPetActionInfo
local GetPetActionsUsable = GetPetActionsUsable
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local IsUsableAction = IsUsableAction
local SetDesaturation = SetDesaturation

local EMPTY_SLOT = "Interface\\Buttons\\UI-Quickslot"
local FILLED_SLOT = "Interface\\Buttons\\UI-Quickslot2"

local buttons = {}

local function getColor(r, g, b)
	return floor(r*100 + .5)/100, floor(g*100 + .5)/100, floor(b*100 + .5)/100
end
local function SetHotKeyText(self, ...)
	self.button.custom.regions.hotkey:SetText("")
end
local function SetHotKeyColor(self, r, g, b, a)
	self.button.custom.regions.hotkey:SetTextColor(self.button.old.regions.hotkey:GetTextColor())
end
local function ShowHotKey(self)
	SetHotKeyText(self)
	self.button.custom.regions.hotkey:Show()
end
local function HideHotKey(self)
	self.button.custom.regions.hotkey:Hide()
end
local function SetActionNameText(self, ...)
	local msg = not(self.button:IsConsumableOrStackable()) and self.button:GetActionText()
	local width
	if msg and msg:len() > 0 then 
		for i = 1, msg:len() do
			self.button.custom.regions.name:SetText(msg:sub(1,i))
			if self.button.custom.regions.name:IsTruncated() then
				break
			else
				width = i
			end
		end
	end
	if width then
		self.button.custom.regions.name:SetText(msg:sub(1,width))
	else
		self.button.custom.regions.name:SetText(msg or "")
	end
end
local function ShowActionName(self)
	SetActionNameText(self)
	self.button.custom.regions.name:Show()
end
local function HideActionName(self)
	self.button.custom.regions.name:Hide()
end
local function SetCountText(self, ...)
	local msg = self.button.old.regions.count:GetText()
	self.button.custom.regions.count:SetText(msg or "")
end
local function ShowCount(self)
	SetCountText(self)
	self.button.custom.regions.count:Show()
end
local function HideCount(self)
	self.button.custom.regions.count:Hide()
end
local function SetNormalTexture(self, texture)
	local normal = self:GetNormalTexture()
	if normal then 
		normal:SetTexture("")
		normal:Hide()
	end
	if texture == EMPTY_SLOT then -- empty
		self.data.empty = true
	elseif texture == FILLED_SLOT then -- filled
		self.data.empty = false
	end
	self:UpdateLayers()
end
local function SetFrameLevel(self)
	local level = self:GetFrameLevel()
	self.scaffold:SetFrameLevel(level + 2)
	self.old.regions.cooldown:SetFrameLevel(level + 1)
end
local function SetIconTexture(self, ...)
	local texture = self.button.old.regions.icon:GetTexture() 
	if texture then
		self.button.custom.regions.icon:SetTexture(texture)
	else
		self.button.custom.regions.icon:SetTexture("")
	end
end
local function SetIconColor(self, ...)
	local usable
	local r, g, b = getColor(self.button.old.regions.icon:GetVertexColor()) 
	if self.button.buttonActionType == "action" then 
		local isUsable, notEnoughMana = self.button:IsUsable()
		if isUsable then
			usable = true
		elseif notEnoughMana then
			usable = true
		else
			usable = false
		end
	else
		if r and g and b then
			if r == .4 and g == .4 and b == .4 then
				usable = false
			else
				usable = true
			end
		else
			usable = true
		end
	end
	if usable then 
		SetDesaturation(self.button.custom.regions.icon, false)
		self.button.custom.regions.icon:SetVertexColor(r or 1, g or 1, b or 1) -- this could be oom coloring too
	else
		SetDesaturation(self.button.custom.regions.icon, true) -- fully desaturate unusable spells
		self.button.custom.regions.icon:SetVertexColor(.7, .7, .7)
	end
end
local function ShowIcon(self)
	SetCountText(self)
	self.button.custom.regions.icon:Show()
end
local function HideIcon(self)
	self.button.custom.regions.icon:Hide()
end

local function OnEnter(self, ...)
	self.data.highlight = true
	self:UpdateLayers()
	self.old.scripts.OnEnter(self, ...)
end
local function OnLeave(self, ...)
	self.data.highlight = false
	self:UpdateLayers()
	self.old.scripts.OnLeave(self, ...)
end
local function OnMouseDown(self, button) 
	-- self.data.pushed = true
	self:UpdateLayers()
end
local function OnMouseUp(self, button)  
	-- self.data.pushed = false
	self:UpdateLayers()
end

local scriptHandlers = {
	extra = { 
		OnMouseDown = OnMouseDown,
		OnMouseUp = OnMouseUp,
		OnEnter = OnEnter, 
		OnLeave = OnLeave 
	}
}

local hidden = CreateFrame("Frame", nil, UIParent)
hidden:Hide()

local function initiate(self)
	if buttons[self] then return end
	local name = self:GetName()
	
	self.scaffold = LMP:NewChain(CreateFrame("Frame", nil, self)) :SetFrameLevel(self:GetFrameLevel() + 2) :SetAllPoints() .__EndChain
	self.data = {}
	self.custom = {}
	self.custom.regions = {}
	self.old = {}
	self.old.regions = {}
	self.old.scripts = {}

	--self.custom.regions.icon = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("BORDER", 0) :SetAllPoints() :SetTexCoord(5/64, 59/64, 5/64, 59/64) .__EndChain
	self.custom.regions.pushed = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("BORDER", 2) :SetColorTexture(1, .97, 0, .25) :SetAllPoints(self.custom.regions.icon) .__EndChain
	self.custom.regions.normal = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("ARTWORK", 0) :SetAllPoints() .__EndChain
	self.custom.regions.normal.highlight = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	self.custom.regions.checked = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	self.custom.regions.checked.highlight = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	self.custom.regions.empty = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	self.custom.regions.empty.highlight = LMP:NewChain(self:CreateTexture()) :SetDrawLayer("ARTWORK", 0) :Hide() :SetAllPoints() .__EndChain
	self.custom.regions.count = LMP:NewChain("FontString", nil, self.scaffold) :SetFontObject(GameFontNormal) :Hide() :SetFontSize(10) :SetFontStyle(nil) :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", -2) :SetPoint("BOTTOMRIGHT", -2, 2) :SetTextColor(1, 1, 1) .__EndChain
	self.custom.regions.hotkey = LMP:NewChain("FontString", nil, self.scaffold) :SetFontObject(GameFontNormal) :Hide() :SetFontSize(10) :SetFontStyle(nil) :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", -1) :SetPoint("TOPRIGHT", -2, -2) :SetTextColor(1, 1, 1) .__EndChain
	self.custom.regions.name = LMP:NewChain("FontString", nil, self.scaffold) :SetFontObject(GameFontNormal) :Hide() :SetFontSize(10) :SetFontStyle(nil) :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) :SetDrawLayer("OVERLAY", -1) :SetPoint("BOTTOM") :SetPoint("LEFT") :SetPoint("RIGHT") :SetTextColor(1, 1, 1) .__EndChain

	
	self.old.regions.icon               = LMP:NewChain(_G[name .. "Icon"])  :SetDrawLayer("BORDER", 0) :SetAllPoints(self) :SetTexCoord(5/64, 59/64, 5/64, 59/64)  .__EndChain --:SetParent(hidden) 

	self.custom.regions.icon = self.old.regions.icon


	self.old.regions.count              = LMP:NewChain(_G[name .. "Count"]) :SetParent(hidden) .__EndChain
	self.old.regions.cooldown       	= LMP:NewChain(_G[name .. "Cooldown"]) :SetSwipeColor(0, 0, 0, .75) :SetAllPoints(self.custom.regions.icon) .__EndChain
	self.old.regions.flash              = LMP:NewChain(_G[name .. "Flash"]) :SetParent(hidden) .__EndChain
	self.old.regions.hotkey             = LMP:NewChain(_G[name .. "HotKey"]) :SetParent(hidden) .__EndChain
	self.old.regions.normalTexture      = LMP:NewChain(_G[name .. "NormalTexture"]) :SetParent(hidden) .__EndChain
	self.old.regions.style 				= LMP:NewChain(_G[name].style) :SetParent(hidden) .__EndChain


	self.old.regions.count.button = self
	self.old.regions.hotkey.button = self
	self.old.regions.icon.button = self
	if self.old.regions.name then -- the extrabuttons lack this
		self.old.regions.name.button = self
	end

	self.custom.regions.count.button = self
	self.custom.regions.hotkey.button = self
	self.custom.regions.name.button = self
	self.custom.regions.icon.button = self

	for handler,script in pairs(scriptHandlers.extra) do
		self.old.scripts[handler] = self:GetScript(handler)
		self:SetScript(handler, script)
	end

	-- hook our custom icon to the original icon
	--hooksecurefunc(self.old.regions.icon, "SetTexture", SetIconTexture) 
	--hooksecurefunc(self.old.regions.icon, "SetVertexColor", SetIconColor)
	--hooksecurefunc(self.old.regions.icon, "Show", ShowIcon)
	--hooksecurefunc(self.old.regions.icon, "Hide", HideIcon)

	--SetIconTexture(self.old.regions.icon)
	
	hooksecurefunc(self.old.regions.hotkey, "SetText", SetHotKeyText)
	hooksecurefunc(self.old.regions.hotkey, "SetVertexColor", SetHotKeyColor)
	hooksecurefunc(self.old.regions.hotkey, "SetTextColor", SetHotKeyColor)
	hooksecurefunc(self.old.regions.hotkey, "Show", ShowHotKey)
	hooksecurefunc(self.old.regions.hotkey, "Hide", HideHotKey)

	if self.old.regions.name then -- the extrabuttons lack this
		hooksecurefunc(self.old.regions.name, "SetText", SetActionNameText)
		hooksecurefunc(self.old.regions.name, "Show", ShowActionName)
		hooksecurefunc(self.old.regions.name, "Hide", HideActionName)
	end
	
	hooksecurefunc(self.old.regions.count, "SetText", SetCountText)
	hooksecurefunc(self.old.regions.count, "Show", ShowCount)
	hooksecurefunc(self.old.regions.count, "Hide", HideCount)
	
	hooksecurefunc(self, "SetChecked", function(self) self:UpdateLayers() end) -- this solves the checking for our custom textures
	hooksecurefunc(self, "SetFrameLevel", SetFrameLevel)
	
	-- hook the NormalTexture changes of this specific button
	-- we mainly use this to hide the gloss layer of empty slots
	if self.SetNormalTexture then -- petbuttons haven't got it
		hooksecurefunc(self, "SetNormalTexture", SetNormalTexture)
	end
	if self.SetCheckedTexture then
		self:SetCheckedTexture("")
	end
	if self.SetHighlightTexture then
		self:SetHighlightTexture("")
	end
	if self.SetPushedTexture then -- let blizz handle this one
		self:SetPushedTexture(self.custom.regions.pushed)
		self:GetPushedTexture():SetBlendMode("BLEND")
		self:GetPushedTexture():SetDrawLayer("BORDER", 2)
	end

	buttons[self] = self.scaffold
	
	self:UpdateLayers()
end

function Button:Update()
	initiate(self)
	if not self:IsShown() then return end
	local id = self:GetID()
	if id then
		self.old.regions.cooldown:Show()
		self.old.regions.icon:Show()
		self.data.empty = false
		self:SetNormalTexture(FILLED_SLOT)
	else
		self.old.regions.cooldown:Hide()
		self.old.regions.icon:Hide()
		self.data.empty = true
		self:SetNormalTexture(EMPTY_SLOT)
	end
	if active then
		self:SetChecked(1)
	else
		self:SetChecked(0)
	end
	local isUsable, notEnoughMana = IsUsableAction(self.action)
	if isUsable then
		SetDesaturation(self.old.regions.icon, nil)
		self.old.regions.icon:SetVertexColor(1, 1, 1)
		self.old.regions.cooldown:SetAlpha(1)
	else
		SetDesaturation(self.old.regions.icon, 1)
		self.old.regions.icon:SetVertexColor(.5, .5, .5)
		self.old.regions.cooldown:SetAlpha(.5)
	end
end

function Button:ShowButton()
	initiate(self)
	local backdrop, gloss
	if backdrop then
		backdrop:Show()
	end
	if gloss then
		gloss:Show()
	end
	self:UpdateLayers()
	self:SetAlpha(1.0)
end

function Button:HideButton()
	initiate(self)
	local backdrop, gloss
	if backdrop then
		backdrop:Hide()
	end
	if gloss then
		gloss:Hide()
	end
	if self.showgrid == 0 and not self.parent:GetSettings().showgrid then  
		-- self:UpdateLayers() -- save it for when we show it
		self:SetAlpha(0.0)
	end
end

function Button:ShowGrid()
	initiate(self)
	self.showgrid = self.showgrid + 1
	local icon = self.icon
	if icon:GetTexture() then -- filled
		self.data.empty = false
	else -- empty / grid display
		self.data.empty = true
	end
	self:UpdateLayers()
	self:SetAlpha(1.0)
end

function Button:HideGrid()
	initiate(self)
	if self.showgrid > 0 then self.showgrid = self.showgrid - 1 end
end

local function style(element, db, ...)
	if not element then return end
	if db then
		element:SetTexture(db:GetPath())
		element:SetTexCoord(db:GetTexCoord())
		element:SetVertexColor(unpack(db:GetColor()))
		element:SetAlpha(db:GetAlpha())
		element:SetSize(db:GetTexSize())
		element:ClearAllPoints()
		element:SetPoint(db:GetPoint())
	else
		element:SetTexture("")
		element:Hide()
		element:SetTexCoord(0, 1, 0, 1)
		element:SetVertexColor(1, 1, 1)
		element:SetAlpha(1)
		element:SetSize(.001, .001)
		element:ClearAllPoints()
		element:SetAllPoints()
	end
	return element
end

function Button:UpdateSkin(db, forced)
	if forced or not self.db then
		self.db = db 
	end
	db = self.db 

	initiate(self)
	
	if db.icon then
		self.custom.regions.icon:SetSize(unpack(db.icon.size))
		self.custom.regions.icon:SetTexCoord(unpack(db.icon.texCoord))
		self.custom.regions.icon:ClearAllPoints()
		self.custom.regions.icon:SetPoint(unpack(db.icon.place))
	else
		self.custom.regions.icon:SetSize(self:GetSize())
		self.custom.regions.icon:SetTexCoord(5/65, 59/64, 5/64, 59/64)
		self.custom.regions.icon:SetAllPoints()
	end
	
	style(self.custom.regions.normal, db.normal)
	style(self.custom.regions.normal.highlight, db.highlight)
	style(self.custom.regions.checked, db.checked)
	style(self.custom.regions.checked.highlight, db.checkedhighlight)
	style(self.custom.regions.empty, db.empty)
	style(self.custom.regions.empty.highlight, db.emptyhighlight)
	
	self.custom.regions.pushed:SetSize(self.custom.regions.icon:GetSize())
	self.custom.regions.pushed:ClearAllPoints()
	self.custom.regions.pushed:SetPoint(self.custom.regions.icon:GetPoint())

	self:SetNormalTexture("") -- fires our hook which also updates gloss
	self:UpdateLayers()	
end

function Button:UpdateLayers()
	local checked, empty, highlight
	empty = nil
	highlight = self.data.highlight
	checked = (self:GetChecked() == 1) or (self.IsCurrentlyActive and self:IsCurrentlyActive()) or (self.IsAutoRepeat and self:IsAutoRepeat())
	self.custom.regions.empty:Hide()
	self.custom.regions.empty.highlight:Hide()
	if checked then
		self.custom.regions.checked:SetShown(not(highlight))
		self.custom.regions.checked.highlight:SetShown(highlight)
		self.custom.regions.normal:Hide()
		self.custom.regions.normal.highlight:Hide()
	else
		self.custom.regions.checked:Hide()
		self.custom.regions.checked.highlight:Hide()
		self.custom.regions.normal:SetShown(not highlight)
		self.custom.regions.normal.highlight:SetShown(highlight)
	end
	self.data.checked = checked
	self.data.pushed = pushed
end
