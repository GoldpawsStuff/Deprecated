--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("DeveloperTools")

local L, C, F, M, db
local defaults = {}

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	
	self:CreateChatCommand("fullscreen", function(msg) 
		SetCVar("gxWindow", "0")
		SetCVar("gxMaximize", "0")
		RestartGx()
	end)
	
	self:CreateChatCommand("windowed", function(msg) 
		SetCVar("gxWindow", "1")
		SetCVar("gxMaximize", "1")
		RestartGx()
	end)

	-- http://www.wowpedia.org/API_GetInspectSpecialization
	local prepFakers = { 252, 105, 258, 73, 260 } -- arena prep faking
	
	-- /emu <group>
	self:CreateChatCommand({ "emulate", "emu" }, function(msg)
		if not(msg) or (msg == "") then 
			msg = "all" 
		end
		if (msg == "all") or (msg == "arena") then
			local frame
			for i = 1, 5 do
				frame = _G["GUIS_Arena"..i]
				if (frame) then
					frame:Show()
					frame.Hide = self.noop 
					frame.unit = "player"
					frame.PvPTrinket.Icon:SetTexture([[Interface\Icons\INV_Jewelry_TrinketPVP_01]]) -- ally icon
					frame.PvPTrinket:Show()
				end
			end
		end
		if (msg == "arenaprep") or (msg == "prep") then
			if (GUIS_ArenaPrep) then
				GUIS_ArenaPrep:Show()
				local frame
				local id, spec, description, icon, background, role, class
				for i = 1, 5 do
					frame = _G["GUIS_ArenaPrep"..i]
					if (frame) then
						id, spec, description, icon, background, role, class = GetSpecializationInfoByID(prepFakers[i])
						frame.class = class
						frame.spec = spec
						frame.role = role
						frame.icon = icon
						frame:PostUpdate()
						frame:Show()
					end
				end
			end
		end
		if (msg == "all") or (msg == "party") then
			if (GUIS_Party) then
				-- thank you Nodd for this. 
				local namelist = UnitName("Player")
				for i = 2, 5 do
					namelist =  namelist .. "," .. UnitName("player")
				end
				
				GUIS_Party:SetAttribute("showPlayer", true)
				GUIS_Party:SetAttribute("showSolo", true)
				GUIS_Party:SetAttribute("groupFilter", nil)
				GUIS_Party:SetAttribute("nameList", namelist) -- it refuses to show duplicates, so BIG FAIL
			end
		end
		if (msg == "all") or (msg == "boss") then
			for i = 1, 3 do
				frame = _G["GUIS_Boss"..i]
				if (frame) then
					frame:Show()
					frame.Hide = self.noop 
					frame.unit = "player"
				end
			end
		end
	end)

	-- /print ... instead of /run print(...)
	self:CreateChatCommand({ "print" }, function(...)
		if not(...) then return end
		local msg = strjoin(" ", ...)
		if not(msg) or (msg == "") then return end
		local func, errorMessage = loadstring( "print(" .. msg .. ")" )
		if not(func) then
			self:UIErrorMessage(errorMessage, C["error"][1], C["error"][2], C["error"][3])
			return
		end
		local success, errorMessage = pcall(func)
		if not(success) then
			self:UIErrorMessage(errorMessage, C["error"][1], C["error"][2], C["error"][3])
			return
		end
	end)
	
	-- /getregions <ObjectName>
	-- @return list of region index and names
	self:CreateChatCommand("getregions", function(object)
		if (object) and (_G[object]) then
			local regions = { _G[object]:GetRegions() }
			for i, v in pairs(regions) do print(i, v.GetName and v:GetName() or "-unnamed-") end
		elseif (object) then
			print("No sub-regions found for " .. object)
		end
	end)
	
	-- /hideregions <ObjectName> <RegionNum>[, <RegionNum>, <RegionNum>, ...]
	self:CreateChatCommand("hideregions", function(object, ...)
		if (object) and (_G[object]) then
			local n, e
			for i = 1, select("#", ...) do
				n = tonumber(select(i, ...))
				module:argCheck(n, i, "number")
				e = select(n, _G[object]:GetRegions())
				if (e) then e:Hide() end
			end
		end
	end)
	
	-- /showregions <ObjectName> <RegionNum>[, <RegionNum>, <RegionNum>, ...]
	self:CreateChatCommand("showregions", function(object, ...)
		if (object) and (_G[object]) then
			local n, e
			for i = 1, select("#", ...) do
				n = tonumber(select(i, ...))
				module:argCheck(n, i, "number")
				e = select(n, _G[object]:GetRegions())
				if (e) then e:Show() end
			end
		end
	end)
	
	-- /itemid <ItemName or ItemLink>
	-- @return the itemID
	self:CreateChatCommand("itemid", function(...)
		local itemLink, itemID
		local link = strjoin(" ", ...)
		if (strsub(link, 1, 7) == "|Hitem:") then
			itemLink = link
		else
			itemLink = (select(2, GetItemInfo(link)))
		end
		if (itemLink) then
			local itemString = strmatch(itemLink, "item[%-?%d:]+")
			local _, itemID = strsplit(":", itemString)
			print(itemLink, itemID)
		end
	end)
	
	-- /itemstring <ItemName or ItemLink>
	-- @return the itemstring for the item
	self:CreateChatCommand("itemstring", function(...)
		local _, itemLink = GetItemInfo(strjoin(" ", ...))
		if (itemLink) then
			print(strmatch(itemLink, "item[%-?%d:]+"))
		end
	end)
	
	self:CreateChatCommand("test", function(what)
		if (what == "dung") then
			PlaySound("LFG_Rewards")
			GuildChallengeAlertFrame_ShowAlert(3, 2, 5)
			ChallengeModeAlertFrame_ShowAlert()
			CriteriaAlertFrame_GetAlertFrame()
			AlertFrame_AnimateIn(CriteriaAlertFrame1)
			AlertFrame_AnimateIn(DungeonCompletionAlertFrame1)
			AlertFrame_AnimateIn(ScenarioAlertFrame1)
			AlertFrame_FixAnchors()
		elseif (what == "achi") then
			PlaySound("LFG_Rewards")
			AchievementFrame_LoadUI()
			AchievementAlertFrame_ShowAlert(5780)
			AchievementAlertFrame_ShowAlert(5000)
			AlertFrame_FixAnchors()
		elseif (what == "more") then
			PlaySound("LFG_Rewards")
			MoneyWonAlertFrame_ShowAlert(1)
			local _, itemLink = GetItemInfo(88169)
			LootWonAlertFrame_ShowAlert(itemLink, -1, 1, 1)
			AlertFrame_FixAnchors()
		end
	end)

	-- hooksecurefunc("ActionBarController_UpdateAll", function() print("ActionBarController_UpdateAll") end)
	hooksecurefunc("OverrideActionBar_Setup", function() print("OverrideActionBar_Setup") end)
end

module.OnEnable = function(self)
end

module.OnDisable = function(self)
end
