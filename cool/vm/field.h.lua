--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Field

--- @class (exact) FieldStruct
--- @field __type__ 'FieldStruct'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class ClassStruct
--- @field name string
--- @field types AllowedType[]
--- @field scope ClassScope
--- @field value any
--- @field static boolean
--- @field final boolean
--- @field get FieldGetDefinition?
--- @field set FieldSetDefinition?
--- @field assignedOnce boolean This flag is used for final fields. If true, all assignments will fail.

--- @class (exact) FieldStructParameter
--- @field name string
--- @field types AllowedType[]?
--- @field type AllowedType?
--- @field scope ClassScope?
--- @field final boolean?
--- @field value any?
--- @field get FieldGetDefinition?
--- @field set FieldSetDefinition?

--- @class (exact) StaticFieldStructParameter
--- @field name string
--- @field types AllowedType[]?
--- @field type AllowedType?
--- @field scope ClassScope?
--- @field final boolean?
--- @field value any?
--- @field get FieldGetDefinition?
--- @field set FieldSetDefinition?

--- @class (exact) FieldGetDefinition
--- @field scope ClassScope?
--- @field body function?
--- @field name string?

--- @class (exact) FieldSetDefinition
--- @field scope ClassScope?
--- @field body function?
--- @field name string?

-- MARK: - Module

--- @class VMFieldModule: VMModule
local API = {};

--- @param self ClassStruct|InterfaceStruct
function API.compileFieldAutoMethods(self) end
