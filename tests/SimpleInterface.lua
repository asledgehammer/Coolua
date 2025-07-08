---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';

local dump = require 'dump'.any;

-- Builder API ------------------------ --
local builder = LuaClass.builder;
local interface = builder.interface;
local static = builder.static;
local method = builder.method;
local public = builder.public;
-- ------------------------------------ --

-- public interface SimpleInterface {
--- @type SimpleInterfaceDefinition
local SimpleInterface, scaffolding = interface 'SimpleInterface' (public) {

    -- void aMethod();
    method 'aMethod',

    -- default void bMethod() {
    --   System.out.println("Hello from bMethod!");
    -- }
    method 'bMethod' {
        --- @param self SimpleInterface
        function(self)
            print('Hello from bMethod!');
        end
    },

    static {
        -- public static void aStaticMethod() {
        --   System.out.println("Hello from a static interface method!");
        -- }
        method 'aStaticMethod' (public) {
            function()
                print('Hello from a static interface method!');
            end
        }
    }
};
-- }

-- print('\n\n # RESULT #\n');
-- print(dump(scaffolding, { pretty = true, label = true }));

return SimpleInterface;
