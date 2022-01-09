--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("API")

-- argCheck(value, num[, nobreak], ...)
-- 	@param value <any> the argument to check
-- 	@param num <number> the number of the argument in your function 
-- 	@param nobreak <boolean> optional. if true, then a non-breaking error will fired instead
-- 	@param ... <string,nil> list of argument types. a 'nil' value will be treated as the text 'nil'
module.argCheck = function(self, value, num, ...)
	assert(type(num) == "number", "Bad argument #2 to 'argCheck' (number expected, got " .. type(num) .. ")")
	
	local nobreak, t
	for i = 1, select("#", ...) do
		if (i == 1) and (select(i, ...) == true) then
			nobreak = true
		else
			t = select(i, ...) or "nil" -- just a little fail-safe in case I forget the quotes
			if (type(value) == t) then return end
		end
	end

	local types = strjoin(", ", ...)
	local name = strmatch(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	
	-- note on offsets:
	-- 	an offset of 2 lists the line argCheck was called from
	-- 	an offset of 3 lists the line the function argCheck was in was called from (which we use in the gUI styling API)
	if (nobreak) then
		geterrorhandler()(("Bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
	else
		error(("Bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
	end
end

module.OnInit = function(self)
	local db = gUI:GetCurrentOptionsSet() -- get the main addon settings
	local defaults = gUI:GetDefaultsForOptions() -- get the main addon defaults
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 

	local select = select
	local tonumber = tonumber
	local type = type
	local unpack = unpack
	
	local GetCVar = GetCVar

	local backdropFrames = {} -- registered backdrops
	local glowFrames = {} -- registered shadows and glows
	local textures = {} -- hidden textures
	local frames = {} -- hidden frames

	-- typical suffixes of clutter we wish to remove from frames while leaving the rest of the textures intact
	local clutter = { "Left", "Right", "Middle", "Mid", "Top", "Bottom", "TopRight", "TopLeft", "BottomLeft", "BottomRight", "Background", "BG", "Track" }

	--------------------------------------------------------------------------------------------------
	--		UI Templates
	--------------------------------------------------------------------------------------------------
	-- need some local debugging in my conversion process from v2 here. it all sucks, but only I'm supposed to use it anyway.
	local prevName, prev

	local makeBackdropFrame = function(object, inset, level)
		inset = inset or 0
		level = level or 5
		local oldLevel = object:GetFrameLevel()
		local backdropFrame = CreateFrame("Frame", nil, object)
		backdropFrame:SetPoint("TOPLEFT", object, "TOPLEFT", -inset, inset)
		backdropFrame:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", inset, -inset)
		backdropFrame:SetFrameLevel(max(oldLevel - level, 0))
		hooksecurefunc(object, "SetFrameLevel", function(object, newLevel) 
			backdropFrame:SetFrameLevel(max(newLevel - level, 0))
		end)
		return backdropFrame
	end
	
	local SetHoverScripts = function(object)
		if not(object._hasHoverScripts) then
			object.__originalRGB = { object:GetBackdropColor() }
			object.__originalBorderRGB = { object:GetBackdropBorderColor() }
			object.__originalGlossAlpha = object.Gloss and object.Gloss:GetAlpha()
			
			object:HookScript("OnEnter", function(object) 
				-- object:SetBackdropColor(0, 0, 0)
				object:SetBackdropBorderColor(C.checked.r, C.checked.g, C.checked.b)
				if (object.Gloss) then
					object.Gloss:SetAlpha(0)
				end
			end)

			object:HookScript("OnLeave", function(object)
				-- object:SetBackdropColor(unpack(object.__originalRGB))
				object:SetBackdropBorderColor(unpack(object.__originalBorderRGB))
				if (object.Gloss) then
					object.Gloss:SetAlpha(object.__originalGlossAlpha)
				end
			end)
			
			object._hasHoverScripts = true
		end
	end

	local SetShineScripts = function(object, shineAlpha, shineDuration, shineScale)
		if not(object.__hasShineEffect) then
			object.shineFrame = F.Shine:New(object, shineAlpha, shineDuration, shineScale)
			object:HookScript("OnEnter", function(self) 
				self.shineFrame:Start()
			end)
			object.__hasShineEffect = true
		end
	end

	local templates = {
		--------------------------------------------------------------------------------------------------
		--		Glows/Shadows
		--------------------------------------------------------------------------------------------------
		tinyglow = function(object, ...)
			local r, g, b, a = ...
			local glow = glowFrames[object] or makeBackdropFrame(object, 3)
			glow:SetBackdrop(M("Backdrop", "TinyGlow"))
			glow:SetBackdropBorderColor(r or 0, g or 0, b or 0, a or 0.75)
			glowFrames[object] = glow
			return glowFrames[object]
		end;

		smallglow = function(object, ...)
			local r, g, b, a = ...
			local glow = glowFrames[object] or makeBackdropFrame(object, 5)
			glow:SetBackdrop(M("Backdrop", "SmallGlow"))
			glow:SetBackdropBorderColor(r or 0, g or 0, b or 0, a or 0.75)
			glowFrames[object] = glow
			return glowFrames[object]
		end;
		
		smallindented = function(object, ...)
			local r, g, b, a = ...
			local glow = glowFrames[object] or makeBackdropFrame(object, 5-2)
			glow:SetBackdrop(M("Backdrop", "SmallGlow"))
			glow:SetBackdropBorderColor(r or 0, g or 0, b or 0, a or 0.55)
			glowFrames[object] = glow
			return glowFrames[object]
		end;

		largeglow = function(object, ...)
			local r, g, b, a = ...
			local glow = glowFrames[object] or makeBackdropFrame(object, 16)
			glow:SetBackdrop(M("Backdrop", "Glow"))
			glow:SetBackdropBorderColor(r or 0, g or 0, b or 0, a or 0.75)
			glowFrames[object] = glow
			return glowFrames[object]
		end;
		
		--------------------------------------------------------------------------------------------------
		--		Standard Backdrops
		--------------------------------------------------------------------------------------------------
		backdrop = function(object, ...)
			object:SetBackdrop(M("Backdrop", "PixelBorder-Blank"))
			object:SetBackdropColor(C.background[1], C.background[2], C.background[3], gUI:GetPanelAlpha())
			object:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
			backdropFrames[object] = object
			return backdropFrames[object]
		end;
		
		outerbackdrop = function(object, ...)
			local target, top, left, bottom, right = ...
			local border = backdropFrames[object] or makeBackdropFrame(object, 3, 1) 
			border:SetBackdrop(M("Backdrop", "PixelBorder-Blank")) -- just a border, no background
			border:SetBackdropColor(C.background[1], C.background[2], C.background[3], gUI:GetPanelAlpha())
			border:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
			border:SetPoint("TOPLEFT", target or object, "TOPLEFT", -3 + (left or 0), 3 - (top or 0))
			border:SetPoint("BOTTOMRIGHT", target or object, "BOTTOMRIGHT", 3 - (right or 0), -3 + (bottom or 0))
			backdropFrames[object] = border -- index by target object, not the borderframe
			return border
		end;
		
		simpleouterbackdrop = function(object, ...)
			local target, top, left, bottom, right = ...
			local border = backdropFrames[object] or makeBackdropFrame(object, 3, 1) 
			border:SetBackdrop(M("Backdrop", "SimpleBorder")) -- bugs out on macro tooltips and various others with our normal border texture
			border:SetBackdropColor(gUI:GetBackdropColor())
			border:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
			border:SetPoint("TOPLEFT", target or object, "TOPLEFT", -3 + (left or 0), 3 - (top or 0))
			border:SetPoint("BOTTOMRIGHT", target or object, "BOTTOMRIGHT", 3 - (right or 0), -3 + (bottom or 0))
			backdropFrames[object] = border 
			return backdropFrames[object]
		end;

		insetbackdrop = function(object, ...)
			object:SetBackdrop(M("Backdrop", "PixelBorder-Blank-Indented"))
			object:SetBackdropColor(C.background[1], C.background[2], C.background[3], gUI:GetPanelAlpha())
			object:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
			backdropFrames[object] = object
			return backdropFrames[object]
		end;
		
		--------------------------------------------------------------------------------------------------
		--		Special Backdrops
		--------------------------------------------------------------------------------------------------
		-- creates and returns a castbar backdrop with a border, and puts it around the object
		castbarwithborder = function(object, ...)
			local border = backdropFrames[object] or makeBackdropFrame(object, 3, 2) 
			border:SetBackdrop(M("Backdrop", "StatusBarBorder")) 
			border:SetBackdropColor(C.overlay[1], C.overlay[2], C.overlay[3], 0.5)
			border:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
			backdropFrames[object] = border 
			return border
		end;

		-- sets the backdrop of object to be a castbar with a border. content must be 3px indented
		castbarbackdropwithborder = function(object, ...)
			object:SetBackdrop(M("Backdrop", "StatusBarBorder")) 
			object:SetBackdropColor(C.overlay[1], C.overlay[2], C.overlay[3], 0.5) 
			object:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
			backdropFrames[object] = object 
			return backdropFrames[object]
		end;

		itembackdrop = function(object, ...)
			local target, top, left, bottom, right = ...
			local border
			if (backdropFrames[object]) then 
				border = backdropFrames[object] 
			else
				object:SetFrameLevel(object:GetFrameLevel() + 2)
				border = makeBackdropFrame(object, 3, 2) 
			end
			border:SetBackdrop(M("Backdrop", "ItemButton")) 
			border:SetBackdropColor(C.backdrop[1], C.backdrop[2], C.backdrop[3], gUI:GetPanelAlpha())
			border:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
			border:SetPoint("TOPLEFT", target or object, "TOPLEFT", -3 + (left or 0), 3 - (top or 0))
			border:SetPoint("BOTTOMRIGHT", target or object, "BOTTOMRIGHT", 3 - (right or 0), -3 + (bottom or 0))
			gUI:CreateUIShadow(border)
			backdropFrames[object] = border 
			return backdropFrames[object]
		end;
		
		--------------------------------------------------------------------------------------------------
		--		Standard Borders
		--------------------------------------------------------------------------------------------------
		simpleborder = function(object, ...)
			object:SetBackdrop(M("Backdrop", "PixelBorder"))
			object:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
			backdropFrames[object] = object
			return backdropFrames[object]
		end;
		
		border = function(object, ...)
			local target, top, left, bottom, right = ...
			local border = backdropFrames[object] or makeBackdropFrame(object, 3, -1) 
			border:SetBackdrop(M("Backdrop", "PixelBorder")) 
			border:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
			border:SetPoint("TOPLEFT", target or object, "TOPLEFT", -3 + (left or 0), 3 - (top or 0))
			border:SetPoint("BOTTOMRIGHT", target or object, "BOTTOMRIGHT", 3 - (right or 0), -3 + (bottom or 0))
			backdropFrames[object] = border 
			return border
		end;
		
		--------------------------------------------------------------------------------------------------
		--		Special Borders
		--------------------------------------------------------------------------------------------------
		targetborder = function(object, ...)
			local border = backdropFrames[object] or makeBackdropFrame(object, 0, 1) 
			border:SetBackdrop(M("Backdrop", "TargetBorder")) 
			border:SetBackdropBorderColor(C.target[1], C.target[2], C.target[3], 1)
			backdropFrames[object] = border 
			return backdropFrames[object]
		end;
		
		highlightborder = function(object, ...)
			local border = backdropFrames[object] or makeBackdropFrame(object, 0, 1) 
			border:SetBackdrop(M("Backdrop", "HighlightBorder"))
			border:SetBackdropColor(1, 1, 1, 1/3)
			border:SetBackdropBorderColor(C.target[1], C.target[2], C.target[3], 1)
			backdropFrames[object] = border 
			return backdropFrames[object]
		end;

		simplehighlightborder = function(object, ...)
			object:SetBackdrop(M("Backdrop", "HighlightBorder"))
			object:SetBackdropColor(1, 1, 1, 1/3)
			object:SetBackdropBorderColor(C.target[1], C.target[2], C.target[3], 1)
			-- object:SetFrameLevel(max(0, object:GetFrameLevel() - 1)) -- I did this in v2, not strictly sure why (?)
			backdropFrames[object] = object
			return backdropFrames[object]
		end;

		--------------------------------------------------------------------------------------------------
		--		Effects
		--------------------------------------------------------------------------------------------------
		gloss = function(object, ...)
			local target = ...
			object.Gloss = object.Gloss or object:CreateTexture()
			object.Gloss:SetDrawLayer("OVERLAY", 2)
			object.Gloss:SetTexture(M("Background", "gUI™ Gloss"))
			object.Gloss:SetVertexColor(1, 1, 1, gUI:GetGlossAlpha()) -- 1/4
			object.Gloss:SetAllPoints(target or object)
			return object.Gloss
		end;
		
		shade = function(object, ...)
			local target = ...
			object.Shade = object.Shade or object:CreateTexture()
			object.Shade:SetDrawLayer("OVERLAY", 1)
			object.Shade:SetTexture(M("Background", "gUI™ Shade"))
			object.Shade:SetVertexColor(0, 0, 0, gUI:GetShadeAlpha()) -- 1/4
			object.Shade:SetAllPoints(target or object)
			return object.Shade
		end;
		
		--------------------------------------------------------------------------------------------------
		--		The old element skinner templates
		--------------------------------------------------------------------------------------------------
		button = function(object, strip, shine, shineAlpha, shineDuration, shineScale)
			if (strip) then 
				gUI:DisableTextures(object) 
			end

			local r, g, b = gUI:GetBackdropColor()
			gUI:SetUITemplate(object, "backdrop"):SetBackdropColor(r, g, b, gUI:GetOverlayAlpha())

			if not (object.Gloss) then
				local gloss = gUI:SetUITemplate(object, "gloss")
				gloss:ClearAllPoints()
				gloss:SetPoint("TOPLEFT", 3, -3)
				gloss:SetPoint("BOTTOMRIGHT", -3, 3)
				object.Gloss = gloss
			end

			local text = object.text or object:GetName() and _G[object:GetName() .. "Text"]
			if (text) and (text.SetFontObject) then
				text:SetFontObject(gUI_TextFontSmall)
				text:SetJustifyH("CENTER")
				object:SetNormalFontObject(gUI_TextFontSmall)
				object:SetHighlightFontObject(gUI_TextFontSmallWhite)
				object:SetDisabledFontObject(gUI_TextFontSmallDisabled)
			end
			
			if (object:GetName()) then
				local l = _G[object:GetName() .. "Left"]
				local m = _G[object:GetName() .. "Middle"]
				local r = _G[object:GetName() .. "Right"]
				if (l) then l:SetAlpha(0) end
				if (m) then m:SetAlpha(0) end
				if (r) then r:SetAlpha(0) end
			end

			if (object.SetNormalTexture) then object:SetNormalTexture("") end
			if (object.SetHighlightTexture) then object:SetHighlightTexture("") end
			if (object.SetPushedTexture) then object:SetPushedTexture("") end
			if (object.SetDisabledTexture) then object:SetDisabledTexture("") end
			
			SetHoverScripts(object)
			
			if (shine) then
				SetShineScripts(object, shineAlpha, shineDuration, shineScale)
			end
			
			return object
		end;

		insetbutton = function(object, strip, shine, shineAlpha, shineDuration, shineScale)
			if (strip) then 
				gUI:DisableTextures(object) 
			end

			local r, g, b = gUI:GetBackdropColor()
			gUI:SetUITemplate(object, "insetbackdrop"):SetBackdropColor(r, g, b, gUI:GetOverlayAlpha())
			
			if not (object.Gloss) then
				local gloss = gUI:SetUITemplate(object, "gloss")
				gloss:ClearAllPoints()
				gloss:SetPoint("TOPLEFT", 5, -5)
				gloss:SetPoint("BOTTOMRIGHT", -5, 5)
				object.Gloss = gloss
			end

			local text = object.text or object:GetName() and _G[object:GetName() .. "Text"]
			if (text) and (text.SetFontObject) then
				text:SetFontObject(gUI_TextFontSmall)
				text:SetJustifyH("CENTER")
				object:SetNormalFontObject(gUI_TextFontSmall)
				object:SetHighlightFontObject(gUI_TextFontSmallWhite)
				object:SetDisabledFontObject(gUI_TextFontSmallDisabled)
			end

			if (object:GetName()) then
				local l = _G[object:GetName() .. "Left"]
				local m = _G[object:GetName() .. "Middle"]
				local r = _G[object:GetName() .. "Right"]
				
				if (l) then l:SetAlpha(0) end
				if (m) then m:SetAlpha(0) end
				if (r) then r:SetAlpha(0) end
			end

			if (object.SetNormalTexture) then object:SetNormalTexture("") end
			if (object.SetHighlightTexture) then object:SetHighlightTexture("") end
			if (object.SetPushedTexture) then object:SetPushedTexture("") end
			if (object.SetDisabledTexture) then object:SetDisabledTexture("") end
			
			SetHoverScripts(object)

			if (shine) then
				SetShineScripts(object, shineAlpha, shineDuration, shineScale)
			end
			
			return object
		end;

		tab = function(object, strip, shine, shineAlpha, shineDuration, shineScale)
			if (strip) then 
				gUI:DisableTextures(object) 
			end

			local backdrop = gUI:SetUITemplate(object, "outerbackdrop", nil, 5, 12, 5, 12)

			local text = object.text or object:GetName() and _G[object:GetName() .. "Text"]
			-- if (text) and (text.SetFontObject) then
				-- text:SetFontObject(gUI_TextFontSmall)
				-- object:SetNormalFontObject(gUI_TextFontSmall)
				-- object:SetHighlightFontObject(gUI_TextFontSmallWhite)
				-- object:SetDisabledFontObject(gUI_TextFontSmallDisabled)
				
				-- not strictly happy with this, but it avoids taint, if nothing else
				--[[
				hooksecurefunc("PanelTemplates_SelectTab = function(tab) 
					if (tab == object) then
						tab:SetDisabledFontObject(GUIS_SystemFontSmallHighlight)
					end
				end)
				
				hooksecurefunc("PanelTemplates_SetDisabledTabState = function(tab) 
					if (tab == object) then
						tab:SetDisabledFontObject(GUIS_SystemFontSmallDisabled)
					end
				end)
				]]--
			-- end

			if (object:GetName()) then
				local l = _G[object:GetName() .. "Left"]
				local m = _G[object:GetName() .. "Middle"]
				local r = _G[object:GetName() .. "Right"]
				local ld = _G[object:GetName() .. "LeftDisabled"]
				local md = _G[object:GetName() .. "MiddleDisabled"]
				local rd = _G[object:GetName() .. "RightDisabled"]
				
				if (l) then l:SetAlpha(0) end
				if (m) then m:SetAlpha(0) end
				if (r) then r:SetAlpha(0) end
				if (ld) then ld:SetAlpha(0) end
				if (md) then md:SetAlpha(0) end
				if (rd) then rd:SetAlpha(0) end
			end

			if (object.SetNormalTexture) then object:SetNormalTexture("") end
			if (object.SetHighlightTexture) then object:SetHighlightTexture("") end
			if (object.SetPushedTexture) then object:SetPushedTexture("") end
			if (object.SetDisabledTexture) then object:SetDisabledTexture("") end
			
			SetHoverScripts(object)

			if (shine) then
				SetShineScripts(object, shineAlpha, shineDuration, shineScale)
			end
			
			return object
		end;

		scrollbar = function(object, strip)
			-- gUI:DisableTextures(object)
			gUI:RemoveClutter(object)
			
			local name = object:GetName()
			if (name) then
				if (_G[name .. "ScrollDownButton"]) then
					gUI:SetUITemplate(_G[name .. "ScrollDownButton"], "arrow", "down")
					_G[name .. "ScrollDownButton"]:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
					_G[name .. "ScrollDownButton"]:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
					_G[name .. "ScrollDownButton"]:GetDisabledTexture():SetTexCoord(0, 1, 0, 1)
					_G[name .. "ScrollDownButton"]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
				end

				if (_G[name .. "ScrollUpButton"]) then
					gUI:SetUITemplate(_G[name .. "ScrollUpButton"], "arrow", "up")
					_G[name .. "ScrollUpButton"]:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
					_G[name .. "ScrollUpButton"]:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
					_G[name .. "ScrollUpButton"]:GetDisabledTexture():SetTexCoord(0, 1, 0, 1)
					_G[name .. "ScrollUpButton"]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
				end
				
				if (_G[name .. "ThumbTexture"]) then
					_G[name .. "ThumbTexture"]:SetTexture(gUI:GetBlankTexture(), 1) 
					_G[name .. "ThumbTexture"]:SetVertexColor(C["disabled"][1], C["disabled"][2], C["disabled"][3], 1) 
					_G[name .. "ThumbTexture"]:SetWidth(_G[name .. "ThumbTexture"]:GetWidth() - 8)
					-- _G[name .. "ThumbTexture"]:SetHeight(_G[name .. "ThumbTexture"]:GetHeight() - 8)
					
					gUI:CreateUIShadow(object)
					gUI:GetUIShadow(object):ClearAllPoints()
					gUI:GetUIShadow(object):SetPoint("TOPLEFT", _G[name .. "ThumbTexture"], "TOPLEFT", -3, 3)
					gUI:GetUIShadow(object):SetPoint("BOTTOMRIGHT", _G[name .. "ThumbTexture"], "BOTTOMRIGHT", 3, -3)
				end
			end
			
			for i = 1, object:GetNumRegions() do
				local region = select(i, object:GetRegions())
				
				if (region:GetName()) and ((region:GetName():find("Up")) or (region:GetName():find("Down"))) then
					gUI:SetUITemplate(region, "arrow")
					region:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
					region:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
					region:GetDisabledTexture():SetTexCoord(0, 1, 0, 1)
					region:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
				end
			end
			
			for v = 1, object:GetNumChildren() do
				local child = select(v, object:GetChildren())
				
				for i = 1, child:GetNumRegions() do
					local region = select(i, child:GetRegions())
					
					if (region:GetName()) and ((region:GetName():find("Up")) or (region:GetName():find("Down"))) then
						gUI:SetUITemplate(region, "arrow")
						region:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
						region:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
						region:GetDisabledTexture():SetTexCoord(0, 1, 0, 1)
						region:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
					end
				end
			end
			
			return object
		end;

		slider = function(object, orientation)
			gUI:SetUITemplate(object, "insetbackdrop")
			-- object.SetBackdrop = noop
			return object
		end;

		closebutton = function(object, ...)
			object:SetNormalTexture(M("Button", "gUI™ CloseButton"))
			object:SetPushedTexture(M("Button", "gUI™ CloseButtonDown"))
			object:SetHighlightTexture(M("Button", "gUI™ CloseButtonHighlight"))
			object:SetDisabledTexture(M("Button", "gUI™ CloseButtonDisabled"))

			object:SetSize(16, 16)

			if (...) then
				local a, b, c, d, e, f = ...
				
				if (a == true) then
					-- object.SetNormalTexture = noop
					-- object.SetPushedTexture = noop
					-- object.SetHighlightTexture = noop
					-- object.SetDisabledTexture = noop
					
					if (b) then
						object:ClearAllPoints()
						object:SetPoint(b, c, d, e, f)
					end
				else
					object:ClearAllPoints()
					object:SetPoint(a, b, c, d, e)
				end
			else
				local point, anchor, relpoint, x, y = object:GetPoint()
				if (point) then
					object:ClearAllPoints()
					object:SetPoint(point, anchor, relpoint, x-8, y-8)
				end
			end
			
			return object
		end;

		radiobutton = function(object, strip)
			if (strip) then 
				gUI:DisableTextures(object) 
			end

			gUI:SetUITemplate(object, "backdrop"):SetBackdropColor(nil, nil, nil, gUI:GetOverlayAlpha())
			
			local name = object:GetName()
			local text = object.text or name and _G[name .. "Text"]
			-- if (text) and (text.SetFontObject) then
				-- text:SetFontObject(gUI_TextFontSmall)
				-- object:SetNormalFontObject(gUI_TextFontSmall)
				-- object:SetHighlightFontObject(gUI_TextFontSmallWhite)
				-- object:SetDisabledFontObject(gUI_TextFontSmallDisabled)
			-- end

			if (object.SetCheckedTexture) then
				object:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
				
				object:GetCheckedTexture():SetDrawLayer("OVERLAY")
				object:GetCheckedTexture():SetTexCoord(0, 1, 0, 1)
				-- object:GetCheckedTexture().SetTexCoord = noop
			end
			
			if (object.SetDisabledTexture) then
				object:SetDisabledTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")

				object:GetDisabledTexture():SetDrawLayer("OVERLAY")
				object:GetDisabledTexture():SetTexCoord(0, 1, 0, 1)
				-- object:GetDisabledTexture().SetTexCoord = noop
			end
			
			if (object.SetHighlightTexture) then
				local highlight = object:CreateTexture(nil, "OVERLAY")
				highlight:ClearAllPoints()
				highlight:SetPoint("TOPLEFT", object, "TOPLEFT", 2, -2)
				highlight:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", -2, 2)
				highlight:SetTexture(C["index"][1], C["index"][2], C["index"][3], 1/4)

				object:SetHighlightTexture(highlight)

				if (name) then
					_G[name .. "Highlight"] = highlight
				end
			end
			
			-- object.SetDisabledTexture = noop	
			-- object.SetNormalTexture = noop
			-- object.SetPushedTexture = noop
			-- object.SetHighlightTexture = noop
			
			return object
		end;

		-- jumping through hoops to make this nonsense compatible with ScrollFrames
		dropdown = function(object, strip, width)
			if (strip) then
				if (strip == true) then
					gUI:DisableTextures(object)
				end
				
				if (tonumber(strip)) and (tonumber(strip) > 0) then
					width = strip
				end
			end
			
			local button = _G[object:GetName() .. "Button"]
			local text = _G[object:GetName() .. "Text"]

			if (width) then
				object:SetWidth(width)
				-- object.SetWidth = noop
				-- object.SetHeight = noop
				-- object.SetSize = noop
			end
			
			gUI:SetUITemplate(object, "insetbackdrop", button):SetBackdropColor(nil, nil, nil, gUI:GetOverlayAlpha())
			gUI:SetUITemplate(button, "arrow", "down")
			
			text:ClearAllPoints()
			text:SetPoint("RIGHT", button:GetNormalTexture(), "LEFT", 0, 0)
			text:SetPoint("LEFT", object, "LEFT", 8, 0)
			-- text:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
			text:SetJustifyV("MIDDLE")
			-- text.ClearAllPoints = noop
			-- text.SetPoint = noop
			
			text:SetParent(button)
			text:SetDrawLayer("OVERLAY")
			-- text:SetFontObject(gUI_TextFontSmallWhite)
			
			button:ClearAllPoints()
			button:SetPoint("RIGHT", object, "RIGHT", -4, 0)
			button:SetPoint("LEFT", object, "LEFT", 4, 0)
			button:SetPoint("TOP", object, "TOP", 0, -2)
			button:SetPoint("BOTTOM", object, "BOTTOM", 0, 2)
			-- button.ClearAllPoints = noop
			-- button.SetAllPoints = noop
			-- button.SetPoint = noop
			
			return button
		end;

		checkbutton = function(object, ...)
			gUI:DisableTextures(object, object:GetCheckedTexture())
			gUI:SetUITemplate(object, "insetbackdrop")
			
			local text = object.text or object:GetName() and _G[object:GetName() .. "Text"]
			-- if (text) and (text.SetFontObject) then
				-- text:SetFontObject(gUI_TextFontSmall)
				-- object:SetNormalFontObject(gUI_TextFontSmall)
				-- object:SetHighlightFontObject(gUI_TextFontSmallWhite)
				-- object:SetDisabledFontObject(gUI_TextFontSmallDisabled)
			-- end

			if (object.SetCheckedTexture) and (object.GetCheckedTexture) then
				object:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
				local t = object:GetCheckedTexture()
				if (t) then
					t:SetTexCoord(0, 1, 0, 1)
					-- t.SetTexCoord = noop
					t:SetPoint("TOPLEFT", -3, 3)
					t:SetPoint("BOTTOMRIGHT", 3, -3)
					t:SetParent(object)
					t:SetDrawLayer("OVERLAY", 7)
				end
			end
			
			if (object.SetDisabledTexture) and (object.GetDisabledTexture) then
				object:SetDisabledTexture("")
				local t = object:GetDisabledTexture()
				if (t) then
					t:SetTexCoord(0, 1, 0, 1)
					-- t.SetTexCoord = noop
				end
			end

			if (object.SetDisabledCheckedTexture) and (object.GetDisabledCheckedTexture) then
				object:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
				local t = object:GetDisabledCheckedTexture()
				if (t) then
					t:SetTexCoord(0, 1, 0, 1)
					-- t.SetTexCoord = noop
				end
			end
			
			if (object.SetHighlightTexture) then
				local highlight = object:CreateTexture()
				highlight:SetDrawLayer("OVERLAY")
				highlight:ClearAllPoints()
				highlight:SetPoint("TOPLEFT", object, "TOPLEFT", 5, -5)
				highlight:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", -5, 5)
				highlight:SetTexture(C["index"][1], C["index"][2], C["index"][3], 1/4)
				object:SetHighlightTexture(highlight)
				if (object:GetName()) then
					_G[object:GetName() .. "Highlight"] = highlight
				end
			end
			
			-- object.SetNormalTexture = noop
			-- object.SetPushedTexture = noop
			-- object.SetHighlightTexture = noop
			
			return object
		end;

		editbox = function(object, top, left, bottom, right, textTop, textLeft, textBottom, textRight)
			gUI:RemoveClutter(object)
			
			object:SetFrameLevel(object:GetFrameLevel() + 1)

			local backdrop = gUI:SetUITemplate(object, "outerbackdrop")
			backdrop:ClearAllPoints()
			backdrop:SetPoint("TOPLEFT", object, "TOPLEFT", -3 + (left or 0), 2 + (top or 0))
			backdrop:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", 3+ (right or 0), -2 + (bottom or 0))

			if (object.SetFontObject) then
				object:SetFontObject(gUI_TextFontNormalWhite)
			end

			local name = object:GetName()
			if (name) then
				if ((name:find("Silver")) or (name:find("Copper"))) then
					backdrop:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", -12, -2 + (bottom or 0))
				end
				local header = _G[name.."Header"]
				if (header) then
					header:SetFontObject(gUI_TextFontNormalWhite)
				end
			end
			
			if (textTop) or (textLeft) or (textBottom) or (textRight) then
				object:SetTextInsets(textLeft or 0, textRight or 0, textTop or 0, textBottom or 0)
			end
			
			return backdrop
		end;

		statusbar = function(object, border)
			gUI:DisableTextures(object, object:GetStatusBarTexture())
			
			if (border) then
				local backdrop = gUI:SetUITemplate(object, "border")
			end

			object:SetStatusBarTexture(gUI:GetStatusBarTexture())
			gUI:SetUITemplate(object, "gloss")
			-- gUI:SetUITemplate(object, "shade")
			
			-- local name = object:GetName()

			-- local text = object.text or name and _G[name .. "Text"]
			-- if (text) and (text.SetFontObject) then
				-- text:SetFontObject(gUI_DisplayFontSmallOutlineWhite)
			-- end

			-- local title = object.title or name and _G[name .. "Title"]
			-- if (title) and (title.SetFontObject) then
				-- title:SetFontObject(gUI_DisplayFontSmallOutlineWhite)
			-- end

			-- local label = object.label or name and _G[name .. "Label"]
			-- if (label) and (label.SetFontObject) then
				-- label:SetFontObject(gUI_DisplayFontSmallOutlineWhite)
			-- end
			
			return object
		end;

		-- to avoid taint, we need to STOP replacing blizzard methods
		arrow = function(object, direction, ...)
			local fileName, isPlusMinus, isPrevNext
			if not(direction) then
				local name = (object.GetName) and (object:GetName())
				if (name:find("Collapse")) or (name:find("Toggle")) then 
					fileName = (normal and normal:find("Plus")) and "Down" or "Up"
					isPlusMinus = true
				elseif (name:find("Expand")) then 
					fileName = (normal and normal:find("Prev")) and "Left" or "Right"
					isPrevNext = true
				elseif (name:find("Prev")) or (name:find("Left")) or (name:find("Dec")) then fileName = "Left"
				elseif (name:find("Next")) or (name:find("Right")) or (name:find("Inc")) then fileName = "Right"
				elseif (name:find("Up")) then fileName = "Up"
				elseif (name:find("Down")) then fileName = "Down"
				elseif (name:find("Top")) then fileName = "Top"
				elseif (name:find("Bottom")) then fileName = "Bottom"
				elseif (name:find("First")) then fileName = "First"
				elseif (name:find("Last")) then fileName = "Last" 
				end
			else
				if (direction == "left") then fileName = "Left"
				elseif (direction == "right") then fileName = "Right"
				elseif (direction == "up") then fileName = "Up"
				elseif (direction == "down") then fileName = "Down"
				elseif (direction == "top") then fileName = "Top"
				elseif (direction == "bottom") then fileName = "Bottom"
				elseif (direction == "first") then fileName = "First"
				elseif (direction == "collapse") then 
					fileName = (normal and normal:find("Plus")) and "Down" or "Up"
					isPlusMinus = true
				elseif (direction == "expand") then 
					fileName = (normal and normal:find("Prev")) and "Left" or "Right"
					isPrevNext = true
				elseif (direction == "last") then fileName = "Last"
				end
			end

			if not(fileName) then
				return
			end
			
			-- togglebuttons are handled differently, due to their changing textures
			-- the v2 version of this causes taint now, so we have to do it... an uglier way
			-- ToDo: make a texture to replace the blizzard arrow- and plusminus textures, that matches the original texcoords perfectly
			if (isPlusMinus) or (isPrevNext) then
				local backdrop = gUI:SetUITemplate(object, "outerbackdrop", object:GetNormalTexture())
				local gloss = gUI:SetUITemplate(object, "gloss", object:GetNormalTexture())
				local shade = gUI:SetUITemplate(object, "shade", object:GetNormalTexture())
				if (isPlusMinus) then
					object:GetNormalTexture():SetSize(object:GetNormalTexture():GetWidth() - 6, object:GetNormalTexture():GetHeight() - 6)
					object:GetNormalTexture():ClearAllPoints()
					object:GetNormalTexture():SetPoint("TOPLEFT", object, "TOPLEFT", 3, -3)
					local toggleVisibility = function(self, tex)
						if not(tex) or (tex == "") then
							backdrop:Hide()
							gloss:Hide()
							shade:Hide()
						else
							backdrop:Show()
							gloss:Show()
							shade:Show()
						end
					end
					hooksecurefunc(object, "SetNormalTexture", toggleVisibility)
					object:GetNormalTexture():SetTexCoord(0.3, 0.29, 0.3, 0.8, 0.65, 0.29, 0.65, 0.8)
					if (object:GetPushedTexture()) then
						object:GetPushedTexture():SetTexCoord(0.3, 0.35, 0.3, 0.8, 0.65, 0.35, 0.65, 0.8)
						object:GetPushedTexture():SetAllPoints(object:GetNormalTexture())
					end
					if (object:GetDisabledTexture()) then
						object:GetDisabledTexture():SetTexCoord(0.3, 0.29, 0.3, 0.75, 0.65, 0.29, 0.65, 0.75)
						object:GetDisabledTexture():SetAllPoints(object:GetNormalTexture())
					end
				end
				if (isPrevNext) then
					object:GetNormalTexture():SetSize(object:GetWidth() - 6, object:GetHeight() - 6)
					object:GetNormalTexture():ClearAllPoints()
					object:GetNormalTexture():SetPoint("TOPLEFT", object, "TOPLEFT", 3, -3)
					object:GetNormalTexture():SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", -3, 3)
					object:GetNormalTexture():SetTexCoord(0.3, 0.29, 0.3, 0.72, 0.65, 0.29, 0.65, 0.72)
					if (object:GetPushedTexture()) then
						object:GetPushedTexture():SetTexCoord(0.3, 0.35, 0.3, 0.8, 0.65, 0.35, 0.65, 0.8)
						object:GetPushedTexture():SetAllPoints(object:GetNormalTexture())
					end
					if (object:GetDisabledTexture()) then
						object:GetDisabledTexture():SetTexCoord(0.3, 0.29, 0.3, 0.75, 0.65, 0.29, 0.65, 0.75)	
						object:GetDisabledTexture():SetAllPoints(object:GetNormalTexture())
					end
				end
				if (object:GetHighlightTexture()) then
					object:GetHighlightTexture():SetTexture(1, 1, 1, 0.3)
					object:GetHighlightTexture():SetAllPoints(object:GetNormalTexture())
				end
			else
				-- static arrows can use our own much better looking textures
				gUI:DisableTextures(object, object:GetNormalTexture(), object:GetPushedTexture(), object:GetHighlightTexture(), object:GetDisabledTexture())
				object:SetNormalTexture(M("Button", "gUI™ Arrow" .. fileName))
				object:SetPushedTexture(M("Button", "gUI™ Arrow" .. fileName))
				object:SetHighlightTexture(M("Button", "gUI™ Arrow" .. fileName .. "Highlight"))
				object:SetDisabledTexture(M("Button", "gUI™ Arrow" .. fileName .. "Disabled"))
			end
			if (...) then
				object:ClearAllPoints()
				object:SetPoint(...)
			end
			return object
		end;
	}
	
	-- same rules as in v2 apply;
	-- 	*the function must not create duplicate items
	-- 	*the function must return an object which responds to backdrop commands
	gUI.RegisterUITemplate = function(self, name, func)
		if not(templates[name]) then
			templates[name] = func
		end
	end
	
	gUI.SetUITemplate = function(self, object, template, ...)
		module:argCheck(object, 1, "table")
		module:argCheck(template, 2, "string")
		if not(object:IsObjectType("Frame")) then
			error(("Expected a Frame, got '%s'"):format(object:GetObjectType()), 2)
		end
		return templates[template](object, ...)
	end
	
	gUI.GetUITemplate = function(self, object)
		module:argCheck(object, 1, "table")
		return backdropFrames[object]
	end

	--------------------------------------------------------------------------------------------------
	--		Media Removal API 
	--------------------------------------------------------------------------------------------------
	local tex = UIParent:CreateTexture() -- just for... stuff
	gUI.HideTexture = function(self, texture)
		module:argCheck(texture, 1, "table")
		if not(texture:GetObjectType() == "Texture") then
			error(("Expected a Texture, got '%s'"):format(texture:GetObjectType()), 2)
		end
		if not(textures[texture]) then
			textures[texture] = texture:GetTexture()
			texture:SetTexture("")
			texture:SetAlpha(0)
		end
	end

	gUI.KillTexture = function(self, texture)
		module:argCheck(texture, 1, "table")
		if not(texture:GetObjectType() == "Texture") then
			error(("Expected a Texture, got '%s'"):format(texture:GetObjectType()), 2)
		end
		if not(textures[texture]) then
			textures[texture] = texture:GetTexture()
			texture:SetTexture("")
			texture.SetTexture = self.noop
		end
	end

	gUI.ShowTexture = function(self, texture)
		if (textures[texture]) then
			-- texture.SetTexture = tex.SetTexture
			texture:SetTexture(textures[texture])
			texture:SetAlpha(1)
			textures[texture] = nil
		end
	end

	-- textures that won't be disabled
	local whiteList = {
		"GetNormalTexture",
		"GetPushedTexture",
		"GetHighlightTexture",
		"GetDisabledTexture",
		"GetStatusBarTexture",
		"GetCheckedTexture"
	}
	gUI.DisableTextures = function(self, object, ...)
		module:argCheck(object, 1, "table")
		if not(object:IsObjectType("Frame")) then
			error(("Expected a Frame, got '%s'"):format(object:GetObjectType()), 2)
		end
		local region
		for i = 1, object:GetNumRegions() do
			region = select(i, object:GetRegions())
			if (region:GetObjectType() == "Texture") then
				local next, found
				if (...) then
					for i = 1, select("#", ...) do
						next = select(i, ...)
						if (next) then
							if (type(next) == "string") then
								if (_G[next]) and (region == _G[next]) then
									found = true
									break
								end
							else
								if (region == next) then
									found = true
								end
							end
						end
					end
				end
				-- for _,method in pairs(whiteList) do
					-- if (object[method]) then
						-- if (region == object[method](object)) then
							-- found = true
						-- end
					-- end
				-- end
				if not(found) then
					self:HideTexture(region)
				end
			end
		end
	end

	gUI.EnableTextures = function(self, object)
		local region
		for i = 1, object:GetNumRegions() do
			region = select(i, object:GetRegions())
			if (region:GetObjectType() == "Texture") then
				self:ShowTexture(region)
			end
		end
	end

	gUI.RemoveClutter = function(self, object)
		if not(object) or not(object.GetName) or not(object:GetName()) then
			return
		end
		
		local t
		for i,v in pairs(clutter) do
			t = _G[object:GetName() .. v]
			if (t) then
				self:KillObject(t)
			end
		end
	end
	
	gUI.HideFrame = function(self, frame)
		if not(frames[frame]) then
			frames[frame] = frame:GetParent()
			frame:SetParent(self:GetAttribute("dummy"))
		end
	end
	
	gUI.ShowFrame = function(self, frame)
		if (frames[frame]) then
			frame:SetParent(frames[frame])
			frames[frame] = nil
		end
	end
	
	gUI.HideObject = function(self, object)
		local type = object:GetObjectType()
		local isFrame = object:IsObjectType("Frame")
		if (type == "Texture") then
			self:HideTexture(object)
		elseif (isFrame) then
			self:HideFrame(object)
		end
	end
	
	gUI.HideObjects = function(self, ...)
		for i = 1, select("#", ...) do
			self:HideObject(select(i, ...))
		end
	end

	gUI.ShowObject = function(self, object)
		local type = object:GetObjectType()
		local isFrame = object:IsObjectType("Frame")
		if (type == "Texture") then
			self:ShowTexture(object)
		elseif (isFrame) then
			self:ShowFrame(object)
		end
	end
	
	gUI.ShowObjects = function(self, ...)
		for i = 1, select("#", ...) do
			self:ShowObject(select(i, ...))
		end
	end

	gUI.KillObject = function(self, object)
		module:argCheck(object, 1, "table")
		if (object.UnregisterAllEvents) then
			object:UnregisterAllEvents()
		end
		self:HideFrame(object)
	end
	
	gUI.KillTextures = function(self, object, ...)
		module:argCheck(object, 1, "table")
		if not(object:IsObjectType("Frame")) then
			error(("Expected a Frame, got '%s'"):format(object:GetObjectType()), 2)
		end
		local region
		for i = 1, object:GetNumRegions() do
			region = select(i, object:GetRegions())
			if (region:GetObjectType() == "Texture") then
				local next, found
				if (...) then
					for i = 1, select("#", ...) do
						next = select(i, ...)
						if (next) then
							if (type(next) == "string") then
								if (_G[next]) and (region == _G[next]) then
									found = true
									break
								end
							else
								if (region == next) then
									found = true
								end
							end
						end
					end
				end
				-- for _,method in pairs(whiteList) do
					-- if (object[method]) then
						-- if (region == object[method](object)) then
							-- found = true
						-- end
					-- end
				-- end
				if not(found) then
					self:KillTexture(region)
				end
			end
		end
	end
	
	-- change a cvar, but only if it's not already the value we want
	-- we do this to avoid firing off hooks related to SetCVar when not needed
	gUI.SetCVar = function(self, cvar, value)
		local c
		if (type(value) == "number") then
			c = tonumber(GetCVar(cvar))
		else
			c = GetCVar(cvar)
		end
		if (c ~= value) then
			_G.SetCVar(cvar, value)
		end
	end
	
	-- remove an entire blizzard options panel, 
	-- and disable its automatic cancel/okay functionality
	-- this is needed, or the option will be reset when the menu closes
	-- it is also a major source of taint related to the Compact group frames!
	gUI.KillPanel = function(self, i, panel)
		if (i) then
			local cat = _G["InterfaceOptionsFrameCategoriesButton" .. i]
			if (cat) then
				cat:SetScale(0.00001)
				cat:SetAlpha(0)
			end
		end
		if (panel) then
			self:KillObject(panel)
			panel.cancel = self.noop
			panel.okay = self.noop
			panel.refresh = self.noop
		end
	end
	
	-- remove a blizzard menu option, 
	-- and disable its automatic cancel/okay functionality
	-- this is needed, or the option will be reset when the menu closes
	-- it is also a major source of taint related to the Compact group frames!
	gUI.KillOption = function(self, shrink, option)
		if not(option) or not(option.IsObjectType) or not(option:IsObjectType("Frame")) then
			return
		end
		self:KillObject(option)
		if (shrink) then
			option:SetHeight(0.00001)
		end
		option.cvar = ""
		option.uvar = ""
		option.value = nil
		option.oldValue = nil
		option.defaultValue = nil
		option.setFunc = self.noop
	end
	
	--------------------------------------------------------------------------------------------------
	--		Media Creation API
	--------------------------------------------------------------------------------------------------
	gUI.CreateUIShadow = function(self, object, size, r, g, b, a)
		module:argCheck(object, 1, "table")
		module:argCheck(r, 2, "number", "nil")
		module:argCheck(g, 3, "number", "nil")
		module:argCheck(b, 4, "number", "nil")
		module:argCheck(a, 5, "number", "nil")
		if (size == "larger") then
			return templates["smallglow"](object, r, g, b, a)
		else
			return templates["tinyglow"](object, r, g, b, a)
		end
	end
	
	gUI.SetUIShadowColor = function(self, object, r, g, b, a)
		module:argCheck(object, 1, "table")
		module:argCheck(r, 2, "number", "nil")
		module:argCheck(g, 3, "number", "nil")
		module:argCheck(b, 4, "number", "nil")
		module:argCheck(a, 5, "number", "nil")
		if (glowFrames[object]) then
			local oldR, oldG, oldB, oldA = glowFrames[object]:GetBackdropBorderColor()
			glowFrames[object]:SetBackdropBorderColor(r or oldR or 0, g or oldG or 0, b or oldB or 0, a or oldA or 0.75)
		end
	end
	
	gUI.GetUIShadow = function(self, object)
		module:argCheck(object, 1, "table")
		return glowFrames[object]
	end

	gUI.CreateHighlight = function(self, object, top, left, bottom, right)
		local highlight = object:CreateTexture(nil, "OVERLAY")
		highlight:ClearAllPoints()
		highlight:SetPoint("TOPLEFT", object, "TOPLEFT", (left or 0), (top or 0))
		highlight:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", (right or 0), (bottom or 0))
		highlight:SetTexture(C["index"][1], C["index"][2], C["index"][3], 1/3)
		object:SetHighlightTexture(highlight)
		
		local name = object:GetName()
		if (name) then
			_G[name .. "Highlight"] = highlight
		end
		
		return object:GetHighlightTexture()
	end

	gUI.CreateChecked = function(self, object, top, left, bottom, right)
		local checked = object:CreateTexture(nil, "OVERLAY")
		checked:ClearAllPoints()
		checked:SetPoint("TOPLEFT", object, "TOPLEFT", (left or 0), (top or 0))
		checked:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", (right or 0), (bottom or 0))
		checked:SetTexture(C["index"][1], C["index"][2], C["index"][3], 1/2)
		object:SetCheckedTexture(checked)
		
		local name = object:GetName()
		if (name) then
			_G[name .. "Checked"] = checked
		end

		return checked
	end

	gUI.CreatePushed = function(self, object, top, left, bottom, right)
		local pushed = object:CreateTexture(nil, "OVERLAY")
		pushed:ClearAllPoints()
		pushed:SetPoint("TOPLEFT", object, "TOPLEFT", (left or 0), (top or 0))
		pushed:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", (right or 0), (bottom or 0))
		pushed:SetTexture(C["value"][1], C["value"][2], C["value"][3], 1/4)
		object:SetPushedTexture(pushed)
		
		local name = object:GetName()
		if (name) then
			_G[name .. "Pushed"] = pushed
		end
		
		return object:GetPushedTexture()
	end

	--------------------------------------------------------------------------------------------------
	--		Media API 
	--------------------------------------------------------------------------------------------------
	-- this seems a bit backwards. but oh well.
	gUI.GetBackgroundColor = function(self)
		return unpack(C.backdrop)
	end

	gUI.GetBackdropColor = function(self)
		return unpack(C.background)
	end

	gUI.GetBackdropBorderColor = function(self)
		return unpack(C.border)
	end

	gUI.GetPanelAlpha = function(self)
		return db.panelAlpha -- 0.75
	end
	
	-- blizzard keeps modifying alpha- and color values, 
	-- so 0.75 turns into 0.74901796225458.... 
	local correctValue = function(v)
		return floor((v*100 + 0.5))/100
	end
	
	local maxAlpha, minAlpha = 1, 0.6 -- keep the alpha above the overlayalpha, to avoid chaos. for now.
	gUI.SetPanelAlpha = function(self, alpha)
		self:argCheck(alpha, 1, "number")
		local new = max(minAlpha, min(maxAlpha, alpha))
		local old = self:GetPanelAlpha()
		local r, g, b, a
		for i,v in pairs(backdropFrames) do
			r, g, b, a = v:GetBackdropColor()
			if (correctValue(a) == correctValue(old)) then 
				v:SetBackdropColor(r, g, b, correctValue(new))
			end
		end
		db.panelAlpha = correctValue(new)
	end
	
	gUI.GetOverlayAlpha = function(self)
		return 0.3
	end

	gUI.GetShadeAlpha = function(self, dark)
		return 0.5 -- dark and 0.66 or 0.1 -- 0.5
	end

	gUI.GetGlossAlpha = function(self, dark)
		return 0.25 -- dark and 0.1 or 0.33 -- 0.33 or 0.5 -- 0.33 
	end

	gUI.SetShadeAlpha = function(self, a)
		-- db.shadeAlpha = a
	end

	gUI.SetGlossAlpha = function(self, a)
		-- db.glossAlpha = a
	end

	-- the following aren't really configurable, 
	-- but fit in here anyway as they represent global styling for the UI
	gUI.GetGlossTexture = function(self)
		return M("Background", "gUI™ Gloss")
	end

	gUI.GetShadeTexture = function(self)
		return M("Background", "gUI™ Shade")
	end

	gUI.GetStatusBarTexture = function(self)
		return M("Statusbar", "gUI™ StatusBar")
	end
	
	gUI.GetItemButtonBackdrop = function(self)
		return M("Backdrop", "ItemButton")
	end

	gUI.GetBlankTexture = function(self)
		return M("Background", "Blank")
	end
	
	-- setup function to initialize the buttonstyling
	-- any module that needs buttonstyling should call this, 
	-- as there is no guarantee that any other have
	local gABT = LibStub("gActionButtons-3.0")
	gUI.SetUpButtonStyling = function(self)
		gABT:SetBackdrop(gUI:GetItemButtonBackdrop()) -- set the default backdrop for all buttons
		gABT:SetBorderSize(3) -- indent for icons, textures and button content
		gABT:SetTexture(gUI:GetBlankTexture()) -- unneeded, it uses it already
		gABT:SetGlossTexture(gUI:GetGlossTexture())
		gABT:SetShadeTexture(gUI:GetShadeTexture())
		gABT:SetGlossAlpha(gUI:GetGlossAlpha(true))
		gABT:SetShadeAlpha(gUI:GetShadeAlpha(true))
		gABT:SetBackgroundColor(gUI:GetBackgroundColor())
		gABT:SetNormalColor(gUI:GetBackdropBorderColor())
	end
	gUI:SetUpButtonStyling()
	
	--------------------------------------------------------------------------------------------------
	--		Addon Styling API
	--------------------------------------------------------------------------------------------------
	-- addon hooking for the modules, mainly intended for skinning,
	-- but can be used for any functionality that should run once for a specific addon
	local addonQueue = {} 
	gUI.HookAddOn = function(self, addon, func)
		if not(addon) or not(func) then return end
		if (IsAddOnLoaded(addon)) then
			func()
		else
			addonQueue[addon] = func
		end
	end

	local addonHooks = function(self, event, addon)
		if not(addon) or not(addonQueue[addon]) then return end
		addonQueue[addon]()
		addonQueue[addon] = nil
	end
	self:RegisterEvent("ADDON_LOADED", addonHooks)
end
