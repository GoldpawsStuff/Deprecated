local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

local smoothing = {}
local function smooth(self, value)
	local _, max = self:GetMinMaxValues()
	if value == self:GetValue() or (self._max and self._max ~= max) then
		smoothing[self] = nil
		self:SetValue_(value)
	else
		smoothing[self] = value
	end
	self._max = max
end

local function SmootherBar(self, bar)
	bar.SetValue_ = bar.SetValue
	bar.SetValue = smooth
end

local function hook(frame)
	frame.SmootherBar = SmootherBar
	if frame.Health and frame.Health.Smoother then
		frame:SmootherBar(frame.Health)
	end
	if frame.Power and frame.Power.Smoother then
		frame:SmootherBar(frame.Power)
	end
end

for i, frame in ipairs(oUF.objects) do hook(frame) end
oUF:RegisterInitCallback(hook)

local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function()
	local limit = 30/GetFramerate()
	for bar, value in pairs(smoothing) do
		local current = bar:GetValue() 
		local new = current and (current + min((value-current)/3, max(value-current, limit))) or value
		bar:SetValue_(new)
		if current == value or abs(new - value) < 2 then
			bar:SetValue_(value)
			smoothing[bar] = nil
		end
	end
end)
