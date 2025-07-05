---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local AbstractClass = require 'tests/AbstractClass';

local ImplAbstractClass = newClass({
    scope = 'public',
    final = true,
    extends = AbstractClass
});

ImplAbstractClass:addConstructor({ scope = 'public' });

ImplAbstractClass:addMethod({
    scope = 'public',
    name = 'aMethod',
    returns = 'void',

    body = function()
        print('Running from implemented abstract class!');
    end
});

ImplAbstractClass:finalize();

--- @cast ImplAbstractClass ImplAbstractClassDefinition
return ImplAbstractClass;
