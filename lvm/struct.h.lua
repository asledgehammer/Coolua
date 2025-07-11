--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Interface

--- @class (exact) Auditable Any struct that is auditing.
--- @field audited boolean If true, the struct is audited and verified to be valid.

--- @class (exact) Staticable Any struct that supports static modes.
--- @field static boolean (Default: false) If true, the struct is considered static.

--- @class (exact) Genericable
--- @field generics GenericsTypesDefinition? If the struct supports generics, this is where its defined.

--- @class (exact) Abstractable
--- @field abstract boolean (Default: false)

--- @class (exact) Constructable Any struct that supports self-construction. (Classes, Enums)
--- @field __middleConstructor function
--- @field declaredConstructors table<string, ConstructorDefinition>

--- @class (exact) Methodable Any struct that supports methods. (Class, Interface, Enum)
--- @field __middleMethods table<string, function> All middle functables for methods.
--- @field declaredMethods table<string, table<string, MethodDefinition>> All compiled methods for the class.
--- @field methods table<string, table<string, MethodDefinition>> All compiled methods. If the struct is extendable then all directly-accessable methods from super-classes are assigned here.
--- @field methodCache table<string, MethodDefinition> Cache all method call signatures with their resolved method definitions. This is used to optimize method routing.

--- @class (exact) Fieldable Any struct that supports fields. (Class, Interface, Enum)
--- @field declaredFields table<string, FieldDefinition>
--- @field staticFields table<string, any> Stores the static values for classes.

--- @class (exact) Hierarchical
--- @field super Hierarchical?
--- @field sub Hierarchical[]
--- @field children table<string, ClassDefinition> Any classes that are defined within the class's context.
--- @field isChild boolean
--- @field final boolean (Default: false) If the struct is final and cannot be extended.

-- MARK: - Definition

--- @class StructReference A pre-initialized definition that is cross-referenced between class initializations.
--- @field __type__ 'StructReference'
--- @field path string The file/package path to the definition.

--- @class StructDefinition: Methodable
--- @field __type__ string The internal type. Used for evaluation for several components inside the LVM.
--- @field __readonly__ boolean
--- @field __supertable__ SuperTable
--- @field path string The file/package path to the definition.
--- @field pkg string
--- @field name string
--- @field scope ClassScope
--- @field printHeader string Used for informational prints.
--- @field static boolean
---
--- * Enclosure Properties *
--- @field outer StructDefinition
--- @field inner table<string, StructDefinition>
local StructDefinition = {};

--- @param struct StructDefinition
function StructDefinition:setOuterStruct(struct) end

--- @param struct StructDefinition
---
--- @return boolean
function StructDefinition:isAssignableFromType(struct) end

function StructDefinition:finalize() end

--- @return boolean
function StructDefinition:isFinalized() end

--- @class HierarchicalStructDefinition: StructDefinition, Hierarchical

--- @class StructDefinitionParameter
---
--- @field pkg string?
--- @field name string?

--- @class LVMStructModule: LVMModule
local API = {};

--- @param definition StructDefinition|StructDefinitionParameter
--- @param outer StructDefinition?
---
--- @return {path: string, name: string, pkg: string}
function API.calcPathNamePackage(definition, outer) end

--- @param path string
--- 
--- @return StructReference
function API.newReference(path) end
