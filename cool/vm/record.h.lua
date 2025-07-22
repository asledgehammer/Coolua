--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - <entry>

--- @class (exact) EntryStruct
--- @field __type__ 'EntryStruct'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field struct Struct
--- @field name string
--- @field types AllowedType[]
--- @field value any
--- @field assignedOnce boolean This flag is used for final fields. If true, all assignments will fail.
local EntryStruct = {};

--- @class (exact) EntryStructInput
--- @field name string
--- @field types AllowedType[]?
--- @field type AllowedType?
--- @field final boolean?
local EntryStructInput = {};

-- MARK: - <input>

--- @class (exact) RecordStructInput: StructInput
--- @field scope ClassScope? (Default: package)
--- @field name string?
--- @field static boolean? If the record is defined as static.
--- @field implements InterfaceStruct|InterfaceStruct[]?
local RecordStructInput = {};

--- @class (exact) ChildRecordStructInput: StructInput
--- @field scope ClassScope? (Default: package)
--- @field name string?
--- @field static boolean? If the record is defined as static.
--- @field implements InterfaceStruct|InterfaceStruct[]?
local ChildRecordStructInput = {};

-- MARK: - <struct>

--- @class RecordStruct: Struct, Constructable, Staticable, Abstractable, Auditable
---
--- @field __type__ 'RecordStruct'
--- @field __readonly__ boolean
---
--- @field printHeader string
--- @field type string
--- @field classObj Class?
--- @field interfaces InterfaceStruct[]
--- @field declaredEntries table<string, EntryStruct>
--- @field declaredEntriesOrdered EntryStruct[] Used to create the implicit constructor.
local RecordStruct = {};

-- MARK: general

--- @return RecordInstance
function RecordStruct:new(...) end

--- @return RecordStruct
function RecordStruct:finalize() end

--- @return boolean
function RecordStruct:isFinalized() end

--- @param class any
---
--- @return boolean
function RecordStruct:isAssignableFromType(class) end

-- MARK: inner-struct

--- @param struct Struct
function RecordStruct:addStaticStruct(struct) end

--- @param struct Struct
function RecordStruct:addInstanceStruct(struct) end

--- @param outer Struct
function RecordStruct:setOuterStruct(outer) end

-- MARK: constructor

--- @param input ConstructorStructInput
---
--- @return ConstructorStruct
function RecordStruct:addConstructor(input) end

--- @param args any[]
---
--- @return ConstructorStruct|nil ConstructorStruct
function RecordStruct:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorStruct|nil ConstructorStruct
function RecordStruct:getDeclaredConstructor(args) end

-- MARK: method

--- @param input ClassMethodStructInput
---
--- @return MethodStruct
function RecordStruct:addMethod(input) end

--- @param input StaticMethodStructInput
---
--- @return MethodStruct
function RecordStruct:addStaticMethod(input) end

--- Attempts to resolve a MethodStruct in the RecordStruct. If the method isn't declared for the record level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function RecordStruct:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function RecordStruct:getMethod(name, args) end

--- Attempts to resolve a MethodStruct in the RecordStruct. If the method isn't defined in the record, nil
--- is returned.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function RecordStruct:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function RecordStruct:getDeclaredMethod(name, args) end

-- MARK: <entry>

--- @param input EntryStructInput
---
--- @return EntryStruct
function RecordStruct:addEntry(input) end

--- Attempts to resolve a FieldStruct in the RecordStruct.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function RecordStruct:getEntry(name) end

--- @return FieldStruct[]
function RecordStruct:getEntries() end

--- Attempts to resolve a FieldStruct in the RecordStruct.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function RecordStruct:getDeclaredEntry(name) end

-- MARK: <field>

--- @param input StaticFieldStructInput
---
--- @return FieldStruct
function RecordStruct:addStaticField(input) end

--- Attempts to resolve a FieldStruct in the RecordStruct.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function RecordStruct:getStaticField(name) end

--- @return FieldStruct[]
function RecordStruct:getStaticFields() end

--- Attempts to resolve a FieldStruct in the RecordStruct.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function RecordStruct:getDeclaredStaticField(name) end

--- @param superInterface InterfaceStruct
---
--- @return boolean
function RecordStruct:isSuperInterface(superInterface) end

-- MARK: - <instance>

--- @class RecordInstance
---
--- @field __type__ string The `record:<package>.<name>` identity of the record.
--- @field __table_id__ string -- For native Lua table identity. Helps prevent infinite loops when checking self literally.
--- @field __class__ Class The Class-Object wrapper, not the VM Struct.
--- @field super table|function? This field is dynamically set for each function invocation.
local RecordInstance = {};

-- MARK: - <module>

--- @class VMRecordModule: VMModule
local API = {};

--- Defined for all records so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b) end

--- @param input RecordStructInput
---
--- @return RecordStruct
function API.newRecord(input) end

--- @param input ChildRecordStructInput
--- @param outer Struct
---
--- @return RecordStruct
function API.newRecord(input, outer) end
