local cool = require 'cool';
local import = cool.import;

--- @type TestDefinition
local Test = import 'tests.Test';

--- @type Test[]
local tests = {

    -- tests/struct
    require 'tests/struct/inner-instanced',
    require 'tests/struct/inner-static',

    -- tests/class
    require 'tests/class/simple',
    require 'tests/class/super-class',
    require 'tests/class/abstract-basic',
    require 'tests/class/abstract-builder',

    -- tests/interface
    require 'tests/interface/simple',
    require 'tests/interface/field',

    -- tests/record
    require 'tests/record/simple',

    -- tests/field
    require 'tests/field/static'
};

print('[TEST] :: Warming up VM..\n');
Test.silent = true;
for _ = 1, 2 do for i = 1, #tests do tests[i]:run() end end
Test.silent = false;

print('[TEST] :: Running test(s)..\n');
for i = 1, #tests do
    if i ~= 1 then
        print();
    end
    tests[i]:run();
end
