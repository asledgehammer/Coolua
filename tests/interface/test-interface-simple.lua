---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';

-- Builder API ------------------------ --
local builder = cool.builder;
local interface = builder.interface;
local class = builder.class;
local implements = builder.implements;
local static = builder.static;
local method = builder.method;
local constructor = builder.constructor;

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

--- Java example:
--- ```java
--- public class SimpleImplementation implements SimpleInterface {
--- 
---   public SimpleImplementation() {}
--- 
---   @Override
---   public void aMethod() {
---     System.out.println("Hello from aMethod!");
---   }
--- 
--- }
--- ```
local SimpleImplementation = class 'SimpleImplementation' (public) {

    implements(SimpleInterface),

    constructor(public) {},

    method 'aMethod' (public) {
        function()
            print('Hello from aMethod!');
        end
    }
};

print('## TEST ##\n');
print('Interface: \t' .. tostring(SimpleInterface));
print('Class: \t' .. tostring(SimpleImplementation));

local o = SimpleImplementation.new();
o:bMethod();
o:aMethod();

SimpleInterface.aStaticMethod();
