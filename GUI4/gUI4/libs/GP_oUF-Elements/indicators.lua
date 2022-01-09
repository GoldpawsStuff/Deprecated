local addon,ns = ...

local oUF = ns.oUF
if not oUF then return end

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
local auras = {
	-- healer classes
	 DRUID = {
		  TOPLEFT = "[gUI4: cenarionward][gUI4: rejuv]";
		  TOPRIGHT = "[gUI4: stats][gUI4: spellhaste][gUI4: crit]";
		  BOTTOMLEFT = "[gUI4: regrowth][gUI4: wildgrowth]";
		  BOTTOMRIGHT = "[gUI4: lifebloom]";
		  CENTER = "[gUI4: rejuvTime]";
	 };
	 MONK = {
		  TOPLEFT = "[gUI4: renewingmist]";
		  TOPRIGHT = "[gUI4: stats][gUI4: crit]";
		  BOTTOMLEFT = "[gUI4: soothingmist][gUI4: envelopingmist]";
		  BOTTOMRIGHT = "[gUI4: lifecocoon][gUI4: zensphere]";
		  CENTER = "[gUI4: renewingmistTime]";
	 };
	 PALADIN = {
		  TOPLEFT = "[gUI4: forbearance]";
		  TOPRIGHT = "[gUI4: mastery][gUI4: stats]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "[gUI4: beacon]"; 
		  CENTER = "";
	 };
	 PRIEST = {
		  TOPLEFT = "[gUI4: pws][gUI4: weakenedsoul]";
		  TOPRIGHT = "[gUI4: stamina][gUI4: spellhaste]";
		  BOTTOMLEFT = "[gUI4: renew][gUI4: pwb]";
		  BOTTOMRIGHT = "[gUI4: mending]";
		  CENTER = "[gUI4: renewTime]";
	 };
	 SHAMAN = {
		  TOPLEFT = "[gUI4: riptide]";
		  TOPRIGHT = "[gUI4: mastery][gUI4: spellpower][gUI4: haste][gUI4: spellhaste]"; 
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "[gUI4: earthshield]";
		  CENTER = "[gUI4: riptideTime]";
	 };
	
	-- other buffers
	 DEATHKNIGHT = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI4: attackpower][gUI4: haste]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
	 HUNTER = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI4: stats][gUI4: stamina][gUI4: attackpower][gUI4: spellpower][gUI4: haste][gUI4: spellhaste][gUI4: crit][gUI4: mastery]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
	 MAGE = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI4: spellpower][gUI4: crit]"; 
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
	 WARLOCK = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI4: spellpower][gUI4: stamina]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "[gUI4: soulstone]";
		  CENTER = "";
	 };
	 WARRIOR = {
		  TOPLEFT = "[gUI4: vigilance]";
		  TOPRIGHT = "[gUI4: attackpower][gUI4: stamina]"; 
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
	 ROGUE = {
		  TOPLEFT = "";
		  TOPRIGHT = "[gUI4: haste]";
		  BOTTOMLEFT = "";
		  BOTTOMRIGHT = "";
		  CENTER = "";
	 };
}

local Enable = function(self)
	if (self.Doticators) then
		local frame = self.Doticators
		local font = frame.fontObject:GetFont()

		-- topright is usually buffs, interesting to all
		frame.TOPRIGHT = frame:CreateFontString(nil, "OVERLAY")
		frame.TOPRIGHT:ClearAllPoints()
		frame.TOPRIGHT:SetPoint("TOPRIGHT", frame, 1, -1)
		frame.TOPRIGHT:SetFont(font, frame.indicatorSize, "THINOUTLINE")
		frame.TOPRIGHT:SetJustifyH("RIGHT")
		
		self:Tag(frame.TOPRIGHT, auras[class]["TOPRIGHT"])
		
		-- stuff not visible in the tiny DPS layout
		if not(frame.onlyBuffs) then
			frame.TOPLEFT = frame:CreateFontString(nil, "OVERLAY")
			frame.TOPLEFT:ClearAllPoints()
			frame.TOPLEFT:SetPoint("TOPLEFT", frame, 1, -1)
			frame.TOPLEFT:SetFont(font, frame.indicatorSize, "THINOUTLINE")
			self:Tag(frame.TOPLEFT, auras[class]["TOPLEFT"])

			frame.BOTTOMLEFT = frame:CreateFontString(nil, "OVERLAY")
			frame.BOTTOMLEFT:ClearAllPoints()
			frame.BOTTOMLEFT:SetPoint("BOTTOMLEFT", frame, 1, 1)
			frame.BOTTOMLEFT:SetFont(font, frame.indicatorSize, "THINOUTLINE")
			self:Tag(frame.BOTTOMLEFT, auras[class]["BOTTOMLEFT"])

			frame.BOTTOMRIGHT = frame:CreateFontString(nil, "OVERLAY")
			frame.BOTTOMRIGHT:ClearAllPoints()
			frame.BOTTOMRIGHT:SetPoint("BOTTOMRIGHT", frame, 0, 1)
			frame.BOTTOMRIGHT:SetFont(font, frame.symbolSize, "THINOUTLINE")
			frame.BOTTOMRIGHT:SetJustifyH("RIGHT")
			self:Tag(frame.BOTTOMRIGHT, auras[class]["BOTTOMRIGHT"])

			frame.CENTER = frame:CreateFontString(nil, "OVERLAY")
			frame.CENTER:SetPoint("CENTER", frame, "TOP", 0, 0)
			frame.CENTER:SetWidth(frame.width)
			frame.CENTER:SetFontObject(frame.fontObject)
			frame.CENTER:SetJustifyH("CENTER")
			frame.CENTER:SetJustifyV("MIDDLE")
			frame.CENTER.frequentUpdates = frame.frequentUpdates
			self:Tag(frame.CENTER, auras[class]["CENTER"])
		end
	end
end
oUF:AddElement("Doticators", nil, Enable, nil)
