local addon,_ = ...

local gUI4 = _G.GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule(addon, true)
if not parent then return end

local module = parent:NewModule("Money", "GP_AceEvent-3.0")

local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LDB = _G.GP_LibStub("LibDataBroker-1.1")

-- Lua API
local _G = _G
local pairs, ipairs = pairs, ipairs
local select = select
local tinsert, tsort = table.insert, table.sort

-- WoW API
local GetCoinTextureString = _G.GetCoinTextureString
local GetMoney = _G.GetMoney
local UnitName = _G.UnitName
local TOTAL = _G.TOTAL
local BONUS_ROLL_REWARD_MONEY = _G.BONUS_ROLL_REWARD_MONEY

local class = select(2, _G.UnitClass("player"))

local defaults = {
	factionrealm = {
		["*"] = { 
      class = "",
			money = 0 
		}
	},
	char = {
    class = class, 
		money = 0
	},
	profile = {
	}
}

local function sortByGold(a, b)
  if a.money and b.money then
    return a.money > b.money
  end  
end

-------------------------------------------------------------------------------
--	Player Money
-------------------------------------------------------------------------------
-- addon messages:
-- 	GUI4_PLAYER_MONEY_INCREASED arg1 = money gained in copper
-- 	GUI4_PLAYER_MONEY_DECREASED arg2 = monely lost in copper
-- 
local money = 0
function module:UpdateMoney(silent, ...)
	local newMoney = GetMoney()
  -- update the stored money value
	if newMoney ~= money then
		local name, _ = UnitName("player")
		self.db.char.money = GetMoney()
		self.db.factionrealm[name].money = GetMoney()
		if not silent then
			if newMoney > money then
				self:SendMessage("GUI4_PLAYER_MONEY_INCREASED", newMoney - money)
			elseif newMoney < money then
				self:SendMessage("GUI4_PLAYER_MONEY_DECREASED", money - newMoney)
			end
		end
		money = newMoney
	end
  -- update the LDB feed
  if self.dataObject then
    self.dataObject.text = "|cffffffff" .. GetCoinTextureString(money) .. "|r"
  end
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Money", defaults)
  self.db.factionrealm[UnitName("player")].class = class -- update class
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateMoney")
	self:RegisterEvent("PLAYER_MONEY", "UpdateMoney")
  self:UpdateMoney(true)
  self.factionGoldByName, self.factionGoldIndexed = {}, {}
end

function module:OnEnable()
  if not self.dataObject then
    self.dataObject = LDB:NewDataObject(L["Goldpaw's UI: Gold"], {
      type = "data source",
      text = "",
      label = BONUS_ROLL_REWARD_MONEY,
      icon = "",
      OnTooltipShow = function(self) 
        local total = 0
        for name, data in pairs(module.db.factionrealm) do
          if data.class and data.class ~= "" then 
            module.factionGoldByName[name] = data.money
            total = total + data.money
          end
        end
        local others = 0
        for name, money in pairs(module.factionGoldByName) do
          local index
          for i, data in ipairs(module.factionGoldIndexed) do
            if data.name == name then
              index = i
              break
            end
          end
          if index then
            module.factionGoldIndexed[index].money = money
          else
            tinsert(module.factionGoldIndexed, {
              name = name, 
              money = money
            })
          end
          others = others + 1
        end
        -- only actually create the tooltip if more than the current character has been registered
        if others > 1 then
          self:AddDoubleLine("|cffffd200"..TOTAL.."|r", "|cffffffff"..GetCoinTextureString(total).."|r")
          self:AddLine(" ") -- add a blank line between total and character listing
          tsort(module.factionGoldIndexed, sortByGold)
          for _, data in ipairs(module.factionGoldIndexed) do
            if data.name and data.money then
              local class = module.db.factionrealm[data.name].class
              local name = gUI4:GetColorCode("class", class)..data.name.."|r"
              if class and name then
                self:AddDoubleLine(name, "|cffffffff"..GetCoinTextureString(data.money).."|r")
              end
            end
          end
        end
      end
    })
  end
  self:UpdateMoney(true)
end

function module:OnDisable()
end
