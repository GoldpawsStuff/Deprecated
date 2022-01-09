--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Chat")
module:SetDefaultModuleState(false)

local _G = _G
local ipairs, pairs, select, unpack = ipairs, pairs, select, unpack
local strfind, strmatch = string.find, string.match
local gsub, strlower, gmatch = string.gsub, string.lower, string.gmatch
local min, max = math.min, math.max

local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
local ChatFrame_RemoveMessageEventFilter = ChatFrame_RemoveMessageEventFilter
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetQuestDifficultyColor = GetQuestDifficultyColor
local GetMinimapZoneText = GetMinimapZoneText
local ChangeChatColor = ChangeChatColor
local ChatFrame_AddChannel = ChatFrame_AddChannel
local ChatFrame_AddMessageGroup = ChatFrame_AddMessageGroup
local ChatFrame_ReceiveAllBNConversations = ChatFrame_ReceiveAllBNConversations
local ChatFrame_ReceiveAllPrivateMessages = ChatFrame_ReceiveAllPrivateMessages
local ChatFrame_RemoveChannel = ChatFrame_RemoveChannel
local ChatFrame_RemoveMessageGroup = ChatFrame_RemoveMessageGroup
local GetChatWindowInfo = GetChatWindowInfo
local GetScreenHeight = GetScreenHeight
local GetScreenWidth = GetScreenWidth
local FCF_DockFrame = FCF_DockFrame
local FCF_OpenNewWindow = FCF_OpenNewWindow
local FCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
local FCF_SetLocked = FCF_SetLocked
local FCF_SetWindowAlpha = FCF_SetWindowAlpha
local FCF_SetWindowColor = FCF_SetWindowColor
local FCF_SetWindowName = FCF_SetWindowName
local FCF_UnDockFrame = FCF_UnDockFrame
local SetChatWindowSavedDimensions = SetChatWindowSavedDimensions
local ToggleChatColorNamesByClassGroup = ToggleChatColorNamesByClassGroup
local SetCVar = SetCVar
local WorldFrame = WorldFrame

local L, C, F, M, db
local E = gUI:GetDataBase("emoticons")
local WoW51 = (select(4, GetBuildInfo())) >= 50100

local AddMessage
local AlignMe, ColorEditBox 
local PrepareFrame, SetUpChatFrame, SetPosAndSize, SetFrameFont, StyleCombatLog
local stickyChannels = { 
	(WoW51) and "INSTANCE_CHAT" or "BATTLEGROUND", 
	"CHANNEL", 
	-- "CHANNEL1", 
	-- "CHANNEL2", 
	-- "CHANNEL3", 
	-- "CHANNEL4", 
	-- "CHANNEL5", 
	-- "CHANNEL6", 
	-- "CHANNEL7", 
	-- "CHANNEL8", 
	-- "CHANNEL9", 
	-- "CHANNEL10", 
	-- "GUILD", 
	"OFFICER", 
	-- "PARTY", 
	-- "RAID", 
	"RAID_WARNING",
	"WHISPER",
	"BN_WHISPER"
	-- "SAY" 
}

--[[
	Timestamps: (http://www.lua.org/pil/22.1.html)
		%a	abbreviated weekday name (e.g., Wed)
		%A	full weekday name (e.g., Wednesday)
		%b	abbreviated month name (e.g., Sep)
		%B	full month name (e.g., September)
		%c	date and time (e.g., 09/16/98 23:48:10)
		%d	day of the month (16) [01-31]
		%H	hour, using a 24-hour clock (23) [00-23]
		%I	hour, using a 12-hour clock (11) [01-12]
		%M	minute (48) [00-59]
		%m	month (09) [01-12]
		%p	either "am" or "pm" (pm)
		%S	second (10) [00-61]
		%w	weekday (3) [0-6 = Sunday-Saturday]
		%x	date (e.g., 09/16/98)
		%X	time (e.g., 23:48:10)
		%Y	full year (1998)
		%y	two-digit year (98) [00-99]
		%%	the character `%´
]]--

local defaults = {
	-- autosetup
	autoAlignMain = true; -- auto-align the Main window to the bottom left info panel
	autoAlignLoot = true; -- auto-align the Loot window to the bottom right info panel
	autoSizeMain = true; -- always set set size of the Main window to the minimum
	autoSizeLoot = true; -- always set set size of the Loot window to the minimum
	useLootFrame = true; -- use the Loot frame, and maintain its channels and groups
	
	-- chat bubble module
	collapseBubbles = true; -- shrink and expand chatbubbles on mouseover
	
	-- chat frame settings
	abbreviateChannels = true; -- abbreviate channel names
	abbreviateStrings = true; -- abbreviate strings for a cleaner chat
	removeBrackets = true; -- no brackets in the chat
	autoAlignChat = true; -- auto-align all chat windows based on position
	useIcons = true; -- use emoticons in the chat
	useIconsInBubbles = true; -- use emoticons in chat bubbles

	-- extra sound settings
	enableWhisperSound = true;

	-- timestamps
	useTimeStamps = true;
	useTimeStampsInLoot = false; -- display the timestamps in the "Loot" window
	timeStampFormat = "%H:%M"; 
	timeStampColor = { 0.6, 0.6, 0.6 };
	
	-- work in progress, none of the following options are there yet
	easyChatInit = false;
}

AddMessage = function(self, msg, ...)
	if not(self) or not(msg) or not(self.BlizzAddMessage) then 
		return self, msg, ... 
	end

	-- apply all special filters
	for i,filter in module:IterateMessageFilters() do
		msg = filter(self, msg)
	end

	-- uncomment to break the chat
	-- for development purposes only. weird stuff happens when used. 
	--	msg = gsub(msg, "|", "||")
	
	-- add timestamps, but separate between the 'Loot' frame and others, 
	-- as they have separate options
	local isLootWindow = ((GetChatWindowInfo(self:GetID())) == L["Loot"])
	if ((isLootWindow) and (db.useTimeStampsInLoot))
	or (not(isLootWindow) and (db.useTimeStamps)) then
		local timeString = BetterDate(db.timeStampFormat, time())

		if not(db.removeBrackets) then
			timeString = "[" .. timeString .. "]"
		end
		
		local timeStamp = ("|cFF%s%s|r"):format(module:RGBToHex(unpack(db.timeStampColor)), timeString)

		if (db.autoAlignChat) and (self:GetJustifyH() == "RIGHT") then
			msg = msg .. " " .. timeStamp
		else
			msg = timeStamp .. " " .. msg
		end
	end
	
	self:BlizzAddMessage(msg, ...)
end

AlignMe = function(self, ...) 
	-- avoid stack overflow
	if (self.aligning) or not(db.autoAlignChat) then 
		return 
	end
	self.aligning = true
	local w, r, l = GetScreenWidth(), self:GetRight() or 0, self:GetLeft() or 0
	if ((w - r) < l) then
		self:SetJustifyH("RIGHT")
		self:SetIndentedWordWrap(false)
	else
		self:SetJustifyH("LEFT")
		self:SetIndentedWordWrap(true)
	end
	self.aligning = nil
end

ColorEditBox = function(editbox)
	if not(editbox:GetBackdrop()) then 
		return 
	end

	if (ACTIVE_CHAT_EDIT_BOX) then
		local type = editbox:GetAttribute("chatType")
		
		if (type == "CHANNEL") then
			local id = GetChannelName(editbox:GetAttribute("channelTarget"))
			if (id == 0) then	
				editbox:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
				editbox:SetBackdropColor(unpack(C["overlay"]))
				gUI:SetUIShadowColor(editbox, unpack(C["shadow"]))
			else 
				-- 4.3
				local r,g,b = 1, 1, 1
				if (type) and (ChatTypeInfo[type..id]) then
					r = ChatTypeInfo[type..id].r or r
					g = ChatTypeInfo[type..id].g or g
					b = ChatTypeInfo[type..id].b or b
				end
				editbox:SetBackdropBorderColor(r, g, b)
				editbox:SetBackdropColor(r/5, g/5, b/5)
				gUI:SetUIShadowColor(editbox, r/2, g/2, b/2)
			end
		else
			-- 4.3
			local r,g,b = 1, 1, 1
			if (type) and (ChatTypeInfo[type]) then
				r = ChatTypeInfo[type].r or r
				g = ChatTypeInfo[type].g or g
				b = ChatTypeInfo[type].b or b
			end
			editbox:SetBackdropBorderColor(r, g, b)
			editbox:SetBackdropColor(r/5, g/5, b/5)
			gUI:SetUIShadowColor(editbox, r/2, g/2, b/2)
		end
	else
		editbox:SetBackdropBorderColor(gUI:GetBackdropBorderColor())
		editbox:SetBackdropColor(unpack(C["overlay"]))
		gUI:SetUIShadowColor(editbox, unpack(C["shadow"]))
	end
end

PrepareFrame = function(frame)
	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetHitRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)
	frame:SetMinResize(F.GetDefaultChatFrameWidth(), F.GetDefaultChatFrameHeight())
end

SetPosAndSize = function(frame)
	local EasyChat = module:GetModule("EasyChat")
	if (EasyChat) then
		PrepareFrame(frame)
		
		local name = frame:GetName()
		if (name == "ChatFrame1") then
			if (db.autoAlignMain) then EasyChat:SetPoint("main") end
			if (db.autoSizeMain) then EasyChat:SetSize("main") end
		else
			local cName, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(frame:GetID())
			if not(docked) then
				if (db.useLootFrame) and (cName == L["Loot"]) then
					if (db.autoAlignLoot) then EasyChat:SetPoint("loot") end
					if (db.autoSizeLoot) then EasyChat:SetSize("loot") end
				end
			end
		end
	end
end

SetFrameFont = function(frame)
	-- frame:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
	-- frame:SetFont(gUI_TextFontSmallBoldOutlineWhite:GetFont())

	local name = frame:GetName()
	_G[name.."TabText"]:SetFontObject(gUI_TextFontSmallWhite)
	_G[name.."TabText"]:SetFont(gUI_TextFontSmallWhite:GetFont())
	_G[name.."EditBoxHeader"]:SetFontObject(gUI_TextFontSmallWhite)
	_G[name.."EditBox"]:SetFontObject(gUI_TextFontSmallWhite)
	
	-- v2
	-- _G[name.."TabText"]:SetFontObject(gUI_TextFontSmallBoldOutlineWhite)
	-- _G[name.."TabText"]:SetFont(gUI_TextFontSmallBoldOutlineWhite:GetFont())
	-- _G[name.."EditBoxHeader"]:SetFontObject(gUI_TextFontSmallWhite)
	-- _G[name.."EditBox"]:SetFontObject(gUI_TextFontSmallWhite)
end

SetUpChatFrame = function(frame)
	local name = frame:GetName()
	
	SetFrameFont(frame)
	PrepareFrame(frame)

	if (frame.styled) then 
		return 
	end	
	
	frame.styled = true

	if not(frame.BlizzAddMessage) and (frame.AddMessage) and (frame ~= _G["ChatFrame2"]) then
		frame.BlizzAddMessage = frame.AddMessage
		frame.AddMessage = AddMessage
	end

	------------------------------------------------------------------------------------------------------------
	-- 	Alignment
	------------------------------------------------------------------------------------------------------------
	AlignMe(frame)

	hooksecurefunc(frame, "SetPoint", AlignMe)
	hooksecurefunc(frame, "SetAllPoints", AlignMe)
	hooksecurefunc(frame, "ClearAllPoints", AlignMe)
	hooksecurefunc(frame, "SetJustifyH", AlignMe)
	
	-- the tab is dragged, not the frame
	if (not _G[name.."Tab"]._onDragHooked) then
		_G[name.."Tab"]:HookScript("OnDragStart", function() AlignMe(frame) end)
		_G[name.."Tab"]:HookScript("OnDragStop", function() AlignMe(frame) end)
		_G[name.."Tab"]:HookScript("OnReceiveDrag", function() AlignMe(frame) end)

		_G[name.."Tab"]._onDragHooked = true
	end
	
	------------------------------------------------------------------------------------------------------------
	-- 	Background Textures
	------------------------------------------------------------------------------------------------------------
	for i,v in pairs(CHAT_FRAME_TEXTURES) do
		if (strfind(v, "ButtonFrame")) then
			_G[name .. v]:SetTexture("")
		end
	end
	
	------------------------------------------------------------------------------------------------------------
	-- 	Buttons
	------------------------------------------------------------------------------------------------------------
	gUI:KillObject(_G[name.."ButtonFrameUpButton"])
	gUI:KillObject(_G[name.."ButtonFrameDownButton"])
	gUI:KillObject(_G[name.."ButtonFrameBottomButton"])
	gUI:KillObject(_G[name.."ButtonFrameMinimizeButton"])
	gUI:KillObject(_G[name.."ButtonFrame"])

	------------------------------------------------------------------------------------------------------------
	-- 	EditBox
	------------------------------------------------------------------------------------------------------------
	_G[name.."EditBoxLeft"]:SetTexture("")
	_G[name.."EditBoxRight"]:SetTexture("")
	_G[name.."EditBoxMid"]:SetTexture("")
	_G[name.."EditBoxFocusLeft"]:SetTexture("")
	_G[name.."EditBoxFocusMid"]:SetTexture("")
	_G[name.."EditBoxFocusRight"]:SetTexture("")
 
	_G[name.."EditBox"]:Hide()
	_G[name.."EditBox"]:SetAltArrowKeyMode(false)
	_G[name.."EditBox"]:SetHeight(F.fixPanelHeight())
	_G[name.."EditBox"]:ClearAllPoints()
	_G[name.."EditBox"]:SetPoint("TOP", frame, "BOTTOM", 0, -7)
	_G[name.."EditBox"]:SetPoint("RIGHT", frame, "RIGHT", 3, 0)
	_G[name.."EditBox"]:SetPoint("LEFT", frame, "LEFT", -3, 0)

	gUI:SetUITemplate(_G[name.."EditBox"], "backdrop")
	gUI:CreateUIShadow(_G[name.."EditBox"])
	-- _G[name.."EditBox"]:SetUITemplate("simplebackdrop")
--	_G[name.."EditBox"]:CreateUIShadow(5) -- we want a really visible shadow around active editboxes
	
	_G[name.."EditBox"]:HookScript("OnEditFocusGained", function(self) self:Show() end)
	_G[name.."EditBox"]:HookScript("OnEditFocusLost", function(self) self:Hide() end)

	hooksecurefunc("ChatEdit_UpdateHeader", ColorEditBox)

	------------------------------------------------------------------------------------------------------------
	-- 	Tabs
	------------------------------------------------------------------------------------------------------------
	_G[name.."TabLeft"]:SetTexture("")
	_G[name.."TabMiddle"]:SetTexture("")
	_G[name.."TabRight"]:SetTexture("")
	_G[name.."TabSelectedLeft"]:SetTexture("")
	_G[name.."TabSelectedMiddle"]:SetTexture("")
	_G[name.."TabSelectedRight"]:SetTexture("")
	_G[name.."TabHighlightLeft"]:SetTexture("")
	_G[name.."TabHighlightMiddle"]:SetTexture("")
	_G[name.."TabHighlightRight"]:SetTexture("")

	_G[name.."Tab"]:SetAlpha(1)
	_G[name.."Tab"].SetAlpha = UIFrameFadeRemoveFrame

	-- if not(frame.isTemporary) then
		_G[name .. "TabText"]:Hide()

		_G[name.."Tab"]:HookScript("OnEnter", function(self) _G[name .. "TabText"]:Show() end)
		_G[name.."Tab"]:HookScript("OnLeave", function(self) _G[name .. "TabText"]:Hide() end)
		
		_G[name.."ClickAnywhereButton"]:HookScript("OnEnter", function(self) _G[name .. "TabText"]:Show() end)
		_G[name.."ClickAnywhereButton"]:HookScript("OnLeave", function(self) _G[name .. "TabText"]:Hide() end)
	-- end
	
	if (_G[name.."Tab"].conversationIcon) then 
		gUI:KillObject(_G[name.."Tab"].conversationIcon)
	end
	
	_G[name.."Tab"]:HookScript("OnClick", function() _G[name.."EditBox"]:Hide() end)
	_G[name.."ClickAnywhereButton"]:HookScript("OnClick", function() 
		FCF_Tab_OnClick(_G[name]) -- click the tab to actually select this frame
		_G[name.."EditBox"]:Hide() -- hide the annoying half-transparent editbox 
	end)
	
end

StyleCombatLog = function()
	gUI:SetUITemplate(CombatLogQuickButtonFrame_CustomAdditionalFilterButton, "arrow", "down")
	CombatLogQuickButtonFrame_CustomTexture:SetTexture(0, 0, 0, 0.3)
end

module.PostUpdateSettings = function(self)
	local Abbreviations = self:GetModule("Abbreviations")
	if (Abbreviations) then
		Abbreviations:GetModule("Brackets"):SetEnabled(db.removeBrackets)
		Abbreviations:GetModule("Channels"):SetEnabled(db.abbreviateChannels)
		Abbreviations:GetModule("Strings"):SetEnabled(db.abbreviateStrings)
	end

	local Emoticons = self:GetModule("Emoticons", true)
	if (Emoticons) then
		Emoticons:SetEnabled(db.useIcons)
	end
	
end

-- our own filter system
--
-- this filters all messages to the frame, 
-- and filters the whole string including the channel name
--
-- the function will be called as msg = func(chatFrame, unfilteredmsg)
local messageFilters = {}
module.RegisterMessageFilter = function(self, func)
	self:argCheck(func, 1, "function")
	tinsert(messageFilters, func)
end

module.UnregisterMessageFilter = function(self, func)
	self:argCheck(func, 1, "function")
	for i = #messageFilters, 1, -1  do
		if (messageFilters[i] == func) then
			tremove(messageFilters, i)
		end
	end
end

module.IterateMessageFilters = function(self)
	return pairs(messageFilters)
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	
	------------------------------------------------------------------------------------------------------------
	-- 	Styling
	------------------------------------------------------------------------------------------------------------
	--
	-- style all the initial frames
	for _,name in ipairs(CHAT_FRAMES) do 
		SetUpChatFrame(_G[name])
	end

	-- style the combat log
	if (IsAddOnLoaded("Blizzard_CombatLog")) then
		StyleCombatLog()
	else
		local proxy
		proxy = function(self, event, addon)
			if (addon == "Blizzard_CombatLog") then
				StyleCombatLog()
				module:UnregisterEvent("ADDON_LOADED", proxy)
			end
		end
		module:RegisterEvent("ADDON_LOADED", proxy)
	end
	
	-- style and position the toastframe
	-- BNToastFrame:SetUITemplate("simplebackdrop-indented")
	-- BNToastFrameCloseButton:SetUITemplate("closebutton")
	BNToastFrame:HookScript("OnShow", function(self)
		self:ClearAllPoints()
		self:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 16)
	end)

	--
	-- style any additional BNet frames when they are opened
	hooksecurefunc("FCF_OpenTemporaryWindow", function(chatType, chatTarget, sourceChatFrame, selectWindow)
		local frame = FCF_GetCurrentChatFrame()
		SetUpChatFrame(frame)
	end)
	
	hooksecurefunc("FCF_SetTemporaryWindowType", function(chatFrame, chatType, chatTarget)
		SetFrameFont(chatFrame)
	end)
	
	-- here we do our magic to remove the silly alphachange on mouseover, 
	-- yet allowing the user to change the alpha to his/hers preference! YAY!
	-- 4 hours of headache to figure this one out. It better work! >:(
	--
	local SetAlpha = function(frame)
		if not(frame.oldAlpha) then return end
		for index, value in pairs(CHAT_FRAME_TEXTURES) do
			if not(value:find("Tab")) then
				local object = _G[frame:GetName() .. value]
				if (object:IsShown()) then
					UIFrameFadeRemoveFrame(object)
					object:SetAlpha(frame.oldAlpha)
				end
			end
		end
		
	end
	hooksecurefunc("FCF_FadeInChatFrame", function(frame) SetAlpha(frame) end)
	hooksecurefunc("FCF_FadeOutChatFrame", function(frame) SetAlpha(frame) end)
	hooksecurefunc("FCF_SetWindowAlpha", function(frame) SetAlpha(frame) end)
	
	-- set position and size of the "Main" and "Loot" windows
	local postUpdateSizeAndPos = function()
		for _,name in ipairs(CHAT_FRAMES) do 
			SetPosAndSize(_G[name])
		end
	end
	postUpdateSizeAndPos()
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD", postUpdateSizeAndPos)
	self:RegisterEvent("PLAYER_ALIVE", postUpdateSizeAndPos)
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", postUpdateSizeAndPos)
	self:RegisterEvent("UI_SCALE_CHANGED", postUpdateSizeAndPos)
	self:RegisterEvent("VARIABLES_LOADED", postUpdateSizeAndPos)

	------------------------------------------------------------------------------------------------------------
	-- 	Channels
	------------------------------------------------------------------------------------------------------------
	-- make pretty much everything sticky, so you can press ENTER to directly speak in Trade, Officer, etc etc
	for _,v in ipairs(stickyChannels) do 
		ChatTypeInfo[v].sticky = 1
	end

	------------------------------------------------------------------------------------------------------------
	-- 	Functionality
	------------------------------------------------------------------------------------------------------------
	--
	-- allow SHIFT + MouseWheel to scroll to the top or bottom
	hooksecurefunc("FloatingChatFrame_OnMouseScroll", function(self, delta)
		if (delta < 0) then
			if IsShiftKeyDown() then
				self:ScrollToBottom()
			end
		elseif (delta > 0) then
			if IsShiftKeyDown() then
				self:ScrollToTop()
			end
		end
	end)
	
	-- initialize all submodules
	for i,v in self:IterateModules() do v:Init() end

	-- enable forced modules
	self:GetModule("Abbreviations"):Enable()
	self:GetModule("BattleNetLinks"):Enable()
	self:GetModule("Bubbles"):Enable()
	self:GetModule("EasyChat"):Enable()
	self:GetModule("Filters"):Enable()
	self:GetModule("TellTarget"):Enable()
	self:GetModule("URLCopy"):Enable()
	
	------------------------------------------------------------------------------------------------------------
	-- 	Sounds
	------------------------------------------------------------------------------------------------------------
	local playWhisperSound = function(self, event, msg, ...)
		if (db.enableWhisperSound) then
			if (msg:sub(1,3) == "OQ,") then 
				return
			end
			PlaySoundFile(M("Sound", "Chat Whisper"), "Master") -- PlaySound("TellMessage", "Master") 
		end
	end
	self:RegisterEvent("CHAT_MSG_WHISPER", playWhisperSound)
	self:RegisterEvent("CHAT_MSG_BN_WHISPER", playWhisperSound)
	
	------------------------------------------------------------------------------------------------------------
	-- 	Post Update All
	------------------------------------------------------------------------------------------------------------
	self:PostUpdateSettings()
	
	------------------------------------------------------------------------------------------------------------
	-- 	Kill Blizzard Options
	------------------------------------------------------------------------------------------------------------
	gUI:KillOption(true, InterfaceOptionsSocialPanelTimestamps)
	--InterfaceOptionsSocialPanelTimestamps:SetScale(0.00001)
	--InterfaceOptionsSocialPanelTimestamps:SetAlpha(0)
	gUI:KillObject(ChatConfigFrameDefaultButton)
	
	local killButtons = function()
		gUI:KillObject(ChatFrameMenuButton)
		gUI:KillObject(FriendsMicroButton)
	end
	self:RegisterEvent("PLAYER_ENTERING_WORLD", killButtons)

	local postUpdateStamps = function()
		SetCVar("showTimestamps", "none")
		CHAT_TIMESTAMP_FORMAT = nil
	end
	self:RegisterEvent("VARIABLES_LOADED", postUpdateStamps)

	killButtons()
	postUpdateStamps()	

	-- create the options menu
	do
		local menuTable = {
			{
				type = "group";
				name = module:GetName();
				order = 1;
				virtual = true;
				children = {
					{ -- title
						type = "widget";
						element = "Title";
						order = 1;
						msg = L["Chat"];
					};
					{ -- subtext
						type = "widget";
						element = "Text";
						order = 2;
						msg = L["Here you can change the settings of the chat windows and chat bubbles. |n|n|cFFFF0000If you wish to change visible chat channels and messages within a chat window, background color, font size, or the class coloring of character names, then Right-Click the chat tab located above the relevant chat window instead.|r"];
					};
					{ -- sound
						type = "group";
						order = 10;
						name = "sound";
						virtual = true;
						children = {
							{ -- whispersound
								type = "widget";
								element = "CheckButton";
								name = "enableWhisperSound";
								order = 10;
								width = "full"; 
								msg = L["Enable sound alerts when receiving whispers or private Battle.net messages."];
								desc = nil;
								set = function(self) 
									db.enableWhisperSound = not(db.enableWhisperSound)
								end;
								get = function() return db.enableWhisperSound end;
							};
						};
					};
					{ -- display
						type = "group";
						order = 20;
						name = "display";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Header";
								order = 1;
								msg = L["Chat Display"];
							};
							{ -- abbreviate channel names
								type = "widget";
								element = "CheckButton";
								name = "abbreviateChannels";
								order = 10;
								width = "full"; 
								msg = L["Abbreviate channel names."];
								desc = nil;
								set = function(self) 
									db.abbreviateChannels = not(db.abbreviateChannels)
									module:PostUpdateSettings()
								end;
								get = function() return db.abbreviateChannels end;
							};
							{ -- abbreviate global strings
								type = "widget";
								element = "CheckButton";
								name = "abbreviateStrings";
								order = 20;
								width = "full"; 
								msg = L["Abbreviate global strings for a cleaner chat."];
								desc = nil;
								set = function(self) 
									db.abbreviateStrings = not(db.abbreviateStrings)
									module:PostUpdateSettings()
								end;
								get = function() return db.abbreviateStrings end;
							};
							{ -- remove brackets
								type = "widget";
								element = "CheckButton";
								name = "removeBrackets";
								order = 30;
								width = "full"; 
								msg = L["Display brackets around player- and channel names."];
								desc = nil;
								set = function(self) 
									db.removeBrackets = not(db.removeBrackets)
									module:PostUpdateSettings()
								end;
								get = function() return not(db.removeBrackets) end;
							};
							{ -- icons
								type = "widget";
								element = "CheckButton";
								name = "useIcons";
								order = 40;
								width = "full"; 
								msg = L["Use emoticons in the chat"];
								desc = nil;
								set = function(self) 
									db.useIcons = not(db.useIcons)
								end;
								get = function() return db.useIcons end;
							};
							{ -- autoalign chat
								type = "widget";
								element = "CheckButton";
								name = "autoAlignChat";
								order = 50;
								width = "full"; 
								msg = L["Auto-align the text depending on the chat window's position."];
								desc = nil;
								set = function(self) 
									db.autoAlignChat = not(db.autoAlignChat)
									module:PostUpdateSettings()
								end;
								get = function() return db.autoAlignChat end;
							};
							{ -- autoalign main chat window
								type = "widget";
								element = "CheckButton";
								name = "autoAlignMain";
								order = 60;
								width = "full"; 
								msg = L["Auto-align the main chat window to the bottom left panel/corner."];
								desc = nil;
								set = function(self) 
									db.autoAlignMain = not(db.autoAlignMain)
								end;
								get = function() return db.autoAlignMain end;
							};
							{ -- autosize main chat window
								type = "widget";
								element = "CheckButton";
								name = "autoSizeMain";
								order = 70;
								width = "full"; 
								msg = L["Auto-size the main chat window to match the bottom left panel size."];
								desc = nil;
								set = function(self) 
									db.autoSizeMain = not(db.autoSizeMain)
								end;
								get = function() return db.autoSizeMain end;
							};
						};
					};
					{ -- timestamps
						type = "group";
						order = 30;
						name = "timestamps";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Header";
								order = 1;
								msg = L["Timestamps"];
							};
							{ -- display timestamps
								type = "widget";
								element = "CheckButton";
								name = "useTimeStamps";
								order = 10;
								width = "full"; 
								msg = L["Show timestamps."];
								desc = nil;
								set = function(self) 
									db.useTimeStamps = not(db.useTimeStamps)
								end;
								get = function() return db.useTimeStamps end;
							};
						};
					};
					{ -- bubbles
						type = "group";
						order = 40;
						name = "bubbles";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Header";
								order = 1;
								msg = L["Chat Bubbles"];
							};
							{ -- collapse bubbles
								type = "widget";
								element = "CheckButton";
								name = "collapseBubbles";
								order = 10;
								width = "full"; 
								msg = L["Collapse chat bubbles"];
								desc = L["Collapses the chat bubbles to preserve space, and expands them on mouseover."];
								set = function(self) 
									db.collapseBubbles = not(db.collapseBubbles)
									module:PostUpdateSettings()
								end;
								get = function() return db.collapseBubbles end;
							};
							{ -- icons in chat bubbles
								type = "widget";
								element = "CheckButton";
								name = "useIconsInBubbles";
								order = 20;
								width = "full"; 
								msg = L["Display emoticons in the chat bubbles"];
								desc = nil;
								set = function(self) 
									db.useIconsInBubbles = not(db.useIconsInBubbles)
									module:PostUpdateSettings()
								end;
								get = function() return db.useIconsInBubbles end;
							};
						};
					};
					{ -- loot
						type = "group";
						order = 50;
						name = "loot";
						virtual = true;
						children = {
							{ -- title
								type = "widget";
								element = "Header";
								order = 1;
								msg = L["Loot Window"];
							};
							{ -- maintain lootframe channels and groups
								type = "widget";
								element = "CheckButton";
								name = "useLootFrame";
								order = 10;
								width = "full"; 
								msg = L["Maintain the channels and groups of the 'Loot' window."];
								desc = nil;
								set = function(self) 
									db.useLootFrame = not(db.useLootFrame)
								end;
								get = function() return db.useLootFrame end;
							};
							{ -- autoalign lootframe
								type = "widget";
								element = "CheckButton";
								name = "autoAlignLoot";
								order = 30;
								width = "full"; 
								msg = L["Auto-align the 'Loot' chat window to the bottom right panel/corner."];
								desc = nil;
								set = function(self) 
									db.autoAlignLoot = not(db.autoAlignLoot)
								end;
								get = function() return db.autoAlignLoot end;
							};
							{ -- autosize lootframe
								type = "widget";
								element = "CheckButton";
								name = "autoSizeLoot";
								order = 40;
								width = "full"; 
								msg = L["Auto-size the 'Loot' chat window to match the bottom right panel size."];
								desc = nil;
								set = function(self) 
									db.autoSizeLoot = not(db.autoSizeLoot)
								end;
								get = function() return db.autoSizeLoot end;
							};
							{ -- timestamps in loot
								type = "widget";
								element = "CheckButton";
								name = "useTimeStampsInLoot";
								order = 20;
								width = "full"; 
								msg = L["Show timestamps."];
								desc = nil;
								set = function(self) 
									db.useTimeStampsInLoot = not(db.useTimeStampsInLoot)
								end;
								get = function() return db.useTimeStampsInLoot end;
							};
						};
					};
				};
			};
		}
		local restoreDefaults = function()
			if (InCombatLockdown()) then 
				print(L["Can not apply default settings while engaged in combat."])
				return
			end
			self:ResetCurrentOptionsSetToDefaults()
		end
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["Chat"], "default", restoreDefaults)
	end
	
end

module.OnEnable = function(self)
end

module.OnDisable = function(self)
end
