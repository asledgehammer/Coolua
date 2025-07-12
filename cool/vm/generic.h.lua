--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @alias GenericsTypesDefinition GenericTypeDefinition[] Applied on Class-Scope and Method-Scope.

--- @class (exact) GenericTypeDefinition The base definition for all generic definitions.
---
--- @field __type__ 'GenericTypeDefinition'
---
--- @field name string The name of the genric type.
--- @field types table<string, any> One or more types to assign.

--- @alias GenericsTypesDefinitionParameter GenericTypeDefinitionParameter[] Applied on Class-Scope and Method-Scope.

--- @class (exact) GenericTypeDefinitionParameter
---
--- @field name string The name of the generic type.
--- @field types string[]? If two or more types are assignable, use the types string[].
--- @field type string? If one type is assignable, use the type string.

-- MARK: - Module

--- @class VMGenericModule: VMModule
local API = {};

--- Compiles provided generic parameters for classes and methods.
---
--- @param cd ClassStructDefinition
--- @param gdefParam GenericsTypesDefinitionParameter
---
--- @return GenericsTypesDefinition
function API.compileGenericTypesDefinition(cd, gdefParam) end
