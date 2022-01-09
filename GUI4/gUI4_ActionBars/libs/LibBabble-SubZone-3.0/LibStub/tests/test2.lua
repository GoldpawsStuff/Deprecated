debugstack = debug.traceback
strmatch = string.match

loadfile("../GP_LibStub.lua")()

for major, library in GP_LibStub:IterateLibraries() do
	-- check that MyLib doesn't exist yet, by iterating through all the libraries
	assert(major ~= "MyLib")
end

assert(not GP_LibStub:GetLibrary("MyLib", true)) -- check that MyLib doesn't exist yet by direct checking
assert(not pcall(GP_LibStub.GetLibrary, GP_LibStub, "MyLib")) -- don't silently fail, thus it should raise an error.
local lib = GP_LibStub:NewLibrary("MyLib", 1) -- create the lib
assert(lib) -- check it exists
assert(rawequal(GP_LibStub:GetLibrary("MyLib"), lib)) -- verify that :GetLibrary("MyLib") properly equals the lib reference

assert(GP_LibStub:NewLibrary("MyLib", 2))	-- create a new version

local count=0
for major, library in GP_LibStub:IterateLibraries() do
	-- check that MyLib exists somewhere in the libraries, by iterating through all the libraries
	if major == "MyLib" then -- we found it!
		count = count +1
		assert(rawequal(library, lib)) -- verify that the references are equal
	end
end
assert(count == 1) -- verify that we actually found it, and only once
