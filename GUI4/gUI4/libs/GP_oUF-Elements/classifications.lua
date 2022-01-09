local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local tinsert = table.insert

local UnitClassification = UnitClassification
local UnitLevel = UnitLevel

local Update = function(self, event, unit)
	local classification = self.Classification

	if classification.PreUpdate then
		classification:PreUpdate()
	end

	local unit = self.unit
	local unitClassification = unit and UnitClassification(unit)
	if unitClassification == "elite" or unitClassification == "rareelite" then
		local level = UnitLevel(unit)
		if not level or level < 0 then
			unitClassification = "worldboss"
		end
	end
	
	if unitClassification then 
		for i,texture in pairs(classification.textures) do
			if texture then 
				if i == unitClassification then
					texture:Show()
				else
					texture:Hide()
				end
			end
		end
	end

	if classification.PostUpdate then
		return classification:PostUpdate(unitClassification)
	end
end

local Path = function(self, ...)
	return (self.Classification.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Disable = function(self)
	if self.Classification then
		self:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED", Path)
	end
end

local Enable = function(self, unit)
	local classification = self.Classification
	if classification then 
		classification.__owner = self
		classification.ForceUpdate = ForceUpdate	
		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", Path, true)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Path, true)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path, true)
		tinsert(self.__elements, Update)
	end
end

oUF:AddElement("Classification", Path, Enable, Disable)
