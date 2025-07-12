---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local VM = require 'cool/vm';
local builder = require 'cool/builder';

local cool = {
    newClass = VM.class.newClass,
    newInterface = VM.interface.newInterface,
    builder = builder,
    import = VM.import,
    packages = VM.package.packages
};

VM.stepIn();

-- Language-level
require 'lua/lang/Object';
require 'lua/lang/Package';
require 'lua/lang/Class';

-- Language-util-level
local StackTraceElement = require 'lua/lang/StackTraceElement';
VM.forName(StackTraceElement.path);

VM.stepOut();

return cool;
