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

--- @param def ExecutableStruct
---
--- @return string
function API.printExecutable(def) end

--- @param def ConstructorStruct
---
--- @return string
function API.printConstructor(def) end

--- @param def MethodStruct
---
--- @return string
function API.printMethod(def) end

--- @param def Struct
---
--- @return string
function API.printStruct(def) end

--- @param def ClassStruct
---
--- @return string
function API.printClass(def) end

--- @param def InterfaceStruct
---
--- @return string
function API.printInterface(def) end

--- @param def RecordStruct
--- 
--- @return string
function API.printRecord(def) end
