--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ClassInstance
---
--- @field __type__ string The `class:<package>.<classname>` identity of the class.
--- @field __super__ SuperTable
--- @field __class__ ClassDefinition The Class-Object wrapper, not the LVM StructDefinition.
--- @field super table|function? This field is dynamically set for each function invocation.
local ClassInstance = {};
