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

--- Java example:
--- ```java
--- package tests;
--- 
--- public interface SimpleInterface {
--- 
---   void aMethod();
--- 
---   default void bMethod() {
---     System.out.println("Hello from bMethod!");
---   }
--- 
---   public static void aStaticMethod() {
---     System.out.println("Hello from a static interface method!");
---   }
--- 
--- }
--- ```
--- @type SimpleInterfaceDefinition
local SimpleInterface = interface 'SimpleInterface' (public) {

    method 'aMethod',

    method 'bMethod' {
        function()
            print('Hello from bMethod!');
        end
    },

    static {
        method 'aStaticMethod' (public) {
            function()
                print('Hello from a static interface method!');
            end
        }
    }
};

return SimpleInterface;
