--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local style = gUI:GetModule("Styling"):NewModule("Postal")

style.OnInit = function(self)
	local L, C, F, M = gUI:GetEnvironment() -- get the gUI environment 
	local gABT = LibStub("gActionButtons-3.0")

	self:SetAttribute("name", self:GetName()) -- don't localize
	self:SetAttribute("description", L["Skins the '%s' addon"]:format(self:GetName()))
	
	local func = function()
		local Postal = LibStub("AceAddon-3.0"):GetAddon("Postal")
		local Postal_BlackBook = Postal:GetModule("BlackBook")
		local Postal_OpenAll = Postal:GetModule("OpenAll")
		local Postal_Select = Postal:GetModule("Select")
		
		MailFrame:SetSize(360, 430) -- extra room
		
		do
			local skinPostalMain
			skinPostalMain = function()
				if (PostalOpenAllButton) then
					gUI:SetUITemplate(PostalOpenAllButton, "button", true)
					PostalOpenAllButton:ClearAllPoints()
					PostalOpenAllButton:SetPoint("BOTTOM", InboxFrame, "BOTTOM", -30, 90)
				end
				if (Postal_ModuleMenuButton) then
					gUI:SetUITemplate(Postal_ModuleMenuButton, "arrow", "down")
				end
				gUI:UnregisterEvent("MAIL_SHOW", skinPostalMain)
			end
			if (PostalOpenAllButton) then
				skinPostalMain()
			else
				gUI:RegisterEvent("MAIL_SHOW", skinPostalMain)
			end
		end
		
		do
			local once
			local skinBlackBook = function()
				if (once) then 
					return
				end
				if (Postal_BlackBookButton) then
					gUI:SetUITemplate(Postal_BlackBookButton, "arrow", "down")
				end
				once = true
			end
			if (Postal_BlackBookButton) then
				skinBlackBook()
			else
				if (Postal_BlackBook) then
					hooksecurefunc(Postal_BlackBook, "OnEnable", skinBlackBook)
				end
			end
		end
		
		do
			local once
			local skinOpenAll = function()
				if (once) then 
					return
				end
				if (Postal_OpenAllMenuButton) then
					gUI:SetUITemplate(Postal_OpenAllMenuButton, "arrow", "down")
				end
				once = true
			end
			if (Postal_OpenAllMenuButton) then
				skinOpenAll()
			else
				if (Postal_OpenAll) then
					hooksecurefunc(Postal_OpenAll, "OnEnable", skinOpenAll)
				end
			end
		end
		
		do
			local once
			local skinSelect = function()
				if (once) then 
					return
				end
				if (PostalSelectOpenButton) then
					gUI:SetUITemplate(PostalSelectOpenButton, "button", true)
				end
				if (PostalSelectReturnButton) then
					gUI:SetUITemplate(PostalSelectReturnButton, "button", true)
				end
				MailItem1:ClearAllPoints()
				MailItem1:SetPoint("TOPLEFT", 38, -80)
				local w = MailItem1:GetWidth() + 14
				for i = 1,INBOXITEMS_TO_DISPLAY do
					local bg = _G["MailItem" .. i]
					local expire = _G["MailItem" .. i .. "ExpireTime"]
					local subject = _G["MailItem" .. i .. "Subject"]
					local b = _G["PostalInboxCB" .. i]
				
					subject:SetPoint("RIGHT", MailItem4, "RIGHT", -30, 0)
					expire:ClearAllPoints()
					expire:SetPoint("TOPRIGHT", -4, -4)
					
					bg:SetWidth(w)
					
					b:ClearAllPoints()
					b:SetPoint("RIGHT", bg, "LEFT", -3, -5)
					
					gUI:SetUITemplate(b, "checkbutton")
				end
				once = true
			end
			if (PostalSelectOpenButton) then
				skinSelect()
			else
				if (Postal_Select) then
					hooksecurefunc(Postal_Select, "OnEnable", skinSelect)
				end
			end
		end
	end
	self:GetParent():RegisterAddOnSkin(self:GetName(), func)
end