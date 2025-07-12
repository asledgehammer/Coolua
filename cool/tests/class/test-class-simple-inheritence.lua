---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

require 'cool';

print('## TEST ##\n');

local Rectangle = require 'cool/tests/Rectangle';

local rec1 = Rectangle.new(0, 0, 128, 64);
print(rec1:toString());
