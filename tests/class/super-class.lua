local cool = require 'cool';
local import = cool.import;

--- @type TestDefinition
local Test = import 'tests.Test';

--- @type RectangleDefinition
local Rectangle = import 'tests.Rectangle';

local test = Test.new('SuperClass',
    --- @param self Test
    function(self)
        local rec1 = Rectangle.new(0, 0, 128, 64);
        self:print(rec1:toString());
        return true;
    end
);

return test;
