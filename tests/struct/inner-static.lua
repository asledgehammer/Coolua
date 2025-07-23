---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';
local import = cool.import;
local dump = require 'cool/dump'.any;
local packages = cool.packages;

-- Builder API ------------------------ --
local builder = cool.builder;
local static = builder.static;
local class = builder.class;

local public = builder.public;
-- ------------------------------------ --

--- @type TestDefinition
local Test = import 'tests.Test';

--- Java Example:
--- ```java
--- public class EnclosingClass {
---   public static class EnclosedClass {}
--- }
--- ```
local EnclosingClass2 = class 'EnclosingClass2' (public) {
    static {
        class 'EnclosedClass2' (public) {}
    }
};

local test = Test.new('Struct-Inner-Static',
    --- @param self Test
    function(self)
        self:printf('outer-struct: %s', dump(EnclosingClass2));
        self:printf('inner-struct: %s', dump(EnclosingClass2.EnclosedClass2));
        self:printf('Explicit package-call to enclosed class: %s',
            dump(packages.tests.struct.EnclosingClass2.EnclosedClass2)
        );

        return true;
    end
);

return test;
