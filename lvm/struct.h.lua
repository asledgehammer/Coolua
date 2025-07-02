--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class StructDefinition
---
--- @field path string
--- @field pkg string
--- @field name string

--- @class StructDefinitionParameter
---
--- @field pkg string?
--- @field name string?

--- @class LVMStructModule: LVMModule
local API = {};

--- @param definition LVMClassDefinitionParameter|LVMChildClassDefinitionParameter
--- @param enclosingDefinition LVMClassDefinition?
---
--- @return {path: string, name: string, pkg: string}
function API.calcPathNamePackage(definition, enclosingDefinition) end
