local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local gUI4_ActionBars = gUI4:GetModule("gUI4_ActionBars", true)
if not gUI4_ActionBars then return end

local LibWin = GP_LibStub("GP_LibWindow-1.1")

local Scaffold = CreateFrame("Button")
local Scaffold_MT = { __index = Scaffold }
gUI4_ActionBars.Scaffold = Scaffold

-- Lua API
local min, max = math.min, math.max
local pairs = pairs
local tconcat, tinsert = table.concat, table.insert
local tonumber = tonumber

function Scaffold:SetConfigAlpha(alpha)
	local settings = self:GetSettings()
	if alpha then
		settings.alpha = alpha
	end
	if not self.faded then
		self:SetAlpha(settings.alpha)
	end
end

function Scaffold:ShowGrid()
	self.showGrid = true
end

function Scaffold:HideGrid()
	self.showGrid = nil
end

function Scaffold:ApplySettings()
	local settings = self:GetSettings()
	self:RegisterConfig(settings.position)
	self:SavePosition()
	self:LoadPosition()
	self:SetConfigAlpha()
	self:ApplyVisibilityDriver()
end

function Scaffold:Enable()
	if self.enabled then return end
	local settings = self:GetSettings()
	settings.enabled = true
	self.enabled = true
	self:ApplyVisibilityDriver()
end

function Scaffold:Disable()
	if not self.enabled then return end
	local settings = self:GetSettings()
	settings.enabled = false
	self.enabled = false
	self:ApplyVisibilityDriver()
end

function Scaffold:IsEnabled()
	return self.enabled
end

function Scaffold:RegisterConfig(settings)
	LibWin.RegisterConfig(self, settings)
end

-- the following sometimes gets called before they have an actual on-screen position.
-- rather than rewrite the whole theme system, we simply skip the bad calls.
function Scaffold:LoadPosition()
	local settings = self:GetSettings()
	if settings and settings.position and settings.position.x then
		LibWin.RestorePosition(self)
	end
end
function Scaffold:SavePosition()
	if self:GetPoint() then
		-- print(self:GetName(), self:GetPoint())
		LibWin.SavePosition(self)
	end
end

local condition = {
	pet = true,
	nopet = true,
	combat = true,
	nocombat = true,
	mounted = true
}
function Scaffold:ApplyVisibilityDriver()
	local settings = self:GetSettings()
	self.driver = {}
	if self.id == "Pet" then
		for key, value in pairs(settings.visibility) do
			if value then
				if key == "always" then
					tinsert(self.driver, "hide")
				elseif key == "possess" then
					tinsert(self.driver, "[possessbar,nopet]hide")
				elseif key == "overridebar" then
					tinsert(self.driver, "[overridebar,nopet]hide")
				elseif key == "vehicleui" then
					tinsert(self.driver, "[vehicleui,nopet]hide")
				elseif key == "vehicle" then
					tinsert(self.driver, "[target=vehicle,exists,nopet]hide")
				elseif condition[key] then
					tinsert(self.driver, ("[%s]hide"):format(key))
				elseif key == "form" then
					for k,v in pairs(value) do
						if v then
							tinsert(self.driver, ("[form:%d]hide"):format(k))
						end
					end
				end
			end
		end	
	else
		for key, value in pairs(settings.visibility) do
			if value then
				if key == "always" then
					tinsert(self.driver, "hide")
				elseif key == "possess" then
					tinsert(self.driver, "[possessbar]hide")
				elseif key == "overridebar" then
					tinsert(self.driver, "[overridebar]hide")
				elseif key == "vehicleui" then
					tinsert(self.driver, "[vehicleui]hide")
				elseif key == "vehicle" then
					tinsert(self.driver, "[target=vehicle,exists]hide")
				elseif condition[key] then
					tinsert(self.driver, ("[%s]hide"):format(key))
				elseif key == "form" then
					for k,v in pairs(value) do
						if v then
							tinsert(self.driver, ("[form:%d]hide"):format(k))
						end
					end
				end
			end
		end	
	end
	tinsert(self.driver, 1, "[petbattle]hide")
	tinsert(self.driver, "show")
	-- if tostring(self.id) == "6" or tostring(self.id) == "5" then 
		-- wipe(self.driver)
		-- tinsert(self.driver, "[noform]hide;show")
	-- end
	if settings.enabled then
		UnregisterStateDriver(self, "visibility")
		RegisterStateDriver(self, "visibility", tconcat(self.driver, ";"))
	else
		UnregisterStateDriver(self, "visibility")
		RegisterStateDriver(self, "visibility", "hide")
	end
end

function Scaffold:New(id, name, settingsFunc)
	local bar = setmetatable(CreateFrame("Frame", "GUI4Bar"..id, UIParent, "SecureHandlerStateTemplate"), Scaffold_MT)
	bar.name = name or id
	bar.id = id
	bar.GetSettings = settingsFunc
	bar:SetSize(1,1)
	local settings = bar.GetSettings and bar:GetSettings()
	if settings and settings.position and settings.position.x then
		bar:SetPoint(settings.position.point, floor(settings.position.x), floor(settings.position.y))
	end
	bar:SetMovable(true)
	return bar
end
