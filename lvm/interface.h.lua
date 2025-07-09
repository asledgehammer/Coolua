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
--- @field returns (string[]|string)? (Default: void)
--- @field body function?
--- NOTE: The `default` flag is automatically true if a function body is provided at the time of adding the method. 

--- @class (exact) InterfaceStaticMethodDefinitionParameter
--- 
--- @field scope ClassScope? (Default: package)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)
--- @field body function?


--- @class InterfaceStructDefinitionParameter: StructDefinitionParameter
--- @field extends InterfaceStructDefinition?
--- @field static boolean?
--- @field scope ClassScope? (Default: package)
local InterfaceStructDefinitionParameter = {};

--- @class InterfaceStructDefinition: HierarchicalStructDefinition, Fieldable
--- 
--- @field printHeader string
--- @field super InterfaceStructDefinition?
--- @field sub InterfaceStructDefinition[]
--- @field lock boolean
--- @field static boolean
local InterfaceStructDefinition = {};

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function InterfaceStructDefinition:addStaticField(definition) end

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
---
--- @return MethodDefinition
function InterfaceStructDefinition:addMethod(definition) end

--- @param definition InterfaceStaticMethodDefinitionParameter
---
--- @return MethodDefinition
function InterfaceStructDefinition:addStaticMethod(definition) end


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

--- @param superInterface InterfaceStructDefinition
---
--- @return boolean
function InterfaceStructDefinition:isSuperInterface(superInterface) end

--- @param clsDef StructDefinition
function InterfaceStructDefinition:addStaticStruct(clsDef) end

--- @param outer StructDefinition
function InterfaceStructDefinition:setOuterStruct(outer) end


-- MARK: - Module

--- @class LVMInterfaceModule: LVMModule
local API = {};

--- @param definition InterfaceStructDefinitionParameter
--- @param enclosingStruct StructDefinition?
---
--- @return InterfaceStructDefinition
function API.newInterface(definition, enclosingStruct) end
