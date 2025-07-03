---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';

local LuaClass = {
    newClass = LVM.class.newClass,
    newInterface = LVM.interface.newInterface
};

LVM.stepIn();

-- Language-level
LuaClass.Object = require 'lua/lang/Object';
LuaClass.Package = require 'lua/lang/Package';
LuaClass.Class = require 'lua/lang/Class';

-- Language-util-level
LuaClass.StackTraceElement = require 'lua/lang/StackTraceElement';
LVM.forName(LuaClass.StackTraceElement.path);

LVM.stepOut();

return LuaClass;
