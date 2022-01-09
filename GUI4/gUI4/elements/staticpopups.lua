local addon, gUI4 = ...

-- Lua API
local _G = _G
local print = print

-- WoW API
local ReloadUI = _G.ReloadUI
local StaticPopupDialogs = _G.StaticPopupDialogs

local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-------------------------------------------------------------------------------
--	Static Popups
-------------------------------------------------------------------------------
StaticPopupDialogs["GUI4_RESTART"] = {
	text = L["The user interface needs to be reloaded for the changes to take effect. Do you wish to reload it now?"],
	button1 = _G.YES,
	button2 = _G.NO,
	OnAccept = ReloadUI,
	OnCancel = function() end,
	OnShow = gUI4.FullScreenFadeOut, 
	onHide = gUI4.FullScreenFadeIn,
	exclusive = 1,
	hideOnEscape = 0,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
	preferredIndex = _G.STATICPOPUP_NUMDIALOGS
}

StaticPopupDialogs["GUI4_QUERY_BASIC_INSTALL_AUTODETECTED"] = {
	text = L["This is your first time running %s.|nWould you like the chat window autosetup to run now? This action will set up the chat windows, channels and messagegroups to what Goldpaw uses."]:format(L["Goldpaw's UI"]),
	button1 = _G.YES,
	button2 = _G.NO,
	OnAccept = function() 
		local module = gUI4:GetModule("gUI4_Setup")
		module:SetUp("all")
	end,
	OnCancel = function() 
		print(L["You can run the setup again any time with /install"])
	end,
	OnShow = gUI4.FullScreenFadeOut, 
	onHide = gUI4.FullScreenFadeIn,
	exclusive = 1,
	hideOnEscape = 0,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
	preferredIndex = _G.STATICPOPUP_NUMDIALOGS
}

StaticPopupDialogs["GUI4_QUERY_BASIC_INSTALL"] = {
	text = L["This will set up your chat windows, chat channels and messagegroups to what Goldpaw uses.|n|nAre you sure you wish to do this?"],
	button1 = _G.YES,
	button2 = _G.NO,
	OnAccept = function() 
		local module = gUI4:GetModule("gUI4_Setup")
		module:SetUp("all")
	end,
	OnCancel = function() 
		print(L["You can run the setup again any time with /install"])
	end,
	OnShow = gUI4.FullScreenFadeOut, 
	onHide = gUI4.FullScreenFadeIn,
	exclusive = 1,
	hideOnEscape = 0,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
	preferredIndex = _G.STATICPOPUP_NUMDIALOGS
}

StaticPopupDialogs["GUI4_GLOCK_RESET_ALL"] = {
	text = L["This will reset the positions of all movable frames. Are you sure?"],
	button1 = _G.YES,
	button2 = _G.NO,
	OnAccept = function() 
		gUI4:ResetLock() 
	end,
	OnCancel = function() end,
	OnShow = gUI4.FullScreenFadeOut, 
	onHide = gUI4.FullScreenFadeIn,
	exclusive = 1,
	hideOnEscape = 0,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
	preferredIndex = _G.STATICPOPUP_NUMDIALOGS
}
