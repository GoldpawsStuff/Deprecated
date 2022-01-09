local addon,ns = ...

--[[

developer's blog, october 7th 2015:

This file is SHIT! It's so chaotic it's amazing it even works! 
I really need to step up and fix this. Because this is just waaaaaaaay
below the standards the rest of this user interface has set. 

Damn. This is like discovering an open sewer in your house. 

Eeeew.

]]
local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule(addon, true)
if not parent then return end

local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local T

local module = parent:NewModule("Filters", "GP_AceEvent-3.0")

-- Lua API
local ipairs, select, unpack = ipairs, select, unpack
local strfind, strmatch, gsub = string.find, string.match, string.gsub
local min, max = math.min, math.max

-- WoW API
local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local ChatFrame_RemoveMessageEventFilter = ChatFrame_RemoveMessageEventFilter
local GetCurrentMapAreaID = GetCurrentMapAreaID
local GetRealmName = GetRealmName
local GetTime = GetTime
local SetMapToCurrentZone = SetMapToCurrentZone

-- this is just bad in so many ways
local G_ChatFrame_OnHyperlinkShow = _G.ChatFrame_OnHyperlinkShow 
local Q_ChatFrame_OnHyperlinkShow

--[[
local spam = {
	gold = {
		keyword = {
			"gold"
		},
		content = {
			"%$", "www", "%.com", "%.net", "%.org", ",còm", ",cóm"
		}
	},
	general = {
		content = {
			"anal", "cunt", "rape", "dirge", "murloc", 
			"{rt%d}", "{star}", "{circle}", "{diamond}", "{triangle}", "{moon}", "{square}", "{cross}",
		}
	},
	yell = {
		content = {
			"wts", "wtb", "lfg", "lfm", "selling"
		}
	},
	scam = {
		opener = {
			"^(%[(gm|game([%s]*)master)+%])"
		},
		content = {
			"abnormal", "verify", "confirm", "login", "account", "visit"
		}
	}
}

local captures = {
	escape = {
		"(%|C.-%|r)", "(%|c.-%|r)", -- color
		"(%|T.-%|t)", -- texture 
		"(%|H.-%|h.-%|h)", "(%|H.-%|h)", -- hyperlink
		"(%|K.-%|k.-%|k)", -- bnet friend links
		"(%|%u.-%|%l)" -- any other general hyperlink not yet caught
	},
	url = {
		-- "(%a+)://(%S+)%s?", "%1://%2",
		"http://(%S+)%s?", "https://(%S+)%s?", "ftp://(%S+)%s?",
		"http://%2", "https://%2", "ftp://%2",
		"www%.([_A-Za-z0-9-]+)%.(%S+)%s?", "www.%1.%2",
		"([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", "%1@%2%3%4"
	},
	id = {
		"(@@%d+@@)"
	}
}
]]--

-- goldspam 
local gold = "gold"
local goldSpam = { "%$", "www", "%.com", "%.net", "%.org", ",còm", ",cóm" }

-- account theft
local URLChecker = "www%d*([%s*%.*%s*]+)([%a%d]+)([%s*%.*%s*]+)([%a%d]+)"
local suspiciousContent = { "abnormal", "verify", "confirm", "login", "account", "visit" }
local suspiciousOpeners = { "^(%[(gm|game([%s]*)master)+%])" }

-- retardspam
local yellSpam = { "anal", "cunt", "rape", "dirge", "murloc", "{rt%d}", "{star}", "{circle}", "{diamond}", "{triangle}", "{moon}", "{square}", "{cross}" }
local yellSpam2 = { "wts", "wtb", "lfg", "lfm", "selling" }

--local escapeCapture = "(%|%u.-%|%l)"
local idCapture = "(@@%d+@@)"
local escapeCaptures = {
	"(%|C.-%|r)", "(%|c.-%|r)", -- color
	"(%|T.-%|t)", -- texture 
	"(%|H.-%|h.-%|h)", "(%|H.-%|h)", -- hyperlink
	"(%|K.-%|k.-%|k)", -- bnet friend links
	"(%|%u.-%|%l)" -- any other general hyperlink not yet caught
}
local urlCaptures = {
	-- { "(%a+)://(%S+)%s?", "%1://%2" },
	{ "http://(%S+)%s?", "http://%1" },
	{ "https://(%S+)%s?", "https://%1" },
	{ "ftp://(%S+)%s?", "ftp://%2" },
	{ "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", "www.%1.%2"},
	{ "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", "%1@%2%3%4" }
}

local defaults = {
	profile = {
		enabled = true,
		useSmileys = true, -- changes emoticons into graphical smileys. 
		useUrlsAsHyperlinks = true, -- changes urls into clickable hyperlinks for copy&paste into browsers and stuff
		
		-- abbreviations
		abbreviatePlayerNames = true, -- remove brackets and realm and stuff from player names
		abbreviateChannelNames = true, -- lfg, trade, and custom channels
		abbreviateDescriptions = true, -- x whispers, yells, says and stuff
		colorizePlayerStatus = true, -- colorizes AFK and DND messages
		abbreviateWarnings = true, -- changes raid warnings to use an exclamation mark instead of the full raid warning message
		
		-- public spam
		removeGoldSpam = true, -- light gold filter to avoid the most offensive gold sellers
		removeRetardSpam = true, -- the ton of morons spamming 'anal' and similar.
		removeTradeYelling = true, -- some people use /yell to trade, look for people and so on. sucks.
    
		-- city spam
		removeNPCspam = true, -- spam like Ronin in Dalaran
		removeSleepSpam = true, -- "falls asleep. Zzzzzzz."  this is locale specific
    
		-- private chat spam
		removeScams = true, -- remove common types of scams from people impersonating Game Masters and similar
		
		-- throttle repeated messages 
	}
}

local function updateConfig()
	T = parent:GetActiveTheme()
end

local function removeRealmName(self, event, msg, author, ...)
	local realmName = gsub(GetRealmName(), " ", "")
	if msg:find("-" .. realmName) then
		return false, gsub(msg, "%-"..realmName, ""), author, ...
	end
end

local function formatUrl(msg)
	return "|cffffb200|Hurl:"..msg.."|h"..msg.."|h|r "
end

local counter = 0
local stack = {}
local function pushItem(msg)
	counter = counter + 1
	local id = "@@"..counter.."@@"
	stack[id] = msg
	return id
end
local function pullItem(id)
	local msg = stack[id]
	stack[id] = nil
	local size = select(2, ChatFrame1:GetFont())
	size = min(max(18, size), 24)
	return msg:format(size, size)
end

local emoticons = ns.emoticons
local function pushEmoticon(msg)
	return pushItem(emoticons[msg])
end

local function chatFilter(self, event, msg, ...)
	if not msg then return end
	local db = module.db.profile
	local new, hasEscapes

	-- turn urls into hyperlinks
	if db.useUrlsAsHyperlinks then
		for _,url in ipairs(urlCaptures) do
			if msg:find(url[1]) then
				msg = gsub(msg, url[1], formatUrl(url[2]))
				new = true
			end
		end
	end

	-- encode any escape sequences already there, including newly created hyperlinks
	for _, esc in ipairs(escapeCaptures) do
		if msg:find(esc) then
			msg = msg:gsub(esc, pushItem) 
			hasEscapes = true
		end
	end

	-- encode smileys
	if db.useSmileys then
		for _,smiley in ns.smileyIterator() do
			if msg:find(smiley) then
				msg = msg:gsub(smiley, pushEmoticon)
				new = true
				hasEscapes = true
			end
		end
	end
		
	-- decode all encoded elements into proper escape sequences
	if new then
		if hasEscapes then
			msg = msg:gsub(idCapture, pullItem)
		end
	end
	
	-- return new string, if any
	if new then
		-- return removeRealmName(self, event, new, ...)
		return false, msg, ...
	end
end

local function privateFilter(self, event, msg, ...)
	local author, lang, _, _, status, _, _, _, _, lineID, GUID = ...
	
	-- make sure real GM messages always come through
	if status == "GM" then
		return chatFilter(self, event, msg, ...)
	end
	local new = msg:lower()
	
	-- identify URLs
	local url = new:find(URLChecker)

	-- identify bad openers
	local opener
	for _, word in ipairs(suspiciousOpeners) do
		if new:find(word) then
			opener = true
			break
		end
	end
	
	-- identify bad content
	local content = 0
	for _, word in ipairs(suspiciousContent) do
		if new:find(word) then
			content = content + 1
		end
	end
	
	-- filter this out if we have a bad opener plus an url or suspicious content
	if opener then
		if url or (content > 0) then
			return true
		end
	end

	return chatFilter(self, event, msg, ...)
end

local function publicFilter(self, event, msg, ...)
	local new = msg:lower()

	-- check for gold spammers
	-- we do this by checking for URLs combined with 'gold'
	if new:find(gold) then
		-- identify URLs
		local url = new:find(URLChecker)
		if url then 
			return true
		end
		for _, word in ipairs(goldSpam) do
			if new:find(word) then
				return true
			end
		end
	end
	
	if event == "CHAT_MSG_YELL" then
		-- check for retarded spam by people dragging 
		-- the average IQ of the entire human race down
		for _, word in ipairs(yellSpam) do
			if new:find(word) then
				return true
			end
		end

		-- new trend. sell, buy, and recruit in... /yell
		-- damn dirty apes. that's all I've got to say. >:(
		for _, word in ipairs(yellSpam2) do
			if new:find(word) then
				return true
			end
		end
	end

	return chatFilter(self, event, msg, ...)
end

local function systemFilter(self, event, msg, ...)
	return removeRealmName(self, event, msg, ...)
end

local function sleepFilter(self, event, msg)
	 if msg:find("falls asleep. Zzzzzzz.") then
		return true
	 end
end

-- used to remove channels that are very spammy in cities, without actually removing them
local function cityFilter(self, event, msg, ...)
	return true
end

-- http://www.wowpedia.org/API_SetMapByID
local city = {
	[978] = true, -- Ashran *not strictly a city, but a potentially spammy area nonetheless
	[504] = true, -- Dalaran
	[381] = true, -- Darnassus
	[976] = true, -- Frostwall (Horde Garrison)
	[684] = true, -- Gilneas
	[341] = true, -- Ironforge
	[971] = true, -- Lunarfall (Alliance Garrison)
	[321] = true, -- Orgrimmar
	[480] = true, -- Silvermoon City
	[481] = true, -- Shattrath City
	[811] = true, -- Vale of Eternal Blossoms
	[905] = true, -- Shrine of Seven Stars
	[903] = true, -- Shrine of Two Moons
	[301] = true, -- Stormwind City
	[1009] = true, -- Stormshield
	[471] = true, -- The Exodar
	[362] = true, -- Thunder Bluff
	[382] = true, -- Undercity
	[1011] = true -- Warspear
}

local function OnHyperlinkShow(self, link, text, button)
	if link:sub(1, 3) == "url" then
		local editBox = ChatEdit_ChooseBoxForSend()
		curLink = link:sub(5)
		if not editBox:IsShown() then
			ChatEdit_ActivateChat(editBox)
		end
		editBox:Insert(curLink)
		editBox:HighlightText()
		curLink = nil
		return
	end

	if Q_ChatFrame_OnHyperlinkShow then
		if type(link) == "string" and string.sub(link, 1, 8) == "Wowhead:" then
			Q_ChatFrame_OnHyperlinkShow(self, link, text, button)
			return
		end
	end
	
	G_ChatFrame_OnHyperlinkShow(self, link, text, button)
end

local styled = {}
local queuedMessages = {}
local waiting = true

local cleaner = CreateFrame("Frame", nil, UIParent)
cleaner:Hide()
cleaner:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < 2.5 then return end
	waiting = nil
	module:SendMessage("GUI4_CHAT_READY")
	local spamFrame
	for i = NUM_CHAT_WINDOWS, 1, -1 do
		local frame = _G["ChatFrame"..i]
		local tab = _G["ChatFrame"..i.."Tab"]
		local name = tab:GetText()
		if name == GENERAL then
			spamFrame = frame
			break
		end
	end
	local frame = spamFrame or DEFAULT_CHAT_FRAME
	for i, info in ipairs(queuedMessages) do
		local msg, r, g, b = unpack(info)
		if msg then
			frame:AddMessage(msg, r, g, b)
		end
	end	
	self:Hide()
end)

local function AddMessage(frame, msg, ...)
	-- uncomment to break the chat
	-- for development purposes only. weird stuff happens when used. 
	-- msg = gsub(msg, "|", "||")
	if waiting and (frame == DEFAULT_CHAT_FRAME) then 
		tinsert(queuedMessages, { msg, ... })
		return 
	end 

	-- player names
	msg = msg:gsub("|Hplayer:(.-)-(.-):(.-)|h%[%|c(%w%w%w%w%w%w%w%w)(.-)-(.-)|r%]|h", "|Hplayer:%1-%2:%3|h|c%4%5|r|h") -- player name removing realm
	msg = msg:gsub("|Hplayer:(.-)|h%[(.-)%]|h", "|Hplayer:%1|h%2|h") -- player names with realm
	msg = msg:gsub("|HBNplayer:(.-)|h%[(.-)%]|h", "|HBNplayer:%1|h%2|h")
	
	-- channel names
	msg = msg:gsub("|Hchannel:(%w+):(%d)|h%[(%d)%. (%w+)%]|h", "|Hchannel:%1:%2|h%3.|h") -- numbered channels
	msg = msg:gsub("|Hchannel:(%w+)|h%[(%w+)%]|h", "|Hchannel:%1|h%2|h") -- non-numbered channels 
	
	-- descriptions 
	msg = msg:gsub("^To (.-|h)", "|cffad2424@|r%1")
	msg = msg:gsub("^(.-|h) whispers", "%1")
	msg = msg:gsub("^(.-|h) says", "%1")
	msg = msg:gsub("^(.-|h) yells", "%1")
	
	-- player status messages
	msg = msg:gsub("<"..AFK..">", "|cffFF0000<"..AFK..">|r ")
	msg = msg:gsub("<"..DND..">", "|cffE7E716<"..DND..">|r ")
	
	-- raid warnings
	msg = msg:gsub("^%["..RAID_WARNING.."%]", "|cffff0000!|r")
	
	return frame.old.message(frame, msg, ...)
end

function module:SetUpFrame(frame)
	if styled[frame] then return end
	styled[frame] = true

	frame.old = {}
	frame.old.message = frame.AddMessage
	
	frame.custom = {}
	frame.custom.message = AddMessage
	
	if frame.AddMessage and frame ~= _G["ChatFrame2"] then
		frame.AddMessage = frame.custom.message
	end
end

function module:UpdateFilters()
	SetMapToCurrentZone()
	local mapID = GetCurrentMapAreaID()
	if city[mapID] then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", sleepFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", cityFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", cityFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", cityFilter)
	else
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", sleepFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_SAY", cityFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_YELL", cityFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", cityFilter)
	end
end

function module:PLAYER_ENTERING_WORLD()
	if waiting then
		cleaner:Show()
	end
	self:UpdateFilters()
end

function module:ApplySettings()
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Chat", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["Filters & Smileys"],
			args = {
				header = {
					order = 1, 
					type = "description",
					name = L["|n|cffffd200" .. "Chat Filters" .. "|r"]
				},
				--description = {
				--	order = 2, 
				--	type = "description",
				--	name = L["Goldpaw's Chat adds "]
				--},
				-- smileys
				useSmileys = {
					order = 10,
					type = "toggle",
					name = L["Display smileys in chat."],
					desc = L["Show certain well known emoticons as icons instead of text."],
					width = "full",
					get = function() return self.db.profile.useSmileys end,
					set = function(info, value)
						self.db.profile.useSmileys = not self.db.profile.useSmileys
					end
				},
				-- encode urls 
				useUrlsAsHyperlinks = {
					order = 10,
					type = "toggle",
					name = L["Make URLs clickable."],
					desc = L["Turn URLs into clickable hyperlinks that can be copied into a browser."],
					width = "full",
					get = function() return self.db.profile.useUrlsAsHyperlinks end,
					set = function(info, value)
						self.db.profile.useUrlsAsHyperlinks = not self.db.profile.useUrlsAsHyperlinks
					end
				},
				-- spam removal
				-- scams, threats and gold sellers
				-- retards and dimwits
				-- city filters for npc spam. "Rhonin Filter" ( http://www.curse.com/addons/wow/stfu-rhonin )
			}
		}
	})
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Filters", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()
	
	for _,name in ipairs(CHAT_FRAMES) do 
		self:SetUpFrame(_G[name])
	end

	hooksecurefunc("FCF_OpenTemporaryWindow", function(chatType, chatTarget, sourceChatFrame, selectWindow)
		local frame = FCF_GetCurrentChatFrame()
		self:SetUpFrame(frame)
	end)
end

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "UpdateFilters")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateFilters")

	ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_ALERT", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_BROADCAST", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_CONVERSATION", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", publicFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_BOSS_WHISPER", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", systemFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", privateFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", chatFilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", publicFilter)

	if gUI4:IsAddOnEnabled("Questionable") then
		Q_ChatFrame_OnHyperlinkShow = _G.ChatFrame_OnHyperlinkShow
	end

	_G.ChatFrame_OnHyperlinkShow = OnHyperlinkShow
end

function module:OnDisable()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("ZONE_CHANGED_INDOORS", "UpdateFilters")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateFilters")

	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_CONVERSATION", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_ALERT", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_BROADCAST", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_CONVERSATION", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL", publicFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_GUILD", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_WHISPER", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_OFFICER", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_BOSS_WHISPER", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_WARNING", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", systemFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", privateFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", chatFilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", publicFilter)

	if gUI4:IsAddOnEnabled("Questionable") then
		_G.ChatFrame_OnHyperlinkShow = Q_ChatFrame_OnHyperlinkShow
		Q_ChatFrame_OnHyperlinkShow = nil
	else
		_G.ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
	end

end