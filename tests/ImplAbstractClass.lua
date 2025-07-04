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
    parameters = {},
    returns = 'void'
}, function()
    print('Running from implemented abstract class!');
end);

ImplAbstractClass:finalize();

--- @cast ImplAbstractClass ImplAbstractClassDefinition
return ImplAbstractClass;
