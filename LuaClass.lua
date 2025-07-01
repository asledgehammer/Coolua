---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';

local LuaClass = {
    newClass = LVM.class.newClass
};

-- Language-level
LuaClass.Object = require 'lua/lang/Object';
LuaClass.Package = require 'lua/lang/Package';
LuaClass.Class = require 'lua/lang/Class';

-- Language-util-level
LuaClass.StackTraceElement = require 'lua/lang/StackTraceElement';

LVM.flags.bypassFieldSet = true;

LuaClass.Class:create();
LuaClass.Object:create();

LVM.flags.bypassFieldSet = false;

return LuaClass;
