--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Interface

--- @class (exact) Auditable Any struct that is auditing.
--- @field audited boolean If true, the struct is audited and verified to be valid.

--- @class (exact) Staticable Any struct that supports static modes.
--- @field static boolean (Default: false) If true, the struct is considered static.

--- @class (exact) Abstractable
--- @field abstract boolean (Default: false)

--- @class (exact) Constructable Any struct that supports self-construction. (Classes, Enums)
--- @field __middleConstructor function
--- @field declaredConstructors table<string, ConstructorStruct>

--- @class (exact) Methodable Any struct that supports methods. (Class, Interface, Enum)
--- @field __middleMethods table<string, function> All middle functables for methods.
--- @field declaredMethods table<string, table<string, MethodStruct>> All compiled methods for the class.
--- @field methods table<string, table<string, MethodStruct>> All compiled methods. If the struct is extendable then all directly-accessable methods from super-classes are assigned here.
--- @field methodCache table<string, MethodStruct> Cache all method call signatures with their resolved method definitions. This is used to optimize method routing.

--- @class (exact) Fieldable Any struct that supports fields. (Class, Interface, Enum)
--- @field declaredFields table<string, FieldStruct>
--- @field staticFields table<string, any> Stores the static values for classes.

--- @class (exact) Hierarchical
--- @field super Hierarchical?
--- @field sub Hierarchical[]
--- @field children table<string, Struct> Any classes that are defined within the class's context.
--- @field isChild boolean
--- @field final boolean (Default: false) If the struct is final and cannot be extended.

-- MARK: - Struct

--- @class StructReference A pre-initialized definition that is cross-referenced between class initializations.
--- @field __type__ 'StructReference'
--- @field path string The file/package path to the definition.

--- @class Struct: Methodable
--- @field __type__ string The internal type. Used for evaluation for several components inside the VM.
--- @field __readonly__ boolean
--- @field __supertable__ SuperTable
--- @field path string The file/package path to the definition.
--- @field pkg string
--- @field file string The exact file the struct is defined.
--- @field folder string The exact folder the struct is defined.
--- @field name string
--- @field scope ClassScope
--- @field printHeader string Used for informational prints.
--- @field static boolean
---
--- * Enclosure Properties *
--- @field outer Struct
--- @field inner table<string, Struct>
local Struct = {};

--- @param struct Struct
function Struct:setOuterStruct(struct) end

--- @param struct Struct
---
--- @return boolean
function Struct:isAssignableFromType(struct) end

function Struct:finalize() end

--- @return boolean
function Struct:isFinalized() end

--- @class HierarchicalStruct: Struct, Hierarchical

--- @class StructInput
---
--- @field pkg string?
--- @field name string?

--- @class VMStructModule: VMModule
local API = {};

--- @param definition Struct|StructInput
--- @param outer Struct?
---
--- @return {path: string, name: string, pkg: string}
function API.calcPathNamePackage(definition, outer) end

--- @param path string
---
--- @return StructReference
function API.newReference(path) end

--- @param classDef ClassStruct
--- @param o Object
function API.createInstanceMetatable(classDef, o) end
