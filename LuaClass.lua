---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local OOPUtils = require 'asledgehammer/util/OOPUtils';
local errorf = OOPUtils.errorf;

local LVM = require 'LVM';

local LuaClass = {};

LVM.ignorePushPopContext = true;
LuaClass.Object = require 'lua/lang/Object';
LuaClass.StackTraceElement = require 'lua/lang/StackTraceElement';
LVM.ignorePushPopContext = false;

LuaClass.newClass = LVM.newClass;

--- Resolves LuaClass definitions like Java.
--- 
--- @param path string The path to the class.
--- 
--- @return LVMClassDefinition
_G.import = function(path)

    require(path);

    local parts = path:split('.');
    local next = _G;
    for i = 1, #parts do
        next = next[parts[i]];
    end

    if not next then
        errorf(2, 'Import not found: %s', path);
    elseif next.__type__ ~= 'ClassDefinition' then
        errorf(2, 'Import not class: %s', path);
    end

    return next;
end

return LuaClass;
