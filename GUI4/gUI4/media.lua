local addon, gUI4 = ...

-- Lua API
local _G = _G
local floor, max, min = math.floor, math.max, math.min
local pairs, select, unpack = pairs, select, unpack
local tconcat, tinsert = table.concat, table.insert
local type, tonumber, tostring = type, tonumber, tostring
local rawset, getmetatable, setmetatable = rawset, getmetatable, setmetatable
local wipe = table.wipe

local L = _G.GP_LibStub("GP_AceLocale-3.0"):GetLocale("gUI4")

-- folder names for the internal function :ConstructPath()
local path = [[Interface\AddOns\]]..addon..[[\media\]]
local paths = {
	Border = path..[[borders\]], 
	Button = path..[[buttons\]], 
	Font = path..[[fonts\]],
	Frame = path..[[frames\]], 
	Emoticon = path.. [[emoticons\]],
	Sound = path..[[sounds\]],
	StatusBar = path..[[statusbars\]], 
	Texture = path..[[textures\]]
}
local mirror = {
	TOP = "BOTTOM",
	BOTTOM = "TOP",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	TOPLEFT = "BOTTOMRIGHT",
	TOPRIGHT = "BOTTOMLEFT",
	BOTTOMLEFT = "TOPRIGHT",
	BOTTOMRIGHT = "TOPLEFT"
}
local keyword = {
	PREFIX = "gUI4", 
	SUFFIX = ".tga", 
	BLANK = [[Interface\ChatFrame\ChatFrameBackground]],
	ICON = { 5/65, 59/64, 5/64, 59/64 }
}

-- only allow sub-tables to be added, not singular values
-- *this is for development purposes only, as the top level 
--  of the table is locked at the end of this file anyway
local M = setmetatable({}, { 
	__newindex = function(tbl, key, value)
		if type(value) == "table" then
			rawset(tbl, key, value)
		else
			error(L["You can't write singular values directly into gUI4's media library, use sub-libraries instead!"])
		end
	end
})

-- write protected metatable
local protected_meta = {
	__newindex = function(self)
		error(L["Attempt to modify read-only table"])
	end,
	__metatable = false
}

local function protect(tbl)
	local old_meta = getmetatable(tbl)
	if old_meta then
		local new_meta = {}
		for i,v in pairs(old_meta) do
			new_meta[i] = v
		end
		for i,v in pairs(protected_meta) do
			new_meta[i] = v
		end
		return setmetatable(tbl, new_meta)
	else
		return setmetatable(tbl, protected_meta)
	end
end

local function rgb2hex(r, g, b)
	return ("|cff%02x%02x%02x"):format(r*255, g*255, b*255)
end

local function normalize(num, scale)
	return max(min(tonumber(num) or scale or 1, scale or 1), 0)/(scale or 1)
end

local function hex2rgb(hex)
    hex = hex:gsub("#", "")
	return normalize("0x"..hex:sub(1,2), 255), normalize("0x"..hex:sub(1,2), 255), normalize("0x"..hex:sub(1,2), 255)
end

-------------------------------------------------------------------------------
--	Media Object Template
-------------------------------------------------------------------------------
local function GetAlpha(self) 
	return self.alpha or 1
end
local color = { 1, 1, 1 }
local function GetColor(self) 
	return self.color or color -- returning the table, to keep it compatible with the colors in gUI4:GetColors()
end
local function GetElement(self)
	return self.element 
end
local function GetInset(self)
	return self.inset or 0
end
local function GetName(self)
	return self.name 
end
local function GetLibrary(self)
	return self.parent
end
local function GetOffset(self)
	return self.offset or 0
end
local function GetPrefix(self)
	return self.prefix
end
local function GetPath(self) 
	if type(self.path) == "table" then
		return unpack(self.path)
	else
		return self.path
	end
end
local function GetPoint(self, frame) 
	if not self.point then return end
	if frame then 
		if #self.point == 4 and mirror[self.point[2]] then
			return self.point[1], frame, self.point[2], self.point[3], self.point[4]
		elseif #self.point == 3 then
			return self.point[1], frame, self.point[1], self.point[2], self.point[3]
		elseif #self.point == 1 then
			return self.point[1], frame, self.point[1]
		else
			return unpack(self.point) 
		end
	else 
		return unpack(self.point) 
	end
end
local function GetSize(self) 
	if self.size then
		return unpack(self.size)
	end
end
local function GetTexCoord(self) 
	if self.texCoord then
		return unpack(self.texCoord)
	else
		return 0, 1, 0, 1
	end
end
local function GetTexSize(self) 
	if self.texSize then
		return unpack(self.texSize)
	end
end
local function GetTheme(self) 
	return self.theme 
end
--local function GetGridSize(self)
--	if self.gridSize then
--		return unpack(self.gridSize)
--	end
--end
local function GetGridSlotSize(self)
	if self.gridSlotSize then
		return unpack(self.gridSlotSize)
	end
end
local function GetGridItemTexCoord(self)
	if self.gridTexCoord then
		return unpack(self.gridTexCoord)
	else
		return 0, 1, 0, 1
	end
end
local function GetNumGridItems(self)
	return self.numGridItems
end
local function GetGridTexCoord(self, index)
	if type(index) ~= "number" then return end
	local itemW, itemH = self:GetGridSlotSize()
	local texW, texH = self:GetTexSize()
	-- local gridSizeX, gridSizeY = self:GetGridSize()
	local itemL, itemR, itemT, itemB = self:GetGridItemTexCoord()
	if itemW and itemH and texW and texH and itemL and itemR and itemT and itemB then
		local cols, rows = floor(texW/itemW), floor(texH/itemH)
		if index < 1 or index > min(cols*rows, self:GetNumGridItems() or 0) then return end
		local x = index%cols
		local y = floor((index-1)/cols) + 1
		if x == 0 then x = cols end
		-- print(self:GetPath(), cols, rows, x, y)
		local left = (itemW*(x-1) + itemL*itemW)/(texW)
		local right = (itemW*(x-1) + itemR*itemW)/(texW)
		local top = (itemH*(y-1) + itemT*itemH)/(texH)
		local bottom = (itemH*(y-1) + itemB*itemH)/(texH)
		return left, right, top, bottom
	end
end
local function GetGridItem(self, index)
	local item = setmetatable({ protected = false }, { __index = self })
	local left, right, top, bottom = self:GetGridTexCoord(index)
	local w, h = self:GetGridSlotSize()
	item:SetTexSize(w, h)
	item:SetTexCoord(left, right, top, bottom)
	item:Close()
	return item
end
local function GetNewInstance(self)
	local new = setmetatable({ protected = false, clone = true }, { __index = self })
	for key, value in pairs(self) do
		if key ~= "protected" then
			new[key] = value
		end
	end
	return new
end
local function GetParent(self) 
	return M[self.parent]
end
local function IsWriteProtected(self)
	return self.protected
end
local function SetAlpha(self, alpha)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if alpha then
		self.alpha = tonumber(alpha) or 0
	end
	return self
end
local function SetColor(self, r, g, b, a)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if r then 
		if self.color then
			wipe(self.color)
		end
		if type(r) == "table" then
			if r.r then
				self.color = { normalize(r.r), normalize(r.g), normalize(r.b) }
			else
				self.color = { normalize(r), normalize(g), normalize(b) }
			end
		elseif type(r) == "string" then
			self.color = { hex2rgb(r) }
		else
			self.color = { normalize(r), normalize(g), normalize(b) }
		end
		if a and type(a) == "number" then
			self:SetAlpha(normalize(a))
		end
		self.color.colorCode = rgb2hex(unpack(self.color)) -- more gUI4:GetColors() compability
	end
	return self
end
local function SetElement(self, element)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if element then
		self.element = tostring(element)
	end
	return self
end
local function SetInset(self, inset)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if inset then
		self.inset = tonumber(inset) or 0
	end
	return self
end
local function SetName(self, name)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if name then
		self.name = name
	end
	return self
end
local function SetOffset(self, offset)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if offset then
		self.offset = floor((tonumber(offset) or 0) + .5)
	end
	return self
end
local function SetPrefix(self, prefix)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	self.prefix = prefix
	return self
end
local function SetPath(self, ...)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if ... then 
		local num, path = select("#", ...), ...
		if num == 1 and type(path) == "string" then
			if keyword[path] then
				self.path = keyword[path]
			else
				self.path = path
			end
		elseif num == 3 or num == 4 then
			-- self.path = keyword.BLANK
			-- self:SetColor(...)
			self.path = { ... }
		end
	end
	return self
end
local function SetPoint(self, ...)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if ... then
		if select("#", ...) == 1 and keyword[...] then
			self.point = keyword[...]
		else
			self.point = { ... }
		end
	end
	return self
end
-- local function SetGridSize(self, ...)
	-- if self:IsWriteProtected() then 
		-- error(L["Cannot modify write protected media objects."])
	-- end
	-- if ... then 
		-- if select("#", ...) == 1 then
			-- local size = ...
			-- self.gridSize = { size, size }
		-- elseif select("#", ...) == 2 then
			-- local width, height = ...
			-- self.gridSize = { width, height }
		-- end
	-- end
	-- return self	
-- end
local function SetGridSlotSize(self, ...)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if ... then
		if select("#", ...) == 1 then
			local size = ...
			self.gridSlotSize = { size, size }
		elseif select("#", ...) == 2 then
			local width, height = ...
			self.gridSlotSize = { width, height }
		end
	end
	return self
end
local function SetGridItemTexCoord(self, left, right, top, bottom)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	self.gridTexCoord = { normalize(left), normalize(right), normalize(top), normalize(bottom) }
	return self
end
local function SetNumGridItems(self, size)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	self.numGridItems = size
	return self
end
local function SetSize(self, ...)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if ... then
		if select("#", ...) == 1 then
			local size = ...
			self.size = { size, size }
		elseif select("#", ...) == 2 then
			local width, height = ...
			self.size = { width, height }
		end
	end
	return self
end
local function SetTexCoord(self, ...)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if ... then
		local key = ...
		if type(key) == "string" and keyword[key] then
			self.texCoord = keyword[key]
		else
			self.texCoord = { ... }
		end
	else
		self.texCoord = { 0, 1, 0, 1 }
	end
	return self
end
local function SetTexSize(self, ...)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if ... then 
		if select("#", ...) == 1 then
			local size = ...
			self.texSize = { size, size }
		elseif select("#", ...) == 2 then
			local width, height = ...
			self.texSize = { width, height }
		end
	end
	return self
end
local function SetTheme(self, theme)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	if theme then 
		self.theme = tostring(theme)
	end
	return self
end
local function ConstructPath(self)
	if self:IsWriteProtected() then return end
	if not self:GetPath() then
		local fileName = {}
		tinsert(fileName, keyword.PREFIX)
		tinsert(fileName, self:GetLibrary())
		if self:GetSize() then
			tinsert(fileName, ("%dx%d"):format(self:GetSize()))
		end
		if self:GetElement() then 
			tinsert(fileName, self:GetElement())
		end
		if self:GetTheme() then 
			tinsert(fileName, self:GetTheme())
		end
		self:SetPath(paths[self:GetLibrary()] .. tconcat(fileName, "_") .. keyword.SUFFIX)
		fileName = nil
	end
	return self
end
local function WriteProtect(self)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	for _,v in pairs(self) do
		if type(v) == "table" then
			protect(v)
		end
	end
	self.protected = true
	protect(self)
	return self.clone and self or M[self.parent]
end
local function Close(self)
	if self:IsWriteProtected() then 
		error(L["Cannot modify write protected media objects."])
	end
	self:ConstructPath()
	self:WriteProtect()
	return self.clone and self or M[self.parent]
end

local mediaTemplate = {
	GetNewInstance = GetNewInstance,
	GetAlpha = GetAlpha,
	GetColor = GetColor,
	GetElement = GetElement,
	GetName = GetName,
	GetInset = GetInset,
	GetLibrary = GetLibrary, 
	GetOffset = GetOffset,
	GetPrefix = GetPrefix,
	GetPath = GetPath,
	GetPoint = GetPoint,
	GetSize = GetSize,
	-- GetGridSize = GetGridSize,
	GetGridItemTexCoord = GetGridItemTexCoord,
	GetGridSlotSize = GetGridSlotSize,
	GetGridTexCoord = GetGridTexCoord,
	GetNumGridItems = GetNumGridItems,
	GetGridItem = GetGridItem, 
	GetTexCoord = GetTexCoord,
	GetTexSize = GetTexSize,
	GetTheme = GetTheme,
	GetParent = GetParent,
	IsWriteProtected = IsWriteProtected,
	SetAlpha = SetAlpha, -- returns 'self'
	SetColor = SetColor, -- returns 'self'
	SetElement = SetElement, -- returns 'self'
	SetInset = SetInset, -- returns 'self'
	SetOffset = SetOffset, -- returns 'self'
	SetName = SetName, -- returns 'self' 
	SetPrefix = SetPrefix, -- returns 'self'
	SetPath = SetPath, -- returns 'self'
	SetPoint = SetPoint, -- returns 'self'
	SetSize = SetSize, -- returns 'self'
	-- SetGridSize = SetGridSize, -- returns 'self'
	SetGridSlotSize = SetGridSlotSize, -- returns 'self'
	SetGridItemTexCoord = SetGridItemTexCoord, -- returns 'self'
	SetNumGridItems = SetNumGridItems, -- returns 'self'
	SetTexCoord = SetTexCoord, -- returns 'self'
	SetTexSize = SetTexSize, -- returns 'self'
	SetTheme = SetTheme, -- returns 'self'
	ConstructPath = ConstructPath, -- returns 'self'
	WriteProtect = WriteProtect, -- returns parent library object
	Close = Close -- returns parent library object
}
local media_mt = { __index = mediaTemplate }

-------------------------------------------------------------------------------
--	Library Template
-------------------------------------------------------------------------------
-- @usage library:GetMedia(name)
-- @usage library:GetMedia(name, element)
-- @usage library:GetMedia(name, element, size[, theme])
-- @usage library:GetMedia(name, element, width, height[, theme])
-- @usage library:GetMedia(element, size[, theme])
-- @usage library:GetMedia(element, width, height[, theme])
local function GetMedia(self, ...)
	if not ... or type((...)) ~= "string" then return end
	local num = select("#", ...)
	if num == 1 then
		local name = ...
		for i,v in ipairs(self) do
			if v.name == name then
				return self[i]
			end
		end
	elseif num == 2 then
		local argType = type((select(2, ...)))
		if argType == "string" then
			local name, element = ...
			for i,v in ipairs(self) do
				if v.name == name and v.element == element then
					return self[i]
				end
			end
		elseif argType == "number" then
			local element, size = ...
			for i,v in ipairs(self) do
				if v.element == element and (v.size and v.size[1] == size) then
					return self[i]
				end
			end
		end
	elseif num == 3 then
		local argType = type((select(2, ...)))
		if argType == "string" then
			local name, element, size = ...
			for i,v in ipairs(self) do
				if v.name == name and v.element == element and (v.size and v.size[1] == size) then
					return self[i]
				end
			end
		elseif argType == "number" then
			local argType = type((select(3, ...)))
			if argType == "string" then
				local element, size, theme = ...
				for i,v in ipairs(self) do
					if v.element == element and (v.size and v.size[1] == size) and v.theme == theme then
						return self[i]
					end
				end
			elseif argType == "number" then
				local element, width, height = ...
				for i,v in ipairs(self) do
					if v.element == element and (v.size and v.size[1] == width and v.size[2] == height) then
						return self[i]
					end
				end
			end
		end
	elseif num == 4 then
		local argType = type((select(2, ...)))
		if argType == "string" then
			local argType = type((select(4, ...)))
			if argType == "string" then
				local name, element, size, theme = ...
				for i,v in ipairs(self) do
					if v.name == name and v.element == element and (v.size and v.size[1] == size) and v.theme == theme then
						return self[i]
					end
				end
			elseif argType == "number" then
				local name, element, width, height = ...
				for i,v in ipairs(self) do
					if v.name == name and v.element == element and (v.size and v.size[1] == width and v.size[2] == height) then
						return self[i]
					end
				end
			end
		elseif argType == "number" then
			local element, width, height, theme = ...
			for i,v in ipairs(self) do
				if v.element == element and (v.size and v.size[1] == width and v.size[2] == height) and v.theme == theme then
					return self[i]
				end
			end
		end
	elseif num == 5 then
		local name, element, width, height, theme = ...
		for i,v in ipairs(self) do
			if v.name == name and v.element == element and (v.size and v.size[1] == width and v.size[2] == height) and v.theme == theme then
				return self[i]
			end
		end
	end
end
local function CreateMedia(self)
	local new = setmetatable({ parent = self.name }, media_mt ) 
	tinsert(self, new) -- self:GetMediaLibrary(self.name)
	return new
end

-------------------------------------------------------------------------------
--	Public API
-------------------------------------------------------------------------------
-- How to retrieve media: 
-- //addon//:GetMediaLibrary(library):GetMedia([name,][element[, width/size, height]])
-- //addon//:GetMedia(library, [name,][element[, width/size, height]])

-- @usage gUI4:CreateMediaLibrary(library)
-- @param library <string> name of the new library
-- @return <table> pointer to the new library
function gUI4:CreateMediaLibrary(library)
	if type(library) ~= "string" or M[library] then
		return
	end
	M[library] = {
		name = library, 
		CreateMedia = CreateMedia, 
		GetMedia = GetMedia
	}
	return M[library]
end

-- @usage //addon//:CreateMedia(library)
function gUI4:CreateMedia(library)
	if type(library) ~= "string" or not M[library] then
		return
	end
	return M[library]:CreateMedia()
end

-- @usage //addon//:GetMediaLibrary([library])
-- @param library <string> name of the library to retrieve
-- @return <table> pointer to the requested media library, or the main table
function gUI4:GetMediaLibrary(library) 
	if type(library) == "string" and M[library] then
		return M[library]
	else
		return M 
	end
end

-- @usage //addon//:GetMedia(library, ...)
-- @param library <string> name of the library to retrieve
-- @param ... @see library:GetMedia()
-- @return <table> pointer to the requested media object
function gUI4:GetMedia(library, ...)
	if type(library) ~= "string" or not M[library] then
		return
	end
	return self:GetMediaLibrary(library):GetMedia(...)
end

-- utility function to get default gUI4 media paths 
-- @usage gUI4:GetMediaPath([library[, fileName]])
-- @return <string> default file path of gUI4 media in the library 
function gUI4:GetMediaPath(library, fileName)
	if type(library) == "string" and paths[library] then
		if type(fileName) == "string" then
			return paths[library] .. fileName
		else
			return paths[library]
		end
	else
		return path
	end
end

local protected = {}
function gUI4:LockMediaLibrary(library)
	local lock = self:GetMediaLibrary(library)
	if not protected[lock] then
		protect(lock) 
		protected[lock] = true
	end
end
