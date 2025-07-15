--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class InterfaceInstance
local InterfaceInstance = {};

--- @class (exact) InterfaceMethodStructInput
---
--- NOTE: All instanced interface methods are public.
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function?
--- NOTE: The `default` flag is automatically true if a function body is provided at the time of adding the method.

--- @class (exact) InterfaceStaticMethodStructInput
---
--- @field scope ClassScope? (Default: package)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function?

--- @class InterfaceStructInput: StructInput
---
--- @field extends InterfaceStruct?
--- @field static boolean?
--- @field scope ClassScope? (Default: package)
local InterfaceStructInput = {};

--- @class InterfaceStruct: HierarchicalStruct, Fieldable
--- @field __type__ 'InterfaceStruct'
--- @field __readonly__ boolean
---
--- @field printHeader string
--- @field super InterfaceStruct?
--- @field sub InterfaceStruct[]
--- @field lock boolean
--- @field static boolean
local InterfaceStruct = {};

--- @param definition FieldStructInput
---
--- @return FieldStruct
function InterfaceStruct:addStaticField(definition) end

--- Attempts to resolve a FieldStruct in the InterfaceStruct. If the field isn't declared for the class level,
--- the super-class(es) are checked.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function InterfaceStruct:getField(name) end

--- Attempts to resolve a FieldStruct in the InterfaceStruct. If the field isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function InterfaceStruct:getDeclaredField(name) end

--- @param definition InterfaceMethodStructInput
---
--- @return MethodStruct
function InterfaceStruct:addMethod(definition) end

--- @param definition InterfaceStaticMethodStructInput
---
--- @return MethodStruct
function InterfaceStruct:addStaticMethod(definition) end

--- Attempts to resolve a MethodStruct in the InterfaceStruct. If the method isn't declared for the class
--- level, the super-class(es) are checked.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function InterfaceStruct:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function InterfaceStruct:getMethod(name, args) end

--- Attempts to resolve a MethodStruct in the InterfaceStruct. If the method isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function InterfaceStruct:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
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

--- @param clsDef Struct
function InterfaceStruct:addStaticStruct(clsDef) end

--- @param outer Struct
function InterfaceStruct:setOuterStruct(outer) end

-- MARK: - Module

--- @class VMInterfaceModule: VMModule
local API = {};

--- @param definition InterfaceStructInput
--- @param enclosingStruct Struct?
---
--- @return InterfaceStruct
function API.newInterface(definition, enclosingStruct) end
