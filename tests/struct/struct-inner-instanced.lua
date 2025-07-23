local cool = require 'cool';
local import = cool.import;

-- Builder API ------------------------ --
local builder = cool.builder;
local class = builder.class;

local public = builder.public;
-- ------------------------------------ --

--- @type TestDefinition
local Test = import 'tests.Test';

local test = Test.new('Struct-Inner-Instanced',
    --- @param self Test
    function(self)
        --- Java Example:
        --- ```java
        --- public class EnclosingClass {
        ---   public static class EnclosedClass {}
        --- }
        --- ```
        local EnclosingClass = class 'EnclosingClass' (public) {
            class 'EnclosedClass' (public) {
            }
        };

        local ins = EnclosingClass.new();

        self:printf('outer-struct: %s', tostring(ins));
        self:printf('inner-struct: %s', tostring(ins.EnclosedClass));
        -- print(EnclosingClass.EnclosedClass); (error)

        return true;
    end
);

return test;
