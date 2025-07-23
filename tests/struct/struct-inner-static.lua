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

local test = Test.new('Struct-Inner-Static',
    --- @param self Test
    function(self)
        --- Java Example:
        --- ```java
        --- public class EnclosingClass {
        ---   public static class EnclosedClass {}
        --- }
        --- ```
        local EnclosingClass = class 'EnclosingClass' (public) {
            static {
                class 'EnclosedClass' (public) {}
            }
        };

        self:printf('outer-struct: %s', dump(EnclosingClass));
        self:printf('inner-struct: %s', dump(EnclosingClass.EnclosedClass));
        self:printf('Explicit package-call to enclosed class: %s',
            dump(packages.tests.struct.EnclosingClass.EnclosedClass)
        );

        return true;
    end
);

return test;
