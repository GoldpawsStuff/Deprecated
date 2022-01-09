-- $Id: GP_LibStub.lua 103 2014-10-16 03:02:50Z mikk $
-- GP_LibStub is a simple versioning stub meant for use in Libraries.  http://www.wowace.com/addons/GP_LibStub/ for more info
-- GP_LibStub is hereby placed in the Public Domain
-- Credits: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke
local GP_LibStub_MAJOR, GP_LibStub_MINOR = "GP_LibStub", 2  -- NEVER MAKE THIS AN SVN REVISION! IT NEEDS TO BE USABLE IN ALL REPOS!
local GP_LibStub = _G[GP_LibStub_MAJOR]

-- Check to see is this version of the stub is obsolete
if not GP_LibStub or GP_LibStub.minor < GP_LibStub_MINOR then
	GP_LibStub = GP_LibStub or {libs = {}, minors = {} }
	_G[GP_LibStub_MAJOR] = GP_LibStub
	GP_LibStub.minor = GP_LibStub_MINOR
	
	-- GP_LibStub:NewLibrary(major, minor)
	-- major (string) - the major version of the library
	-- minor (string or number ) - the minor version of the library
	-- 
	-- returns nil if a newer or same version of the lib is already present
	-- returns empty library object or old library object if upgrade is needed
	function GP_LibStub:NewLibrary(major, minor)
		assert(type(major) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
		minor = assert(tonumber(strmatch(minor, "%d+")), "Minor version must either be a number or contain a number.")
		
		local oldminor = self.minors[major]
		if oldminor and oldminor >= minor then return nil end
		self.minors[major], self.libs[major] = minor, self.libs[major] or {}
		return self.libs[major], oldminor
	end
	
	-- GP_LibStub:GetLibrary(major, [silent])
	-- major (string) - the major version of the library
	-- silent (boolean) - if true, library is optional, silently return nil if its not found
	--
	-- throws an error if the library can not be found (except silent is set)
	-- returns the library object if found
	function GP_LibStub:GetLibrary(major, silent)
		if not self.libs[major] and not silent then
			error(("Cannot find a library instance of %q."):format(tostring(major)), 2)
		end
		return self.libs[major], self.minors[major]
	end
	
	-- GP_LibStub:IterateLibraries()
	-- 
	-- Returns an iterator for the currently registered libraries
	function GP_LibStub:IterateLibraries() 
		return pairs(self.libs) 
	end
	
	setmetatable(GP_LibStub, { __call = GP_LibStub.GetLibrary })
end
