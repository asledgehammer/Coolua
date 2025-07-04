local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local SimpleInterface = require 'tests/SimpleInterface';

-- public class SimpleImplementation implements SimpleInterface {
local SimpleImplementation = newClass({
    scope = 'public',
    implements = {
        SimpleInterface
    }
});

-- public SimpleImplementation() {}
SimpleImplementation:addConstructor({ scope = 'public' });

-- @Override
-- public void aMethod() {
--   System.out.println("Hello from aMethod!");
-- }
SimpleImplementation:addMethod({
    scope = 'public',
    name = 'aMethod',

    --- @param self SimpleImplementation
    body = function(self)
        print('Hello form aMethod!');
    end
});

-- }

SimpleImplementation:finalize();

--- @cast SimpleImplementation SimpleImplementationDefinition

return SimpleImplementation;
