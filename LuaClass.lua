---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';

local LuaClass = {
    newClass = LVM.class.newClass
};

-- Initialize core classes first.

LVM.flags.ignorePushPopContext = true;
LuaClass.Object = require 'lua/lang/Object';
LuaClass.StackTraceElement = require 'lua/lang/StackTraceElement';
LVM.flags.ignorePushPopContext = false;

return LuaClass;
