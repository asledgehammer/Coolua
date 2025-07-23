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

--- @alias MethodTemplate fun(tbl: table): MethodTable
--- @alias MethodTemplateDictionary table<Struct, table<string, MethodTemplate>>

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

--- @class MethodTableBodyInput
--- @field parameters Parameterable[]?
--- @field returnTypes ReturnsTable?
--- @field body function?

--- @class MethodTableBody
--- @field __type__ 'MethodTableBody'
--- 
--- @field parameters Parameterable[]
--- @field returnTypes ReturnsTable
--- @field body function

--- @class ConstructorTable: BuilderTable
--- @field __type__ 'ConstructorTable'

--- @class ReturnsTable

--- @class ExtendsTable: BuilderTable
--- @field __type__ 'ExtendsTable'
--- @field value ClassStruct|InterfaceStruct

--- @class ImplementsTable: BuilderTable
--- @field __type__ 'ImplementsTable'
--- @field value InterfaceStruct[]

-- MARK: static

--- @class StaticTable: BuilderTable
--- @field __type__ 'StaticTable'
--- @field classes table<string, ClassStruct>
--- @field interfaces table<string, InterfaceStruct>
--- @field records table<string, RecordStruct>
--- @field fields table<string, FieldTable>
--- @field methods table<string, MethodTable>

-- MARK: <class>

--- @class ClassTableContents
--- @field classes table<string, ClassStruct>
--- @field interfaces table<string, InterfaceStruct>
--- @field records table<string, RecordStruct>
--- @field fields table<string, FieldTable>
--- @field methods table<string, MethodTable>

--- @alias ClassTableBody {__type__: 'ExtendsTable'|'ImplementsTable'|'ClassStruct'|'InterfaceStruct'|'ConstructorTable'|'MethodTable'|'FieldTable'}[]

--- @class ClassTable
--- @field __type__ 'ClassTable'
---
--- @field name string
--- @field flags string[]
--- @field instanced ClassTableContents
--- @field static ClassTableContents
--- @field constructors ConstructorTable[]
local ClassTable = {};

-- MARK: <record>

--- @class RecordTableContents
--- @field classes table<string, ClassStruct>
--- @field interfaces table<string, InterfaceStruct>
--- @field records table<string, RecordStruct>
--- @field fields table<string, FieldTable>
--- @field methods table<string, MethodTable>

--- @class RecordTableInstancedContents: RecordTableContents
--- @field fields table<string, EntryTable>

--- @class RecordTable
--- @field __type__ 'RecordTable'
---
--- @field name string
--- @field flags string[]
--- @field instanced RecordTableInstancedContents
--- @field static RecordTableContents
--- @field constructors ConstructorTable[]
local RecordTable = {};

-- MARK: <entry>

--- @class EntryTable Aliased `private final` field for RecordTable. get is enforced and set is not allowed.
--- @field __type__ 'EntryTable'
--- @field name string
--- @field types any[]
local EntryTable = {};
