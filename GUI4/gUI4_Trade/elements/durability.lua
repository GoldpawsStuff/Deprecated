local addon,_ = ...

local gUI4 = _G.GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule(addon, true)
if not parent then return end

local module = parent:NewModule("Durability", "GP_AceEvent-3.0")

local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")
local LDB = _G.GP_LibStub("LibDataBroker-1.1")

-- Lua API
local _G = _G
local floor, max = math.floor, math.max
local ipairs  = ipairs
local wipe = table.wipe

-- WoW API
local CreateFrame = _G.CreateFrame
local GetCoinTextureString = _G.GetCoinTextureString
local GetContainerItemDurability = _G.GetContainerItemDurability
local GetContainerItemID = _G.GetContainerItemID
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetInventoryItemDurability = _G.GetInventoryItemDurability
local GetInventoryItemID = _G.GetInventoryItemID
local GetItemInfo = _G.GetItemInfo
local CURRENTLY_EQUIPPED = _G.CURRENTLY_EQUIPPED
local DURABILITY = _G.DURABILITY
local INVENTORY_TOOLTIP = _G.INVENTORY_TOOLTIP
local TOTAL = _G.TOTAL

local slots = { 
  "HeadSlot", 
  "ShoulderSlot", 
  "ChestSlot", 
  "WaistSlot", 
  "WristSlot", 
  "HandsSlot", 
  "LegsSlot", 
  "FeetSlot", 
  "MainHandSlot", 
  "SecondaryHandSlot" 
}

local defaults = {
	profile = {
	}
 }
 
local function colorString(str, color)
  return "|cff"..color..str.."|r"
end

local function coin(money, percentage)
  if percentage then
      local colorCode
      if percentage == 0 then
        colorCode = gUI4:GetColorCode("chat", "red")
      elseif percentage < 25 then
        colorCode = gUI4:GetColorCode("chat", "yellow")
      else
        colorCode = gUI4:GetColorCode("chat", "green")
      end
      return colorCode..percentage.."%|r |cffffd200(|r"..colorString(GetCoinTextureString(money), "ffffff").."|cffffd200)|r"
  else
    return colorString(GetCoinTextureString(money), "ffffff")
  end
end

function module:UpdateDurability()
  if not self.dummy then
    self.dummy = CreateFrame("GameTooltip")
  end
  wipe(self.durabilityData.equippedItems)
  local eqcurrent, eqtotal, eqcost = 0, 0, 0
  for _, slot in ipairs(slots) do
    local item = _G["Character" .. slot]
    local exist, _, cost = self.dummy:SetInventoryItem("player", item:GetID())
    local current, total = GetInventoryItemDurability(item:GetID())
    if exist and cost and cost > 0 then
      local itemName, _, itemRarity = GetItemInfo(GetInventoryItemID("player", item:GetID()))
      self.durabilityData.equippedItems[gUI4:GetColorCode("quality", itemRarity)..itemName.."|r"] = coin(cost, floor(current/total*100))
      eqcost = eqcost + cost
    end
    if current and total then
      eqcurrent = eqcurrent + current
      eqtotal = eqtotal + total
    end
  end
  wipe(self.durabilityData.baggedItems)
  local bgcurrent, bgtotal, bgcost = 0, 0, 0
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local _, cost = self.dummy:SetBagItem(bag, slot)
      local current, total = GetContainerItemDurability(bag, slot)
      if cost and cost > 0 then
        bgcost = bgcost + cost
        local itemName, _, itemRarity = GetItemInfo(GetContainerItemID(bag, slot))
        self.durabilityData.baggedItems[gUI4:GetColorCode("quality", itemRarity)..itemName.."|r"] = coin(cost, floor(current/total*100))
      end
      if current and total and current > 0 and total > 0 then
        bgcurrent = bgcurrent + current
        bgtotal = bgtotal + total
      end
    end
  end
  bgcost = max(bgcost, 0)
  
  -- division by zero cause funny funny results
  -- if total durabilities are 0, there are no items to show
  bgcurrent = bgtotal == 0 and 1 or bgcurrent
  bgtotal = bgtotal == 0 and 1 or bgtotal
  eqcurrent = eqtotal == 0 and 1 or eqcurrent
  eqtotal = eqtotal == 0 and 1 or eqtotal
  
  -- store values for the LDB tooltip
  self.durabilityData.baggedDurability = floor(bgcurrent / bgtotal * 100)
  self.durabilityData.baggedCost = bgcost
  self.durabilityData.equippedDurability = floor(eqcurrent / eqtotal * 100)
  self.durabilityData.equippedCost = eqcost
  self.durabilityData.totalCost = bgcost + eqcost
  self.durabilityData.totalDurability = floor((bgcurrent + eqcurrent) / (bgtotal + eqtotal) * 100)
  
  -- update the LDB feed
  if self.dataObject then
    --self.dataObject.text = (" |cffffffff%d|r|cffffd200%%|r"):format(self.durabilityData.equippedDurability)
    self.dataObject.text = " "..coin(self.durabilityData.equippedCost, self.durabilityData.equippedDurability)
  end

end
module.UpdateDurability = gUI4:SafeCallWrapper(module.UpdateDurability) -- queue this for out of combat, to avoid performance loss while fighting baddies

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
  self.db = parent.db:RegisterNamespace("Durability", defaults)
  self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
  self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
  self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
  
  self.durabilityData = { 
    equippedItems = {}, 
    baggedItems = {} 
  }
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateDurability")
  self:RegisterEvent("UPDATE_INVENTORY_DURABILITY", "UpdateDurability")
  self:RegisterEvent("UNIT_INVENTORY_CHANGED", "UpdateDurability")
  self:UpdateDurability() -- initial call just to set base values
end

function module:OnEnable()
  if not self.dataObject then
    self.dataObject = LDB:NewDataObject(L["Goldpaw's UI: Durability"], {
      type = "data source",
      text = "",
      label = DURABILITY,
      icon = "Interface\\Icons\\Trade_BlackSmithing.blp",
      suffix = "%",
      OnTooltipShow = function(self) 
        if module.durabilityData.totalCost > 0 then
          self:AddLine(colorString(DURABILITY, "ffffff"))
          self:AddLine(" ")
          local more
          if module.durabilityData.equippedDurability < 100 then
            self:AddDoubleLine(colorString(CURRENTLY_EQUIPPED..":", "ffd200"), coin(module.durabilityData.equippedCost, module.durabilityData.equippedDurability))
            for name, price in pairs(module.durabilityData.equippedItems) do
              self:AddDoubleLine(name..colorString(":", "ffd200"), price)
            end
            more = true
          end
          if module.durabilityData.baggedDurability < 100 then
            if more then
              self:AddLine(" ")
            end
            self:AddDoubleLine(colorString(INVENTORY_TOOLTIP..":", "ffd200"), coin(module.durabilityData.baggedCost, module.durabilityData.baggedDurability))
            for name, price in pairs(module.durabilityData.baggedItems) do
              self:AddDoubleLine(name..colorString(":", "ffd200"), price)
            end
            more = true
          end
          if module.durabilityData.equippedDurability < 100 and module.durabilityData.baggedDurability < 100 then
            if more then
              self:AddLine(" ")
            end
            self:AddDoubleLine(colorString(TOTAL..":", "ffd200"), coin(module.durabilityData.totalCost, module.durabilityData.totalDurability))
          end
        end
      end
    })
  end
  self:UpdateDurability()
end
