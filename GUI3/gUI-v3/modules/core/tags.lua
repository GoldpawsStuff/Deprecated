--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Tags")

module.OnInit = function(self)
	local tonumber = tonumber
	local date = date
	local floor = floor
	local format = format
	local select = select
	
	local GetContainerNumSlots = GetContainerNumSlots
	local GetContainerNumFreeSlots = GetContainerNumFreeSlots
	local GetMoney = GetMoney
	local GetGameTime = GetGameTime
	local GetPVPTimer = GetPVPTimer
	local GetWintergraspWaitTime = GetWintergraspWaitTime
	
	--------------------------------------------------------------------------------------------------
	--		string tags
	--------------------------------------------------------------------------------------------------

	local bagStrings = {
		["backpack"] = { 0 };
		["bags"] = { 1, 2, 3, 4 };
		["backpack+bags"] = { 0, 1, 2, 3, 4, };
		["bank"] = { 5, 6, 7, 8, 9, 10, 11 };
		["bankframe"] = { -1 };
		["bankframe+bank"] = { -1, 5, 6, 7, 8, 9, 10, 11 };
		["keyring"] = { -2 };
	}

	local getSpace = function(bags)
		if not(bags) or (type(bags) ~= "string") or not(bagStrings[bags]) then return end
		local free, total, used = 0, 0, 0
		for _,i in pairs(bagStrings[bags]) do
			free, total, used = free + GetContainerNumFreeSlots(i), total + GetContainerNumSlots(i), total - free
		end
		return free, total, used, (total ~= 0) and floor(free / total * 100) or 0
	end

	local createIcon = function(iconPath, iconValues)
		if not iconPath or type(iconPath) ~= "string" then return end
		iconValues = type(iconValues) == "string" and iconValues or "0:0:0:0"
		if type(iconValues) == "table" then
			iconValues = tconcat(iconValues, ":")
		end
		return ("|T%s:%s|t"):format(iconPath, iconValues)
	end
	
	local goldIcon = createIcon([[Interface\MoneyFrame\UI-GoldIcon]], "0:0:0:0")
	local silverIcon = createIcon([[Interface\MoneyFrame\UI-SilverIcon]], "0:0:0:0")
	local copperIcon = createIcon([[Interface\MoneyFrame\UI-CopperIcon]], "0:0:0:0")

	gUI:RegisterTag("money", function(money, full)
		money = money and tonumber(money) or (GetMoney())
		local str
		local g,s,c = floor(money/1e4), floor(money/100) % 100, money % 100
		if (full) then
			if g > 0 then str = (str and str.."" or "") .. g .. goldIcon end
			if s > 0 or g > 0 then str = (str and str.."" or "") .. s .. silverIcon end
			str = (str and str.."" or "") .. c .. copperIcon
			return str
		else
			if g > 0 then str = (str and str.."" or "") .. g .. goldIcon end
			if s > 0 then str = (str and str.."" or "") .. s .. silverIcon end
			if c > 0 or g + s + c == 0 then str = (str and str.."" or "") .. c .. copperIcon end
			return str
		end
	end)

	gUI:RegisterTag("free", function(bags)
		if not bagStrings[bags] then return end
		return (select(1, getSpace(bags)))
	end)

	gUI:RegisterTag("max", function(bags)
		if not bagStrings[bags] then return end
		return (select(2, getSpace(bags))) 
	end)

	gUI:RegisterTag("used", function(bags)
		if not bagStrings[bags] then return end
		return (select(3, getSpace(bags)))
	end)

	gUI:RegisterTag("freepercent", function(bags)
		if not bagStrings[bags] then return end
		return (select(4, getSpace(bags))).."%"
	end)

	gUI:RegisterTag("usedpercent", function(bags)
		if not bagStrings[bags] then return end
		return (100 - (select(4, getSpace(bags)))).."%"
	end)

	gUI:RegisterTag("shortvalue", function(value)
		value = tonumber(value)
		if not(value) then return "0.0" end
		if (value >= 1e6) then
			return ("%.1fM"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
		elseif (value >= 1e3) or (value <= -1e3) then
			return ("%.1fK"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
		else
			return value
		end	
	end)

	-- colored version of the above tag
	gUI:RegisterTag("shortvaluecolored", function(value)
		value = tonumber(value)
		if not(value) then return "0.0" end
		if (value >= 1e6) then
			return ("|cFFFFD200%.1f|r|cFFFFFFFFM|r"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
		elseif (value >= 1e3) or (value <= -1e3) then
			return ("|cFFFFD200%.1f|r|cFFFFFFFFK|r"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
		else
			return ("|cFFFFD200%.1f|r"):format(value)
		end	
	end)

	gUI:RegisterTag("smarttime", function(seconds)
		if not(seconds) then return "0.0" end
		seconds = tonumber(seconds)
		local day, hour, minute = 86400, 3600, 60
		if (seconds >= day) then
			return format("%dd", floor(seconds / day + 0.5)), seconds % day
		elseif (seconds >= hour) then
			return format("%dh", floor(seconds / hour + 0.5)), seconds % hour
		elseif (seconds >= minute) then
			if (seconds <= (minute * 5)) then
				return format("%d:%02d", floor(seconds / 60), seconds % minute), seconds - floor(seconds)
			end
			return format("%dm", floor(seconds / minute + 0.5)), seconds % minute
		elseif (seconds >= minute / 12) then
			return floor(seconds + 0.5), (seconds * 100 - floor(seconds * 100)) / 100
		end
		return format("%.1f", seconds), (seconds * 100 - floor(seconds * 100)) / 100
	end)

	gUI:RegisterTag("time", function(timezone)
		timezone = timezone and timezone:lower() or "game"

		if timezone == "local" or timezone == "local24" then
			return date("%H:%M")

		elseif timezone == "local12" then
			return date("%I:%M %p")

		elseif timezone == "game" or timezone == "game24" then
			local hours, minutes = GetGameTime()
			return (format("%02d", hours)..":"..format("%02d", minutes))

		elseif timezone == "game12" then
			local hours, minutes = GetGameTime()
			return (format("%02d", ((hours > 12) or (hours < 1)) and (hours - 12) or hours)..":"..format("%02d", minutes)..((hours > 12) and " PM" or " AM"))

		elseif timezone == "pvp" then
			local sec = GetPVPTimer()
			if (sec >= 0) and (sec <= 301000) then
				seconds = floor(seconds / 1000)
				return (format("%d", floor(seconds / 60) % 60)..":"..format("%02d", seconds % 60))
			else
				return "--:--"
			end

		elseif timezone == "wintergrasp" then
			local seconds = GetWintergraspWaitTime()
			if seconds then
				return (format("%d", floor(seconds / 3600))..":"..format("%02d", floor(seconds / 60) % 60)..":"..format("%02d", seconds % 60))
			else
				return ("--:--")
			end
		end
	end)
	
end

