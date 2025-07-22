---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local vm = require 'cool/vm';
local import = vm.import;

-- Builder API ------------------------ --
local builder = require 'cool/builder';
local class = builder.class;

local public = builder.public;
-- ----------- ------------------------ --

import 'lua.lang.Object';

--- @type RecordDefinition
local Record = class 'Record' (public) {
    -- TODO: Implement.
}

print(Record);

return Record;
