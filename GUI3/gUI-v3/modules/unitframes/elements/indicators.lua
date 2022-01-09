--[[
	Copyright (c) 2013, Lars "Goldpaw" Norberg
	
	Web: http://www.friendlydruid.com
	Contact: goldpaw@friendlydruid.com
	
	All rights reserved
]]--
local addon,ns = ...
local oUF = ns.oUF or oUF 

local gUI = LibStub("gCore-4.0"):GetAddon(addon)
if not(gUI) then return end

local L = LibStub("gLocale-2.0"):GetLocale(addon)
local C = gUI:GetDataBase("colors", true)
local F = gUI:GetDataBase("functions", true)
local M = function(folder, file) return gUI:GetMedia(folder, file) end 
local unitframes = gUI:GetModule("Unitframes")
local R = unitframes:GetDataBase("auras")
local RaidGroups = unitframes:GetDataBase("raidgroups")
local UnitFrames = unitframes:GetDataBase("unitframes")

local _, class = UnitClass("player")

------------------------------------------------------------------------
--	Grid Indicators 
------------------------------------------------------------------------
--[[
 Simple rules:
	TOPLEFT = instant cast HoTs, shields, shield cooldowns, defensive stuff
	TOPRIGHT = Buffs, missing long term buffs, active short term buffs
	BOTTOMLEFT = Most additional HoTs
	BOTTOMRIGHT = stuff with charges/stacks
	CENTER = timers for riptide, renew, rejuv etc
]]--

-- all new MoP buffs here
R.AurasByClass = {
	-- healer classes
	 DRUID = {
		  TOPLEFT = "[gUI™ cenarionward][gUI™ rejuv]";
		  TOPRIGHT = "[gUI™ stats][gUI™ spellhaste][gUI™ crit]";
		  BOTTOMLEFT = "[gUI™ regrowth][gUI™ wildgrowth]";
		  BOTTOMRIGHT = "[gUI™ lifebloom]";
		  CENTER = "[gUI™ rejuvTime]";
	 };
	 MONK = {
		  TOPLEFT = "[gUI™ renewingmist]";
		  TOPRIGHT = "[gUI™ stats][gUI™ crit]";
		  BOTTOMLEFT = "[gUI™ soothingmist][gUI™ envelopingmist]";
		  BOTTOMRIGHT = "[gUI™ lifecocoon][gUI™ zensphere]";
		  CENTER = "[gUI™ renewingmistTime]";
	 };
	 PALADIN = {
		  TOPLEFT = "[gUI™ forbearance]";
		  TOPRIGHT = "[gUI™ mastery][gUI™ stats]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "[gUI™ beacon]"; 
		  CENTER = "";
	 };
	 PRIEST = {
		  TOPLEFT = "[gUI™ pws][gUI™ weakenedsoul]";
		  TOPRIGHT = "[gUI™ stamina][gUI™ spellhaste]";
		  BOTTOMLEFT = "[gUI™ renew][gUI™ pwb]";
		  BOTTOMRIGHT = "[gUI™ mending]";
		  CENTER = "[gUI™ renewTime]";
	 };
	 SHAMAN = {
		  TOPLEFT = "[gUI™ riptide]";
		  TOPRIGHT = "[gUI™ mastery][gUI™ spellpower][gUI™ haste][gUI™ spellhaste]"; 
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "[gUI™ earthshield]";
		  CENTER = "[gUI™ riptideTime]";
	 };
	
	-- other buffers
	 DEATHKNIGHT = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI™ attackpower][gUI™ haste]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
	 HUNTER = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI™ stats][gUI™ stamina][gUI™ attackpower][gUI™ spellpower][gUI™ haste][gUI™ spellhaste][gUI™ crit][gUI™ mastery]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
	 MAGE = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI™ spellpower][gUI™ crit]"; 
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
	 WARLOCK = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI™ spellpower][gUI™ stamina]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "[gUI™ soulstone]";
		  CENTER = "";
	 };
	 WARRIOR = {
		  TOPLEFT = "[gUI™ vigilance]";
		  TOPRIGHT = "[gUI™ attackpower][gUI™ stamina]"; 
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
	 ROGUE = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI™ haste]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
}

local Enable = function(self)
	if (self.GUISIndicators) then
		local frame = self.GUISIndicators
		local font = frame.fontObject:GetFont()

		-- topright is usually buffs, interesting to all
		frame.TOPRIGHT = frame:CreateFontString(nil, "OVERLAY")
		frame.TOPRIGHT:ClearAllPoints()
		frame.TOPRIGHT:SetPoint("TOPRIGHT", frame, 1, -1)
		frame.TOPRIGHT:SetFont(font, frame.indicatorSize, "THINOUTLINE")
		frame.TOPRIGHT:SetJustifyH("RIGHT")
		
		self:Tag(frame.TOPRIGHT, R.AurasByClass[class]["TOPRIGHT"])
		
		-- stuff not visible in the tiny DPS layout
		if not(frame.onlyBuffs) then
			frame.TOPLEFT = frame:CreateFontString(nil, "OVERLAY")
			frame.TOPLEFT:ClearAllPoints()
			frame.TOPLEFT:SetPoint("TOPLEFT", frame, 1, -1)
			frame.TOPLEFT:SetFont(font, frame.indicatorSize, "THINOUTLINE")
			self:Tag(frame.TOPLEFT, R.AurasByClass[class]["TOPLEFT"])

			frame.BOTTOMLEFT = frame:CreateFontString(nil, "OVERLAY")
			frame.BOTTOMLEFT:ClearAllPoints()
			frame.BOTTOMLEFT:SetPoint("BOTTOMLEFT", frame, 1, 1)
			frame.BOTTOMLEFT:SetFont(font, frame.indicatorSize, "THINOUTLINE")
			self:Tag(frame.BOTTOMLEFT, R.AurasByClass[class]["BOTTOMLEFT"])

			frame.BOTTOMRIGHT = frame:CreateFontString(nil, "OVERLAY")
			frame.BOTTOMRIGHT:ClearAllPoints()
			frame.BOTTOMRIGHT:SetPoint("BOTTOMRIGHT", frame, 0, 1)
			frame.BOTTOMRIGHT:SetFont(font, frame.symbolSize, "THINOUTLINE")
			frame.BOTTOMRIGHT:SetJustifyH("RIGHT")
			self:Tag(frame.BOTTOMRIGHT, R.AurasByClass[class]["BOTTOMRIGHT"])

			frame.CENTER = frame:CreateFontString(nil, "OVERLAY")
			frame.CENTER:SetPoint("CENTER", frame, "TOP", 0, 0)
			frame.CENTER:SetWidth(frame.width)
			frame.CENTER:SetFontObject(frame.fontObject)
			frame.CENTER:SetJustifyH("CENTER")
			frame.CENTER:SetJustifyV("MIDDLE")
			frame.CENTER.frequentUpdates = frame.frequentUpdates
			self:Tag(frame.CENTER, R.AurasByClass[class]["CENTER"])
		end
	end
end
oUF:AddElement("GUISIndicators", nil, Enable, nil)
