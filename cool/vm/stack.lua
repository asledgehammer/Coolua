---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local debugf = PrintPlus.debugf;

local DebugUtils = require 'cool/debug';

--- @type VM
local VM;

--- @type VMStackModule
local API = {

    __type__ = 'VMModule',

    --- @param vm VM
    setVM = function(vm)
        VM = vm;
        VM.moduleCount = VM.moduleCount + 1;
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
    if VM.isInside() or VM.flags.ignorePushPopContext then return end

    debugf(VM.debug.scope, '[SCOPE] :: line %i ContextStack[%i] pushContext(%s)', DebugUtils.getCurrentLine(3),
    #stack + 1,
        tostring(context));

    -- Prevent infinite loop.
    VM.flags.ignorePushPopContext = true;
    table.insert(
        stack,
        VM.package.packages.lua.lang.StackTraceElement.new(
            context.path,
            context.line,
            context.class,
            context.context,
            context.element
        )
    );
    VM.flags.ignorePushPopContext = false;
end

function API.popContext()
    -- Muting context.
    if VM.isInside() or VM.flags.ignorePushPopContext then return end

    debugf(VM.debug.scope, '[SCOPE] :: line %i ContextStack[%i] popContext()', DebugUtils.getCurrentLine(3), #stack - 1);
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
        s = s .. '\n\t' .. tostring(VM.stack:getStack()[i]);
    end
    return s;
end

return API;
