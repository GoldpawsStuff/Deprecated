debugstack = debug.traceback
strmatch = string.match

loadfile("../GP_LibStub.lua")()


-- Pretend like loaded GP_LibStub is old and doesn't have :IterateLibraries
assert(GP_LibStub.minor)
GP_LibStub.minor = GP_LibStub.minor - 0.0001
GP_LibStub.IterateLibraries = nil

loadfile("../GP_LibStub.lua")()

assert(type(GP_LibStub.IterateLibraries)=="function")


-- Now pretend that we're the same version -- :IterateLibraries should NOT be re-created
GP_LibStub.IterateLibraries = 123

loadfile("../GP_LibStub.lua")()

assert(GP_LibStub.IterateLibraries == 123)


-- Now pretend that a newer version is loaded -- :IterateLibraries should NOT be re-created
GP_LibStub.minor = GP_LibStub.minor + 0.0001

loadfile("../GP_LibStub.lua")()

assert(GP_LibStub.IterateLibraries == 123)


-- Again with a huge number
GP_LibStub.minor = GP_LibStub.minor + 1234567890

loadfile("../GP_LibStub.lua")()

assert(GP_LibStub.IterateLibraries == 123)


print("OK")