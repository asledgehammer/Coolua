---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

require 'cool';

print('## TEST ##\n');

local ImplAbstractClass = require 'tests/ImplAbstractClass';

local o = ImplAbstractClass:new();
o:aMethod();
