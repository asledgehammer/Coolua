--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) MethodDefinition
--- @field __type__ 'MethodDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class LVMClassDefinition
--- @field scope ClassScope
--- @field static boolean
--- @field final boolean
--- @field name string
--- @field override boolean (Default: false)
--- @field super MethodDefinition? (Internally assigned. If none, this is nil)
--- @field generics GenericsTypesDefinition?
--- @field parameters ParameterDefinition[]
--- @field returns string[]
--- @field func fun(o: any, ...): (any?)
--- @field lineRange {start: number, stop: number} The function's start and stop line.
--- @field abstract boolean (Default: false)

--- @class (exact) MethodDefinitionParameter
--- @field scope ClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)
--- @field abstract boolean? (Default: false)

-- MARK: - Module

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

--- @param methods MethodDefinition[]
--- @param args any[]
--- 
--- @return MethodDefinition|nil
function API.resolveMethod(methods, args) end
