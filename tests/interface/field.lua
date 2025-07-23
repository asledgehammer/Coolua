---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';
local import = cool.import;

-- Builder API ------------------------- --
local builder = cool.builder;
local interface = builder.interface;
local field = builder.field;
local properties = builder.properties;
local get = builder.get;
-- ------------------------------------- --

--- @type TestDefinition
local Test = import 'tests.Test';

local TestInterface = interface 'TestInterface' {
    field 'myField' {
        properties {
            type = 'number',
            value = 0
        },
        get {},
    }
};

local test = Test.new('Interface-Field',
    --- @param self Test
    function(self)
        assert(TestInterface.declaredFields['myField'].static == true);
        self:print(TestInterface);
        return true;
    end
);

return test;
