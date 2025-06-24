local Rectangle = require 'cssbox/layout/Rectangle';

local test = true;

if test then
    local rec1 = Rectangle.new(0, 0, 128, 64);
    -- TODO: Figure out if the super func assignment is wrong.
    print(rec1:toString());
end
