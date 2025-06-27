---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';

local LuaClass = {};

LVM.ignorePushPopContext = true;
LuaClass.Object = require 'lua/lang/Object';
LuaClass.StackTraceElement = require 'lua/lang/StackTraceElement';
LVM.ignorePushPopContext = false;

LuaClass.newClass = LVM.newClass;

return LuaClass;
