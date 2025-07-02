local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local AbstractClass = newClass({
    scope = 'public',
    abstract = true,
});

AbstractClass:addConstructor({ scope = 'public' });

AbstractClass:addMethod({
    scope = 'public',
    abstract = true,
    name = 'aMethod',
    parameters = {},
    returns = 'void'
});

AbstractClass:finalize();

--- @cast AbstractClass AbstractClassDefinition
return AbstractClass;
