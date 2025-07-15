--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class InterfaceInstance
local InterfaceInstance = {};

--- @class (exact) InterfaceMethodDefinitionParameter
---
--- NOTE: All instanced interface methods are public.
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function?
--- NOTE: The `default` flag is automatically true if a function body is provided at the time of adding the method.

--- @class (exact) InterfaceStaticMethodDefinitionParameter
---
--- @field scope ClassScope? (Default: package)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function?

--- @class InterfaceStructParameter: StructDefinitionParameter
---
--- @field extends InterfaceStruct?
--- @field static boolean?
--- @field scope ClassScope? (Default: package)
local InterfaceStructParameter = {};

--- @class InterfaceStruct: HierarchicalStructDefinition, Fieldable
--- @field __type__ 'InterfaceStruct'
--- @field __readonly__ boolean
---
--- @field printHeader string
--- @field super InterfaceStruct?
--- @field sub InterfaceStruct[]
--- @field lock boolean
--- @field static boolean
local InterfaceStruct = {};

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function InterfaceStruct:addStaticField(definition) end

--- Attempts to resolve a FieldDefinition in the InterfaceStruct. If the field isn't declared for the class level,
--- the super-class(es) are checked.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function InterfaceStruct:getField(name) end

--- Attempts to resolve a FieldDefinition in the InterfaceStruct. If the field isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function InterfaceStruct:getDeclaredField(name) end

--- @param definition InterfaceMethodDefinitionParameter
---
--- @return MethodDefinition
function InterfaceStruct:addMethod(definition) end

--- @param definition InterfaceStaticMethodDefinitionParameter
---
--- @return MethodDefinition
function InterfaceStruct:addStaticMethod(definition) end

--- Attempts to resolve a MethodDefinition in the InterfaceStruct. If the method isn't declared for the class
--- level, the super-class(es) are checked.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function InterfaceStruct:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function InterfaceStruct:getMethod(name, args) end

--- Attempts to resolve a MethodDefinition in the InterfaceStruct. If the method isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function InterfaceStruct:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function InterfaceStruct:getDeclaredMethod(name, args) end

--- @return InterfaceStruct
function InterfaceStruct:finalize() end

--- @return boolean
function InterfaceStruct:isFinalized() end

--- @param interface InterfaceStruct
---
--- @return boolean
function InterfaceStruct:isSuperInterface(interface) end

--- @param interface InterfaceStruct
---
--- @return boolean
function InterfaceStruct:isSubInterface(interface) end

--- @param clsDef StructDefinition
function InterfaceStruct:addStaticStruct(clsDef) end

--- @param outer StructDefinition
function InterfaceStruct:setOuterStruct(outer) end

-- MARK: - Module

--- @class VMInterfaceModule: VMModule
local API = {};

--- @param definition InterfaceStructParameter
--- @param enclosingStruct StructDefinition?
---
--- @return InterfaceStruct
function API.newInterface(definition, enclosingStruct) end
