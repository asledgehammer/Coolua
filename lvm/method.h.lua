--- @meta

--- @class LVMMethodModule: LVMModule
local API = {};

--- @param classDef LVMClassDefinition
--- @param name string
--- @param methods MethodDefinition[]
---
--- @return fun(o: ClassInstance, ...): (any?)
function API.createMiddleMethod(classDef, name, methods) end

--- @param classDef LVMClassDefinition
---
--- @return string[] methodNames
function API.getDeclaredMethodNames(classDef, array) end

--- @param classDef LVMClassDefinition
--- @param methodNames string[]?
---
--- @return string[] methodNames
function API.getMethodNames(classDef, methodNames) end
