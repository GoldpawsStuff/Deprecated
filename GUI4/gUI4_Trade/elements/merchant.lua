local addon,_ = ...

local gUI4 = _G.GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule(addon, true)
if not parent then return end

local module = parent:NewModule("Merchant", "GP_AceEvent-3.0")

local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- Lua API
local _G = _G
local min, max, abs = math.min, math.max, math.abs
local print = print
local select = select

-- WoW API
local BuyMerchantItem = _G.BuyMerchantItem
local CanMerchantRepair = _G.CanMerchantRepair
local GetGuildBankMoney = _G.GetGuildBankMoney
local GetGuildBankWithdrawMoney = _G.GetGuildBankWithdrawMoney
local GetMoney = _G.GetMoney
local GetMerchantItemLink = _G.GetMerchantItemLink
local GetMerchantItemMaxStack = _G.GetMerchantItemMaxStack
local GetCoinTextureString = _G.GetCoinTextureString
local GetContainerItemID = _G.GetContainerItemID
local GetContainerItemInfo = _G.GetContainerItemInfo
local GetContainerNumSlots = _G.GetContainerNumSlots
local GetItemInfo = _G.GetItemInfo
local GetRepairAllCost = _G.GetRepairAllCost
local IsAltKeyDown = _G.IsAltKeyDown
local IsInGuild = _G.IsInGuild
local RepairAllItems = _G.RepairAllItems
local UseContainerItem = _G.UseContainerItem
local MerchantGuildBankRepairButton = _G.MerchantGuildBankRepairButton

local defaults = {
	profile = {
		autorepair = true,
		autosell = true,
		guildrepair = true,
		detailedreport = false
	}
}

-- pre-hook the modified click handler
local _MerchantItemButton_OnModifiedClick = _G.MerchantItemButton_OnModifiedClick -- we NEED this to be a local
function _G.MerchantItemButton_OnModifiedClick(self, ...)
	if IsAltKeyDown() then
		local ID = self:GetID()
		if ID then
			local max = select(8, GetItemInfo(GetMerchantItemLink(ID)))
			if max and max > 1 then
				BuyMerchantItem(ID, GetMerchantItemMaxStack(ID))
			end
		end
	end
	_MerchantItemButton_OnModifiedClick(self, ...)
end

-- set the tooltip to reflect the added functionality
_G.ITEM_VENDOR_STACK_BUY = _G.ITEM_VENDOR_STACK_BUY .. "|n" .. L["<Alt-Click to buy the maximum amount>"]

function module:UpdateMerchant()
	local gain, sold = 0, 0
	local repaired = false
	local useGuildFunds = IsInGuild() and self.db.profile.guildrepair
	local usedGuildFunds = false
	local yourGuildFunds = min((GetGuildBankWithdrawMoney() ~= -1) and GetGuildBankWithdrawMoney() or GetGuildBankMoney(), GetGuildBankMoney())
	local repairCost = select(1, GetRepairAllCost()) or 0
	local itemID, count, link, rarity, price, stack
	if self.db.profile.autosell and not(_G.ZygorGuidesViewer and _G.ZygorGuidesViewer.db.profile.autosell) then -- let zygor handle it if available
		for bag = 0,4,1 do 
			for slot = 1, GetContainerNumSlots(bag), 1 do 
				itemID = GetContainerItemID(bag, slot)
				if itemID then
					count = select(2, GetContainerItemInfo(bag, slot))
					_, link, rarity, _, _, _, _, _, _, _, price = GetItemInfo(itemID)
					if rarity == 0 then
						stack = (price or 0) * (count or 1)
						sold = sold + stack
						if self.db.profile.detailedreport then
							print(L["-%s|cFF00DDDDx%d|r %s"]:format(link, count, GetCoinTextureString(stack)))
						end
						UseContainerItem(bag, slot)
					end
				end 
			end 
		end
		gain = gain + sold
	end
	if sold > 0 then 
		print(L["Earned %s"]:format(GetCoinTextureString(sold)))
	end
	if self.db.profile.autorepair and CanMerchantRepair() and repairCost > 0 then
		if max(GetMoney(), yourGuildFunds) > repairCost then
			if (useGuildFunds and (yourGuildFunds > repairCost)) and MerchantGuildBankRepairButton:IsEnabled() and MerchantGuildBankRepairButton:IsShown() then
				RepairAllItems(1)
				usedGuildFunds = true
				repaired = true
				print(L["You repaired your items for %s using Guild Bank funds"]:format(L["|cffff0000%s|r"]:format(GetCoinTextureString(repairCost))))
			elseif GetMoney() > repairCost then
				RepairAllItems() 
				repaired = true
				print(L["You repaired your items for %s"]:format(L["|cffff0000%s|r"]:format(GetCoinTextureString(repairCost))))
				gain = gain - repairCost
			end
		else
			print(L["You haven't got enough available funds to repair!"])
		end
	end
	if gain > 0 then
		print(L["Your profit is %s"]:format(GetCoinTextureString(gain)))
	elseif gain < 0 then 
		print(L["Your expenses are %s"]:format(L["|cffff0000%s|r"]:format(GetCoinTextureString(abs(gain)))))
	end
end

function module:ApplySettings()
end
module.ApplySettings = gUI4:SafeCallWrapper(module.ApplySettings)

function module:OnInitialize()
	self.db = parent.db:RegisterNamespace("Merchant", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ApplySettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ApplySettings")
	self:RegisterEvent("MERCHANT_SHOW", "UpdateMerchant")
end

function module:OnEnable()
	
end

function module:OnDisable()
end
