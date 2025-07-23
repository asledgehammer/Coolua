---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';
local import = cool.import;

local PrintPlus = require 'cool/print';
local printf = PrintPlus.printf;

-- Builder API ------------------------ --
local builder = cool.builder;
local createMethodTemplate = builder.createMethodTemplate;

local interface = builder.interface;
local class = builder.class;
local implements = builder.implements;
local static = builder.static;
local method = builder.method;
local constructor = builder.constructor;
local parameters = builder.parameters;

local public = builder.public;
-- ------------------------------------ --

--- @type TestDefinition
local Test = import 'tests.Test';

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
            if not Test.silent then
                print('[TEST][Interface-Simple] :: Hello from bMethod!');
            end
        end
    },

    static {
        method 'aStaticMethod' (public) {
            function()
                if not Test.silent then
                    print('[TEST][Interface-Simple] :: Hello from a static interface method!');
                end
            end
        }
    }
};

-- NOTE: To make things a lot easier on implementing classes, create a template of the method that only requires a
--       function-body.
local aMethod = createMethodTemplate(SimpleInterface, 'aMethod', { public }, {
    parameters { 'string' }
});

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
            if not Test.silent then
                printf('[TEST][Interface-Simple] :: Hello %s from aMethod!', str);
            end
        end
    }
};

local test = Test.new('Interface-Simple',
    function(self)
        self:printf('Interface: %s', tostring(SimpleInterface));
        self:printf('    Class: %s', tostring(SimpleImplementation));

        local o = SimpleImplementation.new();
        o:bMethod();
        o:aMethod('Jab');

        SimpleInterface.aStaticMethod();

        return true;
    end
);

return test;
