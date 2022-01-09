local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Chat", true)
if not parent then return end

local module = parent:NewModule("Windows", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LMP = GP_LibStub("GP_LibMediaPlus-1.0")
local T

-- Lua API
local _G = _G
local tostring = tostring
local tinsert = table.insert
local pairs, ipairs, unpack, select = pairs, ipairs, unpack, select

-- WoW API
local FCF_Tab_OnClick = FCF_Tab_OnClick
local IsShiftKeyDown = IsShiftKeyDown
local UIFrameFadeRemoveFrame = UIFrameFadeRemoveFrame

local styled = {}

local defaults = {
	profile = {
		enabled = true,
		clampToScreen = true, -- lock the chatframes inside the boundaries of the screen. 
		indentedWordWrap = true, -- when a message spans multiple lines, indent the wrapped lines.
		visibility = {
			hideButtonFrame = true,
			hideEditBox = true,
			hideTabHeader = true
		},
		fading = {
			enabled = true, -- whether or not to fade out the chat
			timeVisible = 20, -- time visible after last message before starting the fade
			timeFading = 3 -- time spent fading out
		}
	}
}

-- We have to set the insets here before blizzard has a chance to move them 
-- update: clamprectinsets seems to have no effect whatsoever anymore on chat windows :S
-- for i = 1, NUM_CHAT_WINDOWS do
	-- local frame = _G["ChatFrame" .. i]
	-- frame:SetClampedToScreen(true)
	-- frame:SetClampRectInsets(-20, 20, 20, -(20 + 32 + 10))
	-- frame:SetHitRectInsets(0, 0, 0, 0)
-- end

local function updateConfig()
	T = parent:GetActiveTheme()
end

local function setAlpha(frame)
	if not frame.oldAlpha then return end
	for index, value in pairs(CHAT_FRAME_TEXTURES) do
		if not(value:find("Tab")) then
			local object = _G[frame:GetName() .. value]
			if object:IsShown() then
				UIFrameFadeRemoveFrame(object)
				object:SetAlpha(frame.oldAlpha)
			end
		end
	end
end

function module:GetFrameRegistry(frame)
	if not styled[frame] then
		styled[frame] = { hidden = {}, cache = {} }
	end
	return styled[frame]
end

function module:KillMany(frame, ...)
	local registry = self:GetFrameRegistry(frame)
	local name = frame:GetName()
	local object
	for i = 1, select("#", ...) do
		object = _G[name .. select(i, ...)]
		if object then
			LMP:Kill(object)
		end
	end
end

function module:ReviveMany(frame, ...)
	local registry = self:GetFrameRegistry(frame)
	local name = frame:GetName()
	local object
	for i = 1, select("#", ...) do
		object = _G[name .. select(i, ...)]
		if object then
			LMP:Revive(object)
		end
	end
end

function module:CacheTextures(frame, ...)
	local registry = self:GetFrameRegistry(frame)
	local name = frame:GetName()
	local object
	for i = 1, select("#", ...) do
		object = _G[name .. select(i, ...)]
		if object then
			registry.cache[object] = object:GetTexture()
		end
	end
end

function module:ClearTextures(frame, ...)
	local registry = self:GetFrameRegistry(frame)
	local name = frame:GetName()
	local object
	for i = 1, select("#", ...) do
		object = _G[name .. select(i, ...)]
		if object then
			if not registry.cache[object] then
				self:CacheTextures(frame, select(i, ...)) -- cache before clearing
			end
			object:SetTexture("")
		end
	end
end

function module:RestoreCachedTextures(frame, ...)
	local registry = self:GetFrameRegistry(frame)
	local name = frame:GetName()
	local object
	for i = 1, select("#", ...) do
		object = _G[name .. select(i, ...)]
		if object then
			if registry.cache[object] then
				object:SetTexture(registry.cache[object])
			end
		end
	end
end

function module:SetUpFrame(frame)
	local registry = self:GetFrameRegistry(frame)
	local name = frame:GetName()

	LMP:NewChain(frame) :SetHitRectInsets(0, 0, 0, 0) :SetClampedToScreen(self.db.profile.clampToScreen) :SetClampRectInsets(-20, 20, 20, -(20 + 32 + 10)) :SetFading(self.db.profile.fading.enabled) :SetTimeVisible(self.db.profile.fading.timeVisible) :SetFadeDuration(self.db.profile.fading.timeFading) :SetIndentedWordWrap(self.db.profile.indentedWordWrap) :EndChain()
	
	if not(self.db.profile.fading.enabled) then
		frame:ScrollToBottom() -- make the chat fade back in if we disable fading
	end
	
	if self.db.profile.visibility.hideButtonFrame then
		if not registry.hidden.buttonframe then
			self:KillMany(frame, "ButtonFrame")
			-- self:KillMany(frame, "ButtonFrameUpButton", "ButtonFrameDownButton", "ButtonFrameBottomButton", "ButtonFrameMinimizeButton", "ButtonFrame")
			-- for _,v in pairs(CHAT_FRAME_TEXTURES) do
				-- if v:find("ButtonFrame") then
					-- self:ClearTextures(frame, name .. v)
				-- end
			-- end
			registry.hidden.buttonframe = true
		end
	else
		if registry.hidden.buttonframe then
			self:ReviveMany(frame, "ButtonFrame")
			-- self:ReviveMany(frame, "ButtonFrame", "ButtonFrameUpButton", "ButtonFrameDownButton", "ButtonFrameBottomButton", "ButtonFrameMinimizeButton")
			-- for _,v in pairs(CHAT_FRAME_TEXTURES) do
				-- if v:find("ButtonFrame") then
					-- self:RestoreCachedTextures(frame, name .. v)
				-- end
			-- end
			-- for reasons I care not to dig into, the buttonFrame has been parented to the UI parent
			frame.buttonFrame:SetParent(frame)
			frame.buttonFrame:Show()
			frame.buttonSide = nil
			FCF_UpdateButtonSide(frame)
			registry.hidden.buttonframe = false
		end
	end
	
	if self.db.profile.visibility.hideEditBox then
		if not registry.hidden.editbox then
			self:ClearTextures(frame, "EditBoxLeft", "EditBoxRight", "EditBoxMid", "EditBoxFocusLeft", "EditBoxFocusMid", "EditBoxFocusRight")
			registry.hidden.editbox = true 
		end
	else
		if registry.hidden.editbox then
			self:RestoreCachedTextures(frame, "EditBoxLeft", "EditBoxRight", "EditBoxMid", "EditBoxFocusLeft", "EditBoxFocusMid", "EditBoxFocusRight")
			registry.hidden.editbox = false
		end
	end
 
	if self.db.profile.visibility.hideTabHeader then
		if not registry.hidden.tab then
			self:ClearTextures(frame, "TabLeft", "TabMiddle", "TabRight", "TabSelectedLeft", "TabSelectedMiddle", "TabSelectedRight", "TabHighlightLeft", "TabHighlightMiddle", "TabHighlightRight")
			registry.cache.tabFont = _G[name.."TabText"]:GetFontObject()
			registry.hidden.tab = true 
		end
		_G[name.."TabText"]:Hide()
		registry.tabAlpha = _G[name.."Tab"]:GetAlpha()
		_G[name.."Tab"]:SetAlpha(1)
		_G[name.."Tab"].SetAlpha = function(self, alpha) 
			registry.tabAlpha = alpha
			UIFrameFadeRemoveFrame(self)
		end
		_G[name.."TabText"]:SetFontObject(SystemFont_Shadow_Med3)
		_G[name.."TabText"]:SetFont(SystemFont_Shadow_Med3:GetFont())
	else
		if registry.hidden.tab then
			self:RestoreCachedTextures(frame, "TabLeft", "TabMiddle", "TabRight", "TabSelectedLeft", "TabSelectedMiddle", "TabSelectedRight", "TabHighlightLeft", "TabHighlightMiddle", "TabHighlightRight")
			_G[name.."TabText"]:SetFontObject(registry.cache.tabFont)
			_G[name.."TabText"]:SetFont(registry.cache.tabFont:GetFont())
			registry.hidden.tab = false
		end
		_G[name.."TabText"]:Show()
		_G[name.."Tab"]:SetAlpha(registry.tabAlpha or 1)
		_G[name.."Tab"].SetAlpha = nil -- will default it to its default meta method for this
		FCFTab_UpdateAlpha(frame)
	end

	LMP:NewChain(_G[name.."EditBox"]) :Hide() :SetAltArrowKeyMode(false) :ClearAllPoints() :SetPoint("TOP", frame, "BOTTOM", 0, -7) :SetPoint("RIGHT", frame, "RIGHT", 3, 0) :SetPoint("LEFT", frame, "LEFT", -3, 0) :HookScript("OnEditFocusGained", function(self) self:Show() end) :HookScript("OnEditFocusLost", function(self) self:Hide() end) :EndChain()

	_G[name.."EditBoxHeader"]:SetFontObject(SystemFont_Shadow_Med3)
	_G[name.."EditBox"]:SetFontObject(SystemFont_Shadow_Med3)

	_G[name.."Tab"]:HookScript("OnEnter", function() 
		if self.db.profile.visibility.hideTabHeader then
			_G[name .. "TabText"]:Show() 
		end
	end)
	_G[name.."Tab"]:HookScript("OnLeave", function() 
		if self.db.profile.visibility.hideTabHeader then
			_G[name .. "TabText"]:Hide() 
		end
	end)
	_G[name.."Tab"]:HookScript("OnClick", function() 
		if self.db.profile.visibility.hideTabHeader then
			_G[name.."EditBox"]:Hide() 
		end
	end)
	if (_G[name.."Tab"].conversationIcon) then 
		LMP:Kill(_G[name.."Tab"].conversationIcon)
	end
		
	_G[name.."ClickAnywhereButton"]:HookScript("OnEnter", function() 
		if self.db.profile.visibility.hideTabHeader then
			_G[name .. "TabText"]:Show() 
		end
	end)
	_G[name.."ClickAnywhereButton"]:HookScript("OnLeave", function() 
		if self.db.profile.visibility.hideTabHeader then
			_G[name .. "TabText"]:Hide() 
		end
	end)
	_G[name.."ClickAnywhereButton"]:HookScript("OnClick", function() 
		FCF_Tab_OnClick(_G[name]) -- click the tab to actually select this frame
		_G[name.."EditBox"]:Hide() -- hide the annoying half-transparent editbox 
	end)
	
end

function module:SetUpLog(logFrame)
	if logFrame == ChatFrame2 then
		CombatLogQuickButtonFrame_CustomTexture:SetTexture(0, 0, 0, .25)
		for i = 1, CombatLogQuickButtonFrame_Custom:GetNumChildren() do
			local child = select(i, CombatLogQuickButtonFrame_Custom:GetChildren())
			if child:GetObjectType() == "Texture" then
				child:SetTexture("")
			end
		end
		
		-- todo: bake this into the theme
		LMP:NewChain(CombatLogQuickButtonFrame_CustomAdditionalFilterButton) 
			:SetNormalTexture(gUI4:GetMedia("Texture", "TrackerButtonGrid", 32, 32, "Warcraft"):GetPath()) 
			:SetPushedTexture(gUI4:GetMedia("Texture", "TrackerButtonGrid", 32, 32, "Warcraft"):GetPath()) 
			:SetHighlightTexture(gUI4:GetMedia("Texture", "TrackerButtonGrid", 32, 32, "Warcraft"):GetPath()) 
			:SetDisabledTexture(gUI4:GetMedia("Texture", "TrackerButtonDisabled", 32, 32, "Warcraft"):GetPath()) 
		:EndChain()
		
		LMP:NewChain(CombatLogQuickButtonFrame_CustomAdditionalFilterButton:GetNormalTexture()) 
			:SetTexCoord(gUI4:GetMedia("Texture", "TrackerButtonGrid", 32, 32, "Warcraft"):GetGridTexCoord(1))
		:EndChain()
		
		LMP:NewChain(CombatLogQuickButtonFrame_CustomAdditionalFilterButton:GetPushedTexture()) 
			:SetTexCoord(gUI4:GetMedia("Texture", "TrackerButtonGrid", 32, 32, "Warcraft"):GetGridTexCoord(2))
		:EndChain()

		LMP:NewChain(CombatLogQuickButtonFrame_CustomAdditionalFilterButton:GetHighlightTexture()) 
			:SetTexCoord(gUI4:GetMedia("Texture", "TrackerButtonGrid", 32, 32, "Warcraft"):GetGridTexCoord(1))
			:SetAlpha(.3)
		:EndChain()
		
	end
end

function module:PLAYER_ENTERING_WORLD()
	LMP:Kill(ChatFrameMenuButton)
	LMP:Kill(FriendsMicroButton or QuickJoinToastButton) -- 7.1 fix
end

function module:ApplySettings()
	for _,name in ipairs(CHAT_FRAMES) do 
		self:SetUpFrame(_G[name])
	end
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Fading", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["Chat"],
			args = {
				title1 = {
					order = 1,
					type = "description",
					name = L["|n|cffffd200" .. "Chat Frame Fading" .. "|r"]
				},
				description1 = {
					order = 2,
					type = "description",
					name = L["By default the messages in the chat frames fade out after a certain amount of time. Here you can toggle this behavior or change its settings.|n"]
				},
				fading = {
					order = 10,
					type = "toggle",
					name = L["Fade out the chat messages."],
					desc = L["Fades out chat messages after a certain period of time. Uncheck to keep the chat visible at all times."],
					width = "full",
					get = function() return self.db.profile.fading.enabled end,
					set = function(info, value)
						self.db.profile.fading.enabled = value
						self:ApplySettings()
					end
				},				
				header2 = {
					order = 14, 
					type = "description",
					name = L["|n|cffffd200" .. "Display Duration" .. "|r"]
				},
				description2 = {
					order = 15, 
					type = "description",
					name = L["Set how long in seconds the chat messages remain visible before fading out."]
				},
				timeVisible = {
					order = 16, 
					type = "range",
					min = 0, max = 120, step = 1, -- 120 seconds is what blizzard use
					name = "",
					desc = "",
					disabled = function() return not self.db.profile.fading.enabled end,
					get = function() return self.db.profile.fading.timeVisible end,
					set = function(info, value)
						self.db.profile.fading.timeVisible = value
						self:ApplySettings()
					end
				},
				header3 = {
					order = 19, 
					type = "description",
					name = L["|n|cffffd200" .. "Fade Duration" .. "|r"]
				},
				description3 = {
					order = 20, 
					type = "description",
					name = L["Set how much time the chat messages will spend fading out in seconds."]
				},
				timeFading = {
					order = 21, 
					type = "range",
					min = 0.5, max = 5, step = .5,
					name = "",
					desc = "",
					disabled = function() return not self.db.profile.fading.enabled end,
					get = function() return self.db.profile.fading.timeFading end,
					set = function(info, value)
						self.db.profile.fading.timeFading = value
						self:ApplySettings()
					end
				}
			}
		}
	})

	gUI4:RegisterModuleOptions("Chat", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["Windows"],
			args = {
				title1 = {
					order = 1,
					type = "description",
					name = L["|n|cffffd200" .. "Window Positioning" .. "|r"]
				},
				description1 = {
					order = 2,
					type = "description",
					name = L["By default the chat frames are confined to the screen borders. Here you can change the settings for this.|n"]
				},
				clampToScreen = {
					order = 10,
					type = "toggle",
					name = L["Clamp the chat windows to the screen."],
					desc = L["Uncheck to freely move the windows where you want, including to the very edges of the screen, or to other screens."],
					width = "full",
					get = function() return self.db.profile.clampToScreen end,
					set = function(info, value)
						self.db.profile.clampToScreen = value
						self:ApplySettings()
					end
				},
				title2 = {
					order = 20,
					type = "description",
					name = L["|n|cffffd200" .. "Display" .. "|r"]
				},
				description2 = {
					order = 21,
					type = "description",
					name = L["Goldpaw's UI hides a lot of the graphics in the chat frames by default, to make them smoother and more immersive. Here you can toggle the visibility of these elements.|n"]
				},
				hideButtonFrame = {
					order = 22,
					type = "toggle",
					name = L["Hide the navigation buttons."],
					desc = L["The button frame is where the buttons to navigate within the chat frame resides. In Goldpaw's Chat you can use the mouse wheel to scroll up or down, and by holding down the Shift key you can move to the top or bottom of the frame."],
					width = "full",
					get = function() return self.db.profile.visibility.hideButtonFrame end,
					set = function(info, value)
						self.db.profile.visibility.hideButtonFrame = value
						self:ApplySettings()
					end
				},
				hideTabHeader = {
					order = 23,
					type = "toggle",
					name = L["Hide the chat tab background."],
					desc = L["Hides the chat tab backgrounds. Does not hide the actual tabs, as you can still mouse over them to see them."],
					width = "full",
					get = function() return self.db.profile.visibility.hideTabHeader end,
					set = function(info, value)
						self.db.profile.visibility.hideTabHeader = value
						self:ApplySettings()
					end
				},				
				hideEditBox = {
					order = 24,
					type = "toggle",
					name = L["Hide the input box background."],
					desc = L["Hides the background and highlight textures of the input boxes."],
					width = "full",
					get = function() return self.db.profile.visibility.hideEditBox end,
					set = function(info, value)
						self.db.profile.visibility.hideEditBox = value
						self:ApplySettings()
					end
				},
				-- indent wrapped lines for higher readability
				-- fade out the chat
				-- fade out chat after x seconds
				-- fade duration x seconds
			}
		}
	})
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Windows", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	-- Fired when chat window settings are loaded into the client.
	-- To avoid nil bugs in relation to their position and methods like :GetLeft() and GetRight(), 
	-- we need to wait for this event before the initial setup.
	self:RegisterEvent("UPDATE_CHAT_WINDOWS")
end

function module:StartSetup()
	updateConfig()

	-- style all the initial frames
	-- for _,name in ipairs(CHAT_FRAMES) do 
		-- self:SetUpFrame(_G[name])
	-- end

	-- 2016-12-02-1740: 
	-- Discovered that removing these will make FCF_ResetChatWindows() and FCF_ResetAllWindows() bug out!
    --UIPARENT_MANAGED_FRAME_POSITIONS["ChatFrame1"] = nil
    --UIPARENT_MANAGED_FRAME_POSITIONS["ChatFrame2"] = nil

	UIPARENT_MANAGED_FRAME_POSITIONS["ChatFrame1"] = {baseY = true, yOffset = 0, bottomLeft = 0, justBottomRightAndStance = 0, overrideActionBar = 0, petBattleFrame = 0, bonusActionBar = 1, pet = 1, watchBar = 1, maxLevel = 1, point = "BOTTOMLEFT", rpoint = "BOTTOMLEFT", xOffset = 0}
	
	UIPARENT_MANAGED_FRAME_POSITIONS["ChatFrame2"] = {baseY = true, yOffset = 0, bottomRight = 0, overrideActionBar = 0, petBattleFrame = 0, bonusActionBar = 1, rightLeft = 0, rightRight = 0, watchBar = 1, maxLevel = 1, point = "BOTTOMRIGHT", rpoint = "BOTTOMRIGHT", xOffset = 0}

	
	-- style the combat log
	if IsAddOnLoaded("Blizzard_CombatLog") then
		self:SetUpLog(ChatFrame2)
	else
		local proxy
		proxy = function(_, addon)
			if addon == "Blizzard_CombatLog" then
				self:SetUpLog(ChatFrame2)
				self:UnregisterEvent("ADDON_LOADED", proxy)
			end
		end
		self:RegisterEvent("ADDON_LOADED", proxy)
	end

	-- hook the toastframe to the main chat window
	BNToastFrame:HookScript("OnShow", function(self)
		self:ClearAllPoints()
		self:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 16)
	end)
	
	-- style any additional BNet frames when they are opened
	hooksecurefunc("FCF_OpenTemporaryWindow", function(chatType, chatTarget, sourceChatFrame, selectWindow)
		local frame = FCF_GetCurrentChatFrame()
		self:SetUpFrame(frame)
	end)

	-- avoid mouseover alpha change, yet keep the background textures
	hooksecurefunc("FCF_FadeInChatFrame", setAlpha)
	hooksecurefunc("FCF_FadeOutChatFrame", setAlpha)
	hooksecurefunc("FCF_SetWindowAlpha", setAlpha)
	
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

	self:ApplySettings() 
end

function module:UPDATE_CHAT_WINDOWS()
	self:StartSetup()
end

function module:OnEnable()
	CHAT_FRAME_BUTTON_FRAME_MIN_ALPHA = 0
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function module:OnDisable()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end
