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

-- MARK: Module

--- @class LVMSuperModule: LVMModule
local API = {};

--- SuperTables are created for classes to access superclass fields.
---
--- @param cd ClassStructDefinition
---
--- @return SuperTable
function API.createSuperTable(cd) end
