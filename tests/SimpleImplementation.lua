local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local SimpleInterface = require 'tests/SimpleInterface';

local SimpleImplementation = newClass({
    scope = 'public',
    implements = {
        SimpleInterface
    }
});

SimpleImplementation:addConstructor({scope = 'public'});

-- public void aMethod();
SimpleImplementation:addMethod({
        scope = 'public',
        name = 'aMethod',
    },
    function()
        print('Hello form aMethod()!');
    end
);

SimpleImplementation:finalize();

--- @cast SimpleImplementation SimpleImplementationDefinition

return SimpleImplementation;
