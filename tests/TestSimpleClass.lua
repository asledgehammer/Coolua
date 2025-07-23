local cool = require 'cool';
local import = cool.import;

--- @type TestDefinition
local Test = import 'tests.Test';

--- @type DimensionDefinition
local Dimension = import 'tests.Dimension';

local test = Test.new('SimpleClass',
    --- @param self Test
    function(self)
        local dim1 = Dimension.new(5, 5);
        local dim2 = Dimension.new(5, 4);
        local dim3 = Dimension.new(5, 5);

        self:printf('ClassStruct tests:');
        self:printf('    __tostring() = %s', tostring(Dimension));
        self:printf('    __type__     = %s', Dimension.__type__);
        self:print();
        self:printf('Instance tests:');
        self:printf('    getWidth()           = %.4f', dim1:getWidth());
        self:printf('    toString()           = %s', tostring(dim1));
        self:printf('    dim1 == dim2 (false) = %s', tostring(dim1 == dim2));
        self:printf('    dim1 == dim3  (true) = %s', tostring(dim1 == dim3));
        self:printf('    getClass()           = %s', tostring(dim1:getClass()));

        return true;
    end
);

test:run();

return test;
