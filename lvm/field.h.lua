--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Field

--- @class (exact) FieldDefinition
--- @field __type__ 'FieldDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class LVMClassDefinition
--- @field name string
--- @field types string[]
--- @field scope ClassScope
--- @field value any
--- @field static boolean
--- @field final boolean
--- @field get FieldGetDefinition?
--- @field set FieldSetDefinition?
--- @field assignedOnce boolean This flag is used for final fields. If true, all assignments will fail.

--- @class (exact) FieldDefinitionParameter
--- @field name string
--- @field types string[]?
--- @field type string?
--- @field scope ClassScope?
--- @field static boolean?
--- @field final boolean?
--- @field value any?
--- @field get FieldGetDefinition?
--- @field set FieldSetDefinition?

--- @class (exact) FieldGetDefinition
--- @field scope ClassScope?
--- @field func function?

--- @class (exact) FieldSetDefinition
--- @field scope ClassScope?
--- @field func function?

-- MARK: - Module

--- @class LVMFieldModule: LVMModule
local API = {};
