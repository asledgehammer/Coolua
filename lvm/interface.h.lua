--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) InterfaceMethodDefinitionParameter
--- 
--- @field scope ClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)
--- NOTE: The `default` flag is automatically true if a function body is provided at the time of adding the method. 

--- @class InterfaceStructDefinitionParameter: StructDefinitionParameter
local InterfaceStructDefinitionParameter = {};

--- @class InterfaceStructDefinition: StructDefinition, Hierarchical, Fieldable
--- 
--- @field printHeader string
--- @field super InterfaceStructDefinition?
--- @field sub InterfaceStructDefinition[]
--- @field lock boolean
local InterfaceStructDefinition = {};

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function InterfaceStructDefinition:addField(definition) end

--- Attempts to resolve a FieldDefinition in the InterfaceStructDefinition. If the field isn't declared for the class level,
--- the super-class(es) are checked.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function InterfaceStructDefinition:getField(name) end

--- Attempts to resolve a FieldDefinition in the InterfaceStructDefinition. If the field isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function InterfaceStructDefinition:getDeclaredField(name) end

--- @param definition InterfaceMethodDefinitionParameter
--- @param func function?
---
--- @return MethodDefinition
function InterfaceStructDefinition:addMethod(definition, func) end

--- Attempts to resolve a MethodDefinition in the InterfaceStructDefinition. If the method isn't declared for the class
--- level, the super-class(es) are checked.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function InterfaceStructDefinition:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function InterfaceStructDefinition:getMethod(name, args) end

--- Attempts to resolve a MethodDefinition in the InterfaceStructDefinition. If the method isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function InterfaceStructDefinition:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function InterfaceStructDefinition:getDeclaredMethod(name, args) end

--- @returns ClassStructDefinition
function InterfaceStructDefinition:finalize() end

-- MARK: - Module

--- @class LVMInterfaceModule: LVMModule
local API = {};

--- @param definition InterfaceStructDefinitionParameter
--- @param enclosingStruct StructDefinition?
---
--- @return InterfaceStructDefinition
function API.newInterface(definition, enclosingStruct) end
