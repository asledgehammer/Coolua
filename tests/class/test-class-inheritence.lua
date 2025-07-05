local LVM = require 'LVM';

local Rectangle = require 'tests/Rectangle';

-- LVM.debug.super = true;
local rec1 = Rectangle.new(0, 0, 128, 64);
-- LVM.debug.super = false;

print(rec1:toString());
