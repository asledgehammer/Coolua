--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMStackModule: LVMModule
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
