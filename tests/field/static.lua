---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';
local import = cool.import;

--- @type TestDefinition
local Test = import 'tests.Test';
--- @type MathDefinition
local Math = import 'tests.Math';

local test = Test.new('Field-Static',
    --- @param self Test
    function(self)
        local math = Math.new();
        self:printf('(class method)   PI = %f', math.getPI());
        self:printf('(class instance) PI = %f', math.PI);
        self:printf('(static call)    PI = %f', Math.PI);
        return true;
    end
);

return test;
