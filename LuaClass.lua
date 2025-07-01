---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';

local LuaClass = {
    newClass = LVM.class.newClass
};

LVM.flags.internal = LVM.flags.internal + 1;
-- Language-level
LuaClass.Object = require 'lua/lang/Object';
LuaClass.Package = require 'lua/lang/Package';
LuaClass.Class = require 'lua/lang/Class';

-- Language-util-level
LuaClass.StackTraceElement = require 'lua/lang/StackTraceElement';
LVM.class.forName(LuaClass.StackTraceElement.path);

LVM.flags.internal = LVM.flags.internal - 1;

return LuaClass;
