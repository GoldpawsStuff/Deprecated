local _, gUI4 = ...

-- Lua API
local _G = _G

-- WoW API
local CreateFrame = _G.CreateFrame
local UIFrameFade = _G.UIFrameFade
local UIFrameFadeIn = _G.UIFrameFadeIn
local UIFrameFadeRemoveFrame = _G.UIFrameFadeRemoveFrame
local UIFrameIsFading = _G.UIFrameIsFading
local UIParent = _G.UIParent

-------------------------------------------------------------------------------
--	Fullscreen FadeOut
-------------------------------------------------------------------------------
local frame
local function getFader()
	if not frame then
		frame = CreateFrame("Frame", nil, UIParent)
		frame:Hide()
		frame:SetAlpha(0)
		frame:SetAllPoints()
		frame:SetFrameStrata("HIGH")
		frame:SetFrameLevel(129)
		frame.texture = frame:CreateTexture(nil, "BACKGROUND")
		frame.texture:SetTexture(0, 0, 0)
		frame.texture:SetAlpha(.75)
		frame.texture:SetAllPoints(frame)
	end
	return frame
end
local function finishedFunc() 
	getFader():Hide() 
end
function gUI4:FullScreenFadeOut()
	if UIFrameIsFading(getFader()) then 
		UIFrameFadeRemoveFrame(getFader())
	end
	getFader().texture:SetAlpha(.75)
	UIFrameFadeIn(getFader(), (1 - getFader():GetAlpha()) * 3.5, getFader():GetAlpha(), 1)
end
function gUI4:FullScreenFadeIn()
	if UIFrameIsFading(getFader()) then 
		UIFrameFadeRemoveFrame(getFader())
	end
	local fadeInfo = {}
	fadeInfo.mode = "OUT"
	fadeInfo.startAlpha = getFader():GetAlpha()
	fadeInfo.endAlpha = 0
	fadeInfo.timeToFade = getFader():GetAlpha() * 1.5
	fadeInfo.finishedFunc = finishedFunc -- this is why we do it manually
	UIFrameFade(getFader(), fadeInfo)
end
