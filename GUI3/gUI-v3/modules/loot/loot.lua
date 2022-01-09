--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Loot")
local gABT = LibStub("gActionButtons-3.0")

local unpack = unpack

local CreateFrame = CreateFrame
local GetLootRollItemInfo = GetLootRollItemInfo
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local LootFrame = LootFrame
local UIParent = UIParent

local L, C, F, M, db

local holder
local makeBackdrop
local styleRollFrame, styleLootFrame, styleRollFrames
local styleWinFrames, styleLootWonFrame, styleBonusRollFrame
local parseRollChoice
local postUpdateRollChoices, postUpdateRollFrames, postUpdateRollFramePositions
local postUpdateLootFrame, postUpdateLootFramePosition

local settings = {
	gap = 12;
	name = {
		size = 16;
	};
	icon = {
		size = 32;
		gap = 16;
	};
	item = {
		size = 36;
	};
	timer = {
		size = { 224, 16 }
	};
}

local defaults = {
	place = { "TOPLEFT", "UIParent", "TOPLEFT", 450, -350 };
}

--[[
	Original roll strings are from teksLoot, extracted/edited from GlobalStrings.lua by tekkub
	- esES, esMX and ptBR extracted and added by Lars Norberg (untested, need feedback)
	
	tekkub: http://www.tekkub.net/
	teksLoot: http://www.wowinterface.com/downloads/info8198-teksLoot.html
]]--
local locale = GetLocale()
local rollPairs = (locale == "deDE") and {
	["(.*) passt automatisch bei (.+), weil [ersi]+ den Gegenstand nicht benutzen kann.$"]  = "pass",
	["(.*) würfelt nicht für: (.+|r)$"] = "pass",
	["(.*) hat für (.+) 'Gier' ausgewählt"] = "greed",
	["(.*) hat für (.+) 'Bedarf' ausgewählt"] = "need",
	["(.*) hat für '(.+)' Entzauberung gewählt."]  = "disenchant",
} or (locale == "frFR") and {
	["(.*) a passé pour : (.+) parce qu'((il)|(elle)) ne peut pas ramasser cette objet.$"]  = "pass",
	["(.*) a passé pour : (.+)"]  = "pass",
	["(.*) a choisi Cupidité pour : (.+)"] = "greed",
	["(.*) a choisi Besoin pour : (.+)"]  = "need",
	["(.*) a choisi Désenchantement pour : (.+)"]  = "disenchant",
} or (locale == "zhTW") and {
	["(.*)自動放棄:(.+)，因為"]  = "pass",
	["(.*)放棄了:(.+)"] = "pass",
	["(.*)選擇了貪婪優先:(.+)"] = "greed",
	["(.*)選擇了需求優先:(.+)"] = "need",
	["(.*)選擇分解:(.+)"] = "disenchant",
} or (locale == "zhCN") and { 
	["(.*)自动放弃了(.+)，因为他无法拾取该物品。$"]  = "pass",
	["(.*)放弃了：(.+)"] = "pass", 
	["(.*)选择了贪婪取向：(.+)"] = "greed", 
	["(.*)选择了需求取向：(.+)"] = "need", 
	["(.*)选择了分解取向：(.+)"] = "disenchant",
} or (locale == "ruRU") and {
	["(.*) автоматически передает предмет (.+), поскольку не может его забрать"] = "pass",
	["(.*) пропускает розыгрыш предмета \"(.+)\", поскольку не может его забрать"] = "pass",
	["(.*) отказывается от предмета (.+)%."]  = "pass",
	["Разыгрывается: (.+)%. (.*): \"Не откажусь\""] = "greed",
	["Разыгрывается: (.+)%. (.*): \"Мне это нужно\""] = "need",
	["Разыгрывается: (.+)%. (.*): \"Распылить\""] = "disenchant",
} or (locale == "koKR") and {
	["(.+)님이 획득할 수 없는 아이템이어서 자동으로 주사위 굴리기를 포기했습니다: (.+)"] = "pass",
	["(.+)님이 주사위 굴리기를 포기했습니다: (.+)"] = "pass",
	["(.+)님이 차비를 선택했습니다: (.+)"] = "greed",
	["(.+)님이 입찰을 선택했습니다: (.+)"] = "need",
	["(.+)님이 마력 추출을 선택했습니다: (.+)"] = "disenchant",
} or (locale == "esES") and {
	["(.*) ha pasado automáticamente de: (.+) ya que él no puede despojar ese objeto."] = "pass",
	["(.*) ha pasado automáticamente de: (.+) ya que ella no puede despojar ese objeto."] = "pass",
	["(.*) ha pasado de: (.+)"] = "pass",
	["(.*) ha seleccionado codicia para: (.+)"] = "greed",
	["(.*) ha seleccionado necesidad para: (.+)"] = "need",
	["(.*) ha seleccionado desencantar para: (.+)"] = "disenchant",
} or (locale == "esMX") and {
	["(.*) ha pasado automáticamente de: (.+) ya que él no puede despojar ese objeto."] = "pass",
	["(.*) ha pasado automáticamente de: (.+) ya que ella no puede despojar ese objeto."] = "pass",
	["(.*) ha pasado de: (.+)"] = "pass",
	["(.*) ha seleccionado codicia para: (.+)"] = "greed",
	["(.*) ha seleccionado necesidad para: (.+)"] = "need",
	["(.*) ha seleccionado desencantar para: (.+)"] = "disenchant",
} or (locale == "ptBR") and {
	["(.*) abdicou de (.+) automaticamente porque não pode saquear o item."] = "pass",
	["(.*) abdicou de (.+) automaticamente porque não pode saquear o item."] = "pass",
	["(.*) dispensou: (.+)"] = "pass",
	["(.*) selecionou Ganância para: (.+)"] = "greed",
	["(.*) escolheu Necessidade para: (.+)"] = "need",
	["(.*) selecionou Desencantar para: (.+)"] = "disenchant",
} or {
	["^(.*) automatically passed on: (.+) because s?he cannot loot that item.$"] = "pass", -- LOOT_ROLL_PASSED_AUTO, LOOT_ROLL_PASSED_AUTO_FEMALE
	["^(.*) passed on: (.+|r)$"]  = "pass", -- LOOT_ROLL_PASSED
	["(.*) has selected Greed for: (.+)"] = "greed", -- LOOT_ROLL_GREED
	["(.*) has selected Need for: (.+)"]  = "need", -- LOOT_ROLL_NEED
	["(.*) has selected Disenchant for: (.+)"]  = "disenchant", --LOOT_ROLL_DISENCHANT
}

parseRollChoice = function(msg)
	if not(msg) then
		return
	end
	for i,v in pairs(rollPairs) do
		local _, _, playername, itemname = string.find(msg, i)
		if (locale == "ruRU") and ((v == "greed") or (v == "need") or (v == "disenchant"))  then 
			local temp = playername
			playername = itemname
			itemname = temp
		end 
		-- ok (for now) to leave 'Everyone' unlocalized, 
		-- as the LOOT_ROLL_ALL_PASSED string is only the same as
		-- the LOOT_ROLL_PASSED string in enUS/enGB.
		if (playername) and (itemname) and (playername ~= "Everyone") then 
			return playername, itemname, v 
		end
	end
end

postUpdateRollChoices = function(self, event, msg)
	local playername, itemname, rolltype
	if (event == "CHAT_MSG_LOOT") then
		playername, itemname, rolltype = parseRollChoice(msg)
	end
	if (playername) and (itemname) and (rolltype) then
		local i, frame, num
		for i = 1, NUM_GROUP_LOOT_FRAMES do
			frame = _G["GroupLootFrame" .. i]
			if (frame) then
				if not(frame.rolls) then
					frame.rolls = {}
				end
				if (frame.rollID) and (frame.link == itemname) and not(frame.rolls[playername]) then
					num = tonumber(frame[rolltype]:GetText()) + 1
					frame.rolls[playername] = rolltype
					frame[rolltype]:SetText(num)
					if (num > 0) then
						frame[rolltype]:Show()
					else
						frame[rolltype]:Hide()
					end
					return
				end
			end
		end
	end
end

postUpdateRollFramePositions = function(self)
	-- GroupLootFrame1:ClearAllPoints()
	-- GroupLootFrame1:SetPoint("BOTTOM", "UIParent", "BOTTOM", 0, 220)
	
	for i = 1, self.maxIndex do
		local frame = self.rollFrames[i]
		if (frame) then
			frame:ClearAllPoints()
			frame:SetPoint("BOTTOM", "UIParent", "BOTTOM", 0, 220 + (self.reservedSize * (i-1 + 0.5)))
			-- frame:SetPoint("CENTER", self, "BOTTOM", 0, self.reservedSize * (i-1 + 0.5))
		end
	end	
end

postUpdateRollFrames = function()
	for i = 1, NUM_GROUP_LOOT_FRAMES do
		local frame = _G["GroupLootFrame" .. i]
		local rollID = frame.rollID
		if (rollID) and (frame) then
			styleRollFrame(frame)
			
			local texture, name, count, quality, bop, canneed, cangreed, canshard, whyneed, whygreed, whyshard, deskill = GetLootRollItemInfo(rollID)
			frame.link = GetLootRollItemLink(rollID)

			if (name) then
				local color = ITEM_QUALITY_COLORS[quality] or {}
			
				color.r = color.r or 0.6
				color.g = color.g or 0.6
				color.b = color.b or 0.6

				frame.Timer:SetStatusBarColor(color.r, color.g, color.b, 1)
				frame.Timer:SetBackdropColor(color.r * 1/5, color.g * 1/5, color.b * 1/5, 3/4)

				-- frame.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, 1)
				-- gUI:SetUIShadowColor(frame.Backdrop, color.r * 2/3, color.g * 2/3, color.b * 2/3, 3/4)

				frame.IconFrame.Backdrop:SetBackdropBorderColor(color.r, color.g, color.b, 1)
				gUI:SetUIShadowColor(frame.IconFrame.Backdrop, color.r * 2/3, color.g * 2/3, color.b * 2/3, 3/4)
				
				if (canneed) then
					frame.NeedButton:Show()
					frame.NeedButton:SetAlpha(1)
					frame.GreedButton:ClearAllPoints()
					frame.GreedButton:SetPoint("LEFT", frame.NeedButton, "RIGHT", 16, 0)
				else
					frame.NeedButton:SetAlpha(0)
					frame.NeedButton:Hide()
					frame.GreedButton:ClearAllPoints()
					frame.GreedButton:SetPoint("LEFT", frame.Timer, "LEFT", 12, 0)
				end
				
				if (canshard) then
					frame.DisenchantButton:Show()
					frame.DisenchantButton:SetAlpha(1)
				else
					frame.DisenchantButton:SetAlpha(0)
					frame.DisenchantButton:Hide()
				end
				
				if (bop) then
					frame.isbind:SetText(L["BoP"])
					frame.isbind:SetVertexColor(unpack(C["value"]))
				else
					frame.isbind:SetText(L["BoE"])
					frame.isbind:SetVertexColor(unpack(C["disabled"]))
				end

			end
		end
	end
	postUpdateRollChoices()
end

styleRollFrame = function(self)
	self:SetSize(settings.timer.size[1] + settings.gap + settings.item.size, max(settings.timer.size[2] + settings.name.size + settings.gap*2,  settings.item.size + settings.gap*2))
	-- self:SetBackdrop(nil)
	self:SetParent(UIParent)
	-- /run GroupLootFrame1:SetParent(UIParent); GroupLootFrame1:ClearAllPoints(); GroupLootFrame1:SetPoint("CENTER"); GroupLootFrame1:Show()
	gUI:HideObject(self.Background)
	gUI:HideObject(self.Border)
	gUI:HideObject(self.IconFrame.Border)

	self.Backdrop = gUI:SetUITemplate(self, "border", self.Timer)
	gUI:CreateUIShadow(self.Backdrop)
	
	self.Timer:SetSize(unpack(settings.timer.size))
	self.Timer:ClearAllPoints()
	self.Timer:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, settings.gap)
	-- self.Timer:DisableDrawLayer("OVERLAY")
	self.Timer:SetStatusBarTexture(gUI:GetStatusBarTexture())
	
	self.IconFrame:SetSize(settings.item.size, settings.item.size)
	self.IconFrame:ClearAllPoints()
	self.IconFrame:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, settings.gap - 3)

	self.IconFrame.Icon:SetAllPoints(self.IconFrame)
	self.IconFrame.Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)

	self.IconFrame.Backdrop = gUI:SetUITemplate(self.IconFrame, "border")
	gUI:CreateUIShadow(self.IconFrame.Backdrop)

	-- local layer, subLayer = self.IconFrame.Icon:GetDrawLayer()

	if not(self.IconFrame.Shade) then
		self.IconFrame.Shade = gUI:SetUITemplate(self.IconFrame, "shade", self.IconFrame.Icon)
		-- self.IconFrame.Shade:SetDrawLayer(layer or "BACKGROUND", subLayer and subLayer + 1 or 2)
	end

	if not(self.IconFrame.Gloss) then
		self.IconFrame.Gloss = gUI:SetUITemplate(self.IconFrame, "gloss", self.IconFrame.Icon)
		-- self.IconFrame.Gloss:SetDrawLayer(layer or "BACKGROUND", subLayer and subLayer + 2 or 3)
	end

	self.IconFrame.Count:SetSize(settings.item.size, settings.item.size)
	self.IconFrame.Count:ClearAllPoints()
	self.IconFrame.Count:SetPoint("BOTTOMRIGHT", self.IconFrame.Icon, "BOTTOMRIGHT", 0, 0)
	self.IconFrame.Count:SetFontObject(gUI_DisplayFontSmallOutlineWhite)
		
	self.Name:SetSize(self:GetWidth(), settings.name.size)
	self.Name:ClearAllPoints()
	self.Name:SetPoint("BOTTOMLEFT", self.Timer, "TOPLEFT", 0, settings.gap)
	self.Name:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
	
	self.NeedButton:SetSize(settings.icon.size, settings.icon.size)
	self.NeedButton:ClearAllPoints()
	self.NeedButton:SetPoint("LEFT", self.Timer, "LEFT", settings.gap, 0)
	self.NeedButton:SetHitRectInsets(-8, -8, -8, -8)
	
	self.GreedButton:SetSize(settings.icon.size, settings.icon.size)
	self.GreedButton:ClearAllPoints()
	self.GreedButton:SetPoint("LEFT", self.NeedButton, "RIGHT", settings.icon.gap, 0)
	self.GreedButton:SetHitRectInsets(-8, -8, -8, -8)

	self.DisenchantButton:SetSize(settings.icon.size, settings.icon.size)
	self.DisenchantButton:ClearAllPoints()
	self.DisenchantButton:SetPoint("LEFT", self.GreedButton, "RIGHT", settings.icon.gap, 0)
	self.DisenchantButton:SetHitRectInsets(-8, -8, -8, -8)

	self.PassButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	self.PassButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	self.PassButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	self.PassButton:SetSize(settings.icon.size, settings.icon.size)
	self.PassButton:ClearAllPoints()
	self.PassButton:SetPoint("RIGHT", self.Timer, "RIGHT", -settings.gap, 0)
	self.PassButton:SetHitRectInsets(-8, -8, -8, -8)

	-- texts
	if not(self.isbind) then
		self.isbind = self.IconFrame.Backdrop:CreateFontString(nil, "OVERLAY")
		self.isbind:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
		self.isbind:SetPoint("BOTTOM", 0, -3)
	end
	self.isbind:SetText("")

	if not(self.need) then
		self.need = self.NeedButton:CreateFontString(nil, "OVERLAY")
		self.need:SetFontObject(gUI_DisplayFontSmallOutline)
		self.need:SetPoint("BOTTOMRIGHT", 8, -4)
	end
	self.need:SetText(0)
	self.need:Hide()

	if not(self.greed) then
		self.greed = self.GreedButton:CreateFontString(nil, "OVERLAY")
		self.greed:SetFontObject(gUI_DisplayFontSmallOutline)
		self.greed:SetPoint("BOTTOMRIGHT", 8, -4)
	end
	self.greed:SetText(0)
	self.greed:Hide()

	if not(self.disenchant) then
		self.disenchant = self.DisenchantButton:CreateFontString(nil, "OVERLAY")
		self.disenchant:SetFontObject(gUI_DisplayFontSmallOutline)
		self.disenchant:SetPoint("BOTTOMRIGHT", 8, -4)
	end
	self.disenchant:SetText(0)
	self.disenchant:Hide()

	if not(self.pass) then
		self.pass = self.PassButton:CreateFontString(nil, "OVERLAY")
		self.pass:SetFontObject(gUI_DisplayFontSmallOutline)
		self.pass:SetPoint("BOTTOMRIGHT", 8, -4)
	end
	self.pass:SetText(0)
	self.pass:Hide()
	
	if not(self.rolls) then
		self.rolls = {}
	else
		wipe(self.rolls)
	end
	
	self.initialized = true
end

styleRollFrames = function()
	local frame
	for i = 1, NUM_GROUP_LOOT_FRAMES, 1 do
		frame = _G["GroupLootFrame" .. i]
		if (frame) then
			styleRollFrame(frame)
		end
	end
end

postUpdateLootFramePosition = function()
	if (GetCVar("lootUnderMouse") ~= "1") then
		LootFrame:ClearAllPoints()
		LootFrame:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
	end
end

postUpdateLootFrame = function()
	local numshown, lastshown = 0, 0
	for index = 1, LOOTFRAME_NUMBUTTONS do
		local bName = "LootButton" .. index

		if _G[bName]:IsShown() then
			local color = ITEM_QUALITY_COLORS[_G[bName].quality] or {}

			numshown = numshown + 1
			
			if (numshown == 1) then
				_G[bName]:ClearAllPoints()
				_G[bName]:SetPoint("TOPLEFT", LootFrame, "TOPLEFT", 6, -(6 + 18))
			else
				_G[bName]:ClearAllPoints()
				_G[bName]:SetPoint("TOP", _G["LootButton" .. lastshown], "BOTTOM", 0, -8)
			end

			lastshown = index
		
			color.r = color.r or 0.6
			color.g = color.g or 0.6
			color.b = color.b or 0.6

			_G[bName].r = color.r
			_G[bName].g = color.g
			_G[bName].b = color.b

			_G[bName]:SetNormalTexture("")
			_G[bName]:SetHighlightTexture("")
			_G[bName]:SetPushedTexture("")
			_G[bName]:SetDisabledTexture("")

			_G[bName .. "NameFrame"]:SetTexture("")

			_G[bName]:SetBackdropBorderColor(color.r, color.g, color.b)
			_G[bName .. "Background"]:SetVertexColor(color.r, color.g, color.b, 1/3)
			_G[bName .. "Background"]:Show()

			_G[bName]:SetHitRectInsets(0, -148, 0, 0)
		else
			_G[bName .. "Background"]:Hide()
		end
	end
	
	LootFrame:SetHeight(numshown * (32 + 8) + 18 + 4 + ((LootFrameUpButton:IsShown() or LootFrameDownButton:IsShown()) and 32 or 0))
end

styleLootFrame = function()
	LootFrame:SetSize(190, 32)
	LootFrame:SetHitRectInsets(0, 0, 0, 0)

	gUI:HideObject(LootFrameBg)
	gUI:HideObject(LootFrameInset)
	gUI:HideObject(LootFramePortraitFrame)
	gUI:DisableTextures(LootFrame)
	
	LootFrame:SetBackdrop(M("Backdrop", "SimpleBorder"))
	LootFrame:SetBackdropColor(C.background[1], C.background[2], C.background[3], 0.75)
	LootFrame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
	gUI:CreateUIShadow(LootFrame)

	gUI:SetUITemplate(LootFrameCloseButton, "closebutton", "TOPRIGHT", LootFrame, "TOPRIGHT", -3, -3)
	
	LootFramePrev:SetSize(1/1e4, 1/1e4)
	LootFrameNext:SetSize(1/1e4, 1/1e4)
	
	local title = select(19, LootFrame:GetRegions())
	title:ClearAllPoints()
	title:SetPoint("TOPLEFT", LootFrame, "TOPLEFT", 4, -4)
	title:SetFontObject(gUI_TextFontSmallBoldOutline)

	LootFrameUpButton:ClearAllPoints()
	LootFrameUpButton:SetPoint("BOTTOMLEFT", LootFrame, "BOTTOMLEFT", 0, 0)
	gUI:SetUITemplate(LootFrameUpButton, "arrow", "up")
	
	LootFrameDownButton:ClearAllPoints()
	LootFrameDownButton:SetPoint("BOTTOMRIGHT", LootFrame, "BOTTOMRIGHT", 0, 0)
	gUI:SetUITemplate(LootFrameDownButton, "arrow", "down")

	for index = 1, LOOTFRAME_NUMBUTTONS do
		local bName = "LootButton" .. index

		if (index == 1) then
			_G[bName]:ClearAllPoints()
			_G[bName]:SetPoint("TOPLEFT", LootFrame, "TOPLEFT", 6, -(6 + 18))
		else
			_G[bName]:ClearAllPoints()
			_G[bName]:SetPoint("TOP", _G["LootButton" .. (index - 1)], "BOTTOM", 0, -8)
		end

		_G[bName]:SetSize(32, 32)
		_G[bName]:SetHitRectInsets(0, -146, 0, 0)
		gABT:GetStyleFunction()(_G[bName], "itembutton")

		_G[bName].r = 0.0
		_G[bName].g = 0.0
		_G[bName].b = 0.0

		_G[bName .. "Text"]:ClearAllPoints()
		_G[bName .. "Text"]:SetPoint("LEFT", _G[bName], "RIGHT", 6, 0)
		_G[bName .. "Text"]:SetFontObject(gUI_TextFontTinyBoldOutlineWhite)
		_G[bName .. "Text"]:SetJustifyH("LEFT")
		_G[bName .. "Text"]:SetJustifyV("MIDDLE")
		
		_G[bName .. "Background"] = _G[bName]:CreateTexture(nil, "ARTWORK")
		_G[bName .. "Background"]:SetPoint("TOP", _G[bName], "TOP", 0, -1)
		_G[bName .. "Background"]:SetPoint("BOTTOM", _G[bName], "BOTTOM", 0, 1)
		_G[bName .. "Background"]:SetPoint("LEFT", _G[bName], "RIGHT", 1, 0)
		_G[bName .. "Background"]:SetPoint("RIGHT", _G[bName], "RIGHT", 146, 0)
		_G[bName .. "Background"]:SetTexture(gUI:GetStatusBarTexture())

		_G[bName .. "Count"]:SetSize(32, 32)
		_G[bName .. "Count"]:ClearAllPoints()
		_G[bName .. "Count"]:SetPoint("BOTTOMRIGHT", _G[bName.."IconTexture"], "BOTTOMRIGHT", 1, 2)
		_G[bName .. "Count"]:SetJustifyV("BOTTOM")
		_G[bName .. "Count"]:SetJustifyH("RIGHT")
		_G[bName .. "Count"]:SetFontObject(gUI_DisplayFontTinyOutlineWhite)
		
		_G[bName .. "IconTexture"]:SetParent(_G[bName])
		_G[bName .. "IconTexture"]:ClearAllPoints()
		_G[bName .. "IconTexture"]:SetPoint("TOPLEFT", _G[bName], "TOPLEFT", 3, -3)
		_G[bName .. "IconTexture"]:SetPoint("BOTTOMRIGHT", _G[bName], "BOTTOMRIGHT", -3, 3)
		_G[bName .. "IconTexture"]:SetTexCoord(5/64, 59/64, 5/64, 59/64)

		_G[bName .. "IconQuestTexture"]:SetParent(_G[bName])
		_G[bName .. "IconQuestTexture"]:ClearAllPoints()
		_G[bName .. "IconQuestTexture"]:SetPoint("TOPLEFT", _G[bName], "TOPLEFT", 3, -3)
		_G[bName .. "IconQuestTexture"]:SetPoint("BOTTOMRIGHT", _G[bName], "BOTTOMRIGHT", -3, 3)
		_G[bName .. "IconQuestTexture"]:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		
		local layer, subLayer = _G[bName .. "IconTexture"]:GetDrawLayer()

		_G[bName .. "IconShade"] = gUI:SetUITemplate(_G[bName], "shade")
		_G[bName .. "IconShade"]:SetDrawLayer(layer or "BACKGROUND", subLayer and subLayer + 1 or 2)
		_G[bName .. "IconShade"]:ClearAllPoints()
		_G[bName .. "IconShade"]:SetPoint("TOPLEFT", _G[bName], "TOPLEFT", 3, -3)
		_G[bName .. "IconShade"]:SetPoint("BOTTOMRIGHT", _G[bName], "BOTTOMRIGHT", -3, 3)

		_G[bName .. "IconGloss"] = gUI:SetUITemplate(_G[bName], "gloss")
		_G[bName .. "IconGloss"]:SetDrawLayer(layer or "BACKGROUND", subLayer and subLayer + 2 or 3)
		_G[bName .. "IconGloss"]:ClearAllPoints()
		_G[bName .. "IconGloss"]:SetPoint("TOPLEFT", _G[bName], "TOPLEFT", 3, -3)
		_G[bName .. "IconGloss"]:SetPoint("BOTTOMRIGHT", _G[bName], "BOTTOMRIGHT", -3, 3)

		_G[bName .. "Count"]:SetParent(_G[bName])

		_G[bName]:HookScript("OnEnter", function(self) 
			self:SetBackdropBorderColor(self.r, self.g, self.b)
			_G[self:GetName().."Background"]:SetVertexColor(self.r, self.g, self.b, 2/3)
		end)

		_G[bName]:HookScript("OnLeave", function(self) 
			self:SetBackdropBorderColor(self.r * 3/4, self.g * 3/4, self.b * 3/4)
			_G[self:GetName().."Background"]:SetVertexColor(self.r, self.g, self.b, 1/3)
		end)

	end
end

styleMoneyWonFrame = function(self)
	if (self.styled) then return end

	gUI:HideObject(self.Background)
	gUI:HideObject(self.IconBorder)
	
	gUI:SetUITemplate(self, "backdrop")
	
	self.Label:SetFontObject(gUI_TextFontSmallBoldOutline)
	self.Amount:SetFontObject(gUI_DisplayFontNormalOutlineWhite)
	
	local s = self:GetHeight() - 16
	
	self.IconHolder = CreateFrame("Frame", nil, self)
	self.IconHolder:SetSize(s, s)
	self.IconHolder:SetPoint("LEFT", self, "LEFT", 8, 0)

	gUI:SetUITemplate(self.IconHolder, "backdrop")
	gUI:SetUITemplate(self.IconHolder, "gloss", self.Icon)
	gUI:SetUITemplate(self.IconHolder, "shade", self.Icon)
	
	self.Icon:SetParent(self.IconHolder)
	self.Icon:SetSize(s - 6, s - 6)
	self.Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	self.Icon:ClearAllPoints()
	self.Icon:SetPoint("TOPLEFT", self.IconHolder, "TOPLEFT", 3, -3)
	self.Icon:SetPoint("BOTTOMRIGHT", self.IconHolder, "BOTTOMRIGHT", -3, 3)

	self.styled = true
end

postUpdateLootWonFrame = function(self)
	if (self.hyperlink) then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(self.hyperlink)
		local color = ITEM_QUALITY_COLORS[itemRarity]
		if (color) then
			self.IconHolder:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			self.IconHolder:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3])
		end
	end
end

styleLootWonFrame = function(self)
	if (self.styled) then return end
	
	gUI:HideObject(self.Background)
	gUI:HideObject(self.IconBorder)
	gUI:HideObject(self.glow)
	gUI:HideObject(self.shine)
	
	gUI:SetUITemplate(self, "backdrop")

	self.Label:SetFontObject(gUI_TextFontSmallBoldOutline)
	self.Label:ClearAllPoints()
	self.Label:SetPoint("TOPLEFT", self, "TOPLEFT", 84, -12)
	self.Label:SetJustifyH("LEFT")
	self.Label:SetJustifyV("TOP")

	self.ItemName:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
	self.ItemName:ClearAllPoints()
	self.ItemName:SetPoint("TOPLEFT", self, "TOPLEFT", 84, -40)
	self.ItemName:SetJustifyH("LEFT")
	self.ItemName:SetJustifyV("MIDDLE")

	self.RollValue:SetFontObject(gUI_DisplayFontSmallOutlineWhite)
	
	local s = self:GetHeight() - 24
	
	self.IconHolder = CreateFrame("Frame", nil, self)
	self.IconHolder:SetSize(s, s)
	self.IconHolder:SetPoint("LEFT", self, "LEFT", 8, 0)

	gUI:SetUITemplate(self.IconHolder, "backdrop")
	gUI:SetUITemplate(self.IconHolder, "gloss", self.Icon)
	gUI:SetUITemplate(self.IconHolder, "shade", self.Icon)
	
	self.Icon:SetParent(self.IconHolder)
	self.Icon:SetSize(s - 6, s - 6)
	self.Icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	self.Icon:ClearAllPoints()
	self.Icon:SetPoint("TOPLEFT", self.IconHolder, "TOPLEFT", 3, -3)
	self.Icon:SetPoint("BOTTOMRIGHT", self.IconHolder, "BOTTOMRIGHT", -3, 3)
	
	
	-- self.newShine = F.Shine:New(self, nil, nil, 3)
	-- self:HookScript("OnShow", function(self) self.newShine:Start() end)
	
	self.styled = true
end

styleBonusRollFrame = function(self)
end

styleWinFrames = function()
	styleMoneyWonFrame(BonusRollMoneyWonFrame)
	for i = 1, #MONEY_WON_ALERT_FRAMES do
		styleMoneyWonFrame(MONEY_WON_ALERT_FRAMES[i])
	end

	styleLootWonFrame(BonusRollLootWonFrame)
	for i = 1, #LOOT_WON_ALERT_FRAMES do
		styleLootWonFrame(LOOT_WON_ALERT_FRAMES[i])
		postUpdateLootWonFrame(LOOT_WON_ALERT_FRAMES[i])
	end
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- this fails with spy/tellmewhen enabled... how come?

	holder = CreateFrame("Frame", nil, UIParent)
	holder:SetSize(190, 210) -- approx lootframe size with 4 visible lines. (or is 3 the maximum...?)
	self:PlaceAndSave(holder, L["Loot"], db.place, unpack(defaults.place))
	self:AddObjectToFrameGroup(holder, "floaters")
	
	UIPARENT_MANAGED_FRAME_POSITIONS["GroupLootFrame1"] = nil
	
	styleLootFrame()
	hooksecurefunc("LootFrame_Update", postUpdateLootFrame)
	hooksecurefunc("LootFrame_Show", postUpdateLootFramePosition) -- position update
	self:RegisterEvent("LOOT_OPENED", postUpdateLootFrame)
	self:RegisterEvent("LOOT_SLOT_CHANGED", postUpdateLootFrame)
	self:RegisterEvent("LOOT_SLOT_CLEARED", postUpdateLootFrame)

	styleRollFrames()
	hooksecurefunc("GroupLootContainer_Update", postUpdateRollFramePositions) -- position update

	self:RegisterEvent("CHAT_MSG_LOOT", postUpdateRollChoices)
	self:RegisterEvent("START_LOOT_ROLL", postUpdateRollFrames)	
	
	styleWinFrames()
	hooksecurefunc("MoneyWonAlertFrame_ShowAlert", styleWinFrames)
	hooksecurefunc("LootWonAlertFrame_ShowAlert", styleWinFrames)
	
end
