local cool = require 'cool';
local import = cool.import;

--- @type TestDefinition
local Test = import 'tests.Test';

--- @type Test[]
local tests = {
    require 'tests/class/simple',
    require 'tests/class/abstract-basic',
    require 'tests/class/abstract-builder'
};

print('[TEST] :: Warming up VM..');
-- VM Warm-up cycles.
Test.silent = true;
for _ = 1, 2 do for i = 1, #tests do tests[i]:run() end end
Test.silent = false;

print('[TEST] :: Running test(s)..');
for i = 1, #tests do
    tests[i]:run();
end
