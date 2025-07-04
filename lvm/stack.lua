---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = require 'DebugUtils';

local LVMUtils = require 'LVMUtils';
local debugf = LVMUtils.debugf;

--- @type LVM
local LVM;

--- @type LVMStackModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

--- @type StackTraceElement[]
local stack = {};

function API.getStack()
    return stack;
end

--- Grabs the current context.
---
--- @return StackTraceElement|nil
function API.getContext()
    local stackLen = #stack;
    if stackLen == 0 then return nil end
    return stack[stackLen];
end

--- @class (exact) ContextArgs
--- @field path string
--- @field line number
--- @field class StructDefinition
--- @field context string
--- @field element FieldDefinition|ConstructorDefinition|MethodDefinition

--- Adds a context to the stack. This happens when constructors or methods are invoked.
---
--- @param context ContextArgs
function API.pushContext(context)
    -- Muting context.
    if LVM.isInside() or LVM.flags.ignorePushPopContext then return end

    debugf(LVM.debug.scope, 'line %i ContextStack[%i] pushContext(%s)', DebugUtils.getCurrentLine(3), #stack + 1,
        tostring(context));

    -- Prevent infinite loop.
    LVM.flags.ignorePushPopContext = true;
    table.insert(
        stack,
        _G.lua.lang.StackTraceElement.new(
            context.path,
            context.line,
            context.class,
            context.context,
            context.element
        )
    );
    LVM.flags.ignorePushPopContext = false;
end

function API.popContext()
    -- Muting context.
    if LVM.isInside() or LVM.flags.ignorePushPopContext then return end

    debugf(LVM.debug.scope, 'line %i ContextStack[%i] popContext()', DebugUtils.getCurrentLine(3), #stack - 1);
    local stackLen = #stack;
    if stackLen == 0 then
        error('The ContextStack is empty.', 2);
    end
    return table.remove(stack, stackLen);
end

--- @return string stackTrace
function API.printStackTrace()
    local s = 'Class StackTrace:';
    for i = #stack, 1, -1 do
        s = s .. '\n\t' .. tostring(LVM.stack:getStack()[i]);
    end
    return s;
end

return API;
