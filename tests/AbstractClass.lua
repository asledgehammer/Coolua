---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local AbstractClass = newClass({
    scope = 'public',
    abstract = true,
});

AbstractClass:addConstructor({ scope = 'public' });

AbstractClass:addAbstractMethod({
    scope = 'public',
    name = 'aMethod',
    returns = 'void'
});

AbstractClass:finalize();

--- @cast AbstractClass AbstractClassDefinition
return AbstractClass;
