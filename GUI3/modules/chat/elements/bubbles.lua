--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local parent = gUI:GetModule("Chat")
local module = parent:NewModule("Bubbles")
local E = gUI:GetDataBase("emoticons")
local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local db
local Style, Update
local IsBubble, UpdateBubbles
local MAX_CHATBUBBLE_WIDTH = 300
local BlizzardTexture = [[Interface\Tooltips\ChatBubble-Background]]
local bubbles = {}
local scalefixes = {}

-- the initial styling function for the bubble. called once.
Style = function(bubble)
	for i = 1, bubble:GetNumRegions() do
		local region = select(i, bubble:GetRegions())
		if (region:GetObjectType() == "Texture") then
			region:SetTexture(nil)
		elseif (region:GetObjectType() == "FontString") then
			bubble.text = region
		end
	end
	
	local scale = WorldFrame:GetHeight()/UIParent:GetHeight()
	bubble:SetBackdrop({
		bgFile = gUI:GetBlankTexture();
		edgeFile = gUI:GetBlankTexture();
		tile = false; 
		tileSize = 0; 
		edgeSize = 1 * scale;
		insets = {
			left = -1 * scale; 
			right = -1 * scale;
			top = -1 * scale;
			bottom = -1 * scale;
		}
	})
	bubble:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
	bubble:SetBackdropColor(C["background"][1], C["background"][2], C["background"][3], 0.75)
	
	tinsert(scalefixes, bubble)

	bubbles[bubble] = true
end

-- update function for each bubble, to size and stuff
Update = function(bubble)
	if not(bubble:IsShown()) then 
		bubble.text.lastText = nil
		return 
	end

	if (db.collapseBubbles) then
		if (bubble:IsMouseOver()) then
			bubble.text:SetWordWrap(1)
		elseif (bubble.text:CanWordWrap() == 1) then
			bubble.text:SetWordWrap(0)
		end 
	else
		bubble.text:SetWordWrap(1)
	end 

	MAX_CHATBUBBLE_WIDTH = max(bubble:GetWidth(), MAX_CHATBUBBLE_WIDTH)

	local text = bubble.text:GetText() or ""

	if (text == bubble.text.lastText) then
		if (db.collapseBubbles) then
			bubble.text:SetWidth(bubble.text:GetWidth())
		end

		return 
	end

	bubble:SetBackdropColor(C["background"][1], C["background"][2], C["background"][3], 0.75)
	bubble:SetBackdropBorderColor(bubble.text:GetTextColor())

	-- only change the font, not the font object, as that will mess with the colors
	local font, size, style = ChatFrame1:GetFont()
	bubble.text:SetFont(font, size * WorldFrame:GetHeight()/UIParent:GetHeight(), style)
	
	-- change raid icon abbreviations into actual icons
	local t
	for tag in gmatch(text, "%b{}") do
		t = strlower(gsub(tag, "[{}]", ""))
		if (ICON_TAG_LIST[t] and ICON_LIST[ICON_TAG_LIST[t]]) then
			text = gsub(text, tag, ICON_LIST[ICON_TAG_LIST[t]] .. "0|t")
		end
	end
	
	-- add emoticons
	if (db.useIconsInBubbles) then
		text = F.EmoTheString(text) or text
	end
	
	bubble.text:SetText(text)    
	bubble.text.lastText = text  
	bubble.text:SetWidth(min(bubble.text:GetStringWidth(), MAX_CHATBUBBLE_WIDTH - 14))
end

IsBubble = function(self)
	if (self:GetName()) or not(self:GetRegions()) then 
		return 
	end
	return (self:GetRegions():GetTexture() == BlizzardTexture)
end

-- the lengths we go to for pixel perfection...
UpdateScales = function(self, event, ...)
	local scale = WorldFrame:GetHeight()/UIParent:GetHeight()
	local font, size, style = ChatFrame1:GetFont()
	for _,bubble in pairs(scalefixes) do
		bubble:SetBackdrop({
			bgFile = gUI:GetBlankTexture();
			edgeFile = gUI:GetBlankTexture();
			tile = false; 
			tileSize = 0; 
			edgeSize = 1 * scale;
			insets = {
				left = -1 * scale; 
				right = -1 * scale;
				top = -1 * scale;
				bottom = -1 * scale;
			}
		})
		bubble.text:SetFont(font, size * scale, style)
	end
end

module.bubbles = 0
UpdateBubbles = function(self)
	-- find new bubbles
	local bubbles = bubbles
	local i, f, kids
	kids = select("#", WorldFrame:GetChildren())
	
	if (kids ~= self.bubbles) then
		for i = 1, kids do
			f = select(i, WorldFrame:GetChildren())
			if (IsBubble(f)) and not(bubbles[self]) then 
				Style(f)
			end
		end
		self.bubbles = kids
	end
	
	-- update existing bubbles
	for bubble,_ in pairs(bubbles) do
		Update(bubble)
	end
end

module.OnInit = function(self)
	db = self:GetParent():GetCurrentOptionsSet() -- get the chat settings
end

module.OnEnable = function(self)
	self:ScheduleRepeatingTimer(1/10, UpdateBubbles)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateBubbles)
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", UpdateScales)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateScales)
	self:RegisterEvent("UI_SCALE_CHANGED", UpdateScales)
end

module.OnDisable = function(self)
	self:CancelTimer(UpdateBubbles)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", UpdateBubbles)
	self:UnregisterEvent("DISPLAY_SIZE_CHANGED", UpdateScales)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", UpdateScales)
	self:UnregisterEvent("UI_SCALE_CHANGED", UpdateScales)
end