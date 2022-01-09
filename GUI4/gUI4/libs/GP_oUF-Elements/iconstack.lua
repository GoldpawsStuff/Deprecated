local _,ns = ...

local oUF = ns.oUF
if not oUF then return end

-- WoW API
local GetLootMethod = _G.GetLootMethod
local GetNumGroupMembers = _G.GetNumGroupMembers
local GetRaidRosterInfo = _G.GetRaidRosterInfo
local UnitInParty = _G.UnitInParty
local UnitInRaid = _G.UnitInRaid
local UnitIsGroupAssistant = _G.UnitIsGroupAssistant
local UnitIsGroupLeader = _G.UnitIsGroupLeader
local UnitIsUnit = _G.UnitIsUnit

local widget = "IconStackWidget"
local points = {
	RIGHT = { "TOPLEFT", "TOPRIGHT" },
	LEFT = { "TOPRIGHT", "TOPLEFT" },
	UP = { "BOTTOMLEFT", "TOPLEFT" },
	DOWN = { "TOPLEFT", "BOTTOMLEFT" }
}

local Update = function(self, _, ...)
	local IconStack = self[widget]
	if IconStack then
		if IconStack.PreUpdate then
			IconStack:PreUpdate()
		end
		
		local first = true
		local anchor = IconStack
		local point = IconStack.point
		local growth = IconStack.growth
		local padding = IconStack.padding
		local offsetY = 0
		
		-- check for group leader
		if IconStack.showLeader then
			local Leader = IconStack.Leader
			if Leader.PreUpdate then
				Leader:PreUpdate()
			end
			local unit = self.unit
			local isLeader = (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsGroupLeader(unit)
			if isLeader then
				Leader:ClearAllPoints()
				Leader:SetPoint(point, anchor, point, 0, 0)
				Leader:Show()
				first = false
				anchor = Leader
			else
				Leader:Hide()
			end
			if Leader.PostUpdate then
				return Leader:PostUpdate(isLeader)
			end
		else
			IconStack.Leader:Hide()
		end
		
		-- check for group assistant
		if IconStack.showAssistant then
			local Assistant = IconStack.Assistant
			if Assistant.PreUpdate then
				Assistant:PreUpdate()
			end
			local unit = self.unit
			local isAssistant = UnitInRaid(unit) and UnitIsGroupAssistant(unit) and not UnitIsGroupLeader(unit)
			if isAssistant then
				Assistant:ClearAllPoints()
				if first then 
					Assistant:SetPoint(point, anchor, point, 0, 0)
					first = false
				else
					Assistant:SetPoint(points[growth][1], anchor, points[growth][2], padding, offsetY)
				end
				Assistant:Show()
				anchor = Assistant
			else
				Assistant:Hide()
			end
			if Assistant.PostUpdate then
				return Assistant:PostUpdate(isAssistant)
			end
		else
			IconStack.Assistant:Hide()
		end
		
		-- check for Main Tank
		if IconStack.showMainTank then
			local MainTank = IconStack.MainTank
			if MainTank.PreUpdate then
				MainTank:PreUpdate()
			end
			local unit = self.unit
			local isMainTank
			if UnitInRaid(unit) then
				for i = 1, GetNumGroupMembers() do
					if UnitIsUnit(self.unit, "raid"..i) then
						local _, _, _, _, _, _, _, _, _, role, _, _ = GetRaidRosterInfo(i)
						if role == "MAINTANK" then
							MainTank:Show()
							isMainTank = true
							break
						end
					end
				end
				if isMainTank then
					MainTank:ClearAllPoints()
					if first then 
						MainTank:SetPoint(point, anchor, point, 0, 0)
						first = false
					else
						MainTank:SetPoint(points[growth][1], anchor, points[growth][2], padding, offsetY)
					end
					MainTank:Show()
					anchor = MainTank
				else
					MainTank:Hide()
				end
			else
				MainTank:Hide()
			end
			if MainTank.PostUpdate then
				return MainTank:PostUpdate(isMainTank)
			end
		else
			IconStack.MainTank:Hide()
		end
		
		-- check for Main Assist
		if IconStack.showMainAssist then
			local MainAssist = IconStack.MainAssist
			if MainAssist.PreUpdate then
				MainAssist:PreUpdate()
			end
			local unit = self.unit
			local isMainAssist
			if UnitInRaid(unit) then
				for i = 1, GetNumGroupMembers() do
					if UnitIsUnit(self.unit, "raid"..i) then
						local _, _, _, _, _, _, _, _, _, role, _, _ = GetRaidRosterInfo(i)
						if role == "MAINASSIST" then
							MainAssist:Show()
							isMainAssist = true
							break
						end
					end
				end
				if isMainAssist then
					MainAssist:ClearAllPoints()
					if first then 
						MainAssist:SetPoint(point, anchor, point, 0, 0)
						first = false
					else
						MainAssist:SetPoint(points[growth][1], anchor, points[growth][2], padding, offsetY)
					end
					MainAssist:Show()
					anchor = MainAssist
				else
					MainAssist:Hide()
				end
			else
				MainAssist:Hide()
			end
			if MainAssist.PostUpdate then
				return MainAssist:PostUpdate(isMainAssist)
			end
		else
			IconStack.MainAssist:Hide()
		end
		
		-- check for Master Looter
		if IconStack.showMasterLooter then
			local MasterLooter = IconStack.MasterLooter
			if MasterLooter.PreUpdate then
				MasterLooter:PreUpdate()
			end
			local unit = self.unit
			if not (UnitInParty(unit) or UnitInRaid(unit)) then
				return MasterLooter:Hide()
			end
			local isMasterLooter
			local method, pid, rid = GetLootMethod()
			if method == "master" then
				local mlUnit
				if pid then
					if pid == 0 then
						mlUnit = "player"
					else
						mlUnit = "party"..pid
					end
				elseif rid then
					mlUnit = "raid"..rid
				end
				if UnitIsUnit(unit, mlUnit) then
					isMasterLooter = true
					MasterLooter:Show()
				elseif MasterLooter:IsShown() then
					MasterLooter:Hide()
				end
				if isMasterLooter then
					MasterLooter:ClearAllPoints()
					if first then 
						MasterLooter:SetPoint(point, anchor, point, 0, 0)
						first = false
					else
						MasterLooter:SetPoint(points[growth][1], anchor, points[growth][2], padding, offsetY + 2)
						offsetY = -2
					end
					MasterLooter:Show()
					anchor = MasterLooter
				else
					MasterLooter:Hide()
				end
			else
				MasterLooter:Hide()
			end
			if MasterLooter.PostUpdate then
				return MasterLooter:PostUpdate(isMasterLooter)
			end
		else
			IconStack.MasterLooter:Hide()
		end
		
		if IconStack.PostUpdate then
			return IconStack:PostUpdate()
		end
	end
end

local Path = function(self, ...)
	return (self[widget].Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local events = {
	PARTY_LEADER_CHANGED = false,
	GROUP_ROSTER_UPDATE = false,
	PARTY_LOOT_METHOD_CHANGED = false,
}

local Disable = function(self)
	local IconStack = self[widget]
	if IconStack then 
		for event, registered in pairs(events) do
			if registered then
				self:UnregisterEvent(event, Path)
				events[event] = false
			end
		end
	end
end

local Enable = function(self)
	local IconStack = self[widget]
	if IconStack then 
		IconStack.__owner = self
		IconStack.ForceUpdate = ForceUpdate
		
		IconStack.point = IconStack.point or "BOTTOMLEFT"
		IconStack.growth = IconStack.growth or "RIGHT"
		IconStack.padding = IconStack.padding or 0
		
		local Leader = IconStack.Leader
		if Leader then
			self:RegisterEvent("PARTY_LEADER_CHANGED", Path, true)
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Path, true)
			events.PARTY_LEADER_CHANGED = true
			events.GROUP_ROSTER_UPDATE = true
			if Leader:IsObjectType("Texture") and not Leader:GetTexture() then
				Leader:SetTexture[[Interface\GroupFrame\UI-Group-LeaderIcon]]
			end
		end
		
		local Assistant = IconStack.Assistant
		if Assistant then
			if not events.GROUP_ROSTER_UPDATE then
				self:RegisterEvent("GROUP_ROSTER_UPDATE", Path, true)
				events.GROUP_ROSTER_UPDATE = true
			end
			if Assistant:IsObjectType("Texture") and not Assistant:GetTexture() then
				Assistant:SetTexture[[Interface\GroupFrame\UI-Group-AssistantIcon]]
			end
		end
		
		local MainTank = IconStack.MainTank
		if MainTank then
			if not events.GROUP_ROSTER_UPDATE then
				self:RegisterEvent("GROUP_ROSTER_UPDATE", Path, true)
				events.GROUP_ROSTER_UPDATE = true
			end
			if MainTank:IsObjectType("Texture") and not MainTank:GetTexture() then
				MainTank:SetTexture[[Interface\GroupFrame\UI-GROUP-MAINTANKICON]]
			end
		end
		
		local MainAssist = IconStack.MainAssist
		if MainAssist then
			if not events.GROUP_ROSTER_UPDATE then
				self:RegisterEvent("GROUP_ROSTER_UPDATE", Path, true)
				events.GROUP_ROSTER_UPDATE = true
			end
			if MainAssist:IsObjectType("Texture") and not MainAssist:GetTexture() then
				MainAssist:SetTexture[[Interface\GroupFrame\UI-GROUP-MAINASSISTICON]]
			end
		end
		
		local MasterLooter = IconStack.MasterLooter
		if MasterLooter then
			if not events.GROUP_ROSTER_UPDATE then
				self:RegisterEvent("GROUP_ROSTER_UPDATE", Path, true)
				events.GROUP_ROSTER_UPDATE = true
			end
			if not events.PARTY_LOOT_METHOD_CHANGED then
				self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED", Path, true)
				events.PARTY_LOOT_METHOD_CHANGED = true
			end
			if MasterLooter:IsObjectType("Texture") and not MasterLooter:GetTexture() then
				MasterLooter:SetTexture[[Interface\GroupFrame\UI-Group-MasterLooter]]
			end
		end
		
		return true
	end
end

oUF:AddElement(widget, Path, Enable, Disable)