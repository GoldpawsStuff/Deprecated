--[[ Element: Resting Icon

 Toggles visibility of the resting icon.

 Widget

 Resting - Any UI widget.

 Notes

 The default resting icon will be used if the UI widget is a texture and doesn't
 have a texture or color defined.

 Examples

   -- Position and size
   local Resting = self:CreateTexture(nil, 'OVERLAY')
   Resting:SetSize(16, 16)
   Resting:SetPoint('TOPLEFT', self)
   
   -- Register it with oUF
   self.Resting = Resting

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event)
	local resting = self.Resting
	if(resting.PreUpdate) then
		resting:PreUpdate()
	end

	local isResting = IsResting()
	if(isResting) then
		resting:Show()
	else
		resting:Hide()
	end

	if(resting.PostUpdate) then
		return resting:PostUpdate(isResting)
	end
end

local Path = function(self, ...)
	return (self.Resting.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Enable = function(self, unit)
	local resting = self.Resting
	if(resting and unit == 'player') then
		resting.__owner = self
		resting.ForceUpdate = ForceUpdate

		self:RegisterEvent("PLAYER_UPDATE_RESTING", Path, true)

		if(resting:IsObjectType"Texture" and not resting:GetTexture()) then
			resting:SetTexture[[Interface\CharacterFrame\UI-StateIcon]]
			resting:SetTexCoord(0, .5, 0, .421875)
		end

		return true
	end
end

local Disable = function(self)
	local resting = self.Resting
	if(resting) then
		self:UnregisterEvent("PLAYER_UPDATE_RESTING", Path)
	end
end

oUF:AddElement('Resting', Path, Enable, Disable)
