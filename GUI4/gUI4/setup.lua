local addon, gUI4 = ...
local build = tonumber((select(2, GetBuildInfo())))
local LEGION = build >= 22124 

-- Lua API
local _G = _G
local ipairs, unpack = ipairs, unpack

-- WoW API
local ChangeChatColor = _G.ChangeChatColor
local ChatFrame_AddChannel = _G.ChatFrame_AddChannel
local ChatFrame_AddMessageGroup = _G.ChatFrame_AddMessageGroup
local ChatFrame_ReceiveAllBNConversations = _G.ChatFrame_ReceiveAllBNConversations
local ChatFrame_ReceiveAllPrivateMessages = _G.ChatFrame_ReceiveAllPrivateMessages
local ChatFrame_RemoveAllMessageGroups = _G.ChatFrame_RemoveAllMessageGroups
local ChatFrame_RemoveChannel = _G.ChatFrame_RemoveChannel
local ChatFrame_RemoveMessageGroup = _G.ChatFrame_RemoveMessageGroup
local FCF_DockFrame = _G.FCF_DockFrame
local FCFDock_SelectWindow = _G.FCFDock_SelectWindow
local FCF_GetChatWindowInfo = _G.FCF_GetChatWindowInfo
local FCF_OpenNewWindow = _G.FCF_OpenNewWindow
local FCF_ResetChatWindows = _G.FCF_ResetChatWindows
local FCF_SetChatWindowFontSize = _G.FCF_SetChatWindowFontSize
local FCF_SetLocked = _G.FCF_SetLocked
local FCF_SetWindowAlpha = _G.FCF_SetWindowAlpha
local FCF_SetWindowColor = _G.FCF_SetWindowColor
local FCF_SetWindowName = _G.FCF_SetWindowName
local GetScreenHeight = _G.GetScreenHeight
local GetScreenWidth = _G.GetScreenWidth
local IsAddOnLoaded = _G.IsAddOnLoaded
local LoadAddOn = _G.LoadAddOn
local SetChatWindowSavedDimensions = _G.SetChatWindowSavedDimensions
local SetChatWindowSavedPosition = _G.SetChatWindowSavedPosition
local SetCVar = _G.SetCVar
local ShowCloak = _G.ShowCloak
local ShowHelm = _G.ShowHelm
local StaticPopup_Show = _G.StaticPopup_Show
local ToggleChatColorNamesByClassGroup = _G.ToggleChatColorNamesByClassGroup
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitClass = _G.UnitClass

local module = gUI4:NewModule(addon.."_Setup", "GP_AceConsole-3.0", "GP_AceEvent-3.0")

local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local chatNames = {}
local current_version = "2014-11-07 23:43" -- when I update this, the user is requested again for the setup
local gameLocale = _G.GetLocale()

-- these channels are localized, and need to be exact
if gameLocale == "frFR" then
	chatNames.general = "Général"
	chatNames.trade = "Commerce"
	chatNames.defense = "DéfenseLocale"
	chatNames.recruitment = "RecrutementDeGuilde"
	chatNames.lfg = "RechercheDeGroupe" 
elseif gameLocale == "deDE" then 
	chatNames.general = "Allgemein"
	chatNames.trade = "Handel"
	chatNames.defense = "LokaleVerteidigung"
	chatNames.recruitment = "Gildenrekrutierung"
	chatNames.lfg = "SucheNachGruppe"
elseif gameLocale == "itIT" then 
	chatNames.general = "Generale"
	chatNames.trade = "Commercio"
	chatNames.defense = "DifesaLocale"
	chatNames.recruitment = "CercaGilda"
	chatNames.lfg = "CercaGruppo"
elseif gameLocale == "koKR" then 
	chatNames.general = "일반"
	chatNames.trade = "거래"
	chatNames.defense = "수비"
	chatNames.recruitment = "길드모집"
	chatNames.lfg = "파티찾기"
elseif gameLocale == "ptBR" then 
	chatNames.general = "Geral"
	chatNames.trade = "Comércio"
	chatNames.defense = "DefesaLocal"
	chatNames.recruitment = "RecrutamentoDeGuilda"
	chatNames.lfg = "ProcurandoGrupo"
elseif gameLocale == "ruRU" then 
	chatNames.general = "Общий"
	chatNames.trade = "Торговля"
	chatNames.defense = "ОборонаЛокальный"
	chatNames.recruitment = "Гильдии"
	chatNames.lfg = "ПоискСпутников"
elseif gameLocale == "esES" or gameLocale == "esMX" then 
	chatNames.general = "General"
	chatNames.trade = "Comercio"
	chatNames.defense = "DefensaLocal"
	chatNames.recruitment = "ReclutamientoHermandad"
	chatNames.lfg = "BuscandoGrupo"
elseif gameLocale == "zhTW" then 
	chatNames.general = "綜合"
	chatNames.trade = "交易"
	chatNames.defense = "本地防務"
	chatNames.recruitment = "公會招募"
	chatNames.lfg = "尋求組隊"
else
	chatNames.general = "General"
	chatNames.trade = "Trade"
	chatNames.defense = "LocalDefense"
	chatNames.recruitment = "GuildRecruitment"
	chatNames.lfg = "LookingForGroup"
end

-- groups for the loot window
local lootGroups = {
	"COMBAT_XP_GAIN",
	"COMBAT_GUILD_XP_GAIN",
	"COMBAT_HONOR_GAIN",
	"COMBAT_FACTION_CHANGE",
	"LOOT",
	"MONEY",
	"SKILL"
}

-- groups for the main window
local mainGroups = {
	-- "SAY",
	"EMOTE",
	"YELL",
	"GUILD",
	"OFFICER",
	"WHISPER",

	-- "MONSTER_SAY",
	"MONSTER_EMOTE",
	"MONSTER_YELL",
	"MONSTER_WHISPER",
	"MONSTER_BOSS_EMOTE",
	"MONSTER_BOSS_WHISPER",

	"INSTANCE_CHAT",
	"INSTANCE_CHAT_LEADER",
	"PARTY",
	"PARTY_LEADER",
	"RAID",
	"RAID_LEADER",
	"RAID_WARNING",

	"BATTLEGROUND",
	"BATTLEGROUND_LEADER",
	"BG_HORDE",
	"BG_ALLIANCE",
	"BG_NEUTRAL",

	"SYSTEM",
	"AFK",
	"DND",
	"IGNORED",
	"ERRORS",

	"ACHIEVEMENT",
	"GUILD_ACHIEVEMENT",

	"BN_ALERT", 
	"BN_BROADCAST", 
	"BN_BROADCAST_INFORM", 
	"BN_CONVERSATION",
	"BN_CONVERSATION_LIST", 
	"BN_CONVERSATION_NOTICE", 
	"BN_INLINE_TOAST_ALERT", 
	"BN_INLINE_TOAST_BROADCAST", 
	"BN_INLINE_TOAST_BROADCAST_INFORM", 
	"BN_INLINE_TOAST_CONVERSATION",
	"BN_WHISPER",
	"BN_WHISPER_INFORM"
}

-- channels to activate class colors in
local classColors = {
	"ACHIEVEMENT",
	"BATTLEGROUND",
	"BATTLEGROUND_LEADER",
	"CHANNEL1",
	"CHANNEL2",
	"CHANNEL3",
	"CHANNEL4",
	"CHANNEL5",
	"CHANNEL6",
	"CHANNEL7",
	"CHANNEL8",
	"CHANNEL9",
	"CHANNEL10",
	"EMOTE",
	"GUILD",
	"GUILD_ACHIEVEMENT",
	"INSTANCE_CHAT",
	"INSTANCE_CHAT_LEADER",
	"OFFICER",
	"PARTY",
	"PARTY_LEADER",
	"RAID",
	"RAID_LEADER",
	"RAID_WARNING",
	"SAY",
	"WHISPER",
	"YELL"
}

-- default setup data for chatframes
local chatFrameFontSize = 14
local chatFrameButtonFrameIndent = 32
local chatFrameSize = { 420, 120 }
local chatFrameDefaultPos = { "BOTTOMLEFT", 20, 62 }
local chatFrameDefaultPosButtonFrame = { "BOTTOMLEFT", 20 + chatFrameButtonFrameIndent, 62 }
local chatFrameDefaultPosAlternate = { "BOTTOMRIGHT", -20, 62 }
local chatFrameDefaultPosButtonFrameAlternate = { "BOTTOMLEFT", -(20 + chatFrameButtonFrameIndent), 62 }

local defaults = {
	profile = {
		queried = { -- going with a timestamp system here
			[current_version] = false
		}
	}
}
local deprecated = {
	chatInstalled = true,
	cvarsInstalled = true,
	development = true,
	logInstalled = true,
	module = true
}

local function SetUpColors()
	-- change colors to something better
	-- point is that too many things looks like the druid class color
	ChangeChatColor("RAID", unpack(gUI4:GetColors("chat", "raid")))
	ChangeChatColor("RAID_LEADER", unpack(gUI4:GetColors("chat", "leader")))
	ChangeChatColor("BATTLEGROUND", unpack(gUI4:GetColors("chat", "raid")))
	ChangeChatColor("BATTLEGROUND_LEADER", unpack(gUI4:GetColors("chat", "leader")))
	ChangeChatColor("INSTANCE_CHAT", unpack(gUI4:GetColors("chat", "raid")))
	ChangeChatColor("INSTANCE_CHAT_LEADER", unpack(gUI4:GetColors("chat", "leader")))
	
	-- enable class coloring
	for _,v in ipairs(classColors) do
		ToggleChatColorNamesByClassGroup(true, v)
	end
	
	-- change background colors and alpha of all frames
	local frame
	for _,name in ipairs(_G.CHAT_FRAMES) do
		frame = _G[name]
		if frame then
			FCF_SetWindowColor(frame, 0, 0, 0)
			FCF_SetWindowAlpha(frame, 0)
		end
	end
end

local function SavePosition(frame)
	local centerX = frame:GetLeft() + frame:GetWidth() / 2
	local centerY = frame:GetBottom() + frame:GetHeight() / 2
	
	local horizPoint, vertPoint
	local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
	local xOffset, yOffset
	if ( centerX > screenWidth / 2 ) then
		horizPoint = "RIGHT"
		xOffset = (frame:GetRight() - screenWidth)/screenWidth
	else
		horizPoint = "LEFT"
		xOffset = frame:GetLeft()/screenWidth
	end
	
	if ( centerY > screenHeight / 2 ) then
		vertPoint = "TOP"
		yOffset = (frame:GetTop() - screenHeight)/screenHeight
	else
		vertPoint = "BOTTOM"
		yOffset = frame:GetBottom()/screenHeight
	end

	SetChatWindowSavedPosition(frame:GetID(), vertPoint .. horizPoint, xOffset, yOffset)
end

local function SetDefaultPosition(frame)
	if frame then
		local buttonFrameVisible
		local gUI4_Chat = gUI4:GetModule("gUI4_Chat", true)
		if gUI4_Chat then
			buttonFrameVisible = not gUI4_Chat:GetModule("Windows").db.profile.visibility.hideButtonFrame
		end
		local id = frame:GetID()
		local name = FCF_GetChatWindowInfo(id)
		if id == 1 then
			frame:SetSize(unpack(chatFrameSize))
			SetChatWindowSavedDimensions(id, unpack(chatFrameSize))

			frame:SetUserPlaced(true)
			frame:ClearAllPoints()
			frame:SetPoint(unpack(buttonFrameVisible and chatFrameDefaultPosButtonFrame or chatFrameDefaultPos))
			SavePosition(frame)
			-- SetChatWindowSavedPosition(id, unpack(chatFrameDefaultPos))
		elseif id == 4 and name == _G.LOOT then
			if not frame.isDocked then
				frame:SetSize(unpack(chatFrameSize))
				SetChatWindowSavedDimensions(id, unpack(chatFrameSize))

				frame:SetUserPlaced(true)
				frame:ClearAllPoints()
				frame:SetPoint(unpack(buttonFrameVisible and chatFrameDefaultPosButtonFrameAlternate or chatFrameDefaultPosAlternate))
				frame:SetJustifyH("RIGHT")
				SavePosition(frame)
				-- SetChatWindowSavedPosition(id, unpack(chatFrameDefaultPosAlternate))
			end
		end
		if not frame.isLocked then 
			FCF_SetLocked(frame, 1) 
		end
	end
end
-- hooksecurefunc("FCF_RestorePositionAndDimensions", SetDefaultPosition)

function module:SetUpChat(_, forced)
	if self.db.profile.chatInstalled and not forced then return end 

	local ChatFrame1 = _G.ChatFrame1
	local ChatFrame2 = _G.ChatFrame2
	local ChatFrame3 = _G.ChatFrame3
	local ChatFrame4 = _G.ChatFrame4

	FCF_ResetChatWindows() -- this bugs out?

	FCF_SetLocked(ChatFrame1, 1)
	FCF_DockFrame(ChatFrame2)
	FCF_SetLocked(ChatFrame2, 1)

	FCF_OpenNewWindow(_G.GENERAL)
	FCF_SetLocked(ChatFrame3, 1)
	FCF_DockFrame(ChatFrame3)

	FCF_OpenNewWindow(_G.LOOT)
	-- FCF_UnDockFrame(ChatFrame4)
	FCF_SetLocked(ChatFrame4, 1)
	FCF_DockFrame(ChatFrame4)
	-- ChatFrame4:Show()
	
	-- select the main frame
	_G.SELECTED_CHAT_FRAME = ChatFrame1
	FCFDock_SelectWindow(_G.GENERAL_CHAT_DOCK, ChatFrame1)
	
	for i = 1, _G.NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		local id = frame:GetID()

		frame:SetSize(unpack(chatFrameSize))
		SetChatWindowSavedDimensions(id, unpack(chatFrameSize))

		FCF_SetChatWindowFontSize(nil, frame, chatFrameFontSize)
		-- FCF_SetWindowColor(frame, 0, 0, 0)
		-- FCF_SetWindowAlpha(frame, 0)
		-- FCF_SavePositionAndDimensions(frame) 
	
		if i == 1 then FCF_SetWindowName(frame, L["Main"]) end
		if i == 2 then FCF_SetWindowName(frame, _G.GUILD_BANK_LOG) end
		
		SetDefaultPosition(frame)
	end
	SetUpColors()
	
	ChatFrame_RemoveAllMessageGroups(ChatFrame1)
	ChatFrame_RemoveChannel(ChatFrame1, chatNames.trade) 
	ChatFrame_RemoveChannel(ChatFrame1, chatNames.general) 
	ChatFrame_RemoveChannel(ChatFrame1, chatNames.defense) 
	ChatFrame_RemoveChannel(ChatFrame1, chatNames.recruitment) 
	ChatFrame_RemoveChannel(ChatFrame1, chatNames.lfg) 
	
	ChatFrame_ReceiveAllPrivateMessages(ChatFrame1)
--~ 	ChatFrame_ReceiveAllBNConversations(ChatFrame1)
	for _,v in ipairs(mainGroups) do
		ChatFrame_AddMessageGroup(ChatFrame1, v)
	end
				
	ChatFrame_RemoveAllMessageGroups(ChatFrame3)
	ChatFrame_AddChannel(ChatFrame3, chatNames.trade) 
	ChatFrame_AddChannel(ChatFrame3, chatNames.general) 
	ChatFrame_AddChannel(ChatFrame3, chatNames.defense) 
	ChatFrame_AddChannel(ChatFrame3, chatNames.recruitment) 
	ChatFrame_AddChannel(ChatFrame3, chatNames.lfg) 
			
	ChatFrame_RemoveAllMessageGroups(ChatFrame4)
	ChatFrame_AddMessageGroup(ChatFrame4, "COMBAT_XP_GAIN")
	ChatFrame_AddMessageGroup(ChatFrame4, "COMBAT_HONOR_GAIN")
	ChatFrame_AddMessageGroup(ChatFrame4, "COMBAT_FACTION_CHANGE")
	ChatFrame_AddMessageGroup(ChatFrame4, "LOOT")
	ChatFrame_AddMessageGroup(ChatFrame4, "MONEY")
			
	ToggleChatColorNamesByClassGroup(true, "SAY")
	ToggleChatColorNamesByClassGroup(true, "EMOTE")
	ToggleChatColorNamesByClassGroup(true, "YELL")
	ToggleChatColorNamesByClassGroup(true, "GUILD")
	ToggleChatColorNamesByClassGroup(true, "OFFICER")
	ToggleChatColorNamesByClassGroup(true, "GUILD_ACHIEVEMENT")
	ToggleChatColorNamesByClassGroup(true, "ACHIEVEMENT")
	ToggleChatColorNamesByClassGroup(true, "WHISPER")
	ToggleChatColorNamesByClassGroup(true, "PARTY")
	ToggleChatColorNamesByClassGroup(true, "PARTY_LEADER")
	ToggleChatColorNamesByClassGroup(true, "RAID")
	ToggleChatColorNamesByClassGroup(true, "RAID_LEADER")
	ToggleChatColorNamesByClassGroup(true, "RAID_WARNING")
	ToggleChatColorNamesByClassGroup(true, "BATTLEGROUND")
	ToggleChatColorNamesByClassGroup(true, "BATTLEGROUND_LEADER")	
	ToggleChatColorNamesByClassGroup(true, "CHANNEL1")
	ToggleChatColorNamesByClassGroup(true, "CHANNEL2")
	ToggleChatColorNamesByClassGroup(true, "CHANNEL3")
	ToggleChatColorNamesByClassGroup(true, "CHANNEL4")
	ToggleChatColorNamesByClassGroup(true, "CHANNEL5")
	ToggleChatColorNamesByClassGroup(true, "INSTANCE_CHAT")
	ToggleChatColorNamesByClassGroup(true, "INSTANCE_CHAT_LEADER")
	
	self.db.profile.chatInstalled = true
end

function module:SetUpCombatLog(forced)
	if self.db.profile.logInstalled and not forced then return end 

  local ChatFrame2 = _G.ChatFrame2
  
	ChatFrame_RemoveMessageGroup(ChatFrame2, "COMBAT_MISC_INFO")
	ChatFrame_RemoveMessageGroup(ChatFrame2, "OPENING")
	ChatFrame_RemoveMessageGroup(ChatFrame2, "PET_INFO")
	ChatFrame_RemoveMessageGroup(ChatFrame2, "TRADESKILLS")
	
	for _,v in ipairs(lootGroups) do
		ChatFrame_RemoveMessageGroup(ChatFrame2, v)
	end
	
	self.db.profile.logInstalled = true
end

function module:SetUpCVar()
	-- settings for just myself
	if gUI4.version == "Development" then
		self.db.profile.development = true
	else
		self.db.profile.development = false
	end

	-- general
	SetCVar("scriptErrors", 1)
	SetCVar("screenshotQuality", 8)
	SetCVar("showTutorials", 0)
	SetCVar("violenceLevel", 5)

	-- tooltips
	SetCVar("UberTooltips", 1)
end

function module:SetUp(what)
	if UnitAffectingCombat("player") then return end
	if not IsAddOnLoaded("Blizzard_CombatLog") then
		LoadAddOn("Blizzard_CombatLog")
	end
	if what and what:lower() == "all" then
		self:SetUpCVar()
		self:SetUpChat(nil, true)
		self:SetUpCombatLog(true)
	else
		self:SetUpChat(nil, true)
		self:SetUpCombatLog(true)
	end
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Chat", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["General"],
			args = {
				title1 = {
					order = 1,
					type = "description",
					name = L["|n|cffffd200" .. "Preparing the Chat Windows for Goldpaw's UI" .. "|r"]
				},
				description1 = {
					order = 2,
					type = "description",
					name = L["Click the button below or type |cff4488ff\"/install\"|r in the chat (without the quotes) followed by the Enter key to run the automatic chat window setup.|n|n"]
				},
				setup = {
					order = 11,
					type = "execute",
					name = L["Set Up Chat"],
					desc = L["Sets up the windows, chat channels and message groups to what Goldpaw uses. This action will change various game settings."],
					func = function() StaticPopup_Show("GUI4_QUERY_BASIC_INSTALL") end
				}
			}
		}
	})
end

function module:OnInitialize()
	self.db = gUI4.db:RegisterNamespace("SetUp", defaults)
	-- clean up saved settings
	for key in ipairs(deprecated) do
		if self.db.profile[key] ~= nil then
			self.db.profile[key] = nil
		end
	end

	self:RegisterChatCommand("setupgui", function() StaticPopup_Show("GUI4_QUERY_BASIC_INSTALL") end)
	self:RegisterChatCommand("install", function() StaticPopup_Show("GUI4_QUERY_BASIC_INSTALL") end)
	-- gUI4:AddStartupMessage(L["/install to automatically set up chat windows"])
end

function module:OnEnable()
	if not self.db.profile.queried[current_version] then
		StaticPopup_Show("GUI4_QUERY_BASIC_INSTALL_AUTODETECTED")
		self.db.profile.queried[current_version] = true
	end
end
