local addon,ns = ...

local gUI4 = GP_LibStub("GP_AceAddon-3.0"):GetAddon("gUI4", true)
if not gUI4 then return end

local parent = gUI4:GetModule("gUI4_Chat", true)
if not parent then return end

-- emoticon sources: 
-- 	http://en.wikipedia.org/wiki/List_of_emoticons
-- 	http://pc.net/emoticons/
local M = gUI4:GetMediaLibrary("Emoticon")
local emoticons = {
	-- western
	[":-||"] = M:GetMedia("angry"):GetPath(),
	[":@"] = M:GetMedia("angry"):GetPath(),
	[">:("] = M:GetMedia("angry"):GetPath(),
	["o~"] = M:GetMedia("balloon"):GetPath(),
	[":-D"] = M:GetMedia("big_grin"):GetPath(),
	[":D"] = M:GetMedia("big_grin"):GetPath(),
	["8-D"] = M:GetMedia("big_grin"):GetPath(),
	["8D"] = M:GetMedia("big_grin"):GetPath(),
	["x-D"] = M:GetMedia("big_grin"):GetPath(),
	["xD"] = M:GetMedia("big_grin"):GetPath(),
	["X-D"] = M:GetMedia("big_grin"):GetPath(),
	["XD"] = M:GetMedia("big_grin"):GetPath(),
	["=-D"] = M:GetMedia("big_grin"):GetPath(),
	["=D"] = M:GetMedia("big_grin"):GetPath(),
	["=-3"] = M:GetMedia("big_grin"):GetPath(),
	["=3"] = M:GetMedia("big_grin"):GetPath(),
	["B^D"] = M:GetMedia("big_grin"):GetPath(),
	["B^D"] = M:GetMedia("big_grin"):GetPath(),
	[":-))"] = M:GetMedia("bomb"):GetPath(),
	["</3"] = M:GetMedia("broken_heart"):GetPath(),
	["(^)"] = M:GetMedia("cake"):GetPath(),
	[ [[>:\]] ] = M:GetMedia("confused"):GetPath(),
	["o.O"] = M:GetMedia("confused"):GetPath(),
	["O.o"] = M:GetMedia("confused"):GetPath(),
	[">:/"] = M:GetMedia("confused"):GetPath(),
	[":-/"] = M:GetMedia("confused"):GetPath(),
	[":-."] = M:GetMedia("confused"):GetPath(),
	[":/"] = M:GetMedia("confused"):GetPath(),
	[ [[:\]] ] = M:GetMedia("confused"):GetPath(),
	["=/"] = M:GetMedia("confused"):GetPath(),
	[ [[=\]] ] = M:GetMedia("confused"):GetPath(),
	[":L"] = M:GetMedia("confused"):GetPath(),
	["=L"] = M:GetMedia("confused"):GetPath(),
	[":S"] = M:GetMedia("confused"):GetPath(),
	[">.<"] = M:GetMedia("confused"):GetPath(),
	["(y)"] = M:GetMedia("cool"):GetPath(),
	["(Y)"] = M:GetMedia("cool"):GetPath(),
	[":'-("] = M:GetMedia("crying2"):GetPath(),
	[":'("] = M:GetMedia("crying2"):GetPath(),
	[">:)"] = M:GetMedia("devil"):GetPath(),
	[">;)"] = M:GetMedia("devil"):GetPath(),
	[">:-)"] = M:GetMedia("devil"):GetPath(),
	["}:-)"] = M:GetMedia("devil"):GetPath(),
	["}:)"] = M:GetMedia("devil"):GetPath(),
	["3:-)"] = M:GetMedia("devil"):GetPath(),
	["3:)"] = M:GetMedia("devil"):GetPath(),
	["(6)"] = M:GetMedia("devil"):GetPath(),
	["*DRINK*"] = M:GetMedia("drinks"):GetPath(),
	["*drink*"] = M:GetMedia("drinks"):GetPath(),
	["@~)~~~~"] = M:GetMedia("flower"):GetPath(),
	["@-->---"] = M:GetMedia("flower"):GetPath(),
	["--{--@"] = M:GetMedia("flower"):GetPath(),
	["@>--"] = M:GetMedia("flower"):GetPath(),
	["@}->--"] = M:GetMedia("flower"):GetPath(),
	["@};-"] = M:GetMedia("flower"):GetPath(),
	["@>-;--"] = M:GetMedia("flower"):GetPath(),
	["@}-^--^--"] = M:GetMedia("flower"):GetPath(),
	["@)->-"] = M:GetMedia("flower"):GetPath(),
	["@~'~~~"] = M:GetMedia("flower"):GetPath(),
	["(@)->->->--"] = M:GetMedia("flower"):GetPath(),
	["@}-("] = M:GetMedia("flower"):GetPath(),
	["<3"] = M:GetMedia("heart"):GetPath(),
	["{}"] = M:GetMedia("hug"):GetPath(),
	[":*"] = M:GetMedia("kiss"):GetPath(),
	[":^*"] = M:GetMedia("kiss"):GetPath(),
	["( '}{' )"] = M:GetMedia("kiss"):GetPath(),
	[":'-)"] = M:GetMedia("laughing"):GetPath(),
	[":')"] = M:GetMedia("laughing"):GetPath(),
	["(i)"] = M:GetMedia("ligthbulb"):GetPath(),
	["(I)"] = M:GetMedia("ligthbulb"):GetPath(),
	["8-)"] = M:GetMedia("nerd"):GetPath(),
	["(t)"] = M:GetMedia("on_the_phone"):GetPath(),
	["(T)"] = M:GetMedia("on_the_phone"):GetPath(),
	["<:-P"] = M:GetMedia("party"):GetPath(),
	["<:o)"] = M:GetMedia("party"):GetPath(),
	["<:O)"] = M:GetMedia("party"):GetPath(),
	["*<(:)"] = M:GetMedia("party"):GetPath(),
	["*<(8)~/~<"] = M:GetMedia("party"):GetPath(),
	["*<|8-P~"] = M:GetMedia("party"):GetPath(),
	["(r)"] = M:GetMedia("rainbow"):GetPath(),
	["(R)"] = M:GetMedia("rainbow"):GetPath(),
	["O:-)"] = M:GetMedia("sacred"):GetPath(),
	["0:-3"] = M:GetMedia("sacred"):GetPath(),
	["0:3"] = M:GetMedia("sacred"):GetPath(),
	["0:-)"] = M:GetMedia("sacred"):GetPath(),
	["0:)"] = M:GetMedia("sacred"):GetPath(),
	["0;^)"] = M:GetMedia("sacred"):GetPath(),
	[")-:"] = M:GetMedia("sad"):GetPath(),
	["):"] = M:GetMedia("sad"):GetPath(),
	[">:["] = M:GetMedia("sad"):GetPath(),
	[":-("] = M:GetMedia("sad"):GetPath(),
	[":("] = M:GetMedia("sad"):GetPath(),
	[":-c"] = M:GetMedia("sad"):GetPath(),
	[":c"] = M:GetMedia("sad"):GetPath(),
	[":-<"] = M:GetMedia("sad"):GetPath(),
	[":っC"] = M:GetMedia("sad"):GetPath(),
	[":<"] = M:GetMedia("sad"):GetPath(),
	[":-["] = M:GetMedia("sad"):GetPath(),
	[":["] = M:GetMedia("sad"):GetPath(),
	[":{"] = M:GetMedia("sad"):GetPath(),
	[">:O"] = M:GetMedia("scared"):GetPath(),
	[">:o"] = M:GetMedia("scared"):GetPath(),
	[":-O"] = M:GetMedia("scared"):GetPath(),
	[":-o"] = M:GetMedia("scared"):GetPath(),
	[":O"] = M:GetMedia("scared"):GetPath(),
	[":o"] = M:GetMedia("scared"):GetPath(),
	["{:o"] = M:GetMedia("scared"):GetPath(),
	["{:O"] = M:GetMedia("scared"):GetPath(),
	["(:)o)"] = M:GetMedia("scared"):GetPath(),
	["(:)O)"] = M:GetMedia("scared"):GetPath(),
	[":-()"] = M:GetMedia("scared"):GetPath(),
	["=0"] = M:GetMedia("scared"):GetPath(),
	["=o"] = M:GetMedia("scared"):GetPath(),
	["(*.*)"] = M:GetMedia("scared"):GetPath(),
	["8-0"] = M:GetMedia("scared"):GetPath(),
	["8-o"] = M:GetMedia("scared"):GetPath(),
	["<:-|"] = M:GetMedia("sick2"):GetPath(),
	["zzz"] = M:GetMedia("sleeping"):GetPath(),
	["zZz"] = M:GetMedia("sleeping"):GetPath(),
	["ZZZ"] = M:GetMedia("sleeping"):GetPath(),
	["zZzZz"] = M:GetMedia("sleeping"):GetPath(),
	["*yawn*"] = M:GetMedia("sleepy"):GetPath(),
	["*YAWN*"] = M:GetMedia("sleepy"):GetPath(),
	["(-:"] = M:GetMedia("smile"):GetPath(),
	["(:"] = M:GetMedia("smile"):GetPath(),
	[":-)"] = M:GetMedia("smile"):GetPath(),
	[":)"] = M:GetMedia("smile"):GetPath(),
	[":o)"] = M:GetMedia("smile"):GetPath(),
	[":]"] = M:GetMedia("smile"):GetPath(),
	[":3"] = M:GetMedia("smile"):GetPath(),
	[":c)"] = M:GetMedia("smile"):GetPath(),
	[":>"] = M:GetMedia("smile"):GetPath(),
	["=]"] = M:GetMedia("smile"):GetPath(),
	["8)"] = M:GetMedia("smile"):GetPath(),
	["=)"] = M:GetMedia("smile"):GetPath(),
	[":}"] = M:GetMedia("smile"):GetPath(),
	[":^)"] = M:GetMedia("smile"):GetPath(),
	[":っ)"] = M:GetMedia("smile"):GetPath(),
	["B)"] = M:GetMedia("smug"):GetPath(),
	["B-)"] = M:GetMedia("smug"):GetPath(),
	["(*)"] = M:GetMedia("stars"):GetPath(),
	[":|"] = M:GetMedia("straight_face"):GetPath(),
	[":-|"] = M:GetMedia("straight_face"):GetPath(),
	["(#)"] = M:GetMedia("sun"):GetPath(),
	["((o))"] = M:GetMedia("sun"):GetPath(),
	[">:P"] = M:GetMedia("tongue"):GetPath(),
	[":-P"] = M:GetMedia("tongue"):GetPath(),
	[":P"] = M:GetMedia("tongue"):GetPath(),
	-- ["X-P"] = M:GetMedia("tongue"):GetPath(),
	-- ["x-p"] = M:GetMedia("tongue"):GetPath(),
	-- ["xp"] = M:GetMedia("tongue"):GetPath(),
	-- ["XP"] = M:GetMedia("tongue"):GetPath(),
	[":-p"] = M:GetMedia("tongue"):GetPath(),
	[":p"] = M:GetMedia("tongue"):GetPath(),
	["=p"] = M:GetMedia("tongue"):GetPath(),
	[":-Þ"] = M:GetMedia("tongue"):GetPath(),
	[":Þ"] = M:GetMedia("tongue"):GetPath(),
	[":þ"] = M:GetMedia("tongue"):GetPath(),
	[":-þ"] = M:GetMedia("tongue"):GetPath(),
	[":-b"] = M:GetMedia("tongue"):GetPath(),
	[":b"] = M:GetMedia("tongue"):GetPath(),
	[":-###.."] = M:GetMedia("vomit"):GetPath(),
	[":###.."] = M:GetMedia("vomit"):GetPath(),
	[":&"] = M:GetMedia("vomit"):GetPath(),
	[";-)"] = M:GetMedia("winking"):GetPath(),
	[";)"] = M:GetMedia("winking"):GetPath(),
	["*-)"] = M:GetMedia("winking"):GetPath(),
	["*)"] = M:GetMedia("winking"):GetPath(),
	[";-]"] = M:GetMedia("winking"):GetPath(),
	[";]"] = M:GetMedia("winking"):GetPath(),
	[";D"] = M:GetMedia("winking"):GetPath(),
	[";^)"] = M:GetMedia("winking"):GetPath(),
	[":-,"] = M:GetMedia("winking"):GetPath(),
	["|-O"] = M:GetMedia("yawn"):GetPath(),
	["|-o"] = M:GetMedia("yawn"):GetPath(),
	["(:|"] = M:GetMedia("yawn2"):GetPath(),
	-- eastern
	["(>_<)>"] = M:GetMedia("angry"):GetPath(),
	["(>_<)"] = M:GetMedia("angry"):GetPath(),
	["(゜o゜)"] = M:GetMedia("big_grin"):GetPath(),
	["(^_^)/"] = M:GetMedia("big_grin"):GetPath(),
	["(^O^)／"] = M:GetMedia("big_grin"):GetPath(),
	["(^o^)／"] = M:GetMedia("big_grin"):GetPath(),
	["(^^)/"] = M:GetMedia("big_grin"):GetPath(),
	["(≧∇≦)/"] = M:GetMedia("big_grin"):GetPath(),
	["(^o^)丿"] = M:GetMedia("big_grin"):GetPath(),
	["∩( ・ω・)∩"] = M:GetMedia("big_grin"):GetPath(),
	["( ・ω・)"] = M:GetMedia("big_grin"):GetPath(),
	["＼(~o~)／"] = M:GetMedia("big_grin"):GetPath(),
	["＼(^o^)／"] = M:GetMedia("big_grin"):GetPath(),
	["＼(-o-)／"] = M:GetMedia("big_grin"):GetPath(),
	["ヽ(^。^)ノ"] = M:GetMedia("big_grin"):GetPath(),
	["ヽ(^o^)丿"] = M:GetMedia("big_grin"):GetPath(),
	["(*^0^*)"] = M:GetMedia("big_grin"):GetPath(),
	["^ω^"] = M:GetMedia("big_grin"):GetPath(),
	["(・・?"] = M:GetMedia("confused"):GetPath(),
	["(?_?)"] = M:GetMedia("confused"):GetPath(),
	["((+_+))"] = M:GetMedia("confused"):GetPath(),
	["(+o+)"] = M:GetMedia("confused"):GetPath(),
	["(゜゜)"] = M:GetMedia("confused"):GetPath(),
	["(゜-゜)"] = M:GetMedia("confused"):GetPath(),
	["(゜.゜)"] = M:GetMedia("confused"):GetPath(),
	["(゜_゜)"] = M:GetMedia("confused"):GetPath(),
	["(゜_゜>)"] = M:GetMedia("confused"):GetPath(),
	["(゜レ゜)"] = M:GetMedia("confused"):GetPath(),
	["('_')"] = M:GetMedia("crying2"):GetPath(),
	["(/_;)"] = M:GetMedia("crying2"):GetPath(),
	["(T_T)"] = M:GetMedia("crying2"):GetPath(),
	["(;_;)"] = M:GetMedia("crying2"):GetPath(),
	["(;_;"] = M:GetMedia("crying2"):GetPath(),
	["(;_:)"] = M:GetMedia("crying2"):GetPath(),
	["(;O;)"] = M:GetMedia("crying2"):GetPath(),
	["(:_;)"] = M:GetMedia("crying2"):GetPath(),
	["(ToT)"] = M:GetMedia("crying2"):GetPath(),
	["(Ｔ▽Ｔ)"] = M:GetMedia("crying2"):GetPath(),
	[";_;"] = M:GetMedia("crying2"):GetPath(),
	[";-;"] = M:GetMedia("crying2"):GetPath(),
	[";n;"] = M:GetMedia("crying2"):GetPath(),
	[";;"] = M:GetMedia("crying2"):GetPath(),
	["Q.Q"] = M:GetMedia("crying2"):GetPath(),
	["T.T"] = M:GetMedia("crying2"):GetPath(),
	["QQ"] = M:GetMedia("crying2"):GetPath(),
	["Q_Q"] = M:GetMedia("crying2"):GetPath(),
	[":*"] = M:GetMedia("kiss"):GetPath(),
	["(*^3^)/~☆"] = M:GetMedia("laughing"):GetPath(),
	["(^^)v"] = M:GetMedia("laughing"):GetPath(),
	["(^_^)v"] = M:GetMedia("laughing"):GetPath(),
	["(＾▽＾)"] = M:GetMedia("laughing"):GetPath(),
	["（・∀・）"] = M:GetMedia("laughing"):GetPath(),
	["（　´∀｀）"] = M:GetMedia("laughing"):GetPath(),
	["（⌒▽⌒）"] = M:GetMedia("laughing"):GetPath(),
	["（＾ｖ＾）"] = M:GetMedia("laughing"):GetPath(),
	["（’-’*)"] = M:GetMedia("laughing"):GetPath(),
	["((d[-_-]b))﻿"] = M:GetMedia("music"):GetPath(),
	["d[-_-]b﻿"] = M:GetMedia("music"):GetPath(),
	["((d(-_-)b))﻿"] = M:GetMedia("music"):GetPath(),
	["d(-_-)b﻿"] = M:GetMedia("music"):GetPath(),
	["0(o.o)0"] = M:GetMedia("music"):GetPath(),
	["(^0_0^)"] = M:GetMedia("nerd"):GetPath(),
	["（　ﾟ Дﾟ）"] = M:GetMedia("scared"):GetPath(),
	["（゜◇゜）"] = M:GetMedia("scared"):GetPath(),
	["（￣□￣；）"] = M:GetMedia("scared"):GetPath(),
	["°o°"] = M:GetMedia("scared"):GetPath(),
	["°O°"] = M:GetMedia("scared"):GetPath(),
	[":O"] = M:GetMedia("scared"):GetPath(),
	["o_O"] = M:GetMedia("scared"):GetPath(),
	["o_0"] = M:GetMedia("scared"):GetPath(),
	["o.O"] = M:GetMedia("scared"):GetPath(),
	["(o.o)"] = M:GetMedia("scared"):GetPath(),
	["☆彡"] = M:GetMedia("stars"):GetPath(),
	["☆ミ"] = M:GetMedia("stars"):GetPath(),
	["(-_-)zzz"] = M:GetMedia("sleeping"):GetPath(),
	[">^_^<"] = M:GetMedia("smile"):GetPath(),
	["<^!^>"] = M:GetMedia("smile"):GetPath(),
	["^/^"] = M:GetMedia("smile"):GetPath(),
	["（*^_^*）"] = M:GetMedia("smile"):GetPath(),
	["§^。"] = M:GetMedia("smile"):GetPath(),
	["^§"] = M:GetMedia("smile"):GetPath(),
	["(^<^)"] = M:GetMedia("smile"):GetPath(),
	["(^.^)"] = M:GetMedia("smile"):GetPath(),
	["(^ム^)"] = M:GetMedia("smile"):GetPath(),
	["(^・^)"] = M:GetMedia("smile"):GetPath(),
	["(^。^)"] = M:GetMedia("smile"):GetPath(),
	["(^_^.)"] = M:GetMedia("smile"):GetPath(),
	["(^_^)"] = M:GetMedia("smile"):GetPath(),
	["(^^)"] = M:GetMedia("smile"):GetPath(),
	["(^J^)"] = M:GetMedia("smile"):GetPath(),
	["(*^。^*)"] = M:GetMedia("smile"):GetPath(),
	["^_^"] = M:GetMedia("smile"):GetPath(),
	["^^"] = M:GetMedia("smile"):GetPath(),
	["(#^.^#)"] = M:GetMedia("smile"):GetPath(),
	["（＾－＾）"] = M:GetMedia("smile"):GetPath(),
	["（●＾o＾●）"] = M:GetMedia("smile"):GetPath(),
	["（＾ｖ＾）"] = M:GetMedia("smile"):GetPath(),
	["（＾ｕ＾）"] = M:GetMedia("smile"):GetPath(),
	["（＾◇＾）"] = M:GetMedia("smile"):GetPath(),
	["( ^)o(^ )"] = M:GetMedia("smile"):GetPath(),
	["(^O^)"] = M:GetMedia("smile"):GetPath(),
	["(^o^)"] = M:GetMedia("smile"):GetPath(),
	["(^○^)"] = M:GetMedia("smile"):GetPath(),
	[")^o^("] = M:GetMedia("smile"):GetPath(),
	["(*^▽^*)"] = M:GetMedia("smile"):GetPath(),
	["(^^ゞ"] = M:GetMedia("sweating"):GetPath(),
	["(^_^;)"] = M:GetMedia("sweating"):GetPath(),
	["(-_-;)"] = M:GetMedia("sweating"):GetPath(),
	["(~_~;)"] = M:GetMedia("sweating"):GetPath(),
	["(・。・;)"] = M:GetMedia("sweating"):GetPath(),
	["(・_・;)"] = M:GetMedia("sweating"):GetPath(),
	["(・・;)"] = M:GetMedia("sweating"):GetPath(),
	["^^;"] = M:GetMedia("sweating"):GetPath(),
	["^_^;"] = M:GetMedia("sweating"):GetPath(),
	["(#^.^#)"] = M:GetMedia("sweating"):GetPath(),
	["(^ ^;)"] = M:GetMedia("sweating"):GetPath(),
	["(^_-)"] = M:GetMedia("winking"):GetPath(),
	["(^_-)-☆"] = M:GetMedia("winking"):GetPath(),
	["(=_=)"] = M:GetMedia("yawn"):GetPath()
}

local paths = {}
local smileys = {}
local function prepare()
	local special = {"%", ":", "-", "^", "$", ")", "(", "]", "[", "~", "@", "#", "&", "*", "_", "+", "=", ",", ".", "?", "/", "\\", "{", "}", "|", "`", ";", "\"", "'"};
	local specialrepl = "["
	for i,token in ipairs(special) do
		specialrepl = specialrepl.."%"..token
	end
	specialrepl = specialrepl.."]"

	local function convertEmoteToPattern(theEmote)
		theEmote = theEmote:gsub(specialrepl,"%%%0")
		return theEmote
	end

	-- icon paths from text emoticons search patterns
	for smiley, path in pairs(emoticons) do
		paths[convertEmoteToPattern(smiley)] = path
	end

	local tinsert = table.insert
	local tsort = table.sort
	local function sortByLength(a,b) 
		return a:len() > b:len()
	end

	-- indexed table with longest smiley pattern first
	for emoticon, path in pairs(paths) do
		tinsert(smileys, emoticon)
	end
	tsort(smileys, sortByLength)

	-- add the raw text smileys to the path listing as well
	for smiley, path in pairs(emoticons) do 
		paths[smiley] = path
	end
end
prepare()
prepare = nil
icons = nil
emoticons = nil

local function make(msg)
	return "|T" .. paths[msg] .. ":%d:%d|t"
end
ns.emoticons = setmetatable({}, { __index = function(tbl,key) 
	local e = rawget(tbl,key)
	if e then 
		return e
	else
		e = make(key)
		rawset(tbl, key, e)
		return e
	end
end })

function ns.smileyIterator()
	return ipairs(smileys)
end

