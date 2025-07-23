local cool = require 'cool';
local import = cool.import;
local newClass = cool.newClass;

--- @type TestDefinition
local Test = import 'tests.Test';

local test = Test.new('AbstractClass-Basic',
    --- @param self Test
    function(self)
        local AbstractClass = newClass {
            name = 'AbstractClass',
            scope = 'public',
            abstract = true,
        };

        AbstractClass:addAbstractMethod {
            scope = 'public',
            name = 'aMethod',
            returnTypes = 'void'
        };

        AbstractClass:finalize();

        local ImplAbstractClass = newClass {
            name = 'ImplAbstractClass',
            scope = 'public',
            final = true,
            extends = AbstractClass
        };

        ImplAbstractClass:addMethod {
            scope = 'public',
            name = 'aMethod',
            returnTypes = 'void',

            body = function()
                self:print('Running from implemented abstract class!');
            end
        };

        ImplAbstractClass:finalize();

        local o = ImplAbstractClass.new();
        o:aMethod();

        return true;
    end
);

test:run();

return test;
