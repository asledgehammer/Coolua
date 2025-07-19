local cool = require 'cool';

local builder = cool.builder;
local record = builder.record;
local entry = builder.entry;

local SimpleRecord = record 'SimpleRecord' {
    entry 'firstName' ('string'),
    entry 'lastName' ('string'),
    entry 'city' ('string'),
    entry 'state' ('string'),
    entry 'zipcode' ('number'),
};

print(SimpleRecord);
