--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class ClassContext The ClassContext is used to monitor and audit calls for scope-visible methods and fields.
---
--- @field class ClassStruct The current class in the stack.
--- @field context 'constructor'|'method'|'field-get'|'field-set' The current context. (Final fields can be set here)
--- @field executable MethodDefinition|ConstructorDefinition? The definition of the context.
--- @field field FieldDefinition?
--- @field file string
--- @field line integer
local ClassContext = {};

-- MARK: - Module

--- @class VMStackModule: VMModule
local API = {};

--- @return StackTraceElement[]
function API.getStack() end

--- Grabs the current context.
---
--- @return StackTraceElement|nil
function API.getContext() end

--- Adds a context to the stack. This happens when constructors or methods are invoked.
---
--- @param context ContextArgs
function API.pushContext(context) end

function API.popContext() end

--- @return string stackTrace
function API.printStackTrace() end
