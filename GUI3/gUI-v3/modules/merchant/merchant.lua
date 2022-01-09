--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon, ns = ...

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local module = gUI:NewModule("Merchant")

local min, max = math.min, math.max
local print = print
local select = select

local BuyMerchantItem = BuyMerchantItem
local CanMerchantRepair = CanMerchantRepair
local GetGuildBankMoney = GetGuildBankMoney
local GetGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local GetMoney = GetMoney
local GetMerchantItemLink = GetMerchantItemLink
local GetMerchantItemMaxStack = GetMerchantItemMaxStack
local GetContainerItemID = GetContainerItemID
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerNumSlots = GetContainerNumSlots
local GetItemInfo = GetItemInfo
local GetRepairAllCost = GetRepairAllCost
local IsInGuild = IsInGuild
local RepairAllItems = RepairAllItems
local UseContainerItem = UseContainerItem
local MerchantItemButton_OnModifiedClick = MerchantItemButton_OnModifiedClick -- we NEED this to be a local

local L, C, F, M, db

local defaults = {
	autorepair = true;
	autosell = true;
	guildrepair = true;
	detailedreport = false;
}

-- junkselling macro: 
-- /run local i; for b=0,4,1 do for s=1,GetContainerNumSlots(b) do i=GetContainerItemID(b,s); if(i) and (select(3,GetItemInfo(i))==0) then UseContainerItem(b,s) end end end

module.MERCHANT_SHOW = function(self)
	local gain, sold = 0, 0
	local repaired = false
	local useGuildFunds = (IsInGuild()) and db.guildrepair or false
	local usedGuildFunds = false
	local yourGuildFunds = min((GetGuildBankWithdrawMoney() ~= -1) and GetGuildBankWithdrawMoney() or GetGuildBankMoney(), GetGuildBankMoney())
	local repairCost = (select(1, GetRepairAllCost())) or 0

	local itemID, count, link, rarity, price, stack
	if (db.autosell == true) then
		for bag = 0,4,1 do 
			for slot = 1, GetContainerNumSlots(bag), 1 do 
				itemID = GetContainerItemID(bag, slot)
				if (itemID) then
					count = (select(2, GetContainerItemInfo(bag, slot)))
					_, link, rarity, _, _, _, _, _, _, _, price = GetItemInfo(itemID)

					if (rarity == 0) then
						stack = (price or 0) * (count or 1)
						sold = sold + stack
						
						if (db.detailedreport) then
							print( L["-%s|cFF00DDDDx%d|r %s"]:format(link, count, self:Tag(("[money:%d]"):format(stack))) )
						end
						
						UseContainerItem(bag, slot)
					end
				end 
			end 
		end
		gain = gain + sold
	end

	if (sold > 0) then 
		print(L["Earned %s"]:format(self:Tag(("[money:%d]"):format(sold))))
	end

	if (db.autorepair) and CanMerchantRepair() and (repairCost > 0) then

		if (max(GetMoney(), yourGuildFunds) > repairCost) then
		
			if (useGuildFunds and yourGuildFunds > repairCost) and MerchantGuildBankRepairButton:IsEnabled() and MerchantGuildBankRepairButton:IsShown() then
				RepairAllItems(1)
				usedGuildFunds = true
				repaired = true
				print(L["You repaired your items for %s using Guild Bank funds"]:format(self:Tag(("|cffff0000[money:%d]|r"):format(repairCost))))
	
			elseif (GetMoney() > repairCost) then
				RepairAllItems() 
				repaired = true
				print(L["You repaired your items for %s"]:format(self:Tag(("|cffff0000[money:%d]|r"):format(repairCost))))
				
				gain = gain - repairCost
			end
			
		else
			print(L["You haven't got enough available funds to repair!"])
		end
	end

	if (gain > 0) then
		print(L["Your profit is %s"]:format(self:Tag(("[money:%d]"):format(gain))))
		
	elseif (gain < 0) then 
		print(L["Your expenses are %s"]:format(self:Tag(("|cFFFF0000[money:%d]|r"):format(-gain))))
	end
end

module.OnInit = function(self)
	L, C, F, M, db = gUI:GetEnvironment(self, defaults) -- get the gUI environment 
	

	-- pre-hook the modified click handler
	-- local OrigMerchantItemButton_OnModifiedClick = _G.MerchantItemButton_OnModifiedClick
	_G.MerchantItemButton_OnModifiedClick = function(self, ...)
		if (IsAltKeyDown()) then
			local ID = self:GetID()
			if (ID) then
				local max = select(8, GetItemInfo(GetMerchantItemLink(ID)))
				if (max and max > 1) then
					BuyMerchantItem(ID, GetMerchantItemMaxStack(ID))
				end
			end
		end
		MerchantItemButton_OnModifiedClick(self, ...) -- this is our local copy of the original function
	end
	
	-- set the tooltip to reflect the added functionality
	ITEM_VENDOR_STACK_BUY = ITEM_VENDOR_STACK_BUY .. "|n" .. L["<Alt-Click to buy the maximum amount>"]

	-- options menu
	do
		local menuTable = {
			{
				type = "group";
				name = module:GetName();
				order = 1;
				virtual = true;
				children = {
					{
						type = "widget";
						element = "Title";
						order = 1;
						msg = L["Merchants"];
					};
					{
						type = "widget";
						element = "Text";
						order = 2;
						msg = L["Here you can configure the options for automatic actions upon visiting a merchant, like selling junk and repairing your armor."];
					};
					{
						type = "group";
						order = 5;
						virtual = true;
						children = {
							{ -- detailedreport
								type = "widget";
								element = "CheckButton";
								name = "detailedreport";
								order = 11;
								indented = true;
								msg = L["Show detailed sales reports"];
								desc = L["Enabling this option will show a detailed report of the automatically sold items in the default chat frame. Disabling it will restrict the report to gold earned, and the cost of repairs."];
								set = function(self) 
									db.detailedreport = not(db.detailedreport)
								end;
								get = function() return db.detailedreport end;
							};
							{ -- autosell
								type = "widget";
								element = "CheckButton";
								name = "autosell";
								order = 10;
								msg = L["Automatically sell poor quality items"];
								desc = L["Enabling this option will automatically sell poor quality items in your bags whenever you visit a merchant."];
								set = function(self) 
									db.autosell = not(db.autosell)
									self:onrefresh()
								end;
								get = function() return db.autosell end;
								onrefresh = function(self)
									if (db.autosell) then
										self.parent.child.detailedreport:Enable()
									else
										self.parent.child.detailedreport:Disable()
									end
								end;
								init = function(self)
									self:onrefresh()
								end;
							};
							{ -- autorepair
								type = "widget";
								element = "CheckButton";
								name = "autorepair";
								order = 15;
								msg = L["Automatically repair your armor and weapons"];
								desc = L["Enabling this option will automatically repair your items whenever you visit a merchant with repair capability, as long as you have sufficient funds to pay for the repairs."];
								set = function(self) 
									db.autorepair = not(db.autorepair)
									self:onrefresh()
								end;
								get = function() return db.autorepair end;
								onrefresh = function(self)
									if (db.autorepair) then
										self.parent.child.guildrepair:Enable()
									else
										self.parent.child.guildrepair:Disable()
									end
								end;
								init = function(self)
									self:onrefresh()
								end;
							};
							{ -- guildrepair
								type = "widget";
								element = "CheckButton";
								name = "guildrepair";
								order = 20;
								indented = true;
								msg = L["Use your available Guild Bank funds to when available"];
								desc = L["Enabling this option will cause the automatic repair to be done using Guild funds if available."];
								set = function(self) 
									db.guildrepair = not(db.guildrepair)
								end;
								get = function() return db.guildrepair end;
							};
						};
					};
				};
			};
		}
		local restoreDefaults = function()
			if (InCombatLockdown()) then 
				print(L["Can not apply default settings while engaged in combat."])
				return
			end
			self:ResetCurrentOptionsSetToDefaults()
		end
		self:RegisterAsBlizzardOptionsMenu(menuTable, L["Merchants"], "default", restoreDefaults)
	end
	
end

module.OnEnable = function(self)
	self:RegisterEvent("MERCHANT_SHOW")
end

module.OnDisable = function(self)
	self:UnregisterEvent("MERCHANT_SHOW")
end
