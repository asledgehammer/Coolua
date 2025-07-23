local cool = require 'cool';
local import = cool.import;

-- Builder API ------------------------ --
local builder = cool.builder;
local record = builder.record;
local entry = builder.entry;
-- ------------------------------------ --

local SimpleRecord = record 'SimpleRecord' {
    entry 'firstName' ('string'),
    entry 'lastName' ('string'),
    entry 'city' ('string'),
    entry 'state' ('string'),
    entry 'zipcode' ('number'),
};

--- @type TestDefinition
local Test = import 'tests.Test';

local test = Test.new('Record-Simple',
    --- @param self Test
    function(self)
        self:print(SimpleRecord);
        return true;
    end
);

return test;
