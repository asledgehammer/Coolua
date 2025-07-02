--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class EnumDefinitionParameter
local EnumDefinitionParameter = {};

--- @class EnumDefinition
local EnumDefinition = {};

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function EnumDefinition:addField(definition) end

--- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function EnumDefinition:getField(name) end

--- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function EnumDefinition:getDeclaredField(name) end

--- @param constructorDefinition ConstructorDefinitionParameter
--- @param func function
---
--- @return ConstructorDefinition
function EnumDefinition:addConstructor(constructorDefinition, func) end

--- @param constructorDefinition ConstructorDefinitionParameter
---
--- @return ConstructorDefinition
function EnumDefinition:addConstructor(constructorDefinition) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function EnumDefinition:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function EnumDefinition:getDeclaredConstructor(args) end

--- @param definition MethodDefinitionParameter
--- @param func function?
---
--- @return MethodDefinition
function EnumDefinition:addMethod(definition, func) end

--- Attempts to resolve a MethodDefinition in the ClassDefinition. If the method isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function EnumDefinition:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function EnumDefinition:getMethod(name, args) end

--- Attempts to resolve a MethodDefinition in the ClassDefinition. If the method isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function EnumDefinition:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function EnumDefinition:getDeclaredMethod(name, args) end

--- @returns LVMClassDefinition
function EnumDefinition:finalize() end

-- MARK: - Module

--- @class LVMEnumModule: LVMModule
local API = {};

--- @param enumDef EnumDefinitionParameter
---
--- @return EnumDefinition
function API.newEnum(enumDef) end
