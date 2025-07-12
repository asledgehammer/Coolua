local dump = require 'cool/dump'.any;

-- Builder API ------------------------- --
local builder = require 'cool'.builder;
local interface = builder.interface;
local field = builder.field;
local properties = builder.properties;
local get = builder.get;
-- ------------------------------------- --

local TestInterface = interface 'TestInterface' {
    field 'myField' {
        properties {
            type = 'number',
            value = 0
        },
        get {},
    }
};

print(dump(TestInterface, {
    pretty = true,
    label = true,
    ignoreTableFunctions = true,
    ignoreEmptyTableArrays = true
}));

-- print(TestInterface.myField);
-- print(TestInterface.getMyField());
