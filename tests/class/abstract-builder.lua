local cool = require 'cool';
local import = cool.import;

-- Builder API ------------------------ --
local builder = cool.builder;
local class = builder.class;
local extends = builder.extends;
local method = builder.method;
local createMethodTemplate = builder.createMethodTemplate;

local public = builder.public;
local abstract = builder.abstract;
-- ------------------------------------ --

--- @type TestDefinition
local Test = import 'tests.Test';

local AbstractClass = class 'AbstractClass2' (abstract) {
    method 'aMethod' (public, abstract) {}
};

-- Create a method template for the abstract method that'll be implemented.
local aMethod = createMethodTemplate(AbstractClass, 'aMethod');

local ImplementedClass = class 'ImplementedClass2' (abstract) {
    extends(AbstractClass),

    aMethod {
        function()
            if not Test.silent then
                print('[TEST][AbstractClass-Builder] :: Running from implemented abstract class!');
            end
        end
    }
};

local test = Test.new('AbstractClass-Builder',
    --- @param self Test
    function(self)
        local o = ImplementedClass:new();
        o:aMethod();

        return true;
    end
);

return test;
