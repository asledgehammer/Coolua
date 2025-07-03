local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local SimpleInterface = require 'tests/SimpleInterface';

local SimpleImplementation = newClass({
    scope = 'public',
    implements = {
        SimpleInterface
    }
});

SimpleImplementation:finalize();

--- @cast SimpleImplementation SimpleImplementationDefinition

return SimpleImplementation;