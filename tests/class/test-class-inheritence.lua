---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local Rectangle = require 'tests/Rectangle';
local LVM = require 'LVM';

local rec1 = Rectangle.new(0, 0, 128, 64);
print(rec1:toString());

print(LVM.stack.printStackTrace());
