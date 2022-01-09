assert(GP_LibStub, "GP_LibFlash-1.0 requires GP_LibStub")
assert(GP_LibStub:GetLibrary("GP_CallbackHandler-1.0", true), "GP_LibFlash-1.0 requires GP_CallbackHandler-1.0")

local MAJOR, MINOR = "GP_LibFlash-1.0", 10
local lib = GP_LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end -- No upgrade needed

lib.numFades = lib.numFades or 0
lib.numFlashes = lib.numFlashes or 0
lib.fadeFrames = lib.fadeFrames or {}
lib.fadeTimers = lib.fadeTimers or {}
lib.flashFrames = lib.flashFrames or {}
lib.flashTimers = lib.flashTimers or {}
lib.mixed = lib.mixed or {}
lib.embeds = lib.embeds or {}
lib.frame = lib.frame or CreateFrame("Frame", "LibFlash10Frame")

-- Lua API
local _G = _G
local tinsert, tremove = table.insert, table.remove
local wipe = table.wipe

-- WoW API
local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime

--[[
--	Usage of frame fades:
--		frame = lib:ApplyFadersToFrame(frame) -- this call embeds our methods into the target frame
--		
--	Fading a frame in:
--		frame:SetAlpha(0) -- do this initially, to keep transitions smooth
--		frame:Show() -- normal show commands (even done through secure drivers) will fire off the fade-in
--		
--	Fading a frame out:
--		frame:SetFadeOut(durationOut) -- do this out of combat
--		frame:StartFadeOut() -- this will start an animation that fades, then securely hides the frame when done
--		
--	Flashing a frame:
--		frame:StartFlash(durationOut, durationIn, minAlpha, maxAlpha, killOnHide) -- starts it
--		frame:StopFlash() -- stops a flash until manually restarted, clears all parameters
--		frame:PauseFlash() -- pauses a flash
--		frame:ResumeFlash() -- resumes a flash with the previously entered parameters
--		
--		*flashing frames will pause & resume automatically when hidden and reshown, unless 'killOnHide' is 'true'
]]--


lib.frame:SetScript("OnUpdate", function(self, elapsed)
  local lib = lib -- slight speed boost
	local frame
	local fadeIndex = lib.numFades
	local flashIndex = lib.numFlashes
	
	-- check for fading
	while lib.fadeTimers[fadeIndex] do
		frame = lib.fadeTimers[fadeIndex]
		if frame then
			if lib.fadeFrames[frame].isFading then 
				-- calculate new alpha
				local currentAlpha = frame:GetAlpha()
				local targetAlpha = lib.fadeFrames[frame].targetAlphaIn
				local alphaChange = elapsed/lib.fadeFrames[frame].durationIn * targetAlpha
		
				-- apply new alpha
				if currentAlpha + alphaChange < targetAlpha then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
				end
				frame:SetAlpha(currentAlpha)
				
				-- remove frame if target alpha is reached, or the frame has been hidden
				if currentAlpha >= lib.fadeFrames[frame].targetAlphaIn or not frame:IsShown() then
					lib.fadeFrames[frame].isFading = false
					
					tremove(lib.fadeTimers, fadeIndex)
					lib.numFades = lib.numFades - 1
					
					-- if the frame was flashing before it was hidden, resume the flashing now
					if lib.flashFrames[frame] and lib.flashFrames[frame].isFlashingPaused and not lib.flashFrames[frame].killOnHide then
						lib.flashFrames[frame].isFlashingPaused = nil
					end
				end
			else
				tremove(lib.fadeTimers, fadeIndex)
				lib.numFades = lib.numFades - 1
				
				-- if the frame was flashing before it was hidden, resume the flashing now
				if lib.flashFrames[frame] and lib.flashFrames[frame].isFlashingPaused and not lib.flashFrames[frame].killOnHide then
					lib.flashFrames[frame].isFlashingPaused = nil
				end
			end
		end
		fadeIndex = fadeIndex - 1
	end
		
	-- check for flashing
	while lib.flashTimers[flashIndex] do
		frame = lib.flashTimers[flashIndex]
		if frame then
			if frame:IsShown() -- only flash visible frames
			and not(lib.flashFrames[frame].isFlashingPaused -- don't flash while manually paused
			or (lib.fadeFrames[frame] and lib.fadeFrames[frame].isFading) -- don't flash while fading in
			or (lib.fadeFrames[frame] and lib.fadeFrames[frame].fadeOutAnimation and lib.fadeFrames[frame].fadeOutAnimation:IsPlaying())) then -- don't flash while fading out
				local currentAlpha = frame:GetAlpha()
				local minAlpha = lib.flashFrames[frame].minAlpha
				local maxAlpha = lib.flashFrames[frame].maxAlpha

				-- update fade direction
				if currentAlpha <= minAlpha then
					lib.flashFrames[frame].direction = "IN"
				elseif currentAlpha >= maxAlpha then
					lib.flashFrames[frame].direction = "OUT"
				end
				
				-- calculate alpha change
				local fadeOut = lib.flashFrames[frame].direction == "OUT"
				local duration = fadeOut and lib.flashFrames[frame].durationOut or lib.flashFrames[frame].durationIn
				local targetAlpha = fadeOut and lib.flashFrames[frame].minAlpha or lib.flashFrames[frame].maxAlpha
				local alphaChange = elapsed/duration * (maxAlpha - minAlpha)

				-- apply new alpha
				if fadeOut and (currentAlpha - alphaChange > targetAlpha) then
					currentAlpha = currentAlpha - alphaChange
				elseif currentAlpha + alphaChange < targetAlpha then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
				end
				frame:SetAlpha(currentAlpha)
				
				-- allow the flash to go back to max before removing it
				if lib.flashFrames[frame].scheduleForRemoval and currentAlpha >= maxAlpha then
					if lib.flashFrames[frame].fallbackAlpha and frame:IsShown() then
						frame:SetAlpha(lib.flashFrames[frame].fallbackAlpha)
					end
					tremove(lib.flashTimers, flashIndex) -- *note: only the pointer to the table is removed, not the table itself
					lib.numFlashes = lib.numFlashes - 1
					wipe(lib.flashFrames[frame]) -- this is the same table, and we wipe it instead of deleting it, to avoid insane memory overheads
				end
				
			end
		end
		flashIndex = flashIndex - 1
	end
	
	if lib.numFades == 0 and lib.numFlashes == 0 then
		self:Hide()
	end	
end)

function lib.frame:SetFallbackAlpha(alphaIn, alphaOut)
	if not lib.flashFrames[self] then
		lib.flashFrames[self] = {}
	end
	lib.flashFrames[self].fallbackAlpha = alphaIn
	if alphaOut then
		lib.flashFrames[self].fallbackAlpha = alphaIn
	end
end

-- this should be hooked to the frame's OnShow handler, and done with our OnUpdate handler
function lib.frame:StartFadeIn(durationIn, targetAlphaIn)
	if self:IsShown() and self:GetAlpha() == (targetAlphaIn or 1) then return end
	if not lib.fadeFrames[self] then
		lib.fadeFrames[self] = {}
	end
	if lib.fadeFrames[self].fadeOutAnimation and lib.fadeFrames[self].fadeOutAnimation:IsPlaying() then
		lib.fadeFrames[self].fadeOutAnimation:Stop()
	end
	lib.fadeFrames[self].durationIn = durationIn or .75
	lib.fadeFrames[self].targetAlphaIn = targetAlphaIn or 1
	lib.frame:Show()
	-- if not fadeFrames[self].isFading then
		if not lib.fadeFrames[self].isFading then
			lib.numFades = lib.numFades + 1
			lib.fadeFrames[self].isFading = true
			-- lib.fadeFrames[self].isFading = self:GetAlpha() ~= lib.fadeFrames[self].targetAlphaIn
			tinsert(lib.fadeTimers, self)
		end
	-- end
end

-- this should be an animation to remain secure when hiding (?)
function lib.frame:StartFadeOut()
	if not(lib.fadeFrames[self].fadeOutAnimation) then return end
	lib.fadeFrames[self].isFading = false
	if lib.fadeFrames[self].fadeOutAnimation:IsPlaying() then
		return
	end
	lib.fadeFrames[self].fadeOutAnimation:Play()
end

-- this should be called initially and out of combat
function lib.frame:SetFadeOut(durationOut)
	-- if not self:IsShown() then return end
	if not lib.fadeFrames[self] then
		lib.fadeFrames[self] = {}
	end
	lib.fadeFrames[self].durationOut = durationOut or .75
	-- lib.fadeFrames[self].isFading = self:GetAlpha() ~= 0
	
	-- create animation if it doesn't exist
	if not lib.fadeFrames[self].fadeOutAnimation then
		lib.fadeFrames[self].fadeOutAnimation = self:CreateAnimationGroup()
		lib.fadeFrames[self].fadeOutAnimation:SetLooping("NONE")
		lib.fadeFrames[self].fadeOutAnimation:SetScript("OnStop", function(self) end) 
		lib.fadeFrames[self].fadeOutAnimation:SetScript("OnFinished", function(self) 
			if self.override then
				lib.frame.Hide(self.frame)
			else
				self.frame:Hide() 
			end
		end)
		lib.fadeFrames[self].fadeOutAnimation.frame = self
		lib.fadeFrames[self].fadeOutAnimation.alpha = lib.fadeFrames[self].fadeOutAnimation:CreateAnimation("Alpha")
		lib.fadeFrames[self].fadeOutAnimation.alpha:SetSmoothing("OUT")
		self:HookScript("OnHide", function(self) 
			-- if the frame is hidden while the animation is playing, 
			-- it is either because of combat or because its parent was hidden. 
			-- in both cases we need to fully hide the frame, to avoid it popping back in 
			-- for a short period when its parent is shown again.
			if lib.fadeFrames[self].fadeOutAnimation:IsPlaying() then
				lib.fadeFrames[self].fadeOutAnimation:Stop()
				self:SetAlpha(0) 
				if self:IsShown() then
					if lib.fadeFrames[self].fadeOutAnimation.override then
						lib.frame.Hide(self)
					else
						self:Hide() -- safe or taint?
					end
				end
			end
		end)
	end
	
	if lib.fadeFrames[self].fadeOutAnimation:IsPlaying() then
		lib.fadeFrames[self].fadeOutAnimation:Stop()
	end
	
	if lib.fadeFrames[self].fadeOutAnimation.alpha.SetChange then
		lib.fadeFrames[self].fadeOutAnimation.alpha:SetChange(-1)
	elseif lib.fadeFrames[self].fadeOutAnimation.alpha.SetToAlpha then
		lib.fadeFrames[self].fadeOutAnimation.alpha:SetToAlpha(0)
	end
	lib.fadeFrames[self].fadeOutAnimation.alpha:SetDuration(lib.fadeFrames[self].durationOut)
	
end

-- this should be done with our OnUpdate handler
function lib.frame:StartFlash(durationOut, durationIn, minAlpha, maxAlpha, killOnHide)
	if not lib.flashFrames[self] then
		lib.flashFrames[self] = {}
	end
	lib.flashFrames[self].durationIn = durationIn or .75
	lib.flashFrames[self].durationOut = durationOut or .75
	lib.flashFrames[self].minAlpha = minAlpha or .5
	lib.flashFrames[self].maxAlpha = maxAlpha or 1
	lib.flashFrames[self].killOnHide = killOnHide 
	if not lib.flashFrames[self].isFlashing then
		lib.numFlashes = lib.numFlashes + 1
		tinsert(lib.flashTimers, self)
		lib.flashFrames[self].direction = "OUT" -- only set this the first time, or it'll look crazy as the direction keeps changing!
	end
	lib.flashFrames[self].isFlashing = true
	lib.flashFrames[self].isFlashingPaused = false
	lib.frame:Show()
end

function lib.frame:StopFlash()
	if not lib.flashFrames[self] then return end
	lib.flashFrames[self].scheduleForRemoval = true
end

function lib.frame:PauseFlash()
	if not lib.flashFrames[self] then return end
	lib.flashFrames[self].isFlashingPaused = true
end

function lib.frame:StopAllFades()
	if not lib.fadeFrames[self] then return end
	lib.fadeFrames[self].isFading = false
end

-- the following two will make the frame insecure. so don't use it on secure frames. 
lib.justHidden = lib.justHidden or {}
function lib.frame:OverrideShowWithFadeIn(durationIn, targetAlphaIn)
	self:HookScript("OnHide", function() 
		lib.justHidden[self] = true
	end)
	function self:Show()
		if not self:IsShown() then
			self:SetAlpha(0)
			lib.frame.Show(self)
		end
		if lib.justHidden[self] then -- prevent concurrent :Show() calls from restarting the fade and mess up any flashing
			self:StartFadeIn(durationIn, targetAlphaIn)
			lib.justHidden[self] = nil
		end
	end
end
function lib.frame:OverrideHideWithFadeOut(durationOut)
	self:SetFadeOut(durationOut)
	lib.fadeFrames[self].fadeOutAnimation.override = true
	function self:Hide()
		if not lib.fadeFrames[self].fadeOutAnimation:IsPlaying() then
			lib.fadeFrames[self].fadeOutAnimation:Play()
		end
	end
	self.RawHide = lib.frame.Hide
end

local methods = {
	OverrideHideWithFadeOut = true,
	OverrideShowWithFadeIn = true,
	PauseFlash = true,
	SetFadeOut = true, 
	SetFallbackAlpha = true,
	StartFadeIn = true,
	StartFadeOut = true,
	StartFlash = true,
	StopFlash = true,
	StopAllFades = true
}

function lib:ApplyFadersToFrame(frame)
	if lib.mixed[frame] then return end
	for method in pairs(methods) do
		frame[method] = lib.frame[method]
	end
	lib.mixed[frame] = true
end

--------------------------------------------------------------------------------------------------
--		Shine 
--------------------------------------------------------------------------------------------------
local MAXALPHA = .5
local SCALE = 5
local DURATION = .75
local TEXTURE = [[Interface\Cooldown\star4]]

local function New(frameType, parentClass)
	local class = CreateFrame(frameType)
	class.mt = { __index = class }
	if parentClass then
		class = setmetatable(class, { __index = parentClass })
		class.super = function(self, method, ...) parentClass[method](self, ...) end
	end
	class.Bind = function(self, obj) return setmetatable(obj, self.mt) end
	return class
end

local Shine = New("Frame")

function Shine:New(parent, maxAlpha, duration, scale)
	local f = self:Bind(CreateFrame("Frame", nil, parent)) 
  f:Hide() 
  f:SetScript("OnHide", Shine.OnHide) 
  f:SetAllPoints(parent) 
  f:SetToplevel(true) 

  local t = f:CreateTexture(nil, "OVERLAY")
  t:SetPoint("CENTER")
  t:SetBlendMode("ADD") 
  t:SetAllPoints(f) 
  t:SetTexture(TEXTURE)

	f.animation = f:CreateShineAnimation(maxAlpha, duration, scale)
	f.lastPlayed = 0
	f.throttle = 500 
	return f
end

local function shine_finished(self)
	local parent = self:GetParent()
	if parent:IsShown() then
		parent:Hide()
	end
end

function Shine:CreateShineAnimation(maxAlpha, duration, scale)
	local MAXALPHA = maxAlpha or MAXALPHA
	local SCALE = scale or SCALE
	local DURATION = duration or DURATION
	local g = self:CreateAnimationGroup() 
  g:SetLooping("NONE") 
  g:SetScript("OnFinished", shine_finished) 

  local a1 = g:CreateAnimation("Alpha")
	if a1.SetChange then
		a1:SetChange(-1)
	elseif a1.SetToAlpha then
		a1:SetToAlpha(0)
	end
  a1:SetDuration(0) 
  a1:SetOrder(0) 

	local a2 = g:CreateAnimation("Scale") 
  a2:SetOrigin("CENTER", 0, 0) 
  a2:SetScale(SCALE, SCALE) 
  a2:SetDuration(DURATION/2) 
  a2:SetOrder(1) 

	local a3 = g:CreateAnimation("Alpha") 
	if a3.SetChange then
		a3:SetChange(MAXALPHA)
	elseif a3.SetToAlpha then
		a3:SetToAlpha(MAXALPHA)
	end
  a3:SetDuration(DURATION/2) 
  a3:SetOrder(1)

  local a4 = g:CreateAnimation("Scale") 
  a4:SetOrigin("CENTER", 0, 0) 
  a4:SetScale(-SCALE, -SCALE) 
  a4:SetDuration(DURATION/2) 
  a4:SetOrder(2)

	local a5 = g:CreateAnimation("Alpha") 
	if a5.SetChange then
		a5:SetChange(-MAXALPHA)
	elseif a5.SetToAlpha then
		a5:SetToAlpha(0)
	end
  a5:SetDuration(DURATION/2) 
  a5:SetOrder(2)
  
	return g
end

function Shine:OnHide()
	if self.animation:IsPlaying() then
		self.animation:Finish()
	end
	self:Hide()
end

function Shine:SetThrottle(ms)
	self.throttle = ms
end

function Shine:Start()
	if (GetTime() - self.lastPlayed) < self.throttle then
		if self.animation:IsPlaying() then
      self.animation:Finish()
		end
		self:Show()
		self.animation:Play()
	end
	self.lastPlayed = GetTime()
end

-- usage:
-- 	local shine = gUI4:ApplyShine(frame, maxAlpha, duration, scale)
-- 	shine:Start() -- start
--	shine:Hide() -- finish
function lib:ApplyShine(frame, maxAlpha, duration, scale)
	return Shine:New(frame, maxAlpha, duration, scale)
end

------------------------------------------------------------------------
--	Embedding
------------------------------------------------------------------------
local mixins = {
  "ApplyShine", "ApplyFadersToFrame"
 }

function lib:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

