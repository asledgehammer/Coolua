--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) ConstructorDefinition
--- @field __type__ 'ConstructorDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class ClassStructDefinition
--- @field scope ClassScope
--- @field parameters ParameterDefinition[]
--- @field func fun(o: any, ...)

--- @class (exact) ConstructorDefinitionParameter
--- @field scope ClassScope? (Default: "package")
--- @field parameters ParameterDefinitionParameter[]?

-- MARK: - Module

--- @class LVMConstructorModule: LVMModule
local API = {};

--- @param classDef ClassStructDefinition
function API.createMiddleConstructor(classDef) end

--- @param constructors ConstructorDefinition[]
--- @param args table
--- 
--- @return ConstructorDefinition|nil
function API.resolveConstructor(constructors, args) end