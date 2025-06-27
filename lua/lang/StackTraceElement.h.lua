--- @meta

--- @class StackTraceElementDefinition: ObjectDefinition
local StackTraceElementDefinition = {};

--- @param path string
--- @param line number
--- @param class any
--- @param context string
--- @param element any
function StackTraceElementDefinition.new(path, line, class, context, element) end

--- @class StackTraceElement: Object
---
local StackTraceElement = {};

--- @return string
function StackTraceElement:getPath() end

--- @return number
function StackTraceElement:getLine() end

--- @return number
function StackTraceElement:getCallingClass() end

--- @return string
function StackTraceElement:getContext() end

--- @return any
function StackTraceElement:getElement() end
