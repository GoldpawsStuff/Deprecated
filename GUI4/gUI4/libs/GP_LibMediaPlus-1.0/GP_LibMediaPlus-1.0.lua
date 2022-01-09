assert(GP_LibStub, "GP_LibMediaPlus-1.0 requires GP_LibStub")
assert(GP_LibStub:GetLibrary("GP_CallbackHandler-1.0", true), "GP_LibMediaPlus-1.0 requires GP_CallbackHandler-1.0")

local MAJOR, MINOR = "GP_LibMediaPlus-1.0", 62
local lib = GP_LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end -- No upgrade needed

local LEGION = tonumber((select(2, GetBuildInfo()))) >= 21996

lib.bar = lib.bar or CreateFrame("StatusBar", "GP_LibMediaPlusStatusBar", UIParent)
lib.font = lib.font or lib.bar:CreateFontString("GP_LibMediaPlusFontString", "ARTWORK")
lib.embeds = lib.embeds or {} -- what objects embed this lib
lib.widgetTypes = lib.widgetTypes or {} -- widget registry
lib.bars = lib.bars or {} -- statusbar registry
lib.borders = lib.borders or {} -- border registry
lib.fonthooks = lib.fonthooks or {} -- fontstring registry
lib.utilFrame = lib.utilFrame or CreateFrame("Frame")

-- Lua API
local _G = _G
local modf, abs = math.modf, math.abs
local type = type
local ipairs, pairs, select, unpack = ipairs, pairs, select, unpack
local setmetatable, getmetatable, rawset, rawget = setmetatable, getmetatable, rawset, rawget
local tinsert, tremove = table.insert, table.remove

-- WoW API
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local GameTooltip = GameTooltip

-- Grab some basic frame methods
local SetPoint = getmetatable(lib.utilFrame).__index.SetPoint
local ClearAllPoints = getmetatable(lib.utilFrame).__index.ClearAllPoints

------------------------------------------------------------------------
--	Utility Functions
------------------------------------------------------------------------
local function embed(source, target)
	for i,v in pairs(source) do
		target[i] = v
	end
	return target
end

local function new(tbl, parentClass)
	local class = tbl or {}
	class.mt = { __index = class }
	
	-- add a parent class to inherit from
	if parentClass then
		class = setmetatable(class, { __index = parentClass })
		-- use a method from the parent class, with self passed as argument
		function class:Super(method, ...)
			return parentClass[method](self, ...)
		end
	end
	
	-- returns a new object with its metatable set to the class metatable
	function class:Bind(obj) 
		return setmetatable(obj, self.mt) 
	end
	return class
end

local function newFrameClass(frameType, parentClass)
	return new(CreateFrame(frameType), parentClass)
end

local function argcheck(value, num, ...)
	assert(type(num) == "number", "Bad argument #2 to 'argcheck' (number expected, got "..type(num)..")")
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = strjoin(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s' (%s expected, got %s"):format(num, name, types, type(value)), 3)
end


------------------------------------------------------------------------
--	StatusBar Template
------------------------------------------------------------------------
local function PostUpdateStatusBar(self, unit, min, max)
	if unit and UnitIsDeadOrGhost(unit) then 
		self:SetValue(0) 
	end
end

local function UpdateStatusBar(self)
	local range = self._max - self._min 
	local value = self._value - self._min
	local size = self._mult or 1
	local fraction = 0.0001
	
	if range > 0 and value > 0 and range >= value then
		fraction = value / range
	end
	
	if self._growth == "RIGHT" then
		local final = ((self._right - self._left) * fraction) + self._left
		self._bar:SetWidth(size * fraction) 
		self._bar:SetTexCoord(self._left, final, self._top, self._bottom)
		
	elseif self._growth == "LEFT" then
		local final = ((self._left - self._right) * fraction) + self._right
		self._bar:SetWidth(size * fraction) 
		self._bar:SetTexCoord(final, self._right, self._top, self._bottom)
		
	elseif self._growth == "UP" then
		local final = self._bottom - ((self._bottom - self._top) * fraction)
		self._bar:SetHeight(size * fraction)
		self._bar:SetTexCoord(self._left, self._right, final, self._bottom)
		
	elseif self._growth == "DOWN" then
		local final = self._top - ((self._top - self._bottom) * fraction)
		self._bar:SetHeight(size * fraction)
		self._bar:SetTexCoord(self._left, self._right, self._top, final)
	end
end

local function OnStatusBarSizeChanged(self)
	if self._growth == "LEFT" or self._growth == "RIGHT" then
		local left, right = self:GetLeft(), self:GetRight()
		if left and right then
			self._mult = abs(left-right)
		else
			self._mult = self:GetWidth()
		end
	elseif self._growth == "UP" or self._growth == "DOWN" then
		local top, bottom = self:GetTop(), self:GetBottom()
		if top and bottom then
			self._mult = abs(top-bottom)
		else
			self._mult = self:GetHeight()
		end
	end
	self:Update()
end

local function SetStatusBarSize(self, width, height)
	argcheck(width, 1, "number")
	argcheck(height, 2, "number")
	self:RawSetSize(width, height)
	self:OnSizeChanged()
	return self
end

local function SetStatusBarWidth(self, width)
	argcheck(width, 1, "number")
	self:RawSetWidth(width)
	self:OnSizeChanged()
	return self
end

local function SetStatusBarHeight(self, height)
	argcheck(height, 1, "number")
	self:RawSetHeight(height)
	self:OnSizeChanged()
	return self
end

local function SetStatusBarScript(self, handler, func)
	argcheck(handler, 1, "string")
	argcheck(func, 2, "function", "nil")
	if self.__scripts[handler] ~= nil then
		if func then
			self.__scripts[handler] = func
		else
			self.__scripts[handler] = false -- make sure it's never set to 'nil'
		end
	elseif self:RawHasScript(handler) then
		self:RawSetScript(handler, func)
	end
	return self
end

local function GetStatusBarScript(self, handler)
	argcheck(handler, 1, "string")
	if self.__scripts[handler] ~= nil then
		return self.__scripts and self.__scripts[handler]
	elseif self:RawHasScript(handler) then
		return self:RawGetScript(handler)
	end
end

local function HookStatusBarScript(self, handler, func)
	argcheck(handler, 1, "string")
	argcheck(func, 2, "function")
	if self.__scripts[handler] ~= nil then
		if not self.__scriptHooks then
			self.__scriptHooks = {}
		end
		if not self.__scriptHooks[handler] then
			self.__scriptHooks[handler] = {}
		end
		tinsert(self.__scriptHooks[handler], func)
	else
		self:RawSetScript(handler, func)
	end
end

local function HasStatusBarScript(self, handler)
	argcheck(handler, 1, "string")
	if self.__scripts[handler] ~= nil then
		return true
	else
		return self:RawHasScript(handler)
	end
end

local function FireStatusBarScript(self, handler, ...)
	argcheck(handler, 1, "string")
	local script = self:GetScript(handler)
	if script then
		script(self, ...)
	end
	if self.__scriptHooks and self.__scriptHooks[handler] then
		for i,func in ipairs(self.__scriptHooks) do
			func(self, ...)
		end
	end
end

local function SetStatusBarPostUpdate(self, func)
	if type(func) == "function" then
		self.PostUpdate = func
	elseif func == true then
		self.PostUpdate = PostUpdateStatusBar
	else
		self.PostUpdate = nil
	end
	return self
end
	
local function SetStatusBarValue(self, value)
	argcheck(value, 1, "number")
	if value <= self._min then 
		self._value = self._min
	elseif value >= self._max then
		self._value = self._max
	else
		self._value = value 
	end
	self:Update()
	self:FireScript("OnValueChanged", value)
	return self
end

local function SetStatusBarMinMaxValues(self, min, max)
	argcheck(min, 1, "number")
	argcheck(max, 2, "number")
	if max > min then
		self._min = min
		self._max = max
	else 
		self._min = 0
		self._max = 1
	end
	if self._value > self._max then 
		self._value = self._max
	elseif self._value < self._min then 
		self._value = self._min 
	end
	self:Update() 
	self:FireScript("OnMinMaxChanged", min, max)
	return self
end

local function SetStatusBarGrowth(self, growth)
	argcheck(growth, 1, "string")
	if growth == "RIGHT" then
		self._growth = "RIGHT"
		self._reverse = false
		self._bar:ClearAllPoints()
		self._bar:SetPoint("TOPLEFT")
		self._bar:SetPoint("BOTTOMLEFT")
	elseif growth == "LEFT" then
		self._growth = "LEFT"
		self._reverse = true
		self._bar:ClearAllPoints()
		self._bar:SetPoint("TOPRIGHT")
		self._bar:SetPoint("BOTTOMRIGHT")
	elseif growth == "UP" then
		self._growth = "UP"
		self._reverse = false
		self._bar:ClearAllPoints()
		self._bar:SetPoint("BOTTOMLEFT")
		self._bar:SetPoint("BOTTOMRIGHT")
	elseif growth == "DOWN" then
		self._growth = "DOWN"
		self._reverse = true
		self._bar:ClearAllPoints()
		self._bar:SetPoint("TOPLEFT")
		self._bar:SetPoint("TOPRIGHT")
	end
	self:OnSizeChanged()
	return self
end

local function SetStatusBarOrientation(self, orientation)
	argcheck(orientation, 1, "string")
	if orientation == "HORIZONTAL" then
		self:SetGrowth(self._reverse and "LEFT" or "RIGHT")
	elseif orientation == "VERTICAL" then
		self:SetGrowth(self._reverse and "DOWN" or "UP")
	end
	return self
end

local function SetStatusBarReverse(self, enable)
	argcheck(enable, 1, "boolean", "nil")
	if enable then
		self._reverse = true
	else
		self._reverse = false
	end
	return self
end

local function GetStatusBarOrientation(self)
	if self.growth == "RIGHT" or self.growth == "LEFT" then
		return "HORIZONTAL"
	else
		return "VERTICAL"
	end
end

local function IsStatusBarReverse(self)
	return self._reverse
end

local function SetStatusBarColor(self, r, g, b, a)
	argcheck(r, 1, "number")
	argcheck(g, 2, "number")
	argcheck(b, 3, "number")
	argcheck(a, 4, "number", "nil")
	self._bar:SetVertexColor(r, g, b, a)
	if self._backdrop.mult then
		local m = self._backdrop.mult
		self._backdrop:SetVertexColor(r * m, g * m, b * m)
	end
	return self
end

local function SetStatusBarGradient(self, r1, g1, b1, a1, r2, g2, b2, a2) 
	argcheck(r1, 1, "number")
	argcheck(g1, 2, "number")
	argcheck(b1, 3, "number")
	argcheck(a1, 4, "number")
	argcheck(r2, 5, "number")
	argcheck(g2, 6, "number")
	argcheck(b2, 7, "number")
	argcheck(a2, 8, "number")
	if self._growth == "RIGHT" then
		self._bar:SetGradientAlpha("HORIZONTAL", r1, g1, b1, a1, r2, g2, b2, a2) 
	elseif self._growth == "LEFT" then
		self._bar:SetGradientAlpha("HORIZONTAL", r2, g2, b2, a2, r1, g1, b1, a1) 
	elseif self._growth == "UP" then
		self._bar:SetGradientAlpha("VERTICAL", r1, g1, b1, a1, r2, g2, b2, a2) 
	elseif self._growth == "DOWN" then
		self._bar:SetGradientAlpha("VERTICAL", r2, g2, b2, a2, r1, g1, b1, a1) 
	end
	return self
end

local function SetStatusBarTexture(self, r, g, b, a)
	argcheck(r, 1, "number", "string", "nil")
	argcheck(g, 2, "number", "nil")
	argcheck(b, 3, "number", "nil")
	argcheck(a, 4, "number", "nil")
	if LEGION and (type(r) == "number") then
		self._bar:SetColorTexture(r, g, b, a)
	else
		self._bar:SetTexture(r, g, b, a)
	end
	return self
end

local function SetStatusBarTexCoord(self, left, right, top, bottom)
	argcheck(left, 1, "number", "nil")
	argcheck(right, 2, "number", "nil")
	argcheck(top, 3, "number", "nil")
	argcheck(bottom, 4, "number", "nil")
	self._left = left or 0
	self._right = right or 1
	self._top = top or 0
	self._bottom = bottom or 1
	self:Update()
	return self
end

local function SetBackdropTexCoord(self, left, right, top, bottom)
	argcheck(left, 1, "number", "nil")
	argcheck(right, 2, "number", "nil")
	argcheck(top, 3, "number", "nil")
	argcheck(bottom, 4, "number", "nil")
	self._backdrop:SetTexCoord(left or 0, right or 1,top or 0, bottom or 1)
	return self
end

local function SetBackdropTexture(self, r, g, b, a)
	argcheck(r, 1, "number", "string", "nil")
	argcheck(g, 2, "number", "nil")
	argcheck(b, 3, "number", "nil")
	argcheck(a, 4, "number", "nil")
	if LEGION and (type(r) == "number") then
		self._backdrop:SetColorTexture(r, g, b, a)
	else
		self._backdrop:SetTexture(r, g, b, a)
	end
	if self._backdrop:GetTexture() then
		self._backdrop:Show()
	else
		self._backdrop:Hide()
	end
	return self
end

local function SetBackdropAlpha(self, a)
	argcheck(a, 1, "number", "nil")
	self._backdrop:SetAlpha(a or 1)
	return self
end

local function SetBackdropColor(self, r, g, b, a)
	argcheck(r, 1, "number", "string", "nil")
	argcheck(g, 2, "number", "nil")
	argcheck(b, 3, "number", "nil")
	argcheck(a, 4, "number", "nil")
	if r and g and b then
		self._backdrop:SetVertexColor(r, g, b, a)
	else
		local m = self._backdrop.mult
		if m then 
			local r, g, b = self._bar:GetVertexColor()
			self._backdrop:SetVertexColor(r * m, g * m, b * m, a)
		else
			self._backdrop:SetVertexColor(1, 1, 1)
		end
	end
	return self
end

local function SetBackdropMultiplier(self, mult)
	argcheck(mult, 1, "number", "nil")
	if mult then
		self._backdrop.mult = min(max(mult, 0), 1)
	else
		self._backdrop.mult = nil
	end
	return self
end

local function SetOverlayTexCoord(self, left, right, top, bottom)
	argcheck(left, 1, "number", "nil")
	argcheck(right, 2, "number", "nil")
	argcheck(top, 3, "number", "nil")
	argcheck(bottom, 4, "number", "nil")
	self._gloss:SetTexCoord(left or 0, right or 1,top or 0, bottom or 1)
	return self
end

local function SetOverlayTexture(self, r, g, b, a)
	argcheck(r, 1, "number", "string", "nil")
	argcheck(g, 2, "number", "nil")
	argcheck(b, 3, "number", "nil")
	argcheck(a, 4, "number", "nil")
	if LEGION and (type(r) == "number") then
		self._gloss:SetColorTexture(r, g, b, a)
	else
		self._gloss:SetTexture(r, g, b, a)
	end
	if self._gloss:GetTexture() then
		self._gloss:Show()
	else
		self._gloss:Hide()
	end
	return self
end

local function SetOverlayAlpha(self, a)
	argcheck(a, 1, "number", "nil")
	self._gloss:SetAlpha(a or 1)
	return self
end

local function SetOverlayColor(self, r, g, b, a)
	argcheck(r, 1, "number", "string", "nil")
	argcheck(g, 2, "number", "nil")
	argcheck(b, 3, "number", "nil")
	argcheck(a, 4, "number", "nil")
	if r and g and b then
		self._gloss:SetVertexColor(r, g, b, a)
	else
		local m = self._gloss.mult
		local r, g, b = self._bar:GetVertexColor()
		self._gloss:SetVertexColor(r * m, g * m, b * m, a)
	end
	return self
end

local function SetThreatTexCoord(self, left, right, top, bottom)
	argcheck(left, 1, "number", "nil")
	argcheck(right, 2, "number", "nil")
	argcheck(top, 3, "number", "nil")
	argcheck(bottom, 4, "number", "nil")
	self._threat:SetTexCoord(left or 0, right or 1,top or 0, bottom or 1)
	return self
end

local function SetThreatTexture(self, r, g, b, a)
	argcheck(r, 1, "number", "string", "nil")
	argcheck(g, 2, "number", "nil")
	argcheck(b, 3, "number", "nil")
	argcheck(a, 4, "number", "nil")
	if LEGION and (type(r) == "number") then
		self._threat:SetColorTexture(r, g, b, a)
	else
		self._threat:SetTexture(r, g, b, a)
	end
	return self
end

local function SetThreatAlpha(self, a)
	argcheck(a, 1, "number", "nil")
	self._threat:SetAlpha(a or 1)
	return self
end

local function SetThreatColor(self, r, g, b, a)
	argcheck(r, 1, "number", "string")
	argcheck(g, 2, "number")
	argcheck(b, 3, "number")
	argcheck(a, 4, "number", "nil")
	self._threat:SetVertexColor(r, g, b, a)
	return self
end

local function ShowThreatTexture(self)
	self._threat:Show()
end

local function HideThreatTexture(self)
	self._threat:Hide()
end

local function GetStatusBarValue(self)
	return self._value
end

local function GetStatusBarMinMaxValues(self)
	return self._min, self._max
end

local function GetStatusBarGrowth(self)
	return self._growth
end

local function GetStatusBarColor(self)
	return self._bar:GetVertexColor()
end

local function GetStatusBarTexture(self)
	return self._bar
end

local function GetStatusBarSetTexCoord(self)
	return self._bar:GetTexCoord()
end

local function GetBackdropTexCoord(self)
	return self._backdrop:GetTexCoord()
end

local function GetBackdropTexture(self)
	return self._backdrop:GetTexture()
end

local function GetBackdropColor(self)
	return self._backdrop:GetVertexColor()
end

local function GetBackdropAlpha(self)
	return self._backdrop:GetAlpha()
end

local function GetOverlayTexCoord(self)
	return self._gloss:GetTexCoord()
end

local function GetOverlayTexture(self)
	return self._gloss:GetTexture()
end

local function GetOverlayColor(self)
	return self._gloss:GetVertexColor()
end

local function GetOverlayAlpha(self)
	return self._gloss:GetAlpha()
end

local function GetThreatTexCoord(self)
	return self._threat:GetTexCoord()
end

local function GetThreatTexture(self)
	return self._threat:GetTexture()
end

local function GetThreatColor(self)
	return self._threat:GetVertexColor()
end

local function GetThreatAlpha(self)
	return self._threat:GetAlpha()
end

local StatusBarMethods = {
	-- inherited blizzard methods
	RawSetSize = lib.bar.SetSize,
	RawSetWidth = lib.bar.SetWidth,
	RawSetHeight = lib.bar.SetHeight,
	RawSetScript = lib.bar.SetScript,
	RawGetScript = lib.bar.GetScript,
	RawHasScript = lib.bar.HasScript,
	
	-- replacement blizzard methods
	GetScript = GetStatusBarScript,
	GetStatusBarTexture = GetStatusBarTexture,
	GetStatusBarColor = GetStatusBarColor,
	GetMinMaxValues = GetStatusBarMinMaxValues,
	GetValue = GetStatusBarValue,
	GetOrientation = GetStatusBarOrientation,
	HasScript = HasStatusBarScript,
	HookScript = HookStatusBarScript,
	SetScript = SetStatusBarScript,
	SetSize = SetStatusBarSize, 
	SetWidth = SetStatusBarWidth, 
	SetHeight = SetStatusBarHeight, 
	SetStatusBarTexture = SetStatusBarTexture,
	SetStatusBarColor = SetStatusBarColor,
	SetMinMaxValues = SetStatusBarMinMaxValues,
	SetValue = SetStatusBarValue,

	-- custom methods
	Update = UpdateStatusBar,
	OnSizeChanged = OnStatusBarSizeChanged,
	FireScript = FireStatusBarScript,
	IsReverse = IsStatusBarReverse,
	GetBackdropAlpha = GetBackdropAlpha,
	GetBackdropColor = GetBackdropColor,
	GetBackdropTexture = GetBackdropTexture,
	GetBackdropTexCoord = GetBackdropTexCoord,
	GetOverlayAlpha = GetOverlayAlpha,
	GetOverlayColor = GetOverlayColor,
	GetOverlayTexture = GetOverlayTexture,
	GetOverlayTexCoord = GetOverlayTexCoord,
	GetThreatAlpha = GetThreatAlpha,
	GetThreatColor = GetThreatColor,
	GetThreatTexture = GetThreatTexture,
	GetThreatTexCoord = GetThreatTexCoord,
	GetStatusBarSetTexCoord = GetStatusBarSetTexCoord,
	GetGrowth = GetStatusBarGrowth,
	SetOrientation = SetStatusBarOrientation,
	SetReverse = SetStatusBarReverse, 
	SetBackdropMultiplier = SetBackdropMultiplier,
	SetBackdropColor = SetBackdropColor,
	SetBackdropAlpha = SetBackdropAlpha,
	SetBackdropTexture = SetBackdropTexture,
	SetBackdropTexCoord = SetBackdropTexCoord,
	SetOverlayColor = SetOverlayColor,
	SetOverlayAlpha = SetOverlayAlpha,
	SetOverlayTexture = SetOverlayTexture,
	SetOverlayTexCoord = SetOverlayTexCoord,
	SetThreatColor = SetThreatColor,
	SetThreatAlpha = SetThreatAlpha,
	SetThreatTexture = SetThreatTexture,
	SetThreatTexCoord = SetThreatTexCoord,
	SetStatusBarTexCoord = SetStatusBarTexCoord,
	SetStatusBarGradient = SetStatusBarGradient,
	SetGrowth = SetStatusBarGrowth,
	SetPostUpdate = SetStatusBarPostUpdate,
	HideThreatTexture = HideThreatTexture, 
	ShowThreatTexture = ShowThreatTexture
}

local function newBarWidget(name, parent)
	-- add an entry for the given 'parent' in our bar registry
	if not lib.bars[parent] then
		lib.bars[parent] = {}
	end

	-- bar frame
	local bar = CreateFrame("Frame", name, parent)
	bar:SetHeight(1)
	bar:SetWidth(1)
	bar._value = 1
	bar._min = 0
	bar._max = 1
	bar._growth = "RIGHT"
	bar._reverse = false
	bar._left = 0
	bar._right = 1
	bar._top = 0
	bar._bottom = 1
	bar.__scripts = { OnValueChanged = false, OnMinMaxChanged = false }
	
	-- backdrop texture 
	bar._backdrop = bar:CreateTexture()
	bar._backdrop:SetDrawLayer("BACKGROUND", 0)
	bar._backdrop:SetAllPoints(bar)
	bar._backdrop.mult = 1/3
	bar._backdrop:Hide() -- will be shown whenever a texture is set
	
	-- bar texture
	bar._bar = bar:CreateTexture()
	bar._bar:SetDrawLayer("BORDER", 0)
	bar._bar:SetPoint("TOPLEFT")
	bar._bar:SetPoint("BOTTOMLEFT")

	-- highlight texture (intended for mouseover, etc)
	bar._highlight = bar:CreateTexture()
	bar._highlight:SetDrawLayer("BORDER", 2)
	bar._highlight:SetAllPoints(bar)
	bar._highlight:Hide() -- needs to be manually shown/hidden with bar:ShowHighlightTexture() / bar:HideHighlightTexture()
	bar._highlight:SetBlendMode("BLEND")

	-- gloss texture
	bar._gloss = bar:CreateTexture()
	bar._gloss:SetDrawLayer("ARTWORK", -2)
	bar._gloss:SetAllPoints(bar)
	bar._gloss:Hide() -- will be shown whenever a texture is set

	-- shade texture
	bar._shade = bar:CreateTexture()
	bar._shade:SetDrawLayer("ARTWORK", -1)
	bar._shade:SetAllPoints(bar)
	bar._shade:Hide() -- will be shown whenever a texture is set
	
	-- threat texture 
	bar._threat = bar:CreateTexture()
	bar._threat:SetDrawLayer("ARTWORK", 0)
	bar._threat:SetAllPoints(bar)
	bar._threat:Hide() -- needs to be manually shown/hidden with bar:ShowThreatTexture() / bar:HideThreatTexture()

	embed(StatusBarMethods, bar)
	
	-- bar:SetScript("OnSizeChanged", OnSizeChanged)
	bar:HookScript("OnSizeChanged", bar.OnSizeChanged) -- needed for the bar to be resized through :SetPoint
	bar:OnSizeChanged()
	
	if not parent.GetStatusBarRegistry then
		local registry = lib.bars[parent]
		function parent:GetStatusBarRegistry()
			return pairs(registry)
		end
	end
	lib.bars[parent][bar] = bar -- hm...
	
	return bar	
end

------------------------------------------------------------------------
--	FontString Template
------------------------------------------------------------------------
-- updates the font face of any font based on a fontObject
local function updateFontFace(self, font)
	for i = 1, #lib.fonthooks[self] do
		local fontString = lib.fonthooks[self][i]
		local _, size, style = fontString:GetFont()
		fontString:RawSetFont(font, size, style)
	end
end

-- inserts a fontString into the list of hooked fonts for a given fontObject
local function insertFontString(fontObject, fontString)
	if not lib.fonthooks[fontObject] then
		lib.fonthooks[fontObject] = {}
		tinsert(lib.fonthooks[fontObject], fontString)
		hooksecurefunc(fontObject, "SetFont", updateFontFace)
		return true
	else
		tinsert(lib.fonthooks[fontObject], fontString)
	end
end

-- hooks the font face changes of 'fontObject' to 'fontString'
local function hookFont(fontObject, fontString)
	insertFontString(fontObject, fontString)
end

local function unHookFont(fontObject, fontString)
	if fontObject and lib.fonthooks[fontObject] then
		for i,hooked in pairs(lib.fonthooks[fontObject]) do
			if fontstring == hooked then
				tremove(strings, i)
			end
		end
	elseif not fontObject then
		-- for i,hooked in pairs(lib.fonthooks[fontObject]) do
			-- if fontstring == hooked then
				-- tremove(strings, i)
			-- end
		-- end
	end
end

local function SetFont(self, font, size, style)
	argcheck(font, 1, "string")
	argcheck(size, 2, "number", "nil")
	argcheck(style, 3, "string", "nil")

	local oldFont, oldSize, oldStyle = self:GetFont()
	local objectFont = self:GetFontObject():GetFont()
	local hooked = oldFont == objectFont
	if hooked and font ~= oldFont then
		unHookFont(nil, self) -- automatic unhooking when font face changes occur
	end
	self:RawSetFont(font or oldFont, size or oldSize, style or oldStyle)
	-- if not hooked and font == objectFont then
		-- hookFont(self:GetFontObject(), self) -- automatic rehook? nah...
	-- end
	return self
end

local function SetFontSize(self, size)
	argcheck(size, 1, "number")
	local oldFont, oldSize, oldStyle = self:GetFont()
	self:RawSetFont(oldFont, size or oldSize, oldStyle)
	return self
end

local function SetFontStyle(self, style)
	argcheck(style, 1, "string", "nil")
	local oldFont, oldSize, oldStyle = self:GetFont()
	self:RawSetFont(oldFont, oldSize, style or "")
	return self
end

local function SetFontObject(self, objectOrName)
	argcheck(objectOrName, 1, "string", "table")
	if type(objectOrName) == "string" then
		assert(_G[objectOrName], "Bad argument #1 to 'SetFontObject'. No object named '"..name.."' exists.")
		objectOrName = _G[objectOrName]
	end
	unHookFont(nil, self)
	self:RawSetFontObject(objectOrName)
	hookFont(objectOrName, self)
	return self
end

local FontStringMethods = {
	-- inherited blizzard methods
	RawSetFont = lib.font.SetFont,
	RawSetFontObject = lib.font.SetFontObject,
	
	-- replacement blizzard methods
	SetFont = SetFont,
	SetFontObject = SetFontObject,
	
	-- custom methods
	SetFontSize = SetFontSize,
	SetFontStyle = SetFontStyle
}

local function newFontWidget(name, parent)
	local fontString = parent:CreateFontString()
	embed(FontStringMethods, fontString)
	return fontString
end


------------------------------------------------------------------------
--	Public API
------------------------------------------------------------------------
local hider = CreateFrame("Frame", "LibMediaPlusSecureHider", UIParent)
hider:SetAllPoints()
hider.children = {}
RegisterStateDriver(hider, "visibility", "hide")

-- kill off an existing frame in a secure, taint free way
-- @usage LMP:Kill(object, [keepEvents], [silent])
-- @param object <table, string> frame, fontstring or texture to hide
-- @param keepEvents <boolean, nil> 'true' to leave a frame's events untouched
-- @param silent <boolean, nil> 'true' to return 'false' instead of producing an error for non existing objects
function lib:Kill(object, keepEvents, silent)
	argcheck(object, 1, "string", "table")
	argcheck(keepEvents, 2, "boolean", "nil")
	if type(object) == "string" then
		if silent and not _G[object] then
			return false
		end
		assert(_G[object], "Bad argument #1 to 'Kill'. No object named '"..object.."' exists.")
		object = _G[object]
	end
	if not hider[object] then
		hider[object] = {
			parent = hider:GetParent(),
			isshown = hider:IsShown(),
			point = { hider:GetPoint() }
		}
	end
	object:SetParent(hider)
	if object.UnregisterAllEvents and not keepEvents then
		object:UnregisterAllEvents()
	end
	return true
end

-- revive a previously killed frame
-- @usage LMP:Revive(object, [silent], [events])
-- @param object <table, string> frame, fontstring or texture to hide
-- @param silent <boolean, nil> 'true' to return 'false' instead of producing an error for non existing objects
-- @param events <string, nil> list of events to register to the frame
function lib:Revive(object, silent, ...)
	argcheck(object, 1, "string", "table")
	argcheck(silent, 2, "boolean", "nil")
	if type(object) == "string" then
		if silent and not _G[object] then
			return false
		end
		assert(_G[object], "Bad argument #1 to 'Revive'. No object named '"..object.."' exists.")
		object = _G[object]
	end
	if not hider[object] then
		if silent then 
			return false
		else
			assert(hider[object], "Bad argument #1 to 'Revive'. Frame has not previously been hidden by LibMediaPlus.")
		end
	end
	object:SetParent(hider[object].parent)
	object:SetShown(hider[object].isshown)
	object:ClearAllPoints()
	object:SetPoint(unpack(hider[object].point))
	if ... then
		for i = 1, select("#", ...) do
			object:RegisterEvent((select(i, ...)))
		end
	end
	hider[object] = nil
	return true
end


-- position an object
-- @usage LMP:Place(object, ...) will call object:SetPoint(...)
-- @usage LMP:Place(object, {...}) will call object:SetPoint(unpack({...}))
-- @usage LMP:Place(object, func, ...) will call object:SetPoint(func(object, ...))
function lib:Place(object, arg, ...)
	argcheck(object, 1, "string", "table")
	if type(object) == "string" then
		assert(_G[object], "Bad argument #1 to 'Place'. No object named '"..object.."' exists.")
		object = _G[object]
	end
	ClearAllPoints(object)
	if type(arg) == "table" then
		SetPoint(object, unpack(arg))
	elseif type(arg) == "function" then
		SetPoint(object, arg(object, ...))
	else
		SetPoint(object, arg, ...)
	end
end

-- Smart tooltip anchoring that takes the position on the screen into consideration
-- @usage LMP:PlaceTip(anchor,[position],[offset],[tooltip])
-- @param anchor <frame> the frame to anchor the tooltip to
-- @param position <string> fake position of the object to force a tooltip position
-- @param offset <number> optional padding 
-- @param tooltip <frame> optional tooltip frame (defaults to GameTooltip)
local padding = 6
local positions = {
	BOTTOM = { "TOP", 0, 1 },
	BOTTOMLEFT = { "TOPRIGHT", 1, 1 }, 
	BOTTOMRIGHT = { "TOPLEFT", -1, 1 },
	LEFT = { "RIGHT", 1, 0 },
	RIGHT = { "LEFT", -1, 0 },
	TOP = { "BOTTOM", 0, -1 },
	TOPLEFT = { "BOTTOMRIGHT", 1, -1 }, 
	TOPRIGHT = { "BOTTOMLEFT", -1, -1 }
}
function lib:PlaceTip(anchor, position, offset, tooltip)
	if not position or not positions[position] then
		local vertical = ((GetScreenHeight() - anchor:GetTop()) > anchor:GetBottom()) and "BOTTOM" or "TOP"
		local horizontal = ((GetScreenWidth() - anchor:GetRight()) > anchor:GetLeft()) and "LEFT" or "RIGHT"
		position = vertical .. horizontal
	end
	if not tooltip then
		tooltip = GameTooltip
	end
	if (tooltip == GameTooltip) and (GameTooltip:IsForbidden()) then
		return
	end
	tooltip:SetOwner(anchor, "ANCHOR_PRESERVE")
	tooltip:ClearAllPoints()
	tooltip:SetPoint(position, anchor, positions[position][1], positions[position][2] * (offset or padding), positions[position][3] * (offset or padding))
end

-- create a new instance of the given widgetType
-- @usage local widget = //addon//:NewWidget(widgetType, [name], parent[, ...])
-- @param widgetType <string> type of widget to create a new instance of 
-- @param name <string> unique global name of the widget instance. can be 'nil', but not omitted
-- @param parent <string,frame> the parent of the new widget instance
-- @param ... <vararg> anything else you need to pass to the widget
-- @return <table> the new widget instance
function lib:NewWidget(widgetType, name, parent, ...)
	argcheck(widgetType, 1, "string")
	argcheck(name, 2, "string", "nil")
	argcheck(parent, 3, "string", "table")
	assert(lib.widgetTypes[widgetType], "Bad argument #1 to 'NewWidget'. '"..widgetType.."' is not a valid widget type.")
	if type(name) == "string" then
		assert(not _G[name], "Bad argument #2 to 'NewWidget'. The name '"..name.."' is already in use.")
	end
	if type(parent) == "string" then
		assert(_G[parent], "Bad argument #3 to 'NewWidget'. No frame named '"..parent.."' exists.")
		parent = _G[parent]
	end
	local widget = lib.widgetTypes[widgetType](name, parent, ...)
	if not widget.GetObjectType or widget:GetObjectType() ~= widgetType then
		function widget:GetObjectType() return widgetType end
	end
	if not widget.GetName then
		function widget:GetName() return name end
	end
	return widget
end

-- safe and taint free method chaining for UI widgets
-- @usage local object = //addon//:NewChain(object)  ... :Method()  :Method() ... .__EndChain 		-- to have the objected returned
-- @usage //addon//:NewChain(object)  ... :Method()  :Method() ... :EndChain() 						-- for standalone calls
function lib:NewChain(objectOrWidget, name, parent, ...)
	argcheck(objectOrWidget, 1, "table", "string")
	local object
	if type(objectOrWidget) == "string" then
		object = self:NewWidget(objectOrWidget, name, parent, ...)
	else
		object = objectOrWidget
	end
	local new = {}
	setmetatable(new, { __index = function(self, method) 
		if method == "__EndChain" then
			return object
		elseif method == "EndChain" then
			return function() end
		end
		return function(self, ...) 
			assert(object[method], ("Method Chaining failed: No method named '%s' exists in object."):format(method))
			object[method](object, ...) 
			return self 
		end 
	end })
	return new
end

-- add a widget type to the registry
-- @usage //addon//:RegisterWidget(widgetType, func)
-- @param widgetType <string> name of the widget. must be unique, if you're creating custom widgets for your projects, include the project name 
-- @param func <func> the function to be called when creating a widget of this type. parameters should be (name, parent, ...), and return value the widget instance
function lib:RegisterWidget(widgetType, func)
	argcheck(widgetType, 1, "string")
	argcheck(func, 2, "function")
	-- as of v62 we decided to allow widgets being overwritten to work around incompatibilities with the standalone version of LibMediaPlus
	--assert(not lib.widgetTypes[widgetType], "Bad argument #1 to 'RegisterWidget'. The widget type '"..widgetType.."' already exists.")
	lib.widgetTypes[widgetType] = func
end

------------------------------------------------------------------------
--	Register Default Widget Types
------------------------------------------------------------------------
lib:RegisterWidget("StatusBar", newBarWidget)
lib:RegisterWidget("FontString", newFontWidget)

--@do-not-package@
-- local mixins = {
	-- "NewWidget",
	-- "NewChain"
-- }

-- function lib:Embed(target)
	-- for k, v in pairs(mixins) do
		-- target[v] = self[v]
	-- end
	-- self.embeds[target] = true
	-- return target
-- end

-- for target, v in pairs(lib.embeds) do
	-- lib:Embed(target)
-- end
--@end-do-not-package@