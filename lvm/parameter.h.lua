--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) ParameterDefinition
--- @field __type__ 'ParameterDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class ClassStructDefinition
--- @field name string
--- @field types string[]

--- @class (exact) ParameterDefinitionParameter
--- @field types string[]?
--- @field type string?
--- @field name string?

-- MARK: - Module

--- @class LVMParameterModule: LVMModule
local API = {};

--- @param paramsA ParameterDefinition[]
--- @param paramsB ParameterDefinition[]
---
--- @return boolean
function API.areCompatible(paramsA, paramsB) end

--- @param arg string
--- 
--- @return string[] argTypes
function API.getVarargTypes(arg) end

--- @param arg string
--- 
--- @return boolean isVararg
function API.isVararg(arg) end
