--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("GuildInvite")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", L["Guild Invite"])
	self:SetAttribute("description", L["The guild invite frame where you accept or decline a guild invitation"])
	
	local func = function()
		gUI:DisableTextures(GuildInviteFrame)
		gUI:SetUITemplate(GuildInviteFrameJoinButton, "button", true)
		gUI:SetUITemplate(GuildInviteFrameDeclineButton, "button", true)
		gUI:SetUITemplate(GuildInviteFrame, "backdrop")
	end
	self:GetParent():RegisterSkin(self:GetName(), func)
end