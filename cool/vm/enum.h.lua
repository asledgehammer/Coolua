--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class EnumStructDefinitionParameter: StructDefinitionParameter
local EnumStructDefinitionParameter = {};

--- @class EnumStructDefinition: StructDefinition
local EnumStructDefinition = {};

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function EnumStructDefinition:addField(definition) end

--- Attempts to resolve a FieldDefinition in the EnumStructDefinition. If the field isn't declared for the class level,
--- the super-class(es) are checked.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function EnumStructDefinition:getField(name) end

--- Attempts to resolve a FieldDefinition in the EnumStructDefinition. If the field isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function EnumStructDefinition:getDeclaredField(name) end

--- @param constructorDefinition ConstructorDefinitionParameter
---
--- @return ConstructorDefinition
function EnumStructDefinition:addConstructor(constructorDefinition) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function EnumStructDefinition:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function EnumStructDefinition:getDeclaredConstructor(args) end

--- @param definition MethodDefinitionParameter
--- @param func function?
---
--- @return MethodDefinition
function EnumStructDefinition:addMethod(definition, func) end

--- Attempts to resolve a MethodDefinition in the EnumStructDefinition. If the method isn't declared for the class
--- level, the super-class(es) are checked.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function EnumStructDefinition:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function EnumStructDefinition:getMethod(name, args) end

--- Attempts to resolve a MethodDefinition in the EnumStructDefinition. If the method isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function EnumStructDefinition:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function EnumStructDefinition:getDeclaredMethod(name, args) end

--- @returns ClassStructDefinition
function EnumStructDefinition:finalize() end

-- MARK: - Module

--- @class VMEnumModule: VMModule
local API = {};

--- @param enumDef EnumStructDefinitionParameter
---
--- @return EnumStructDefinition
function API.newEnum(enumDef) end
