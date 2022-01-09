--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local parent = gUI:GetModule("Combat")
local module = parent:NewModule("Bars")

local L, C, F, M, db

local defaults

local updateAll

-- panels
local MAX_DOCKS = 3
local DOCK_WIDTH = MINIMAP_SIZE -- actual visible width is 6px more, due to outside borders
local dockParent = Minimap -- will make this movable sooner or later
local xpbar, repbar, capturebar = 1, 2, 3 -- position in the dock
local padding, statheight, barheight = 3, 20, 12
local panel, point, CaptureBar = {}, {}, {}

-- bars
local initBars
local SetPosition 
local UpdatePanels, UpdateDock
local CreateCaptureBar, UpdateCaptureBar
local PostUpdateWorldState

------------------------------------------------------------------------------------------------------------
-- 	"Hooked" bars. 
-- 	*not really hooked, not parented or anything,
-- 	just positioned next to the default pos for the minimap
------------------------------------------------------------------------------------------------------------

-- XP Bar
local RegisterAsXPBar
do
	local XPColor = { 0.4, 0.0, 0.4, 1.0 };
	local XPRestedColor = { 0.3, 0.3, 0.8, 1.0 };
	local XPRestedBonusColor = { 0.1, 0.1, 0.4, 1.0 };
	
	local XPText = function() 
		local min = UnitXP("player") or 0
		local max = UnitXPMax("player") or 0
		local exhaust = GetXPExhaustion() or 0
	
		local r, g, b = unpack(C["index"])
		local iCol = "|cFF" .. module:RGBToHex(r, g, b)
		local vCol = "|cFF" .. module:RGBToHex(unpack(C["value"]))
		
		local current = vCol .. module:Tag(("[shortvalue:%d]"):format(min)) .. "|r"
		local total = vCol .. module:Tag(("[shortvalue:%d]"):format(max)) .. "|r"
		
		local percent, restpercent
		if (max == 0) then 
			percent = vCol .. "0|r"
			restpercent = vCol .. "0|r"
		else
			percent = vCol .. tostring(floor(min / max * 100)) .. "|r"
			restpercent = vCol .. tostring(floor(exhaust / max *100)) .. "|r"
		end

		local values = ("%s/%s - %s%%"):format(current, total, percent)
		local rested = (" (%s%%)"):format(restpercent)
	
		return iCol .. values .. "|r"
	end
	
	local OnEvent = function(self, event, ...)
		if (event == "PLAYER_LEVEL_UP") then
			if (GetXPExhaustion() or 0) > 0 then 
				self.bar:SetStatusBarColor(unpack(XPRestedColor))
			else
				self.bar:SetStatusBarColor(unpack(XPColor))
			end

			self.bar:SetMinMaxValues(0, UnitXPMax("player"))
			self.bar:SetValue(UnitXP("player"))
			self.rested:SetMinMaxValues(0, UnitXPMax("player"))
			self.rested:SetValue(min(UnitXPMax("player"), UnitXP("player") + (GetXPExhaustion() or 0)))

			self.text:SetText(XPText())
		end
		
		if (event == "PLAYER_XP_UPDATE") or (event == "PLAYER_ALIVE") or (event == "PLAYER_ENTERING_WORLD") or (event == "PLAYER_LOGIN") then
			if (GetXPExhaustion() or 0) > 0 then 
				self.bar:SetStatusBarColor(unpack(XPRestedColor))
			else
				self.bar:SetStatusBarColor(unpack(XPColor))
			end
			
			self.bar:SetMinMaxValues(0, UnitXPMax("player"))
			self.bar:SetValue(UnitXP("player"))

			self.rested:SetMinMaxValues(0, UnitXPMax("player"))
			self.rested:SetValue(min(UnitXPMax("player"), UnitXP("player") + (GetXPExhaustion() or 0)))

			self.text:SetText(XPText())
		end
	end

	local OnLoad = function(self)
		self.background = self:CreateTexture(nil, "BACKGROUND")
		self.background:SetAllPoints(self)
		self.background:SetTexture(gUI:GetStatusBarTexture())
		self.background:SetVertexColor(0.15, 0.15, 0.15, 1)
		
		self.rested = CreateFrame("StatusBar", nil, self)
		self.rested:SetStatusBarTexture(gUI:GetStatusBarTexture())
		self.rested:SetStatusBarColor(unpack(XPRestedBonusColor))
		self.rested:SetMinMaxValues(0, UnitXPMax("player"))
		self.rested:SetValue(min(UnitXPMax("player"), UnitXP("player") + (GetXPExhaustion() or 0)))
		self.rested:SetAllPoints(self)

		self.bar = CreateFrame("StatusBar", nil, self.rested)
		self.bar:SetStatusBarTexture(gUI:GetStatusBarTexture())
		self.bar:SetAllPoints(self)
		
		gUI:SetUITemplate(self.bar, "gloss")
		-- gUI:SetUITemplate(self.bar, "shade")

		if (GetXPExhaustion() or 0) > 0 then 
			self.bar:SetStatusBarColor(unpack(XPRestedColor))
		else
			self.bar:SetStatusBarColor(unpack(XPColor))
		end

		self.bar:SetMinMaxValues(0, UnitXPMax("player"))
		self.bar:SetValue(UnitXP("player"));
		self.bar:EnableMouse(true)

		self.text = self.bar:CreateFontString(nil, "OVERLAY")
		self.text:SetFontObject(gUI_DisplayFontMicroOutlineWhite)
		self.text:SetPoint("CENTER")
		self.text:SetDrawLayer("OVERLAY", 3)
		self.text:SetText(XPText())
		self.text:SetTextColor(1, 1, 1, 1)
		
		self.overlay = CreateFrame("Frame", nil, self)
		self.overlay:SetAllPoints(self)
		self.overlay:SetParent(self.bar)
	end
	
	local OnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE")
		GameTooltip:ClearAllPoints()
		
		if (GetScreenWidth() - self:GetRight()) > self:GetLeft() then
			GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 8, 0)
		else
			GameTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -8, 0)
		end
		
		local min = UnitXP("player") or 0
		local max = UnitXPMax("player") or 0
		local exhaust = GetXPExhaustion() or 0
		
		local xpgain = 100
		local r, g, b = unpack(C["index"])
		local iCol = "|cFF" .. module:RGBToHex(r, g, b)
		local vCol = "|cFF" .. module:RGBToHex(unpack(C["value"]))
		
		local current = vCol .. module:Tag(("[shortvalue:%d]"):format(min)) .. "|r"
		local total = vCol .. module:Tag(("[shortvalue:%d]"):format(max)) .. "|r"

		-- avoiding division by zero
		local percent, restpercent
		if (max == 0) then 
			percent = vCol .. "0|r"
			restpercent = vCol .. "0|r"
		else
			percent = vCol .. tostring(floor(min / max * 100)) .. "|r"
			restpercent = vCol .. tostring(floor(exhaust / max *100)) .. "|r"
		end

		local values = ("%s/%s - %s%%"):format(current, total, percent)
		local rested = (" (%s%% %s)"):format(restpercent, L["Rested"])
		
		if (exhaust > 0) then 
			xpgain = 200
			
			GameTooltip:AddLine(values .. rested, r, g, b)
			GameTooltip:AddLine("|cFF00FF00" .. L["%d%% of normal experience gained from monsters."]:format(xpgain) .. "|r")
		else
			GameTooltip:AddLine(values, r, g, b)
			GameTooltip:AddLine("|cFFFFFFFF" .. L["%d%% of normal experience gained from monsters."]:format(xpgain) .. "|r")
			GameTooltip:AddLine("|cFFFF0000" .. L["You should rest at an Inn."] .. "|r")
		end

		GameTooltip:Show()
	end
	
	local OnLeave = function(self)
		GameTooltip:Hide()
	end

	RegisterAsXPBar = function(self)
		OnLoad(self)
		self.overlay:SetScript("OnEnter", OnEnter)
		self.overlay:SetScript("OnLeave", OnLeave)
		self:SetScript("OnEvent", OnEvent)
		self:RegisterEvent("PLAYER_ALIVE")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("PLAYER_LEVEL_UP")
		self:RegisterEvent("PLAYER_LOGIN")
		self:RegisterEvent("PLAYER_XP_UPDATE")
	end
end

-- Reputation Bar
local RegisterAsRepBar
do
	local RPText, RPColor
	local OnLoad, OnEvent, OnClick
	
	RPText = function() 
		local RPName, RPStanding, RPMin, RPMax, RPValue = GetWatchedFactionInfo()
		if (not RPName) then 
			return "" 
		end
		return (RPName and module:Tag(("|cFFFFd100[shortvalue:%d]|r"):format(RPValue - RPMin)).." / "..module:Tag(("|cFFFFd100[shortvalue:%d]|r"):format(RPMax - RPMin)).." - |cFFFFd100"..floor((RPValue - RPMin) / (RPMax - RPMin) * 100)).."|r%" or ""
	end
	
	RPColor = function() 
		local RPName, RPStanding, RPMin, RPMax, RPValue = GetWatchedFactionInfo()
		if not(RPName) then 
			return { 0, 0, 0, 1 }
		end
		return { FACTION_BAR_COLORS[RPStanding].r, FACTION_BAR_COLORS[RPStanding].g, FACTION_BAR_COLORS[RPStanding].b, 1 }
	end
	
	OnLoad = function(self)
		self.background = self:CreateTexture(nil, "BACKGROUND")
		self.background:SetAllPoints(self)
		self.background:SetTexture(gUI:GetStatusBarTexture())
		self.background:SetVertexColor(0.15, 0.15, 0.15, 1)

		local RPName, RPStanding, RPMin, RPMax, RPValue = GetWatchedFactionInfo()
		self.bar = CreateFrame("StatusBar", nil, self)
		self.bar:SetStatusBarTexture(gUI:GetStatusBarTexture())
		self.bar:SetStatusBarColor(unpack(RPColor()))
		self.bar:SetAllPoints(self)
		self.bar:SetMinMaxValues(RPMin, RPMax)
		self.bar:SetValue(RPValue);
		self.bar:EnableMouse(true)
		
		gUI:SetUITemplate(self.bar, "gloss")
		-- gUI:SetUITemplate(self.bar, "shade")

		self.text = self.bar:CreateFontString(nil, "OVERLAY")
		self.text:SetFontObject(gUI_DisplayFontMicroOutlineWhite)
		self.text:SetPoint("CENTER")
		self.text:SetDrawLayer("OVERLAY", 3)
		self.text:SetText(RPText())
		self.text:SetTextColor(1, 1, 1, 1)
		
		self.overlay = CreateFrame("Frame", nil, self)
		self.overlay:SetAllPoints(self)
		self.overlay:SetParent(self.bar)

		hooksecurefunc("ReputationWatchBar_Update", function() 
			OnEvent(self, "UPDATE_FACTION") 
		end)
	end
	
	OnClick = function(self, button)
		if (button == "LeftButton") then
			ToggleCharacter("ReputationFrame")
			
			local RPName, RPStanding, RPMin, RPMax, RPValue = GetWatchedFactionInfo()
			
			if (RPName) then
				local headersToClose = {}
				local headerID, headerName, headerToExpand, headerToExpandName, faction
				
				ExpandAllFactionHeaders()
				
				for i = 1, GetNumFactions() do
					local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(i)

					if (isHeader) then
						headerID = i
						headerName = name
					end
					
					if (RPName == name) then
						faction = i
						headerToExpand = headerID
						headerToExpandName = headerName
					end
				end
				
				SetSelectedFaction(faction)
				ReputationDetailFrame:Show()
				ReputationFrame_Update()
			end
		end
	end
	
	OnEvent = function(self, event, ...)
		local RPName, RPStanding, RPMin, RPMax, RPValue = GetWatchedFactionInfo()
		self.bar:SetStatusBarColor(unpack(RPColor()))
		self.bar:SetMinMaxValues(RPMin, RPMax)
		self.bar:SetValue(RPValue)
		self.text:SetText(RPText())
	end
	
	OnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE")
		GameTooltip:ClearAllPoints()
		
		if (GetScreenWidth() - self:GetRight()) > self:GetLeft() then
			GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 8, 0)
		else
			GameTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -8, 0)
		end
		
		local RPName, RPStanding, RPMin, RPMax, RPValue = GetWatchedFactionInfo()
		if (RPName) then
			local gender = UnitSex("player")
			local r, g, b = unpack(C["index"])
			local r2, g2, b2 = unpack(C["value"])
			local r3, g3, b3 = C["FACTION_BAR_COLORS"][RPStanding].r, C["FACTION_BAR_COLORS"][RPStanding].g, C["FACTION_BAR_COLORS"][RPStanding].b 
			local vCol = "|cFF" .. module:RGBToHex(r2, g2, b2)
			local standing = "|cFF" .. module:RGBToHex(r3, g3, b3) .. GetText("FACTION_STANDING_LABEL" .. RPStanding, gender) .. "|r"
			local label = RPName .. " (" .. standing .. ")"
			local current = vCol .. module:Tag(("[shortvalue:%d]"):format(RPValue - RPMin)) .. "|r"
			local total = vCol .. module:Tag(("[shortvalue:%d]"):format(RPMax - RPMin)) .. "|r"
			local percent = vCol .. tostring(floor((RPValue - RPMin) / (RPMax - RPMin) * 100)) .. "|r"
			local values = ("%s/%s - (%s%%)"):format(current, total, percent)

			GameTooltip:AddLine(label, r, g, b)
			GameTooltip:AddLine(values, r, g, b)
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["<Left-Click to toggle Reputation pane>"], r2, g2, b2)
			GameTooltip:Show()
		end		
	end
	
	local OnLeave = function(self)
		GameTooltip:Hide()
	end

	RegisterAsRepBar = function(self)
		OnLoad(self)
		self.overlay:SetScript("OnMouseDown", OnClick)
		self.overlay:SetScript("OnEnter", OnEnter)
		self.overlay:SetScript("OnLeave", OnLeave)
		self:SetScript("OnEvent", OnEvent)
		self:RegisterEvent("UPDATE_FACTION")
	end
end

SetPosition = function(frame, position)
	frame:ClearAllPoints()
	for _,p in pairs(point[position]) do
		frame:SetPoint(unpack(p))
	end
end

UpdateDock = function()
	local slot = 1
	for i,p in ipairs(panel) do
		if (p:IsShown()) then
			SetPosition(p, slot)
			slot = slot + 1
		end
	end
end

UpdatePanels = function()
	if (panel[repbar]) then
		local RPName, RPStanding, RPMin, RPMax, RPValue = GetWatchedFactionInfo()
		if not(db.showRepBar) or not(RPName) then
			panel[repbar]:Hide()
		else
			panel[repbar]:Show()
		end
	end
	
	if (panel[xpbar]) then
		local accountLevel = GetAccountExpansionLevel()
		local maxLevel = MAX_PLAYER_LEVEL_TABLE[accountLevel or #MAX_PLAYER_LEVEL_TABLE]
		local isMaxLevel = (UnitLevel("player") == maxLevel) or IsXPUserDisabled()
		
		if not(db.showXPBar) or ((isMaxLevel) and not(db.showXPBarAtMax)) then
			panel[xpbar]:Hide()
		else
			panel[xpbar]:Show()
		end
	end
	
	UpdateDock()
end

CreateCaptureBar = function(id)
	if (CaptureBar[id]) then 
		return 
	end
	
	-- local newBar = CreateFrame("Frame", module:GetName() .. "CaptureBar" .. id, panel[capturebar])
	local newBar = CreateFrame("Frame", nil, panel[capturebar])
	newBar:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
	newBar:SetSize(DOCK_WIDTH, barheight + 6) -- room for our 3px border
	newBar:Hide()
	
	-- make it pretty
	gUI:SetUITemplate(newBar, "backdrop")
	gUI:CreateUIShadow(newBar)  

	-- newBar:SetUITemplate("simpleblackbackdrop") -- border inside, thus we had to make the frame 6px larger
	newBar.candyLayer = CreateFrame("Frame", nil, newBar)
	newBar.candyLayer:SetPoint("TOPLEFT", 3, -3)
	newBar.candyLayer:SetPoint("BOTTOMRIGHT", -3, 3)
	gUI:SetUITemplate(newBar.candyLayer, "gloss")
	-- gUI:SetUITemplate(newBar.candyLayer, "shade")
	
	-- shine effect
	newBar.shine = F.Shine:New(newBar.candyLayer)
	newBar:SetScript("OnShow", function(self) self.shine:Start() end)
	newBar:SetScript("OnHide", function(self) self.shine:Hide() end)
	
	newBar.leftIcon = newBar:CreateTexture(nil, "OVERLAY")
	newBar.leftIcon:SetPoint("RIGHT", newBar, "LEFT", -5, 0)
	newBar.leftIcon:SetTexture(M("Icon", "FactionAlliance"))
	newBar.leftIcon:SetSize(24, 24)
	newBar.leftIcon:Hide()

	newBar.rightIcon = newBar:CreateTexture(nil, "OVERLAY")
	newBar.rightIcon:SetPoint("LEFT", newBar, "RIGHT", 5, 0)
	newBar.rightIcon:SetTexture(M("Icon", "FactionHorde"))
	newBar.rightIcon:SetSize(26, 26)
	newBar.rightIcon:Hide()
			
	newBar.middle = newBar:CreateTexture(nil, "OVERLAY")
	newBar.middle:SetDrawLayer("OVERLAY", 0)
	newBar.middle:SetPoint("TOP", newBar, "TOP", 0, -3)
	newBar.middle:SetPoint("BOTTOM", newBar, "BOTTOM", 0, 3)
	newBar.middle:SetTexture(gUI:GetStatusBarTexture())
	newBar.middle:SetWidth(0.0001)
	newBar.middle:SetVertexColor(0.9, 0.9, 0.6, 1)

	newBar.left = newBar:CreateTexture(nil, "OVERLAY")
	newBar.left:SetDrawLayer("OVERLAY", 0)
	newBar.left:SetPoint("LEFT", newBar, "LEFT", 3, 0)
	newBar.left:SetPoint("TOP", newBar, "TOP", 0, -3)
	newBar.left:SetPoint("BOTTOM", newBar, "BOTTOM", 0, 3)
	newBar.left:SetPoint("RIGHT", newBar.middle, "LEFT", 0, 0)
	newBar.left:SetTexture(gUI:GetStatusBarTexture())
	newBar.left:SetVertexColor(0.0, 0.5, 0.9, 1)
	
	newBar.right = newBar:CreateTexture(nil, "OVERLAY")
	newBar.right:SetDrawLayer("OVERLAY", 0)
	newBar.right:SetPoint("LEFT", newBar.middle, "RIGHT", 0, 0)
	newBar.right:SetPoint("TOP", newBar, "TOP", 0, -3)
	newBar.right:SetPoint("BOTTOM", newBar, "BOTTOM", 0, 3)
	newBar.right:SetPoint("RIGHT", newBar, "RIGHT", -3, 0)
	newBar.right:SetTexture(gUI:GetStatusBarTexture())
	newBar.right:SetVertexColor(0.9, 0.1, 0.0, 1)
	
	newBar.indicator = newBar:CreateTexture()
	newBar.indicator:SetDrawLayer("OVERLAY", 7)
	newBar.indicator:SetSize(5, 18)
	newBar.indicator:SetTexture([[Interface\WorldStateFrame\WorldState-CaptureBar]])
	newBar.indicator:SetTexCoord(199/256, 203/256, 0/64, 17/64)
	newBar.indicator:SetPoint("CENTER", newBar, "LEFT", 0, 0)

	newBar.indicatorLeft = newBar:CreateTexture()
	newBar.indicatorLeft:SetDrawLayer("OVERLAY", 6)
	newBar.indicatorLeft:SetSize(8, 15)
	newBar.indicatorLeft:SetTexture([[Interface\WorldStateFrame\WorldState-CaptureBar]])
	newBar.indicatorLeft:SetTexCoord(186/256, 193/256, 9/64, 23/64)
	newBar.indicatorLeft:SetPoint("RIGHT", newBar.indicator, "LEFT", 1, 0)
	
	newBar.indicatorRight = newBar:CreateTexture()
	newBar.indicatorRight:SetDrawLayer("OVERLAY", 6)
	newBar.indicatorRight:SetSize(8, 15)
	newBar.indicatorRight:SetTexture([[Interface\WorldStateFrame\WorldState-CaptureBar]])
	newBar.indicatorRight:SetTexCoord(193/256, 186/256, 9/64, 23/64)
	newBar.indicatorRight:SetPoint("LEFT", newBar.indicator, "RIGHT", -1, 0)
	
	CaptureBar[id] = newBar
	
	return newBar
end

UpdateCaptureBar = function(id, value, neutralPercent)
	if (not CaptureBar[id]) then 
		CaptureBar[id] = CreateCaptureBar(id) 
	end

	local position = CaptureBar[id]:GetWidth()/100 * (100 - value)
	
	if not(CaptureBar[id]:IsShown()) then 
		CaptureBar[id]:Show() 
	end
	
	if not(CaptureBar[id].oldValue) then
		CaptureBar[id].oldValue = position
	end
	
	-- indicator visibility
	if (value < 0.5) or (value > 99.5) then
		CaptureBar[id].indicatorLeft:Hide()
		CaptureBar[id].indicatorRight:Hide()
	
	elseif (position < CaptureBar[id].oldValue) then
		CaptureBar[id].indicatorLeft:Show()
		CaptureBar[id].indicatorRight:Hide()
		
	elseif( position > CaptureBar[id].oldValue) then
		CaptureBar[id].indicatorLeft:Hide()
		CaptureBar[id].indicatorRight:Show()
		
	else
		CaptureBar[id].indicatorLeft:Hide()
		CaptureBar[id].indicatorRight:Hide()
	end
	
	-- color the border according to control
	if ( value > (50 + neutralPercent/2) ) then
		if (CaptureBar[id].status ~= "Alliance") then
			-- CaptureBar[id]:SetBackdropColor(0.0, 0.5 * 1/5, 0.9* 1/5, 1) -- Alliance
			gUI:SetUIShadowColor(CaptureBar[id], 0, 0, 0.75, 0.35)
			CaptureBar[id]:SetBackdropBorderColor(0.0, 0, 1, 1) 
			CaptureBar[id].status = "Alliance"
			CaptureBar[id].shine:Start()
		end
		
	elseif ( value < (50 - neutralPercent/2) ) then
		if (CaptureBar[id].status ~= "Horde") then
			-- CaptureBar[id]:SetBackdropColor(0.9 * 1/5, 0.1 * 1/5, 0.0, 1) -- Horde
			gUI:SetUIShadowColor(CaptureBar[id], 0.75, 0, 0, 0.35)
			CaptureBar[id]:SetBackdropBorderColor(1, 0, 0.0, 1) 
			CaptureBar[id].status = "Horde"
			CaptureBar[id].shine:Start()
		end
		
	else
		if (CaptureBar[id].status ~= "Neutral") then
			gUI:SetUIShadowColor(CaptureBar[id])
			CaptureBar[id]:SetBackdropColor(unpack(C["background"])) -- Neutral
			CaptureBar[id]:SetBackdropBorderColor(gUI:GetBackdropBorderColor()) 
			CaptureBar[id].status = "Neutral"
			CaptureBar[id].shine:Start()
		end
	end
	
	CaptureBar[id].middle:SetWidth(CaptureBar[id]:GetWidth()/100 * (neutralPercent == 0 and 0.0001 or neutralPercent))
	CaptureBar[id].oldvalue = position
	CaptureBar[id].indicator:ClearAllPoints()
	CaptureBar[id].indicator:SetPoint("CENTER", CaptureBar[id], "LEFT", position, 0)
end

PostUpdateWorldState = function()
	local extendedUIShown = 1
	for i = 1, GetNumWorldStateUI() do
		local uiType, state, hidden, text, icon, dynamicIcon, tooltip, dynamicTooltip, extendedUI, extendedUIState1, extendedUIState2, extendedUIState3 = GetWorldStateUIInfo(i)

		if ( (not hidden) and ((uiType ~= 1) or ((WORLD_PVP_OBJECTIVES_DISPLAY == "1") or (WORLD_PVP_OBJECTIVES_DISPLAY == "2" and IsSubZonePVPPOI()) or (instanceType == "pvp"))) ) and ( state > 0 ) and ( extendedUI == "CAPTUREPOINT" ) then

			UpdateCaptureBar(extendedUIShown, extendedUIState1, extendedUIState2, extendedUIState3)
			extendedUIShown = extendedUIShown + 1
		end
	end

	local f
	for i = 1, NUM_EXTENDED_UI_FRAMES do
		f = _G[("WorldStateCaptureBar%d"):format(i)]

		if (f) then 
			if f:IsShown() then
				f:SetScale(0.0001)

				if (not CaptureBar[i]) then 
					CaptureBar[i] = CreateCaptureBar(i) 
				end
				
				CaptureBar[i]:ClearAllPoints()
				
				if (i == 1) then
					CaptureBar[i]:SetPoint("TOPLEFT", panel[capturebar], "TOPLEFT", -3, 0)
				else
					CaptureBar[i]:SetPoint("TOPLEFT", CaptureBar[i], "BOTTOMLEFT", 0, -4)
				end
			else
				if CaptureBar[i] then
					CaptureBar[i]:Hide()
				end
			end
		end
	end

	if #CaptureBar > NUM_EXTENDED_UI_FRAMES then
		for i = NUM_EXTENDED_UI_FRAMES + 1, #CaptureBar do
			if (CaptureBar[i]) then
				CaptureBar[i]:Hide()
			end
		end
	end
end

initBars = function(self)
	local padding, border = 4, 3
	local Dock = CreateFrame("Frame", nil, gUI:GetAttribute("parent"))
	Dock:SetSize(DOCK_WIDTH, (barheight + border*2)*MAX_DOCKS + padding*(MAX_DOCKS-1))

	-- gUI:SetUITemplate(Dock, "backdrop")
	-- gUI:CreateUIShadow(Dock) 
	
	self:PlaceAndSave(Dock, L["XP-, Rep- & Capture Bars"], db.dockposition, unpack(defaults.dockposition))
	self:AddObjectToFrameGroup(Dock, "uipanels")

	-- our docking positions
	for i = 1, MAX_DOCKS do
		point[i] = {
			{ "TOPLEFT", border, -(border + ((i-1)*(padding + barheight + border*2))) };
		}
	end

	-- xp bar
	panel[xpbar] = CreateFrame("Frame", nil, Dock)
	panel[xpbar]:SetSize(DOCK_WIDTH - 6, barheight)
	gUI:CreateUIShadow(gUI:SetUITemplate(panel[xpbar], "outerbackdrop")) 
	RegisterAsXPBar(panel[xpbar])

	-- rep bar
	panel[repbar] = CreateFrame("Frame", nil, Dock)
	panel[repbar]:SetSize(DOCK_WIDTH - 6, barheight)
	gUI:CreateUIShadow(gUI:SetUITemplate(panel[repbar], "outerbackdrop")) 
	RegisterAsRepBar(panel[repbar])

	-- capture bar(s)
	-- we're not adding the styling directly here, 
	-- since there can be more than one capturebar. In theory.
	panel[capturebar] = CreateFrame("Frame", nil, Dock)
	panel[capturebar]:SetSize(DOCK_WIDTH, barheight + 6)

	hooksecurefunc("WorldStateAlwaysUpFrame_Update", PostUpdateWorldState)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", PostUpdateWorldState)
	self:RegisterBucketEvent({
		"PLAYER_ALIVE";
		"PLAYER_ENTERING_WORLD";
		"PLAYER_LEVEL_UP";
		"PLAYER_XP_UPDATE";
		"PLAYER_FLAGS_CHANGED";
		"DISABLE_XP_GAIN";
		"ENABLE_XP_GAIN";
		"UPDATE_FACTION";
	}, UpdatePanels)
end

local settings = {
}

updateAll = function()
	PostUpdateWorldState()
	UpdatePanels()
end
module.PostUpdateSettings = updateAll

module.OnInit = function(self)
	L, C, F, M = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	db = self:GetParent():GetCurrentOptionsSet() -- get module settings
	defaults = self:GetParent():GetDefaultsForOptions() -- get module defaults

	-- since we basically hijacked this function from another module, 
	-- we push our parent as "self" here, since "PlaceAndSave" appearantly isn't available on submodules
	initBars(parent) 
end

