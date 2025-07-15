--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: Definitions

--- @class SuperTable
---
--- @field methods table<string, function>
--- @field constructor function
--- @field __who__ (ConstructorDefinition|MethodDefinition)? While a constructor is ran, this will help point to it.
--- @field __call_count__ number To keep track of constructor super() invocations.

-- MARK: Module

--- @class VMSuperModule: VMModule
local API = {};

--- SuperTables are created for classes to access superclass fields.
---
--- @param cd ClassStructDefinition
---
--- @return SuperTable
function API.createSuperTable(cd) end
