---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';

-- Builder API ------------------------ --
local builder = LuaClass.builder;
local import = builder.import;
local class = builder.class;
local implements = builder.implements;
local constructor = builder.constructor;
local method = builder.method;
local public = builder.public;
-- ------------------------------------ --

local SimpleInterface = import 'tests.SimpleInterface';

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
local SimpleImplementation, scaffolding = class 'SimpleImplementation' (public) {

    implements(SimpleInterface),

    constructor(public) {},

    method 'aMethod' (public) {
        function()
            print('Hello from aMethod!');
        end
    }
};

--- @cast SimpleImplementation SimpleImplementationDefinition

return SimpleImplementation;
