---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';
local newClass = cool.newClass;

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
