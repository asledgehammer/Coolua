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

--- @class (exact) Enclosurable
--- @field enclosingClass StructDefinition
--- @field enclosed table<string, StructDefinition>

--- @class (exact) Constructable Any struct that supports self-construction. (Classes, Enums)
--- @field __middleConstructor function
--- @field declaredConstructors ConstructorDefinition[]

--- @class (exact) Methodable Any struct that supports methods. (Class, Interface, Enum)
--- @field __middleMethods table<string, function> All middle functables for methods.
--- @field declaredMethods table<string, MethodDefinition> All compiled methods for the class.
--- @field methods table<string, MethodDefinition[]> All compiled methods. If the struct is extendable then all directly-accessable methods from super-classes are assigned here.

--- @class (exact) Fieldable Any struct that supports fields. (Class, Interface, Enum)
--- @field declaredFields table<string, FieldDefinition>
--- @field staticFields table<string, any> Stores the static values for classes.

--- @class (exact) Hierarchical
--- @field superClass Hierarchical
--- @field subClasses (ClassDefinition|Class)[]
--- @field children table<string, ClassDefinition> Any classes that are defined within the class's context.
--- @field isChild boolean
--- @field final boolean (Default: false) If the struct is final and cannot be extended.

-- MARK: - Definition

--- @class (exact) StructDefinition
--- @field __type__ string The internal type. Used for evaluation for several components inside the LVM.
--- @field path string
--- @field pkg string
--- @field name string
--- @generic T: string The type of structure. E.G: `ClassDefinition`

--- @class StructDefinitionParameter
---
--- @field pkg string?
--- @field name string?

--- @class LVMStructModule: LVMModule
local API = {};

--- @param definition StructDefinition|StructDefinitionParameter
--- @param enclosingDefinition StructDefinition?
---
--- @return {path: string, name: string, pkg: string}
function API.calcPathNamePackage(definition, enclosingDefinition) end
