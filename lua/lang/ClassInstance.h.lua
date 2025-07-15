--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ClassInstance
---
--- @field __type__ string The `class:<package>.<classname>` identity of the class.
--- @field __super__ SuperTable
--- @field __table_id__ string -- For native Lua table identity. Helps prevent infinite loops when checking self literally.
--- @field __class__ ClassDefinition The Class-Object wrapper, not the VM Struct.
--- @field super table|function? This field is dynamically set for each function invocation.
local ClassInstance = {};
