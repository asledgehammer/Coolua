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

--- @param definition MethodStructParameter
--- @param func function?
---
--- @return MethodStruct
function EnumStructDefinition:addMethod(definition, func) end

--- Attempts to resolve a MethodStruct in the EnumStructDefinition. If the method isn't declared for the class
--- level, the super-class(es) are checked.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function EnumStructDefinition:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function EnumStructDefinition:getMethod(name, args) end

--- Attempts to resolve a MethodStruct in the EnumStructDefinition. If the method isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function EnumStructDefinition:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function EnumStructDefinition:getDeclaredMethod(name, args) end

--- @returns ClassStruct
function EnumStructDefinition:finalize() end

-- MARK: - Module

--- @class VMEnumModule: VMModule
local API = {};

--- @param enumDef EnumStructDefinitionParameter
---
--- @return EnumStructDefinition
function API.newEnum(enumDef) end
