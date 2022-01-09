local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Chat", true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T

local module = parent:NewModule("Bubbles", "GP_AceEvent-3.0")
module.updater = CreateFrame("Frame", "GUI4ChatBubbleWatcher", WorldFrame)
module.updater:SetFrameStrata("TOOLTIP")

-- Lua API
local abs, floor = math.abs, math.floor
local ipairs, pairs, select = ipairs, pairs, select
local tostring = tostring

local WorldFrame = WorldFrame

local bubbles = {}
local colors = gUI4:GetColors()
local numChildren, numBubbles = -1, 0
local NONE = gUI4:GetMedia("Texture", "Empty"):GetPath()
local BUBBLE_TEXTURE = [[Interface\Tooltips\ChatBubble-Background]]

local BUILD = tonumber((select(2, GetBuildInfo()))) -- current game client build
local LEGION_720 = BUILD >= 24015
local LEGION_725 = BUILD >= 24367

local defaults = {
	profile = {
		enabled = true,
		fontsize = 12,
		alpha = .25
	}
}

local function getPadding()
	return module.db.profile.fontsize / 1.2
end

-- let the bubble size scale from 400 to 660ish (font size 22)
local function getMaxWidth()
	return 400 + floor((module.db.profile.fontsize - 12)/22 * 260)
end

local function getBackdrop(scale) 
	return {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],  
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
		edgeSize = 16 * scale,
		insets = {
			left = 2.5 * scale,
			right = 2.5 * scale,
			top = 2.5 * scale,
			bottom = 2.5 * scale
		}
	}
end

local function updateConfig()
	T = parent:GetActiveTheme()
end

------------------------------------------------------------------------------
-- 	Namebubble Detection & Update Cycle
------------------------------------------------------------------------------
local updater = module.updater

-- check whether the given frame is a bubble or not
function updater:IsBubble(bubble)
	if (bubble.IsForbidden and bubble:IsForbidden()) then
		return
	end
	local name = bubble.GetName and bubble:GetName()
	local region = bubble.GetRegions and bubble:GetRegions()
	if name or (not region) then 
		return 
	end
	local texture = region.GetTexture and region:GetTexture()
	return texture and (texture == BUBBLE_TEXTURE)
end

local offsetX, offsetY = 0, -100 -- todo: move this into the theme
function updater:OnUpdate(elapsed)
	local children = select("#", WorldFrame:GetChildren())
	if numChildren ~= children then
		for i = 1, children do
			local frame = select(i, WorldFrame:GetChildren())
			if not(bubbles[frame]) and self:IsBubble(frame) then
				self:InitBubble(frame)
			end
		end
		numChildren = children
	end
	
	-- bubble, bubble.text = original bubble and message
	-- bubbles[bubble], bubbles[bubble].text = our custom bubble and message
	local scale = WorldFrame:GetHeight()/UIParent:GetHeight()
	for bubble in pairs(bubbles) do
		if bubble:IsShown() then
			local blizzTextWidth = floor(bubble.text:GetWidth())
			local blizzTextHeight = floor(bubble.text:GetHeight())
			local point, anchor, rpoint, blizzX, blizzY = bubble.text:GetPoint()
			local r, g, b = bubble.text:GetTextColor()
			bubbles[bubble].color[1] = r
			bubbles[bubble].color[2] = g
			bubbles[bubble].color[3] = b
			if blizzTextWidth and blizzTextHeight and point and rpoint and blizzX and blizzY then
				if not bubbles[bubble]:IsShown() then
					bubbles[bubble]:SetAlpha(0)
					bubbles[bubble]:Show()
					bubbles[bubble]:StartFadeIn(.25, 1)
				end
				local msg = bubble.text:GetText()
				if msg and (bubbles[bubble].last ~= msg) then
					bubbles[bubble].text:SetText(msg or "")
					bubbles[bubble].text:SetTextColor(r, g, b)
					bubbles[bubble].last = msg
					local sWidth = bubbles[bubble].text:GetStringWidth()
					local maxWidth = getMaxWidth()
					if sWidth > maxWidth then
						bubbles[bubble].text:SetWidth(maxWidth)
					else
						bubbles[bubble].text:SetWidth(sWidth)
					end
				end
				local space = getPadding()
				local ourTextWidth = bubbles[bubble].text:GetWidth()
				local ourTextHeight = bubbles[bubble].text:GetHeight()
				local ourX = floor(offsetX + (blizzX - blizzTextWidth/2)/scale - (ourTextWidth-blizzTextWidth)/2) -- chatbubbles are rendered at BOTTOM, WorldFrame, BOTTOMLEFT, x, y
				local ourY = floor(offsetY + blizzY/scale - (ourTextHeight-blizzTextHeight)/2) -- get correct bottom coordinate
				local ourWidth = floor(ourTextWidth + space*2)
				local ourHeight = floor(ourTextHeight + space*2)
				bubbles[bubble]:Hide() -- hide while sizing and moving, to gain fps
				bubbles[bubble]:SetSize(ourWidth, ourHeight)
				local oldX, oldY = select(4, bubbles[bubble]:GetPoint())
				if not(oldX and oldY) or ((abs(oldX - ourX) > .5) or (abs(oldY - ourY) > .5)) then -- avoid updates if we can. performance. 
					bubbles[bubble]:ClearAllPoints()
					bubbles[bubble]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", ourX, ourY)
				end
				bubbles[bubble]:SetBackdropColor(0, 0, 0, module.db.profile.alpha)
				bubbles[bubble]:SetBackdropBorderColor(.15, .15, .15, module.db.profile.alpha)
				bubbles[bubble]:Show() -- show the bubble again
			end
			-- bubble:SetBackdropColor(0, 0, 0, .5)
			-- bubble:SetBackdropBorderColor(.15, .15, .15, .5)
			bubble.text:SetTextColor(r, g, b, 0)
		else
			if bubbles[bubble]:IsShown() then
				bubbles[bubble]:StartFadeOut()
			else
				bubbles[bubble].last = nil -- to avoid repeated messages not being shown
			end
		end
	end
end

function updater:HideBlizzard(bubble)
	local r, g, b = bubble.text:GetTextColor()
	bubbles[bubble].color[1] = r
	bubbles[bubble].color[2] = g
	bubbles[bubble].color[3] = b
	bubble.text:SetTextColor(r, g, b, 0)
	for region, texture in pairs(bubbles[bubble].regions) do
		region:SetTexture(nil)
	end
end

function updater:ShowBlizzard(bubble)
	bubble.text:SetTextColor(bubbles[bubble].color[1], bubbles[bubble].color[2], bubbles[bubble].color[3], 1)
	for region, texture in pairs(bubbles[bubble].regions) do
		region:SetTexture(texture)
	end
end

function updater:InitBubble(bubble)
	numBubbles = numBubbles + 1

	local space = getPadding()
	bubbles[bubble] = LMP:NewChain(CreateFrame("Frame", nil, self.bubblebox)) :Hide() :SetFrameStrata("BACKGROUND") :SetBackdrop(getBackdrop(1)) .__EndChain
	bubbles[bubble].text = LMP:NewChain("FontString", nil, bubbles[bubble]) :SetPoint("BOTTOMLEFT", space, space) :SetFontObject(ChatFontNormal) :SetFontSize(module.db.profile.fontsize) :SetFontStyle(nil) :SetShadowOffset(1.25, -1.25) :SetShadowColor(0, 0, 0, 1) .__EndChain
	bubbles[bubble].regions = {}
	bubbles[bubble].color = { unpack(colors.chat.normal) }
	gUI4:ApplyFadersToFrame(bubbles[bubble])
	bubbles[bubble]:SetFadeOut(.1)

	-- gather up info about the existing blizzard bubble
	for i = 1, bubble:GetNumRegions() do
		local region = select(i, bubble:GetRegions())
		if region:GetObjectType() == "Texture" then
			bubbles[bubble].regions[region] = region:GetTexture()
		elseif region:GetObjectType() == "FontString" then
			bubble.text = region
		end
	end

	-- hide the blizzard bubble
	self:HideBlizzard(bubble)
end

function module:ApplySettings()
	for bubble, our in pairs(bubbles) do
		local font, size, style = our.text:GetFont()
		if size ~= self.db.profile.fontsize then
			our.text:SetFontSize(self.db.profile.fontsize)
			local space = getPadding()
			our.text:ClearAllPoints()
			our.text:SetPoint("BOTTOMLEFT", space, space)
			our.last = nil -- trigger a size update
		end
		local r, g, b, a = our:GetBackdropColor()
		if abs(a - self.db.profile.alpha) > .02 then
			our:SetBackdropColor(r, g, b, self.db.profile.alpha)
		end
		r, g, b, a = our:GetBackdropBorderColor()
		if abs(a - self.db.profile.alpha) > .02 then
			our:SetBackdropBorderColor(r, g, b, self.db.profile.alpha)
		end
	end
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Chat", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["Bubbles"],
			args = {
				header = {
					order = 1, 
					type = "description",
					name = L["|n|cffffd200" .. "Chat Bubbles" .. "|r"]
				},
				description = {
					order = 2, 
					type = "description",
					name = L["Goldpaw's Chat features custom chat bubbles. These bubbles were designed to be far less intrusive than the default chat bubbles, and meant to encourage a far more immersive gaming experience. Here you can toggle them or change their settings."]
				},
				enabled = {
					order = 10,
					type = "toggle",
					name = L["Use custom chat bubbles."],
					desc = L["Replaces the default chat bubbles with a set of less intrusive bubbles, allowing for a far more immersive gaming experience."],
					width = "full",
					get = function() return self.db.profile.enabled end,
					set = function(info, value)
						self.db.profile.enabled = value
						if value then 
							self:Start()
						else
							self:Stop()
						end
					end
				},
				header2 = {
					order = 20, 
					type = "description",
					name = L["|n|cffffd200" .. "Opacity" .. "|r"]
				},
				description2 = {
					order = 21, 
					type = "description",
					name = L["Set the opacity of the chat bubble background. A higher value makes the chat easier to read, but can also be more intrusive as it covers more of the background."]
				},
				alpha = {
					order = 22, 
					type = "range",
					min = 0, max = .5, step = .05,
					name = "",
					desc = "",
					disabled = function() return not self.db.profile.enabled end,
					get = function() return self.db.profile.alpha end,
					set = function(info, value)
						self.db.profile.alpha = value
						self:ApplySettings()
					end
				},
				header3 = {
					order = 30, 
					type = "description",
					name = L["|n|cffffd200" .. "Size" .. "|r"]
				},
				description3 = {
					order = 31, 
					type = "description",
					name = L["Set the size of the font used within the chat bubbles. As with the opacity, a higher value makes it easier to read, but at the cost of immersion."]
				},
				fontsize = {
					order = 32, 
					type = "select",
					style = "dropdown",
					values = {
						[12] = "12",
						[13] = "13",
						[14] = "14",
						[15] = "15",
						[16] = "16",
						[18] = "18",
						[20] = "20",
						[22] = "22"
					},
					name = "",
					desc = L["Select the size of the font used within the chat bubbles."],
					disabled = function() return not self.db.profile.enabled end,
					get = function() return self.db.profile.fontsize end,
					set = function(info, value)
						if value ~= self.db.profile.fontsize then
							self.db.profile.fontsize = value
							self:ApplySettings()
						end
					end
				}
			}
		}
	})
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Bubbles", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	updateConfig()
	
	-- this will be our bubble parent
	self.bubblebox = CreateFrame("Frame", nil, UIParent)
	self.bubblebox:SetAllPoints()
	self.bubblebox:Hide()
	
	-- give the updater a reference to the bubble parent
	self.updater.bubblebox = self.bubblebox

	-- Thanks to Blizzard making chat bubbles in instances secure in 7.2.5, 
	-- we're going to forcefully disable them while in instances. 
	-- If the user turns them back on manually, they will show, 
	-- but our script to skin them won't be running. 
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBubbleDisplay")
end

function module:UpdateBubbleDisplay()
	local _, instanceType = IsInInstance()
	if (instanceType == "none") then
		SetCVar("chatBubbles", 1)
		self.updater:SetScript("OnUpdate", self.updater.OnUpdate)
	else
		self.updater:SetScript("OnUpdate", nil)
		SetCVar("chatBubbles", 0) 
	end
end

function module:Start()
	self:UpdateBubbleDisplay()
	self.bubblebox:Show()
	for bubble in pairs(bubbles) do
		self.updater:HideBlizzard(bubble)
	end
end

function module:Stop()
	self:UpdateBubbleDisplay()
	self.bubblebox:Hide()
	for bubble in pairs(bubbles) do
		self.updater:ShowBlizzard(bubble)
	end
end

function module:OnEnable()
	if self.db.profile.enabled then
		self:Start()
	end
end

function module:OnDisable()
	self:Stop()
end
