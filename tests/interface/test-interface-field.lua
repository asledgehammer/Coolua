local dump = require 'dump'.any;

-- Builder API ------------------------- --
local builder = require 'LuaClass'.builder;
local interface = builder.interface;
local field = builder.field;
local properties = builder.properties;

local public = builder.public;
-- ------------------------------------- --

local TestInterface = interface 'TestInterface' {
    field 'myField' {
        properties {
            type = 'number',
            value = 0
        }
    }
};

print('d', TestInterface);
print('e', dump(TestInterface, {pretty = true, label = true}));