--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class InterfaceStructDefinitionParameter: StructDefinitionParameter
local InterfaceStructDefinitionParameter = {};

--- @class InterfaceStructDefinition: StructDefinition
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

--- @param definition MethodDefinitionParameter
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

--- @param enumDef InterfaceStructDefinitionParameter
---
--- @return InterfaceStructDefinition
function API.newInterface(enumDef) end
