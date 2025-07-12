--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class dump
local dump = {};

--- @class (exact) DumpConfiguration
--- @field level number?
--- @field maxLevel number?
--- @field label boolean?
--- @field labelField string?
--- @field pretty boolean?
--- @field ignoreTableFunctions boolean?
--- @field ignoreEmptyTableArrays boolean?

--- @class (exact) DumpMetadata
--- @field level number
--- @field discovered any[]

--- @param e any
--- @param data DumpConfiguration?
--- @param metadata DumpMetadata?
---
--- @return string
function dump.any(e, data, metadata) end

--- @param a any[]
--- @param data DumpConfiguration?
--- @param metadata DumpMetadata?
---
--- @return string
function dump.array(a, data, metadata) end

--- @param t table
--- @param data DumpConfiguration?
--- @param metadata DumpMetadata?
---
--- @return string
function dump.table(t, data, metadata) end

--- @param s string
---
--- @return string
function dump.string(s) end

--- @param f function
---
--- @return string
function dump.func(f) end

--- @param ud userdata
---
--- @return string
function dump.userdata(ud) end

--- @param o any
---
--- @return string
function dump.object(o) end

--- @param c Class|ClassStructDefinition
---
--- @return string
function dump.class(c) end

--- @return string
function dump.discovered() end
