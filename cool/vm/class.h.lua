--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Struct

--- @class (exact) ClassMethodStructInput
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field parameters ParameterStructParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function

--- @class (exact) ClassStaticMethodStructInput
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field parameters ParameterStructParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function

--- @class (exact) ClassAbstractMethodStructInput
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field parameters ParameterStructParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body nil

--- @class (exact) ClassStructInput: StructInput
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field extends ClassStruct? (Default: nil)
--- @field static boolean? If the class is defined as static.
--- @field abstract boolean? (Default: false)
--- @field implements InterfaceStruct|InterfaceStruct[]?

--- @class (exact) ChildClassStructInput: StructInput
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field extends ClassStruct? (Default: nil)
--- @field abstract boolean? (Default: false)
--- @field implements InterfaceStruct|InterfaceStruct[]?

--- @class (exact) ClassStruct: HierarchicalStruct, Constructable, Fieldable, Staticable, Abstractable, Auditable
--- @field __type__ 'ClassStruct'
--- @field __readonly__ boolean
--- @field __supertable__ SuperTable
---
--- @field printHeader string
--- @field type string
--- @field classObj Class?
--- @field super ClassStruct?
--- @field sub ClassStruct[]
--- @field interfaces InterfaceStruct[]
local ClassStruct = {};

--- @return ClassInstance
function ClassStruct:new(...) end

--- @param input FieldStructInput
---
--- @return FieldStruct
function ClassStruct:addField(input) end

--- @param input StaticFieldStructInput
---
--- @return FieldStruct
function ClassStruct:addStaticField(input) end

--- Attempts to resolve a FieldStruct in the ClassStruct. If the field isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function ClassStruct:getField(name) end

--- @return FieldStruct[]
function ClassStruct:getFields() end

--- Attempts to resolve a FieldStruct in the ClassStruct. If the field isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function ClassStruct:getDeclaredField(name) end

--- @param input ConstructorStructInput
---
--- @return ConstructorStruct
function ClassStruct:addConstructor(input) end

--- @param args any[]
---
--- @return ConstructorStruct|nil ConstructorStruct
function ClassStruct:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorStruct|nil ConstructorStruct
function ClassStruct:getDeclaredConstructor(args) end

--- @param input ClassMethodStructInput
---
--- @return MethodStruct
function ClassStruct:addMethod(input) end

--- @param input ClassAbstractMethodStructInput
---
--- @return MethodStruct
function ClassStruct:addAbstractMethod(input) end

--- @param input ClassStaticMethodStructInput
---
--- @return MethodStruct
function ClassStruct:addStaticMethod(input) end

--- Attempts to resolve a MethodStruct in the ClassStruct. If the method isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function ClassStruct:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function ClassStruct:getMethod(name, args) end

--- Attempts to resolve a MethodStruct in the ClassStruct. If the method isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function ClassStruct:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function ClassStruct:getDeclaredMethod(name, args) end

--- @return ClassStruct
function ClassStruct:finalize() end

--- @return boolean
function ClassStruct:isFinalized() end

--- @param class ClassStruct
---
--- @return boolean
function ClassStruct:isAssignableFromType(class) end

--- @param class Hierarchical?
---
--- @return boolean
function ClassStruct:isSuperClass(class) end

--- @param class ClassStruct The class to evaulate.
---
--- @return boolean result True if the class to evaluate is a super-class of the subClass.
function ClassStruct:isSubClass(class) end

--- @param superInterface InterfaceStruct
---
--- @return boolean
function ClassStruct:isSuperInterface(superInterface) end

--- @param struct Struct
function ClassStruct:addStaticStruct(struct) end

--- @param struct Struct
function ClassStruct:addInstanceStruct(struct) end

--- @param outer Struct
function ClassStruct:setOuterStruct(outer) end

-- MARK: - Module

--- @class VMClassModule: VMModule
local API = {};

--- Defined for all classes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b) end

--- @param input ClassStructInput
---
--- @return ClassStruct
function API.newClass(input) end

--- @param input ChildClassStructInput
--- @param outer Struct
---
--- @return ClassStruct
function API.newClass(input, outer) end
