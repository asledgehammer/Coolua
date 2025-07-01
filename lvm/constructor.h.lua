--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMConstructorModule: LVMModule
local API = {};

--- @param classDef LVMClassDefinition
function API.createMiddleConstructor(classDef) end

--- @param constructors ConstructorDefinition[]
--- @param args table
--- 
--- @return ConstructorDefinition|nil
function API.resolveConstructor(constructors, args) end