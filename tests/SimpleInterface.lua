local LuaClass = require 'LuaClass';
local newInterface = LuaClass.newInterface;

-- public interface SimpleInterface {
local SimpleInterface = newInterface({
    scope = 'public',
    package = 'tests',
    name = 'SimpleInterface',
});

-- public void aMethod();
SimpleInterface:addMethod({
    scope = 'public',
    name = 'aMethod'
});

-- public default void bMethod() {
--   System.out.println("Hello from bMethod()!");
-- }
SimpleInterface:addMethod({
        scope = 'public',
        name = 'bMethod',
    },
    function()
        print('Hello from bMethod()!');
    end
);

-- }

SimpleInterface:finalize();

--- @cast SimpleInterface SimpleInterfaceDefinition

return SimpleInterface;