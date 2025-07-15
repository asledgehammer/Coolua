--- @meta

--- @alias PublicFlag 'public' Structs with this flag are accessible to everything.
--- @alias ProtectedFlag 'protected'
--- @alias PrivateFlag 'private'
--- @alias AbstractFlag 'abstract'
--- @alias FinalFlag 'final'
--- @alias VoidType 'void'

--- @alias ScopeFlag PublicFlag|ProtectedFlag|PrivateFlag
--- @alias ModifierFlag ScopeFlag|FinalFlag|AbstractFlag

--- @alias ClassName string

--- @alias TableBody {__type__: string}[]

--- @class BuilderTable
--- @field __type__ string

--- @class FieldTable: BuilderTable
--- @field __type__ 'FieldTable'
---
--- @field name string
--- @field flags string[]

--- @class MethodTable: BuilderTable
--- @field __type__ 'MethodTable'
---
--- @field name string
--- @field body MethodTableBody

--- @class MethodTableBody

--- @class ConstructorTable: BuilderTable
--- @field __type__ 'ConstructorTable'

--- @class ExtendsTable: BuilderTable
--- @field __type__ 'ExtendsTable'
--- @field value ClassStructDefinition|InterfaceStructDefinition

--- @class ImplementsTable: BuilderTable
--- @field __type__ 'ImplementsTable'
--- @field value InterfaceStructDefinition[]

-- MARK: - static

--- @class StaticTable: BuilderTable
--- @field __type__ 'StaticTable'
--- @field classes table<string, ClassStructDefinition>
--- @field interfaces table<string, InterfaceStructDefinition>
--- @field fields table<string, FieldTable>
--- @field methods table<string, MethodTable>

-- MARK: - class

--- @class ClassTableInstanced
--- @field classes table<string, ClassStructDefinition>
--- @field interfaces table<string, InterfaceStructDefinition>
--- @field fields table<string, FieldTable>
--- @field methods table<string, MethodTable>

--- @class ClassTableStatic
--- @field classes table<string, ClassStructDefinition>
--- @field interfaces table<string, InterfaceStructDefinition>
--- @field fields table<string, FieldTable>
--- @field methods table<string, MethodTable>

--- @alias ClassTableBody {__type__: 'ExtendsTable'|'ImplementsTable'|'ClassStructDefinition'|'InterfaceStructDefinition'|'ConstructorTable'|'MethodTable'|'FieldTable'}[]

--- @class ClassTable
--- @field __type__ 'ClassTable'
---
--- @field name string
--- @field flags string[]
--- @field instanced ClassTableInstanced
--- @field static ClassTableStatic
--- @field constructors ConstructorTable[]
local ClassTable = {};
