--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class PrintPlus
local API = {};

--- A common printf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function API.printf(message, ...) end

--- A common errorf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param level number
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function API.errorf(level, message, ...) end

--- A common debugf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param flag boolean If true, the message prints. If false, it doesn't.
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function API.debugf(flag, message, ...) end
