--- @meta

--- @class SuperTable
--- 
--- @field methods table<string, function>
--- @field constructor function

--- @class ClassInstance
---
--- @field __type string The `class:<package>.<classname>` identity of the class.
--- @field __super SuperTable
--- @field super table|function? This field is dynamically set for each function invocation.
local ClassInstance = {};
