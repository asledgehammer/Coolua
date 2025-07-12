---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

require 'cool';

print('## TEST ##\n');

local SimpleInterface = require 'cool/tests/SimpleInterface';
local SimpleImplementation = require 'cool/tests/SimpleImplementation';

print('Interface: \t' .. tostring(SimpleInterface));
print('Class: \t' .. tostring(SimpleImplementation));

local o = SimpleImplementation.new();
o:bMethod();
o:aMethod();

SimpleInterface.aStaticMethod();
