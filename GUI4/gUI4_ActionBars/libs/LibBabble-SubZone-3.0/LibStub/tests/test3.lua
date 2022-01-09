debugstack = debug.traceback
strmatch = string.match

loadfile("../GP_LibStub.lua")()

local proxy = newproxy() -- non-string

assert(not pcall(GP_LibStub.NewLibrary, GP_LibStub, proxy, 1)) -- should error, proxy is not a string, it's userdata
local success, ret = pcall(GP_LibStub.GetLibrary, proxy, true)
assert(not success or not ret) -- either error because proxy is not a string or because it's not actually registered.

assert(not pcall(GP_LibStub.NewLibrary, GP_LibStub, "Something", "No number in here")) -- should error, minor has no string in it.

assert(not GP_LibStub:GetLibrary("Something", true)) -- shouldn't've created it from the above statement