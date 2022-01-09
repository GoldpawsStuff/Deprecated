local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Chat", true)
if not parent then return end

local module = parent:NewModule("Sounds", "GP_AceEvent-3.0")
local L = GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local T

-- wow api
local PlaySoundFile = PlaySoundFile

local defaults = {
	profile = {
		enabled = true,
		playWhisperSound = true, -- play a sound when receiving a whisper
		playBNWhisperSound = true, -- play a sound when receiving a battle.net whisper
		soundChannel = 1 -- sound channel to use, see below
	}
}

local function updateConfig()
	T = parent:GetActiveTheme()
end

local sound_channels = {
	"Master", "SFX", "Ambience", "Music"
}

function module:CHAT_MSG_WHISPER(event, msg, ...)
	if msg and msg:sub(1,3) == "OQ," then 
		return
	end
	if event == "CHAT_MSG_WHISPER" then
		if self.db.profile.playWhisperSound then
			PlaySoundFile(gUI4:GetMedia("Sound", "Whisper"):GetPath(), sound_channels[self.db.profile.soundChannel]) 
		end
	elseif event == "CHAT_MSG_BN_WHISPER" then
		if self.db.profile.playBNWhisperSound then
			PlaySoundFile(gUI4:GetMedia("Sound", "Whisper"):GetPath(), sound_channels[self.db.profile.soundChannel]) 
		end
	elseif event == "Forced" then
		PlaySoundFile(gUI4:GetMedia("Sound", "Whisper"):GetPath(), sound_channels[self.db.profile.soundChannel])
	end
end

function module:ApplySettings()
end

function module:SetupOptions()
	gUI4:RegisterModuleOptions("Chat", {
		[tostring(self)] = {
			order = 0, 
			type = "group",
			name = L["Sounds"],
			args = {
				header = {
					order = 1, 
					type = "description",
					name = L["|n|cffffd200" .. "Whisper Sounds" .. "|r"]
				},
				description = {
					order = 2, 
					type = "description",
					name = L["Goldpaw's Chat plays a sound when you receive a whisper. Here you can toggle or modify that behavior to your liking."]
				},
				header2 = {
					order = 10, 
					type = "description",
					name = L["|n|cffffd200" .. "Sound Channel" .. "|r"]
				},
				description2 = {
					order = 11, 
					type = "description",
					name = L["Here you can choose which sound channel to send the whisper sound to. By choosing 'Master' the sound will be heard even when sound effects are turned off in the system settings. This is the default setting."]
				},
				soundChannel = {
					order = 15, 
					type = "select",
					style = "dropdown",
					values = {
						[1] = L[sound_channels[1]],
						[2] = L[sound_channels[2]],
						[3] = L[sound_channels[3]],
						[4] = L[sound_channels[4]]
					},
					name = "",
					desc = L["Select the sound channel to send the whisper sound to. Choosing 'Master' will allow the whisper sound to be heard even with sound effects disabled."],
					get = function() return self.db.profile.soundChannel end,
					set = function(info, value)
						self.db.profile.soundChannel = value
					end
				},
				testSound = {
					order = 16, 
					type = "execute",
					name = L["Test Sound"],
					desc = L["Test the whisper sound with your current settings."],
					func = function() 
						self:CHAT_MSG_WHISPER("Forced")
					end
				},
				playWhisperSound = {
					order = 100,
					type = "toggle",
					name = L["Play a sound when receiving a whisper."],
					desc = L["Play a sound when somebody sends you a private whisper."],
					width = "full",
					get = function() return self.db.profile.playWhisperSound end,
					set = function(info, value)
						self.db.profile.playWhisperSound = value
					end
				},
				--[[
				playBNWhisperSound = {
					order = 101,
					type = "toggle",
					name = L["Play a sound when receiving a battle.net whisper."],
					desc = L["Play a sound when somebody sends you a private whisper through battle.net."],
					width = "full",
					get = function() return self.db.profile.playBNWhisperSound end,
					set = function(info, value)
						self.db.profile.playBNWhisperSound = value
					end
				}]]--
			}
		}
	})
end

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Sounds", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")

	updateConfig()
end

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_WHISPER")
	self:RegisterEvent("CHAT_MSG_BN_WHISPER", "CHAT_MSG_WHISPER")
end

function module:OnDisable()
	self:UnregisterEvent("CHAT_MSG_WHISPER")
	self:UnregisterEvent("CHAT_MSG_BN_WHISPER", "CHAT_MSG_WHISPER")
end
