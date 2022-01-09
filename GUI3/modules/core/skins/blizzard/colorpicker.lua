--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("ColorPickerFrame")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")
	
	self:SetAttribute("name", L["Color Picker"])
	self:SetAttribute("description", L["The color wheel"])

	local func = function()
		local r, g, b, a

		gUI:SetUITemplate(ColorPickerFrame, "backdrop")
		for i = 1, ColorPickerFrame:GetNumRegions() do
			local v = select(i, ColorPickerFrame:GetRegions())
			if (v:GetObjectType() == "Texture") then
				local t = v:GetTexture()
				if ((t == [[Interface\DialogFrame\UI-DialogBox-Border]]) 
					or (t == [[Interface\DialogFrame\UI-DialogBox-Background]]) 
					or (t == [[Interface\DialogFrame\UI-DialogBox-Header]])) then
				
					v:SetTexture("")
				end
			end
		end
		
		gUI:SetUITemplate(ColorPickerCancelButton, "button", true)
		gUI:SetUITemplate(ColorPickerOkayButton, "button", true)
		gUI:SetUITemplate(OpacitySliderFrame, "slider")
		ColorPickerFrameHeader:SetPoint("TOP", 0, 4)
		
		local copy = function()
			r, g, b = ColorPickerFrame:GetColorRGB()
			a = OpacitySliderFrame:GetValue()
		end
		
		local paste = function()
			if (r) and (g) and (b) then
				ColorPickerFrame:SetColorRGB(r, g, b)
			end
			
			if (a) then
				OpacitySliderFrame:SetValue(a)
			end
		end
		
		local copyButton = CreateFrame("Button", "ColorPickerCopyButton", ColorPickerFrame, "MagicButtonTemplate") 
		copyButton:SetText(L["Copy"])
		copyButton:SetPoint("TOPLEFT", 4, -4)
		copyButton:SetScript("OnClick", copy)
		gUI:SetUITemplate(copyButton, "button", true)

		local pasteButton = CreateFrame("Button", "ColorPickerPasteButton", ColorPickerFrame, "MagicButtonTemplate") 
		pasteButton:SetText(L["Paste"])
		pasteButton:SetPoint("TOPRIGHT", -4, -4)
		pasteButton:SetScript("OnClick", paste)
		gUI:SetUITemplate(pasteButton, "button", true)
		
		local CreateFontString = function()
			local box = ColorPickerFrame:CreateFontString(nil, "BACKGROUND")
			box:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
			
			return box
		end
		
		local CreateEditBox = function(parent, showFunc, hideFunc)
			local clickFrame = CreateFrame("Frame", nil, ColorPickerFrame)
			clickFrame.parent = parent
			clickFrame:EnableMouse(true)
			clickFrame:SetAllPoints(parent)
			clickFrame:SetScript("OnMouseDown", function(self) self.editBox:Show() end)

			parent.clickFrame = clickFrame
			
			local editBox = CreateFrame("EditBox", nil, clickFrame)
			editBox.parent = parent
			editBox.Refresh = showFunc
			editBox:Hide()
			editBox:SetSize(48, 20)
			editBox:SetPoint("CENTER")
			editBox:SetJustifyH("RIGHT")
			editBox:SetAutoFocus(false)
			gUI:SetUITemplate(editBox, "editbox")
			editBox:SetScript("OnHide", hideFunc)
			editBox:SetScript("OnShow", function(self) 
				showFunc(self)
				self:SetFocus()
				self:HighlightText() -- EditBox_HighlightText
			end)
			editBox:SetScript("OnEscapePressed", function(self) self:Hide() end)
			editBox:SetScript("OnEnterPressed", function(self) self:Hide() end)
			editBox:SetScript("OnEditFocusLost", function(self) self:Hide() end)

			parent.editBox = editBox
			clickFrame.editBox = editBox
		end
		
		local setR = CreateFontString()
		setR:SetPoint("TOPLEFT", ColorSwatch, "BOTTOMLEFT", 0, -8)
		CreateEditBox(setR, function(self) 
			self:SetText(("%.2f"):format((select(1, ColorPickerFrame:GetColorRGB())))) 
		end, 
		function(self) 
			local n = tonumber(self:GetText())
			if (n) and (n >= 0) and (n <= 1) then
				local r, g, b = ColorPickerFrame:GetColorRGB()
				ColorPickerFrame:SetColorRGB(n, g, b)
				self.parent:Refresh() 
			end
		end)
		
		local setG = CreateFontString()
		setG:SetPoint("TOPLEFT", setR, "BOTTOMLEFT", 0, -8)
		CreateEditBox(setG, function(self) 
			self:SetText(("%.2f"):format((select(2, ColorPickerFrame:GetColorRGB())))) 
		end, 
		function(self) 
			local n = tonumber(self:GetText())
			if (n) and (n >= 0) and (n <= 1) then
				local r, g, b = ColorPickerFrame:GetColorRGB()
				ColorPickerFrame:SetColorRGB(r, n, b)
				self.parent:Refresh() 
			end
		end)

		local setB = CreateFontString()
		setB:SetPoint("TOPLEFT", setG, "BOTTOMLEFT", 0, -8)
		CreateEditBox(setB, function(self) 
			self:SetText(("%.2f"):format((select(3, ColorPickerFrame:GetColorRGB())))) 
		end, 
		function(self) 
			local n = tonumber(self:GetText())
			if (n) and (n >= 0) and (n <= 1) then
				local r, g, b = ColorPickerFrame:GetColorRGB()
				ColorPickerFrame:SetColorRGB(r, g, n)
				self.parent:Refresh() 
			end
		end)	
		
		local setA = CreateFontString()
		setA:SetPoint("TOPLEFT", setB, "BOTTOMLEFT", 0, -8)
		CreateEditBox(setA, function(self) 
			self:SetText(("%.2f"):format(1 - OpacitySliderFrame:GetValue())) 
		end, 
		function(self) 
			local n = tonumber(self:GetText())
			if (n) and (n >= 0) and (n <= 1) then
				OpacitySliderFrame:SetValue(1 - n)
				self.parent:Refresh() 
			end
		end)
		
		updateText = function() 
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = OpacitySliderFrame:GetValue()

			setR:SetText(("%s: |cFFFFD100%.2f|r"):format(L["R"], r))
			setG:SetText(("%s: |cFFFFD100%.2f|r"):format(L["G"], g))
			setB:SetText(("%s: |cFFFFD100%.2f|r"):format(L["B"], b))
			setA:SetText(("%s: |cFFFFD100%.2f|r"):format(L["A"], 1 - a))
			
			setR.editBox:Refresh()
			setG.editBox:Refresh()
			setB.editBox:Refresh()
			setA.editBox:Refresh()
		end
		
		setR.Refresh = updateText
		setG.Refresh = updateText
		setB.Refresh = updateText
		setA.Refresh = updateText
		
		ColorPickerFrame:HookScript("OnShow", updateText)
		ColorPickerFrame:HookScript("OnColorSelect", updateText)
		OpacitySliderFrame:HookScript("OnValueChanged", updateText)
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end