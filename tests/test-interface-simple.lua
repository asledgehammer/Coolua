local LuaClass = require 'LuaClass';
local newInterface = LuaClass.newInterface;

-- public interface SimpleInterface {
local SimpleInterface = newInterface({
    scope = 'public',
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
    function(self)
        print('Hello from bMethod()!');
    end
);

-- }

SimpleInterface:finalize();

-- TODO: Where we left off: Creating the method params definition for interfaces.
-- Next, go into the interface addMethod and suit it for interface methods context.
