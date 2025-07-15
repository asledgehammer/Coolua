--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class StackTraceElementDefinition: ObjectDefinition
local StackTraceElementDefinition = {};

--- @param path string
--- @param line number
--- @param struct Struct
--- @param context string
--- @param element any
function StackTraceElementDefinition.new(path, line, struct, context, element) end

--- @class StackTraceElement: Object
--- @field path string
--- @field line integer
--- @field struct Struct
--- @field context string
--- @field element FieldStruct|ConstructorStruct|MethodStruct
local StackTraceElement = {};

--- @return string
function StackTraceElement:getPath() end

--- @return number
function StackTraceElement:getLine() end

--- @return number
function StackTraceElement:getCallingStruct() end

--- @return string
function StackTraceElement:getContext() end

--- @return any
function StackTraceElement:getElement() end
