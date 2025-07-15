--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class VMPrintModule: VMModule
local API = {};

--- @param args any[]
---
--- @return string explodedArgsString
function API.argsToString(args) end

--- @param def StructDefinition
---
--- @return string
function API.printStruct(def) end

--- @param def ExecutableDefinition
---
--- @return string
function API.printExecutable(def) end

--- @param def ConstructorDefinition
---
--- @return string
function API.printConstructor(def) end

--- @param def MethodDefinition
---
--- @return string
function API.printMethod(def) end

--- @param def InterfaceStruct
---
--- @return string
function API.printInterface(def) end

--- @param def ClassStruct
---
--- @return string
function API.printClass(def) end

--- @param def GenericTypeDefinition
---
--- @return string
function API.printGenericType(def) end

--- @param def GenericsTypesDefinition
---
--- @return string
function API.printGenericTypes(def) end
