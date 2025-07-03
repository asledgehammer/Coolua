--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) MethodDefinition
---
--- @field __type__ 'MethodDefinition'
---
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class StructDefinition
--- @field scope ClassScope
--- @field name string
--- @field super MethodDefinition? (Internally assigned. If none, this is nil)
--- @field generics GenericsTypesDefinition?
--- @field parameters ParameterDefinition[]
--- @field returns string[]
--- @field func function?
--- @field lineRange {start: number, stop: number} The function's start and stop line.
--- 
--- * General Flags *
--- @field static boolean
--- @field final boolean
--- @field override boolean (Default: false)
--- 
--- * Class Flags *
--- @field abstract boolean (Default: false)
---
--- * Interface Flags *
--- @field interface boolean (Default: false) If the method belongs to an interface.
--- @field default boolean (Default: false) If true, `interface` is true and the method is also defined in the interface.

--- @class (exact) MethodDefinitionParameter
--- 
--- @field scope ClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)

--- @class (exact) ClassMethodDefinitionParameter: MethodDefinitionParameter
--- 
--- @field abstract boolean? (Default: false)

-- MARK: - Module

--- @class LVMMethodModule: LVMModule
local API = {};

--- @param classDef StructDefinition
--- @param name string
--- @param methods MethodDefinition[]
---
--- @return fun(o: ClassInstance, ...): (any?)
function API.createMiddleMethod(classDef, name, methods) end

--- @param classDef ClassStructDefinition
---
--- @return string[] methodNames
function API.getDeclaredMethodNames(classDef, array) end

--- @param classDef StructDefinition
--- @param methodNames string[]?
---
--- @return string[] methodNames
function API.getMethodNames(classDef, methodNames) end

--- @param methods MethodDefinition[]
--- @param args any[]
---
--- @return MethodDefinition|nil
function API.resolveMethod(methods, args) end
