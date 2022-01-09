local _,ns = ...

local oUF = ns.oUF
if not oUF then return end

-- WoW API
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned

local Update = function(self)
	local GroupRole = self.GroupRole
	if GroupRole.PreUpdate then
		GroupRole:PreUpdate()
	end
	
	local role = UnitGroupRolesAssigned(self.unit)
	if role == "TANK" or role == "HEALER" or role == "DAMAGER" then
		if GroupRole.Tank then
			if role == "TANK" and GroupRole.showTank then
				GroupRole.Tank:Show()
			else
				GroupRole.Tank:Hide()
			end
		end
		if GroupRole.Healer then
			if role == "HEALER" and GroupRole.showHealer then
				GroupRole.Healer:Show()
			else
				GroupRole.Healer:Hide()
			end
		end
		if GroupRole.DPS then
			if role == "DAMAGER" and GroupRole.showDPS then
				GroupRole.DPS:Show()
			else
				GroupRole.DPS:Hide()
			end
		end
		GroupRole:Show()
	else
		GroupRole:Hide()
	end
	
	if GroupRole.PostUpdate then
		return GroupRole:PostUpdate(role)
	end
end

local Path = function(self, ...)
	return (self.GroupRole.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate")
end

local Enable = function(self)
	local GroupRole = self.GroupRole
	if GroupRole then
		GroupRole.__owner = self
		GroupRole.ForceUpdate = ForceUpdate
		
		if self.unit == "player" then
			self:RegisterEvent("PLAYER_ROLES_ASSIGNED", Path, true)
		else
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Path, true)
		end
		
		return true
	end
end

local Disable = function(self)
	local GroupRole = self.GroupRole
	if GroupRole then
		GroupRole:Hide()
		self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Path)
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", Path)
	end
end

oUF:AddElement("GroupRole", Path, Enable, Disable)