--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMPrintModule: LVMModule
local API = {};

--- @param args any[]
---
--- @return string explodedArgsString
function API.argsToString(args) end

--- @param def MethodDefinition
---
--- @return string
function API.printMethod(def) end

--- @param def GenericTypeDefinition
--- 
--- @return string
function API.printGenericType(def) end

--- @param def GenericsTypesDefinition
--- 
--- @return string
function API.printGenericTypes(def) end
