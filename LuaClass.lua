---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';
local LVMUtils = require 'LVMUtils';
local debugf = LVMUtils.debugf;

local LuaClass = {
    newClass = LVM.class.newClass,
    newInterface = LVM.interface.newInterface
};

LVM.stepIn();

-- Language-level
require 'lua/lang/Object';
require 'lua/lang/Package';
require 'lua/lang/Class';

-- Language-util-level
local StackTraceElement = require 'lua/lang/StackTraceElement';
LVM.forName(StackTraceElement.path);

LVM.stepOut();

return LuaClass;
