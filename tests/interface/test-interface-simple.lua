---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';

local PrintPlus = require 'cool/print';
local printf = PrintPlus.printf;

-- Builder API ------------------------ --
local builder = cool.builder;
local methodTemplate = builder.createMethodTemplate;

local interface = builder.interface;
local class = builder.class;
local implements = builder.implements;
local static = builder.static;
local method = builder.method;
local constructor = builder.constructor;
local parameters = builder.parameters;

local public = builder.public;
-- ------------------------------------ --

-- NOTE: To make things a lot easier on implementing classes, create a template of the method that only requires a 
--       function-body.
local aMethod = methodTemplate('aMethod', { public }, {
    parameters { 'string' }
});

--- Java example:
--- ```java
--- package tests.interface;
---
--- public interface SimpleInterface {
---
---   void aMethod(String str);
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

    method 'aMethod' (public) {
        parameters { 'string' }
    },

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
---   public void aMethod(String str) {
---     System.out.println("Hello " + str + " from aMethod!");
---   }
---
--- }
--- ```
local SimpleImplementation = class 'SimpleImplementation' (public) {

    implements(SimpleInterface),

    constructor(public) {},

    aMethod {
        function(self, str)
            printf('Hello %s from aMethod!', str);
        end
    }
};

print('## TEST ##\n');
print('Interface: \t' .. tostring(SimpleInterface));
print('Class: \t' .. tostring(SimpleImplementation));

local o = SimpleImplementation.new();
o:bMethod();
o:aMethod('Jab');

SimpleInterface.aStaticMethod();
